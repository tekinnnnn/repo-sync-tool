#!/bin/bash

# Configuration module for repository synchronization tool
# Defines constants and default configuration values

# Prevent multiple inclusions
if [ -z "$CONFIG_INCLUDED" ]; then
  CONFIG_INCLUDED=true

  # Script directory
  readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

  # User config file location
  readonly CONFIG_FILE="${SCRIPT_DIR}/repo-sync.conf"
  
  # Status codes
  readonly STATUS_SUCCESS=0
  readonly STATUS_ERROR=1
  readonly STATUS_SKIPPED=2
fi

# Default configuration values
# These values will be used if no config file exists

# Base repository path (default)
DEFAULT_REPO_BASE_PATH="${HOME}/repos"

# Default repositories to sync (will be populated from config file or init wizard)
DEFAULT_REPOS=()

# Git remote configuration (default)
# Remote names in order of preference
DEFAULT_REMOTE_NAMES=("upstream" "origin")

# Default branch name to sync with (default, comma-separated alternatives)
DEFAULT_TARGET_BRANCH="master,main"

# Default SSH connection string for remote server
DEFAULT_SSH_CONNECTION=""

# Default run after pull scripts (comma-separated)
DEFAULT_RUN_AFTER_PULL="sync,syncAll"

# Maximum number of attempts to connect to remote server (default)
DEFAULT_MAX_CONNECT_ATTEMPTS=3

# Time to wait between connection attempts in seconds (default)
DEFAULT_CONNECT_RETRY_WAIT=10

# Actual configuration values (will be set from config file or defaults)
REPO_BASE_PATH=""
REPOS=()
REMOTE_NAMES=()
DEFAULT_BRANCH=""
SSH_CONNECTION=""
RUN_AFTER_PULL=()
MAX_CONNECT_ATTEMPTS=""
CONNECT_RETRY_WAIT=""

# Load configuration from file
# Returns:
#   0 on success, 1 on failure
load_config() {
  # Check if config file exists
  if [ ! -f "$CONFIG_FILE" ]; then
    set_default_config
    return 1
  fi
  
  log_info "Loading configuration from $(realpath "$CONFIG_FILE")..."
  
  # Read the config file line by line and set variables directly
  while IFS='=' read -r key value || [ -n "$key" ]; do
    # Skip comments and empty lines
    [[ $key =~ ^[[:space:]]*# ]] && continue
    [[ -z $key ]] && continue
    
    # Trim leading and trailing whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    
    # Set variables based on the key
    case "$key" in
      REPO_BASE_PATH)
        REPO_BASE_PATH="$value"
        ;;
      REPOSITORIES)
        IFS=',' read -ra REPOS <<< "$value"
        ;;
      REMOTE_NAMES)
        IFS=',' read -ra REMOTE_NAMES <<< "$value"
        ;;
      DEFAULT_BRANCH)
        # Set as comma-separated list of branch alternatives
        DEFAULT_BRANCH="$value"
        ;;
      SSH_CONNECTION)
        SSH_CONNECTION="$value"
        ;;
      RUN_AFTER_PULL)
        # Split space-separated groups
        RUN_AFTER_PULL=()
        for group in $value; do
          RUN_AFTER_PULL+=("$group")
        done
        ;;
      MAX_CONNECT_ATTEMPTS)
        MAX_CONNECT_ATTEMPTS="$value"
        ;;
      CONNECT_RETRY_WAIT)
        CONNECT_RETRY_WAIT="$value"
        ;;
    esac
  done < "$CONFIG_FILE"
  
  # Set default values for any variables that weren't set from the config file
  
  # Repository base path
  REPO_BASE_PATH="${REPO_BASE_PATH:-$DEFAULT_REPO_BASE_PATH}"
  
  # Default repositories
  if [ ${#REPOS[@]} -eq 0 ]; then
    REPOS=("${DEFAULT_REPOS[@]}")
  fi
  
  # Remote names
  if [ ${#REMOTE_NAMES[@]} -eq 0 ]; then
    REMOTE_NAMES=("${DEFAULT_REMOTE_NAMES[@]}")
  fi
  
  # Default branch
  DEFAULT_BRANCH="${DEFAULT_BRANCH:-$DEFAULT_TARGET_BRANCH}"
  
  # SSH connection
  SSH_CONNECTION="${SSH_CONNECTION:-$DEFAULT_SSH_CONNECTION}"
  
  # Run after pull scripts
  if [ ${#RUN_AFTER_PULL[@]} -eq 0 ] && [ -n "$DEFAULT_RUN_AFTER_PULL" ]; then
    IFS=',' read -ra RUN_AFTER_PULL <<< "$DEFAULT_RUN_AFTER_PULL"
  fi
  
  # Max connection attempts
  MAX_CONNECT_ATTEMPTS="${MAX_CONNECT_ATTEMPTS:-$DEFAULT_MAX_CONNECT_ATTEMPTS}"
  
  # Connection retry wait
  CONNECT_RETRY_WAIT="${CONNECT_RETRY_WAIT:-$DEFAULT_CONNECT_RETRY_WAIT}"
  
  return 0
}

# Set configuration to default values
# Returns:
#   0 always
set_default_config() {
  REPO_BASE_PATH="$DEFAULT_REPO_BASE_PATH"
  REPOS=("${DEFAULT_REPOS[@]}")
  REMOTE_NAMES=("${DEFAULT_REMOTE_NAMES[@]}")
  DEFAULT_BRANCH="$DEFAULT_TARGET_BRANCH"
  SSH_CONNECTION="$DEFAULT_SSH_CONNECTION"
  DEFAULT_SYNC_BEHAVIOR="$DEFAULT_SYNC_BEHAVIOR"
  MAX_CONNECT_ATTEMPTS="$DEFAULT_MAX_CONNECT_ATTEMPTS"
  CONNECT_RETRY_WAIT="$DEFAULT_CONNECT_RETRY_WAIT"
  return 0
}

# Save configuration to file
# Returns:
#   0 on success, 1 on failure
save_config() {
  # Create configuration content
  local config_content=$(cat <<EOF
# Repository Sync Tool Configuration
# Created on $(date)

# Repository base path - the base directory where your repositories are located
REPO_BASE_PATH=$REPO_BASE_PATH

# Repositories to sync by default (comma-separated list)
REPOSITORIES=$(IFS=,; echo "${REPOS[*]}")

# Remote names in order of preference (comma-separated list)
REMOTE_NAMES=$(IFS=,; echo "${REMOTE_NAMES[*]}")

# Default branch name to sync with
DEFAULT_BRANCH=$DEFAULT_BRANCH

# SSH connection string for remote server (REQUIRED)
SSH_CONNECTION=$(echo "$SSH_CONNECTION" | sed -E 's/Enter the SSH connection string for remote server \[[^]]*\]:\s*//' | xargs)

# Scripts to run after pull (space-separated groups with comma-separated alternatives)
# Example: "sync,syncAll fire_webhook" - First try sync OR syncAll, then try fire_webhook
# Leave empty to skip running any scripts
RUN_AFTER_PULL=$(printf "%s " "${RUN_AFTER_PULL[@]}" | sed 's/Scripts to run after pull \[[^]]*\]:*//g' | sed 's/^ *//;s/ *$//')

# Maximum number of attempts to connect to remote server
MAX_CONNECT_ATTEMPTS=${MAX_CONNECT_ATTEMPTS}

# Seconds to wait between connection attempts
CONNECT_RETRY_WAIT=${CONNECT_RETRY_WAIT}
EOF
)
  
  # Save to file
  echo "$config_content" > "$CONFIG_FILE"
  
  if [ $? -eq 0 ]; then
    echo "Configuration saved to ${CONFIG_FILE}"
    return 0
  else
    echo "Failed to save configuration to ${CONFIG_FILE}"
    return 1
  fi
}

# Find all git repositories in the base directory
# Arguments:
#   $1 - Base directory to search in
# Returns:
#   String with newline-separated list of repository paths
find_git_repos() {
  local base_dir="$1"
  local repos=""
  
  # Expand tilde to home directory if needed
  base_dir="${base_dir/#\~/$HOME}"
  
  # Validate base directory
  if [ ! -d "$base_dir" ]; then
    echo "Directory not found: $base_dir"
    return 1
  fi
  
  # Find all directories in the base directory that are git repositories
  # Using a different approach to avoid potential issues with find -print0
  for dir in "$base_dir"/*; do
    if [ -d "$dir/.git" ]; then
      local rel_path="${dir#$base_dir/}"
      repos="${repos}${rel_path}
"
    fi
  done
  
  echo "$repos" | sort
  return 0
}

# Get the full path of a repository
# Arguments:
#   $1 - Repository name or path
get_repo_full_path() {
  local repo="$1"
  local base_path="$REPO_BASE_PATH"
  
  # Expand tilde to home directory if present in base path
  base_path="${base_path/#\~/$HOME}"
  
  # If it's already an absolute path, return it as is
  if [[ "$repo" == /* ]]; then
    echo "$repo"
  else
    echo "${base_path}/${repo}"
  fi
}

# Get the basename of a repository
# Arguments:
#   $1 - Repository name or path
get_repo_name() {
  basename "$1"
}

# Initialize configuration
# This is called when the script is loaded
initialize_config() {
  # Try to load config from file, fall back to defaults if not found
  if ! load_config; then
    set_default_config
  fi
}

# Call the initialization function
initialize_config