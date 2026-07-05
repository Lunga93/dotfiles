# SDDM

Quickshell-based SDDM login greeter.

## Location

`sddm/themes/quickshell-pywal/` → `/usr/share/sddm/themes/quickshell-pywal/`

Installed by `install.sh` (not stowable — system path requires sudo).

## Key Files

| File | Purpose |
|------|---------|
| `Main.qml` | Greeter entry point — login form, user list, password field |
| `Theme.qml` | Design tokens for the greeter |
| `theme.conf` | SDDM theme metadata |

## Integration Points

- **apply-theme** — pushes colors and wallpaper to `/var/lib/sddm-theme/` (user-writable)
- **SDDM** — reads theme files from `/usr/share/sddm/themes/quickshell-pywal/`
- **sddm-greeter-debug** — script to test the greeter in a window without logging out

## Conventions

- Runtime state synced via `/var/lib/sddm-theme/` (not `~/.cache/`)
- QML surface colors match the desktop pywal palette
- Theme mirror at `/var/lib/sddm-theme/theme.conf.user` (no sudo required for updates)

## Extending

To modify the greeter layout: edit `Main.qml`. To sync additional state: add file writes to `apply-theme` and read paths in QML.
