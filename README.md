# Claude Code Skills

Claude Codeでプロジェクト立ち上げから設計・並列実装・レビュー・PR作成までを効率化するスキルセットです。

## スキル一覧

### プロジェクト立ち上げ

新規プロジェクトの初期セットアップに使用するスキル（通常1回のみ実行）。

| スキル | 説明 |
|--------|------|
| [create-product-concept](./.claude/skills/create-product-concept/SKILL.md) | プロダクトコンセプト（ビジョン・ターゲット・MVP・技術スタック） |
| [init-project](./.claude/skills/init-project/SKILL.md) | プロジェクト基盤（git, GitHub, mise, husky, dependabot, docs テンプレート） |
| [init-go-backend](./.claude/skills/init-go-backend/SKILL.md) | Go バックエンド（Clean Architecture, golangci-lint, depguard） |
| [init-go-api](./.claude/skills/init-go-api/SKILL.md) | Web API インフラコード生成（middleware, response helpers, domain errors, main.go） |
| [init-react-frontend](./.claude/skills/init-react-frontend/SKILL.md) | React フロントエンド（Vite, TypeScript, ESLint, Prettier, dev proxy） |
| [init-nextjs-frontend](./.claude/skills/init-nextjs-frontend/SKILL.md) | Next.js フロントエンド |
| [init-react-native](./.claude/skills/init-react-native/SKILL.md) | React Native（Expo, TypeScript, Expo Router, ESLint, Prettier） |
| [init-serena](./.claude/skills/init-serena/SKILL.md) | Serena MCP（セマンティックコード操作） |

### 開発中

日常の開発サイクルで繰り返し使用するスキル。

#### ドキュメント作成

| スキル | 説明 |
|--------|------|
| [create-feature-brief](./.claude/skills/create-feature-brief/SKILL.md) | Feature Brief（要件定義）を生成 |
| [create-design-doc](./.claude/skills/create-design-doc/SKILL.md) | Design Doc（設計書）を生成 |
| [create-issue](./.claude/skills/create-issue/SKILL.md) | GitHub Issueを作成（タスク定義・受け入れ基準） |

#### Docker + 並列実装

| スキル | 説明 |
|--------|------|
| [setup-docker](./.claude/skills/setup-docker/SKILL.md) | Docker 開発環境のセットアップ（Dockerfile, docker-compose, ネットワーク, mise） |
| [launch-workers](./.claude/skills/launch-workers/SKILL.md) | Open Issueから最大4件を選定し、常駐worktree上でtmux並列ワーカーを起動 |
| [start-implementation](./.claude/skills/start-implementation/SKILL.md) | Issue番号を指定してPlan策定・実装・テスト・レビュー・コミットを自律実行（各ワーカーが実行） |

#### ブランチ管理

| スキル | 説明 |
|--------|------|
| [finalize-worktree](./.claude/skills/finalize-worktree/SKILL.md) | mainマージ → コードレビュー委譲 → 修正 → PR作成 |
| [delegate-code-review](./.claude/skills/delegate-code-review/SKILL.md) | コードレビューをチームメイトに委譲（内部スキル） |

#### PR / レビュー

| スキル | 説明 |
|--------|------|
| [create-pr](./.claude/skills/create-pr/SKILL.md) | PR作成（Issue番号をタイトル/本文に自動追加） |
| [code-review](./.claude/skills/code-review/SKILL.md) | コードレビュー（セルフレビュー / チームメイト委譲対応） |
| [review-pr](./.claude/skills/review-pr/SKILL.md) | GitHub PRをレビューしてコメント投稿（Issue受け入れ基準チェック対応） |

#### 共通

| スキル | 説明 |
|--------|------|
| [shared/REVIEW_CHECKLIST_COMMON.md](./.claude/skills/shared/REVIEW_CHECKLIST_COMMON.md) | 共通レビューチェックリスト（セキュリティ、パフォーマンス、Git、ドキュメント） |
| [shared/REVIEW_CHECKLIST_BACKEND.md](./.claude/skills/shared/REVIEW_CHECKLIST_BACKEND.md) | バックエンドレビューチェックリスト（アーキテクチャ、エラー、テスト、ログ、DB） |
| [shared/REVIEW_CHECKLIST_FRONTEND.md](./.claude/skills/shared/REVIEW_CHECKLIST_FRONTEND.md) | フロントエンドレビューチェックリスト（ルーティング、状態管理、i18n、UX） |
| [generate-review-checklist](./.claude/skills/generate-review-checklist/SKILL.md) | プロジェクト固有のレビューチェックリストを生成・更新 |

#### タスク管理（vibe-kanban連携）

vibe-kanban MCP を使用する場合のスキル。

| スキル | 説明 |
|--------|------|
| [[legacy]start-vk-task](./.claude/skills/%5Blegacy%5Dstart-vk-task/SKILL.md) | GitHub Issueをvibe-kanbanに登録してワークスペース開始 |
| [[legacy]start-pr-review-task](./.claude/skills/%5Blegacy%5Dstart-pr-review-task/SKILL.md) | PRレビュータスクをvibe-kanbanに登録して開始 |

---

## ワークフロー

### プロジェクト立ち上げフロー

新規プロジェクトを開始する際のフロー。技術スタックに応じて必要なスキルを実行する。

```
/init-project              <- 基盤作成（/create-product-concept → git, GitHub, tooling）
      |
/init-go-backend           <- Go バックエンド追加（任意）
      |
/init-go-api               <- Web API インフラコード追加（init-go-backend 後）
      |
/init-react-frontend       <- React フロントエンド追加（任意）
      |
/init-react-native         <- React Native (Expo) 追加（任意）
      |
/init-serena               <- Serena MCP追加（任意）
```

### ドキュメント作成フロー

Feature Brief -> Design Doc -> GitHub Issue の構造でドキュメントを管理する。

```
/create-feature-brief -> docs/<name>-brief.md（なぜ・何を）
      |
/create-design-doc -> docs/<name>-design.md（どうやって）
      |
/create-issue -> GitHub Issue（タスク定義・受け入れ基準）
```

### Docker 並列実装フロー

Dockerコンテナ内で常駐worktreeを使い、複数のGitHub Issueを並列に実装するフロー。
worktreeは事前に作成済みの常駐プールとして運用し、タスク完了後も削除せず再利用する。

```
/setup-docker                    <- 初回のみ: Docker環境 + ネットワーク + mise構成
      |
docker compose up -d             <- dev stack 起動（DB等。ネットワーク疎通に必要）
      |
/create-issue                    <- 実装対象のGitHub Issueを作成
      |
/launch-workers #101 #102        <- Issue選定 → worktree同期 → tmux並列ワーカー起動
                                      各ワーカーが /start-implementation を実行
                                      実装・テスト・レビュー・コミットまで自律完結
```

```mermaid
flowchart TD
    subgraph Setup["初回セットアップ"]
        A["/setup-docker"]
    end

    subgraph Issues["Issue作成"]
        A2["/create-issue x N"]
    end

    subgraph Workers["並列実装（常駐worktree）"]
        B["/launch-workers #101 #102"]
        C1["wt1: /start-implementation #101"]
        C2["wt2: /start-implementation #102"]
        B --> C1 & C2
    end

    A --> A2
    A2 --> B
```

### 役割と責務

| 役割 | 責務 |
|------|------|
| **リーダー（メインエージェント）** | 設計・タスク分割・Issue作成・ワーカー起動 |
| **ワーカー（各worktree）** | `/start-implementation` による実装・テスト・レビュー・コミットを自律実行 |

---

## 使い方

### プロジェクト立ち上げ

```bash
# 1. プロジェクト基盤（最初に /create-product-concept でコンセプト整理）
/init-project
# -> docs/product-concept.md, git init, GitHub repo, mise.toml, docs/, husky, dependabot

# 2. Go バックエンド（必要な場合）
/init-go-backend
# -> go.mod, Clean Architecture layers, golangci-lint

# 3. Web API インフラコード（init-go-backend 後）
/init-go-api
# -> middleware, response helpers, domain errors, main.go with graceful shutdown

# 4. React フロントエンド（必要な場合）
/init-react-frontend
# -> Vite + React + TypeScript, ESLint, Prettier, dev proxy

# 5. React Native（必要な場合）
/init-react-native
# -> Expo + TypeScript, Expo Router, ESLint, Prettier

# 6. Serena MCP（必要な場合）
/init-serena
# -> Serena MCP設定, .gitignore更新
```

### ドキュメント作成

```bash
# 1. Feature Brief 作成
/create-feature-brief user-auth
# -> docs/user-auth-brief.md（なぜ・何を）

# 2. Design Doc 作成
/create-design-doc user-auth
# -> docs/user-auth-design.md（どうやって）

# 3. GitHub Issue作成
/create-issue
# -> GitHub Issue #30（タスク定義・受け入れ基準）
```

### Docker 並列実装

```bash
# 1. Docker環境セットアップ（初回のみ）
/setup-docker
# -> .claude-docker/, .mise.toml検証, worktrees/, Dockerイメージビルド

# 2. dev stack を起動（DB等が必要な場合）
docker compose up -d
# -> {project-name}_default ネットワーク作成。コンテナ内からサービス名でアクセス可能

# 3. コンテナを起動してClaude Codeに接続
.claude-docker/scripts/start.sh
# -> GH_TOKEN自動管理, ネットワーク疎通チェック, mise install

# 4. コンテナ内でIssueを並列実装（常駐worktree上）
/launch-workers #101 #102
# -> Issue選定 → worktree同期 → tmux並列ワーカー起動
# -> 各ワーカーが /start-implementation を自動実行（実装・テスト・レビュー・コミットまで自律完結）
```

### PRレビュー

```bash
# 基本的なレビュー
/review-pr 123

# Issue番号を指定して受け入れ基準チェック付きレビュー
/review-pr 123 --issue 30
# -> PRタイトルに #30 が含まれていれば自動取得

# -> Approve / Request Changes / Comment を選択してGitHubに投稿
```

---

## 他プロジェクトへの導入

### ディレクトリ構成

```
.claude/
├── skill-source/          <- submodule（このリポジトリ）
│   └── .claude/skills/
│       ├── setup-docker/
│       ├── launch-workers/
│       ├── create-pr/
│       └── ...
└── skills/                <- 実際に使用するスキル（コミット対象）
    ├── setup-docker/      <- skill-sourceからコピー
    ├── launch-workers/    <- skill-sourceからコピー
    └── my-custom-skill/   <- プロジェクト固有のスキル
```

### 1. Submoduleとして追加

```bash
git submodule add https://github.com/boost-consulting/claude-code-skill-example-aibara .claude/skill-source
```

### 2. 必要なスキルをコピー

```bash
# 使いたいスキルを .claude/skills/ にコピー
cp -r .claude/skill-source/.claude/skills/setup-docker .claude/skills/
cp -r .claude/skill-source/.claude/skills/launch-workers .claude/skills/
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
