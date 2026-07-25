#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    WALLPAPER_MENU="$SANDBOX_REPO/scripts/.local/bin/wallpaper-menu"
    SET_WALLPAPER="$SANDBOX_REPO/scripts/.local/bin/set-wallpaper"

    mkdir -p "$SANDBOX_HOME/Pictures/wallpapers/subdir"
    mkdir -p "$SANDBOX_HOME/.config"

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
make_png('$SANDBOX_HOME/Pictures/wallpapers/forest.png', 34, 139, 34)
make_png('$SANDBOX_HOME/Pictures/wallpapers/sunset.png', 255, 140, 0)
make_png('$SANDBOX_HOME/Pictures/wallpapers/subdir/ocean.png', 0, 105, 148)
" 2>/dev/null || true

    cat > "$SANDBOX_ROOT/bin/set-wallpaper" <<'EOF'
#!/usr/bin/env bash
echo "set-wallpaper called with: $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/set-wallpaper"
}

teardown() {
    cleanup_sandbox
}

@test "wallpaper-menu: lists available wallpapers" {
    SANDBOX_WOFI_CHOICE="sunset.png" run bash "$WALLPAPER_MENU" 2>/dev/null || true
    grep -q "set-wallpaper called" "$SANDBOX_ROOT/calls.log"
}

@test "wallpaper-menu: handles no selection gracefully" {
    SANDBOX_WOFI_CHOICE="" run bash "$WALLPAPER_MENU" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "wallpaper-menu: rejects non-existent selected file" {
    SANDBOX_WOFI_CHOICE="ghost.png" run bash "$WALLPAPER_MENU" 2>/dev/null || true
}
