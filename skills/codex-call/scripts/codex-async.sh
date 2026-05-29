#!/usr/bin/env bash
# codex-async.sh — run a long Codex task in the BACKGROUND and collect the
# result when it finishes, without blocking the host CLI.
#
# Why: `codex exec` is synchronous. For a multi-minute job the host (Claude
# Code / Codex) would block. This wrapper turns one job into a small "job
# directory" you can poll, wait on, read the result of, and resume.
#
# Subcommands:
#   start  "<PROMPT>" [opts]      launch in background, print the JOB_DIR
#   status <JOB_DIR>              running | done rc=<n> | timeout | missing
#   wait   <JOB_DIR> [secs]       block until done (or until secs elapse)
#   result <JOB_DIR>              final assistant message (once done)
#   id     <JOB_DIR>              codex thread/session id (for `codex exec resume`)
#   resume <JOB_DIR> "<PROMPT>"   continue the SAME codex session (synchronous)
#
# start options:
#   --cd DIR         working root for codex (default: $PWD)
#   --sandbox MODE   read-only | workspace-write | danger-full-access (default read-only)
#   --timeout DUR    hard wall-clock cap, e.g. 5m or 300s (needs `timeout`/`gtimeout`)
#
# Exit codes: 0 ok, 2 setup/usage error.
set -uo pipefail

die() { echo "codex-async: $*" >&2; exit 2; }

# thread id lives in the very first JSONL event: {"type":...,"thread_id":"<uuid>"}
extract_thread_id() {
  python3 - "$1" <<'PY' 2>/dev/null
import sys, json
try:
    with open(sys.argv[1]) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            tid = json.loads(line).get("thread_id")
            if tid:
                print(tid); break
except Exception:
    pass
PY
}

cmd_start() {
  [ "$#" -ge 1 ] || die "usage: start \"<PROMPT>\" [--cd DIR] [--sandbox MODE] [--timeout DUR]"
  local prompt="$1"; shift
  local cdir="$PWD" sandbox="read-only" tmout=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --cd)      cdir="${2:?--cd needs a dir}"; shift 2;;
      --sandbox) sandbox="${2:?--sandbox needs a mode}"; shift 2;;
      --timeout) tmout="${2:?--timeout needs a duration}"; shift 2;;
      *) die "unknown option: $1";;
    esac
  done

  command -v codex >/dev/null || die "codex not installed"
  [ -f "$HOME/.codex/auth.json" ] || die "no codex auth. Run: codex login"
  [ -d "$cdir" ] || die "--cd: no such directory: $cdir"

  # Stable base dir: macOS reaps per-user $TMPDIR, which would orphan a job
  # polled across turns. Override with CODEX_ASYNC_HOME. (Jobs still do not
  # survive a host reboot — the detached subshell dies with the session.)
  local base="${CODEX_ASYNC_HOME:-$HOME/.codex/async-jobs}"
  mkdir -p "$base" || die "cannot create job base: $base"
  local job; job=$(mktemp -d "$base/job-XXXXXX") || die "cannot create job dir"
  printf '%s' "$prompt" > "$job/prompt.txt"

  # timeout is optional; only used when a duration is given and a binary exists
  local tbin=()
  if [ -n "$tmout" ]; then
    if command -v timeout >/dev/null;  then tbin=(timeout "$tmout")
    elif command -v gtimeout >/dev/null; then tbin=(gtimeout "$tmout")
    else echo "codex-async: no timeout binary; running without a cap" >&2; fi
  fi

  # Background subshell. The EXIT trap records the exit code UNCONDITIONALLY,
  # so `status` can always tell a finished job from one that crashed at launch.
  # ${tbin[@]+"${tbin[@]}"} is the set -u-safe expansion of a maybe-empty array
  # (a bare "${tbin[@]}" is a fatal "unbound variable" on bash 3.2 / macOS).
  (
    trap 'echo "$?" > "$job/rc"' EXIT
    ${tbin[@]+"${tbin[@]}"} codex exec --json --skip-git-repo-check \
      --sandbox "$sandbox" -C "$cdir" \
      -o "$job/last.txt" "$prompt" \
      > "$job/events.jsonl" 2> "$job/err.log"
  ) &
  echo "$!" > "$job/pid"
  echo "$job"
}

cmd_status() {
  local job="${1:?usage: status <JOB_DIR>}"
  [ -d "$job" ] || { echo "missing"; return 0; }
  if [ -f "$job/rc" ]; then
    local rc; rc=$(cat "$job/rc")
    # timeout/gtimeout return 124 when the cap is hit
    [ "$rc" = "124" ] && { echo "timeout"; return 0; }
    echo "done rc=$rc"; return 0
  fi
  local pid; pid=$(cat "$job/pid" 2>/dev/null || echo "")
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then echo "running"; else echo "done rc=?"; fi
}

cmd_wait() {
  local job="${1:?usage: wait <JOB_DIR> [secs]}"
  local cap="${2:-0}" waited=0
  [ -d "$job" ] || die "no such job dir: $job"
  local pid; pid=$(cat "$job/pid" 2>/dev/null || echo "")
  while [ ! -f "$job/rc" ]; do
    # Abnormal exit: process gone but no rc written — stop instead of looping.
    if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
      echo "wait: job process exited without recording rc" >&2; break
    fi
    sleep 2; waited=$((waited + 2))
    if [ "$cap" -gt 0 ] && [ "$waited" -ge "$cap" ]; then
      echo "wait: still running after ${cap}s" >&2; cmd_status "$job"; return 0
    fi
  done
  cmd_status "$job"
}

cmd_result() {
  local job="${1:?usage: result <JOB_DIR>}"
  [ -f "$job/rc" ] || die "job not finished yet (status: $(cmd_status "$job"))"
  if [ -s "$job/last.txt" ]; then cat "$job/last.txt"; else
    echo "codex-async: no final message; stderr tail:" >&2
    tail -n 20 "$job/err.log" >&2; return 1
  fi
}

cmd_id() {
  local job="${1:?usage: id <JOB_DIR>}"
  local tid; tid=$(extract_thread_id "$job/events.jsonl")
  [ -n "$tid" ] && echo "$tid" || die "no thread id yet (job may not have started)"
}

cmd_resume() {
  local job="${1:?usage: resume <JOB_DIR> \"<PROMPT>\"}"
  local prompt="${2:?resume needs a prompt}"
  local tid; tid=$(extract_thread_id "$job/events.jsonl")
  [ -n "$tid" ] || die "no thread id; cannot resume"
  # `resume` inherits the original session's sandbox; it rejects --sandbox/-C.
  codex exec resume --skip-git-repo-check \
    -o "$job/resume-last.txt" "$tid" "$prompt" >/dev/null 2>"$job/resume-err.log" \
    && cat "$job/resume-last.txt" \
    || { echo "codex-async: resume failed" >&2; tail -n 20 "$job/resume-err.log" >&2; return 1; }
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    start)  cmd_start  "$@";;
    status) cmd_status "$@";;
    wait)   cmd_wait   "$@";;
    result) cmd_result "$@";;
    id)     cmd_id     "$@";;
    resume) cmd_resume "$@";;
    ""|-h|--help)
      sed -n '2,30p' "$0";;
    *) die "unknown subcommand: $sub (try --help)";;
  esac
}

main "$@"
