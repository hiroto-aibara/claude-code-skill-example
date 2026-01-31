---
name: start-vk-task
description: Registers a GitHub Issue to vibe-kanban and starts a workspace session.
allowed-tools: mcp__github__get_issue, mcp__vibe_kanban__list_projects, mcp__vibe_kanban__create_task, mcp__vibe_kanban__start_workspace_session, mcp__vibe_kanban__list_repos, mcp__vibe_kanban__get_repo
---

# Start VK Task

GitHub IssueをVibe-kanbanに登録し、ワークスペースセッションを開始します。

## 概要

このSkillは以下を実行します：

1. GitHub Issueの内容を取得
2. vibe-kanbanにタスクを登録
3. ワークスペースセッションを開始

## 使用方法

```bash
/start-vk-task <issue-number>
```

### 例

```bash
# Issue番号を指定して開始
/start-vk-task 30
/start-vk-task #30
```

## 実行手順

### Phase 1: GitHub Issue取得

1. `mcp__github__get_issue` でIssueの内容を取得
   - `owner`: リポジトリオーナー（GitHubリモートから取得）
   - `repo`: リポジトリ名（GitHubリモートから取得）
   - `issue_number`: 引数で渡されたIssue番号

2. Issueが存在しない場合はエラーを表示

### Phase 2: vibe-kanban情報取得

1. `mcp__vibe_kanban__list_projects` でプロジェクト一覧を取得
2. 適切なプロジェクトを選択（複数ある場合はユーザーに確認）
3. `mcp__vibe_kanban__list_repos` でリポジトリ一覧を取得
4. `mcp__vibe_kanban__get_repo` でリポジトリ詳細（base branch等）を取得

### Phase 3: タスク登録

1. **タイトル生成**: Issue番号とIssueタイトルから生成
   - フォーマット: `#<issue-number> <issue-title>`
   - 例: `#30 refactor(api): TYPE_CHECKING ガードで型スタブのインポートを囲む`

2. **description**: 以下の形式で構成
   ```markdown
   GitHub Issue: #<issue-number>

   <issue-body>
   ```

3. `mcp__vibe_kanban__create_task` でタスクを登録
   - `project_id`: 選択したプロジェクトID
   - `title`: 上記ルールで生成
   - `description`: 上記形式

### Phase 4: ワークスペースセッション開始

1. `mcp__vibe_kanban__start_workspace_session` を実行
   - `task_id`: 作成したタスクのID
   - `executor`: `CLAUDE_CODE`
   - `repos`: `[{repo_id, base_branch}]`

### Phase 5: 結果表示

```markdown
## タスク登録・セッション開始完了

| 項目 | 値 |
|------|-----|
| タスクID | xxxx-xxxx |
| タイトル | #30 refactor(api): TYPE_CHECKING... |
| GitHub Issue | #30 |
| プロジェクト | OnboardAI |
| ワークスペース | 開始済み |
```

## タイトル生成ルール

| Issue | 生成タイトル |
|-------|-------------|
| Issue #30: `refactor(api): TYPE_CHECKING ガード...` | `#30 refactor(api): TYPE_CHECKING ガード...` |
| Issue #45: `feat: Add user authentication` | `#45 feat: Add user authentication` |

**重要**: タイトルには必ずIssue番号を先頭に含める（`#<number> `形式）

## 前提条件

- vibe-kanban MCPサーバーが接続されていること
- GitHub MCPサーバーが接続されていること
- 指定したIssue番号がリポジトリに存在すること

## 関連スキル

- `/start-pr-review-task` - PRレビュータスクの登録・開始
- `/review-pr` - PRレビュー実行
