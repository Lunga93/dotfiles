#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox
    install_bluetooth_mocks

    export BT_SYS_DIR="$SANDBOX_ROOT/sys/class/bluetooth"

    BLUETOOTH_MENU="$SANDBOX_REPO/scripts/.local/bin/bluetooth-menu"

    cat > "$SANDBOX_ROOT/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK-NOTIFY] $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/notify-send"

    cat > "$SANDBOX_ROOT/bin/overskride" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] overskride $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/overskride"
}

teardown() {
    cleanup_sandbox
}

@test "bluetooth-menu: shows unavailable when no adapter" {
    export SANDBOX_BT_AVAILABLE=no

    run bash "$BLUETOOTH_MENU" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "bluetooth-menu: shows power on option when off" {
    export SANDBOX_BT_POWERED=no
    export SANDBOX_WOFI_CHOICE="󰂯  Power on"

    run bash "$BLUETOOTH_MENU" 2>/dev/null || true
    grep -q "bluetoothctl power on" "$SANDBOX_ROOT/calls.log"
}

@test "bluetooth-menu: shows power off option when on" {
    export SANDBOX_BT_POWERED=yes
    export SANDBOX_WOFI_CHOICE="󰂲  Power off"

    run bash "$BLUETOOTH_MENU" 2>/dev/null || true
    grep -q "bluetoothctl power off" "$SANDBOX_ROOT/calls.log"
}

@test "bluetooth-menu: disconnects selected device" {
    export SANDBOX_BT_POWERED=yes
    export SANDBOX_BT_CONNECTED="AA:BB:CC:DD:EE:FF|TestHeadphones"
    export SANDBOX_WOFI_CHOICE="󰂱  TestHeadphones"

    run bash "$BLUETOOTH_MENU" 2>/dev/null || true
    grep -q "bluetoothctl disconnect AA:BB:CC:DD:EE:FF" "$SANDBOX_ROOT/calls.log"
}

@test "bluetooth-menu: handles empty choice gracefully" {
    export SANDBOX_BT_POWERED=yes
    export SANDBOX_WOFI_CHOICE=""

    run bash "$BLUETOOTH_MENU" 2>/dev/null || true
    [ "$status" -eq 0 ]
}
