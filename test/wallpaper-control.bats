#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    WALLPAPER_CONTROL="$SANDBOX_REPO/scripts/.local/bin/wallpaper-control"

    mkdir -p "$SANDBOX_HOME/Pictures/wallpapers"
    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"
    mkdir -p "$SANDBOX_HOME/.config"

    touch "$SANDBOX_HOME/Pictures/wallpapers/daily.jpg"

    cat > "$SANDBOX_ROOT/bin/fetch-wallpaper" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK-FETCH] wallpaper fetched" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/fetch-wallpaper"

    cat > "$SANDBOX_ROOT/bin/set-wallpaper" <<'EOF'
#!/usr/bin/env bash
echo "set-wallpaper called with: $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/set-wallpaper"

    cat > "$SANDBOX_ROOT/bin/wallpaper-menu" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK-MENU] wallpaper-menu $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/wallpaper-menu"

    cat > "$SANDBOX_ROOT/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK-NOTIFY] $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/notify-send"
}

teardown() {
    cleanup_sandbox
}

@test "wallpaper-control: fetches new wallpaper" {
    export SANDBOX_WOFI_CHOICE="Fetch New Wallpaper"
    run bash "$WALLPAPER_CONTROL" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "\[MOCK-FETCH\]" "$SANDBOX_ROOT/calls.log"
}

@test "wallpaper-control: re-applies current theme" {
    export SANDBOX_WOFI_CHOICE="Re-apply Current Theme"
    run bash "$WALLPAPER_CONTROL" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "set-wallpaper called" "$SANDBOX_ROOT/calls.log"
}

@test "wallpaper-control: opens archive menu" {
    export SANDBOX_WOFI_CHOICE="Select from Archive"
    run bash "$WALLPAPER_CONTROL" 2>/dev/null || true
    grep -q "\[MOCK-MENU\]" "$SANDBOX_ROOT/calls.log"
}

@test "wallpaper-control: handles empty choice gracefully" {
    export SANDBOX_WOFI_CHOICE=""
    run bash "$WALLPAPER_CONTROL" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "wallpaper-control: skip today creates skip file" {
    export SANDBOX_WOFI_CHOICE="Skip Today"
    run bash "$WALLPAPER_CONTROL" 2>/dev/null || true
    [ "$status" -eq 0 ]
    [ -f "$SANDBOX_HOME/.local/share/dotfiles/skip_today" ]
}

@test "wallpaper-control: unskip today removes skip file" {
    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"
    date +%F > "$SANDBOX_HOME/.local/share/dotfiles/skip_today"
    export SANDBOX_WOFI_CHOICE="Unskip Today"
    run bash "$WALLPAPER_CONTROL" 2>/dev/null || true
    [ "$status" -eq 0 ]
    [ ! -f "$SANDBOX_HOME/.local/share/dotfiles/skip_today" ]
}
