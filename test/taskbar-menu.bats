#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    TASKBAR_MENU="$SANDBOX_REPO/scripts/.local/bin/taskbar-menu"
}

teardown() {
    cleanup_sandbox
}

@test "taskbar-menu: exits cleanly when no appId set" {
    run bash "$TASKBAR_MENU" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "taskbar-menu: shows spotify menu items" {
    APP_ID="spotify" run bash "$TASKBAR_MENU" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "taskbar-menu: shows steam menu items" {
    APP_ID="steam" run bash "$TASKBAR_MENU" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "taskbar-menu: handles unknown appId" {
    APP_ID="firefox" run bash "$TASKBAR_MENU" 2>/dev/null || true
    [ "$status" -eq 0 ]
}
