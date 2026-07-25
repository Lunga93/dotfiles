#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly SCRIPT_DIR="$_script_dir"

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

DRY_RUN=false
DO_UPDATE=false

OFFICIAL_PACKAGES=(
    "alacritty"
    "base-devel"
    "bats-core"
    "kcov"
    "python-coverage"
    "bluez"
    "bluez-utils"
    "chafa"
    "cliphist"
    "curl"
    "fastfetch"
    "git"
    "gnome-calendar"
    "jq"
    "nautilus"
    "networkmanager"
    "niri"
    "ntfs-3g"
    "otf-font-awesome"
    "papirus-icon-theme"
    "pavucontrol"
    "pipewire"
    "playerctl"
    "polkit-kde-agent"
    "python"
    "python-pillow"
    "python-pywal"
    "qt6-declarative"
    "qt6-svg"
    "quickshell"
    "sddm"
    "shellcheck"
    "shfmt"
    "stow"
    "swaylock"
    "swaync"
    "ttf-fira-sans"
    "ttf-roboto"
    "wl-clipboard"
    "wlsunset"
    "wofi"
    "wireplumber"
    "opencode"
)

AUR_PACKAGES=(
    "aylurs-gtk-shell"
    "overskride"
    "swaylock-effects-git"
    "awww"
    "ttf-phosphor-icons"
    "xwayland-satellite"
    "zen-browser-bin"
)

STOW_DIRS=(
    "ags"
    "alacritty"
    "fastfetch"
    "gtk"
    "niri"
    "quickshell"
    "scripts"
    "swaync"
    "welcome"
    "systemd"
    "wofi"
    "opencode"
)

usage() {
    cat <<EOF
usage: install.sh [options]

Options:
  -n, --dry-run    Show what would be done without making changes
  -u, --update     Run pacman -Syu before installing packages
  -h, --help       Show this help and exit
EOF
    exit 0
}

info()  { echo -e "${BLUE}::${NC} $*"; }
ok()    { echo -e "${GREEN}OK${NC}  $*"; }
warn()  { echo -e "${YELLOW}!!${NC} $*"; }
die()   { echo -e "${RED}!!${NC} $*" >&2; exit 1; }

run() {
    if $DRY_RUN; then
        echo -e "${YELLOW}DRY${NC} $(IFS=' '; echo "$*")" >&2
        return 0
    fi
    "$@"
}

sudo_run() {
    if $DRY_RUN; then
        echo -e "${YELLOW}DRY${NC} sudo $(IFS=' '; echo "$*")" >&2
        return 0
    fi
    sudo "$@"
}

check_arch() {
    info "Checking system ..."
    if [[ ! -f /etc/arch-release ]]; then
        die "This installer is designed for Arch Linux (or derivatives like CachyOS)."
    fi
    ok "Arch Linux detected"
}

update_system() {
    if $DO_UPDATE; then
        info "Updating system (--update) ..."
        sudo_run pacman -Syu
        ok "System updated"
    else
        info "Skipping system update (pass --update to run pacman -Syu)"
    fi
}

install_official() {
    info "Checking for AUR-provided packages ..."
    local filtered=()
    for pkg in "${OFFICIAL_PACKAGES[@]}"; do
        local skip=false
        for aur in "${AUR_PACKAGES[@]}"; do
            if pacman -Q "$aur" &>/dev/null 2>&1; then
                if pacman -Qi "$aur" 2>/dev/null | grep -qE "^Provides[[:space:]]*:.*\b$pkg\b"; then
                    warn "$aur provides $pkg — skipping official $pkg"
                    skip=true
                    break
                fi
            fi
        done
        $skip || filtered+=("$pkg")
    done
    info "Installing official packages ..."
    sudo_run pacman -S --needed --overwrite '*' "${filtered[@]}"
    ok "Official packages installed"
}

ensure_aur_helper() {
    if command -v yay &>/dev/null; then
        ok "yay already installed"
        return 0
    fi
    info "Installing yay from AUR ..."
    run git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && run makepkg -si --noconfirm)
    run rm -rf /tmp/yay
    ok "yay installed"
}

install_aur() {
    info "Installing AUR packages ..."
    run yay -S --needed "${AUR_PACKAGES[@]}"
    ok "AUR packages installed"
}

evict_mako() {
    if pacman -Q mako &>/dev/null 2>&1; then
        info "Removing mako (conflicts with swaync for notifications) ..."
        sudo_run pacman -Rns --noconfirm mako 2>/dev/null || \
            warn "Could not remove mako (required by other packages)"
    fi
    run rm -rf "$HOME/.config/mako"
}

stow_all() {
    info "Stowing dotfiles ..."
    run cd "$SCRIPT_DIR"
    for dir in "${STOW_DIRS[@]}"; do
        local target="$HOME/.config/$dir"
        if [[ -d "$target" && ! -L "$target" ]]; then
            warn "Backing up $target -> $target.bak"
            run mv "$target" "$target.bak"
        fi
        if $DRY_RUN; then
            echo -e "${YELLOW}DRY${NC} stow -n -v $dir"
        else
            stow -R "$dir"
        fi
    done
    ok "Dotfiles stowed"
}

install_sddm() {
    local name="manatee"
    local src="$SCRIPT_DIR/sddm/themes/$name"
    local dst="/usr/share/sddm/themes/$name"
    local rundir="/var/lib/sddm-theme"

    if [[ ! -d "$src" ]]; then
        warn "SDDM theme source missing at $src, skipping"
        return 0
    fi

    info "Installing SDDM theme ($name) ..."
    local user="${USER:-$(whoami)}"
    local group
    group="$(id -gn "$user")"

    sudo_run install -d -m 755 -o "$user" -g "$group" "$rundir"

    if [[ -d "$dst" ]]; then
        local ts
        ts="$(date +%Y%m%d-%H%M%S)"
        warn "Backing up existing theme -> ${dst}.bak.${ts}"
        sudo_run mv "$dst" "${dst}.bak.${ts}"
    fi
    sudo_run cp -r "$src" "$dst"
    sudo_run ln -sfT "$rundir/theme.conf.user" "$dst/theme.conf.user"

    if [[ ! -f "$rundir/theme.conf.user" ]]; then
        cat > "$rundir/theme.conf.user" <<CONF
[General]
background=#1c1c1e
foreground=#f5f5f7
accent=#0a84ff
viewBg=#26262a
wallpaperPath=$rundir/wallpaper
CONF
        run chmod 644 "$rundir/theme.conf.user"
    fi

    if [[ ! -f "$rundir/wallpaper" && -f "$HOME/.config/current_wallpaper" ]]; then
        local curr
        curr="$(cat "$HOME/.config/current_wallpaper")"
        if [[ -f "$curr" ]]; then
            run cp -f "$curr" "$rundir/wallpaper"
            run chmod 644 "$rundir/wallpaper"
        fi
    fi

    sudo_run install -d -m 755 /etc/sddm.conf.d
    sudo_run install -m 644 "$SCRIPT_DIR/sddm/sddm.conf.d/10-theme.conf" \
        /etc/sddm.conf.d/10-theme.conf
    ok "SDDM theme installed"
}

enable_services() {
    info "Enabling services ..."
    sudo_run systemctl enable --now bluetooth
    run systemctl --user daemon-reload || true

    if [[ -f "$HOME/.config/systemd/user/daily-wallpaper.timer" ]]; then
        info "Enabling daily-wallpaper.timer ..."
        run systemctl --user enable --now daily-wallpaper.timer || \
            warn "Could not enable daily-wallpaper.timer (enable manually after login)"
    fi

    if systemctl --user list-unit-files swaync.service &>/dev/null; then
        info "Enabling swaync.service ..."
        run systemctl --user enable --now swaync.service || \
            warn "Could not enable swaync.service (enable manually after login)"
    fi

    if systemctl --user list-unit-files seed-wallpapers.timer &>/dev/null; then
        info "Enabling seed-wallpapers.timer ..."
        run systemctl --user enable --now seed-wallpapers.timer || \
            warn "Could not enable seed-wallpapers.timer"
    fi

    if systemctl --user list-unit-files wallpaper-cleanup.timer &>/dev/null; then
        info "Enabling wallpaper-cleanup.timer ..."
        run systemctl --user enable --now wallpaper-cleanup.timer || \
            warn "Could not enable wallpaper-cleanup.timer"
    fi

    info "Fetching first daily wallpaper ..."
    run systemctl --user start daily-wallpaper.service || \
        warn "Could not trigger initial wallpaper fetch"
    ok "Services enabled"
}

setup_wallpaper_dir() {
    info "Setting up wallpaper directory ..."
    run mkdir -p "$HOME/Pictures/wallpapers"

    local bundled="$SCRIPT_DIR/assets/wallpapers/manatee-deep-dive.png"
    if [[ -f "$bundled" ]]; then
        run cp "$bundled" "$HOME/Pictures/wallpapers/manatee-deep-dive.png"
        ok "Default manatee wallpaper installed"
    else
        warn "Bundled wallpaper not found at $bundled"
    fi
    ok "Wallpaper directory ready"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=true; shift ;;
            -u|--update)  DO_UPDATE=true; shift ;;
            -h|--help)    usage ;;
            *) die "Unknown option: $1 (try --help)" ;;
        esac
    done

    local logo="$SCRIPT_DIR/brand/logo.svg"
    if command -v chafa &>/dev/null && [[ -f "$logo" ]]; then
        chafa --size 40x20 "$logo" || true
    fi
    echo -e "${BLUE}Manatee Desktop installer${NC}"
    echo -e "${BLUE}A gentle, glossy Wayland desktop for Arch.${NC}"
    echo

    check_arch
    update_system
    install_official
    ensure_aur_helper
    install_aur
    evict_mako
    stow_all
    install_sddm
    enable_services
    setup_wallpaper_dir

    info "Seeding initial wallpaper library (~100 images) ..."
    if command -v seed-wallpapers >/dev/null 2>&1; then
        run seed-wallpapers --initial --quiet || \
            warn "Initial seed failed (will retry on next seed-day via timer)"
    fi

    echo
    echo -e "${GREEN}Manatee welcomes you.${NC}"
    echo -e "${BLUE}Log out and back in (or start niri) to join the pod.${NC}"

    local marker_dir="$HOME/.config/manatee"
    run mkdir -p "$marker_dir"
    run touch "$marker_dir/desktop-marker"
    ok "Manatee desktop marker set"
}

main "$@"
