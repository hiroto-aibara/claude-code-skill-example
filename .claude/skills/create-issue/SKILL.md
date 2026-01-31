---
name: create-issue
description: Creates a GitHub Issue based on user's description. Use this to define task requirements before starting work with /start-vk-task.
allowed-tools: mcp__github__create_issue, mcp__github__list_issues, Bash(git remote:*)
---

# Issue Creator

ユーザーの説明を元にGitHub Issueを作成します。

## 概要

このSkillは以下を実行します：

1. ユーザーからタスクの説明を受け取る
2. 要件・受け入れ基準・品質基準を含むIssue本文を生成
3. GitHub Issueとして登録

## 使用方法

```bash
/create-issue
```

### 例

```bash
/create-issue
# ユーザー: "JWTを使った認証機能。ログイン、ログアウト、トークンリフレッシュが必要"
# → GitHub Issue #31 が作成される
```

## 実行手順

### Phase 1: 情報収集

1. ユーザーからタスクの説明を聞き取る
2. 不明点があれば質問して明確化
3. 関連するDesign Docがあれば参照

### Phase 2: Issue内容生成

以下の構成でIssue本文を生成：

```markdown
## 概要
タスクの概要説明

## 要件
- [ ] 要件1
- [ ] 要件2
- [ ] 要件3

## 技術仕様
- 使用技術:
- 関連ファイル:
- API エンドポイント:

## 受け入れ基準
- [ ] 全テストがパス
- [ ] ESLint/Prettier エラーなし
- [ ] コードレビュー完了

## 品質基準
- テストカバレッジ: 80%以上
- パフォーマンス: レスポンス200ms以内
- セキュリティ: 入力バリデーション必須

## 参考リソース
- Design Doc:
- 関連Issue:
```

### Phase 3: Issue作成

1. リポジトリ情報を取得（`git remote get-url origin` から）
2. `mcp__github__create_issue` でIssueを作成
   - `owner`: リポジトリオーナー
   - `repo`: リポジトリ名
   - `title`: タスクのタイトル（Conventional Commits形式推奨）
   - `body`: 上記構成の本文
   - `labels`: 適切なラベル（任意）

### Phase 4: 結果表示

```markdown
## Issue作成完了

| 項目 | 値 |
|------|-----|
| Issue番号 | #31 |
| タイトル | feat(auth): JWT認証機能の実装 |
| URL | https://github.com/owner/repo/issues/31 |

### 次のステップ
ワークスペースを開始するには:
\`\`\`bash
/start-vk-task 31
\`\`\`
```

## タイトル命名規則

Conventional Commits形式を推奨：

| プレフィックス | 用途 |
|---------------|------|
| `feat:` | 新機能 |
| `fix:` | バグ修正 |
| `refactor:` | リファクタリング |
| `perf:` | パフォーマンス改善 |
| `docs:` | ドキュメント |
| `test:` | テスト |
| `chore:` | その他 |

### 例

- `feat(auth): JWT認証機能の実装`
- `fix(api): ユーザー取得時のエラーハンドリング修正`
- `refactor(infra): TYPE_CHECKING ガードで型スタブのインポートを囲む`

## 前提条件

- GitHub MCPサーバーが接続されていること
- リポジトリへの書き込み権限があること

## 関連スキル

- `/start-vk-task` - Issue番号を指定してvibe-kanbanに登録・ワークスペース開始
- `/review-pr` - PRレビュー実行
