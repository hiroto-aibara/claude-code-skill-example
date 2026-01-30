---
name: start-pr-review-task
description: Registers a PR review task to vibe-kanban and starts a workspace session.
allowed-tools: Read, mcp__vibe_kanban__list_projects, mcp__vibe_kanban__create_task, mcp__vibe_kanban__start_workspace_session, mcp__vibe_kanban__list_repos, mcp__vibe_kanban__get_repo
---

# Start PR Review Task

PRレビュータスクをvibe-kanbanに登録し、ワークスペースセッションを開始します。

## 概要

このSkillは以下を実行します：

1. PRレビュータスクをvibe-kanbanに登録
2. ワークスペースセッションを開始
3. タスクファイルが指定された場合、受け入れ基準チェック用にリンク

## 使用方法

```bash
# タスクファイルなし
/start-pr-review-task <PR番号>

# タスクファイルあり
/start-pr-review-task <PR番号> <task-file-path>
```

### 例

```bash
# 基本的な使い方
/start-pr-review-task 123

# タスクファイル付き
/start-pr-review-task 123 tasks/feature-user-auth.md
```

## 実行手順

### Phase 1: 引数の解析

1. 第1引数: PR番号（必須）
2. 第2引数: タスクファイルパス（任意）

### Phase 2: vibe-kanban情報取得

1. `mcp__vibe_kanban__list_projects` でプロジェクト一覧を取得
2. OnboardAIプロジェクト（ID: `dda09758-b4ed-4960-be35-a00157366e50`）を使用
3. `mcp__vibe_kanban__list_repos` でリポジトリ一覧を取得
4. `mcp__vibe_kanban__get_repo` でリポジトリ詳細（base branch等）を取得

### Phase 3: タスク登録

**タイトル**: `review: PR #<番号>`

**description（タスクファイルありの場合）**:
```markdown
## 概要
PR #<番号> のレビューを行う

## 関連タスクファイル
`<タスクファイルパス>`

## レビュー手順
1. `/review-pr <PR番号> <タスクファイルパス>` を実行
   - タスクファイル付きで実行することで受け入れ基準のチェックも自動実行
2. 指摘事項があればPRにコメント
3. レビュー完了後、タスクステータスを `done` に更新

## 受け入れ基準
- [ ] セキュリティ観点でのチェック完了
- [ ] コード品質のチェック完了
- [ ] 関連タスクファイルの受け入れ基準との整合性確認
- [ ] レビューコメント投稿完了
```

**description（タスクファイルなしの場合）**:
```markdown
## 概要
PR #<番号> のレビューを行う

## レビュー手順
1. `/review-pr <PR番号>` を実行
2. 指摘事項があればPRにコメント
3. レビュー完了後、タスクステータスを `done` に更新

## 受け入れ基準
- [ ] セキュリティ観点でのチェック完了
- [ ] コード品質のチェック完了
- [ ] レビューコメント投稿完了
```

`mcp__vibe_kanban__create_task` でタスクを登録:
- `project_id`: `dda09758-b4ed-4960-be35-a00157366e50`
- `title`: `review: PR #<番号>`
- `description`: 上記テンプレート

### Phase 4: ワークスペースセッション開始

1. `mcp__vibe_kanban__start_workspace_session` を実行
   - `task_id`: 作成したタスクのID
   - `executor`: `CLAUDE_CODE`
   - `repos`: `[{repo_id, base_branch}]`

### Phase 5: 結果表示

```markdown
## ✅ PRレビュータスク登録・セッション開始完了

| 項目 | 値 |
|------|-----|
| タスクID | xxxx-xxxx |
| タイトル | review: PR #123 |
| 関連タスクファイル | tasks/feature-user-auth.md / なし |
| プロジェクト | OnboardAI |
| ワークスペース | 開始済み |

### 次のステップ
ワークスペースで以下を実行:
\`\`\`bash
/review-pr <PR番号> [<タスクファイル>]
\`\`\`
```

## プロジェクト設定

| 項目 | 値 |
|------|-----|
| プロジェクトID | `dda09758-b4ed-4960-be35-a00157366e50` |
| リポジトリ | OnboardAI |

## 前提条件

- vibe-kanban MCPサーバーが接続されていること
- タスクファイル指定時は `tasks/` ディレクトリに存在すること

## 関連スキル

- `/review-pr` - PRレビュー実行
- `/start-vk-task` - タスクファイルの登録・開始
- `/create-task` - タスクファイル作成
