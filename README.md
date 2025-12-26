# 🌌 Lunga's Dotfiles

My personal configuration files for a productive Wayland-based workflow on **Arch Linux / CachyOS**, featuring the **Niri** compositor and **Zen Browser**.

## 🛠 Tech Stack
* **OS:** Arch Linux (CachyOS)
* **Compositor:** [Niri](https://github.com/YaLTeR/niri) (Scrollable tiling window manager)
* **Terminal:** Alacritty
* **Browser:** Zen Browser (AUR)
* **Lockscreen:** Swaylock
* **Idle Daemon:** Swayidle
* **Shell:** Zsh

## 📂 Structure
This repository uses **GNU Stow** to manage symbolic links.
- `niri/`: Configuration for the Niri compositor (`~/.config/niri/config.kdl`)
- `scripts/`: Custom scripts for power management and shortcuts.

## 🚀 Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YOUR_USERNAME/dotfiles.git](https://github.com/YOUR_USERNAME/dotfiles.git) ~/dotfiles
   cd ~/dotfiles
