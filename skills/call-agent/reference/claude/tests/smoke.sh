#!/usr/bin/env bash
# claude-call smoke test (this skill runs INSIDE Codex CLI; we test the
# wrapper scripts here, since you can also invoke them from any shell)
set -u

SKILL=claude-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# L0 — claude binary present
if command -v claude >/dev/null 2>&1; then
  V=$(claude --version 2>&1 | head -1)
  note "L0 ok: claude $V"
else
  note "L0 skip: claude not on PATH"
  exit 3
fi

# L1 — wrapper scripts syntax-valid + help works
for s in scripts/preflight-auth.sh scripts/preflight-shell.sh scripts/claude-implement.sh scripts/claude-plan.sh scripts/claude-review.sh; do
  if bash -n "$SCRIPT_DIR/$s"; then
    note "L1a ok: $s syntax"
  else
    fail "L1a: $s syntax error"
  fi
done
if claude --help >/dev/null 2>&1; then
  note "L1b ok: claude --help"
else
  fail "L1b: claude --help failed"
fi

if grep -Eq 'dangerously-skip-permissions|bypassPermissions' \
  "$SCRIPT_DIR/scripts/claude-implement.sh" "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
  fail "L1d: Claude write path weakens permission checks"
else
  note "L1d ok: Claude write path keeps permission checks"
fi

if grep -q -- '--max-budget-usd 0.05' "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
  note "L1e ok: shell probe cost capped"
else
  fail "L1e: shell probe needs a cost cap"
fi

if grep -q -- '--safe-mode' "$SCRIPT_DIR/scripts/preflight-shell.sh" \
  && grep -q -- '--tools Bash' "$SCRIPT_DIR/scripts/preflight-shell.sh" \
  && grep -q -- '--max-turns 4' "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
  note "L1f ok: shell probe context minimized"
else
  fail "L1f: shell probe must isolate configuration and tools"
fi

# L1c — preflight runs (may exit 2 if no auth; that's the "warn" path)
if "$SCRIPT_DIR/scripts/preflight-auth.sh" >/dev/null 2>&1; then
  note "L1c ok: preflight passed (auth present)"
  HAVE_AUTH=1
else
  note "L1c warn: preflight reports no auth — run \`claude auth login\`"
  HAVE_AUTH=0
fi

# L2s — shell-capability probe (small model call)
if [ "${RUN_L2_SHELL:-0}" = "1" ] && [ "$HAVE_AUTH" = "1" ]; then
  if "$SCRIPT_DIR/scripts/preflight-shell.sh"; then
    note "L2s ok: shell capability"
  else
    fail "L2s: shell capability unavailable"
  fi
fi

# L2 — actual claude -p round-trip
if [ "${RUN_L2:-0}" = "1" ] && [ "$HAVE_AUTH" = "1" ]; then
  OUT=$(claude -p --print \
          --output-format json \
          --no-session-persistence \
          "Reply with exactly: OK" 2>/dev/null \
        | python3 -c 'import sys,json
d=json.load(sys.stdin)
if isinstance(d,list): d=next((x for x in d if isinstance(x,dict) and x.get("type")=="result"),{})
print(d.get("result",""))' \
        | tr -d '[:space:]')
  if echo "$OUT" | grep -qi 'ok'; then
    note "L2 ok: round-trip"
  else
    fail "L2: unexpected response: $OUT"
  fi
fi

# L3 — plan & review wrappers
if [ "${RUN_L3:-0}" = "1" ] && [ "$HAVE_AUTH" = "1" ]; then
  if "$SCRIPT_DIR/scripts/claude-plan.sh" "Plan a one-line hello-world script. One step only." >/tmp/claude-plan-test.txt 2>/dev/null \
     && [ -s /tmp/claude-plan-test.txt ]; then
    note "L3a ok: claude-plan.sh"
  else
    fail "L3a: claude-plan.sh failed"
  fi
  rm -f /tmp/claude-plan-test.txt
fi

exit "$FAIL"
