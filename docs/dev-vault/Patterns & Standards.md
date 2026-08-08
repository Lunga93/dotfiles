# Patterns & Standards

> [!WARNING] Update this when conventions change. [[#Docs-Update Discipline]] requires docs follow code.

## Shell Scripts

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- Indent: 4 spaces
- Line length: < 100 chars
- Quote all vars: `"$var"`
- `$(...)` over backticks
- `snake_case` functions, `UPPER_SNAKE_CASE` globals
- Errors to stderr: `echo "Error: ..." >&2`

### Three Patterns

**Status** : JSON to stdout:
```bash
echo '{"volume": 0.8, "mute": false}'
```

**Action** : mutate state, return exit code:
```bash
case "${1}" in
    --volume) wpctl set-volume @DEFAULT_SINK@ "${2}" ;;
esac
```

**Menu** : Wofi frontend:
```bash
choice=$(generate | wofi --dmenu)
[[ -n "$choice" ]] || exit 1
```

## QML (Quickshell / Welcome)

- 4-space indent
- Design tokens in `Theme.qml`, never hardcoded
- Palette in `Palette.qml` (gitignored)
- Popout IPC: `qs ipc call <target> toggle`

## KDL (Niri)

```kdl
binds {
    Mod+Space { spawn ["wofi", "--show", "drun"]; }
}
```

- 4-space indent
- Mod = Super key
- `spawn-at-startup` with list syntax

## Config Files

| Format | Indent | Validate with |
|--------|--------|--------------|
| JSON | 2 | `jq .` |
| JSONC | 2 | manual |
| TOML | 2 | no duplicates |
| CSS | 2 | manual |

## Theming Contract

Any themed component must:
1. Accept colors from pywal-generated file
2. Be rewriteable by `apply-theme`
3. Support live reload when possible

## Stow Contract

Every package must:
1. Mirror install path
2. Be in `STOW_DIRS` in `install.sh`
3. Pass `stow -n -v <pkg>`

## Git

- `type(package): description` : `feat`, `fix`, `chore`, `test`
- No secrets, no force-push
- Branch naming: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`
- Prefer `git rebase` over merge for feature branches
- Use `git worktree` for parallel feature work on the same repo

## Testing Standards

> [!IMPORTANT] **Minimum 90% code coverage** required on all new/changed scripts.
> See [[Testing Standards]] for full testing guide, mock architecture, and PR requirements.

### Quick reference

```bash
bats test/                           # Run all tests
test-coverage                        # Full coverage report
test-coverage --check                # Check against baseline
test-coverage --threshold 90         # Enforce minimum
test-coverage --update-baseline      # Save current as baseline
test-coverage --json                 # Machine-readable output
```

### Test design patterns

| Pattern | For | Example |
|---------|-----|---------|
| Status | JSON output scripts | `audio-status`, `bluetooth-status`, `network-status` |
| Action | Side-effect scripts | `audio-set`, `lock-screen` |
| Menu | Wofi routing scripts | `audio-menu`, `bluetooth-menu`, `wallpaper-menu` |
| Pipeline | Config generators | `apply-theme` |

## Comments

Default: none. Only comment WHY (not what), pre/post-conditions, or external context.

## Docs-Update Discipline

> [!DANGER] Every code change must update docs. See `AGENTS.md` section 11.

| Change | Update |
|--------|--------|
| Script | `Packages/Scripts.md` |
| Package config | `Packages/<Name>.md` |
| New package | `Packages Reference.md` + new |
| Data flow | `Architecture.md` |
| Convention | This file |
| Workflow | `Workflows.md` |

Verify: `git diff --name-only | grep -q docs/dev-vault`

## Package Conflict Resolution

When an official package conflicts with an AUR package, add it to `AUR_CONFLICTS` in `install.sh`:

```
    "official-pkg:aur-pkg"
```

The installer removes the conflicting AUR package before installing the official one. This follows the same pattern as `evict_mako` for `mako`/`swaync`.

## Backup Rule

Replace user files? Create backup first (`*.bak` or `.broken.<ts>`).
