#!/bin/bash

# Repository Sync Tool Installer
# This script creates a standalone repo-sync script that can be used anywhere

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check for required tools
check_requirements() {
  if ! command -v cat &> /dev/null; then
    log_error "The 'cat' command is required but not found."
    exit 1
  fi
}

# Create combined script
create_standalone_script() {
  local output_file="$1"
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  log_info "Creating standalone script at: $output_file"
  
  # Create file and add shebang
  echo '#!/bin/bash' > "$output_file"
  echo '' >> "$output_file"
  echo '# Repository Sync Tool - Combined Standalone Version' >> "$output_file"
  echo '# Generated on: '"$(date)" >> "$output_file"
  echo '' >> "$output_file"
  
  # Add logger module
  echo '# ====== Begin logger.sh ======' >> "$output_file"
  cat "$script_dir/lib/logger.sh" | grep -v "#!/bin/bash" >> "$output_file"
  echo '' >> "$output_file"
  echo '# ====== End logger.sh ======' >> "$output_file"
  echo '' >> "$output_file"
  
  # Add config module
  echo '# ====== Begin config.sh ======' >> "$output_file"
  cat "$script_dir/lib/config.sh" | grep -v "#!/bin/bash" | grep -v 'SCRIPT_DIR=' | grep -v 'source' >> "$output_file"
  echo '' >> "$output_file"
  echo '# ====== End config.sh ======' >> "$output_file"
  echo '' >> "$output_file"
  
  # Fix script directory path
  sed -i '' 's|readonly CONFIG_FILE="${SCRIPT_DIR}/repo-sync.conf"|readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\nreadonly CONFIG_FILE="${SCRIPT_DIR}/repo-sync.conf"|g' "$output_file"
  
  # Add repo operations module
  echo '# ====== Begin repo-operations.sh ======' >> "$output_file"
  cat "$script_dir/lib/repo-operations.sh" | grep -v "#!/bin/bash" | grep -v 'source' >> "$output_file"
  echo '' >> "$output_file"
  echo '# ====== End repo-operations.sh ======' >> "$output_file"
  echo '' >> "$output_file"
  
  # Add main script
  echo '# ====== Begin repo-sync.sh ======' >> "$output_file"
  cat "$script_dir/repo-sync.sh" | grep -v "#!/bin/bash" | grep -v 'SCRIPT_DIR=' | grep -v 'source' >> "$output_file"
  echo '' >> "$output_file"
  echo '# ====== End repo-sync.sh ======' >> "$output_file"
  
  # Make executable
  chmod +x "$output_file"
  
  log_success "Standalone script created successfully at: $output_file"
  log_info "You can now move this script anywhere and run it with './$(basename "$output_file")'"
}

# Main
check_requirements

if [ "$#" -eq 0 ]; then
  output_file="repo-sync-standalone.sh"
else
  output_file="$1"
fi

create_standalone_script "$output_file"

log_info "To get started, run the following command:"
echo -e "${GREEN}   ./$output_file --init${NC}"