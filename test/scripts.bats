#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox
}

teardown() {
    cleanup_sandbox
}

@test "clipboard-manager selects entry and copies to clipboard" {
    export SANDBOX_WOFI_CHOICE="second snippet"
    run bash "$SANDBOX_REPO/scripts/.local/bin/clipboard-manager"
    [ "$status" -eq 0 ]
    # ensure wl-copy received the selection (use fixed string)
    grep -Fq "[MOCK-WL-COPY] second snippet" "$SANDBOX_ROOT/calls.log"
}

@test "set-wallpaper invokes swww and wal" {
    IMG="/tmp/test-image.jpg"
    run bash "$SANDBOX_REPO/scripts/.local/bin/set-wallpaper" "$IMG"
    [ "$status" -eq 0 ]
    grep -q "swww" "$SANDBOX_ROOT/calls.log"
    grep -q "wal" "$SANDBOX_ROOT/calls.log"
}

@test "lock-screen prefers swaylock-effects" {
    run bash "$SANDBOX_REPO/scripts/.local/bin/lock-screen"
    [ "$status" -eq 0 ]
    grep -q "swaylock-effects" "$SANDBOX_ROOT/calls.log"
}

@test "apply-theme generates swaync colors if directory exists" {
    # Ensure swaync dir exists
    mkdir -p "$SANDBOX_HOME/.config/swaync"
    
    # Create fake wallpaper
    touch "$SANDBOX_ROOT/wall.jpg"
    
    # Create fake jq (if system jq missing) or ensure system jq works
    # Mocking jq to be safe since we don't know if system has it
    cat > "$SANDBOX_ROOT/bin/jq" <<'EOF'
#!/usr/bin/env bash
# Minimal mock to extract colors
# This is a very crude mock that only handles the specific queries apply-theme uses
# But since we control the input (mock wal output), we can just hardcode the output.
if [[ "$@" == *".special.background"* ]]; then echo "#1e1e1e"; fi
if [[ "$@" == *".special.foreground"* ]]; then echo "#f0f0f0"; fi
if [[ "$@" == *".colors.color2"* ]]; then echo "#a3be8c"; fi
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/jq"
    
    # Mock UI reload tools
    cat > "$SANDBOX_ROOT/bin/swaync-client" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/swaync-client"

    cat > "$SANDBOX_ROOT/bin/makoctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/makoctl"

    # Mock alacritty to prevent launching real terminal
    cat > "$SANDBOX_ROOT/bin/alacritty" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/alacritty"

    # Mock python3 for the complex accent logic to just return a color
    cat > "$SANDBOX_ROOT/bin/python3" <<'EOF'
#!/usr/bin/env bash
echo "#a3be8c"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/python3"

    run bash "$SANDBOX_REPO/scripts/.local/bin/apply-theme" "$SANDBOX_ROOT/wall.jpg"
    
    [ "$status" -eq 0 ]
    [ -f "$SANDBOX_HOME/.config/swaync/colors.css" ]
    grep -q "@define-color background #1e1e1ecc;" "$SANDBOX_HOME/.config/swaync/colors.css"
}
