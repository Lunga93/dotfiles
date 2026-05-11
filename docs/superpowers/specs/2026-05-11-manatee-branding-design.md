# Manatee Branding: Fastfetch + Default Wallpaper + Color Palette

## Overview

Brand identity for the Manatee Linux distro: fastfetch config with custom ASCII
manatee art, a "Deep Dive" branded default wallpaper, and a pywal-compatible
default color palette. All three live in the dotfiles repo and ship with
`install.sh`.

Reference: [Underwater manatee photo](https://upload.wikimedia.org/wikipedia/commons/d/d7/Underwater_photography_on_endangered_mammal_manatee.jpg)
— validates the oceanic scene, blue-green water, light rays, and the manatee's
gentle silhouette with whiskered snout and paddle tail.

## Deliverables

### 1. Fastfetch Config (`~/.config/fastfetch/config.jsonc`)

- Uses terminal image protocol (kitty/icat) to display the manatee reference
  image (`assets/brand/manatee.png`) directly in the terminal for maximum detail.
- Fastfetch `--logo-type image` or `--logo ~/.../manatee.png` or inline config.
- Below the image: system info lines (os, host, kernel, packages, shell, etc.)
  using the Manatee brand colors.
- Color bar at bottom showing the full brand palette.
- Stowed via `dotfiles/fastfetch/.config/fastfetch/config.jsonc`.
- Add `fastfetch` to `OFFICIAL_PACKAGES` in `install.sh`.
- Add `fastfetch` to `STOW_DIRS` in `install.sh`.

### 2. Default Wallpaper — "Deep Dive" (`assets/wallpapers/manatee-default.png`)

- Generated via Python PIL script (committed to `scripts/.local/bin/gen-default-wallpaper`).
- Scene: manatee silhouette swimming in deep ocean, light rays piercing from above,
  bubbles, serene underwater atmosphere inspired by the reference photo.
- Dark gradient background (deep navy → dark indigo → subtle teal).
- Manatee silhouette centered, with soft accent glow behind.
- Multicolor: deep blues (#0a2a4a), teals (#2ec4b6), accent glow (#0a84ff),
  light rays (#64d2ff), warm sand hint (#d4a373) for the sea floor.
- Serves as `DEFAULT_WALLPAPER` in `restore-wallpaper` (replaces `forest-train.gif`).
- Pre-generated and committed to `assets/wallpapers/manatee-default.png`.

### 3. Default Color Palette (`~/.cache/wal/colors.json`)

- Shipped as a static `colors.json` that lives in the repo at
  `quickshell/.config/quickshell/default-wal-colors.json`.
- On first boot (before pywal ever runs on a real wallpaper), the Theme.qml
  reads this file instead of falling back to hardcoded defaults.
- Palette derived from the "Deep Dive" wallpaper colors.

### 4. Update restore-wallpaper

The `restore-wallpaper` script's `DEFAULT_WALLPAPER` path changes from
`forest-train.gif` to `manatee-default.png`.

## Color Palette

```
background:  #0d1f2d  (deep navy)
foreground:  #f5f5f7  (white)
primary:     #0a84ff  (Manatee blue)
secondary:   #bf5af2  (purple)
accent:      #2ec4b6  (teal)
color0:      #0d1f2d
color1:      #ff453a  (red)
color2:      #0a84ff  (blue)
color3:      #ffd60a  (yellow)
color4:      #2ec4b6  (teal)
color5:      #bf5af2  (purple)
color6:      #64d2ff  (cyan)
color7:      #f5f5f7  (white)
```

## Implementation Plan

### Task 1: Fastfetch config + manatee ASCII art
- Create `fastfetch/.config/fastfetch/config.jsonc` in the dotfiles repo
- Hand-craft ASCII manatee art
- Add fastfetch to `install.sh` (packages + stow dirs)
- File: `scripts/.local/bin/gen-manatee-ascii` (optional — or inline)
- Tests: `fastfetch` runs without errors with the config

### Task 2: Default wallpaper + color palette
- Create `scripts/.local/bin/gen-default-wallpaper` (Python PIL)
- Generate `assets/wallpapers/manatee-default.png`
- Create `quickshell/.config/quickshell/default-wal-colors.json`
- Update `restore-wallpaper` default path
- Tests: wallpaper file exists, valid PNG

### Task 3: Review (wise senior)
- Code review of both tasks
- Verify manatee actually looks like a manatee
- Verify color palette is cohesive
- Sign off

## Implementation Tasks

### Task 1: Fastfetch config
- Create `fastfetch/.config/fastfetch/config.jsonc`
- Download reference image to `assets/brand/manatee-reference.jpg`
- Configure fastfetch to use image protocol with the manatee photo
- Add fastfetch to install.sh (packages + stow dirs)
- Update `restore-wallpaper` to use `manatee-default.png` as default
- Tests: `fastfetch` runs without errors, config parses

### Task 2: Default wallpaper + color palette
- Create `scripts/.local/bin/gen-default-wallpaper` (Python PIL)
- Generate `assets/wallpapers/manatee-default.png`
- Create `quickshell/.config/quickshell/default-wal-colors.json`
- Tests: wallpaper file exists, valid PNG, colors.json valid JSON

### Task 3: Review (wise senior)
- Code review of both tasks
- Verify visual quality
- Verify color palette is cohesive
- Sign off before merge
