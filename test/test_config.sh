#!/bin/bash

# Tests for configuration functionality
# Tests the lib/config.sh module

# Source dependencies
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/config.sh"

# Test loading default configuration
test_config_defaults() {
  # Use a temporary config file location to avoid interfering with existing config
  local test_config="/tmp/test_repo_sync_config_$$"
  
  # Ensure no config file exists
  rm -f "$test_config"
  
  # Load config (should set defaults) 
  # We'll test the set_default_config function directly
  set_default_config
  
  # Test default values are set
  assert_not_empty "$SCRIPT_DIR" "SCRIPT_DIR is set"
  assert_not_empty "$DEFAULT_REPO_BASE_PATH" "DEFAULT_REPO_BASE_PATH is set"
  assert_equals "upstream" "${DEFAULT_REMOTE_NAMES[0]}" "First default remote name is upstream"
  assert_equals "origin" "${DEFAULT_REMOTE_NAMES[1]}" "Second default remote name is origin"
  assert_equals "master,main" "$DEFAULT_TARGET_BRANCH" "Default target branch contains master,main"
  
  # Cleanup
  rm -f "$test_config"
}

# Test configuration file structure
test_config_constants() {
  # Test that constants are properly defined
  assert_equals "0" "$STATUS_SUCCESS" "STATUS_SUCCESS is 0"
  assert_equals "1" "$STATUS_ERROR" "STATUS_ERROR is 1" 
  assert_equals "2" "$STATUS_SKIPPED" "STATUS_SKIPPED is 2"
  
  # Test that default values are reasonable
  assert_equals "3" "$DEFAULT_MAX_CONNECT_ATTEMPTS" "Default max connect attempts is 3"
  assert_equals "10" "$DEFAULT_CONNECT_RETRY_WAIT" "Default connect retry wait is 10"
}

# Run the tests
test_config_defaults
test_config_constants