#!/usr/bin/env bash

# this script can clean claude cached files or all traces of claude
# usage: ./claude.sh [cache|all] [--dry-run|--confirm] [basedir]

set -euo pipefail

TARGET=${1:-cache}        # cache | all
shift || true

# Parse remaining args in any order
ACTION="--dry-run"
BASEDIR="$HOME"

for arg in "$@"; do
  case "$arg" in
    --confirm|-y)
      ACTION="--confirm"
      ;;
    --dry-run)
      ACTION="--dry-run"
      ;;
    *)
      BASEDIR="$arg"
      ;;
  esac
done

if [[ "$BASEDIR" != "/" ]]; then
  BASEDIR="${BASEDIR%/}"
fi

format_count() {
  local path="$1"
  local count=0

  if [[ -d "$path" ]]; then
    count=$(find "$path" -type f -print 2>/dev/null | wc -l | tr -d '[:space:]')
    count=${count:-0}
  elif [[ -f "$path" || -L "$path" ]]; then
    count=1
  fi

  if [[ -z "$count" || "$count" -eq 0 ]]; then
    echo "(empty)"
  else
    echo "($count)"
  fi
}

print_path_list() {
  if [[ "$#" -eq 0 ]]; then
    echo "    (none)"
    return
  fi

  local path
  for path in "$@"; do
    printf '    %s %s\n' "$path" "$(format_count "$path")"
  done
}

prune_cache() {
  echo "[*] Claude cache targets under $BASEDIR:"
  local -a claude_dirs=()
  local -a claude_files=()
  local -a claude_home_paths=()
  local -a tmp_matches=()

  mapfile -t claude_dirs < <(find "$BASEDIR" -mindepth 3 -type d -name '.claude' -print 2>/dev/null || true)
  mapfile -t claude_files < <(find "$BASEDIR" -type f -name 'CLAUDE.md' -print 2>/dev/null || true)

  if [[ -d "$BASEDIR/.claude" ]]; then
    local path
    for path in \
      "$BASEDIR/.claude/projects" \
      "$BASEDIR/.claude/file-history" \
      "$BASEDIR/.claude/history.jsonl" \
      "$BASEDIR/.claude/debug" \
      "$BASEDIR/.claude/session-env" \
      "$BASEDIR/.claude/settings.json" \
      "$BASEDIR/.claude/shell-snapshots" \
      "$BASEDIR/.claude/statsig" \
      "$BASEDIR/.claude/todos"; do
      [[ -e "$path" ]] && claude_home_paths+=("$path")
    done
  fi

  local -a claude_targets=("${claude_dirs[@]}" "${claude_files[@]}" "${claude_home_paths[@]}")
  print_path_list "${claude_targets[@]}"

  # summarize /tmp files
  shopt -s nullglob
  tmp_matches=(/tmp/claude-*)
  shopt -u nullglob
  local tmp_count=${#tmp_matches[@]}
  if (( tmp_count > 0 )); then
    echo "[*] Found $tmp_count items in /tmp matching claude-*"
    local path
    for path in "${tmp_matches[@]:0:5}"; do
      printf '    %s %s\n' "$path" "$(format_count "$path")"
    done
    (( tmp_count > 5 )) && echo "    ... ($((tmp_count-5)) more)"
  else
    echo "[i] No /tmp/claude-* entries found."
  fi

  if [[ "$ACTION" == "--confirm" ]]; then
    echo "[*] Deleting cache data..."
    if [[ ${#claude_targets[@]} -gt 0 ]]; then
      local target
      for target in "${claude_targets[@]}"; do
        if [[ -d "$target" ]]; then
          rm -rf "$target" 2>/dev/null || true
        else
          rm -f "$target" 2>/dev/null || true
        fi
      done
    fi
    if [[ ${#tmp_matches[@]} -gt 0 ]]; then
      rm -rf "${tmp_matches[@]}" 2>/dev/null || true
    fi
  fi
}

prune_all() {
  prune_cache
  echo "[*] Additional Claude data under $BASEDIR:"

  shopt -s nullglob
  local -a extra_paths=()
  extra_paths+=("$BASEDIR/.claude")
  extra_paths+=("$BASEDIR/.local/lib/node_modules/@anthropic-ai/claude-code")
  local -a json_matches=("$BASEDIR"/.claude.json*)
  shopt -u nullglob
  extra_paths+=("${json_matches[@]}")
  print_path_list "${extra_paths[@]}"

  if [[ "$ACTION" == "--confirm" ]]; then
    echo "[*] Deleting all Claude data..."
    rm -rf "$BASEDIR/.claude" 2>/dev/null || true
    if [[ ${#json_matches[@]} -gt 0 ]]; then
      rm -f "${json_matches[@]}" 2>/dev/null || true
    fi
    npm uninstall -g @anthropic-ai/claude-code --prefix "$BASEDIR/.local" 2>/dev/null || true
  fi
}

case "$TARGET" in
  cache) prune_cache ;;
  all)   prune_all ;;
  *) echo "Usage: $0 [cache|all] [--dry-run|--confirm] [basepath]" ; exit 1 ;;
esac

echo
if [[ "$ACTION" != "--confirm" ]]; then
  echo "[!] This was a dry run. No data has been removed."
  echo "    Re-run with '--confirm' to actually delete."
fi
