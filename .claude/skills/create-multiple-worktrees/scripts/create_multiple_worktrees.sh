#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_dry() {
    echo -e "${CYAN}[DRY-RUN]${NC} $1"
}

# Default options
DRY_RUN=false
TASK_FILES=()

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <task-file.md> [task-file.md...]

Creates git worktrees from TASK.md files for parallel feature development.

Arguments:
  task-file.md    Path to TASK.md files (feature name is extracted from filename)

Options:
  --dry-run       Show what would be created without actually creating
  -h, --help      Show this help message

Examples:
  $0 tasks/user-auth.md tasks/dashboard.md tasks/api-v2.md
  $0 tasks/*.md
  $0 --dry-run tasks/user-auth.md

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            # Check if file exists
            if [[ -f "$1" ]]; then
                TASK_FILES+=("$1")
            else
                log_error "File not found: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if we have any task files
if [[ ${#TASK_FILES[@]} -eq 0 ]]; then
    log_error "No TASK.md files provided"
    usage
fi

# Get the root directory of the repository
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$REPO_ROOT" ]]; then
    log_error "Not a git repository"
    exit 1
fi
cd "$REPO_ROOT"

# Check if we're in a git repository
if [[ ! -d ".git" ]]; then
    log_error "Not a git repository"
    exit 1
fi

# Function to extract feature name from filename
extract_feature_name() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    # Remove .md extension
    echo "${filename%.md}"
}

# Function to generate random port (range: 10000-60000)
generate_random_port() {
    echo $((RANDOM % 50000 + 10000))
}

# Function to copy file if it exists
copy_if_exists() {
    local src="$1"
    local dest="$2"
    if [[ -f "${src}" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "${src}" "${dest}"
        return 0
    fi
    return 1
}

# Function to create a single worktree
create_single_worktree() {
    local task_file="$1"
    local feature_name=$(extract_feature_name "$task_file")
    local branch_name="feature/${feature_name}"
    local worktree_dir=".worktrees/${feature_name}"

    # Check if worktree already exists
    if [[ -d "${worktree_dir}" ]]; then
        log_warn "Worktree already exists: ${worktree_dir} (skipping)"
        return 1
    fi

    # Create worktree
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        log_warn "Branch ${branch_name} already exists, using it"
        git worktree add "${worktree_dir}" "${branch_name}" 2>/dev/null || {
            log_error "Failed to create worktree for ${feature_name}"
            return 1
        }
    else
        git worktree add -b "${branch_name}" "${worktree_dir}" main 2>/dev/null || {
            log_error "Failed to create worktree for ${feature_name}"
            return 1
        }
    fi

    # Copy TASK.md to worktree
    cp "$task_file" "${worktree_dir}/TASK.md"
    log_info "TASK.md copied to ${worktree_dir}"

    # Copy environment files with randomized ports
    if [[ -f ".env" ]]; then
        local random_frontend_port=$(generate_random_port)
        local random_backend_port=$(generate_random_port)
        local random_agent_port=$(generate_random_port)

        sed -e "s/^FRONTEND_PORT=.*/FRONTEND_PORT=${random_frontend_port}/" \
            -e "s/^BACKEND_PORT=.*/BACKEND_PORT=${random_backend_port}/" \
            -e "s/^AGENT_PORT=.*/AGENT_PORT=${random_agent_port}/" \
            ".env" > "${worktree_dir}/.env"
    fi
    copy_if_exists ".envrc" "${worktree_dir}/.envrc" || true

    # Frontend environment files
    for file in .env .env.local .env.dev .env.prd .env.test; do
        copy_if_exists "modules/frontend/${file}" "${worktree_dir}/modules/frontend/${file}" || true
    done

    # Backend and agent environment files
    copy_if_exists "modules/backend/.env" "${worktree_dir}/modules/backend/.env" || true
    copy_if_exists "modules/agent/.env" "${worktree_dir}/modules/agent/.env" || true

    # Run make setup if Makefile exists
    if [[ -f "${worktree_dir}/Makefile" ]]; then
        (cd "${worktree_dir}" && make setup 2>/dev/null) || log_warn "make setup completed with warnings for ${feature_name}"
    fi

    log_success "${feature_name} created (${worktree_dir})"
    return 0
}

# Dry run mode
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    log_dry "Would create the following worktrees:"
    echo ""
    for task_file in "${TASK_FILES[@]}"; do
        feature_name=$(extract_feature_name "$task_file")
        echo "  - .worktrees/${feature_name}/"
        echo "    ├── TASK.md (from ${task_file})"
        echo "    ├── .env"
        echo "    └── (branch: feature/${feature_name})"
    done
    echo ""
    log_dry "Total: ${#TASK_FILES[@]} worktrees"
    echo ""
    exit 0
fi

# Main execution
echo ""
log_info "Creating ${#TASK_FILES[@]} worktrees from TASK.md files..."
echo ""

SUCCESS_COUNT=0
FAILED_COUNT=0
CREATED_WORKTREES=()

for task_file in "${TASK_FILES[@]}"; do
    feature_name=$(extract_feature_name "$task_file")
    log_step "Creating worktree: ${feature_name}"
    if create_single_worktree "$task_file"; then
        ((SUCCESS_COUNT++))
        CREATED_WORKTREES+=("$feature_name")
    else
        ((FAILED_COUNT++))
    fi
done

# Print summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} ${SUCCESS_COUNT} worktrees created successfully!${NC}"
if [[ $FAILED_COUNT -gt 0 ]]; then
    echo -e "${YELLOW} ${FAILED_COUNT} worktrees failed or skipped${NC}"
fi
echo -e "${GREEN}========================================${NC}"
echo ""

for feature in "${CREATED_WORKTREES[@]}"; do
    echo ".worktrees/${feature}/"
    echo "  ├── TASK.md"
    echo "  ├── .env"
    echo "  └── feature/${feature}"
done

echo ""
echo "To start working on a feature:"
echo "  cd .worktrees/<feature-name>"
echo "  cat TASK.md    # Review task details"
echo "  claude         # Start Claude Code session"
echo ""
echo "To remove all worktrees when done:"
echo "  for wt in .worktrees/*/; do git worktree remove \"\$wt\"; done"
echo ""
