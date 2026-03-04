---
name: setup-docker
description: Docker 開発環境のセットアップ。Dockerfile・docker-compose.yml・スクリプトの検証・作成、worktrees ディレクトリ準備、Docker イメージビルドを実行する。
allowed-tools: Bash(docker:*), Bash(docker-compose:*), Bash(mkdir:*), Bash(chmod:*), Bash(ls:*), Bash(git:*), Bash(cp:*), Read, Write, Glob
user-invocable: true
---

# Setup Docker

Docker ベースの Claude Code 開発環境をセットアップします。

## 概要

```
1. 前提チェック
   - Docker Desktop が起動しているか
   - プロジェクトルートにいるか
        ↓
2. .mise.toml の検証・作成
   - 存在しない場合 → 新規作成
   - 存在する場合 → 必須項目の十分性を確認し、不足があれば修正
        ↓
3. .claude-docker/ ファイル検証・作成
   - .project, Dockerfile, docker-compose.yml (TEMPLATE.md から)
   - scripts/start.sh, scripts/stop.sh, .tmux.conf, .dockerignore (Skill フォルダからコピー)
        ↓
4. .gitignore 更新
   - worktrees/* 追加（未追加の場合）
   - .claude-docker/.env 追加（未追加の場合）
        ↓
5. worktrees ディレクトリ準備
   - worktrees/ 作成 + .gitkeep
        ↓
6. Docker イメージビルド
   - docker compose -f .claude-docker/docker-compose.yml build
        ↓
7. 次のステップ案内
   - dev stack 起動推奨
   - start.sh による起動手順
```

## 前提条件

- Docker Desktop がインストール・起動済み
- プロジェクトルートで実行すること

## フロー詳細

### 1. 前提チェック

```bash
# Docker が起動しているか
docker info > /dev/null 2>&1

# プロジェクトルートかどうか（.git が存在するか）
git rev-parse --show-toplevel
```

### 2. .mise.toml の検証・作成

`.mise.toml` はコンテナ内のランタイム管理と worktree セットアップ（`mise run setup`）の基盤となる。

#### 存在しない場合

プロジェクトの構成（使用言語、ディレクトリ構成、依存管理ファイル）を分析し、新規作成する。
最低限以下を満たすこと:

- `[tools]` にプロジェクトで使用するランタイムが定義されている
- `[tasks.setup]` で worktree の依存セットアップが一括実行できる

#### 存在する場合

以下の観点で十分性を確認し、不足があればユーザーに提示して修正する:

| 確認項目 | 内容 |
|---------|------|
| `[tools]` | プロジェクトで使用するランタイム（node, python, go, rust 等）が定義されているか |
| `[tasks.setup]` | `mise run setup` で worktree の依存セットアップが完結するか |
| サブタスク | 各アプリケーションディレクトリ（frontend, backend 等）のセットアップタスクがあるか |
| `[tasks."setup:env"]` | worktree への .env コピータスクがあるか（推奨。worktree 環境で .env が必要な場合） |

不足項目がある場合は追加内容をユーザーに提示し、承認を得てから修正する。

### 3. .claude-docker/ ファイル検証・作成

以下のファイルが存在するか確認し、なければ作成する。
既に存在する場合はスキップし、上書きしない。

#### TEMPLATE.md からカスタマイズして作成（プレースホルダ置換が必要）

- `.claude-docker/.project` — プロジェクト名を記入
- `.claude-docker/Dockerfile` — `{git-user-name}`, `{git-user-email}` を置換、必要なパッケージ・ランタイムをカスタマイズ
- `.claude-docker/docker-compose.yml` — `{project-name}` を置換

プレースホルダの一覧と詳細は [TEMPLATE.md](TEMPLATE.md) を参照。

#### Skill フォルダからコピー（そのまま使える）

以下のファイルはこの Skill フォルダに実ファイルとして配置されている。`.claude-docker/` にコピーする。

| コピー元（Skill フォルダ） | コピー先 |
|---|---|
| `setup-docker/scripts/start.sh` | `.claude-docker/scripts/start.sh` |
| `setup-docker/scripts/stop.sh` | `.claude-docker/scripts/stop.sh` |
| `setup-docker/.tmux.conf` | `.claude-docker/.tmux.conf` |
| `setup-docker/.dockerignore` | `.claude-docker/.dockerignore` |

コピー後、スクリプトに実行権限を付与する:
```bash
chmod +x .claude-docker/scripts/start.sh .claude-docker/scripts/stop.sh
```

#### 自動生成ファイル（スキルでは作成しない）

- `.claude-docker/.env` — `start.sh` が `GH_TOKEN` 等を書き込む。Step 4 で `.gitignore` に追加必須

### 4. .gitignore 更新

`.gitignore` に以下が含まれていなければ追加:

```
worktrees/*
!worktrees/.gitkeep
.claude-docker/.env
```

### 5. worktrees ディレクトリ準備

```bash
mkdir -p worktrees && touch worktrees/.gitkeep
```

### 6. Docker イメージビルド

```bash
docker compose -f .claude-docker/docker-compose.yml build
```

### 7. 次のステップ案内

セットアップ完了後、以下のメッセージを表示:

```
セットアップが完了しました。

次の手順:
  1. dev stack を起動（DB 等が必要な場合）:
     docker compose up -d
     ※ これにより {project-name}_default ネットワークが作成され、
       コンテナ内から DB 等にサービス名でアクセス可能になります。

  2. このセッションを終了: /exit

  3. コンテナを起動して Claude Code に接続:
     .claude-docker/scripts/start.sh
```

## 使用方法

```
/setup-docker
```
