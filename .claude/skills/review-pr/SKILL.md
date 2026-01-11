---
name: review-pr
description: Review a GitHub PR and post comments. Analyzes code quality, bugs, security, and performance. User chooses final action (Approve/Request Changes/Comment).
allowed-tools: Bash(gh:*), Bash(git:*), Read, Grep, Glob
---

# PR Reviewer

GitHub PRをレビューし、コメントを投稿します。

## 概要

このスキルは以下を実行します：

1. PR番号またはURLからPR情報を取得
2. 変更内容を分析（diff、変更ファイル、PR説明）
3. 以下の観点でレビュー：
   - コード品質（可読性、保守性、設計パターン）
   - バグ/ロジックエラー
   - セキュリティ（脆弱性、機密情報の漏洩）
   - パフォーマンス（N+1問題、不要なループなど）
4. レビュー結果をユーザーに提示
5. ユーザーがアクション選択（Approve / Request Changes / Comment）
6. GitHub PRにレビューを投稿

## 使用方法

### 基本的な使い方

```bash
# PR番号で指定
/review-pr 123

# PR URLで指定
/review-pr https://github.com/owner/repo/pull/123
```

### owner/repoを明示的に指定

```bash
# 別リポジトリのPRをレビュー
/review-pr owner/repo#123
```

## レビュー観点

### 1. コード品質
- 可読性（命名、コメント、構造）
- 保守性（関心の分離、DRY原則）
- 設計パターンの適切な使用
- テストの有無と品質

### 2. バグ/ロジックエラー
- 境界値処理
- null/undefined チェック
- 非同期処理のエラーハンドリング
- 型の不整合

### 3. セキュリティ
- インジェクション脆弱性（SQL, XSS, Command）
- 認証・認可の問題
- 機密情報のハードコード
- 安全でない依存関係

### 4. パフォーマンス
- N+1クエリ問題
- 不要なループ・再計算
- メモリリーク
- 非効率なアルゴリズム

## レビュー結果の構造

```markdown
## PR Review: #123 - PRタイトル

### 概要
変更の全体的な評価と概要

### 問題点

#### 🔴 Critical（修正必須）
- セキュリティ問題
- 重大なバグ

#### 🟡 Warning（要検討）
- 潜在的な問題
- パフォーマンス懸念

#### 🔵 Suggestion（提案）
- コード品質の改善
- ベストプラクティス

### 良い点
- 評価できる実装

### 推奨アクション
- [ ] Approve（承認）
- [ ] Request Changes（変更要求）
- [ ] Comment（コメントのみ）
```

## 実行フロー

```
1. PR情報取得
   $ gh pr view <number> --json title,body,files,additions,deletions
   $ gh pr diff <number>

2. コード分析
   - diff を読み込み
   - 変更ファイルを確認
   - 関連コードを必要に応じて読み込み

3. レビュー実施
   - 4つの観点で分析
   - 問題点・良い点をリストアップ

4. ユーザー確認
   - レビュー結果を表示
   - アクションを選択してもらう

5. レビュー投稿
   $ gh pr review <number> --body <review> [--approve|--request-changes|--comment]
```

## Request Changes 時の投稿オプション

Request Changesを選択した場合、以下の投稿方法を選択できます：

### 1. 通常のRequest Changes

レビューコメントのみを投稿します。修正作業は別途行います。

### 2. @claude 付きRequest Changes

GitHub Actionで自動修正させる場合、レビューコメントに `@claude` メンションを含めて投稿します。

```markdown
@claude 以下の修正をお願いします:
- XXXのバリデーションを追加
- エラーハンドリングを改善
```

**前提条件**: Claude Code GitHub Actionがリポジトリに設定済みであること

## 前提条件

- `gh` CLI がインストール・認証済みであること
- PRの読み取り権限があること

## 注意事項

- 最終的なApprove/Request Changesの判断はユーザーが行います
- 機密情報を含むPRは慎重に扱ってください
- 大規模な変更（100ファイル超）は分割レビューを検討してください

## 関連スキル

- `create-pr`: PR作成
- `cleanup-worktree`: worktree削除
- `create-worktree`: worktree作成

## 詳細

詳細については [REFERENCE.md](REFERENCE.md) を参照してください。
