# Changelog — 2026-10-28

## v0.4.0 — Codex async stall detection (release preparation)

2026-10-28 retro: on 2026-10-26 a delegated Codex job stayed at "starting"
for 58 minutes while the host's wait loop failed to notice. Async jobs now
record their start time and track the mtime and size of stderr, JSONL events,
and the last assistant message.

- `start` / `start-review` accept `--stall SECS` (default 600 seconds).
  `CODEX_ASYNC_STALL`, when set, overrides the option; the limit persists per job.
- A live job with unchanged output reports `stalled idle=<sec>s`; `wait`
  prints that state and returns exit code **3** before the wait cap.
  `codex-review.sh` propagates a stalled review as exit code **3**.
- Completion and hard timeout retain their existing status/exit behavior.
  Stall detection does not kill the job; the host stops it and reports.
- The async guide and Pattern 6 include a host-side output-liveness Monitor
  loop and a bounded recovery: stop, report, then at most one resume when a
  thread ID exists. No thread ID means no resume; review jobs cannot resume.
- Offline regressions use fake Codex processes and run from the existing
  smoke harness without model calls or credits, even if Codex is not installed.

`VERSION` records **0.4.0**; both READMEs link to it. Earlier versions were
recorded only as Git tags. This prepares the minor release without creating
a tag, pushing, or merging.
