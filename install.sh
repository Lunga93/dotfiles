#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Dotfiles Installation...${NC}"

# 1. Check for Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}Error: This script is designed for Arch Linux (or derivatives like CachyOS).${NC}"
    exit 1
fi

# 2. Update System
echo -e "${GREEN}Updating system...${NC}"
sudo pacman -Syu --noconfirm

# 3. Install Official Repository Packages
echo -e "${GREEN}Installing official packages...${NC}"
OFFICIAL_PACKAGES=(
    "niri"
    "waybar"
    "mako"
    "wofi"
    "alacritty"
    "nautilus"
    "swaylock"
    "bluez"
    "bluez-utils"
    "gnome-calendar"
    "pipewire"
    "wireplumber"
    "playerctl"
    "polkit-kde-agent"
    "cliphist"
    "wl-clipboard"
    "ttf-fira-sans"
    "ttf-font-awesome"
    "ttf-roboto"
    "stow"
    "git"
    "base-devel"
    "python-pywal"
)

sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"

# 4. Install AUR Helper (yay) if missing
if ! command -v yay &> /dev/null; then
    echo -e "${BLUE}Installing yay (AUR helper)...${NC}"
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

# 5. Install AUR Packages
echo -e "${GREEN}Installing AUR packages...${NC}"
AUR_PACKAGES=(
    "overskride"          # Bluetooth client
    "swww"                # Wallpaper daemon
    "xwayland-satellite"  # XWayland manager for Niri
    "aylurs-gtk-shell"    # AGS
    "zen-browser-bin"     # Zen Browser
    "swaylock-effects-git" # Enhanced lock screen with blur
)

yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

# 6. Apply Dotfiles using Stow
echo -e "${GREEN}Stowing configurations...${NC}"
# Ensure we are in the dotfiles directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Directories to stow
STOW_DIRS=(
    "niri"
    "waybar"
    "mako"
    "wofi"
    "ags"
    "scripts"
)

# Handle potential conflicts by backing up existing configs
for dir in "${STOW_DIRS[@]}"; do
    TARGET_DIR="$HOME/.config/$dir"
    if [ -d "$TARGET_DIR" ] && [ ! -L "$TARGET_DIR" ]; then
        echo -e "${BLUE}Backing up existing $TARGET_DIR to $TARGET_DIR.bak${NC}"
        mv "$TARGET_DIR" "$TARGET_DIR.bak"
    fi
    
    echo "Stowing $dir..."
    stow -R "$dir"
done

# 7. Enable Services
echo -e "${GREEN}Enabling services...${NC}"
sudo systemctl enable --now bluetooth

# 8. Wallpaper Setup (Placeholder)
echo -e "${BLUE}Setting up wallpaper directory...${NC}"
mkdir -p ~/Pictures/wallpapers
# Note: config references forest-train.gif. User needs to provide this.

echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${BLUE}Please log out and log back in (or start niri) to see changes.${NC}"
echo -e "${BLUE}Note: Make sure to add 'forest-train.gif' to ~/Pictures/wallpapers/ or update ~/.config/niri/config.kdl${NC}"
