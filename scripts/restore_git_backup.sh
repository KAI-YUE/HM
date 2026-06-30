#!/usr/bin/env bash
set -Eeuo pipefail

# restore_git_backup.sh
#
# Purpose:
#   Restore a .git directory saved by clean_git_stable_push.sh.
#
# Usage:
#   ./scripts/restore_git_backup.sh ./archive .
#   ./restore_git_backup.sh . ..
#
# Optional environment variables:
#   DRY_RUN=1 ./scripts/restore_git_backup.sh ./archive .
#   RESTORE_REPO_ROOT=/path/to/repo ./scripts/restore_git_backup.sh /path/to/backup

timestamp() {
	date +"%Y%m%d_%H%M%S"
}

need_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "ERROR: Missing required command: $1" >&2
		exit 1
	fi
}

real_path() {
	if command -v realpath >/dev/null 2>&1; then
		realpath "$1"
	else
		python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$1"
	fi
}

script_dir() {
	cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

default_backup_dir() {
	local dir
	dir="$(script_dir)"
	if [[ -f "$dir/dot_git_backup.tar.gz" ]]; then printf "%s\n" "$dir"; return; fi
	printf "%s\n" "archive"
}

default_repo_root() {
	local backup_abs cwd_abs parent_abs saved_root
	backup_abs="$(real_path "$BACKUP_DIR")"
	cwd_abs="$(real_path "$PWD")"
	parent_abs="$(real_path "$backup_abs/..")"
	saved_root="$(sed -n '1p' "$backup_abs/repo_root.txt" 2>/dev/null || true)"
	if [[ -n "${RESTORE_REPO_ROOT:-}" ]]; then printf "%s\n" "$RESTORE_REPO_ROOT"; return; fi
	if [[ "$cwd_abs" != "$backup_abs" ]]; then printf "%s\n" "$cwd_abs"; return; fi
	if [[ -e "$parent_abs/main.lua" || -d "$parent_abs/scripts" || -d "$parent_abs/core" ]]; then printf "%s\n" "$parent_abs"; return; fi
	if [[ -n "$saved_root" ]]; then printf "%s\n" "$saved_root"; return; fi
	printf "%s\n" "$cwd_abs"
}

need_cmd tar

BACKUP_DIR="${1:-$(default_backup_dir)}"
BACKUP_DIR="$(real_path "$BACKUP_DIR")"
REPO_ROOT="${2:-$(default_repo_root)}"
REPO_ROOT="$(real_path "$REPO_ROOT")"
BACKUP_TAR="$BACKUP_DIR/dot_git_backup.tar.gz"

if [[ ! -f "$BACKUP_TAR" ]]; then
	echo "ERROR: Missing backup archive: $BACKUP_TAR" >&2
	exit 1
fi

if ! tar -tzf "$BACKUP_TAR" .git >/dev/null 2>&1; then
	echo "ERROR: Backup archive does not contain a .git directory." >&2
	exit 1
fi

echo "Backup dir: $BACKUP_DIR"
echo "Restore repo: $REPO_ROOT"
echo

if [[ "${DRY_RUN:-0}" == "1" ]]; then
	echo "DRY_RUN=1 enabled. No files were changed."
	exit 0
fi

mkdir -p "$REPO_ROOT"

if [[ -e "$REPO_ROOT/.git" ]]; then
	existing_git_backup="$REPO_ROOT/.git_before_restore_$(timestamp).tar.gz"
	echo "Saving existing .git to: $existing_git_backup"
	tar -C "$REPO_ROOT" -czf "$existing_git_backup" .git
	rm -rf "$REPO_ROOT/.git"
fi

echo "Restoring .git..."
tar -C "$REPO_ROOT" -xzf "$BACKUP_TAR" .git

echo
echo "Restored local Git metadata."
if command -v git >/dev/null 2>&1; then
	git -C "$REPO_ROOT" status --short || true
fi
echo
echo "Remote history is unchanged. Push manually if you need to put the old history back online."
