# GTK

libadwaita/GTK theme integration via pywal colors.

## Location

`gtk/.config/` → `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/`

## Key Files

| File | Purpose |
|------|---------|
| `gtk-3.0/colors-wal.css` | GTK3 pywal palette: rewritten by `apply-theme` |
| `gtk-4.0/colors-wal.css` | GTK4 pywal palette: rewritten by `apply-theme` |

## Integration Points

- **apply-theme**: writes both color files. Most libadwaita apps pick up the new palette without restarting.

## What This Affects

- Nautilus
- GTK file dialogs
- libadwaita apps (GNome Builder, etc.)
- Any GTK3/4 app respecting CSS custom properties

## Conventions

- CSS custom properties matching pywal output
- Same palette written for both GTK3 and GTK4
- No base theme files: this just overrides colors on top of the system theme

## Extending

To add new CSS variables: edit both `gtk-3.0/colors-wal.css` and `gtk-4.0/colors-wal.css` with matching variable names.
