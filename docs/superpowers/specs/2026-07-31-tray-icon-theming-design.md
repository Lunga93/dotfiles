# Tray Icon Theming — design spec

**Date:** 2026-07-31
**Status:** Design locked, ready for implementation plan
**Scope:** `quickshell/.config/quickshell/TraySegment.qml`

## Context

The top bar's right pill mixes two icon languages. The glyph segments
(clipboard, volume, bluetooth, power) render Nerd Font PUA glyphs via
`Theme.fontMono` tinted with `Theme.textPrimary`. The tray segment, however,
renders `SystemTrayItem.icon` as a raw `IconImage` — the artwork ships from the
indicator apps themselves, so it keeps native/brand colors (green Spotify logo,
arbitrary grays from clipboard managers, update indicators, etc.) and ignores
the pywal palette entirely. The mismatch reads as "ugly": the tray cluster is
the one part of the bar that refuses to follow the theme.

## Goals

- Make every tray icon use a theme color instead of its app-supplied artwork
  colors.
- Idle state: `Theme.textPrimary` (matches the glyph segments' default tint).
- Hover/pressed state: `Theme.accent` (matches how glyph buttons light up on
  interaction, per the user's chosen design).
- Keep the existing hover background pill, sizing, and click behavior untouched.

## Non-goals

- Tinting the **taskbar** app icons (center pill) — those are window identity
  badges and intentionally keep brand colors.
- Recoloring glyph segments — they already use `Theme.textPrimary`.
- Replacing the tray service (`Quickshell.Services.SystemTray`) or menu handling.
- Adding per-app tint overrides or configurable tint colors.

## Design

### Locked decisions

| Decision | Locked value | Notes |
|---|---|---|
| Tint approach | `MultiEffect.colorization: 1.0` | Layer effect; matches existing repo usage (BarPill, Card, Indicator, BarGlowText) |
| Idle tint | `Theme.textPrimary` | Same as glyph segments |
| Hover / pressed tint | `Theme.accent` | Lights up on interaction |
| Transition | `ColorAnimation`, `Theme.durationFast` (140 ms) | Consistent with the rest of the bar |
| Icon sizing | unchanged (`Theme.barIconSize`) | — |

### Why `MultiEffect` over `Qt5Compat.GraphicalEffects.ColorOverlay`

`MultiEffect.colorization` is already the established pattern in this config
(`BarPill.qml:28`, `Card.qml:25`, `Indicator.qml:36`, `BarGlowText.qml:47`).
It colorizes using the source's luminance and preserves alpha, which is exactly
the monochrome tint desired. The repo runs Qt 6.11 (`QtQuick.Effects`),
so no `Qt5Compat` dependency is introduced.

### Implementation shape

In each tray delegate (`TraySegment.qml`):

```qml
Item {
    id: item
    required property SystemTrayItem modelData

    property color tint: (mouse.containsMouse || mouse.pressed)
        ? Theme.accent : Theme.textPrimary
    Behavior on tint { ColorAnimation { duration: Theme.durationFast } }

    // ...existing background Rectangle...

    IconImage {
        id: trayIcon
        anchors.centerIn: parent
        width: Theme.barIconSize
        height: Theme.barIconSize
        source: item.modelData ? item.modelData.icon || "" : ""
        smooth: true
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: item.tint
        }
    }

    // ...existing MouseArea (id: mouse)...
}
```

The delegate already references `mouse.containsMouse` / `mouse.pressed` from
before the `MouseArea` declaration (the background `Rectangle` does), so the
forward id lookup is an established pattern in this file.

## Verification

1. **Syntax** — `qmllint` on `TraySegment.qml` passes (no new warnings beyond
   pre-existing ones); `qmlformat` leaves the file idempotent.
2. **Idle** — with the bar running, tray icons render in the theme foreground
   (matches the glyph segments), including brand-colored apps (e.g. Spotify).
3. **Hover** — hovering a tray icon animates its color to `Theme.accent` and
   back on leave; the background pill still shows.
4. **Interaction unchanged** — left/right/middle click and the platform menu
   (`display()`) still work; filtered `nm-applet` still hidden.
5. **Theme change** — wallpaper swap re-tints the tray icons via `Theme.qml`'s
   existing `colors.json` watcher (no `qs` restart).

## Open questions

- None. Design is fully determined.
