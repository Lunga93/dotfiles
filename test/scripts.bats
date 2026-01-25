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
