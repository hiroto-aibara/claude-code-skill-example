---
name: start-vk-task
description: Registers a task file (tasks/*.md) to vibe-kanban and starts a workspace session.
allowed-tools: Read, mcp__vibe_kanban__list_projects, mcp__vibe_kanban__create_task, mcp__vibe_kanban__start_workspace_session, mcp__vibe_kanban__list_repos, mcp__vibe_kanban__get_repo
---

# Start VK Task

タスクファイルをvibe-kanbanに登録し、ワークスペースセッションを開始します。

## 概要

このSkillは以下を実行します：

1. タスクファイル（`tasks/*.md`）を読み込む
2. vibe-kanbanにタスクを登録
3. ワークスペースセッションを開始

## 使用方法

```bash
/start-vk-task <task-file-path>
```

### 例

```bash
# タスクファイルを指定して開始
/start-vk-task tasks/feature-user-auth.md
```

## 実行手順

### Phase 1: タスクファイル読み込み

1. 引数で渡されたタスクファイルをReadツールで読み込む
2. ファイルが存在しない場合はエラーを表示

### Phase 2: vibe-kanban情報取得

1. `mcp__vibe_kanban__list_projects` でプロジェクト一覧を取得
2. OnboardAIプロジェクト（ID: `dda09758-b4ed-4960-be35-a00157366e50`）を使用
3. `mcp__vibe_kanban__list_repos` でリポジトリ一覧を取得
4. `mcp__vibe_kanban__get_repo` でリポジトリ詳細（base branch等）を取得

### Phase 3: タスク登録

1. **タイトル生成**: ファイル名から生成
   - `tasks/feature-user-auth.md` → `feature: user-auth`
   - `tasks/fix-login-bug.md` → `fix: login-bug`
   - `tasks/refactor-bootstrap.md` → `refactor: bootstrap`

2. **description**: タスクファイルの内容をそのままコピー

3. `mcp__vibe_kanban__create_task` でタスクを登録
   - `project_id`: `dda09758-b4ed-4960-be35-a00157366e50`
   - `title`: 上記ルールで生成
   - `description`: タスクファイル内容

### Phase 4: ワークスペースセッション開始

1. `mcp__vibe_kanban__start_workspace_session` を実行
   - `task_id`: 作成したタスクのID
   - `executor`: `CLAUDE_CODE`
   - `repos`: `[{repo_id, base_branch}]`

### Phase 5: 結果表示

```markdown
## ✅ タスク登録・セッション開始完了

| 項目 | 値 |
|------|-----|
| タスクID | xxxx-xxxx |
| タイトル | feature: user-auth |
| プロジェクト | OnboardAI |
| ワークスペース | 開始済み |
```

## タイトル生成ルール

| ファイル名パターン | 生成タイトル |
|-------------------|-------------|
| `feature-<name>.md` | `feature: <name>` |
| `fix-<name>.md` | `fix: <name>` |
| `refactor-<name>.md` | `refactor: <name>` |
| `perf-<name>.md` | `perf: <name>` |
| `<other>.md` | `task: <other>` |

## プロジェクト設定

| 項目 | 値 |
|------|-----|
| プロジェクトID | `dda09758-b4ed-4960-be35-a00157366e50` |
| リポジトリ | OnboardAI |

## 前提条件

- vibe-kanban MCPサーバーが接続されていること
- タスクファイルが `tasks/` ディレクトリに存在すること

## 関連スキル

- `/create-task` - タスクファイル作成
- `/start-pr-review-task` - PRレビュータスクの登録・開始
