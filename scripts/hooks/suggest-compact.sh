#!/usr/bin/env bash
# suggest-compact.sh — Strategic Compact for Shogun System
# 家老・軍師のPreToolUse(Edit|Write)で発火し、/compact を提案する

# エージェント判定
AGENT_ID=$(tmux display-message -t "$TMUX_PANE" -p '#{@agent_id}' 2>/dev/null || echo "")
case "$AGENT_ID" in
    karo|gunshi) ;; # 対象
    *) exit 0 ;;    # それ以外はスキップ
esac

# カウンターファイル
SESSION_ID="${CLAUDE_SESSION_ID:-${PPID:-default}}"
COUNTER_FILE="/tmp/shogun-compact-count-${SESSION_ID}"
THRESHOLD=${COMPACT_THRESHOLD:-50}

if [ -f "$COUNTER_FILE" ]; then
    count=$(cat "$COUNTER_FILE")
    count=$((count + 1))
    echo "$count" > "$COUNTER_FILE"
else
    echo "1" > "$COUNTER_FILE"
    count=1
fi

# 閾値到達時に初回提案
if [ "$count" -eq "$THRESHOLD" ]; then
    echo "[StrategicCompact] ${count}回のツール呼出。タスク切れ目で /compact を検討せよ" >&2
fi

# 閾値超過後は25回ごとにリマインド
if [ "$count" -gt "$THRESHOLD" ] && [ $((count % 25)) -eq 0 ]; then
    echo "[StrategicCompact] ${count}回のツール呼出。コンテキスト圧迫の兆候あり。/compact推奨" >&2
fi

exit 0
