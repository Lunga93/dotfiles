# Wofi

Fuzzy application launcher.

## Location

`wofi/.config/wofi/` → `~/.config/wofi/`

## Key Files

| File | Purpose |
|------|---------|
| `config` | Wofi configuration (position, size, mode) |
| `style.css` | Base styling |
| `colors-wal.css` | pywal-generated colors — rewritten on theme change |

## Integration Points

- **Keybinding** — bound to `Mod+Space` in Niri config
- **apply-theme** — writes `colors-wal.css`
- **Scripts** — `audio-menu`, `bluetooth-menu`, `clipboard-manager`, `wallpaper-menu` use Wofi as their UI

## Conventions

- Launcher mode for apps (`wofi --show drun`)
- Custom modes for scripts pipe options via stdin
- Colors from `colors-wal.css` (pywal)

## Extending

To add a custom Wofi menu: pipe options to `wofi --dmenu` and handle the selection in a script. See `audio-menu` for an example.
