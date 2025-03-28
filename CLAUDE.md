# CLAUDE.md - Repo Sync Tool Guide

## Commands
- Run the script: `./repo-sync.sh [OPTIONS] [repo1 repo2 ...]`
- Run initialization wizard: `./repo-sync.sh --init`
- Make script executable: `chmod +x repo-sync.sh`
- No explicit test commands exist - this is a bash utility script

## Code Style Guidelines
- **Shell**: Bash 4+ compatible
- **Formatting**: 2-space indentation, 80-char line limit
- **Documentation**: All functions documented with block comments
- **Functions**: Use descriptive names; arguments documented with @param-style comments
- **Error Handling**: Use return codes (0=success, 1=error, 2=skipped)
- **Variables**: Use descriptive names, local scope where possible
- **Logging**: Use logger.sh functions for consistent output (log_info, log_error, etc.)
- **Constants**: Use uppercase for constants/readonly variables 
- **Modularity**: Code organized in modules (config.sh, logger.sh, repo-operations.sh)
- **Validation**: Check inputs and command results, fail gracefully

## Project Structure
- `repo-sync.sh`: Main script 
- `lib/config.sh`: Configuration module
- `lib/logger.sh`: Logging utilities
- `lib/repo-operations.sh`: Git operations
- `repo-sync.conf`: User configuration file (generated during init)