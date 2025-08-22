#!/bin/bash

# Tests for the test framework itself
# Validates that the test framework functions work correctly

# Test assertion functions work correctly
test_assertion_functions() {
  # Test basic functionality without trying to track counters recursively
  # (since the tracking functions themselves add to the counters)
  
  # Test assert_equals with matching values
  assert_equals "test" "test" "Basic equality test"
  
  # Test assert_not_empty with non-empty value
  assert_not_empty "not empty" "Non-empty string test"
  
  # Test assert_file_exists with existing file
  assert_file_exists "$SCRIPT_DIR/repo-sync.sh" "Existing file test"
  
  # Test color variables are available (indicating framework loaded correctly)
  assert_not_empty "$GREEN" "Test framework colors loaded"
  assert_not_empty "$RED" "Test framework colors loaded (RED)"
}

# Test that test framework has the expected functions
test_framework_functions_exist() {
  # Check that our test functions are actually defined
  if declare -f assert_equals >/dev/null 2>&1; then
    assert_equals "true" "true" "assert_equals function exists"
  else
    assert_equals "true" "false" "assert_equals function exists"
  fi
  
  if declare -f assert_not_empty >/dev/null 2>&1; then
    assert_equals "true" "true" "assert_not_empty function exists"
  else
    assert_equals "true" "false" "assert_not_empty function exists"
  fi
  
  if declare -f assert_file_exists >/dev/null 2>&1; then
    assert_equals "true" "true" "assert_file_exists function exists"
  else
    assert_equals "true" "false" "assert_file_exists function exists"
  fi
  
  if declare -f print_summary >/dev/null 2>&1; then
    assert_equals "true" "true" "print_summary function exists"
  else
    assert_equals "true" "false" "print_summary function exists"
  fi
}

# Run the tests
test_framework_functions_exist
test_assertion_functions