---
name: kiro-call
description: Delegate to AWS Kiro (the agentic IDE). Use ONLY when the user explicitly says "kiro", OR when the task is (a) registering an MCP server into Kiro's profile (`--add-mcp`), (b) opening a visual 3-way merge to resolve a conflict (`-m`), (c) opening a side-by-side diff viewer (`-d`), or (d) handing a prompt to Kiro's IDE chat (`kiro chat`) because the user wants Kiro's agent/edit/ask modes. Do NOT use for routine code edits, planning, or anything Claude Code can do natively in-terminal — Kiro pops a GUI window.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
---

# kiro-call

Shell out to the AWS Kiro IDE (`/usr/local/bin/kiro`, version 0.12.x). Kiro
is a VS Code-based agentic IDE; its CLI is a launcher, so calling Kiro
**opens a GUI window**. Use this skill only when the user wants Kiro's
GUI affordances or chat agent specifically.

## When this skill fires

1. **Explicit name** — user says "kiro".
2. **Feature gap** — user asks for:
   - Registering an MCP server into Kiro's user profile so Kiro can call
     it next time (`kiro --add-mcp <json>`)
   - A visual 3-way merge UI (`kiro -m base v1 v2 out`)
   - A side-by-side diff (`kiro -d a b`)
   - Handing a prompt to Kiro's IDE chat in `ask` / `edit` / `agent` mode
     (e.g. user has Kiro open and wants the prompt routed there)

Do NOT fire for: routine in-terminal coding, planning, or analysis —
those stay in Claude Code (Kiro's CLI is GUI-only, no headless mode).

## Preflight

```bash
command -v kiro >/dev/null || { echo "kiro not installed (https://kiro.dev)" >&2; exit 2; }
kiro --version | head -1
```

## Operation 1 — register an MCP server into Kiro

Easy automation target — no GUI, no chat, just a JSON-encoded server
spec written into Kiro's user profile.

```bash
./scripts/kiro-add-mcp.sh \
  '{"name":"weather","command":"npx","args":["-y","@weather/mcp"]}'
```

Underlying call:

```bash
kiro --add-mcp '<JSON>'
```

Useful when the user has set up an MCP server for Claude Code and wants
the same server available in Kiro's chat agent.

## Operation 2 — visual 3-way merge

```bash
./scripts/kiro-merge.sh <left> <right> <base> <output>
```

Opens Kiro's GUI merge editor on the four paths. The script blocks via
`--wait` so the calling agent can act on the result after the user
saves+closes. **Requires user interaction in the GUI.**

## Operation 3 — side-by-side diff

```bash
kiro -d <fileA> <fileB>
# add --wait to block until the user closes the window
```

## Operation 4 — hand prompt to Kiro chat

```bash
kiro chat -m <ask|edit|agent> -a <file> "<PROMPT>"
```

- Default mode is `agent` (full tools)
- `ask` is read-only Q&A
- `edit` makes targeted edits
- `-a` repeats — `-a path1 -a path2 ...` adds files as context
- stdin: `cat input.txt | kiro chat "Summarize this" -`

Opens (or reuses) a Kiro window. There is **no `--print` / `-p`
non-interactive output flag** in the current CLI — the response shows in
the IDE chat panel, not stdout. So this operation is a launcher, not a
result-fetcher.

## See also

- [`reference.md`](reference.md) — full CLI flag map + Kiro-specific
  data paths
- [`scripts/kiro-add-mcp.sh`](scripts/kiro-add-mcp.sh) — MCP register
  helper with JSON validation
- [`scripts/kiro-merge.sh`](scripts/kiro-merge.sh) — 3-way merge wrapper
