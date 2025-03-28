#!/bin/bash

# Logger module for repository synchronization tool
# Provides standardized logging functions with colored output

# Prevent multiple inclusions
if [ -z "$LOGGER_INCLUDED" ]; then
  LOGGER_INCLUDED=true

  # Color codes
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[0;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color

  # Log level constants
  readonly LOG_LEVEL_INFO=0
  readonly LOG_LEVEL_SUCCESS=1
  readonly LOG_LEVEL_WARNING=2
  readonly LOG_LEVEL_ERROR=3
fi

# Current log level (defaults to INFO)
CURRENT_LOG_LEVEL=${CURRENT_LOG_LEVEL:-$LOG_LEVEL_INFO}

# Print a formatted log message
# Arguments:
#   $1 - Log level [INFO, SUCCESS, WARNING, ERROR]
#   $2 - Log message
#   $3 - Color code (optional)
_log() {
  local level="$1"
  local message="$2"
  local color="${3:-$BLUE}"
  
  echo -e "${color}[${level}]${NC} $message"
}

# Log an informational message
# Arguments:
#   $1 - Message to log
log_info() {
  _log "INFO" "$1" "$BLUE"
}

# Log a success message
# Arguments:
#   $1 - Message to log
log_success() {
  _log "SUCCESS" "$1" "$GREEN"
}

# Log a warning message
# Arguments:
#   $1 - Message to log
log_warning() {
  _log "WARNING" "$1" "$YELLOW"
}

# Log an error message
# Arguments:
#   $1 - Message to log
log_error() {
  _log "ERROR" "$1" "$RED"
}

# Print a section header with a title
# Arguments:
#   $1 - Title of the section
print_section_header() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Print a separator line
# Arguments:
#   $1 - Text to display in the separator
print_separator() {
  echo -e "\n${BLUE}▓▒░ $1 ░▒▓${NC}"
}

# Print a colorized status icon
# Arguments:
#   $1 - Status type (success, failure, skipped)
# Returns:
#   Colorized icon for the given status
print_status_icon() {
  case "$1" in
    "success")
      echo -e "${GREEN}✓${NC}"
      ;;
    "failure")
      echo -e "${RED}✗${NC}"
      ;;
    "skipped")
      echo -e "${YELLOW}○${NC}"
      ;;
    *)
      echo "•"
      ;;
  esac
}

# Format duration in a readable format
# Arguments:
#   $1 - Duration in seconds
# Returns:
#   Formatted duration string (e.g. "2m 30s" or "45s")
format_duration() {
  local duration=$1
  
  if [ $duration -ge 60 ]; then
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    echo "${minutes}m ${seconds}s"
  else
    echo "${duration}s"
  fi
}