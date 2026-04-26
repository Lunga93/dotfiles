#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox
    install_bluetooth_mocks
    BT_STATUS="$SANDBOX_REPO/scripts/.local/bin/bluetooth-status"
    export BT_SYS_DIR="$SANDBOX_ROOT/sys/class/bluetooth"
}

teardown() { cleanup_sandbox; }

@test "bluetooth-status reports unavailable when no adapter" {
    rm -rf "$SANDBOX_ROOT/sys/class/bluetooth"
    run "$BT_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.available')" = "false" ]
}

@test "bluetooth-status reports adapter present but powered off" {
    SANDBOX_BT_POWERED=no run "$BT_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.available')" = "true" ]
    [ "$(echo "$output" | jq -r '.powered')"   = "false" ]
    [ "$(echo "$output" | jq -r '.count')"     = "0" ]
}

@test "bluetooth-status reports powered + connected devices" {
    SANDBOX_BT_POWERED=yes \
    SANDBOX_BT_CONNECTED='AA:BB:CC:DD:EE:FF|Sony_WH-1000XM3' \
        run "$BT_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.powered')" = "true" ]
    [ "$(echo "$output" | jq -r '.count')"   = "1" ]
    [ "$(echo "$output" | jq -r '.connected[0].address')" = "AA:BB:CC:DD:EE:FF" ]
    [ "$(echo "$output" | jq -r '.connected[0].name')"    = "Sony_WH-1000XM3" ]
}

@test "bluetooth-status emits valid JSON in all states" {
    SANDBOX_BT_POWERED=no run "$BT_STATUS"
    echo "$output" | jq -e . >/dev/null
}
