---
name: kiro-call
description: Delegate to AWS Kiro CLI (`kiro-cli`, the AWS Q successor — a headless agentic terminal). Use ONLY when the user explicitly says "kiro" or "kiro-cli", OR when the task is (a) natural-language → shell command translation (`kiro-cli translate`), (b) a second opinion from an AWS Bedrock / Q-family model, or (c) cross-registering an MCP server so Kiro can use it (`kiro-cli mcp`). Do NOT use for routine code work — Claude Code does that natively.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
---

# kiro-call

Shell out to AWS Kiro CLI (`kiro-cli`) — a headless agentic terminal
backed by AWS Bedrock / Kiro-managed models. Distinct from the Kiro IDE
launcher (`/usr/local/bin/kiro`); this skill targets the CLI binary at
`~/.local/bin/kiro-cli` only.

## When this skill fires

1. **Explicit name** — user says "kiro", "kiro-cli", or "ask kiro".
2. **Feature gap** — user asks for:
   - Natural-language → shell command translation
     (`kiro-cli translate "<NL>"`)
   - A peer opinion from a non-Anthropic / non-OpenAI model (AWS Bedrock
     family via Kiro)
   - Registering an MCP server in Kiro so Kiro can call it in future
     sessions (`kiro-cli mcp`)

Do NOT fire for: routine code edits, planning, or analysis — Claude
Code handles those.

## Preflight

```bash
./scripts/kiro-preflight.sh
```

Verifies `kiro-cli` is on PATH, the user is logged in
(`kiro-cli whoami`), and at least one agent profile exists.

## Canonical headless call

```bash
./scripts/kiro-chat.sh "<PROMPT>"

# with options
./scripts/kiro-chat.sh --agent default --model claude-sonnet-4 "<PROMPT>"
```

Underlying:

```bash
kiro-cli chat --no-interactive --trust-all-tools "<PROMPT>"
```

`--no-interactive` prints final response to stdout and exits. `-a` /
`--trust-all-tools` skips approval prompts (required for scripted use).
Tighten the trust set with `--trust-tools=fs_read,fs_write,execute_bash`
when you don't want full tool access.

## Natural-language to shell

```bash
kiro-cli translate "find every PDF modified in the last week and copy them into /tmp/recent-pdfs/"
```

Use this when the user gives a fuzzy task and a one-liner shell command
is the right answer. Kiro returns the proposed command for review
before running.

## MCP server registration

```bash
# List servers Kiro knows about
kiro-cli mcp list

# Add a server (same shape as Claude Code's mcp config)
kiro-cli mcp add my-server --command npx --args "-y @scope/mcp-server"

# Remove
kiro-cli mcp remove my-server
```

Use when the user wants an MCP server they're using in Claude Code
available to Kiro chat sessions too.

## Resume a previous session

```bash
kiro-cli chat --no-interactive --resume "<follow-up>"             # most recent
kiro-cli chat --no-interactive --resume-id <SESSION_ID> "<msg>"   # specific
kiro-cli chat --list-sessions --format json                       # list
```

Sessions live in `~/.kiro/sessions/cli/{id}.json` (metadata) and
`{id}.jsonl` (turns).

## Model selection

```bash
kiro-cli chat --list-models --format json   # discover
kiro-cli chat --no-interactive --model <NAME> "<PROMPT>"
```

Default model is the user's profile setting. Override when the user
wants a specific peer model (e.g. AWS Bedrock Claude or Q-family).

## See also

- [`reference.md`](reference.md) — full flag map, agent profiles, MCP
- [`scripts/kiro-chat.sh`](scripts/kiro-chat.sh) — headless wrapper
- [`scripts/kiro-translate.sh`](scripts/kiro-translate.sh) — NL → shell
- [`scripts/kiro-preflight.sh`](scripts/kiro-preflight.sh) — readiness
