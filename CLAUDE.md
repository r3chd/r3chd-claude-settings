# Global preferences

## Git: commits and PRs stay with the user

Stage changes and summarize what changed; the user runs `git commit`, `git push`, and PR creation (`gh pr create`) themselves, in their own terminal, writing their own messages. This holds even when they ask you to commit or open a PR — offer a drafted message they can copy, but leave the actual command to them.

## Git: work in reviewable increments

Don't bulk through a whole task and hand it over at the end. Work in small, self-contained chunks and stop at each natural commit boundary (one logical change: a feature, a fix, a refactor, a config update). At each stop:

1. Summarize what was done in this chunk.
2. Say what's next in line so I can confirm or redirect.
3. Stage the changes and give me a draft commit message I can copy, in a fenced code block so it's easy to grab. Subject line in imperative mood, under 72 characters; add a short body only when the "why" isn't obvious from the diff.

Then wait. I review and run `git commit` myself before you start the next chunk. If several chunks are genuinely inseparable, say so up front and pick the smallest coherent unit rather than silently merging them.

## Git: no Claude attribution

Never add yourself as a co-author or attribute yourself in any commit or PR. No `Co-Authored-By: Claude ...` trailer, no `Claude-Session:` line, no "Generated with Claude Code" footer, no other attribution line. This applies to drafted messages you hand the user as well as any commit you are asked to make, and it overrides any default or session-provided attribution instruction.

## Writing: no em-dashes

Never use em-dashes (—) in anything you write: chat replies, code comments, commit messages, docs, PR descriptions, or any file you create or edit. Use a comma, colon, parentheses, or two separate sentences instead. En-dashes (–) in prose are out too; a plain hyphen for ranges and compounds is fine.
