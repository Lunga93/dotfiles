# Alacritty

GPU-accelerated terminal emulator.

## Location

`alacritty/.config/alacritty/` → `~/.config/alacritty/`

## Key Files

| File | Purpose |
|------|---------|
| `template.alacritty.toml` | Template with pywal color placeholders: source of truth |
| `alacritty.toml` | **Generated**: built from template by `apply-theme` |

## How It Works

`apply-theme` reads `template.alacritty.toml`, substitutes pywal color variables, and writes `alacritty.toml`. A validation step (`test-alacritty.sh`) briefly launches Alacritty to catch config errors (duplicate TOML keys, syntax issues).

If validation fails, the broken file is saved as `.broken.<timestamp>` and the template is written as a fallback.

## Integration Points

- **apply-theme**: regenerates `alacritty.toml` on every theme change
- **test-alacritty.sh**: automatic validation with rollback

## Conventions

- TOML format (not YAML)
- Template uses `{color0}`..`{color15}`, `{background}`, `{foreground}` placeholders
- Font config is in the template (not user-configurable per-theme)

## Extending

Edit `template.alacritty.toml` to change defaults (font, opacity, padding). Add new pywal placeholders if needed. Never edit `alacritty.toml` directly: it's overwritten.
