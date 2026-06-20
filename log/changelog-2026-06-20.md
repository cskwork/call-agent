# Changelog — 2026-06-20

## Consolidate the 5 `*-call` skills into one `call-agent` router

### Why
The repo shipped five sibling skills — `agy-call`, `kiro-call`, `codex-call`,
`notebooklm-call`, `claude-call`. Each had its own `SKILL.md` with a `description`
that competes for the model's attention at skill-routing time, and each installed
into a host-specific directory. Five descriptions, five frontmatter blocks, five
install cases. Adding a new target meant a new skill folder plus an `install.sh`
mapping. The `supergoal` skill demonstrates the cleaner shape: one skill whose
`SKILL.md` is a *router* — it classifies intent against a small table and lazily
loads exactly one `reference/<x>.md`. This change adopts that pattern.

### Decisions
- **One skill, `call-agent`, that routes by intent.** `SKILL.md` is a thin router:
  a Route table maps request signals (explicit tool name OR host-capability gap) to
  one target, then loads `reference/<target>/call.md`. Trigger policy is unchanged
  and still conservative (explicit name or real capability gap only).
- **Each old skill became `reference/<agent>/`, moved intact.** The five skill
  folders were `git mv`d under `skills/call-agent/reference/` (agy, codex, kiro,
  claude, notebooklm), keeping their `scripts/`, `tests/`, and support `.md`s in the
  same relative layout. Each `SKILL.md` → `call.md` with its YAML frontmatter
  stripped (the router owns the single frontmatter now). Because the per-agent
  folder shape is preserved, every `./scripts/...` reference and every smoke test's
  `$(dirname)/.. → scripts/` path resolves with zero edits — verified by run-all.
- **Host generalization: never call yourself, otherwise any installed peer is a
  target.** Previously `claude-call` only ran inside Codex and the rest only inside
  Claude. The single skill installs into BOTH `~/.claude/skills` and `~/.codex/skills`;
  "Rule zero" in the router tells the host not to delegate to itself. This is strictly
  more capable (e.g. Codex can now reach `agy`/`kiro` too) and removes the per-host
  install mapping. Per-agent `call.md` wording was generalized from "Claude Code" to
  "the host CLI".
- **`install.sh` simplified.** Links one skill into both host dirs. `--uninstall`
  also removes the legacy `*-call` symlinks so a migration leaves nothing stale.
  Positional per-skill selection dropped (only one skill now); `--dry-run` /
  `--uninstall` kept.

### Alternatives rejected
- **Keep five skills, add a sixth dispatcher.** Rejected: leaves the five competing
  descriptions in place — the exact problem — and adds indirection on top.
- **Thin shims: keep each `*-call` as a 1-line pointer to the router.** Rejected by
  the user in favor of a clean replacement; shims keep stale trigger names alive and
  multiply files for no behavioral gain.
- **Preserve original per-host eligibility (Host column in the table).** Rejected in
  favor of the simpler "never call yourself" rule, which is more capable and needs no
  host detection in the installer.

### Files
- `skills/call-agent/SKILL.md` — new router (Route table + reference map + rule zero).
- `skills/call-agent/reference/{agy,codex,kiro,claude,notebooklm}/` — the five former
  skills, moved; each `SKILL.md` → `call.md`, frontmatter stripped, host wording
  generalized.
- `install.sh` — single-skill install into both host dirs; legacy-link cleanup on
  `--uninstall`.
- `tests/run-all.sh` — iterates `skills/call-agent/reference/<agent>/tests/smoke.sh`.
- `README.md`, `README.ko.md` — rewritten for the single-router architecture.

### Verification
- `bash -n install.sh tests/run-all.sh`: pass.
- `./install.sh --dry-run`: links `call-agent` into `~/.claude/skills` and
  `~/.codex/skills`. `--uninstall --dry-run`: no stale links present.
- `./tests/run-all.sh` (L0/L1): PASS agy codex claude, SKIP kiro notebooklm
  (CLIs absent), RESULT OK. codex/claude L1 confirm wrapper scripts resolve from the
  new `reference/<agent>/scripts/` location.

## Fix `claude -p --output-format json` parsing (now returns an array)

### Why
Found while running `RUN_L2=1` against claude 2.1.183: `claude -p --output-format
json` no longer returns a single `{type:"result", result:...}` object — it returns a
JSON **array** of stream events (`system/init`, `rate_limit_event`, `assistant`,
`result`). The claude target parsed it as `json.load(sys.stdin).get("result")`, which
throws `AttributeError: 'list' object has no attribute 'get'`. This broke the real
delegation wrappers (`claude-plan.sh`, `claude-review.sh`), not only the smoke test —
both returned empty/errored. Pre-existing; the consolidation move (pure `git mv`) did
not introduce it, only surfaced it under L2.

### Fix
Collapse a list payload to its `type == "result"` element before reading `.result`
(and `.total_cost_usd` / `.session_id`): `if isinstance(d, list): d = next((x for x in
d if x.get("type")=="result"), {})`. Dict payloads (older claude) still work, so the
fix is backward-compatible. Applied to all three copies of the parser —
`reference/claude/scripts/claude-plan.sh`, `claude-review.sh`, and
`reference/claude/tests/smoke.sh` — and documented the array shape in
`reference/claude/call.md` Output handling.

### Verification
- `claude` smoke `RUN_L2=1`: was FAIL (`'list' object has no attribute 'get'`), now
  `L2 ok: round-trip`, rc=0.
- Real wrapper `claude-plan.sh "<trivial task>"` returns non-empty plan text
  end-to-end (127 bytes).
- `bash -n` on all three edited files: pass.
