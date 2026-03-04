#!/bin/bash
# =============================================================================
# Worktree メインブランチ同期スクリプト
# =============================================================================
# Usage: bash scripts/worktree-sync.sh <worktree-id> [main-branch]
#
# worktree をメインブランチの最新に同期する。
# タスク完了後の再利用（pre-warmed pool パターン）に使用。
#
# 動作:
#   1. 未コミット変更を stash
#   2. worktree ブランチをローカルのメインブランチにリベース
#   3. stash pop
# =============================================================================
set -euo pipefail

WT_ID="${1:?Usage: $0 <worktree-id> [main-branch]}"
MAIN_BRANCH="${2:-main}"

# プロジェクトルートを自動検出
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WT_PATH="${REPO_ROOT}/worktrees/${WT_ID}"

if [ ! -d "${WT_PATH}" ]; then
  echo "ERROR: Worktree not found: ${WT_PATH}"
  exit 1
fi

echo "=== Syncing worktree ${WT_ID} with ${MAIN_BRANCH} ==="

cd "${WT_PATH}"

# -----------------------------------------------
# 1. 未コミットの変更を退避
# -----------------------------------------------
STASHED=false
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "  Stashing uncommitted changes..."
  git stash push -m "worktree-sync: auto-stash before rebase"
  STASHED=true
fi

# -----------------------------------------------
# 2. ローカルのメインブランチにリベース
# -----------------------------------------------
echo "  Rebasing onto ${MAIN_BRANCH}..."
if ! git rebase "${MAIN_BRANCH}"; then
  echo "ERROR: Rebase conflict detected. Aborting rebase."
  git rebase --abort
  if [ "${STASHED}" = true ]; then
    git stash pop
  fi
  exit 1
fi

# -----------------------------------------------
# 3. 退避した変更を復元
# -----------------------------------------------
if [ "${STASHED}" = true ]; then
  echo "  Restoring stashed changes..."
  git stash pop || echo "  WARNING: Stash pop had conflicts. Resolve manually."
fi

echo "=== Sync complete ==="
