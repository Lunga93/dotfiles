#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    SDDM_GREETER_DEBUG="$SANDBOX_REPO/scripts/.local/bin/sddm-greeter-debug"

    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"
}

teardown() {
    cleanup_sandbox
}

@test "sddm-greeter-debug: runs without crashing" {
    run bash "$SDDM_GREETER_DEBUG" 2>/dev/null || true
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}
