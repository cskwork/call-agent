#!/usr/bin/env bash
# codex-call smoke test
set -u

SKILL=codex-call
FAIL=0
note() { printf '[%s] %s\n' "$SKILL" "$*"; }
fail() { printf '[%s] FAIL: %s\n' "$SKILL" "$*" >&2; FAIL=1; }

# L0 — binary present
if command -v codex >/dev/null 2>&1; then
  V=$(codex --version 2>&1 | head -1)
  note "L0 ok: codex $V"
else
  fail "L0: codex not on PATH"
  exit "$FAIL"
fi

# L1 — help works + auth detected + scripts syntax-valid
if codex --help >/dev/null 2>&1 && codex exec --help >/dev/null 2>&1 && codex review --help >/dev/null 2>&1; then
  note "L1a ok: codex / exec / review --help"
else
  fail "L1a: codex help subcommands failed"
fi

if [ -f "$HOME/.codex/auth.json" ]; then
  note "L1b ok: ChatGPT auth file present"
else
  note "L1b warn: no ~/.codex/auth.json — run \`codex login\`"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
for s in scripts/codex-imagegen.sh scripts/codex-review.sh; do
  if bash -n "$SCRIPT_DIR/$s"; then
    note "L1c ok: $s syntax"
  else
    fail "L1c: $s syntax error"
  fi
done

# L2 — non-interactive round-trip
if [ "${RUN_L2:-0}" = "1" ]; then
  OUTFILE=$(mktemp -t codex-smoke-XXXXXX)
  if codex exec --sandbox read-only --skip-git-repo-check \
       -o "$OUTFILE" "Reply with exactly: OK" >/dev/null 2>&1; then
    if grep -qi 'ok' "$OUTFILE"; then
      note "L2 ok: round-trip"
    else
      fail "L2: unexpected response in $OUTFILE: $(head -c 200 "$OUTFILE")"
    fi
  else
    fail "L2: codex exec failed"
  fi
  rm -f "$OUTFILE"
fi

# L3 — actual image gen via wrapper
if [ "${RUN_L3:-0}" = "1" ]; then
  IMG=$(mktemp -u -t codex-smoke-img-XXXXXX).png
  if "$SCRIPT_DIR/scripts/codex-imagegen.sh" \
       "A small 64x64 solid red square. Minimal, no detail." \
       "$IMG" >/dev/null 2>&1 && [ -s "$IMG" ]; then
    note "L3 ok: image at $IMG"
    rm -f "$IMG"
  else
    fail "L3: no image at $IMG"
  fi
fi

exit "$FAIL"
