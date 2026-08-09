#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox
    install_network_mocks
    STATUS="$SANDBOX_REPO/scripts/.local/bin/network-status"
    SCAN="$SANDBOX_REPO/scripts/.local/bin/network-scan"
}

teardown() {
    cleanup_sandbox
}

# ────────────────────────── network-status ────────────────────────────────────

@test "network-status emits valid JSON" {
    run "$STATUS"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e . >/dev/null
}

@test "network-status reports ethernet connected by default" {
    run "$STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.state')" = "connected" ]
    [ "$(echo "$output" | jq -r '.type')" = "ethernet" ]
    [ "$(echo "$output" | jq -r '.ssid')" = "Wired connection 1" ]
    [ "$(echo "$output" | jq -r '.ip')" = "192.168.10.102" ]
    [ "$(echo "$output" | jq -r '.wifi_hw')" = "false" ]
    [ "$(echo "$output" | jq -r '.wifi_powered')" = "false" ]
}

@test "network-status reports wifi connection with hardware flags" {
    export SANDBOX_NET_DEVSTATUS=$'wlan0:wifi:connected:Home-5G\nenp5s0:ethernet:connected:Wired connection 1'
    export SANDBOX_NET_WIFILIST=$'Home-5G:92:WPA2'
    export SANDBOX_NET_CONNSSID="Home-5G"
    run "$STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.state')" = "connected" ]
    [ "$(echo "$output" | jq -r '.type')" = "wifi" ]
    [ "$(echo "$output" | jq -r '.ssid')" = "Home-5G" ]
    [ "$(echo "$output" | jq -r '.signal')" = "92" ]
    [ "$(echo "$output" | jq -r '.wifi_hw')" = "true" ]
    [ "$(echo "$output" | jq -r '.wifi_powered')" = "true" ]
}

@test "network-status reports radio disabled when nmcli radio is off" {
    export SANDBOX_NET_RADIO="disabled"
    run "$STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.wifi_enabled')" = "false" ]
    [ "$(echo "$output" | jq -r '.wifi_powered')" = "false" ]
}

@test "network-status emits disconnected state when nothing is connected" {
    export SANDBOX_NET_DEVSTATUS="wlan0:wifi:unavailable:"
    run "$STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.state')" = "disconnected" ]
    [ "$(echo "$output" | jq -r '.type')" = "" ]
}

# ─────────────────────────── network-scan ─────────────────────────────────────

@test "network-scan emits valid JSON" {
    run "$SCAN"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e . >/dev/null
}

@test "network-scan reports no wifi hardware when only ethernet exists" {
    run "$SCAN"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.wifi_hw')" = "false" ]
    [ "$(echo "$output" | jq '.networks | length')" = "0" ]
}

@test "network-scan handles SSIDs with colons and quotes" {
    export SANDBOX_NET_DEVSTATUS="wlan0:wifi:connected:Home-5G"
    export SANDBOX_NET_WIFILIST=$'Home:5G:92:WPA2\nWeird"quote:SSID:55:WPA3\nCafe_Free:70:--'
    run "$SCAN"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.wifi_hw')" = "true" ]
    [ "$(echo "$output" | jq '.networks | length')" = "3" ]
    [ "$(echo "$output" | jq -r '.networks[] | select(.ssid == "Home:5G") | .signal')" = "92" ]
    [ "$(echo "$output" | jq -r '.networks[] | select(.ssid == "Weird\"quote:SSID") | .secured')" = "true" ]
    [ "$(echo "$output" | jq -r '.networks[] | select(.ssid == "Cafe_Free") | .secured')" = "false" ]
}

@test "network-scan dedupes SSIDs case-insensitively keeping strongest signal" {
    export SANDBOX_NET_DEVSTATUS="wlan0:wifi:connected:Home-5G"
    export SANDBOX_NET_WIFILIST=$'Home:5G:92:WPA2\nhome:5g:40:WPA2'
    run "$SCAN"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq '.networks | length')" = "1" ]
    [ "$(echo "$output" | jq -r '.networks[0].ssid')" = "Home:5G" ]
    [ "$(echo "$output" | jq -r '.networks[0].signal')" = "92" ]
}

@test "network-scan computes signal bars" {
    export SANDBOX_NET_DEVSTATUS="wlan0:wifi:connected:Home-5G"
    export SANDBOX_NET_WIFILIST=$'W1:20:WPA2\nW2:45:WPA2\nW3:70:WPA2\nW4:95:WPA2'
    run "$SCAN"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.networks[] | select(.ssid == "W1") | .bars')" = "1" ]
    [ "$(echo "$output" | jq -r '.networks[] | select(.ssid == "W2") | .bars')" = "2" ]
    [ "$(echo "$output" | jq -r '.networks[] | select(.ssid == "W3") | .bars')" = "3" ]
    [ "$(echo "$output" | jq -r '.networks[] | select(.ssid == "W4") | .bars')" = "4" ]
}

@test "network-scan reports radio off with hardware present" {
    export SANDBOX_NET_RADIO="disabled"
    export SANDBOX_NET_DEVSTATUS="wlan0:wifi:unavailable:"
    run "$SCAN"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.wifi_hw')" = "true" ]
    [ "$(echo "$output" | jq -r '.wifi_enabled')" = "false" ]
    [ "$(echo "$output" | jq '.networks | length')" = "0" ]
}
