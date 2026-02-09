---
name: start-pr-review-task
description: Registers a PR review task to vibe-kanban and starts a workspace session.
allowed-tools: Read, mcp__vibe_kanban__list_projects, mcp__vibe_kanban__create_task, mcp__vibe_kanban__start_workspace_session, mcp__vibe_kanban__list_repos, mcp__vibe_kanban__get_repo, mcp__github__get_pull_request, mcp__github__list_pull_requests, AskUserQuestion
---

# Start PR Review Task

PRレビュータスクをvibe-kanbanに登録し、ワークスペースセッションを開始します。

## 概要

このSkillは以下を実行します：

1. PR番号の確認（指定がなければOpen PR一覧から選択）
2. PRタイトルからIssue番号を自動抽出
3. PRレビュータスクをvibe-kanbanに登録
4. ワークスペースセッションを開始

## 使用方法

```bash
# PR番号を指定
/start-pr-review-task 123

# PR番号未指定（Open PR一覧から選択）
/start-pr-review-task
```

### 例

```bash
# 基本的な使い方
/start-pr-review-task 123

# Open PR一覧から選択
/start-pr-review-task
# → Open PRの一覧が表示され、レビュー対象を選択
```

## 実行手順

### Phase 1: PR番号の確認

**PR番号が指定されている場合:**
- そのPR番号を使用

**PR番号が指定されていない場合:**
1. `mcp__github__list_pull_requests` でOpen状態のPR一覧を取得
2. `AskUserQuestion` でユーザーにレビュー対象PRを選択させる

### Phase 2: PR情報取得・Issue番号抽出

1. `mcp__github__get_pull_request` でPR情報を取得
2. PRタイトルから `#<number>` パターンを抽出 → Issue番号

**抽出パターン例:**
- `#30 feat: Add user authentication` → Issue #30
- `feat: Add feature (closes #30)` → Issue #30

### Phase 3: vibe-kanban情報取得

1. `mcp__vibe_kanban__list_projects` でプロジェクト一覧を取得
2. OnboardAIプロジェクト（ID: `dda09758-b4ed-4960-be35-a00157366e50`）を使用
3. `mcp__vibe_kanban__list_repos` でリポジトリ一覧を取得
4. `mcp__vibe_kanban__get_repo` でリポジトリ詳細（base branch等）を取得

### Phase 4: タスク登録

**タイトル**: `review: PR #<番号>`

**description（Issue番号ありの場合）**:
```markdown
## 概要
PR #<番号> のレビューを行う

## 関連Issue
#<issue-number>

## レビュー手順
1. `/review-pr <PR番号> --issue <Issue番号>` を実行
   - Issue本文の受け入れ基準との整合性チェックも自動実行
2. 指摘事項があればPRにコメント
3. レビュー完了後、タスクステータスを `done` に更新

## 受け入れ基準
- [ ] セキュリティ観点でのチェック完了
- [ ] コード品質のチェック完了
- [ ] Issue受け入れ基準との整合性確認
- [ ] レビューコメント投稿完了
```

**description（Issue番号なしの場合）**:
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

### Phase 5: ワークスペースセッション開始

1. `mcp__vibe_kanban__start_workspace_session` を実行
   - `task_id`: 作成したタスクのID
   - `executor`: `CLAUDE_CODE`
   - `repos`: `[{repo_id, base_branch}]`

### Phase 6: 結果表示

```markdown
## ✅ PRレビュータスク登録・セッション開始完了

| 項目 | 値 |
|------|-----|
| タスクID | xxxx-xxxx |
| タイトル | review: PR #123 |
| 関連Issue | #30 / なし |
| プロジェクト | OnboardAI |
| ワークスペース | 開始済み |

### 次のステップ
ワークスペースで以下を実行:
```bash
/review-pr 123 --issue 30
# または（Issue番号なしの場合）
/review-pr 123
```
```

## プロジェクト設定

| 項目 | 値 |
|------|-----|
| プロジェクトID | `dda09758-b4ed-4960-be35-a00157366e50` |
| リポジトリ | OnboardAI |

## 前提条件

- vibe-kanban MCPサーバーが接続されていること
- GitHub MCPサーバーが接続されていること
- gh CLIが認証済みであること

## 関連スキル

- `/review-pr` - PRレビュー実行
- `/start-vk-task` - GitHub Issue登録・開始（vibe-kanban連携）
- `/create-issue` - GitHub Issue作成
