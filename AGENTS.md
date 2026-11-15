# AGENTS.md

Conventions for agents working on `SaftUI`. Universal documentation and git
conventions live in `~/.claude/conventions/`; this file covers `SaftUI`-specific
rules only.

## What this is

SaftUI is a modular World of Warcraft UI replacement: a set of Lua addons that share one
core (`SaftUI-Core`) and each own one area of the UI (unit frames and nameplates, action
bars, bags, chat, minimap and micro menu, loot, an objective tracker that is off by
default, and a grab-bag of skins and small modules). It targets two clients at once: **WoW Forever** (interface 16001, a
mainline-family client with "Camelot" overrides, the one the user plays) and **retail**
(Midnight, interface 120000). It has its own edit mode, where registered frames are
dragged and nudged on screen and configured in the `/sui` options window, which is built
on Ace3. There is no build step. Logic that can be checked outside the game has Lua
tests in `tests/`, which agents run on Lua 5.1 with `tests/run`. Changes are also
verified by reading the code, and by the user checking them in game.

## Repo layout

| Path | What it is |
| ---- | ---------- |
| `SaftUI-Core/` | Shared core every module depends on: addon object, constants, API helpers (`api.lua`), frames and panels (`panels.lua`), the theme engine that draws every backdrop (`theme.lua`), fonts, colors and the theme's settings (`Media/`; `Media/colors.lua` holds the color accessor, `st:Color` and `st:ColorRGBA`, and the colors' migration, `st:MigrateColors`), config (AceDB profile, `/sui` and SaftUI's options window, which has three sizes (full, half, and a small bar: `Config/optionssizes.lua`, with its arrows, which wear Blizzard's expand and condense art under Blizzard) and a sidebar that collapses (`Config/optionsnav.lua`, with the footer's tools and the title's page list it leaves behind), and whose color fields open SaftUI's own color picker, `Config/optionscolorpicker.lua`), and the edit mode framework (`EditMode/`: movers and the picker, grid and snapping, the filter that chooses which movers show, the Coordinates label, the dim layer, the history of moves with Undo, Redo and Reset in `history.lua` and `moves.lua`, and the bar docked or floating with its History list in `EditMode/Bar/`). `Dev/fontdemo.lua` is a temporary demo (`/suifonts`, a window to choose a small-text font, with the candidate fonts in `Media/Fonts/Candidates/`), to be deleted once a font is chosen; its header lists what goes. Bundles Ace3 and other libraries. Has per-client TOCs. |
| `SaftUI-Unitframes/` | Unit frames built on a bundled oUF (`Libraries/oUF`, oUF master), and SaftUI's nameplates on oUF's nameplate driver (`nameplates/`: spawning and standing down for another nameplate addon, each plate's kind and Blizzard's widgets, the game's nameplate settings, the target's border, threat, the subtext line under a plate's name, whole-pixel plates, and the two plate pages in `/sui` in `options.lua`). Party and raid headers and the group border in `groups.lua`, the header layout math in `grouplayout.lua`, hiding Blizzard's raid frames in `blizzardraid.lua`, test mode previews in `grouppreview.lua`. Elements in `elements/`, config in `config/` (the unit frame profiles in `profiles.lua`, party, raid and boss Layout and party and raid Range in `groupoptions.lua`, the rest of the Unitframes page in `config.lua`, the plates' defaults in `units/nameplate.lua`), the purge, dispel and steal spells and every aura group's filter in `aurafilters.lua`. Per-client TOCs. |
| `SaftUI-Bags/` | Bag, bank and combined bank windows (`container.lua` makes a window and updates it, `header.lua` its title bar's buttons and the view switch, `layout.lua` lays it out in each view, `search.lua` the bag window's search box, `containers/` each window's own code), bag slot bars, and the bag categories: an ordered list in the profile, each with a block rule (`rules.lua` evaluates them, `categorydefaults.lua` holds today's filters as the defaults, `categories.lua` is the list, its edits, pins and migration and says where an item goes, `itemclasses.lua` gives item class names their IDs), the Categories tab in `/sui` (`categoriestab.lua`, which at half width puts the list in a menu on a button over the editor, `ruleeditor.lua`, and `dragparts.lua`, the handle, ghost and drop line both drag with), and the tooltip lines and slot menu entries that name an item's category. |
| `SaftUI-Chat/` | Chat frame placement, size and skin. |
| `SaftUI-Loot/` | Loot roll frames (`rollbar.lua` draws SaftUI's roll bars, `roll.lua` skins Blizzard's and holds chosen rolls, `rolltest.lua` is Test mode's previews, `rollinfo.lua` the live choices), loot feed (`Feed/`: `parse.lua` reads the chat lines, `loothistory.lua` reads C_LootHistory's drops, `rolls.lua` makes the roll entries; `feed.lua` also its two icon buttons, which show only under the mouse, and `filter.lua` the filters and their menu, the options kit's check list), loot window popup. |
| `SaftUI-Minimap/` | Minimap, SaftUI's micro menu bar and the pieces it hosts (`micromenu.lua` the bar and its items, `micromenuart.lua` their panels and Blizzard art, `micromenuitems.lua` `SkinBarButton` and the mail and tracking items, `micromenuoptions.lua` its `/sui` page), Blizzard micro buttons inline, addon compartment. |
| `SaftUI-ActionBars/` | SaftUI's own action bars, built on a bundled LibActionButton-1.0 (`Libraries/`), in place of Blizzard's, which it takes off screen at load (`hideblizzard.lua`). Bars 1-8 use LibActionButton buttons; the pet and stance bars (`petbar.lua`, `stancebar.lua`) use SaftUI's own secure buttons (`buttons.lua`). Their keys come from Blizzard's binding commands, with hover binding in `/sui kb` (`keybindmode.lua`; `bindings.lua` lays the keys). The extra action button and zone ability (Blizzard's) and a leave vehicle button (SaftUI's) sit on SaftUI holders (`extras.lua`). Settings every bar shares (All bars' values, each bar's own flags, the one effective config every reader takes, Apply to, and the conversion of an older profile) are in `shared.lua`. The `/sui` page (All bars first in the Bar picker, then each bar on one page with no tabs, then the extras; each shared setting's share and reset) and the edit mode movers are in `options.lua`; its four texts' menu items (Hotkey, Stack count, Macro name, Cooldown) in `textoptions.lua`. |
| `SaftUI-Tracker/` | SaftUI's own objective tracker, switched off by default (`tracker.enable`, read once at login: `init.lua`, with the module `Tracker`, `TR:IsOn()`, standing down for another tracker addon, `TR:Build()`, `TR:UpdateConfig()` and the per-character data). `config.lua` has the profile defaults and the key binding strings, `options.lua` the Tracker page in `/sui` (under Info), `Bindings.xml` the nearest quest item key. The data: `model.lua` reads the quest log into a plain table (`TR.Model.Read`, the zone names, the display rule, the game's order) and says a quest's title and the lines of its row (`TR.TitleText`, `TR.QuestLines`, `TR.TimeText`), `groups.lua` puts those quests in zone groups (`TR.Groups`: the current zone first, campaigns, the log's header order, Other last). `layout.lua` has the window's constants and pure math (`TR.LAYOUT`, `TR.Layout`), `window.lua` its holder and edit mode mover (`tracker`), the window with its header, Width, Max height and Grow, and the scroll frame and its bar. `rows.lua` draws the quest list: the row pools (zone headers, quest rows with their lines, progress bars, popups, the empty line), the focused quest's marker and the timer's ticker, and `init.lua` has the events, the throttle and `TR:Refresh` that keep it current. `clicks.lua` is what a click on a quest row does (`TR.ClickAction`, `TR:OnQuestClick`: the chat link, Shift to stop tracking, Show on map out of combat and focus in combat, the quest icon's focus), Blizzard's right-click menu (`TR.MenuEntries`, `TR:OpenMenu`, through `MenuUtil`) and the row tooltip; `TR.ShowOnMapAllowed()`, `TR.QuestDetailsAllowed()` and `TR.AbandonAllowed()` hold whether a click or menu entry may open the map, the quest details and the abandon confirmation (in-game experiment P5), and `TR.WatchChangeAllowed()` whether a click may track or untrack a quest (P6; today out of combat only). `items.lua` the secure quest item layer and the buttons in the rows or in the numbered column beside the tracker (`TR.Items.Column`, `TR:ColumnWidth()`; `TR:RefreshItems` hands out the pool out of combat and only dims in combat; `TR.ItemAttributes` is how a button is told what to use; the rows' item slot, the list held still in combat while a button shows), and `blizzard.lua` holds Blizzard's own tracker off screen while SaftUI's is on (`TR:OwnsBlizzard()`, `TR:SetupBlizzard()`, `TR:BlizzardTarget(where)` and `TR:PlaceBlizzard(where)`, the one function that holds the concealment: three C methods, never `Hide`, `SetParent` or a size; `.agents/taint.md` rule 5). One TOC for both clients, with `OptionalDeps: SaftUI-Misc`. |
| `SaftUI-Misc/` | Experience/rep bars (their defaults in `config.lua` with Misc's others), tooltip, totem bar (`totembar.lua` the module and hiding, `totemlayout.lua` its buttons, `totemposition.lua` its holder and mover, `totemoptions.lua` its `/sui` page, `totemskin.lua`, `totemtimers.lua`), the armour durability figure (`durability.lua`: its mover and `/sui` page; `durabilitytooltip.lua`: the damaged items and the repair cost added to its tooltip), and skins in `Skinning/`: `skinning.lua` the Skinning module, Blizzard's frames in `blizzard/` (buff frames, swing timer, character frame, Cooldown Manager, objective tracker, color picker (`Blizzard_ColorPicker.lua`), weekly rewards, world map, zone text; Blizzard's objective tracker's look in `Blizzard_ObjectiveTracker.lua` and its holder, mover and `/sui` page, named "Blizzard's tracker", in `Blizzard_ObjectiveTrackerPosition.lua`, which stand down while SaftUI's own tracker is on) and other addons' in `addons/` (Hekili, RestedXP, WeakAuras). |
| `tools/` | Scripts for making assets, run by hand and never loaded by the game: `lucide-to-tga.cjs` makes the Lucide icon textures. |
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
