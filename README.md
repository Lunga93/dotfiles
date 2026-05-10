# dotfiles

A Wayland desktop for Arch-based systems, distributed as GNU Stow packages.
[Niri](https://github.com/YaLTeR/niri) compositor, [Quickshell](https://quickshell.outfoxxed.me/)
bar, pywal-driven theming.

## What's included

### Niri

Scrollable-tiling Wayland compositor. Vertical workspaces scroll with
`Mod+Page_Up`/`Mod+Page_Down`; columns scroll horizontally with `Mod+Left`/`Mod+Right`.
Keybindings, startup programs, focus ring colors all live in
`niri/.config/niri/config.kdl`.

### Quickshell

A single Qt6/QML shell daemon. One process renders the bar (one `PanelWindow`
per screen via `Variants { model: Quickshell.screens }`) and the floating
popouts: audio, calendar, power. Toggled from the bar or via
`qs ipc call <target> toggle`. Live-themed by `Theme.qml` watching
`~/.cache/wal/colors.json`.

### Wofi

Fuzzy launcher bound to `Mod+Space`. The wallpaper-derived palette is written
to `~/.config/wofi/colors-wal.css` on every theme change.

### swaync

D-Bus notification daemon with a slide-out control center. `colors.css` is
rewritten and reloaded automatically on theme change. Default `timeout` is 3s.

### Alacritty

Terminal. `alacritty.toml` is regenerated from `alacritty/template.alacritty.toml`
on every theme change; `test-alacritty.sh` validates the new file and rolls
back to the template (writing a `.broken.<ts>` backup) if the TOML is invalid.

### GTK / libadwaita

`gtk/.config/gtk-{3,4}.0/colors-wal.css` is rewritten on theme change so
Nautilus and other libadwaita apps pick up the new palette without restarting.

### SDDM

Quickshell-based greeter installed at `/usr/share/sddm/themes/quickshell-pywal`.
Runtime colors and wallpaper are pushed to the user-writable
`/var/lib/sddm-theme/`, so `apply-theme` updates the login screen without sudo.

## Theming

Wallpaper drives every palette via [pywal](https://github.com/dylanaraps/pywal).
`set-wallpaper <image>` runs swww, then `apply-theme` regenerates colors and
patches each component:

| Component   | Output                                                              |
|-------------|---------------------------------------------------------------------|
| Alacritty   | `~/.config/alacritty/alacritty.toml` (rebuilt from template)        |
| Niri        | focus ring `active-color` / `inactive-color` in `config.kdl`        |
| Quickshell  | `Theme.qml` reads `~/.cache/wal/colors.json` via `FileView`         |
| swaync      | `~/.config/swaync/colors.css` + `swaync-client -R` reload           |
| Wofi        | `~/.config/wofi/colors-wal.css`                                     |
| GTK 3/4     | `~/.config/gtk-{3,4}.0/colors-wal.css`                              |
| SDDM        | `/var/lib/sddm-theme/{theme.conf.user,wallpaper}`                   |

## Install

```sh
git clone https://github.com/Lunga93/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer requires Arch (`/etc/arch-release`), optionally runs `pacman -Syu`,
installs the package lists baked into `install.sh` (`OFFICIAL_PACKAGES` and
`AUR_PACKAGES`), then stows each entry in `STOW_DIRS`. Existing
`~/.config/<pkg>` directories are renamed to `<pkg>.bak` before being replaced.

After install, log out and start niri. Set a wallpaper to seed the palette:

```sh
set-wallpaper ~/Pictures/wallpapers/your-image.jpg
```

## Stow workflow

Each top-level directory mirrors its install destination:

```
quickshell/.config/quickshell/...  ->  ~/.config/quickshell/...
scripts/.local/bin/...             ->  ~/.local/bin/...
```

Always dry-run before stowing:

```sh
stow -n -v <package>   # preview only
stow -R <package>      # apply (idempotent re-stow)
stow -D <package>      # unstow
```

## Packages

| Stow dir     | Target                          | Notes                                       |
|--------------|---------------------------------|---------------------------------------------|
| `niri`       | `~/.config/niri/`               | Compositor (KDL)                            |
| `quickshell` | `~/.config/quickshell/`         | Bar + popouts (QML)                         |
| `swaync`     | `~/.config/swaync/`             | Notifications                               |
| `wofi`       | `~/.config/wofi/`               | Launcher                                    |
| `alacritty`  | `~/.config/alacritty/`          | Terminal (TOML, generated)                  |
| `gtk`        | `~/.config/gtk-{3,4}.0/`        | libadwaita palette                          |
| `scripts`    | `~/.local/bin/`                 | `apply-theme`, `set-wallpaper`, menus       |
| `systemd`    | `~/.config/systemd/user/`       | User services + timers                      |
| `sddm/themes/quickshell-pywal/` | `/usr/share/sddm/themes/` | Greeter (installed by `install.sh`) |

`ags/` is JS-based and being phased out in favour of Quickshell. `archive/`
holds inactive packages and is excluded from `STOW_DIRS`.

## Tests

```sh
sudo pacman -S shellcheck shfmt bats-core jq yq --noconfirm
bats test/                              # all tests
bats test/install.bats                  # one file
shellcheck scripts/.local/bin/apply-theme
shfmt -d -i 4 -ci scripts/.local/bin/apply-theme
```

## See also

- [`AGENTS.md`](AGENTS.md) — architecture notes, build/test commands, code-style
  rules for human and automated contributors.
- [LICENSE](LICENSE) — MIT.
