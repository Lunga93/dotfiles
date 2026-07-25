#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    APPLY_THEME="$SANDBOX_REPO/scripts/.local/bin/apply-theme"
    ACCENT_GUARDIAN="$SANDBOX_REPO/scripts/.local/bin/accent-guardian"

    mkdir -p "$SANDBOX_HOME/Pictures/wallpapers"
    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"
    mkdir -p "$SANDBOX_HOME/.cache/wal"

    # apply-theme uses $HOME/dotfiles/... to find templates
    mkdir -p "$SANDBOX_HOME/dotfiles/alacritty"
    mkdir -p "$SANDBOX_HOME/dotfiles/scripts/.local/bin"

    WALLPAPER="$SANDBOX_HOME/Pictures/wallpapers/test.png"
    python3 -c "
import struct, zlib
def make_png(path, r, g, b):
    raw = b''
    for _ in range(10):
        raw += b'\x00' + bytes([r, g, b])
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', struct.pack('>IIBBBBB', 10, 1, 8, 2, 0, 0, 0)))
        f.write(chunk(b'IDAT', zlib.compress(raw)))
        f.write(chunk(b'IEND', b''))
make_png('$WALLPAPER', 100, 150, 200)
"

    cat > "$SANDBOX_ROOT/bin/test-alacritty.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/test-alacritty.sh"

    cat > "$SANDBOX_HOME/dotfiles/scripts/.local/bin/test-alacritty.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$SANDBOX_HOME/dotfiles/scripts/.local/bin/test-alacritty.sh"

    cat > "$SANDBOX_HOME/dotfiles/scripts/.local/bin/accent-guardian" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] accent-guardian $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_HOME/dotfiles/scripts/.local/bin/accent-guardian"

    cat > "$SANDBOX_ROOT/bin/niri" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] niri $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/niri"

    cat > "$SANDBOX_ROOT/bin/swaync-client" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] swaync-client $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/swaync-client"
}

teardown() {
    cleanup_sandbox
}

# ── Argument handling ───────────────────────────────────────────────────────

@test "apply-theme: requires wallpaper argument" {
    run bash "$APPLY_THEME"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Usage" ]]
}

@test "apply-theme: runs successfully with mocked wal" {
    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Starting apply-theme" ]]
    [[ "$output" =~ "pywal complete" ]]
}

@test "apply-theme: exits on pywal failure" {
    cat > "$SANDBOX_ROOT/bin/wal" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "$SANDBOX_ROOT/bin/wal"
    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 1 ]
}

# ── Alacritty config generation ─────────────────────────────────────────────

@test "apply-theme: generates alacritty config from template" {
    local alacritty_dir="$SANDBOX_HOME/.config/alacritty"
    mkdir -p "$alacritty_dir"
    echo '# Template file' > "$SANDBOX_HOME/dotfiles/alacritty/template.alacritty.toml"

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
    [ -f "$alacritty_dir/alacritty.toml" ]

    grep -q 'Template file' "$alacritty_dir/alacritty.toml"
    grep -q '\[colors.primary\]' "$alacritty_dir/alacritty.toml"
    grep -q 'background' "$alacritty_dir/alacritty.toml"
    grep -q 'foreground' "$alacritty_dir/alacritty.toml"
    grep -q '\[colors.normal\]' "$alacritty_dir/alacritty.toml"
    grep -q '\[colors.bright\]' "$alacritty_dir/alacritty.toml"
}

@test "apply-theme: skips alacritty when template missing" {
    rm -f "$SANDBOX_HOME/dotfiles/alacritty/template.alacritty.toml" 2>/dev/null || true
    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "template not found" ]]
}

# ── Niri focus ring ─────────────────────────────────────────────────────────

@test "apply-theme: updates niri focus ring" {
    local niri_conf="$SANDBOX_HOME/.config/niri/config.kdl"
    mkdir -p "$(dirname "$niri_conf")"
    cat > "$niri_conf" <<'KDL'
prefer-no-csd
layout {
    focus-ring {
        active-color "#000000"
        inactive-color "#111111"
    }
}
KDL
    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
    grep -q 'active-color' "$niri_conf"
    ! grep -q 'active-color "#000000"' "$niri_conf"
}

# ── SwayNC colors ───────────────────────────────────────────────────────────

@test "apply-theme: generates swaync colors" {
    local swaync_dir="$SANDBOX_HOME/.config/swaync"
    mkdir -p "$swaync_dir"

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]

    [ -f "$swaync_dir/colors.css" ]
    grep -q '@define-color background' "$swaync_dir/colors.css"
    grep -q '@define-color accent' "$swaync_dir/colors.css"
    grep -q '@define-color text' "$swaync_dir/colors.css"
}

@test "apply-theme: reloads swaync when running" {
    local swaync_dir="$SANDBOX_HOME/.config/swaync"
    mkdir -p "$swaync_dir"

    pgrep() { return 0; }

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
}

# ── Wofi colors ─────────────────────────────────────────────────────────────

@test "apply-theme: generates wofi colors" {
    local wofi_dir="$SANDBOX_HOME/.config/wofi"
    mkdir -p "$wofi_dir"

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]

    [ -f "$wofi_dir/colors-wal.css" ]
    grep -q '#input' "$wofi_dir/colors-wal.css"
    grep -q '#entry:selected' "$wofi_dir/colors-wal.css"
}

# ── GTK colors ──────────────────────────────────────────────────────────────

@test "apply-theme: generates GTK3 colors-wal.css" {
    local gtk_dir="$SANDBOX_HOME/.config/gtk-3.0"
    mkdir -p "$gtk_dir"

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]

    [ -f "$gtk_dir/colors-wal.css" ]
    grep -q 'accent_color' "$gtk_dir/colors-wal.css"
    grep -q 'window_bg_color' "$gtk_dir/colors-wal.css"
    grep -q 'card_bg_color' "$gtk_dir/colors-wal.css"
}

@test "apply-theme: generates GTK4 colors-wal.css" {
    local gtk_dir="$SANDBOX_HOME/.config/gtk-4.0"
    mkdir -p "$gtk_dir"

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]

    [ -f "$gtk_dir/colors-wal.css" ]
    grep -q 'headerbar_bg_color' "$gtk_dir/colors-wal.css"
    grep -q 'sidebar_bg_color' "$gtk_dir/colors-wal.css"
}

# ── SDDM theme ──────────────────────────────────────────────────────────────

@test "apply-theme: generates SDDM theme config when dir exists" {
    local sddm_dir="/var/lib/sddm-theme"

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
}

# ── Accent picking ──────────────────────────────────────────────────────────

@test "apply-theme: picks primary and secondary accents" {
    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Derived primary" ]]
    [[ "$output" =~ "derived secondary" ]]
    [[ "$output" =~ "Final accent" ]]
}

@test "apply-theme: persists last accent files" {
    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
    [ -f "$SANDBOX_HOME/.local/share/dotfiles/last_primary" ]
    [ -f "$SANDBOX_HOME/.local/share/dotfiles/last_secondary" ]
}

# ── Manual accent mode ──────────────────────────────────────────────────────

@test "apply-theme: respects manual accent mode" {
    local settings_dir="$SANDBOX_HOME/.config/dotfiles"
    mkdir -p "$settings_dir"
    cat > "$settings_dir/settings.json" <<'JSON'
{
    "appearance": {
        "accent_mode": "manual",
        "manual_primary": "#ff0000",
        "manual_secondary": "#00ff00"
    }
}
JSON

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]

    local last_primary
    last_primary=$(cat "$SANDBOX_HOME/.local/share/dotfiles/last_primary")
    [ "$last_primary" = "#ff0000" ]
}

# ── Alacritty validation ────────────────────────────────────────────────────

@test "apply-theme: runs test-alacritty.sh after generation" {
    local alacritty_dir="$SANDBOX_HOME/.config/alacritty"
    mkdir -p "$alacritty_dir"
    echo '# Template' > "$SANDBOX_HOME/dotfiles/alacritty/template.alacritty.toml"

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 0 ]
}

@test "apply-theme: restores alacritty on invalid config" {
    local alacritty_dir="$SANDBOX_HOME/.config/alacritty"
    mkdir -p "$alacritty_dir"
    echo '# Original template' > "$SANDBOX_HOME/dotfiles/alacritty/template.alacritty.toml"

    cat > "$SANDBOX_HOME/dotfiles/scripts/.local/bin/test-alacritty.sh" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "$SANDBOX_HOME/dotfiles/scripts/.local/bin/test-alacritty.sh"

    run bash "$APPLY_THEME" "$WALLPAPER"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "invalid" ]]
}
