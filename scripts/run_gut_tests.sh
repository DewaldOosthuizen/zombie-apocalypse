#!/usr/bin/env bash
# run_gut_tests.sh — run GUT tests locally against a Godot 4 binary.
#
# Usage:
#   ./scripts/run_gut_tests.sh                  # uses 'godot' on PATH
#   GODOT=/path/to/godot ./scripts/run_gut_tests.sh
#
# The script must be run from the repository root.

set -euo pipefail

GODOT="${GODOT:-godot}"

if ! command -v "$GODOT" &>/dev/null; then
    echo "ERROR: Godot binary not found ('$GODOT')."
    echo "  Install Godot 4 and make sure it is on PATH, or set GODOT=/path/to/godot."
    exit 1
fi

echo "Using Godot: $("$GODOT" --version 2>&1 | head -1)"
echo "Running GUT tests headlessly..."

"$GODOT" --headless \
    -s addons/gut/addons/gut/gut_cmdln.gd \
    -gdir=res://tests \
    -gprefix=test_ \
    -gsuffix=.gd \
    -gexit
