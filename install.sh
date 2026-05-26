#!/usr/bin/env bash
# install.sh — symlink cc-agent-call skills into ~/.claude/skills and ~/.codex/skills.
# Usage:
#   ./install.sh                   # install all skills
#   ./install.sh agy-call          # install just one skill
#   ./install.sh --dry-run         # show what would be linked
#   ./install.sh --uninstall       # remove all symlinks created here
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude/skills"
CODEX_DIR="$HOME/.codex/skills"

# host targets per skill (newline-separated; macOS bash 3.2 compatible)
declare_targets() {
  case "$1" in
    agy-call|kiro-call|codex-call) printf '%s\n' "$CLAUDE_DIR" ;;
    claude-call)                   printf '%s\n' "$CODEX_DIR"  ;;
    notebooklm-call)               printf '%s\n%s\n' "$CLAUDE_DIR" "$CODEX_DIR" ;;
    *) return 1 ;;
  esac
}

ALL_SKILLS="agy-call kiro-call codex-call notebooklm-call claude-call"

DRY=0
UNINSTALL=0
SELECTED=""

for a in "$@"; do
  case "$a" in
    --dry-run)   DRY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      sed -n '1,12p' "$0"
      exit 0
      ;;
    *) SELECTED="$SELECTED $a" ;;
  esac
done
SELECTED="${SELECTED:-$ALL_SKILLS}"

run() { [ "$DRY" = "1" ] && echo "DRY: $*" || eval "$*"; }

for skill in $SELECTED; do
  src="$REPO_DIR/skills/$skill"
  if [ ! -d "$src" ]; then
    echo "skip $skill: not found at $src" >&2
    continue
  fi
  declare_targets "$skill" | while IFS= read -r tdir; do
    [ -z "$tdir" ] && continue
    link="$tdir/$skill"
    if [ "$UNINSTALL" = "1" ]; then
      if [ -L "$link" ]; then
        run "rm '$link' && echo 'removed $link'"
      else
        echo "skip $link: not a symlink (will not delete)"
      fi
      continue
    fi
    run "mkdir -p '$tdir'"
    if [ -e "$link" ] && [ ! -L "$link" ]; then
      echo "skip $link: exists and is not a symlink (refusing to overwrite)"
      continue
    fi
    run "ln -snf '$src' '$link' && echo 'linked $link -> $src'"
  done
done
