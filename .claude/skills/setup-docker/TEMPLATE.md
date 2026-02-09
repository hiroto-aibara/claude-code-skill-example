# Setup Docker - テンプレート

`/setup-docker` が不足ファイルを作成する際に使用するテンプレート集。

---

## Dockerfile

```dockerfile
FROM ubuntu:24.04

# 基本ツール
RUN apt-get update && apt-get install -y \
    git curl ca-certificates \
    ripgrep jq sudo \
    && rm -rf /var/lib/apt/lists/*

# 非 root ユーザー作成（--dangerously-skip-permissions は root 不可）
RUN useradd -m -s /bin/bash claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# mise（ランタイムマネージャ: Python, Node.js, uv 等を管理）
USER claude
RUN curl https://mise.run | sh
ENV PATH="/home/claude/.local/bin:/home/claude/.local/share/mise/shims:${PATH}"

# Claude Code（公式 Native Install）
RUN curl -fsSL https://claude.ai/install.sh | bash

WORKDIR /workspace
```

> **Note**: Python, Node.js, uv 等のランタイムは Dockerfile に直接インストールせず、
> mise がプロジェクトの `.mise.toml` に基づいて管理する。
> コンテナ起動後に `mise install` で必要なランタイムがインストールされる。

---

## docker-compose.yml

```yaml
services:
  claude-workspace:
    build: .
    volumes:
      - ../:/workspace
    environment:
      # 認証（どちらか一方を設定）
      # Pro/Max サブスクリプション → CLAUDE_CODE_OAUTH_TOKEN を使用
      # API 従量課金 → ANTHROPIC_API_KEY を使用
      # ※ ANTHROPIC_API_KEY が設定されているとサブスクリプションより優先される
      - CLAUDE_CODE_OAUTH_TOKEN
      - ANTHROPIC_API_KEY
      # Agent Teams 有効化
      - CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
    command: sleep infinity
    working_dir: /workspace
```

---

## scripts/start.sh

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SERVICE_NAME="claude-workspace"

# 引数解析
REBUILD=false
for arg in "$@"; do
    case $arg in
        --rebuild) REBUILD=true ;;
        --help|-h)
            echo "Usage: start.sh [--rebuild]"
            echo "  --rebuild  Force rebuild of Docker image"
            exit 0
            ;;
    esac
done

# 認証の確認
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    echo "Auth: Pro/Max subscription (CLAUDE_CODE_OAUTH_TOKEN)"
elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "Auth: API key (ANTHROPIC_API_KEY)"
else
    echo "Auth: not configured (use /login after startup)"
fi

# コンテナが起動中かチェック
if docker compose -f "$COMPOSE_FILE" ps --status running 2>/dev/null | grep -q "$SERVICE_NAME"; then
    if [ "$REBUILD" = true ]; then
        echo "=== Rebuilding container ==="
        docker compose -f "$COMPOSE_FILE" down
        docker compose -f "$COMPOSE_FILE" up -d --build
        echo "=== Configuring git ==="
        docker compose -f "$COMPOSE_FILE" exec \
            "$SERVICE_NAME" \
            git config --global --add safe.directory /workspace
        echo "=== Installing runtimes via mise ==="
        docker compose -f "$COMPOSE_FILE" exec \
            "$SERVICE_NAME" \
            mise install
    else
        echo "=== Container already running. Reattaching... ==="
    fi
else
    echo "=== Building and starting container ==="
    if [ "$REBUILD" = true ]; then
        docker compose -f "$COMPOSE_FILE" up -d --build
    else
        docker compose -f "$COMPOSE_FILE" up -d
    fi
    echo "=== Configuring git ==="
    docker compose -f "$COMPOSE_FILE" exec \
        "$SERVICE_NAME" \
        git config --global --add safe.directory /workspace
    echo "=== Installing runtimes via mise ==="
    docker compose -f "$COMPOSE_FILE" exec \
        "$SERVICE_NAME" \
        mise install
fi

echo "=== Starting Claude Code ==="
echo "  Tip: Use Agent Teams as usual inside the container."
echo "  To stop: run .claude-docker/scripts/stop.sh from another terminal"
echo ""

docker compose -f "$COMPOSE_FILE" exec -it \
    "$SERVICE_NAME" \
    claude --dangerously-skip-permissions
```

---

## scripts/stop.sh

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

docker compose -f "$SCRIPT_DIR/docker-compose.yml" down
echo "Container stopped."
```

---

## .dockerignore

```
.git
node_modules
.venv
__pycache__
```
