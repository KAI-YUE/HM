#!/usr/bin/env bash
set -Eeuo pipefail

# fix_github_remote.sh
#
# Purpose:
#   Replace an old GitHub remote link with a new repository URL.
#
# Usage:
#   ./scripts/fix_github_remote.sh git@github.com:USER/NEW_REPO.git
#   ./scripts/fix_github_remote.sh https://github.com/USER/NEW_REPO.git
#
# Optional environment variables:
#   REMOTE_NAME=origin ./scripts/fix_github_remote.sh git@github.com:USER/NEW_REPO.git
#   BRANCH=main ./scripts/fix_github_remote.sh git@github.com:USER/NEW_REPO.git
#   PUSH=1 ./scripts/fix_github_remote.sh git@github.com:USER/NEW_REPO.git
#   DRY_RUN=1 ./scripts/fix_github_remote.sh git@github.com:USER/NEW_REPO.git

usage() {
	echo "Usage: $0 <new-github-remote-url>"
	echo
	echo "Example:"
	echo "  $0 git@github.com:USER/NEW_REPO.git"
}

need_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then echo "ERROR: Missing required command: $1" >&2; exit 1; fi
}

timestamp() {
	date +"%Y%m%d_%H%M%S"
}

need_cmd git

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi
if [[ $# -ne 1 ]]; then usage >&2; exit 1; fi

NEW_REMOTE_URL="$1"
REMOTE_NAME="${REMOTE_NAME:-origin}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then echo "ERROR: Run this from inside a Git repository." >&2; exit 1; fi
cd "$REPO_ROOT"

BRANCH="${BRANCH:-$(git branch --show-current 2>/dev/null || true)}"
if [[ -z "$BRANCH" ]]; then BRANCH="${DEFAULT_BRANCH:-main}"; fi

BACKUP_DIR="$REPO_ROOT/.git/remote_fix_backup_$(timestamp)"
OLD_REMOTE_URL="$(git remote get-url "$REMOTE_NAME" 2>/dev/null || true)"

echo "Repository: $REPO_ROOT"
echo "Remote: $REMOTE_NAME"
echo "Old URL: ${OLD_REMOTE_URL:-<missing>}"
echo "New URL: $NEW_REMOTE_URL"
echo "Branch: $BRANCH"
echo

mkdir -p "$BACKUP_DIR"
git remote -v > "$BACKUP_DIR/remotes_before.txt" || true
git branch -vv > "$BACKUP_DIR/branches_before.txt" || true
printf "%s\n" "$OLD_REMOTE_URL" > "$BACKUP_DIR/old_remote_url.txt"
printf "%s\n" "$NEW_REMOTE_URL" > "$BACKUP_DIR/new_remote_url.txt"

if [[ "${DRY_RUN:-0}" == "1" ]]; then
	echo "DRY_RUN=1 enabled. No remote was changed."
	echo "Backup written to: $BACKUP_DIR"
	exit 0
fi

if git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
	git remote set-url "$REMOTE_NAME" "$NEW_REMOTE_URL"
else
	git remote add "$REMOTE_NAME" "$NEW_REMOTE_URL"
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
	git branch --set-upstream-to="$REMOTE_NAME/$BRANCH" "$BRANCH" >/dev/null 2>&1 || true
fi

echo "Updated remotes:"
git remote -v
echo
echo "Backup written to: $BACKUP_DIR"

if [[ "${PUSH:-0}" == "1" ]]; then
	echo
	echo "Pushing current HEAD to $REMOTE_NAME/$BRANCH..."
	git push -u "$REMOTE_NAME" "HEAD:refs/heads/$BRANCH"
fi
