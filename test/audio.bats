#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox
    install_audio_mocks
    AUDIO_STATUS="$SANDBOX_REPO/scripts/.local/bin/audio-status"
    AUDIO_SET="$SANDBOX_REPO/scripts/.local/bin/audio-set"
}

teardown() {
    cleanup_sandbox
}

# ────────────────────────── audio-status snapshot ────────────────────────────

@test "audio-status emits valid JSON" {
    run "$AUDIO_STATUS"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e . >/dev/null
}

@test "audio-status reports default sink with volume + mute" {
    SANDBOX_SINK_VOLUME=65 SANDBOX_SINK_MUTED=no run "$AUDIO_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.sink.name')" = "alsa_output.test.analog-stereo" ]
    [ "$(echo "$output" | jq -r '.sink.volume')" = "65" ]
    [ "$(echo "$output" | jq -r '.sink.muted')" = "false" ]
    [ "$(echo "$output" | jq -r '.sink.default')" = "true" ]
}

@test "audio-status reports default source" {
    SANDBOX_SOURCE_VOLUME=80 SANDBOX_SOURCE_MUTED=yes run "$AUDIO_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq -r '.source.name')" = "alsa_input.test.analog-stereo" ]
    [ "$(echo "$output" | jq -r '.source.volume')" = "80" ]
    [ "$(echo "$output" | jq -r '.source.muted')" = "true" ]
}

@test "audio-status enumerates all sinks with friendly labels" {
    run "$AUDIO_STATUS"
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | jq '.sinks | length')" = "2" ]
    # Analog sink → "Speakers (Analog)"
    [ "$(echo "$output" | jq -r '.sinks[] | select(.name | contains("analog")) | .label')" = "Speakers (Analog)" ]
    # HDMI sink → "HDMI"
    [ "$(echo "$output" | jq -r '.sinks[] | select(.name | contains("hdmi")) | .label')" = "HDMI" ]
}

@test "audio-status filters monitor sources" {
    run "$AUDIO_STATUS"
    [ "$status" -eq 0 ]
    # Two sources in fixture; one is a monitor and must be filtered out.
    [ "$(echo "$output" | jq '.sources | length')" = "1" ]
    [ "$(echo "$output" | jq -r '.sources[0].label')" = "Microphone (Analog)" ]
}

@test "audio-status marks the active sink with default:true" {
    run "$AUDIO_STATUS"
    [ "$status" -eq 0 ]
    local defaults
    defaults=$(echo "$output" | jq '[.sinks[] | select(.default)] | length')
    [ "$defaults" = "1" ]
}

@test "audio-status --pretty produces multi-line output" {
    run "$AUDIO_STATUS" --pretty
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -gt 5 ]
}

# ────────────────────────────── audio-set ────────────────────────────────────

@test "audio-set sink calls wpctl set-default" {
    run "$AUDIO_SET" sink 47
    [ "$status" -eq 0 ]
    grep -q "wpctl set-default 47" "$SANDBOX_ROOT/calls.log"
}

@test "audio-set source calls wpctl set-default" {
    run "$AUDIO_SET" source 55
    [ "$status" -eq 0 ]
    grep -q "wpctl set-default 55" "$SANDBOX_ROOT/calls.log"
}

@test "audio-set sink-volume +5 issues a relative wpctl command" {
    run "$AUDIO_SET" sink-volume +5
    [ "$status" -eq 0 ]
    grep -qE "wpctl set-volume -l 1\\.5 @DEFAULT_AUDIO_SINK@ 5%\\+" "$SANDBOX_ROOT/calls.log"
}

@test "audio-set sink-volume -10 issues a relative decrement" {
    run "$AUDIO_SET" sink-volume -10
    [ "$status" -eq 0 ]
    grep -qE "wpctl set-volume -l 1\\.5 @DEFAULT_AUDIO_SINK@ 10%-" "$SANDBOX_ROOT/calls.log"
}

@test "audio-set sink-volume 65 (absolute) converts to 0.65" {
    run "$AUDIO_SET" sink-volume 65
    [ "$status" -eq 0 ]
    grep -qE "wpctl set-volume -l 1\\.5 @DEFAULT_AUDIO_SINK@ 0\\.65" "$SANDBOX_ROOT/calls.log"
}

@test "audio-set source-volume targets the source sink" {
    run "$AUDIO_SET" source-volume +5
    [ "$status" -eq 0 ]
    grep -q "@DEFAULT_AUDIO_SOURCE@" "$SANDBOX_ROOT/calls.log"
}

@test "audio-set mute sink toggles default sink" {
    run "$AUDIO_SET" mute sink
    [ "$status" -eq 0 ]
    grep -q "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" "$SANDBOX_ROOT/calls.log"
}

@test "audio-set mute source toggles default source" {
    run "$AUDIO_SET" mute source
    [ "$status" -eq 0 ]
    grep -q "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" "$SANDBOX_ROOT/calls.log"
}

@test "audio-set rejects unknown verb" {
    run "$AUDIO_SET" warpdrive 5
    [ "$status" -ne 0 ]
}

@test "audio-set rejects bad volume argument" {
    run "$AUDIO_SET" sink-volume loud
    [ "$status" -ne 0 ]
}
