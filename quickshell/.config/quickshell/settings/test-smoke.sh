#!/usr/bin/env bash
set -euo pipefail

echo "=== Settings App Smoke Test ==="

echo "Checking qmldir paths..."
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

while IFS= read -r line; do
    if [[ "$line" =~ ^([a-zA-Z]|singleton\ ) ]]; then
        file=$(echo "$line" | awk '{print $NF}')
        if [ -n "$file" ] && [ "$file" != "1.0" ]; then
            if [ ! -f "$file" ]; then
                echo "MISSING: $file"
                exit 1
            fi
        fi
    fi
done < qmldir
echo "All qmldir paths OK."

SCRIPTS_DIR="$(cd "$REPO_DIR/../../.." && pwd)/scripts/.local/bin"

echo "Checking tag-wallpaper-moods..."
if [ -x "$SCRIPTS_DIR/tag-wallpaper-moods" ]; then
    python3 "$SCRIPTS_DIR/tag-wallpaper-moods" --version
    echo "Tagger OK."
else
    echo "WARNING: tag-wallpaper-moods not found at expected path"
fi

echo "Checking fetch-wallpaper settings.json reading..."
if [ -f "$SCRIPTS_DIR/fetch-wallpaper" ]; then
    grep -q 'library_dir' "$SCRIPTS_DIR/fetch-wallpaper" && echo "fetch-wallpaper uses library_dir OK." || echo "WARNING: library_dir not found in fetch-wallpaper"
else
    echo "WARNING: fetch-wallpaper not found at expected path"
fi

echo ""
echo "=== Smoke test passed ==="
