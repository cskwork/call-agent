# kilo-call — Reference

Verified against `kilo --help` v0.6.0.

## Top-level flags

| Flag | Notes |
|---|---|
| `-m, --mode` | `architect` \| `code` \| `ask` \| `debug` \| `orchestrator` (deprecated) |
| `-w, --workspace PATH` | Working dir (default: cwd) |
| `-a, --auto` | Non-interactive — required for any script call |
| `-j, --json` | One JSON event per line (requires `--auto`) |
| `-c, --continue` | Resume last conversation in this workspace |
| `-t, --timeout SEC` | Hard timeout for `--auto` |
| `-p, --parallel` | Spawn on a new git branch |
| `-eb, --existing-branch BRANCH` | Attach `-p` to existing branch |
| `-pv, --provider ID` | Provider override (must be pre-configured) |
| `-mo, --model NAME` | Model override |
| `--nosplash` | Skip welcome banner |

Exit codes: `0` success, `124` timeout, `1` error.

## JSON event types

`{ timestamp, source, id, type, content, metadata }` per line.

### `say.*` (informational)

| `type` | Content |
|---|---|
| `say.text` | Agent response chunk (check `partial: bool`) |
| `say.reasoning` | Chain-of-thought (where surfaced) |
| `say.api_req_started/finished/retried` | Has `tokenUsageSchema`, `cost` |
| `say.command_output` | stdout/stderr from shell tools |
| `say.completion_result` | Final summary text |
| `say.error` | Errors |
| `say.image` | Generated image refs |
| `say.subtask_result` | When orchestrator dispatches subtasks |
| `say.checkpoint_saved` | Auto-save snapshots |

### `ask.*` (approval gates — auto-resolved in `--auto`)

`followup`, `command`, `tool`, `completion_result`, `browser_action_launch`,
`use_mcp_server`, etc. In `--auto` these are auto-approved per the
config's `autoApproval` policy.

## Providers

`kilocode` (default — uses `kilocodeToken`), `anthropic`, `openai-native`,
`openrouter`, `bedrock`, `gemini`, `vertex`, `mistral`, `ollama`,
`lmstudio`, `openai` (compat), `gemini-cli`.

Per-provider credentials live in `~/.kilocode/cli/config.json`. Edit via
`kilo config`. Validate before scripted call.

## Auth

`kilo auth` opens a browser flow and writes `kilocodeToken` to the
config. For self-hosted Kilo Gateway, the JWT decodes to the backend URL.

## Subcommands not used

`auth`, `config`, `debug` — user-side configuration; never scripted from
the skill.
