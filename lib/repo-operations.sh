#!/bin/bash

# Repository operations module
# Provides functions for working with git repositories

# Load dependencies
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# RDS server status flags
RDS_CHECKED=""
RDS_FAILED=""

# Verify if the directory is a git repository
# Arguments:
#   $1 - Path to repository
# Returns:
#   0 if it's a git repository, 1 otherwise
verify_git_repo() {
  local repo_path="$1"
  
  if [ ! -d "$repo_path/.git" ]; then
    log_error "This directory is not a git repository: $repo_path"
    return 1
  fi
  
  return 0
}

# Get the current branch of a repository
# Arguments:
#   $1 - Path to repository
# Returns:
#   Current branch name or empty string if in detached HEAD state
get_current_branch() {
  local repo_path="$1"
  local current_branch
  
  cd "$repo_path" || return 1
  current_branch=$(git branch --show-current)
  
  if [ -z "$current_branch" ]; then
    log_warning "In detached HEAD state: $repo_path"
    return 1
  fi
  
  echo "$current_branch"
}

# Determine the appropriate remote to use
# Arguments:
#   None (uses git from current directory)
# Returns:
#   Name of the remote to use
determine_target_remote() {
  # Try each remote in order of preference
  for remote in "${REMOTE_NAMES[@]}"; do
    if git remote | grep -q "$remote"; then
      echo "$remote"
      return 0
    fi
  done
  
  # Default to origin if no preferred remote is found
  echo "origin"
}

# Check if remote server is reachable
# Arguments:
#   None
# Returns:
#   0 if remote server is reachable, 1 otherwise
check_remote_server() {
  # Check if SSH connection is configured
  if [ -z "$SSH_CONNECTION" ]; then
    log_error "SSH connection is not configured. Please run './$(basename "$0") --init' to configure it."
    return 1
  fi
  
  # Skip if we've already checked
  if [ -n "$RDS_CHECKED" ]; then
    if [ -n "$RDS_FAILED" ]; then
      log_warning "Remote server check previously failed, skipping connection attempt"
      return 1
    fi
    return 0
  fi
  
  log_info "Checking if remote server ($SSH_CONNECTION) is online..."
  
  local attempt=1
  local success=false
  
  while [ $attempt -le $MAX_CONNECT_ATTEMPTS ] && [ "$success" = false ]; do
    log_info "Attempt $attempt of $MAX_CONNECT_ATTEMPTS to connect to remote server..."
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_CONNECTION" exit 2>/dev/null; then
      log_success "Remote server ($SSH_CONNECTION) is online"
      export RDS_CHECKED=true
      return 0
    else
      if [ $attempt -lt $MAX_CONNECT_ATTEMPTS ]; then
        log_warning "Remote server not reachable, retrying in $CONNECT_RETRY_WAIT seconds..."
        sleep $CONNECT_RETRY_WAIT
      fi
      ((attempt++))
    fi
  done
  
  log_error "Remote server is not reachable after $MAX_CONNECT_ATTEMPTS attempts"
  export RDS_FAILED=true
  return 1
}

# Run post-pull scripts specified in configuration
# Arguments:
#   $1 - Path to repository
# Returns:
#   0 on success, 1 on failure
run_post_pull_scripts() {
  local repo_path="$1"
  local script_executed=false
  # Reset the executed scripts list for this repo
  executed_scripts=""
  
  cd "$repo_path" || return 1
  
  # Check if there are any scripts to run
  if [ ${#RUN_AFTER_PULL[@]} -eq 0 ]; then
    log_info "No post-pull scripts configured. Skipping."
    return 0
  fi
  
  # Check remote server access
  if ! check_remote_server; then
    return 1
  fi
  
  # Process each script group (alternatives separated by commas)
  for script_group in "${RUN_AFTER_PULL[@]}"; do
    log_info "Processing script group: $script_group"
    
    # Parse script alternatives - split comma-separated values
    IFS=',' read -ra script_alternatives <<< "$script_group"
    local alternative_found=false
    
    # Try each alternative until one works
    for script_name in "${script_alternatives[@]}"; do
      # Trim leading/trailing whitespace
      script_name=$(echo "$script_name" | xargs)
      local script_path="./${script_name}"
      
      log_info "Checking for script: $script_name"
      
      # Skip if script doesn't exist
      if [ ! -f "$script_path" ] || [ ! -x "$script_path" ]; then
        log_info "Script '$script_name' not found or not executable. Trying next alternative."
        continue
      fi
      
      # We found an alternative that exists
      alternative_found=true
      script_executed=true
      log_info "Executing $script_name script..."
      
      # Record executed script
      if [ -z "$executed_scripts" ]; then
        executed_scripts="$script_name"
      else
        executed_scripts="$executed_scripts, $script_name"
      fi
      
      # Execute the script and capture output
      output=$($script_path 2>&1)
      local script_status=$?
      
      if [ $script_status -eq 0 ]; then
        log_success "$script_name executed successfully"
        
        # Show output based on verbosity level
        local output_lines=$(echo "$output" | wc -l)
        if [ ${verbosity:-0} -eq 0 ]; then
          # No output in default mode
          :
        elif [ ${verbosity:-0} -eq 1 ] && [ $output_lines -gt 0 ]; then
          # Verbose mode: show truncated output
          if [ $output_lines -gt 10 ]; then
            echo "Script output (truncated):"
            echo "$output" | head -n 5
            echo "..."
            echo "$output" | tail -n 5
          else
            echo "Script output:"
            echo "$output"
          fi
        elif [ ${verbosity:-0} -ge 2 ] && [ $output_lines -gt 0 ]; then
          # Very verbose mode: show full output
          echo "Script output (full):"
          echo "$output"
        fi
        
        # We've successfully executed an alternative, so move to the next group
        break
      else
        log_error "$script_name failed with status: $script_status"
        # Always show error output, but adjust based on verbosity
        if [ ${verbosity:-0} -ge 2 ]; then
          # Show full error output in very verbose mode
          log_error "Error output (full):"
          echo "$output"
        else
          # Show truncated or summary in other modes
          if [ $(echo "$output" | wc -l) -gt 5 ]; then
            log_error "Error output (truncated):"
            echo "$output" | head -n 5
            echo "..."
          else
            log_error "Error output:"
            echo "$output"
          fi
        fi
        # On error, we stop completely
        return 1
      fi
    done
    
    # If no alternative was found for this group
    if [ "$alternative_found" = false ]; then
      log_warning "No valid alternative found for script group: $script_group"
    fi
  done
  
  # If we get here and no scripts were executed
  if [ "$script_executed" = false ]; then
    log_warning "None of the configured scripts were found or executable. Nothing was executed."
    executed_scripts="(none found)"
  fi
  
  # Return the list of executed scripts for summary
  export EXECUTED_SCRIPTS="$executed_scripts"
  return 0
}

# Check for unpushed commits
# Arguments:
#   $1 - Path to repository
#   $2 - Current branch
# Returns:
#   0 if no unpushed commits, 1 if unpushed commits exist
check_unpushed_commits() {
  local repo_path="$1"
  local current_branch="$2"
  
  cd "$repo_path" || return 1
  
  local local_commit
  local_commit=$(git rev-parse @)
  
  # Determine target remote
  local target_remote
  target_remote=$(determine_target_remote)
  log_info "Using remote: $target_remote"
  
  local remote_branch="$target_remote/$current_branch"
  
  if git rev-parse --verify $remote_branch >/dev/null 2>&1; then
    local remote_commit
    remote_commit=$(git rev-parse $remote_branch)
    
    if [ "$local_commit" != "$remote_commit" ]; then
      # Check if there are unpushed commits
      local unpushed
      unpushed=$(git log $remote_branch..HEAD --oneline)
      
      if [ -n "$unpushed" ]; then
        log_warning "There are unpushed commits, not touching: $repo_path (branch: $current_branch)"
        log_info "Unpushed commits:"
        echo "${unpushed}" | sed 's/^/  /'
        return 1
      fi
    fi
  else
    log_warning "Remote branch not found: $remote_branch. This is probably a branch that hasn't been pushed yet."
    return 1
  fi
  
  return 0
}

# Stash local changes
# Arguments:
#   $1 - Path to repository
# Returns:
#   0 if stash created or no changes, 1 on failure
#   Sets the global variable has_changes=true if stash was created
stash_local_changes() {
  local repo_path="$1"
  
  cd "$repo_path" || return 1
  
  local_changes=$(git status --porcelain)
  
  if [ -n "$local_changes" ]; then
    log_info "Local changes found. Stashing..."
    echo "${local_changes}" | sed 's/^/  /'
    
    git stash push -m "Auto stash by sync script $(date)"
    if [ $? -ne 0 ]; then
      log_error "Failed to stash changes"
      return 1
    fi
    
    has_changes=true
    log_success "Changes stashed"
  else
    log_info "No local changes"
    has_changes=false
  fi
  
  return 0
}

# Restore stashed changes
# Arguments:
#   $1 - Path to repository
# Returns:
#   0 on success, 1 on failure
restore_stash() {
  local repo_path="$1"
  
  cd "$repo_path" || return 1
  
  if [ "$has_changes" = true ]; then
    log_info "Applying stashed changes..."
    
    stash_result=$(git stash pop 2>&1)
    stash_status=$?
    
    if [ $stash_status -ne 0 ]; then
      log_error "Stash apply failed! There might be conflicts."
      log_error "Git output: $stash_result"
      log_warning "You need to manually resolve conflicts and run 'git stash apply'."
      return 1
    fi
    
    log_success "Stashed changes successfully restored"
  fi
  
  return 0
}

# Switch to target branch
# Arguments:
#   $1 - Path to repository
#   $2 - Target branch
#   $3 - Current branch
# Returns:
#   0 on success, 1 on failure
switch_to_branch() {
  local repo_path="$1"
  local target_branch="$2"
  local current_branch="$3"
  local target_remote=""
  
  cd "$repo_path" || return 1
  
  # If already on target branch, nothing to do
  if [ "$current_branch" = "$target_branch" ]; then
    log_info "Already on target branch: $target_branch"
    return 0
  fi
  
  log_info "Switching from $current_branch to $target_branch..."
  
  # Determine target remote
  target_remote=$(determine_target_remote)
  
  # Checkout to target branch
  git checkout "$target_remote/$target_branch" -B "$target_branch" 2>/dev/null
  checkout_status=$?
  
  if [ $checkout_status -ne 0 ]; then
    log_error "Could not switch branch!"
    log_error "Git checkout error. Check if you have uncommitted changes."
    return 1
  fi
  
  log_success "Switched to $target_branch branch"
  return 0
}

# Pull latest changes
# Arguments:
#   $1 - Path to repository
#   $2 - Target branch
# Returns:
#   0 on success, 1 on failure
pull_latest_changes() {
  local repo_path="$1"
  local target_branch="$2"
  
  cd "$repo_path" || return 1
  
  # Determine target remote
  local target_remote
  target_remote=$(determine_target_remote)
  
  log_info "Pulling latest changes from $target_remote/$target_branch (with rebase)..."
  
  pull_result=$(git pull --rebase $target_remote $target_branch 2>&1)
  pull_status=$?
  
  if [ $pull_status -ne 0 ]; then
    log_error "Pull operation failed!"
    log_error "Git output: $pull_result"
    return 1
  else
    if [[ "$pull_result" == *"Already up to date"* ]]; then
      log_info "Repository already up to date, no changes pulled"
    else
      log_success "Successfully pulled latest changes"
      echo "${pull_result}" | grep -E "^ " | sed 's/^/  /'
    fi
  fi
  
  return 0
}

# Return to original branch
# Arguments:
#   $1 - Path to repository
#   $2 - Original branch
#   $3 - Current branch
# Returns:
#   0 on success, 1 on failure
return_to_original_branch() {
  local repo_path="$1"
  local original_branch="$2"
  local current_branch="$3"
  
  cd "$repo_path" || return 1
  
  # If already on original branch, nothing to do
  if [ "$current_branch" = "$original_branch" ]; then
    return 0
  fi
  
  log_info "Returning to original branch: $original_branch..."
  
  git checkout $original_branch
  if [ $? -ne 0 ]; then
    log_error "Could not return to original branch!"
    log_error "You are currently on $current_branch branch"
    return 1
  fi
  
  log_success "Successfully returned to $original_branch branch"
  return 0
}

# Show latest commit
# Arguments:
#   $1 - Path to repository
# Returns:
#   0 always (informational only)
show_latest_commit() {
  local repo_path="$1"
  
  cd "$repo_path" || return 1
  
  log_info "Latest commit:"
  latest_commit=$(git log -1 --pretty=format:"  %h - %s (%cr) <%an>" HEAD)
  echo "$latest_commit"
  
  return 0
}

# Main function to sync a repository
# Arguments:
#   $1 - Path to repository
#   $2 - Force switch to master branch flag
#   $3 - Sync mode (true = run post-pull scripts, false = skip post-pull scripts, null/empty = use default behavior)
#   $4 - Verbosity level (0=default, 1=verbose, 2=very verbose)
# Returns:
#   STATUS_SUCCESS (0) on success
#   STATUS_ERROR (1) on error
#   STATUS_SKIPPED (2) if sync was skipped
sync_repo() {
  local repo_path="$1"
  local force_master="$2"
  local sync_mode="$3"
  local verbosity="${4:-0}"  # Default to 0 if not provided
  local repo_name
  repo_name=$(get_repo_name "$repo_path")
  has_changes=false
  
  print_section_header "Syncing Repository: $repo_name"
  log_info "Full path: $repo_path"
  
  # Go to directory
  cd "$repo_path" || { 
    log_error "Cannot access directory: $repo_path"
    return $STATUS_ERROR
  }
  
  # Git repo check
  if ! verify_git_repo "$repo_path"; then
    return $STATUS_ERROR
  fi
  
  # Branch check
  local current_branch
  current_branch=$(get_current_branch "$repo_path")
  if [ $? -ne 0 ]; then
    return $STATUS_ERROR
  fi
  log_info "Current branch: $current_branch"
  
  # Get list of target branches from comma-separated alternatives
  IFS=',' read -ra target_branches <<< "$DEFAULT_BRANCH"
  
  # Determine if we need to switch branches
  local is_on_target_branch=false
  local primary_branch="${target_branches[0]}"  # First branch is primary
  
  # Check if current branch is one of the target branches
  for branch in "${target_branches[@]}"; do
    if [ "$current_branch" = "$branch" ]; then
      is_on_target_branch=true
      log_info "On valid target branch: $branch"
      break
    fi
  done
  
  # Check if we're not on any target branch and force_master is not enabled
  if [ "$is_on_target_branch" = false ] && [ "$force_master" != "true" ]; then
    log_warning "Not on any target branch ($DEFAULT_BRANCH). Current branch: $current_branch"
    log_warning "Skipping operations. Use --force-master to override."
    return $STATUS_SKIPPED
  elif [ "$force_master" = "true" ] && [ "$is_on_target_branch" = false ]; then
    log_info "Force-master enabled. Will checkout to $primary_branch from remote."
    
    # Switch to primary branch
    if ! switch_to_branch "$repo_path" "$primary_branch" "$current_branch"; then
      return $STATUS_ERROR
    fi
    current_branch="$primary_branch"
  fi
  
  # Determine whether to run post-pull scripts
  local should_run_scripts=true  # Default to true - run scripts by default
  
  # If sync_mode is specified, use it
  if [ -n "$sync_mode" ]; then
    should_run_scripts="$sync_mode"
  fi
  
  # Execute post-pull scripts if enabled and sync mode is enabled
  if [ "$should_run_scripts" = "true" ]; then
    log_info "Running post-pull scripts..."
    if run_post_pull_scripts "$repo_path"; then
      log_success "Post-pull scripts completed successfully"
      return $STATUS_SUCCESS
    else
      log_error "Post-pull scripts execution failed"
      return $STATUS_ERROR
    fi
  fi
  
  # Check for unpushed commits
  if ! check_unpushed_commits "$repo_path" "$current_branch"; then
    return $STATUS_SKIPPED
  fi
  
  # Stash local changes
  if ! stash_local_changes "$repo_path"; then
    return $STATUS_ERROR
  fi
  
  # Switch to target branch (if needed)
  if ! switch_to_branch "$repo_path" "$primary_branch" "$current_branch"; then
    # If branch switch failed, try to restore stash and return
    restore_stash "$repo_path"
    return $STATUS_ERROR
  fi
  
  # Pull latest changes
  if ! pull_latest_changes "$repo_path" "$primary_branch"; then
    # If pull failed, try to restore stash and return to original branch
    restore_stash "$repo_path"
    return_to_original_branch "$repo_path" "$current_branch" "$primary_branch"
    return $STATUS_ERROR
  fi
  
  # Restore stash if exists
  if ! restore_stash "$repo_path"; then
    return $STATUS_ERROR
  fi
  
  # Return to original branch (if different)
  if ! return_to_original_branch "$repo_path" "$current_branch" "$primary_branch"; then
    return $STATUS_ERROR
  fi
  
  # Show the latest commit log
  show_latest_commit "$repo_path"
  
  log_success "$repo_name successfully synced with remote"
  return $STATUS_SUCCESS
}