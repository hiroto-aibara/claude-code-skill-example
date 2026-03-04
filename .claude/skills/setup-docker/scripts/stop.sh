#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Read project name from .project file
PROJECT_NAME="$(tr -d '[:space:]' < "$SCRIPT_DIR/.project")"
export PROJECT_NAME
export COMPOSE_PROJECT_NAME="claude-${PROJECT_NAME}"
export NETWORK_NAME="${PROJECT_NAME}_default"

docker compose -f "$SCRIPT_DIR/docker-compose.yml" down
echo "Claude Code container (claude-${PROJECT_NAME}) stopped."
echo "Note: The dev stack is not affected."
