# call-agent -> claude (Claude Code)

Loaded by the `call-agent` router when delegating to `claude`. Lets the
host CLI shell out to Claude Code (`claude -p`) when Claude has a
capability worth the extra hop (1M-token context, plan-mode, deep review).

## When to route here

1. **Explicit name** — user says "claude" or "claude code".
2. **Feature gap** — user asks for:
   - Planning over a very large codebase that benefits from Claude's
     1M-token context window
   - A plan-mode (guaranteed read-only) architecture pass
   - A deep code review (`--effort high`) for a second opinion

Do NOT route here for routine code edits — the host CLI handles those.

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

`claude -p --output-format json` returns a JSON **array** of stream events
whose final element is the result envelope:

```json
{
  "type": "result",
  "subtype": "success",
  "result": "...the actual response markdown...",
  "session_id": "...",
  "total_cost_usd": 0.0123
}
```

Pick the element with `type == "result"`, surface its `.result` verbatim,
and log `.total_cost_usd` if cost tracking is requested. (Older claude
returned this object directly, not wrapped in an array; the wrapper scripts
handle both shapes.)

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
