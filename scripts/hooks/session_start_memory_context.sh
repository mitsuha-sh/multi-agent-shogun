#!/usr/bin/env bash
# Wrapper: call atri-memory-mcp's session_start_memory_context.sh
# Resolves the external repo path via environment variable or config.
set -eu

# 1. Environment variable (preferred)
if [[ -n "${ATRI_MEMORY_MCP_DIR:-}" ]]; then
  TARGET="$ATRI_MEMORY_MCP_DIR/scripts/session_start_memory_context.sh"
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
  if [[ -n "${ATRI_MEMORY_MCP_DIR:-}" ]]; then
    TARGET="$ATRI_MEMORY_MCP_DIR/scripts/session_start_memory_context.sh"
    if [[ -x "$TARGET" ]]; then
      exec bash "$TARGET"
    fi
  fi
fi

echo "[session_start_memory_context] ATRI_MEMORY_MCP_DIR not set. Skipping." >&2
echo "Set it in environment or in config/local.env" >&2
exit 0
