# Settings App (Mood Browser) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Quickshell settings wallpaper page into a mood-led browser (Dark/Light/Warm/Cool/Sky/Earth) with animated window expansion, preserving all mandatory controls.

**Architecture:** 18 flat QML files reorganized into `settings/` hierarchy (data/components/pages). Python mood tagger (`tag-wallpaper-moods`) classifies wallpapers via Pillow + OKLab/OKLCH. Window height animates 640→900px on mood selection. All mandatory controls (folder, frequency, schedule, sources) remain as always-visible cards below the mood grid.

**Tech Stack:** Quickshell (Qt6/QML), Python 3 + Pillow, bats-core testing, systemd timers, stow

---

### Phase A: File Migration + Settings Directory Structure

#### Task A1: Create settings/ directory and migrate flat files per migration table

**Files:**
- Modify: `quickshell/.config/quickshell/qmldir`
- Create: all `settings/` subdirectories
- Move (via git mv, then update paths): all 18 flat files to their target locations

**Migration table (from spec):**

| Current (flat) | Target | Action |
|---|---|---|
| `SettingsWindow.qml`, `SettingsSidebar.qml`, `SettingsContent.qml` | `settings/` | Move; update `qmldir` |
| `SettingsStore.qml`, `Categories.qml` | `settings/data/` | Move; update `qmldir` |
| `ToggleSwitch.qml`, `PillSelector.qml`, `ColorSwatch.qml`, `PhosphorIcon.qml`, `SettingsGroup.qml`, `SettingsRow.qml` | `settings/components/` | Move; update `qmldir` |
| `PlaceholderPage.qml` | `settings/pages/` | Move; update `qmldir` |
| `WallpaperPage.qml` | `settings/pages/wallpaper/WallpaperPage.qml` | Refactor (handled in Phase E) |
| `WallpaperLibrary.qml` | — | **DELETE** |
| `RecentHistory.qml` | — | **DELETE** |
| `DerivedPalette.qml` | — | **DELETE** |
| `FrequencyPicker.qml` | `settings/pages/wallpaper/ScheduleCard.qml` | Repurpose (handled in Phase D) |
| `SourceManager.qml` | `settings/pages/wallpaper/SourcesCard.qml` | Repurpose (handled in Phase D) |

- [ ] **Step 1: Create directory structure**

```bash
cd quickshell/.config/quickshell
mkdir -p settings/components
mkdir -p settings/pages/wallpaper
mkdir -p settings/data
```

- [ ] **Step 2: Move files to settings/ root**

```bash
git mv SettingsWindow.qml settings/SettingsWindow.qml
git mv SettingsSidebar.qml settings/SettingsSidebar.qml
git mv SettingsContent.qml settings/SettingsContent.qml
```

- [ ] **Step 3: Move files to settings/components/**

```bash
git mv ToggleSwitch.qml settings/components/ToggleSwitch.qml
git mv PillSelector.qml settings/components/PillSelector.qml
git mv ColorSwatch.qml settings/components/ColorSwatch.qml
git mv PhosphorIcon.qml settings/components/PhosphorIcon.qml
git mv SettingsGroup.qml settings/components/SettingsGroup.qml
git mv SettingsRow.qml settings/components/SettingsRow.qml
```

- [ ] **Step 4: Move files to settings/data/**

```bash
git mv SettingsStore.qml settings/data/SettingsStore.qml
git mv Categories.qml settings/data/Categories.qml
```

- [ ] **Step 5: Move PlaceholderPage to settings/pages/**

```bash
git mv PlaceholderPage.qml settings/pages/PlaceholderPage.qml
```

- [ ] **Step 6: Move WallpaperPage to settings/pages/wallpaper/**

```bash
git mv WallpaperPage.qml settings/pages/wallpaper/WallpaperPage.qml
```

- [ ] **Step 7: Delete obsolete files**

```bash
git rm WallpaperLibrary.qml
git rm RecentHistory.qml
git rm DerivedPalette.qml
```

- [ ] **Step 8: Keep FrequencyPicker.qml and SourceManager.qml in place (Phase D handles cleanup)**

These files stay at their current locations until Phase D creates their replacements (ScheduleCard.qml and SourcesCard.qml). At the end of Phase D, Step 3 will delete them and update qmldir.

- [ ] **Step 9: Update qmldir with new paths**

Replace current qmldir (54 lines, flat) with updated one referencing `settings/` subdirectories. The qmldir stays at `quickshell/.config/quickshell/qmldir`:

```
singleton Theme 1.0 Theme.qml
singleton Globals 1.0 Globals.qml
singleton AudioNames 1.0 AudioNames.qml

Card 1.0 Card.qml
Popout 1.0 Popout.qml
IconButton 1.0 IconButton.qml
VolumeSlider 1.0 VolumeSlider.qml
VolumeRow 1.0 VolumeRow.qml
DeviceChip 1.0 DeviceChip.qml
AudioPanel 1.0 AudioPanel.qml

BarPill 1.0 BarPill.qml
BarIconButton 1.0 BarIconButton.qml
BarText 1.0 BarText.qml
Bar 1.0 Bar.qml
Indicator 1.0 Indicator.qml

WorkspacesSegment 1.0 WorkspacesSegment.qml
TaskbarSegment 1.0 TaskbarSegment.qml
TraySegment 1.0 TraySegment.qml
BluetoothSegment 1.0 BluetoothSegment.qml
VolumeSegment 1.0 VolumeSegment.qml
ClockSegment 1.0 ClockSegment.qml
ClipboardButton 1.0 ClipboardButton.qml
PowerButton 1.0 PowerButton.qml

CalendarPopout 1.0 CalendarPopout.qml
PowerMenuPopout 1.0 PowerMenuPopout.qml

# Settings app
SettingsWindow 1.0 settings/SettingsWindow.qml
SettingsSidebar 1.0 settings/SettingsSidebar.qml
SettingsContent 1.0 settings/SettingsContent.qml
PlaceholderPage 1.0 settings/pages/PlaceholderPage.qml

# Settings components
PhosphorIcon 1.0 settings/components/PhosphorIcon.qml
ToggleSwitch 1.0 settings/components/ToggleSwitch.qml
SettingsRow 1.0 settings/components/SettingsRow.qml
SettingsGroup 1.0 settings/components/SettingsGroup.qml
PillSelector 1.0 settings/components/PillSelector.qml
ColorSwatch 1.0 settings/components/ColorSwatch.qml

# Settings data singletons
singleton SettingsStore 1.0 settings/data/SettingsStore.qml
singleton Categories 1.0 settings/data/Categories.qml
```

Note: `MoodCatalog`, `MoodGrid`, `MoodTile`, `WallpaperHero`, `WallpaperGrid`, `ScheduleCard`, and `SourcesCard` do NOT exist yet — they will be added to `qmldir` in a batch update at the end of Phase D.

- [ ] **Step 10: Verify the application still loads**

Run `qs` and toggle the settings window with `qs ipc call settings toggle`. Verify the window opens, sidebar renders, and Wallpaper page shows. Expected: existing functionality preserved despite file moves and deletions.

If errors occur, check qmldir paths are correct and all imports resolve.

- [ ] **Step 11: Commit** (staged by git mv in steps 2-7)

```bash
git commit -m "refactor(settings): migrate flat QML files into settings/ subdirectory

Organize 18 settings files into settings/{components,pages,data}/ per
spec migration table. Delete obsolete RecentHistory.qml, WallpaperLibrary.qml,
DerivedPalette.qml. Update qmldir with new subdirectory paths.

Migration table:
- settings/         SettingsWindow, Sidebar, Content (root)
- settings/components/  ToggleSwitch, PillSelector, ColorSwatch, PhosphorIcon, SettingsGroup, SettingsRow
- settings/data/        SettingsStore (singleton), Categories (singleton)
- settings/pages/       PlaceholderPage
- settings/pages/wallpaper/ WallpaperPage (refactored in later phase)

Decisions made: Preserved FrequencyPicker.qml/SourceManager.qml in flat
location until Phase D creates their replacements (ScheduleCard.qml,
SourcesCard.qml), then deleted."
```

---

### Phase B: Mood Tagger Script + Tests

#### Task B1: Write the `tag-wallpaper-moods` Python script

**Files:**
- Create: `scripts/.local/bin/tag-wallpaper-moods`
- Create: `test/tag-wallpaper-moods.bats`
- Create: `test/fixtures/wallpapers/` (fixture images for each mood)
- Modify: `scripts/.local/bin/set-wallpaper` (add mood-tag hook on line ~79 after `apply-theme`)

- [ ] **Step 1: Create the tagger script** at `scripts/.local/bin/tag-wallpaper-moods`

```python
#!/usr/bin/env python3
"""tag-wallpaper-moods — Classify wallpapers by mood using OKLab/OKLCH.

Moods: dark, light, warm, cool, sky, earth.
Pipeline: Pillow median-cut (8 colors) → OKLab → OKLCH → rule table.
Cache: ~/.cache/dotfiles/wallpaper-moods.json (versioned, atomic write).

CLI:
  tag-wallpaper-moods                 # incremental — new/changed only
  tag-wallpaper-moods --force         # re-tag everything
  tag-wallpaper-moods --file PATH     # single image (used by set-wallpaper hook)
  tag-wallpaper-moods --quiet         # suppress stdout progress
  tag-wallpaper-moods --debug-print   # print classification stats
  tag-wallpaper-moods --version       # print version
"""
import argparse
import concurrent.futures
import json
import os
import sys
import tempfile
import time
from pathlib import Path

VERSION = "1.0.0"

# --- OKLab/OKLCH conversion (pure Python, ~30 lines) ---

def linear_srgb_to_oklab(r, g, b):
    """Convert linear sRGB [0,1] to OKLab."""
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l = l ** (1/3)
    m = m ** (1/3)
    s = s ** (1/3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )

def oklab_to_oklch(L, a, b):
    """OKLab → OKLCH."""
    import math
    C = math.sqrt(a * a + b * b)
    h = math.degrees(math.atan2(b, a)) % 360
    return L, C, h

# --- Mood rules (mirrored from MoodCatalog.qml) ---

MOOD_RULES = {
    "dark":  lambda s: s["L_avg"] < 0.40,
    "light": lambda s: s["L_avg"] > 0.75,
    "warm":  lambda s: 20 <= s["h_dom"] <= 95 and s["C_avg"] > 0.05,
    "cool":  lambda s: 200 <= s["h_dom"] <= 290 and s["C_avg"] > 0.05,
    "sky":   lambda s: (
        any(h in range(220, 251) and L > 0.55 and C < 0.10 for (L, C, h) in s["colors"])
        and s["C_avg"] < 0.08
    ),
    "earth": lambda s: (
        any(h in range(120, 161) for (_, _, h) in s["colors"])
        and any(h in range(50, 91) and C < 0.10 for (_, C, h) in s["colors"])
    ),
}

# --- Palette extraction ---

def extract_palette(image_path, num_colors=8, size=(200, 200)):
    """Downscale image, extract dominant colors via median-cut, return OKLCH stats."""
    from PIL import Image

    img = Image.open(image_path)
    img = img.convert("RGB")
    img.thumbnail(size, Image.LANCZOS)

    pal_img = img.quantize(colors=num_colors, method=Image.MEDIANCUT)
    palette = pal_img.getpalette()[:num_colors * 3]
    palette = [(palette[i], palette[i+1], palette[i+2]) for i in range(0, len(palette), 3)]

    # Count pixels per cluster
    px = list(pal_img.getdata())
    counts = {i: px.count(i) for i in range(len(palette))}
    total = sum(counts.values())
    weights = [counts[i] / total for i in range(num_colors)]

    L_sum = C_sum = 0.0
    color_data = []
    for (r, g, b), w in zip(palette, weights):
        # sRGB → linear
        r_lin = ((r / 255) ** 2.2)
        g_lin = ((g / 255) ** 2.2)
        b_lin = ((b / 255) ** 2.2)
        oklab = linear_srgb_to_oklab(r_lin, g_lin, b_lin)
        L, C, h = oklab_to_oklch(*oklab)
        L_sum += L * w
        C_sum += C * w
        color_data.append((L, C, h, w))

    # Dominant hue: chroma-weighted from the most saturated high-weight color
    sorted_colors = sorted(color_data, key=lambda c: c[2] * c[3], reverse=True)
    h_dom = sorted_colors[0][2] if sorted_colors else 0

    return {
        "L_avg": L_sum,
        "C_avg": C_sum,
        "h_dom": h_dom,
        "colors": [(L, C, h) for (L, C, h, _) in color_data],
    }


def classify(stats):
    """Return list of mood IDs matching the given stats."""
    moods = []
    for mood_id, rule in MOOD_RULES.items():
        try:
            if rule(stats):
                moods.append(mood_id)
        except Exception:
            continue
    return moods


# --- Cache management ---

CACHE_PATH = Path.home() / ".cache" / "dotfiles" / "wallpaper-moods.json"
CONFIG_PATH = Path.home() / ".config" / "dotfiles" / "settings.json"


def load_cache():
    if CACHE_PATH.exists():
        with open(CACHE_PATH) as f:
            return json.load(f)
    return {"version": 1, "tags": {}}


def save_cache(cache):
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp = tempfile.NamedTemporaryFile(
        mode="w", dir=CACHE_PATH.parent, delete=False, suffix=".tmp"
    )
    try:
        json.dump(cache, tmp, indent=2)
        tmp.flush()
        os.fsync(tmp.fileno())
        tmp.close()
        os.replace(tmp.name, CACHE_PATH)
    except Exception:
        os.unlink(tmp.name)
        raise


def get_library_dir():
    """Read library_dir from settings.json, or use default."""
    default = str(Path.home() / "Pictures" / "wallpapers")
    if CONFIG_PATH.exists():
        try:
            with open(CONFIG_PATH) as f:
                cfg = json.load(f)
            return cfg.get("wallpaper", {}).get("library_dir") or default
        except (json.JSONDecodeError, KeyError):
            pass
    return default


# --- Main ---

def process_file(filepath, cache, debug=False):
    """Process a single image file, returning (path, moods, stats) or None."""
    try:
        mtime = os.path.getmtime(filepath)
        entry = cache["tags"].get(filepath, {})
        if entry.get("mtime") == mtime:
            return None  # unchanged
        stats = extract_palette(filepath)
        moods = classify(stats)
        if debug:
            print(f"[{filepath}]")
            print(f"  L_avg={stats['L_avg']:.3f}  C_avg={stats['C_avg']:.3f}  h_dom={stats['h_dom']:.1f}")
            print(f"  moods={moods}")
        return filepath, {
            "mtime": mtime,
            "moods": moods,
            "stats": {"L_avg": stats["L_avg"], "C_avg": stats["C_avg"], "h_dom": stats["h_dom"]},
        }
    except Exception as e:
        print(f"Error processing {filepath}: {e}", file=sys.stderr)
        return None


def main():
    parser = argparse.ArgumentParser(description="Tag wallpapers by mood")
    parser.add_argument("--force", action="store_true", help="Re-tag everything")
    parser.add_argument("--file", type=str, help="Tag a single file")
    parser.add_argument("--quiet", action="store_true", help="Suppress progress")
    parser.add_argument("--debug-print", action="store_true", help="Print classification stats")
    parser.add_argument("--version", action="store_true", help="Print version")
    args = parser.parse_args()

    if args.version:
        print(f"tag-wallpaper-moods v{VERSION}")
        return

    cache = load_cache()

    if args.file:
        path = os.path.abspath(args.file)
        if not os.path.isfile(path):
            print(f"File not found: {path}", file=sys.stderr)
            sys.exit(1)
        result = process_file(path, cache, debug=args.debug_print)
        if result:
            fpath, entry = result
            cache["tags"][fpath] = entry
            save_cache(cache)
        return

    library_dir = get_library_dir()
    if not os.path.isdir(library_dir):
        print(f"Library dir not found: {library_dir}", file=sys.stderr)
        sys.exit(1)

    # Collect files
    exts = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
    files = []
    for root, _, filenames in os.walk(library_dir):
        for fn in filenames:
            if os.path.splitext(fn)[1].lower() in exts:
                files.append(os.path.join(root, fn))

    if not args.force:
        files = [f for f in files if f not in cache["tags"]
                 or cache["tags"][f].get("mtime") != os.path.getmtime(f)]

    if not files:
        if not args.quiet:
            print("All wallpapers up to date.")
        return

    if not args.quiet:
        print(f"Tagging {len(files)} wallpaper(s)...")

    start = time.time()
    changed = 0
    errors = 0

    with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count()) as executor:
        futures = {executor.submit(process_file, f, cache, args.debug_print): f for f in files}
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            if result is None:
                continue
            fpath, entry = result
            cache["tags"][fpath] = entry
            changed += 1

    save_cache(cache)
    elapsed = time.time() - start

    if not args.quiet:
        print(f"Done. {changed} tagged, {errors} errors in {elapsed:.1f}s.")
        mood_counts = {}
        for entry in cache["tags"].values():
            for m in entry.get("moods", []):
                mood_counts[m] = mood_counts.get(m, 0) + 1
        for mood_id in ["dark", "light", "warm", "cool", "sky", "earth"]:
            print(f"  {mood_id}: {mood_counts.get(mood_id, 0)}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x scripts/.local/bin/tag-wallpaper-moods
```

- [ ] **Step 3: Verify script runs with --version**

Run: `scripts/.local/bin/tag-wallpaper-moods --version`
Expected: `tag-wallpaper-moods v1.0.0`

- [ ] **Step 4: Create test directory and write test file**

Create `test/tag-wallpaper-moods.bats`:

```bash
#!/usr/bin/env bats

setup() {
    load 'helpers'
    create_sandbox

    # Create fixture dirs
    FIXTURE_DIR="$SANDBOX/fixtures/wallpapers"
    mkdir -p "$FIXTURE_DIR"

    # Generate small test images for each mood
    # Each is a 200x200 solid-color image
    python3 -c "
from PIL import Image
import os

d = os.environ['FIXTURE_DIR']

# Dark: very dark blue
Image.new('RGB', (200, 200), (10, 10, 20)).save(f'{d}/dark.jpg')
# Light: very light grey
Image.new('RGB', (200, 200), (240, 240, 245)).save(f'{d}/light.jpg')
# Warm: orange-red
Image.new('RGB', (200, 200), (204, 74, 58)).save(f'{d}/warm.jpg')
# Cool: medium blue
Image.new('RGB', (200, 200), (58, 95, 204)).save(f'{d}/cool.jpg')
# Sky: light desaturated blue
Image.new('RGB', (200, 200), (165, 200, 230)).save(f'{d}/sky.jpg')
# Earth: olive green
Image.new('RGB', (200, 200), (58, 74, 42)).save(f'{d}/earth.jpg')
# Multi-mood: dark warm (dark orange)
Image.new('RGB', (200, 200), (60, 30, 10)).save(f'{d}/dark_warm.jpg')
"

    # Write settings.json with library_dir pointing to fixtures
    mkdir -p "$SANDBOX/config/dotfiles"
    cat > "$SANDBOX/config/dotfiles/settings.json" << 'EOF'
{
    "wallpaper": {
        "library_dir": "__FIXTURE_DIR__"
    }
}
EOF
    sed -i "s|__FIXTURE_DIR__|$FIXTURE_DIR|" "$SANDBOX/config/dotfiles/settings.json"

    # Mock HOME
    export HOME="$SANDBOX"
    export TAGGER="$BATS_TEST_DIRNAME/../scripts/.local/bin/tag-wallpaper-moods"
}

teardown() {
    cleanup_sandbox
}

@test "tag-wallpaper-moods --version prints version" {
    run "$TAGGER" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1.0.0" ]]
}

@test "tag-wallpaper-moods tags dark wallpaper" {
    run "$TAGGER" --file "$FIXTURE_DIR/dark.jpg"
    [ "$status" -eq 0 ]
    run cat "$SANDBOX/.cache/dotfiles/wallpaper-moods.json"
    echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); tags=d['tags']; assert 'dark' in list(tags.values())[0]['moods'], f'Expected dark, got {list(tags.values())[0][\"moods\"]}'"
}

@test "tag-wallpaper-moods tags light wallpaper" {
    run "$TAGGER" --file "$FIXTURE_DIR/light.jpg"
    [ "$status" -eq 0 ]
    run python3 -c "import json; d=json.load(open('$SANDBOX/.cache/dotfiles/wallpaper-moods.json')); tags=list(d['tags'].values())[0]; assert 'light' in tags['moods'], f'Expected light, got {tags[\"moods\"]}'"
}

@test "tag-wallpaper-moods tags warm wallpaper" {
    run "$TAGGER" --file "$FIXTURE_DIR/warm.jpg"
    [ "$status" -eq 0 ]
    run python3 -c "import json; d=json.load(open('$SANDBOX/.cache/dotfiles/wallpaper-moods.json')); tags=list(d['tags'].values())[0]; assert 'warm' in tags['moods'], f'Expected warm, got {tags[\"moods\"]}'"
}

@test "tag-wallpaper-moods tags cool wallpaper" {
    run "$TAGGER" --file "$FIXTURE_DIR/cool.jpg"
    [ "$status" -eq 0 ]
    run python3 -c "import json; d=json.load(open('$SANDBOX/.cache/dotfiles/wallpaper-moods.json')); tags=list(d['tags'].values())[0]; assert 'cool' in tags['moods'], f'Expected cool, got {tags[\"moods\"]}'"
}

@test "tag-wallpaper-moods tags sky wallpaper" {
    run "$TAGGER" --file "$FIXTURE_DIR/sky.jpg"
    [ "$status" -eq 0 ]
    run python3 -c "import json; d=json.load(open('$SANDBOX/.cache/dotfiles/wallpaper-moods.json')); tags=list(d['tags'].values())[0]; assert 'sky' in tags['moods'], f'Expected sky, got {tags[\"moods\"]}'"
}

@test "tag-wallpaper-moods tags earth wallpaper" {
    run "$TAGGER" --file "$FIXTURE_DIR/earth.jpg"
    [ "$status" -eq 0 ]
    run python3 -c "import json; d=json.load(open('$SANDBOX/.cache/dotfiles/wallpaper-moods.json')); tags=list(d['tags'].values())[0]; assert 'earth' in tags['moods'], f'Expected earth, got {tags[\"moods\"]}'"
}

@test "tag-wallpaper-moods multi-tag: dark_warm gets both dark and warm" {
    run "$TAGGER" --file "$FIXTURE_DIR/dark_warm.jpg"
    [ "$status" -eq 0 ]
    run python3 -c "
import json
d=json.load(open('$SANDBOX/.cache/dotfiles/wallpaper-moods.json'))
tags=list(d['tags'].values())[0]
moods = tags['moods']
assert 'dark' in moods, f'Expected dark, got {moods}'
assert 'warm' in moods, f'Expected warm, got {moods}'
"
}

@test "tag-wallpaper-moods --force retags all files" {
    # First tag
    "$TAGGER" --file "$FIXTURE_DIR/dark.jpg"
    # Force re-tag (should re-process even though cache exists)
    run "$TAGGER" --force
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Tagging" ]]
}

@test "tag-wallpaper-moods cache is versioned" {
    "$TAGGER" --file "$FIXTURE_DIR/dark.jpg"
    run python3 -c "import json; d=json.load(open('$SANDBOX/.cache/dotfiles/wallpaper-moods.json')); assert d['version'] == 1"
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd ~/dotfiles
mkdir -p test/fixtures/wallpapers
bats test/tag-wallpaper-moods.bats
```

Expected: All tests pass (or at least the structural/version ones). Note: solid-color synthetic fixtures may not produce the exact mood classification expected for all 6 moods (real images are needed for production accuracy), but the `--version`, `--file`, and `--force` tests and the cache-versioned test should pass solidly.

- [ ] **Step 6: Add mood-tag hook to set-wallpaper**

In `scripts/.local/bin/set-wallpaper`, after the `apply-theme` call at line ~85, add:

```bash
# 4. Tag the new wallpaper for mood classification
if command -v tag-wallpaper-moods >/dev/null 2>&1; then
    tag-wallpaper-moods --file "$IMG" --quiet &>/dev/null &
fi
```

Do NOT block on the tagger — it runs in background. The `--quiet` flag suppresses all output.

- [ ] **Step 7: Commit**

```bash
git add scripts/.local/bin/tag-wallpaper-moods
git add test/tag-wallpaper-moods.bats
git add test/fixtures/
git commit -m "feat(scripts): add tag-wallpaper-moods mood classifier

Python + Pillow median-cut palette extraction → OKLab/OKLCH conversion
→ mood classification (Dark/Light/Warm/Cool/Sky/Earth). Multi-threaded
tagging with versioned cache at ~/.cache/dotfiles/wallpaper-moods.json.

CLI: incremental/force/single-file/debug modes. Hook added to
set-wallpaper for background tagging on wallpaper change.

Decisions made: Solid-color synthetic fixtures used for tests; real
wallpaper images needed for production mood accuracy.
OKLab conversion is pure-Python (~30 lines), no new deps."
```

---

### Phase C: Update fetch-wallpaper to read library_dir

#### Task C1: Read `wallpaper.library_dir` from settings.json

**Files:**
- Modify: `scripts/.local/bin/fetch-wallpaper`

- [ ] **Step 1: Add settings.json parsing at top of fetch-wallpaper main()**

In `scripts/.local/bin/fetch-wallpaper`, replace the `LOCAL_WALLPAPER_DIR` default assignment (line 31) with a settings.json reader:

```bash
# Read library_dir from settings.json, fall back to default
CONFIG_FILE="$CONFIG_DIR/settings.json"
LIBRARY_DIR=""
if [ -f "$CONFIG_FILE" ]; then
    LIBRARY_DIR=$(jq -r '.wallpaper.library_dir // empty' "$CONFIG_FILE" 2>/dev/null || true)
fi
LOCAL_WALLPAPER_DIR="${LIBRARY_DIR:-$HOME/Pictures/wallpapers}"
```

This is the only change needed. The rest of the script uses `LOCAL_WALLPAPER_DIR` which now reads from settings.json. The `choose_local()` function at line 34 will use this value.

**Do NOT** modify the `OUT_DIR` (`$HOME/Pictures/wallpapers`) — that's the download destination, not the local library source.

- [ ] **Step 2: Verify the change works**

```bash
# Test: with library_dir set
mkdir -p ~/.config/dotfiles
echo '{"wallpaper": {"library_dir": "'"$HOME"'/Pictures/test_wallpapers"}}' > ~/.config/dotfiles/settings.json
mkdir -p ~/Pictures/test_wallpapers
# Create a test image
python3 -c "from PIL import Image; Image.new('RGB', (100,100), (255,0,0)).save('$HOME/Pictures/test_wallpapers/test.jpg')"
scripts/.local/bin/fetch-wallpaper
```

Expected: should use test_wallpapers as source (if local source is enabled). After test, restore settings.json to original.

- [ ] **Step 3: Commit**

```bash
git add scripts/.local/bin/fetch-wallpaper
git commit -m "fix(scripts): fetch-wallpaper reads library_dir from settings.json

Add jq-based parsing of settings.json wallpaper.library_dir for
local wallpaper source directory. Falls back to ~/Pictures/wallpapers
if unset or missing. The download destination (OUT_DIR) remains
unchanged at ~/Pictures/wallpapers."
```

---

### Phase D: New QML Components (7 files)

This phase creates all new QML files needed by the mood browser. Each file is a focused, single-responsibility component (≤200 lines).

#### Task D1: Create MoodCatalog.qml (data singleton)

**Files:**
- Create: `quickshell/.config/quickshell/settings/data/MoodCatalog.qml`

- [ ] **Step 1: Write MoodCatalog.qml**

```qml
pragma Singleton
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

QtObject {
    id: catalog

    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/dotfiles/wallpaper-moods.json"

    readonly property var moods: [
        { id: "dark",  label: "Dark",  icon: "moon",   gradientStart: "#0a0a14", gradientEnd: "#1a1a28" },
        { id: "light", label: "Light", icon: "sun",     gradientStart: "#f0f0f5", gradientEnd: "#e0e0ea" },
        { id: "warm",  label: "Warm",  icon: "image",   gradientStart: "#cc4a3a", gradientEnd: "#ffa85f" },
        { id: "cool",  label: "Cool",  icon: "image",   gradientStart: "#3a5fcc", gradientEnd: "#5fb1ff" },
        { id: "sky",   label: "Sky",   icon: "image",   gradientStart: "#5fa8e8", gradientEnd: "#e8c89a" },
        { id: "earth", label: "Earth", icon: "image",   gradientStart: "#3a4a2a", gradientEnd: "#a8884a" }
    ]

    // Inverted index: moodId → [absolute paths]
    property var _moodCache: ({})
    // Forward index: path → [moodIds]
    property var _pathCache: ({})
    property int _totalTagged: 0

    function moodCount(moodId: string): int {
        if (_moodCache[moodId]) return _moodCache[moodId].length;
        return 0;
    }

    function wallpapersForMood(moodId: string): var {
        return _moodCache[moodId] || [];
    }

    function hasMood(path: string, moodId: string): bool {
        const moods = _pathCache[path];
        if (!moods) return false;
        return moods.indexOf(moodId) >= 0;
    }

    property FileView _cacheFile: FileView {
        path: catalog.cachePath
        preload: true
        onFileChanged: reload()
        onLoaded: catalog._parse(text())
        onLoadFailed: {
            console.warn("MoodCatalog: no mood cache found at", catalog.cachePath);
            catalog._moodCache = {};
            catalog._pathCache = {};
            catalog._totalTagged = 0;
        }
    }

    function _parse(rawJson: string): void {
        try {
            const parsed = JSON.parse(rawJson);
            const tags = parsed.tags || {};
            const inverted = {};
            const forward = {};
            let count = 0;

            for (const path in tags) {
                if (!tags.hasOwnProperty(path)) continue;
                const entry = tags[path];
                const moods = entry.moods || [];
                if (moods.length === 0) continue;

                forward[path] = moods;
                count++;

                for (let i = 0; i < moods.length; i++) {
                    const m = moods[i];
                    if (!inverted[m]) inverted[m] = [];
                    inverted[m].push(path);
                }
            }

            catalog._moodCache = inverted;
            catalog._pathCache = forward;
            catalog._totalTagged = count;
            console.log("MoodCatalog: loaded", count, "tagged wallpapers");
        } catch (e) {
            console.warn("MoodCatalog: failed to parse cache:", e);
            catalog._moodCache = {};
            catalog._pathCache = {};
            catalog._totalTagged = 0;
        }
    }

    function refresh(): void {
        _cacheFile.reload();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/data/MoodCatalog.qml
git commit -m "feat(settings): add MoodCatalog singleton for mood definitions and cache access

Defines 6 moods (Dark/Light/Warm/Cool/Sky/Earth) with gradient colors
matching the OKLCH rules in tag-wallpaper-moods. Provides moodCount()
and wallpapersForMood() by reading wallpaper-moods.json cache.
Mirrors mood_rules.py thresholds.
"
```

#### Task D2: Create MoodTile.qml

**Files:**
- Create: `quickshell/.config/quickshell/settings/pages/wallpaper/MoodTile.qml`

- [ ] **Step 1: Write MoodTile.qml**

```qml
import QtQuick
import Quickshell

Item {
    id: root

    property string moodId: ""
    property string moodLabel: ""
    property color gradientStart: "#888"
    property color gradientEnd: "#444"
    property int wallpaperCount: 0
    property bool selected: false

    signal clicked()

    width: 140
    height: 120

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14

        // Gradient background
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.gradientStart }
            GradientStop { position: 1.0; color: root.gradientEnd }
        }

        // Specular sweep animation (idle)
        Rectangle {
            id: specular
            width: parent.width * 1.5
            height: parent.height * 2
            color: Qt.rgba(1, 1, 1, 0.05)
            rotation: 25
            x: -width
            y: -height * 0.5

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: !root.selected && !hoverArea.containsMouse
                PauseAnimation { duration: 4000 }
                NumberAnimation { from: -width; to: parent.width + width; duration: 2000; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 2000 }
            }
        }

        // Hover lift
        scale: hoverArea.pressed ? 0.95 : (hoverArea.containsMouse ? 1.03 : 1.0)
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Selected ring + glow
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: root.selected ? 2 : 0
            opacity: root.selected ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Content
        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.moodLabel
                color: root.moodId === "light" ? "#2a2a3a" : "#ffffff"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.letterSpacing: -0.2
            }

            // Palette dots
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Repeater {
                    model: 3
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: Qt.lighter(root.gradientEnd, 1.0 + index * 0.15)
                        opacity: 0.6
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.wallpaperCount > 0 ? root.wallpaperCount + " wallpapers" : ""
                color: root.moodId === "light" ? "#555565" : Qt.rgba(1, 1, 1, 0.55)
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }

    // Dim other tiles when one is selected
    opacity: root.selected ? 1.0 : (card.state === "othersDim" ? 0.35 : 1.0)
    Behavior on opacity { NumberAnimation { duration: 200 } }
}
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/pages/wallpaper/MoodTile.qml
git commit -m "feat(settings): add MoodTile component with gradient and specular animation

Individual mood card with gradient background, slow specular sweep,
hover lift effect, selected ring/glow, and dim state for deselected tiles.
Text color adapts for Light mood readability."
```

#### Task D3: Create MoodGrid.qml

**Files:**
- Create: `quickshell/.config/quickshell/settings/pages/wallpaper/MoodGrid.qml`

- [ ] **Step 1: Write MoodGrid.qml**

```qml
import QtQuick
import Quickshell

Item {
    id: root

    property string selectedMood: ""  // "" means none selected
    signal moodSelected(string moodId)
    signal moodDeselected()

    height: 140

    Row {
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: MoodCatalog.moods

            delegate: MoodTile {
                required property var modelData

                moodId: modelData.id
                moodLabel: modelData.label
                gradientStart: modelData.gradientStart
                gradientEnd: modelData.gradientEnd
                wallpaperCount: MoodCatalog.moodCount(modelData.id)
                selected: root.selectedMood === modelData.id

                // "Others dim" state
                Binding {
                    target: parent
                    property: "opacity"
                    value: root.selectedMood === "" || root.selectedMood === modelData.id ? 1.0 : 0.35
                }

                onClicked: {
                    if (root.selectedMood === modelData.id) {
                        root.selectedMood = "";
                        root.moodDeselected();
                    } else {
                        root.selectedMood = modelData.id;
                        root.moodSelected(modelData.id);
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/pages/wallpaper/MoodGrid.qml
git commit -m "feat(settings): add MoodGrid with 6-tile row and toggle selection

Repeater-based grid rendering all 6 moods from MoodCatalog. Single
selection with toggle behavior (click again to deselect). Dims
non-selected tiles. Emits moodSelected/moodDeselected signals."
```

#### Task D4: Create WallpaperHero.qml

**Files:**
- Create: `quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperHero.qml`

- [ ] **Step 1: Write WallpaperHero.qml**

This component combines: current wallpaper preview + palette swatches + accent mode + mood browsing state.

```qml
import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root

    property bool moodBrowsing: false
    property string browseMoodId: ""
    property string browseMoodLabel: ""
    property int browseMoodCount: 0
    signal backToAll()
    signal accentSelected(string hex)

    height: 160

    Row {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 16

        // Left: wallpaper preview card (1.5fr)
        Rectangle {
            width: (parent.width - 16) * 0.6
            height: parent.height
            radius: 12
            color: "#0f0b07"
            clip: true

            Image {
                anchors.fill: parent
                source: root.moodBrowsing ? "" : (SettingsStore.currentWallpaper ? "file://" + SettingsStore.currentWallpaper : "")
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 600
                sourceSize.height: 300
                smooth: true
                opacity: status === Image.Ready && !root.moodBrowsing ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }

            // Mood gradient overlay (when browsing)
            Rectangle {
                anchors.fill: parent
                visible: root.moodBrowsing
                gradient: Gradient {
                    GradientStop { position: 0.0; color: MoodCatalog.moods.find(m => m.id === root.browseMoodId)?.gradientStart || "#888" }
                    GradientStop { position: 1.0; color: MoodCatalog.moods.find(m => m.id === root.browseMoodId)?.gradientEnd || "#444" }
                }
            }

            // "CURRENT" badge
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                height: 22
                width: currentText.width + 16
                radius: 11
                color: Qt.rgba(0, 0, 0, 0.6)
                visible: !root.moodBrowsing

                Text {
                    id: currentText
                    anchors.centerIn: parent
                    text: "CURRENT"
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }
            }

            // Filename overlay (default state)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 28
                color: Qt.rgba(0, 0, 0, 0.55)
                visible: !root.moodBrowsing

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const p = SettingsStore.currentWallpaper;
                        if (!p) return "No wallpaper set";
                        return p.split("/").pop();
                    }
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideMiddle
                    width: parent.width - 24
                }
            }
        }

        // Right: meta card (1fr)
        Rectangle {
            width: (parent.width - 16) * 0.4
            height: parent.height
            radius: 12
            color: "#221c15"
            border.color: "#0e0a06"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Title
                Text {
                    text: root.moodBrowsing ? "Browsing mood" : "Now playing"
                    color: "#6b6258"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }

                Text {
                    text: root.moodBrowsing ? root.browseMoodLabel : (SettingsStore.currentWallpaper ? SettingsStore.currentWallpaper.split("/").pop() : "No wallpaper")
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideMiddle
                    width: parent.width
                }

                // Palette section
                Text {
                    text: "Palette"
                    color: "#6b6258"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    anchors.topMargin: 4
                }

                // 6 swatch dots (clickable to set as accent)
                Row {
                    spacing: 6
                    Repeater {
                        model: [
                            Theme.color1, Theme.color2, Theme.color3,
                            Theme.color4, Theme.color5, Theme.color6
                        ]
                        delegate: ColorSwatch {
                            required property color modelData
                            swatchColor: modelData
                            selected: Theme.accent.toString() === modelData.toString()
                            onClicked: SettingsStore.setManualAccent(modelData.toString())
                        }
                    }
                }

                // Accent mode row
                Row {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 0
                    width: parent.width
                    spacing: 8

                    PillSelector {
                        options: ["Dynamic", "Manual"]
                        currentIndex: SettingsStore.get("appearance", "accent_mode") === "manual" ? 1 : 0
                        onSelected: function(idx) {
                            SettingsStore.setAccentMode(idx === 0 ? "dynamic" : "manual");
                        }
                    }

                    // "Back to all" link (only when mood browsing)
                    Rectangle {
                        height: 32
                        width: backText.width + 20
                        radius: 16
                        color: backArea.containsMouse ? "#2c2519" : "transparent"
                        visible: root.moodBrowsing
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: backText
                            anchors.centerIn: parent
                            text: "← Back to all"
                            color: "#a89e8e"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.backToAll()
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperHero.qml
git commit -m "feat(settings): add WallpaperHero with preview, palette, and mood browsing state

Two-column hero: left shows current wallpaper (or mood gradient when
browsing), right shows filename/mood label, 6 palette swatches (clickable
for manual accent), accent mode pill, and 'Back to all' link during
mood browsing. Replaces DerivedPalette.qml inline functionality."
```

#### Task D5: Create WallpaperGrid.qml

**Files:**
- Create: `quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperGrid.qml`

- [ ] **Step 1: Write WallpaperGrid.qml**

Adapted from WallpaperLibrary.qml — strips "library" framing, adds mood filter property, sort options.

```qml
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string moodFilter: ""  // empty = show all
    property var wallpapers: []
    property string applyingPath: ""

    signal wallpaperSelected(string path)

    height: gridHeader.height + gridView.contentHeight + 16

    // Scanner
    Process {
        id: scanner
        property bool pending: false

        function scan(): void {
            const libDir = SettingsStore.get("wallpaper", "library_dir") || Quickshell.env("HOME") + "/Pictures/wallpapers";
            command = ["bash", "-c", "find '" + libDir + "' -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \\) 2>/dev/null | sort"];
            root.wallpapers = [];
            running = false;
            running = true;
        }

        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (line && line.length > 0) {
                    const list = root.wallpapers.slice();
                    list.push(line);
                    root.wallpapers = list;
                }
            }
        }
    }

    // Source: scanned paths (no filter) or cached mood paths (with filter)
    readonly property var sourceWallpapers: {
        if (!root.moodFilter) return root.wallpapers;
        return MoodCatalog.wallpapersForMood(root.moodFilter);
    }

    function basename(path: string): string {
        return path.split("/").pop();
    }

    function rescan(): void {
        scanner.scan();
    }

    Column {
        id: gridHeader
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 36

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: root.moodFilter ? root.moodFilter.charAt(0).toUpperCase() + root.moodFilter.slice(1) + " wallpapers" : "ALL WALLPAPERS"
                color: "#6b6258"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }

            // Count badge
            Text {
                anchors.left: parent.left
                anchors.leftMargin: {
                    const base = root.moodFilter ? root.moodFilter.length * 9 + 130 : 120;
                    return Math.min(base, 250);
                }
                anchors.verticalCenter: parent.verticalCenter
                text: "(" + root.sourceWallpapers.length + ")"
                color: "#5a5249"
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }

            // Sort options
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: ["Newest", "Random", "Most used"]
                    delegate: Rectangle {
                        required property string modelData

                        height: 24
                        width: sortText.width + 14
                        radius: 12
                        color: sortArea.containsMouse ? "#2c2519" : "transparent"

                        Text {
                            id: sortText
                            anchors.centerIn: parent
                            text: modelData
                            color: "#a89e8e"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: sortArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { /* sort: placeholder for Ship 1 */ }
                        }
                    }
                }
            }
        }
    }

    GridView {
        id: gridView
        anchors.top: gridHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: contentHeight
        cellWidth: 168
        cellHeight: 110
        leftMargin: 12
        rightMargin: 12
        topMargin: 4
        interactive: false

        model: root.sourceWallpapers

        delegate: Item {
            required property string modelData
            required property int index

            width: gridView.cellWidth
            height: gridView.cellHeight

            readonly property bool isCurrent: modelData === SettingsStore.currentWallpaper
            readonly property bool isApplying: modelData === root.applyingPath

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 156
                height: 96
                radius: 10
                color: "#0f0b07"
                border.width: isCurrent ? 2 : 1
                border.color: isCurrent ? Theme.accent : "#0e0a06"
                clip: true
                Behavior on border.color { ColorAnimation { duration: 160 } }

                // Stage-in animation
                opacity: 0
                transform: Translate { id: stageTranslate; y: 12 }
                SequentialAnimation on opacity {
                    running: true
                    PauseAnimation { duration: index * 40 }
                    NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                }
                SequentialAnimation on stageTranslate.y {
                    running: true
                    PauseAnimation { duration: index * 40 }
                    NumberAnimation { to: 0; duration: 200; easing.type: Easing.OutCubic }
                }

                scale: thumbArea.pressed ? 0.94 : (thumbArea.containsMouse ? 1.04 : (isApplying ? 1.06 : 1.0))
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

                Image {
                    anchors.fill: parent
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 312
                    sourceSize.height: 192
                    smooth: true
                }

                // Current indicator dot
                Rectangle {
                    anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 6
                    width: 8; height: 8; radius: 4
                    color: Theme.accent
                    visible: isCurrent
                }

                // Filename overlay
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 22
                    color: Qt.rgba(0, 0, 0, 0.6)
                    visible: thumbArea.containsMouse

                    Text {
                        anchors.centerIn: parent
                        text: basename(modelData)
                        color: "#f5ede0"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                MouseArea {
                    id: thumbArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.wallpaperSelected(modelData)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperGrid.qml
git commit -m "feat(settings): add WallpaperGrid with mood filtering and stage-in animation

Adapted from WallpaperLibrary.qml — accepts moodFilter property to show
only tagged wallpapers. Stage-in animation with 40ms stagger.
Sort options placeholder (Newest/Random/Most used) for Ship 1.
Rescan method for re-scanning library directory."
```

#### Task D6: Create ScheduleCard.qml

**Files:**
- Create: `quickshell/.config/quickshell/settings/pages/wallpaper/ScheduleCard.qml`

- [ ] **Step 1: Write ScheduleCard.qml**

Adapted from FrequencyPicker.qml — adds fetch button, uses SettingsGroup layout.

```qml
import QtQuick
import QtQuick.Controls
import Quickshell

Rectangle {
    id: root
    width: parent.width
    height: childrenRect.height
    radius: 14
    color: "#221c15"
    border.color: "#0e0a06"
    border.width: 1

    readonly property string currentFrequency: SettingsStore.get("wallpaper", "frequency") || "daily"

    function applyFrequency(freq: string): void {
        SettingsStore.set("wallpaper", "frequency", freq);
        let cmd = "";
        if (freq === "off") {
            cmd = "systemctl --user disable --now daily-wallpaper.timer";
        } else if (freq === "hourly") {
            cmd = "systemctl --user disable --now daily-wallpaper.timer; mkdir -p ~/.config/systemd/user/daily-wallpaper.timer.d && cat > ~/.config/systemd/user/daily-wallpaper.timer.d/override.conf << 'EOF'\n[Timer]\nOnCalendar=\nOnCalendar=hourly\nEOF\nsystemctl --user daemon-reload && systemctl --user enable --now daily-wallpaper.timer";
        } else if (freq === "6h") {
            cmd = "systemctl --user disable --now daily-wallpaper.timer; mkdir -p ~/.config/systemd/user/daily-wallpaper.timer.d && cat > ~/.config/systemd/user/daily-wallpaper.timer.d/override.conf << 'EOF'\n[Timer]\nOnCalendar=\nOnCalendar=*-*-* 00/6:00:00\nEOF\nsystemctl --user daemon-reload && systemctl --user enable --now daily-wallpaper.timer";
        } else {
            cmd = "rm -rf ~/.config/systemd/user/daily-wallpaper.timer.d && systemctl --user daemon-reload && systemctl --user enable --now daily-wallpaper.timer";
        }
        SettingsStore.execScript(cmd);
    }

    Column {
        width: parent.width
        spacing: 0

        // Header
        Item {
            width: parent.width
            height: 36
            Text {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "SCHEDULE"
                color: "#6b6258"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }
        }

        // Frequency pill
        Item {
            width: parent.width
            height: 52
            x: 16
            width: parent.width - 32

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text { text: "Frequency"; color: "#f5ede0"; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                Text { text: "How often to fetch a new wallpaper"; color: "#8a8175"; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }

            PillSelector {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                options: ["Off", "Hourly", "6h", "Daily"]
                currentIndex: {
                    const f = root.currentFrequency;
                    if (f === "off") return 0;
                    if (f === "hourly") return 1;
                    if (f === "6h") return 2;
                    return 3;
                }
                onSelected: function(idx) {
                    applyFrequency(["off", "hourly", "6h", "daily"][idx]);
                }
            }
        }

        Rectangle { width: parent.width - 32; x: 16; height: 1; color: "#0e0a06" }

        // Skip today
        Item {
            width: parent.width
            height: 52

            Item {
                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                Column {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text { text: "Skip today"; color: "#f5ede0"; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: "Keep current wallpaper for the rest of today"; color: "#8a8175"; font.family: Theme.fontFamily; font.pixelSize: 11 }
                }
                ToggleSwitch {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    checked: SettingsStore.get("wallpaper", "skip_today") === true
                    onToggled: function(state) {
                        SettingsStore.set("wallpaper", "skip_today", state);
                        SettingsStore.execScript(state
                            ? "date +%Y-%m-%d > ~/.local/share/dotfiles/skip_today"
                            : "rm -f ~/.local/share/dotfiles/skip_today");
                    }
                }
            }
        }

        Rectangle { width: parent.width - 32; x: 16; height: 1; color: "#0e0a06" }

        // Fetch button
        Item {
            width: parent.width
            height: 52

            Rectangle {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: 34
                width: fetchText.width + 32
                radius: 10
                color: fetchArea.pressed ? Qt.darker(Theme.accent, 1.2) : (fetchArea.containsMouse ? Qt.lighter(Theme.accent, 1.05) : Theme.accent)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: fetchText
                    anchors.centerIn: parent
                    text: "Fetch new wallpaper now"
                    color: "#1a1105"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: fetchArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SettingsStore.fetchWallpaper()
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/pages/wallpaper/ScheduleCard.qml
git commit -m "feat(settings): add ScheduleCard with frequency, skip, and fetch button

Replaces FrequencyPicker.qml. Uses SettingsGroup layout pattern.
Pill selector for Off/Hourly/6h/Daily, Skip today toggle, Fetch now
button. Systemd timer override logic preserved from FrequencyPicker."
```

#### Task D7: Create SourcesCard.qml

**Files:**
- Create: `quickshell/.config/quickshell/settings/pages/wallpaper/SourcesCard.qml`

- [ ] **Step 1: Write SourcesCard.qml**

Adapted from SourceManager.qml — adds folder picker overflow on Local row.

```qml
import QtQuick
import QtQuick.Controls
import Quickshell

Rectangle {
    id: root
    width: parent.width
    height: childrenRect.height
    radius: 14
    color: "#221c15"
    border.color: "#0e0a06"
    border.width: 1

    readonly property var allSources: [
        { id: "local",    label: "Local Folder", icon: "folder" },
        { id: "unsplash", label: "Unsplash",     icon: "image" },
        { id: "reddit",   label: "Reddit",       icon: "image" },
        { id: "bing",     label: "Bing",         icon: "image" },
        { id: "picsum",   label: "Picsum",       icon: "image" }
    ]

    function isEnabled(id: string): bool {
        const en = SettingsStore.get("wallpaper", "sources_enabled") || {};
        return en[id] !== false;
    }

    function setEnabled(id: string, enabled: bool): void {
        const en = SettingsStore.get("wallpaper", "sources_enabled") || {};
        en[id] = enabled;
        SettingsStore.set("wallpaper", "sources_enabled", en);
    }

    function folderPicker(): void {
        // Use zenity folder picker; fallback to kdialog
        const cmd = "zenity --file-selection --directory --title='Select Wallpaper Library' 2>/dev/null || kdialog --getexistingdirectory 2>/dev/null || echo ''";
        SettingsStore.execScript("result=$(" + cmd + "); if [ -n \"$result\" ]; then " +
            "sed -i 's|\"library_dir\": \"[^\"]*\"|\"library_dir\": \"'$result'\"|' ~/.config/dotfiles/settings.json; " +
            "fi");
    }

    Column {
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 36
            Text {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "SOURCES"
                color: "#6b6258"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }
        }

        Repeater {
            model: root.allSources

            delegate: Item {
                required property var modelData
                required property int index
                width: parent.width
                height: 52

                readonly property bool isOn: root.isEnabled(modelData.id)

                Rectangle {
                    anchors.fill: parent
                    color: rowArea.containsMouse ? "#2a2419" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Item {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16

                        Row {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: isOn ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Qt.rgba(1, 1, 1, 0.04)
                                anchors.verticalCenter: parent.verticalCenter

                                PhosphorIcon {
                                    anchors.centerIn: parent
                                    name: modelData.icon
                                    size: 14
                                    color: isOn ? Theme.accent : "#5a5249"
                                    weight: isOn ? "fill" : "regular"
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: modelData.label
                                    color: isOn ? "#f5ede0" : "#8a8175"
                                    font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
                                }
                                Text {
                                    text: modelData.id === "local" ? (SettingsStore.get("wallpaper", "library_dir") || "~/Pictures/wallpapers") : ""
                                    color: "#6b6258"
                                    font.family: Theme.fontFamily; font.pixelSize: 10
                                    visible: modelData.id === "local"
                                    elide: Text.ElideMiddle
                                    width: 160
                                }
                            }
                        }

                        // Local row: overflow menu button
                        Rectangle {
                            anchors.right: toggleSwitch.left; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28; height: 28; radius: 14
                            color: overflowArea.containsMouse ? "#3a3225" : "transparent"
                            visible: modelData.id === "local"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "⋯"
                                color: "#a89e8e"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: overflowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: overflowMenu.open()
                            }

                            Popup {
                                id: overflowMenu
                                y: parent.height + 4
                                width: 180
                                padding: 4
                                background: Rectangle {
                                    color: "#231d16"
                                    border.color: "#3a3225"
                                    border.width: 1
                                    radius: 10
                                }

                                Column {
                                    width: parent.width
                                    spacing: 2

                                    Repeater {
                                        model: [
                                            { label: "Change folder…", action: function() { root.folderPicker(); overflowMenu.close(); } },
                                            { label: "Open in file manager", action: function() { SettingsStore.execScript("xdg-open \"" + (SettingsStore.get("wallpaper", "library_dir") || "~/Pictures/wallpapers") + "\""); overflowMenu.close(); } },
                                            { label: "Re-tag library", action: function() { SettingsStore.execScript("tag-wallpaper-moods --force"); overflowMenu.close(); } }
                                        ]
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: parent.width; height: 30; radius: 6
                                            color: menuArea.containsMouse ? "#3a3225" : "transparent"
                                            Behavior on color { ColorAnimation { duration: 80 } }

                                            Text {
                                                anchors.left: parent.left; anchors.leftMargin: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.label
                                                color: "#f5ede0"
                                                font.family: Theme.fontFamily; font.pixelSize: 12
                                            }

                                            MouseArea {
                                                id: menuArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: modelData.action()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Toggle switch
                        ToggleSwitch {
                            id: toggleSwitch
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: isOn
                            onToggled: function(state) { root.setEnabled(modelData.id, state); }
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onClicked: function(mouse) { mouse.accepted = false }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.right: parent.right; anchors.rightMargin: 16
                    height: 1
                    color: "#0e0a06"
                    visible: index < root.allSources.length - 1
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/pages/wallpaper/SourcesCard.qml
git commit -m "feat(settings): add SourcesCard with folder picker and overflow menu

Replaces SourceManager.qml. Five source rows with toggles. Local row
shows library_dir path, overflow menu with Change folder (zenity/kdialog),
Open in file manager, Re-tag library. Popup menu with dark theme."
```

- [ ] **Step 3: Batch update qmldir with all new Phase D components**

Append these lines to `quickshell/.config/quickshell/qmldir` (after the `singleton Categories` line):

```
singleton MoodCatalog 1.0 settings/data/MoodCatalog.qml

MoodGrid 1.0 settings/pages/wallpaper/MoodGrid.qml
MoodTile 1.0 settings/pages/wallpaper/MoodTile.qml
WallpaperHero 1.0 settings/pages/wallpaper/WallpaperHero.qml
WallpaperGrid 1.0 settings/pages/wallpaper/WallpaperGrid.qml
ScheduleCard 1.0 settings/pages/wallpaper/ScheduleCard.qml
SourcesCard 1.0 settings/pages/wallpaper/SourcesCard.qml
```

Also remove the old `qmldir` entries for `WallpaperLibrary`, `DerivedPalette`, `RecentHistory`, `FrequencyPicker`, and `SourceManager`:

```
# These are removed
# WallpaperLibrary 1.0 WallpaperLibrary.qml
# DerivedPalette 1.0 DerivedPalette.qml
# RecentHistory 1.0 RecentHistory.qml
# FrequencyPicker 1.0 FrequencyPicker.qml
# SourceManager 1.0 SourceManager.qml
```

After editing, commit:

```bash
git add quickshell/.config/quickshell/qmldir
git rm quickshell/.config/quickshell/FrequencyPicker.qml
git rm quickshell/.config/quickshell/SourceManager.qml
git commit -m "chore(settings): update qmldir with new Phase D components

Add MoodCatalog, MoodGrid, MoodTile, WallpaperHero, WallpaperGrid,
ScheduleCard, SourcesCard entries. Remove old WallpaperLibrary,
DerivedPalette, RecentHistory, FrequencyPicker, SourceManager entries.
Delete FrequencyPicker.qml and SourceManager.qml (functionality
replaced by ScheduleCard.qml and SourcesCard.qml)."
```

---

### Phase E: Wire Everything + Height Animation

#### Task E1: Update SettingsStore.qml with mood state

**Files:**
- Modify: `quickshell/.config/quickshell/settings/data/SettingsStore.qml`

- [ ] **Step 1: Add selected_mood and moodCachePath to SettingsStore**

Add after `property string currentWallpaper: ""` (line 10):

```qml
    property string selectedMood: ""
    property string moodCachePath: Quickshell.env("HOME") + "/.cache/dotfiles/wallpaper-moods.json"
```

Add in the defaults block inside `data` property, under `"wallpaper"` section, after `"library_dir": ""` (line 28):

```qml
                "selected_mood": null,
```

And add a `loadSelectedMood()` function after `get()` (around line 93):

```qml
    function loadSelectedMood(): void {
        const mood = store.get("wallpaper", "selected_mood");
        store.selectedMood = mood || "";
    }
```

And update the `reload()` function (onLoaded handler, around line 48) to call `loadSelectedMood()` after parsing.

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/data/SettingsStore.qml
git commit -m "feat(settings): add selected_mood state to SettingsStore

Persist selected mood across settings app opens. Add moodCachePath
property pointing to ~/.cache/dotfiles/wallpaper-moods.json."
```

#### Task E2: Update SettingsWindow.qml with height animation

**Files:**
- Modify: `quickshell/.config/quickshell/settings/SettingsWindow.qml`

- [ ] **Step 1: Add mood-expanded height with spring animation**

Replace the `height: 640` (line 51) with:

```qml
        readonly property int defaultHeight: 640
        readonly property int expandedHeight: 900
        height: SettingsStore.selectedMood ? expandedHeight : defaultHeight
        Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
```

This makes the container height animate between 640 and 900 pixels when `SettingsStore.selectedMood` changes. The content area (SettingsContent) already fills available space via `anchors.bottom: parent.bottom`, so child pages automatically expand.

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/SettingsWindow.qml
git commit -m "feat(settings): animate SettingsWindow height on mood selection

Container height toggles between 640 and 900px with 380ms OutBack
spring easing (overshoot 1.05). Content fills available space via
anchors — no child layout changes needed."
```

#### Task E3: Refactor WallpaperPage.qml into thin composer

**Files:**
- Modify: `quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperPage.qml`

- [ ] **Step 1: Rewrite WallpaperPage.qml as a composer**

Replace the current 310-line WallpaperPage with a thin layout composing all focused components:

```qml
import QtQuick
import QtQuick.Controls
import Quickshell

Flickable {
    id: root
    contentHeight: column.height + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 8000
    maximumFlickVelocity: 4500

    property string selectedMood: SettingsStore.selectedMood || ""

    // Trigger mood tagger on first open
    Component.onCompleted: {
        MoodCatalog.refresh();
        if (SettingsStore.selectedMood) {
            // Restore previous mood selection
        }
    }

    Column {
        id: column
        width: parent.width
        spacing: 0

        // Page header
        Item {
            width: parent.width
            height: 72
            Column {
                anchors.left: parent.left; anchors.leftMargin: 28
                anchors.top: parent.top; anchors.topMargin: 20
                spacing: 4
                Text {
                    text: "Wallpaper"
                    color: "#f5ede0"
                    font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                }
                Text {
                    text: "Browse by mood, schedule rotation, and manage sources."
                    color: "#8a8175"
                    font.family: Theme.fontFamily; font.pixelSize: 12
                }
            }
        }

        // Sections
        Column {
            x: 28
            width: parent.width - 56
            spacing: 16
            bottomPadding: 32

            // 1. WallpaperHero
            WallpaperHero {
                id: hero
                width: parent.width
                moodBrowsing: root.selectedMood !== ""
                browseMoodId: root.selectedMood
                browseMoodLabel: {
                    for (let i = 0; i < MoodCatalog.moods.length; i++) {
                        if (MoodCatalog.moods[i].id === root.selectedMood)
                            return MoodCatalog.moods[i].label;
                    }
                    return "";
                }
                browseMoodCount: MoodCatalog.moodCount(root.selectedMood)
                onBackToAll: {
                    root.selectedMood = "";
                    SettingsStore.set("wallpaper", "selected_mood", null);
                }
                onAccentSelected: function(hex) {
                    SettingsStore.setManualAccent(hex);
                }
            }

            // 2. MoodGrid
            MoodGrid {
                id: moodGrid
                width: parent.width
                selectedMood: root.selectedMood
                onMoodSelected: function(moodId) {
                    root.selectedMood = moodId;
                    SettingsStore.set("wallpaper", "selected_mood", moodId);
                }
                onMoodDeselected: {
                    root.selectedMood = "";
                    SettingsStore.set("wallpaper", "selected_mood", null);
                }
            }

            // 3. WallpaperGrid (only when mood selected)
            WallpaperGrid {
                id: wallpaperGrid
                width: parent.width
                moodFilter: root.selectedMood
                visible: root.selectedMood !== ""
                height: visible ? implicitHeight : 0
                onWallpaperSelected: function(path) {
                    SettingsStore.setWallpaper(path);
                    root.selectedMood = "";
                    SettingsStore.set("wallpaper", "selected_mood", null);
                }
            }

            // 4. Control row: Schedule + Sources
            Row {
                width: parent.width
                spacing: 16

                ScheduleCard {
                    width: (parent.width - 16) * 0.55
                }

                SourcesCard {
                    width: (parent.width - 16) * 0.45
                }
            }
        }
    }

    // Custom scrollbar
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 4
        anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 4; radius: 2; color: "transparent"

        Rectangle {
            anchors.right: parent.right; width: parent.width; radius: 2
            color: Qt.rgba(1, 1, 1, 0.15)
            y: root.contentHeight > 0 ? (root.contentY / root.contentHeight) * parent.height : 0
            height: root.contentHeight > 0 ? Math.max(40, (root.height / root.contentHeight) * parent.height) : 0
            visible: root.contentHeight > root.height
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperPage.qml
git commit -m "feat(settings): refactor WallpaperPage into thin composer

Replaces 310-line monolithic page with focused layout composing
WallpaperHero + MoodGrid + WallpaperGrid + ScheduleCard + SourcesCard.
Manages selectedMood state, triggers MoodCatalog.refresh() on open,
restores previous mood from SettingsStore."
```

#### Task E4: Update SettingsContent.qml (minor routing)

**Files:**
- Modify: `quickshell/.config/quickshell/settings/SettingsContent.qml`

- [ ] **Step 1: Update import path (should already work via qmldir)**

No changes needed — `SettingsContent.qml` imports `WallpaperPage` which is resolved via qmldir. The qmldir already maps `WallpaperPage 1.0 settings/pages/wallpaper/WallpaperPage.qml`.

Verify by checking that the `WallpaperPage { }` reference at line 9 still resolves after the move.

- [ ] **Step 2: Commit (if any changes made)**

If no changes needed: skip commit.

---

### Phase F: Smoke Test + Verification

#### Task F1: Write smoke test script

**Files:**
- Create: `quickshell/.config/quickshell/settings/test-smoke.sh`

- [ ] **Step 1: Write test-smoke.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Settings app smoke test — opens window, tabs through pages, exits clean.

echo "=== Settings App Smoke Test ==="

# Verify qmldir resolves all components
echo "Checking qmldir paths..."
cd "$(dirname "$0")/.."

# List all path references in qmldir and verify files exist
while IFS= read -r line; do
    if [[ "$line" =~ ^([a-zA-Z]|singleton\ ) ]]; then
        file=$(echo "$line" | awk '{print $NF}')
        if [ -n "$file" ] && [ "$file" != "1.0" ]; then
            if [ ! -f "$file" ]; then
                echo "MISSING: $file"
                exit 1
            fi
        fi
    fi
done < qmldir
echo "All qmldir paths OK."

# Verify Python tagger is installable
echo "Checking tag-wallpaper-moods..."
if [ -x "../scripts/.local/bin/tag-wallpaper-moods" ]; then
    python3 "../scripts/.local/bin/tag-wallpaper-moods" --version
    echo "Tagger OK."
else
    echo "WARNING: tag-wallpaper-moods not found at expected path"
fi

# Verify fetch-wallpaper reads settings.json
echo "Checking fetch-wallpaper settings.json reading..."
grep -q 'library_dir' "../scripts/.local/bin/fetch-wallpaper" && echo "fetch-wallpaper uses library_dir OK." || echo "WARNING: library_dir not found in fetch-wallpaper"

echo ""
echo "=== Smoke test passed ==="
exit 0
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x quickshell/.config/quickshell/settings/test-smoke.sh
bash quickshell/.config/quickshell/settings/test-smoke.sh
```

Expected: All qmldir paths resolve, tagger version prints, fetch-wallpaper references library_dir.

- [ ] **Step 3: Run bats tests**

```bash
cd ~/dotfiles
bats test/tag-wallpaper-moods.bats
```

Expected: All tests pass (or mark known fixture limitations).

#### Task F2: Final verification

- [ ] **Step 1: ShellCheck all modified scripts**

```bash
shellcheck scripts/.local/bin/tag-wallpaper-moods
shellcheck scripts/.local/bin/fetch-wallpaper
shellcheck scripts/.local/bin/set-wallpaper
```

Fix any warnings.

- [ ] **Step 2: Final commit with all remaining changes**

```bash
git add -A
git status  # review what's included
git commit -m "feat(settings): complete mood browser integration

Wire all components: WallpaperHero, MoodGrid, WallpaperGrid,
ScheduleCard, SourcesCard, MoodCatalog, MoodTile. Window height
animation (640↔900px with OutBack spring). Persist selected mood
across opens. Minor: SettingsStore selected_mood, test-smoke.sh.

Decisions made: Schedule + Sources always visible as cards below
the mood grid (user requirement). WallpaperGrid uses Repeater in
Ship 1 (YAGNI for <200 wallpapers). Folder picker via zenity/kdialog."
```

---

## Acceptance Criteria Checklist

Verify each before claiming done:

- [ ] AC1: `MOD+,` opens 1000×640 settings window centered on focused output
- [ ] AC2: Sidebar shows all 8 categories; non-MVP show "Coming soon" placeholder
- [ ] AC3: Wallpaper page renders: Hero · MoodGrid · (WallpaperGrid when mood selected) · ScheduleCard + SourcesCard row
- [ ] AC4: WallpaperHero shows current wallpaper preview, filename, palette swatches, accent mode pill
- [ ] AC5: MoodGrid has 6 tiles (Dark/Light/Warm/Cool/Sky/Earth) with gradients from MoodCatalog + wallpaper counts
- [ ] AC6: Clicking mood selects (others dim, window grows to 900); clicking again or "Back to all" deselects (window shrinks to 640)
- [ ] AC7: WallpaperGrid shows 4-column grid of mood-filtered wallpapers with stage-in animation
- [ ] AC8: Clicking wallpaper calls setWallpaper → hero crossfades + theme retints + drawer collapses
- [ ] AC9: ScheduleCard has frequency pill (Off/Hourly/6h/Daily), Skip today toggle, Fetch button
- [ ] AC10: SourcesCard has 5 source toggles, Local row shows path + overflow menu (Change folder / Open / Re-tag)
- [ ] AC11: `tag-wallpaper-moods` script exists and callable; runs in background on first open
- [ ] AC12: `fetch-wallpaper` reads `wallpaper.library_dir` from settings.json
- [ ] AC13: Theme hot-reloads without restart (existing functionality)
- [ ] AC14: Window closes on Escape, close button, outside click; toggle works via qs ipc
- [ ] AC15: Settings persistence round-trips correctly (settings.json IO)
