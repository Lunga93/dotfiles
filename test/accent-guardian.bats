#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    ACCENT_GUARDIAN="$SANDBOX_REPO/scripts/.local/bin/accent-guardian"

    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"
    mkdir -p "$SANDBOX_HOME/.cache/wal"
    mkdir -p "$SANDBOX_HOME/.local/bin"

    cat > "$SANDBOX_HOME/.cache/wal/colors.json" <<'JSON'
{"colors":{"color2":"#a3be8c"}}
JSON

    cat > "$SANDBOX_HOME/.local/bin/fetch-wallpaper" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK-FETCH] remediation fetch" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_HOME/.local/bin/fetch-wallpaper"
}

teardown() {
    cleanup_sandbox
}

@test "accent-guardian: runs without error when colors.json missing" {
    rm -f "$SANDBOX_HOME/.cache/wal/colors.json"
    run bash "$ACCENT_GUARDIAN" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "accent-guardian: detects accent change" {
    echo '#a3be8c' > "$SANDBOX_HOME/.local/share/dotfiles/last_color2"

    # Change the accent in colors.json
    cat > "$SANDBOX_HOME/.cache/wal/colors.json" <<'JSON'
{"colors":{"color2":"#bf616a"}}
JSON

    run bash "$ACCENT_GUARDIAN" 2>/dev/null || true
    [ "$status" -eq 0 ]
    [ "$(cat "$SANDBOX_HOME/.local/share/dotfiles/last_color2")" = "#bf616a" ]
}

@test "accent-guardian: increments count on repeated accent" {
    echo '#a3be8c' > "$SANDBOX_HOME/.local/share/dotfiles/last_color2"
    echo "1" > "$SANDBOX_HOME/.local/share/dotfiles/accent_stagnant_count"

    run bash "$ACCENT_GUARDIAN" 2>/dev/null || true
    [ "$status" -eq 0 ]
    [ "$(cat "$SANDBOX_HOME/.local/share/dotfiles/accent_stagnant_count")" = "2" ]
}

@test "accent-guardian: triggers remediation on threshold breach" {
    echo '#a3be8c' > "$SANDBOX_HOME/.local/share/dotfiles/last_color2"
    echo "3" > "$SANDBOX_HOME/.local/share/dotfiles/accent_stagnant_count"

    run bash "$ACCENT_GUARDIAN" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "\[MOCK-FETCH\] remediation fetch" "$SANDBOX_ROOT/calls.log"
}
