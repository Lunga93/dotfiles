# Fastfetch

System information display tool (neofetch replacement).

## Location

`fastfetch/.config/fastfetch/` → `~/.config/fastfetch/`

## Key Files

| File | Purpose |
|------|---------|
| `config.jsonc` | Fastfetch config — modules, logo, display options |
| `manatee-logo.jpg` | Logo image rendered as ASCII art by Chafa |

## What It Shows

- OS, host, kernel, uptime
- Packages, shell, display config
- DE, WM, theme, icons, font, cursor, terminal
- CPU, GPU, memory, swap, disk
- Local IP, battery, power adapter, locale
- 16-color swatch block
- Custom ASCII logo from `manatee-logo.jpg`

## Conventions

- JSON with comments (`.jsonc`)
- Logo rendered via Chafa (256-color indexed, diffusion dithering)
- No theming integration — static config

## Extending

To add or remove info modules: edit `config.jsonc` — add/remove entries in the `modules` array.
