# Manatee Desktop Rebrand: Design Spec

**Date:** 2026-07-15
**Status:** Approved
**Personality:** Playful & warm: the manatee mascot leads. "Oh My Zsh" / "LazyVim" energy.

## 1. Naming & Repo

- GitHub repo: `Lunga93/dotfiles` → `Lunga93/manatee-desktop`
- Project name: **Manatee Desktop** (the thing you install)
- Internal name: **Manatee** (used in code, welcome app, etc.)
- Tagline (unchanged): *"A gentle, glossy Wayland desktop for Arch."*
- All internal references to "dotfiles" as a project name replaced with "Manatee" or "Manatee Desktop"
- AGENTS.md updated to reflect new repo name and project identity
- `STOW_DIRS` array and package structure: unchanged (niri, quickshell, etc.)

## 2. Visual Identity

- **Logo**: Existing `logo.svg` (manatee silhouette + bubbles): kept. `manatee-logo.jpg` kept for fastfetch.
- **Brand directory**: New `brand/` in repo root:
  - `logo.svg`: the manatee icon (copied from `welcome/.config/manatee-welcome/assets/logo.svg`)
  - `logo-full.svg`: manatee icon + "Manatee Desktop" wordmark (new)
  - `BRANDING.md`: style guide: accent `#0a84ff`, font Fira Sans, logo usage
- **Installer banner**: Render `logo.svg` via chafa (already a dependency), no ASCII approximation. Falls back cleanly if chafa unavailable.
- **Color identity**: No new hardcoded palette: pywal-driven theming is the point. `#0a84ff` only for static branded surfaces (README, brand guide, GitHub).

## 3. Install Script (`install.sh`)

- **Banner** (line 329): `"== lunga's dotfiles installer =="` → render logo via chafa + `"Manatee Desktop installer"`
- **Completion** (line 351): `"Installation complete"` → `"Manatee welcomes you. Log out and back in (or start niri) to join the pod."`
- Package arrays, stow logic, error handling: all unchanged.

## 4. README

Structure:
1. Logo + tagline + badges (Arch, Niri, license)
2. "Why Manatee?": 3 warm bullets
3. Quick start: clone, `./install.sh`, log out, log in
4. What's in the box: component overview with personality
5. Theming: pywal + wallpaper pipeline
6. Contributing: short, welcoming
7. "Join the pod" closer

## 5. SDDM Theme Rename

- `sddm/themes/quickshell-pywal/` → `sddm/themes/manatee/`
- `metadata.desktop`: `Name=Quickshell Pywal` → `Name=Manatee`, `Theme-Id=manatee`
- `theme.conf`: no content changes
- `install.sh` `install_sddm()`: `local name="quickshell-pywal"` → `local name="manatee"`
- `sddm/sddm.conf.d/10-theme.conf`: `Current=quickshell-pywal` → `Current=manatee`
- QML files, logic, pywal integration: all unchanged.

## 6. Fastfetch & Welcome App

- Both already branded. No changes needed.

## 7. Marker File

- `install.sh` writes `~/.config/manatee/desktop-marker` on completion
- Signal for scripts/tools to detect Manatee Desktop environment

## Implementation Checklist

- [ ] Rename SDDM theme directory: `quickshell-pywal` → `manatee`
- [ ] Update `metadata.desktop` (name, description, Theme-Id)
- [ ] Update `install.sh` `install_sddm()` name reference
- [ ] Update `sddm/sddm.conf.d/10-theme.conf` theme reference
- [ ] Update `install.sh` banner (chafa logo + "Manatee Desktop installer")
- [ ] Update `install.sh` completion message
- [ ] Add marker file creation to `install.sh`
- [ ] Create `brand/` directory with `logo.svg`, `logo-full.svg`, `BRANDING.md`
- [ ] Rewrite README with Manatee branding and warm tone
- [ ] Update AGENTS.md repo name references
- [ ] Rename GitHub repo (done manually by user on github.com)
- [ ] Grep for remaining "dotfiles" / "quickshell-pywal" references and fix
