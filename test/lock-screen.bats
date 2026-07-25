#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    LOCK_SCREEN="$SANDBOX_REPO/scripts/.local/bin/lock-screen"

    # helpers.bash already has swaylock-effects and swaylock mocks
}

teardown() {
    cleanup_sandbox
}

@test "lock-screen: prefers swaylock-effects when available" {
    run bash "$LOCK_SCREEN" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "swaylock-effects" "$SANDBOX_ROOT/calls.log"
}

@test "lock-screen: falls back to swaylock when effects missing" {
    rm -f "$SANDBOX_ROOT/bin/swaylock-effects"

    run bash "$LOCK_SCREEN" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "swaylock" "$SANDBOX_ROOT/calls.log"
}

@test "lock-screen: exits with error when neither available" {
    rm -f "$SANDBOX_ROOT/bin/swaylock-effects"
    rm -f "$SANDBOX_ROOT/bin/swaylock"

    run bash "$LOCK_SCREEN"
    [ "$status" -eq 2 ]
}
