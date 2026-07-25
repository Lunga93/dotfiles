#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    AUDIO_PANEL="$SANDBOX_REPO/scripts/.local/bin/audio-panel"
    AUDIO_MENU="$SANDBOX_REPO/scripts/.local/bin/audio-menu"

    cat > "$SANDBOX_ROOT/bin/qs" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] qs $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/qs"

    cat > "$SANDBOX_ROOT/bin/audio-menu" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] audio-menu $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/audio-menu"
}

teardown() {
    cleanup_sandbox
}

@test "audio-panel: calls qs ipc when quickshell available" {
    run bash "$AUDIO_PANEL" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "qs ipc call audio toggle" "$SANDBOX_ROOT/calls.log"
}

@test "audio-panel: falls back to audio-menu when qs missing" {
    rm -f "$SANDBOX_ROOT/bin/qs"

    run bash "$AUDIO_PANEL" 2>/dev/null || true
    grep -q "\[MOCK\] audio-menu" "$SANDBOX_ROOT/calls.log"
}
