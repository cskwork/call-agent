#!/usr/bin/env bash
# notebooklm-call smoke test
set -u

SKILL=notebooklm-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# L0 — binary present (warn-only, since it's pip-installed)
if command -v notebooklm >/dev/null 2>&1; then
  V=$(notebooklm --version 2>&1 | head -1)
  note "L0 ok: notebooklm $V"
  HAVE_NB=1
else
  note "L0 warn: notebooklm not installed — pip install 'notebooklm-py[browser]'"
  HAVE_NB=0
fi

# L1 — preflight script syntax + help
if bash -n "$SCRIPT_DIR/scripts/notebooklm-preflight.sh"; then
  note "L1a ok: preflight syntax"
else
  fail "L1a: preflight syntax error"
fi
if [ "$HAVE_NB" = "1" ]; then
  if notebooklm --help >/dev/null 2>&1; then
    note "L1b ok: notebooklm --help"
  else
    fail "L1b: notebooklm --help failed"
  fi
fi

# L2 — auth check (uses local cookies; no Google quota)
if [ "${RUN_L2:-0}" = "1" ] && [ "$HAVE_NB" = "1" ]; then
  if "$SCRIPT_DIR/scripts/notebooklm-preflight.sh" >/dev/null 2>&1; then
    note "L2 ok: preflight passed"
  else
    note "L2 warn: preflight failed (likely no auth — run 'notebooklm login')"
  fi
fi

# L3 — actual round-trip ask against a tiny notebook
if [ "${RUN_L3:-0}" = "1" ] && [ "$HAVE_NB" = "1" ]; then
  NB_TITLE="cc-agent-call-smoke-$$"
  NB_ID=$(notebooklm create "$NB_TITLE" --json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin).get("id",""))' || true)
  if [ -z "$NB_ID" ]; then
    fail "L3: could not create notebook"
  else
    ANS=$(notebooklm ask --notebook "$NB_ID" "Reply with exactly: OK" 2>/dev/null | tr -d '[:space:]')
    if echo "$ANS" | grep -qi 'ok'; then
      note "L3 ok: ask round-trip"
    else
      fail "L3: unexpected ask response: $ANS"
    fi
    notebooklm delete --notebook "$NB_ID" --yes >/dev/null 2>&1 || true
  fi
fi

exit "$FAIL"
