#!/usr/bin/env bash
# codex-prune.sh — safe cleanup for OpenAI Codex CLI
set -euo pipefail

TARGET=${1:-cache}        # cache | all
shift || true

# Parse remaining args in any order
ACTION="--dry-run"
BASEDIR="$HOME"
NPMPATH="$HOME/.npm-global"

for arg in "$@"; do
  case "$arg" in
    --confirm|-y)
      ACTION="--confirm"
      ;;
    --dry-run)
      ACTION="--dry-run"
      ;;
    *)
      if [[ "$BASEDIR" == "$HOME" ]]; then
        BASEDIR="$arg"
      else
        NPMPATH="$arg"
      fi
      ;;
  esac
done

if [[ "$BASEDIR" != "/" ]]; then
  BASEDIR="${BASEDIR%/}"
fi
if [[ "$NPMPATH" != "/" ]]; then
  NPMPATH="${NPMPATH%/}"
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
  echo "[*] Codex cache targets under $BASEDIR:"
  local codex_home="$BASEDIR/.codex"
  local -a codex_targets=()

  if [[ -d "$codex_home" ]]; then
    local candidate
    for candidate in \
      "$codex_home/sessions" \
      "$codex_home/log" \
      "$codex_home/history.jsonl"; do
      [[ -e "$candidate" ]] && codex_targets+=("$candidate")
    done
  fi

  print_path_list "${codex_targets[@]}"

  if [[ "$ACTION" == "--confirm" ]]; then
    echo "[*] Deleting cache data..."
    local path
    for path in "${codex_targets[@]}"; do
      if [[ -d "$path" ]]; then
        rm -rf "$path" 2>/dev/null || true
      else
        rm -f "$path" 2>/dev/null || true
      fi
    done
  fi
}

prune_all() {
  prune_cache
  echo "[*] Additional Codex data under $BASEDIR:"

  local codex_home="$BASEDIR/.codex"
  shopt -s nullglob
  local -a codex_json=("$BASEDIR"/.codex.json*)
  shopt -u nullglob
  local -a workspace_agents=()
  mapfile -t workspace_agents < <(find "$BASEDIR" -type f \( -name 'AGENTS.md' -o -name 'AGENTS.override.md' \) -print 2>/dev/null || true)
  local -a extra_paths=(
    "$codex_home"
    "$codex_home/auth.json"
    "$codex_home/config.toml"
    "$codex_home/version.json"
    "$NPMPATH/lib/node_modules/@openai/codex"
  )
  extra_paths+=("${codex_json[@]}")
  extra_paths+=("${workspace_agents[@]}")
  print_path_list "${extra_paths[@]}"

  if [[ "$ACTION" == "--confirm" ]]; then
    echo "[*] Deleting all Codex data..."
    rm -rf "$codex_home" 2>/dev/null || true
    if [[ ${#codex_json[@]} -gt 0 ]]; then
      rm -f "${codex_json[@]}" 2>/dev/null || true
    fi
    if [[ ${#workspace_agents[@]} -gt 0 ]]; then
      rm -f "${workspace_agents[@]}" 2>/dev/null || true
    fi
    npm uninstall -g @openai/codex --prefix "$NPMPATH" 2>/dev/null || true
    if [[ -d "$NPMPATH/lib/node_modules/@openai/codex" ]]; then
      rm -rf "$NPMPATH/lib/node_modules/@openai/codex" 2>/dev/null || true
    fi
  fi
}

case "$TARGET" in
  cache) prune_cache ;;
  all)   prune_all ;;
  *) echo "Usage: $0 [cache|all] [--dry-run|--confirm] [codexdir] [npmpath]" ; exit 1 ;;
esac

echo
if [[ "$ACTION" != "--confirm" ]]; then
  echo "[!] This was a dry run. No data has been removed."
  echo "    Re-run with '--confirm' to actually delete."
fi
