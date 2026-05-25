#!/usr/bin/env bash
# notebooklm-preflight.sh — verify notebooklm-py is installed and authed.
# Exit codes: 0 ok, 2 setup needed, 1 unexpected error.
set -uo pipefail

note() { printf '[nblm-preflight] %s\n' "$*"; }
fail() { printf '[nblm-preflight] FAIL: %s\n' "$*" >&2; }

# 1. binary
if ! command -v notebooklm >/dev/null; then
  fail "notebooklm not on PATH"
  echo "  Install: pip install 'notebooklm-py[browser]'" >&2
  exit 2
fi
note "notebooklm: $(command -v notebooklm)"

# 2. python version
if ! command -v python3 >/dev/null; then
  fail "python3 not on PATH"; exit 2
fi
PY=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')
note "python: $PY"
python3 - <<'PY' || { fail "Python < 3.10"; exit 2; }
import sys
sys.exit(0 if sys.version_info >= (3, 10) else 1)
PY

# 3. playwright + chromium
if ! python3 -c 'import playwright' 2>/dev/null; then
  fail "playwright not importable"
  echo "  Install: pip install 'notebooklm-py[browser]'" >&2
  exit 2
fi
# chromium check is best-effort; don't hard-fail
python3 -c 'from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    bp = p.chromium.executable_path
    import os, sys
    sys.exit(0 if bp and os.path.exists(bp) else 3)' 2>/dev/null \
  && note "playwright chromium ok" \
  || note "playwright chromium not installed — run: playwright install chromium"

# 4. auth — the careful check
AUTH_JSON=$(notebooklm auth check --test --json 2>/dev/null || true)
if [ -z "$AUTH_JSON" ]; then
  fail "notebooklm auth check returned nothing"
  echo "  Run: notebooklm login" >&2
  exit 2
fi

if echo "$AUTH_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(2)
ok = d.get("status") == "ok" and d.get("checks", {}).get("token_fetch") is True
sys.exit(0 if ok else 2)'; then
  note "auth ok"
else
  fail "auth not valid (token_fetch failed)"
  echo "  Run: notebooklm login" >&2
  exit 2
fi

note "preflight passed"
exit 0
