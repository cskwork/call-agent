# Changelog — 2026-05-30

## codex-call: unify code review onto the async runner; add `stop`

### Why
A `codex review` (and the separate `omc ask codex` path) ran **synchronously
with no timeout**, so a stalled run blocked the host for 43 minutes. Cleanup
relied on `pkill -f "codex exec ..."`, a broad pattern sweep that hits the
permission prompt and was denied — leaving no clean cancel path.

### Decisions
- **Review → async, caller waits (bounded).** `codex-review.sh` no longer calls
  `codex review` directly. It launches a detached background job via
  `codex-async.sh start-review`, then blocks only up to `--wait` seconds
  (default 540). A review that outlasts the cap keeps running detached; the
  caller polls/stops it. A single call can therefore never hang forever.
- **Hard `--timeout` stays OFF by default.** Tens-of-minutes reviews are
  legitimate; auto-killing them is worse than a bounded wait. The wait cap (not
  a process kill) is what bounds caller blocking. `--timeout` remains opt-in as
  a safety net.
- **`stop <JOB_DIR>` subcommand.** Cancels by the recorded pid + its children
  (`pgrep -P` depth-first walk), never `pkill -f`. Targeted `kill` does not trip
  the broad-kill permission prompt. Writes a synthetic rc=143 if the subshell's
  EXIT trap did not fire on SIGTERM, so `status` still reports a finished job.

### Constraints honored
- `codex review` has no `--json`/`-o` (reference.md): it prints markdown to
  stdout, so `start-review` captures stdout → `last.txt` and `cd`s into the repo
  in the subshell (review has no `-C`).
- bash 3.2 / macOS: kept the `${TBIN[@]+"${TBIN[@]}"}` set -u-safe empty-array
  expansion; arrays defaulted before expansion.

### Files
- `skills/codex-call/scripts/codex-async.sh` — added `start-review`, `stop`,
  `kill_tree`, `make_job_dir`, `build_tbin`, `preflight` helpers.
- `skills/codex-call/scripts/codex-review.sh` — rewritten to delegate to async.
- `skills/codex-call/SKILL.md`, `patterns.md` — documented the above.
- `skills/codex-call/tests/smoke.sh` — L5 exercises the `stop` path (no credit).
- `.gitignore` — added `.env` / `.env.*` (Gitea token never committed).

### Verification
- `bash -n` on both scripts: pass.
- Full smoke suite with `RUN_L4=1` (real `codex exec` async round-trip + L5 stop).
- Real `codex review` of this change set via `codex-review.sh`.
