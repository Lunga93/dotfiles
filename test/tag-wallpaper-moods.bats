#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    export HOME="$SANDBOX_HOME"
    export TAGGER="$SANDBOX_REPO/scripts/.local/bin/tag-wallpaper-moods"

    FIXTURE_DIR="$SANDBOX_HOME/fixtures/wallpapers"
    mkdir -p "$FIXTURE_DIR"

    python3 <<PYEOF
from PIL import Image

d = "$FIXTURE_DIR"

Image.new('RGB', (200, 200), (10, 10, 20)).save(f'{d}/dark.jpg')
Image.new('RGB', (200, 200), (240, 240, 245)).save(f'{d}/light.jpg')
Image.new('RGB', (200, 200), (204, 74, 58)).save(f'{d}/warm.jpg')
Image.new('RGB', (200, 200), (58, 95, 204)).save(f'{d}/cool.jpg')
Image.new('RGB', (200, 200), (165, 200, 230)).save(f'{d}/sky.jpg')
Image.new('RGB', (200, 200), (58, 74, 42)).save(f'{d}/earth.jpg')
PYEOF

    mkdir -p "$SANDBOX_HOME/.config/dotfiles"
    cat > "$SANDBOX_HOME/.config/dotfiles/settings.json" << EOF
{
    "wallpaper": {
        "library_dir": "$FIXTURE_DIR"
    }
}
EOF
}

teardown() {
    cleanup_sandbox
}

@test "tag-wallpaper-moods --version prints version" {
    run "$TAGGER" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.0.0" ]]
}

@test "tag-wallpaper-moods tags a single file and creates cache" {
    run "$TAGGER" --file "$FIXTURE_DIR/dark.jpg"
    [ "$status" -eq 0 ]
    [ -f "$SANDBOX_HOME/.cache/dotfiles/wallpaper-moods.json" ]
}

@test "tag-wallpaper-moods cache is versioned" {
    "$TAGGER" --file "$FIXTURE_DIR/dark.jpg"
    run python3 -c "import json; d=json.load(open('$SANDBOX_HOME/.cache/dotfiles/wallpaper-moods.json')); assert d['version'] == 1"
    [ "$status" -eq 0 ]
}

@test "tag-wallpaper-moods --force retags all files" {
    "$TAGGER" --file "$FIXTURE_DIR/dark.jpg"
    run "$TAGGER" --force
    [ "$status" -eq 0 ]
}

@test "tag-wallpaper-moods --file missing path exits with error" {
    run "$TAGGER" --file "$FIXTURE_DIR/nonexistent.jpg"
    [ "$status" -eq 1 ]
}

@test "tag-wallpaper-moods tags dark image with dark mood" {
    run "$TAGGER" --file "$FIXTURE_DIR/dark.jpg"
    [ "$status" -eq 0 ]
    run python3 -c "
import json
d=json.load(open('$SANDBOX_HOME/.cache/dotfiles/wallpaper-moods.json'))
for path, entry in d['tags'].items():
    if path.endswith('dark.jpg'):
        assert 'dark' in entry['moods'], f'Expected dark mood for dark.jpg, got {entry[\"moods\"]}'
        print('OK: dark.jpg has dark mood')
        break
"
    [ "$status" -eq 0 ]
}

@test "tag-wallpaper-moods tags light image with light mood" {
    run "$TAGGER" --file "$FIXTURE_DIR/light.jpg"
    [ "$status" -eq 0 ]
    run python3 -c "
import json
d=json.load(open('$SANDBOX_HOME/.cache/dotfiles/wallpaper-moods.json'))
for path, entry in d['tags'].items():
    if path.endswith('light.jpg'):
        assert 'light' in entry['moods'], f'Expected light mood for light.jpg, got {entry[\"moods\"]}'
        print('OK: light.jpg has light mood')
        break
"
    [ "$status" -eq 0 ]
}
