# cc-agent-call — Design Spec

Date: 2026-05-26
Status: Approved (auto-mode)

## Purpose

Single public repo bundling five skills that let one agentic CLI delegate
work to another agentic CLI. Hosts: Claude Code (4 skills) and Codex CLI
(2 skills). Each skill is invoked only when the user explicitly names the
target tool, or when the target tool exposes a feature the host CLI
cannot perform natively (image generation, document RAG, 1M-context
planning, parallel git-branch agent fan-out).

## Skill matrix

| Skill | Host | Headline gap filled | Explicit triggers |
|---|---|---|---|
| `agy-call` | Claude Code | Google Search grounding, image gen, science DB | "agy", "antigravity", "gemini cli" |
| `kiro-call` | Claude Code | AWS Kiro CLI (`kiro-cli`) headless chat, NL→shell `translate`, MCP cross-registry, AWS Bedrock peer opinion | "kiro", "kiro-cli" |
| `codex-call` | Claude Code | High-quality image gen (gpt-image-2), `codex review` | "codex" |
| `notebooklm-call` | Claude Code + Codex | Document RAG via NotebookLM | "notebooklm", "nblm" |
| `claude-call` | Codex CLI | Plan-mode planning, deep code review, 1M context | "claude", "claude code" |

## Trigger policy

Two-line `description` per skill:

1. **Explicit-name trigger** — fires only when the user names the target
   tool. Default for everything.
2. **Feature-gap trigger** — fires automatically only when the user
   requests a capability the host CLI lacks. Limited list per skill,
   spelled out in the SKILL.md body.

Anti-pattern: never auto-fire on generic "review my code" or "plan this
feature" — the host CLI is presumed capable.

## Repo layout

```
cc-agent-call/
  README.md
  install.sh                       # symlinks skills into ~/.claude/skills and ~/.codex/skills
  docs/specs/                      # design docs
  skills/<name>/
    SKILL.md                       # frontmatter + body
    patterns.md | reference.md     # optional support docs
    scripts/                       # bash wrappers
    tests/smoke.sh                 # L0-L3 staged tests
  tests/run-all.sh                 # iterates each skill's smoke.sh
```

## Test strategy

Each skill ships `tests/smoke.sh` with up to four levels:

- **L0** — binary present, version readable. Always runs.
- **L1** — `--help` or dry-run. Zero network, zero cost.
- **L2** — single round-trip "Reply OK" prompt. Runs only when `RUN_L2=1`.
- **L3** — actual feature exercise (image gen, RAG query). Runs only when
  `RUN_L3=1`. Cleans up artifacts.

`tests/run-all.sh` runs every skill's `smoke.sh` and returns non-zero on
the first failure. CI deferred; manual run is the gate.

## Excluded items (from `claude-code-agy-CLI-skill`)

Per user request, the following reference triggers are NOT carried into
`agy-call`:

1. Deep multi-file codebase analysis (host CLI does this)
6. Long-running refactors that exhaust the context window (host CLI has
   compaction)
7. Tasks requiring many sequential tool calls (host CLI does this)

Kept: web research with Google Search grounding, image generation, second
AI perspective for review/architecture, specialized scientific DB
queries, explicit-name trigger.

## Open follow-ups (out of scope for v1)

- CI workflow with credential-free L0/L1 tests
- MCP transport alternative for `codex-call` (currently shell-out)
- Auto-detect host CLI on install (currently both link sets created)
