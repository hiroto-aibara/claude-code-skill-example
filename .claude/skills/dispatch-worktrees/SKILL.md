---
name: dispatch-worktrees
description: GitHub Issue をもとに git worktree を作成し、依存セットアップ後に Agent Teams チームメイトを並列起動する。Issue 番号を指定するか、対話的に選択可能。
allowed-tools: Bash(git:*), Bash(cd:*), Bash(pwd:*), Bash(npm:*), Bash(pip:*), Bash(python*:*), Bash(source:*), Bash(ln:*), Bash(ls:*), Bash(gh:*), Read, Glob, AskUserQuestion, TeamCreate, TaskCreate, TaskUpdate, TaskList, Task, SendMessage, mcp__github__get_issue, mcp__github__list_issues
user-invocable: true
---

# Dispatch Worktrees

GitHub Issue をもとに worktree を作成し、Agent Teams チームメイトを並列起動します。

## 概要

```
1. Issue 特定
   - 引数あり → 指定された Issue 番号を使用
   - 引数なし → Open な Issue 一覧を表示 → ユーザーが選択
        ↓
2. Issue 内容取得
   - 各 Issue のタイトル・本文を取得
        ↓
3. Worktree 作成
   - Issue ごとに git worktree add
   - ブランチ名: feat/<issue-number>-<slug>
        ↓
4. 依存セットアップ
   - 各 worktree で独立した環境を構築
   - Python: python -m venv + pip install
   - Node.js: npm ci
        ↓
5. Agent Teams 起動
   - TeamCreate でチーム作成
   - TaskCreate × N（Issue 内容をタスク説明に使用）
   - Task × N でチームメイトを bypassPermissions で並列起動
```

## 使用方法

### Issue 番号を指定

```
/dispatch-worktrees #101 #102 #103
```

### 対話的に選択

```
/dispatch-worktrees
```

Open な Issue 一覧から AskUserQuestion で対象を選択する（複数選択可能）。

## フロー詳細

### 1. Issue 特定

#### 引数ありの場合

引数からIssue番号を抽出して使用する。

#### 引数なしの場合

```bash
gh issue list --state open --limit 20 --json number,title,labels
```

AskUserQuestion で対象 Issue を選択（multiSelect: true）:

```
対象の Issue を選択してください:
  □ #101 feat: ユーザー認証機能
  □ #102 feat: オンボーディングAPI
  □ #103 fix: DocuSign webhook冪等性
```

### 2. Issue 内容取得

各 Issue の内容を取得する:

```bash
gh issue view <number> --json number,title,body
```

### 3. Worktree 作成

各 GitHub Issue に対して worktree を作成する。
ワークツリー名・ブランチ名には **GitHub Issue 番号** を使用し、対応関係を明確にする。

```bash
# ワークツリー名: issue-<GitHub Issue番号>-<slug>
# ブランチ名:     feat/issue-<GitHub Issue番号>-<slug>
# slug は Issue タイトルから英数字とハイフンのみ抽出（最大30文字）

# 例: Issue #101 "ユーザー認証機能" の場合
git worktree add worktrees/issue-101-user-auth -b feat/issue-101-user-auth
```

### 4. 依存セットアップ

各 worktree で `mise install && mise run setup` を実行し、独立した環境を構築する。
mise がプロジェクトの `.mise.toml` に基づいてランタイム（Python, Node.js, uv）と依存関係を一括セットアップする。

```bash
# 各 worktree に対して実行
cd worktrees/issue-101-user-auth && mise install && mise run setup && cd -
cd worktrees/issue-102-onboarding-api && mise install && mise run setup && cd -
```

### 5. Agent Teams 起動

#### チーム作成

```
TeamCreate: team_name = "parallel-impl" （または適切な名前）
```

#### タスク作成

各 Issue に対して TaskCreate を実行。タスク説明には Issue の内容をそのまま使用する:

```
TaskCreate:
  subject: "#<GitHub Issue番号> <Issue タイトル>"
  description: |
    ## GitHub Issue
    <Issue 本文をそのまま記載>

    ## 作業ディレクトリ
    /workspace/worktrees/issue-<GitHub Issue番号>-<slug>/

    ## ルール
    - 作業は上記ディレクトリ内でのみ行うこと
    - コミット前に、変更したレイヤに関連するユニットテストを実行すること
    - コミットメッセージは Conventional Commits 形式で記述すること
    - 作業完了後は TaskUpdate で completed に設定し、SendMessage でリーダーに報告すること
```

#### チームメイト起動

各タスクに対してチームメイトを並列起動する:

```
Task:
  name: "worker-<GitHub Issue番号>"
  subagent_type: "general-purpose"
  mode: "bypassPermissions"
  team_name: "parallel-impl"
  prompt: |
    あなたはチームメイト worker-<GitHub Issue番号> です。

    TaskList を確認し、あなたに割り当てられたタスクを TaskGet で取得して作業を開始してください。

    作業ディレクトリ: /workspace/worktrees/issue-<GitHub Issue番号>-<slug>/

    作業ルール:
    - 上記ディレクトリ内でのみファイルを変更すること
    - コミット前に変更レイヤのユニットテストを実行すること
      - Domain層: pytest tests/domain/
      - Infrastructure層: pytest tests/infrastructure/
      - Application層: pytest tests/application/
      - API層: pytest tests/api/
    - コミットメッセージは Conventional Commits 形式
    - 完了したら TaskUpdate で completed にし、SendMessage でリーダーに報告すること
```

**注意**: チームメイトは可能な限り並列で起動する（Task ツールを同一メッセージ内で複数呼び出す）。

## 制約・注意事項

- worktrees/ ディレクトリが存在すること（`/setup-docker` で作成済み）
- コンテナ内で実行する場合、作業パスは `/workspace/worktrees/` になる
- 各 worktree の `.venv/` と `node_modules/` は `.gitignore` に含まれるためコミット対象外

## 参考

- [docs/docker-agent-teams-guide.md](../../../docs/docker-agent-teams-guide.md) - Docker + Agent Teams ガイド
