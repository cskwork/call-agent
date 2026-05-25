#!/usr/bin/env bash
# kilo-parallel.sh — run N kilo agents concurrently, each on its own branch.
# Usage:
#   ./kilo-parallel.sh "feat-a:Implement A" "feat-b:Implement B" ...
#
# Each arg is "BRANCH:PROMPT". Branch is suggestive only — kilo decides
# the real branch name; we pass it via -eb if you want to attach to an
# existing one. Pass an empty BRANCH ("") to let kilo create one.
#
# Env:
#   KILO_TIMEOUT   per-task timeout in seconds (default 600)
#   KILO_MODE      mode (default: code)
#   KILO_PROVIDER  provider override (optional)
#   KILO_MODEL     model override (optional)
#   KILO_OUTDIR    where to write JSONL logs (default: /tmp/kilo-parallel-$$)

set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 'BRANCH:PROMPT' ['BRANCH:PROMPT' ...]" >&2
  exit 2
fi

if ! command -v kilo >/dev/null; then
  echo "kilo not installed" >&2; exit 2
fi
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "must be inside a git repo for kilo parallel mode" >&2; exit 2
fi

TIMEOUT="${KILO_TIMEOUT:-600}"
MODE="${KILO_MODE:-code}"
OUTDIR="${KILO_OUTDIR:-/tmp/kilo-parallel-$$}"
mkdir -p "$OUTDIR"

PIDS=()
SLUGS=()
i=0
for spec in "$@"; do
  i=$((i + 1))
  branch="${spec%%:*}"
  prompt="${spec#*:}"
  if [ "$prompt" = "$spec" ]; then
    prompt="$spec"; branch=""
  fi
  slug=$(printf '%02d-%s' "$i" "$(echo "${branch:-anon}" | tr -c 'A-Za-z0-9_-' '_' )")
  log="$OUTDIR/$slug.jsonl"
  SLUGS+=("$slug")

  args=(--auto --json --timeout "$TIMEOUT" --mode "$MODE" -p --nosplash)
  [ -n "${KILO_PROVIDER:-}" ] && args+=(--provider "$KILO_PROVIDER")
  [ -n "${KILO_MODEL:-}" ]    && args+=(--model "$KILO_MODEL")
  [ -n "$branch" ]            && args+=(-eb "$branch")

  echo "[kilo-parallel] launching $slug -> $log"
  kilo "${args[@]}" "$prompt" >"$log" 2>&1 &
  PIDS+=("$!")
done

RC=0
for pid in "${PIDS[@]}"; do
  if ! wait "$pid"; then RC=1; fi
done

echo "[kilo-parallel] all done; logs in $OUTDIR"
for slug in "${SLUGS[@]}"; do
  log="$OUTDIR/$slug.jsonl"
  final=$(grep '"type":"say.completion_result"' "$log" 2>/dev/null | tail -1)
  printf '\n=== %s ===\n%s\n' "$slug" "${final:-<no completion event>}"
done

exit "$RC"
