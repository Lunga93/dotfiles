# Workflows

> [!TIP] Check the relevant [[Packages Reference|package note]] for file locations before starting.

## Add a Stow Package

```bash
mkdir -p your-pkg/.config/your-app
vim your-pkg/.config/your-app/config.file
# Add to STOW_DIRS in install.sh
stow -n -v your-pkg    # dry-run
stow -R your-pkg       # apply
# Update docs: Packages Reference.md + Packages/YourPackage.md
```

## Add a Bar Segment (Quickshell)

1. Create `YourSegment.qml` in `quickshell/.config/quickshell/`
2. Add to `Bar.qml` in the appropriate pill section
3. If it needs a popout, wire IPC: `qs.ipc.set("your", yourPopout)`
4. `pkill qs && qs &`
5. Toggle: `qs ipc call your toggle`
6. Update [[Packages/Quickshell]] docs

## Add a Utility Script

```bash
vim scripts/.local/bin/your-script
chmod +x scripts/.local/bin/your-script
shellcheck scripts/.local/bin/your-script
shfmt -w -i 4 -ci scripts/.local/bin/your-script
stow -R scripts
# Create test: bats test/your-script.bats
# Run tests: bats test/ && test-coverage --check
# Update docs: Packages/Scripts.md
```

Pick a pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Status (JSON to stdout) or Action (mutate state) or Menu (wofi)
case "${1:-}" in
    --action) do_thing;;
    *) echo "Usage: ..." >&2; exit 1;;
esac
```

## Testing Workflow

```mermaid
graph LR
    A[Write code] --> B[bats test/]
    B --> C{All pass?}
    C -->|No| A
    C -->|Yes| D[test-coverage]
    D --> E{Coverage ≥ 90%?}
    E -->|No| F[Add tests]
    F --> A
    E -->|Yes| G[test-coverage --check]
    G --> H{Baseline ok?}
    H -->|Regression| F
    H -->|Pass| I[Ready to commit]
```

### Daily development loop

```bash
# After any script change:
bats test/your-script.bats          # Fast: just your tests
test-coverage                       # Slow: full coverage run
```

### Pre-commit checklist

```bash
git add -p                          # Stage hunks intentionally, not -A
git diff --cached                   # Review exactly what will be committed
bats test/                          # All 140+ tests must pass
test-coverage --threshold 90        # Enforce coverage floor
test-coverage --check               # No baseline regressions
test-coverage --update-baseline     # If coverage improved
shellcheck scripts/.local/bin/*     # Lint all scripts
git diff --name-only | grep -q docs/dev-vault || echo "WARNING: no docs changes"
```

## PR Workflow

```mermaid
sequenceDiagram
    participant Dev
    participant Branch as feat/ branch
    participant Tests as bats + coverage
    participant Main as main

    Dev->>Branch: Create feature branch
    Dev->>Branch: Write code + tests
    Dev->>Tests: bats test/
    Tests-->>Dev: 140+ pass
    Dev->>Tests: test-coverage --check
    Tests-->>Dev: No regressions
    Dev->>Branch: Commit with type(scope): msg
    Dev->>Main: Open PR (git request-pull / gh pr create)
    Note over Main: Review coverage report
    Note over Main: Verify docs updated
    Main->>Main: Merge (fast-forward or rebase)
    Dev->>Main: Push to main
```

### Commit discipline

```bash
# Good commits
git commit -m "test(coverage): add test-coverage script with baseline support"
git commit -m "test(audio-menu): add 8 tests for menu routing"
git commit -m "test(apply-theme): add 17 tests covering all output stages"

# Bad commits
git commit -m "fixes"               # No type/scope
git commit -m "test: update tests"  # Too vague
git commit -m "WIP"                 # Not atomic
```

### Modern git features

```bash
# Parallel feature work with worktrees
git worktree add ../dotfiles-feature feat/new-feature

# Sparse checkout for monorepos (future)
git sparse-checkout init --cone
git sparse-checkout set scripts test

# Better merge with merge-ort (git 2.34+, default since 2.40)
git config --global pull.rebase true
git config --global merge.ort.ignoreCoworkerConflicts true

# Interactive rebase: clean up before PR
git rebase -i HEAD~5

# Bisect with test execution
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
git bisect run bats test/failing-test.bats
```

## Add a Systemd Timer

```ini
# service: systemd/.config/systemd/user/your-task.service
[Unit]
Description=Your task
[Service]
Type=oneshot
ExecStart=%h/.local/bin/your-script
Nice=10
```

```ini
# timer: systemd/.config/systemd/user/your-task.timer
[Unit]
Description=Your task timer
[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1800
[Install]
WantedBy=timers.target
```

```bash
ln -s ../your-task.timer systemd/.config/systemd/user/timers.target.wants/
stow -R systemd
systemctl --user daemon-reload
systemctl --user enable --now your-task.timer
# Update docs: Packages/Systemd.md
```

## Extend Theming Pipeline

Add a block to `apply-theme` that writes pywal colors to your component's config. Implement live reload if possible. Test with `set-wallpaper ~/test.jpg`.

## Troubleshooting

### No audio from TV

```bash
pactl list sinks short
pactl set-default-sink <tv-sink-name>
pactl move-sink-input <stream-id> <tv-sink-name>
```

Persist with `~/.config/wireplumber/wireplumber.conf.d/50-tv-default.conf` (sets NVIDIA card to `pro-audio` profile).

### Quickshell not starting

```bash
pkill qs && qs &
journalctl --user -u pipewire --since "5 min ago"
```

### Wallpaper not applying

```bash
test-theme
set-wallpaper ~/Pictures/wallpapers/your-image.jpg
```

## Audio Debug Flowchart

```mermaid
graph TD
    A[No sound?] --> B{pactl list sinks}
    B --> C{TV listed?}
    C -->|No| D[pro-audio profile]
    C -->|Yes| E{Default sink = TV?}
    E -->|No| F[pactl set-default-sink]
    E -->|Yes| G{Volume up?}
    G -->|No| H[pactl set-sink-volume 100%]
    G -->|Yes| I[Check cables + TV volume]
```
