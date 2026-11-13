# AGENTS.md

Conventions for agents working on `SaftUI`. Universal documentation and git
conventions live in `~/.claude/conventions/`; this file covers `SaftUI`-specific
rules only.

## What this is

SaftUI is a modular World of Warcraft UI replacement: a set of Lua addons that share one
core (`SaftUI-Core`) and each own one area of the UI (unit frames and nameplates, action
bars, bags, chat, minimap and micro menu, loot, and a grab-bag of skins and small
modules). It targets two clients at once: **WoW Forever** (interface 16001, a
mainline-family client with "Camelot" overrides, the one the user plays) and **retail**
(Midnight, interface 120000). It has its own edit mode, where registered frames are
dragged and nudged on screen and configured in the `/sui` options window, which is built
on Ace3. There is no build step. Logic that can be checked outside the game has Lua
tests in `tests/`, which agents run on Lua 5.1 with `tests/run`. Changes are also
verified by reading the code, and by the user checking them in game.

## Repo layout

| Path | What it is |
| ---- | ---------- |
| `SaftUI-Core/` | Shared core every module depends on: addon object, constants, API helpers (`api.lua`), frames and panels (`panels.lua`), the theme engine that draws every backdrop (`theme.lua`), fonts, colors and the theme's settings (`Media/`), config (AceDB profile, `/sui` and SaftUI's options window), and the edit mode framework (`EditMode/`). Bundles Ace3 and other libraries. Has per-client TOCs. |
| `SaftUI-Unitframes/` | Unit frames built on a bundled oUF (`Libraries/oUF`, oUF master), and SaftUI's nameplates on oUF's nameplate driver (`nameplates/`: spawning and standing down for another nameplate addon, each plate's kind and Blizzard's widgets, the game's nameplate settings, the target's border, threat, the subtext line under a plate's name, whole-pixel plates, and the two plate pages in `/sui` in `options.lua`). Party and raid headers and the group border in `groups.lua`, the header layout math in `grouplayout.lua`, hiding Blizzard's raid frames in `blizzardraid.lua`, test mode previews in `grouppreview.lua`. Elements in `elements/`, config in `config/` (the unit frame profiles in `profiles.lua`, party, raid and boss Layout and party and raid Range in `groupoptions.lua`, the rest of the Unitframes page in `config.lua`, the plates' defaults in `units/nameplate.lua`), the purge, dispel and steal spells and every aura group's filter in `aurafilters.lua`. Per-client TOCs. |
| `SaftUI-Bags/` | Bag, bank and combined bank windows (`container.lua` makes a window and updates it, `header.lua` its title bar's buttons and the view switch, `layout.lua` lays it out in each view, `search.lua` the bag window's search box, `containers/` each window's own code), bag slot bars, and the bag categories: an ordered list in the profile, each with a block rule (`rules.lua` evaluates them, `categorydefaults.lua` holds today's filters as the defaults, `categories.lua` is the list, its edits, pins and migration and says where an item goes, `itemclasses.lua` gives item class names their IDs), the Categories tab in `/sui` (`categoriestab.lua`, `ruleeditor.lua`, and `dragparts.lua`, the handle, ghost and drop line both drag with), and the tooltip lines and slot menu entries that name an item's category. |
| `SaftUI-Chat/` | Chat frame placement, size and skin. |
| `SaftUI-Loot/` | Loot roll frames (`rollbar.lua` draws SaftUI's roll bars, `roll.lua` skins Blizzard's and holds chosen rolls, `rolltest.lua` is Test mode's previews, `rollinfo.lua` the live choices), loot feed (`Feed/`: `parse.lua` reads the chat lines, `loothistory.lua` reads C_LootHistory's drops, `rolls.lua` makes the roll entries), loot window popup. |
| `SaftUI-Minimap/` | Minimap, SaftUI's micro menu bar and the pieces it hosts (`micromenu.lua` the bar and its items, `micromenuart.lua` their panels and Blizzard art, `micromenuitems.lua` `SkinBarButton` and the mail and tracking items, `micromenuoptions.lua` its `/sui` page), Blizzard micro buttons inline, addon compartment. |
| `SaftUI-ActionBars/` | SaftUI's own action bars, built on a bundled LibActionButton-1.0 (`Libraries/`), in place of Blizzard's, which it takes off screen at load (`hideblizzard.lua`). Bars 1-8 use LibActionButton buttons; the pet and stance bars (`petbar.lua`, `stancebar.lua`) use SaftUI's own secure buttons (`buttons.lua`). Their keys come from Blizzard's binding commands, with hover binding in `/sui kb` (`keybindmode.lua`; `bindings.lua` lays the keys). The extra action button and zone ability (Blizzard's) and a leave vehicle button (SaftUI's) sit on SaftUI holders (`extras.lua`). Per-bar options and edit mode movers are in `options.lua`. |
| `SaftUI-Misc/` | Experience/rep bars (their defaults in `config.lua` with Misc's others), tooltip, totem bar (`totembar.lua` the module and hiding, `totemlayout.lua` its buttons, `totemposition.lua` its holder and mover, `totemoptions.lua` its `/sui` page, `totemskin.lua`, `totemtimers.lua`), and skins in `Skinning/`: `skinning.lua` the Skinning module, Blizzard's frames in `blizzard/` (buff frames, swing timer, character frame, Cooldown Manager, zone text) and other addons' in `addons/` (Hekili, RestedXP, WeakAuras). |
| `docs/` | Followups queue, design specs and implementation plans. |
| `tests/` | Lua 5.1 tests for agents, run with `tests/run`: the runner, the test harness, the core shell and the shared test helpers (`lib/`), the WoW API stubs (`wow/`), and tests by addon. Never loaded by the game. |

## When you need it

Topic docs live in `.agents/`. Load one when your work matches its row.

| Doing | Read |
| ----- | ---- |
| Planning, followups, specs/plans, branching, running subagents, committing | `.agents/workflow.md` |
| Adding or changing a module, its config/defaults, `UpdateConfig`, profile switching, TOCs/load order, drawing a frame in the theme (Theme and Background, kinds) | `.agents/architecture.md` |
| Touching any Blizzard frame, hooking Blizzard code, anything that can run in combat | `.agents/taint.md` |
| Making a frame movable, `/sui` options, the options window and its widgets | `.agents/edit-mode.md` |
| Forever vs retail differences, secret values, Blizzard source/icon lookups, reading the user's error logs | `.agents/clients.md` |
| Writing or running tests | `.agents/testing.md` |

**Read `.agents/taint.md` before writing any code that touches a Blizzard frame.** Most of
this repo's worst bugs (combat `ADDON_ACTION_BLOCKED`, a client crash) came from breaking
its rules.

See [`.agents/README.md`](.agents/README.md) for how this system works and how to extend it.

## Before claiming work complete

Run `tests/run`; it must pass.

If this repo has `.agents/<topic>.md` docs with `covers:` frontmatter, run the
`agents-doc-parity-check` skill before reporting any task complete or opening a PR.
If it has a root `README.md`, run `readme-freshness-check`. Both are additive to
`superpowers:verification-before-completion`, not replacements.
