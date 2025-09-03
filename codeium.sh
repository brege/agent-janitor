#!/usr/bin/env bash

# this script can clean codeium cached files or all traces of codeium
# usage: ./codeium.sh [cache|all] [--dry-run|--confirm] [basedir]

set -euo pipefail

TARGET=${1:-cache}        # cache | all
shift || true

# Parse remaining args in any order
ACTION="--dry-run"
BASEDIR="$HOME/.codeium"

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

if [[ ! -d "$BASEDIR/code_tracker" && -d "$BASEDIR/.codeium" ]]; then
  BASEDIR="$BASEDIR/.codeium"
  if [[ "$BASEDIR" != "/" ]]; then
    BASEDIR="${BASEDIR%/}"
  fi
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
  echo "[*] Codeium cache targets under $BASEDIR:"
  local -a codeium_targets=()
  local candidate
  for candidate in \
    "$BASEDIR/code_tracker/active" \
    "$BASEDIR/code_tracker/history" \
    "$BASEDIR/context_state" \
    "$BASEDIR/database"; do
    [[ -e "$candidate" ]] && codeium_targets+=("$candidate")
  done

  local default_nvim_cache="$HOME/.cache/nvim/codeium"
  if [[ -e "$default_nvim_cache" ]]; then
    codeium_targets+=("$default_nvim_cache")
  fi

  print_path_list "${codeium_targets[@]}"

  if [[ "$ACTION" == "--confirm" ]]; then
    echo "[*] Deleting cache data..."
    for candidate in "${codeium_targets[@]}"; do
      if [[ -d "$candidate" ]]; then
        rm -rf "$candidate" 2>/dev/null || true
      else
        rm -f "$candidate" 2>/dev/null || true
      fi
    done
  fi
}

prune_all() {
  prune_cache
  echo "[*] Additional Codeium data under $BASEDIR:"
  shopt -s nullglob
  local -a onboarding_matches=("$BASEDIR"/onboarding.json*)
  shopt -u nullglob
  local -a extra_paths=(
    "$BASEDIR/bin"
    "$BASEDIR/config.json"
  )
  extra_paths+=("${onboarding_matches[@]}")
  print_path_list "${extra_paths[@]}"

  if [[ "$ACTION" == "--confirm" ]]; then
    echo "[*] Deleting entire Codeium directory..."
    rm -rf "$BASEDIR" 2>/dev/null || true
  fi
}

case "$TARGET" in
  cache) prune_cache ;;
  all)   prune_all ;;
  *) echo "Usage: $0 [cache|all] [--dry-run|--confirm] [basedir]" ; exit 1 ;;
esac

echo
if [[ "$ACTION" != "--confirm" ]]; then
  echo "[!] This was a dry run. No data has been removed."
  echo "    Re-run with '--confirm' to actually delete."
fi
