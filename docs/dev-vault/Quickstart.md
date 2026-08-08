# Quickstart

Clone, install, and make your first change in under 5 minutes.

## Clone & Install

```bash
git clone https://github.com/Lunga93/manatee-desktop ~/manatee-desktop
cd ~/manatee-desktop
./install.sh
```

The installer: verifies Arch, optionally runs `pacman -Syu`, installs packages, backs up existing configs to `*.bak`, and stows everything.

## First Boot

Log out, select Niri, log in. Then:

```bash
set-wallpaper ~/Pictures/wallpapers/your-image.jpg
```

This seeds the entire theming pipeline.

## Your First Change

Edit the clock format in Quickshell:

```bash
# 1. Find the clock
grep -rn "ClockSegment" quickshell/.config/quickshell/

# 2. Edit the time format
vim quickshell/.config/quickshell/ClockSegment.qml

# 3. Restart Quickshell
pkill qs && qs &

# 4. See your change
```

## Dev Commands

| Action | Command |
|--------|---------|
| Run tests | `bats test/` |
| Lint shell | `shellcheck path/to/script.sh` |
| Format shell | `shfmt -w -i 4 -ci path/to/script.sh` |
| Dry-run stow | `stow -n -v <package>` |
| Apply stow | `stow -R <package>` |

## Vault Map

- [[Home]]: start here
- [[Architecture]]: system overview
- [[Packages Reference]]: where things live
- [[Patterns & Standards]]: conventions
- [[Workflows]]: step-by-step guides
