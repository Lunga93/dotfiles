# Settings App — Design Spec

**Status:** Approved (design phase, revised)
**Date:** 2026-05-10
**Last revised:** 2026-05-10 (Wallpaper Page → mood-browser direction)
**Author:** Brainstormed with the user; agent-assisted
**Audience:** Future agents and human contributors picking up this work

## Revision History

| Date | Change |
|---|---|
| 2026-05-10 | Initial spec — generic wallpaper page with library grid + recent + palette + frequency + sources |
| 2026-05-10 | **Wallpaper page reworked into a mood-browser**: 6 mood tiles (Dark/Light/Warm/Cool/Sky/Earth) drive discovery; window grows downward when a mood is selected; mandatory features (folder, frequency, skip, fetch, source toggles, accent picker) preserved as always-visible cards |
| 2026-05-10 | **Color extraction pipeline**: Pillow + OKLab/OKLCH replaces ImageMagick + HSL (perceptual uniformity, no shell-outs, deterministic, testable). **Maintainability principles section added**: file size limits, naming, "new page test", scalability table, test contract |

## Purpose

Build a glossy, modern, full-window settings application for the Niri + Quickshell desktop. The app is the single front-door for configuring wallpaper, appearance, display, keybindings, and other system utilities — replacing the current "edit config files by hand" workflow.

The design priority is **visual polish and discoverability** (Mac-inspired glass, glossy gradients, dynamic theme colors, mood-led browsing) over feature breadth at launch. Ship one category fully working, then iterate.

## Goals

1. **Single front-door for settings** — replace ad-hoc config edits with a discoverable UI.
2. **Mood-led wallpaper discovery** — flip the model. Pick the *feeling* you want (Cool, Warm, Sky…); the app surfaces wallpapers that produce that vibe. Browsing by filename is a fallback, not the primary path.
3. **Glossy + modern aesthetic** — feel more refined than typical Linux settings panels (GNOME / KDE Systemsettings).
4. **Live theme integration** — every visual element adapts to pywal palette changes in real time, with zero manual restart.
5. **Frontend over existing scripts** — never re-implement logic that already works in `~/.local/bin/`. The settings app calls existing scripts; it is not a parallel implementation.
6. **Scalable architecture** — adding a new category should be a self-contained file, not a global refactor.
7. **Knowledge transfer** — design + plan + decisions are documented so the next agent (human or AI) can continue without conversation history.

## Non-Goals

- Replacing `niri/config.kdl` or `Theme.qml` as the source of truth.
- Building a configuration daemon, IPC bus, or new state machine. State lives in plain files.
- Cross-distro support. This targets the user's Niri + Quickshell + pywal stack on CachyOS.
- Pixel-perfect Mac fidelity. We borrow the language, not clone it.
- Auto-clustering of mood taxonomy from user library. Mood definitions are hand-curated rules; per-wallpaper tagging is automated.

## Architecture

### Top level

The settings app is a **new window inside the existing `qs` Quickshell daemon** — alongside `Bar`, `AudioPanel`, `CalendarPopout`, and `PowerMenuPopout`. It is not a separate process.

This matches the established pattern in `quickshell/.config/quickshell/` and gives us:

- One process, one set of theme bindings, no IPC bridge to write
- Reuse of `Theme.qml` and `Palette.qml` singletons (already pywal-watched)
- `qs ipc call settings toggle` to show/hide, mapped to `MOD+,` in Niri
- Cheap to add: just a new `PanelWindow` + components

### Directory layout

```
quickshell/.config/quickshell/
├── shell.qml                     # entrypoint — adds Settings window
├── Theme.qml                     # already exists, reused
├── Bar.qml                       # already exists
├── ...existing components...
└── settings/                     # all settings UI lives here
    ├── README.md                 # architecture overview for next agent
    ├── SettingsWindow.qml        # top-level PanelWindow (resizes 1000×640 ↔ 1000×900)
    ├── SettingsSidebar.qml       # category nav
    ├── SettingsContent.qml       # right-hand content host (StackLayout)
    ├── components/               # reusable building blocks
    │   ├── SettingsGroup.qml     # rounded card containing rows
    │   ├── SettingsRow.qml       # label + control row
    │   ├── ToggleSwitch.qml      # iOS-style toggle
    │   ├── PillSelector.qml      # segmented pill control
    │   ├── ColorSwatch.qml       # accent swatch button
    │   └── PhosphorIcon.qml      # icon font wrapper
    ├── pages/
    │   ├── PlaceholderPage.qml   # "Coming soon" for un-implemented categories (single file)
    │   ├── AppearancePage.qml    # Ship 2 (single file)
    │   ├── IconsPage.qml         # Ship 2 (single file)
    │   └── wallpaper/            # Ship 1 — multi-component page gets its own subdirectory
    │       ├── WallpaperPage.qml      # composer
    │       ├── WallpaperHero.qml      # current preview + palette + accent picker
    │       ├── MoodGrid.qml           # 6-tile mood selector
    │       ├── MoodTile.qml           # individual gradient mood card
    │       ├── WallpaperGrid.qml      # filtered/unfiltered grid of wallpapers
    │       ├── ScheduleCard.qml       # frequency + skip + fetch
    │       └── SourcesCard.qml        # source toggles + folder picker
    └── data/
        ├── SettingsStore.qml     # singleton — reads/writes settings.json
        ├── Categories.qml        # singleton — sidebar definition
        └── MoodCatalog.qml       # singleton — mood definitions, gradients, tag lookup
```

### Migration from current implementation

The current branch already has 18 untracked QML files in `quickshell/.config/quickshell/` (flat). They migrate as follows:

| Current (flat) | Target | Action |
|---|---|---|
| `SettingsWindow.qml`, `SettingsSidebar.qml`, `SettingsContent.qml` | `settings/` | Move; update `qmldir` |
| `SettingsStore.qml`, `Categories.qml` | `settings/data/` | Move; update `qmldir` |
| `ToggleSwitch.qml`, `PillSelector.qml`, `ColorSwatch.qml`, `PhosphorIcon.qml`, `SettingsGroup.qml`, `SettingsRow.qml` | `settings/components/` | Move; update `qmldir` |
| `PlaceholderPage.qml` | `settings/pages/` | Move; update `qmldir` |
| `WallpaperPage.qml` | `settings/pages/wallpaper/WallpaperPage.qml` | Refactor — it becomes a thin composer; current sectioned layout is replaced |
| `WallpaperLibrary.qml` | `settings/pages/wallpaper/WallpaperGrid.qml` | Repurpose — strip the "library only" framing, accept a `mood` filter property |
| `RecentHistory.qml` | — | Delete; "Most used" sort in `WallpaperGrid` covers the use case |
| `DerivedPalette.qml` | `settings/pages/wallpaper/WallpaperHero.qml` (partial) | Inline its palette + accent picker into the new Hero |
| `FrequencyPicker.qml` | `settings/pages/wallpaper/ScheduleCard.qml` | Repurpose — reuse the frequency + skip-today logic; add fetch button |
| `SourceManager.qml` | `settings/pages/wallpaper/SourcesCard.qml` | Repurpose — add folder picker overflow menu on Local row |

New files to create: `MoodCatalog.qml` (data), `MoodGrid.qml`, `MoodTile.qml` (pages/wallpaper), and the `tag-wallpaper-moods` script.

### Data flow

```
┌───────────────────────────────────────────────────────────┐
│ User opens Settings (MOD+, or qs ipc call)                │
└───────────────────────────────────────────────────────────┘
                            │
                            ▼
            ┌──────────────────────────────┐
            │ SettingsWindow.qml           │
            │  ↳ SettingsSidebar           │
            │  ↳ SettingsContent (Stack)   │
            └──────────────────────────────┘
                            │
                            ▼
            ┌──────────────────────────────┐
            │ WallpaperPage.qml            │
            │  ↳ WallpaperHero             │
            │  ↳ MoodGrid (filter)         │
            │  ↳ WallpaperGrid (results)   │
            │  ↳ ScheduleCard              │
            │  ↳ SourcesCard               │
            └──────────────────────────────┘
                  │              │
        Mood selected      Wallpaper clicked
                  │              │
                  ▼              ▼
   ┌─────────────────┐   ┌────────────────────────────┐
   │ Window grows    │   │ SettingsStore.setWallpaper │
   │ 640 → 900 px    │   │  → set-wallpaper <path>    │
   │ Grid stages in  │   │  → apply-theme retints     │
   └─────────────────┘   └────────────────────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────────┐
                         │ pywal regenerates colors.json│
                         │  → Theme.qml hot-reloads     │
                         │  → Settings UI re-themes     │
                         │  → Hero swaps to new wp      │
                         └──────────────────────────────┘
```

### Backend integration (no new logic)

| UI action | Existing script / command |
|---|---|
| Set wallpaper from grid click | `set-wallpaper <path>` |
| Fetch new wallpaper now | `fetch-wallpaper` |
| Change auto-rotate frequency | systemd timer overrides (logic in `FrequencyPicker.qml` today, moves to `ScheduleCard.qml`) |
| Skip today | Touch `~/.local/share/dotfiles/skip_today` |
| Toggle source enabled | Write to `~/.config/dotfiles/settings.json`; `fetch-wallpaper` reads it |
| Change library folder | Write `wallpaper.library_dir` to `settings.json`; `fetch-wallpaper` and the new mood-tagger read it |
| Re-apply theme | `apply-theme <wallpaper>` |
| Pick manual accent | Write to `~/.local/share/dotfiles/last_accent`, call `apply-theme` |
| Toggle dynamic vs manual accent mode | Write to `settings.json`, `apply-theme` honors it |

### New backend addition: mood tagging

One new script: `~/.local/bin/tag-wallpaper-moods` (Python). It:

1. Walks the configured library folder.
2. For each new image (not already in `~/.cache/dotfiles/wallpaper-moods.json` or with stale `mtime`), extracts a representative palette and classifies it.
3. Output schema (versioned, atomic write):
   ```json
   {
     "version": 1,
     "tags": {
       "<absolute-path>": {
         "mtime": 1234567890,
         "moods": ["cool", "sky"],
         "stats": { "L_avg": 0.62, "C_avg": 0.08, "h_dom": 215 }
       }
     }
   }
   ```

**Pipeline (all in-process, no shell-outs):**

| Step | Library / approach | Why |
|---|---|---|
| Image load + downscale to 200×200 | `Pillow` (transitive dep via pywal) | Already on the system; no new deps |
| Palette extraction (top 8 colors with frequencies) | `Image.quantize(colors=8, method=Image.MEDIANCUT)` | Median-cut is the same algorithm used by Material Design's Vibrant; mature; sub-100ms per image |
| RGB → linear sRGB → OKLab → OKLCH | Pure-Python conversion (~30 lines, no deps) | OKLab is perceptually uniform — `L` actually corresponds to perceived brightness across all hues, so Dark/Light classification is reliable |
| Stats: weighted-mean L, C, dominant hue (chroma-weighted) | Pure Python | Weighting by pixel-count of each cluster avoids minor outlier colors skewing classification |
| Mood classification | Rule table in `MoodCatalog.qml` (mirrored as a dict in the Python script) | Single source of truth; rules are small (one inequality each); easy to tune |
| Cache write | Atomic via `tempfile + os.replace` | Concurrent settings-app reads never see partial JSON |

**Parallelism:** `concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count())` — Pillow releases the GIL during decode, so threading scales linearly. A 200-image library tags in ~3–5 seconds on first run, ~50ms incremental thereafter.

**Triggered:**
- On settings app first open (background; SettingsStore shows a toast if `> 300ms`).
- After `set-wallpaper` runs (a one-line hook in the script re-tags just the new file).
- Manually from "Re-tag library" in the Sources card overflow menu.

**CLI:**
```
tag-wallpaper-moods                # incremental — only new/changed
tag-wallpaper-moods --force        # re-tag everything
tag-wallpaper-moods --single PATH  # single image (used by set-wallpaper hook)
tag-wallpaper-moods --print PATH   # print classification + stats for debugging
```

### State management

Three layers:

1. **System state** — owned by the OS / existing scripts. Read via shell commands, file watches, or `Quickshell.Io` services.

2. **User preferences** — owned by `~/.config/dotfiles/settings.json`. Schema (additions in **bold**):
   ```json
   {
     "wallpaper": {
       "frequency": "daily",
       "skip_today": false,
       "sources_enabled": {
         "local": true, "unsplash": true, "reddit": true, "bing": true, "picsum": true
       },
       "sources_order": ["local", "unsplash", "reddit", "bing", "picsum"],
       "custom_subreddits": ["wallpapers", "earthporn", "minimalwallpaper"],
       "unsplash_api_key": "",
       "recent": [],
       "favorites": [],
       "library_dir": "",
       "selected_mood": null
     },
     "appearance": {
       "accent_mode": "dynamic",
       "manual_accent": null
     }
   }
   ```
   `selected_mood` persists the last filter so reopening the settings app shows the same mood grid state.

3. **Mood index** — `~/.cache/dotfiles/wallpaper-moods.json`, a flat map of absolute path → array of mood ids. Owned by the `tag-wallpaper-moods` script. The settings app reads it; never writes it.

4. **UI state** — purely transient (which page is open, scroll position, hover). Lives in QML properties; not persisted.

## Mood Taxonomy

Six moods. Each defined as a gradient (for the mood tile), a representative palette (for the Hero in browse mode), and a classification rule in **OKLCH** color space (for the tagger).

OKLCH is `Lightness ∈ [0,1]` (perceptual), `Chroma ∈ [0, ~0.4]` (saturation, non-uniform max), `Hue ∈ [0, 360)`. All "luminance" / "saturation" references in rules below mean OKLCH `L` and `C`.

Stats per palette:
- `L_avg` — pixel-count-weighted mean of `L` across the top-8 cluster colors
- `C_avg` — same, weighted mean of `C`
- `h_dom` — hue of the cluster with highest `cluster_size × C` (so big-but-grey clusters don't dominate)
- `colors[]` — the eight clusters with their `(L, C, h, weight)` for per-color rules

| Mood | Gradient | Tagger rule (OKLCH) |
|---|---|---|
| **Dark** | `linear-gradient(135deg, #0a0a14, #1a1a28)` | `L_avg < 0.40` |
| **Light** | `linear-gradient(135deg, #f0f0f5, #e0e0ea)` | `L_avg > 0.75` |
| **Warm** | `linear-gradient(135deg, #cc4a3a, #ffa85f)` | `h_dom ∈ [20, 95]` AND `C_avg > 0.05` |
| **Cool** | `linear-gradient(135deg, #3a5fcc, #5fb1ff)` | `h_dom ∈ [200, 290]` AND `C_avg > 0.05` |
| **Sky** | `linear-gradient(180deg, #5fa8e8, #e8c89a)` | At least one color with `h ∈ [220, 250]` AND `L > 0.55` AND `C < 0.10`, AND `C_avg < 0.08` overall (washed-out, atmospheric) |
| **Earth** | `linear-gradient(135deg, #3a4a2a, #a8884a)` | At least one color with `h ∈ [120, 160]` (greens) AND one with `h ∈ [50, 90]` AND `C < 0.10` (browns/khakis) |

A wallpaper can carry multiple tags (Warm + Sky for sunsets over water; Dark + Cool for moonlit oceans). Untagged wallpapers always appear in the unfiltered "All wallpapers" view.

Mood definitions live in **two mirrored files**: `MoodCatalog.qml` (gradients + display labels for the UI) and `mood_rules.py` (numeric rule thresholds, imported by the tagger). The single source of truth for *visual data* is QML; for *classification thresholds* is Python. Both files are short (~50 lines each) and cross-referenced in comments.

## Maintainability Principles

These rules apply to all settings-app code. Future agents must not violate them without updating this section.

### Component boundaries

- **One responsibility per file.** A QML file does one thing — Hero shows current state, MoodGrid handles mood selection, ScheduleCard owns the schedule UI. No file mixes data fetching, layout, *and* business logic.
- **Files target ≤ 200 lines.** If a file exceeds 250, split it. The current `WallpaperPage.qml` (310 lines) is the main offender; the refactor breaks it into 7 ≤150-line pieces.
- **Pages compose, components present, data stores own state.** A page (`WallpaperPage`) is a thin layout that composes presentational components (`WallpaperHero`, `MoodGrid`…). Components are dumb — they read from `SettingsStore` / `MoodCatalog` and emit signals. Stores own all writes.

### Naming

- Components named for what they *are* (`MoodTile`, `ScheduleCard`), not what they do (`MoodPicker`, `ScheduleHandler`).
- Page directories named for the category id (`pages/wallpaper/`, `pages/appearance/`), matching `Categories.qml` ids.
- Stores singletons end in `Store` or `Catalog` (`SettingsStore`, `MoodCatalog`).

### Adding a new page (the maintainability test)

The architecture passes the "new page test" if adding a new category requires:

1. Add an entry to `Categories.qml` (one object literal).
2. Add a new file or subdirectory under `pages/`.
3. Add the index → page mapping in `SettingsContent.qml` (one line in a switch).
4. Update `qmldir` (one line per new component).

No edits to `SettingsWindow`, `SettingsSidebar`, `SettingsStore`, or any existing page. If the new page needs new persisted prefs, it adds its own section to `settings.json` schema (no schema migration needed since the store does shallow merge).

### Scalability

| Aspect | Current | Headroom |
|---|---|---|
| Wallpaper grid render | `Repeater` (loads all at once) | Up to ~200 wallpapers comfortable. Beyond, swap to `GridView` with delegate recycling — same component interface, ~30 line change |
| Mood tagger | Multi-threaded, ~50 ms/image | Linear in library size; 1000 wallpapers ≈ 30s on first run, ~50ms incremental |
| Settings IO | Single JSON file with shallow merge | Fine to ~10K of settings. Beyond, split per-page JSON files (existing schema makes this trivial) |
| Theme reload | Hot via `Theme.qml` file watch | No code change needed for new colors |

### Tests

- `test/tag-wallpaper-moods.bats` covers each mood rule with a 200×200 fixture image checked into `test/fixtures/wallpapers/`. New moods MUST add a fixture and a test.
- `test/settings-store.bats` covers JSON round-trip + corruption recovery. New `settings.json` sections MUST add a round-trip test.
- The smoke script (`settings/test-smoke.sh`) opens the window, tabs through all pages, exits clean. New pages MUST add a tab-through case.

### Documentation contract

When the next agent picks up Ship 2 (Appearance/Icons), they read in order:

1. This spec (one file, this directory)
2. `quickshell/.config/quickshell/settings/README.md` (architecture overview)
3. The implementation plan for the ship they're starting

If those three files don't make it obvious where to put new code, the spec or README has a bug — fix it before writing the page.

## Visual Design

### Window

- **Default:** 1000 × 640, centered on focused output (matches existing `SettingsWindow.qml`)
- **Expanded** (mood selected): 1000 × 900, animated growth downward with spring easing (`Easing.OutBack`, 380ms, overshoot 1.05)
- 16px border radius (matches existing implementation)
- Solid layered surfaces: window `#1a1611`, title bar `#231d16`, sidebar `#15110c` (already implemented)
- Subtle inner border: `1px rgba(255,255,255,0.06)`
- Drop shadow approximated by stacked rectangles (already implemented)
- Solid scrim layer behind window (rgba(0,0,0,0.55)) — already implemented

Width never changes — only height. This keeps the window predictable on multi-monitor setups and avoids re-centering during animation.

### Title bar

- 42px tall (matches existing implementation)
- Mac-style traffic-light buttons on the left, **tinted with palette colors** (close → `Theme.color1`, min → `Theme.color5`, max → `Theme.color2`)
- Centered title "Settings" in `Theme.fontFamily` (Fira Sans), 13px medium, secondary text color
- Search field on the right (Ship 2+; placeholder visible in Ship 1)

### Sidebar (232px wide)

- Background: `#15110c` (slightly darker than content, hairline-divided)
- Section headers (uppercase, tracked, 10px) — Personalization / System / About
- Nav items: 22px Phosphor Duotone icon + label
- Active item: gradient `accent → accent-soft`, white text, accent shadow ring
- Hover: `surfaceHover` background, 140ms transition

### Wallpaper page layout (Ship 1)

Top to bottom inside the content area:

1. **WallpaperHero** (160px) — two-column row.
   - Left (1.5fr): current wallpaper image card (rounded, drop shadow, 'CURRENT' badge top-left).
   - Right (1fr): meta card — `Now playing` label + filename, `Palette` label + 6 swatch dots (clickable to set as accent), accent row with `Dynamic / Manual` pill at bottom.
   - When a mood is selected, the hero's left card replaces the wallpaper preview with the mood's gradient and the meta swaps: the title becomes "Browsing mood: <Name>", and the accent row becomes a "← Back to all moods" link with the mood's count. **The "Back to all" affordance lives in the hero meta**, not in the mood grid itself.

2. **MoodGrid** (compact ~140px) — 6 tiles in a single row, each a gradient with mood name, count badge, and tiny palette dots.
   - Idle: a slow specular sweep crosses the tile every 6s (translated white-overlay rectangle, ~12% opacity peak). No animated gradient stops.
   - Hover: lifts 3px, deeper shadow (180ms ease).
   - Selected: ring (2px white at 15%) + outer glow, other 5 tiles dim to 35% opacity.
   - Click selected mood again, or click the hero's "← Back to all" link, deselects (window collapses back to 640).

3. **WallpaperGrid** (only present when mood selected, ~280px) — 4-column grid of filtered wallpapers.
   - Header row: "<Mood> wallpapers" + count badge + sort options (Newest / Random / Most used).
   - Each card: 16:10 aspect ratio, rounded 8px, drop shadow.
   - Stage-in animation: fade + translate-up from y+12px, staggered 40ms per card, total 380ms.
   - Hover: scale 1.04 with mood-tinted glow ring.
   - Click: `setWallpaper(path)`. Hero crossfades to new wallpaper, theme retints, drawer collapses (window shrinks back to 640 height).

4. **Control row** (200px) — two cards side by side.
   - **ScheduleCard (1.3fr):** icon + name + sub ("Next change in 4h 12m") in header. Pill segment row (Off / Hourly / 6h / Daily). Toggle row "Skip today". Button row "Fetch new wallpaper now".
   - **SourcesCard (1fr):** icon + name + sub ("3 enabled") in header. List of 5 source rows, each with mini icon, name, optional subtext, and toggle. The Local row has its folder path as subtext + "⋯" overflow menu (Change folder / Open in file manager / Re-tag library).

### Controls

- **MoodTile** — gradient card. White text + dots inside (or dark text on Light tile). Drift animation, shimmer, hover lift, selected ring.
- **Pill selector** — already exists; segmented control with active pill highlighted by accent gradient.
- **ToggleSwitch** — already exists; iOS-style with accent-colored on state.
- **ColorSwatch** — 22px circle, white inner ring + accent outer ring when selected. Hover scales 1.15.
- **Wallpaper card** (in grid) — 16:10 image with bottom gradient overlay.

### Icons — Phosphor Duotone

Loaded from `ttf-phosphor-icons`. `PhosphorIcon.qml` exposes `name`, `size`, `weight`, `color`. Default weight: **Regular**. The Duotone variant is used when explicit; we don't rely on the secondary fill picking up `Theme.accent` (verified problematic in earlier spike).

### Typography

- Family: `Fira Sans` (already in `Theme.fontFamily`)
- Page title: 24px / 700 (existing)
- Section header: 10px / 700 / 0.8px tracking / uppercase / `#6b6258`
- Mood tile name: 14px / 600 / -0.2px tracking / white (or `#2a2a3a` on Light)
- Row title: 13px / 500
- Row description: 11px / `#8a8175`

### Color tokens

All structural colors come from `Theme.qml`. Mood gradients are defined in `MoodCatalog.qml` as static palettes — they are deliberately not pywal-derived because their job is to act as a *guide*, not to follow the current theme.

## Categories

| Section | Category | Phosphor Icon | Ship |
|---|---|---|---|
| Personalization | Wallpaper | `image` | **1** |
| Personalization | Appearance | `palette` | 2 |
| Personalization | Icons | `shapes` | 2 |
| System | Display | `monitor` | 3 |
| System | Keybindings | `keyboard` | 3 |
| System | Network | `wifi-high` | 4 |
| System | Sound | `speaker-high` | 4 |
| About | System Info | `info` | 4 |

## MVP — Ship 1: Wallpaper Page

**Acceptance criteria:**

1. `MOD+,` opens a 1000×640 settings window centered on focused output.
2. Sidebar shows all eight categories. Clicking a category switches the content area. Non-MVP categories show the "Coming soon" placeholder.
3. Wallpaper page renders four sections in order: WallpaperHero · MoodGrid · (WallpaperGrid only when a mood is selected) · ScheduleCard + SourcesCard row.
4. **WallpaperHero**:
   - Reads `~/.config/current_wallpaper`.
   - Shows preview image with filename overlay.
   - Shows derived palette (6 swatches from `~/.cache/wal/colors.json`).
   - Click any palette swatch → sets it as manual accent (writes to `settings.json`, calls `apply-theme`).
   - `Dynamic / Manual` pill toggles accent mode.
5. **MoodGrid**:
   - 6 tiles (Dark, Light, Warm, Cool, Sky, Earth) with gradients defined in `MoodCatalog.qml`.
   - Each tile shows mood name + count of matching wallpapers from `wallpaper-moods.json`.
   - Hover lifts; click selects (others dim, window grows downward to 900 height).
   - Click selected mood again (or "← Back to all" link in hero) deselects (window shrinks back to 640).
6. **WallpaperGrid** (only when mood selected):
   - 4-column grid of wallpapers tagged with the selected mood.
   - Stage-in animation: 380ms total, 40ms stagger.
   - Click any wallpaper → calls `setWallpaper(path)` → hero crossfades + theme retints + drawer collapses.
7. **ScheduleCard**:
   - Pill segment for frequency: Off / Hourly / 6h / Daily. Selecting one writes to `settings.json` and reconfigures `daily-wallpaper.timer` via systemd overrides (existing `FrequencyPicker` logic).
   - Toggle for "Skip today" — touches/removes `~/.local/share/dotfiles/skip_today`.
   - Button "Fetch new wallpaper now" — calls `fetch-wallpaper`.
8. **SourcesCard**:
   - 5 rows: Local / Unsplash / Reddit / Bing / Picsum. Each with toggle.
   - Local row shows folder path + "⋯" overflow menu (Change folder, Open in file manager, Re-tag library).
   - "Change folder" opens a directory picker (zenity / kdialog fallback) and writes the result to `settings.json` `library_dir`.
9. **`tag-wallpaper-moods` script** exists and is callable. On settings app first open, runs in background, shows a toast if it took >300ms.
10. **`fetch-wallpaper` script** updated to read `wallpaper.library_dir` from `settings.json` (currently hardcoded to `~/Pictures/wallpapers/`). Falls back to default if unset.
11. All theme tokens live (changing wallpaper updates the settings UI without restart).
12. Window closes on Escape, on title-bar close button, and on outside click.
13. `qs ipc call settings toggle` works.
14. Settings persistence to `~/.config/dotfiles/settings.json` round-trips correctly.

**Out of scope for Ship 1:**

- Search field
- Keyboard navigation between sidebar and content
- Drag-and-drop reordering of source priority (use up/down arrows in Ship 2)
- Custom mood definitions or user-defined moods
- Animations beyond the documented spring + crossfade + stagger

## Subsequent Ships

- **Ship 2 — Appearance + Icons.** Theme variants, font sizing, GTK/icon theme picker. Wires into existing `apply-theme` and GTK config writers. Source priority drag-reorder lands here.
- **Ship 3 — Display + Keybindings.** Display: monitor list from `niri msg outputs --json`, modes, scaling. Keybindings: parse `niri/config.kdl`, list each binding, allow rebind via key capture.
- **Ship 4 — Network + Sound + System Info.** Network: nmcli wrapper. Sound: Pipewire service binding. About: distro info, kernel, uptime, dotfiles version.

Each ship: own commit(s), own acceptance criteria, full pass through `verification-before-completion` skill before declaring done.

## Error Handling

- **Missing scripts** — Settings UI shows the action greyed-out with a tooltip explaining the missing dependency.
- **Failed shell commands** — `Process` `onExited` checks `exitCode != 0` → surface a transient toast at the bottom of the window (3s, dismissible) with the script's stderr.
- **Malformed `settings.json`** — `SettingsStore.qml` writes a `.bak` copy and resets to defaults, logs to `~/.local/share/dotfiles/settings-app.log`.
- **Missing `wallpaper-moods.json`** — settings app shows mood tiles with `count: 0`; clicking shows an empty grid with a "Run mood tagger" hint that triggers the script manually. The page still works for browsing and fetching.
- **Mood tagger errors** (missing ImageMagick, corrupt image) — script logs to `~/.local/share/dotfiles/mood-tagger.log`, skips bad files, continues. UI shows toast on completion only if errors exceed 5.
- **Theme reload failures** — already handled by existing `apply-theme` rollback paths.
- **Missing Phosphor font** — `PhosphorIcon.qml` falls back to a textual placeholder (single uppercase letter).

## Testing

- **Manual smoke test** per ship — `quickshell/.config/quickshell/settings/test-smoke.sh` opens the window, switches pages, exits.
- **Mood-tagger bats test** — `test/tag-wallpaper-moods.bats` covers the classification rules with fixture images (5–10 small JPGs in `test/fixtures/wallpapers/`).
- **`SettingsStore` round-trip bats test** — covers JSON load/save with mood-tag persistence.
- **Visual regression** — screenshots committed under `docs/superpowers/specs/screenshots/` per ship.

## Knowledge Sharing for Future Agents

Three artifacts ensure the next agent doesn't have to re-derive context:

1. **This spec** — `docs/superpowers/specs/2026-05-10-settings-app-design.md`
2. **Implementation plan** — `docs/superpowers/plans/2026-05-10-settings-app-implementation.md` (next step)
3. **Module README** — `quickshell/.config/quickshell/settings/README.md`, written as part of Ship 1, explaining file layout + extension pattern (how to add a new page).

Each ship commit message includes a "Decisions made" footer listing autonomous choices.

## Open Questions / Risks

| Item | Status | Mitigation |
|---|---|---|
| Pillow availability on target system | Already a transitive dep via pywal | No new install needed; `install.sh` adds explicit `python-pillow` for clarity |
| Mood classification accuracy with mixed-color wallpapers | Unknown until tested with the user's library | Tagger errs on the side of multi-tagging; the `--print` CLI flag lets the user inspect any image's stats and tune `mood_rules.py` thresholds without touching code elsewhere |
| Window resize jank with PanelWindow on Niri | Unknown | Spike test in Ship 1; if jank, switch to fixed-size container with internal `clip:true` and just animate inner content (drawer pattern) |
| Folder picker (zenity / kdialog) availability | Likely present | Add to `install.sh`; fallback: `xdg-mime` text input dialog |
| `niri/config.kdl` rewriting for keybindings — KDL parser availability | Unknown | Defer to Ship 3 |
| Display configuration via `niri msg` — runtime persistence | Unknown | Confirm in Ship 3 |
| Phosphor Duotone via Qt FontLoader — does it render two-tone correctly? | Verified problematic | Default to Regular weight; Duotone only when explicitly requested per icon |

## Decision Log

| # | Decision | Rationale | Reversibility |
|---|---|---|---|
| 1 | Quickshell over AGS | Active stack; pywal-integrated; supports glossy/animated UI; AGS being phased out per AGENTS.md | High |
| 2 | New window in existing qs daemon (vs new process) | Matches AudioPanel/PowerMenuPopout pattern; shares Theme; one IPC surface | High |
| 3 | Sidebar nav (vs tabs / grid) | Mac aesthetic match; scales to 8+ categories | Medium |
| 4 | Phosphor Duotone icons | Two-tone picks up accent automatically; 9000+ icons; font-loadable | High |
| 5 | Frontend-over-scripts (no new logic) | Existing scripts work; avoids parallel implementations; AGENTS.md non-duplication norm | High |
| 6 | `~/.config/dotfiles/settings.json` for prefs | Plain file; scripts already read this dir; no daemon required | High |
| 7 | Ship 1 = Wallpaper only | "Start with the simplest" — wallpaper has the richest existing backend | High |
| 8 | **Mood-led discovery as the primary wallpaper interaction** | The library is large enough that filename-scrolling fails; mood-led browsing turns the page from a list into an experience | Medium — could revert to flat library grid in one PR |
| 9 | **Six fixed moods (Dark/Light/Warm/Cool/Sky/Earth)** | Hand-curated taxonomy is predictable and visually composable; auto-clustering produces wonky group names; "feeling" axes generalize better than thematic ones (Sunset, Forest…) | High — `MoodCatalog.qml` is one file |
| 10 | **Window grows downward, width fixed** | Drawer metaphor; predictable on multi-monitor; avoids re-centering animation jank | Medium |
| 11 | **Wallpaper-moods stored at `~/.cache/dotfiles/wallpaper-moods.json`** | Cache, not config — regeneratable; flat path→tags map is trivial to read from QML | High |
| 12 | **Mood tagging via Python + Pillow + OKLab/OKLCH** | OKLab is perceptually uniform (HSL is not); Pillow already on system via pywal; pure-Python OKLab conversion is ~30 lines, no new heavy deps; in-process beats `magick` shell-out for testability and determinism | Medium — could swap to pywal-based extraction by replacing `extract_palette()` |
| 15 | **Mirrored mood definitions: `MoodCatalog.qml` (UI) + `mood_rules.py` (thresholds)** | Each language owns what it needs; both files are tiny and cross-referenced; trying to share via JSON adds a build step and helps no one | High |
| 16 | **Versioned cache schema (`{ "version": 1, "tags": {...} }`)** | Future schema changes (e.g. adding stats) won't break old caches — just bump version + regenerate | High |
| 17 | **`Repeater` for wallpaper grid in Ship 1, `GridView` later if needed** | Repeater is simpler to author; YAGNI for libraries < 200 wallpapers; documented swap path | High |
| 18 | **Maintainability rules codified in spec, not just intent** | "Future agents must not violate" is enforceable in code review; the "new page test" is concrete and falsifiable | N/A |
| 13 | **Schedule + Sources always visible (cards below grid)** | Mandatory features must not be buried by the new mood UI; user explicitly called this out | Low — moving them into a sub-tab would be a UX regression |
| 14 | **Folder picker via zenity / kdialog** | Standard system dialog; no custom QML directory tree; matches user expectations | High |
