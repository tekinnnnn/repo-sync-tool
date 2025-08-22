#!/usr/bin/make -f

# Simple Makefile for repo-sync-tool
# Provides common development tasks

.PHONY: help test install clean

# Default target
help:
	@echo "Repo Sync Tool - Available targets:"
	@echo ""
	@echo "  test     - Run the test suite"
	@echo "  install  - Install the tool system-wide"  
	@echo "  clean    - Clean temporary files"
	@echo "  help     - Show this help message"

# Run tests
test:
	@echo "Running repo-sync-tool test suite..."
	@./test/test_runner.sh

# Install the tool
install:
	@echo "Running installation script..."
	@./install.sh

# Clean temporary files
clean:
	@echo "Cleaning temporary test files..."
	@rm -f /tmp/test_repo_sync_config_*
	@echo "Done."