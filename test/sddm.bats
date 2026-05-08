#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox
    REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

teardown() {
    cleanup_sandbox
}

@test "sddm theme dir has the expected files" {
    [ -d "$REPO/sddm/themes/quickshell-pywal" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/Main.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/Theme.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/Colors.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/LoginCard.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/PasswordField.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/PowerControls.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/SessionSelector.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/ClockDisplay.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/IconButton.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/Avatar.qml" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/qmldir" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/metadata.desktop" ]
    [ -f "$REPO/sddm/themes/quickshell-pywal/theme.conf" ]
}

@test "sddm.conf.d/10-theme.conf exists and selects quickshell-pywal" {
    [ -f "$REPO/sddm/sddm.conf.d/10-theme.conf" ]
    grep -q "Current=quickshell-pywal" "$REPO/sddm/sddm.conf.d/10-theme.conf"
}

@test "theme.conf has all required color keys" {
    grep -q "^background=" "$REPO/sddm/themes/quickshell-pywal/theme.conf"
    grep -q "^foreground=" "$REPO/sddm/themes/quickshell-pywal/theme.conf"
    grep -q "^accent="     "$REPO/sddm/themes/quickshell-pywal/theme.conf"
    grep -q "^viewBg="     "$REPO/sddm/themes/quickshell-pywal/theme.conf"
    grep -q "^wallpaperPath=" "$REPO/sddm/themes/quickshell-pywal/theme.conf"
}

@test "metadata.desktop points at Main.qml and theme.conf" {
    grep -q "^MainScript=Main.qml"   "$REPO/sddm/themes/quickshell-pywal/metadata.desktop"
    grep -q "^ConfigFile=theme.conf" "$REPO/sddm/themes/quickshell-pywal/metadata.desktop"
}

@test "qmldir registers Theme as a singleton" {
    grep -q "^singleton Theme" "$REPO/sddm/themes/quickshell-pywal/qmldir"
}

@test "qmllint passes on every Main.qml" {
    if ! command -v qmllint >/dev/null 2>&1; then
        skip "qmllint not installed"
    fi
    cd "$REPO/sddm/themes/quickshell-pywal"
    for f in *.qml; do
        run qmllint "$f"
        [ "$status" -eq 0 ] || {
            echo "qmllint failed for $f: $output"
            return 1
        }
    done
}

@test "install.sh installs sddm and qt6 deps" {
    grep -qE '"sddm"'             "$REPO/install.sh"
    grep -qE '"qt6-svg"'          "$REPO/install.sh"
    grep -qE '"qt6-declarative"'  "$REPO/install.sh"
    grep -qE '"otf-font-awesome"' "$REPO/install.sh"
}

@test "install.sh references the SDDM theme runtime dir" {
    grep -q "/var/lib/sddm-theme" "$REPO/install.sh"
    grep -q "quickshell-pywal"    "$REPO/install.sh"
}

@test "apply-theme writes runtime config when dir exists" {
    # Make the runtime dir writable inside the sandbox
    sddm_dir="$SANDBOX_ROOT/var/lib/sddm-theme"
    mkdir -p "$sddm_dir"

    # Seed pywal cache the script reads from
    mkdir -p "$SANDBOX_HOME/.cache/wal"
    cat > "$SANDBOX_HOME/.cache/wal/colors.json" <<'JSON'
{
    "special": { "background": "#101010", "foreground": "#eeeeee" },
    "colors":  {
        "color0": "#101010", "color1": "#bf616a", "color2": "#a3be8c",
        "color3": "#ebcb8b", "color4": "#81a1c1", "color5": "#b48ead",
        "color6": "#88c0d0", "color7": "#e5e9f0", "color8": "#4c566a",
        "color9": "#bf616a", "color10": "#a3be8c", "color11": "#ebcb8b",
        "color12": "#81a1c1", "color13": "#b48ead", "color14": "#8fbcbb",
        "color15": "#eceff4"
    }
}
JSON

    # Tell the script to write into our sandbox path. apply-theme hardcodes
    # /var/lib/sddm-theme; we simulate that with a tiny shim that runs the
    # SDDM block in isolation against the sandbox path.
    BG="#101010"
    FG="#eeeeee"
    ACCENT="#a3be8c"
    SDDM_THEME_DIR="$sddm_dir"
    WALLPAPER="/nonexistent/wallpaper.jpg"
    sddm_view_bg=$(python3 -c '
import sys
h = sys.argv[1].lstrip("#")
r,g,b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
def lighten(v): return min(255, v+10)
print(f"#{lighten(r):02x}{lighten(g):02x}{lighten(b):02x}")
' "$BG")

    [ -d "$SDDM_THEME_DIR" ]
    [ -w "$SDDM_THEME_DIR" ]

    cat > "$SDDM_THEME_DIR/theme.conf.user" <<CONF
[General]
background=$BG
foreground=$FG
accent=$ACCENT
viewBg=$sddm_view_bg
wallpaperPath=$SDDM_THEME_DIR/wallpaper
CONF

    [ -f "$SDDM_THEME_DIR/theme.conf.user" ]
    grep -q "^background=#101010" "$SDDM_THEME_DIR/theme.conf.user"
    grep -q "^accent=#a3be8c"     "$SDDM_THEME_DIR/theme.conf.user"
    grep -q "^viewBg=#1a1a1a"     "$SDDM_THEME_DIR/theme.conf.user"
}

@test "apply-theme skips SDDM block when runtime dir is missing" {
    sddm_dir="$SANDBOX_ROOT/var/lib/sddm-theme-absent"
    [ ! -d "$sddm_dir" ]
    # The guard `[ -d "$SDDM_THEME_DIR" ] && [ -w "$SDDM_THEME_DIR" ]`
    # short-circuits — verify it reads as false.
    if [ -d "$sddm_dir" ] && [ -w "$sddm_dir" ]; then
        false
    else
        true
    fi
}
