#!/bin/bash

# Tests for main script functionality
# Tests basic argument parsing and help functionality

# Test help functionality
test_help_command() {
  # Test that help command works and exits with success
  local help_output
  help_output=$("$SCRIPT_DIR/repo-sync.sh" --help 2>&1)
  local exit_code=$?
  
  assert_equals "0" "$exit_code" "Help command exits with status 0"
  
  # Check that help output contains expected strings
  if echo "$help_output" | grep -q "Usage:"; then
    assert_equals "true" "true" "Help output contains Usage section"
  else
    assert_equals "true" "false" "Help output contains Usage section"
  fi
  
  if echo "$help_output" | grep -q "Options:"; then
    assert_equals "true" "true" "Help output contains Options section"  
  else
    assert_equals "true" "false" "Help output contains Options section"
  fi
}

# Test script structure
test_script_structure() {
  # Test that main script file exists and is executable
  assert_file_exists "$SCRIPT_DIR/repo-sync.sh" "Main script exists"
  
  # Test that library files exist
  assert_file_exists "$SCRIPT_DIR/lib/config.sh" "Config library exists"
  assert_file_exists "$SCRIPT_DIR/lib/logger.sh" "Logger library exists" 
  assert_file_exists "$SCRIPT_DIR/lib/repo-operations.sh" "Repo operations library exists"
  
  # Test script is executable
  if [ -x "$SCRIPT_DIR/repo-sync.sh" ]; then
    assert_equals "true" "true" "Main script is executable"
  else
    assert_equals "true" "false" "Main script is executable"
  fi
}

# Test that the script loads properly without errors
test_script_loading() {
  # Test script can be loaded without immediate errors by checking syntax
  local syntax_check
  syntax_check=$(bash -n "$SCRIPT_DIR/repo-sync.sh" 2>&1)
  local syntax_status=$?
  
  assert_equals "0" "$syntax_status" "Main script has valid bash syntax"
  
  # Test library files have valid syntax too
  syntax_check=$(bash -n "$SCRIPT_DIR/lib/config.sh" 2>&1)
  syntax_status=$?
  assert_equals "0" "$syntax_status" "Config library has valid bash syntax"
  
  syntax_check=$(bash -n "$SCRIPT_DIR/lib/logger.sh" 2>&1) 
  syntax_status=$?
  assert_equals "0" "$syntax_status" "Logger library has valid bash syntax"
  
  syntax_check=$(bash -n "$SCRIPT_DIR/lib/repo-operations.sh" 2>&1)
  syntax_status=$?
  assert_equals "0" "$syntax_status" "Repo operations library has valid bash syntax"
}

# Run the tests
test_help_command
test_script_structure
test_script_loading