---
name: notebooklm-call
description: Delegate document RAG to Google NotebookLM via the unofficial notebooklm-py CLI. Use ONLY when the user explicitly says "notebooklm", "nblm", or "use NotebookLM", OR when the task is querying / generating audio overviews / running research over a defined document corpus (PDFs, URLs, YouTube, etc.) — capabilities Claude Code and Codex do not have natively. Do NOT use for general code or text Q&A.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
---

# notebooklm-call

Wrap the `notebooklm` CLI (https://github.com/teng-lin/notebooklm-py) for
document RAG, audio/video overviews, mind maps, and research over a
user-defined corpus.

> ⚠️ **Unofficial library.** notebooklm-py uses undocumented Google APIs
> and your own browser session cookies. Endpoints can change without
> notice and heavy usage MAY get a Google account flagged. Do not use
> for production-critical pipelines.

## When this skill fires

1. **Explicit name** — user says "notebooklm" or "nblm".
2. **Feature gap** — user asks for RAG / audio-overview / video-overview
   / mind-map over a document collection. Neither Claude Code nor Codex
   does this natively.

Do NOT fire for: general Q&A, code analysis, or web research that does
not involve a curated document corpus.

## Preflight — run this FIRST every session

```bash
./scripts/notebooklm-preflight.sh
```

It checks:
- `notebooklm` is on PATH
- Python ≥ 3.10
- `playwright` chromium installed
- Auth cookies valid via `notebooklm auth check --test --json` (parsing
  BOTH `status:ok` AND `checks.token_fetch:true` — bare `--json` is a
  known false-positive trap)

If auth is missing, surface this verbatim:

> Run once: `notebooklm login` (opens Chromium for Google sign-in)

## Concurrency-safe call pattern

`notebooklm use <id>` mutates a per-profile active-notebook context file.
**Never** rely on it in scripted multi-agent runs. Always pass the
notebook ID explicitly:

```bash
notebooklm ask --notebook "$NB_ID" "<QUESTION>"
notebooklm generate audio --notebook "$NB_ID" --out audio.mp3
notebooklm download artifact --notebook "$NB_ID" <ART_ID> --out file.pdf
```

For truly parallel agents, also isolate state:

```bash
NOTEBOOKLM_HOME=/tmp/nblm-agent-A notebooklm ask --notebook "$NB_ID" "Q1" &
NOTEBOOKLM_HOME=/tmp/nblm-agent-B notebooklm ask --notebook "$NB_ID" "Q2" &
wait
```

## Common operations

| Need | Command |
|---|---|
| Create notebook | `notebooklm create "<TITLE>"` (prints `<ID>`) |
| Add a PDF source | `notebooklm source add --notebook <ID> /abs/path/file.pdf` |
| Add a URL | `notebooklm source add --notebook <ID> --url https://...` |
| Add YouTube | `notebooklm source add --notebook <ID> --youtube https://...` |
| Ask | `notebooklm ask --notebook <ID> "<Q>" --save-as-note` |
| Audio overview | `notebooklm generate audio --notebook <ID> --language en --format deep-dive --out a.mp3` |
| Mind map | `notebooklm generate mind-map --notebook <ID> --out map.json` |
| Research import | `notebooklm research --notebook <ID> --mode deep "<TOPIC>"` |

## Output

The CLI prints either plain text (for `ask`) or a path/ID (for
`generate`, `source add`, `create`). Use `--json` on commands that
support it for parseable output, and verify the file exists after any
`download` or `generate --out`.

## See also

- [`reference.md`](reference.md) — all verbs, env vars, gotchas
- [`scripts/notebooklm-preflight.sh`](scripts/notebooklm-preflight.sh)
- Upstream docs: https://github.com/teng-lin/notebooklm-py
