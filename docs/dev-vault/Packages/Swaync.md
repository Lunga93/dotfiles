# Swaync

Notification daemon with a slide-out control center.

## Location

`swaync/.config/swaync/` → `~/.config/swaync/`

## Key Files

| File | Purpose |
|------|---------|
| `config.json` | Notification behavior: timeout, position, notification blocking |
| `style.css` | Base styling |
| `colors.css` | pywal-generated colors — rewritten on theme change |

## Integration Points

- **apply-theme** — writes `colors.css` and calls `swaync-client -R` to reload
- **Autostart** — Niri config spawns `swaync` at startup
- **systemd** — `graphical-session.target.wants/swaync.service` symlink

## Conventions

- Default notification timeout: 3 seconds
- Colors come from `colors.css` (pywal-driven, not hardcoded)
- CSS uses CSS custom properties from pywal

## Extending

To add notification categories or change behavior: edit `config.json`. To style: edit `style.css` (base) which references `colors.css` (generated).
