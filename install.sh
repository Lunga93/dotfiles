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
    "swaync"
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
    "otf-font-awesome"
    "ttf-roboto"
    "stow"
    "git"
    "base-devel"
    "python-pywal"
    "curl"
    "jq"
    "quickshell"
    "pavucontrol"
    "ntfs-3g"
    "sddm"
    "qt6-svg"
    "qt6-declarative"
)

sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"

# 3b. Evict mako if present.
# Both mako and swaync ship D-Bus activation files for
# org.freedesktop.Notifications. If mako is installed it tends to win the
# race on boot, silently shadowing swaync and freezing notification colors
# at mako's hard-coded config. Mako is not in OFFICIAL_PACKAGES, but may
# be left over from a previous setup or pulled in as a dependency.
if pacman -Q mako &> /dev/null; then
    echo -e "${BLUE}Removing mako (conflicts with swaync for notifications)...${NC}"
    sudo pacman -Rns --noconfirm mako || true
fi
rm -rf "$HOME/.config/mako"

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
    "swaync"
    "wofi"
    "ags"
    "scripts"
    "alacritty"
    "quickshell"
    "gtk"
    "systemd"
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

# 6b. SDDM theme (quickshell-pywal)
# Theme dir lives under /usr/share (root-owned). Runtime overrides go to
# /var/lib/sddm-theme which is user-owned, so apply-theme writes colors and
# wallpaper without sudo. theme.conf.user inside the theme dir is a symlink
# into the runtime dir — SDDM merges it on top of theme.conf transparently.
echo -e "${GREEN}Installing SDDM theme (quickshell-pywal)...${NC}"
SDDM_THEME_NAME="quickshell-pywal"
SDDM_THEME_SRC="$SCRIPT_DIR/sddm/themes/$SDDM_THEME_NAME"
SDDM_THEME_DST="/usr/share/sddm/themes/$SDDM_THEME_NAME"
SDDM_RUNTIME_DIR="/var/lib/sddm-theme"

if [ ! -d "$SDDM_THEME_SRC" ]; then
    echo -e "${RED}SDDM theme source missing at $SDDM_THEME_SRC, skipping.${NC}"
else
    TARGET_USER="${USER:-$(whoami)}"
    TARGET_GROUP="$(id -gn "$TARGET_USER")"

    sudo install -d -m 755 -o "$TARGET_USER" -g "$TARGET_GROUP" "$SDDM_RUNTIME_DIR"

    if [ -d "$SDDM_THEME_DST" ]; then
        TS=$(date +%Y%m%d-%H%M%S)
        echo -e "${BLUE}Backing up existing theme to ${SDDM_THEME_DST}.bak.${TS}${NC}"
        sudo mv "$SDDM_THEME_DST" "${SDDM_THEME_DST}.bak.${TS}"
    fi
    sudo cp -r "$SDDM_THEME_SRC" "$SDDM_THEME_DST"

    sudo ln -sfT "$SDDM_RUNTIME_DIR/theme.conf.user" \
        "$SDDM_THEME_DST/theme.conf.user"

    if [ ! -f "$SDDM_RUNTIME_DIR/theme.conf.user" ]; then
        cat > "$SDDM_RUNTIME_DIR/theme.conf.user" <<CONF
[General]
background=#1c1c1e
foreground=#f5f5f7
accent=#0a84ff
viewBg=#26262a
wallpaperPath=$SDDM_RUNTIME_DIR/wallpaper
CONF
        chmod 644 "$SDDM_RUNTIME_DIR/theme.conf.user"
    fi

    if [ ! -f "$SDDM_RUNTIME_DIR/wallpaper" ] && \
       [ -f "$HOME/.config/current_wallpaper" ]; then
        CURR_WP=$(cat "$HOME/.config/current_wallpaper")
        if [ -f "$CURR_WP" ]; then
            cp -f "$CURR_WP" "$SDDM_RUNTIME_DIR/wallpaper"
            chmod 644 "$SDDM_RUNTIME_DIR/wallpaper"
        fi
    fi

    sudo install -d -m 755 /etc/sddm.conf.d
    sudo install -m 644 "$SCRIPT_DIR/sddm/sddm.conf.d/10-theme.conf" \
        /etc/sddm.conf.d/10-theme.conf

    echo -e "${GREEN}SDDM theme installed at $SDDM_THEME_DST${NC}"
    echo -e "${BLUE}Run 'apply-theme <wallpaper>' (via set-wallpaper) to refresh greeter colors.${NC}"
fi

# 7. Enable Services
echo -e "${GREEN}Enabling services...${NC}"
sudo systemctl enable --now bluetooth

# Reload user units so freshly stowed unit files are visible to systemd --user.
systemctl --user daemon-reload || true

# Enable user timers (the activation symlink under timers.target.wants/ is no
# longer tracked in the repo — it's created by `systemctl --user enable`).
if [ -f "$HOME/.config/systemd/user/daily-wallpaper.timer" ]; then
    echo -e "${GREEN}Enabling daily-wallpaper.timer...${NC}"
    systemctl --user enable --now daily-wallpaper.timer || \
        echo -e "${RED}Could not enable daily-wallpaper.timer (run manually after login).${NC}"
fi

# Enable swaync via its package-provided unit. We start it via systemd rather
# than niri's spawn-at-startup so D-Bus activation ordering is correct and
# Restart=on-failure handles crashes.
if systemctl --user list-unit-files swaync.service &> /dev/null; then
    echo -e "${GREEN}Enabling swaync.service...${NC}"
    systemctl --user enable --now swaync.service || \
        echo -e "${RED}Could not enable swaync.service (run manually after login).${NC}"
fi

# 8. Wallpaper Setup (Placeholder)
echo -e "${BLUE}Setting up wallpaper directory...${NC}"
mkdir -p ~/Pictures/wallpapers
# Note: config references forest-train.gif. User needs to provide this.

echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${BLUE}Please log out and log back in (or start niri) to see changes.${NC}"
echo -e "${BLUE}Note: Make sure to add 'forest-train.gif' to ~/Pictures/wallpapers/ or update ~/.config/niri/config.kdl${NC}"
