# Manatee Desktop Rebrand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand the dotfiles project as "Manatee Desktop" — rename SDDM theme, update install script, rewrite README, create brand assets, and update all internal references.

**Architecture:** This is a pure rename/rebrand — no new logic. SDDM theme directory moves, metadata files get new names, install.sh gains branded banner messages, README is rewritten with warm/playful tone. Tests update path references in lockstep with the renames.

**Tech Stack:** Bash (install.sh), QML (SDDM theme), Markdown (README, docs), SVG (logo), GNU Stow (unchanged)

## Global Constraints

- All "quickshell-pywal" references in paths and test files → "manatee"
- All "dotfiles" project name references → "Manatee" or "Manatee Desktop"
- No logic changes — only names, paths, and text
- `sddm/themes/quickshell-pywal/` directory → `sddm/themes/manatee/` (full rename)
- Warm, playful tone in README and installer messages
- Installer banner renders logo.svg via chafa (chafa already in OFFICIAL_PACKAGES)

---

### Task 1: Rename SDDM theme directory and update internal files

**Files:**
- Rename: `sddm/themes/quickshell-pywal/` → `sddm/themes/manatee/` (entire directory)
- Modify: `sddm/themes/manatee/metadata.desktop`
- Modify: `sddm/themes/manatee/Main.qml:1-3`

**Interfaces:**
- Consumes: nothing (first task)
- Produces: `sddm/themes/manatee/` directory with updated metadata

- [ ] **Step 1: Rename the directory**

```bash
git mv sddm/themes/quickshell-pywal sddm/themes/manatee
```

- [ ] **Step 2: Update metadata.desktop**

Edit `sddm/themes/manatee/metadata.desktop`:

```
[SddmGreeterTheme]
Name=Manatee
Description=A gentle SDDM greeter that follows the pywal palette.
Author=lunga
License=MIT
Type=sddm-theme
Version=1.0
Website=
Screenshot=
MainScript=Main.qml
ConfigFile=theme.conf
TranslationsDirectory=
Theme-Id=manatee
Theme-API=2.0
QtVersion=6
```

- [ ] **Step 3: Update Main.qml comment**

Edit `sddm/themes/manatee/Main.qml` line 1:

```
// Entry point for the Manatee SDDM theme. Reads runtime colors and
```

- [ ] **Step 4: Commit**

```bash
git add sddm/themes/manatee/ sddm/themes/quickshell-pywal/
git commit -m "refactor(sddm): rename theme directory quickshell-pywal -> manatee"
```

---

### Task 2: Update sddm.conf.d theme reference

**Files:**
- Modify: `sddm/sddm.conf.d/10-theme.conf`

- [ ] **Step 1: Update the theme reference**

Edit `sddm/sddm.conf.d/10-theme.conf`:

```ini
[Theme]
Current=manatee
```

- [ ] **Step 2: Commit**

```bash
git add sddm/sddm.conf.d/10-theme.conf
git commit -m "refactor(sddm): update sddm.conf.d to use manatee theme"
```

---

### Task 3: Update install.sh (banner, completion, SDDM name, marker file)

**Files:**
- Modify: `install.sh` (lines 217, 329, 351, and add marker creation)

**Interfaces:**
- Consumes: `sddm/themes/manatee/` directory (from Task 1)
- Produces: branded install script with chafa banner, warm completion message, marker file creation

- [ ] **Step 1: Update SDDM theme name in install_sddm()**

Edit `install.sh` line 217:

```bash
    local name="manatee"
```

- [ ] **Step 2: Replace the installer banner**

Edit `install.sh` line 328-329. Replace:

```bash
    echo -e "${BLUE}== lunga's dotfiles installer ==${NC}"
```

With:

```bash
    if command -v chafa &>/dev/null && [[ -f "$SCRIPT_DIR/brand/logo.svg" ]]; then
        chafa --size 40x20 "$SCRIPT_DIR/brand/logo.svg" || true
    fi
    echo -e "${BLUE}Manatee Desktop installer${NC}"
    echo -e "${BLUE}A gentle, glossy Wayland desktop for Arch.${NC}"
```

- [ ] **Step 3: Replace the completion message**

Edit `install.sh` line 350-352. Replace:

```bash
    echo -e "${GREEN}== Installation complete ==${NC}"
    echo -e "${BLUE}Log out and back in (or start niri) to see changes.${NC}"
```

With:

```bash
    echo -e "${GREEN}Manatee welcomes you.${NC}"
    echo -e "${BLUE}Log out and back in (or start niri) to join the pod.${NC}"
```

- [ ] **Step 4: Add marker file creation**

Add after the completion message (before `main "$@"`):

```bash
    local marker_dir="$HOME/.config/manatee"
    run mkdir -p "$marker_dir"
    run touch "$marker_dir/desktop-marker"
    ok "Manatee desktop marker set"
```

- [ ] **Step 5: Run shellcheck on the modified script**

```bash
shellcheck install.sh
```

Expected: no errors

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "feat(install): add Manatee branding, chafa banner, marker file"
```

---

### Task 4: Update test files (sddm.bats)

**Files:**
- Modify: `test/sddm.bats`

**Interfaces:**
- Consumes: `sddm/themes/manatee/` directory (from Task 1), updated `install.sh` (from Task 3)
- Produces: tests that pass against the renamed theme

- [ ] **Step 1: Update all path references from quickshell-pywal to manatee**

Replace all occurrences of `quickshell-pywal` with `manatee` in `test/sddm.bats`. This affects lines 14-27 (theme dir file checks), lines 30-32 (sddm.conf.d check), lines 36-40 (theme.conf color keys), lines 44-45 (metadata.desktop checks), line 49 (qmldir check), line 56 (qmllint cd path), and line 75 (install.sh reference grep).

- [ ] **Step 2: Update test descriptions**

Line 30: `"sddm.conf.d/10-theme.conf exists and selects quickshell-pywal"` → `"sddm.conf.d/10-theme.conf exists and selects manatee"`

- [ ] **Step 3: Run the tests**

```bash
bats test/sddm.bats
```

Expected: all tests pass

- [ ] **Step 4: Commit**

```bash
git add test/sddm.bats
git commit -m "test(sddm): update theme references from quickshell-pywal to manatee"
```

---

### Task 5: Update script and doc references

**Files:**
- Modify: `scripts/.local/bin/sddm-greeter-debug` (line 38)
- Modify: `docs/dev-vault/Packages/SDDM.md` (lines 3, 7, 22)

- [ ] **Step 1: Update sddm-greeter-debug default theme fallback**

Edit `scripts/.local/bin/sddm-greeter-debug` line 38:

```bash
    [ -n "$cur" ] || cur="manatee"
```

- [ ] **Step 2: Update SDDM docs**

Edit `docs/dev-vault/Packages/SDDM.md`:

Line 3: `Quickshell-based SDDM login greeter.` → `Manatee SDDM login greeter.`

Line 7: `sddm/themes/quickshell-pywal/` → `/usr/share/sddm/themes/quickshell-pywal/` → replace both occurrences with `manatee`

Line 22: `sddm/themes/quickshell-pywal/` → `sddm/themes/manatee/`

- [ ] **Step 3: Commit**

```bash
git add scripts/.local/bin/sddm-greeter-debug docs/dev-vault/Packages/SDDM.md
git commit -m "docs: update SDDM references from quickshell-pywal to manatee"
```

---

### Task 6: Create brand/ directory with logo assets and style guide

**Files:**
- Create: `brand/logo.svg`
- Create: `brand/logo-full.svg`
- Create: `brand/BRANDING.md`

**Interfaces:**
- Consumes: `welcome/.config/manatee-welcome/assets/logo.svg` (existing asset)
- Produces: brand assets usable by README, installer, and external surfaces

- [ ] **Step 1: Copy logo.svg from welcome assets**

```bash
mkdir -p brand
cp welcome/.config/manatee-welcome/assets/logo.svg brand/logo.svg
```

- [ ] **Step 2: Create logo-full.svg (manatee icon + wordmark)**

Create `brand/logo-full.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 80" fill="none">
  <!-- Manatee icon (scaled) -->
  <g transform="translate(8, 8) scale(1)">
    <path d="M10 36c1-9 5-17 12-21 7-4 15-5 23-2 6 3 9 9 7 15 0 2 0 3 0 5 1 6 4 11 2 17 0 3-2 7-5 8-4 2-9 0-12-3-1-1-2-3-2-4 0-2 1-4 2-5 2-2 5-1 7 1 1 2 1 4 0 6-1 2-3 3-5 2-3 0-5-2-5-5 0-3 2-5 5-5 1 0 2 0 3 1" fill="currentColor"/>
    <circle cx="22" cy="32" r="1.6" fill="currentColor"/>
    <circle cx="34" cy="32" r="1.6" fill="currentColor"/>
    <path d="M26 38c1 1 2 2 4 2s3-1 4-2" stroke="currentColor" stroke-width="0.8" stroke-linecap="round" fill="none"/>
    <path d="M52 38l8-2-1 6-7-1z" fill="currentColor"/>
    <circle cx="46" cy="18" r="1.8" fill="currentColor" opacity="0.55"/>
    <circle cx="50" cy="14" r="1.2" fill="currentColor" opacity="0.40"/>
    <circle cx="44" cy="12" r="0.9" fill="currentColor" opacity="0.30"/>
  </g>
  <!-- Wordmark -->
  <text x="80" y="48" font-family="Fira Sans, sans-serif" font-size="22" font-weight="600" fill="currentColor">Manatee</text>
  <text x="80" y="68" font-family="Fira Sans, sans-serif" font-size="12" fill="currentColor" opacity="0.6">Desktop</text>
</svg>
```

- [ ] **Step 3: Create BRANDING.md**

Create `brand/BRANDING.md`:

```markdown
# Manatee Desktop Brand Guide

## Logo

The Manatee logo is a stylized manatee silhouette with bubbles — a friendly,
gentle sea cow. Use it wherever Manatee Desktop is represented.

- `logo.svg` — icon only (64x64 viewBox). Use for app icons, favicons, small spots.
- `logo-full.svg` — icon + "Manatee Desktop" wordmark (200x80 viewBox). Use for
  headers, README, project pages.

The logo uses `fill="currentColor"` — it inherits color from context. On light
backgrounds, prefer a dark color (#1c1c1e). On dark backgrounds, prefer light
(#f5f5f7) or the accent color.

## Colors

| Role     | Hex       | Usage |
|----------|-----------|-------|
| Accent   | `#0a84ff` | Buttons, links, focus rings in static branded surfaces |
| Dark BG  | `#1c1c1e` | Default background for static surfaces |
| Light FG | `#f5f5f7` | Text on dark static surfaces |

These are for static branded surfaces only (README, brand guide, GitHub).
The desktop itself uses pywal-generated palettes from your wallpaper.

## Typography

- Primary: **Fira Sans** — used in the welcome app and recommended for all
  Manatee-branded text.
- Monospace: **Fira Code** or system monospace — for code blocks and terminals.

## Voice

Warm, playful, and gentle — like a manatee. Technical accuracy without coldness.
Think "friendly companion" not "corporate product."
```

- [ ] **Step 4: Commit**

```bash
git add brand/
git commit -m "feat(brand): add logo assets and branding guide"
```

---

### Task 7: Rewrite README.md with Manatee branding

**Files:**
- Modify: `README.md` (full rewrite)

**Interfaces:**
- Consumes: `brand/logo-full.svg` (from Task 6), project structure knowledge
- Produces: warm, playful README that introduces Manatee Desktop

- [ ] **Step 1: Write the new README**

Create `README.md`:

```markdown
<p align="center">
  <img src="brand/logo-full.svg" alt="Manatee Desktop" width="320">
</p>

<p align="center">
  <strong>A gentle, glossy Wayland desktop for Arch.</strong><br>
  Built on Niri and Quickshell, themed by your wallpaper.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Arch-1793D1?logo=archlinux&logoColor=white" alt="Arch">
  <img src="https://img.shields.io/badge/compositor-Niri-8b5cf6" alt="Niri">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT">
</p>

---

## Why Manatee?

Manatees are gentle giants — calm, deliberate, and perfectly at home in their
environment. Your desktop should feel the same.

- **Gentle on your system** — Niri's scrollable tiling keeps everything flowing
  without the jank. One workspace scrolls into the next. No reshuffling, no
  surprises.
- **Glossy out of the box** — Quickshell bar, notification center, app launcher,
  lock screen, and SDDM greeter — all themed together. Looks good from the moment
  you log in.
- **Grows with your wallpaper** — pywal pulls a full palette from any image.
  Every surface — bar, notifications, terminal, GTK apps, even the login screen —
  follows along. Drop a new wallpaper, everything shifts to match.

## Quick Start

```bash
git clone https://github.com/Lunga93/manatee-desktop.git
cd manatee-desktop
./install.sh
```

Log out. Log back in with Niri. That's it — you're in the pod.

> **Arch-based distros only.** Tested on CachyOS. The installer checks
> `/etc/arch-release` and will bail politely if it's not there.

See `./install.sh --help` for dry-run and update options.

## What's in the box

| Component   | What it does                                      | Keybinding       |
|-------------|---------------------------------------------------|------------------|
| **Niri**    | Scrollable-tiling compositor. Workspaces scroll vertically, columns horizontally. | `Mod+Shift+H/L`  |
| **Quickshell** | Bar with workspaces, taskbar, tray, clock, power. Floating popouts for audio and calendar. | `Mod+,` for Settings |
| **Wofi**    | Fuzzy app launcher. Type to find.                 | `Mod+Space`      |
| **swaync**  | Notification daemon with slide-out control center. | `Mod+N`          |
| **Alacritty** | GPU-accelerated terminal.                      | `Mod+Return`     |
| **SDDM**    | Login greeter themed to match your desktop.       | —                |

Plus: fastfetch system info, daily wallpaper rotation, Bluetooth and audio
controls, clipboard history, and a first-run welcome wizard.

## Theming

Manatee is theme-native. Drop a wallpaper into `~/Pictures/wallpapers/` and
`apply-theme` regenerates every color surface:

```
wallpaper → pywal → colors.json
                        ├── Alacritty (terminal colors)
                        ├── swaync (notification colors)
                        ├── Wofi (launcher colors)
                        ├── GTK3/4 (app colors)
                        ├── Niri (focus rings)
                        ├── SDDM (login screen)
                        └── Quickshell (bar + popouts)
```

Use `Mod+Shift+W` to pick a new wallpaper and retheme instantly.

## Contributing

Found a rough edge? Have an idea? Open an issue or PR. Manatee is a personal
desktop that grew into something worth sharing — contributions that keep it
gentle and glossy are welcome.

## Join the pod

- **Repo:** [github.com/Lunga93/manatee-desktop](https://github.com/Lunga93/manatee-desktop)
- **Issues:** [open an issue](https://github.com/Lunga93/manatee-desktop/issues)

---

<p align="center">
  <sub>🐋 Manatee Desktop — gentle by nature, glossy by design.</sub>
</p>
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs(readme): rebrand as Manatee Desktop with warm, playful tone"
```

---

### Task 8: Update AGENTS.md

**Files:**
- Modify: `AGENTS.md` (lines referencing repo/project name)

- [ ] **Step 1: Update repo and project references**

In `AGENTS.md`, replace any references to the project as "dotfiles" or "this dotfiles repository" with "Manatee Desktop" where it refers to the project identity. The technical details about stow packages and config locations stay unchanged.

Key changes:
- Line ~3: "this dotfiles repository" → "this Manatee Desktop repository"
- Any reference to "dotfiles" as a project name → "Manatee" or "Manatee Desktop"
- Repo URL references → `github.com/Lunga93/manatee-desktop`

- [ ] **Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "docs(agents): update to Manatee Desktop project name"
```

---

### Task 9: Final grep cleanup and verification

**Files:**
- Any remaining files with stale references (discovered by grep)

- [ ] **Step 1: Grep for remaining quickshell-pywal references**

```bash
grep -r "quickshell-pywal" --include="*.sh" --include="*.md" --include="*.qml" --include="*.bats" --include="*.conf" --include="*.desktop" .
```

Expected: no output (all references updated)

- [ ] **Step 2: Grep for stale "dotfiles installer" / "lunga's dotfiles" references**

```bash
grep -r "lunga's dotfiles\|dotfiles installer" --include="*.sh" --include="*.md" .
```

Expected: no output outside of design docs (which are historical)

- [ ] **Step 3: Run the full test suite**

```bash
bats test/
```

Expected: all tests pass

- [ ] **Step 4: Run shellcheck on all modified scripts**

```bash
shellcheck install.sh scripts/.local/bin/sddm-greeter-debug
```

Expected: no errors

- [ ] **Step 5: Final commit**

```bash
git add -A
git diff --cached --stat
git commit -m "chore: final cleanup of remaining stale references"
```
