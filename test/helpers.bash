#!/usr/bin/env bash
# Shared helpers for bats tests — lightweight: no repo copy, mocks only
set -euo pipefail

create_sandbox() {
    SANDBOX_ROOT=$(mktemp -d)
    export SANDBOX_ROOT
    export SANDBOX_HOME="$SANDBOX_ROOT/home"
    mkdir -p "$SANDBOX_HOME"
    mkdir -p "$SANDBOX_ROOT/bin"
    touch "$SANDBOX_ROOT/calls.log"

    mkdir -p "$SANDBOX_HOME/.config/niri"

    for cmd in pacman yay stow makepkg sudo systemctl; do
        cat > "$SANDBOX_ROOT/bin/$cmd" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] $(basename "$0") $@" >> "$SANDBOX_ROOT/calls.log"
if [ "$(basename \"$0\")" = "sudo" ]; then
    cmd="$1"
    shift || true
    if [ -n "${cmd:-}" ]; then
        echo "[MOCK-FORWARDED] $cmd $@" >> "$SANDBOX_ROOT/calls.log"
        if [ -x "$SANDBOX_ROOT/bin/$cmd" ]; then
            exec "$SANDBOX_ROOT/bin/$cmd" "$@"
        fi
    fi
    exit 0
fi
exit 0
EOF
        chmod +x "$SANDBOX_ROOT/bin/$cmd"
    done

    cat > "$SANDBOX_ROOT/bin/git" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] git $@" >> "$SANDBOX_ROOT/calls.log"
if [ "$1" = "clone" ]; then
    dst="${@: -1}"
    mkdir -p "$dst"
    echo "fake-repo" > "$dst/README" || true
fi
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/git"

    export PATH="$SANDBOX_ROOT/bin:$PATH"
    export HOME="$SANDBOX_HOME"

    # Misc potentially-slow real bins that get invoked via command -v
    for bin in chafa seed-wallpapers fetch-wallpaper apply-theme; do
        cat > "$SANDBOX_ROOT/bin/$bin" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] $(basename "$0") $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
        chmod +x "$SANDBOX_ROOT/bin/$bin"
    done

    # wofi: return chosen line via SANDBOX_WOFI_CHOICE, or first stdin line
    cat > "$SANDBOX_ROOT/bin/wofi" <<'EOF'
#!/usr/bin/env bash
if [ -n "${SANDBOX_WOFI_CHOICE:-}" ]; then
    printf '%s' "$SANDBOX_WOFI_CHOICE"
    exit 0
fi
awk 'NR==1{print; exit}'
EOF
    chmod +x "$SANDBOX_ROOT/bin/wofi"

    # wal (pywal): create dummy colors.json
    cat > "$SANDBOX_ROOT/bin/wal" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] wal $@" >> "$SANDBOX_ROOT/calls.log"
mkdir -p "$HOME/.cache/wal"
cat > "$HOME/.cache/wal/colors.json" <<JSON
{
    "special": {
        "background": "#1e1e1e",
        "foreground": "#f0f0f0"
    },
    "colors": {
        "color0": "#1e1e1e", "color1": "#bf616a", "color2": "#a3be8c",
        "color3": "#ebcb8b", "color4": "#81a1c1", "color5": "#b48ead",
        "color6": "#88c0d0", "color7": "#e5e9f0", "color8": "#4c566a",
        "color9": "#bf616a", "color10": "#a3be8c", "color11": "#ebcb8b",
        "color12": "#81a1c1", "color13": "#b48ead", "color14": "#8fbcbb",
        "color15": "#eceff4"
    }
}
JSON
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/wal"

    export TEST_TMPDIR="$SANDBOX_ROOT/tmp"
    mkdir -p "$TEST_TMPDIR"

    # Point to the real repo — no copy needed
    SANDBOX_REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export SANDBOX_REPO
}

cleanup_sandbox() {
    if [ -n "${SANDBOX_ROOT:-}" ] && [ -d "$SANDBOX_ROOT" ]; then
        rm -rf "$SANDBOX_ROOT"
    fi
}

# ── Audio mocks ──────────────────────────────────────────────────────────────
install_audio_mocks() {
    : "${SANDBOX_DEFAULT_SINK:=alsa_output.test.analog-stereo}"
    : "${SANDBOX_DEFAULT_SOURCE:=alsa_input.test.analog-stereo}"
    : "${SANDBOX_SINK_VOLUME:=42}"
    : "${SANDBOX_SINK_MUTED:=no}"
    : "${SANDBOX_SOURCE_VOLUME:=78}"
    : "${SANDBOX_SOURCE_MUTED:=no}"
    export SANDBOX_DEFAULT_SINK SANDBOX_DEFAULT_SOURCE
    export SANDBOX_SINK_VOLUME SANDBOX_SINK_MUTED
    export SANDBOX_SOURCE_VOLUME SANDBOX_SOURCE_MUTED

    cat > "$SANDBOX_ROOT/bin/pactl" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] pactl $*" >> "$SANDBOX_ROOT/calls.log"
case "$1 $2" in
    "get-default-sink "*|"get-default-sink ")
        printf '%s\n' "$SANDBOX_DEFAULT_SINK" ;;
    "get-default-source "*|"get-default-source ")
        printf '%s\n' "$SANDBOX_DEFAULT_SOURCE" ;;
    "get-sink-volume "*)
        v=${SANDBOX_SINK_VOLUME}
        printf 'Volume: front-left: 0 / %s%% / 0.00 dB,   front-right: 0 / %s%% / 0.00 dB\n' "$v" "$v" ;;
    "get-source-volume "*)
        v=${SANDBOX_SOURCE_VOLUME}
        printf 'Volume: mono: 0 / %s%% / 0.00 dB\n' "$v" ;;
    "get-sink-mute "*)
        printf 'Mute: %s\n' "$SANDBOX_SINK_MUTED" ;;
    "get-source-mute "*)
        printf 'Mute: %s\n' "$SANDBOX_SOURCE_MUTED" ;;
esac

if [ "$1" = "-f" ] && [ "$2" = "json" ] && [ "$3" = "list" ]; then
    case "$4" in
        sinks)
            cat <<JSON
[
  {"index":47,"name":"alsa_output.test.analog-stereo","description":"Built-in Speakers"},
  {"index":48,"name":"alsa_output.test.hdmi-stereo","description":"HDMI Output"}
]
JSON
            ;;
        sources)
            cat <<JSON
[
  {"index":55,"name":"alsa_input.test.analog-stereo","description":"Built-in Mic","properties":{"device.class":"sound"}},
  {"index":56,"name":"alsa_output.test.analog-stereo.monitor","description":"Monitor of Speakers","properties":{"device.class":"monitor"}}
]
JSON
            ;;
    esac
fi

if [ "$1" = "subscribe" ]; then
    echo "Event 'change' on sink #47"
    sleep 0.05
    echo "Event 'change' on source #55"
fi
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/pactl"

    cat > "$SANDBOX_ROOT/bin/wpctl" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] wpctl $*" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/wpctl"
}

# ── Bluetooth mocks ──────────────────────────────────────────────────────────
install_bluetooth_mocks() {
    : "${SANDBOX_BT_AVAILABLE:=yes}"
    : "${SANDBOX_BT_POWERED:=no}"
    : "${SANDBOX_BT_CONNECTED:=}"
    export SANDBOX_BT_AVAILABLE SANDBOX_BT_POWERED SANDBOX_BT_CONNECTED

    if [ "$SANDBOX_BT_AVAILABLE" = "yes" ]; then
        mkdir -p "$SANDBOX_ROOT/sys/class/bluetooth/hci0"
    fi

    cat > "$SANDBOX_ROOT/bin/bluetoothctl" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] bluetoothctl $*" >> "$SANDBOX_ROOT/calls.log"
case "$1" in
    show)
        printf '\tPowered: %s\n'        "$SANDBOX_BT_POWERED"
        printf '\tDiscovering: no\n'
        printf '\tDiscoverable: no\n'
        ;;
    devices)
        if [ "$2" = "Connected" ] && [ -n "$SANDBOX_BT_CONNECTED" ]; then
            for entry in $SANDBOX_BT_CONNECTED; do
                mac=${entry%%|*}; name=${entry#*|}
                printf 'Device %s %s\n' "$mac" "$name"
            done
        fi
        ;;
    power) ;;
esac
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/bluetoothctl"
}

# ── Network mocks ─────────────────────────────────────────────────────────────
# Drives nmcli. SANDBOX_NET_DEVSTATUS lines: DEVICE:TYPE:STATE:CONNECTION
# (STATE "unavailable" simulates an unbound driver / radio off).
# SANDBOX_NET_WIFILIST lines: SSID:SIGNAL:SECURITY (SSIDs may contain ':').
install_network_mocks() {
    : "${SANDBOX_NET_RADIO:=enabled}"
    : "${SANDBOX_NET_DEVSTATUS:="enp5s0:ethernet:connected:Wired connection 1"}"
    : "${SANDBOX_NET_WIFILIST:=}"
    : "${SANDBOX_NET_CONNSSID:=}"
    : "${SANDBOX_NET_IP:=192.168.10.102/24}"
    export SANDBOX_NET_RADIO SANDBOX_NET_DEVSTATUS SANDBOX_NET_WIFILIST
    export SANDBOX_NET_CONNSSID SANDBOX_NET_IP

    cat > "$SANDBOX_ROOT/bin/nmcli" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] nmcli $*" >> "$SANDBOX_ROOT/calls.log"
subcmd=""; ftype=false
for a in "$@"; do
    case "$a" in
        radio)      subcmd=radio ;;
        device)     subcmd=device ;;
        wifi)       [ "$subcmd" = device ] && subcmd=wifi ;;
        list)       [ "$subcmd" = wifi ] && subcmd=wifi_list ;;
        status)     [ "$subcmd" = device ] && subcmd=devstatus ;;
        connection) subcmd=connection ;;
        show)       [ "$subcmd" = connection ] && subcmd=connshow ;;
        TYPE)       ftype=true ;;
    esac
done
case "$subcmd" in
    radio)     printf '%s\n' "$SANDBOX_NET_RADIO" ;;
    devstatus)
        if [ "$ftype" = true ]; then
            printf '%s\n' "$SANDBOX_NET_DEVSTATUS" | awk -F: '{print $2}'
        else
            printf '%s\n' "$SANDBOX_NET_DEVSTATUS"
        fi
        ;;
    wifi_list) printf '%s\n' "$SANDBOX_NET_WIFILIST" ;;
    connshow)  printf '802-11-wireless.ssid:%s\n' "$SANDBOX_NET_CONNSSID" ;;
    *)         printf 'IP4.ADDRESS[1]:%s\n' "$SANDBOX_NET_IP" ;;
esac
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/nmcli"
}

run_install_sh() {
    (cd "$SANDBOX_REPO" && PATH="$SANDBOX_ROOT/bin:$PATH" HOME="$SANDBOX_HOME" bash ./install.sh)
}
