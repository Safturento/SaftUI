# Colors named for their roles

Design, 2026-11-14. A draft for the owner to approve. It builds the proposal and audit in
`docs/design-system/25-colour-roles.md` (the audit, below) with the owner's seven answers recorded there,
and design-system decisions 7, 14 and 48. Every decision below that the owner didn't make is marked
**call** and listed again at the end, under "Calls made while writing this".

Checked against SaftUI's code on `modular` at `48c2a67`. Line numbers are that commit's. The audit was
written the evening before (2026-11-13), and the repo has moved since: "Where the audit is out of date"
lists what changed.

Words used below:

- **Role**: one color on the Colors page, named for what it is for (Danger, Muted), not its hue.
- **Group**: a section of the Colors page and its table in the profile (`colors.text`, `colors.loot`).
- **Reader**: a line of code that draws something in a role's color.
- **Strength**: the alpha a reader draws a color at, which it owns (a flash at 0.4, a row tint at 0.25).

## Why

The Colors page (Global settings > Colors) lets the player change colors named after a hue: Text > Blue,
Red, Green and the rest, and Buttons > Red, Green, Blue, Yellow, Grey. Once changed, Red needn't be red,
and one swatch recolors things that only share a hue: Text > Red is an error line, a loot roll's Pass,
a DPS role mark and Horde on the zone text. The owner (decision 14): "maybe we should analyze how those
specific entries are being used and consider renaming them accordingly? let the user decide what color
truly belongs to that type of text." And, on the audit: "yep this is exactly why I wanted the research,
we can establish better groups to change certain things without messing other things up".

## What the owner decided

His answers of 2026-11-14 (the audit, "The owner's answers"), binding here:

1. **The role names.** Text, Muted (was Grey), Strong (was White), Danger (Red), Warning (Orange),
   Caution (Yellow), Success (Green), Shared (Cyan). "yep this is good"
2. **Blue becomes the theme's accent.** Text > Blue and Buttons > Blue leave the Colors page for one
   accent swatch in the Theme section. "sounds good, if there's something that's using blue that isn't
   a "theme" coloring let me know and we can address what to shift them to". The list is under "Blue that
   isn't theme coloring", and its open items are Questions 1 to 4.
3. **Loot rolls, factions and roles get groups of their own**, not tied to the state colors.
4. **No new Own and Edited colors.** "maybe the yellow diff marker can just become muted, and the blue
   highlight we can make the accent color? we can play with individual opacity for those highlights if
   needed"
5. **The equipped item's border on action buttons is the accent.** "lets go with accent color for now"
6. **The Buttons section's opacity sliders are made to work.** "lets make opacity work"
7. **Strong stays apart from Text.** "lets keep them separate, if we want to make the text a muter color
   like eggshell or light gray it might look weird for certain elements that should really be white"

Earlier decisions that bind (`docs/design-system/05-decisions.md`): 7 ("On" is the accent, never green;
the accent is a theme color with its own swatch in the Theme section), 10 (resets are per setting, no
section Reset buttons), 20 (sentence case), 21 (the docs and the UI spell it "color"), 23 (under the
Blizzard theme the rule editor's AND and OR, the own mark and the diff icon keep SaftUI's colors), 29
(25% for a hovered or selected row, 15% for a selected object's fill).

## Goals

- Every color on the Colors page named for what it is for. No hue name left on the page, in a profile
  key of these groups, or in the code that reads them.
- Blue gone from the Colors page: one Accent swatch in Global settings > Theme.
- Loot, Factions and Roles as groups of their own, so changing Danger recolors no Pass, Horde or DPS mark.
- Nothing a player sees changes on the update, at SaftUI's defaults or with their own colors, except the
  short list under "What a player sees change".
- A player's customized colors carried into the new roles, on every profile, the first time each is used.
- The Buttons section's opacity drawn wherever its colors are.
- One way for code to reach a role, pinned by a test, so a hue name can't come back.

## Non-goals

- Remapping what Buttons > Normal and Hover color (code changes 9: Normal is a hover highlight and the
  thumb at rest; Hover is a checked box, a minimap hover and the resize handles). Their keys, labels and
  readers stay; only their opacity starts to work.
- Live Text and Buttons colors. As today (the Colors tab spec's non-goal), most readers set a color when
  they build a frame, and the sections say to reload.
- The groups that already name a game concept: Class, Reputation and Renown, Power, Item quality, Status,
  Threat, Objectives. Their keys, labels and readers are untouched.
- The options kit's surface colors (`st.BOX_COLORS`, `SIDEBAR_BG`, `OB.LINE`, `DOT_GREY`): they belong to
  the tokens table (code changes 1).
- An accent per theme, death knight rune colors, a switch for Blizzard's class colors (the followup
  "Colors tab: role and rune colors").
- Going back to an older SaftUI with a migrated profile (a downgrade). An older build reads the new keys
  as missing and draws its own defaults.

## Anti-goals

What would make this a failure even if it works:

- **A player's customized color lost**, other than the two dropped on purpose (Buttons > Green and
  Buttons > Grey, under "What happens to a player's colors").
- **A look change at the defaults that this document doesn't list.**
- **A Lua error in game from a stale hue key**, such as a string key `'blue'` left in a table of data
  that the accessor no longer knows.
- **A color object losing its methods**: a migrated color written as a new plain table into the active
  profile, so `:GetRGB()` errors.
- **Taint or a combat block.** Nothing here hooks Blizzard code or touches a protected frame in a new way;
  the migration is table writes only.

## Where the audit is out of date

Checked against the code at `48c2a67`. The audit's design reasoning stands; these facts changed or were
wrong:

1. **Line numbers have moved nearly everywhere** (for example `colors.lua`'s `ProfileColor` is now at
   176, the `:GetRGBA()` at 228; `defaults.lua`'s colors at 118 to 223; `api.lua`'s chat prefix at 207,
   the Error at 214, DEBUG at 221; `OB.OWN_TEXT` and `OB.DIFF_COLOR` at `optionsbody.lua:228-229`;
   the picker's hint line at `picker.lua:128`; the Categories' + New category and Reset all at
   `categoriestab.lua:1002`).
2. **There are no "on is green" uses left.** `EditMode/settings.lua:22` and `optionsnav.lua:52` no longer
   read green: edit mode's footer moved to the bar, whose toggles and the sidebar's Edit mode button are
   lit by `W.SetOn` in the accent. Text > Green's description still says "edit mode being on".
3. **The action buttons' hover isn't the accent any more.** Decision 30 dimmed it to white at 15%
   (`SaftUI-ActionBars/skin.lua:59,441`). So the audit's Question 5 premise ("hover on the same button is
   already accent") no longer holds, which suits the owner's answer: the equipped border in the accent
   is now the only accent on an action button.
4. **The rule editor's orange row tint is the Caught now highlight**, not the OR operator's
   (`SaftUI-Bags/ruleeditor.lua:824`, shown by `SetHighlight` when a Caught now icon is under the mouse).
5. **`CODE_COLOR` (`optionstypes.lua:174`) is gone.** The color field draws its code in Text (decision 13).
6. **The objective colors are a group of their own already**: Global settings > Colors > Objectives
   (`colors.objectives.completed` and `.failed`), moved from the skin's `status_colors` by
   `OTP:MoveStatusColors` with its `colorsMoved` marker. It is the precedent for the groups here. The
   audit's "Objective tracker has `Profile().colors`" predates it.
7. **New readers the audit doesn't list.** SaftUI-Tracker (`rows.lua:110-160`, `window.lua:54,108,489`:
   Text, Grey, the accent for its focus bar, row hover, current-zone pin and popup bar and label, plus a
   hardcoded white and Blizzard's progress blue); the durability tooltip (`SaftUI-Misc/durabilitytooltip.lua:54-57`:
   Green, Orange, Red); edit mode's bar (`barchanges.lua:125` Red for a refusal, `bardock.lua:294` the
   hide strip, `historylist.lua:196,199`), the snap guide (`snap.lua:250`), the Coordinates label
   (`coordinates.lua:205`), the page list's arrow (`optionsnav.lua:748`), the skin of Blizzard's color
   picker (`Blizzard_ColorPicker.lua:334`).
8. **The counts.** Buttons > Blue has 37 direct reads (plus `OB.Blue` at 8 more), Text > Blue 9 (plus
   `LinkBlue` and `slot.lua`'s alias). Tests: 55 files and about 165 lines read `colors.text` or
   `colors.button`, not 44 and 105. 16 modules define `OnColorsChanged`, not 13. The Colors page has 9
   sections now (Objectives is the ninth), which `tests/core/colors_test.lua:57` pins.
9. **Saved colors hold only the channels that differ.** AceDB saves only values unlike their default, so
   a customized Text > Red can be saved as `{ r = 1 }` alone. The audit's migration copies "the old
   value", but once a key's default is gone its missing channels must come from the old default: the
   migration needs a frozen table of them, as `OTP.OLD_STATUS_COLORS` is.
10. **`Config:Import` carries no colors.** Its only caller is the unit frames' profile import
    (`SaftUI-Unitframes/config/profiles.lua:140`), whose data is a layout. The audit's "old exports reach
    the migration through `Config:Import`" doesn't apply.
11. **The color field's toggle** (`toggle` on a `color` option, new since the audit) changes nothing here:
    no Colors page row has one. The unit frames' new Text color rows are per unit, not roles.
12. **`UF:UpdateColors` already points oUF at `colors.roles`** (`SaftUI-Unitframes/unitframes.lua:221`),
    falling back to oUF's, which this oUF doesn't have; nothing in the bundled oUF reads it.

## The Colors page and the Theme tab

**Global settings > Colors**, sections in this order (**call** for the order: each new group sits after
the one it is nearest, Roles after Class, Factions after Reputation, Loot after Item quality):

| Section | Profile key | Colors, in order | Opacity |
| ------- | ----------- | ---------------- | ------- |
| Text | `colors.text` | Text, Muted, Strong, Danger, Warning, Caution, Success, Shared | no |
| Buttons | `colors.button` | Normal, Hover, Pushed, Danger | yes |
| Class | `colors.class` | unchanged | no |
| Roles | `colors.roles` | Tank, Healer, Damage | no |
| Reputation | `colors.reaction`, `colors.renown` | unchanged | no |
| Factions | `colors.factions` | Alliance, Horde, Neutral | no |
| Power | `colors.power` | unchanged | no |
| Item quality | `colors.item_quality` | unchanged | no |
| Loot | `colors.loot` | Need, Greed, Transmog, Pass, Mount | no |
| Status | `colors.status` | unchanged | no |
| Threat | `colors.threat` | unchanged (Warning, Bad) | no |
| Objectives | `colors.objectives` | unchanged | no |

The Text order is the owner's own list. Text, Buttons, Roles, Factions and Loot carry today's note, "Most
of SaftUI reads these when it builds its frames: reload (Reload UI, bottom right) to see a change
everywhere." (**call**: the new sections' readers are today's Text readers, which mostly set a color once.)
The Buttons note adds one sentence on opacity (below). Every row keeps its own reset and a description
naming what it colors, written from the table under "What each role colors". Threat's Warning and Bad keep
their names (**call**): the page then shows a Warning under Text and one under Threat, each under its
section's title.

**Global settings > Theme** gains **Accent**, after Background and before Options windows: Theme,
Border, Outer border, Window background, Background, Accent, Options windows (**call**). One color for
every theme (Thick, Thin and Blizzard), no opacity, its own reset, and a description that says it is
SaftUI's accent under every theme and, like Text, takes a reload to show everywhere.

### What each role colors

Defaults are today's, so nothing changes color at the defaults unless listed under "What a player sees
change". "From" names what the role takes its place and its saved color from.

**Text** (`colors.text`)

| Label | Key | From | Default | What it colors |
| ----- | --- | ---- | ------- | -------------- |
| Text | `normal` | Text (key unchanged, **call**: its label is already Text) | 0.9, 0.9, 0.8 | Ordinary text: the options window and its widgets, totem timers, the summon arrow, the zone line, an enemy plate's threat text while it's fine, the trackers' titles, the bags' header glyphs, the feed's icons at rest. |
| Muted | `muted` | Grey; Buttons > Grey; the diff icon; the bag category's marker | 150, 150, 150 | Hints, captions, section titles, disabled and inactive text, resting icons and dots, the unbound key, a far lower level's tag, the combined bank's eye toggle, edit mode's picker hint line, the diff icon (answer 4), the bag category's "edited" and "yours" marker (**call**, with the diff icon). |
| Strong | `strong` | White | 1, 1, 1 | Plain item levels and counts in bags and on the character frame, the bank purchase price you can afford. Folded in: the share line's links and icons under the mouse, loot roll timer text over a minute, the tracker's progress percent and a chevron under the mouse. |
| Danger | `danger` | Red | 220, 100, 100 | Errors and refusals (status lines, why a row is disabled, the edit mode bar's refusal, the bank's combat line and a price you can't afford), the chat's DEBUG label and Error prefix, urgency (loot roll timers under a minute, expiring totems), destructive hover (the close button, remove icons), a much higher level's tag, hostile names, a durability under 20%. |
| Warning | `warning` | Orange | 220, 150, 100 | A somewhat higher level's tag, the poor end of the micro menu's stats, a durability from 20% to 49%, the rule editor's OR groups and its Caught now highlight (**call**: both keep their look). |
| Caution | `caution` | Yellow | 200, 200, 100 | A level near yours, unfriendly names, the middle of the stats, the micro menu's alert flash, "Caught by:" in a bag item's tooltip. |
| Success | `success` | Green | 60, 240, 60 | Bind on Equip item levels, the reagent marker and count, the good end of the stats, a lower level's tag, the winner's roll in the loot tooltip, a durability from 50%. |
| Shared | `shared` | Cyan | 120, 202, 250 | Warbound item levels, account-wide currency counts, the warband bank's count. |

**Buttons** (`colors.button`, with opacity)

| Label | Key | From | Default | What it colors |
| ----- | --- | ---- | ------- | -------------- |
| Normal | `normal` | unchanged | 0.1, 0.1, 0.1, 100% (was 60%, never drawn) | The highlight under the mouse on SaftUI's buttons, check boxes and micro menu items; a scroll bar thumb at rest. |
| Hover | `hover` | unchanged | 0.3, 0.5, 0.7, 100% (was 80%) | A checked check box, a hovered thumb, the minimap's and micro menu's button hover, resize handles. |
| Pushed | `pushed` | unchanged | 0.3, 0.4, 0.5, 100% (was 80%) | A pressed button, thumb or micro button. |
| Danger | `danger` | Red | 0.6, 0.1, 0.1, 100% (was 80%) | An unbought bank slot's tint, the flash on an action or totem button. |

Buttons > Danger stays apart from Text > Danger (**call**): it is a darker red made to be drawn as a fill
over an icon, and keeping it apart means a brighter Danger text recolors no flash. Buttons > Green, Blue,
Yellow and Grey leave the section (the accent, Loot > Mount, Text > Muted).

**Roles** (`colors.roles`, keyed by the game's role tokens, as Class and Power are, **call**)

| Label | Key | From | Default | What it colors |
| ----- | --- | ---- | ------- | -------------- |
| Tank | `TANK` | Text > Blue | 0, 0.68, 0.94 | The role corner on unit frames (`elements/indicators.lua:63`) and in the group test previews (`grouppreview.lua:296`). |
| Healer | `HEALER` | Text > Green | 60, 240, 60 | The same, for healers (`indicators.lua:61`, `grouppreview.lua:294`). |
| Damage | `DAMAGER` | Text > Red | 220, 100, 100 | The same, for damage, shown with Show DPS (`indicators.lua:65`, `grouppreview.lua:298`). |

**Factions** (`colors.factions`, keyed by the words the zone text already uses, `Alliance`, `Horde`,
`Neutral`, **call**): who holds a zone, on the zone text and the world map's zone line
(`SaftUI-Misc/Skinning/blizzard/ZoneText.lua:57,90`). Defaults from Text > Blue, Red and Yellow.

**Loot** (`colors.loot`, **call**: named Loot, since it also holds the feed's mount entry)

| Label | Key | From | Default | What it colors |
| ----- | --- | ---- | ------- | -------------- |
| Need | `need` | Text > White | 1, 1, 1 | The Need button's letter (`rollbar.lua:15`), Need in the feed's roll tooltip (`Feed/rolls.lua:40`). |
| Greed | `greed` | Text > Yellow | 200, 200, 100 | Greed's letter, its counts and its tooltip line (`rollbar.lua:13`, `rollinfo.lua:78`, `Feed/rolls.lua:42`). |
| Transmog | `transmog` | Text > Purple | 197, 128, 255 | Transmog's letter, counts and tooltip line (`rollbar.lua:14`, `rollinfo.lua:77`, `Feed/rolls.lua:41`). |
| Pass | `pass` | Text > Red | 220, 100, 100 | Pass's letter, "All passed" and "Pass:" in the feed (`rollbar.lua:12`, `Feed/rolls.lua:127,165,196`). |
| Mount | `mount` | Buttons > Yellow | 0.6, 0.6, 0.1 | A mount's entry in the loot feed: its border, its fill at 60% and its icon's border (`Feed/feed.lua:141-150`). |

**Theme > Accent** (`theme.accent`, a color object like the Colors page's, `CreateColor(0, 0.68, 0.94)`,
the #00adf0 both blues share today). It takes the place of Buttons > Blue, of Text > Blue where Text > Blue
was the accent, of Buttons > Green (the equipped border, answer 5), of the own marks' light blue
`OB.OWN_TEXT` (answer 4), and of the chat prefix's hardcoded `|cff00adef`.

### What a player sees change

At SaftUI's defaults, after the update:

- A shared setting's own label, own section title, the hover line's Own and the diff tooltip's per-page
  values: light blue (0.56, 0.85, 1) to the accent (answer 4).
- The diff icon: orange (0.88, 0.63, 0.25) to Muted grey (answer 4). The bag category's "edited" and
  "yours" marker: orange to Muted (**call**).
- The equipped item's border on action buttons: green to the accent (answer 5).
- The chat's Error prefix: pure red to Danger (**call**, discrepancy 26's "text-red for every error").
- The chat's SaftUI prefix: #00adef to #00adf0 (one step of blue, not visible).
- Whatever the owner's answers to Questions 1 to 4 move.

Nothing else. Every other reader keeps its color and strength.

## Keys, and the migration

### The keys change

**Call: the keys are renamed, with a migration, not only the labels.** The splits need new keys anyway
(Loot, Factions, Roles and the accent can't be the old ones), so a migration is needed either way, and a
key that still said `red` for Danger would mislead every reader of the code and its tests: the work is to
stop the hue lying, and the code is where it lies most. The extra cost over a labels-only change is the
mechanical rename of the remaining keys, which the scan test (below) makes safe.

New keys: `colors.text.muted`, `strong`, `danger`, `warning`, `caution`, `success`, `shared` (`normal`
stays); `colors.button.danger` (`normal`, `hover`, `pushed` stay); `colors.roles.TANK`, `HEALER`,
`DAMAGER`; `colors.factions.Alliance`, `Horde`, `Neutral`; `colors.loot.need`, `greed`, `transmog`,
`pass`, `mount`; `theme.accent`. Gone: `colors.text.grey`, `white`, `red`, `orange`, `yellow`, `green`,
`blue`, `purple`, `cyan`; `colors.button.red`, `green`, `blue`, `yellow`, `grey`.

### The migration

`st:MigrateColors(profile)`, in `SaftUI-Core/Media/colors.lua`, a sibling of `st:MigrateTemplateKeys`.

**Where it runs.** Wherever saved colors enter use: on `st.config.profile` right after
`st:MigrateTemplateKeys` at login (`Config:InitializeAceConfig`, `config.lua:88`), and right after it at
the start of every `Config:UpdateConfig` (`config.lua:266`: a profile switched to, copied from or reset).
Not in `Config:Import` (**call**): it carries only unit frame layouts, and the migration must not write a
`colors` table into one. A table with no `colors` table is left alone.

**A version.** `colors.version` (no default, a number), inside `colors` so a profile copy carries it and a
reset clears it, as `actionbars.version` and `categories.version` do. Each phase adds one numbered step.
`st:MigrateColors` runs, in order, every step whose number is above `colors.version or 0`, then sets
`colors.version` to the last step's number. So a profile saved before any phase runs every step at once,
in order; a migrated one runs none. Table writes only: it runs in combat too.

**The old defaults.** A frozen table in the same file, `OLD_COLORS`, of every retired key's shipped value
(today's `st.defaults.colors.text.*` and `button.*`, alpha included). AceDB saves only the channels that
differ from a default, so a saved color can lack some; once its default is gone, they come from here.

**Reading a source.** A source is an old key's table in `profile.colors`. Its color is its saved channels
over `OLD_COLORS`' value. A source that is absent, or whose color equals its old value (each channel as a
whole 0 to 255, as the Colors page compares), counts as not customized: nothing is copied from it, and its
destinations keep their own defaults. (While an old key still has a default, the active profile holds the
full color; a source at its default copies nothing, so this is the same rule.)

**Writing a destination.** Copy `r`, `g` and `b` (never `a`, which no destination takes from a source)
into the destination's table **in place** (`c.r, c.g, c.b = ...`, as `ColorDefault` resets): in the active
profile AceDB has filled it from the defaults, methods included, and a new table would have no `:GetRGB()`.
In a table AceDB hasn't filled (a stored profile's raw data), create the destination table, and its group,
only when absent. Never set a channel to nil in the active profile: write the default's value instead.

**Retiring a key.** A step that retires a key sets `profile.colors.<group>.<key> = nil` after copying it.
A key is retired in the same phase its default is removed.

**The steps**, one per code phase:

| Step | Phase | Copies | Retires |
| ---- | ----- | ------ | ------- |
| 1 | Groups of their own | `text.white` to `loot.need`; `text.yellow` to `loot.greed` and `factions.Neutral`; `text.purple` to `loot.transmog`; `text.red` to `loot.pass`, `roles.DAMAGER` and `factions.Horde`; `text.green` to `roles.HEALER`; `text.blue` to `roles.TANK` and `factions.Alliance`; `button.yellow` to `loot.mount` | `text.purple`, `button.yellow` |
| 2 | The accent | `button.blue` to `theme.accent` | `button.blue`, `text.blue`, `button.green` |
| 3 | Muted | `text.grey` to `text.muted` | `text.grey`, `button.grey` |
| 4 | The state colors | `text.white` to `text.strong`, `red` to `danger`, `orange` to `warning`, `yellow` to `caution`, `green` to `success`, `cyan` to `shared`; `button.red` to `button.danger` | each of those seven |
| 5 | Opacity | the alpha of `button.normal`, `hover`, `pushed` and `danger` set to the default's (100%) | none |

### What happens to a player's colors

- **A customized color keeps its look** in every role it fed. A changed Text > Red is the player's Danger,
  Pass, Damage and Horde; a changed Text > Yellow their Caution, Greed and Neutral; a changed Text > Blue
  their Tank and Alliance; a changed Buttons > Blue their accent; and so on through the steps.
- **The accent takes Buttons > Blue only** (**call**). Buttons > Blue paints 45 of the accent's places,
  Text > Blue 9 (selected rows, links, the found label). A player who changed only Text > Blue keeps it on
  Tank and Alliance, and their selected rows and links take the accent their controls already showed; the
  other way would recolor every control they never changed.
- **Dropped on purpose:** a customized Buttons > Green (its one use, the equipped border, becomes the
  accent by the owner's answer 5) and a customized Buttons > Grey (its two uses become Text > Muted, which
  takes Text > Grey's; **call**: Muted colors about 50 places, Buttons > Grey two).
- **Opacity:** every saved opacity on Buttons goes back to 100%, the strength each was drawn at (none was
  ever drawn); from then on the slider works.
- **Profiles on other characters**, and every profile in the saved file, migrate the first time they are
  used: at the login of a character on that profile, or when a player switches to it, copies from it
  (AceDB copies the source's saved data, `colors.version` with it, then `UpdateConfig` runs), or resets it
  (a reset profile runs every step on nothing and gets the version). A profile no character uses stays in
  the file unmigrated; nothing reads its old keys, and it migrates if it is ever used.

## How code reaches a role

**One accessor** (**call**), in `SaftUI-Core/Media/colors.lua` beside `st:ColorsChanged`:

```lua
st:Color(group, key)                 -- the color object: st.config.profile.colors[group][key]
st:Color('accent')                   -- the accent: st.config.profile.theme.accent
st:ColorRGBA(group, key, strength)   -- r, g, b, (strength or 1) * (the color's a or 1)
```

- Read at call time, so a profile switch reaches the new profile's table; never cached across a change.
- Before `st.config` exists (a `st:Print` at load) it reads `st.defaults`.
- A group or key with no default is an error naming it (`"SaftUI: no color text.blue"`), so a stale hue
  key, string-keyed data included (`FACTION_COLORS`, the roll buttons' `color`, `CHOICES`, `PAIRED`,
  `text[tooExpensive and 'red' or 'white']`), fails the tests rather than drawing nothing.
- A nil alpha counts as 1 (`CreateColor` itself gives `a` 1 when none is passed, in game and in the stubs; the bare `{ r, g, b }` tables the migration makes have none).
- It returns the object, so readers that need one (`curve:AddPoint(0, color)`, `.r` reads, `ColorEscape`,
  `ColorCode`) still get one.

Every read of a Text, Buttons, Roles, Factions or Loot color, and of the accent, goes through it. Gone with
it: the group aliases (`local colors = st.config.profile.colors.text` and the like, about 15), the wrappers
named for a hue (`OB.Blue`, `OB.Grey`, `LinkBlue`, `D.Grey`, `GreyRGB`, `Grey()` in their files), the tip
line's `red = true` field (`optionscontrols.lua:65`), and the string keys of hues in data. A wrapper the
builder keeps is named for its role (`OB.Accent`, `Muted()`). The other groups (Class, Power, Reputation,
Item quality, Status, Threat, Objectives) keep their reads, whose keys come from the game and have their own
fallbacks (`st:QualityColor`).

**Change notifications.** `st:ColorsChanged(group)` gains four groups: `'accent'` (the Theme tab's Accent
row), `'roles'`, `'factions'` and `'loot'`. A handler that recolors something on `'button'` or `'text'`
today recolors it on the group that now holds its color: the held roll bars' lit border and label
(`roll.lua:597`) and the bags' lit view buttons (`header.lua:230`, `slot.lua:109`) on `'accent'`; the
feed's buttons (`feed.lua:167`) on `'text'` and `'accent'`; the zone text's faction (`ZoneText.lua:290`)
on `'factions'`. `Config:UpdateConfig` fires `'accent'` after its last `'theme'` (**call**): the accent is
now a theme color, and a profile switch already promises no frame keeps the old profile's theme.

## Opacity

**The rule** (**call**): a reader draws a Buttons color at its own strength times the color's opacity,
`st:ColorRGBA('button', key, strength)`. The defaults' opacities become 100%, so at the defaults every
reader draws exactly what it draws today; 50% draws each at half its strength. One rule for every reader,
whether it draws the color solid or at 0.3. The other way (the opacity is the alpha drawn) would need one
color per strength, since Danger is drawn at 0.3 on a bank slot and 0.4 on a flash, and the micro buttons
draw Hover at 0.4 and Pushed at 0.6.

The Buttons note gains: "Opacity sets how strongly each is drawn: 100% is SaftUI's own." (the builder
words it). The swatch shows no percent at 100%, as the color field does today.

**What reads them**, each with its strength:

| Color | Reader | Strength |
| ----- | ------ | -------- |
| Normal | `SaftUI-Core/Widgets/button.lua:253` (the highlight of `st:SkinButton`'s buttons) | 1 |
| Normal | `SaftUI-Core/Widgets/checkbutton.lua:84,115` (a check box's highlight) | 1 |
| Normal | `SaftUI-Core/Widgets/scrollbar.lua:10` (the thumb at rest) | 1 |
| Normal | `SaftUI-Minimap/micromenuitems.lua:37` (a micro menu item's highlight) | 1 |
| Hover | `checkbutton.lua:83,109` (a checked box's fill) | 1 |
| Hover | `scrollbar.lua:10` (a hovered thumb) | 1 |
| Hover | `micromenuitems.lua:97`, `expansionbutton.lua:51`, `queuebutton.lua:44` (hover) | 1 |
| Hover | `SaftUI-Minimap/microbuttons.lua:181` (a micro button's highlight) | `HOVER_ALPHA` (0.4) |
| Hover | `SaftUI-Core/skinning.lua:443,446`, `Config/optionsresize.lua:163-167` (resize handles) | 1 |
| Pushed | `button.lua:263`, `micromenuitems.lua:43`, `scrollbar.lua:10` | 1 |
| Pushed | `microbuttons.lua:123` | `PUSHED_ALPHA` (0.6) |
| Danger | `SaftUI-Bags/containers/bank.lua:56` (an unbought slot, its region alpha 0.3 kept) | 1 on the vertex, so 0.3 in all |
| Danger | `SaftUI-ActionBars/skin.lua:445`, `SaftUI-Misc/totemskin.lua:304` (the flash) | 0.4 |

Like their colors, these are set when a frame is built or restyled, so an opacity change shows after a
reload, as the note says.

**The own marks and the diff icon** (answer 4: "we can play with individual opacity for those highlights
if needed"): the own label, title, Own text and tooltip values draw the accent at `OB.OWN_STRENGTH`, and
the diff icon draws Muted at `OB.DIFF_STRENGTH`, both 1 to start (**call**), so turning either down after
the owner sees them in game is one number in `optionsbody.lua`. They are SaftUI's constants, not settings.
The accent's tints keep theirs: `st.TINT_ROW` (0.25) and `st.TINT_OBJECT` (0.15), through
`st:ColorRGBA('accent', nil, st.TINT_ROW)`.

## Blue that isn't theme coloring

Every use of blue in SaftUI, verified at `48c2a67`, sorted by whether it is theme coloring. The owner asked
for every one that isn't.

### Theme coloring: becomes the accent, no question

The accent's job is "active, selected, on, current, hovered, linked" on SaftUI's own controls and frames:

- **`/sui` and the options kit:** the sidebar's open page (`optionsnav.lua:114,131`), the tab underline
  (`:242`), the page list's arrow under the mouse (`:748`), the brand's "UI" (`optionslayout.lua:367`), a
  list row's hover and the picked entry (`optionslist.lua:70,172,206`), a search result's hover and the
  found label (`optionsbody.lua:892`, `optionswindow.lua:847`), the slider fill (`optionsrange.lua:131`),
  the check mark (`optionslook.lua:475`), a hovered or focused edge (`:81`), the picked position dot
  (`optionsposition.lua:43`), a lit control's icon and label (`optionscontrols.lua:107,118`, `W.SetOn`:
  edit mode's toggles, the sidebar's Edit mode), the item dots under the mouse (`optionsitem.lua:60`),
  "Press a key" (`optionskeybinding.lua:154`), the reset icon under the mouse, the own mark and the share
  links (`optionsshare.lua:151,273,274,409,537`), the own marks' text (`OB.OWN_TEXT`, answer 4).
- **Edit mode:** a selected mover (`mover.lua:100`), the grid's centre lines (`grid.lua:74`), the snap
  guide (`snap.lua:250`), the Coordinates label (`coordinates.lua:205`), the picker's current mover
  (`picker.lua:121`), the hide strip (`bardock.lua:294`), the History list's current step and hover
  (`historylist.lua:196,199`).
- **Selection and "on" in the world:** a picked radio button (`Widgets/radiogroup.lua:27`), the bags' lit
  header button (`header.lua:51`), the selected bank window (`inventory.lua:84`), the selected category row
  (`categoriestab.lua:643`), the drag's insertion line (`dragparts.lua:119`), the rule editor's check and
  Not box and + Block and + Group (`ruleeditor.lua:497,529,712`), + New category and Reset all
  (`categoriestab.lua:1002`), the feed's lit buttons (`feed.lua:39`), keybind mode's highlight
  (`keybindmode.lua:254`), a held roll's border and label (`rollbar.lua:99,120`), the equipped item's
  border (answer 5), SaftUI-Tracker's focused quest bar, row hover, current-zone pin and popups
  (`rows.lua:120` and its `NewAccent` pieces), the skin of Blizzard's color picker (`Blizzard_ColorPicker.lua:334`).
- **Hover on in-world buttons:** Core's skinned buttons (`skinning.lua:266`), bag slots
  (`containers/bag.lua:76`), totem buttons (`totemskin.lua:296`), Blizzard's tracker's item button under
  the skin (`Blizzard_ObjectiveTracker.lua:433`), each at today's strength. (The action buttons' hover is
  white at 15% since decision 30; nothing here changes that.)
- **The chat's SaftUI prefix** (`api.lua:207`, hardcoded `|cff00adef`), read at print time.

### Not theme coloring

| Use | Where | Today | This design |
| --- | ----- | ----- | ----------- |
| The tank role mark | `elements/indicators.lua:63`, `grouppreview.lua:296` | Text > Blue | Roles > Tank (answer 3) |
| Alliance on the zone text and world map | `ZoneText.lua:57,90` | Text > Blue | Factions > Alliance (answer 3) |
| "Category: <name>", the first line SaftUI adds to a bag item's tooltip | `SaftUI-Bags/slot.lua:234` | Text > Blue | **Question 1.** Recommended: the accent. It is SaftUI speaking inside Blizzard's tooltip, as the chat prefix is in chat, and it is the line that leads to the Categories tab. |
| The rule editor's AND groups: their line, connectors and badge | `ruleeditor.lua:91-93,820,930` | Buttons > Blue, against OR in Text > Orange | **Question 2.** Recommended: AND the accent, OR Warning. Each badge says its word, so a player who makes the accent orange loses only a hint; decision 23 is kept (both SaftUI's under Blizzard). |
| Progress and timer fills: the bags' loading bar, the loot roll timer bars | `SaftUI-Bags/container.lua:85`, `SaftUI-Loot/roll.lua:225`, `rollbar.lua:195` | Buttons > Blue | **Question 3.** Recommended: the accent. They say "time passing", not a state; the timer's text still turns Danger under a minute. |
| Quest progress bars in SaftUI's tracker and in Blizzard's skinned tracker | `SaftUI-Tracker/rows.lua:296,305` (`BAR_COLOR`, 0.26, 0.42, 1), `Blizzard_ObjectiveTracker.lua` (its progress and timer bars) | Blizzard's progress blue, hardcoded, not the profile's | **Question 4.** Recommended: leave. It is the game's own quest progress color, which the tracker design chose. |
| The out-of-mana tint on action buttons | `SaftUI-ActionBars/skin.lua:230` (0.5, 0.5, 1.0, LibActionButton's `colors.mana`) | hardcoded | **Question 4.** Recommended: leave, with its partner the out-of-range red: both are tints multiplied on the icon, which no role maps onto. |
| Heroic on the zone text's difficulty | `ZoneText.lua:13` (`5794de`) | hardcoded, Blizzard's | **Question 4.** Recommended: leave, with LFR, Normal and Mythic: Blizzard's difficulty colors. |

Not counted as SaftUI's blue: Item quality's Rare, Heirloom and WoW Token, Power's Mana and Maelstrom,
Renown, experience's rested bar, Blizzard's own art, and the dev tools (`Dev/fontdemo.lua`, to be deleted
when a font is chosen; `utilities.lua:129`, the table printer's nesting colors).

## The hardcoded colors the audit lists

The audit's part 5, each decided (**call** for each but OWN_TEXT and DIFF_COLOR, which are the owner's):

| Where | Today | This design | Phase |
| ----- | ----- | ----------- | ----- |
| `SaftUI-Core/api.lua:207` | the SaftUI prefix, #00adef | the accent, at print time | 2 |
| `api.lua:214` | the Error prefix, pure red | Text > Danger, at print time (a look change, listed) | 4 |
| `api.lua:221` | DEBUG in Text > Red | Text > Danger | 4 |
| `Config/optionsbody.lua:228` | `OB.OWN_TEXT`, light blue | the accent at `OB.OWN_STRENGTH` (answer 4) | 2 |
| `optionsbody.lua:229` | `OB.DIFF_COLOR`, orange | Muted at `OB.DIFF_STRENGTH` (answer 4) | 3 |
| `Config/optionsshare.lua:268-269` | links and icons white under the mouse | Strong | 4 |
| `SaftUI-Loot/rollbar.lua:206`, `roll.lua:230` | timer text white over a minute | Strong | 4 |
| `SaftUI-Tracker/rows.lua:119`, `window.lua:106` (new) | the progress percent, a chevron under the mouse, white | Strong | 4 |
| `SaftUI-Core/panels.lua:361` | the close button's hover fill, 0.5, 0.1, 0.1, 0.4 | read from `templates.close.backdropcolor`, the same value (code changes 11) | 4 |
| `optionsposition.lua:34` `DOT_GREY`, `optionswindow.lua:177` `SIDEBAR_BG`, `OB.LINE` | kit surfaces | stay, for the tokens table | none |
| `optionstypes.lua:174` `CODE_COLOR` | gone already | none | none |
| `ZoneText.lua:10-15` | difficulty colors | stay (Question 4) | none |
| `ActionBars/skin.lua:229-230` | out of range and out of mana tints | stay (Question 4) | none |
| `Blizzard_CooldownViewer.lua:86`, `instancedifficulty.lua:23`, `Blizzard_BuffFrame.lua:36` | Blizzard's bar orange, the badge's base, the temporary enchant purple | stay: game colors, no role | none |
| `Dev/fontdemo.lua` | the dev tool's greens, blues and reds | stay: deleted with the font choice | none |

## Phases

Each phase is one task with its own tests, merged whole, and leaves every saved profile intact: a phase
that removes a key's default moves its readers, adds its migration step and retires the key in the same
change. They run in order; each starts from the last. Each updates the `.agents/` docs its files are covered
by (`.agents/architecture.md` for config, defaults and the migration; `.agents/edit-mode.md` for the Colors
and Theme tabs and every "Text > Grey" and "Button > Blue" there; `.agents/testing.md` for the new tests),
and the page descriptions of what each color colors.

**Phase 1: the accessor, the migration, and groups of their own.** `st:Color` and `st:ColorRGBA`;
`st:MigrateColors` with step 1, run at login and in `UpdateConfig`; the defaults of `colors.roles`,
`colors.factions` and `colors.loot`; the Roles, Factions and Loot sections in their places; Text > Purple
and Buttons > Yellow leave the page. Readers: the roll buttons' data and its readers (`rollbar.lua:12-15`,
`roll.lua:89`), the counts (`rollinfo.lua:77-78,113`), the feed's tooltip (`Feed/rolls.lua:40-42,57-62,127,165,196`),
the mount entry (`Feed/feed.lua:141`), the zone text (`ZoneText.lua:57,90` and its handler on
`'factions'`), the role corners (`indicators.lua:61-65`, and its description at `:44`, which names hues) and
the previews (`grouppreview.lua:293-298`); `UF:UpdateColors` drops its `colors.roles` fallback line (the
followup's plan). Text's and Buttons' descriptions drop the moved uses. About 15 sites.

**Phase 2: the accent.** `theme.accent`; the Theme tab's Accent row (get, set, its own reset, `'accent'`);
`UpdateConfig` fires `'accent'`; step 2. Every reader of Buttons > Blue, Text > Blue's theme uses and
Buttons > Green moves to `st:Color('accent')` (the lists above, about 55 sites with the wrappers), the own
marks and the chat prefix with them, and the handlers listening on `'button'` for blue listen on
`'accent'`. The owner's answers to Questions 1 to 3 go in here. Text > Blue, Buttons > Blue and Buttons >
Green leave the page. The biggest visible phase: everything blue follows one swatch.

**Phase 3: Muted.** `text.grey` becomes `text.muted`; Buttons > Grey folds into it (`combinedbank.lua:51`,
`picker.lua:128`); the diff icon (`optionsshare.lua:562,642`) and the bag category's marker
(`categoriestab.lua:659`) take it; step 3. The grey wrappers are renamed. About 55 sites, the most of any
one key.

**Phase 4: the state colors.** Strong, Danger, Warning, Caution, Success and Shared, and Buttons > Danger;
step 4; the hardcoded folds marked 4 above; the rule editor's OR and Caught now highlight as Warning (or
the owner's answer to Question 2). Every remaining read of these groups, Text included, goes through the
accessor, and the scan test takes its final rule. About 90 sites. Labels are now final.

**Phase 5: opacity.** The Buttons defaults at 100%; every reader in the opacity table through
`st:ColorRGBA` at its strength; step 5; the Buttons note. About 20 sites.

**Phase 6: the design system's pages** (docs only). `docs/design-system/tokens.json` (the accent token and
the text tokens by role), `05-decisions.md` (14 and 48 built), `10-discrepancies.md` (26),
`30-code-changes.md` (9 and 11 as far as this covers them), the components that name a hue (DiffIcon,
ActionButton, Mover, Tooltip), and a line at the top of `25-colour-roles.md` saying it was built by this
design. The design system's artifact is republished after.

## Testing

All in `tests/`, run with `tests/run`.

- **The accessor** (phase 1): a profile color, the accent, the default before `st.config`, an unknown
  group or key raising with its name, a nil alpha as 1, `ColorRGBA`'s strength times opacity.
- **The migration**, one case per step and together: a profile with nothing saved (only the version set);
  a source saved with one channel (the rest from `OLD_COLORS`); a source equal to its old value (nothing
  copied); every destination of a split; the accent from Buttons > Blue and not Text > Blue; Buttons >
  Green and Grey dropped; retired keys gone; run twice (no change); a profile saved before phase 1 run
  through every step; a copy from an unmigrated profile into a migrated one; a reset; raw data (a table
  AceDB hasn't filled) and the active profile, where `:GetRGB()` still works on every migrated color;
  opacity reset to the default's in place, never nil. In the real AceDB world the history tests use.
- **The scan** (grows each phase, final in phase 4), like `tests/core/theme_kinds_test.lua`: every file the
  TOCs load, read for each form found today (`st.config.profile.colors.text.x`, `Colors().button.x`, a
  local alias of a group, `colors.text[...]`), fails on any read of a retired key and, from phase 4, on
  any read of Text, Buttons, Roles, Factions, Loot or `theme.accent` outside `colors.lua`'s accessor and
  page rows; from phase 5, on a Buttons color read with `:GetRGB()`.
- **The pages:** the Colors page's section names and order and each section's names and order (the
  tables above), the opacity flag on Buttons only, the notes, every row's reset; the Theme tab's rows in
  order with Accent, its reset and its `'accent'`.
- **Readers keep their look:** for each phase's readers, at the defaults, the color drawn equals the old
  key's default (the listed changes excepted, each with a case of its own); after a change of the new
  role, it is drawn there and nowhere it no longer belongs (Danger recolors no Pass, Damage or Horde;
  the accent recolors Tank and Alliance no more).
- **Opacity:** at 100% every reader in the table draws today's alpha; at 50% half of it.
- The 55 test files that read the old keys move to the new ones in the phase that retires each.

## In-game checks

The owner's, at the end of each phase:

1. Phase 1: loot roll letters and counts, the feed's roll tooltip and a mount entry, the zone text in a
   friendly, hostile and contested zone, role corners in a group and in test mode: all as before. Change
   Pass, Horde and Damage and see each move alone; Text > Red still colors errors.
2. Phase 2: Theme > Accent recolors `/sui`'s sidebar, tabs, sliders and checks, the edit mode bar, a
   selected mover, the tracker's focus bar, a held roll's border, and (after a reload) bag and totem hover
   and an equipped item's border. Own labels and the own mark both in the accent; the chat prefix.
3. Phase 3: hints, captions and disabled rows as before; the diff icon grey beside a differing setting.
4. Phase 4: errors, timers, level tags, stats, durability, item levels as before; the Error prefix in
   Danger.
5. Phase 5: Buttons opacities at 100% look as before; lower Hover and see check boxes and micro buttons
   fade after a reload.

## What's left to the builder

- Exact descriptions and notes, within the "What each role colors" table and the gists above.
- Names of locals and of any wrapper kept (named for a role), and whether `st:Color` and the migration live
  in `colors.lua` or a file beside it.
- The scan test's exact patterns and file, and how each test file is split.
- How each handler routes `'accent'`, `'roles'`, `'factions'` and `'loot'`, within "Change notifications".
- **Followups** (`docs/followups.md`): "Design decisions waiting to be built" loses 14 and the accent part
  of 7 when phase 2 and phase 4 land; "Colors tab: role and rune colors" has its role colors done in phase
  1 (runes and the class switch stay).

## Calls made while writing this

Ordered by how much the owner is likely to care.

1. **The accent is one color for every theme**, stored at `theme.accent`, not one per theme: a frame drawn
   in a module's own theme would otherwise have no clear accent, and the accent is SaftUI's own color (the
   brand's "UI", the chat prefix).
2. **Keys are renamed, with a versioned migration** (`colors.version`, one step per phase), not labels
   only.
3. **The accent takes Buttons > Blue's saved color only;** a changed Text > Blue goes to Tank and Alliance.
4. **Buttons > Danger stays apart from Text > Danger** (a darker fill for flashes and unbought slots).
5. **The mount's feed entry (Buttons > Yellow) joins the loot group, named Loot**: Need, Greed, Transmog,
   Pass, Mount.
6. **Opacity is a strength:** drawn alpha is the reader's own strength times the color's opacity, defaults
   100%, and every saved Buttons opacity goes back to 100% once.
7. **The bag category's "edited" and "yours" marker goes to Muted**, with the diff icon.
8. **The chat's Error prefix becomes Danger** (pure red to the soft red).
9. **Buttons > Grey folds into Text > Muted**, and a customized Buttons > Grey is dropped.
10. **The rule editor's OR and its Caught now highlight keep their orange as Warning** (subject to
    Question 2 for OR).
11. **The order of sections:** Text, Buttons, Class, Roles, Reputation, Factions, Power, Item quality,
    Loot, Status, Threat, Objectives; Accent on the Theme tab between Background and Options windows.
12. **Roles are keyed `TANK`, `HEALER`, `DAMAGER` and Factions `Alliance`, `Horde`, `Neutral`**, the game's
    own tokens, as Class and Power are; Loot by lowercase choice names.
13. **`text.normal` keeps its key** (its label is already Text), and Buttons' Normal, Hover and Pushed keep
    their keys and labels.
14. **The new sections and the Accent row carry the reload note**, as Text and Buttons do.
15. **One accessor, `st:Color` and `st:ColorRGBA`, that errors on an unknown key**, pinned by a scan test;
    the groups named for game concepts keep their own reads.
16. **New `ColorsChanged` groups** `'accent'`, `'roles'`, `'factions'`, `'loot'`, and `UpdateConfig` fires
    `'accent'` after `'theme'`.
17. **`OB.OWN_STRENGTH` and `OB.DIFF_STRENGTH`, both 1**, so the owner's "play with individual opacity" is
    one number each after the in-game check.
18. **Folded into Strong:** the share line's white under the mouse, the roll timers' white, the tracker's
    two whites. The close button's hover fill reads `templates.close`. Every other hardcoded color stays.
19. **A source still at its old shipped value copies nothing**, so a later change of a new role's default
    still reaches players who never changed the old one.
20. **The migration isn't run on `Config:Import`**, which carries only unit frame layouts.
21. **Threat's Warning and Bad keep their names.**
22. **Six phases in this order**, docs of the design system last.

## Questions for the owner (answered)

The blue that isn't theme coloring, which you asked to hear about. Each changes what phase 2 builds.
All four are answered: see "Settled with the owner after the draft (2026-11-14)", below.

1. **"Category: <name>"**, the first line SaftUI adds to a bag item's tooltip, is Text > Blue today.
   Recommended: the accent (SaftUI's own line, like the chat prefix). Or Strong, or Text?
   **Answered:** the accent.
2. **The rule editor's AND groups** are blue and OR groups orange. Recommended: AND the accent, OR
   Warning (each badge also says AND or OR). Or should the two get a pair of their own colors, so the
   accent can be any color without meeting OR's?
   **Answered:** AND the accent, OR Warning.
3. **The bags' loading bar and the loot roll timer bars** fill in blue. Recommended: the accent. Or a color
   of their own?
   **Answered:** the accent.
4. **Three blues that are the game's own, not SaftUI's:** the quest progress bars in both trackers
   (Blizzard's progress blue), the out-of-mana tint on action buttons, and Heroic on the zone text's
   difficulty. Recommended: leave all three as they are. Or should any follow the accent?
   **Answered:** all three are left as they are.

## Settled with the owner after the draft (2026-11-14)

The owner, on this draft: "I'm good with all of those suggestions, if any feel off we can adjust". These
override anything above that they contradict.

1. **The design is approved**, with every recommendation as written.
2. **Question 1:** "Category: <name>" in a bag item's tooltip takes the accent.
3. **Question 2:** the rule editor's AND groups (their line, connectors and badge) take the accent, and its
   OR groups Warning. They get no pair of colors of their own.
4. **Question 3:** the bags' loading bar and the loot roll timer bars fill in the accent. They get no color of
   their own.
5. **Question 4:** the three blues that are the game's own stay as they are: the quest progress bars in
   SaftUI's tracker and in Blizzard's skinned tracker, the out-of-mana tint on action buttons, and Heroic on
   the zone text's difficulty.
6. **Every call** under "Calls made while writing this" (1 to 22) stands as written.
7. **"if any feel off we can adjust":** a call that looks wrong in game is changed then, with a dated note
   added here.
