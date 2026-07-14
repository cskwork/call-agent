#!/usr/bin/env bash
# claude-review.sh — delegate a code review to Claude Code (read-only).
# Usage: claude-review.sh "<REVIEW INSTRUCTIONS>"
# Returns: review markdown on stdout, cost on stderr.
set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 '<REVIEW INSTRUCTIONS>'" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/preflight-auth.sh" >/dev/null || exit 2
source "$SCRIPT_DIR/claude-mcp-tools.sh"
load_claude_allowed_tools \
  Read Grep Glob \
  'Bash(git diff:*)' 'Bash(git log:*)' 'Bash(git show:*)' 'Bash(git status:*)'

PROMPT="$*"
SYS="You are a strict code reviewer. Find correctness, security, and design bugs in the diff or the files indicated. Cite file:line. Group findings by severity (Critical / Major / Minor). No prose preamble."

OUT_JSON=$(claude -p --print \
  --model opus \
  --effort high \
  --permission-mode plan \
  "${CLAUDE_ALLOWED_TOOLS_ARGS[@]+"${CLAUDE_ALLOWED_TOOLS_ARGS[@]}"}" \
  --output-format json \
  --no-session-persistence \
  --add-dir "$PWD" \
  --append-system-prompt "$SYS" \
  "$PROMPT")

echo "$OUT_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if isinstance(d, list):
    d = next((x for x in d if isinstance(x, dict) and x.get("type") == "result"), {})
print(d.get("result", ""))
cost = d.get("total_cost_usd")
sid = d.get("session_id", "")
if cost is not None:
    print(f"[claude-review] cost=${cost:.4f} session={sid}", file=sys.stderr)
'
