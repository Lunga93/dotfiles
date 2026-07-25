#!/usr/bin/env bash
set -euo pipefail

echo ""
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

echo "Checking all page files exist..."
PAGES_DIR="settings/pages"
for page in top-bar/TopBarPage icons/IconsPage display/DisplayPage \
    keybindings/KeybindingsPage keybindings/KeyCaptureDialog \
    network/NetworkPage sound/SoundPage sysinfo/SysInfoPage \
    wallpaper/WallpaperPage; do
    if [ ! -f "$PAGES_DIR/$page.qml" ]; then
        echo "MISSING: $PAGES_DIR/$page.qml"
        exit 1
    fi
done
echo "All page files present."

echo "Checking SettingsContent routes all pages..."
SETTINGS_CONTENT="settings/SettingsContent.qml"
for name in TopBarPage IconsPage DisplayPage KeybindingsPage NetworkPage SoundPage SysInfoPage WallpaperPage; do
    if ! grep -q "$name" "$SETTINGS_CONTENT"; then
        echo "MISSING: $name not in SettingsContent.qml"
        exit 1
    fi
done
echo "SettingsContent routes OK."

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
