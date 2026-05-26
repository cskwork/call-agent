#!/usr/bin/env bash
# tests/run-all.sh — run every skill's smoke test in turn.
# Env passthrough:
#   RUN_L2=1   include round-trip prompts (uses credit)
#   RUN_L3=1   include feature exercises (image gen, RAG, etc.)
set -u

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS=(agy-call kiro-call codex-call notebooklm-call claude-call)

OVERALL=0
for s in "${SKILLS[@]}"; do
  smoke="$REPO_DIR/skills/$s/tests/smoke.sh"
  if [ ! -x "$smoke" ]; then
    if [ -f "$smoke" ]; then
      chmod +x "$smoke" 2>/dev/null || true
    else
      echo "[$s] no smoke.sh"; OVERALL=1; continue
    fi
  fi
  echo "===== $s ====="
  if bash "$smoke"; then
    :
  else
    OVERALL=1
  fi
  echo
done

if [ "$OVERALL" = "0" ]; then
  echo "ALL PASS (with RUN_L2=${RUN_L2:-0} RUN_L3=${RUN_L3:-0})"
else
  echo "SOME FAILED — see logs above"
fi
exit "$OVERALL"
