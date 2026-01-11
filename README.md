# Claude Code Skill Example

Claude Codeでプランモードから開発を設計し、TASK.mdを作成してからworktreeで並列開発するためのスキルセットです。

## スキル一覧

| スキル | 説明 |
|--------|------|
| [create-task](./.claude/skills/create-task/SKILL.md) | ユーザーの説明を元にTASK.mdを生成 |
| [create-multiple-worktrees](./.claude/skills/create-multiple-worktrees/SKILL.md) | TASK.mdから複数のworktreeを一括作成 |
| [create-worktree](./.claude/skills/create-worktree/SKILL.md) | 単一のworktreeを作成 |
| [create-pr](./.claude/skills/create-pr/SKILL.md) | PR作成 |
| [cleanup-worktree](./.claude/skills/cleanup-worktree/SKILL.md) | worktree削除（PRマージ後に使用） |
| [review-pr](./.claude/skills/review-pr/SKILL.md) | GitHub PRをレビューしてコメント投稿 |

## ワークフロー

```
1. /plan で全体設計
   ↓
2. /create-task <feature-name> でTASK.md作成
   → tasks/user-auth.md
   → tasks/dashboard.md
   → tasks/api-v2.md
   ↓
3. /create-multiple-worktrees tasks/*.md でworktree一括作成
   ↓
4. 各ターミナルで並列開発
   ├── cd .worktrees/user-auth && claude
   ├── cd .worktrees/dashboard && claude
   └── cd .worktrees/api-v2 && claude
   ↓
5. 各worktreeで /create-pr でPR作成
   ↓
6. 別セッションで /review-pr <PR番号> でレビュー
   ├── Approve → マージ
   └── Request Changes → 修正 → 再レビュー
   ↓
7. PRマージ後、/cleanup-worktree でworktree削除
```

## 使い方

### 1. TASK.md作成

```bash
/create-task user-auth
# → ユーザーがタスク内容を説明
# → Claude Codeが要件・品質基準を含むTASK.mdを生成
# → tasks/user-auth.md として保存
```

### 2. Worktree一括作成

```bash
/create-multiple-worktrees tasks/*.md
# または
/create-multiple-worktrees tasks/user-auth.md tasks/dashboard.md
```

### 3. 並列開発

各ターミナルでworktreeに移動してClaude Codeを起動：

```bash
cd .worktrees/user-auth && claude
```

### 4. PR作成

```bash
/create-pr
```

### 5. PRレビュー（別セッション）

```bash
# PR番号で指定
/review-pr 123

# URL形式でも可
/review-pr https://github.com/owner/repo/pull/123
```

レビュー後、Approve / Request Changes / Comment を選択してGitHubに投稿します。

### 6. worktree削除（PRマージ後）

```bash
/cleanup-worktree
```

## リファレンス

このリポジトリは以下を元に作成されています：

- [shikajiro/claude-code-skill-example](https://github.com/shikajiro/claude-code-skill-example/tree/main)
