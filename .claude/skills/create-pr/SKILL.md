---
name: create-pr
description: Creates a PR from the current branch without deleting the worktree. Use this when you want to keep the worktree for local modifications.
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cd:*), Bash(pwd:*)
---

# Create PR

現在のブランチからPRを作成します。

## 概要

このスキルは以下を実行します：

1. 現在のworktreeディレクトリとブランチを検出
2. 未コミットの変更がないか確認
3. PRを作成（タイトル・本文はインタラクティブ入力可能）

## 使用方法

### 基本的な使い方

```bash
# worktreeディレクトリ内で実行
cd .worktrees/<feature-name>
/create-pr
```

### オプション

```bash
# タイトルと本文を事前指定
/create-pr --title "feat: Add new feature" --body "詳細な説明..."

# ドラフトPRとして作成
/create-pr --draft

# ベースブランチを指定
/create-pr --base develop

# 未コミット変更を無視（非推奨）
/create-pr --force
```

## 前提条件

- worktreeディレクトリ内で実行すること
- すべての変更がコミット済みであること
- `gh` CLI がインストール・認証済みであること

## 実行例

```bash
$ cd .worktrees/user-auth
$ /create-pr

[INFO] Current branch: feature/user-auth
[INFO] Worktree path: /path/to/.worktrees/user-auth
[STEP] Checking for uncommitted changes...
[INFO] No uncommitted changes detected
[STEP] Creating pull request...
[INFO] PR created: https://github.com/user/repo/pull/123
```

## 関連スキル

- `cleanup-worktree`: worktree削除
- `review-pr`: PRレビュー
- `create-worktree`: worktree作成

## 詳細

詳細については [REFERENCE.md](REFERENCE.md) を参照してください。
