#!/usr/bin/env bash
set -Eeuo pipefail

# restore_codex_archived_session.sh
#
# Usage:
#   ./scripts/restore_codex_archived_session.sh --list
#   ./scripts/restore_codex_archived_session.sh
#   ./scripts/restore_codex_archived_session.sh 019ed06e-e6f2-70e0-aac2-95d618a268b2
#   ./scripts/restore_codex_archived_session.sh rollout-2026-06-16T08-36-29-019ed06e-e6f2-70e0-aac2-95d618a268b2.jsonl
#
# Optional:
#   CODEX_HOME=/path/to/.codex ./scripts/restore_codex_archived_session.sh
#   DRY_RUN=1 ./scripts/restore_codex_archived_session.sh

CODEX_HOME="${CODEX_HOME:-"$HOME/.codex"}"
ARCHIVE_DIR="$CODEX_HOME/archived_sessions"
SESSIONS_DIR="$CODEX_HOME/sessions"
INDEX_FILE="$CODEX_HOME/session_index.jsonl"

usage() {
	echo "Usage: $0 [--list|session-id-or-archived-jsonl]"
	echo
	echo "--list shows archived sessions with id, date, and thread name."
	echo "With no argument, restores all archived sessions from:"
	echo "  $ARCHIVE_DIR"
}

session_id_from_file() {
	basename "$1" | sed -n 's/^rollout-[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9-]*-\(.*\)\.jsonl$/\1/p'
}

thread_name_for_id() {
	local id="$1"
	if [[ -f "$INDEX_FILE" ]]; then
		sed -n 's/.*"id":"'"$id"'".*"thread_name":"\([^"]*\)".*/\1/p' "$INDEX_FILE" | tail -n 1
	fi
}

list_archived() {
	local file base id name

	shopt -s nullglob
	files=("$ARCHIVE_DIR"/rollout-*.jsonl)
	if [[ ${#files[@]} -eq 0 ]]; then echo "No archived Codex sessions found in: $ARCHIVE_DIR"; return 0; fi

	for file in "${files[@]}"; do
		base="$(basename "$file")"
		id="$(session_id_from_file "$file")"
		name="$(thread_name_for_id "$id")"
		printf "%s  %s  %s\n" "${base:8:10}" "$id" "${name:-$base}"
	done
}

restore_file() {
	local src="$1"
	local base date yyyy mm dd dst_dir dst

	base="$(basename "$src")"
	date="$(printf "%s\n" "$base" | sed -n 's/^rollout-\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)T.*/\1-\2-\3/p')"
	if [[ -z "$date" ]]; then
		echo "ERROR: Could not parse date from: $base" >&2
		return 1
	fi

	yyyy="${date:0:4}"
	mm="${date:5:2}"
	dd="${date:8:2}"
	dst_dir="$SESSIONS_DIR/$yyyy/$mm/$dd"
	dst="$dst_dir/$base"

	if [[ -e "$dst" ]]; then
		echo "Skip, already exists: $dst"
		return 0
	fi

	echo "Restore: $src"
	echo "     to: $dst"
	if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi

	mkdir -p "$dst_dir"
	mv "$src" "$dst"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi
if [[ ! -d "$ARCHIVE_DIR" ]]; then echo "ERROR: Missing archive dir: $ARCHIVE_DIR" >&2; exit 1; fi
if [[ "${1:-}" == "--list" || "${1:-}" == "list" ]]; then list_archived; exit 0; fi

if [[ $# -eq 0 ]]; then
	shopt -s nullglob
	files=("$ARCHIVE_DIR"/rollout-*.jsonl)
	if [[ ${#files[@]} -eq 0 ]]; then echo "No archived Codex sessions found in: $ARCHIVE_DIR"; exit 0; fi
	for file in "${files[@]}"; do restore_file "$file"; done
	echo "Done. Reload VS Code after restoring."
	exit 0
fi

query="$1"
if [[ -f "$query" ]]; then
	restore_file "$query"
elif [[ -f "$ARCHIVE_DIR/$query" ]]; then
	restore_file "$ARCHIVE_DIR/$query"
else
	shopt -s nullglob
	matches=("$ARCHIVE_DIR"/*"$query"*.jsonl)
	if [[ ${#matches[@]} -eq 0 ]]; then echo "ERROR: No archived session matched: $query" >&2; exit 1; fi
	if [[ ${#matches[@]} -gt 1 ]]; then
		echo "ERROR: Multiple archived sessions matched: $query" >&2
		printf "  %s\n" "${matches[@]}" >&2
		exit 1
	fi
	restore_file "${matches[0]}"
fi

echo "Done. Reload VS Code after restoring."
