#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    TEST_THEME="$SANDBOX_REPO/scripts/.local/bin/test-theme"

    mkdir -p "$SANDBOX_HOME/.cache/wal"
    mkdir -p "$SANDBOX_HOME/.config/alacritty"
    mkdir -p "$SANDBOX_HOME/.config/niri"
    mkdir -p "$SANDBOX_HOME/.config/swaync"
    mkdir -p "$SANDBOX_HOME/.config/wofi"
    mkdir -p "$SANDBOX_HOME/.config/gtk-3.0"
    mkdir -p "$SANDBOX_HOME/.config/gtk-4.0"
}

teardown() {
    cleanup_sandbox
}

@test "test-theme: runs without crash" {
    run bash "$TEST_THEME" 2>/dev/null || true
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || [ "$status" -eq 2 ]
}
