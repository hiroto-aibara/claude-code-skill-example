---
name: create-issue
description: Creates a GitHub Issue based on user's description. Use this to define task requirements before starting work with /dispatch-worktrees.
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

[TEMPLATE.md](TEMPLATE.md) のフォーマットに従ってIssue本文を生成する。主要セクション：

1. **概要** — タスクの概要を1-2文で
2. **フロー** — 処理フローを矢印で表現
3. **実装ファイル一覧** — 変更対象をレイヤー/カテゴリごとに整理
4. **実装順序** — 依存関係を考慮した順序
5. **状態遷移ルール** — 該当する場合
6. **設計判断** — 重要な設計上の判断事項と理由
7. **後続機能との整合性** — 関連する既存/将来機能との整合
8. **受け入れ基準** — Issue 完了の判定チェックリスト（**最重要セクション**）
9. **テスト計画** — テストファイル・正常系/異常系・手動確認項目
10. **完了時の手順** — 受け入れ基準チェック → `/code-review` → `/create-pr` → ステータス更新

#### 受け入れ基準の記述ルール

受け入れ基準は Issue の品質を担保する最重要セクション。以下を厳守すること：

- **チェックボックス形式** (`- [ ]`) で記載する
- **具体的・検証可能**: yes/no で判定できる表現にする。曖昧な表現（「適切に」「正しく」のみ）は避け、何をもって正しいとするかを明記する
- **検証方法を併記**: 自明でない場合は括弧で補足（例: 「PHPUnit テストが通ること」「`curl localhost:8000/health` で HTTP 200」）
- **サブ機能ごとにグループ化**: 複数の機能を含む Issue は見出しで分ける
- **数値・固有名を含める**: 「主要テーブル」ではなく「全20テーブル」、「認証が通る」ではなく「管理者・一般ユーザーの2種で認証が通る」のように定量化する

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
worktreeを作成して実装を開始するには:
\`\`\`bash
/dispatch-worktrees #31
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

- `/code-review` - セルフレビュー実行（完了時の手順で使用）
- `/create-pr` - PR作成（完了時の手順で使用）
- `/review-pr` - PRレビュー実行
