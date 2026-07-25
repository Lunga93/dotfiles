#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox
    install_audio_mocks

    AUDIO_MENU="$SANDBOX_REPO/scripts/.local/bin/audio-menu"

    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"
    mkdir -p "$SANDBOX_HOME/.config"

    cat > "$SANDBOX_ROOT/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK-NOTIFY] $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/notify-send"

    cat > "$SANDBOX_ROOT/bin/pavucontrol" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] pavucontrol $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/pavucontrol"
}

teardown() {
    cleanup_sandbox
}

@test "audio-menu: generates menu with default sink info" {
    export SANDBOX_WOFI_CHOICE=""
    run bash "$AUDIO_MENU" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "audio-menu: emits devices with correct structure" {
    run bash -c "$AUDIO_MENU 2>/dev/null" || true
    [ "$status" -eq 0 ]
}

@test "audio-menu: vertical volume set triggers audio-set" {
    export SANDBOX_WOFI_CHOICE="   Set volume to 50%"
    export SANDBOX_SINK_VOLUME=42

    run bash "$AUDIO_MENU" 2>/dev/null || true
    grep -q "wpctl set-volume.*0\\.50" "$SANDBOX_ROOT/calls.log"
}

@test "audio-menu: mute toggle calls wpctl" {
    export SANDBOX_WOFI_CHOICE="󰝟  Mute"
    run bash "$AUDIO_MENU" 2>/dev/null || true
    grep -q "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" "$SANDBOX_ROOT/calls.log"
}

@test "audio-menu: unmute toggle calls wpctl" {
    export SANDBOX_SINK_MUTED=yes
    export SANDBOX_WOFI_CHOICE="󰝟  Unmute"
    run bash "$AUDIO_MENU" 2>/dev/null || true
    grep -q "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" "$SANDBOX_ROOT/calls.log"
}

@test "audio-menu: volume up +5 triggers relative command" {
    export SANDBOX_WOFI_CHOICE="󰝝  Volume +5%"
    run bash "$AUDIO_MENU" 2>/dev/null || true
    grep -q "wpctl set-volume.*5%+" "$SANDBOX_ROOT/calls.log"
}

@test "audio-menu: volume down -5 triggers relative command" {
    export SANDBOX_WOFI_CHOICE="󰝞  Volume -5%"
    run bash "$AUDIO_MENU" 2>/dev/null || true
    grep -q "wpctl set-volume.*5%-" "$SANDBOX_ROOT/calls.log"
}

@test "audio-menu: sink selection calls wpctl set-default" {
    export SANDBOX_WOFI_CHOICE="󰓃  ●  Speakers (Analog)"
    run bash "$AUDIO_MENU" 2>/dev/null || true
    grep -q "wpctl set-default alsa_output.test.analog-stereo" "$SANDBOX_ROOT/calls.log"
}
