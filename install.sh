#!/usr/bin/env bash
# install.sh — symlink the call-agent skill into ~/.claude/skills and ~/.codex/skills.
# call-agent is a single router skill that delegates to peer AI CLIs (codex, agy,
# kiro, claude, notebooklm). It links into BOTH host dirs so whichever CLI you run
# can reach the others.
# Usage:
#   ./install.sh                   # link call-agent into both host skill dirs
#   ./install.sh --dry-run         # show what would be linked, do nothing
#   ./install.sh --uninstall       # remove call-agent links + legacy *-call links
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL="call-agent"
SRC="$REPO_DIR/skills/$SKILL"
TARGET_DIRS="$HOME/.claude/skills
$HOME/.codex/skills"

# legacy per-CLI skills replaced by call-agent — cleaned up on --uninstall so a
# re-install does not leave stale, now-broken symlinks behind.
LEGACY_SKILLS="agy-call kiro-call codex-call notebooklm-call claude-call"

DRY=0
UNINSTALL=0
for a in "$@"; do
  case "$a" in
    --dry-run)   DRY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   sed -n '1,8p' "$0"; exit 0 ;;
    *) echo "ignoring '$a' — call-agent is the only skill" >&2 ;;
  esac
done

run() { [ "$DRY" = "1" ] && echo "DRY: $*" || eval "$*"; }

# remove a path only when it is a symlink (never delete a real dir/file)
rm_link() {
  if [ -L "$1" ]; then
    run "rm '$1' && echo 'removed $1'"
  elif [ -e "$1" ]; then
    echo "skip $1: not a symlink (will not delete)"
  fi
}

if [ ! -d "$SRC" ]; then
  echo "error: $SRC not found" >&2
  exit 1
fi

printf '%s\n' "$TARGET_DIRS" | while IFS= read -r tdir; do
  [ -z "$tdir" ] && continue
  link="$tdir/$SKILL"
  if [ "$UNINSTALL" = "1" ]; then
    rm_link "$link"
    for ls in $LEGACY_SKILLS; do rm_link "$tdir/$ls"; done
    continue
  fi
  run "mkdir -p '$tdir'"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "skip $link: exists and is not a symlink (refusing to overwrite)"
    continue
  fi
  run "ln -snf '$SRC' '$link' && echo 'linked $link -> $SRC'"
done
