# Top Bar Redesign — design spec

**Date:** 2026-05-11
**Status:** Design locked, ready for implementation plan
**Scope:** `dotfiles/quickshell/.config/quickshell/` (bar) + `dotfiles/quickshell/.config/quickshell/settings/` (new category)

## Context

The current top bar is three rounded pills (left / center / right) with an opaque-looking 55% background tint, 1-px hairline border, drop shadow, and Fira Sans Medium text. The user finds the typography "robotic" and the bar visually heavy. The redesign targets a **macOS menu bar feel** — translucent so the wallpaper shows through, soft humanist typography with a subtle text glow, and an ambient top-down hue gradient (like the tint band on a car windshield) that picks up colors from the active pywal palette.

To preserve the option of the current look, the redesign introduces **bar presets** as a first-class concept. Two presets ship: **Vibrancy** (the new default) and **Original** (today's design, snapshotted exactly as-is). Users can switch between them and, within Vibrancy, fine-tune gradient style, opacity, glow, and typography from a new Top Bar settings page.

## Goals

- Replace the current 3-pill bar with a single edge-to-edge translucent surface (Vibrancy preset).
- Add a windshield-style top-down color gradient pulled from the pywal palette (4 styles + intensity slider).
- Switch typography to Inter Light by default; allow SF Pro, Geist, Manrope, and per-axis weight customization.
- Add soft text-glow (configurable intensity).
- Preserve the current look as a selectable **Original** preset — no user is forced into the new style.
- Expose all of the above via a new **Top Bar** category in the existing Quickshell settings app.

## Non-goals

- Changing what content the bar shows (workspaces / taskbar / tray cluster stay where they are).
- Reimagining the popouts (audio, calendar, power) — out of scope.
- Bundling custom fonts as part of dotfiles — fonts are installed via separate packages (`pacman -S inter-font`; AUR for SF Pro etc.).
- Animation overhaul beyond the existing 140/220/320 ms durations.

## Design

### Locked decisions (from visual brainstorming)

| Decision | Locked value | Notes |
|---|---|---|
| Background treatment | Vibrancy — edge-to-edge, ~22 % bg tint, no border | Replaces 3-pill design |
| Typography | Inter, weight Light (300) | Default; falls back to system if Inter not installed |
| Layout | Workspaces left · Taskbar pills center · Tray cluster right | Same as current, but edge-to-edge instead of pills |
| Gradient | Windshield (top-down, fades to clear at bar bottom) | 4 styles available |
| Default gradient style | Cabin (primary tint left-top, secondary tint right-top) | Pywal-driven |
| Gradient intensity default | 60 % (= 4-5 % max alpha at top) | Slider 0-100 % |
| Text glow default | 50 % | Slider 0-100 % |
| Original preset | Today's exact bar, frozen as the second preset | Selectable but not customisable |

### Bar surface

```
┌────────────────────────────────────────────────────────────────────────────┐
│ ● · · ·    zen-browser  Docs  alacritty           󰂯 󰕾 10:48  ⏻             │  ← Vibrancy preset, edge-to-edge
└────────────────────────────────────────────────────────────────────────────┘
  ▲ wallpaper shows through translucent surface, top-down hue gradient
```

- Edge-to-edge `PanelWindow` anchored top/left/right (no side margins like today's 3-pill).
- Background: `Rectangle` with color `Qt.rgba(Theme.background.r, .g, .b, bgOpacity)` where `bgOpacity` is read from settings (default 0.22).
- Optional gradient overlay (see below) layered on top of the background, *under* the content.
- Soft text shadow on all text: `0 0 6 rgba(255,255,255, glow*0.18) + 0 1 1 rgba(0,0,0,0.32)` — implemented in QML as a stacked `Text` blur layer (`MultiEffect { blurEnabled: true, blur: 0.4 }`) on a duplicated invisible text element behind the visible one.
- No border, no drop shadow (the bar should look like part of the wallpaper, not a panel hovering above it).

### Gradient styles (windshield, top-down)

All gradient styles use a **vertical mask** that fades from 1 at the top to 0 at the bottom — the bar is only 34 px tall, so the gradient is most visible in the top third and feels like ambient light coming from above. Color stops use pywal `primary_accent` and `secondary_accent`.

| Style | Composition | Max α | Live equivalent |
|---|---|---|---|
| Off | (no overlay) | 0 | None |
| Luminance | white linear, top-down | 0.07 | Pure "light from above", no hue |
| Single hue | primary linear, top-down | 0.09 | Pywal primary, fades down |
| Cabin (default) | primary (left-top) + secondary (right-top), both top-down | 0.06 each | Most "ambient cabin light" |

A user-controlled **Intensity** slider (0-100 %) multiplies each style's max alpha. The Original preset has gradient implicitly off; switching to Vibrancy applies the user's most recent gradient choice.

### Typography

- Family: pill selector — **Inter** (default), SF Pro, Geist, Manrope.
- Weight: pill selector — **Light** (default), Regular, Medium.
- Glow: slider 0-100 % — multiplies the `MultiEffect.blur` strength on the duplicated shadow text.

If the chosen font is not installed, the rendering silently falls back to `Theme.fontFamily` and the settings row shows a small "(not installed — run `pacman -S inter-font`)" hint.

### Original preset

A frozen snapshot of the current bar — kept exactly as-is so the user can revert with one click. The current `Bar.qml` is split into two named QML components:

- `bars/OriginalBar.qml` — today's three-pill design (verbatim copy of current Bar.qml).
- `bars/VibrancyBar.qml` — the new design.

`Bar.qml` becomes a thin dispatcher that loads either component based on `SettingsStore.data.top_bar.preset`.

### Settings page

New category under **Personalization → Top Bar** (between Appearance and Icons). Page layout — top to bottom:

1. **Live preview** — small section rendering the bar over the current wallpaper. Reflects every change in real time.
2. **Preset** group (single PillSelector: Original / Vibrancy). Switching disables/enables the customisation groups below.
3. **Gradient** group (active when preset = Vibrancy):
   - Style — PillSelector: Off / Luminance / Single hue / Cabin
   - Intensity — slider 0-100 %
4. **Surface** group (active when preset = Vibrancy):
   - Background opacity — slider 10-60 %
   - Text glow — slider 0-100 %
5. **Typography** group (active when preset = Vibrancy):
   - Font family — PillSelector: Inter / SF Pro / Geist / Manrope
   - Weight — PillSelector: Light / Regular / Medium

When preset = Original, the customisation groups remain visible but dimmed/disabled with a small note "Customisation available on the Vibrancy preset."

### Settings schema

Add a `top_bar` section to `~/.config/dotfiles/settings.json` via `SettingsStore.data`:

```jsonc
"top_bar": {
  "preset": "vibrancy",              // "original" | "vibrancy"
  "vibrancy": {
    "gradient_style": "cabin",       // "off" | "luminance" | "single_hue" | "cabin"
    "gradient_intensity": 0.6,       // 0.0–1.0
    "bg_opacity": 0.22,              // 0.10–0.60
    "text_glow": 0.5,                // 0.0–1.0
    "font_family": "Inter",          // "Inter" | "SF Pro" | "Geist" | "Manrope"
    "font_weight": "light"           // "light" | "regular" | "medium"
  }
}
```

Default population happens via `SettingsStore.data` initialiser (existing pattern). `SettingsStore.set("top_bar", "preset", "original")` calls update the JSON and emit `changed()`, which all bar components react to via property bindings on `SettingsStore.data.top_bar`.

### Files to add

```
dotfiles/quickshell/.config/quickshell/
├── bars/
│   ├── OriginalBar.qml              ← verbatim of current Bar.qml
│   └── VibrancyBar.qml              ← new design
├── BarGradient.qml                  ← reusable gradient overlay component
├── BarGlowText.qml                  ← Text + duplicated MultiEffect-blurred shadow
└── settings/pages/top-bar/
    ├── TopBarPage.qml               ← main page
    ├── TopBarPreview.qml            ← live preview component
    └── PresetSelector.qml           ← thin wrapper if needed
```

### Files to modify

| File | Change |
|---|---|
| `dotfiles/quickshell/.config/quickshell/Bar.qml` | Becomes dispatcher: `Loader { source: SettingsStore.data.top_bar.preset === "original" ? "bars/OriginalBar.qml" : "bars/VibrancyBar.qml" }` |
| `dotfiles/quickshell/.config/quickshell/qmldir` | Register OriginalBar, VibrancyBar, BarGradient, BarGlowText, TopBarPage, TopBarPreview |
| `dotfiles/quickshell/.config/quickshell/settings/data/Categories.qml` | Insert `{ id: "top-bar", label: "Top Bar", icon: "browser", ship: 2 }` under Personalization, index 2 |
| `dotfiles/quickshell/.config/quickshell/settings/data/SettingsStore.qml` | Add `top_bar` default section; persistence/load logic already handles arbitrary sections |
| `dotfiles/quickshell/.config/quickshell/settings/SettingsContent.qml` | Add `TopBarPage` slot at index 2, shift later placeholders to 3-8 |
| `dotfiles/quickshell/.config/quickshell/BarText.qml` | Take `glow` and `weight` properties; render glow via stacked blurred text |
| `dotfiles/quickshell/.config/quickshell/BarIconButton.qml` | Same glow + weight treatment for icon font |
| `dotfiles/quickshell/.config/quickshell/Theme.qml` | Add `fontFamilyVibrancy` token (reads `SettingsStore.data.top_bar.vibrancy.font_family`); add `barGlowStrength` token |

### Implementation work split (for parallel agents)

The work decomposes into four independent tracks that can run in parallel — no shared state between them:

1. **Settings schema + storage** — `SettingsStore.qml` defaults, migration of any existing config, `Categories.qml` insertion, `SettingsContent.qml` slot.
2. **Vibrancy bar QML** — `bars/VibrancyBar.qml`, `BarGradient.qml`, `BarGlowText.qml`, updates to `BarText.qml` and `BarIconButton.qml` for glow/weight.
3. **Bar dispatcher** — split `Bar.qml` into the new thin Loader + verbatim move of current code to `bars/OriginalBar.qml`.
4. **Settings page UI** — `settings/pages/top-bar/TopBarPage.qml`, `TopBarPreview.qml`, plus qmldir registrations.

After all four merge: integration verification — visual + functional checks per below.

## Verification

1. **Default boot** — fresh stow + restart Quickshell → bar renders in Vibrancy preset with Cabin gradient at 60 %, Inter Light, 22 % bg, 50 % glow. No errors in the qslog.
2. **Preset toggle** — open Settings → Top Bar → switch to Original. Bar instantly reverts to today's three-pill design with no restart. Switch back → Vibrancy returns.
3. **Gradient style swap** — cycle through Off / Luminance / Single hue / Cabin. Each transition is smooth (Theme.durationMed) and the gradient picks up the current pywal palette.
4. **Slider changes** — drag Intensity, Bg opacity, Text glow sliders. Bar updates live; values persist across Quickshell restarts.
5. **Font missing fallback** — temporarily uninstall `inter-font` (or select SF Pro before installing it). Bar still renders in `Theme.fontFamily`; settings row shows the install hint.
6. **Wallpaper change** — `set-wallpaper <other>.jpg`. Bar gradient re-tints within ~1 s (Theme.qml's FileView watch on `colors.json` already triggers this).
7. **Original parity** — visual diff of Original preset vs today's bar should be pixel-identical (we're moving the file, not editing it).

## Open implementation questions (resolved via plan)

- Whether `BarGlowText.qml` should use `MultiEffect.blur` (Qt 6.5+) or fall back to drawing duplicated `Text` items — defer to plan once we confirm the Quickshell Qt version on noctalia-qs 0.0.12.
- Exact pywal alpha curve when `gradient_intensity` slides — likely linear, but a small `Math.pow(x, 1.5)` may feel more responsive; tune during implementation.
