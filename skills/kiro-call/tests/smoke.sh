#!/usr/bin/env bash
# kiro-call smoke test — only L0+L1 (kiro is a GUI launcher with no
# headless output; round-trip tests would require GUI inspection)
set -u

SKILL=kiro-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# L0 — binary present
if command -v kiro >/dev/null 2>&1; then
  V=$(kiro --version 2>&1 | head -1)
  note "L0 ok: kiro $V"
else
  fail "L0: kiro not on PATH (install from https://kiro.dev)"
  exit "$FAIL"
fi

# L1a — help works
if kiro --help >/dev/null 2>&1; then
  note "L1a ok: kiro --help"
else
  fail "L1a: kiro --help failed"
fi
if kiro chat --help >/dev/null 2>&1; then
  note "L1b ok: kiro chat --help"
else
  fail "L1b: kiro chat --help failed"
fi

# L1c — wrapper scripts syntax-valid
for s in scripts/kiro-add-mcp.sh scripts/kiro-merge.sh; do
  if bash -n "$SCRIPT_DIR/$s"; then
    note "L1c ok: $s syntax"
  else
    fail "L1c: $s syntax error"
  fi
done

# L1d — kiro-add-mcp.sh validates JSON without invoking kiro
# (use a bad payload that would fail validation before the kiro call)
BAD_OUT=$("$SCRIPT_DIR/scripts/kiro-add-mcp.sh" '{"name":"x"}' 2>&1 || true)
if echo "$BAD_OUT" | grep -q "missing required keys"; then
  note "L1d ok: kiro-add-mcp validates payload shape"
else
  fail "L1d: kiro-add-mcp accepted bad payload: $BAD_OUT"
fi

# L2/L3 deliberately skipped — kiro CLI has no headless mode.
# Manual verification recipes are in reference.md.

exit "$FAIL"
