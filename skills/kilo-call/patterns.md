# kilo-call — Patterns

## Pattern 1 — Parallel branch fan-out (THE reason this skill exists)

User says: "implement feature A on one branch and feature B on another
in parallel using kilo."

```bash
./scripts/kilo-parallel.sh \
  "feat-a:Implement <A>" \
  "feat-b:Implement <B>"
```

The wrapper enforces `-p` per task, runs them concurrently, and gathers
each agent's final text + branch name + token usage.

## Pattern 2 — Cheap provider for high-volume work

User says: "run this batch with Ollama" or "use Gemini for this."

```bash
kilo --auto --json --provider ollama --model llama3.3:70b \
     --timeout 300 "<PROMPT>"
```

Pre-check the provider is configured:

```bash
jq -e --arg p "ollama" '.providers[] | select(.id==$p)' \
  "$HOME/.kilocode/cli/config.json" >/dev/null \
  || { echo "Provider not configured. Run: kilo config" >&2; exit 2; }
```

## Pattern 3 — Architect plan (no writes)

```bash
kilo --auto --json --mode architect --timeout 300 \
     "Plan <CHANGE>. Output the plan as markdown in .kilo/plans/."
```

The agent can only write inside `.kilo/plans/`. Useful when you want a
separate plan artifact reviewed before code lands.

## Pattern 4 — Image generation

```bash
kilo --auto --json --mode code --timeout 300 \
     "Use generateImage to make <DESC>. Save to <ABS_PATH>." \
     > /tmp/kilo-img.jsonl 2>&1
test -s "<ABS_PATH>" || echo "image not written" >&2
```

## Anti-patterns

- Running `kilo` for what Claude Code can do — wasted spend.
- Forgetting `--auto` with `--json` — interactive prompts hang.
- Spawning many parallel agents in a repo with uncommitted local changes
  — branches will stack on dirty state. Commit or stash first.
- Skipping the provider preflight check — silent fall-through to the
  default provider (`kilocode`) confuses cost attribution.
