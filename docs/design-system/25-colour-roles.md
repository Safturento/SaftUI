# Colour roles: analysis and proposal

A proposal, not yet decided. The Colors page lets the player change colours that are named after a hue (Blue, Red, Green and so on), which can then stop being that hue. This page lists every use of each one and proposes names that say what the colour is for.

## Questions for the owner

1. **The role names.** Text becomes: Text, Muted (was Grey), Strong (was White), Danger (was Red), Warning (was Orange), Caution (was Yellow), Success (was Green), Shared (was Cyan). Are those the right words?
2. **Blue becomes the theme's accent** (already decided), so Text > Blue and Buttons > Blue both leave the Colors page for the one accent swatch in the Theme section.
3. **Three small groups of their own,** so that changing Danger doesn't recolour a Pass or a DPS mark: loot rolls (Need, Greed, Transmog, Pass), factions (Alliance, Horde, Neutral) and roles (Tank, Healer, Damage). Yes, or keep them tied to the state colours?
4. **Own and Edited.** A bar's own setting is light blue and the diff icon is orange, both hardcoded today. They would become two colours the player can change, Own and Edited (Edited also marks an edited bag category). Or should Own just be a lighter accent?
5. **The equipped item's border** on action buttons is green today. "On is the accent, never green" argues for accent, but hover on the same button is already accent. Success, accent, or its own colour?
6. **The Buttons section's opacity sliders do nothing** (no code reads them). Remove them, or make them work?
7. **White and Text** are nearly the same role. Keep both (Strong for item levels and counts), or fold White into Text?


Read-only pass over `/mnt/c/Github/wow-addons/SaftUI-Modular` (every `SaftUI-*` addon, skipping `Libraries/`, `tests/` and `.claude/`). Counts come from grep. Paths are relative to the repo root. `Config/` means `SaftUI-Core/Config/`.

**Scope.** `SaftUI-Chat` reads no profile colours at all. The owner's "chat prefix" example is really `st:Print`'s hardcoded `|cff00adef` (`SaftUI-Core/api.lua:122`).

## 1. Where the colours are defined and how code reaches them

### Definitions

**`SaftUI-Core/Config/defaults.lua:109-215`** holds `st.defaults.colors`. Defaults as colour objects (`CreateColor`):

| `text.*` | default | `button.*` | default (r, g, b, a) |
|---|---|---|---|
| `normal` | 0.9, 0.9, 0.8 | `normal` | 0.1, 0.1, 0.1, 0.6 |
| `red` | 220, 100, 100 | `hover` | 0.3, 0.5, 0.7, 0.8 |
| `orange` | 220, 150, 100 | `pushed` | 0.3, 0.4, 0.5, 0.8 |
| `yellow` | 200, 200, 100 | `red` | 0.6, 0.1, 0.1, 0.8 |
| `green` | 60, 240, 60 | `green` | 0.1, 0.6, 0.1, 0.8 |
| `grey` | 150, 150, 150 | `blue` | 0, 0.68, 0.94, 0.8 |
| `blue` | 0, 0.68, 0.94, 1 (#00adf0) | `yellow` | 0.6, 0.6, 0.1, 0.8 |
| `purple` | 197, 128, 255 | `grey` | 150, 150, 150 |
| `cyan` | 120, 202, 250 | | |
| `white` | 1, 1, 1 | | |

Other groups in the same table:
- `experience`: `normal`, `rested`. Not on the Colors page. Not hue-named.
- `item_quality[0..8]`.
- `power`: Blizzard power tokens such as `MANA`.
- `class`: class tokens.
- `renown`.
- `reaction[1..8]`.
- `status`: `disconnected`, `tapped`.
- `threat`: `warning`, `bad`.

**Hue-named keys.** Only `text.*` and `button.*` are named by hue. The others are named by game concept or already by role: `threat.warning` and `bad`, `status.*`, `experience.*`.

**`SaftUI-Core/Media/colors.lua`**
- `CO.SECTIONS` (lines 44-139) defines the Colors tab. Text rows are at lines 49-58 and Button rows at 64-71, each with a one-line `desc` that says what the colour touches.
- `CO:GetConfigTable` (line 253) builds the tab. The tab is `Fonts.args.colors` in `tests/core/colors_test.lua`, shown as Global settings > Colors.
- `ProfileColor` and `DefaultColor` (lines 167-181) read `st.config.profile.colors[group][key]` and the default at call time.
- `ColorDefault` (lines 195-208) resets a swatch by writing `c.r, c.g, c.b, c.a = from...` into the existing table.
- `st:ColorsChanged(group)` (line 10) calls every module's `OnColorsChanged(group)`.
- Groups that test `group == 'text'` or `'button'`:
  - `SaftUI-Bags/header.lua:230-231`
  - `SaftUI-Bags/slot.lua:106`
  - `SaftUI-Loot/roll.lua:587`
  - `SaftUI-Loot/Feed/feed.lua:167`
  - `SaftUI-Misc/Skinning/blizzard/ZoneText.lua:290`

**Side finding: no code reads the alpha of a `button.*` colour.** The Buttons section has `hasAlpha = true`, so every swatch gets an opacity slider (the only `:GetRGBA()` is the picker's own getter at `colors.lua:221`). Every use calls `:GetRGB()` and applies a literal alpha such as `HOVER_ALPHA`, `PUSHED_ALPHA` or `0.25`. The opacity sliders on the Buttons page do nothing, and the 0.8 alphas in the defaults are dead.

### Ways code reaches them

1. **Direct profile reads.** About 130 sites, e.g. `st.config.profile.colors.text.red:GetRGB()` and `st.config.profile.colors.button.blue:GetRGB()`.
2. **`Colors()` helpers, which return `st.config.profile.colors`.**
   - Core's options kit uses `OM.Colors` / `OB.Colors` / `Kit.Colors` (`Config/optionsmodel.lua:137`).
   - Bags uses `D.Colors` (`SaftUI-Bags/dragparts.lua:43`).
   - Misc has `Colors()` in `SaftUI-Misc/experience.lua:6` (experience only).
   - Objective tracker has `Profile().colors`.
3. **Thin wrappers that each hide a single entry** (about 47 call sites):
   - `Config/optionsbody.lua:209-211`: `Normal()` = text.normal, `Grey()` = text.grey, `Blue()` = **button**.blue.
   - `Config/optionsshare.lua:110-111`: `Grey()`, `LinkBlue()` = text.blue.
   - `SaftUI-Bags/dragparts.lua:44`: `D.Grey()` = text.grey, aliased `Grey` in `categoriestab.lua` and `ruleeditor.lua`.
   - `SaftUI-Bags/categoriestab.lua:141`: `Normal()`.
   - `SaftUI-Misc/Skinning/addons/restedxp.lua:168`: `GreyRGB()`.
   - `Config/optionsnav.lua:93`: `PickedText()` reads theme art, not the profile.
4. **Local aliases of a whole group.**
   - `local colors = ...colors.text`: `SaftUI-Bags/slot.lua:226`, `SaftUI-Core/EditMode/settings.lua:22`, `SaftUI-Loot/Feed/feed.lua:38`, `SaftUI-Minimap/stats.lua:7`, `SaftUI-Misc/totemtimers.lua:316`, `SaftUI-Unitframes/tags.lua:9`, `SaftUI-Unitframes/grouppreview.lua:173` (`textColors`).
   - `local colors = ...colors.button`: `SaftUI-Core/Widgets/scrollbar.lua:9`, `SaftUI-Core/Widgets/checkbutton.lua:81`, `SaftUI-Minimap/micromenuitems.lua:33`.
   - `local colors = ...colors`: `SaftUI-ActionBars/skin.lua:391`, `SaftUI-Misc/totemskin.lua:258`, `SaftUI-Core/EditMode/picker.lua:113`, `SaftUI-Core/panels.lua:359`, `SaftUI-Unitframes/nameplates/threat.lua:153`.
   - `local blue = ...button.blue`: `Core/EditMode/grid.lua:72`, `Bags/categoriestab.lua:786` (text.blue).
5. **String-keyed reads** (a hue name stored in data):
   - `SaftUI-Misc/Skinning/blizzard/ZoneText.lua:57` has `FACTION_COLORS = { Alliance='blue', Horde='red', Neutral='yellow' }`, read at `:90`.
   - `SaftUI-Loot/rollbar.lua:12-15` has `color='red'|'yellow'|'purple'|'white'` per roll button, read at `SaftUI-Loot/roll.lua:89`.
   - `SaftUI-Loot/rollinfo.lua:77-78` has `PAIRED`, read at `:113`.
   - `SaftUI-Loot/Feed/rolls.lua:40-42` has `CHOICES`, read through `TextRGB(key)` at `:57-58`, plus literal `'red'` and `'green'` at `:127`, `:157`, `:165`, `:196`.
   - `SaftUI-Bags/containers/bank.lua:165` has `text[tooExpensive and 'red' or 'white']`.
   - Consequence: **`text.purple` has no `text.purple` property read anywhere.** It is reached only through the string `'purple'`, so a grep for the property finds nothing.
6. **Object methods.** `:GetRGB()` everywhere. The colour object is also passed whole (`totemtimers.lua:238`, `curve:AddPoint(0, text.red)`), and `.r/.g/.b` are read directly (`slot.lua:231`).
7. **Hex or escape strings built from them:**
   - `SaftUI-Bags/slot.lua:208-209`: `ColorEscape` -> `colors.grey`, `colors.yellow`.
   - `SaftUI-Bags/views.lua:182`: bag title suffix, grey.
   - `SaftUI-Core/EditMode/picker.lua:75-76` `ColorCode`: `button.blue`, `button.grey`.
   - `SaftUI-Unitframes/tags.lua:60,62`: `'|cff'..ToHex(text.red/yellow)`.
   - `SaftUI-Misc/Skinning/blizzard/ZoneText.lua:90-91`: faction word.
   - `SaftUI-Core/Config/optionsnav.lua:227-228`: "Profile: ..." in text.normal.
   - `st.StringFormat:ColorString(text, r, g, b)` in `Bags/containers/bag.lua:197-199` (green), `combinedbank.lua:129-131` (cyan), `api.lua:135` (red), `Loot/Feed/rolls.lua:62`.
8. **`WrapTextInColorCode` is not used** for these colours.
9. **Aliases that carry hue meaning outside the profile.** There are none. `tests/` also pins the keys (see part 7).

## 2. Every use of every colour-named entry, by meaning

Format: `file:line` and a few words. Sites that go through the wrappers are expanded.

### `text.normal` (not a hue; "the ordinary text colour"). About 25 sites.
- **Body text**
  - Options window: field font `Config/optionslook.lua:37`, `Config/optionsbody.lua:229` (font objects), row labels `optionsbody.lua:711,735,764`, nav entries `optionsnav.lua:108`, active tab `optionsnav.lua:286`, hovered tab `:244`, "Profile: ..." value `:227`, input text `Config/optionstypes.lua:439`.
  - Options widgets: bound key `Config/optionskeybinding.lua:157`, unselected list row `Config/optionslist.lua:67`, position axis label `Config/optionsposition.lua:386`.
  - Totem bar: timer text `SaftUI-Misc/totemtimers.lua:155,248,321`, summon arrow fallback `SaftUI-Misc/totemskin.lua:365`.
  - Other: zone line `SaftUI-Misc/Skinning/blizzard/ZoneText.lua:173`, nameplate threat text while threat is fine `SaftUI-Unitframes/nameplates/threat.lua:154`, Categories tab name `SaftUI-Bags/categoriestab.lua:542`.
- **Glyphs and icons** in text colour: Bags header glyph `SaftUI-Bags/header.lua:57`, currencies filter icon `SaftUI-Bags/currencies.lua:172`, feed filter icon at rest `SaftUI-Loot/Feed/feed.lua:39`.
- **Hover or active text**
  - Position dot hovered `optionsposition.lua:42`; nudge arrows hovered `:115`.
  - Slider knob `Config/optionsrange.lua:69,144`.
  - Hovered tab `optionsnav.lua:244`.
  - Edit mode button when edit mode is off `optionsnav.lua:52`.

### `text.grey` (muted). About 45 sites.
- **Secondary and hint text**
  - Window: search hint `Config/optionswindow.lua:860`, brand sub-title `:909`, profile footer `:928`, page description `:962`, placeholder `:991`, footer label `:1028`.
  - Page body: section titles `Config/optionsbody.lua:850,1100`, section notes `:856`, menu title `Config/optionsmenu.lua:184`.
  - Share/own line: separator and pipe `Config/optionsshare.lua:385-386`, source tooltip line `:180`.
  - Bags: category count `SaftUI-Bags/categoriestab.lua:527`, "(nth)" place in the category tooltip `SaftUI-Bags/slot.lua:230`, bag-type suffix in the bag title `SaftUI-Bags/views.lua:182`, rule editor captions `SaftUI-Bags/ruleeditor.lua:501,515,858`, Not-box off `:715`.
  - RestedXP text `Misc/Skinning/addons/restedxp.lua:169`.
- **Disabled or inactive**
  - Disabled row labels `optionsbody.lua:708,710`; an item row whose Show is off.
  - Inactive tabs `optionsnav.lua:200,247,286`.
  - Sidebar group titles `optionsnav.lua:200`.
  - A disabled category's name and its strike-through `categoriestab.lua:538,551`.
  - Unbound key `Config/optionskeybinding.lua:160`.
  - Position nudge arrows at rest `optionsposition.lua:104,120`.
- **Resting icons and decorations**
  - Chevron carets `Config/optionsselect.lua:30`, `ruleeditor.lua:102`; options item dots at rest `optionsitem.lua:54`.
  - Remove x icons at rest `categoriestab.lua:1088,1122`, `ruleeditor.lua:784,834`.
  - Drag handle dots `dragparts.lua:72`.
  - Close button X at rest `SaftUI-Core/panels.lua:367`.
  - Objective tracker collapse icon `Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua:181`.
  - Position block field labels `optionsposition.lua:353`.
- **Game meaning:** a unit frame level tag for a far lower level (`SaftUI-Unitframes/tags.lua:19`).

### `text.red`. About 20 sites.
- **Errors and refusals**
  - Dialog status line `Config/optionssmalldialog.lua:182`.
  - Window footer status `Config/optionswindow.lua:1016`.
  - Why a row is disabled, in its tooltip `optionsbody.lua:641`.
  - `st:Debug` "DEBUG" label `SaftUI-Core/api.lua:136`.
  - "Can't buy bank slots in combat." `SaftUI-Bags/containers/bank.lua:84`.
  - Bank tab purchase button when you can't afford it `bank.lua:165`.
- **Urgency**
  - Loot roll timer text under 60s `SaftUI-Loot/roll.lua:228`, `rollbar.lua:204`.
  - Totem timer and bar while expiring `SaftUI-Misc/totemtimers.lua:238,318-319`.
- **Destructive hover**
  - Close button border and X on hover `SaftUI-Core/panels.lua:362-363`.
  - Remove icons on hover `categoriestab.lua:1087`, `ruleeditor.lua:783`.
- **Pass or decline in loot**
  - Pass button `rollbar.lua:12`.
  - "All passed" and "Pass:" `Loot/Feed/rolls.lua:127,165,196`.
- **Game meaning (identity, not a state)**
  - Level tag for a much higher level `tags.lua:11`.
  - Hostile names (reaction below 3) `tags.lua:60`, `grouppreview.lua:278`.
  - DPS role mark `SaftUI-Unitframes/elements/indicators.lua:65`, `grouppreview.lua:297`.
  - Horde on the zone text and the world map's zone names `ZoneText.lua:57`.

### `text.orange`. 5 sites.
- Level tag for a somewhat higher level `tags.lua:13`.
- Bad end of the micro menu's latency and FPS gradient `SaftUI-Minimap/stats.lua:8`.
- "yours" / "edited" marker on a category `SaftUI-Bags/categoriestab.lua:532`.
- Rule editor OR operator: group connector colour `ruleeditor.lua:93` and row tint `:825`.

### `text.yellow`. 8 sites.
- Greed on loot rolls: button letter `rollbar.lua:13`, counts `rollinfo.lua:78`, tooltip `rolls.lua:42`.
- Level tag near your level `tags.lua:15`.
- Unfriendly names (reaction 3 or 4) `tags.lua:62`, `grouppreview.lua:278`.
- Middle of the micro menu's stats gradient `stats.lua:9`.
- Micro menu alert flash `SaftUI-Minimap/microbuttons.lua:139`.
- Neutral on zone text and world map `ZoneText.lua:57`.
- "Caught by:" prefix in a bag item's category tooltip `slot.lua:250`.

### `text.green`. 11 sites.
- **"On" and active (conflicts with decision 7)**
  - Edit mode footer toggles on `SaftUI-Core/EditMode/settings.lua:22` (the comment says "green text when on, grey when off").
  - Edit mode button in the sidebar while edit mode is active `Config/optionsnav.lua:52`.
- **Bags: Bind on Equip and reagent**
  - BoE item level `slot.lua:138`.
  - Reagent corner marker `slot.lua:480,503`.
  - Reagent bag count `containers/bag.lua:199`.
- **Good end or easy**
  - Good end of the stats gradient `stats.lua:10`.
  - Level tag for a lower level `tags.lua:17`.
  - Winner's roll in the loot tooltip `rolls.lua:157`.
- **Game meaning:** healer role mark `indicators.lua:61`, `grouppreview.lua:293`.

### `text.blue` (9 direct sites plus `LinkBlue`, `blue`, string keys)
- **Selected, active or lit**
  - Selected list row text `Config/optionslist.lua:65`.
  - Found setting's label (search jump) `Config/optionswindow.lua:585`.
  - "Press a key" while waiting `Config/optionskeybinding.lua:154`.
  - Options item dots on hover `Config/optionsitem.lua:58`.
  - Feed filter button when lit/hovered `Loot/Feed/feed.lua:39`.
  - Rule editor "Not" box on `ruleeditor.lua:713`.
- **Links and actions**
  - All / Multiple links `optionsshare.lua:246,382`.
  - "Add" in the rule editor `ruleeditor.lua:530`.
  - Add and Reset buttons under the Categories list `categoriestab.lua:786`.
- **Label**
  - "Category: name" first line of a bag item tooltip `slot.lua:231`.
- **Identity (not accent)**
  - Tank role mark `indicators.lua:63`, `grouppreview.lua:295`.
  - Alliance on zone text and world map `ZoneText.lua:57`.

### `text.purple`. Zero property reads. Used only as the string `'purple'`.
- **Transmog on loot rolls**
  - Button letter `rollbar.lua:14`.
  - Counts `rollinfo.lua:77`.
  - Tooltip header `rolls.lua:41`.

### `text.cyan`. 3 sites. One role.
- **Shared across the account or warband**
  - Warbound item level `slot.lua:136`.
  - Account-wide currency count `SaftUI-Bags/currencies.lua:262`.
  - Warband bank slot count `containers/combinedbank.lua:131`.

### `text.white`. About 8 sites.
- Need on loot rolls: `rollbar.lua:15`, `rolls.lua:40`.
- Plain item levels and counts: `slot.lua:140`, `currencies.lua:264`, `SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua:70,118`.
- Bank purchase button text when affordable `bank.lua:165`.
- Neutral emphasis: "full-strength text", about the same as `normal` but pure white.

### `button.blue` (33 direct sites plus `Blue()`)
- **Accent for "active, selected, on, current" in `/sui`**
  - Sidebar active entry fill and bar `optionsnav.lua:112,129` via `Blue()`.
  - Tab underline `optionsnav.lua:239`.
  - List row hover fill at 25% `optionslist.lua:162,196`.
  - Search result hover `optionsbody.lua:827`.
  - Slider fill `optionsrange.lua:131`.
  - Check box mark `optionslook.lua:477`.
  - Hovered or focused field border `optionslook.lua:81`.
  - Picked position dot `optionsposition.lua:44`.
  - Reset icons and own mark `optionsshare.lua:141,148,247,380,502,712`.
  - Rule editor check mark `ruleeditor.lua:498`.
  - Rule editor AND group `ruleeditor.lua:94`.
  - Insertion line while dragging `dragparts.lua:119`.
  - Selected category row's tint, hover, bar `categoriestab.lua:516`.
- **Selected or current thing in the world**
  - Lit Bags header button border `SaftUI-Bags/header.lua:51`.
  - Selected bank window border `SaftUI-Bags/inventory.lua:84`.
  - Picked radio button border `SaftUI-Core/Widgets/radiogroup.lua:27`.
  - Selected mover fill and border `SaftUI-Core/EditMode/mover.lua:100`.
  - Grid centre lines `SaftUI-Core/EditMode/grid.lua:72`.
  - Current mover in the edit mode picker `picker.lua:117`.
  - Keybind mode highlight `SaftUI-ActionBars/keybindmode.lua:254`.
- **Hover highlight on game and skinned buttons**
  - Skinned buttons `SaftUI-Core/skinning.lua:266`.
  - Bag slot `containers/bag.lua:76`.
  - Action bar buttons `ActionBars/skin.lua:437`.
  - Totem buttons `totemskin.lua:296`.
  - Objective tracker item `Blizzard_ObjectiveTracker.lua:362`.
- **Progress and choice**
  - Bags loading bar `SaftUI-Bags/container.lua:85`.
  - Loot roll timer fill `roll.lua:225`, `rollbar.lua:195`.
  - Chosen roll's border `rollbar.lua:99` and label `:120`.

### `button.normal`, `button.hover`, `button.pushed`. Named by state, but the state is misdescribed.
- `button.normal` is the **hover highlight** on SaftUI buttons: `SaftUI-Core/Widgets/button.lua:253`, `checkbutton.lua:115`, `micromenuitems.lua:37`. It is also the **scroll bar thumb at rest** (`scrollbar.lua:6`). It is never the resting fill of a button.
- `button.hover` is a **checked check box fill** (`checkbutton.lua:109`), a **hovered scroll thumb** (`scrollbar.lua:6`), and the hover on minimap buttons (`micromenuitems.lua:97`, `expansionbutton.lua:51`, `queuebutton.lua:44`, `microbuttons.lua:181`). It also colours **resize handles** (`SaftUI-Core/skinning.lua:443,446`, `optionsresize.lua:174`).
- `button.pushed` is a pressed button, scroll thumb, or micro button (`button.lua:263`, `micromenuitems.lua:43`, `microbuttons.lua:123`, `scrollbar.lua:6`).

### `button.red`. 3 sites.
- Locked bank slot tint `containers/bank.lua:56`.
- Action button flash `ActionBars/skin.lua:441`.
- Totem button flash `totemskin.lua:304`.

### `button.green`. 1 site.
- Equipped item's action button border `ActionBars/skin.lua:482`.

### `button.yellow`. 1 site.
- Fresh mount entry in the loot feed, border and fill `Loot/Feed/feed.lua:141`.

### `button.grey`. 2 sites.
- Combined bank visibility toggle `containers/combinedbank.lua:51`.
- "Alt: next" hint line in the edit mode picker `picker.lua:124`.

## 3. Roles per entry, and does one name fit?

| Entry | Roles its uses fall into | One name fits? |
|---|---|---|
| `text.normal` | body text; icon at rest; hover emphasis | Yes: "text". Not a hue. |
| `text.grey` | muted/secondary text; disabled/inactive; resting icon; decoration; game meaning ("trivial level") | Yes: "muted". The "trivial level" use is the bottom of the severity ladder. |
| `text.red` | (a) error/danger (about 8); (b) urgency (timers); (c) destructive hover; (d) pass/decline; (e) identity: hostile, DPS, Horde, much higher level | **No, 3 or 4 roles share a hue:** `danger` covers a to c; d is a loot choice; e is identity (role, faction). |
| `text.orange` | caution/warning ladder (level, stats); "edited/yours" marker; OR operator | **Two or three:** warning (ladder); "edited"; decorative operator. |
| `text.yellow` | caution (mid ladder, unfriendly, alert flash, neutral, "Caught by"); Greed choice | Mostly `caution`, plus the Greed choice. |
| `text.green` | **"on"** (2 sites, contradicts decision 7); good/success; BoE/reagent markers; winner; healer role | **No:** success is one role; "on" belongs to the accent; healer is identity. |
| `text.blue` | accent (selected, active, lit, link, action, key-wait, found); a label ("Category:"); tank role; Alliance | **No:** accent, plus two identity uses that only happen to be blue. |
| `text.purple` | Transmog choice only | One name, but it names a loot choice, not a text role. |
| `text.cyan` | warband / account-wide / shared | Yes: "shared". |
| `text.white` | Need choice; plain full-strength numbers (item levels, counts) | Mostly one ("strong"); Need is a loot choice. |
| `button.blue` | accent for controls; selection/current; hover highlight; progress and timer fills; chosen roll | Yes: it **is** the accent. It duplicates `text.blue`'s accent role. |
| `button.normal/hover/pushed` | resting overlay, hover/checked/handles, pressed | State-named, but "normal" and "hover" are misnamed (see above). |
| `button.red` | locked slot; flash on attention | Yes: danger-ish fill. |
| `button.green` | "equipped" border | One use. Needs a design call, since "on = accent, never green". |
| `button.yellow` | new mount entry highlight | One use: "notable/new". |
| `button.grey` | muted icon; hint line | Yes: muted. Duplicates `text.grey` (identical default). |

**What this shows.** The Text group mixes four kinds of colour:
1. UI-state colours: accent, muted, danger, success, warning, caution, shared, strong.
2. A severity ladder used for game data: red / orange / yellow / green / grey for level tags, the stats gradient and hostile/neutral names.
3. Identity sets: tank/healer/dps, Alliance/Horde/Neutral, and Need/Greed/Transmog/Pass.
4. Plain text colours.

Category 2 and the identity sets are exactly where a player who changes "Red" away from red breaks the meaning.

## 4. Unused, used once, duplicated

**Unused.** None entirely, but:
- `text.purple` has no property read (string key only; one meaning).
- No code reads the alpha of any `button.*` colour, so the Buttons opacity sliders are dead (see part 1).

**Used once or twice.**
- `button.green`: `ActionBars/skin.lua:482`.
- `button.yellow`: `Loot/Feed/feed.lua:141`.
- `button.grey`: 2 sites.
- `button.red`: 3 sites.
- `text.yellow` also feeds Greed three times (one role).

**Duplicates by default and role.**
- `text.blue` and `button.blue`: the same RGB (0, 0.68, 0.94); `button.blue` adds alpha 0.8 that nothing reads. Same role: accent.
- `text.grey` and `button.grey`: both 150/255 grey.
- `text.red` and `button.red` and `threat.bad` (1, 0.1, 0.1): "five reds" (`docs/design-system/10-discrepancies.md:116-118`).
- `text.white` against `text.normal` (1, 1, 1 versus 0.9, 0.9, 0.8): nearly the same role, plain text.
- `text.cyan` against the hardcoded `OB.OWN_TEXT` (0.56, 0.85, 1): two light blues.
- `text.orange` against the hardcoded `OB.DIFF_COLOR` (0.88, 0.63, 0.25): two oranges, and `diff` and "edited" mean the same thing.
- `button.hover` (0.3, 0.5, 0.7) is a bluer accent in practice. Different role from `button.blue`.

## 5. Hardcoded colours a named entry should supply

| Where | What | Should be |
|---|---|---|
| `SaftUI-Core/api.lua:122` | `"|cff00adefSaftUI|r"` chat prefix, #00adef (profile accent is #00adf0) | accent, read at print time |
| `SaftUI-Core/api.lua:129` | `|cFFFF0000Error|r` pure red | `danger` |
| `SaftUI-Core/api.lua:136` | `text.red` for the "DEBUG" label | already named, but `text.red` |
| `SaftUI-Core/Config/optionsbody.lua:199` | `OB.OWN_TEXT = {0.56, 0.85, 1}` | own marks (own label, own section title, own tooltip line `optionsshare.lua:182,379,515,586`) |
| `SaftUI-Core/Config/optionsbody.lua:200` | `OB.DIFF_COLOR = {0.88, 0.63, 0.25}` | the diff icon `optionsshare.lua:526,593` |
| `SaftUI-Core/Config/optionsshare.lua:241` | hover icon/text `1, 1, 1` | strong/hover text |
| `SaftUI-Core/Config/optionsposition.lua:35` | `DOT_GREY = {0.333, ...}` | muted |
| `SaftUI-Core/Config/optionstypes.lua:174` | `CODE_COLOR = {1, 1, 1}` | text |
| `SaftUI-Core/Config/optionswindow.lua:150` | `SIDEBAR_BG = {0.09, ...}` | not role text; surface |
| `SaftUI-Core/Config/optionsbody.lua:206` | `OB.LINE = {0.18, ...}` | not role text; surface |
| `SaftUI-Core/panels.lua:361` | close hover fill `0.5, 0.1, 0.1, 0.4` (duplicates `defaults.templates.close.backdropcolor`) | `danger` at alpha, or read from `templates.close` |
| `SaftUI-Core/Dev/fontdemo.lua:71-72,355,362,381,411,574` | dev tool: GREEN, `LIT = {0, 0.68, 0.94}`, `|cff00adef`, red 1, 0.3, 0.3 | accent, danger, success (dev only, low priority) |
| `SaftUI-Loot/rollbar.lua:206`, `roll.lua:230` | `(1, 1, 1)` timer text over 60s | strong |
| `SaftUI-Misc/Skinning/blizzard/ZoneText.lua:10-15` | difficulty colour hex strings (`68de57`, `ffeac2`, `5794de`, `a357de`): green, white, blue, purple | game category colours, no entry |
| `SaftUI-ActionBars/skin.lua:225-226` | range `0.8, 0.1, 0.1` red; mana `0.5, 0.5, 1.0` blue (action bar config) | `danger` (range) |
| `SaftUI-Misc/Skinning/blizzard/Blizzard_CooldownViewer.lua:86` | `BAR_COLOR = {1, 0.5, 0.25}` orange | a third orange |
| `SaftUI-Minimap/instancedifficulty.lua:23` | `0.66, 0.40, 0.72` | difficulty badge |
| `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFrame.lua:36` | `TEMP_ENCHANT_COLOR` purple | an aura category |

Existing violations of "on is the accent, never green": `SaftUI-Core/EditMode/settings.lua:22` and `Config/optionsnav.lua:52`.

## 6. Proposed role names

### Principles
- **Accent is a theme colour.** It lives in the Theme section, not in `colors.text` or `colors.button`. `text.blue` and `button.blue` both fold into it; the 0.25 and 0.15 fills (`accent-fill`, `accent-tint`) stay derived in code.
- **"On" is the accent.** `text.green`'s two on/active uses (`EditMode/settings.lua:22`, `optionsnav.lua:52`) move to accent.
- **State colours stay a small set.** Keep one ladder of status roles for game data too, so the level tag, the stats gradient and the hostile/neutral names reuse it.
- **Identity sets get their own small groups,** so changing the state palette doesn't recolour tank/healer/DPS or Alliance/Horde. Roles and a loot-choice group are the natural ones; roles are already a planned Colors tab section (`docs/followups.md`, "Colors tab: role and rune colors").

### The set (about 11 names plus two identity groups)

**Theme (not on the Colors page).**
- `accent`: replaces `text.blue` accent uses and `button.blue`.

**Text (`colors.text`).**
- `normal` -> **`text`** (not a hue, keep or rename to match).
- `grey` -> **`muted`**.
- `white` -> **`strong`** (full-strength numbers and icons). Optional: fold into `text` and drop one entry.
- `red` -> **`danger`**.
- `orange` -> **`warning`**.
- `yellow` -> **`caution`**.
- `green` -> **`success`**.
- `cyan` -> **`shared`**.
- New: **`own`** (replaces `OB.OWN_TEXT`) and **`edited`** (replaces `OB.DIFF_COLOR` and the "yours/edited" marker, so the two oranges become one). If `own` and `shared` should be one light blue, name it `accentSoft`; they mean different things (this bar's own setting versus account-wide), so keep them apart unless the owner prefers to merge.

**Identity groups (new, small).**
- `roll`: `need`, `greed`, `transmog`, `pass`. Replaces `white` (Need), `yellow` (Greed), `purple` (Transmog) and `red` (Pass) in `rollbar.lua:12-15`, `rollinfo.lua:77-78`, `Loot/Feed/rolls.lua:40-42,127,165,196` and the roll-text read at `roll.lua:89`.
- `faction`: `alliance`, `horde`, `neutral`. Replaces `ZoneText.lua:57`.
- `roles` (already planned): `tank`, `healer`, `damage`. Replaces `indicators.lua:61-65`, `grouppreview.lua:293-297`.

**Buttons (`colors.button`).**
- `normal` -> **`fill`** (what it actually is: the overlay or thumb at rest).
- `hover` -> **`hover`** and a new **`checked`** (the check box fill is the one real split in this group).
- `pushed` -> **`pressed`**.
- `blue` -> `accent` (above).
- `red` -> `danger` (alpha applied in code).
- `green` -> **design call:** "equipped" is a state marker. Decision 7 argues for the accent, but that same button already uses accent for hover. Safest is `success`, or a one-off `equipped`.
- `yellow` -> `caution`, or a one-off `notable`.
- `grey` -> `muted`.

### Mapping table (old -> new)

| Old | New | Notes |
|---|---|---|
| `text.normal` | `text.text` (or keep `normal`) | |
| `text.grey` | `text.muted` | `button.grey` merges here |
| `text.red` | `text.danger` | split: Pass -> `roll.pass`; DPS -> `roles.damage`; Horde -> `faction.horde`; hostile names/higher level stay `danger` |
| `text.orange` | `text.warning` | split: OR operator and "edited" marker -> `edited` (or `warning`); `OB.DIFF_COLOR` merges here |
| `text.yellow` | `text.caution` | split: Greed -> `roll.greed`; Neutral -> `faction.neutral` |
| `text.green` | `text.success` | split: on/active -> accent; healer -> `roles.healer`; BoE/reagent markers stay `success` |
| `text.blue` | accent | split: tank -> `roles.tank`; Alliance -> `faction.alliance` |
| `text.purple` | `roll.transmog` | |
| `text.cyan` | `text.shared` | `OB.OWN_TEXT` -> new `own` |
| `text.white` | `text.strong` | split: Need -> `roll.need` |
| `button.blue` | accent | |
| `button.normal` | `button.fill` | rename; note actual use is the hover overlay |
| `button.hover` | `button.hover` + `button.checked` | split |
| `button.pushed` | `button.pressed` | |
| `button.red` | `danger` | |
| `button.green` | `success` or a one-off | design call |
| `button.yellow` | `caution` or `notable` | |
| `button.grey` | `muted` | |

**Name clash to watch.** `threat.warning` and `threat.bad` already exist. A new `warning` role in `text` would sit beside `threat.warning`, so either keep them in different tables or name the threat ones `threat.pull` / `threat.holding`.

## 7. What a rename would touch

### Code
- About **58 non-test source files** across 7 of the 8 addons (Chat has none). About **200 call sites**: ~130 direct reads, ~47 helper-wrapped, ~21 alias reads, plus the string-keyed uses in `rollbar`, `rolls`, `rollinfo`, `ZoneText`, `bank`.
- A pure hue-to-role rename of the keys is mechanical. The splits (accent, red, orange, yellow, green, white) need a decision per site, listed in part 2. They touch roughly 40 sites.
- Comments and the Colors descriptions that say "Text > Blue", "Buttons > Blue": about 14 files.
- `OnColorsChanged` consumers that test the group names `'text'` and `'button'` (`header.lua:230-231`, `slot.lua:106`, `roll.lua:587`, `feed.lua:167`, `ZoneText.lua:290`) must still get the right group if tables move. 13 modules define `OnColorsChanged`.

### Saved profiles and migration
- Colours save as `SaftUI_DB.profiles.<name>.colors.text.<hue>` and `.colors.button.<hue>`: plain `{r, g, b, a}` tables. AceDB stores only values that differ from `st.defaults`, so only players who changed a swatch have these keys.
- **Today's migration** is `st:MigrateTemplateKeys` (`SaftUI-Core/theme.lua:167`). It only rewrites keys ending `template` that hold a string, into Theme/Background. It is idempotent, walks raw saved data with `pairs`, and is called from three places:
  - login: `Config/config.lua:84`;
  - `Config:UpdateConfig` (every profile change, copy or reset): `config.lua:254`;
  - `Config:Import`: `config.lua:61`.
  There is **no profile version number** and **no migration of colour keys**. Nothing like it exists for the colours.
- A colour rename needs a sibling, for example `st:MigrateColorKeys(profile)`, run at the same three sites, idempotent, and a no-op when the old key is absent. Details:
  - **Splits:** copy the old value to every successor, so the player's look is preserved. Example: a changed `text.red` goes to `danger`, `roll.pass`, `roles.damage` and `faction.horde`.
  - **Merges:** `text.blue` and `button.blue` both become the theme accent. Pick one, say `button.blue` first, since the accent colour is the control colour.
  - **Write into the existing table** with `c.r, c.g, c.b, c.a = ...` (as `ColorDefault` does at `colors.lua:200`) rather than assigning a plain table, because the colour object's `:GetRGB()` comes from the default object.
  - **Exported strings:** old exports reach the migration through `Config:Import`; copy and reset reach it through `UpdateConfig`.
  - **Defaults:** `st.defaults.colors` and the colour tab's `defaults` lookup must be renamed in lockstep; `DefaultColor` (`colors.lua:175`) fails on a missing default.

### Colors page labels and tests
- Labels are the second element of each row in `colors.lua:49-58` and `:64-71`, plus each `desc`. If the entries are renamed, the Text section reads Text, Muted, Danger, Warning, Caution, Success, Shared, Strong. The Buttons section loses Blue, Red, Green, Yellow, Grey and gains Checked (names as in part 6).
- Tests that pin the old keys: **44 test files, about 105 lines** read `colors.text.*` or `colors.button.*`.
  - `tests/core/colors_test.lua:62-63` pins the expected tab names and order.
  - `colors_test.lua:174,216` read `Section('button').args.blue` and the faction keys `blue/red/yellow`.
  - `tests/core/options_default_test.lua:245,412`.
  - `tests/core/options_body_test.lua:814`.
  - `tests/core/theme_core_frames_test.lua:150,367,553`.
  - `tests/core/theme_blizzard_editmode_test.lua:149`.
  - `tests/bags/theme_test.lua:649`.
  - The Loot, Misc and Unitframes tests under `tests/` also read these keys.
- Docs that mention the entries: `docs/design-system/10-discrepancies.md` (#26), `30-code-changes.md` (section 9, section 11), `tokens.json` (the "accent" token), `05-decisions.md` (decisions 7 and 14), `.agents/*.md` and `AGENTS.md`.

### Suggested order
1. Land the accent as a theme colour and the three identity groups first. They remove the splits.
2. Rename what's left mechanically.
3. Add `st:MigrateColorKeys` and its test in the same change as the key rename.
4. Update the Colors page labels last. Update `docs/design-system/tokens.json` and decision 14 to match.
