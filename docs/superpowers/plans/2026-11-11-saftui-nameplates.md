# SaftUI's nameplates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SaftUI draws enemy, neutral and (outside instances) friendly nameplates on the bundled oUF, on WoW Forever and retail, with role-aware threat tints, the buffs the player can purge, a bright target border, and borders that stay whole-pixel while plates move.

**Architecture:** A new unit, `nameplate`, spawned once with `oUF:SpawnNamePlates` and styled by `UF.ConstructUnit` like every unit. Its frames live in `UF.nameplates` (by plate number), and every walker of unit frames reaches them. The nameplate-only code is in a new folder, `SaftUI-Unitframes/nameplates/`: spawning and plate kinds, the game's nameplate settings, the target border, threat and pixel rounding. Each file hooks a plate's add and update through a small callback list in `nameplates.lua`, so the files don't edit each other. "Only buffs I can purge" works on every unit (`purge.lua`, `elements/auras.lua`). Three fixes to existing code come first: the castbar's uninterruptible colour, secret-safe name and health texts, and group units updated after oUF's init.

**Tech Stack:** Lua 5.1 (WoW); the bundled oUF master (`SaftUI-Unitframes/Libraries/oUF`); Blizzard's AuraContainer, `C_NamePlate` and threat APIs; SaftUI's theme engine (`SaftUI-Core/theme.lua`, `themeart.lua`); the Lua test suite (`tests/run`).

**Spec:** `docs/superpowers/specs/2026-11-11-saftui-nameplates-design.md`. It's committed on `modular` (7e46526), not on round2, so from a round2 worktree read it with `git show 7e46526:docs/superpowers/specs/2026-11-11-saftui-nameplates-design.md`. The research behind it is `report-research-nameplates.md` in the controller's scratchpad, with Blizzard's source beside it (`src_forever_clone/`, `src_live_clone/`) and other addons' plates (`np/`).

## Global Constraints

- **Clients.** Both clients are targets: WoW Forever (interface 16001, `st.forever`) and retail (120000). Wherever behaviour can differ, the tests run on both (`T.client('forever')`, `T.client('retail')`, from `tests/lib/theme_helpers.lua`).
- **Spec defaults** (the spec's "my calls"):
  - Nameplates on. Friendly plates on. Threat when solo off.
  - Health bar 200 by 20.
  - Castbar 12 tall under the bar, the full width less its 12x12 icon on the left.
  - Debuffs: the player's own (`isFromPlayerOrPlayerPet`), up to 6, 20px, growing right from the bar's left edge.
  - Purgeable buffs: right of the bar, up to 4, 20px.
  - "Only buffs I can purge" on for nameplates only, off for every other unit.
- **Friendly plates** carry the bar, the name, health % and the raid mark: no castbar, debuffs, purge row, threat or quest icon.
- **Threat.** The tint replaces the bar's colour while it applies, in new Colors tab colours `threat.warning` (1, 0.6, 0) and `threat.bad` (1, 0.1, 0.1), which the user can edit. SaftUI's hostile red is (135, 81, 81). The state comes from `UnitThreatSituation('player', plateUnit)`:
  - tank: good 3, warning 2, bad 0 or 1, but good when another group tank holds the mob;
  - DPS or healer: good 0, warning 1, bad 2 or 3;
  - nil shows nothing, and a secret state shows nothing.

  Tints show in a party or raid, and solo only with Threat when solo on.
- **Stand down** when any of these is loaded (`C_AddOns.IsAddOnLoaded`): Plater, EllesmereUI's nameplates (`EllesmereUINameplates`), `Kui_Nameplates`, `TidyPlates_ThreatPlates`, `NeatPlates`, or ElvUI with its nameplates on. Standing down means no plates, no game settings set or restored, and nothing of Blizzard's plates touched. The page then says "Nameplates are drawn by Plater. Turn it off to use SaftUI's." (with that addon's name), and its options are disabled. The list is a table in the code.
- **Game settings,** set out of combat only:
  - friendly plates, for players and for NPCs, follow the Friendly plates toggle;
  - while SaftUI's plates are on: `nameplateMinScale`, `nameplateMaxScale` and `nameplateSelectedScale` 1, and simplified plates off.

  The user's previous value is recorded once, the first time SaftUI changes it, and put back when Nameplates is turned off.
- **Target border.** Under Thick and Thin, a 1px white line through `st:SetBorderColor`. Under Blizzard, `UI-HUD-CoolDownManager-Selected-yellow` (Forever) or `UI-HUD-Nameplates-Selected` (retail). The target's plate is found by frame (`C_NamePlate.GetNamePlateForUnit('target')`), never by `UnitIsUnit`.
- **Pixel-perfect.** Plate frames are pinned to UIParent's effective scale. Every frame and region SaftUI makes on a plate rounds its layout to whole pixels: native `SetRoundLayoutToNearestPixel`, applied by SaftUI's own walker, never by `PixelUtil`'s recursive helper and never on Blizzard's frames. Textures are unsnapped wherever rounding is on. Sizes are even pixels.
- **Taint** (`.agents/taint.md`):
  - nothing is written onto Blizzard's nameplate frames beyond what the bundled oUF writes (`nameplate.unitFrame`, `nameplate.style`, blocking the pooled UnitFrame);
  - `NamePlateDriverFrame` gets a post-hook only, and its events are left alone;
  - forbidden plates are untouched;
  - no `NineSliceUtil`;
  - no arithmetic, comparison, concatenation or table indexing on a secret value (`issecretvalue` first);
  - the hover texture stays in the HIGHLIGHT layer.
- **Users and profiles.** Words the user sees name no CVar, atlas or API. Saved profiles keep working, and nameplates arrive on by default with a /reload.
- **Atlases.** Every new atlas goes into `tests/wow/atlases.lua`. In `themeart.lua` it's marked `Atlas(name, client)` where only one client's art names it.
- **Repo rules:**
  - test first, and `tests/run` must pass (Lua 5.1);
  - a new WoW API goes in `tests/wow/`, with a comment saying what the client does and how we know;
  - no `git stash`;
  - keep each file's line endings (every file these tasks touch is LF today);
  - stage by explicit path;
  - commit messages are `<area>: <plain sentence>` (`unitframes:`, `core:`, `tests:`, `docs:`), ending with the round's two trailer lines.
- **Docs.** Tasks 1–12 leave `.agents/*.md`, `AGENTS.md` and `README.md` alone, and each lists in its report what those docs need. Task 13 writes them. A task does edit `docs/followups.md` when it resolves an entry or leaves something out of scope (the entry template is at the top of that file).

## Review Focus

1. **A plate handed to a unit of the other kind.** The game reuses each NamePlateN. A frame first built for a friendly NPC (its castbar off) later shows an enemy, often mid-fight. Expected: the enemy's castbar, debuffs and purge row show, placed where the config puts them. Test: Task 5, "a plate reused for an enemy shows the enemy parts, placed".
2. **Widget-only and game-object plates** (capture bars, quest objects). oUF never calls SaftUI's added callback for these, yet their widgets must show. Test: Task 5, "widgets move to the plate on every add, widget-only plates too".
3. **A secret health value with Health % on** (enemy plates in restricted content). Expected: the game draws the percent, with no error. Test: Task 2, "health percent with a secret health is drawn from UnitHealthPercent".
4. **Nameplates turned off and on again across reloads.** Expected: after off, the user's original friendly and scale settings are back exactly; a second on/off cycle records whatever is set then. Test: Task 6, "a second on/off cycle records anew".
5. **UI scale changed while plates are up** (Blizzard's UI scale setting, or a display change). Expected: every plate is re-pinned to UIParent's new scale, and the plate size is applied again out of combat. Test: Task 11, "a UI scale change re-pins every plate and re-applies the size".

## Spec gaps, and how this plan settles them

1. **The Friendly plates toggle.** Goal 1 says both "off, the game shows none" and "puts the user's previous value back when Nameplates or the toggle is turned off". The plan: the toggle's off sets friendly plates off, and the previous values come back only when Nameplates is turned off (Task 6).
2. **The `st:name` target mark.** The spec lists the dead `baseunit` test as a bug, but answer 7 replaces the 2019 mark with a border. The plan removes the mark rather than reviving it (Task 2).
3. **Health % with a secret health.** `health.lua`'s percent branch runs `floor` on a secret value, which errors, and plates show the percent by default. The spec doesn't name this. The plan fixes it (Task 2), and leaves the boss percent path to a followup.
4. **Group units' colour events.** Moving group units' update after oUF's `Enable` would lose their `UNIT_FACTION` registration (followup 2026-11-09). The plan folds that followup's setter fix into Task 3.
5. **Enabling elements.** `EnableElement` and `DisableElement` are used on plates only, by kind. oUF's castbar `Disable` re-registers Blizzard's player castbar, which the player castbar's option promises not to do. Group units are simply updated after init (Task 3).
6. **Widget-only plates** never reach oUF's added callback, so SaftUI listens to `NAME_PLATE_UNIT_ADDED` itself to move the widgets (Task 5).
7. **Plate size and the pinned scale.** The config's size is in UIParent pixels, and the plate's size is in its parent's units. The plan converts between them through WorldFrame's effective scale (Task 11), with an in-game check.
8. **Purge filters.** Blizzard's candidate filters AND their keys, so Magic covers Spellsteal (a stealable buff is Magic). A Spellsteal-only player gets `isStealable`, and a player with an enrage remover and Spellsteal but no Magic remover (no class today) would see enrages only (Task 10).
9. **Debuffs on plates.** `HARMFUL|PLAYER` would drop the pet's debuffs (the spec counts them on Forever) and Blizzard's nameplate-only debuffs. Plates use `HARMFUL|INCLUDE_NAME_PLATE_ONLY` with `isFromPlayerOrPlayerPet` (Task 10).
10. **`UF:OnColorsChanged` skipped frames never hovered.** It read `frame.unit`, which only `UF.OnEnter` sets. The plan reads `__unit` (Task 9).
11. **The plate's Theme.** "Use SaftUI's theme by default, like every unit" is read as every unit's shape: the frame None, its bars in SaftUI's theme. That gives one border per bar, and Blizzard's fills under Blizzard, which need the bar's own Theme to be Blizzard's (Task 7).
12. **Health % format.** The plate's health percent keeps every unit's format, a whole number with no sign. The spec's drawing shows "72%" (Task 7).

---

## Files

| File | Responsibility | Tasks |
| --- | --- | --- |
| `SaftUI-Unitframes/elements/castbar.lua` | cast colours; ShouldShow by plate kind | 1, 5 |
| `SaftUI-Unitframes/tags.lua` | the `st:name` tag | 2 |
| `SaftUI-Unitframes/elements/health.lua` | health percent text; colour flags; threat colour | 2, 3, 9 |
| `SaftUI-Unitframes/elements/power.lua` | colour flags; ValidUnit | 3, 4 |
| `SaftUI-Unitframes/unitframes.lua` | init callback; plates in the walkers; OnEnable; OnColorsChanged | 3, 4, 6, 9, 12 |
| `SaftUI-Unitframes/updaters.lua` | `SetElementEnabled`, `UF:ElementWanted` | 3, 5 |
| `SaftUI-Unitframes/purge.lua` (new) | purge spells per client; aura filters | 10 |
| `SaftUI-Unitframes/elements/auras.lua` | filters through `UF.AuraFilter`; purge option; enabled by plate kind; plate aura backdrops rounded | 10, 5, 11 |
| `SaftUI-Unitframes/config/default.lua` | `buffs.purgeable` | 10 |
| `SaftUI-Unitframes/config/units/nameplate.lua` (new) | the nameplate defaults | 4, 7 |
| `SaftUI-Unitframes/config/load.xml` | loads nameplate.lua | 4 |
| `SaftUI-Unitframes/SaftUI-Unitframes_Forever.toc`, `_Mainline.toc` | load `purge.lua`, `nameplates\nameplates.xml` | 10, 4 |
| `SaftUI-Unitframes/nameplates/nameplates.xml` (new) | lists the folder's files | 4, 6, 8, 9, 11 |
| `SaftUI-Unitframes/nameplates/nameplates.lua` (new) | spawn, stand-down, plate list, callbacks, size, kinds, widgets | 4, 5, 11 |
| `SaftUI-Unitframes/nameplates/cvars.lua` (new) | game settings: set, record, restore | 6 |
| `SaftUI-Unitframes/nameplates/target.lua` (new) | the target border | 8 |
| `SaftUI-Unitframes/nameplates/threat.lua` (new) | threat state and tint | 9 |
| `SaftUI-Unitframes/nameplates/pixels.lua` (new) | rounding walker, scale pin, scale settings | 11 |
| `SaftUI-Unitframes/config/config.lua` | the Nameplates page; `GetConfigFrame` | 6 |
| `SaftUI-Unitframes/elements/name.lua` | Max width | 7 |
| `SaftUI-Unitframes/elements/indicators.lua` | role icons' ValidUnit; PostUpdate by kind; quest icon | 4, 5, 7 |
| `SaftUI-Core/themeart.lua` | the `nameplatetarget` control | 8 |
| `SaftUI-Core/Config/defaults.lua`, `SaftUI-Core/Media/colors.lua` | the threat colours | 9 |
| `tests/wow/game.lua` | new API stubs | 2, 4, 5, 6, 7, 9, 10 |
| `tests/wow/widgets.lua` | attributes; layout rounding; ignore parent scale | 3, 11 |
| `tests/wow/blizzard.lua` | `NamePlateDriverFrame`, `PlayerUtil`, `Enum.SpellBookSpellBank` | 4, 9, 10 |
| `tests/wow/atlases.lua` | the target border atlases | 8 |
| `tests/lib/secrets.lua` (new) | secret values for tests | 2 |
| `tests/unitframes/fixtures/ouf.lua` (new) | the oUF stand-in | 3, 4, 11 |
| `tests/unitframes/nameplate_world.lua` (new) | the plates' test world | 4 |

## Order and parallelism

| Task | Depends on | Wave |
| --- | --- | --- |
| 1 Castbar colours | — | 1 |
| 2 Secret-safe name and health texts | — | 1 |
| 3 Group units after oUF's init | — | 1 |
| 10 Only buffs I can purge | — | 1 |
| 4 The nameplate unit and its spawning | 3 | 2 |
| 5 Each add: friendly or enemy, widgets, forbidden plates | 1, 2, 3, 4, 10 | 3 |
| 6 The Nameplates page and the game's settings | 4 | 3 |
| 8 The target's border | 4 | 3 |
| 7 The plate's layout | 5, 6 | 4 |
| 9 Threat | 2, 3, 5 | 4 |
| 11 Pixel-perfect plates and the scale settings | 5, 6, 7, 10 | 5 |
| 12 The plates in each theme | 7, 8, 9 | 5 |
| 13 Docs | all | 6 |

Each task's own **Files** block lists what it touches, and the Files table above gives the same by file. Tasks in the same wave are independent and can run in parallel worktrees. They share only append-only files. When merging, keep both sides of:

- `tests/wow/game.lua`: stubs appended by 2, 4, 5, 6, 7, 9 and 10;
- `SaftUI-Unitframes/nameplates/nameplates.xml`: a `<Script>` line each from 6, 8, 9 and 11;
- `tests/wow/blizzard.lua`;
- `docs/followups.md`.

Wave 1 has one more overlap: Tasks 2 and 3 both edit `elements/health.lua`, in different functions (2 `PostUpdateHealth`, 3 `UpdateConfig`).

---

### Task 1: Castbar colours from oUF's argument; no classic-only fallback

**Files:**
- Modify: `SaftUI-Unitframes/elements/castbar.lua` (`PostCastStart`, `Constructor`)
- Test: `tests/unitframes/bar_colors_test.lua` (its four castbar cases pass the argument; four new cases)

**Interfaces:**
- Produces:
  - `PostCastStart(castbar, unit, spellID, notInterruptible)` and `PostCastInterruptible(castbar, unit, spellID, notInterruptible)`, set on every castbar. These are the bundled oUF's callbacks (`Libraries/oUF/elements/castbar.lua` 306, 511).
  - No `PostChannelStart`: this oUF never calls one, because `CastStart` runs `PostCastStart` for channels too.

- [ ] **Step 1: Write the failing tests**

In the four existing castbar cases, replace `castbar.notInterruptible = X; castbar.PostCastStart(castbar, 'player')` with `castbar.PostCastStart(castbar, 'player', 1, X)`. Add:

```lua
local function fill(castbar) return stub.state(castbar).color_fill end
test("castbar: oUF's notInterruptible argument picks the bar color", function()
	local castbar = bar('Castbar'); UF:UpdateStatusBarElement(castbar)
	local c = castbar.config.colors
	castbar.PostCastStart(castbar, 'target', 133, true)
	check(near(fill(castbar)[1], c.nointerrupt.r) and near(fill(castbar)[3], c.nointerrupt.b), "can't interrupt: its color")
	castbar.PostCastStart(castbar, 'target', 133, false)
	check(near(fill(castbar)[1], c.normal.r) and near(fill(castbar)[3], c.normal.b), 'interruptible: the castbar color')
end)
test('castbar: a cast turning uninterruptible mid-cast recolors', function()
	local castbar = bar('Castbar'); UF:UpdateStatusBarElement(castbar)
	castbar.PostCastStart(castbar, 'target', 133, false)
	castbar.PostCastInterruptible(castbar, 'target', 133, true)
	check(near(fill(castbar)[1], castbar.config.colors.nointerrupt.r), "now the can't-interrupt color")
end)
test('castbar: a secret notInterruptible is handed to EvaluateColorValueFromBoolean', function()
	local castbar = bar('Castbar'); UF:UpdateStatusBarElement(castbar)
	local got = {}
	C_CurveUtil.EvaluateColorValueFromBoolean = function(b, t, f) got[#got + 1] = { b, t, f }; return secret end
	castbar.SetStatusBarColor = function() end -- the stub's takes numbers only
	castbar.PostCastStart(castbar, 'target', 133, secret)
	eq(#got, 3, 'r, g and b')
	check(got[1][1] == secret and near(got[1][2], castbar.config.colors.nointerrupt.r) and near(got[1][3], castbar.config.colors.normal.r), 'the secret, then true and false colors')
end)
test("castbar: the icon is oUF's; no CastingInfo is read", function()
	local castbar = bar('Castbar'); UF:UpdateStatusBarElement(castbar)
	CastingInfo = nil -- classic-only (Blizzard_DeprecatedUnitScript); Forever and retail lack it
	castbar.Icon.texture:SetTexture([[Interface\ICONS\INV_Misc_QuestionMark]])
	local ok, err = pcall(castbar.PostCastStart, castbar, 'target', 133, false)
	check(ok, 'no error: ' .. tostring(err))
	eq(castbar.Icon.texture:GetTexture(), [[Interface\ICONS\INV_Misc_QuestionMark]], 'the icon left as oUF set it')
end)
```

Each case that swaps `C_CurveUtil.EvaluateColorValueFromBoolean` puts the file's stand-in back at its end.

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/bar_colors_test.lua`
Expected: FAIL. The colour cases get the normal colour (the code reads `castbar.notInterruptible`), `PostCastInterruptible` is nil, and the icon case errors with "attempt to call global 'CastingInfo'".

- [ ] **Step 3: Implement it in `castbar.lua`**

Add one local, `ColorCast(castbar, notInterruptible)`, which does what `PostCastStart` does today with the argument in place of `castbar.notInterruptible`:

- a secret argument goes through `GetColorFromBoolean` and `SetStatusBarColor`;
- otherwise `SetColorFill`;
- either way, the background is coloured as before.

`PostCastStart` and `PostCastInterruptible` both call it. Delete the `CastingInfo` block (the bundled oUF always sets the icon, and falls back to its own icon), and delete the `castbar.PostChannelStart` line.

- [ ] **Step 4: Run them to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/bar_colors_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/elements/castbar.lua tests/unitframes/bar_colors_test.lua
git commit -m "unitframes: the castbar colours a cast from oUF's notInterruptible, with no classic-only icon fallback"
```

---

### Task 2: Secret-safe name and health texts

**Files:**
- Modify: `SaftUI-Unitframes/tags.lua` (the `st:name` method), `SaftUI-Unitframes/elements/health.lua` (`PostUpdateHealth`'s percent branch), `tests/wow/game.lua`
- Create: `tests/lib/secrets.lua`, `tests/unitframes/secret_texts_test.lua`
- Modify: `docs/followups.md` (one new entry, below)

**Interfaces:**
- Produces:
  - `tests/lib/secrets.lua`, loaded with `local S = load_test_file('lib/secrets.lua')`:
    - `S.secret(label) -> userdata`, which errors on indexing, calling, `#`, `..`, arithmetic and ordering, as `power_text_test.lua`'s secret does;
    - `S.install() -> restore()`, which makes the global `issecretvalue` recognise every value `S.secret` made, plus whatever it recognised before. `restore()` puts the old function back.

    Tasks 9 and later use it.
  - `C_StringUtil.WrapString(str, prefix, suffix)` in `tests/wow/game.lua`:
    - a plain string or number gives `prefix .. str .. suffix` (nil counts as `''`);
    - a value the global `issecretvalue` calls secret gives `{ wrapped = str, prefix = prefix, suffix = suffix }`. In game the result is a secret string; the table lets a test read the parts.

    `StringUtilDocumentation.lua` has it on both clients.
  - `UnitIsDead(unit)` in `tests/wow/game.lua`: from `stub.units[unit].dead`; for the player, `stub.dead`.
- The `st:name` tag keeps its signature `(unit, realUnit, baseUnit)`, and may now return a secret.

- [ ] **Step 1: Write the failing tests**

The world: the name tag's world as `config_test.lua` builds it (its header and lines 76-81: Core helpers, the unit frames' defaults, `config/config.lua` for `UF:GetProfileConfig`, `UF.oUF` as far as `tags.lua` uses it, and LibStringFormat-1.0 as `st.StringFormat`). Health bars come from health's own constructor, as `bar_colors_test.lua` builds bars. `UnitHealthPercent` and `CurveConstants` are stood in the way `power_text_test.lua` stands in `UnitPowerPercent`: return a secret, and record the arguments. The locals the cases use: `P` (`UF:GetProfileConfig()`), `tag` (`UF.oUF.Tags.Methods['st:name']`), `bar(name)` (an element built by its own constructor, as in `bar_colors_test.lua`), `S` (`tests/lib/secrets.lua`, installed), `secretPercent` (what the `UnitHealthPercent` stand-in returns) and `lastHealthPercentArgs` (the arguments it got).

```lua
test('the name tag wraps a secret name in its hostile colour with C_StringUtil.WrapString', function()
	local name = S.secret('NAME')
	P.target.name.color_hostile, P.target.name.showLevel = true, false
	stub.units.target = { name = name, level = 22, reaction = 2 }
	local text = tag('target', 'target', 'target')
	check(type(text) == 'table' and text.wrapped == name, 'WrapString got the name')
	eq(text.prefix, '|cff' .. st.StringFormat:ToHex(st.config.profile.colors.text.red:GetRGB()), 'red before it')
	eq(text.suffix, '|r', 'and the colour closed after it')
end)
test('the name tag leaves out a secret level, reaction or classification, with no error', function()
	P.target.name.showLevel, P.target.name.show_classification, P.target.name.color_hostile = true, true, true
	stub.units.target = { name = 'Mob', level = S.secret('LVL'), reaction = S.secret('REACT'), classification = S.secret('CLS') }
	local ok, text = pcall(tag, 'target', 'target', 'target')
	check(ok, tostring(text)); eq(text, 'Mob', 'just the name')
end)
test('All caps leaves a secret name as it is', function()
	P.target.name.allCaps = true
	stub.units.target = { name = S.secret('NAME'), level = 22, reaction = 5 }
	check(pcall(tag, 'target', 'target', 'target'), 'no strupper on a secret')
end)
test('the name tag reads no UnitIsUnit: the 2019 target mark is gone, the target border replaces it', function()
	check(not read_saftui_source('SaftUI-Unitframes/tags.lua'):find('UnitIsUnit', 1, true), 'not in tags.lua')
end)
test('health percent with a secret health is drawn from UnitHealthPercent', function()
	local health = bar('Health'); health.config.text.percent = true
	local fmt, value
	health.text.SetFormattedText = function(_, f, v) fmt, value = f, v end
	local ok, err = pcall(health.PostUpdate, health, 'nameplate1', S.secret('CUR'), S.secret('MAX'))
	check(ok, tostring(err)); eq(fmt, '%.0f'); check(value == secretPercent, 'the game formats the percent')
	check(lastHealthPercentArgs[1] == 'nameplate1' and lastHealthPercentArgs[2] == true and lastHealthPercentArgs[3] == CurveConstants.ScaleTo100, 'scaled to 0-100')
end)
test('health percent with plain values is unchanged', function()
	local health = bar('Health'); health.config.text.percent = true
	health.PostUpdate(health, 'target', 72, 100)
	eq(health.text:GetText(), '72')
end)
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/secret_texts_test.lua`
Expected: FAIL. The tag errors on `..` with a secret name, `reaction < 3` errors on a secret reaction, the source still names `UnitIsUnit`, and `floor` errors on a secret percent.

- [ ] **Step 3: Implement it**

`tags.lua`:
- Read the level, the reaction and the classification. Each one that's secret is left out: no level part, no hostile colour, no mark.
- Build the parts around the name (the level part, the colour codes) as plain strings.
- A secret name gets no `strupper` and no UTF-8 cut. It returns `C_StringUtil.WrapString(name, prefix, suffix)`.
- A plain name concatenates as today.
- Delete the `baseunit` lines; the target border (Task 8) replaces that mark.

`health.lua`'s percent branch: when `current` is secret, `health.text:SetFormattedText('%.0f', UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))`, as `UF:SetPowerPercentText` does. Otherwise, today's `getHealthPercentText`.

- [ ] **Step 4: Add the followup**

Add a `docs/followups.md` entry: "Health text's value and boss percent paths with a secret health". The boss percent branch `format`s a secret value and compares a possibly secret `UnitLevel` with `-1`. Anchors: `elements/health.lua` `PostUpdateHealth`. Out of scope here: plates use the percent branch.

- [ ] **Step 5: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/secret_texts_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Unitframes/tags.lua SaftUI-Unitframes/elements/health.lua tests/wow/game.lua tests/lib/secrets.lua tests/unitframes/secret_texts_test.lua docs/followups.md
git commit -m "unitframes: name and health texts take secret values: the name through WrapString, health percent from UnitHealthPercent"
```

---

### Task 3: Group units updated after oUF's init; colour flags through oUF's setters

**Files:**
- Modify:
  - `SaftUI-Unitframes/unitframes.lua` (`UF.ConstructUnit`, a new `UF.InitUnit`, registered in OnEnable);
  - `SaftUI-Unitframes/updaters.lua` (the TODO block in `SetElementEnabled`);
  - `SaftUI-Unitframes/elements/health.lua` and `elements/power.lua` (`UpdateConfig`'s colour flags);
  - `tests/wow/widgets.lua` (Frame `SetAttribute` / `GetAttribute`);
  - `docs/followups.md`.
- Create: `tests/unitframes/fixtures/ouf.lua`, `tests/unitframes/unit_init_test.lua`

**Interfaces:**
- Produces:
  - `UF.InitUnit(object)`. `UF:OnEnable` registers it first, with `self.oUF:RegisterInitCallback(UF.InitUnit)`, before any `Spawn`. Registering at file load would break every test that stands oUF in by its colors table (`theme_test.lua`, `blizzard_look_test.lua`, `boss_preview_test.lua` and others). It runs `UF:UpdateUnitFrame(object)` for `object.is_group_unit`; Task 4 adds `object.isNamePlate`. Single units are left to OnEnable's `UF:ApplyConfig()`.
  - `Frame.SetAttribute(name, value)` and `Frame.GetAttribute(name)` in the stub. A changed value runs `OnAttributeChanged(name, value)`, as the game does.
  - `tests/unitframes/fixtures/ouf.lua` returns `new() -> ouf`, a stand-in for the bundled oUF as far as SaftUI uses it. Its header comment says what the real oUF does beyond it. It has:
    - `colors` (`theme_test.lua`'s table) and `Tags = { Methods = {}, Events = {} }`;
    - methods called with a colon, as oUF's are: `ouf:RegisterStyle`, `ouf:SetActiveStyle`, `ouf:RegisterInitCallback`, `ouf:Spawn(unit, name) -> frame`, and `ouf:SpawnGroupButton(header, unit, name) -> frame` (a Button child of `header`, as a group header makes one);
    - a plain function, `ouf.IsInitialized(frame)`;
    - `ouf.calls`: a list of `{ frame, method, element }` for `EnableElement` and `DisableElement`.

    Every object gets `EnableElement`, `DisableElement`, `IsElementEnabled`, `UpdateAllElements` (counted in `frame.__updates`), `Tag`, `PauseAllElements`, `ResumeAllElements` and `CreateAuras`. `CreateAuras` gives a container stand-in:
    - `AddGroup(filter, options) -> 'GroupN'`, recorded in `container.groups[key] = { filter = ..., options = ... }`;
    - `SetAuraGroupFilterString` and `SetAuraGroupCandidateFilters`, recorded on the group;
    - `SetAuraGroupLayout`, `SetEnabled` (recorded in `container.enabled`) and the flow layout setters;
    - `IsObjectType('AuraContainer')` true.

    An object is built as oUF's `initObject` builds one (`ouf.lua` 431-447): the style function, then its active elements, then each element widget it has enabled, then the init callbacks. Enabling an element gives Health and Power `SetColorTapping`, `SetColorReaction` and `ForceUpdate`, as their `Enable`s do. Before init, `EnableElement` errors "attempt to index a nil value", as `ouf.lua` 104 does (`activeElements[self][name] = true`).

- [ ] **Step 1: Write the failing tests**

The world: real Core helpers and defaults, every unit's config, `unitframes.lua`, `groups.lua`, `config/config.lua`, `constructors.lua`, `updaters.lua`, `tags.lua`, the files `elements/elements.xml` lists, and LibStringFormat-1.0. `addon_namespace('SaftUI-Unitframes').oUF` is the fixture, made before `unitframes.lua` loads, and the test calls it `ouf`. `UF.InitUnit` is registered with it as OnEnable does.

```lua
test('a party button is updated once, after oUF has made its active elements', function()
	local seen = {}
	local real = UF.UpdateUnitFrame
	UF.UpdateUnitFrame = function(self, frame, ...) seen[#seen + 1] = ouf.IsInitialized(frame); return real(self, frame, ...) end
	local header = CreateFrame('Frame', 'SaftUI_Party', UIParent); header:SetAttribute('base_unit', 'party')
	ouf:SpawnGroupButton(header, 'party1', 'SaftUI_PartyUnitButton1')
	UF.UpdateUnitFrame = real
	eq(#seen, 1, 'once'); eq(seen[1], true, 'after init')
end)
test("OnEnable registers UF.InitUnit before it spawns anything", function()
	local body = read_saftui_source('SaftUI-Unitframes/unitframes.lua'):match('function UF:OnEnable%(%)(.-)\nend')
	check(body:find('RegisterInitCallback(UF.InitUnit)', 1, true) < body:find('Spawn', 1, true), 'registered first')
end)
test('a single unit is not updated by the init callback: OnEnable places it', function()
	-- spy as above; ouf:Spawn('player', 'SaftUI_Player') -> no call
end)
test("the stand-in's EnableElement errors before init, as oUF's does", function()
	-- a style function that calls self:EnableElement('Health') -> the spawn errors "attempt to index a nil value"
end)
test("health and power colour flags go through oUF's setters once enabled, so their events register", function()
	local frame = ouf:Spawn('target', 'SaftUI_Target')
	local got = {}
	frame.Health.SetColorTapping = function(_, state, forced) got[#got + 1] = { 'tapping', state, forced } end
	frame.Health.SetColorReaction = function(_, state, forced) got[#got + 1] = { 'reaction', state, forced } end
	UF.elements.Health.UpdateConfig(frame, 'Health')
	-- got = { { 'tapping', P.target.health.colorTapping, true }, { 'reaction', P.target.health.colorReaction, true } }
	-- and the same for Power
end)
test('before oUF enables a bar, the flags are plain fields', function()
	-- an element with no SetColorTapping: health.colorTapping == config.colorTapping
end)
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/unit_init_test.lua`
Expected: FAIL. The party button is updated during its style function (`seen[1] == false`), and no setter is called.

- [ ] **Step 3: Implement it**

- `ConstructUnit`: drop the `UF:UpdateUnitFrame(self)` call from the group branch. Other units still go in `UF.allUnits`.
- Add `UF.InitUnit`, and register it as `UF:OnEnable`'s first line.
- `health.lua` and `power.lua` `UpdateConfig`: when `element.SetColorTapping` exists, call `element:SetColorTapping(config.colorTapping, true)`, and the same for `SetColorReaction`. A forced call registers or unregisters the event to match. Otherwise assign the fields as today, and oUF's `Enable` registers the events itself.
- `updaters.lua`: replace the commented TODO block with a comment. `SetElementEnabled` only shows or hides. oUF enables every element at init. `DisableElement` isn't used for these units, because oUF's castbar `Disable` re-registers Blizzard's player castbar (`Libraries/oUF/elements/castbar.lua` 744-752), which the player castbar's option promises not to do.

- [ ] **Step 4: Resolve the followup**

Move "2026-11-09 — Unit frame color flags are set after oUF enables the bars, so their recolor events are never registered" to Resolved, with `**Resolved 2026-11-11:**` and one line on the fix. Update the ToC.

- [ ] **Step 5: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/unit_init_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Unitframes/unitframes.lua SaftUI-Unitframes/updaters.lua SaftUI-Unitframes/elements/health.lua SaftUI-Unitframes/elements/power.lua tests/wow/widgets.lua tests/unitframes/fixtures/ouf.lua tests/unitframes/unit_init_test.lua docs/followups.md
git commit -m "unitframes: group units update from oUF's init callback, and the bars' colour flags go through oUF's setters"
```

---

### Task 4: The nameplate unit and its spawning

**Files:**
- Create: `SaftUI-Unitframes/nameplates/nameplates.xml` (one `<Script file="nameplates.lua"/>`), `nameplates/nameplates.lua`, `SaftUI-Unitframes/config/units/nameplate.lua`, `tests/unitframes/nameplate_world.lua`, `tests/unitframes/nameplate_spawn_test.lua`
- Modify:
  - `config/load.xml` (`units\nameplate.lua` after `units\raid40.lua`);
  - both TOCs (`nameplates\nameplates.xml` after `elements\elements.xml`);
  - `unitframes.lua`;
  - `elements/power.lua` (ValidUnit);
  - `elements/indicators.lua` (`validUnit` on GroupRoleIndicator and RaidRoleIndicator);
  - `tests/wow/game.lua`, `tests/wow/blizzard.lua`, `tests/unitframes/fixtures/ouf.lua`.

**Interfaces:**
- Consumes: `UF.InitUnit` and the oUF fixture (Task 3).
- Produces, in `nameplates/nameplates.lua`:
  - `UF.NAMEPLATE_ADDONS`: an ordered list of `{ addon = <folder>, label = <name shown>, drawsPlates = <function, optional> }`:

    | addon | label |
    | --- | --- |
    | `Plater` | Plater |
    | `EllesmereUINameplates` | EllesmereUI Nameplates |
    | `Kui_Nameplates` | KuiNameplates |
    | `TidyPlates_ThreatPlates` | Threat Plates |
    | `NeatPlates` | NeatPlates |
    | `ElvUI` | ElvUI |

    `ElvUI`'s `drawsPlates` returns false only when `ElvUI[1].private.nameplates.enable == false`. It reads with nil checks, so ElvUI loaded with its private table not yet set up counts as drawing. The folder names Plater and EllesmereUINameplates were checked in the user's AddOns folder.
  - `UF:NameplateAddon() -> label|nil`: the first loaded addon (whose `drawsPlates`, if it has one, returns true).
  - `UF.nameplates = {}`, by plate number (`frame.ID`); `UF:ForEachPlate(fn(frame))`; `UF:PlateForUnit(unit) -> frame|nil`, by `frame.__unit`.
  - `UF:RegisterPlateCallback(event, fn)` and `UF:RunPlateCallbacks(event, frame, ...)`. The events: `'added'` (`fn(frame, unit)`), `'removed'` (`fn(frame, unit)`), `'updated'` (`fn(frame)`, after every `UF:UpdateUnitFrame` on a plate).
  - `UF:SpawnNameplates() -> boolean`. It returns false, doing nothing, when `UF.plateDriver` exists, when the nameplate config's `enable` is off, or when `UF:NameplateAddon()` names an addon. Otherwise:
    1. `UF.plateDriver = UF.oUF:SpawnNamePlates('SaftUI_')`, so the frames are `SaftUI_NamePlateN`;
    2. the added and removed callbacks run the plate callbacks;
    3. `UF:ApplyPlateSize()`;
    4. `hooksecurefunc(NamePlateDriverFrame, 'UpdateNamePlateSize', function() UF:ApplyPlateSize() end)`.
  - `UF:ApplyPlateSize()`: `UF.plateDriver:SetSize(UF.PlateDriverSize(config.width, config.height))`. In combat it waits (`st:QueueAfterCombat('NameplateSize', ...)`).
  - `UF.PlateDriverSize(width, height) -> width, height`: the config's for now; Task 11 converts it.
- Produces, in `unitframes.lua`:
  - `ConstructUnit` puts a plate (`self.isNamePlate`) in `UF.nameplates[self.ID]`, not in `UF.allUnits`;
  - `UF.InitUnit` also updates `isNamePlate` objects;
  - `ForEachUnitFrame` visits the plates;
  - `ApplyConfig('nameplate', element)` updates each plate (`SafeUpdateUnitFrame`) and, with no element, calls `ApplyPlateSize`; `ApplyConfig()` includes the plates; `ClearUnitFramePoints` leaves them;
  - `PlaceUnitFrame` returns true for a plate and touches nothing (oUF sets its points to the plate's);
  - `UpdateUnitFrame` ends with `UF:RunPlateCallbacks('updated', frame)` for a plate;
  - OnEnable calls `UF:SpawnNameplates()` after `CreateGroupHeaders`, `ApplyConfig`, `UpdateColors` and `RegisterMovers`. Plates get no mover.
- Produces, the defaults: `profiles['**'].nameplate = { enable = true, friendly = true, threat_solo = false, width = 200, height = 20 }`. Task 7 adds the elements' defaults.
- Produces, ValidUnit: Power, GroupRoleIndicator and RaidRoleIndicator reject `'nameplate'`. AdditionalPower and ClassPower are player-only, and ReadyCheck group-only, already.
- Produces, the stubs in `tests/wow/game.lua` (`NamePlateDocumentation.lua`, the same on both clients):
  - `C_NamePlate.GetNamePlateForUnit(unit, includeForbidden)`. `'target'` gives the plate of `stub.nameplate_target`. A forbidden plate is nil unless `includeForbidden` is passed: addon code never gets one.
  - `C_NamePlate.GetNamePlates()`.
  - `C_NamePlate.SetNamePlateSize(w, h)`. In combat it's refused and noted in `stub.blocked` as `{ C_NamePlate, 'SetNamePlateSize' }` (the docs mark it HasRestrictions). Otherwise it sets `stub.nameplate_size = { w, h }` and sizes every plate.
  - `stub.add_nameplate(unit, opts) -> plate`, which fires `NAME_PLATE_UNIT_ADDED`. `opts` takes `forbidden`, `widgets_only`, `game_object`, and `plate = n` to reuse NamePlate<n>. Each add hands the plate a new pooled Blizzard `UnitFrame` with `WidgetContainer` and `SoftTargetFrame` children, set with `rawset`, as Blizzard's pool does.
  - `stub.remove_nameplate(unit)`, which fires `NAME_PLATE_UNIT_REMOVED`.
  - `stub.nameplate_target`.
  - `UnitNameplateShowsWidgetsOnly(unit)` and `UnitIsGameObject(unit)`, from the add's `opts`.
  - `stub.set_nameplate_size_secure(w, h)`: sets the size even in combat, as Blizzard's untainted code can.
- Produces, in `tests/wow/blizzard.lua`: `NamePlateDriverFrame`, with `UpdateNamePlateSize()` calling `stub.set_nameplate_size_secure(230, 45)`. Blizzard's own call (`Blizzard_NamePlates.lua` 630-636) sizes plates from its options; the numbers are the stand-in's.
- Produces, in the fixture: `ouf:SpawnNamePlates(prefix) -> driver`, modelled on `ouf.lua` 866-1097:
  - the driver: `SetSize` (calls `C_NamePlate.SetNamePlateSize`), `SetAddedCallback`, `SetRemovedCallback`, `SetTargetCallback`;
  - a forbidden plate is skipped;
  - a NamePlateN's first add: a Button `prefix .. plate:GetName()`, child of the plate, `EnableMouse(false)`, `SetAllPoints`, `isNamePlate = true`; `rawset` of `plate.unitFrame` and `plate.style` (the library's own departure from rule 1); style and init; WidgetContainer and SoftTargetFrame reparented (first add only, as upstream);
  - a widgets-only or game-object unit: pause and hide, with no added callback;
  - otherwise: `__unit`, then the added callback, then `UpdateAllElements`;
  - a remove: unit cleared, resume, show, then the removed callback;
  - a second `SpawnNamePlates` errors 'oUF nameplate driver has already been initialized.'.
- Produces, `tests/unitframes/nameplate_world.lua`, which returns `NP`:
  - `NP.world(client) -> st, UF`: a fresh world on `'forever'` or `'retail'`. It has:
    - real Core helpers and defaults, every unit's config (`nameplate.lua` included);
    - `unitframes.lua`, `groups.lua`, `config/config.lua`, `constructors.lua`, `updaters.lua`, `tags.lua`, `purge.lua`;
    - the files `elements/elements.xml` and `nameplates/nameplates.xml` list, read from the XML so later tasks' files load;
    - LibStringFormat-1.0;
    - the fixture as `UF.oUF`, with `UF.InitUnit` registered and the style registered and active, as OnEnable leaves them;
    - `UF.units`, `UF.allUnits` and `UF.holders` empty; `st.config.global = {}`;
    - `NamePlateDriverFrame`, and every NamePlateN with its UnitFrame, WidgetContainer and SoftTargetFrame, locked with `misc/fixtures/locked_widget.lua` as Blizzard's.
  - `NP.add(unit, opts) -> frame`: SaftUI's frame on the new plate, found as the plate's child with `isNamePlate`, never by reading `plate.unitFrame`.
  - `NP.remove(unit)`.

- [ ] **Step 1: Write the failing tests** (`nameplate_spawn_test.lua`)

```lua
local NP = load_test_file('unitframes/nameplate_world.lua')
test('Nameplates on: one driver, the config size, and a second call spawns nothing', function()
	local st, UF = NP.world('forever')
	-- sizes are compared with UF.PlateDriverSize(200, 20), so Task 11's conversion keeps these cases right
	local size = table.concat({ UF.PlateDriverSize(200, 20) }, 'x')
	check(UF:SpawnNameplates(), 'spawned'); eq(table.concat(stub.nameplate_size, 'x'), size)
	check(not UF:SpawnNameplates(), 'not again'); eq(#take_errors(), 0)
end)
test('OnEnable spawns nameplates after the other units', function()
	local src = read_saftui_source('SaftUI-Unitframes/unitframes.lua')
	local body = src:match('function UF:OnEnable%(%)(.-)\nend')
	for _, call in ipairs({ 'CreateGroupHeaders', 'ApplyConfig', 'RegisterMovers' }) do
		check(body:find(call, 1, true) < body:find('SpawnNameplates', 1, true), call .. ' first')
	end
end)
test('Nameplates off: no driver, no size set', function() --[[ P.nameplate.enable = false ]] end)
test('another nameplate addon loaded: SaftUI stands down and touches nothing', function()
	for _, a in ipairs({ { 'Plater', 'Plater' }, { 'EllesmereUINameplates', 'EllesmereUI Nameplates' }, { 'Kui_Nameplates', 'KuiNameplates' }, { 'TidyPlates_ThreatPlates', 'Threat Plates' }, { 'NeatPlates', 'NeatPlates' } }) do
		local st, UF = NP.world('forever'); stub.loaded_addons[a[1]] = true
		local before = rawget(NamePlateDriverFrame, 'UpdateNamePlateSize')
		check(not UF:SpawnNameplates(), a[1]); eq(UF:NameplateAddon(), a[2])
		eq(stub.nameplate_size, nil, 'no size'); eq(rawget(NamePlateDriverFrame, 'UpdateNamePlateSize'), before, 'not hooked')
	end
end)
test('ElvUI stands SaftUI down while its nameplates are on', function()
	-- ElvUI = { { private = { nameplates = { enable = false } } } } -> spawns
	-- enable = true -> stands down; ElvUI = { {} } (private not set up) -> stands down
end)
test("a plate's first add builds SaftUI's frame, kept in UF.nameplates by its number, not UF.allUnits", function()
	-- frame = NP.add('nameplate1'); eq(frame:GetName(), 'SaftUI_NamePlate1'); eq(UF.nameplates[1], frame); eq(UF.allUnits.nameplate1, nil)
end)
test('a plate has health, name, castbar, buffs, debuffs, quest and raid target icons, and nothing else', function()
	-- sorted keys of frame.elements == 'Buffs,Castbar,Debuffs,Health,Name,QuestIndicator,RaidTargetIndicator'
end)
test("a plate is updated after its init, never from the style function", function()
	-- spy UF.UpdateUnitFrame with ouf.IsInitialized: one call on the first add, initialized; a second add of the same plate: no full update
end)
test("the plate size is set again after Blizzard sets its own, and waits for the end of combat", function()
	local st, UF = NP.world('forever'); UF:SpawnNameplates()
	local size = table.concat({ UF.PlateDriverSize(200, 20) }, 'x')
	NamePlateDriverFrame:UpdateNamePlateSize(); eq(table.concat(stub.nameplate_size, 'x'), size, "SaftUI's again")
	stub.in_combat = true; NamePlateDriverFrame:UpdateNamePlateSize()
	eq(table.concat(stub.nameplate_size, 'x'), '230x45', "Blizzard's until combat ends"); eq(#stub.blocked, 0, 'SaftUI waited')
	stub.in_combat = false; stub.fire_event('PLAYER_REGEN_ENABLED'); eq(table.concat(stub.nameplate_size, 'x'), size)
end)
test('config changes reach the plates', function()
	-- ForEachUnitFrame visits both plates; UF:UpdateConfig('nameplate', 'Health') re-runs Health's UpdateConfig on each;
	-- UF:UpdateConfig() too; after it, each plate's only anchors are oUF's SetAllPoints to its plate;
	-- RefreshConfigReferences points each plate's config at a new profile's table
end)
test('a removed plate runs the removed callbacks and keeps its frame for the next add', function()
	-- a registered 'removed' callback got (frame, 'nameplate1'); frame.__unit is nil; NP.add('nameplate2', { plate = 1 }) gives the same frame
end)
test("nothing is written onto Blizzard's plate frames", function()
	-- add, remove, re-add, size, Blizzard's size update: no error from the locked frames (take_errors empty)
end)
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/nameplate_spawn_test.lua`
Expected: FAIL, because `UF:SpawnNameplates` is nil.

- [ ] **Step 3: Implement it.** Use the signatures under Interfaces; the stubs and the fixture come first.

- [ ] **Step 4: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/nameplate_spawn_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0 (`tests/core/theme_kinds_test.lua` scans the new files).

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/nameplates/nameplates.xml SaftUI-Unitframes/nameplates/nameplates.lua SaftUI-Unitframes/config/units/nameplate.lua SaftUI-Unitframes/config/load.xml SaftUI-Unitframes/SaftUI-Unitframes_Forever.toc SaftUI-Unitframes/SaftUI-Unitframes_Mainline.toc SaftUI-Unitframes/unitframes.lua SaftUI-Unitframes/elements/power.lua SaftUI-Unitframes/elements/indicators.lua tests/wow/game.lua tests/wow/blizzard.lua tests/unitframes/fixtures/ouf.lua tests/unitframes/nameplate_world.lua tests/unitframes/nameplate_spawn_test.lua
git commit -m "unitframes: a nameplate unit, spawned once by oUF after the other units, standing down for another nameplate addon"
```

---

### Task 5: Each add: friendly or enemy, Blizzard's widgets, forbidden plates

**Files:**
- Modify:
  - `SaftUI-Unitframes/nameplates/nameplates.lua`;
  - `SaftUI-Unitframes/updaters.lua` (`UF:ElementWanted`, `SetElementEnabled`);
  - `elements/castbar.lua` (`ShouldShow`);
  - `elements/indicators.lua` (the `PostUpdate` wrapper);
  - `elements/auras.lua` (`UpdateConfig`'s `SetEnabled`);
  - `tests/wow/game.lua`.
- Create: `tests/unitframes/nameplate_kind_test.lua`

**Interfaces:**
- Consumes: Task 4's callbacks, `UF.nameplates`, `UF:PlateForUnit` and the nameplate world; `tests/lib/secrets.lua` (Task 2).
- Produces:
  - `UF.PLATE_ENEMY_ONLY = { Castbar = true, Buffs = true, Debuffs = true, QuestIndicator = true }`.
  - `UF.IsFriendlyPlate(unit) -> boolean`: `UnitIsFriend('player', unit)` and not `UnitCanAttack('player', unit)`. That's Blizzard's `UpdateIsFriend`, where an attackable cross-faction party member counts as an enemy. A secret answer counts as an enemy, so the plate is full.
  - `UF:ElementWanted(element) -> boolean` (`updaters.lua`): `element.config.enable`, and not (its unit frame is a friendly plate and the element is enemy-only).
  - `UF:SetElementEnabled(element)` shows by `ElementWanted`, but still returns `element.config.enable`. So `UF:UpdateElement` places and sizes a part a friendly plate hides, and it's ready for the next enemy.
  - `UF:ApplyPlateKind(frame, friendly)`: sets `frame.friendly`, then for each enemy-only element the frame has:
    - the oUF ones (Castbar, QuestIndicator) get `frame:EnableElement(name)` or `frame:DisableElement(name)`, by `UF:ElementWanted`;
    - every one gets `SetShown(wanted)`;
    - aura areas get `SetEnabled(wanted)`.

    It's registered as an `'added'` callback (`UF.IsFriendlyPlate(unit)`). It's also re-run for a plate's unit on `UNIT_FACTION`.
  - castbar `ShouldShow`, the indicators' `PostUpdate` wrapper and auras `UpdateConfig`'s `SetEnabled` use `UF:ElementWanted` in place of `config.enable`.
  - SaftUI's own `NAME_PLATE_UNIT_ADDED` listener, registered in `SpawnNameplates`. On every add, widget-only and game-object units included: `plate.UnitFrame.WidgetContainer:SetParent(plate)`, `:SetPoint('TOP', plate, 'BOTTOM')`, and `plate.UnitFrame.SoftTargetFrame:SetParent(plate)`. These are the calls oUF makes on a first add; reading `plate.UnitFrame` is a read. A plate `C_NamePlate.GetNamePlateForUnit` doesn't give (forbidden) is skipped.
  - Stubs: `UnitIsFriend(unit, other)` and `UnitCanAttack(unit, other)`, between the player and a `stub.units` unit, from its `friend` and `attackable` fields. A test can put a secret in either.

- [ ] **Step 1: Write the failing tests** (`nameplate_kind_test.lua`)

```lua
test('an enemy plate shows every part; a friendly plate carries the bar, name, health text and raid mark', function()
	-- P.nameplate.castbar.enable = true (Task 7 makes it the default)
	-- enemy (attackable): Castbar and QuestIndicator enabled (ouf.calls), Buffs and Debuffs container.enabled true
	-- friendly (friend): Castbar and QuestIndicator DisableElement'd and hidden; Buffs and Debuffs enabled false; Health, Name, Health.text and RaidTargetIndicator shown
end)
test('a friendly plate never shows a cast', function() --[[ castbar.ShouldShow(castbar, unit) == false and hidden ]] end)
test('a plate reused for an enemy shows the enemy parts, placed', function() -- Review Focus 1
	-- first add of NamePlate1: friendly; remove; NP.add('nameplate2', { plate = 1 }) for an enemy:
	-- the castbar enabled and shown, and its first point its config's position (point, relative frame, offsets)
end)
test('an attackable friend counts as an enemy, and a secret answer too', function()
	-- friend and attackable: the castbar enabled; UnitIsFriend giving S.secret('F'): enabled, no error
end)
test('a unit turning hostile gets the enemy parts at once', function() --[[ friend -> attackable, fire UNIT_FACTION(unit) ]] end)
test('widgets move to the plate on every add, widget-only plates too', function() -- Review Focus 2
	-- second add of NamePlate1 (a new pooled UnitFrame): its WidgetContainer and SoftTargetFrame have the plate as parent
	-- NP.add('nameplate3', { widgets_only = true }): the same, though no added callback ran
end)
test('a forbidden plate is left alone', function()
	-- stub.add_nameplate('nameplate4', { forbidden = true }): no SaftUI frame on it, its WidgetContainer's parent unchanged, no callbacks
end)
test('kinds are applied after init: a first add of a friendly plate raises no error', function()
	-- the fixture's EnableElement errors before init; NP.add of a friend on a fresh plate: take_errors() empty, Castbar disabled
end)
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/nameplate_kind_test.lua`
Expected: FAIL. A friendly plate still shows its castbar, and the second add's WidgetContainer keeps its pooled parent.

- [ ] **Step 3: Implement it.** Use the signatures under Interfaces.

- [ ] **Step 4: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/nameplate_kind_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0 (`theme_test.lua` and `blizzard_look_test.lua` still draw every other unit's parts).

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/nameplates/nameplates.lua SaftUI-Unitframes/updaters.lua SaftUI-Unitframes/elements/castbar.lua SaftUI-Unitframes/elements/indicators.lua SaftUI-Unitframes/elements/auras.lua tests/wow/game.lua tests/unitframes/nameplate_kind_test.lua
git commit -m "unitframes: friendly plates carry the bar, name, health and raid mark; Blizzard's widgets move to every plate on every add"
```

---

### Task 6: The Nameplates page and the game's nameplate settings

**Files:**
- Create: `SaftUI-Unitframes/nameplates/cvars.lua`, `tests/unitframes/nameplate_page_test.lua`
- Modify:
  - `nameplates/nameplates.xml` (`cvars.lua`);
  - `SaftUI-Unitframes/config/config.lua` (the page, `UNIT_ORDER`, `UNIT_SHOWS`, `GetConfigFrame`);
  - `unitframes.lua` (OnEnable, after `SpawnNameplates`);
  - `tests/wow/game.lua` (`C_CVar`);
  - `tests/unitframes/config_test.lua` (the unit picker's order, and loading `nameplate.lua`).

**Interfaces:**
- Consumes: `UF:SpawnNameplates`, `UF.plateDriver`, `UF:NameplateAddon`, `UF.nameplates` (Task 4).
- Produces, in `nameplates/cvars.lua`:
  - `UF.NAMEPLATE_CVARS`: `{ [name] = function(config) -> string }`, the settings applied while SaftUI's plates are on. This task adds `nameplateShowFriendlyPlayers` and `nameplateShowFriendlyNpcs`, both `config.friendly and '1' or '0'`. Task 11 adds the scale ones.
  - `UF:SetNameplateCVar(name, value)`:
    - skips a name `C_CVar.GetCVar` gives nil for (the client has no such setting);
    - records `st.config.global.nameplateCVars[name] = C_CVar.GetCVar(name)` when it has no record yet;
    - sets it.

    Callers are out of combat.
  - `UF:ApplyNameplateCVars()`: does nothing without `UF.plateDriver`. In combat it waits (`st:QueueAfterCombat('NameplateCVars', ...)`). Then it sets each `UF.NAMEPLATE_CVARS` entry from the nameplate config.
  - `UF:RestoreNameplateCVars()`: in combat it waits (same key). It sets each recorded value back, then clears the record.
- Produces, in OnEnable after `UF:SpawnNameplates()`: spawned → `UF:ApplyNameplateCVars()`; not spawned, and no other nameplate addon → `UF:RestoreNameplateCVars()`.
- Produces, the page: `config.args.nameplate`, always present.
  - It's named "Nameplates", follows Raid 40 in `UNIT_ORDER`, and has `UNIT_SHOWS.nameplate = { players = true, npcs = true, pets = true, mobs = true }`.
  - Its element tabs are every unit's (by ValidUnit).
  - General has these rows, with these descs (exact copy):

    | Row | Desc | Set |
    | --- | --- | --- |
    | Nameplates (`enable`) | "Draws nameplates in SaftUI's look: enemies and neutral units, and friendly ones outside instances. Changes after a reload." | saves; when turned off, `UF:RestoreNameplateCVars()`; then `st.OptionsWidgets.Confirm('Nameplates change after a reload. Reload now?', ReloadUI)` |
    | Friendly plates (`friendly`) | "Shows nameplates over friendly players and NPCs: SaftUI's outside instances, Blizzard's inside them. Off, friendly units have none." | `UF:ApplyNameplateCVars()` |
    | Threat when solo (`threat_solo`) | "Tints enemy health bars by your threat while you're on your own too. In a party or raid they're always tinted." | `UF:UpdateConfig('nameplate')` |
    | Width | "Every nameplate's width: its health bar and the area you click." | `UF:UpdateConfig('nameplate')`, which re-applies the plate size |
    | Height | "Every nameplate's height: its health bar and the area you click." | as Width |

    Theme and Background are also on General. There's no Position, Layout or Range.
  - Stood down (`UF:NameplateAddon()`): a description row first, "Nameplates are drawn by <label>. Turn it off to use SaftUI's.", and `disabled` on the unit's group, so every option dims.
- Produces, `UF:GetConfigFrame('nameplate')`: the plate with the lowest number in `UF.nameplates`, or nil. The element Position editors use it.
- Produces, the stubs (`CVarDocumentation.lua`, `C_CVar` on both clients):
  - `C_CVar.GetCVar(name)`: `stub.cvars[name]`, a string, or nil for a setting the client lacks.
  - `C_CVar.SetCVar(name, value)`: in combat it's refused, noted in `stub.blocked` as `{ C_CVar, name }`, and returns false. The game protects some nameplate settings in combat; the stub refuses them all, the strict side. An unknown name returns false. Otherwise it sets the string and returns true.

- [ ] **Step 1: Write the failing tests** (`nameplate_page_test.lua`)

The world is `NP.world`'s, which has the real `config/config.lua`. Add the options window, the options model and the widgets as `config_test.lua` loads them, so the page is read through `UF:GetConfigTable()` and `W.Confirm` draws. `ReloadUI` is a recorder.

```lua
test('the Nameplates page follows Raid 40; General has Nameplates, Friendly plates, Threat when solo, Theme, Background, Width and Height, and no Position', function()
	-- the picker: ..., raid40, nameplate; its name 'Nameplates'; General's keys sorted == 'background,enable,friendly,height,theme,threat_solo,width'
end)
test('turning Nameplates off puts the game settings back and asks for a reload', function()
	-- set enable false -> stub.cvars back to the recorded values; W.ConfirmText() == 'Nameplates change after a reload. Reload now?'; Yes -> ReloadUI called once
end)
test("Friendly plates sets the game's friendly plates for players and NPCs, out of combat", function()
	-- spawned: both '1'; set false: both '0'; in combat no change until PLAYER_REGEN_ENABLED
end)
test("the user's previous settings are recorded once, the first time SaftUI changes them", function()
	-- before: players '1', npcs '0'; ApplyNameplateCVars -> record { players '1', npcs '0' }; Friendly off/on -> record unchanged
	-- RestoreNameplateCVars -> '1','0'; record nil
end)
test('a second on/off cycle records anew', function() -- Review Focus 4
	-- after a restore the user sets players '0'; a new world keeping st.config.global spawns and applies -> record players '0'
end)
test('a setting this client lacks is skipped', function() --[[ stub.cvars.nameplateShowFriendlyNpcs = nil -> no SetCVar, no record ]] end)
test('Nameplates off at login with a record: it is put back. Stood down: nothing set or restored', function()
	-- enable false, a record { players '1' }: OnEnable's step puts '1' back and clears it
	-- stub.loaded_addons.Plater: no C_CVar.SetCVar call, the record kept
end)
test('another nameplate addon loaded: the page says which, and its options are disabled', function()
	-- stub.loaded_addons.Plater = true: the first General row's name == "Nameplates are drawn by Plater. Turn it off to use SaftUI's."; the group's disabled() == true
end)
```

In `config_test.lua`, load `config/units/nameplate.lua` with the other units, and add `nameplate` after `raid40` in the picker test. Its other per-unit checks (tooltips, no Ace widths, Position last) then cover the new page.

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/nameplate_page_test.lua tests/unitframes/config_test.lua`
Expected: FAIL: there's no `nameplate` page and no `C_CVar` calls.

- [ ] **Step 3: Implement it.** Use the signatures under Interfaces.

- [ ] **Step 4: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/nameplate_page_test.lua tests/unitframes/config_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0 (`options_validate_test.lua` validates the new page).

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/nameplates/cvars.lua SaftUI-Unitframes/nameplates/nameplates.xml SaftUI-Unitframes/config/config.lua SaftUI-Unitframes/unitframes.lua tests/wow/game.lua tests/unitframes/config_test.lua tests/unitframes/nameplate_page_test.lua
git commit -m "unitframes: the Nameplates page, the Friendly plates toggle, and the game's nameplate settings set and put back"
```

---

### Task 7: The plate's layout

**Files:**
- Modify:
  - `SaftUI-Unitframes/config/units/nameplate.lua` (the elements' defaults);
  - `elements/name.lua` (`max_width`, and its option);
  - `config/default.lua` (`name.max_width = 0`);
  - `elements/indicators.lua` (the quest icon);
  - `tests/wow/game.lua`.
- Create: `tests/unitframes/nameplate_layout_test.lua`

**Interfaces:**
- Consumes: `UF:ElementWanted` (Task 5); `buffs.purgeable` (Task 10).
- Produces:
  - Name `max_width`: pixels, 0 for no limit. The base default is 0; the nameplate's is 150. When it's set, `name.lua`'s UpdateConfig gives the Name that width with `SetWordWrap(false)`, so the game cuts a long name, a secret one too. It's on every unit's Name tab: "Max width", a range 0–600 step 1, desc "Cuts the name at this many pixels, so it can't run under the health text. 0: no limit."
  - The QuestIndicator gets an `Override(frame, event, unit)`. It shows for `C_QuestLog.UnitIsRelatedToActiveQuest(unit)`, else for `UnitIsQuestBoss(unit)`, and a secret answer counts as false. Then it calls the indicator's PostUpdate wrapper, which hides it when it's not wanted. On `QUEST_LOG_UPDATE`, every unit frame with the QuestIndicator enabled runs `ForceUpdate` on it.
  - Stubs: `C_QuestLog.UnitIsRelatedToActiveQuest(unit)` (`stub.units[u].quest`) and `UnitIsQuestBoss(unit)` (`stub.units[u].quest_boss`). `QuestLogDocumentation.lua` has the first on both clients.
- Produces, the defaults: in `profiles['**'].nameplate`, beside Task 4's keys.

  ```lua
  health = { text = { enable = true, percent = true, boss_percent = false,
  	position = { point = 'RIGHT', element = 'Health', rel_point = 'RIGHT', x_off = -4, y_off = 0 } } },
  name = { showLevel = false, show_classification = false, color_hostile = true, max_width = 150,
  	position = { point = 'LEFT', element = 'Health', rel_point = 'LEFT', x_off = 4, y_off = 0 } },
  castbar = { enable = true, theme = 'theme', background = 'theme',
  	relative_width = true, width = -18, relative_height = false, height = 12,
  	position = { point = 'TOPRIGHT', element = 'Health', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -6 },
  	colors = { nointerrupt = { r = 0.6, g = 0.6, b = 0.6 } },
  	text = { enable = true, font = 'pixel', position = { point = 'LEFT', element = 'Castbar', rel_point = 'LEFT', x_off = 4, y_off = 0 } },
  	time = { enable = false },
  	icon = { enable = true, theme = 'theme', background = 'theme',
  		relative_width = false, width = 12, relative_height = false, height = 12,
  		position = { point = 'RIGHT', element = 'Castbar', rel_point = 'LEFT', x_off = -6, y_off = 0 } } },
  debuffs = { enable = true, onlyShowPlayer = true, size = 20, max = 6, per_row = 6, spacing = 6,
  	grow_right = true, grow_up = true, initial_anchor = 'BOTTOMLEFT',
  	position = { point = 'BOTTOMLEFT', element = 'Health', rel_point = 'TOPLEFT', x_off = 0, y_off = 6 } },
  buffs = { enable = true, purgeable = true, size = 20, max = 4, per_row = 4, spacing = 6,
  	grow_right = true, grow_up = false, initial_anchor = 'TOPLEFT',
  	position = { point = 'TOPLEFT', element = 'Health', rel_point = 'TOPRIGHT', x_off = 6, y_off = 0 } },
  questindicator = { enable = true, size = 16, position = { point = 'RIGHT', element = 'Health', rel_point = 'LEFT', x_off = -6, y_off = 0 } },
  raidtargetindicator = { enable = true, size = 16, position = { point = 'BOTTOM', element = 'Health', rel_point = 'TOP', x_off = 0, y_off = 32 } },
  ```

  The arithmetic: the castbar is 182 wide (200 − 18), and its icon is 12, plus a 6 gap, to its left, so the row starts at the bar's left edge. The 6 debuffs are 150 wide (6×20 + 5×6). The raid mark sits 6 above the debuff row (6 + 20 + 6). The health bar, its colours (reaction, class, tapped) and the frame's Theme (None, the bars in SaftUI's theme) are every unit's defaults.

- [ ] **Step 1: Write the failing tests** (`nameplate_layout_test.lua`; an enemy plate per client)

```lua
for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': the bar is 200 by 20 and fills the plate; the name inside left, the health percent inside right', function()
		-- Health: width 200, height 20, its TOPRIGHT on the plate frame's TOPRIGHT (UF.FillsFrame(P.nameplate.health) true);
		-- Name point LEFT of Health +4; Health.text point RIGHT -4; percent on. Rects are compared only between SaftUI's parts, which share a scale (Task 11 pins the frame).
	end)
	test(client .. ": the castbar hangs 6 under the bar, 182 by 12, its 12x12 icon to its left so the row starts at the bar's left edge", function()
		-- castbar:GetTop() == health:GetBottom() - 6; castbar:GetRight() == health:GetRight(); width 182, height 12
		-- icon 12x12; icon:GetLeft() == health:GetLeft(); the spell name inside left; Time not shown; nointerrupt (0.6, 0.6, 0.6)
	end)
	test(client .. ': up to 6 of your debuffs above the bar, from its left edge growing right; up to 4 purgeable buffs right of it', function()
		-- the aura containers' points and sizes (150 by 20; 98 by 20), max, per_row, spacing, onlyShowPlayer, purgeable, colorStealable on
	end)
	test(client .. ': the quest icon left of the bar; the raid mark centred above the debuff row', function()
		-- QuestIndicator 16x16, its RIGHT 6 left of Health's LEFT; RaidTargetIndicator 16x16, its BOTTOM 32 over Health's TOP, centred
	end)
	test(client .. ': hostile names coloured, no level and no classification mark', function()
		-- stub.units.nameplate1 = { name = 'Kobold', level = 22, reaction = 2, classification = 'elite' }: the tag gives the name in text red, nothing before it
	end)
end
test('a long name is cut at 150 pixels', function()
	-- stub.units.nameplate1.name = ('Kobold '):rep(10); Name:GetWidth() == 150 and Name:GetStringWidth() <= 150
end)
test('the quest icon shows for a unit tied to an active quest, or a quest boss; a secret answer hides it', function()
	-- quest = true: shown; quest = false, quest_boss = true: shown; quest = S.secret('Q'): hidden, no error; neither: hidden
end)
test('a finished quest hides the icon at the next quest log update', function()
	-- shown, then quest = false and fire QUEST_LOG_UPDATE: hidden
end)
test("Max width is on every unit's Name tab", function()
	-- each unit's Name tab has max_width: a range 0 to 600 step 1, with a desc; 0 on target leaves the Name unsized
end)
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/nameplate_layout_test.lua`
Expected: FAIL. The plate has the base defaults (castbar off, a 301-wide unit).

- [ ] **Step 3: Implement it.** Use the defaults and signatures under Interfaces.

- [ ] **Step 4: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/nameplate_layout_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0 (`config_test.lua` and `bar_colors_test.lua`'s "defaults that block their options" cover the new keys).

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/config/units/nameplate.lua SaftUI-Unitframes/config/default.lua SaftUI-Unitframes/elements/name.lua SaftUI-Unitframes/elements/indicators.lua tests/wow/game.lua tests/unitframes/nameplate_layout_test.lua
git commit -m "unitframes: the nameplate's layout: name and health inside the bar, castbar under, debuffs above, purge row right"
```

---

### Task 8: The target's border

**Files:**
- Create: `SaftUI-Unitframes/nameplates/target.lua`, `tests/unitframes/nameplate_target_test.lua`
- Modify: `nameplates/nameplates.xml`, `SaftUI-Core/themeart.lua` (`ART.nameplatetarget`, `CONTROLS`), `tests/wow/atlases.lua`

**Interfaces:**
- Consumes: Task 4's callbacks and `UF:ForEachPlate`.
- Produces:
  - `st.ThemeArt.Control('nameplatetarget') -> { atlas, offsets = { left, top, right, bottom }, layer = 'OVERLAY' }`:

    | Client | Atlas | Offsets |
    | --- | --- | --- |
    | Forever | `Atlas('UI-HUD-CoolDownManager-Selected-yellow', 'forever')` | (-5, 5, 6, -4) |
    | Retail | `Atlas('UI-HUD-Nameplates-Selected', 'live')` | (-3, 4, 3, -3) |

    The offsets run from the health bar's TOPLEFT and BOTTOMRIGHT. They're Blizzard's anchors summed:
    - `bgTexture` round the health bar at (-2, 3) / (6, -6) (`Blizzard_NamePlateUnitFrame.lua` 813-815, both branches);
    - the selected border round `bgTexture`: Camelot's `SELECTED_BORDER_OFFSETS` (-3, 2) / (0, 2) on Forever (`Camelot/Blizzard_NamePlateConstants.lua` 28), (-1, 1) / (-3, 3) on retail (live 778-779).

    These are starting values for the in-game check.
  - `tests/wow/atlases.lua`: Forever `['UI-HUD-CoolDownManager-Selected-yellow'] = { 132, 16 }` (its Camelot member, -c60, 132x16; the -c60-2x member, 264x32, halves to the same) and live `['UI-HUD-Nameplates-Selected'] = { 216, 18 }`, from UiTextureAtlasMember at 1.60.1.70888 and 12.1.5.70783. Retail's tables have no Selected-yellow.
  - `UF.PlateBorderFrame(frame) -> drawn frame|nil`: `st:DrawnFrame(frame.Health)` while the health bar is drawn (`st:DrawnTheme(frame.Health)`), else the plate frame's while it's drawn, else nil.
  - `UF:IsPlateTarget(frame) -> boolean`: `frame:GetParent() == C_NamePlate.GetNamePlateForUnit('target')`, and not nil.
  - `UF:PlateTargetArt(frame) -> frame`: made once, a child of the plate frame two levels over the health bar, holding one texture.
  - `UF:UpdatePlateTarget(frame)`, by the border frame's drawn theme:

    | Drawn theme | Target plate | Other plates |
    | --- | --- | --- |
    | Blizzard | the art: the control's atlas, white, anchored to Health at the offsets; the border keeps its own colour (`st:SetBorderColor(border)`) | art hidden |
    | Thick or Thin | `st:SetBorderColor(border, 1, 1, 1, 1)`; art hidden | `st:SetBorderColor(border)`; art hidden |
    | None | nothing | nothing |

  - It's registered for `'added'` and `'updated'`. `PLAYER_TARGET_CHANGED`, on its own event frame, runs it on every plate.

- [ ] **Step 1: Write the failing tests** (`nameplate_target_test.lua`)

```lua
test("Thick: the target plate's health border is white; the others keep the theme's", function()
	-- two enemy plates; stub.nameplate_target = 'nameplate2'; fire PLAYER_TARGET_CHANGED
	-- the edge colour of plate2's health border (T.edge_rgb of UF.PlateBorderFrame(plate2)) is white; plate1's is Thick's bordercolor
end)
test('Thin: the same white line', function()
	-- as Thick, with SaftUI's theme Thin: the target's edge white, the other's Thin's bordercolor
end)
for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": Blizzard: Blizzard's target art round the target's health bar; the bronze box keeps its colour", function()
		-- art texture atlas == (forever 'UI-HUD-CoolDownManager-Selected-yellow' | retail 'UI-HUD-Nameplates-Selected'); shown only on the target
		-- its two points: TOPLEFT of Health at (left, top), BOTTOMRIGHT at (right, bottom) from the control
	end)
end
test("the border follows PLAYER_TARGET_CHANGED and is found on a plate's add", function()
	-- target nameplate2 then nameplate1 (fire the event each time): only the target white; a new plate added as the target is white at once
end)
test('the target is found by its plate frame: UnitIsUnit is never read', function()
	UnitIsUnit = function() error('UnitIsUnit read') end -- the rest of the case runs with it
end)
test('no target, or a target with no SaftUI plate: no plate is marked', function()
	-- stub.nameplate_target = nil, then a forbidden plate's unit: every plate keeps the theme's border, no art shown
end)
test('a config update keeps the white border on the target', function() --[[ UF:UpdateConfig('nameplate') ]] end)
test("health drawn None: the white goes on the plate frame's border when that is drawn", function()
	-- P.nameplate.health.theme = 'none', P.nameplate.theme = 'thick': the plate frame's edge white on the target
end)
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/nameplate_target_test.lua`
Expected: FAIL: no border colour, and `nameplatetarget` is not a control.

- [ ] **Step 3: Implement it.** Use the signatures under Interfaces.

- [ ] **Step 4: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/nameplate_target_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0 (`tests/core/theme_blizzard_test.lua` checks both atlases on their clients).

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/nameplates/target.lua SaftUI-Unitframes/nameplates/nameplates.xml SaftUI-Core/themeart.lua tests/wow/atlases.lua tests/unitframes/nameplate_target_test.lua
git commit -m "unitframes: a bright border on the target's nameplate: white under Thick and Thin, Blizzard's target art under Blizzard"
```

---

### Task 9: Threat

**Files:**
- Create: `SaftUI-Unitframes/nameplates/threat.lua`, `tests/unitframes/threat_test.lua`
- Modify:
  - `nameplates/nameplates.xml`;
  - `elements/health.lua` (`PostUpdateColor`);
  - `unitframes.lua` (`OnColorsChanged`);
  - `SaftUI-Core/Config/defaults.lua` (`colors.threat`);
  - `SaftUI-Core/Media/colors.lua` (the Threat section);
  - `tests/wow/game.lua`, `tests/wow/blizzard.lua`;
  - `tests/core/colors_test.lua`, `tests/unitframes/colors_test.lua`.

**Interfaces:**
- Consumes: `tests/lib/secrets.lua` (Task 2); `UF.IsFriendlyPlate` and `frame.friendly` (Task 5); `threat_solo` (Task 4).
- Produces:
  - `st.defaults.colors.threat = { warning = CreateColor(1, 0.6, 0), bad = CreateColor(1, 0.1, 0.1) }`.
  - A Colors tab section, Threat, after Status, with no note:
    - Warning, desc "An enemy nameplate's health bar when you're about to pull it as damage or healing, or about to lose it as a tank.";
    - Bad, desc "An enemy nameplate's health bar when it's attacking you as damage or healing, or someone else while you tank.".
  - `UF.ThreatState(isTank, status, coTanked) -> 'good'|'warning'|'bad'|nil`. The spec's table: tank 3 good, 2 warning, 0 or 1 bad, but good when `coTanked`; others 0 good, 1 warning, 2 or 3 bad; nil status gives nil.
  - `UF.IsGroupTank(unit) -> boolean`: `UnitGroupRolesAssigned(unit) == 'TANK'`, or on Forever (`st.forever`) `UnitHasEffectivelyTankAura(unit)`. A secret answer is false.
  - `UF:PlateThreat(frame) -> state|nil`. It's nil for:
    - a friendly plate;
    - solo (`not IsInGroup()`) with `threat_solo` off;
    - `C_Secrets.ShouldUnitThreatStateBeSecret('player', unit)`;
    - a status that `issecretvalue` calls secret.

    Otherwise it's `UF.ThreatState(PlayerUtil.IsPlayerEffectivelyTank(), status, coTanked)`. `coTanked` is read only for a tank at status 0 or 1: over the group's tokens (`party1..N-1`, or `raid1..N`), any `UF.IsGroupTank` member whose `UnitDetailedThreatSituation(member, unit)` isTanking is true. A member whose threat state is secret is skipped.
  - `UF:UpdatePlateThreat(frame)`: sets `frame.threatState`. Warning or bad → `frame.Health:SetStatusBarColor(<threat colour>)`. Otherwise, if it had a tint, `frame.Health:ForceUpdate()`, which gives oUF's colour back.
  - `health.lua` `PostUpdateColor`: after Custom, a frame whose `threatState` is `'warning'` or `'bad'` takes `st.config.profile.colors.threat[state]`. So the threat colour wins every time oUF colours the bar.
  - Updates:

    | Trigger | Plates updated |
    | --- | --- |
    | `UNIT_THREAT_LIST_UPDATE` | that unit's plate |
    | `UNIT_THREAT_SITUATION_UPDATE`, `GROUP_ROSTER_UPDATE`, `PLAYER_ROLES_ASSIGNED`, `PLAYER_SPECIALIZATION_CHANGED` | every plate |
    | `'added'` and `'updated'` callbacks | that plate |

    Every event is in both clients' API docs.
  - `UF:OnColorsChanged` takes `'threat'` among its groups. It reads `frame.__unit`, oUF's active unit (`.agents/architecture.md`). It read `frame.unit`, which only `UF.OnEnter` sets, so a frame never hovered missed every Colors tab change.
  - Stubs in `tests/wow/game.lua` (`UnitDocumentation.lua`, `SecretPredicateAPIDocumentation.lua`):
    - `UnitThreatSituation(unit, mob)` and `UnitDetailedThreatSituation(unit, mob)`, from `stub.threat[mob][unit]`. isTanking is status 2 or 3. A unit not on the list gives nil.
    - `C_Secrets.ShouldUnitThreatStateBeSecret(unit, mob)`: `stub.secret_threat[mob] == true`.
    - `IsInGroup`, `IsInRaid` and `GetNumGroupMembers`, from `stub.group = { raid = bool, members = { tokens } }`; nil is solo.
    - `UnitGroupRolesAssigned(unit)`: `stub.role` for the player, `stub.units[u].role` for others, `'NONE'` by default.
    - `UnitHasEffectivelyTankAura(unit)`, from `stub.tank_aura[unit]`. Only Forever has it, and SaftUI calls it only on Forever.
  - Stub in `tests/wow/blizzard.lua`: `PlayerUtil.IsPlayerEffectivelyTank()`, as `Blizzard_SharedXML/UnitUtil.lua` has it:
    - Forever (109-121): the tank aura, then the assigned role;
    - live (109-117): the assigned role, then with none the spec's role, `stub.spec_role`.

    The stub takes Forever's spec system to be not ChrSpecialization; that's unconfirmed, so the stub's comment says so.

- [ ] **Step 1: Write the failing tests** (`threat_test.lua`)

```lua
test('the threat table: every role and status', function()
	for _, c in ipairs({
		{ true, 3, false, 'good' }, { true, 2, false, 'warning' }, { true, 1, false, 'bad' }, { true, 0, false, 'bad' },
		{ true, 1, true, 'good' }, { true, 0, true, 'good' }, { true, nil, false, nil },
		{ false, 0, false, 'good' }, { false, 1, false, 'warning' }, { false, 2, false, 'bad' }, { false, 3, false, 'bad' }, { false, nil, false, nil },
	}) do eq(UF.ThreatState(c[1], c[2], c[3]), c[4], table.concat({ tostring(c[1]), tostring(c[2]), tostring(c[3]) }, ',')) end
end)
test('a tank: a mob another group tank holds is good', function()
	-- stub.role = 'TANK'; stub.group = { members = { 'party1' } }; stub.units.party1.role = 'TANK'
	-- stub.threat.nameplate1 = { player = 0, party1 = 3 } -> 'good'; party1 = 1 -> 'bad'
end)
test('Forever: a member with the tank aura counts as a group tank; retail reads the role only', function()
	-- party1 role NONE, stub.tank_aura.party1 = true, tanking the mob: Forever 'good', retail 'bad'
end)
test("a co-tank whose threat is secret is skipped", function()
	-- party1 a tank tanking the mob, ShouldUnitThreatStateBeSecret('party1', mob) true: 'bad', no error
end)
test('no threat entry shows nothing; a secret threat state shows nothing, with no error', function()
	-- stub.threat.nameplate1 = {}: nil, the bar oUF's colour; stub.secret_threat.nameplate1 = true: nil; a status of S.secret('T'): nil
end)
test('solo: no tint unless Threat when solo is on', function()
	-- stub.group = nil, status 3 as DPS: nil; P.nameplate.threat_solo = true: 'bad'
end)
test('a friendly plate is never tinted', function()
	-- a friend with stub.threat entries: nil, threatState nil
end)
test("warning and bad replace the bar's colour every time oUF colours it; good gives oUF's colour back", function()
	-- frame.Health:SetStatusBarColor(<reaction red>); frame.Health:PostUpdateColor('nameplate1') -> the bar is threat.bad
	-- status -> good: Health.ForceUpdate called once, threatState 'good'
end)
test("the role comes from Blizzard's effectively-tank check: Forever's tank aura first", function()
	-- Forever, stub.role = 'DAMAGER', stub.tank_aura.player = true: read as a tank; retail, stub.role = 'NONE', stub.spec_role = 'TANK': a tank
end)
test('threat, group and role events retint the plates', function()
	-- change stub.threat, fire UNIT_THREAT_LIST_UPDATE('nameplate1'): that plate only; UNIT_THREAT_SITUATION_UPDATE, GROUP_ROSTER_UPDATE, PLAYER_ROLES_ASSIGNED, PLAYER_SPECIALIZATION_CHANGED: every plate
end)
test('the Colors tab: Threat with Warning and Bad at their defaults; a change retints every plate', function()
	-- st.config.profile.colors.threat.bad: set, st:ColorsChanged('threat') -> the tinted plate's bar is the new colour
end)
```

In `tests/core/colors_test.lua`:
- the section names end `...,Status,Threat`;
- `expected.threat = 'Warning,Bad'`;
- `threat` joins the sections with no note.

In `tests/unitframes/colors_test.lua`, the frames carry `__unit` in place of `unit`.

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/threat_test.lua tests/core/colors_test.lua tests/unitframes/colors_test.lua`
Expected: FAIL: `UF.ThreatState` is nil, there's no Threat section, and the frames are skipped.

- [ ] **Step 3: Implement it.** Use the signatures under Interfaces.

- [ ] **Step 4: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/threat_test.lua tests/core/colors_test.lua tests/unitframes/colors_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/nameplates/threat.lua SaftUI-Unitframes/nameplates/nameplates.xml SaftUI-Unitframes/elements/health.lua SaftUI-Unitframes/unitframes.lua SaftUI-Core/Config/defaults.lua SaftUI-Core/Media/colors.lua tests/wow/game.lua tests/wow/blizzard.lua tests/core/colors_test.lua tests/unitframes/colors_test.lua tests/unitframes/threat_test.lua
git commit -m "unitframes: nameplates tint enemy health bars by the player's threat, by role, in the Colors tab's new threat colours"
```

---

### Task 10: Only buffs I can purge, on every unit; the plates' aura filters

**Files:**
- Create: `SaftUI-Unitframes/purge.lua`, `tests/unitframes/purge_test.lua`
- Modify:
  - both TOCs (`purge.lua` after `tags.lua`);
  - `elements/auras.lua` (`AddGroup`, `UpdateConfig`, the option);
  - `config/default.lua` (`buffs.purgeable = false`);
  - `tests/wow/game.lua`;
  - `tests/wow/blizzard.lua` (`Enum.SpellBookSpellBank = { Player = 0, Pet = 1 }`, from `SpellBookConstantsDocumentation.lua`).

**Interfaces:**
- Produces:
  - `UF.PURGE_SPELLS = { forever = { [CLASS] = { { id = n, removes = { ... }, pet = true|nil } } }, live = { ... } }`. The spec's spells are below; the IDs are candidates until Step 1 verifies them.

    | Client | Class | Spell | ID | Removes |
    | --- | --- | --- | --- | --- |
    | live | SHAMAN | Purge | 370 | Magic |
    | live | SHAMAN | Greater Purge | 378773 | Magic |
    | live | PRIEST | Dispel Magic | 528 | Magic |
    | live | DEMONHUNTER | Consume Magic | 278326 | Magic |
    | live | HUNTER | Tranquilizing Shot | 19801 | Magic, Enrage |
    | live | WARLOCK | Devour Magic (Felhunter, pet) | 19505 | Magic |
    | live | MAGE | Spellsteal | 30449 | stealable |
    | live | DRUID | Soothe | 2908 | Enrage |
    | live | ROGUE | Shiv | 5938 | Enrage |
    | forever | SHAMAN | Purge (ranks) | 370, 8012 | Magic |
    | forever | PRIEST | Dispel Magic (ranks) | 527, 988 | Magic |
    | forever | HUNTER | Tranquilizing Shot | 19801 | Enrage |
    | forever | WARLOCK | Devour Magic (pet, ranks) | 19505, 19731, 19734, 19736 | Magic |
    | forever | MAGE, DRUID, ROGUE, DEMONHUNTER | Spellsteal, Soothe, Shiv, Consume Magic | as live, only where Forever has them | as live |

  - `UF:KnownRemovals() -> { Magic = true, Enrage = true, stealable = true }` (a subset): the player's class (`UnitClass('player')`'s token) on this client (`st.forever`), with each spell checked by `C_SpellBook.IsSpellKnown(id, pet and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player)`. The API is on both clients (`SpellBookDocumentation.lua`), and its answers aren't secret.
  - `UF.PurgeFilter(known) -> filterString, candidateFilters`:

    | Known | filterString | candidateFilters |
    | --- | --- | --- |
    | Magic or Enrage | `'HELPFUL\|RAID_PLAYER_DISPELLABLE'` | `{ includeDispelTypes = { ... } }`, with `Magic = true` and `Enrage = true` each only if known |
    | stealable only | `'HELPFUL'` | `{ isStealable = true }` |
    | none | `'HELPFUL'` | `{ includeDispelTypes = {} }`: no buff passes |

    Blizzard's candidate filters AND their keys (`AuraContainerUtil.DoesAuraPassCandidateFilters`), so dispel types and stealable can't be OR'd in one group. A stealable buff is Magic, so Magic covers Spellsteal.
  - `UF.AuraFilter(unitframe, auraType, config) -> filterString, candidateFilters|nil`:
    - Buffs with `config.purgeable`: `UF.PurgeFilter(UF:KnownRemovals())`.
    - Debuffs on a nameplate (`unitframe.isNamePlate`): `'HARMFUL|INCLUDE_NAME_PLATE_ONLY'`, with Only mine giving `{ isFromPlayerOrPlayerPet = true }` and no `|PLAYER`. That keeps the pet's debuffs, which Forever's own debuff list counts, and Blizzard's nameplate-only debuffs, which plain `HARMFUL` drops.
    - Otherwise, today's: `'HELPFUL'` or `'HARMFUL'`, with Only mine adding `'|PLAYER'` and `{ isFromPlayerOrPlayerPet = true }`.
  - `AddGroup` builds the group from `UF.AuraFilter`.
  - `UF:ApplyAuraFilter(auras)`: for an element with a group, `SetAuraGroupFilterString` and `SetAuraGroupCandidateFilters` (Blizzard's `CustomAuraContainerSharedMixin`), only when either has changed since the last apply. `UpdateConfig` runs it, so the toggle applies without a reload.
  - `UF:RefreshPurgeFilters()`: every unit frame's Buffs that has `purgeable` and a group. In combat it waits (`st:QueueAfterCombat('PurgeFilters', ...)`). It runs on `SPELLS_CHANGED`, `PLAYER_TALENT_UPDATE`, `TRAIT_CONFIG_UPDATED` and `UNIT_PET` (player), all in both clients' docs.
  - The option: Buffs' Buttons section, `purgeable`, order 6.5, `generators.toggle(6.5, 'Only buffs I can purge', "Shows only buffs you can take off the unit with a spell you know: a purge, a dispel or a steal. If you know none, no buffs show.", 'small')`. It has no reload note, and it's not on Debuffs.
  - Stubs:
    - `C_SpellBook.IsSpellKnown(id, bank)`, from `stub.known_spells[id]` (Player) and `stub.known_pet_spells[id]` (Pet). It errors on a non-number id.
    - `stub.class` (default `'WARRIOR'`), which `UnitClass('player')` returns as its token, with the class's name.

- [ ] **Step 1: Verify each spell ID on both clients, and write down what was found**

1. Download, into a new scratch directory, `SpellName`, `SpellEffect`, `SpellDispelType` and `SkillLineAbility` for builds 1.60.1.70888 (Forever) and 12.1.5.70783 (retail): `curl -s "https://wago.tools/db2/<Table>/csv?build=<build>"`.
2. For each candidate, confirm:
   - the ID's name;
   - a `SpellEffect` row of Effect 38 (dispel) whose `EffectMiscValue_0` is Magic or Enrage, by `SpellDispelType`'s IDs; or Effect 126 (steal a beneficial buff).
3. On Forever, list every ID with one of these names and such an effect: Purge, Greater Purge, Dispel Magic, Devour Magic, Tranquilizing Shot, Spellsteal, Soothe, Shiv, Consume Magic. Keep the ranks a player learns: their `SkillLineAbility` row puts them on the class's skill line.
4. Write the builds and the results in a comment above `UF.PURGE_SPELLS`. Drop what a client lacks, and set `removes` from the effect, not the table above.

- [ ] **Step 2: Write the failing tests** (`purge_test.lua`)

The world is `theme_test.lua`'s: real Core helpers and defaults, every unit's config, `unitframes.lua`, `groups.lua`, `config/config.lua`, `constructors.lua`, `updaters.lua` and the elements, with `UF.oUF` stood in by its colors table. Add `purge.lua`. A unit frame is built as `theme_test.lua`'s `make_unit_frame`, with a container that also records `AddGroup`, `SetAuraGroupFilterString` and `SetAuraGroupCandidateFilters`. `UF.units = { target = frame }`, so `UF:ForEachUnitFrame` reaches it. Task 3's oUF fixture can't be used here: this task runs beside Task 3.

```lua
test('the purge table: each spell has an ID and what it removes, by class, on each client', function()
	for _, client in ipairs({ 'forever', 'live' }) do for class, spells in pairs(UF.PURGE_SPELLS[client]) do for _, s in ipairs(spells) do
		check(type(s.id) == 'number' and #s.removes > 0, client .. ' ' .. class)
		for _, r in ipairs(s.removes) do check(r == 'Magic' or r == 'Enrage' or r == 'stealable', r) end
	end end end
end)
for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': a shaman who knows Purge sees the magic buffs the raid can dispel', function()
		-- stub.class = 'SHAMAN'; stub.known_spells[370] = true
		-- UF.AuraFilter(frame, 'Buffs', { purgeable = true }) == 'HELPFUL|RAID_PLAYER_DISPELLABLE', { includeDispelTypes = { Magic = true } }
	end)
	test(client .. ": a hunter's Tranquilizing Shot", function() --[[ live: Magic and Enrage; Forever: Enrage, as Step 1 found ]] end)
	test(client .. ": a warlock with Devour Magic in the pet's spellbook; without the pet, none", function()
		-- stub.class = 'WARLOCK', stub.known_pet_spells[19505] = true: Magic; known_pet_spells empty: includeDispelTypes = {}
	end)
end
test('a mage who knows only Spellsteal sees stealable buffs', function() --[[ 'HELPFUL', { isStealable = true } ]] end)
test('a player who knows no such spell sees no buffs while the toggle is on', function() --[[ includeDispelTypes = {} ]] end)
test("Only buffs I can purge is on every unit's Buffs tab, off by default, and not on Debuffs", function()
	-- for each unit: GetConfigTable(unit, 'Buffs').args.buttons.args.purgeable a small toggle with a desc, its value false; Debuffs has none
end)
test("off, Buffs keeps today's filter; on, it switches without a reload, and back", function()
	-- a built group: on -> SetAuraGroupFilterString(key, 'HELPFUL|RAID_PLAYER_DISPELLABLE') and the candidates; off -> 'HELPFUL', nil
end)
test('learning a purge spell mid-session updates the filters; in combat it waits', function()
	-- a shaman's built Buffs group with the toggle on: known_spells[370] = true, fire SPELLS_CHANGED: candidates { Magic }; in combat: unchanged until PLAYER_REGEN_ENABLED
end)
test("nameplate debuffs: nameplate-only debuffs in, Only mine by the aura's own flag, the pet's in", function()
	-- frame.isNamePlate = true: 'HARMFUL|INCLUDE_NAME_PLATE_ONLY', { isFromPlayerOrPlayerPet = true }; another unit unchanged: 'HARMFUL|PLAYER'
end)
```

- [ ] **Step 3: Run them to make sure they fail**

Run: `tests/run tests/unitframes/purge_test.lua`
Expected: FAIL: `purge.lua` doesn't exist.

- [ ] **Step 4: Implement it.** Use the signatures under Interfaces.

- [ ] **Step 5: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/purge_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0 (`config_test.lua` checks the new option's tooltip and size).

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Unitframes/purge.lua SaftUI-Unitframes/SaftUI-Unitframes_Forever.toc SaftUI-Unitframes/SaftUI-Unitframes_Mainline.toc SaftUI-Unitframes/elements/auras.lua SaftUI-Unitframes/config/default.lua tests/wow/game.lua tests/wow/blizzard.lua tests/unitframes/purge_test.lua
git commit -m "unitframes: Only buffs I can purge, on every unit's buffs, from the purge, dispel and steal spells the player knows"
```

---

### Task 11: Pixel-perfect plates and the scale settings

**Files:**
- Create: `SaftUI-Unitframes/nameplates/pixels.lua`, `tests/unitframes/nameplate_pixel_test.lua`
- Modify:
  - `nameplates/nameplates.xml`;
  - `nameplates/nameplates.lua` (`UF.PlateDriverSize`);
  - `elements/auras.lua` (`PostCreateButton` on a plate);
  - `tests/wow/widgets.lua`;
  - `tests/unitframes/fixtures/ouf.lua` (the container stand-in makes a button).

**Interfaces:**
- Consumes: `UF.NAMEPLATE_CVARS`, `UF:ApplyNameplateCVars` (Task 6); `UF:ApplyPlateSize` (Task 4); the layout defaults (Task 7).
- Produces:
  - `UF.RoundLayout(region, recursive)`:
    - `SetRoundLayoutToNearestPixel(true)` on `region`; a texture also gets `SetSnapToPixelGrid(false)` and `SetTexelSnappingBias(0)`;
    - `recursive` walks the frame's regions and children;
    - it skips an `AuraContainer` (Blizzard's container, whose buttons refuse tainted access while auras are secret: `.agents/taint.md` rule 11) and a forbidden frame, and everything under them;
    - it does no arithmetic on sizes.

    It runs on a plate's `'updated'` callback (`UF.RoundLayout(frame, true)`), and from `PostCreateButton` on a plate's aura button's own backdrop (`UF.RoundLayout(button.backdrop, true)`, guarded with `UF.RoundLayout` existing).
  - `UF:PinPlateScale(frame)`: `frame:SetIgnoreParentScale(true)` and `frame:SetScale(UIParent:GetEffectiveScale())`; a secret scale leaves it as it is. It runs on `'added'`. On `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`, every plate is re-pinned, and `UF:ApplyPlateSize()` runs.
  - `UF.PlateDriverSize(width, height) -> width * r, height * r`, with `r = UIParent:GetEffectiveScale() / WorldFrame:GetEffectiveScale()`. NamePlateN are WorldFrame's children (research §5; in-game check 1), and SaftUI's plate frame is pinned to UIParent's scale, so the click area matches the 200x20-pixel bar. A secret or zero scale gives r = 1.
  - `UF.NAMEPLATE_CVARS` gains `nameplateMinScale`, `nameplateMaxScale` and `nameplateSelectedScale`, each `'1'`, and `nameplateSimplifiedTypes` `'0'`. The last is a bitfield, so `'0'` simplifies nothing; Blizzard's settings read it only when `C_CVar.GetCVar` has it, so Task 6's skip covers a client without it.
  - Stubs (`SimpleScriptRegionAPIDocumentation.lua`, `SimpleFrameAPIDocumentation.lua`, `SimpleRegionAPIDocumentation.lua`):
    - `SetRoundLayoutToNearestPixel(enabled)` on every widget, recorded as `stub.state(w).round_layout`; it errors on a non-boolean;
    - `SetIgnoreParentScale(ignore)` on frames and regions. A widget ignoring its parent's scale has its own scale as its effective scale: what the API names, and what Inomena's plates rely on (`np/other/inomena_util.lua`).

    Both are `IsProtectedFunction` in the docs, so both join `PROTECTED_IN_COMBAT`.
  - The fixture: `container:_AddButton() -> button`. It makes a Button child of the container, with oUF's `Icon`, `Count` and `Border`, and hands it to `PostCreateButton`, as Blizzard's container does. It's not locked: `auras.lua` already keeps `button.backdrop` on it, as `theme_test.lua`'s stand-in button allows.

- [ ] **Step 1: Write the failing tests** (`nameplate_pixel_test.lua`)

```lua
test("every frame and region of SaftUI's on a plate rounds its layout, textures unsnapped; nothing of Blizzard's", function()
	-- walk the plate frame (skipping AuraContainers): round_layout true everywhere, snap_to_pixel_grid false and texel_snapping_bias 0 on textures
	-- NamePlate1, its UnitFrame, WidgetContainer and SoftTargetFrame: round_layout nil
end)
test("a plate's aura buttons round their own backdrops; the container and its buttons are left alone", function()
	-- frame.Buffs:_AddButton(): button.backdrop and its regions round_layout true; the container, the button and its Icon round_layout nil
end)
test("the plate frame is pinned to UIParent's effective scale, whatever its plate's", function()
	-- NamePlate1:SetScale(0.8) before the add; frame:GetEffectiveScale() == UIParent:GetEffectiveScale()
end)
test('a UI scale change re-pins every plate and re-applies the size', function() -- Review Focus 5
	-- UIParent:SetScale(0.6); fire UI_SCALE_CHANGED -> every plate's effective scale 0.6; stub.nameplate_size == PlateDriverSize(200, 20); in combat the size waits
end)
test("the plate size is the config's in UIParent pixels", function()
	-- WorldFrame scale 1, UIParent's st.scale: stub.nameplate_size == { 200 * st.scale, 20 * st.scale }
end)
test('the scale settings are 1 and simplified plates off while SaftUI\'s plates are on, and put back when Nameplates is off', function()
	-- before: '0.8', '1', '1.2', '3'; ApplyNameplateCVars: '1', '1', '1', '0'; RestoreNameplateCVars: '0.8', '1', '1.2', '3'
end)
test('every sized part of a plate is an even number of pixels on both sides', function()
	-- for each element on the plate with a size (UF:ElementSize), and the plate (config width and height): width % 2 == 0 and height % 2 == 0
end)
test('rounding is applied again after a config update', function() --[[ theme switch to Blizzard makes new textures; all round ]] end)
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/nameplate_pixel_test.lua`
Expected: FAIL: no rounding, and the effective scale is the plate's.

- [ ] **Step 3: Implement it.** Use the signatures under Interfaces.

Ruling: the borders stay the theme engine's (BackdropTemplate edges and the art's textures), rounded with everything else. Texture-built borders come only if the in-game check shows shimmer.

- [ ] **Step 4: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/nameplate_pixel_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/nameplates/pixels.lua SaftUI-Unitframes/nameplates/nameplates.xml SaftUI-Unitframes/nameplates/nameplates.lua SaftUI-Unitframes/elements/auras.lua tests/wow/widgets.lua tests/unitframes/fixtures/ouf.lua tests/unitframes/nameplate_pixel_test.lua
git commit -m "unitframes: nameplates keep whole-pixel borders: pinned to the UI's scale, rounded to pixels, one plate size"
```

---

### Task 12: The plates in each theme

**Files:**
- Modify: `SaftUI-Unitframes/unitframes.lua` (`OnColorsChanged`)
- Create: `tests/unitframes/nameplate_theme_test.lua`

**Interfaces:**
- Consumes: `UF:UpdatePlateTarget` (Task 8), `frame.threatState` (Task 9), the layout (Task 7).
- Produces: `UF:OnColorsChanged('theme')` runs `UF:UpdatePlateTarget` on every plate (`UF:ForEachPlate`). A theme recolor or redraw takes a frame's own border colour off (`.agents/architecture.md`, "A frame's own border color"), so the target's white goes back on after one.

- [ ] **Step 1: Write the failing tests** (`nameplate_theme_test.lua`, with `T.watch()` from `theme_helpers.lua`)

```lua
for _, theme in ipairs({ 'thick', 'thin' }) do
	test(theme .. ': plate health and castbar draw as unit frames, the cast icon as a control, aura buttons as auras', function()
		-- drawn(frame.Health) == 'theme,theme,unitframe'; drawn(frame.Castbar) == 'theme,theme,unitframe'
		-- drawn(frame.Castbar.Icon) kind 'control'; an aura button's kind 'aura'
	end)
end
for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": Blizzard: health and castbar in the bronze box, health on Blizzard's raid fill, the castbar on its own texture", function()
		-- T.art(frame.Health) shows the unitframe cut pieces; the health bar texture's atlas 'RaidFrame-Hp-Fill'; the castbar's no atlas
	end)
end
test('the target border survives a recolor and a redraw, in each look', function()
	-- thick: st:RecolorThemed() then st:ColorsChanged('theme') -> still white; st:RedrawThemed() the same
	-- blizzard: the art still shown after a redraw
end)
test('a threat tint survives a theme change', function() --[[ st:ThemeChanged() -> the bar keeps threat.bad ]] end)
test("the Nameplates page's Theme draws the plates as every unit's does", function()
	-- P.nameplate.theme = 'thin'; UF:UpdateConfig('nameplate') -> drawn(frame) == 'thin,theme,unitframe'
end)
```

- [ ] **Step 2: Run them to make sure they fail**

Run: `tests/run tests/unitframes/nameplate_theme_test.lua`
Expected: FAIL: the target's white is gone after a recolor.

- [ ] **Step 3: Implement it.** Add the `'theme'` branch to `UF:OnColorsChanged`, before its group check.

- [ ] **Step 4: Run the tests to make sure they pass, then the whole suite**

Run: `tests/run tests/unitframes/nameplate_theme_test.lua`, then `tests/run`
Expected: PASS; the whole suite exits 0.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/unitframes.lua tests/unitframes/nameplate_theme_test.lua
git commit -m "unitframes: nameplates in Thick, Thin and Blizzard, the target border kept through theme recolors and redraws"
```

---

### Task 13: Docs

**Files:**
- Modify: `.agents/architecture.md`, `.agents/taint.md`, `.agents/clients.md`, `.agents/testing.md`, `.agents/edit-mode.md`, `AGENTS.md`, `README.md`, `docs/followups.md`

- [ ] **Step 1: Write each doc's change**

Bump each doc's `last_updated` to the day of the change.

- `architecture.md`:
  - Unit frames gets nameplates: the unit, `UF.nameplates` and the walkers, the plate callbacks, the init callback (Task 3), plate kinds and `UF:ElementWanted`, the purge filter, threat, and the stand-down list;
  - `OnColorsChanged` takes `threat` (the groups list) and reads `__unit`.
- `taint.md`:
  - a nameplates entry: what's written onto Blizzard's plates (only oUF's own); the `NamePlateDriverFrame` post-hook; widgets reparented with the same calls as oUF; game settings out of combat; forbidden plates; the rounding walker never touching Blizzard's frames or AuraContainers;
  - add `SaftUI-Unitframes/nameplates/**` to its `covers`.
- `clients.md`: Forever vs retail for plates: the target atlas and offsets, the tank aura, the purge table per client (with Step 1's findings), and the pet's debuffs.
- `testing.md`:
  - rows for every new test file;
  - `tests/lib/secrets.lua`;
  - the new stubs (`C_NamePlate`, `C_CVar`, threat, group, roles, spellbook, quest, rounding, ignore parent scale, attributes, `NamePlateDriverFrame`, `PlayerUtil`);
  - in the stand-ins list: the oUF fixture, the nameplate world, and the aura container stand-in.
- `edit-mode.md`: the Nameplates page (no movers; its reload prompt; disabled while stood down).
- `AGENTS.md`: the Unitframes row names `nameplates/` and `purge.lua`.
- `README.md`: nameplates in the feature list and in `/sui` → Unitframes; the Colors tab's section list gains Threat; Only buffs I can purge.
- `docs/followups.md`: a new entry, "Nameplates: in-game checks", with these steps:
  1. With a plate up, `/dump NamePlate1:GetParent()==WorldFrame, NamePlate1:GetEffectiveScale(), UIParent:GetEffectiveScale()`. Clicking the edges of a plate's bar targets it.
  2. Strafe and turn past a pack under Thick, Thin and Blizzard: the borders stay whole, with no shimmer or doubling.
  3. Change Blizzard's Interface → Nameplates size with plates up: SaftUI's size and click area come back.
  4. In a dungeon pull, `/run print(C_Secrets.ShouldUnitThreatStateBeSecret('player','nameplate1'))`. Tank and DPS tints show, and solo tints show with Threat when solo on.
  5. Purge: a shaman or priest sees an enemy's magic buff, and a hunter or druid an enrage (whether the dispel name is `Enrage`). As a non-mage, check what `isStealable` means.
  6. Under Blizzard the target art sits round the bronze box, on each client.
  7. Friendly plates show outside an instance and are Blizzard's inside one; Friendly plates off hides them.
  8. With Plater loaded, there are no SaftUI plates and the page shows its message.
  9. Quest progress widgets and the soft-target icon show on plates.
  10. An uninterruptible cast is grey, and the quest icon shows on quest mobs.

- [ ] **Step 2: Check doc parity**

For each `.agents/<topic>.md`, run `git diff --name-only <round2 base>...HEAD -- ':(glob)<glob>'` for each of its `covers` globs, and check every hit is described. Check `README.md` against every user-facing change.

- [ ] **Step 3: Run the whole suite**

Run: `tests/run`
Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add .agents/architecture.md .agents/taint.md .agents/clients.md .agents/testing.md .agents/edit-mode.md AGENTS.md README.md docs/followups.md
git commit -m "docs: SaftUI's nameplates in the agent docs, the README and the in-game checks"
```
