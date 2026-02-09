---
name: code-review
description: Review code changes with strict senior engineer perspective. Check git diff, analyze by file, categorize feedback as Must/Should/Nice with examples and rationale. Use when reviewing code, pull requests, or the user asks for code review.
allowed-tools: Bash(git:*), Read, Grep, SendMessage
user-invocable: true
---

# Code Review Skill

## Overview

このスキルは、厳しめのシニアエンジニアの視点でコード変更をレビューします。

## Review Process

### 1. 差分の取得

まず、現在の変更状況を確認します：

```bash
# 現在の状況確認
git status

# 未ステージ差分をレビューする場合
git diff

# ステージ済み差分をレビューする場合
git diff --cached

# main ブランチとの差分をレビューする場合
git diff origin/main...HEAD
```

**重要**: レビューは取得した diff 出力を根拠として実施してください。

### 2. チェックリストの読み込み

共通チェックリストを読み込んでレビューの基準とする:

```
.claude/skills/shared/REVIEW_CHECKLIST.md
```

### 3. レビュー実施

#### レビュー視点

あなたは **厳しめのシニアエンジニア** として、共通チェックリストに基づいてレビューしてください。

#### レビューフォーマット

**ファイルごと**にレビューし、以下の3分類で指摘してください：

```markdown
## ファイル名: `path/to/file.py`

### Must（必須対応）
致命的な問題。マージ前に必ず修正が必要。

- **問題**: <具体的な問題の説明>
  - **根拠**: <なぜこれが問題か、どのルール・原則に違反しているか>
  - **修正例**:
    ```python
    # 修正前
    <問題のあるコード>

    # 修正後
    <修正後のコード>
    ```

### Should（推奨対応）
重要だが致命的ではない問題。できれば修正すべき。

- **問題**: <具体的な問題の説明>
  - **根拠**: <なぜこれが問題か>
  - **修正例**:
    ```python
    <修正後のコード>
    ```

### Nice（改善提案）
さらに良くするための提案。余裕があれば対応。

- **提案**: <改善提案の説明>
  - **根拠**: <どのように改善されるか>
  - **例**:
    ```python
    <改善例>
    ```
```

### 4. サマリー作成

レビュー完了後、以下のサマリーを提示：

```markdown
## レビューサマリー

- **レビュー対象**: <対象ブランチ/コミット>
- **変更ファイル数**: <N> ファイル
- **指摘事項**:
  - Must: <N> 件
  - Should: <N> 件
  - Nice: <N> 件

### 優先対応事項（Must）
1. <ファイル名>: <問題の要約>
2. ...

### 総評
<全体的な評価とコメント>
```

## チームメイトとして実行される場合

Agent Teams のチームメイトとしてレビューを実行する場合は、レビュー結果を **構造化フォーマット** で `SendMessage` を使ってリーダーに送信してください。

### 構造化出力フォーマット

```markdown
## レビュー結果: <ブランチ名>

### Must（必須対応）
- **ファイル**: `path/to/file.py:行番号`
  - **問題**: <説明>
  - **修正案**: <コード例>

### Should（推奨対応）
- **ファイル**: `path/to/file.py:行番号`
  - **問題**: <説明>
  - **修正案**: <コード例>

### Nice（改善提案）
- **ファイル**: `path/to/file.py:行番号`
  - **提案**: <説明>

### サマリー
- Must: N 件
- Should: N 件
- Nice: N 件
- 総評: <全体的な評価>
```

## 具体例

具体的な違反例・正解例は共通チェックリストの各項目に記載されています。
レビュー時は共通チェックリストの違反例/正解を根拠として指摘してください。

## 参考資料

レビュー時の判断基準として、以下を参照してください：

- [shared/REVIEW_CHECKLIST.md](../shared/REVIEW_CHECKLIST.md) - 共通レビューチェックリスト（**最優先**）
- プロジェクトの開発規約・テスト方針・エラーハンドリング規約（存在する場合）

## 使用方法

### スラッシュコマンドとして実行

```
/code-review
```

### 自然な言葉で依頼

```
このコードをレビューしてください
差分をチェックして
コードレビューお願いします
```

Claude が自動的にこのスキルを使用してレビューを実施します。
