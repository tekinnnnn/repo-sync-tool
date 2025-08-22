#!/bin/bash

# Basic test runner for repo-sync-tool
# Simple bash testing framework for validating core functionality

# Colors for output (check if already defined to avoid readonly variable errors)
if [ -z "$RED" ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
fi

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="${3:-assertion}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $test_name"
    echo -e "  Expected: '$expected'"
    echo -e "  Actual:   '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_not_empty() {
  local value="$1"
  local test_name="${2:-not empty assertion}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [ -n "$value" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $test_name"
    echo -e "  Expected non-empty value, got empty"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_exists() {
  local file_path="$1"
  local test_name="${2:-file exists assertion}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [ -f "$file_path" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $test_name"
    echo -e "  File not found: $file_path"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Print test summary
print_summary() {
  echo
  echo -e "${BLUE}=== Test Summary ===${NC}"
  echo -e "Tests run: $TESTS_RUN"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  
  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    return 0
  else
    echo -e "\n${RED}Some tests failed!${NC}"
    return 1
  fi
}

# Main test runner
main() {
  echo -e "${BLUE}=== Repo Sync Tool Tests ===${NC}"
  echo
  
  # Get script directory
  local test_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local project_root="$(dirname "$test_dir")"
  
  # Source the main libraries for testing
  export SCRIPT_DIR="$project_root"
  
  # Run test files
  for test_file in "$test_dir"/test_*.sh; do
    if [ -f "$test_file" ] && [ "$test_file" != "$0" ]; then
      echo -e "${YELLOW}Running $(basename "$test_file")...${NC}"
      source "$test_file"
      echo
    fi
  done
  
  # Print summary and exit with appropriate code
  print_summary
}

# Run main if this script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi