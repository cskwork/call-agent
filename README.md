# cc-agent-call

Cross-CLI delegation skills. Lets one agentic CLI (Claude Code or Codex)
shell out to another (agy, kiro, codex, NotebookLM, Claude Code) when the
target tool has a feature the host lacks, or when the user explicitly
names it.

## Skills

| Skill | Host | What it does |
|---|---|---|
| [`agy-call`](skills/agy-call/) | Claude Code | Google Antigravity — Google Search grounding, image gen, second-opinion review, science DBs |
| [`kiro-call`](skills/kiro-call/) | Claude Code | AWS Kiro IDE — MCP registry bridge, 3-way merge GUI, diff viewer, IDE chat launcher |
| [`codex-call`](skills/codex-call/) | Claude Code | OpenAI Codex — highest-quality image gen (`gpt-image-2`), `codex review` |
| [`notebooklm-call`](skills/notebooklm-call/) | Claude Code + Codex | NotebookLM — document RAG, audio overview, web research import |
| [`claude-call`](skills/claude-call/) | Codex CLI | Claude Code — 1M-context plan-mode planning, deep code review |

## Install

```bash
git clone https://github.com/<you>/cc-agent-call
cd cc-agent-call
./install.sh             # symlinks all skills into the right host dirs
./install.sh agy-call    # install one skill
./install.sh --dry-run   # show what would be linked
```

`install.sh` links Claude-Code skills into `~/.claude/skills/<name>` and
Codex skills into `~/.codex/skills/<name>`. The `notebooklm-call` skill
is linked into both.

## Trigger policy

Each SKILL.md is configured so the host CLI invokes it ONLY when:

- the user explicitly names the target tool (e.g. "use agy", "ask codex"), OR
- the user asks for a capability the host CLI cannot do natively (image
  generation for Claude Code; 1M-context planning for Codex; etc.)

It does not hijack routine "review this code" or "plan this feature" —
the host CLI is presumed capable.

## Tests

```bash
./tests/run-all.sh                 # L0+L1 (binary present, help works)
RUN_L2=1 ./tests/run-all.sh        # adds round-trip prompts (uses credit)
RUN_L3=1 ./tests/run-all.sh        # adds feature exercises (image gen etc.)
```

Each skill also has `skills/<name>/tests/smoke.sh` you can run individually.

## Prerequisites per skill

| Skill | Required binary | Auth |
|---|---|---|
| `agy-call` | `agy` (Antigravity CLI) | `agy install` then sign in |
| `kiro-call` | `kiro` (AWS Kiro IDE) | first launch handles sign-in (https://kiro.dev) |
| `codex-call` | `codex` | `codex login` (ChatGPT) or `OPENAI_API_KEY` |
| `notebooklm-call` | Python 3.10+, `notebooklm` CLI | `notebooklm login` (browser, one-time) |
| `claude-call` | `claude` | `claude auth login` or `ANTHROPIC_API_KEY` |

## License

MIT
