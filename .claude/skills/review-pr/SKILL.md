---
name: review-pr
description: Review a GitHub PR and post comments. Analyzes code quality, bugs, security, and performance. User chooses final action (Approve/Request Changes/Comment).
allowed-tools: Bash(gh:*), Bash(git:*), Bash(jq:*), Bash(pytest:*), Bash(mypy:*), Bash(ruff:*), Bash(black:*), Bash(npm:*), Read, Grep, Glob, AskUserQuestion, mcp__github__get_pull_request, mcp__github__get_pull_request_files, mcp__github__get_pull_request_diff, mcp__github__create_and_submit_pull_request_review
---

# PR Reviewer

GitHub PRを段階的にレビューし、コメントを投稿します。

## 概要

このスキルは**段階的アプローチ**でPRをレビューします：

```
Phase 0: タスクファイル確認【任意】
   - タスクファイルの有無を確認
   - あれば受け入れ基準チェック用に読み込み
        ↓
Phase 1: 全体像把握
   - PR基本情報・変更ファイル一覧を取得
        ↓
Phase 2: 優先度判定
   - セキュリティ > API > Domain > Infra > UI > Tests
        ↓
Phase 2.5: 受け入れ基準チェック【任意】
   - タスクファイル指定時のみ実行
   - pytest, mypy, ruff等を実行してチェック
        ↓
Phase 3: 詳細レビュー
   - 優先度高のファイルから個別にdiff確認
        ↓
Phase 4: レビュー結果整理
   - Critical/Warning/Suggestion に分類
        ↓
Phase 5: ユーザー確認・投稿
   - Approve / Request Changes / Comment
```

## 使用方法

### 基本

```bash
/review-pr 123
/review-pr https://github.com/owner/repo/pull/123
```

### タスクファイル付き（受け入れ基準チェック）

```bash
/review-pr 123 tasks/feature-user-auth.md
```

### 別リポジトリ

```bash
/review-pr owner/repo#123
```

## 各フェーズの概要

### Phase 0: タスクファイル確認

タスクファイルが引数で指定されていない場合、`AskUserQuestion` でユーザーに確認：
- **あり** → パスを入力
- **なし** → Phase 1 へ

### Phase 1: 全体像把握

| 取得情報 | 内容 |
|---------|------|
| PR基本情報 | タイトル、説明、作成者、ブランチ、マージ可能状態 |
| 変更ファイル一覧 | ファイルパス、追加/削除行数 |

### Phase 2: 優先度判定

| 優先度 | 対象 |
|--------|------|
| 🔴 最高 | セキュリティ関連（auth, jwt, password, secret等） |
| 🟠 高 | API/エンドポイント |
| 🟡 中 | Domain/Application層 |
| 🟢 低 | Infrastructure層 |
| 🔵 通常 | フロントエンド |
| ⚪ 最低 | テスト/設定ファイル |

### Phase 2.5: 受け入れ基準チェック（タスクファイル指定時のみ）

タスクファイルの「## 受け入れ基準」をチェック：

| 基準タイプ | 判定方法 |
|-----------|---------|
| テスト | `pytest` 実行 |
| 型チェック | `mypy` 実行 |
| Lint | `ruff`, `black` 実行 |
| フロントエンド | `npm run lint/test` 実行 |
| 定性的基準 | PR内容と照合 |

### Phase 3: 詳細レビュー

優先度順に個別diffを取得し、4観点でチェック：
1. **コード品質**: 可読性、保守性、設計
2. **バグ/ロジック**: 境界値、null処理、非同期
3. **セキュリティ**: インジェクション、認証認可、機密情報
4. **パフォーマンス**: N+1、不要ループ、メモリ

**早期終了**: Critical問題が3つ以上 → Phase 4 へ

### Phase 4: レビュー結果整理

```markdown
## PR Review: #123 - PRタイトル

### 📋 概要
| 項目 | 内容 |
|------|------|
| 変更ファイル数 | 15 files |
| 追加/削除 | +500 / -100 |
| タスクファイル | tasks/xxx.md / なし |

### 📋 受け入れ基準チェック（指定時のみ）
| 基準 | 結果 |
|------|------|
| pytest | ✅ PASS |
| mypy | ❌ FAIL |

### 🔍 レビュー結果
#### 🔴 Critical / 🟡 Warning / 🔵 Suggestion

### 📊 総合評価
**推奨アクション**: Approve / Request Changes / Comment
```

### Phase 5: ユーザー確認・投稿

| アクション | 条件 |
|------------|------|
| **Approve** | Critical なし、Warning 軽微 |
| **Request Changes** | Critical 1つ以上、またはセキュリティ懸念 |
| **Comment** | 判断に迷う、追加議論が必要 |

## 前提条件

- `gh` CLI がインストール・認証済み
- PRの読み取り権限があること

## 関連スキル

- `/create-pr` - PR作成
- `/cleanup-worktree` - worktree削除
- `/start-pr-review-task` - PRレビュータスクの登録・開始（vibe-kanban連携）
- `/create-task` - タスクファイル作成

## 詳細

コマンド例、チェックリスト、テンプレートは [REFERENCE.md](REFERENCE.md) を参照。
