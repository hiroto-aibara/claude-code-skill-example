---
name: setup-docker
description: Docker + Agent Teams 環境のセットアップ。Dockerfile・docker-compose.yml・スクリプトの検証・作成、worktrees ディレクトリ準備、Docker イメージビルドを実行する。
allowed-tools: Bash(docker:*), Bash(docker-compose:*), Bash(mkdir:*), Bash(chmod:*), Bash(ls:*), Bash(git:*), Read, Write, Glob
user-invocable: true
---

# Setup Docker

Docker + Agent Teams 並列実装環境をセットアップします。

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
   - Dockerfile, docker-compose.yml, scripts/, .dockerignore
        ↓
4. worktrees ディレクトリ準備
   - worktrees/ 作成 + .gitkeep
   - .gitignore に worktrees/* 追加（未追加の場合）
        ↓
5. Docker イメージビルド
   - docker compose -f .claude-docker/docker-compose.yml build
        ↓
6. 次のステップ案内
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

**必須ファイル:**
- `.claude-docker/Dockerfile`
- `.claude-docker/docker-compose.yml`
- `.claude-docker/scripts/start.sh`
- `.claude-docker/scripts/stop.sh`
- `.claude-docker/.dockerignore`

ファイルの内容は [TEMPLATE.md](TEMPLATE.md) を参照する。

### 4. worktrees ディレクトリ準備

```bash
mkdir -p worktrees && touch worktrees/.gitkeep
```

`.gitignore` に以下が含まれていなければ追加:
```
worktrees/*
!worktrees/.gitkeep
```

### 5. Docker イメージビルド

```bash
docker compose -f .claude-docker/docker-compose.yml build
```

### 6. 次のステップ案内

セットアップ完了後、以下のメッセージを表示:

```
セットアップが完了しました。

次の手順:
  1. このセッションを終了: /exit
  2. コンテナを起動して Claude Code に接続:
     .claude-docker/scripts/start.sh
```

## 使用方法

```
/setup-docker
```

## 参考

- [docs/docker-agent-teams-guide.md](../../../docs/docker-agent-teams-guide.md) - Docker + Agent Teams ガイド
