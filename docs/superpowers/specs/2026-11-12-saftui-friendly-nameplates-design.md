# SaftUI friendly nameplates: their own settings

Date: 2026-11-12. Status: approved in the brainstorm (2026-11-12). The user's answers are binding; the calls marked "My call" are the controller's, for the user to check. Builds on SaftUI's nameplates (`docs/superpowers/specs/2026-11-11-saftui-nameplates-design.md`), merged on `modular`.

## Why

With SaftUI's plates on, every friendly NPC in a city gets a full 200 by 20 plate, and the user found that overwhelming. They want friendly plates to be "just a simple name instead of a full nameplate, class colored for players", and fully configurable apart from enemy plates, with that look as the default.

## What the user decided

1. **Friendly plates have their own settings**, separate from enemy plates, and fully configurable: every part an enemy plate has can be turned on and set up for friendly plates too.
2. **The default friendly look is a name only**, with players' names in their class color.
3. **"Use the other plates' settings":** both pages get one checkbox: on the friendly page "Use enemy nameplates' settings", on the enemy page "Use friendly nameplates' settings". Checked, that kind of plate takes every setting from the other page, and **the rest of its own page is hidden**, so it's obvious the box is on and nobody wonders why their changes do nothing.
4. **Friendly players and friendly NPCs share one config** for now. The user may want them split later (`docs/followups.md`, "Nameplates: friendly players and friendly NPCs configured apart").
5. The mockups' guesses below were all confirmed ("all of that looks good", "yep all of that tracks", "all sounds good").

## Goals

- `/sui` → Unitframes has two plate pages where it has one today: **Enemy nameplates** (today's Nameplates page, renamed) and **Friendly nameplates**, after Raid 40, in that order. Both have the same tabs and parts as today's page: General, Health, Name, Castbar, Buffs, Debuffs, the quest icon, the raid mark. Threat is on the enemy page only.
- A friendly plate is drawn from the Friendly page's settings, an enemy or neutral plate from the Enemy page's, unless that kind's "use the other's settings" box is checked.
- **Friendly defaults** (confirmed):
  - no health bar;
  - the name centred, with players in their class color and friendly NPCs in the friendly reaction green;
  - the raid mark on, above the name;
  - the castbar, debuffs, buffs (the purge row) and the quest icon off.

  My calls after the builder check:
  - The frame's own Theme is None, as on today's plates, so nothing is drawn behind or around the name: "a simple name". The click area is the frame, which is invisible.
  - The health text is off with the bar.
  - The name sits at the frame's centre, attached to the frame, not to the hidden health bar. The raid mark sits above the name (its bottom 4 above the name's top), so neither depends on a part that's off.
  - Every other part takes the same defaults as the enemy page, but off.
  - With no bar and the frame at None, the target's name-only plate has no border. The target border needs something drawn to go round, and the name isn't such a thing. Whether it needs a mark is an in-game judgement (check 1).
- **Enemy defaults:** today's Nameplates defaults, unchanged.
- **The boxes:**
  - Only one can be on at a time. While one is checked, the other page's box is greyed out (disabled), with a note that the other kind uses this page's settings.
  - A checked box hides every other setting on its page, apart from the on/off switches below. A short note under it says where to change the look: the other page.
  - The hidden settings are kept. Unchecking the box brings them back exactly as they were.
  - Both are off by default.
- **The on/off switches stay visible.** They aren't looks, so a checked box doesn't hide them (confirmed):
  - **Nameplates** (all of SaftUI's plates; asks to reload) is on the Enemy page's General.
  - **Friendly plates** (whether the game shows friendly plates at all; it drives the game's two friendly settings, as today) is on the Friendly page.
  - **Threat when solo** stays on the Enemy page with the other threat settings, and stays visible when the enemy box is checked (see Threat below).
- **Your settings carry over** (confirmed): what's set on today's Nameplates page becomes the Enemy page, in every existing profile. The Friendly page starts from its new defaults. Today's Friendly plates value is kept.
- **Size and clicking** (confirmed):
  - The game gives every plate one size (`C_NamePlate.SetNamePlateSize`: there's no friendly size on either client), and that size sets how plates stack and space. It stays the enemy look's Width and Height. That is the Enemy page's, or the Friendly page's while the enemy box is checked.
  - A friendly look is drawn at its own Width and Height, centred on its plate.
  - The click area is what's drawn: SaftUI's frame, as today, so a name-only plate is clicked on its name box, not an invisible 200 by 20 box.
  - Friendly default size: about a name's width and height. My call: 150 by 16, the name's Max width 150.
- **A plate the game hands from one kind to the other takes the new kind's look in full:** its size, which parts show, their places, sizes, theme and colors, and the name's colors. This applies out of combat and in combat (a plate's frame isn't secure). The one exception is aura buttons already made: they keep their style until combat ends, as every config change to them does today (`.agents/taint.md` rule 11).
- **Threat stays enemy-only** (confirmed), whatever the settings. The tint and the % never show on a friendly plate, even when friendly plates use the enemy settings.
- **Threat always reads the Enemy page's threat settings** (the Threat tab, Threat when solo), by plate kind, not by which page an enemy plate's look comes from. My call after the builder check: the Friendly page has no threat settings, so while the enemy box is checked the Enemy page keeps showing its Threat tab and Threat when solo, and they still take effect. The box's note says so: everything but threat comes from the Friendly page. A checked box must never quietly turn threat off.
- **Unchanged:**
  - Inside dungeons and raids, friendly plates are Blizzard's (forbidden to addons), whatever the Friendly page says.
  - SaftUI still stands down when Plater or another nameplate addon is loaded.
  - The pixel-perfect rounding, the target's border, the stand-down, the game settings record and restore, the click-area restore (ruling N11), and the plates in each theme all apply to both kinds.

## Non-goals

- Splitting friendly players from friendly NPCs (a followup; the user may want it later).
- Copy from between the two plate pages, or from other units. The plate pages stay out of Copy from, as today. The boxes are the way to share a look. My call.
- Any change to how the game stacks plates.
- Styling friendly plates inside instances (impossible: forbidden plates).

## Anti-goals

- **A user changes a setting and nothing happens.** That's why a checked box hides its page, and why the other box is greyed out with a note.
- **Both boxes on,** so neither page holds the real settings.
- **The enemy plates looking or behaving any differently after this change** with default settings. Existing profiles must see no difference on enemy plates.
- **A plate showing a mix of the two looks** after it changes kind: parts from the old kind left on, the old size, or the old name colors.
- **A plate's click area larger than what's drawn.**

## Constraints

- Lua 5.1, Forever (16001) and retail (120000). There's no build step. Tests run on the stubs with `tests/run`, and must pass.
- `.agents/taint.md` applies, and so do the nameplates spec's "Combat and taint" rules:
  - plate frames aren't secure, so their look can change in combat;
  - aura buttons can't be touched while aura data is secret, so their restyle waits for the end of combat;
  - hit-test changes are oUF's own two calls (ruling N11), now on a frame whose size can change with its kind: the click area must follow the frame after a kind change.
- Secret values on plates as today (names, levels, reactions, classes can be secret): the name's class color is skipped for a secret class, as today.
- **Code facts the builder needs** (as of `modular` 3b8fc12):
  - A unit frame reads its config through `frame.base_unit` (`UF:GetProfileConfig()[base_unit]`, `unitframes.lua`), and its elements and texts keep `config` and `GetConfig` from it.
  - The name tag reads `units[baseUnit].name` from its tag argument (`tags.lua`, `st:name`).
  - `UF:PlaceUnitFrame` returns early for plates, and `UF:UpdateUnitFrame` skips placement in combat.
  - oUF makes one frame per `NamePlateN` and hands it units of either kind. `UF:ApplyPlateKind` (`nameplates/nameplates.lua`) runs on every add and on `UNIT_FACTION`, and `UF.PLATE_ENEMY_ONLY` turns parts off on friendly plates today.
  - The plate size comes from `nameplate.width`/`height` (`UF:ApplyPlateSize`).
  - The game settings come from `nameplate.friendly` (`nameplates/cvars.lua`).
  - The Nameplates page is in `SaftUI-Unitframes/config/config.lua`.
- `UF.PLATE_ENEMY_ONLY`'s hard-coded friendly hiding of the castbar, debuffs, buffs and quest icon gives way to the Friendly page's settings: those parts show on friendly plates when that page turns them on. Threat stays hard-coded enemy-only.

## What's left to the builder

- How a plate's frame switches config by kind: a second config unit key beside `nameplate` (e.g. `friendlynameplate`) that the frame's base unit points at, or another way. Every config read must follow the plate's current kind, including the name tag and every element's `config`.
- Where the box values and the Friendly plates switch live in the profile, as long as existing profiles keep today's values.
- How the pages hide and grey out (AceConfig `hidden` and `disabled`), and the note's wording.
- The friendly reaction green for NPC names: a Name option (e.g. "Color friendly", using the profile's reaction color for friendly) that's on in the friendly defaults. It should be available where it makes sense for other units too, off by default there, so no other unit changes.
- Keeping kind switches cheap: a plate re-applies a look only when its kind's effective config differs from the one it last applied.
- How a frame of its own size sits on its plate: re-anchored and resized on each kind change, in or out of combat. After it:
  - the rounding walk runs, as after every update (`'updated'`);
  - the click area is SaftUI's frame (re-run oUF's two hit-test calls, ruling N11, if the anchors don't follow the frame's new size);
  - Blizzard's widgets still sit under the plate (`PlaceWidgets`).
- **Which plates are friendly:** today's rule (`UF:IsFriendlyPlate`) is unchanged. My call after the builder check: a duel opponent, a neutral or attackable unit, and a secret answer are enemy plates.

## In-game checks (to add to `docs/followups.md`'s nameplates in-game checks)

1. In a city, friendly NPCs and players show only their names: players in class color, NPCs green. Click a name: you target that unit. Click beside it: nothing.
2. The Enemy page looks and behaves as the old Nameplates page did, with your old settings.
3. Check the friendly page's "Use enemy nameplates' settings":
   - the friendly page's other settings disappear;
   - friendly plates look like enemy plates (no threat);
   - the enemy page's box is greyed out with its note.

   Uncheck it: the friendly settings come back as they were.
4. The same from the Enemy page's box.
5. Mobs and friendly NPCs together (a guard fighting a mob), and a duel or a mob turning friendly: plates switch looks cleanly, in and out of combat, with no leftover parts.
