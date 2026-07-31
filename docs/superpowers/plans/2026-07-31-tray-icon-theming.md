# Tray Icon Theming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tint every system-tray icon with theme colors — `Theme.textPrimary` idle, `Theme.accent` on hover — using a `MultiEffect.colorization` layer, so the tray cluster stops showing app-supplied brand/grayscale artwork.

**Architecture:** One QML file (`TraySegment.qml`) + `import QtQuick.Effects`. Tray delegates get a `tint` property bound to the existing `mouse` area state, applied to the `IconImage` via `layer.effect: MultiEffect { colorization: 1.0 }`. The `nm-applet` filter, sizing, and click handling are untouched. Docs update in `docs/dev-vault/Packages/Quickshell.md` (bar-segment table + a tray-theming note). No bash/coverage surface — verification is `qmllint`/`qmlformat` + manual bar reload.

**Tech Stack:** Quickshell (Qt 6.11 / QML), stow, `reload-desktop`

---

### Task 1: Implement MultiEffect tinting in TraySegment.qml

**Files:**
- Modify: `quickshell/.config/quickshell/TraySegment.qml`

- [ ] **Step 1: Add `import QtQuick.Effects`**

Add `import QtQuick.Effects` to the import block (after `Quickshell.Widgets`).

- [ ] **Step 2: Add the `tint` property + transition to the delegate**

On the delegate `Item` (the one with `required property SystemTrayItem modelData`), add:

```qml
property color tint: (mouse.containsMouse || mouse.pressed)
    ? Theme.accent : Theme.textPrimary
Behavior on tint { ColorAnimation { duration: Theme.durationFast } }
```

- [ ] **Step 3: Apply the layer effect to the IconImage**

Give the `IconImage` an `id` (`trayIcon`) and add:

```qml
layer.enabled: true
layer.effect: MultiEffect {
    colorization: 1.0
    colorizationColor: item.tint
}
```

- [ ] **Step 4: Verify with qmllint / qmlformat**

```bash
qmllint -I /usr/lib/qt6/qml quickshell/.config/quickshell/TraySegment.qml
qmlformat quickshell/.config/quickshell/TraySegment.qml >/dev/null
```

Expected: qmllint reports no errors (pre-existing warnings on other files, if any, are out of scope); qmlformat produces no meaningful diff.

- [ ] **Step 5: Commit**

```bash
git add quickshell/.config/quickshell/TraySegment.qml
git commit -m "feat(quickshell): tint tray icons with theme colors via MultiEffect

Tray icons previously rendered SystemTrayItem.icon as raw app artwork
(brand colors, arbitrary grays) that ignored the pywal palette. Colorize
the IconImage with a MultiEffect layer: Theme.textPrimary idle,
Theme.accent on hover/pressed, animated at Theme.durationFast.

Filtering, sizing, and click handling are unchanged."
```

---

### Task 2: Update Quickshell docs

**Files:**
- Modify: `docs/dev-vault/Packages/Quickshell.md`

- [ ] **Step 1: Update the bar-segment table row for TraySegment**

In the "Bar Segments" table (line ~67), change `TraySegment.qml`'s Purpose to mention the theme tint:

```
| `TraySegment.qml` | `Quickshell.Services.SystemTray` | System tray icons, colorized to the theme (filters `nm-applet`) |
```

- [ ] **Step 2: Add a themed-icons note**

In the "Integration Points" section (after the `> [!FAQ]` block, before "IPC Protocol"), add a callout explaining the two icon languages:

```
> [!TIP] **Tray icons are app art, not theme glyphs.** The tray renders
> `SystemTrayItem.icon` through a `MultiEffect` colorization layer
> (`Theme.textPrimary` idle, `Theme.accent` on hover) so app-supplied
> brand/grayscale artwork follows the palette. Bar segments (volume,
> clipboard, bluetooth, power) use Nerd Font PUA glyphs via `Theme.fontMono`.
> If a tray icon looks untinted, the `layer.effect` fell off — re-check the
> `IconImage` in `TraySegment.qml`.
```

- [ ] **Step 3: Commit**

```bash
git add docs/dev-vault/Packages/Quickshell.md
git commit -m "docs(quickshell): document tray icon theming in TraySegment"
```

---

### Task 3: Manual verification on the live bar

**Files:** none (runtime check)

- [ ] **Step 1: Reload the bar**

```bash
reload-desktop
```

- [ ] **Step 2: Visually confirm**

- Idle: all tray icons render in the theme foreground (no green Spotify, no stray grays).
- Hover: icon color animates to `Theme.accent`, reverts on leave; hover background pill unchanged.
- Click: left-click activates, right-click still opens the platform menu; `nm-applet` still filtered out.

If anything regressed, restart the task 1 fix and re-review.

- [ ] **Step 3: Close out the review**

```bash
git log --oneline -5
```
