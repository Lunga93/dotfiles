# Welcome (Manatee Welcome)

First-run onboarding wizard built with Quickshell/QML.

## Location

`welcome/` → `~/.config/manatee-welcome/` + `~/.local/bin/manatee-welcome`

## Architecture

5-step wizard launched once on first login:

| Step | Page | Purpose |
|------|------|---------|
| 1 | `WelcomePage.qml` | Logo + tagline + "Get Started" |
| 2 | `OverviewPage.qml` | Distro components grid |
| 3 | `KeybindingsPage.qml` | Searchable Niri keybindings |
| 4 | `ThemingPage.qml` | Wallpaper thumbnails |
| 5 | `FinishPage.qml` | Links + hotkey reminder |

## Key Files

| File | Purpose |
|------|---------|
| `shell.qml` | Main app — fullscreen PanelWindow, StackView for pages |
| `Theme.qml` | Design tokens (hardcoded dark palette with pywal live-update) |
| `qmldir` | Module registry |
| `DistroFacts.qml` | Distro metadata singleton |
| `Keybindings.qml` | Keybinding data model |
| `NiriKeybindsModel.qml` | Parsed Niri keybinding model |
| `parse-niri-keybinds.sh` | Extracts keybindings from niri config.kdl → JSON |
| `manatee-welcome` | Bash launcher — checks flag file, generates data, launches qs |
| `manatee-welcome.desktop` | Autostart entry |

### UI Components

| File | Purpose |
|------|---------|
| `Card.qml` | Frosted-glass card with shadow |
| `PrimaryButton.qml` | Primary action button |
| `SecondaryButton.qml` | Back/secondary button |
| `PageContainer.qml` | Shared page layout wrapper |
| `Stepper.qml` | Step indicator dots |
| `KeybindingChip.qml` | Pill-shaped keybinding chip |

## Integration Points

- **Niri** — parses keybindings from `config.kdl`
- **wallpapers** — scans `~/Pictures/wallpapers/` for thumbnails
- **Autostart** — launched by Niri `spawn-at-startup`; checks `shown` flag in `~/.local/state/manatee-welcome/`

## Conventions

- State file: `~/.local/state/manatee-welcome/shown` (delete to re-trigger)
- Data generation: keybinds JSON + wallpaper list generated on first run
- Flag must exist and be empty/marked to skip on subsequent logins

## Extending

To add a wizard step:
1. Create `YourPage.qml`
2. Add it to the StackView in `shell.qml`
3. Update the stepper count
4. If it needs data, add a singleton or script
