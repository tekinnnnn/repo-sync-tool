# Repo Sync Tool

A tool for synchronizing multiple git repositories at once.

## Features

- Synchronize multiple git repositories with a single command
- Automatic checkout to master branch
- Automatically stash and restore local changes
- Progress tracking and summary report
- Custom repository lists and exclusion options
- Easy remote server synchronization via SSH connection
- Configuration wizard for easy setup
- Automatic git repository discovery and selection
- Configurable sync behavior

## Installation

### Option 1: Quick Install (Recommended)

Install globally with a single command:

```bash
# Download and run the installer
curl -s https://raw.githubusercontent.com/tekinnnnn/repo-sync-tool/main/install.sh | bash

# Run the initialization wizard
repo-sync --init
```

### Option 2: Manual Install

You can also download and use the tool manually:

```bash
# Clone the repository
git clone https://github.com/tekinnnnn/repo-sync-tool.git
cd repo-sync-tool

# Run the installer
./install.sh

# Run the initialization wizard
repo-sync --init
```

### Option 3: Local Install

If you prefer not to install globally:

```bash
# Clone the repository
git clone https://github.com/tekinnnnn/repo-sync-tool.git
cd repo-sync-tool

# Create a local standalone script
./install.sh --local

# Run the initialization wizard
./repo-sync-standalone.sh --init
```

## Requirements

- Bash 4 or later
- Git

## Usage

```bash
./repo-sync.sh [OPTIONS] [repo1 repo2 ...]
```

### Options

- `--repos=REPO1,REPO2,...`: Comma-separated list of repositories to sync
- `--exclude=REPO1,REPO2,...`: Comma-separated list of repositories to exclude from sync
- `--force-master`: Force checkout to master branch even if currently on another branch
- `--no-sync`: Skip running post-pull scripts, only perform git operations
- `--sync`: Run post-pull scripts after git operations
- `--init`: Run the configuration wizard
- `-v, --verbose`: Show truncated script output (first and last 5 lines)
- `-vv, --very-verbose`: Show full script output
- `--help`: Display help message and exit

### Examples

```bash
./repo-sync.sh                                   # Sync all default repositories
./repo-sync.sh --exclude=backend,api             # Sync all default repositories except backend and api
./repo-sync.sh --repos=Jotform3,frontend,backend # Only sync the specified repositories
./repo-sync.sh Jotform3 frontend                 # Only sync the specified repositories (alternative syntax)
./repo-sync.sh --init                            # Run the configuration wizard
./repo-sync.sh --sync                            # Force run post-pull scripts
./repo-sync.sh --no-sync                         # Skip post-pull scripts
./repo-sync.sh -v                                 # Show truncated script output
./repo-sync.sh -vv                                # Show full script output
```

## Configuration

The configuration is stored in the `~/.repo-sync.conf` file in your home directory, and includes the following options:

- `REPO_BASE_PATH`: Base directory where your repositories are located
- `REPOSITORIES`: List of repositories to sync by default (comma-separated)
- `REMOTE_NAMES`: Git remote names in order of preference (comma-separated)
- `DEFAULT_BRANCH`: Branch names to sync with (comma-separated alternatives, e.g., "master,main"). Will try each branch in order.
- `SSH_CONNECTION`: SSH connection string for remote server (e.g., "rds" or "user@server")
- `RUN_AFTER_PULL`: List of scripts to run after pulling from remote. Format: space-separated groups with comma-separated alternatives within groups (e.g., "sync,syncAll fire_webhook"). Leave empty to disable running scripts after pull
- `MAX_CONNECT_ATTEMPTS`: Maximum number of connection attempts to remote server
- `CONNECT_RETRY_WAIT`: Seconds to wait between connection attempts

This configuration can be easily set up using the configuration wizard by running `repo-sync --init` after installation.

## Usage Examples

After installation, you can use the tool with the following commands:

```bash
# Sync all configured repositories
repo-sync

# Get help with available options
repo-sync --help

# Run the initialization wizard (if you haven't already)
repo-sync --init
```

## Upgrading

To upgrade to the latest version:

```bash
# Download and run the installer again
curl -s https://raw.githubusercontent.com/tekinnnnn/repo-sync-tool/main/install.sh | bash
```

## Project Structure

- `repo-sync.sh`: Main script
- `lib/logger.sh`: Logging functions
- `lib/repo-operations.sh`: Repository operations
- `lib/config.sh`: Configuration and constants
- `repo-sync.conf`: User configuration (created with --init)