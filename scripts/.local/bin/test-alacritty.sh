#!/usr/bin/env bash
set -euo pipefail

# test-alacritty.sh
# A simple test runner for the Alacritty configuration.

echo "--- Running Alacritty Config Test ---"

# 1. Clear old logs
rm -f /tmp/Alacritty*.log
echo "Cleared old Alacritty logs."

# 2. Run Alacritty to trigger a config parse
# We run it with a simple command that exits immediately.
alacritty -e echo "Config test..." &>/dev/null || true
sleep 0.5 # Give it a moment to write a log if it fails

# 3. Check for new logs
LOG_FILE=$(ls -t /tmp/Alacritty*.log 2>/dev/null | head -n 1)

if [ -n "$LOG_FILE" ]; then
    echo "ERROR: Alacritty configuration failed to load."
    echo "--- Log File: $LOG_FILE ---"
    cat "$LOG_FILE"
    echo "------------------------------------"
    exit 1
else
    echo "SUCCESS: Alacritty configuration is valid."
    exit 0
fi
