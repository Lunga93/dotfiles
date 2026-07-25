#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    NIRI_KEYBIND="$BATS_TEST_DIRNAME/../scripts/.local/bin/niri-keybind"
    NIRI_CONFIG="$SANDBOX_HOME/.config/niri/config.kdl"
    mkdir -p "$(dirname "$NIRI_CONFIG")"

    cat > "$NIRI_CONFIG" <<'KDL'
binds {
    Mod+T { spawn "alacritty"; }
    Mod+SHIFT+C { close-window; }
    Mod+Q { quit; }
    Mod+SPACE { spawn "wofi"; }
}
KDL
}

teardown() {
    cleanup_sandbox
}

run_py() {
    local cov_cmd=()
    if command -v coverage >/dev/null 2>&1; then
        cov_cmd=(coverage run --append --branch -m)
    fi
    run "${cov_cmd[@]}" python3 "$@"
}

@test "niri-keybind list emits valid JSON array" {
    run_py "$NIRI_KEYBIND" --config "$NIRI_CONFIG" list
    [ "$status" -eq 0 ]
    echo "$output" | jq . >/dev/null
    count=$(echo "$output" | jq 'length')
    [ "$count" -eq 4 ]
}

@test "niri-keybind list includes expected keys" {
    run_py "$NIRI_KEYBIND" --config "$NIRI_CONFIG" list
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'map(select(.key == "Mod+T")) | length == 1' >/dev/null
    echo "$output" | jq -e 'map(select(.key == "Mod+SHIFT+C")) | length == 1' >/dev/null
}

@test "niri-keybind validate accepts valid key" {
    run_py "$NIRI_KEYBIND" validate "Mod+T"
    [ "$status" -eq 0 ]
}

@test "niri-keybind validate rejects empty string" {
    run_py "$NIRI_KEYBIND" validate ""
    [ "$status" -eq 4 ]
}

@test "niri-keybind set rebinds key atomically" {
    local bak="$NIRI_CONFIG.bak"
    cp "$NIRI_CONFIG" "$bak"
    run_py "$NIRI_KEYBIND" --config "$NIRI_CONFIG" set "Mod+T" "Mod+RETURN"
    [ "$status" -eq 0 ]
    run grep -c "Mod+T" "$NIRI_CONFIG" || true
    [ "${output:-0}" -eq 0 ]
    run grep -c "Mod+RETURN" "$NIRI_CONFIG" || true
    [ "${output:-0}" -eq 1 ]
    run grep -c "Mod+Q" "$NIRI_CONFIG" || true
    [ "${output:-0}" -eq 1 ]
    mv "$bak" "$NIRI_CONFIG"
}

@test "niri-keybind set preserves indent" {
    local bak="$NIRI_CONFIG.bak"
    cp "$NIRI_CONFIG" "$bak"
    run_py "$NIRI_KEYBIND" --config "$NIRI_CONFIG" set "Mod+SPACE" "Mod+D"
    [ "$status" -eq 0 ]
    run grep -c "    Mod+D" "$NIRI_CONFIG" || true
    [ "${output:-0}" -eq 1 ]
    mv "$bak" "$NIRI_CONFIG"
}

@test "niri-keybind set no-ops on same key" {
    local bak="$NIRI_CONFIG.bak"
    cp "$NIRI_CONFIG" "$bak"
    run_py "$NIRI_KEYBIND" --config "$NIRI_CONFIG" set "Mod+T" "Mod+T"
    [ "$status" -eq 0 ]
    diff "$bak" "$NIRI_CONFIG"
    mv "$bak" "$NIRI_CONFIG"
}

@test "niri-keybind set reports conflict for already-bound key" {
    run_py "$NIRI_KEYBIND" --config "$NIRI_CONFIG" set "Mod+T" "Mod+Q"
    [ "$status" -eq 2 ]
}

@test "niri-keybind set reports not-found for missing key" {
    run_py "$NIRI_KEYBIND" --config "$NIRI_CONFIG" set "Mod+Z" "Mod+X"
    [ "$status" -eq 3 ]
}

@test "niri-keybind get returns JSON for existing key" {
    run_py "$NIRI_KEYBIND" --config "$NIRI_CONFIG" get "Mod+T"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.key == "Mod+T"' >/dev/null
}

@test "niri-keybind selftest passes" {
    run_py "$NIRI_KEYBIND" selftest
    [ "$status" -eq 0 ]
    [[ "$output" =~ "all selftests passed" ]]
}
