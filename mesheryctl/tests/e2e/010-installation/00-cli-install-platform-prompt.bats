#!/usr/bin/env bats

setup_file() {
  export INSTALL_SCRIPT="${BATS_FILE_TMPDIR}/meshery-install.sh"
  curl -fsSL --connect-timeout 10 --max-time 60 https://meshery.io/install -o "$INSTALL_SCRIPT"
}

teardown_file() {
  rm -f "$INSTALL_SCRIPT"
}

run_platform_prompt() {
  local input="$1"
  local harness="${BATS_TEST_TMPDIR}/platform-prompt.sh"

  # Exercise only the installer's interactive platform-selection contract.
  # Stop before the common functions so no installation side effects occur.
  # Replace the TTY read with stdin so the prompt is deterministic in CI.
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

@test "installer rejects an invalid platform and accepts the next valid selection" {
  run run_platform_prompt $'invalid\nkubernetes\n'

  assert_success
  assert_output --partial "Invalid platform"
  assert_output --partial "SELECTED_PLATFORM=kubernetes"
}
