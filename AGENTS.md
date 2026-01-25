AGENTS
======

This file gives automated/code-writing agents (and humans) a concise, opinionated set
of commands, conventions and expectations for working in this dotfiles repository.

If you are an agent operating in this repo, follow these rules: be conservative with
destructive actions (do not overwrite user's live config without backup), prefer
small, reviewable changes and always verify changes with a dry-run when possible.

1) Quick repository commands
----------------------------

- Install / apply dotfiles (interactive):

  ./install.sh

  - The repository ships an `install.sh` which:
    1) checks for Arch Linux, updates the system (`pacman -Syu`), installs a list
       of official packages, installs AUR packages via `yay`, and stows packages
       with `stow -R`.
    2) The script backs up existing config directories by moving them to
       `<target>.bak` before stowing.

- Dry-run stow (safe preview):

  cd ~/dotfiles
  stow -n -v <package>

  - `-n` = no-act/dry-run. Use this to preview what would be linked.

- Re-stow a single package:

  cd ~/dotfiles
  stow -R waybar

- Revert a stow symlink set (manual cleanup recommended):

  stow -D <package>

- Check installed packages (official):

  pacman -Q <package>

- Check installed AUR packages (yay):

  yay -Q <package>

- Enable and check system services used by the dotfiles (example):

  sudo systemctl enable --now bluetooth
  systemctl --user status <service>

2) Lint, format and test commands
---------------------------------

This repo contains shell scripts and configuration files (KDL, JSON, CSS,
alacritty YAML). Use the following tools to lint and validate files before
committing.

- Shell scripts (lint + format):

  - Install tools:

    sudo pacman -S shellcheck shfmt bats-core --noconfirm
    # Or use AUR helper for packages not in official repos

  - Lint a script with ShellCheck:

    shellcheck install.sh

  - Format a script with shfmt (opinionated):

    shfmt -w -i 4 -ci install.sh

- KDL / JSON / YAML

  - Validate JSON: `jq . path/to/file.json` (returns non-zero on parse errors)
  - Validate YAML (alacritty): `yq eval . -P path/to/file.yml` or `python -c ...`
  - No dedicated KDL linter included here — keep KDL files tidy and consistent.

- Waybar / Wofi / Mako configs

  - Manually validate by launching the app in a safe session or by running
    `waybar --config <path> --style <path>` where supported. Prefer a nested
    test user or a secondary seat to avoid disrupting your main session.

- Shell script unit tests:

  - This repository uses `bats-core` for shell script testing.
    Install: `sudo pacman -S bats-core` or `yay -S bats-core`.

  - Run all tests:

    bats test/

  - Run a single test file:

    bats test/install.bats

  - Run a single test by name (filter):

    bats --filter 'backs up existing configs' test/install.bats

  - Notes: The tests are located in `test/` and use a sandboxed environment with
    mocked commands to prevent system changes. See `test/helpers.bash` for details.

3) Repository scan findings relevant to agents
---------------------------------------------

- This repository contains:
  - `install.sh` — main installer script for Arch-based systems.
  - stow packages: `niri/`, `waybar/`, `wofi/`, `mako/`, `ags/`, `alacritty/`, `scripts/`, `systemd/`.
  - configuration files under each package (KDL, JSON, CSS, shell scripts).
  - A `bats-core` test suite in `test/` for `install.sh` and helper scripts.

- No `.cursor` or `.cursorrules` present; no `.github/copilot-instructions.md`.
  If these are added later, include them verbatim in this file.

4) Code style & conventions (shell scripts & configs)
-----------------------------------------------------

These are opinionated rules to make agent edits predictable and safe.

- Shebang and shell
  - Use `#!/usr/bin/env bash` or `#!/bin/bash` consistently at the top of
    executable scripts. This repo uses `#!/bin/bash` in `install.sh`.
  - Prefer POSIX-compatible constructs where possible but accept Bash-specific
    features when they simplify logic. Document non-POSIX usage clearly.

- Safety flags
  - At the start of non-interactive scripts use `set -euo pipefail` and
    `IFS=$'\n\t'` where appropriate. This reduces unexpected state on errors.

- Quoting and expansions
  - Always quote variable expansions unless deliberate: `"$var"`.
  - Use `$(...)` for command substitution, not backticks.

- Idempotency
  - Scripts should be idempotent: running `install.sh` multiple times should
    not irreversibly break a system. Back up existing files rather than
    overwriting without notice (the repo already moves existing folders to
    `<target>.bak`).

- Privilege escalation
  - Avoid running the whole script as root. Use `sudo` only for the specific
    commands that require elevated privileges (`pacman`, `systemctl`, etc.).

- Error messages and exit codes
  - Use descriptive messages with `echo` and return non-zero exit codes for
    fatal errors. For example: `echo "Error: This script is designed for Arch Linux" >&2`.

- Formatting
  - Indentation: 4 spaces for shell scripts and config snippets in this repo.
  - Line length: prefer < 100 characters where practical.

- Config files
  - KDL / JSON / YAML files: keep keys consistent (snake_case or kebab-case
    depending on the target application). Do not embed secrets – use placeholders
    and instruct the user to populate them in `README.md` or `install` prompts.

- Waybar/wofi/mako specifics
  - Module names: keep identifiers short and kebab-case (e.g., `battery-status`).
  - Theme assets (icons, wallpapers) must be referenced relatively from the
    stowed config and included in `public/` or documented in README.

5) Naming and organization
--------------------------

- Keep each stow package as a top-level directory matching the target
  configuration directory under `~/.config/` (e.g., `waybar/` -> `~/.config/waybar`).
- Files meant to be executable should have the executable bit set and contain
  a proper shebang.
- Keep small helper scripts under `ags/` or `scripts/` with clear README notes.

6) Commit / PR guidance for agents
----------------------------------

- Make small, focused commits; prefer atomic changes that are easy to review.
- Use commit message style: `fix(stow): avoid overwriting existing configs` or
  `chore(install): add swww to AUR package list`.
- Do not commit secrets or private keys. If a change requires a secret, add a
  placeholder and document how to provide it via environment variables or a
  local-only file ignored by git.

7) When you are blocked
-----------------------

- If a change affects the live system (systemd units, package lists, install
  flows) ask one targeted question and recommend a safe default. Describe the
  rollback steps and where backups will be stored.
- If lint or validation fails, run `shellcheck` or `shfmt` locally and include
  the exact error output in the issue or PR.

8) Helpful commands for agents
------------------------------

- Preview stow operations: `stow -n -v <package>`
- Lint a script: `shellcheck path/to/script.sh`
- Format a script: `shfmt -w -i 4 -ci path/to/script.sh`
- Run a single bats test: `bats --filter 'pattern' test/some_test.bats`
- Backup existing config before stowing: `mv ~/.config/waybar ~/.config/waybar.bak`

9) Cursor & Copilot rules
-------------------------

- There are no `.cursor` or `.cursorrules` files in this repository and no
  `.github/copilot-instructions.md` at the time this file was generated. If
  those files are introduced later, paste their contents here and honor them.

10) Safety rules for agents
---------------------------

- Never apply changes that replace or delete user files without creating a
  `.bak` backup or clearly documenting the action in the PR description.
- Avoid running `sudo pacman -Syu` or mass package installs on the user's
  behalf unless explicitly requested. Offer commands for the user to run.

Contact
-------

Open a draft PR for non-trivial changes and tag the repository owner for review.
When in doubt, prefer making a small, easily reversible change and add a note
explaining how to rollback.

-- End of AGENTS.md
