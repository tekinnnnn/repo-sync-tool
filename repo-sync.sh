#!/bin/bash

# Repository Synchronization Tool
# A tool for synchronizing multiple git repositories at once
# Author: Tekin Aydoğdu

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/repo-operations.sh"

# Display help information
# Arguments:
#   None
# Returns:
#   None (exits with status 0)
display_help() {
  echo "Usage: $0 [OPTIONS] [repo1 repo2 ...]"
  echo
  echo "Script for syncing git repositories"
  echo
  echo "Options:"
  echo "  --repos=REPO1,REPO2,...    Comma-separated list of repositories to sync"
  echo "  --exclude=REPO1,REPO2,...  Comma-separated list of repositories to exclude from sync"
  echo "  --force-master             Force checkout to master branch even if currently on another branch"
  echo "  --no-sync                  Skip running post-pull scripts, only git operations will be performed"
  echo "  --sync                     Run post-pull scripts after git operations"
  echo "  --init                     Run the initialization wizard to configure the tool"
  echo "  -v, --verbose              Show truncated script output (first and last 5 lines)"
  echo "  -vv, --very-verbose        Show full script output"
  echo "  --help                     Display this help message and exit"
  echo
  echo "If no repositories are specified, the following defaults will be used:"
  for repo in "${REPOS[@]}"; do
    echo "  - $repo"
  done
  echo
  echo "Examples:"
  echo "  $0                                     # Sync all default repositories"
  echo "  $0 --exclude=backend,api              # Sync all default repositories except backend and api"
  echo "  $0 --repos=Jotform3,frontend,backend  # Only sync the specified repositories"
  echo "  $0 Jotform3 frontend                  # Only sync the specified repositories (alternative syntax)"
  echo "  $0 --init                             # Run the initialization wizard"
  echo "  $0 --sync                             # Force run post-pull scripts"
  echo "  $0 --no-sync                          # Skip post-pull scripts"
  echo "  $0 -v                                 # Show truncated script output"
  echo "  $0 -vv                                # Show full script output"
  exit 0
}

# Parse command line arguments and build repo list
# Arguments:
#   All command line arguments as $@
# Returns:
#   Sets global variables and arrays
parse_arguments() {
  local use_default=true
  repos=()
  exclude_repos=()
  force_master=false
  sync_mode=""
  init_mode=false
  verbosity=0  # Default verbosity level
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -v|--verbose)
        verbosity=1
        log_info "Verbose mode enabled (level 1)"
        shift
        ;;
      -vv|--very-verbose)
        verbosity=2
        log_info "Very verbose mode enabled (level 2)"
        shift
        ;;
      --repos=*)
        IFS=',' read -r -a repo_names <<< "${1#*=}"
        for repo_name in "${repo_names[@]}"; do
          repos+=("$repo_name")
        done
        use_default=false
        log_info "Using specified repositories: ${repo_names[*]}"
        shift
        ;;
      --exclude=*)
        IFS=',' read -r -a exclude_names <<< "${1#*=}"
        for exclude_name in "${exclude_names[@]}"; do
          exclude_repos+=("$exclude_name")
        done
        log_info "Excluding repositories: ${exclude_names[*]}"
        shift
        ;;
      --force-master)
        force_master=true
        log_info "Force master mode enabled: will checkout master branch even if currently on another branch"
        shift
        ;;
      --no-sync)
        sync_mode="false"
        log_info "Sync mode disabled: will not run post-pull scripts"
        shift
        ;;
      --sync)
        sync_mode="true"
        log_info "Sync mode enabled: will run post-pull scripts"
        shift
        ;;
      --init)
        init_mode=true
        log_info "Initialization mode enabled"
        shift
        ;;
      --help)
        display_help
        ;;
      *)
        # If positional arguments are provided, use them as repos and ignore defaults
        repos+=("$1")
        use_default=false
        shift
        ;;
    esac
  done
  
  # Handle --init mode separately
  if [ "$init_mode" = true ]; then
    run_init_wizard
    exit 0
  fi
  
  # Check if config file exists and suggest creating one if it doesn't
  if [ ! -f "$CONFIG_FILE" ] && [ "$use_default" = true ]; then
    log_warning "No configuration file found."
    log_info "Consider running '$0 --init' to create a configuration file."
    echo
  fi
  
  # If no repos specified, use default list
  if [ "$use_default" = true ]; then
    repos=("${REPOS[@]}")
    log_info "Using default repository list"
    
    # Log the default repositories for visibility
    echo -e "${BLUE}Default repositories:${NC}"
    for repo in "${repos[@]}"; do
      echo "  - $repo"
    done
  fi
}

# Apply exclusions to the repository list
# Arguments:
#   None (uses global variables)
# Returns:
#   Modifies global repos array
apply_exclusions() {
  if [ ${#exclude_repos[@]} -gt 0 ]; then
    log_info "Applying exclusions..."
    local filtered_repos=()
    
    for repo in "${repos[@]}"; do
      # Extract repo name from path for comparison
      repo_name=$(get_repo_name "$repo")
      exclude=false
      
      for exclude_item in "${exclude_repos[@]}"; do
        if [ "$repo_name" = "$exclude_item" ]; then
          exclude=true
          break
        fi
      done
      
      if [ "$exclude" = false ]; then
        filtered_repos+=("$repo")
      else
        log_info "Excluding repository: $repo_name"
      fi
    done
    
    repos=("${filtered_repos[@]}")
  fi
  
  # If no repos to sync after exclusions, exit
  if [ ${#repos[@]} -eq 0 ]; then
    log_error "No repositories to sync after applying exclusions."
    exit 1
  fi
}

# Display a summary of sync operations
# Arguments:
#   $1 - Start time (in seconds since epoch)
#   $2 - End time (in seconds since epoch)
# Returns:
#   None
display_summary() {
  local start_time="$1"
  local end_time="$2"
  local duration=$((end_time - start_time))
  local duration_str=$(format_duration "$duration")
  
  print_separator "Sync Summary"
  echo -e "Operation completed in: ${duration_str}"
  echo -e "Repositories processed: ${#repos[@]}"
  echo -e "  ${GREEN}✓ Successful: $successful${NC}"
  echo -e "  ${RED}✗ Failed: $failed${NC}"
  echo -e "  ${YELLOW}○ Skipped: $skipped${NC}"
  
  # Display detailed results for each category
  if [ $successful -gt 0 ]; then
    echo -e "\n${GREEN}Successfully synced repositories:${NC}"
    for repo in "${successful_repos[@]}"; do
      echo -e "  $(print_status_icon success) $repo"
    done
  fi
  
  if [ $failed -gt 0 ]; then
    echo -e "\n${RED}Failed repositories:${NC}"
    for repo in "${failed_repos[@]}"; do
      echo -e "  $(print_status_icon failure) $repo"
    done
  fi
  
  if [ $skipped -gt 0 ]; then
    echo -e "\n${YELLOW}Skipped repositories:${NC}"
    for repo in "${skipped_repos[@]}"; do
      echo -e "  $(print_status_icon skipped) $repo"
    done
  fi
}

# Prompt the user for a string value
# Arguments:
#   $1 - Prompt message
#   $2 - Default value
# Returns:
#   The user's input or the default value if no input was provided
prompt_string() {
  local prompt_message="$1"
  local default_value="$2"
  local user_input
  
  # Display prompt with default value
  echo -n "$prompt_message [$default_value]: "
  read -r user_input
  
  # Return user input or default value
  if [ -z "$user_input" ]; then
    echo "$default_value"
  else
    echo "$user_input"
  fi
}

# Prompt the user for a boolean value (yes/no)
# Arguments:
#   $1 - Prompt message
#   $2 - Default value (true/false)
# Returns:
#   "true" for yes, "false" for no
prompt_boolean() {
  local prompt_message="$1"
  local default_value="$2"
  local default_text
  local user_input
  
  # Set default text based on default value
  if [ "$default_value" = "true" ]; then
    default_text="Y/n"
  else
    default_text="y/N"
  fi
  
  # Display prompt with default value
  echo -n "$prompt_message [$default_text]: "
  read -r user_input
  
  # Convert input to lowercase
  user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
  
  # Return based on input
  if [ -z "$user_input" ]; then
    echo "$default_value"
  elif [[ "$user_input" == "y" || "$user_input" == "yes" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Prompt the user for a multiselect
# Arguments:
#   $1 - Prompt title
#   $2 - Options array (newline-separated)
# Returns:
#   Selected options (newline-separated)
prompt_multiselect() {
  local title="$1"
  local options="$2"
  local selections=""
  
  echo "$title"
  
  # Display options with numbers
  local i=1
  while IFS= read -r option; do
    echo "  $i) $option"
    ((i++))
  done <<< "$options"
  
  echo "Enter the numbers of your selections (comma-separated), or 'a' for all:"
  printf "Your selections: "
  read -r user_selection
  
  # Convert input to lowercase
  user_selection=$(echo "$user_selection" | tr '[:upper:]' '[:lower:]')
  
  # Handle "all" selection
  if [ "$user_selection" = "a" ] || [ "$user_selection" = "all" ]; then
    echo "$options"
    return 0
  fi
  
  # Process comma-separated selections
  IFS=',' read -ra selected_indices <<< "$user_selection"
  
  # Build selections string
  local option_count=$(echo "$options" | wc -l)
  local option_array=()
  while IFS= read -r line; do
    option_array+=("$line")
  done <<< "$options"
  
  for index in "${selected_indices[@]}"; do
    # Trim whitespace
    index=$(echo "$index" | tr -d ' ')
    
    # Validate index
    if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le "$option_count" ]; then
      selection="${option_array[$((index-1))]}"
      selections="${selections}${selection}
"
    fi
  done
  
  echo "$selections"
}

# Prompt the user for a string value with better readability
# Arguments:
#   $1 - Prompt message
#   $2 - Default value
# Returns:
#   The user's input or the default value if no input was provided
prompt_string_interactive() {
  local prompt_message="$1"
  local default_value="$2"
  local user_input
  
  # Display prompt with default value
  printf "%s [%s]: " "$prompt_message" "$default_value"
  read -r user_input
  
  # Return user input or default value
  if [ -z "$user_input" ]; then
    echo "$default_value"
  else
    echo "$user_input"
  fi
}

# Run the initialization wizard to configure the tool
# Returns:
#   0 on success, 1 on failure
run_init_wizard() {
  print_section_header "Repository Sync Tool Configuration Wizard"
  
  echo "This wizard will help you configure the Repository Sync Tool."
  echo "Press Enter to accept the default values shown in brackets."
  echo
  
  # Set default values for wizard
  local wizard_repo_path="$DEFAULT_REPO_BASE_PATH"
  local wizard_ssh="$DEFAULT_SSH_CONNECTION"
  local wizard_max_attempts="$DEFAULT_MAX_CONNECT_ATTEMPTS"
  local wizard_retry_wait="$DEFAULT_CONNECT_RETRY_WAIT"
  
  # Check if config file exists and delete it
  if [ -f "$CONFIG_FILE" ]; then
    echo "Existing configuration found. It will be deleted and a new one will be created."
    rm "$CONFIG_FILE"
    echo "Old configuration deleted."
  fi
  
  echo "Step 1: Repository Base Path"
  echo "Enter the base directory for your repositories [$wizard_repo_path]: "
  # Use read with bash tab completion
  read -e REPO_BASE_PATH
  # Use default if empty
  REPO_BASE_PATH="${REPO_BASE_PATH:-$wizard_repo_path}"
  # Expand tilde to home directory if needed
  REPO_BASE_PATH="${REPO_BASE_PATH/#\~/$HOME}"
  echo "Using repository base path: $REPO_BASE_PATH"
  echo
  
  echo "Step 2: Remote Connection"
  # If this is a standard terminal session
  if [ -t 0 ]; then
    SSH_CONNECTION=$(prompt_string_interactive "Enter the SSH connection string for remote server" "$wizard_ssh")
  else
    # For piped input or script, use default
    SSH_CONNECTION="$wizard_ssh"
    echo "Using default SSH connection: $SSH_CONNECTION"
  fi
  echo
  
  # Set default branch to master without asking
  DEFAULT_BRANCH="master"
  echo "Default branch set to: master"
  echo
  
  echo "Step 3: Post-Pull Scripts"
  echo "These scripts will be run after pulling from the remote repository."
  echo "Format: Each group is processed separately, with alternatives within a group."
  echo "Example: 'sync syncAll, fire_webhook' means:"
  echo "  - First try 'sync' OR 'syncAll' (first one found will be executed)"
  echo "  - Then always try to run 'fire_webhook'"
  echo "Leave empty to disable running scripts after pull."
  local default_scripts=""
  if [ ${#RUN_AFTER_PULL[@]} -gt 0 ]; then
    default_scripts=$(printf "%s " "${RUN_AFTER_PULL[@]}")
  fi
  local run_after_pull_input=$(prompt_string_interactive "Scripts to run after pull" "$default_scripts")
  
  # Tokenize by spaces to get script groups
  if [ -n "$run_after_pull_input" ]; then
    # Split the input by spaces to get script groups
    read -ra RUN_AFTER_PULL <<< "$run_after_pull_input"
    echo "Configured script execution groups:"
    for group in "${RUN_AFTER_PULL[@]}"; do
      echo "  - $group"
    done
  else
    RUN_AFTER_PULL=()
  fi
  echo
  
  # Set connection settings without asking
  MAX_CONNECT_ATTEMPTS=3
  CONNECT_RETRY_WAIT=10
  echo
  
  # Make sure repository path is not interactive output
  if [[ "$REPO_BASE_PATH" == *":"* ]]; then
    REPO_BASE_PATH="$DEFAULT_REPO_BASE_PATH"
  fi
  
  # Find git repositories in base path
  echo "Step 5: Default Repositories"
  echo "Searching for git repositories in $REPO_BASE_PATH..."
  
  if [ ! -d "$REPO_BASE_PATH" ]; then
    log_warning "Directory not found: $REPO_BASE_PATH"
    mkdir -p "$REPO_BASE_PATH"
    log_success "Created directory: $REPO_BASE_PATH"
  fi
  
  local available_repos
  available_repos=$(find_git_repos "$REPO_BASE_PATH")
  
  if [ -z "$available_repos" ]; then
    log_warning "No git repositories found in $REPO_BASE_PATH"
    REPOS=()
    echo "You'll need to manually specify repositories when running the tool."
    echo "Either add git repositories to $REPO_BASE_PATH or use the --repos option when running."
  else
        # Filter out empty lines and prepare repository list
    local repo_list=""
    while IFS= read -r line; do
      if [ -n "$line" ]; then  # Skip empty lines
        repo_list="${repo_list}${line}
"
      fi
    done <<< "$available_repos"
    
    # Save clean repository list to a temporary file
    local repo_list_file=$(mktemp)
    echo "$repo_list" > "$repo_list_file"

    # Display available repositories with line numbers
    echo "Found repositories:"
    
    # Create numbered list of repositories
    local i=1
    while IFS= read -r line; do
      if [ -n "$line" ]; then  # Skip empty lines
        printf "%3d) %s\n" "$i" "$line"
        ((i++))
      fi
    done <<< "$repo_list"
    
    echo "Enter the numbers of your selections (comma-separated), or 'a' for all:"
    printf "Your selections: "
    read -r user_selection
    
    # Convert input to lowercase
    user_selection=$(echo "$user_selection" | tr '[:upper:]' '[:lower:]')
    
    # Handle "all" selection
    if [ "$user_selection" = "a" ] || [ "$user_selection" = "all" ]; then
      selected_repos="$repo_list"
    else
      # Process comma-separated selections
      IFS=',' read -ra selected_indices <<< "$user_selection"
      selected_repos=""
      
      # Count actual lines for validation
      local option_count=$(grep -c '[^[:space:]]' "$repo_list_file")
      
      for index in "${selected_indices[@]}"; do
        # Trim whitespace
        index=$(echo "$index" | tr -d ' ')
        
        # Validate index
        if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le "$option_count" ]; then
          # Get the repository name directly from the file using the index
          selection=$(sed -n "${index}p" "$repo_list_file")
          
          # Add to selected repos
          if [ -n "$selected_repos" ]; then
            selected_repos="${selected_repos}
$selection"
          else
            selected_repos="$selection"
          fi
        fi
      done
    fi
    
    # Clean up temp file
    rm "$repo_list_file"
    
    # Update REPOS array
    REPOS=()
    while IFS= read -r repo; do
      if [ -n "$repo" ]; then
        REPOS+=("$repo")
      fi
    done <<< "$selected_repos"
    
    echo "Selected repositories:"
    if [ ${#REPOS[@]} -eq 0 ]; then
      echo "  (No repositories selected)"
    else
      for repo in "${REPOS[@]}"; do
        echo "  - $repo"
      done
    fi
  fi
  
  # Set remote names
  REMOTE_NAMES=("upstream" "origin")
  
  # Save configuration
  echo "Saving configuration..."
  if save_config; then
    log_success "Configuration completed successfully!"
    echo "You can now use the tool with your new configuration."
    echo "Run '$0 --help' to see available options."
  else
    log_error "Failed to save configuration."
    return 1
  fi
  
  return 0
}

# Main function to sync all repositories
# Arguments:
#   All command line arguments as $@
# Returns:
#   0 on success, 1 if any repo failed
sync_all() {
  # Initialize result tracking variables
  successful=0
  failed=0
  skipped=0
  successful_repos=()
  failed_repos=()
  skipped_repos=()
  
  # Parse command line arguments
  parse_arguments "$@"
  
  # Apply exclusions to repo list
  apply_exclusions
  
  print_separator "Repo Sync Tool"
  log_info "Version 1.0.0 - Starting synchronization"
  
  print_separator "Sync Operation Started"
  log_info "Repositories to sync: ${#repos[@]}"
  
  # Display the repositories to be synced
  for repo in "${repos[@]}"; do
    repo_name=$(get_repo_name "$repo")
    echo "  - $repo_name"
  done
  
  start_time=$(date +%s)
  
  print_separator "Starting sync operations"
  
  # Process each repository
  for repo in "${repos[@]}"; do
    # Convert repo name to full path if it's not already a path
    repo_path=$(get_repo_full_path "$repo")
    repo_name=$(get_repo_name "$repo_path")
    
    if [ ! -d "$repo_path" ]; then
      echo -e "\n${BLUE}[$((successful+failed+skipped+1))/${#repos[@]}] ${RED}✗ $repo_name${NC}"
      log_error "Directory not found: $repo_path"
      ((failed++))
      failed_repos+=("$repo_name: Directory not found")
      continue
    fi
    
    echo -e "\n${BLUE}[$((successful+failed+skipped+1))/${#repos[@]}] ▶ $repo_name${NC}"
    sync_repo "$repo_path" "$force_master" "$sync_mode" "$verbosity"
    result=$?
    
    if [ $result -eq $STATUS_SUCCESS ]; then
      # Get the executed scripts if available
      local script_status=""
      if [ -n "${EXECUTED_SCRIPTS:-}" ]; then
        script_status=" (Scripts: ${EXECUTED_SCRIPTS})"
        unset EXECUTED_SCRIPTS
      fi
      
      echo -e "${GREEN}✓ $repo_name - Successfully synced${NC}${script_status}"
      ((successful++))
      successful_repos+=("$repo_name${script_status}")
    elif [ $result -eq $STATUS_ERROR ]; then
      echo -e "${RED}✗ $repo_name - Sync failed${NC}"
      ((failed++))
      failed_repos+=("$repo_name: Sync operation failed")
    else
      echo -e "${YELLOW}○ $repo_name - Sync skipped${NC}"
      ((skipped++))
      skipped_repos+=("$repo_name: Skipped")
    fi
  done
  
  end_time=$(date +%s)
  
  # Display summary
  display_summary "$start_time" "$end_time"
  
  # Exit with non-zero status if any repos failed
  if [ $failed -gt 0 ]; then
    exit 1
  fi
  
  exit 0
}

# Main command
if [ "$0" = "$BASH_SOURCE" ]; then
  sync_all "$@"
fi