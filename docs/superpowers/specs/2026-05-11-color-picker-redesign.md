# Color Picker Redesign: Primary + Secondary

Status: approved, ready for implementation
Date: 2026-05-11

## Problem

The wallpaper page color picker has three issues users reported:

1. **Confusing what is being selected.** A 6-swatch row with a Dynamic|Manual pill, but no visual mapping between swatches and roles. Clicking any swatch jumps to manual mode silently.
2. **No primary/secondary distinction.** Only one accent exists end-to-end (`apply-theme` → `Theme.qml` → consumers).
3. **Dynamic mode is not read-only.** Swatches are clickable in Dynamic mode and switch the mode as a side effect.

Plus two layout bugs:

4. **Current wallpaper preview doesn't refresh** when the wallpaper file is rewritten in place (e.g., `daily.jpg`). The source URL string is unchanged, Qt cache serves stale pixels.
5. **Padding is off**: the page gives the hero a 28px gutter, the hero adds another 28px internally, so the hero is inset further than the cards beneath it.

## Goals

- Two color slots (Primary + Secondary) end-to-end, including `apply-theme` and `Theme.qml`.
- Dynamic mode = read-only display of pywal-derived colors.
- Manual mode = explicit per-slot picker.
- Hero preview updates when the wallpaper file changes, even if the path string is unchanged.
- Hero padding aligns with the cards below it.

## Non-goals

- Migrating every existing component to consume `Theme.secondary`. Initial scope updates only obvious hover/active sites.
- Color theory beyond hue separation (no AA contrast checks, no luminance balancing).
- Showing color names or hex labels on swatches.
- Allowing arbitrary hex input (always pick from the pywal 6-color palette).

## Data model

`settings.json` `appearance` section becomes:

```json
"appearance": {
  "accent_mode": "dynamic" | "manual",
  "manual_primary":   "#RRGGBB" | null,
  "manual_secondary": "#RRGGBB" | null
}
```

- Renames `manual_accent` → `manual_primary`. `SettingsStore.qml` migrates on load: if `manual_accent` exists and `manual_primary` does not, copy across, then drop the old key on next save.
- `manual_secondary` is null until the user picks one. `apply-theme` falls back to derived secondary when null, even in manual mode (allows partial customization).

## apply-theme algorithm

After pywal generates `colors.json`:

1. **Primary** = current `best_accent` algorithm: most-saturated palette color with anti-repeat against `last_primary`.
2. **Secondary** = next-best score where `|hue(secondary) − hue(primary)| ≥ 60°` (circular). If no candidate satisfies the hue gap, fall back to next-best regardless.
3. Read `~/.config/dotfiles/settings.json`. If `accent_mode == "manual"`:
   - If `manual_primary` set → override primary.
   - If `manual_secondary` set → override secondary.
4. Write both values into `colors.json` as `colors.primary_accent` and `colors.secondary_accent` (preserves pywal's existing keys, additive).
5. Cache files: `~/.local/share/dotfiles/last_primary` and `~/.local/share/dotfiles/last_secondary` (replaces `last_accent`).

## Theme.qml additions

```qml
property color primary    // = colors.primary_accent (or pywal color2 fallback)
property color secondary  // = colors.secondary_accent (or pywal color4 fallback)
property color accent     // alias for primary, kept for backward compatibility
```

The existing FileView watcher already re-reads `colors.json` on change: no new wiring needed.

## Where Secondary gets used (initial)

Initial pass updates only sites that already have a hover or active state:

- Bar segments hover backgrounds (`BarPill`, `BarIconButton`, `IconButton`)
- Settings `ToggleSwitch` track when ON
- Wallpaper grid hover ring on tiles
- `PillSelector` selected pill background

Out of scope: workspace markers, taskbar fill, focus rings: these stay on `accent`/`primary`.

## Hero color-section UI (in WallpaperHero.qml)

Replaces the existing palette + pill block. Layout:

```
┌─ Color scheme ──────────  [Dynamic | Manual] ──┐
│                                                 │
│ Primary    ⬢ ⬢ ⦿ ⬢ ⬢ ⬢                          │
│ Secondary  ⬢ ⦿ ⬢ ⬢ ⬢ ⬢                          │
└─────────────────────────────────────────────────┘
```

- Mode pill at top right of the section, label "Color scheme" at top left.
- Two labeled rows ("Primary", "Secondary"), each with the 6 palette swatches.
- Currently-selected swatch in each row gets a 2px ring in `Theme.foreground` for clear identification.
- **Dynamic mode**: rows render at `opacity: 0.55`, `MouseArea` disabled, no cursor change. The ring still shows what pywal picked.
- **Manual mode**: rows at `opacity: 1.0`, click on a swatch sets that row's slot via new `SettingsStore.setManualPrimary(hex)` / `setManualSecondary(hex)`.

## Wallpaper preview cache-bust

In `SettingsStore.qml`:

- Add `property int wallpaperVersion: 0`.
- In `_wallpaperFile.onLoaded`, increment `wallpaperVersion` regardless of whether the path string changed.

In `WallpaperHero.qml`:

- Image `source` becomes `"file://" + SettingsStore.currentWallpaper + "?v=" + SettingsStore.wallpaperVersion`.
- Qt's QML Image treats different URLs as different sources and bypasses cache for the new one.

## Padding fix

In `WallpaperHero.qml`, drop the internal `anchors.leftMargin: 28` and `anchors.rightMargin: 28`: let the page-level `Column { x: 28; width: parent.width - 56 }` own the gutter. Keep `topMargin: 8` and `bottomMargin: 8` for vertical breathing room.

## Bugs fixed along the way

- Replace the `Column { anchors.fill: parent }` containing children with `anchors.topMargin` / `anchors.bottom` (which Qt warns about and ignores) with explicit `ColumnLayout` from `QtQuick.Layouts`, or with positional `y` calculations.
- Add explicit selected-ring rendering on `ColorSwatch` (currently only `selected: true` toggles a subtle border).

## Migration

- Existing users with `appearance.manual_accent` get auto-migrated to `manual_primary` on first load. `manual_secondary` defaults to null (uses derived).
- `last_accent` cache file kept for one release as fallback for `last_primary` lookup, then removed.

## Testing strategy

- Existing bats tests for `apply-theme` need updates to assert both `primary_accent` and `secondary_accent` are written to `colors.json`.
- Add a hue-gap test: feed apply-theme a known pywal palette, assert the chosen secondary differs from primary by ≥60°.
- Smoke test: launch the shell with the new `WallpaperHero`, verify no QML warnings about Column anchors.

## Files touched

- `scripts/.local/bin/apply-theme`: secondary computation, settings.json read for manual override
- `quickshell/.config/quickshell/Theme.qml`: primary/secondary properties, accent alias
- `quickshell/.config/quickshell/settings/data/SettingsStore.qml`: `manual_accent` migration, `setManualPrimary`/`setManualSecondary`, `wallpaperVersion` counter
- `quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperHero.qml`: full color-section rewrite, cache-busted preview URL, padding fix
- `quickshell/.config/quickshell/settings/components/ColorSwatch.qml`: explicit selection ring
- `quickshell/.config/quickshell/BarPill.qml`, `IconButton.qml`, `PillSelector.qml`, `WallpaperGrid.qml`, `ToggleSwitch.qml`: hover/active states use `Theme.secondary`
- `test/apply-theme.bats` (new or updated): secondary derivation tests

## Post-launch fixes (2026-05-11)

User-reported bugs after Ship 1 landed and the four root causes:

| Symptom | Root cause | Fix |
|---|---|---|
| Color swatches won't select | `WallpaperHero.isManual` (and every other `SettingsStore.get(...)` binding) never re-evaluated after a write because `SettingsStore.set()` mutated `data[section][key]` in place; QML only fires change notifications when the `var` reference itself changes. | Rewrite `set()` to build a new top-level `data` object (`Object.assign` at every touched level) and reassign. Also fixed the file-load path and `migrateAccentFields` which had the same in-place mutation. |
| Buttons feel "unclickable" | Same as above: `currentFrequency`, `isOn`, `isManual` etc. stayed stale even though the underlying writes succeeded. Click was processed; UI just never reflected it. | Same fix: `set()` reactivity. |
| Page won't scroll on mouse wheel | `Flickable` in Qt 6 does not consume wheel events natively. The custom thumb scrollbar was visual-only. | Add a `WheelHandler` (non-visual `PointHandler`: does NOT get reparented to `contentItem` like a child `Item` would) inside both the `WallpaperPage` Flickable and the `SettingsSidebar` Flickable. |
| Wallpaper grid invisible after picking a mood | `WallpaperPage` set `wallpaperGrid.height: visible ? implicitHeight : 0`. `WallpaperGrid` declared `height: gridHeader.height + gridView.contentHeight + 16` but never set `implicitHeight`, so `Item.implicitHeight` defaulted to `0` and the grid collapsed to zero pixels. | `WallpaperGrid` now sets `implicitHeight` instead of `height`. `WallpaperPage` drops the override and relies on `Column` skipping `visible: false` items. |

### Notes for future work

- `PillSelector` overrides its own `currentIndex` on click (`root.currentIndex = index;`), which permanently severs the parent binding. Today this is masked because every consumer also writes the underlying state, so the next read agrees. If you ever need PillSelector to track *external* state changes, drop the local override and emit only `selected(index)`: let the parent drive `currentIndex` via the binding.
- `MoodGrid` has the same pattern: writing to its own `selectedMood` inside `onClicked` breaks the binding from `WallpaperPage`. Same caveat applies.
- The `Process { id: scanner }` inside `WallpaperGrid` is currently dead code: `running: true` with no `command` set, and the `scan()` function is never invoked. The grid only renders the mood-filtered cache today, so the scanner adds no value. Remove it next time you touch the file.

## Post-launch fixes round 2 (2026-05-11)

| Symptom | Root cause | Fix |
|---|---|---|
| Mood "carousel" tiles cut off on left and right edges | Row of 6 × 140px tiles + 5 × 12px gaps = 900px, but the inner column is only 712px. Row is `anchors.centerIn parent`, so first and last tile overflow ~94px each side and get clipped by the Flickable. | Shrink `MoodTile` to 108 × 120: six tiles + gaps now sum to 708px and fit cleanly. |
| `WheelHandler` doesn't fire on either Flickable in this Quickshell build | Unknown: the file linted and qs started without errors, but the event evidently never reaches the handler. May be a Qt 6 / fork-specific quirk. | Replace with `ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }`. Attaching a ScrollBar to a Flickable wires up Qt's built-in wheel/touchpad handler regardless of the bar's visual policy. The custom thumb-only scrollbar remains as the visible indicator. |
| 305 archive files but only 165 unique by content hash (140 duplicates) | `fetch-wallpaper` always copied `daily.jpg` into `archive/daily-<ts>.jpg` before overwriting it, even when the file content hadn't changed. | One-time fix: ran new `wallpaper-cleanup` script (305 → 41 files). Going-forward: `fetch-wallpaper` now hashes the existing `daily.jpg` against the most recent archive entry and skips the copy when they match. |
| No automated archive maintenance | None existed. | New script `scripts/.local/bin/wallpaper-cleanup` does content-hash dedup (keep oldest) + age-prune (default 60 days). Scheduled by new `systemd/.config/systemd/user/wallpaper-cleanup.{service,timer}` running `OnCalendar=monthly` with a 30-minute random delay. The script refuses to delete the file currently pointed to by `~/.config/current_wallpaper` and refreshes the mood cache after running. |

### Files added/touched in round 2

- `scripts/.local/bin/wallpaper-cleanup` (new)
- `scripts/.local/bin/fetch-wallpaper`: skip archive when current daily.jpg hash matches latest archive entry
- `systemd/.config/systemd/user/wallpaper-cleanup.service` (new)
- `systemd/.config/systemd/user/wallpaper-cleanup.timer` (new, enabled via `timers.target.wants/` symlink)
- `quickshell/.config/quickshell/settings/pages/wallpaper/MoodTile.qml`: width 140 → 108
- `quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperPage.qml`: `WheelHandler` → `ScrollBar.vertical`
- `quickshell/.config/quickshell/settings/SettingsSidebar.qml`: `WheelHandler` → `ScrollBar.vertical`

## Post-launch fixes round 3 (2026-05-11)

### Mood-rule defect: Sky and Earth never matched

`tag-wallpaper-moods` MOOD_RULES used `h in range(220, 251)` to test if a color's hue was in the sky-blue range. Python's `range()` only contains integers: `225.7 in range(220, 251)` is `False`. Since `math.atan2()` returns floats, hue checks for Sky and Earth basically never fired regardless of how sky-like a wallpaper was. Warm and Cool used `<=` comparisons so they worked.

Fix: replace `h in range(a, b)` with explicit `a <= h < b` in the two affected rules. After fix, the existing 43-image library tagged as Sky 0→5, Earth 0→11.

### `--force` didn't actually force a re-tag

`process_file` in `tag-wallpaper-moods` always returned `None` when the cache's stored mtime matched the file's current mtime. So `--force` re-walked the library but every file was skipped, meaning the mood-rule fix above didn't actually propagate until the cache was deleted.

Fix: `process_file` takes a `force` parameter; CLI `--force` passes it through. Also added: after the run, drop cache entries pointing to files that no longer exist on disk (previously the cache grew forever and `MoodCatalog.qml` could report phantom matches against deleted paths).

### Wallpaper seeding system

The user's library after dedup contained only 43 photos: too few for any rule tuning to surface meaningful results in the underrepresented moods (Light, Sky). Built a seeding system that downloads ~100 photos and distributes them across moods.

**Architecture:**

- `scripts/.local/bin/seed-wallpapers` (Python). Downloads from Reddit (round-robin across 8 subreddits × 4 sort modes, cap 18 per combo for variety) + Picsum. Classifies in-process using the same OKLab/OKLCH pipeline as `tag-wallpaper-moods` (`MOOD_RULES` mirrored: drift risk acknowledged; small and explicitly cross-referenced). Greedy mood-balanced selection: prefers candidates filling the rarest mood, caps per-mood at 22, keeps up to 10 untagged for variety.
- `~/.local/share/dotfiles/seed-day`: single integer 1..28, picked randomly on first run, stored. The timer fires daily but the script exits immediately unless today's day-of-month matches this stored day. Spreads load across machines.
- `~/.local/share/dotfiles/seed-manifest.json`: list of paths the seeder owns. Monthly refresh wipes only these, leaving user-added photos untouched.
- `systemd/.config/systemd/user/seed-wallpapers.{service,timer}`: `OnCalendar=daily` with 2h random delay, `Persistent=true` for catch-up after downtime.

**CLI:** `--initial` (force first run, picks seed-day if missing), `--refresh` (force a refresh today regardless of seed-day), `--dry-run`, `--target N` (default 100), `--quiet`.

**Initial run result:** 86 of 100 target downloaded and selected (Light hit a natural ceiling: Reddit photo subs lean dark/dramatic). Library went from 43 → 130 wallpapers; MoodCatalog from 19 → 104 tagged. Per-mood: dark 25, light 5, warm 18, cool 14, sky 27, earth 23.

**Known limitation:** Light remains underrepresented (5) because `L_avg > 0.75` is a strict threshold and few Reddit photos qualify. Two future paths: (a) lower the threshold to ~0.65, (b) add `r/SnowPorn`, `r/BeachPorn`, `r/MinimalWallpaper` higher in the rotation. Punted for now.

### Files added/touched in round 3

- `scripts/.local/bin/seed-wallpapers` (new)
- `scripts/.local/bin/tag-wallpaper-moods`: fixed float-in-range bug for Sky/Earth; added `--force` plumbing; drop stale cache entries
- `systemd/.config/systemd/user/seed-wallpapers.{service,timer}` (new, enabled via `timers.target.wants/` symlink)
- `~/.local/bin/{tag-wallpaper-moods,wallpaper-cleanup,seed-wallpapers}`: manual symlinks (stow blocked by an unrelated existing file)
