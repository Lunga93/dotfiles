#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    NETWORK_STATUS="$SANDBOX_REPO/scripts/.local/bin/network-status"

    cat > "$SANDBOX_ROOT/bin/nmcli" <<'NMCLIEOF'
#!/usr/bin/env bash
echo "[MOCK] nmcli $*" >> "$SANDBOX_ROOT/calls.log"
case "$1" in
    radio)
        [ "$2" = "wifi" ] && echo "enabled" ;;
    -t)
        case "$2" in
            DEVICE|device)
                cat <<DEV
wlp2s0:wifi:connected:MyWiFi
eth0:ethernet:unavailable:
DEV
                ;;
            802-11-wireless.ssid)
                echo "802-11-wireless.ssid:MyWiFi" ;;
            SSID,SIGNAL)
                echo "MyWiFi:85:WPA2" ;;
            IP4.ADDRESS)
                echo "IP4.ADDRESS[1]:192.168.1.42/24" ;;
        esac
        ;;
    connection)
        [ "$2" = "show" ] && echo "802-11-wireless.ssid:MyWiFi" ;;
esac
exit 0
NMCLIEOF
    chmod +x "$SANDBOX_ROOT/bin/nmcli"
}

teardown() {
    cleanup_sandbox
}

@test "network-status: emits valid JSON" {
    run bash "$NETWORK_STATUS"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e . >/dev/null
}

@test "network-status: reports wifi type when connected" {
    run bash "$NETWORK_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.type')" = "wifi" ]
    [ "$(echo "$output" | jq -r '.state')" = "connected" ]
}

@test "network-status: includes IP address" {
    run bash "$NETWORK_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.ip')" = "192.168.1.42" ]
}

@test "network-status: --pretty produces multi-line output" {
    run bash "$NETWORK_STATUS" --pretty
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -gt 1 ]
}

@test "network-status: handles missing nmcli gracefully" {
    rm -f "$SANDBOX_ROOT/bin/nmcli"
    run bash "$NETWORK_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.state')" = "unavailable" ]
}

@test "network-status: handles disconnected state" {
    cat > "$SANDBOX_ROOT/bin/nmcli" <<'NMCLIEOF'
#!/usr/bin/env bash
case "$1" in
    radio) [ "$2" = "wifi" ] && echo "enabled" || true ;;
    -t)
        [ "$2" = "DEVICE" ] || [ "$2" = "device" ] && echo "wlp2s0:wifi:disconnected:" ; exit 0 ;;
esac
exit 0
NMCLIEOF
    chmod +x "$SANDBOX_ROOT/bin/nmcli"

    run bash "$NETWORK_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.state')" = "disconnected" ]
}
