#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    CLIPBOARD_MANAGER="$SANDBOX_REPO/scripts/.local/bin/clipboard-manager"

    cat > "$SANDBOX_ROOT/bin/cliphist" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    list)   echo "item1: first clipboard entry"
            echo "item2: second entry" ;;
    decode) cat - ;;
    *)      echo "item1: first"; echo "item2: second" ;;
esac
EOF
    chmod +x "$SANDBOX_ROOT/bin/cliphist"

    cat > "$SANDBOX_ROOT/bin/wl-copy" <<'EOF'
#!/usr/bin/env bash
content=$(cat -)
echo "[MOCK-WL-COPY] $content" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/wl-copy"
}

teardown() {
    cleanup_sandbox
}

@test "clipboard-manager: selects and copies first history item" {
    export SANDBOX_WOFI_CHOICE="item1: first clipboard entry"

    run bash "$CLIPBOARD_MANAGER" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "\[MOCK-WL-COPY\]" "$SANDBOX_ROOT/calls.log"
}

@test "clipboard-manager: handles empty selection" {
    export SANDBOX_WOFI_CHOICE=""

    run bash "$CLIPBOARD_MANAGER" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "clipboard-manager: exits cleanly on empty history" {
    cat > "$SANDBOX_ROOT/bin/cliphist" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/cliphist"

    run bash "$CLIPBOARD_MANAGER" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "clipboard-manager: handles missing wl-copy gracefully" {
    export SANDBOX_WOFI_CHOICE="item1: first clipboard entry"
    rm -f "$SANDBOX_ROOT/bin/wl-copy"

    run bash "$CLIPBOARD_MANAGER" 2>/dev/null || true
    [ "$status" -eq 0 ]
}
