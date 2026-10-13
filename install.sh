#!/bin/bash
# Symlink this repo's config into ~/.claude. Safe to re-run.
# Windows: run from Git Bash with Developer Mode on (needed for real symlinks).
set -e
export MSYS=winsymlinks:nativestrict
repo=$(cd "$(dirname "$0")" && pwd)
dest="$HOME/.claude"
mkdir -p "$dest/skills"

link() {
  local src="$repo/$1" dst="$dest/$1"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%s)"
    echo "backed up existing $1"
  fi
  ln -sfn "$src" "$dst"
  echo "linked $1"
}

for f in CLAUDE.md settings.json statusline-command.sh rules commands; do link "$f"; done
# One link per skill so ~/.claude/skills/synced stays machine-managed
for s in "$repo"/skills/*/; do link "skills/$(basename "$s")"; done
