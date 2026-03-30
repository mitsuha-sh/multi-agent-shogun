#!/usr/bin/env bash
# post_clear_recovery.sh — SessionStart hook: /clear後のタスク再開指示注入
# exit 0 = 正常終了（Claude Codeはstdout内容をadditionalContextとして注入する）

SCRIPT_DIR="${__SESSIONSTART_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# 1. AGENT_IDを読み取る
if [ -n "${__SESSIONSTART_AGENT_ID:-}" ]; then
  AGENT_ID="${__SESSIONSTART_AGENT_ID}"
else
  AGENT_ID=$(tmux display-message -t "$TMUX_PANE" -p '#{@agent_id}' 2>/dev/null)
fi

# AGENT_IDが空なら何もしない
if [ -z "$AGENT_ID" ]; then
  exit 0
fi

# 2. handoffを収集
HANDOFF_FILE="$SCRIPT_DIR/queue/handoff/${AGENT_ID}.md"
HANDOFF_CONTENT=""
if [ -f "$HANDOFF_FILE" ]; then
  HANDOFF_CONTENT=$(cat "$HANDOFF_FILE")
fi

# 3. タスクYAMLを確認
TASK_FILE="$SCRIPT_DIR/queue/tasks/${AGENT_ID}.yaml"

if [ ! -f "$TASK_FILE" ]; then
  if [ -n "$HANDOFF_CONTENT" ]; then
    printf '%s\n' "[SESSION_START] 前回handoff: queue/handoff/${AGENT_ID}.md"
    printf '%s\n' "$HANDOFF_CONTENT"
  fi
  exit 0
fi

# 4. statusとtask_idを読み取る（クォートを除去）
TASK_STATUS=$(grep -m1 'status:' "$TASK_FILE" | awk -F': ' '{val=$2; gsub(/[" \r]/, "", val); print val}')
TASK_ID=$(grep -m1 'task_id:' "$TASK_FILE" | awk -F': ' '{val=$2; gsub(/[" \r]/, "", val); print val}')

# 5. status判定して指示を出力
if [ "$TASK_STATUS" = "assigned" ] || [ "$TASK_STATUS" = "in_progress" ]; then
  echo "[SESSION_START] タスク再開: queue/tasks/${AGENT_ID}.yaml を読み、${TASK_ID}を実行せよ。"
else
  echo "[SESSION_START] 待機中: queue/inbox/${AGENT_ID}.yaml を確認し、未読メッセージがあれば処理せよ。なければ待機せよ。"
fi

if [ -n "$HANDOFF_CONTENT" ]; then
  printf '\n%s\n' "[SESSION_START] 前回handoff: queue/handoff/${AGENT_ID}.md"
  printf '%s\n' "$HANDOFF_CONTENT"
fi

exit 0
