---
name: agy-call
description: Delegate to Google Antigravity (agy) CLI. Use ONLY when the user explicitly says "agy", "antigravity", or "gemini cli", OR when the task is image generation, web research that needs Google Search grounding, a second AI opinion on a code/architecture decision, or a specialized scientific/biology database query (gnomAD, UniProt, PubMed, etc.). Do NOT use for routine code edits, planning, or analysis that Claude Code can do natively.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
---

# agy-call

Shell out to Google's Antigravity CLI (`agy`) for capabilities Claude
Code cannot do natively.

## When this skill fires

Two conditions only:

1. **Explicit name** — user mentions "agy", "antigravity", or "gemini cli".
2. **Feature gap** — user asks for one of:
   - Web research that requires Google Search grounding (live web, citations)
   - Image generation
   - A second AI perspective on code/architecture (different model lineage)
   - Specialized scientific database queries (gnomAD, UniProt, PubMed, ChEMBL, etc.)

Do NOT fire for: generic code review, refactor, plan, file analysis,
debugging. Claude Code handles those.

## Preflight

```bash
command -v agy >/dev/null || { echo "agy not installed. See https://antigravity.google/cli" >&2; exit 2; }
agy --version
```

## Canonical invocation

```bash
agy -p "<PROMPT>" --print-timeout 3m0s 2>&1
```

Always use `-p` (non-interactive). Default timeout 3m, bump to 5m for
research or image jobs, 10m only for science DB queries that may chain
many API calls.

## Output handling

`agy` prints plain text on stdout. Three patterns:

```bash
# Capture
RESULT=$(agy -p "..." --print-timeout 3m0s 2>&1)

# Persist
agy -p "..." --print-timeout 5m0s > /tmp/agy-out.md 2>&1

# Parallel fan-out (two independent prompts)
agy -p "Q1" --print-timeout 3m0s > /tmp/q1.txt 2>&1 &
P1=$!
agy -p "Q2" --print-timeout 3m0s > /tmp/q2.txt 2>&1 &
P2=$!
wait "$P1" "$P2"
```

## Image generation (always include the save path IN the prompt)

```bash
agy -p "Generate a polished hero image of a matte ceramic mug on a wood desk. Save the final PNG to /abs/path/hero.png" \
    --dangerously-skip-permissions \
    --print-timeout 5m0s
```

`agy` does not create an artifact dir for you. You must put the absolute
target path in the prompt and confirm the file exists afterward.

## Workspace scoping (read other dirs)

```bash
agy -p "Review the code in this repo and answer X" \
    --add-dir "$(pwd)" \
    --add-dir /other/repo \
    --print-timeout 5m0s
```

Repeat `--add-dir` per directory.

## Conversation continuation

```bash
agy -c -p "Follow-up question"                            # most recent
agy --conversation <id> -p "Follow-up question"           # specific
```

## See also

- [`patterns.md`](patterns.md) — five reusable orchestration recipes
- [`reference.md`](reference.md) — full flag table, model behavior
- [`templates.md`](templates.md) — copy-paste prompt scaffolds
