#!/usr/bin/env bats

setup() {
    TEST_TMP="$(mktemp -d)"
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    mkdir -p "$TEST_TMP/queue/tasks" "$TEST_TMP/queue/inbox" "$TEST_TMP/queue/handoff" "$TEST_TMP/config/hooks"
    cp "$PROJECT_ROOT/config/hooks/write_handoff.sh" "$TEST_TMP/config/hooks/write_handoff.sh"
    cp "$PROJECT_ROOT/config/hooks/post_clear_recovery.sh" "$TEST_TMP/config/hooks/post_clear_recovery.sh"
    chmod +x "$TEST_TMP/config/hooks/"*.sh
}

teardown() {
    rm -rf "$TEST_TMP"
}

@test "write_handoff.sh: task and shogun message are summarized into queue/handoff" {
    cat > "$TEST_TMP/queue/tasks/ashigaru1.yaml" <<'YAML'
task:
  task_id: subtask_638a
  status: assigned
  description: "Stop hook で handoff を自動保存する"
  output_path: reports/cmd_638_handoff.md
YAML
    cat > "$TEST_TMP/queue/inbox/ashigaru1.yaml" <<'YAML'
messages:
  - id: msg_1
    from: shogun
    type: task_assigned
    content: "handoff を実装せよ"
    read: true
YAML
    run env __HANDOFF_SCRIPT_DIR="$TEST_TMP" __HANDOFF_AGENT_ID="ashigaru1" \
        bash "$TEST_TMP/config/hooks/write_handoff.sh" <<'JSON'
{"last_assistant_message":"途中まで実装し、次は hook 配線を確認する。"}
JSON
    [ "$status" -eq 0 ]
    [ -f "$TEST_TMP/queue/handoff/ashigaru1.md" ]
    grep -q "## 議論中の論点" "$TEST_TMP/queue/handoff/ashigaru1.md"
    grep -q "subtask_638a: assigned" "$TEST_TMP/queue/handoff/ashigaru1.md"
    grep -q "handoff を実装せよ" "$TEST_TMP/queue/handoff/ashigaru1.md"
}

@test "post_clear_recovery.sh: handoff content is appended to SessionStart context" {
    cat > "$TEST_TMP/queue/tasks/ashigaru1.yaml" <<'YAML'
task:
  task_id: subtask_638a
  status: assigned
YAML
    cat > "$TEST_TMP/queue/handoff/ashigaru1.md" <<'MD'
# Session Handoff - ashigaru1
updated: 2026-03-24T12:40:00+09:00

## 議論中の論点
- handoff の読込確認
MD
    run env __SESSIONSTART_SCRIPT_DIR="$TEST_TMP" __SESSIONSTART_AGENT_ID="ashigaru1" \
        bash "$TEST_TMP/config/hooks/post_clear_recovery.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[SESSION_START] タスク再開"* ]]
    [[ "$output" == *"[SESSION_START] 前回handoff"* ]]
    [[ "$output" == *"handoff の読込確認"* ]]
}
