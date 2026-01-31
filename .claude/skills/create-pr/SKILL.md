---
name: create-pr
description: Creates a PR from the current branch without deleting the worktree. Use this when you want to keep the worktree for local modifications.
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cd:*), Bash(pwd:*), Read, mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, AskUserQuestion
---

# Create PR

現在のブランチからPRを作成します。

## 概要

このスキルは以下のワークフローを実行します：

```
1. 環境検証（bash）
   - worktree/ブランチ検出
   - 未コミット変更チェック
   - 未プッシュコミット → 自動push
        ↓
2. Issue番号の取得
   - vibe-kanban タスクタイトルから抽出（#30 feat: ... 形式）
   - またはブランチ名から抽出（issue-30-xxx, 30-xxx 等）
   - 取得できない場合はユーザーに確認
        ↓
3. 情報収集・構造化（bash）【Token節約】
   - レイヤー別変更ファイル集計
   - コミットログ要約
   - Issue本文から概要・受け入れ基準を参照（任意）
   → 構造化情報を出力
        ↓
4. PR本文生成（Claude Code）
   - 構造化情報のみを入力として受け取る
   - テンプレートに沿って本文生成
   - 「Closes #<issue-number>」を追加
        ↓
5. PR作成（bash）
   - gh pr create 実行（タイトルにIssue番号を含む）
   - PR URL返却
```

## 使用方法

### 基本的な使い方

```bash
# worktreeディレクトリ内で実行
cd .worktrees/<feature-name>
/create-pr
```

### オプション

```bash
# タイトルと本文を事前指定
/create-pr --title "feat: Add new feature" --body "詳細な説明..."

# Issue番号を明示指定
/create-pr --issue 30

# ドラフトPRとして作成
/create-pr --draft

# ベースブランチを指定
/create-pr --base develop
```

---

## PR本文の書き方ガイド

### 必須セクション

#### 1. Summary（1-3行）

変更の目的と効果を簡潔に記述。

**良い例:**
> オンボーディング案件の一覧・詳細取得APIを実装し、フロントエンドをAPI経由のデータ取得に移行。
> これによりページリロード後もデータが保持されるようになる。

**悪い例:**
> APIを追加しました。

#### 2. 変更内容（レイヤー別）

変更をレイヤー別に整理し、各変更の具体的な内容を記述。

**良い例:**
```markdown
### Backend
- **Domain層**: `OnboardingRepository` に `list_all()`, `count_all()` 追加
- **Infrastructure層**: DynamoDB Scan実装（将来的にGSI移行予定）
- **Application層**: `GetOnboardingUseCase`, `ListOnboardingsUseCase` 実装
- **API層**: `GET /onboardings`, `GET /onboardings/{id}` エンドポイント追加

### Frontend
- APIクライアント関数追加（`getOnboarding`, `listOnboardings`）
- OnboardingListPage/DetailPage をAPI経由に移行
- Zustandストアからの依存を削除
```

**悪い例:**
```markdown
- ファイルを追加
- 修正
- テスト追加
```

#### 3. Test plan

検証方法をチェックリスト形式で記述。

**良い例:**
```markdown
- [ ] `pytest tests/application/` - UseCase単体テスト
- [ ] `pytest tests/api/` - API統合テスト
- [ ] `ruff check && mypy` - Lintエラーなし
- [ ] フロントエンドで一覧・詳細画面が表示される
- [ ] ページリロード後もデータが保持される
```

### GitHub Issueとの連携

関連するGitHub Issueがある場合：
- **Issue本文の概要** → Summary の素材
- **Issue本文の受け入れ基準** → Test plan のベース
- **PRタイトル** に `#<issue-number>` を含める
- **PR本文** に `Closes #<issue-number>` を追加（マージ時にIssue自動クローズ）

#### Issue番号の取得優先順位

1. **vibe-kanban タスクタイトル** から抽出（`#30 feat: ...` 形式）
2. **ブランチ名** から抽出（`issue-30-xxx`、`30-feature-xxx` 等）
3. **ユーザーに確認** - 上記で取得できない場合は `AskUserQuestion` で問い合わせ

---

## 前提条件

- worktreeディレクトリ内で実行すること
- すべての変更がコミット済みであること
- `gh` CLI がインストール・認証済みであること

## 実行例

```bash
$ cd .worktrees/user-auth
$ /create-pr

[INFO] Current branch: feature/user-auth
[INFO] Base branch: main
[INFO] Issue number: #30 (from vibe-kanban task title)
[STEP] Analyzing changes...

### 変更ファイル分析

**Backend:**
- Domain層: 1ファイル
- Application層: 2ファイル
- Infrastructure層: 1ファイル
- API層: 1ファイル

**Frontend:**
- 4ファイル変更

**テスト:**
- 6ファイル追加

### Issue #30 情報
- Summary候補: ユーザー認証機能を実装...
- Test plan候補: 全テストがパス, ESLintエラーなし...

[STEP] Creating pull request...
[INFO] PR title: #30 feat: Add user authentication
[INFO] PR body includes: Closes #30
[INFO] PR created: https://github.com/user/repo/pull/123
```

## 関連スキル

- `cleanup-worktree`: worktree削除
- `review-pr`: PRレビュー
- `create-worktree`: worktree作成
- `create-issue`: GitHub Issue作成
- `start-vk-task`: Issue登録・ワークスペース開始

## 詳細

詳細については [REFERENCE.md](REFERENCE.md) を参照してください。
