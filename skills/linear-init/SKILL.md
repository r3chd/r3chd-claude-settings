---
name: linear-init
description: Backfill a repo's entire development history into a Linear project as a fully written-up project — summary, description, milestones, one issue per shipped milestone, PR links, and a project status update. Only run when the user explicitly invokes /linear-init.
argument-hint: [linear-project-name-or-slug]
disable-model-invocation: true
allowed-tools: Bash(git log *) Bash(git branch *) Bash(git rev-list *) Bash(git remote *) Bash(git ls-remote *) Bash(git rev-parse *) Bash(git symbolic-ref *) Bash(gh pr list *) Bash(gh pr view *) Bash(gh repo view *) Bash(gh auth status *) Bash(ls *) Bash(find *) Read Glob Grep
---

Turn this repo's real history into a Linear project write-up: project summary + description, milestones, one issue per shipped milestone (git-verified details, PR links attached), and a project status update. This is a backfill of *facts already in the repo* — never invent dates, commit counts, or "what shipped" bullets. Every claim must trace to a git command, a PR, or a file actually in the repo.

## Quick context

- Remote: !`git remote -v 2>&1`
- Repo root: !`git rev-parse --show-toplevel 2>&1`
- gh auth: !`gh auth status 2>&1`

If the remote check fails (not a git repo), stop and tell the user this skill needs to run inside a git repository.

Determine the default branch yourself with an ordinary Bash call (not injected above, since it needs a fallback): try `git symbolic-ref --short refs/remotes/origin/HEAD` first — that already strips the `refs/remotes/` prefix, no `sed` needed. If it's unset (some clones never run `git remote set-head origin -a`), fall back to checking whether `main` or `master` exists locally or on the remote.

## Phase 0 — Linear tools

Run `ToolSearch` for `"linear"`. If nothing comes back, tell the user to connect the Linear MCP server (`claude mcp add --transport http linear https://mcp.linear.app/mcp -s user`, then `/mcp` to finish OAuth) and that they'll need to restart Claude Code or reinvoke this skill once it's connected. Don't guess a tool-name prefix — whatever comes back from `ToolSearch`, use those exact names for the rest of this skill.

## Phase 1 — Resolve team + project (don't skip the safety check)

List teams and projects. Match against `$ARGUMENTS` if given, otherwise against the repo's name (directory name, `package.json` "name", or the README H1).

- **One team, no ambiguity** → use it.
- **Multiple teams, or the project name is ambiguous** → ask the user with `AskUserQuestion`. Don't guess.
- **No matching project exists** → confirm with the user, then create one.
- **A matching project exists** → fetch it (`get_project` with `includeMilestones: true, includeResources: true`) and check whether it already has a description, milestones, or issues. If it's non-empty, **stop and ask the user** (via `AskUserQuestion`) whether to: refresh it in place (update existing issues/milestones rather than duplicating), leave it alone and just report what's there, or create a separate new project. Never silently overwrite or duplicate an already-populated project.

## Phase 2 — Gather source material

All from the repo itself, nothing invented:

- Full commit history: `git log --all --pretty=format:'%H %ad %s' --date=short`, plus `git log --first-parent <default-branch> --pretty=...` for the merge topology.
- Every local and remote branch: `git branch -vv --sort=-committerdate` and `git branch -r`. Note any branch that's ahead of its remote counterpart or not pushed at all (`git log origin/<default>..<branch>` vs. `git ls-remote --heads origin <branch>`) — this is exactly the kind of thing worth flagging later.
- PRs, if there's a GitHub remote: `gh pr list --state all --limit 200 --json number,title,state,headRefName,baseRefName,createdAt,mergedAt,url`.
- `README.md`, `CLAUDE.md` / `AGENTS.md`, `package.json` (name/description) — whatever exists.
- Any plan/roadmap/spec documents: search broadly (`docs/`, `plans/`, `ROADMAP.md`, `CHANGELOG.md`, or whatever this specific repo uses) rather than assuming a fixed layout. Don't assume the `docs/superpowers/plans/` convention — that's specific to some repos, not a standard.

## Phase 3 — Reconstruct milestones (verify every range before writing it down)

**If the repo has dedicated plan/spec docs** (one file per unit of work, as some repos do): use those as the milestone boundaries. For each, find the actual commit range with `git log`/`git rev-list --count` between the boundary commits — confirm the count and date span with a real command, never estimate.

**If there are no plan docs**, fall back to PR-based clustering:
- One candidate milestone per merged/closed PR (`gh pr list`), using the PR's own commit range and dates.
- Commits that landed directly on the default branch without a PR (common early in a project, or in solo repos) — group these by natural boundaries: date clusters (a gap of a day+ often marks a phase change), or `feat:`/`fix:`/`chore:` conventional-commit scopes if the repo uses them. Use judgment to land on a *reasonable* number of milestones (typically 3–15 for most repos) — never one milestone per commit, and don't force everything into one giant bucket either.

**Always verify** each range's commit count and date span with an actual `git log`/`git rev-list` call before it goes into any issue description. If you can't verify a claim, don't make it — say "commit history doesn't show X" rather than guessing.

**Open/in-progress work**: if the default branch has an unmerged feature branch, uncommitted changes, or a plan doc with unchecked items, that becomes a milestone in `Todo`/`In Progress` state with a checklist sourced from the actual plan doc checkboxes or actual remaining diffs — not invented next-steps.

## Phase 4 — Write it to Linear

1. **Project summary + description**: what the project is (from README/CLAUDE.md/package.json — don't paraphrase into something the docs don't say), stack, any documented architecture invariants, a milestone table, and a link to the GitHub repo as a project resource. Correct the project's `startDate` to the date of the first real commit (Linear defaults this to "whenever the project record was created," which is wrong for a backfill).
2. **Milestones**: one Linear project-milestone per cluster from Phase 3, with a real `targetDate` (last commit date in that cluster) — leave the in-progress one's target date unset unless the repo states a real deadline.
3. **Issues**: one per milestone, in the matching state (`Done` for shipped work, `In Progress`/`Todo` for what's open), linked to its milestone via the `milestone` field. Each description: what shipped (bulleted, from commit subjects / plan doc / PR body — not invented), branch name, PR link if one exists (attach via the issue's `links` field, not just inline text — Linear renders that as a real attachment), verified commit range, and real dates. If re-running on an already-populated project, update the matching existing issue instead of creating a duplicate — check `list_issues` on the project first and match by title.
4. **Project status update**: one `save_status_update` (type `project`) summarizing current state, a `health` value that's honest about it (`onTrack`/`atRisk`/`offTrack` — don't default to `onTrack` if the repo shows a stalled branch or a long gap since the last commit), and real next steps. Note in it that this was a git-history backfill and the date it was done, since Linear's own timestamps on backfilled items won't reflect the real historical dates.

After creating anything with a title containing `&`, `'`, or other characters that can get HTML-entity-encoded by the API (this has happened — `&` became `&amp;` in a title on creation), re-check the created object and fix the title if it got mangled.

## Phase 5 — Report back

A table: milestone → issue → state → link. Explicitly flag anomalies you found while gathering material — unpushed branches, uncommitted work, missing PRs, a milestone with no clear completion signal, stale plan docs that don't match what the code actually does. This is the same kind of thing worth surfacing that you'd want to know if someone else did this backfill for you: don't bury it in the middle of a long report, call it out.

If this environment has a working memory system (a `memory/MEMORY.md` the user's setup already maintains — check whether one exists rather than assuming), save a short project-type memory recording the resolved Linear team/project IDs and the issue-key prefix (e.g. "magic-word prefix is `D3V-`, not the project name") so a future session in this repo doesn't need to re-resolve them. Skip this step if no memory system is present — it's specific to some environments, not a hard requirement of this skill.
