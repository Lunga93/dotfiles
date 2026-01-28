AGENTS
======

Purpose
-------

Guidance and rules for automated coding agents (and humans) contributing to
this dotfiles repository. Be conservative with destructive actions, make small
reviewable changes, and prefer dry-runs and backups.

1) Quick repository commands
----------------------------

- Apply dotfiles (interactive): `./install.sh` — installer checks Arch Linux,
  optionally updates the system, installs packages, and stows package dirs.
- Dry-run stow (preview): `stow -n -v <package>` — always run before stowing.
- Re-stow a package: `stow -R <package>`
- Revert stow links: `stow -D <package>` (manual cleanup may be needed)
- Check installed packages: `pacman -Q <package>`
- Check AUR packages (yay): `yay -Q <package>`
- Enable/check services: `sudo systemctl enable --now <service>` and
  `systemctl --user status <service>`

2) Build / Lint / Test commands
------------------------------

- Install recommended tooling (Arch):
  `sudo pacman -S shellcheck shfmt bats-core jq yq --noconfirm` (or `yay`)
- Shell lint: `shellcheck path/to/script.sh`
- Shell format: `shfmt -w -i 4 -ci path/to/script.sh`
- JSON validation: `jq . path/to/file.json`
- YAML validation: `yq eval . -P path/to/file.yml`

Tests (bats-core)
- Run all tests: `bats test/`
- Run a single test file: `bats test/install.bats`
- Run a single test by name: `bats --filter 'test name substring' test/install.bats`
- Run an individual test (filename+filter) for targeted feedback.

Alacritty validation helper
- Script: `scripts/.local/bin/test-alacritty.sh` — runs Alacritty briefly,
  detects `duplicate key` TOML errors and restores the trusted template while
  backing up broken files to `~/.config/alacritty/alacritty.toml.broken.<ts>`.

3) Repository scan highlights
----------------------------

- Top-level packages: `niri/`, `waybar/`, `wofi/`, `mako/`, `ags/`, `alacritty/`,
  `scripts/`, `systemd/` — each maps to a stow package targeting `~/.config`.
- Main installer: `install.sh`.
- Tests: `test/` (bats-core)
- No `.cursor` / `.cursorrules` or `.github/copilot-instructions.md` detected
  in the current tree. If added later, include their contents verbatim below.

4) Code style & conventions (shell scripts & configs)
----------------------------------------------------

Shebangs & interpreter
- Use `#!/usr/bin/env bash` or `#!/bin/bash` at the top of executables.
- Prefer POSIX-compatible constructs where feasible; document non-POSIX usage.

Safety flags
- Non-interactive scripts should start with:
  `set -euo pipefail` and `IFS=$'\n\t'` to reduce surprising failures.

Quoting & expansions
- Always quote expansions: `"$var"` unless deliberately unquoted.
- Use `$(...)` for command substitution.

Formatting
- Use `shfmt -w -i 4 -ci` for shell files; keep line length < 100 chars.
- Indent with 4 spaces (consistent across scripts/config snippets).

Naming conventions
- Variables: `snake_case` for config keys and shell variables used across
  scripts; `UPPER_SNAKE_CASE` for constants and exported env vars.
- Functions: `verb_description` or `verbNoun` (e.g., `install_package`,
  `backup_config`). Keep names short and descriptive.
- Files / directories: stow package names map directly to `~/.config/<name>`.

Imports / ordering (in scripts)
- Group responsibilities top-to-bottom: constants/config, helper functions,
  argument parsing, core logic, main entrypoint.
- Check for required external tools early and fail-fast with helpful error.

Types & data
- Shell is untyped; prefer explicit validation and clear variable names.
- When parsing numbers, validate with regex before arithmetic.

Error handling
- Return non-zero on fatal errors; print helpful context to stderr
  (`echo "Error: <message>" >&2`).
- Use `trap 'cleanup_function' EXIT` to restore state or remove temp files.
- Avoid silent failures; prefer failing fast with recovery instructions.

Idempotency & backups
- Do not overwrite user files without creating a `.bak` (e.g.,
  `mv ~/.config/foo ~/.config/foo.bak`).
- Scripts should be safe to re-run; detect existing state and skip or backup.

Privilege escalation
- Use `sudo` only for commands that require it. Do not run whole scripts as root.

Config styles
- KDL / JSON / YAML: keep key styles consistent (snake_case or kebab-case
  per app conventions). Use `jq` / `yq` to validate before committing.

5) Git & commit guidance for agents
----------------------------------

- Make small, focused commits. Message style examples:
  `fix(stow): avoid overwriting configs`
  `chore(install): add swww to AUR package list`
- NEVER commit secrets. Use placeholders and document how to supply secrets
  via env vars or git-ignored local files.
- Don't amend or rewrite public history unless the user explicitly requests it.

6) When blocked
---------------

- If a change affects live system services or package lists, ask one focused
  question and present a safe default. Describe rollback steps and backup paths.
- If lint/validation fails, include the exact `shellcheck` / `shfmt` output.

7) Cursor & Copilot rules
-------------------------

- No `.cursor` / `.cursorrules` or `.github/copilot-instructions.md` files were
  found in the repository during this analysis. If those files are added later,
  paste their contents here and follow them verbatim.

8) Safety rules for agents
--------------------------

- Never replace or delete user files without creating a `.bak` backup or
  documenting the action in the PR description.
- Avoid running `sudo pacman -Syu` or bulk installs on the user's behalf;
  instead provide commands for the user to execute locally.

Contact
-------

Open a draft PR for non-trivial changes and tag the repository owner for
review. Prefer small, reversible changes and include verification steps.
