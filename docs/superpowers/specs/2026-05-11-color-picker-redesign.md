# Color Picker Redesign — Primary + Secondary

Status: approved, ready for implementation
Date: 2026-05-11

## Problem

The wallpaper page color picker has three issues users reported:

1. **Confusing what is being selected.** A 6-swatch row with a Dynamic|Manual pill, but no visual mapping between swatches and roles. Clicking any swatch jumps to manual mode silently.
2. **No primary/secondary distinction.** Only one accent exists end-to-end (`apply-theme` → `Theme.qml` → consumers).
3. **Dynamic mode is not read-only.** Swatches are clickable in Dynamic mode and switch the mode as a side effect.

Plus two layout bugs:

4. **Current wallpaper preview doesn't refresh** when the wallpaper file is rewritten in place (e.g., `daily.jpg`). The source URL string is unchanged, Qt cache serves stale pixels.
5. **Padding is off** — the page gives the hero a 28px gutter, the hero adds another 28px internally, so the hero is inset further than the cards beneath it.

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

1. **Primary** = current `best_accent` algorithm — most-saturated palette color with anti-repeat against `last_primary`.
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

The existing FileView watcher already re-reads `colors.json` on change — no new wiring needed.

## Where Secondary gets used (initial)

Initial pass updates only sites that already have a hover or active state:

- Bar segments hover backgrounds (`BarPill`, `BarIconButton`, `IconButton`)
- Settings `ToggleSwitch` track when ON
- Wallpaper grid hover ring on tiles
- `PillSelector` selected pill background

Out of scope: workspace markers, taskbar fill, focus rings — these stay on `accent`/`primary`.

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

In `WallpaperHero.qml`, drop the internal `anchors.leftMargin: 28` and `anchors.rightMargin: 28` — let the page-level `Column { x: 28; width: parent.width - 56 }` own the gutter. Keep `topMargin: 8` and `bottomMargin: 8` for vertical breathing room.

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

- `scripts/.local/bin/apply-theme` — secondary computation, settings.json read for manual override
- `quickshell/.config/quickshell/Theme.qml` — primary/secondary properties, accent alias
- `quickshell/.config/quickshell/settings/data/SettingsStore.qml` — `manual_accent` migration, `setManualPrimary`/`setManualSecondary`, `wallpaperVersion` counter
- `quickshell/.config/quickshell/settings/pages/wallpaper/WallpaperHero.qml` — full color-section rewrite, cache-busted preview URL, padding fix
- `quickshell/.config/quickshell/settings/components/ColorSwatch.qml` — explicit selection ring
- `quickshell/.config/quickshell/BarPill.qml`, `IconButton.qml`, `PillSelector.qml`, `WallpaperGrid.qml`, `ToggleSwitch.qml` — hover/active states use `Theme.secondary`
- `test/apply-theme.bats` (new or updated) — secondary derivation tests
