#!/usr/bin/env bash
# pre-commit hook: protect main/develop from direct commits
# Symlinked from .git/hooks/pre-commit

set -euo pipefail

branch=$(git symbolic-ref --short HEAD 2>/dev/null || true)

protected_branches="main develop"

for protected in $protected_branches; do
  if [ "$branch" = "$protected" ]; then
    echo "❌ Direct commit to '$branch' is not allowed."
    echo "   Create a feature branch first: git checkout -b feature/your-change"
    exit 1
  fi
done
