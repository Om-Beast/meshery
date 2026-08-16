#!/usr/bin/env bats

setup_file() {
    export INSTALL_SCRIPT="${BATS_FILE_TMPDIR}/install.sh"
    curl -fsSL --connect-timeout 10 --max-time 60 https://meshery.io/install -o "$INSTALL_SCRIPT"
}

teardown_file() {
    rm -f "$INSTALL_SCRIPT"
}

run_platform_prompt() {
    local input="$1"
    local harness="${BATS_TEST_TMPDIR}/platform-prompt.sh"

    # Keep the test focused on the interactive platform-selection logic. The
    # installer performs downloads and system changes after this block, so
    # stop before the common functions and replace the TTY input source with
    # stdin for deterministic test input.
    awk '/^####### COMMON FUNCTIONS/{exit} {print}' "$INSTALL_SCRIPT" \
        | sed 's#read PLATFORM < /dev/tty#read PLATFORM#g' \
        > "$harness"
    cat >> "$harness" <<'EOF'
printf 'SELECTED_PLATFORM=%s\n' "$PLATFORM"
EOF

    printf '%s' "$input" | bash "$harness"
}

@test "installer prompts for a platform and accepts docker" {
    run run_platform_prompt $'docker\n'

    assert_success
    assert_output --partial "Enter a platform to deploy Meshery"
    assert_output --partial "SELECTED_PLATFORM=docker"
}

@test "installer prompts again after an invalid platform and accepts kubernetes" {
    run run_platform_prompt $'invalid\nkubernetes\n'

    assert_success
    assert_output --partial "Invalid platform"
    assert_output --partial "SELECTED_PLATFORM=kubernetes"
}
