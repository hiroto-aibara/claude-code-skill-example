---
name: delegate-code-review
description: コードレビューをタスク化し、Agent Teams チームメイトに委譲する。レビュー結果を構造化フォーマットで受信する。finalize-worktree の内部から呼び出される。
allowed-tools: Bash(git:*), Bash(cd:*), Bash(pwd:*), Bash(gh:*), Read, Grep, Glob, TaskCreate, TaskUpdate, TaskList, TaskGet, Task, SendMessage, TeamCreate, mcp__github__get_issue
user-invocable: false
---

# Delegate Code Review

コードレビューをタスク化し、チームメイトに委譲します。

## 概要

```
1. レビュー対象の確認
   - ブランチ名・作業ディレクトリ・diff 概要を取得
   - ブランチ名から Issue 番号を抽出（あれば）
        ↓
2. Issue 情報取得（Issue 番号がある場合）
   - Issue 本文から受け入れ基準を抽出
        ↓
3. チーム・タスク作成
   - TeamCreate（チームが未作成の場合）
   - TaskCreate でレビュータスク登録（Issue 情報を含む）
        ↓
4. レビュアーチームメイト起動
   - Task で reviewer を bypassPermissions で起動
   - 共通チェックリスト + 受け入れ基準チェックを指示
        ↓
5. レビュー結果の受信
   - reviewer からの SendMessage を待機
   - 構造化フォーマットで結果を受け取る
        ↓
6. 結果をリーダーに返却
   - Must / Should / Nice の件数と詳細
   - 受け入れ基準の充足状況
```

## 入力

| パラメータ | 必須 | 説明 |
|-----------|------|------|
| ブランチ名 | Yes | レビュー対象のブランチ |
| 作業ディレクトリ | Yes | worktree のパス |
| Issue 番号 | No | 明示指定がなければブランチ名から自動抽出 |
| チーム名 | No | 既存チームに参加する場合 |

## フロー詳細

### 1. レビュー対象の確認

```bash
# diff の概要を取得
cd <worktree-path>
git diff --stat origin/main...HEAD
git diff --name-only origin/main...HEAD
```

#### Issue 番号の抽出

ブランチ名から Issue 番号を自動抽出する:

```
feat/101-user-auth      → Issue #101
fix/102-webhook-bug     → Issue #102
issue-103-xxx           → Issue #103
```

明示的に指定された場合はそちらを優先する。

### 2. Issue 情報取得（Issue 番号がある場合）

```bash
gh issue view <number> --json number,title,body
```

Issue 本文から以下を抽出:
- **受け入れ基準**（`## 受け入れ基準` / `## Acceptance Criteria` セクション）
- **概要**（Issue タイトルおよび冒頭の説明）

### 3. タスク作成

#### Issue 番号がある場合

```
TaskCreate:
  subject: "code-review: <ブランチ名> (Issue #<number>)"
  description: |
    ## レビュー対象
    - ブランチ: <ブランチ名>
    - 作業ディレクトリ: <worktree-path>
    - 関連 Issue: #<number>
    - 変更ファイル数: N files
    - 追加/削除: +X / -Y

    ## Issue 受け入れ基準
    <Issue 本文から抽出した受け入れ基準をここに記載>

    ## レビュー手順
    1. 作業ディレクトリに移動
    2. git diff origin/main...HEAD で差分を取得
    3. .claude/skills/shared/REVIEW_CHECKLIST.md を読み込み
    4. チェックリストに基づいてコードレビュー実施
    5. Issue の受け入れ基準を満たしているか確認
       - テスト実行（pytest, npm test 等）が基準に含まれる場合は実行する
       - 定性的な基準は diff の内容と照合して判定する
    6. 結果を構造化フォーマットで SendMessage でリーダーに送信

    ## 出力フォーマット
    ### コードレビュー結果

    #### Must（必須対応）
    - **ファイル**: `path/to/file.py:行番号`
      - **問題**: <説明>
      - **修正案**: <コード例>

    #### Should（推奨対応）
    - **ファイル**: `path/to/file.py:行番号`
      - **問題**: <説明>
      - **修正案**: <コード例>

    #### Nice（改善提案）
    - **ファイル**: `path/to/file.py:行番号`
      - **提案**: <説明>

    ### 受け入れ基準チェック
    | 基準 | 結果 | 詳細 |
    |------|------|------|
    | <基準1> | PASS/FAIL | <補足> |
    | <基準2> | PASS/FAIL | <補足> |

    ### サマリー
    - Must: N 件
    - Should: N 件
    - Nice: N 件
    - 受け入れ基準: N/M 充足
    - 総評: <全体的な評価>
  activeForm: "コードレビューを委譲中"
```

#### Issue 番号がない場合

タスク説明から「Issue 受け入れ基準」セクションと「受け入れ基準チェック」出力を省略する。
それ以外は同じフローで実行する。

### 4. レビュアーチームメイト起動

```
Task:
  name: "reviewer"
  subagent_type: "general-purpose"
  mode: "bypassPermissions"
  prompt: |
    あなたはコードレビュー担当のチームメイトです。

    TaskList を確認し、あなたに割り当てられたレビュータスクを TaskGet で取得してください。
    タスクの description に記載されたレビュー手順に従って作業してください。

    重要:
    - .claude/skills/shared/REVIEW_CHECKLIST.md を必ず読み込み、
      チェックリストの各項目に沿ってレビューすること
    - タスクに Issue 受け入れ基準が記載されている場合は、
      その基準を満たしているかも必ず確認すること
    - レビュー結果はタスクの description に記載された構造化フォーマットで
      SendMessage を使ってリーダーに送信すること
    - レビュー完了後、TaskUpdate でタスクを completed にすること
```

### 5. レビュー結果の受信

チームメイトからの SendMessage を受信し、構造化されたレビュー結果を取得する。

### 6. 結果の返却

受信したレビュー結果をそのまま呼び出し元（finalize-worktree）に返す。

## 呼び出し元

このスキルは以下のスキルから内部的に呼び出される:

- `/finalize-worktree` — ステップ3「コードレビュー」で使用
