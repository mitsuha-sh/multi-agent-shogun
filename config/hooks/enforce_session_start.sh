#!/usr/bin/env bash
# enforce_session_start.sh — Session Start Step 1 強制実行チェック
# PreToolUse hookとして呼ばれる。exit 0=許可, exit 2=ブロック(blockモード時), exit 1=ノンブロッキング警告

# 1. config/settings.yaml から session_start_enforcement を読む
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENFORCEMENT=$(grep 'session_start_enforcement:' "$SCRIPT_DIR/config/settings.yaml" 2>/dev/null | awk '{print $2}')
ENFORCEMENT="${ENFORCEMENT:-warn}"

# 2. 完了フラグ確認: tmux変数 @session_started を読む
STARTED=$(tmux display-message -t "$TMUX_PANE" -p '#{@session_started}' 2>/dev/null)
AGENT_ID=$(tmux display-message -t "$TMUX_PANE" -p '#{@agent_id}' 2>/dev/null)

if [ "$STARTED" = "1" ]; then
  exit 0  # 明示フラグ済み → 許可
fi

if [ -n "$AGENT_ID" ]; then
  # @agent_id がセットされている = Step 1完了済みとみなす
  tmux set-option -p -t "$TMUX_PANE" @session_started 1 2>/dev/null
  exit 0
fi

# 3. 未完了の場合
MSG="[SESSION_START] Step 1未完了。まず: tmux display-message -t \"\$TMUX_PANE\" -p '#{@agent_id}' を実行して自分の役割を確認せよ。確認後: tmux set-option -p @session_started 1"

if [ "$ENFORCEMENT" = "block" ]; then
  echo "$MSG" >&2
  exit 2  # ブロック（exit 2 = PreToolUseをブロック。exit 1はノンブロッキング）
else
  echo "[WARN] $MSG" >&2
  exit 0  # 警告のみ
fi
