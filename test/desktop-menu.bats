#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    DESKTOP_MENU="$SANDBOX_REPO/scripts/.local/bin/desktop-menu"

    cat > "$SANDBOX_ROOT/bin/reload-desktop" <<'EOF'
#!/usr/bin/env bash
echo "reload-desktop $@" >> "$SANDBOX_ROOT/calls.log"
EOF
    chmod +x "$SANDBOX_ROOT/bin/reload-desktop"

    cat > "$SANDBOX_ROOT/bin/wallpaper-control" <<'EOF'
#!/usr/bin/env bash
echo "wallpaper-control $@" >> "$SANDBOX_ROOT/calls.log"
EOF
    chmod +x "$SANDBOX_ROOT/bin/wallpaper-control"
}

teardown() {
    cleanup_sandbox
}

@test "desktop-menu: exits cleanly when wofi returns no match" {
    export SANDBOX_WOFI_CHOICE="Nothing Here"
    run bash "$DESKTOP_MENU"
    [ "$status" -eq 0 ]
}

@test "desktop-menu: reloads all components" {
    export SANDBOX_WOFI_CHOICE=" Reload All Components"
    run bash "$DESKTOP_MENU"
    [ "$status" -eq 0 ]
    grep -q "reload-desktop all" "$SANDBOX_ROOT/calls.log"
}

@test "desktop-menu: reloads quickshell only" {
    export SANDBOX_WOFI_CHOICE=" Reload Quickshell"
    run bash "$DESKTOP_MENU"
    [ "$status" -eq 0 ]
    grep -q "reload-desktop quickshell" "$SANDBOX_ROOT/calls.log"
}

@test "desktop-menu: reloads swaync" {
    export SANDBOX_WOFI_CHOICE=" Reload SwayNC"
    run bash "$DESKTOP_MENU"
    [ "$status" -eq 0 ]
    grep -q "reload-desktop swaync" "$SANDBOX_ROOT/calls.log"
}

@test "desktop-menu: reloads niri config" {
    export SANDBOX_WOFI_CHOICE=" Reload Niri Config"
    run bash "$DESKTOP_MENU"
    [ "$status" -eq 0 ]
    grep -q "reload-desktop niri" "$SANDBOX_ROOT/calls.log"
}

@test "desktop-menu: launches wallpaper control" {
    export SANDBOX_WOFI_CHOICE=" Change Wallpaper"
    run bash "$DESKTOP_MENU"
    [ "$status" -eq 0 ]
    grep -q "wallpaper-control" "$SANDBOX_ROOT/calls.log"
}
