---
name: call-agent
description: Delegate the current task to a peer AI CLI when it is better suited than the host you are running in. Targets - OpenAI Codex ("codex"), Google Antigravity ("agy"/"antigravity"/"gemini cli"), AWS Kiro ("kiro"/"kiro-cli"), Claude Code ("claude"/"claude code"), Google NotebookLM ("notebooklm"/"nblm"). Use when the user names one of those tools, OR asks for a capability the host lacks - image generation, web search with Google grounding, natural-language-to-shell translation, document RAG over PDFs/URLs/YouTube, scientific-database queries (gnomAD/UniProt/PubMed), 1M-token-context planning, or a second-opinion review from a different model. Do NOT use for routine code edits, planning, or analysis the host can do natively.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
---

# call-agent - delegate to a peer AI CLI

Router. You (the host CLI) hand ONE task to a peer agentic CLI when the peer does it
better, then report the result back. This file is a router; load only the one
`reference/<target>/call.md` you route to - never all of them.

## Rule zero - never call yourself

Whichever CLI is reading this is the *host*. Routing a task to the host is a no-op (you
would just do it yourself). Delegate only to a DIFFERENT CLI whose capability the host
lacks. Inside Claude Code, never route to `claude`; inside Codex, never route to `codex`.

## Trigger policy (conservative - external CLIs spend separate credits)

Fire on TWO conditions only:

1. **Explicit name** - the user names a target tool.
2. **Capability gap** - the user asks for something the host cannot do natively.

Never auto-fire on generic "review / plan / refactor / debug" - the host is presumed
capable. When the win is unclear, ask before spending a peer's credits.

## Route (match the request to ONE target, then load its call.md)

| Signal in the request | Target | Needs binary | Load |
|---|---|---|---|
| "codex"; image generation; one-shot `codex review` | codex | `codex` | `reference/codex/call.md` |
| "agy" / "antigravity" / "gemini cli"; Google-grounded web search; image gen; science DB (gnomAD/UniProt/PubMed/ChEMBL) | agy | `agy` | `reference/agy/call.md` |
| "kiro" / "kiro-cli"; natural-language -> shell `translate`; MCP cross-register; AWS Bedrock peer opinion | kiro | `kiro-cli` | `reference/kiro/call.md` |
| "claude" / "claude code"; 1M-context planning; plan-mode (read-only) architecture; deep `--effort high` review | claude | `claude` | `reference/claude/call.md` |
| "notebooklm" / "nblm"; RAG / audio / mind-map over a PDF/URL/YouTube corpus | notebooklm | `notebooklm` | `reference/notebooklm/call.md` |

Tie-breakers: an explicit tool name always wins over a capability guess. Image
generation is offered by both `codex` (gpt-image-2, ChatGPT-auth, highest quality) and
`agy` - prefer `codex` when installed, fall back to `agy`.

## Preflight (every route)

Each `call.md` opens with a preflight (binary on PATH + auth). Run it first. If the
target binary is missing, surface that target's install hint verbatim and STOP - do NOT
silently fall back to another peer or fake the capability.

## Reference map (load only what the routed target needs)

| Load | When |
|---|---|
| `reference/<target>/call.md` | you routed to <target> (always) |
| `reference/agy/patterns.md`, `reference/codex/patterns.md` | need orchestration recipes (parallel fan-out, async jobs) |
| `reference/<target>/reference.md` | need the full flag table / gotchas (agy, codex, kiro, notebooklm) |
| `reference/agy/templates.md` | need copy-paste agy prompt scaffolds |
| `reference/<target>/scripts/*.sh` | the routed call.md tells you to run a wrapper script |

**Done =** target named in one line; preflight passed; the peer's output captured and
reported back verbatim (with cost / session id when the CLI returns it); any generated
file verified to exist; no silent fallback, no faked capability.
