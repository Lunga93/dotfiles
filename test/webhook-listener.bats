#!/usr/bin/env bats

setup() {
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox

    cat > "$SANDBOX_ROOT/bin/opencode" <<'OPENCODE_EOF'
#!/usr/bin/env bash
echo "[MOCK] opencode $*" >> "$SANDBOX_ROOT/calls.log"
echo "Starting analysis..."
echo "Found issue in config"
echo "Applying fix..."
echo "Task completed successfully"
exit ${SANDBOX_OPENCODE_EXIT:-0}
OPENCODE_EOF
    chmod +x "$SANDBOX_ROOT/bin/opencode"
    export SANDBOX_OPENCODE_EXIT=0

    mkdir -p "$SANDBOX_HOME"
    ln -sf "$SANDBOX_REPO" "$SANDBOX_HOME/dotfiles" 2>/dev/null || true

    WEBHOOK="$SANDBOX_REPO/scripts/.local/bin/webhook-listener"
    SANDBOX_TASK_DIR="$SANDBOX_HOME/.local/state/niri-heal/tasks"
    SANDBOX_HEAL_LOG="$SANDBOX_HOME/.local/state/niri-heal/heal.log"

    cat > "$SANDBOX_ROOT/run_streaming.py" <<PYEOF
import sys, os
os.environ['HOME'] = os.environ.get('SANDBOX_HOME', os.environ['HOME'])
sys.path.insert(0, os.path.join(os.environ['SANDBOX_REPO'], 'scripts/.local/bin'))

import importlib.machinery, importlib.util
from pathlib import Path

_webhook_path = os.path.join(
    os.environ['SANDBOX_REPO'], 'scripts/.local/bin/webhook-listener'
)
loader = importlib.machinery.SourceFileLoader('webhook_listener', _webhook_path)
spec = importlib.util.spec_from_loader('webhook_listener', loader, origin=_webhook_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

mod.TASK_DIR = Path(os.environ['SANDBOX_TASK_DIR'])
mod.TASK_DIR.mkdir(parents=True, exist_ok=True)

label = sys.argv[1]
log_path = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None
rc = mod._run_opencode_streaming('test prompt', label, log_path)
print(f'RC:{rc}')
PYEOF

    export WEBHOOK SANDBOX_TASK_DIR SANDBOX_HEAL_LOG
}

teardown() {
    cleanup_sandbox
}

@test "streaming log: creates log file with header on success" {
    local log="$SANDBOX_TASK_DIR/success.log"
    mkdir -p "$(dirname "$log")"
    SANDBOX_OPENCODE_EXIT=0 run python3 "$SANDBOX_ROOT/run_streaming.py" "success-test" "$log"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "RC:0" ]]
    [ -f "$log" ]
    grep -q "# Task: success-test" "$log"
    grep -q "# Started:" "$log"
    grep -q "# Log: tail -f" "$log"
}

@test "streaming log: captures opencode stdout in log file" {
    local log="$SANDBOX_TASK_DIR/capture.log"
    mkdir -p "$(dirname "$log")"
    SANDBOX_OPENCODE_EXIT=0 run python3 "$SANDBOX_ROOT/run_streaming.py" "capture-test" "$log"
    [ "$status" -eq 0 ]
    grep -q "Starting analysis..." "$log"
    grep -q "Found issue in config" "$log"
    grep -q "Applying fix..." "$log"
    grep -q "Task completed successfully" "$log"
}

@test "streaming log: records exit code on success" {
    local log="$SANDBOX_TASK_DIR/exit-ok.log"
    mkdir -p "$(dirname "$log")"
    SANDBOX_OPENCODE_EXIT=0 run python3 "$SANDBOX_ROOT/run_streaming.py" "exit-ok-test" "$log"
    [ "$status" -eq 0 ]
    grep -q "# Exit code: 0" "$log"
    grep -q "# Finished:" "$log"
}

@test "streaming log: records non-zero exit code on failure" {
    local log="$SANDBOX_TASK_DIR/exit-fail.log"
    mkdir -p "$(dirname "$log")"
    SANDBOX_OPENCODE_EXIT=1 run python3 "$SANDBOX_ROOT/run_streaming.py" "exit-fail-test" "$log"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "RC:1" ]]
    grep -q "# Exit code: 1" "$log"
    grep -q "# Finished:" "$log"
}

@test "streaming log: auto-generates log path from label" {
    mkdir -p "$SANDBOX_TASK_DIR"
    SANDBOX_OPENCODE_EXIT=0 run python3 "$SANDBOX_ROOT/run_streaming.py" "auto-label" ""
    [ "$status" -eq 0 ]
    [[ "$output" =~ "RC:0" ]]
    local generated
    generated=$(find "$SANDBOX_TASK_DIR" -name "*-auto-label.log" 2>/dev/null | head -1)
    [ -n "$generated" ]
    [ -f "$generated" ]
    grep -q "# Task: auto-label" "$generated"
}

@test "streaming log: writes TASK_LOG entry to heal log" {
    local log="$SANDBOX_TASK_DIR/heal-entry.log"
    mkdir -p "$(dirname "$log")"
    SANDBOX_OPENCODE_EXIT=0 run python3 "$SANDBOX_ROOT/run_streaming.py" "heal-entry-test" "$log"
    [ "$status" -eq 0 ]
    [ -f "$SANDBOX_HEAL_LOG" ]
    grep -q "TASK_LOG" "$SANDBOX_HEAL_LOG"
    grep -q "$(basename "$log")" "$SANDBOX_HEAL_LOG"
}
