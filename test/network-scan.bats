#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    NETWORK_SCAN="$SANDBOX_REPO/scripts/.local/bin/network-scan"

    cat > "$SANDBOX_ROOT/bin/nmcli" <<'NMCLIEOF'
#!/usr/bin/env bash
echo "[MOCK] nmcli $*" >> "$SANDBOX_ROOT/calls.log"
case "$1" in
    device)
        [ "$2" = "wifi" ] && [ "$3" = "list" ] && cat <<WIFI
MyHome:85:WPA2
CoffeeShop:42:WPA2
OpenGuest:15:
WIFI
        ;;
esac
exit 0
NMCLIEOF
    chmod +x "$SANDBOX_ROOT/bin/nmcli"
}

teardown() {
    cleanup_sandbox
}

@test "network-scan: emits valid JSON" {
    run bash "$NETWORK_SCAN"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e . >/dev/null
}

@test "network-scan: includes networks array" {
    run bash "$NETWORK_SCAN"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq '.networks | length')" -eq 3 ]
}

@test "network-scan: marks secured networks" {
    run bash "$NETWORK_SCAN"
    [ "$status" -eq 0 ]
    local secured
    secured=$(echo "$output" | jq '[.networks[] | select(.secured == true)] | length')
    [ "$secured" -eq 2 ]
}

@test "network-scan: handles missing nmcli gracefully" {
    rm -f "$SANDBOX_ROOT/bin/nmcli"
    run bash "$NETWORK_SCAN"
    [ "$status" -eq 1 ]
    echo "$output" | jq -e . >/dev/null
    [ "$(echo "$output" | jq -r '.error')" = "nmcli not found" ]
}

@test "network-scan: deduplicates by SSID keeping strongest signal" {
    run bash "$NETWORK_SCAN"
    [ "$status" -eq 0 ]
    local myhome_signal
    myhome_signal=$(echo "$output" | jq '.networks[] | select(.ssid == "MyHome") | .signal')
    [ "$myhome_signal" = "85" ]
}
