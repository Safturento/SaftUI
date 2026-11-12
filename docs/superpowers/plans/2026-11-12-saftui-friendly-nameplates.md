# Friendly Nameplates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Friendly plates get their own settings: a "Friendly nameplates" page beside "Enemy nameplates", name only by default, with a "use the other plates' settings" box on each page.

**Architecture:**
- A second plate config unit, `friendlynameplate`, sits beside `nameplate`.
- Each plate's frame points its `base_unit` at the config its current kind draws from (`UF.PlateConfigKey`). A kind change re-applies the whole look.
- A frame whose look isn't the enemy plates' sits centred on its plate at its own size, which is also its click area.

**Tech Stack:** Lua 5.1, oUF (bundled), AceDB/AceConfig through SaftUI's options window. Tests run on stubs with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-12-saftui-friendly-nameplates-design.md`. It builds on `docs/superpowers/specs/2026-11-11-saftui-nameplates-design.md`.

## Global Constraints

- **Clients:** Forever (16001) and retail (120000). `.agents/taint.md` and `.agents/clients.md` apply.
- **Combat:**
  - Plate frames aren't secure: their look, size and anchors change in combat too.
  - Aura buttons are restyled only while aura data isn't secret (`RestyleButtons`, `elements/auras.lua`).
  - Hit-test calls are oUF's own two (ruling N11), asked with `CanChangeHitTestPoints` first, queued for the end of combat when refused.
- **Enemy plates unchanged:** with default settings, an existing profile's enemy plates look and behave exactly as before. Every existing nameplate test passes unchanged, unless a task says which assertion changes and why.
- **Config keys (exact):**
  - `nameplate` (Enemy nameplates; keeps `enable`, `friendly`, `threat_solo`, `threat`);
  - `friendlynameplate` (Friendly nameplates);
  - the boxes `nameplate.use_friendly` and `friendlynameplate.use_enemy`, both default `false`.
- **Page names (exact):** `Enemy nameplates`, `Friendly nameplates`, in that order, after Raid 40.
- **Box labels (exact):**
  - `Use friendly nameplates' settings` (Enemy page);
  - `Use enemy nameplates' settings` (Friendly page).
- **Friendly defaults (exact):**
  - `width = 150`, `height = 16`;
  - frame Theme None (the plate frames' default today);
  - health off (bar and text);
  - name on, centred on the frame (anchored to the frame, not to an element), `max_width = 150`, `colorClass = true`, `color_friendly = true`, `color_hostile = true`, no level or classification;
  - raid mark on, `size = 16`, its BOTTOM 4 above the name's TOP;
  - castbar, debuffs, buffs and quest icon off, with the Enemy page's other values for when they're turned on.
- **Threat:** enemy-only whatever the settings, and always read from `nameplate.threat` and `nameplate.threat_solo`.
- **Nothing hard-coded hides parts on friendly plates except Threat.** `UF.PLATE_ENEMY_ONLY` becomes `{ Threat = true }`.
- **No WoW account folder name or character name** in any committed doc or test.

## Review Focus

1. **A plate reused across kinds mid-pull:** a mob's plate handed to a friendly guard and back, in combat. It shows the new kind's look in full each time (size, parts, name colour, no threat on the friend), with no Lua error. → Task 3 and Task 4 tests.
2. **The enemy box checked:** enemy plates draw from the Friendly page, but the threat tint and % still show and still follow the Enemy page's threat settings and Threat when solo. → Task 3 test.
3. **A box toggled while plates are up:** every shown plate re-resolves its config and size at once, and the plate size (all plates) follows the enemy look. → Task 4 and Task 5 tests.
4. **An existing profile:** today's `nameplate` values are untouched, and the Friendly page shows its defaults. → Task 1 test.
5. **The page while a box is checked:**
   - everything but the switches (and the Enemy page's threat settings) is hidden;
   - the other box is disabled;
   - unchecking brings the settings back with their values.

   → Task 5 test.

---

### Task 1: The friendly config unit and the plate units

**Files:**
- Create: `SaftUI-Unitframes/config/units/friendlynameplate.lua`
- Modify: `SaftUI-Unitframes/config/load.xml` (after `units\nameplate.lua`), `SaftUI-Unitframes/config/units/nameplate.lua` (`use_friendly = false`), `SaftUI-Unitframes/unitframes.lua` (plate unit helpers), `SaftUI-Unitframes/elements/power.lua:205-207`, `SaftUI-Unitframes/elements/indicators.lua:78,89`
- Test: `tests/unitframes/friendly_config_test.lua`

**Interfaces:**
- Produces:
  - `UF.PLATE_UNITS = { nameplate = true, friendlynameplate = true }`;
  - `UF.IsPlateUnit(unit) -> boolean`;
  - `UF.PlateConfigKey(friendly) -> 'nameplate' | 'friendlynameplate'`. For an enemy it's `nameplate`, or `friendlynameplate` while `nameplate.use_friendly`. For a friend it's `friendlynameplate`, or `nameplate` while `friendlynameplate.use_enemy`.
  - All three live in `unitframes.lua`, which loads before the elements and `nameplates.xml`.

- [ ] **Step 1: Write the failing tests** in `tests/unitframes/friendly_config_test.lua`, using the world that `nameplate_page_test.lua` and `config_test.lua` use to load defaults:
  - `the friendly defaults`: every value in the Global Constraints' "Friendly defaults", read through the profile (`P.friendlynameplate`).
  - `the enemy defaults are today's`: `P.nameplate` matches the current `config/units/nameplate.lua` values (width 200, height 20, health text short, name LEFT on Health, the castbar, debuffs and buffs on), plus `use_friendly == false`.
  - `an existing profile keeps its values`: a profile table holding a changed `nameplate.width = 180` and `nameplate.friendly = false`, run through AceDB defaults, keeps both, and gets `friendlynameplate` defaults.
  - `PlateConfigKey`: all four box states × both kinds. The state with both boxes on can't happen (Task 5), and the function must not loop on it: enemy → `friendlynameplate`, friend → `nameplate`.
  - `IsPlateUnit`: true for both keys, false for `player`, `party`, `nil`.
  - `the plates' parts`: `ValidUnit` of Power, the role indicator and the raid role indicator is false for `friendlynameplate` as for `nameplate`, and Threat's is false for `friendlynameplate` (its tab is on the Enemy page only).
- [ ] **Step 2: Run, expect FAIL** — `tests/run tests/unitframes/friendly_config_test.lua` (no `friendlynameplate` defaults, `UF.PlateConfigKey` nil).
- [ ] **Step 3: Implement.**
  - Write the defaults file in the style of `config/units/nameplate.lua`, with a header comment on the friendly look.
  - Add the load.xml line.
  - Add the helpers.
  - Replace the three `unit ~= 'nameplate'` checks with `not UF.IsPlateUnit(unit)`.
  - Leave Threat's `ValidUnit` as `unit == 'nameplate'`.
  - The name's frame anchor: pick the position value that `UF:GetFrame` resolves to the frame itself, and that the Name tab's position options can show. Say which in the report.
- [ ] **Step 4: Run, expect PASS**, then the full `tests/run`.
- [ ] **Step 5: Commit** — `unitframes: a friendly nameplate config beside the enemy one, and the plates' config key`.

### Task 2: The name's friendly colour

**Files:**
- Modify: `SaftUI-Unitframes/tags.lua` (`NameColor`), `SaftUI-Unitframes/elements/name.lua` (option)
- Test: `tests/unitframes/name_color_test.lua`

**Interfaces:**
- Produces: the Name config key `color_friendly` (boolean, default false for every unit; Task 1 sets it true on `friendlynameplate`).

- [ ] **Step 1: Write the failing tests:**
  - `color_friendly colours a friendly NPC`: reaction 5 (and 8), `color_friendly = true`, not a player. The tag's colour code is `UF.oUF.colors.reaction[reaction]`'s hex.
  - `players keep their class colour`: `colorClass = true`, `color_friendly = true`, a friendly player is in the class colour.
  - `off by default`: `color_friendly` unset leaves a friendly NPC uncoloured. Today's behaviour for every unit is unchanged (hostile red and yellow as before).
  - `a secret reaction`: no colour and no error (the tag's `Plain` reading).
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement.**
  - In `NameColor`, after the hostile branch: `config.color_friendly and reaction and reaction >= 5` gives the reaction colour from `UF.oUF.colors.reaction`.
  - In `name.lua`, a `Color friendly` toggle (desc: "Colors friendly units' names in the friendly reaction color."), shown where `UF.CanShow(unit, 'npcs')`, ordered after Color hostile.
- [ ] **Step 4: Run, expect PASS**, then the full `tests/run`.
- [ ] **Step 5: Commit** — `unitframes: names can be colored for friendly units`.

### Task 3: Plates draw from their kind's config

**Files:**
- Modify: `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF.PLATE_ENEMY_ONLY`, `UF:ApplyPlateKind`, its header comment), `SaftUI-Unitframes/unitframes.lua` (`UF:ApplyConfig`'s plate branch), `SaftUI-Unitframes/elements/name.lua` (the tag follows the base unit), `SaftUI-Unitframes/nameplates/threat.lua` (the Threat element's config)
- Test: `tests/unitframes/friendly_plate_test.lua`

**Interfaces:**
- Consumes: `UF.PlateConfigKey`, `UF.IsPlateUnit` (Task 1).
- Produces:
  - `UF:ApplyPlateConfig(frame) -> changed:boolean`: sets `frame.base_unit` to `UF.PlateConfigKey(frame.friendly)` and, when that changed, runs a full `UF:UpdateUnitFrame(frame)`.
  - `UF:ApplyPlateKind(frame, friendly)` calls it after setting `frame.friendly`, before its parts loop.
  - `UF:ApplyConfig('nameplate' | 'friendlynameplate', element_name)` re-resolves every plate's key, then updates every plate.

- [ ] **Step 1: Write the failing tests** (nameplate world, both clients):
  - `a friendly plate draws from the friendly config`: `frame.base_unit == 'friendlynameplate'`, the health bar hidden, the name shown, the castbar and aura areas off (disabled in oUF, hidden), the raid mark wanted.
  - `an enemy plate is unchanged`: `base_unit == 'nameplate'`, every part as before.
  - `a plate handed from an enemy to a friend and back, in combat`: each time, `base_unit` follows, the parts follow, the name tag is bound with the new base unit, no Lua error, and the friend shows no threat tint or text.
  - `UNIT_FACTION turns a friend hostile`: the plate takes the enemy look.
  - `the friendly box`: with `friendlynameplate.use_enemy = true` and `UF:ApplyConfig('friendlynameplate')`, a friendly plate's `base_unit == 'nameplate'` and its castbar and auras follow the enemy config. Threat is still hidden on it.
  - `the enemy box keeps threat`: with `nameplate.use_friendly = true`, an enemy plate's `base_unit == 'friendlynameplate'`. Its threat tint and text still show in a group, and the text's font and position come from `nameplate.threat`. `nameplate.threat_solo` still decides when you're on your own.
  - `parts turned on in the friendly config show on friends`: friendly castbar enabled, so a friendly plate's castbar is enabled in oUF.
  - `a re-applied look only when the key changes`: two adds of friends in a row run one `UF:UpdateUnitFrame` for the kind (count calls), not two.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement.**
  - `UF.PLATE_ENEMY_ONLY = { Threat = true }`; update its header comment.
  - `UF:ApplyPlateConfig`.
  - The Name element re-binds its tag (`Untag`, then `Tag`) when the base unit it was bound with differs from the frame's.
  - The Threat text reads `UF:GetProfileConfig().nameplate.threat` (its `config` and `GetConfig`) whatever the frame's base unit.
  - `UF:ApplyConfig`'s branch runs for both plate keys.
  - Every existing nameplate test that asserted friendly parts hidden by kind changes to assert hidden by the friendly config. Name each changed assertion in the report.
- [ ] **Step 4: Run, expect PASS**, then the full `tests/run`.
- [ ] **Step 5: Commit** — `unitframes: a plate draws from its kind's nameplate config`.

### Task 4: A friendly look's own size, the plate size and the click area

**Files:**
- Modify: `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF:ApplyPlateSize`, placing a plate's frame, the click area after it), `SaftUI-Unitframes/unitframes.lua` (`UF:PlaceUnitFrame` and `UF:UpdateUnitFrame` for plates)
- Test: `tests/unitframes/friendly_plate_size_test.lua`

**Interfaces:**
- Consumes:
  - `UF.PlateConfigKey`, `UF:ApplyPlateConfig` (Tasks 1 and 3);
  - `UF:RestorePlateHitTests` and its guards (`nameplates.lua`, ruling N11).
- Produces:
  - `UF:PlacePlateFrame(frame)`: the frame fills its plate (`SetAllPoints`) when its `base_unit` is `UF.PlateConfigKey(false)`. Otherwise it's `CENTER` on the plate at its config's Width and Height. It runs from `UF:UpdateUnitFrame` for plates, in or out of combat.
  - `UF:RestorePlateHitTest(frame)`: one plate's version of the restore, with the same ask-first and queue rules.

- [ ] **Step 1: Write the failing tests:**
  - `a friendly plate is 150 by 16, centred`: its rect is centred in its plate's.
  - `an enemy plate fills its plate`.
  - `the plate size follows the enemy look`: `nameplate.use_friendly = true` → the driver's size is `friendlynameplate`'s width and height (through `UF.PlateDriverSize`). Off again → `nameplate`'s.
  - `a kind change in combat resizes the frame`.
  - `the click area is the frame after a resize`: hit-test points on the frame after a kind change. In combat on the add tick it's at once; after a `UNIT_FACTION` change in combat it waits for the end of combat, with no error.
  - `the rounding walk and the widgets after a resize`: the plate is still rounded (`'updated'`), and the widgets still sit under the plate.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement.** `UF:PlaceUnitFrame` returns true for plates after `UF:PlacePlateFrame`. `UF:UpdateUnitFrame` calls the plate placement even in combat. `UF:ApplyPlateSize` reads `UF.PlateConfigKey(false)`'s config. `UF:PlacePlateFrame` calls `UF:RestorePlateHitTest(frame)` when the frame's anchors changed.
- [ ] **Step 4: Run, expect PASS**, then the full `tests/run`.
- [ ] **Step 5: Commit** — `unitframes: a friendly plate is its own size, and the plate size follows the enemy look`.

### Task 5: The Enemy and Friendly nameplates pages

**Files:**
- Modify: `SaftUI-Unitframes/config/config.lua`:
  - `UNIT_ORDER`, `UNIT_SHOWS`;
  - `UF:GetConfigFrame` (both keys give the lowest plate);
  - `UF:OpenCopyTable` (both keys left out);
  - `NameplateGeneral`;
  - a `FriendlyNameplateGeneral`;
  - the per-unit page branch;
  - `config.args.friendlynameplate`.
- Test: `tests/unitframes/friendly_page_test.lua`

**Interfaces:**
- Consumes: the config keys (Task 1); `UF:UpdateConfig('nameplate' | 'friendlynameplate')` re-resolving plates (Task 3); `UF:ApplyPlateSize` (Task 4).

- [ ] **Step 1: Write the failing tests** (the `nameplate_page_test.lua` harness):
  - `the two pages`: `Enemy nameplates` then `Friendly nameplates`, after Raid 40. Neither has Copy from, and neither is offered in another unit's Copy from.
  - `the Friendly page`: General has `Friendly plates` (reads and writes `nameplate.friendly`, runs `UF:ApplyNameplateCVars`), `Use enemy nameplates' settings`, Theme, Background, Width and Height. It has the element tabs of a plate except Threat.
  - `checking a box hides the page`:
    - Friendly box on: every option and tab on the Friendly page is hidden except `Friendly plates` and the box. A description under the box says friendly plates use the Enemy nameplates page.
    - Enemy box on: everything on the Enemy page is hidden except `Nameplates`, the box, `Threat when solo` and the Threat tab. The description says enemy plates use the Friendly nameplates page for all but threat.
  - `one box at a time`: with one box on, the other page's box is disabled, and a description under it says the other kind uses this page.
  - `unchecking brings the settings back`: values set before checking are the same after unchecking.
  - `a box re-applies every plate and the plate size`: setting either box runs `UF:UpdateConfig` for plates and `UF:ApplyPlateSize`, and a shown plate's `base_unit` follows.
  - `standing down`: with another nameplate addon, both pages say which and disable everything.
- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement.** Rename the `nameplate` page to `Enemy nameplates`. Build the Friendly page with `GetUnitConfig('friendlynameplate')` and the same plate branch (no Copy from, `StandDown`). Hide through AceConfig `hidden` functions read at call time, and disable through `disabled`. Tooltips follow the repo's options style (`.agents/edit-mode.md`).
- [ ] **Step 4: Run, expect PASS**, then the full `tests/run`.
- [ ] **Step 5: Commit** — `unitframes: the Enemy and Friendly nameplates pages, each able to use the other's settings`.

### Task 6: Docs

**Files:**
- Modify: `.agents/architecture.md`, `.agents/edit-mode.md`, `.agents/testing.md`, `.agents/taint.md` (only if a rule's statement changed), `README.md`, `docs/followups.md`

- [ ] **Step 1: Write the docs:**
  - **architecture.md, the Nameplates section:** the two config keys, `UF.PlateConfigKey`, `UF:ApplyPlateConfig`, `UF:PlacePlateFrame`, threat reading the enemy config, and `PLATE_ENEMY_ONLY` now `{ Threat = true }`. Add `'SaftUI-Unitframes/config/units/friendlynameplate.lua'` to its `covers`.
  - **edit-mode.md:** the two pages, the boxes, hiding and disabling.
  - **testing.md:** rows for the four new test files.
  - **README.md:** the friendly plates' look and page, the boxes, and the Name tab's Color friendly.
  - **followups.md:** add the spec's five in-game checks to "Nameplates: in-game checks", and correct anything there that the friendly look changes (step 7, the friendly plates; the declined items about city NPC plates).
  - Bump `last_updated` on each doc changed.
- [ ] **Step 2: Parity:** `git diff --name-only modular...HEAD` against every `.agents/*.md` `covers`, and the README against every user-facing change.
- [ ] **Step 3: Run the whole suite** — `tests/run`, exit 0.
- [ ] **Step 4: Commit** — `docs: friendly nameplates in the agent docs, the README and the in-game checks`.

## Order and parallelism

- **Wave 1:** Task 1 and Task 2 in parallel (separate files).
- **Wave 2:** Task 3 and Task 5 in parallel, both after Task 1 (nameplates and elements against config.lua).
- **Wave 3:** Task 4 after Task 3.
- **Wave 4:** Task 6.

Task 5's box test for the plate size needs Task 4's `UF:ApplyPlateSize` change. Until Task 4 lands it asserts only that `UF:ApplyPlateSize` is called.
