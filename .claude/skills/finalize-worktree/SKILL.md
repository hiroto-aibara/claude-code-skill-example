---
name: finalize-worktree
description: worktree ブランチに対して main マージ → コードレビュー（チームメイト委譲）→ 修正 → PR 作成を実行する。ブランチ名を指定するか、自動検出して対話的に選択可能。
allowed-tools: Bash(git:*), Bash(cd:*), Bash(pwd:*), Bash(gh:*), Bash(ls:*), Read, Grep, Glob, AskUserQuestion, TeamCreate, TaskCreate, TaskUpdate, TaskList, TaskGet, Task, SendMessage, Skill
user-invocable: true
---

# Finalize Worktree

worktree ブランチのレビュー → 修正 → PR 作成を実行します。

## 概要

```
1. ブランチ特定
   - 引数あり → 指定ブランチを使用
   - 引数なし → 未マージ worktree ブランチを自動検出 → ユーザーが選択
        ↓
2. main → feature マージ
   - git fetch origin main
   - feature ブランチに main を取り込む
   - コンフリクトがあればユーザーに通知して中断
        ↓
3. コードレビュー（チームメイトに委譲）
   - レビュー用チームメイトを起動
   - /code-review を実行させる
   - 構造化されたレビュー結果を受信
        ↓
4. レビュー結果に基づく判断
   - Must 指摘あり → リーダーが修正 or 修正タスクを委譲
   - Should/Nice のみ → ユーザーに対応要否を確認
   - 指摘なし → 次へ
        ↓
5. PR 作成
   - /create-pr スキルを実行
```

## 使用方法

### ブランチ名を指定

```
/finalize-worktree feat/101-user-auth
```

### 自動検出

```
/finalize-worktree
```

## フロー詳細

### 1. ブランチ特定

#### 引数ありの場合

指定されたブランチ名（または worktree 名）を使用する。

#### 引数なしの場合

```bash
# worktree 一覧を取得
git worktree list

# main にマージされていないブランチを抽出
git branch --no-merged main
```

worktrees/ 配下かつ main 未マージのブランチを候補として AskUserQuestion で選択:

```
対象のブランチを選択してください:
  ○ feat/101-user-auth (worktrees/101-user-auth)
  ○ feat/102-onboarding-api (worktrees/102-onboarding-api)
```

### 2. main → feature マージ

```bash
# main を最新化
git fetch origin main

# feature ブランチで main を取り込む
cd worktrees/<name>
git merge origin/main
```

**コンフリクト発生時**: マージを中断し、ユーザーに通知する。手動解決を依頼。

```
コンフリクトが発生しました。以下のファイルを手動で解決してください:
- apps/api/app/domain/onboarding.py
- apps/web/src/views/OnboardingList.tsx

解決後、再度 /finalize-worktree を実行してください。
```

### 3. コードレビュー（チームメイトに委譲）

`delegate-code-review` スキルを使用してレビューをチームメイトに委譲する。

```
delegate-code-review:
  ブランチ名: feat/<branch-name>
  作業ディレクトリ: worktrees/<name>/
  Issue 番号: <ブランチ名から自動抽出、または明示指定>
```

delegate-code-review が以下を実行:
1. レビュータスクの作成（Issue 受け入れ基準を含む）
2. レビュアーチームメイトの起動
3. 構造化されたレビュー結果の受信・返却

詳細は [delegate-code-review/SKILL.md](../delegate-code-review/SKILL.md) を参照。

### 4. レビュー結果に基づく判断

チームメイトからレビュー結果を受信後:

#### Must 指摘がある場合

リーダー自身が修正するか、修正タスクをチームメイトに委譲する。
修正後、必要に応じて再レビューを実施する。

#### Should/Nice のみの場合

ユーザーに対応要否を確認する:

```
AskUserQuestion:
  question: "Should/Nice の指摘があります。対応しますか？"
  options:
    - "対応する" → 修正を実施
    - "スキップしてPR作成" → 次へ
```

#### 指摘なしの場合

そのまま PR 作成へ進む。

### 5. PR 作成

`/create-pr` スキルを実行する:

```
Skill: create-pr
```

## 制約・注意事項

- 各ステップ間でユーザー確認を挟む（自動で全工程を進めない）
- コンフリクト解決は自動で行わない（ユーザーに委ねる）
- PR 作成には `gh` CLI の認証が必要（コンテナ内では不可。ホスト側で実行すること）

## 参考

- [docs/docker-agent-teams-guide.md](../../../docs/docker-agent-teams-guide.md) - Docker + Agent Teams ガイド
- [.claude/skills/shared/REVIEW_CHECKLIST_COMMON.md](../shared/REVIEW_CHECKLIST_COMMON.md) - 共通レビューチェックリスト
- [.claude/skills/shared/REVIEW_CHECKLIST_BACKEND.md](../shared/REVIEW_CHECKLIST_BACKEND.md) - バックエンドレビューチェックリスト
- [.claude/skills/shared/REVIEW_CHECKLIST_FRONTEND.md](../shared/REVIEW_CHECKLIST_FRONTEND.md) - フロントエンドレビューチェックリスト
