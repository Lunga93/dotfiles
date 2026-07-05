# Packages Reference

Every top-level directory in the repo (except `archive/`) is a GNU Stow package.

## Active Packages

| Package | Stow Target | Role |
|---------|------------|------|
| [[Packages/Niri|Niri]] | `~/.config/niri/` | Compositor |
| [[Packages/Quickshell|Quickshell]] | `~/.config/quickshell/` | Shell + bar |
| [[Packages/Swaync|Swaync]] | `~/.config/swaync/` | Notifications |
| [[Packages/Wofi|Wofi]] | `~/.config/wofi/` | Launcher |
| [[Packages/Alacritty|Alacritty]] | `~/.config/alacritty/` | Terminal |
| [[Packages/GTK|GTK]] | `~/.config/gtk-{3,4}.0/` | GTK theme |
| [[Packages/Scripts|Scripts]] | `~/.local/bin/` | System tools |
| [[Packages/Systemd|Systemd]] | `~/.config/systemd/user/` | Scheduling |
| [[Packages/SDDM|SDDM]] | `/usr/share/sddm/themes/` | Login screen |
| [[Packages/Fastfetch|Fastfetch]] | `~/.config/fastfetch/` | System info |
| [[Packages/Welcome|Welcome]] | `~/.config/manatee-welcome/` | First-run |

## Archived Packages

| Package | Location | Replaced By |
|---------|----------|-------------|
| [[Packages/AGS|AGS]] | `ags/` | Quickshell |
| [[Packages/Waybar|Waybar]] | `archive/waybar/` | Quickshell |

## How Stow Works

Each package mirrors the install path. `stow -R <pkg>` creates symlinks. Existing dirs backed up to `*.bak` by `install.sh`.

---

**Next:** Browse individual package notes below.
