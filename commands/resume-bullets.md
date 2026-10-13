---
description: Generate a LaTeX resume project entry for a codebase using a 5-role bullet framework
argument-hint: [project name or path — defaults to the current directory]
allowed-tools: Bash(git log:*), Bash(git remote:*), Bash(pwd:*), Bash(find:*), Read, Grep, Glob
---

## Context

- Working directory: !`pwd`
- Git remote (if any): !`git remote get-url origin 2>/dev/null || echo "none"`
- First commit date: !`git log --reverse --format=%ad --date=format:'%b %Y' 2>/dev/null | head -1`
- Most recent commit date: !`git log -1 --format=%ad --date=format:'%b %Y' 2>/dev/null`
- Recent commit subjects (scope/status signal): !`git log --oneline -20 2>/dev/null`
- README (if present): !`find . -maxdepth 2 -iname "README*" 2>/dev/null -exec cat {} \; | head -150`
- Manifest files (tech stack signal): !`find . -maxdepth 2 \( -iname "package.json" -o -iname "requirements.txt" -o -iname "pyproject.toml" -o -iname "Cargo.toml" -o -iname "go.mod" -o -iname "*.csproj" \) 2>/dev/null`

## Target

$ARGUMENTS

If a project name or path was given above, focus the analysis there. If empty, use the current repository as the project.

## Your task

Produce one LaTeX resume project entry for this project using the **Resume Bullet Kit** framework: a fixed 5-role bullet structure, with wording written fresh per bullet — never reuse a sentence template across bullets.

Roles, in order:

1. **Scope & ownership** — what was built, its scale, and what makes it technically sound (not "a website" but *why it holds up*: e.g. server-authoritative, handles N concurrent users, race-condition-safe). Ground this in something real from the code/README/commits.
2. **Architecture decision** — one specific, real design choice (a named pattern, a structural decision, a technology tradeoff actually visible in the codebase) and its concrete payoff (extensibility, decoupling, performance, testability).
3. **Hard problem solved** — one genuinely tricky constraint the code had to handle (concurrency, privacy, consistency, latency, security, data integrity) and the mechanism that solved it. Find evidence for this in the code or commit history — don't invent one.
4. **Status / roadmap** *(optional — include only if the project is clearly still active: recent commits, TODOs, an explicit roadmap doc)* — what's still in flight.
5. **Tech stack** — flat list, ordered by relevance, no verbs.

Rules:

- Investigate before writing — read enough of the actual code (key modules, README, commit log, config/manifest files) to make bullets 1–3 true and specific. Do not fabricate features, scale numbers, or metrics that aren't supported by what you find; if a claim can't be grounded, phrase it more conservatively instead of inventing a number.
- Vary the opening verb across bullets 1–3 (Built, Designed, Implemented, Reduced, Migrated, Replaced, Introduced, Cut, Modeled, Enforced...) — they should not share a sentence shape.
- Infer the project name and date range from the repo (name from directory/README/package.json; dates from first/last commit — use "Present" as the end date if the most recent commit is recent).
- If something essential is missing or ambiguous (project name, whether it's still active, which job/role to prioritize in bullet ordering), ask a single clarifying question rather than guessing.

Output the result as a single LaTeX block in this exact macro style, with no commentary before or after it (unless you asked a clarifying question, or need to flag a claim you softened for lack of evidence):

```latex
\resumeProjectHeading
      {\textbf{PROJECT NAME (Category)}}{Start -- End (or Present)}
  \resumeItemListStart
    \resumeItem{...}
    \resumeItem{...}
    \resumeItem{...}
    \resumeItem{...}
    \resumeItem{...}
  \resumeItemListEnd
```
