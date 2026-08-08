# v0.2.0 — Dark Mode, Accent Hover & Heal Pipeline

## Dark / Light Mode
- Toggle in Settings → Display (Dark | Light pill selector)
- `apply-theme` reads `appearance.color_scheme` from `settings.json`
- Pywal runs with `-l` for light mode, injects `scheme` into `colors.json`
- `Theme.qml` surface colors flip via `surfaceOverlay()` (white in dark, black in light)
- Settings window colors (surfaceWindow, textHeader, etc.) adapt to scheme
- `gsettings color-scheme` set system-wide for GTK/Qt apps
- 20+ settings pages: hardcoded hex/rgba replaced with Theme tokens
- Fixed race condition: settings.json saved before apply-theme runs (0.5s delay)

## Accent Hover
- Bar icons (volume, clock, workspaces, bluetooth, network, power, clipboard) tint `Theme.accent` on hover
- No background rectangles or white overlays — pure glyph color shift
- Matches tray icon tint behavior
- Tray segment: removed white hover/press background rectangle (dirty icon area fix)

## Quickshell Directory Refactor
- 39 QML files moved from flat root into 7 subdirectories:
  `bar/` (6)  `segments/` (9)  `popouts/` (5)  `components/` (8)
  `design/` (1)  `state/` (1)  `audio/` (1)
- `qmldir` updated with new paths, `import "../"` added to all subdir files
- `design/Theme.qml` (was flat root), `state/Globals.qml`, `audio/AudioNames.qml`

## Bar Regression Fixes (from overlord branch)
- Network icon: uses `textPrimary` like other system icons (was bright accent always-on)
- Ethernet icon: reverted to `󰈀`, increased network icon size
- Restored nm-applet tray filter (no duplicate wifi icons)
- Restored MultiEffect tinting on tray icons
- Restored QtRendering on bar icon buttons (no Nerd Font glyph corruption)

## Network Panel
- `NetworkPanel.qml` popout wired into bar + Globals + IPC (`qs ipc call network toggle`)
- `NetworkSegment.qml` in bar right pill

## Self-Healing Pipeline
- `journal-watch`: watches journal for niri/swaync errors, rate-limited webhook POSTs
- `webhook-listener`: HTTP server on :9876, `/heal` auto-fixes via opencode, `/task` drives feature dev
- `niri-healthcheck`: proactive niri validate + compositor responsiveness + service status (every 30min)
- `niri-heal-pause` / `niri-heal-resume`: pause/resume pipeline for manual editing
- `niri-heal-log`: log viewer (`-f` for follow, `tasks` for task logs)
- OpenCode `niri-healer` agent command with restricted bash permissions

## Night Light
- `night-light` script: reads `display.night_light_*` from settings.json, drives wlsunset
- `--watch` mode polls every 3s (systemd unit), live toggle from Settings → Display page

## Screenshots
- `Ctrl+Shift+1/2/3` save to `~/Pictures/Screenshots/` with timestamps (was clipboard-only)

## Theming & Style
- Wallhaven purity filter: `110` → `100` (SFW only, no sketchy/ecchi tier)
- Niri focus ring + menu QSS + Alacritty: pywal-driven palette (green accent shift)
- Shell-level comments on `shell.qml` use `//@ pragma UseQApplication` for tray menus

## Documentation
- README: screenshot gallery (desktop overview, calendar, power menu)
- Docs: em-dashes replaced with colons across all markdown files
- Package docs updated: Quickshell (dir tree, dark mode, accent hover), Scripts (heal pipeline, night-light, apply-theme), Niri (screenshots)
- `RELEASE.md`: this file, added for v0.2.0

## Cleanup
- JetBrains machine-local desktop entries removed from repo
- `.bak` files cleaned from quickshell directory
- `AGENTS.md` verified and pruned for accuracy (stale AUR/package references removed)
