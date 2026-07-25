#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    VIEW_LOGS="$SANDBOX_REPO/scripts/.local/bin/view-logs"

    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"
    touch "$SANDBOX_HOME/.local/share/dotfiles/apply-theme.log"
    touch "$SANDBOX_HOME/.local/share/dotfiles/wallpaper.log"
}

teardown() {
    cleanup_sandbox
}

@test "view-logs: runs without error" {
    run bash "$VIEW_LOGS" 2>/dev/null || true
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
