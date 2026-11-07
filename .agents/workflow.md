---
name: workflow
description: Followups, specs/plans, branching and how subagents work in SaftUI (no Jira)
last_updated: 2026-11-07
covers:
  - 'docs/followups.md'
  - 'docs/superpowers/**'
---

# Workflow

Repo-specific overlay on the user-level `~/.claude/CLAUDE.md` "Planning workflow" + "Followup detection" sections. **Read those first.** This doc only names SaftUI's instances (file locations, branch shapes) and the repo's exceptions, and does **not** restate the rules.

**Exception: no Jira.** SaftUI skips the Jira Epic/ticket step. After brainstorm → spec → plan, the work is implemented directly in session with subagents (`superpowers:subagent-driven-development`). Everything else in the planning workflow still applies.

## Doc taxonomy (where things live)

| Content | Location |
| ------- | -------- |
| Design spec (from `superpowers:brainstorming`) | `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` |
| Implementation plan (from `superpowers:writing-plans`) | `docs/superpowers/plans/YYYY-MM-DD-<topic>.md` |
| Followups queue | `docs/followups.md` (single file) |
| Agent-actionable repo rules | `.agents/<topic>.md` |
| Subagent-driven-development ledger, briefs, reports, review packages | `.superpowers/sdd/<plan>/` (git-excluded scratch, not committed) |

## Followups

- The queue lives at `docs/followups.md`. Its format (entry template, Active/Resolved/Abandoned) is defined in user-level `~/.claude/CLAUDE.md` "Followup detection". Follow it verbatim. There are no `**Ticket:**` lines here because there's no Jira.
- Skim the queue at the start of substantial new work. Move an entry to Resolved in the same change that ships its fix, with a `**Resolved YYYY-MM-DD:**` line, and update the ToC.

## Specs and plans

- Specs come out of `superpowers:brainstorming` → `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
- Plans come out of `superpowers:writing-plans` → `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`.
- The date prefix is the authoring day, not the ship day. Both directories are flat, with no nesting.
- New requests that extend a running plan are appended to it as new numbered tasks, citing the user's words. Spec decisions the user changes get a dated "Revised" note in the spec.

## Branching

- Never commit on `main` (see user-level "Branching"). `main` is protected on the remote (`github.com:Safturento/SaftUI`) and is far behind.
- **`modular` is the active integration branch.** Work lands there. Push only when the user asks.

## Working with subagents in this repo

- **Worktrees.** The Agent tool's `isolation: "worktree"` creates worktrees from `main`, which is stale here, and an agent's `git reset --hard` to fix that may be denied. So:
  1. Create the worktree yourself at the right commit: `git worktree add -b <branch> .claude/worktrees/<branch> <commit>`.
  2. Tell the agent to work only in that path. Don't use `isolation: "worktree"`.
  3. Once the agent reports, cherry-pick its commits onto `modular`, then `git worktree remove` the worktree and `git branch -D` its branch.
- **Briefs.** A worker gets:
  - the task brief, extracted with the SDD `task-brief` script
  - the shared rules
  - pointers into `.agents/`
  - a report path in the session scratchpad, since `.superpowers/` isn't present inside a worktree

  Workers never dispatch subagents.
- **Reviews.** Every task gets a reviewer, and fix rounds get a scoped re-review. For changes that touch Blizzard frames, ask the reviewer to check taint against the forever source specifically (see `.agents/taint.md`).
- **Merge conflicts.** Parallel tasks often conflict where each appends defaults to the end of `SaftUI-Misc/config.lua`, or edits `docs/followups.md`. Keep both sides.

## Commits and files

- Subjects are lowercase `module: imperative summary` (`minimap: …`, `core: …`, `unitframes: …`, `docs: …`). End with the session's `Co-Authored-By` line.
- **Stage by explicit path only.** Never `git add -A`, `git add .` or a directory: the user may have unrelated local changes.
- **Line endings.** `.gitattributes` normalizes to LF on commit, but some working-tree files are CRLF. Keep each file's existing endings when editing (check with `file`).
- **Verification.** There is no Lua tooling or test runner. Verify by re-reading changed files end to end and checking Blizzard names against the source (`.agents/clients.md`). Every change ends with a short in-game checklist for the user, and nothing counts as verified until the user confirms it in game.

## See also

- User-level `~/.claude/CLAUDE.md`: "Planning workflow", "Followup detection", "Branching".
- User-level `~/.claude/conventions/documentation.md`: generic plan/spec structure.
