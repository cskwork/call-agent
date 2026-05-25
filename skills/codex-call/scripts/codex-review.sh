#!/usr/bin/env bash
# codex-review.sh — wraps `codex review` with sane defaults.
# Usage:
#   codex-review.sh                          # review uncommitted changes
#   codex-review.sh --uncommitted
#   codex-review.sh --base main
#   codex-review.sh --commit <SHA>
#   codex-review.sh --base main "Focus on security"
set -uo pipefail

if ! command -v codex >/dev/null; then
  echo "codex not installed" >&2; exit 2
fi
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "must run inside a git repo" >&2; exit 2
fi

SCOPE=()
PROMPT=""
case "${1:-}" in
  --uncommitted|--base|--commit)
    SCOPE+=("$1")
    [ "$1" != "--uncommitted" ] && { shift; SCOPE+=("${1:?missing arg for ${SCOPE[0]}}"); }
    shift
    PROMPT="${*:-}"
    ;;
  "")
    SCOPE+=(--uncommitted)
    ;;
  *)
    PROMPT="$*"
    SCOPE+=(--uncommitted)
    ;;
esac

ARGS=("${SCOPE[@]}")
[ -n "$PROMPT" ] && ARGS+=("$PROMPT")

codex review "${ARGS[@]}"
