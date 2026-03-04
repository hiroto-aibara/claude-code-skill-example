#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVICE_NAME="claude-workspace"

# Read project name from .project file
PROJECT_FILE="$SCRIPT_DIR/.project"
if [ ! -f "$PROJECT_FILE" ]; then
    echo "ERROR: $PROJECT_FILE not found. Create it with your project name."
    exit 1
fi
PROJECT_NAME="$(tr -d '[:space:]' < "$PROJECT_FILE")"
if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: $PROJECT_FILE is empty."
    exit 1
fi

# Export for docker-compose.yml variable substitution
export PROJECT_NAME
export COMPOSE_PROJECT_NAME="claude-${PROJECT_NAME}"
export NETWORK_NAME="${PROJECT_NAME}_default"

# Argument parsing
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

# --- Pre-flight checks ---

# 1. Docker running?
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Start Docker Desktop first."
    exit 1
fi

# 2. Authentication configured?
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    echo "Auth: Pro/Max subscription (CLAUDE_CODE_OAUTH_TOKEN)"
elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "Auth: API key (ANTHROPIC_API_KEY)"
else
    echo "Auth: not configured (use /login after startup)"
fi

# 3. GitHub CLI token -> write to .env file for docker-compose
ENV_FILE="$SCRIPT_DIR/.env"
if [ -z "${GH_TOKEN:-}" ] && command -v gh > /dev/null 2>&1; then
    GH_TOKEN="$(gh auth token 2>/dev/null || true)"
fi

if [ -n "${GH_TOKEN:-}" ]; then
    echo "GH_TOKEN=$GH_TOKEN" > "$ENV_FILE"
    echo "GitHub: token written to .claude-docker/.env"
else
    # Create empty .env so docker-compose doesn't complain
    touch "$ENV_FILE"
    echo "GitHub: not configured (set GH_TOKEN or run 'gh auth login' on host)"
fi

# 4. App stack network available?
if docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
    echo "Network: $NETWORK_NAME found -- dev stack services accessible"
else
    echo ""
    echo "WARNING: Network '$NETWORK_NAME' not found."
    echo "  The dev stack is not running. To start it:"
    echo "    cd $PROJECT_ROOT && docker compose up -d"
    echo ""
    echo "  Creating the network now so the container can start..."
    docker network create "$NETWORK_NAME" || true
fi

# --- Container lifecycle ---
if docker compose -f "$COMPOSE_FILE" ps --status running 2>/dev/null | grep -q "$SERVICE_NAME"; then
    if [ "$REBUILD" = true ]; then
        echo "=== Rebuilding container ==="
        docker compose -f "$COMPOSE_FILE" down
        docker compose -f "$COMPOSE_FILE" up -d --build
    else
        # Recreate to pick up .env changes (e.g. refreshed GH_TOKEN)
        echo "=== Recreating container with latest .env ==="
        docker compose -f "$COMPOSE_FILE" up -d --force-recreate
    fi
else
    echo "=== Building and starting container ==="
    if [ "$REBUILD" = true ]; then
        docker compose -f "$COMPOSE_FILE" up -d --build
    else
        docker compose -f "$COMPOSE_FILE" up -d
    fi
fi

# --- Post-start setup ---
echo "=== Configuring git ==="
docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" \
    git config --global --add safe.directory /workspace

# Mark all worktree directories as safe too
for wt in "$PROJECT_ROOT"/worktrees/*/; do
    if [ -d "$wt" ]; then
        wt_name="$(basename "$wt")"
        docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" \
            git config --global --add safe.directory "/workspace/worktrees/$wt_name"
    fi
done

# Docker socket permissions
# macOS: stat -f '%g'
# Linux: stat -c '%g'
if [ -S /var/run/docker.sock ]; then
    DOCKER_GID=$(stat -f '%g' /var/run/docker.sock)
    # On Linux, replace the line above with:
    # DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" \
        sudo bash -c "
            if getent group docker >/dev/null 2>&1; then
                usermod -aG docker claude
            elif getent group $DOCKER_GID >/dev/null 2>&1; then
                EXISTING_GROUP=\$(getent group $DOCKER_GID | cut -d: -f1)
                usermod -aG \$EXISTING_GROUP claude
            else
                groupadd -g $DOCKER_GID docker && usermod -aG docker claude
            fi
        "
    echo "Docker: socket access configured for claude user"
fi

echo "=== Configuring GitHub auth ==="
docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" bash -c '
    if [ -n "${GH_TOKEN:-}" ]; then
        echo "${GH_TOKEN}" | gh auth login --with-token 2>/dev/null || true
        gh auth setup-git 2>/dev/null || true
        git config --global url."https://github.com/".insteadOf "git@github.com:"
        echo "  gh auth setup-git configured"
    else
        echo "  WARNING: GH_TOKEN not set, git fetch/push will not work"
    fi
'

echo "=== Installing runtimes via mise ==="
docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" mise trust /workspace/mise.toml
docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" mise install

# --- Project-specific dependency install (uncomment as needed) ---
# echo "=== Installing dependencies ==="
# docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" bash -c "cd /workspace && go mod download"
# docker compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" bash -c "cd /workspace && npm ci"

# --- Launch Claude Code ---
echo ""
echo "=== Starting Claude Code ==="
echo "  To stop: .claude-docker/scripts/stop.sh"
echo ""

docker compose -f "$COMPOSE_FILE" exec -it "$SERVICE_NAME" \
    claude --dangerously-skip-permissions
