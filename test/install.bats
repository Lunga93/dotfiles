#!/usr/bin/env bats

setup() {
    # Use BATS_TEST_DIRNAME to source helper reliably regardless of CWD
    source "$BATS_TEST_DIRNAME/helpers.bash"
    create_sandbox
}

teardown() {
    cleanup_sandbox
}

@test "install.sh runs and calls pacman, yay and stow" {
    run run_install_sh
    [ "$status" -eq 0 ]

    # Verify pacman was invoked (may be called via sudo)
    grep -q "pacman" "$SANDBOX_ROOT/calls.log"
    [ $? -eq 0 ]

    # Verify yay was invoked
    grep -q "yay" "$SANDBOX_ROOT/calls.log"
    [ $? -eq 0 ]

    # Verify stow was invoked for at least one package
    grep -q "stow" "$SANDBOX_ROOT/calls.log"
    [ $? -eq 0 ]
}

@test "install.sh backups existing configs before stowing" {
    run run_install_sh
    [ "$status" -eq 0 ]

    # The sandbox HOME should contain a backup created by the script
    [ -d "$SANDBOX_HOME/.config/waybar.bak" ]
}
