#!/usr/bin/env bash
# Wrapper: call summonai-memory-mcp's stop_hook_conversation_save.sh
# Resolves the external repo path via environment variable or config.
set -eu

# 1. Environment variable (preferred)
if [[ -n "${SUMMONAI_MEMORY_MCP_DIR:-}" ]]; then
  TARGET="$SUMMONAI_MEMORY_MCP_DIR/scripts/stop_hook_conversation_save.sh"
  if [[ -x "$TARGET" ]]; then
    exec bash "$TARGET"
  fi
fi

# 2. config/local.env (gitignored, per-machine settings)
PROJ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_ENV="$PROJ_ROOT/config/local.env"
if [[ -f "$LOCAL_ENV" ]]; then
  # shellcheck source=/dev/null
  source "$LOCAL_ENV"
  if [[ -n "${SUMMONAI_MEMORY_MCP_DIR:-}" ]]; then
    TARGET="$SUMMONAI_MEMORY_MCP_DIR/scripts/stop_hook_conversation_save.sh"
    if [[ -x "$TARGET" ]]; then
      exec bash "$TARGET"
    fi
  fi
fi

echo "[stop_hook_conversation_save] SUMMONAI_MEMORY_MCP_DIR not set. Skipping." >&2
echo "Set it in environment or in config/local.env" >&2
exit 0
