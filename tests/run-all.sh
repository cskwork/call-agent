#!/usr/bin/env bash
# tests/run-all.sh — run every skill's smoke test in turn.
# Env passthrough:
#   RUN_L2=1   include round-trip prompts (uses credit)
#   RUN_L3=1   include feature exercises (image gen, RAG, etc.)
#   RUN_L4=1   include long-running async jobs (codex-call; uses credit)
#
# Per-skill smoke exit codes: 0 PASS, 3 SKIP (dependency not installed),
# anything else FAIL. The suite is GREEN when nothing FAILed — a skill whose
# CLI isn't installed is SKIPped, not failed, so a partial install still passes.
set -u

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS=(agy-call kiro-call codex-call notebooklm-call claude-call)

passed=""; skipped=""; failed=""
for s in "${SKILLS[@]}"; do
  smoke="$REPO_DIR/skills/$s/tests/smoke.sh"
  if [ ! -f "$smoke" ]; then
    echo "[$s] no smoke.sh"; failed="$failed $s"; continue
  fi
  [ -x "$smoke" ] || chmod +x "$smoke" 2>/dev/null || true
  echo "===== $s ====="
  bash "$smoke"; rc=$?
  echo
  case "$rc" in
    0) passed="$passed $s";;
    3) skipped="$skipped $s";;
    *) failed="$failed $s";;
  esac
done

echo "================== SUMMARY =================="
echo "PASS:${passed:- (none)}"
echo "SKIP:${skipped:- (none)}   (dependency not installed)"
echo "FAIL:${failed:- (none)}"
echo "(RUN_L2=${RUN_L2:-0} RUN_L3=${RUN_L3:-0} RUN_L4=${RUN_L4:-0})"

if [ -z "$failed" ]; then
  echo "RESULT: OK"
  exit 0
else
  echo "RESULT: FAILURES — see logs above"
  exit 1
fi
