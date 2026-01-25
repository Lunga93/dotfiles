#!/usr/bin/env bash
# Shared helpers for bats tests
set -euo pipefail

create_sandbox() {
    SANDBOX_ROOT=$(mktemp -d)
    export SANDBOX_ROOT
    export SANDBOX_HOME="$SANDBOX_ROOT/home"
    mkdir -p "$SANDBOX_HOME"
    mkdir -p "$SANDBOX_ROOT/bin"
    touch "$SANDBOX_ROOT/calls.log"

    # Create a fake config dir to test backup behavior
    mkdir -p "$SANDBOX_HOME/.config/waybar"

    # Create lightweight mocks for commands used by install.sh
    # Each mock writes its invocation to $SANDBOX_ROOT/calls.log and exits 0.
    for cmd in pacman yay stow makepkg sudo systemctl; do
        cat > "$SANDBOX_ROOT/bin/$cmd" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] $(basename "$0") $@" >> "$SANDBOX_ROOT/calls.log"
if [ "$(basename \"$0\")" = "sudo" ]; then
    # preserve the original command name, then remove it from args
    cmd="$1"
    shift || true
    if [ -n "${cmd:-}" ]; then
        echo "[MOCK-FORWARDED] $cmd $@" >> "$SANDBOX_ROOT/calls.log"
        if [ -x "$SANDBOX_ROOT/bin/$cmd" ]; then
            exec "$SANDBOX_ROOT/bin/$cmd" "$@"
        fi
    fi
    exit 0
fi
exit 0
EOF
        chmod +x "$SANDBOX_ROOT/bin/$cmd"
    done

    # Mock git clone to create /tmp/yay dir (safe) instead of contacting network
    cat > "$SANDBOX_ROOT/bin/git" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] git $@" >> "$SANDBOX_ROOT/calls.log"
if [ "$1" = "clone" ]; then
    dst="${@: -1}"
    mkdir -p "$dst"
    echo "fake-repo" > "$dst/README" || true
fi
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/git"

    # Ensure PATH and HOME are overridden for the test-run
    export PATH="$SANDBOX_ROOT/bin:$PATH"
    export HOME="$SANDBOX_HOME"

    # Provide higher-level mocks for desktop utilities used by scripts
    # cliphist: output sample clipboard entries
    cat > "$SANDBOX_ROOT/bin/cliphist" <<'EOF'
#!/usr/bin/env bash
echo "first snippet"
echo "second snippet"
echo "third snippet"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/cliphist"

    # wofi: read stdin, return a chosen line (env SANDBOX_WOFI_CHOICE overrides)
    cat > "$SANDBOX_ROOT/bin/wofi" <<'EOF'
#!/usr/bin/env bash
if [ -n "${SANDBOX_WOFI_CHOICE:-}" ]; then
    printf '%s' "$SANDBOX_WOFI_CHOICE"
    exit 0
fi
# by default output the first line from stdin
awk 'NR==1{print; exit}'
EOF
    chmod +x "$SANDBOX_ROOT/bin/wofi"

    # wl-copy: read stdin and log the copied content
    cat > "$SANDBOX_ROOT/bin/wl-copy" <<'EOF'
#!/usr/bin/env bash
content=$(cat -)
echo "[MOCK-WL-COPY] $content" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/wl-copy"

    # wal (pywal) mock — log the invocation
    cat > "$SANDBOX_ROOT/bin/wal" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] wal $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/wal"

    # swww mock — log the invocation
    cat > "$SANDBOX_ROOT/bin/swww" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] swww $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/swww"

    # swaylock-effects and swaylock mocks
    cat > "$SANDBOX_ROOT/bin/swaylock-effects" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] swaylock-effects $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/swaylock-effects"

    cat > "$SANDBOX_ROOT/bin/swaylock" <<'EOF'
#!/usr/bin/env bash
echo "[MOCK] swaylock $@" >> "$SANDBOX_ROOT/calls.log"
exit 0
EOF
    chmod +x "$SANDBOX_ROOT/bin/swaylock"

    # Provide a safe TMPDIR to avoid interfering with real /tmp state
    export TEST_TMPDIR="$SANDBOX_ROOT/tmp"
    mkdir -p "$TEST_TMPDIR"

    # Copy the repo into the sandbox so stow -n -v and stow -R solve relative paths
    # but we will mock stow so it's not necessary; still ensure safe cwd
    SANDBOX_REPO="$SANDBOX_ROOT/repo"
    mkdir -p "$SANDBOX_REPO"
    cp -a "$(pwd)"/* "$SANDBOX_REPO/" || true
    export SANDBOX_REPO
}

cleanup_sandbox() {
    if [ -n "${SANDBOX_ROOT:-}" ] && [ -d "$SANDBOX_ROOT" ]; then
        rm -rf "$SANDBOX_ROOT"
    fi
}

run_install_sh() {
    # Run the real install.sh but with PATH and HOME pointed to sandbox
    # Run from the repo root so the script's stow targets are available
    (cd "$SANDBOX_REPO" && bash ./install.sh)
}
