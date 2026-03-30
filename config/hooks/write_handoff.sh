#!/usr/bin/env bash
# write_handoff.sh — Stop hook: session handoff summary generator
# exit 0 = approve stop. stdout is intentionally empty.

set -euo pipefail

SCRIPT_DIR="${__HANDOFF_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
INPUT="$(cat)"

if [ -n "${__HANDOFF_AGENT_ID:-}" ]; then
    AGENT_ID="${__HANDOFF_AGENT_ID}"
else
    AGENT_ID="$(tmux display-message -t "${TMUX_PANE:-}" -p '#{@agent_id}' 2>/dev/null || true)"
fi

if [ -z "${AGENT_ID:-}" ]; then
    exit 0
fi

HANDOFF_DIR="$SCRIPT_DIR/queue/handoff"
mkdir -p "$HANDOFF_DIR"
HANDOFF_FILE="$HANDOFF_DIR/${AGENT_ID}.md"
TASK_FILE="$SCRIPT_DIR/queue/tasks/${AGENT_ID}.yaml"
INBOX_FILE="$SCRIPT_DIR/queue/inbox/${AGENT_ID}.yaml"
CMD_QUEUE="$SCRIPT_DIR/queue/shogun_to_karo.yaml"

python3 - "$INPUT" "$AGENT_ID" "$TASK_FILE" "$INBOX_FILE" "$CMD_QUEUE" "$HANDOFF_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml


def load_yaml(path_str):
    path = Path(path_str)
    if not path.exists():
        return {}
    try:
        return yaml.safe_load(path.read_text()) or {}
    except Exception:
        return {}


def as_list(value):
    if isinstance(value, list):
        return value
    return []


payload = {}
try:
    payload = json.loads(sys.argv[1])
except Exception:
    payload = {}

agent_id = sys.argv[2]
task_file = sys.argv[3]
inbox_file = sys.argv[4]
cmd_queue_file = sys.argv[5]
handoff_file = Path(sys.argv[6])

last_msg = (payload.get("last_assistant_message") or "").strip()
task_yaml = load_yaml(task_file)
task = task_yaml.get("task") if isinstance(task_yaml, dict) else {}
inbox_yaml = load_yaml(inbox_file)
messages = as_list(inbox_yaml.get("messages")) if isinstance(inbox_yaml, dict) else []
cmd_queue = as_list(load_yaml(cmd_queue_file))

discussion = []
progress = []
next_actions = []
lord_interest = []

if isinstance(task, dict) and task:
    task_id = task.get("task_id", "unknown_task")
    status = task.get("status", "unknown")
    desc = " ".join(str(task.get("description", "")).split())
    if desc:
        discussion.append(desc[:200])
    progress.append(f"{task_id}: {status}")
    if task.get("blocked_by"):
        progress.append(f"blocked_by: {task.get('blocked_by')}")
    if task.get("output_path"):
        progress.append(f"output_path: {task.get('output_path')}")
    next_actions.append(f"queue/tasks/{agent_id}.yaml を確認し、{task_id} を継続")
elif agent_id == "karo":
    active_cmds = [c for c in cmd_queue if isinstance(c, dict) and c.get("status") in ("pending", "in_progress")]
    if active_cmds:
        current = active_cmds[-1]
        discussion.append(str(current.get("purpose", "")))
        progress.append(f"{current.get('id')}: {current.get('status')}")
        next_actions.append(f"queue/shogun_to_karo.yaml の {current.get('id')} を処理")

if last_msg:
    progress.append(f"last_message: {' '.join(last_msg.split())[:220]}")

shogun_msgs = [m for m in messages if isinstance(m, dict) and m.get("from") == "shogun"]
if shogun_msgs:
    latest = shogun_msgs[-1]
    lord_interest.append(" ".join(str(latest.get("content", "")).split())[:220])

unread = [m for m in messages if isinstance(m, dict) and not m.get("read", True)]
if unread:
    next_actions.append(f"queue/inbox/{agent_id}.yaml の未読 {len(unread)} 件を処理")

if not discussion:
    discussion.append("継続中の論点なし")
if not progress:
    progress.append("未完了タスクなし")
if not next_actions:
    next_actions.append("新しい inbox / task を確認")
if not lord_interest:
    lord_interest.append("直近の殿指示なし")

updated = datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")
content = "\n".join([
    f"# Session Handoff - {agent_id}",
    f"updated: {updated}",
    "",
    "## 議論中の論点",
    *[f"- {item}" for item in discussion],
    "",
    "## 未完了タスクの進捗",
    *[f"- {item}" for item in progress],
    "",
    "## 次のアクション",
    *[f"- {item}" for item in next_actions],
    "",
    "## 殿の最新指示・関心",
    *[f"- {item}" for item in lord_interest],
    "",
])

handoff_file.write_text(content)
PY

exit 0
