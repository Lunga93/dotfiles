#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    RESTORE_WALLPAPER="$SANDBOX_REPO/scripts/.local/bin/restore-wallpaper"
    SET_WALLPAPER="$SANDBOX_REPO/scripts/.local/bin/set-wallpaper"

    mkdir -p "$SANDBOX_HOME/Pictures/wallpapers"
    mkdir -p "$SANDBOX_HOME/.config"
    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"

    cat > "$SANDBOX_ROOT/bin/set-wallpaper" <<'EOF'
#!/usr/bin/env bash
echo "set-wallpaper called with: $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/set-wallpaper"

    DEFAULT_WP="$SANDBOX_HOME/Pictures/wallpapers/manatee-deep-dive.png"
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
make_png('$DEFAULT_WP', 50, 50, 50)
" 2>/dev/null || touch "$DEFAULT_WP"

    CUSTOM_WP="$SANDBOX_HOME/Pictures/wallpapers/custom.png"
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
make_png('$CUSTOM_WP', 200, 100, 50)
" 2>/dev/null || touch "$CUSTOM_WP"
}

teardown() {
    cleanup_sandbox
}

@test "restore-wallpaper: uses saved state when available" {
    echo "$CUSTOM_WP" > "$SANDBOX_HOME/.config/current_wallpaper"

    run bash "$RESTORE_WALLPAPER"
    [ "$status" -eq 0 ]
    grep -q "set-wallpaper called" "$SANDBOX_ROOT/calls.log"
    grep -q "$CUSTOM_WP" "$SANDBOX_ROOT/calls.log"
}

@test "restore-wallpaper: falls back to default wallpaper when no state" {
    run bash "$RESTORE_WALLPAPER"
    [ "$status" -eq 0 ]
    grep -q "set-wallpaper called" "$SANDBOX_ROOT/calls.log"
}

@test "restore-wallpaper: skips when saved wallpaper file missing" {
    echo "/nonexistent/path.png" > "$SANDBOX_HOME/.config/current_wallpaper"

    run bash "$RESTORE_WALLPAPER"
    [ "$status" -eq 0 ]
}

@test "restore-wallpaper: exits cleanly when nothing to restore" {
    rm -f "$DEFAULT_WP"

    run bash "$RESTORE_WALLPAPER"
    [ "$status" -eq 0 ]
}

@test "restore-wallpaper: exits with error when set-wallpaper missing" {
    rm -f "$SANDBOX_ROOT/bin/set-wallpaper"
    rm -f "$SANDBOX_REPO/scripts/.local/bin/set-wallpaper" 2>/dev/null || true
    echo "$CUSTOM_WP" > "$SANDBOX_HOME/.config/current_wallpaper"

    run bash "$RESTORE_WALLPAPER"
    [ "$status" -eq 1 ]
}
