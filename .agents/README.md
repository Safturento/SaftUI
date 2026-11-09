---
description: How the .agents/ system works and how to extend it
last_updated: 2026-11-09
---

# `.agents/` — repo-scoped topic docs for AI agents

## 1. What this is

Two-tier progressive disclosure for agent context. Claude Code auto-loads `CLAUDE.md`, not `AGENTS.md`; a thin `CLAUDE.md` shim (`@AGENTS.md` import) at the repo root pulls the `AGENTS.md` content into context at launch. `.agents/<topic>.md` topic docs load on demand when referenced from the index. User-level skills (`~/.claude/skills/`) and conventions (`~/.claude/conventions/`) are orthogonal — they teach *how*; `.agents/` captures *what this repo is*.

## 2. Discovery model

Today, topic docs are discovered indirectly: the root `AGENTS.md` carries a "When you need it" table that points at `.agents/<topic>.md`. An agent loads a topic doc when its work matches the index entry.

Future: opt-in frontmatter triggers (`globs:`, `alwaysApply:`) will let tooling auto-inject matched docs. See the trigger system note below.

## 3. Frontmatter spec

Every `.agents/<topic>.md` declares:

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | yes | kebab-case slug; matches filename without `.md` |
| `description` | yes | One-line summary; root `AGENTS.md` index cites this verbatim |
| `last_updated` | yes | ISO date; bumped whenever the body materially changes |
| `covers` | yes | Path globs the doc claims to govern; consumed by parity hook + future audits |
| `globs` | reserved | AGENTS.md community trigger field; activates when hybrid trigger system lands |
| `alwaysApply` | reserved | Same |

Monorepos may also carry per-package `packages/<pkg>/AGENTS.md` with lighter frontmatter (no `covers:` — path-scoped by location):

```yaml
---
description: Patterns and rules for the `<package-name>` package
last_updated: YYYY-MM-DD
---
```

Root `AGENTS.md` has no frontmatter.

SaftUI is a Lua (WoW addon) repo with no Node toolchain, so the Node frontmatter validator from the project-scaffolding convention is not wired in. Keep frontmatter correct by hand: all required fields, valid globs, and `name:` matching the filename.

## 4. When to add a topic file

Three criteria — all must be true:

1. **Repo-specific.** Universal coding/Node/git conventions belong in `~/.claude/conventions/`, not here.
2. **Referenced by ≥2 places.** One AGENTS.md or one PR-review cycle isn't enough; that's inline-doc material.
3. **Has a clear `covers:` scope.** You can name path globs.

If any of the three doesn't hold, the content belongs somewhere else — see §10 below.

## 5. When to split a topic into a folder

Either:

- The topic crosses ~200 lines **and** has natural subdivisions, **or**
- One section of the topic is consistently the only part agents need.

Until then, single file.

## 6. Parity rule — the load-bearing one

If you edit code matching a `.agents/<topic>.md`'s `covers:` glob, audit that doc in the same PR. Update or confirm-still-current. Enforced by:

- **Self-audit at completion.** The `agents-doc-parity-check` skill scans `.agents/` for `covers:` overlap before any "I'm done" claim.
- **Soft hook on commit/PR.** The global doc-parity-gate hook walks the diff and warns if a `.agents/<topic>.md`'s `covers:` overlaps a changed path without the doc being touched in the same commit.

If the doc is still correct after your code change, just bump `last_updated`. No body edit needed.

## 7. Staleness signals

Freshness gauge thresholds:

- **<30 days** → trust.
- **30–90 days** → trust but verify load-bearing claims if they affect your work.
- **>90 days** → don't trust without checking; bump the date in your PR if confirmed correct.

`last_updated` is what gets compared, not git mtime.

## 8. Trigger system (future)

Hybrid trigger system deferred. When it lands, opted-in docs gain `globs:` + `alwaysApply:` frontmatter; tooling walks `.agents/` triggers and auto-injects matched docs into the agent prompt. Until then, discovery is via the AGENTS.md indexes only.

## 9. Naming conventions

- kebab-case filenames.
- No dates in filenames (`.agents/architecture.md`, never `.agents/2026-05-13-architecture.md`).
- Filename matches `name:` frontmatter without the `.md` extension.

## 10. What does NOT belong in `.agents/`

Explicit taxonomy — each kind of doc has a home:

| Content | Home |
|---------|------|
| Design specs (point-in-time, from brainstorming) | `docs/superpowers/specs/` |
| Implementation plans (point-in-time, from writing-plans) | `docs/superpowers/plans/` |
| Long-form architecture/design rationale | `docs/rationale/` |
| Project followups | `docs/followups.md` |
| Universal coding/git/Node conventions | `~/.claude/conventions/` |
| "How to do X" capability injection | user-level skills (`~/.claude/skills/`) |
| Per-conversation notes / todos / in-flight state | not committed |

`.agents/` is for **repo-specific, durable, agent-actionable rules**. If a doc isn't all three, it lives somewhere else above.

**Pointers vs content.** The rule above is about *content* sitting in `.agents/`, not about *cross-references*. A `.agents/<topic>.md` MAY (and often SHOULD) include a brief footer pointer like `See docs/rationale/<topic>.md for the why` or `See user-level skill <name> for how`. Pointers improve discoverability without bringing narrative into the agent-actionable layer. Aim for one or two short lines; if a topic doc needs a paragraph of context from elsewhere, that's a sign the content classification was wrong.

## 11. Index of current topic docs

Manually maintained. Mirrored from root `AGENTS.md`.

Add a row here for each `.agents/<topic>.md` as you create it (mirror of the root AGENTS.md index).

| Topic | Description |
|-------|-------------|
| workflow | Followups, specs/plans, branching and how subagents work in SaftUI (no Jira) |
| architecture | How SaftUI's addons, modules, config, profiles and load order fit together |
| taint | Rules for touching Blizzard frames and code without causing taint, blocked actions or crashes |
| edit-mode | SaftUI's edit mode (movers), the /sui options tree, option widgets and the scoped Ace skin |
| clients | WoW Forever vs retail, secret values, Blizzard source and icon lookups, and reading the user's in-game logs |
| testing | SaftUI's Lua test suite in tests/ - running it, writing tests, the WoW stub rules, and when tests are required |
