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

# Global verbosity level (0=default, 1=verbose, 2=very verbose)
GLOBAL_VERBOSITY=${GLOBAL_VERBOSITY:-0}

# Verbosity levels definitions:
# 0 (default): Only critical information, status updates, errors, warnings
# 1 (-v): Technical operations progress, repo details, operation summaries
# 2 (-vv): Full debug information, git command outputs, detailed progress info

# Print a formatted log message with verbosity check
# Arguments:
#   $1 - Log level [INFO, SUCCESS, WARNING, ERROR]
#   $2 - Log message
#   $3 - Color code (optional)
#   $4 - Minimum verbosity level required (optional, default 0)
_log() {
  local level="$1"
  local message="$2"
  local color="${3:-$BLUE}"
  local required_verbosity="${4:-0}"
  
  # Only print if global verbosity is >= required verbosity
  # ERROR and WARNING messages are always shown regardless of verbosity
  # SUCCESS messages are always shown regardless of verbosity
  if [[ "$level" == "ERROR" || "$level" == "WARNING" || "$level" == "SUCCESS" || $GLOBAL_VERBOSITY -ge $required_verbosity ]]; then
    echo -e "${color}[${level}]${NC} $message"
  fi
}

# Log an informational message
# Arguments:
#   $1 - Message to log
#   $2 - Minimum verbosity level required (optional, default 0)
log_info() {
  local message="$1"
  local required_verbosity="${2:-0}"
  _log "INFO" "$message" "$BLUE" $required_verbosity
}

# Log a success message
# Arguments:
#   $1 - Message to log
#   $2 - Minimum verbosity level required (optional, default 0)
log_success() {
  local message="$1"
  local required_verbosity="${2:-0}"
  _log "SUCCESS" "$message" "$GREEN" $required_verbosity
}

# Log a warning message
# Arguments:
#   $1 - Message to log
#   $2 - Minimum verbosity level required (optional, default 0)
log_warning() {
  local message="$1"
  local required_verbosity="${2:-0}"
  _log "WARNING" "$message" "$YELLOW" $required_verbosity
}

# Log an error message
# Arguments:
#   $1 - Message to log
#   $2 - Minimum verbosity level required (optional, default 0)
log_error() {
  local message="$1"
  local required_verbosity="${2:-0}"
  _log "ERROR" "$message" "$RED" $required_verbosity
}

# Print a section header with a title
# Arguments:
#   $1 - Title of the section
#   $2 - Minimum verbosity level required (optional, default 0)
print_section_header() {
  local title="$1"
  local required_verbosity="${2:-0}"
  
  # Only print if global verbosity is >= required verbosity
  if [ $GLOBAL_VERBOSITY -ge $required_verbosity ]; then
    echo -e "\n${BLUE}=== $title ===${NC}"
  fi
}

# Print a separator line
# Arguments:
#   $1 - Text to display in the separator
#   $2 - Minimum verbosity level required (optional, default 0)
print_separator() {
  local text="$1"
  local required_verbosity="${2:-0}"
  
  # Only print if global verbosity is >= required verbosity
  if [ $GLOBAL_VERBOSITY -ge $required_verbosity ]; then
    echo -e "\n${BLUE}▓▒░ $text ░▒▓${NC}"
  fi
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