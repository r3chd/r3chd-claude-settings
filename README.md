# r3chd-claude-settings

My Claude Code config, shared between my macOS and Windows machines. `install.sh` symlinks everything into `~/.claude`, so edits on either side land in this repo.

## Install

```sh
./install.sh
```

- macOS: run as-is.
- Windows: run from Git Bash with Developer Mode on (needed for real symlinks). Install `jq` for the status line.

Any real file already in `~/.claude` gets renamed to `<name>.bak.<timestamp>` first. Safe to re-run.

## What's here

| Path | What | Why |
|---|---|---|
| `CLAUDE.md` | Global instructions | Commits and PRs stay with me, work comes in small reviewable chunks with a drafted commit message, no Claude attribution, no em-dashes. |
| `rules/context7.md` | Rule to fetch library docs with the `ctx7` CLI | Training data goes stale; current docs beat guessing at APIs. |
| `commands/resume-bullets.md` | `/resume-bullets` | Turns a repo's history into a LaTeX resume project entry. |
| `skills/find-docs/` | Docs lookup skill | Same idea as the context7 rule, as an invocable skill. |
| `skills/linear-init/` | `/linear-init` | Backfills a repo's real git/PR history into a Linear project (milestones, issues, status update). Manual invoke only. |
| `statusline-command.sh` | Status line | Model, repo/branch with dirty counts, session tokens, and 5h/7d plan usage bars. |
| `settings.json` | Main settings | See below. |

### settings.json

- **Model: Opus, effort `xhigh`.** Quality over speed by default; I drop down per session when I need to.
- **Plugins:** discipline plus memory.
  - `superpowers`, `mattpocock-skills`: process (plan, TDD, debugging, review).
  - `ponytail`: keeps solutions minimal and stops over-engineering.
  - `claude-mem`: memory across sessions.
  - `humanizer`: strips AI tells from prose.
  - `claude-md-management`: keeps CLAUDE.md files current.
- **Notification hook:** plays a sound on macOS, does nothing elsewhere.
- **MCP servers:** `unity-mcp` (binary path is Mac-only, so it fails to start on Windows) and `drawio`.

## Not synced

- `~/.claude/skills/synced/`: managed by Anthropic account sync.
- History, sessions, caches, project memory, plugin installs, `.claude.json`: machine-local or generated.

## Gotcha

Claude Code may rewrite `settings.json` as a plain file (for example after `/model` or toggling a plugin), which breaks the symlink. If `ls -l ~/.claude/settings.json` shows a plain file, copy any changes you want into the repo and re-run `./install.sh`.
