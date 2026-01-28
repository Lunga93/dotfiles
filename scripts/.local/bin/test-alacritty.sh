#!/usr/bin/env bash
set -euo pipefail

# test-alacritty.sh
# Reliably checks if Alacritty config has errors by scanning stderr.

echo "--- Running Alacritty Config Test ---"

# Run alacritty for a split second and capture stderr
# We use timeout to ensure it doesn't hang if it actually succeeds (and opens a window)
OUTPUT=$(timeout 1s alacritty -e true 2>&1 || true)

# Look for any ERROR lines
if echo "$OUTPUT" | grep -q "\[ERROR\]"; then
    echo "ERROR: Alacritty configuration failed."
    echo "--- Alacritty Output (first ERROR context) ---"
    echo "$OUTPUT" | grep "\[ERROR\]" -n -A 6 | sed -n '1,200p'

    # Detect duplicate key specifically and attempt automated repair
    if echo "$OUTPUT" | grep -qi "duplicate key"; then
        echo "CRITICAL: Duplicate key (TOML) detected in Alacritty config. This is usually caused by multiple [colors] or [colors.primary] blocks." 
        echo "Attempting automated repair: restore template -> ~/.local/share/dotfiles/alacritty_fix.log will record actions."
        TEMPLATE="$HOME/dotfiles/alacritty/template.alacritty.toml"
        DEST="$HOME/.config/alacritty/alacritty.toml"
        LOGFILE="$HOME/.local/share/dotfiles/alacritty_fix.log"
        mkdir -p "$(dirname "$LOGFILE")"
        if [ -f "$TEMPLATE" ]; then
            # Backup broken dest if exists
            if [ -f "$DEST" ]; then
                cp "$DEST" "$DEST.broken.$(date +%s)" 2>/dev/null || true
            fi
            cp "$TEMPLATE" "$DEST"
            echo "[$(date --iso-8601=seconds)] Restored template to $DEST due to duplicate key" >> "$LOGFILE"
            echo "Restoration performed from $TEMPLATE -> $DEST"
            # Re-run quick check
            OUTPUT2=$(timeout 1s alacritty -e true 2>&1 || true)
            if echo "$OUTPUT2" | grep -q "\[ERROR\]"; then
                echo "Post-restore check still reports errors:"; echo "$OUTPUT2" | grep "\[ERROR\]" -n -A 5
                exit 3
            else
                echo "Post-restore: SUCCESS. Alacritty config restored and valid."
                exit 0
            fi
        else
            echo "Template not found at $TEMPLATE; cannot auto-restore."
            exit 2
        fi
    fi

    echo "------------------------"
    exit 1
else
    echo "SUCCESS: Alacritty configuration appears valid."
    exit 0
fi
