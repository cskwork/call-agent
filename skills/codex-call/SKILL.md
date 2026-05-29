---
name: codex-call
description: Delegate to OpenAI Codex CLI for capabilities Claude Code lacks. Use ONLY when the user explicitly says "codex", OR when the task is image generation (Codex has the highest-quality option via the built-in image_gen tool and gpt-image-2). May also be used for a one-shot code review (`codex review`) when the user explicitly asks. Do NOT use for routine edits, planning, or analysis Claude Code can do natively.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
---

# codex-call

Shell out to OpenAI Codex CLI (`codex`) for things Claude Code does not
do natively — primarily **image generation**, secondarily one-shot
**code review** with diff scoping.

## When this skill fires

1. **Explicit name** — user mentions "codex".
2. **Feature gap** — user asks for image generation (Claude Code cannot
   do this; Codex has the best built-in option).

Do NOT fire for routine code work — Claude Code handles those.

## Preflight

```bash
command -v codex >/dev/null || { echo "codex not installed" >&2; exit 2; }
codex --version
test -f "$HOME/.codex/auth.json" || { echo "Run: codex login" >&2; exit 2; }
```

## Image generation (the headline use)

Two paths. **Prefer Path A** — uses Codex's ChatGPT subscription auth and
needs no API key.

### Path A — built-in `image_gen` tool via `codex exec`

```bash
./scripts/codex-imagegen.sh "<PROMPT>" "<ABS_OUTPUT_PATH.png>"
```

The wrapper script runs:

```bash
codex exec \
  --sandbox workspace-write \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  -C "$(dirname "$OUT")" \
  "Use the image_gen tool to generate: $PROMPT. Save the final PNG to $OUT"
```

After the call, verify `[ -s "$OUT" ]`.

### Path B — direct CLI helper (needs `OPENAI_API_KEY`)

Reserve for batch jobs or true alpha-transparency requirements.

```bash
export OPENAI_API_KEY=sk-...
python "$HOME/.codex/skills/.system/imagegen/scripts/image_gen.py" generate \
  --prompt "<PROMPT>" \
  --model gpt-image-2 \
  --quality high \
  --size 2048x1152 \
  --out "<ABS_PATH>"
```

`gpt-image-1.5 --background transparent` for native PNG alpha; gpt-image-2
cannot.

## Code review

```bash
./scripts/codex-review.sh                            # review uncommitted
./scripts/codex-review.sh --base main                # diff vs branch
./scripts/codex-review.sh --commit <SHA>             # one commit
./scripts/codex-review.sh --uncommitted --strict     # extra rigor
```

Underlying: `codex review` with mutually exclusive scope flags.

## One-shot non-interactive prompt

```bash
codex exec \
  --sandbox read-only \
  --skip-git-repo-check \
  -o /tmp/codex-out.txt \
  "<PROMPT>"
```

Output flags:
- `-o, --output-last-message FILE` — final message only (cleanest)
- `--json` — JSONL event stream
- `--output-schema FILE` — JSON Schema constrains final response

## Long-running / async jobs (don't block the host)

`codex exec` is synchronous — a multi-minute task blocks Claude Code until
it returns. For a long job you want to start now and collect later, use the
async wrapper:

```bash
JOB=$(./scripts/codex-async.sh start "<LONG TASK>" --sandbox read-only --timeout 10m)
./scripts/codex-async.sh status "$JOB"     # running | done rc=0 | timeout
./scripts/codex-async.sh wait   "$JOB" 600 # block until done (cap 600s)
./scripts/codex-async.sh result "$JOB"     # final message once finished
./scripts/codex-async.sh resume "$JOB" "<FOLLOW-UP>"  # continue same session
```

The job is a temp dir; poll it from any later turn. See `patterns.md`
Pattern 6 for the full recipe.

## See also

- [`patterns.md`](patterns.md)
- [`reference.md`](reference.md)
- [`scripts/codex-imagegen.sh`](scripts/codex-imagegen.sh)
- [`scripts/codex-review.sh`](scripts/codex-review.sh)
- [`scripts/codex-async.sh`](scripts/codex-async.sh)
