#!/usr/bin/env bats

setup() {
    TEST_TMP="$(mktemp -d)"
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    mkdir -p "$TEST_TMP/queue/tasks" "$TEST_TMP/config/hooks"
    cp "$PROJECT_ROOT/config/hooks/post_clear_recovery.sh" "$TEST_TMP/config/hooks/post_clear_recovery.sh"
    chmod +x "$TEST_TMP/config/hooks/post_clear_recovery.sh"
}

teardown() {
    rm -rf "$TEST_TMP"
}

@test "post_clear_recovery.sh: assigned task emits resume instruction" {
    cat > "$TEST_TMP/queue/tasks/ashigaru1.yaml" <<'YAML'
task:
  task_id: subtask_999a
  status: assigned
YAML
    run env __SESSIONSTART_SCRIPT_DIR="$TEST_TMP" __SESSIONSTART_AGENT_ID="ashigaru1" \
        bash "$TEST_TMP/config/hooks/post_clear_recovery.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[SESSION_START] タスク再開"* ]]
    [[ "$output" == *"subtask_999a"* ]]
}

@test "post_clear_recovery.sh: idle task emits inbox wait instruction" {
    cat > "$TEST_TMP/queue/tasks/ashigaru1.yaml" <<'YAML'
task:
  task_id: subtask_999a
  status: idle
YAML
    run env __SESSIONSTART_SCRIPT_DIR="$TEST_TMP" __SESSIONSTART_AGENT_ID="ashigaru1" \
        bash "$TEST_TMP/config/hooks/post_clear_recovery.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[SESSION_START] 待機中"* ]]
    [[ "$output" == *"queue/inbox/ashigaru1.yaml"* ]]
}

@test "post_clear_recovery.sh: missing task file exits quietly" {
    run env __SESSIONSTART_SCRIPT_DIR="$TEST_TMP" __SESSIONSTART_AGENT_ID="ashigaru1" \
        bash "$TEST_TMP/config/hooks/post_clear_recovery.sh"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
