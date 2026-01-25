Scripts package
===============

This package contains small user scripts intended to be stowed to
`~/.local/bin` so they are available on the user's PATH.

Included scripts
----------------
- `clipboard-manager` — presents clipboard history (cliphist) via wofi and
  copies the selection back to the clipboard (wl-copy).
- `apply-theme` — runs `pywal` on a given wallpaper and signals UI components
  (Waybar, Mako) to reload if possible.
- `set-wallpaper` — sets wallpaper with `swww` and applies the generated theme.
- `lock-screen` — wraps `swaylock-effects` or `swaylock` with preferred flags.

Installation
------------
1. Ensure `scripts` is included in the `STOW_DIRS` in `install.sh` (it is by
   default in this repository).
2. Run `stow -R scripts` from the repo root to symlink the scripts into
   `~/.local/bin`.

Notes
-----
- Scripts are defensive: they check for commands and exit gracefully if a
  dependency is missing. They are intentionally conservative and do not force
  installation of external packages.
