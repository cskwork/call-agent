---
name: kilo-call
description: Delegate to the kilo (kilocode) CLI. Use ONLY when the user explicitly says "kilo" or "kilocode", OR when the task requires (a) parallel git-branch agent fan-out (multiple agents on separate branches working concurrently), (b) a specific non-Anthropic provider (Bedrock / Vertex / Gemini / OpenAI / Mistral / Ollama / LM Studio / OpenRouter), or (c) image generation. Do NOT use for routine code edits, planning, or analysis that Claude Code can do natively.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
---

# kilo-call

Shell out to the Kilo Code CLI (`kilo` / `kilocode`) for things Claude
Code does not do natively.

## When this skill fires

1. **Explicit name** — user mentions "kilo" or "kilocode".
2. **Feature gap** — user asks for:
   - Parallel git-branch agent fan-out (N agents, N branches, one repo)
   - A specific non-Anthropic provider that Claude Code does not have
     (Bedrock / Vertex / Gemini / OpenAI native / Mistral / Ollama /
     LM Studio / OpenRouter)
   - Image generation

Do NOT fire for: generic code work, planning, review, debugging — Claude
Code handles those.

## Preflight

```bash
command -v kilo >/dev/null || { echo "kilo not installed (npm i -g @kilocode/cli)" >&2; exit 2; }
kilo --version
# config must exist and have a kilocodeToken or configured provider
test -f "$HOME/.kilocode/cli/config.json" || { echo "Run: kilo auth" >&2; exit 2; }
```

## Canonical non-interactive call

```bash
kilo --auto --json --timeout 300 \
     --mode <architect|code|ask|debug> \
     "<PROMPT>"
```

`--auto` is required for any scripted call. `--json` makes output
parseable (one JSON event per line). `--timeout` is seconds.

## Mode selection

| Mode | Use for |
|---|---|
| `code` (default) | Implementation, edits, full toolset |
| `ask` | Read-only Q&A about the repo |
| `architect` | Plan a change without writing code outside `.kilo/plans/` |
| `debug` | Methodical narrow-down loop on a failing thing |

Skip `orchestrator` — deprecated in current kilo versions.

## Parallel fan-out (the headline feature)

```bash
# Run two kilo agents concurrently on separate branches
kilo --auto --json -p --timeout 600 \
     --mode code "Implement feature A" > /tmp/kilo-a.jsonl 2>&1 &
PA=$!
kilo --auto --json -p --timeout 600 \
     --mode code "Implement feature B" > /tmp/kilo-b.jsonl 2>&1 &
PB=$!
wait "$PA" "$PB"
```

Each `-p` invocation creates a new git branch automatically. Use `-eb
<branch>` to attach to an existing branch.

See [`scripts/kilo-parallel.sh`](scripts/kilo-parallel.sh) for a wrapper
that takes an array of prompts and gathers results.

## Provider override

```bash
kilo --auto --json --provider gemini --model gemini-2.5-pro "<PROMPT>"
kilo --auto --json --provider vertex --model claude-sonnet-4 "<PROMPT>"
kilo --auto --json --provider ollama --model llama3.3:70b "<PROMPT>"
```

Provider IDs accepted: `kilocode` (default), `anthropic`, `openai-native`,
`openrouter`, `bedrock`, `gemini`, `vertex`, `mistral`, `ollama`,
`lmstudio`, `openai`, `gemini-cli`. The provider must be pre-configured
in `~/.kilocode/cli/config.json`.

## Image generation

```bash
kilo --auto --json --mode code --timeout 300 \
     "Use the generateImage tool to produce <DESCRIPTION>. Save to <ABS_PATH>."
```

Verify the file exists after.

## Parsing `--json` output

Each line is a JSON object with `timestamp`, `type`, `content`, etc.
Relevant types:

- `say.text` — agent response text
- `say.api_req_finished` — has `tokenUsageSchema` and `cost`
- `say.completion_result` — final wrap-up
- `say.error` — errors
- `ask.command` / `ask.tool` — would normally need approval; in `--auto`
  mode these auto-resolve per `autoApproval` config

Extract final text:

```bash
jq -r 'select(.type=="say.completion_result") | .content' /tmp/kilo-out.jsonl
```

## See also

- [`patterns.md`](patterns.md) — parallel and provider patterns
- [`reference.md`](reference.md) — full mode and event matrix
- [`scripts/kilo-parallel.sh`](scripts/kilo-parallel.sh) — fan-out helper
