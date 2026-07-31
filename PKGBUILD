# Maintainer: Lunga <Lunga93 at github>
pkgname=manatee-desktop
pkgver=0.1.9
pkgrel=1
pkgdesc="A gentle, glossy Wayland desktop for Arch — Niri compositor, Quickshell bar, pywal theming"
arch=('any')
url="https://github.com/Lunga93/dotfiles"
license=('MIT')
depends=(
    'niri'
    'quickshell'
    'stow'
    'qt6-declarative'
    'qt6-svg'
)
optdepends=(
    'python-pywal: Theme engine — generates palettes from wallpapers'
    'python-pillow: Image processing for pywal'
    'swaync: Notification daemon with control center'
    'wofi: Application launcher'
    'alacritty: GPU-accelerated terminal'
    'papirus-icon-theme: Default icon theme'
    'sddm: Login manager — Manatee includes a custom SDDM theme'
    'swaylock: Lock screen'
    'swaylock-effects-git: Enhanced lock screen effects'
    'pipewire: Audio server'
    'wireplumber: PipeWire session manager'
    'networkmanager: Network management'
    'bluez: Bluetooth support'
    'bluez-utils: Bluetooth utilities'
    'cliphist: Clipboard history'
    'wl-clipboard: Wayland clipboard utilities'
    'playerctl: Media player control'
    'pavucontrol: Audio control panel'
    'polkit-kde-agent: Polkit authentication agent'
    'fastfetch: System info on terminal launch'
    'chafa: Image-to-terminal for fastfetch'
    'curl: HTTP client for wallpaper fetching'
    'jq: JSON processor for scripts'
    'wlsunset: Night light / blue light filter'
    'ttf-fira-sans: Bar + UI font'
    'ttf-roboto: Fallback font'
    'otf-font-awesome: Icon glyphs for bar'
    'ntfs-3g: NTFS drive support'
    'aylurs-gtk-shell: Legacy AGS shell (archived)'
    'overskride: Bluetooth device manager'
    'awww: Animated wallpaper daemon'
    'ttf-phosphor-icons: Phosphor icon font'
    'xwayland-satellite: XWayland rootful support'
    'zen-browser-bin: Zen browser'
    'gnome-calendar: Calendar application'
    'nautilus: File manager'
    'bats-core: Bash test framework'
    'shellcheck: Shell script linter'
    'shfmt: Shell script formatter'
    'opencode: AI coding agent'
)
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/Lunga93/dotfiles/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('SKIP')
install="${pkgname}.install"

package() {
    install -d -m755 "${pkgdir}/usr/share/${pkgname}"
    cp -r "${srcdir}/dotfiles-${pkgver}/"* "${pkgdir}/usr/share/${pkgname}/"
    find "${pkgdir}/usr/share/${pkgname}" -type f -exec chmod 644 {} \;
    find "${pkgdir}/usr/share/${pkgname}" -type d -exec chmod 755 {} \;
    chmod +x "${pkgdir}/usr/share/${pkgname}/install.sh"
    find "${pkgdir}/usr/share/${pkgname}/scripts/.local/bin" -type f -exec chmod +x {} \;
}
