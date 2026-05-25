# codex-call — Patterns

## Pattern 1 — Single image (Path A, no API key)

```bash
./scripts/codex-imagegen.sh \
  "Polished hero shot of a matte ceramic mug on a wood desk, soft window light" \
  "/abs/path/hero.png"
```

The wrapper handles sandbox/approval flags and verifies the output file.

## Pattern 2 — Multiple variants in parallel

```bash
./scripts/codex-imagegen.sh "<PROMPT v1>" /abs/path/v1.png &
./scripts/codex-imagegen.sh "<PROMPT v2>" /abs/path/v2.png &
./scripts/codex-imagegen.sh "<PROMPT v3>" /abs/path/v3.png &
wait
```

Independent prompts only — these do not share state. Concurrency 3 is a
safe default; higher risks rate-limit responses.

## Pattern 3 — Batch (Path B, needs `OPENAI_API_KEY`)

For 10+ images, prefer the bundled batch helper:

```bash
cat > /tmp/jobs.jsonl <<'JSONL'
{"prompt":"...", "out":"/abs/path/01.png", "size":"1024x1024"}
{"prompt":"...", "out":"/abs/path/02.png", "size":"1024x1024"}
JSONL

python "$HOME/.codex/skills/.system/imagegen/scripts/image_gen.py" generate-batch \
  --input /tmp/jobs.jsonl --concurrency 4
```

## Pattern 4 — `codex review` for diff scoping

```bash
# Review only uncommitted changes
./scripts/codex-review.sh --uncommitted

# Review vs a base branch (PR-style)
./scripts/codex-review.sh --base main

# Review a single commit
./scripts/codex-review.sh --commit abc1234
```

Use this when you want a fresh model's read on the same diff Claude just
produced.

## Pattern 5 — Structured output (planning artifacts)

```bash
cat > /tmp/plan.schema.json <<'JSON'
{ "type":"object", "required":["steps","risks"],
  "properties":{
    "steps":{"type":"array","items":{"type":"string"}},
    "risks":{"type":"array","items":{"type":"string"}}}}
JSON

codex exec --sandbox read-only --skip-git-repo-check \
  --output-schema /tmp/plan.schema.json \
  -o /tmp/plan.json \
  "Plan migration from X to Y; respond per schema."
```

## Anti-patterns

- Using Codex for image gen when the user did NOT ask for an image —
  unnecessary cost.
- Using Path B when Path A would work — Path A is free under the ChatGPT
  subscription; Path B is metered.
- Forgetting `--skip-git-repo-check` for ad-hoc image jobs outside a
  repo.
- Running long agentic loops in `codex exec` — that defeats the "Codex
  for capability gap" framing. Use Claude Code for the loop, Codex for
  the one capability.
