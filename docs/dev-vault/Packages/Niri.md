# Niri

Scrollable-tiling Wayland compositor.

## Location

`niri/.config/niri/config.kdl` → `~/.config/niri/config.kdl`

## Key Files

| File | Purpose |
|------|---------|
| `config.kdl` | All compositor config: keybindings, layout, startup programs, focus ring |

## Architecture

Niri's scrollable-tiling model:
- **Vertical workspaces** — scroll with `Mod+Page_Up`/`Mod+Page_Down`
- **Columns** — columns scroll horizontally with `Mod+Left`/`Mod+Right`
- Windows tile within columns

## What Lives Here

- **Keybindings** — all keyboard shortcuts
- **Startup programs** — `spawn-at-startup` blocks (Quickshell, swaync, swww, etc.)
- **Focus ring** — colors patched by `apply-theme` (active-color, inactive-color)
- **Input config** — keyboard layout, touchpad settings
- **Output config** — monitor layout, scale, refresh rate

## Notable Keybindings

| Action | Keys |
|--------|------|
| Focus window | `Mod+{Arrows}` / `H,J,K,L` |
| Move window | `Mod+Ctrl+{Arrows}` |
| **Focus adjacent monitor** | `Mod+Shift+{Arrow}` |
| **Move column to monitor** | `Mod+Shift+Ctrl+{Arrow}` |
| Focus workspace 1-9 | `Mod+{1-9}` |
| Open launcher | `Mod+Space` |
| Terminal | `Mod+Enter` |

## Multi-Monitor

Output config uses exact names from `niri msg outputs` — case-sensitive, must match exactly or the block is silently ignored.

```kdl
output "SKYDATA S.P.A. TV-monitor 0x01010101" {
    mode "1920x1080@60"
    scale 1
    position x=1920 y=0
}
```

Live reconfiguration without restart:
```bash
niri msg output "<name>" mode "1920x1080@60"
niri msg output "<name>" position set 1920 0
```

## Integration Points

- **Quickshell** — launched at startup; Niri provides `niri msg --json event-stream` for live workspace/window data
- **apply-theme** — patches focus ring colors in `config.kdl` after pywal runs
- **Keybindings page** — `welcome/parse-niri-keybinds.sh` extracts binds for the Welcome wizard

## Conventions

- KDL syntax, 4-space indent
- Keybindings use `Mod` (Super/Windows key) as primary modifier
- Startup programs run via `spawn-at-startup` blocks (not external scripts)

## Extending

To add a keybinding: add a `binds` block with the key combo and action. To add a startup program: add a `spawn-at-startup` block with the command and arguments as a list.
