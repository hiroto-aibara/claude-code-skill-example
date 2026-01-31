# Claude Code Skills

Claude Codeでプロジェクト立ち上げから設計・タスク管理・並列開発・PR作成までを効率化するスキルセットです。

## スキル一覧

### プロジェクト立ち上げ

新規プロジェクトの初期セットアップに使用するスキル（通常1回のみ実行）。

| スキル | 説明 |
|--------|------|
| [init-project](./.claude/skills/init-project/SKILL.md) | プロジェクト基盤（git, GitHub, mise, husky, dependabot, docs テンプレート） |
| [init-go-backend](./.claude/skills/init-go-backend/SKILL.md) | Go バックエンド（Clean Architecture, golangci-lint, depguard） |
| [init-react-frontend](./.claude/skills/init-react-frontend/SKILL.md) | React フロントエンド（Vite, TypeScript, ESLint, Prettier, dev proxy） |
| [init-serena](./.claude/skills/init-serena/SKILL.md) | Serena MCP（セマンティックコード操作） |

### 開発中

日常の開発サイクルで繰り返し使用するスキル。

#### ドキュメント作成

| スキル | 説明 |
|--------|------|
| [create-feature-brief](./.claude/skills/create-feature-brief/SKILL.md) | Feature Brief（要件定義）を生成 |
| [create-design-doc](./.claude/skills/create-design-doc/SKILL.md) | Design Doc（設計書）を生成 |

#### タスク管理

| スキル | 説明 |
|--------|------|
| [create-issue](./.claude/skills/create-issue/SKILL.md) | GitHub Issueを作成（タスク定義用） |
| [start-vk-task](./.claude/skills/start-vk-task/SKILL.md) | GitHub Issueをvibe-kanbanに登録してワークスペース開始 |
| [create-vk-task](./.claude/skills/create-vk-task/SKILL.md) | vibe-kanban MCPでタスクを直接登録 |

#### PR / レビュー

| スキル | 説明 |
|--------|------|
| [create-pr](./.claude/skills/create-pr/SKILL.md) | PR作成（Issue番号をタイトル/本文に自動追加） |
| [code-review](./.claude/skills/code-review/SKILL.md) | コードレビュー（セルフレビュー用） |
| [review-pr](./.claude/skills/review-pr/SKILL.md) | GitHub PRをレビューしてコメント投稿（Issue受け入れ基準チェック対応） |
| [start-pr-review-task](./.claude/skills/start-pr-review-task/SKILL.md) | PRレビュータスクをvibe-kanbanに登録して開始 |

---

## ワークフロー

### プロジェクト立ち上げフロー

新規プロジェクトを開始する際のフロー。技術スタックに応じて必要なスキルを実行する。

```
/init-project              ← 基盤作成（git, GitHub, tooling）
      ↓
/init-go-backend           ← Go バックエンド追加（任意）
      ↓
/init-react-frontend       ← React フロントエンド追加（任意）
      ↓
/init-serena               ← Serena MCP追加（任意）
```

```mermaid
flowchart TD
    A["/init-project"]
    B["/init-go-backend"]
    C["/init-react-frontend"]
    D["/init-serena"]

    A --> B
    A --> C
    A --> D
```

### 開発フロー

#### ドキュメント作成フロー

Feature Brief → Design Doc の構造でドキュメントを管理する。
タスクはGitHub Issueとして作成し、vibe-kanbanで管理する。

```
/create-feature-brief → docs/<name>-brief.md（なぜ・何を）
      ↓
/create-design-doc → docs/<name>-design.md（どうやって）
      ↓
/create-issue → GitHub Issue（タスク定義・受け入れ基準）
```

```mermaid
flowchart TD
    subgraph Documents["ドキュメント作成"]
        A["/create-feature-brief で要件定義"]
        B["/create-design-doc で設計書作成"]
        C["/create-issue でGitHub Issue作成"]
        A --> B --> C
    end
```

#### 実装フロー（GitHub Issue + vibe-kanban連携）

GitHub IssueとVibe-kanbanを連携したタスク管理フロー。

```
GitHub Issue作成 → /start-vk-task <issue-number>
      ↓
ワークスペース作成（自動でworktree + ブランチ作成）
      ↓
開発 → /code-review → /create-pr → タスクステータス更新
```

```mermaid
flowchart TD
    subgraph IssueManagement["Issue管理"]
        A["GitHub Issueを作成"]
        B["/start-vk-task でvibe-kanbanに登録"]
        C["ワークスペース自動作成"]
        A --> B --> C
    end

    subgraph Implementation["実装"]
        D["ワークスペースで開発"]
        E["コミット"]
        D --> E
    end

    subgraph Completion["完了処理"]
        F["/code-review でセルフレビュー"]
        G["指摘事項を修正"]
        H["/create-pr でPR作成（Closes #issue-number）"]
        I["タスクステータスを inreview に更新"]
        F --> G --> H --> I
    end

    C --> D
    E --> F
```

---

## 役割と責務

| 役割 | 責務 |
|------|------|
| **オーケストレーター** | 設計・タスク分割・ワークスペース作成・レビュー・クリーンアップ |
| **実装者** | ワークスペース内での開発・PR作成 |

---

## 使い方

### プロジェクト立ち上げ

```bash
# 1. プロジェクト基盤
/init-project
# → git init, GitHub repo, mise.toml, docs/, husky, dependabot

# 2. Go バックエンド（必要な場合）
/init-go-backend
# → go.mod, Clean Architecture layers, golangci-lint

# 3. React フロントエンド（必要な場合）
/init-react-frontend
# → Vite + React + TypeScript, ESLint, Prettier, dev proxy

# 4. Serena MCP（必要な場合）
/init-serena
# → Serena MCP設定, .gitignore更新
```

### ドキュメント作成

```bash
# 1. Feature Brief 作成
/create-feature-brief user-auth
# → docs/user-auth-brief.md（なぜ・何を）

# 2. Design Doc 作成
/create-design-doc user-auth
# → docs/user-auth-design.md（どうやって）

# 3. GitHub Issue作成
/create-issue
# → GitHub Issue #30（タスク定義・受け入れ基準）
```

### GitHub Issue + vibe-kanban連携

```bash
# 1. GitHub Issueを作成（GitHub UI または gh CLI）
gh issue create --title "feat: Add user authentication" --body "..."
# → Issue #30 が作成される

# 2. Issue番号を指定してvibe-kanbanに登録 + ワークスペース開始
/start-vk-task 30
# → vibe-kanbanにタスク登録（タイトル: #30 feat: Add user authentication）
# → worktree + ブランチが自動作成される

# 3. 完了処理
/code-review
/create-pr
# → PRの説明に "Closes #30" を含める
# → タスクステータスを inreview に更新
```

### PRレビュー

```bash
# 基本的なレビュー
/review-pr 123
# または
/review-pr https://github.com/owner/repo/pull/123

# Issue番号を指定して受け入れ基準チェック付きレビュー
/review-pr 123 --issue 30
# → PRタイトルに #30 が含まれていれば自動取得される

# → Approve / Request Changes / Comment を選択してGitHubに投稿
```

### PRレビュータスク登録（vibe-kanban連携）

```bash
# PR番号を指定してレビュータスクを登録
/start-pr-review-task 123
# → vibe-kanbanにタスク登録
# → PRタイトルからIssue番号を自動抽出
# → ワークスペースセッション開始

# PR番号未指定の場合、Open PR一覧から選択
/start-pr-review-task
```

---

## 他プロジェクトへの導入

### ディレクトリ構成

```
.claude/
├── skill-source/          ← submodule（このリポジトリ）
│   └── .claude/skills/
│       ├── init-project/
│       ├── init-go-backend/
│       ├── create-pr/
│       └── ...
└── skills/                ← 実際に使用するスキル（コミット対象）
    ├── init-project/      ← skill-sourceからコピー
    ├── create-pr/         ← skill-sourceからコピー
    └── my-custom-skill/   ← プロジェクト固有のスキル
```

### 1. Submoduleとして追加

```bash
git submodule add https://github.com/boost-consulting/claude-code-skill-example-aibara .claude/skill-source
```

### 2. 必要なスキルをコピー

```bash
# 使いたいスキルを .claude/skills/ にコピー
cp -r .claude/skill-source/.claude/skills/init-project .claude/skills/
cp -r .claude/skill-source/.claude/skills/create-pr .claude/skills/

git add .claude/skills/
git commit -m "add skills from skill-source"
```

**ポイント:**
- `.claude/skill-source/` はスキルとして認識されない
- 使いたいスキルだけを `.claude/skills/` にコピー
- プロジェクト固有のスキルは `.claude/skills/` に直接配置可能

---

## スキル改善のフィードバック（PR手順）

他プロジェクトでスキルを改善した場合のPR手順。

### 1. skill-source内で編集・コミット

```bash
cd .claude/skill-source
git checkout -b improve/create-pr-enhancement
# ファイルを編集...
git add .
git commit -m "feat(create-pr): add support for draft PR"
```

### 2. PRを作成

```bash
git push origin improve/create-pr-enhancement
# GitHub上でPRを作成
```

### 3. マージ後、プロジェクトに同期

```bash
cd .claude/skill-source
git checkout main && git pull
cd ../..

cp -r .claude/skill-source/.claude/skills/create-pr .claude/skills/

git add .claude/skills/ .claude/skill-source
git commit -m "sync: update create-pr skill"
```

---

