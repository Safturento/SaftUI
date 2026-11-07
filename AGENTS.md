# AGENTS.md

Conventions for agents working on `SaftUI`. Universal documentation and git
conventions live in `~/.claude/conventions/`; this file covers `SaftUI`-specific
rules only.

## What this is

SaftUI is a modular World of Warcraft UI replacement: a set of Lua addons that share
one core (`SaftUI-Core`) and each own one area of the UI (unit frames, action bars, bags,
chat, minimap and micro menu, loot, and a grab-bag of skins and small modules). It targets
two clients at once: **WoW Forever** (interface 16001, a mainline-family client with
"Camelot" overrides, the one the user plays) and **retail** (Midnight, interface
120000). It has its own edit mode, where registered frames are dragged and nudged on
screen and configured in the `/sui` options window, which is built on Ace3. There is
no build step and no test runner: changes are verified by reading the code and by the
user checking them in game.

## Repo layout

| Path | What it is |
| ---- | ---------- |
| `SaftUI-Core/` | Shared core every module depends on: addon object, constants, API helpers (`api.lua`), backdrops/templates (`panels.lua`), fonts and media, config (AceDB profile, `/sui`, Ace skin), and the edit mode framework (`EditMode/`). Bundles Ace3 and other libraries. Has per-client TOCs. |
| `SaftUI-Unitframes/` | Unit frames built on a bundled oUF (`Libraries/oUF`, oUF master). Elements in `elements/`, config in `config/`. Per-client TOCs. |
| `SaftUI-Bags/` | Bag, bank and combined bank windows, filters, categories, bag slot bars. |
| `SaftUI-Chat/` | Chat frame placement, size and skin. |
| `SaftUI-Loot/` | Loot roll frames, loot feed (`Feed/`), loot window popup. |
| `SaftUI-Minimap/` | Minimap, SaftUI's micro menu bar and the pieces it hosts, Blizzard micro buttons inline, addon compartment. |
| `SaftUI-ActionBars/` | SaftUI's own action bars, built on a bundled LibActionButton-1.0 (`Libraries/`), in place of Blizzard's, which it takes off screen at load (`hideblizzard.lua`). Their keys come from Blizzard's binding commands, with hover binding in `/sui kb` (`bindings.lua`). |
| `SaftUI-Misc/` | Experience/rep bars, tooltip, totem bar, and Blizzard skins in `Skinning/` (buff frames, swing timer, character frame). |
| `docs/` | Followups queue, design specs and implementation plans. |

## When you need it

Topic docs live in `.agents/`. Load one when your work matches its row.

| Doing | Read |
| ----- | ---- |
| Planning, followups, specs/plans, branching, running subagents, committing | `.agents/workflow.md` |
| Adding or changing a module, its config/defaults, `UpdateConfig`, profile switching, TOCs/load order | `.agents/architecture.md` |
| Touching any Blizzard frame, hooking Blizzard code, anything that can run in combat | `.agents/taint.md` |
| Making a frame movable, `/sui` options, option widgets, the Ace skin | `.agents/edit-mode.md` |
| Forever vs retail differences, secret values, Blizzard source/icon lookups, reading the user's error logs | `.agents/clients.md` |

**Read `.agents/taint.md` before writing any code that touches a Blizzard frame.** Most of
this repo's worst bugs (combat `ADDON_ACTION_BLOCKED`, a client crash) came from breaking
its rules.

See [`.agents/README.md`](.agents/README.md) for how this system works and how to extend it.

## Before claiming work complete

If this repo has `.agents/<topic>.md` docs with `covers:` frontmatter, run the
`agents-doc-parity-check` skill before reporting any task complete or opening a PR.
If it has a root `README.md`, run `readme-freshness-check`. Both are additive to
`superpowers:verification-before-completion`, not replacements.
