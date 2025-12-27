# Lunga's Dotfiles

Personal configuration files for a productive Wayland-based workflow on Arch Linux (CachyOS). This setup features the Niri compositor, aimed at a clean, keyboard-centric experience.

![Desktop Screenshot](./public/img.png)

## Core Components
* **OS:** Arch Linux (CachyOS)
* **Compositor:** Niri (Scrollable tiling window manager)
* **Status Bar:** Waybar
* **Launcher:** Wofi
* **Notifications:** Mako
* **Terminal:** Alacritty
* **Browser:** Zen Browser
* **File Manager:** Nautilus (GNOME Files)
* **Wallpaper Daemon:** swww

## Structure
This repository is managed using **GNU Stow**. Each top-level directory corresponds to a stow package.

* `niri/` - Main compositor configuration
* `waybar/` - Status bar styling and modules
* `wofi/` - Application launcher styling
* `mako/` - Notification daemon settings

## Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YOUR_USERNAME/dotfiles.git](https://github.com/YOUR_USERNAME/dotfiles.git) ~/dotfiles
   cd ~/dotfiles