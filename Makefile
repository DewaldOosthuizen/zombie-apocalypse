# Makefile — single entry point for local verification, builds, and cleanup.
#
# Composes only commands and scripts that already exist and are documented in
# README.md, CONTRIBUTING.md, .github/workflows/pr_gate.yml, and scripts/.
# No existing file is modified; this Makefile is purely a wrapper layer.
#
# Usage:
#   make            # print this help (default goal)
#   make help       # print this help
#   make start      # run the game in the Godot editor
#   make build      # export the Linux and Windows release binaries
#   make clean      # remove build artifacts and downloaded Godot binaries
#   make lint       # gdlint scripts/ tests/ (mirrors the PR gate)
#   make test       # run the GUT headless test suite
#   make ci         # run the full CI-equivalent pipeline

# Delete a target's partial output if its recipe fails, so an interrupted
# export cannot leave a truncated binary that a later build would trust.
.DELETE_ON_ERROR:

# Suppress make's built-in rules and guard against any stray tracked
# directory named like a target being misinterpreted as a build rule.
MAKEFLAGS += --no-builtin-rules

# A bare `make` prints help instead of erroring.
.DEFAULT_GOAL := help

# Output directory for exported binaries (per README.md "Local Builds").
BUILD_DIR := build

# All targets are phony: none corresponds to a file on disk. The trailing
# empty recipe keeps GNU make from looking for a file named after the
# special .PHONY target itself.
.PHONY: help start build clean lint test ci
:;

help: ## Show this help listing every available target
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

start: ## Run the game in the Godot editor using project.godot's run/main_scene
	godot project.godot

build: ## Export the Linux/X11 and Windows Desktop release binaries into build/
	mkdir -p build/linux build/windows
	godot --headless --export-release "Linux/X11" build/linux/zombie-apocalypse.x86_64
	mkdir -p $(BUILD_DIR)/windows
	godot --headless --export-release "Windows Desktop" build/windows/zombie-apocalypse.exe

clean: ## Remove build artifacts and downloaded Godot binaries
	rm -rf build bin/godot bin/Godot_v*

lint: ## Run gdlint scripts/ tests/ (exactly the PR gate command)
	gdlint scripts/ tests/

test: ## Run the GUT headless test suite (honours the GODOT env var)
	bash scripts/run_gut_tests.sh

ci: ## Run the full CI-equivalent pipeline (may download Godot on first run)
	bash scripts/verify.sh
