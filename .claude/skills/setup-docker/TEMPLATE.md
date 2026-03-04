# Setup Docker - テンプレート

`/setup-docker` が不足ファイルを作成する際に使用するテンプレート集。
プレースホルダをプロジェクトに合わせて置換してから配置する。

---

## プレースホルダ一覧

| プレースホルダ | 説明 | 例 |
|---|---|---|
| `{project-name}` | `.project` のプロジェクト名 | `myapp` |
| `{git-user-name}` | Git author 名 | `john-doe` |
| `{git-user-email}` | Git author メール | `user@example.com` |

---

## .project

```
{project-name}
```

> **Note**: この値からコンテナ名 `claude-{project-name}` とネットワーク名 `{project-name}_default` が導出される。
> ネットワーク名は Docker Compose のデフォルトネットワーク命名規約（`{project-name}_default`）と一致するため、
> dev stack（DB 等）を同じプロジェクト名で `docker compose up` すれば、サービス名（例: `db`）でコンテナ間疎通が可能。

---

## Dockerfile

```dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# System packages
RUN apt-get update && apt-get install -y \
    git curl ca-certificates openssh-client ripgrep jq sudo unzip tmux \
    && rm -rf /var/lib/apt/lists/*
# Project-specific packages (uncomment as needed):
#   postgresql-client

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI + Compose plugin (for dev stack management from inside the container)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Non-root user (Claude Code requires non-root)
# Docker socket GID varies by host; entrypoint will fix permissions at runtime
RUN groupadd -g 999 docker || true && \
    useradd -m -s /bin/bash -G docker claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER claude

# Git author info
RUN git config --global user.name "{git-user-name}" && \
    git config --global user.email "{git-user-email}"

# mise (runtime manager)
RUN curl https://mise.run | sh
ENV PATH="/home/claude/.local/bin:/home/claude/.local/share/mise/shims:${PATH}"
ENV MISE_YES=1
WORKDIR /home/claude
# Pre-install runtimes for faster startup (uncomment as needed):
# RUN mise use -g go@1.24 && mise use -g node@22 && mise reshim

# Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | bash

# tmux config
COPY --chown=claude:claude .tmux.conf /home/claude/.tmux.conf

WORKDIR /workspace
```

> **Note**: ランタイムの事前インストール行をコメント解除すると、`mise install` がビルド時に実行され
> コンテナ起動が高速化する。ただしイメージサイズは増加する。

---

## docker-compose.yml

```yaml
name: claude-{project-name}

services:
  claude-workspace:
    container_name: claude-${PROJECT_NAME}
    build: .
    volumes:
      - ../:/workspace
      - ${SSH_AUTH_SOCK:-/dev/null}:/ssh-agent
      - /var/run/docker.sock:/var/run/docker.sock
    env_file:
      - .env
    environment:
      # Authentication (one of these must be set)
      # Pro/Max subscription -> CLAUDE_CODE_OAUTH_TOKEN
      # API pay-per-use -> ANTHROPIC_API_KEY
      - CLAUDE_CODE_OAUTH_TOKEN
      - ANTHROPIC_API_KEY
      # SSH agent forwarding (for git operations via SSH)
      - SSH_AUTH_SOCK=/ssh-agent
    entrypoint: ["/bin/sh", "-c", "sudo chmod 666 /var/run/docker.sock 2>/dev/null || true; exec sleep infinity"]
    working_dir: /workspace
    networks:
      - app-network

networks:
  app-network:
    external: true
    name: ${NETWORK_NAME}
```

> **Note**:
> - `SSH_AUTH_SOCK` マウントにより、ホストの SSH キーをコンテナ内で利用可能（git submodule 等）
> - `/var/run/docker.sock` マウントにより、コンテナ内から dev stack の `docker compose up/down` が可能
> - `env_file: .env` は `start.sh` が自動生成する（`GH_TOKEN` 等を含む）。`.gitignore` に追加必須
> - `app-network` は dev stack の Docker Compose デフォルトネットワーク（`{project-name}_default`）に接続。
>   これにより dev stack のサービス名（例: `db`）でコンテナ間疎通が可能
