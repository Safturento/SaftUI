# SaftUI unit frames: nameplates

Date: 2026-11-11. Status: no open questions. The user's answers are binding; the calls marked "My call" are the controller's, for the user to check. Revised after the builder check (2026-11-11): SaftUI stands down when another nameplate addon is loaded (the user's answer 8); the Friendly plates toggle drives the game's friendly plates; friendly plates carry less; threat colours replace the bar's and stand out from the hostile red.

## Intent

The user, 2026-11-11: "can we do some work on re-enabling nameplates in the unitframes addon?" SaftUI had its own nameplates in 2019 (before the modular split: 7d6d8fe "add nameplates", 637d3fe "add focus & nameplate target", 4bebdd3 "add cvars for nameplate scaling"); the modular unit frames never spawned them, and the leftover defaults were removed in 0308977. This brings them back, on the bundled oUF master, on both clients.

Shown the 2019 design (health, name on the left, castbar, the player's own debuffs above, a quest icon, hostile name colour, a target highlight, scaling): "all of that sounds good, I also want to be able to track my threat situation with mobs as well as purgable buffs. I'd also like to make sure that pixel perfect doesn't get messed up on the borders when nameplates shift around."

On threat: "it should be able to handle all three roles, if I'm in a tank role consider the 'bad' situation to be not having threat on a mob but if I'm in a dps or healing role consider the 'bad' situation to be having threat. Also a warning situation should exist right before going into the bad situation." Shown as a tint of the health bar ("the tint works for me").

So: SaftUI draws enemy, neutral and (outside instances) friendly nameplates in its own look and theme, with the player's threat on each mob at a glance by role, the buffs the player can purge, and borders that stay whole-pixel while plates move.

## The user's answers (2026-11-11)

1. The 2019 feature set: yes ("all of that sounds good").
2. Threat: role-aware, three states (good, warning just before bad, bad), shown as a **health bar tint**.
3. Purgeable buffs: only buffs the player can purge or steal, in a short row on the plate's right, separate from the debuffs above ("yeah that's good"); **"only what I can purge", and also "a standard toggle in the buffs element config for all unitframes"**.
4. Friendly plates: **"Friendly too, outside instances"** (inside instances the game keeps them Blizzard's).
5. Threat when solo: **"a toggleable option"**.
6. Layout: **the bar with text inside** (2023's plate: name inside left, health % inside right, castbar under, debuffs above, purgeable buffs right, quest icon left, raid mark above).
7. Target: **a bright border** on the current target's plate.
8. Another nameplate addon loaded (the user has Plater on all their Forever characters, EllesmereUI Nameplates on two): **"Stand down if one is loaded"**.
9. The bar's right-hand text (2026-11-11, building): **"for the health lets put the actual health value, short format. for threat use a percentage"**.

## Today

- `SaftUI-Unitframes/` builds every unit on the bundled oUF master (`Libraries/oUF`, upstream 3692cb6). `UF:OnEnable` spawns every key of `UF.unit_strings`; `UF.ConstructUnit` (unitframes.lua) is the style; elements in `elements/`, config per unit in `config/units/` (loaded by `config/load.xml`), `UNIT_ORDER` / `UNIT_SHOWS` for the /sui pages; movers via `RegisterMovers`.
- Nothing spawns nameplates. `updaters.lua` has "TODO: Figure out why EnableElement is breaking on nameplates": it called `UF:UpdateUnitFrame` inside oUF's style function, before oUF made `activeElements[object]` (ouf.lua `initObject`: styleFunc at ~431, `activeElements[object] = {}` at ~441), so `EnableElement` indexed nil. Group units still call `UpdateUnitFrame` from the style function.
- Round 2 of the Blizzard theme (in progress) adds the `unitframe` kind (the bronze box, at least 16 by 16 drawn) and `member` kind, Blizzard's raid bar fills, and `UF:ElementKind` / `UF:ElementTheme` / `UF.SizedKind`.
- Pre-existing bugs the research found that plates would hit:
  - `elements/castbar.lua` reads `castbar.notInterruptible`, but the bundled oUF passes it as `PostCastStart`'s 3rd argument (kept private), so the uninterruptible colour never shows; its `CastingInfo(unit)` fallback exists only on the classic game type and errors on Forever.
  - `tags.lua` ~89 tests the undefined global `baseunit` (not `baseUnit`), so the 2019 target marker never ran; it builds names with `..`, which errors if an NPC name is secret.

## Blizzard's nameplates (researched 2026-11-11)

The full report: the controller's scratchpad, `report-research-nameplates.md`. Blizzard_NamePlates is the same 12.x system on both clients. The facts that bind the design:

- **Spawning:** `oUF:SpawnNamePlates(prefix)` once per session (a toggle needs /reload). It blocks Blizzard's pooled plate UnitFrame on every add (`DisableBlizzard`), makes a non-secure `nameplate.unitFrame` per NamePlateN, sets one size for **all** plates (`C_NamePlate.SetNamePlateSize`) and the hit-test area, and gives added / removed / target callbacks. Blizzard's NamePlateDriverFrame sets the size again on display and option changes; oUF re-applies only at login.
- **Forbidden plates** (friendly plates inside dungeons and raids) can't be styled: they stay Blizzard's.
- **Widgets and the soft-target icon** live on Blizzard's pooled UnitFrame; upstream oUF reparents them only on a NamePlateN's first add, so they show or not depending on which pooled frame comes back.
- **Threat:** `UnitThreatSituation('player', plateUnit)` (0 not tanking lower; 1 not tanking higher; 2 tanking insecurely; 3 tanking securely) and `UnitDetailedThreatSituation(unit, plateUnit)` are generally **not secret** for player/ally vs a nameplate unit; guard with `C_Secrets.ShouldUnitThreatStateBeSecret`. A secret status can't be turned into a colour by addon code. Blizzard shows threat only in a group. The mob's target is secret, so an off-tank is found by asking each group tank `UnitDetailedThreatSituation(tank, plateUnit).isTanking`. oUF's ThreatIndicator and `colorThreat` error on a secret status.
- **Auras:** in combat, enemy aura data is secret; only Blizzard's AuraContainer filters work: filter strings (`HELPFUL|RAID_PLAYER_DISPELLABLE`, `HARMFUL|INCLUDE_NAME_PLATE_ONLY`, …) and candidate filters (`isStealable`, `isFromPlayerOrPlayerPet`, `includeDispelTypes`, `nameplateShowPersonal`, …). There is **no "the player alone can purge" filter**; spell-ID lists are refused for buffs on enemies. The bundled oUF Auras element is container-only (no FilterAura / PostUpdateButton).
- **Casts** by any non-player unit are always secret (oUF handles this with durations).
- **Pixel-perfect:** C++ places plates at fractional positions every frame and may scale them; Blizzard rounds its plates' layout to whole pixels (`SetRoundLayoutToNearestPixel`, recursively) and builds borders from textures; ElvUI, Inomena, RealUI and Plater do the same, with texture snapping off and plates pinned to UIParent's scale.

## Goals

### 1. SaftUI's nameplates, spawned by oUF

- A new unit, `nameplate`, with its own config (`config/units/nameplate.lua`, in `config/load.xml`, `UNIT_ORDER`, `UNIT_SHOWS`) and its own /sui page under Unitframes, with the usual element tabs. No movers.
- Spawned with `oUF:SpawnNamePlates` once, after the other units, when **Nameplates** is enabled (a toggle on the page; on by default — **my call**). Turning it on or off asks for a /reload (`W.Confirm` or the existing reload prompt pattern).
- **Standing down (the user's answer 8):** at load, before spawning, SaftUI checks for a loaded nameplate addon (`C_AddOns.IsAddOnLoaded`): Plater, EllesmereUI's nameplates, Kui_Nameplates, TidyPlates_ThreatPlates, NeatPlates, and ElvUI with its nameplates on (the builder checks how to read ElvUI's setting safely, or leaves ElvUI out and says so). If one is loaded, SaftUI spawns no plates, sets and restores no nameplate settings, touches nothing of Blizzard's plates, and the Nameplates page says which addon is in charge ("Nameplates are drawn by Plater. Turn it off to use SaftUI's.") with its options disabled. The list is a table in the code, easy to extend.
- **Which plates:** enemy and neutral plates always; friendly plates (players and NPCs) outside instances (the user's answer 4). Forbidden plates (friendly inside instances) stay Blizzard's: nothing is done to them.
- **The Friendly plates toggle** (my call, after the builder check): once SaftUI's plates are on, oUF blocks Blizzard's pooled plate frame on every plate it's handed, so "off" can't mean "Blizzard's look". The toggle drives the game's own friendly plates setting (players and NPCs): on, the game shows friendly plates and SaftUI styles them outside instances (Blizzard's look inside, where they're forbidden); off, the game shows none. On by default. SaftUI sets the game setting out of combat and puts the user's previous value back when Nameplates or the toggle is turned off (recorded once, the first time SaftUI changes it).
- **What friendly plates carry** (my call): the bar, the name, health % and the raid mark. No castbar, debuffs, purge row, threat or quest icon (the game uses one size for all plates, so the bar is the same 200 by 20).
- Plates live in their own list (`UF.nameplates`, by NamePlateN), not in `UF.allUnits` (plates are reused); every place that walks unit frames (`ForEachUnitFrame`, `RefreshConfigReferences`, `ApplyConfig`, `OnColorsChanged`, theme redraws) reaches them.
- Elements are enabled or disabled after oUF's init (the added callback or `oUF:RegisterInitCallback`), never from the style function: this fixes the TODO for plates and for group units.
- The plate's size is the config's (`driver:SetSize`), applied again after Blizzard's own size updates (a hook on NamePlateDriverFrame's size update, out of combat; in combat it waits). The click area is the plate, and stays so after Blizzard sets its own (Combat and taint).
- Blizzard's widgets and soft-target icon are reparented to the plate on **every** add (in SaftUI's added callback, writing nothing onto Blizzard's frames beyond what oUF already does), so they always show.

### 2. The plate's layout (the user's answer 6)

```
        [D][D][D]          <- the player's debuffs
   +---------------------+
   |                 85% |          <- threat % (when on its list)
   | Kobold Miner  12.5k  | [B][B]  <- buffs the player can purge
   +---------------------+
   [i]|=====cast=====|      <- castbar + icon
```

- **Health bar:** 200 by 20 (**my call**, adjustable), reaction coloured (hostile red, neutral yellow, friendly green, players by class), with the threat tint (goal 4) over it. Blizzard's raid bar fill under the Blizzard theme, as unit frames get in round 2.
- **Name:** inside on the left, in the unit frames' font; hostile names coloured as today's `color_hostile`; truncated to fit. Built secret-safe (`C_StringUtil.WrapString` or plain `SetText` of the name, no `..` on a secret).
- **Health value:** inside on the right, the unit's current health in short format (e.g. 12.5k, 1.2M), secret-safe (the game's abbreviation that accepts secret numbers, or `SetFormattedText`; the builder verifies which works with a secret health on both clients) — the user's answer 9.
- **Threat %:** a small text above the bar's right end: the player's threat on the mob as a percentage (`UnitDetailedThreatSituation`'s scaled percent, 100% when the mob is attacking the player), coloured as the threat tint (goal 4), shown only when the tint would show (in a group, or solo with Threat when solo on) and the player is on the mob's threat list; hidden on friendly plates. Secret-safe (`SetFormattedText` with a secret percent is fine; a secret state hides it). **My call** for the place; the user's answer 9 for the percentage.
- **Castbar:** under the bar, 12 tall (**my call**), the full width less its icon (12x12, left); interruptible casts in the castbar colour, uninterruptible in a grey (the bundled oUF's `notInterruptible` argument, fixed for every unit's castbar); the spell name inside.
- **Debuffs:** above the bar, the player's own (`isFromPlayerOrPlayerPet`), up to 6, 20px (**my call**), growing right from the left edge.
- **Purgeable buffs:** to the right of the bar, up to 4, 20px, from the "Only buffs I can purge" toggle (goal 5), with a highlight on stealable ones (oUF's stealable border).
- **Quest icon:** left of the bar, for a unit related to one of the player's active quests (`C_QuestLog.UnitIsRelatedToActiveQuest`, falling back to `UnitIsQuestBoss`).
- **Raid mark:** above the bar, centred.
- **No** portrait, power, level, ready check, class power.
- Every position and size is in the page's options as other units' are.

### 3. The target's border (the user's answer 7)

- The current target's plate gets a bright border: under Thick and Thin a 1px white line (the frame's own border colour, `st:SetBorderColor`); under the Blizzard theme Blizzard's target border art (`UI-HUD-CoolDownManager-Selected-yellow` on Forever, `UI-HUD-Nameplates-Selected` on retail, as Blizzard's plates draw it).
- The target is found by frame (`C_NamePlate.GetNamePlateForUnit('target')`), not `UnitIsUnit` (which can be secret), on target changes and on plate adds.

### 4. Threat (the user's answers 2 and 5)

- **States**, per mob, from `UnitThreatSituation('player', plateUnit)`:

  | Player's role | Good | Warning | Bad |
  |---|---|---|---|
  | Tank | 3 (holding it securely) | 2 (holding it, someone close) | 0 or 1 (it's attacking someone else) |
  | DPS or healer | 0 (someone else holds it, lower) | 1 (higher than the tank, not yet attacking you) | 2 or 3 (it's attacking you) |

  A mob that has no threat entry for the player (nil: not fighting the player or the group) shows nothing.
- **Role:** the player's current spec role (`GetSpecializationRole` / the group's assigned role, and Forever's effectively-tank aura first, as Blizzard's `PlayerUtil.IsPlayerEffectivelyTank` does).
- **Co-tank:** as a tank, a mob another group tank holds (`UnitDetailedThreatSituation(groupTank, plateUnit).isTanking`) is good, not bad.
- **Shown as a tint of the health bar:** good leaves the bar's normal colour; warning and bad **replace** the bar's colour (every time oUF colours the bar, the threat colour wins while it applies) with a bright orange and a bright red that stand out from SaftUI's muted hostile red (135, 81, 81) and neutral yellow (**my call**: new colours in the Colors tab, `threat.warning` (1, 0.6, 0) and `threat.bad` (1, 0.1, 0.1), editable).
- **When:** in a party or raid; solo only when the **Threat when solo** toggle is on (the user's answer 5; off by default, **my call**, as Blizzard's).
- A secret threat state (`C_Secrets.ShouldUnitThreatStateBeSecret`) shows nothing (the bar's normal colour), never an error. SaftUI's own code reads threat (not oUF's ThreatIndicator / `colorThreat`, which error on secrets).
- Updated on `UNIT_THREAT_LIST_UPDATE` / `UNIT_THREAT_SITUATION_UPDATE` for the plate's unit, on group and role changes, and on plate adds.

### 5. "Only buffs I can purge" — for every unit frame (the user's answer 3)

- The **Buffs** element of every unit (player, target, focus, party, boss, arena, nameplate…) gets a toggle, **Only buffs I can purge**. On: the element shows only the unit's buffs the player can remove with a spell they know. Off: today's behaviour. On by default for nameplates only (**my call**); off for every other unit.
- **How:** SaftUI keeps a table of purge, dispel and steal spells by class (and pet) per client, with what each removes (Magic, Enrage, stealable): e.g. Shaman Purge / Greater Purge (Magic), Priest Dispel Magic (Magic), Demon Hunter Consume Magic (Magic), Hunter Tranquilizing Shot (Magic, Enrage), Warlock's Felhunter Devour Magic (Magic), Mage Spellsteal (stealable), Druid Soothe (Enrage), Rogue Shiv (Enrage) — checked against each client's spellbook (`C_SpellBook.IsSpellKnown` / `IsPlayerSpell`), refreshed on spell and talent changes. From the spells the player knows, the element builds Blizzard AuraContainer filters (`includeDispelTypes`, `isStealable`) so it works in combat with secret auras.
- A player who knows no such spell sees no buffs while the toggle is on.
- The builder verifies each spell's ID and what it removes on both clients (the research's list is from game knowledge); unknown or missing spells are skipped.

### 6. Pixel-perfect borders while plates move

- The requirement: every border on a plate (the bar's, the castbar's, the aura buttons', the target border) draws as the same whole number of pixels on every frame while the plate moves and while the camera moves, at any UI scale SaftUI sets.
- **My calls**, from the research:
  - Plates keep one size: the nameplate scale CVars SaftUI controls (`nameplateMinScale`, `nameplateMaxScale`, `nameplateSelectedScale`, and the simplified plates setting) are set to 1 / off, out of combat, while SaftUI's plates are on. No target or threat scaling.
  - The plate's root is pinned to UIParent's effective scale.
  - Every frame and region SaftUI makes on a plate rounds its layout to whole pixels (native rounding, applied by SaftUI's own walker to SaftUI's frames only, never Blizzard's), with texture snapping off where rounding is on.
  - Sizes are even pixels (the half-pixel rule in `.agents/architecture.md`).
  - Whether the theme's backdrop (BackdropTemplate) holds up under this or the plate's borders are built from textures, and how secret sizes are guarded, is the builder's, proven in tests as far as the stubs reach and checked in game.

### 7. The plates in each theme

- Plates follow the Nameplates page's Theme and Background (Use SaftUI's theme by default), like every unit.
- Under Thick and Thin: the bar's and castbar's borders as other unit frames' bars.
- Under the Blizzard theme: the `unitframe` kind's bronze box around the bar (it's at least 16 drawn) and the castbar; Blizzard's raid bar fills; the target border art (goal 3).

## Combat and taint

- Nothing is written onto Blizzard's nameplate frames beyond what the bundled oUF does (`nameplate.unitFrame`, `nameplate.style`, blocking the pooled UnitFrame); `NamePlateDriverFrame`'s events are left alone; forbidden plates are untouched.
- CVars are set out of combat. Size changes wait for the end of combat. Hit-test changes are only oUF's own two calls (`ClearAllHitTestPoints`, then `SetAllHitTestPoints` with SaftUI's frame on the plate), never a new kind of write onto Blizzard's frames: oUF makes them on the add, and SaftUI makes the same two again where Blizzard's pooled UnitFrame sets its own click area outside the add (ruling N11, from the final review): after `NamePlateDriverFrame:UpdateNamePlateOptions` (a post-hook), at the end of `UF:RefreshPlateWidgets`, and on the frame after the friendly NPC plates setting (or showing only friendly players' names) changes, through `CVarCallbackRegistry`. In combat the game lets addon code change a plate's click area only on the tick the plate got its unit or Blizzard's own code changed it (`CanChangeHitTestPoints`), so the post-hook's calls go through and one the game refuses waits for the end of combat.
- Threat and aura reads are secret-safe: a secret value hides the threat tint or falls back to Blizzard's filters, never errors.
- Rounding and scale calls go only on SaftUI's own frames on the plate (not protected).

## Both clients

The same Blizzard_NamePlates system. Differences: the target border atlas (above), Forever's effectively-tank aura, Forever's debuff source including the pet, the purge spell table per client.

## Constraints

- `.agents/taint.md`; `.agents/clients.md` for secret values.
- Saved profiles keep working; nameplates arrive on by default with a /reload.
- Words the user sees: no CVar, atlas or API names.

## Non-goals

- The personal resource display and Blizzard's class bars on plates.
- Forbidden plates (friendly plates inside instances).
- Restyling Blizzard's widgets (quest progress bars) and the soft-target icon.
- Plate scaling by distance or target; plate stacking/overlap tuning beyond what the CVars give.
- A crowd-control row, Blizzard's curated "important" buff list.

## Anti-goals

- Shimmering or doubling borders as plates move.
- An error from a secret threat, aura or name value.
- Anything done to Blizzard's plates SaftUI doesn't own.
- The threat tint on solo play when the toggle is off.

## Tests

- Spawning: one call, after the other units, only when enabled; plates in their own list; elements enabled after init (the TODO's error can't happen); widgets reparented on every add; size re-applied after Blizzard's update, deferred in combat.
- Layout: every element's place and size from the defaults, on both clients.
- Target border: on target change and on add, by frame; each look.
- Threat: the table above for each role and status, the co-tank case, nil shows nothing, secret shows nothing, solo off/on, colours from the Colors tab.
- Purge: the class table per client resolves to the right container filters; the toggle on every unit's Buffs; a player with no purge spell shows none; off is today's behaviour.
- Pixel-perfect: the CVars set out of combat and restored when plates are off; rounding applied to SaftUI's plate frames and none of Blizzard's; even sizes.
- Themes: Thick, Thin, Blizzard (the bronze box, the fills, the target art).
- The castbar fix (uninterruptible colour, no classic-only fallback) and the tag fixes, for every unit.

## Left to the builder

- Border construction for plates (backdrop vs textures), the rounding walker, secret-size guards.
- Exact sizes and offsets beyond the defaults above; the castbar's grey; how the purge table is keyed and verified per client.
- How the size re-apply hooks Blizzard's update.

## The builder check's answers (2026-11-11)

1. **Another nameplate addon:** the user's answer 8, stand down (goal 1).
2. **The Friendly plates toggle:** drives the game's friendly plates setting; off shows none; friendly plates carry the bar, name, health % and raid mark (goal 1, my calls).
3. **Threat colours:** they replace the bar's colour, bright orange and bright red, distinct from the muted hostile red (goal 4, my call).

## Questions for the user

None open.
