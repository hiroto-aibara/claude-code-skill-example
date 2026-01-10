---
name: create-multiple-worktrees
description: Creates git worktrees from TASK.md files for parallel feature development. Each worktree gets its own TASK.md with requirements and quality standards.
allowed-tools: Bash(git:*), Bash(mkdir:*), Bash(cp:*), Bash(chmod:*), Bash(bash:*), Bash(make:*), Bash(cat:*)
---

# Multiple Git Worktree Creator

TASK.mdファイルから複数のworktreeを一括作成し、並列開発環境を構築します。

## 概要

このSkillは以下のスクリプトを実行します：

```bash
bash .claude/skills/create-multiple-worktrees/scripts/create_multiple_worktrees.sh <task-files>
```

スクリプトにより以下の処理が行われます：

1. 引数で指定されたTASK.mdファイルを読み込み
2. ファイル名からfeature名を抽出（例: `user-auth.md` → `user-auth`）
3. 各featureの `.worktrees/<feature-name>/` にworktreeを作成
4. `feature/<feature-name>` ブランチを新規作成
5. TASK.mdを各worktreeにコピー
6. 環境変数ファイル（`.env`, `.envrc` など）を自動コピー

## 使用方法

### 基本的な使い方

```bash
# TASK.mdファイルを直接指定
/create-multiple-worktrees tasks/user-auth.md tasks/dashboard.md tasks/api-v2.md

# ワイルドカードで一括指定
/create-multiple-worktrees tasks/*.md
```

## 実行結果

```
.worktrees/
├── user-auth/
│   ├── TASK.md          # ← tasks/user-auth.md からコピー
│   ├── .env
│   └── ...
├── dashboard/
│   ├── TASK.md          # ← tasks/dashboard.md からコピー
│   ├── .env
│   └── ...
└── api-v2/
    ├── TASK.md          # ← tasks/api-v2.md からコピー
    ├── .env
    └── ...
```

## オプション

| オプション | 説明 |
|------------|------|
| `--dry-run` | 実際には作成せず、何が作成されるか表示 |

## 作業完了後

各worktreeで **pr-and-cleanup** スキルを使用すると、PR作成とworktree削除を自動で行えます：

```bash
cd .worktrees/<feature-name>
/pr-and-cleanup
```

### 手動でworktreeを削除する場合

```bash
# 個別に削除
git worktree remove .worktrees/<feature-name>

# 一括削除
for wt in .worktrees/*/; do git worktree remove "$wt"; done
```

## 詳細

詳細については [REFERENCE.md](REFERENCE.md) を参照してください。
