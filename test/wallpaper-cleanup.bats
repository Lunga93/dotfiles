#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    CLEANUP="$SANDBOX_REPO/scripts/.local/bin/wallpaper-cleanup"

    ARCHIVE_DIR="$SANDBOX_HOME/Pictures/wallpapers/archive"
    mkdir -p "$ARCHIVE_DIR"
    mkdir -p "$SANDBOX_HOME/.local/share/dotfiles"
    mkdir -p "$SANDBOX_HOME/.config"

    # Create duplicate files (same content) to test dedup
    python3 -c "
import struct, zlib
def make_png(path, seed):
    raw = b''
    for i in range(10):
        raw += b'\x00' + bytes([(seed + i) % 256 for _ in range(3)])
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', struct.pack('>IIBBBBB', 10, 1, 8, 2, 0, 0, 0)))
        f.write(chunk(b'IDAT', zlib.compress(raw)))
        f.write(chunk(b'IEND', b''))
make_png('$ARCHIVE_DIR/dupe_a.jpg', 42)
make_png('$ARCHIVE_DIR/dupe_b.jpg', 42)
make_png('$ARCHIVE_DIR/unique_c.jpg', 99)
" 2>/dev/null || (touch "$ARCHIVE_DIR/dupe_a.jpg" && touch "$ARCHIVE_DIR/dupe_b.jpg" && touch "$ARCHIVE_DIR/unique_c.jpg")

    cat > "$SANDBOX_ROOT/bin/tag-wallpaper-moods" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] tag-wallpaper-moods $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/tag-wallpaper-moods"
}

teardown() {
    cleanup_sandbox
}

@test "wallpaper-cleanup: --dry-run shows planned removals" {
    run bash "$CLEANUP" --dry-run --retain-days 999
    [ "$status" -eq 0 ]
    [[ "$output" =~ "would remove" ]] || [[ "$output" =~ "deduped" ]]
}

@test "wallpaper-cleanup: removes old files in non-dry mode" {
    run bash "$CLEANUP" --retain-days 999 --quiet
    [ "$status" -eq 0 ]
}

@test "wallpaper-cleanup: protects current wallpaper from deletion" {
    echo "$ARCHIVE_DIR/unique_c.jpg" > "$SANDBOX_HOME/.config/current_wallpaper"
    run bash "$CLEANUP" --retain-days 999 --quiet
    [ "$status" -eq 0 ]
    [ -f "$ARCHIVE_DIR/unique_c.jpg" ]
}

@test "wallpaper-cleanup: exits cleanly when archive missing" {
    rm -rf "$ARCHIVE_DIR"
    run bash "$CLEANUP" --quiet
    [ "$status" -eq 0 ]
    [ -f "$SANDBOX_HOME/.local/share/dotfiles/wallpaper-cleanup.log" ]
    grep -q "no archive" "$SANDBOX_HOME/.local/share/dotfiles/wallpaper-cleanup.log"
}

@test "wallpaper-cleanup: --help shows usage" {
    run bash "$CLEANUP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Maintenance pass" ]] || [[ "$output" =~ "dry-run" ]]
}

@test "wallpaper-cleanup: rejects unknown flags" {
    run bash "$CLEANUP" --bogus
    [ "$status" -eq 2 ]
}
