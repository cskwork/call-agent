# Changelog — 2026-06-21

## Add a `gpt-pro` delegation target (ChatGPT Pro deep reasoning)

### Why
Users want a deep second opinion from **ChatGPT Pro** (the slow, maximal-reasoning
tier) using their existing flat-fee subscription. That tier is effectively
web-only: the Pro model via the API is priced around $30/$180 per 1M tokens, which
defeats the economic point of a subscription. So call-agent needs a target that
gets a high-signal context in front of ChatGPT Pro on the web — not one that calls
an API.

### What we verified first (live, this machine)
Chrome **149**, Playwright **1.54**, `@playwright/cli` **0.1.14**:
- Chrome **136+ blocks `--remote-debugging-port` on the default profile** — the
  user's current logged-in main session is not reachable by raw CDP/port. A
  dedicated debug profile works but is a *new, not-logged-in* session.
- After enabling `chrome://inspect/#remote-debugging` "Allow remote debugging…",
  `playwright-cli attach --cdp=chrome` *reaches* the real session but then
  **crashes** on the browser's extension `service_worker` target (assertion in
  bundled playwright-core 1.61-alpha — latest, no upgrade fixes it).
- `attach --extension=chrome` needs the Playwright Web-Store extension installed
  (+ manual per-tab authorization).

Conclusion: live browser-drive of the real session is blocked by tooling, not by
permissions. So the target is **context-bundle-primary**, with a fail-loud
experimental live path.

### Decisions
- **Bundle is the reliable path.** `gpt-pro-bundle.sh` collects `--files` under
  `source/`, adds a git tree/log, **fail-fast secret scan** (refuse to package on
  a hit; no in-place redaction), writes a framed `PROMPT.md`
  (Role+Context+Question+What-to-examine+Output), emits `PASTE_THIS.txt` for small
  bundles, tars it, and `pbcopy`s the prompt. The human pastes + uploads + reads
  the answer back — call-agent does the hard part (scoping, framing, sanitizing).
- **First target with `pbcopy`/`tar`/secret-sanitization.** No existing target
  needed these; they are self-contained in the gpt-pro scripts.
- **Live drive shipped but fail-loud.** `gpt-pro-live.sh` attaches via the
  Playwright extension relay and drives a logged-in tab, but exits 2 with the
  bundle as fallback whenever it cannot attach, detect a login, or bind the
  upload. It never prints fake success. Verified caveats are in `call.md`.
- **Live input via file upload, not keystrokes.** Actual runs showed `type`/paste
  of an 18KB prompt truncates and the composer mangles it; the driver now
  `upload`s the bundle as a file and types only a one-line instruction. Completion
  detection waits for generation to STOP (no stop-button) + a stable answer, so it
  no longer captures interim "thinking" text. The poll uses one eval per tick on
  the PATH binary against a wall-clock deadline (per-call node startup otherwise
  miscounts time and trips the outer timeout). Short Q&A captured cleanly
  (e.g. "PONG"); ChatGPT's attachment binding is intermittent, so file-heavy
  reviews are most reliable via the bundle + a manual attach.
- **Output location configurable.** `${GPT_PRO_OUT:-~/Documents/GPT Pro Analysis}/<date>-<slug>/`,
  overridable per call with `--out`, so it slots into any workflow.

### Alternatives rejected
- **API call to GPT-5.x Pro.** Rejected: ~$30/$180 per 1M tokens defeats the
  flat-fee-subscription motive; codex already covers programmatic OpenAI reasoning.
- **Dedicated debug-profile Chrome for live drive.** Rejected as default: it is a
  fresh, not-logged-in session; users want their current session, and the raw-CDP
  attach crashes on real-browser extensions anyway.
- **Live-only target.** Rejected: too fragile to be the primary path today.

### Files
- `skills/call-agent/reference/gpt-pro/call.md` — routing doc (when, preflight,
  bundle path, sanitization, experimental live drive, see-also).
- `skills/call-agent/reference/gpt-pro/scripts/{gpt-pro-bundle,gpt-pro-preflight,gpt-pro-live}.sh`
- `skills/call-agent/reference/gpt-pro/tests/smoke.sh` — L0/L1 incl. sanitizer fail-fast.
- `skills/call-agent/SKILL.md` — Route table row + frontmatter triggers.
- `tests/run-all.sh` — `gpt-pro` added to the agent loop.
- `README.md`, `README.ko.md` — target-table row (EN/KO).
- `docs/index.html` — new card; "five → six targets" across hero/pill/og/section.
- `install.sh` — unchanged (router is the single installed skill).

### Verification
- `bash -n` on all three scripts + smoke.sh + run-all.sh: pass.
- `gpt-pro-preflight.sh`: exit 0; reports tar/pbcopy and live-dep availability.
- `gpt-pro-bundle.sh "…" --files …`: produces `PROMPT.md` + `source/` + sibling
  `.tar.gz`; prompt on clipboard (`pbpaste`).
- Sanitizer: planted `sk-…` without `--allow-secrets` → exit 2, `file:line`
  printed, no bundle left.
- `./tests/run-all.sh` (L0/L1): gpt-pro PASS, others unchanged.
- `./install.sh --dry-run`: links unchanged; router picks up the new target.
