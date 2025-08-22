# Repo Sync Tool - GitHub Copilot Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Setup
- Clone the repository: `git clone https://github.com/tekinnnnn/repo-sync-tool.git`
- Change to directory: `cd repo-sync-tool`
- Make scripts executable: `chmod +x repo-sync.sh install.sh`
- Test basic functionality: `./repo-sync.sh --help`

### Installation Methods (All execute in ~1-2 seconds)
- **Local installation**: `./install.sh --local` - Creates `repo-sync-standalone.sh` 
- **Global installation**: `sudo ./install.sh` - Installs to `/usr/local/bin/repo-sync`
- **Test installations work**: `./repo-sync-standalone.sh --help` or `repo-sync --help`

### Linting and Code Quality
- **Validate bash syntax**: `bash -n repo-sync.sh install.sh lib/*.sh`
- **Run shellcheck linting**: `shellcheck repo-sync.sh install.sh lib/*.sh` - Takes ~2 seconds, expect warnings but no errors
- **Always run shellcheck** before committing changes to bash scripts

### Testing and Validation Scenarios
- **Basic help test**: `./repo-sync.sh --help` - Should show usage and options
- **Configuration check**: `./repo-sync.sh` without args - Shows configuration warning and default behavior
- **Test with non-existent repo**: `./repo-sync.sh non-existent-repo` - Should show "Directory not found" error  
- **Test initialization wizard**: `./repo-sync.sh --init` - Starts interactive configuration wizard
- **Dependency check**: `bash --version && git --version` - Verify required versions are available

### Manual Validation Requirements
**ALWAYS test these scenarios after making changes:**
1. **Installation validation**: Run both local and global install, verify help command works
2. **Basic sync test**: Create test git repo and run sync operation
3. **Configuration test**: Run `./repo-sync.sh --init` and complete wizard with test values
4. **Error handling**: Test with invalid repository paths to ensure proper error messages
5. **Complete workflow test**: Run the validation script below

### Complete Validation Script
```bash
#!/bin/bash
# Run this script to validate all functionality works
cd /path/to/repo-sync-tool
echo "=== Validating repo-sync-tool ==="

# Test 1: Syntax validation
echo "Testing syntax..."
bash -n repo-sync.sh install.sh lib/*.sh || exit 1

# Test 2: Help command
echo "Testing help command..."
./repo-sync.sh --help | grep -q "Usage:" || exit 1

# Test 3: Error handling
echo "Testing error handling..."
./repo-sync.sh non-existent-repo 2>&1 | grep -q "Directory not found" || exit 1

# Test 4: Local installation
echo "Testing local install..."
rm -f repo-sync-standalone.sh
./install.sh --local >/dev/null 2>&1
test -x repo-sync-standalone.sh || exit 1
./repo-sync-standalone.sh --help | grep -q "Usage:" || exit 1

# Test 5: Global installation (if you have sudo)
echo "Testing global install..."
sudo ./install.sh >/dev/null 2>&1
which repo-sync >/dev/null || exit 1
repo-sync --help | grep -q "Usage:" || exit 1

echo "SUCCESS: All validations passed!"
```

## Repository Structure
```
repo-sync-tool/
├── repo-sync.sh          # Main script - entry point
├── install.sh            # Installation script for creating standalone/global installs  
├── lib/
│   ├── config.sh         # Configuration constants and defaults
│   ├── logger.sh         # Logging functions with colored output
│   └── repo-operations.sh # Git operations and repository sync logic
├── README.md             # User documentation
├── CLAUDE.md             # Development guide
└── .gitignore            # Excludes generated files like repo-sync-standalone.sh
```

## Requirements and Dependencies
- **Bash**: Version 4 or later (check with `bash --version`)
- **Git**: Any modern version (check with `git --version`) 
- **Operating System**: Linux/macOS/WSL - standard UNIX tools required
- **No build process** - This is a pure bash utility script

## Timing Expectations
- **Script execution**: 0.02-0.08 seconds for typical operations
- **Installation**: 1-2 seconds for local or global install  
- **Shellcheck linting**: ~1.5 seconds for all files
- **Validation script**: ~0.07 seconds total
- **No long-running processes** - All operations complete very quickly
- **NEVER CANCEL operations** - All commands finish in under 2 seconds

## Configuration and Usage
- **Configuration file**: `~/.repo-sync.conf` (created by `--init` wizard)
- **Main usage**: `./repo-sync.sh [OPTIONS] [repo1 repo2 ...]`
- **Key options**: `--init`, `--help`, `--repos=list`, `--exclude=list`, `--sync`/`--no-sync`

## Code Style Guidelines
- **Bash version**: Bash 4+ compatible syntax
- **Formatting**: 2-space indentation, 80-character line limit
- **Functions**: Documented with block comments and @param-style annotations
- **Error handling**: Use return codes (0=success, 1=error, 2=skipped)
- **Logging**: Use logger.sh functions (log_info, log_error, log_success, log_warning)
- **Variables**: Descriptive names, use local scope in functions

## Common Development Tasks
- **Add new functionality**: Modify appropriate module in lib/ directory
- **Change logging**: Edit lib/logger.sh for new log levels or formatting
- **Update configuration**: Modify lib/config.sh for new config options
- **Git operations**: Extend lib/repo-operations.sh for new git functionality

## Validation Checklist
Before committing changes, always:
- [ ] Run `bash -n` syntax check on modified scripts
- [ ] Run `shellcheck` on all modified bash files
- [ ] Test `./repo-sync.sh --help` works
- [ ] Test local installation with `./install.sh --local`
- [ ] Test global installation with `sudo ./install.sh`
- [ ] Verify the installed version works: `repo-sync --help`
- [ ] Test error handling with invalid input
- [ ] Run initialization wizard to ensure it still works

## Key Files Reference
- **Main entry point**: `repo-sync.sh` - Contains CLI parsing and main sync logic
- **Installation**: `install.sh` - Creates standalone or global installations by combining all modules
- **Configuration**: `lib/config.sh` - Default values, constants, config file handling
- **Logging**: `lib/logger.sh` - Colored output functions and verbosity levels
- **Git operations**: `lib/repo-operations.sh` - All git repository manipulation functions

## Expected Command Outputs
```bash
# Help command shows usage
$ ./repo-sync.sh --help
Usage: ./repo-sync.sh [OPTIONS] [repo1 repo2 ...]
Script for syncing git repositories
Options:
...

# Default execution shows configuration warning (expected)
$ ./repo-sync.sh
[WARNING] No configuration file found.
[INFO] Consider running './repo-sync.sh --init' to create a configuration file.
...

# Shellcheck shows warnings but no errors (exit code 1 is expected)
$ shellcheck *.sh lib/*.sh
(shows style warnings, no critical errors)

# Installation creates working global command
$ sudo ./install.sh
[SUCCESS] Installation successful! The repo-sync tool is now available globally.
$ repo-sync --help
Usage: /usr/local/bin/repo-sync [OPTIONS] [repo1 repo2 ...]
```

## Troubleshooting
- **"Command not found"**: Ensure scripts are executable with `chmod +x`
- **Syntax errors**: Run `bash -n filename.sh` to check syntax
- **Global install fails**: Check permissions, may need `sudo`
- **Config wizard hangs**: Use Ctrl+C to exit and restart
- **Git operations fail**: Ensure repository paths are correct and git is installed
- **Shellcheck warnings**: Expected behavior, warnings are acceptable but no errors
- **"Directory not found"**: Verify repository paths exist and are git repositories

## Testing With Real Repositories
```bash
# Create a test repository for validation
mkdir -p /tmp/test-repo && cd /tmp/test-repo
git init && git config user.email "test@example.com" && git config user.name "Test User"
echo "test" > README.md && git add . && git commit -m "initial commit"

# Test sync operation (will skip due to no remote)
cd /path/to/repo-sync-tool
./repo-sync.sh /tmp/test-repo  # Should show "Remote branch not found" and skip

# Test with multiple repos
./repo-sync.sh /tmp/test-repo /path/to/another/repo

# Test exclusion
./repo-sync.sh --exclude=test-repo repo1 repo2 test-repo  # test-repo should be excluded
```

## Do Not
- Add heavy dependencies - keep it as pure bash
- Modify the modular structure in lib/ directory
- Remove the colored output logging system
- Change the configuration file format without updating the wizard
- Cancel any operations (they all complete in under 2 seconds)

## Quick Reference - Most Common Operations
```bash
# Basic workflow for development
./repo-sync.sh --help                    # Always works, shows usage
bash -n *.sh lib/*.sh                    # Syntax check (always passes)
shellcheck *.sh lib/*.sh                 # Linting (shows warnings, that's OK)  
./install.sh --local                     # Creates repo-sync-standalone.sh
sudo ./install.sh                        # Installs to /usr/local/bin/repo-sync
./repo-sync.sh --init                    # Configuration wizard
./repo-sync.sh path/to/repo              # Sync single repository
./repo-sync.sh --exclude=repo1 repo1 repo2  # Sync with exclusions

# Expected results:
# - All commands complete in under 2 seconds
# - Shellcheck shows warnings (acceptable) 
# - Help/usage always displays properly
# - Installations create working executables
# - Error messages are clear and helpful
```