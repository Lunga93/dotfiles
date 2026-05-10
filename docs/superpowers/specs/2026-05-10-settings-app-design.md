# Settings App — Design Spec

**Status:** Approved (design phase)
**Date:** 2026-05-10
**Author:** Brainstormed with the user; agent-assisted
**Audience:** Future agents and human contributors picking up this work

## Purpose

Build a glossy, modern, full-window settings application for the Niri + Quickshell desktop. The app is the single front-door for configuring wallpaper, appearance, display, keybindings, and other system utilities — replacing the current "edit config files by hand" workflow.

The design priority is **visual polish** (Mac-inspired glass, glossy gradients, dynamic theme colors) over feature breadth at launch. Ship one category fully working, then iterate.

## Goals

1. **Single front-door for settings** — replace ad-hoc config edits with a discoverable UI.
2. **Glossy + modern aesthetic** — feel more refined than typical Linux settings panels (GNOME / KDE Systemsettings).
3. **Live theme integration** — every visual element adapts to pywal palette changes in real time, with zero manual restart.
4. **Frontend over existing scripts** — never re-implement logic that already works in `~/.local/bin/`. The settings app calls existing scripts; it is not a parallel implementation.
5. **Scalable architecture** — adding a new category should be a self-contained file, not a global refactor.
6. **Knowledge transfer** — design + plan + decisions are documented so the next agent (human or AI) can continue without conversation history.

## Non-Goals

- Replacing `niri/config.kdl` or `Theme.qml` as the source of truth.
- Building a configuration daemon, IPC bus, or new state machine. State lives in plain files.
- Cross-distro support. This targets the user's Niri + Quickshell + pywal stack on CachyOS.
- Pixel-perfect Mac fidelity. We borrow the language, not clone it.

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
└── settings/                     # NEW — all settings UI lives here
    ├── README.md                 # architecture overview for next agent
    ├── SettingsWindow.qml        # top-level PanelWindow
    ├── SettingsSidebar.qml       # category nav
    ├── SettingsContent.qml       # right-hand content host (StackLayout)
    ├── components/               # reusable building blocks
    │   ├── SettingsGroup.qml     # rounded card containing rows
    │   ├── SettingsRow.qml       # label + control row
    │   ├── ToggleSwitch.qml      # iOS-style toggle
    │   ├── PillSelector.qml      # segmented pill control
    │   ├── ColorSwatch.qml       # accent swatch button
    │   └── PhosphorIcon.qml      # icon font wrapper
    ├── pages/                    # one file per category
    │   ├── WallpaperPage.qml     # MVP Ship 1
    │   ├── AppearancePage.qml    # Ship 2
    │   ├── IconsPage.qml         # Ship 2
    │   ├── DisplayPage.qml       # Ship 3
    │   ├── KeybindingsPage.qml   # Ship 3
    │   ├── NetworkPage.qml       # Ship 4
    │   ├── SoundPage.qml         # Ship 4
    │   └── AboutPage.qml         # Ship 4
    └── data/
        ├── SettingsStore.qml     # singleton — reads/writes settings.json
        └── Categories.qml        # singleton — sidebar definition
```

### Data flow

```
┌──────────────────────────────────────────────────────────┐
│ User opens Settings (MOD+, or qs ipc call)               │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
            ┌──────────────────────────────┐
            │ SettingsWindow.qml           │
            │  ↳ SettingsSidebar           │
            │  ↳ SettingsContent (Stack)   │
            └──────────────────────────────┘
                            │
            User clicks "Wallpaper"        User toggles "Daily fetch"
                            │                              │
                            ▼                              ▼
            ┌──────────────────────────┐   ┌────────────────────────────┐
            │ WallpaperPage.qml        │──▶│ SettingsStore.set(key,val) │
            │  ↳ shows current image   │   │  → writes settings.json    │
            │  ↳ daily toggle          │   │  → spawns side-effect      │
            │  ↳ accent picker         │   │    (systemctl, scripts)    │
            └──────────────────────────┘   └────────────────────────────┘
                            │                              │
                            └──────────┬───────────────────┘
                                       ▼
                        ┌──────────────────────────────┐
                        │ Existing scripts:            │
                        │  set-wallpaper, fetch-...,   │
                        │  apply-theme, systemctl,     │
                        │  niri msg output             │
                        └──────────────────────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │ pywal regenerates colors.json│
                        │  → Theme.qml hot-reloads     │
                        │  → Settings UI re-themes     │
                        └──────────────────────────────┘
```

### Backend integration (no new logic)

| UI action | Existing script / command |
|---|---|
| Set wallpaper from picker | `set-wallpaper <path>` |
| Fetch new daily wallpaper | `fetch-wallpaper` |
| Toggle daily timer | `systemctl --user enable/disable daily-wallpaper.timer` |
| Skip today | Touch `~/.local/share/dotfiles/skip_today` |
| Choose source priority | Write to `~/.config/dotfiles/settings.json`, `fetch-wallpaper` reads it |
| Re-apply theme | `apply-theme <wallpaper>` |
| Pick manual accent | Write to `~/.local/share/dotfiles/last_accent`, call `apply-theme` |
| Toggle dynamic vs manual accent mode | Write to `settings.json`, `apply-theme` honors it |
| Display arrangement | `niri msg output <name> ...` |
| Read/write keybindings | Parse + edit `niri/config.kdl` (text manipulation, with backup) |
| Network | `nmcli` |
| Sound | Already-existing `audio-set` and Quickshell Pipewire service |

The settings app **never reimplements** these — it shells out and reads the same state files the scripts write.

### State management

Three layers:

1. **System state** — owned by the OS / existing scripts (running services, current wallpaper, network connection, etc.). Read via shell commands or file watches.

2. **User preferences** — owned by `~/.config/dotfiles/settings.json`. Schema:
   ```json
   {
     "wallpaper": {
       "source_priority": ["local", "unsplash", "reddit", "bing", "picsum"],
       "daily_enabled": true
     },
     "appearance": {
       "accent_mode": "dynamic",
       "manual_accent": null
     },
     "icons": {
       "theme": "default"
     }
   }
   ```
   `SettingsStore.qml` is the single QML reader/writer. Scripts that consume the file (e.g. `fetch-wallpaper`, `apply-theme`) read it directly.

3. **UI state** — purely transient (which page is open, scroll position). Lives in QML properties; not persisted.

## Visual Design

### Window

- 980 × 620, centered on the focused output
- 18px border radius (matches `Theme.radiusCard`)
- Glassmorphic backdrop: `Theme.surface` (translucent over background)
- Subtle inner border: `1px rgba(255,255,255,0.08)`
- Drop shadow: `0 30px 60px rgba(0,0,0,0.5)`
- Optional dim layer behind window (matches Mac modal feel)

### Title bar

- 38px tall
- Mac-style traffic-light buttons on the left, **tinted with palette colors** (close → `color1`, min → `color5`, max → `color2`)
- Centered title "Settings" in `Theme.fontFamily` (Fira Sans), 12px semibold, secondary text color
- Search field on the right (Ship 2+; placeholder visible in Ship 1)

### Sidebar (220px wide)

- Background: `rgba(0,0,0,0.20)` over the window's translucent surface
- Section headers (uppercase, tracked, 10px) — Personalization / System / About
- Nav items: 22px Phosphor Duotone icon + label
- Active item: gradient `accent → accent-soft`, white text, accent shadow ring
- Hover: `surfaceHover` background, 140ms transition

### Content area

- 22px page title + secondary subtitle
- Settings grouped in **rounded cards** (`SettingsGroup`)
- Each card: small uppercase header + rows separated by hairline borders
- Rows: label + description (left) + control (right)
- Glassmorphism: `surfaceElev` background, blur(10px), 1px translucent border

### Controls

- **Toggle switch** — accent-colored when on (with soft glow), `surfaceHover` when off
- **Pill selector** — segmented control; active pill has gradient + glow
- **Color swatch** — 30px circle, white inner ring + accent outer ring when selected
- **Wallpaper preview** — 120px tall card, real image, rounded 12px

### Icons — Phosphor Duotone

Loaded from the system-installed `ttf-phosphor-icons` (or downloaded from `phosphoricons.com` as a fallback `.ttf` placed in the package). Wrapper component `PhosphorIcon.qml` exposes `name` and `weight` properties.

Default weight: **Duotone**. Falls back to **Regular** if Duotone isn't available.

The duotone secondary fill picks up `Theme.accent` automatically — this is the key reason for the choice.

### Typography

- Family: `Fira Sans` (already in `Theme.fontFamily`)
- Page title: 22px / 700 / -0.4px tracking
- Section header: 11px / 700 / 0.6px tracking / uppercase / `textSecondary`
- Row title: 13px / 500
- Row description: 11px / `textSecondary`

### Color tokens

All colors come from `Theme.qml`. No new tokens needed for Ship 1. Future ships may add `Theme.surfaceFloat` (window-floating glass) and `Theme.accentGradient` if required.

## Categories

| Section | Category | Phosphor Icon | Ship |
|---|---|---|---|
| Personalization | Wallpaper | `ph-image` | **1** |
| Personalization | Appearance | `ph-palette` | 2 |
| Personalization | Icons | `ph-shapes` | 2 |
| System | Display | `ph-monitor` | 3 |
| System | Keybindings | `ph-keyboard` | 3 |
| System | Network | `ph-wifi-high` | 4 |
| System | Sound | `ph-speaker-high` | 4 |
| About | System Info | `ph-info` | 4 |

## MVP — Ship 1: Wallpaper Page

The first shippable increment. Everything else is gated until this is solid.

**Acceptance criteria:**

1. `MOD+,` opens a 980×620 settings window centered on focused output.
2. Sidebar shows all eight categories. Clicking a category switches the content area. (Non-MVP categories show a "Coming soon" placeholder.)
3. Wallpaper page renders:
   - Current wallpaper preview (reads `~/.config/current_wallpaper`)
   - "Pick from folder" button → opens wofi-style picker (reuses `wallpaper-menu` script)
   - "Fetch new wallpaper" button → runs `fetch-wallpaper`
   - "Daily wallpaper" toggle → enables/disables `daily-wallpaper.timer`
   - "Skip today" toggle → manages `~/.local/share/dotfiles/skip_today`
   - Source priority pill row (Local / Unsplash / Reddit / Bing / Picsum) — multi-select reorderable list. Persisted to `settings.json`.
   - Accent mode pill (Dynamic / Manual)
   - Accent swatch picker (reads from `~/.cache/wal/colors.json` for dynamic candidates; in Manual mode, all 6 are pickable)
4. All theme tokens live (changing wallpaper updates the settings UI without restart).
5. Window closes on Escape, on title-bar close button, and on outside click.
6. `qs ipc call settings toggle` works.
7. Settings persistence to `~/.config/dotfiles/settings.json` round-trips correctly.

**Out of scope for Ship 1:** search, keyboard navigation between sidebar and content, animations beyond simple transitions, drag-and-drop reordering of source priority (basic up/down arrows only).

## Subsequent Ships

- **Ship 2 — Appearance + Icons.** Theme variants, font sizing, GTK/icon theme picker. Wires into existing `apply-theme` and GTK config writers.
- **Ship 3 — Display + Keybindings.** Display: monitor list from `niri msg outputs --json`, modes, scaling. Keybindings: parse `niri/config.kdl`, list each binding, allow rebind via key capture.
- **Ship 4 — Network + Sound + System Info.** Network: nmcli wrapper. Sound: Pipewire service binding. About: distro info, kernel, uptime, dotfiles version.

Each ship: own commit(s), own acceptance criteria, full pass through `verification-before-completion` skill before declaring done.

## Error Handling

- **Missing scripts** — Settings UI shows the action greyed-out with a tooltip explaining the missing dependency.
- **Failed shell commands** — `Process` `onExited` checks `exitCode != 0` → surface a transient toast at the bottom of the window (3s, dismissible) with the script's stderr.
- **Malformed `settings.json`** — `SettingsStore.qml` writes a `.bak` copy and resets to defaults, logs to `~/.local/share/dotfiles/settings-app.log`.
- **Theme reload failures** — already handled by existing `apply-theme` rollback paths.
- **Missing Phosphor font** — `PhosphorIcon.qml` falls back to a textual placeholder (the icon name as a single uppercase letter — same as the mockup).

## Testing

- **Manual smoke test** per ship — script in `quickshell/.config/quickshell/settings/test-smoke.sh` that opens the window, switches pages, and exits.
- **bats tests** for `SettingsStore` round-trip if we expose any shell helper (most logic stays in QML, so coverage is integration-style).
- **Visual regression** — screenshots committed under `docs/superpowers/specs/screenshots/` per ship.

## Knowledge Sharing for Future Agents

Three artifacts ensure the next agent doesn't have to re-derive context:

1. **This spec** — `docs/superpowers/specs/2026-05-10-settings-app-design.md`
2. **Implementation plan** — `docs/superpowers/plans/2026-05-10-settings-app-implementation.md` (next step)
3. **Module README** — `quickshell/.config/quickshell/settings/README.md`, written as part of Ship 1, explaining file layout + extension pattern (how to add a new page)

Each ship commit message includes a "Decisions made" footer listing autonomous choices.

## Open Questions / Risks

| Item | Status | Mitigation |
|---|---|---|
| Phosphor Duotone via Qt FontLoader — does it render two-tone correctly? | Unknown | Verify in Ship 1 spike before building UI. Fallback to Regular weight if not. |
| `niri/config.kdl` rewriting for keybindings — KDL parser availability | Unknown | Defer to Ship 3; investigate `kdl4j` or simple regex approach. |
| Display configuration via `niri msg` — runtime persistence | Unknown | Confirm Niri persists changes or whether we need to write `config.kdl`. |
| Window dimming behind settings | Optional | Niri "block-out" rule may suffice; investigate later. |
| Keyboard navigation (Tab/Arrows) | Deferred to Ship 2 | Track in plan |

## Decision Log

| # | Decision | Rationale | Reversibility |
|---|---|---|---|
| 1 | Quickshell over AGS | Active stack; pywal-integrated; supports glossy/animated UI; AGS being phased out per AGENTS.md | High — could rebuild in AGS later |
| 2 | New window in existing qs daemon (vs new process) | Matches AudioPanel/PowerMenuPopout pattern; shares Theme; one IPC surface | High — splitting later is mechanical |
| 3 | Sidebar nav (vs tabs / grid) | Mac aesthetic match; scales to 8+ categories | Medium — would touch most files |
| 4 | Phosphor Duotone icons | Two-tone picks up accent automatically; 9000+ icons; font-loadable | High — swap font in `PhosphorIcon.qml` |
| 5 | Frontend-over-scripts (no new logic) | Existing scripts work; avoids parallel implementations; AGENTS.md non-duplication norm | High |
| 6 | `~/.config/dotfiles/settings.json` for prefs | Plain file; scripts already read this dir; no daemon required | High |
| 7 | Ship 1 = Wallpaper only | "Start with the simplest" — wallpaper has the richest existing backend | High |
