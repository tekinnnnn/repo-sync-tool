#!/bin/bash

# Tests for logging functionality  
# Tests the lib/logger.sh module

# Test logger color constants and basic functions
test_logger_constants() {
  # Source logger to get color constants
  source "$SCRIPT_DIR/lib/logger.sh"
  
  # Test that color constants are defined
  assert_not_empty "$RED" "RED color constant is defined"
  assert_not_empty "$GREEN" "GREEN color constant is defined" 
  assert_not_empty "$YELLOW" "YELLOW color constant is defined"
  assert_not_empty "$BLUE" "BLUE color constant is defined"
  assert_not_empty "$NC" "NC (no color) constant is defined"
}

# Test status icon function
test_status_icons() {
  source "$SCRIPT_DIR/lib/logger.sh"
  
  # Test status icon function returns expected values
  local success_icon
  success_icon=$(print_status_icon "success")
  assert_not_empty "$success_icon" "Success icon is not empty"
  
  local failure_icon
  failure_icon=$(print_status_icon "failure")
  assert_not_empty "$failure_icon" "Failure icon is not empty"
  
  local skipped_icon
  skipped_icon=$(print_status_icon "skipped")
  assert_not_empty "$skipped_icon" "Skipped icon is not empty"
  
  local unknown_icon
  unknown_icon=$(print_status_icon "unknown")
  assert_equals "•" "$unknown_icon" "Unknown status returns default bullet"
}

# Test duration formatting
test_duration_formatting() {
  source "$SCRIPT_DIR/lib/logger.sh"
  
  # Test various duration formats
  local short_duration
  short_duration=$(format_duration 30)
  assert_equals "30s" "$short_duration" "Short duration formats correctly"
  
  local long_duration  
  long_duration=$(format_duration 90)
  assert_equals "1m 30s" "$long_duration" "Long duration formats correctly"
  
  local zero_duration
  zero_duration=$(format_duration 0)
  assert_equals "0s" "$zero_duration" "Zero duration formats correctly"
}

# Run the tests
test_logger_constants
test_status_icons  
test_duration_formatting