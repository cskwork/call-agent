---
name: claude-call
description: Delegate from Codex CLI to Claude Code. Use ONLY when the user explicitly says "claude" or "claude code", OR when the task is (a) planning that benefits from a 1M-token context window, (b) plan-mode (read-only) architecture work, or (c) a deep code review at `--effort high`. Do NOT use for routine edits, image generation, or anything Codex can do natively.
---

# claude-call

Codex-side skill. Lets Codex CLI shell out to Claude Code (`claude -p`)
when Claude has a capability worth the extra hop.

## When this skill fires

1. **Explicit name** — user says "claude" or "claude code".
2. **Feature gap** — user asks for:
   - Planning over a very large codebase that benefits from Claude's
     1M-token context window
   - A plan-mode (guaranteed read-only) architecture pass
   - A deep code review (`--effort high`) for a second opinion

Do NOT fire for routine code edits — Codex handles those.

## Preflight

```bash
./scripts/preflight-auth.sh
```

Verifies `claude` is on PATH and either Claude-Max OAuth is active or
`ANTHROPIC_API_KEY` is set.

## Planning (read-only)

```bash
./scripts/claude-plan.sh "<TASK DESCRIPTION>"
```

Underlying call:

```bash
claude -p --print \
  --model opus --effort high \
  --permission-mode plan \
  --output-format json \
  --no-session-persistence \
  --add-dir "$PWD" \
  --append-system-prompt "You are a planner. Produce an actionable plan with numbered steps, risks, and acceptance criteria. Do not modify files." \
  "$PROMPT"
```

Parse `.result` for the plan text; `.total_cost_usd` and `.session_id`
for accounting.

## Code review (read-only, diff-aware)

```bash
./scripts/claude-review.sh "<PROMPT, e.g. 'Review staged changes for security'>"
```

Underlying call:

```bash
claude -p --print \
  --model opus --effort high \
  --permission-mode plan \
  --allowedTools "Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(git show:*)" \
  --output-format json \
  --no-session-persistence \
  --add-dir "$PWD" \
  --append-system-prompt "You are a strict code reviewer. Find correctness, security, and design bugs in the diff. Cite file:line." \
  "$PROMPT"
```

## Output handling

The JSON envelope:

```json
{
  "type": "result",
  "result": "...the actual response markdown...",
  "session_id": "...",
  "total_cost_usd": 0.0123,
  "duration_ms": 14567,
  "num_turns": 1
}
```

Surface `.result` verbatim to the user. Log `.total_cost_usd` if cost
tracking is requested.

## Auth fallbacks

- Preferred: Claude Max / Pro OAuth (stored at `~/.claude/auth.json`)
- Fallback: `ANTHROPIC_API_KEY` env var
- Long-lived token: `claude setup-token`

If the preflight reports neither, surface this verbatim:

> Run `claude auth login` (Max/Pro) or `export ANTHROPIC_API_KEY=sk-ant-...`

## See also

- [`scripts/preflight-auth.sh`](scripts/preflight-auth.sh)
- [`scripts/claude-plan.sh`](scripts/claude-plan.sh)
- [`scripts/claude-review.sh`](scripts/claude-review.sh)
