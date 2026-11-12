# Nameplate Subtext Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A second line under a nameplate's name that shows an NPC's title ("General Goods Vendor") or a player's guild, with one set of text settings and a checkbox for each.

**Architecture:** One new plate element, `Subtext`, in `SaftUI-Unitframes/nameplates/subtext.lua`: a font string written by an oUF tag (`st:subtext`), as the name is by `st:name`. The tag reads the plate's current config unit (`nameplate` or `friendlynameplate`), so the line follows a plate's kind and the "use the other plates' settings" boxes like every other part. The NPC title comes from the unit's tooltip data; the guild from `GetGuildInfo`.

**Tech Stack:** Lua 5.1, oUF (bundled, not to be modified), AceConfig options through `st.Config.generators`, tests on the stubs with `tests/run`.

**Spec:** there is no separate design document. The user approved the description in "What the user approved" below (2026-11-12, "that's all good, you can go ahead"); that section is the spec. It builds on `docs/superpowers/specs/2026-11-12-saftui-friendly-nameplates-design.md`.

## What the user approved

The user's words: "can we have an option to include subtext for titles (both player and npc titles like General Goods Vendor)", then "guild is what I meant for players. I think that text element should be the same font element but have checkbox toggles for enabling it for npcs vs players".

- A second line under a plate's name: an NPC's title, or a player's guild.
- **One text element** with one set of settings, plus two checkboxes: **NPC titles** and **Player guilds**.
- A Subtext tab on **both** the Friendly nameplates and Enemy nameplates pages. It follows the "use the other plates' settings" boxes like every other part.
- **Defaults:** both checkboxes on for friendly plates, both off for enemy plates.
- **Look:** directly under the name, centred on it, in angle brackets (`<General Goods Vendor>`, `<Some Guild>`), light grey, in the name's font. Settings: font, color, position, opacity (alpha), max width.
- **Nothing to show** (an NPC with no title, a player with no guild): no line, and the name doesn't move.
- **Pets and guardians:** "So-and-so's Pet" is not shown; it isn't a title.
- **Clicking:** the click area stays the plate's frame. The subtext hangs below it and isn't clickable. The plate's size doesn't change.
- **Scope:** nameplates only, not target or the other unit frames.
- Where the game hides unit info from addons, the line is hidden.

## Global Constraints

- Nothing under any `Libraries/` folder may be modified.
- Lua 5.1; both clients (Forever 16001, retail 120000). No build step. `tests/run` must pass (use `tests/run -j3`; another worker is running tests on this machine).
- `.agents/taint.md` and the "Secret values" section of `.agents/clients.md` apply. Names, levels, reactions, classes and tooltip text can be secret on plates. A secret value may be handed to `SetText`, or wrapped with `C_StringUtil.WrapString(secret, prefix, suffix)`; it must never be compared, matched, concatenated or used as a table key. Test `UnitIsPlayer`'s answer with `issecretvalue` before using it as a condition.
- No field is written on a Blizzard frame. A plate's SaftUI frame and its font strings are SaftUI's own.
- Existing test assertions are not changed. Enemy and friendly plates with default settings must look as they do today apart from the new line on friendly plates.
- Commit format: lowercase `module: imperative summary`. Stage by explicit path only.
- Keep the user's account and character names out of docs and tests.
- `docs/followups.md` is the controller's to edit, not the implementer's.

## Review Focus

1. **An NPC with no title.** Its tooltip's second line is the level line ("Level 80 Humanoid"). It must never show as a title, whether the line is typed `UnitLevel` or (on a client that leaves it untyped) only recognisable by its text.
2. **Secret values.** A secret title text, a secret line type, or a secret `UnitIsPlayer` answer gives no line and no error. A secret guild name is still shown, wrapped in its brackets by the game.
3. **Both boxes off** (the enemy default): no tooltip data is read at all, on any update.
4. **A plate handed to another unit or kind.** An NPC's plate reused for a player, or a friendly plate handed to an enemy: the line shows the new unit's text from the new kind's config, never the old unit's.
5. **Pets, guardians and guildless players** show nothing.

---

### Task 1: the Subtext element

**Files:**
- Create: `SaftUI-Unitframes/nameplates/subtext.lua`
- Modify: `SaftUI-Unitframes/nameplates/nameplates.xml` (add `subtext.lua` after `threat.lua`, before `pixels.lua`, whose rounding must run last)
- Modify: `SaftUI-Unitframes/config/units/nameplate.lua`, `SaftUI-Unitframes/config/units/friendlynameplate.lua` (the `subtext` defaults, and each file's header comment)
- Modify: `SaftUI-Unitframes/elements/name.lua` only if its max-width helper is shared instead of copied (see Step 5)
- Modify: `tests/wow/game.lua` and/or `tests/unitframes/nameplate_world.lua` (stubs)
- Test: `tests/unitframes/plate_subtext_test.lua`
- Docs: `AGENTS.md` (the Unitframes row lists what `nameplates/` holds), `.agents/clients.md` (the nameplates bullet and Secret values: how a title and a guild are read), `.agents/architecture.md` and `.agents/testing.md` where they list the plates' parts or the stubs.

**Interfaces (produced):**

- `UF.NpcTitle(unit)` → a plain string, or nil.
  - Reads `C_TooltipInfo.GetUnit(unit)` (it may return nothing). The title is the tooltip's **second** line (`data.lines[2].leftText`) when all of these hold: the text is a plain, non-empty string (`st.PlainString`); the line's `type` is nil or plainly `Enum.TooltipDataLineType.None`; and the text does not match the level line's pattern, built once from the global `TOOLTIP_UNIT_LEVEL` ("Level %s") by escaping Lua's magic characters and replacing each `%s` or `%d` with `.+`, anchored at the start. Anything else (a `UnitLevel`, `UnitOwner` or other typed line, a secret type or text, no second line) gives nil.
- `UF.PlateSubtext(unit, config)` → a string (plain, or a secret one from `C_StringUtil.WrapString`), or nil. `config` is a plate config's `subtext` table.
  - `UnitIsPlayer(unit)` secret → nil.
  - A player: nil unless `config.player`. The guild is `GetGuildInfo(unit)`'s first return. nil or an empty plain string → nil. A plain string → `'<' .. guild .. '>'`. A secret → `C_StringUtil.WrapString(guild, '<', '>')`.
  - Not a player: nil unless `config.npc` (checked **before** any tooltip read). `UF.NpcTitle(unit)` → `'<' .. title .. '>'`, or nil.
- The tag `st:subtext`, events `UNIT_NAME_UPDATE`. Like `st:name` (`tags.lua`) it takes the config unit as its argument (`[st:subtext(friendlynameplate)]`) and reads `UF:GetProfileConfig()[baseUnit].subtext`; it returns `UF.PlateSubtext(unit, config) or ''`, and `''` when the config unit or its `subtext` is missing. It lives in `subtext.lua`.
- The element `Subtext`, registered with `UF:RegisterElement('Subtext', Constructor, UpdateConfig, GetConfigTable, UF.IsPlateUnit)`. Its config key is `subtext` (`UF:AddTextElement`).

**Config (`subtext` in both plate defaults):**

| Key | Friendly | Enemy | Note |
| --- | --- | --- | --- |
| `enable` | `true` | `true` | Not an option on the page. `UF:ElementWanted` needs it; the two boxes decide what is written. Say so in a comment. |
| `npc` | `true` | `false` | The NPC titles box |
| `player` | `true` | `false` | The Player guilds box |
| `font` | the name's default font | the same | whatever key the plate's name resolves to today |
| `color` | `{ r = 0.8, g = 0.8, b = 0.8 }` | the same | applied with `SetTextColor` |
| `alpha` | `1` | `1` | |
| `max_width` | `150` | `200` | pixels, 0 for no limit, as the name's |
| `position` | `{ point = 'TOP', element = 'Name', rel_point = 'BOTTOM', x_off = 0, y_off = -2 }` | `{ point = 'TOP', element = 'Health', rel_point = 'BOTTOM', x_off = 0, y_off = -24 }` | Enemy: under the castbar's row (6 + 12 + 6), centred on the bar |

**The page (`GetConfigTable`):** a group named `Subtext`, ordered after Name's tab. Options, in order: `npc` ("NPC titles": "Shows an NPC's title, such as General Goods Vendor, under its name."), `player` ("Player guilds": "Shows a player's guild under their name."), `font`, `color` (an AceConfig `color` option, as `elements/castbar.lua` builds its own), `alpha`, `max_width`, and `position` last (`G.uf_element_position` with `UF:ConfigTarget(unit, 'Subtext')`, as `nameplates/threat.lua` does). Every set calls `UF:UpdateConfig(unit, 'Subtext')`. The tab must be hidden with the rest of a page whose "use the other plates' settings" box is checked, and must stay out of Copy from, as the plate pages' other tabs do; confirm from `config/config.lua` whether that needs anything.

- [ ] **Step 1: stubs.** Add what the tests need and the stubs lack: `C_TooltipInfo.GetUnit` (returns what a test sets per unit, nothing by default), `GetGuildInfo` (per unit, nil by default), `Enum.TooltipDataLineType` (`None = 0`, `UnitName = 2`, `UnitOwner = 16`, and `UnitLevel` with any distinct number), `TOOLTIP_UNIT_LEVEL = 'Level %s'`. Follow how the nameplate tests already set per-unit answers (`tests/unitframes/nameplate_world.lua`, `NP.add(unit, opts)`).

- [ ] **Step 2: write the failing tests** in `tests/unitframes/plate_subtext_test.lua`. Each line is one case with the assertion it makes:
  - `UF.NpcTitle`: lines `{UnitName 'Bob'}, {None 'General Goods Vendor'}, {UnitLevel 'Level 80 Humanoid'}` → `'General Goods Vendor'`.
  - Second line typed `UnitLevel` → nil. Second line with no `type` and text `'Level 80 Humanoid'` → nil. Second line with `type` None and text `'Level ?? Boss'` → nil.
  - Second line typed `UnitOwner` (`"Ann's Pet"`) → nil. One line only → nil. `GetUnit` returns nothing → nil. Second line's text `''` → nil.
  - Secret second-line text → nil, no error. Secret line type → nil, no error. (Use the secret-value stub the other tests use, e.g. `tests/unitframes/secret_texts_test.lua`.)
  - `UF.PlateSubtext`, NPC with title: `{ npc = true, player = true }` → `'<General Goods Vendor>'`; `{ npc = false, player = true }` → nil **and `C_TooltipInfo.GetUnit` was not called**.
  - Player in a guild: `{ player = true }` → `'<Some Guild>'`; `{ player = false, npc = true }` → nil, and `GetUnit` was not called. Player with no guild (nil, and `''`) → nil.
  - Secret guild name → the value `C_StringUtil.WrapString` returned for `(secret, '<', '>')`. Secret `UnitIsPlayer` → nil, no error.
  - On a plate (`NP.world`, `NP.add`): a friendly NPC with a title shows `<General Goods Vendor>` on `frame.Subtext` with default settings; an enemy NPC with a title shows an empty line with default settings, and `GetUnit` was not called for it.
  - The same plate frame removed and added again for a guilded friendly player shows `<Some Guild>`; added again for a titleless NPC shows nothing.
  - A plate that goes friendly → enemy (as `tests/unitframes/nameplate_kind_test.lua` does it) with the enemy `npc` box on shows the enemy unit's title, read from the enemy config; with `friendlynameplate.use_enemy` on, a friendly plate reads the enemy page's boxes.
  - `UF.Subtext`'s font string: its color is the config's (`0.8, 0.8, 0.8`), its width is `max_width` with word wrap off, and its point is `TOP` to the name's `BOTTOM` at `0, -2` on a friendly plate.
  - The page: both plate pages have a `subtext` group with `npc`, `player`, `font`, `color`, `alpha`, `max_width`, `position`; setting `npc` off on the Friendly page clears a shown title; the group is hidden on a page whose "use the other" box is checked (assert it the way `tests/unitframes/friendly_page_test.lua` asserts it for the other tabs).
  - Defaults: `friendlynameplate.subtext.npc` and `.player` are true, `nameplate.subtext.npc` and `.player` are false, in a fresh profile.

- [ ] **Step 3: run them and see them fail.** `tests/run -j3 tests/unitframes/plate_subtext_test.lua` (or the runner's way of naming one file; see `.agents/testing.md`). Expected: failures naming `UF.NpcTitle` / `frame.Subtext` as nil.

- [ ] **Step 4: implement `UF.NpcTitle`, `UF.PlateSubtext` and the tag** in `subtext.lua`, as the Interfaces block says.

- [ ] **Step 5: implement the element.** Constructor: `UF:AddTextElement(frame, 'Subtext')`. UpdateConfig: `UF:UpdateElement(frame.Subtext)` (font, alpha, position, shown), then the color, the max width (the same rule as the name's `SetMaxWidth` in `elements/name.lua`; share that helper through `UF` rather than copy it, without changing what the name does), and the tag binding, bound again when `frame.base_unit` changes exactly as `elements/name.lua` does with `taggedUnit`. Add the defaults and the page.

- [ ] **Step 6: run the tests.** `tests/run -j3`. Expected: every file passes, with no existing assertion changed.

- [ ] **Step 7: docs**, as listed under Files. Bump `last_updated` on each `.agents` doc changed.

- [ ] **Step 8: commit**, one commit for the stubs and tests' helpers if they stand alone, one for the element with its tests, one for docs.

**In-game checks this task leaves for the user** (put them in the report; the controller files them):
1. In a city: a vendor's plate shows its title under its name in grey angle brackets; a guard with no title shows no second line; no plate shows "Level 80 Humanoid".
2. A guilded player's friendly plate shows their guild; a guildless player's shows nothing.
3. A hunter's pet shows no "So-and-so's Pet" line.
4. `/sui` → Unitframes → Friendly nameplates → Subtext: each box turns its line off and on at once; font, color, max width and position take effect.
5. Enemy nameplates → Subtext: both boxes are off; turned on, an enemy NPC's title sits under its castbar.
6. In combat with plates on screen: no errors in BugSack from `subtext.lua`.
