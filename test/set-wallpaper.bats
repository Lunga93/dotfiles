#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    SET_WALLPAPER="$SANDBOX_REPO/scripts/.local/bin/set-wallpaper"
    APPLY_THEME="$SANDBOX_REPO/scripts/.local/bin/apply-theme"

    mkdir -p "$SANDBOX_HOME/Pictures/wallpapers"
    mkdir -p "$SANDBOX_HOME/.config"
    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"

    WALLPAPER="$SANDBOX_HOME/Pictures/wallpapers/test.png"
    python3 -c "
import struct, zlib
def make_png(path, r, g, b):
    raw = b''
    for _ in range(10):
        raw += b'\x00' + bytes([r, g, b])
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', struct.pack('>IIBBBBB', 10, 1, 8, 2, 0, 0, 0)))
        f.write(chunk(b'IDAT', zlib.compress(raw)))
        f.write(chunk(b'IEND', b''))
make_png('$WALLPAPER', 100, 150, 200)
"
}

teardown() {
    cleanup_sandbox
}

@test "set-wallpaper: requires image path argument" {
    run bash "$SET_WALLPAPER"
    [ "$status" -eq 2 ]
}

@test "set-wallpaper: saves state file" {
    run bash "$SET_WALLPAPER" "$WALLPAPER"
    [ "$status" -eq 0 ]
    [ -f "$SANDBOX_HOME/.config/current_wallpaper" ]
    [ "$(cat "$SANDBOX_HOME/.config/current_wallpaper")" = "$WALLPAPER" ]
}

@test "set-wallpaper: calls awww with image" {
    run bash "$SET_WALLPAPER" "$WALLPAPER"
    [ "$status" -eq 0 ]
    grep -q "awww img" "$SANDBOX_ROOT/calls.log"
}

@test "set-wallpaper: falls back when awww missing" {
    rm -f "$SANDBOX_ROOT/bin/awww"
    run bash "$SET_WALLPAPER" "$WALLPAPER"
    [ "$status" -eq 0 ]
}

@test "set-wallpaper: invokes apply-theme via PATH" {
    cat > "$SANDBOX_ROOT/bin/apply-theme" <<'EOF'
#!/usr/bin/env bash
echo "apply-theme called with: $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/apply-theme"

    run bash "$SET_WALLPAPER" "$WALLPAPER"
    [ "$status" -eq 0 ]
    grep -q "apply-theme called" "$SANDBOX_ROOT/calls.log"
}

@test "set-wallpaper: invokes apply-theme via sibling path when not in PATH" {
    rm -f "$SANDBOX_ROOT/bin/apply-theme" 2>/dev/null || true
    cat > "$SANDBOX_REPO/scripts/.local/bin/apply-theme" <<'EOF'
#!/usr/bin/env bash
echo "sibling apply-theme: $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_REPO/scripts/.local/bin/apply-theme"

    run bash "$SET_WALLPAPER" "$WALLPAPER"
    [ "$status" -eq 0 ]
    grep -q "sibling apply-theme" "$SANDBOX_ROOT/calls.log"
}
