#!/usr/bin/env bash
# kilo-call smoke test
# L0+L1 always; L2 needs RUN_L2=1 (uses provider credit); L3 image gen
set -u

SKILL=kilo-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

# L0 — binary present
if command -v kilo >/dev/null 2>&1; then
  V=$(kilo --version 2>&1 | head -1)
  note "L0 ok: kilo $V"
else
  fail "L0: kilo not on PATH (npm i -g @kilocode/cli)"
  exit "$FAIL"
fi

# L1 — help works and config dir exists
if kilo --help >/dev/null 2>&1; then
  note "L1a ok: kilo --help"
else
  fail "L1a: kilo --help failed"
fi
CFG="$HOME/.kilocode/cli/config.json"
if [ -f "$CFG" ]; then
  note "L1b ok: config exists at $CFG"
else
  note "L1b warn: $CFG missing — user must run \`kilo auth\`"
fi

# Also verify our parallel wrapper script is syntax-valid
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if bash -n "$SCRIPT_DIR/scripts/kilo-parallel.sh"; then
  note "L1c ok: kilo-parallel.sh syntax"
else
  fail "L1c: kilo-parallel.sh syntax error"
fi

# L2 — round-trip; gated on a usable config (token or configured providers)
if [ "${RUN_L2:-0}" = "1" ]; then
  if [ ! -f "$CFG" ]; then
    note "L2 skipped: no config"
  else
    USABLE=$(python3 - "$CFG" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    print("no"); sys.exit(0)
CRED_KEYS = ("kilocodeToken","anthropicApiKey","openaiApiKey","openRouterApiKey",
             "geminiApiKey","mistralApiKey","awsAccessKey","vertexJsonCredentials",
             "ollamaBaseUrl","lmStudioBaseUrl","apiKey","token")
def has_creds(obj):
    if not isinstance(obj, dict): return False
    return any((obj.get(k) or "").strip() if isinstance(obj.get(k), str)
               else bool(obj.get(k)) for k in CRED_KEYS)
if has_creds(d):
    print("yes"); sys.exit(0)
provs = d.get("providers") or []
print("yes" if any(has_creds(p) for p in provs) else "no")
PY
)
    if [ "$USABLE" != "yes" ]; then
      note "L2 warn: kilocodeToken empty and no providers — run \`kilo auth\` or \`kilo config\`"
    else
      RAW=$(kilo --auto --json --timeout 60 --nosplash \
                  "Reply with exactly: OK" 2>&1)
      if echo "$RAW" | grep -q 'Configuration Error'; then
        note "L2 warn: kilo reports incomplete config — run \`kilo config\`"
      else
        OUT=$(echo "$RAW" | grep '"type":"say.completion_result"' | tail -1)
        if echo "$OUT" | grep -qi 'OK'; then
          note "L2 ok: round-trip"
        else
          fail "L2: unexpected response: $(echo "$RAW" | head -c 200)"
        fi
      fi
    fi
  fi
fi

# L3 — image gen (config + provider required)
if [ "${RUN_L3:-0}" = "1" ]; then
  if [ ! -f "$CFG" ]; then
    note "L3 skipped: no config"
  else
    IMG=$(mktemp -u -t kilo-smoke-XXXXXX).png
    kilo --auto --json --mode code --timeout 180 --nosplash \
         "Use the generateImage tool to make a 64x64 solid red PNG and save it to $IMG. Then exit." \
         >/dev/null 2>&1
    if [ -s "$IMG" ]; then
      note "L3 ok: image at $IMG"
      rm -f "$IMG"
    else
      fail "L3: no image at $IMG"
    fi
  fi
fi

exit "$FAIL"
