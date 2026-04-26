#!/usr/bin/env bash
# Shared helpers for bats tests
set -euo pipefail

create_sandbox() {
    SANDBOX_ROOT=$(mktemp -d)
    export SANDBOX_ROOT
    export SANDBOX_HOME="$SANDBOX_ROOT/home"
    mkdir -p "$SANDBOX_HOME"
    mkdir -p "$SANDBOX_ROOT/bin"
    touch "$SANDBOX_ROOT/calls.log"

    # Create a fake config dir to test backup behavior
    mkdir -p "$SANDBOX_HOME/.config/niri"

    # Create lightweight mocks for commands used by install.sh
    # Each mock writes its invocation to $SANDBOX_ROOT/calls.log and exits 0.
    for cmd in pacman yay stow makepkg sudo systemctl; do
        cat > "$SANDBOX_ROOT/bin/$cmd" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] $(basename "$0") $@" >> "$SANDBOX_ROOT/calls.log"
if [ "$(basename \"$0\")" = "sudo" ]; then
    # preserve the original command name, then remove it from args
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

    # Mock git clone to create /tmp/yay dir (safe) instead of contacting network
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

    # Ensure PATH and HOME are overridden for the test-run
    export PATH="$SANDBOX_ROOT/bin:$PATH"
    export HOME="$SANDBOX_HOME"

    # Provide higher-level mocks for desktop utilities used by scripts
    # cliphist: output sample clipboard entries
    cat > "$SANDBOX_ROOT/bin/cliphist" <<'EOF'
#!/usr/bin/env bash
echo "first snippet"
echo "second snippet"
echo "third snippet"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/cliphist"

    # wofi: read stdin, return a chosen line (env SANDBOX_WOFI_CHOICE overrides)
    cat > "$SANDBOX_ROOT/bin/wofi" <<'EOF'
#!/usr/bin/env bash
if [ -n "${SANDBOX_WOFI_CHOICE:-}" ]; then
    printf '%s' "$SANDBOX_WOFI_CHOICE"
    exit 0
fi
# by default output the first line from stdin
awk 'NR==1{print; exit}'
EOF
    chmod +x "$SANDBOX_ROOT/bin/wofi"

    # wl-copy: read stdin and log the copied content
    cat > "$SANDBOX_ROOT/bin/wl-copy" <<'EOF'
#!/usr/bin/env bash
content=$(cat -)
echo "[MOCK-WL-COPY] $content" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/wl-copy"

    # wal (pywal) mock — log the invocation and create dummy colors
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
        "color0": "#1e1e1e",
        "color1": "#bf616a",
        "color2": "#a3be8c",
        "color3": "#ebcb8b",
        "color4": "#81a1c1",
        "color5": "#b48ead",
        "color6": "#88c0d0",
        "color7": "#e5e9f0",
        "color8": "#4c566a",
        "color9": "#bf616a",
        "color10": "#a3be8c",
        "color11": "#ebcb8b",
        "color12": "#81a1c1",
        "color13": "#b48ead",
        "color14": "#8fbcbb",
        "color15": "#eceff4"
    }
}
JSON
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/wal"

    # swww mock — log the invocation
    cat > "$SANDBOX_ROOT/bin/swww" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] swww $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/swww"

    # swaylock-effects and swaylock mocks
    cat > "$SANDBOX_ROOT/bin/swaylock-effects" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] swaylock-effects $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/swaylock-effects"

    cat > "$SANDBOX_ROOT/bin/swaylock" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] swaylock $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/swaylock"

    # Provide a safe TMPDIR to avoid interfering with real /tmp state
    export TEST_TMPDIR="$SANDBOX_ROOT/tmp"
    mkdir -p "$TEST_TMPDIR"

    # Copy the repo into the sandbox so stow -n -v and stow -R solve relative paths
    # but we will mock stow so it's not necessary; still ensure safe cwd
    SANDBOX_REPO="$SANDBOX_ROOT/repo"
    mkdir -p "$SANDBOX_REPO"
    cp -a "$(pwd)"/* "$SANDBOX_REPO/" || true
    export SANDBOX_REPO
}

# ─────────────────────────── Audio mocks (pactl/wpctl) ───────────────────────
# install_audio_mocks
#   Drops in deterministic mocks for pactl and wpctl so audio-status / audio-set
#   can be tested without a running pipewire session. Mocks read fixture data
#   from $SANDBOX_AUDIO and log writes to $SANDBOX_ROOT/calls.log.
#
# Exposed env knobs:
#   SANDBOX_DEFAULT_SINK    name of default sink   (default: alsa_output.test.analog-stereo)
#   SANDBOX_DEFAULT_SOURCE  name of default source (default: alsa_input.test.analog-stereo)
#   SANDBOX_SINK_VOLUME     0-150
#   SANDBOX_SINK_MUTED      yes|no
#   SANDBOX_SOURCE_VOLUME   0-150
#   SANDBOX_SOURCE_MUTED    yes|no
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

# `pactl -f json list sinks|sources`
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
    # Emit a couple of fake events then exit so --watch tests don't hang.
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

# install_bluetooth_mocks
#   Mocks bluetoothctl + a fake /sys/class/bluetooth/hci0 directory so
#   bluetooth-status returns deterministic data.
#
#   SANDBOX_BT_AVAILABLE   yes|no  (default yes)
#   SANDBOX_BT_POWERED     yes|no  (default no)
#   SANDBOX_BT_CONNECTED   space-separated "MAC|Name" pairs (default empty)
install_bluetooth_mocks() {
    : "${SANDBOX_BT_AVAILABLE:=yes}"
    : "${SANDBOX_BT_POWERED:=no}"
    : "${SANDBOX_BT_CONNECTED:=}"
    export SANDBOX_BT_AVAILABLE SANDBOX_BT_POWERED SANDBOX_BT_CONNECTED

    if [ "$SANDBOX_BT_AVAILABLE" = "yes" ]; then
        mkdir -p "$SANDBOX_ROOT/sys/class/bluetooth/hci0"
        # bluetooth-status uses /sys/class/bluetooth/hci* via compgen, which
        # checks the real path. We can't redirect that, so the script's
        # adapter_present must accept an env override for tests.
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

cleanup_sandbox() {
    if [ -n "${SANDBOX_ROOT:-}" ] && [ -d "$SANDBOX_ROOT" ]; then
        rm -rf "$SANDBOX_ROOT"
    fi
}

run_install_sh() {
    # Run the real install.sh but with PATH and HOME pointed to sandbox
    # Run from the repo root so the script's stow targets are available
    (cd "$SANDBOX_REPO" && bash ./install.sh)
}
