# Shared fonts named for their jobs, a Heading font, and font rows that take a typeface

Design, 2026-11-14. It takes up the followup "Fonts: separate the fonts users pick per kind of text from
SaftUI's internal font objects" (`docs/followups.md`, 2026-11-10) and the design system's Code change 3,
"Font roles" (`docs/design-system/30-code-changes.md`), from the audit
`docs/research/2026-11-14-fonts-audit.md` and the owner's answers to its seven questions. It is a draft for
the owner to approve: every decision he didn't make is marked **call** and listed again at the end, under
"Calls made while writing this".

Checked against SaftUI's code on `modular` at `ccfb21f` (the audit read `e9b5197`; what moved since is
under "Where the audit is out of date or falls short"). Nothing here has been checked in game; the checks it needs are
G1 to G8 under "In-game checks".

Words used below:

- **Shared font**: one of SaftUI's font objects (`st.config.profile.fonts.<key>`, made by
  `SaftUI-Core/Media/fonts.lua`), edited on Global settings > Fonts. The code and the audit call them font
  objects or roles; players will see them listed as "SaftUI fonts".
- **Typeface**: a face LibSharedMedia lists (Colus, AgencyFB Bold, Homespun, Friz Quadrata, another addon's).
- **Font setting**: a setting that says which font one kind of text uses (`chat.font`,
  `tracker.header_font`, a unit frame's `name.font`, ...).
- **Font row**: the row in `/sui` that sets one; `generators.font` makes it.

## Why

The owner, 2026-11-10: "I'd like to change my bag category labels to Colus but don't currently have a good
way of doing that without also changing the font of my unit frames as well as anything else that uses the
"Normal" font object." Today every font row offers only the shared fonts, each a face, size, outline,
shadow and spacing together, so restyling one kind of text restyles every other kind on the same font. The
shared fonts are also named after their faces ("Colus", "Pixel") rather than their jobs, two of them are
used by nothing, and the action bars and buffs copy Pixel's look when their file loads, so they never
follow it (audit section 4).

The owner's way out, from his answers: the shared fonts stay, named for what they do, as "shared configs
for font objects across the UI", and any one text can step out of them with a typeface of its own.

## What the owner decided

His answers to the audit's questions, binding on this design:

1. **Rename only the names players see.** The keys (`title`, `normal`, `pixel`, ...) stay, and no profile
   is migrated for names.
2. **Shared fonts stay editable on the Fonts tab.** "those font objects are essentially shared configs for
   font objects across the UI - we're simply adding the option to also ignore those font objects for an
   given element with a specific override".
3. **A font dropdown lists the shared fonts, then the typefaces.** With a typeface picked, three dots
   beside the dropdown open a menu with that text's own options: "if a font face is directly selected we
   can have the expansion menu to set to configure all of the options (size, outline, offset, etc.)". With
   a shared font picked there is no override at all, and a different icon in the dots' place takes the
   player to that shared font: "instead of putting the dots when a font object is configured we put a
   different icon that links to the font object config? that way a user learns where to configure it if
   they need but the config stays in one place".
4. **Colus (key `title`) becomes "Huge title"** and stays the zone name at 72. **A new shared font,
   Heading,** ships as Colus at about 15, what `/sui`'s section titles look like today. `/sui`'s titles
   follow Heading's face. SaftUI's tracker's zone headers (`tracker.header_font`) and the bags' category
   titles (`inventory.fonts.titles`) default to Heading.
5. **Window titles get a section in the theme.** "can we add a config section to the theme for setting
   window title fonts? that way we can just swap it to a different font easily without needing to change
   the "Text" font object". Window titles default to Text, so nothing changes until he chooses.
6. **Homespun is offered as a typeface at any size.** "lets just keep all sizes for now because I don't
   like being super restrictive".
7. **Pixel Huge and Normal Med are dropped** if nothing uses them (verified: nothing in code reads either),
   and players can no longer rename shared fonts.

## Goals

- Six shared fonts, named for their jobs, in one fixed order on the Fonts tab and in every list.
- Every font row in SaftUI offers the shared fonts first, then every typeface, each drawn in its own face.
- A typeface picked on a row carries that text's own size, outline, shadow and line spacing, set in a menu
  behind three dots; a shared font picked has no override, and a link icon takes the player to it.
- Saved profiles keep working as they are: today's values are strings naming a shared font, and stay valid.
- One function applies a font setting to a text, and every font setting applies at once; no font row says
  "after a reload" any more.
- Heading, and Window titles in the Theme tab.

## Non-goals

- Renaming the keys, or any profile migration for names (answer 1).
- Moving the action bars' and buffs' texts off their copied faces onto Small text by default. They gain the
  shared fonts in their lists, so a player can pick Small text; making it their default needs a conversion
  of its own (Later).
- Resets for the font rows that have none today (all but the Tracker's two and All bars'); Later.
- The tooltip's shadow and line spacing, which stay Blizzard's on its lines, as today.
- The font demo (`/suifonts`), the unregistered and stray font files, and the faces' licences (audit
  section 1). They are unchanged here.
- A size per theme for anything, or a font per theme (see Window titles).

## Anti-goals

- `SetFont` on a font string SaftUI keeps. In game `SetFontObject` doesn't undo an earlier `SetFont`
  (`.agents/testing.md`, stub rule 3), so a text that switched between a typeface and a shared font would
  stick on the face.
- A menu opened inside a menu. `OW:OpenMenu` closes the open menu first; a font row in an item's menu has
  its options as rows of that menu instead.
- Reusing a font object the game made (`.agents/taint.md` rule 10). Every object here is one SaftUI made
  with `CreateFont` and keeps.
- A font setting that only applies after a reload.
- A shared font's look changed by any one text's settings. An override is a typeface, never a shared font
  with a field changed.

## The shared fonts

The order below is the Fonts tab's and every list's (`FN.FONTS` in `fonts.lua`, a fixed list of
`{ key, name, job }`; **call**). The names and jobs live in code: a profile's saved `name` is ignored, and
the objects are named by key (`SaftUI_<key>Font`), so two can never ask `CreateFont` for one name.

| Name players see | Key | Face | Size | Outline | Job (the section's note on the Fonts tab) |
| --- | --- | --- | --- | --- | --- |
| Text | `normal` | AgencyFB Bold | 16 | Outline | Most readable text: unit frame names and values, tooltips, chat, the loot feed and rolls, the trackers' quests, window titles, check box labels; and the face of `/sui`'s labels and fields |
| Small text | `pixel` | Homespun | 10 | Monochrome outline | Small numbers and labels on buttons, icons and bars: counts, item levels, cast bar text, chat tabs, the micro menu, edit mode's labels |
| Large numbers | `pixel_med` | Homespun | 18 | Monochrome outline | Cooldown numbers on buttons 36 pixels and larger, and the player's mana text |
| Heading (new) | `heading` | Colus | 15 | Outline | Headings: the bags' category titles, SaftUI's tracker's header and zone headers; and the face of `/sui`'s titles |
| Huge title | `title` | Colus | 72 | Outline | The zone name, as you enter a zone |
| Subtitle | `subtitle` | Colus | 24 | Outline | The lines under the zone name |

Every one has shadow offset 0, 0 and line spacing 4, as today. **Calls:** "Small text" over the audit's
"Small", since a list entry reads better as a noun beside "Text"; "Large numbers" as the audit proposed.
The color roles design names a color "Text" too (decision 48); a shared font and a color of the same name
on two tabs read as the text's font and the text's color, so both keep it.

**Dropped:** Pixel Huge (`pixel_huge`) and Normal Med (`normal_med`). Nothing in code reads either (checked:
no `st:GetFont`, no key built from parts). A profile can still name one, in any setting a player pointed at
it through a font row. Such a value reads as the typeface it looked like: the old default (Homespun 32,
Monochrome outline; AgencyFB Bold 24, Outline) with whatever the profile saved under
`fonts.pixel_huge` or `fonts.normal_med` over it (`FN.DROPPED`, two entries in code). The row shows that
typeface with its dots, and nothing is written until the player changes it (**call**). The saved
`fonts.<dropped>` table stays in the profile, unread except for this. `FN:UpdateFontConfig` and the lists
walk `FN.FONTS`, never `pairs(st.config.profile.fonts)`: today's loop would meet such a saved table, with no
`name`, and fail building it.

## A font setting's value

### The saved shape

A font setting holds one of two things:

```lua
-- a shared font: its key, a string, as every saved value is today
header_font = 'heading'

-- a typeface with this text's own options: a table with a shared font's own fields, less its name
header_font = { font_name = 'Colus', font_size = 15, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
```

The table's fields are the ones `st.defaults.fonts` entries have (**call**), so one routine sets a font
object from either. A field it lacks reads as Text's default, so a partial table still draws. A table is
never a default: every font setting's default stays a string.

The action bars' texts (`text.<kind>.font`, `size`, `outline`) and the buffs' and debuffs' Duration and
Stack count (`auras.<buffs|debuffs>.<duration|count>.font`, `size`, `outline`) keep their own shape, which
their shares and pages are built on: `font` is a string, a shared font's key or else a typeface's name, with
`size` and `outline` beside it, read only while it names a typeface. `st:FaceFont(font, size, outline)`
turns such a triple into a value of the shape above (the key, or a table).

### Old values

Nothing is converted for names or for this shape. A string is read as it always was: a key in `FN.FONTS`
is that shared font; `pixel_huge` and `normal_med` are their typefaces (above); anything else is no font,
which the one function below draws as Text rather than erroring.

AceDB leaves both shapes alone (checked against the bundled `AceDB-3.0.lua`): `copyDefaults` fills a key
only while it's nil, and `removeDefaults` drops a value only when it equals the default, so a saved table
under a string default is kept, and a key put back to its default string is dropped at logout as today. No
`*` or `**` default sits at a font key's own level (the unit frames' wildcards are a level above, at the
units' and the elements' keys), so AceDB never merges defaults into a typeface table. Phase 1 adds the case
to the tests' `apply_defaults`.

The one conversion in this design is chat's, which follows from answer 3 (Readers, below).

### One function

`st:ApplyFont(fontString, value)` is how every reader puts a font setting on a text. It calls
`SetFontObject` with `st:GetFont(value)`, or Text's object when that is nil, and nothing else.

`st:GetFont(value)` (`fonts.lua`) takes either shape:

- a string: the shared font's object, a dropped key's typeface object, or nil (as today, so code that
  falls back with `or st:GetFont('normal')` still works);
- a table: a typeface object for that look. There is one object per look (face, size, outline, shadow X and
  Y, spacing), made the first time a look is asked for, named `SaftUI_Typeface<n>Font`, white like the
  shared fonts (so `SetFontObject` keeps giving texts white, the note in `SaftUI-Unitframes/updaters.lua`),
  and never changed after (**call**). The game can't free a font object, so they last the session; their
  number is the number of looks used.

One routine, `FN:SetObject(object, values)`, sets a shared font's object and a typeface's: the face from
LibSharedMedia, size, outline, opaque black shadow color, shadow offset, spacing, and the one-up-one-down
size nudge that makes texts measure again. The scaling design's per-face rule, if it comes
(`docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`, Fonts), then lands in one place for both.

Beside it, for readers that can't take a font object:

- `st:FontValues(value)` gives `path, size, flags, shadowX, shadowY, spacing`.
- `st:FontLabel(value)` gives the words for a value: a shared font's name ("Heading"), or a typeface as
  "Colus 15, outline". Resets' and shares' tooltips use it.
- `st:IsSharedFont(value)`.

The names are the builder's; the rule is what matters.

### The rule for readers

1. **A text SaftUI made or keeps** gets its font from `st:ApplyFont`. It never has `SetFont` called on it.
   A test scans every file the TOCs load for `:SetFont(` and fails outside a short list: the objects
   SaftUI keeps (`fonts.lua`, `/sui`'s own in `optionsbody.lua` and `optionslook.lua`, the buff frames'),
   the kit's `SetFieldFont` (pooled list rows drawn in each face, which sets outright on purpose), the
   frames below that only take values, and the font demo. (`theme_kinds_test.lua` is the precedent.)
2. **Every font setting applies at once.** A shared font changed on the Fonts tab changes its object, and
   every text on it follows with no code. A setting changed in its own row (another font picked, a dots
   change) runs the row's own `set`, which already re-applies its module (`UpdateConfig`), as every setting
   does. A setting with no module to re-apply it (Button text, Check box labels, Window titles) keeps its
   texts in `st:FollowFont(region, getValue)`, a weak list that `st:RefollowFonts()` applies again; its
   row's `set` and the profile update call that.
3. **A region whose font only takes values** (Blizzard's chat frames, Blizzard's tooltip lines, RestedXP's
   texts, the buff frames' font objects) reads `st:FontValues` and applies again from `OnFontsChanged`.
   `st:FontsChanged()` runs every module's `OnFontsChanged()` (in `xpcall`, as `st:ColorsChanged` runs
   `OnColorsChanged`) after a change on the Fonts tab. The Tracker's hook on `FN:UpdateFontConfig`
   (`SaftUI-Tracker/init.lua`) becomes its `OnFontsChanged`, and Config's runs `OW:UpdateFonts()`, so
   `/sui` follows a Fonts tab change at once instead of at the next profile change.

Code that names a key directly (`st:GetFont('pixel')` for chat tabs, mover labels, ...) isn't a setting;
the builder may leave it as it is.

## The font row

`generators.font(order, desc, opts)` makes a row of a new kit type, `font` (**call**: a type of its own
rather than a select, since its value isn't a key of a `values` table). Its arguments stay `(order, desc)`
for the 18 call sites today (`opts` is new and optional), so every one of them gets the new row with no
change: Kinds of text's (1 site, three rows today), the bags' Title font and Icon font, chat, loot rolls and
feed, tooltip, Skinning, Blizzard's tracker's Font and Header font, SaftUI's tracker's two, and eight in the
unit frames (name, health, power, additional power, cast bar text and time, aura count, plate subtext,
threat). Its `get` and `set` are the caller's or inherited, as today.

### The row

Its label, then the dropdown (the select's width and look, both looks), then one 16 by 24 slot at the
cell's right edge, which holds the dots or the link, so the dropdown doesn't move when a pick swaps them. A
row's reset icon, where it has a `default`, sits left of the dropdown as on any row.

- **A shared font picked:** the slot shows the link (below). The face reads the font's name, drawn in its
  typeface at the field's 15.
- **A typeface picked:** the slot shows the dots. The face reads the typeface's name in that typeface.

### The list

The kit's select list (`W.OpenList`), with the two kinds of entry it already draws:

- a heading, **SaftUI fonts** (a caption: the sidebar headings' font, Text > Grey, never lit, a click
  does nothing);
- the six shared fonts in `FN.FONTS` order, each by name, drawn in its own typeface at the list's 15 (not at
  its own size: Huge title at 72 would fill the list);
- a heading, **Typefaces**;
- every face LibSharedMedia lists, by name, in LibSharedMedia's order, each in its own face: Homespun among
  them, at any size (answer 6), the font demo's candidates while it exists, LibSharedMedia's defaults and
  other addons' faces.

The picked entry is blue: the shared font, or the typeface by its face. The list scrolls as long lists do
and has no steppers (a font list's names are never measured: that loads every file). A font list's mode
becomes per entry: an entry with a face is drawn in it, any other in the field font, a heading in the
heading font. **Note for the builder:** a heading in a font list must be set outright as `SetFieldFont`
does; today's `ListFill` sets the caption with `SetFontObject` after `SetFieldFont`, which in game keeps the
row's last face.

**Picking.** A shared font saves its key. A typeface saves a table filled from what the row shows now, so
nothing jumps but the face (**call**): from a shared font, that font's size, outline, shadow and spacing;
from another typeface, its options with the face swapped.

### The dots and their menu

Lucide's `ellipsis-vertical` (`st.icons.ellipsisVertical`), as on a menu item: 16 by 16 in the slot,
Text > Grey, Text > Blue under the mouse (white under Blizzard). Tooltip: "<Typeface> for <row name>",
then "Its own size, outline, shadow and line spacing." A click opens the menu as an item's dots do
(`OW:OpenMenu`: 400 wide, hanging from the dots, kept in the screen edge margin, following its row across
renders, closed by Esc, a click outside, navigation and combat).

The menu, titled "<row name>: <typeface>" ("Header font: Colus"), holds five rows, one to a line:

| Row | Range | Desc |
| --- | --- | --- |
| Size | 1 to 100 | How big this text is. |
| Outline | None, Outline, Thick outline, Monochrome, Monochrome outline, Monochrome thick outline | The outline around its letters. |
| Shadow offset X | -5 to 5 | How far right of the letters its shadow falls, in pixels; below 0, to the left. |
| Shadow offset Y | -5 to 5 | How far above the letters its shadow falls, in pixels; below 0, below them. |
| Line spacing | 0 to 20 | The gap between its lines, in pixels, when it runs to more than one line. |

They are the Fonts tab's rows for one text (one builder in `fonts.lua` makes both sets, with the Fonts
tab's ranges; **call**: one range for both, and Line spacing on every menu, though some texts never wrap).
The menu's rows have no reset of their own: the setting's default is a shared font, so the row's own reset,
where it has one, puts that back.

**How the menu saves.** Each menu row reads the row's value through `st:FontValues` and writes a copy of the
table with its one field changed through the font row's own `set` (`OM.Set` on that row). It never edits the
saved table in place (**call**), so the caller's `set` runs as for any change (its module re-applies, the
look gets its object), and Copy from and the history see whole values. Mid-drag the menu's rows follow in
place, as an item's menu's do.

### The link

When a shared font is picked, the slot holds a link: Lucide's `link` (new: `tools/lucide-to-tga.cjs link`,
`st.icons.link`, checked by `tests/core/icons_test.lua`, listed in
`docs/design-system/components/Icons/README.md`), the dots' size and colors (**call**: the chain says the
setting is linked to something shared, and that clicking follows it; an "external link" arrow would read as
leaving `/sui`).

Tooltip: the font's name as its title, then "A shared font. Its typeface, size and outline are set on
Global settings > Fonts, and change every text that uses it." and "Click to go there."

A click opens Global settings > Fonts and brings that font's section into view with its Typeface row's
label lit, exactly as a search result's click does: the window's `GoTo` (`optionswindow.lua`), exported as
`OW:Reveal(path)`, on `{ 'Fonts', 'fonts', <key>, 'font_name' }`. It closes an open menu first (navigation
does). On a disabled row neither icon takes the mouse, as an item's dots don't.

### Rows with their options beside them

`generators.font(order, desc, { faceOnly = true })` (`faceOnly`, a SaftUI field) is the row for the action
bars' four texts, which sit in an item's menu, and the buffs' and debuffs' two, whose Size and Outline are
rows of their own already. Its value is the string of their saved shape. It has the same list. Picking a
typeface saves the face's name, and the text's own Size and Outline rows show; picking a shared font saves
its key and hides them (their `hidden`), and the link shows. It never shows dots. It is the only font row
that may sit in an item's menu.

### Resets, shares and search

- A `default` works as on any row; its tooltip names the default through `st:FontLabel`: "Header font goes
  back to its default: Heading."
- The type is a `'row'` kind in `OB.SHARE_KINDS`, so the action bars' own mark, diff icon and Apply to
  work on it; `AB:SettingText` names a shared font by name.
- Search finds the row by its name, as today. The dots menu's rows are not search results (**call**: they
  exist only while a typeface is picked, and "Size" would match on every such row).
- `tests/lib/options_walk.lua` gets `font` among `SAFTUI_TYPES` and `faceOnly` among `SAFTUI_FIELDS`.

## The Fonts tab after the change

Global settings > Fonts:

1. **A line at the top** (a description row): "SaftUI's shared fonts. Every Font row in SaftUI lists these
   first, and a change here changes every text that uses the font, at once. A Font row can take a
   typeface of its own instead, with its size and outline in its dots."
2. **A section per shared font**, in `FN.FONTS` order (each group gets an `order`, so sections no longer sort
   by an editable name), titled with its name, with its job as the section's note. Its rows:
   - **Typeface** (was Font Name): every LibSharedMedia face, each in its own face.
   - **Size** (was Font Size), 1 to 100.
   - **Outline** (was Font Outline). `FN.outlines`' names go to sentence case: None, Outline, Thick
     outline, Monochrome, Monochrome outline, Monochrome thick outline (the action bars' Outline rows read
     the same table).
   - **Shadow offset X**, **Shadow offset Y**, **Line spacing**, as today.

   Each row has its own reset while it differs from `st.defaults.fonts[key]` (decision 10). There is no
   Name row (answer 7).
3. **Kinds of text**, last (**call**: the tab is about the shared fonts now): **Button text**
   (`buttons.font`; its desc now names the bag slot bars and the bank's bag slots, which the audit found
   missing) and **Check box labels** (`panels.font`). Both are font rows, so they take a typeface too,
   with resets to Small text and Text, and both apply at once (`st:FollowFont`), so the section's note no
   longer says to reload. Window titles has left for the Theme tab.

Every change on the tab applies at once to every text on that font, `/sui`'s own titles and labels included,
and runs `st:FontsChanged()`.

## Heading

`st.defaults.fonts.heading = { font_name = 'Colus', font_size = 15, font_outline = 'OUTLINE',
shadow_offset = { 0, 0 }, spacing = 4 }`: today's section title, as an object.

### `/sui`'s titles

`/sui`'s fonts (`FONTS` in `SaftUI-Core/Config/optionsbody.lua`) take Heading's face and outline where they
took Huge title's: the page title 34, the brand 26, the bar's brand 18, section titles 15, group titles 13
and captions 11. The tabs, labels, fields and small line keep Text's face and outline, as today.

**Their sizes stay the window's own (call).** Heading ships at 15, so a section title is Heading as it
ships, and every other title is its face at the size the window was laid out for. `/sui` doesn't read
Heading's size: the window measures its header and its section title lines around those numbers, and a
player who sets Heading to 24 for the bags' titles shouldn't get a 54 page title or section titles
running into their panels. Heading's face and outline reach `/sui` at once (`OnFontsChanged`).

RestedXP's guide title, which today takes Huge title's face at RestedXP's own size plus 3
(`restedxp.lua`), takes Heading's (**call**: it is a heading, and Huge title is now only the zone name).

### Its defaults

- `tracker.header_font`: `'normal'` to `'heading'`. That setting is SaftUI's tracker's whole header line
  ("Objectives" and the quest count, `window.lua`) as well as its zone headers (`rows.lua`); both take
  Heading (Question 1).
- `inventory.fonts.titles`: `'normal'` to `'heading'`. That setting also gives the bag window's search box
  its font (`inventory.lua`, `st:StyleEditBox`); the search box takes Text instead, and Title font's desc
  becomes "The font of the category titles." (**call**: Colus in a box you type in reads oddly, and the
  owner asked for the titles).
- Blizzard's tracker's Header font (`objectivetracker.header_font`) stays Text (**call**: answer 4 names
  only SaftUI's tracker and the bags).

### What changes on screen at upgrade (for the owner to check)

AceDB saves only what differs from a default, so a profile that never set one of these two picks up
Heading at once, and one that picked a font keeps its pick. A profile imported later from an export made
before the upgrade carries `'normal'` written out, and keeps Text.

What the owner will see on his own profile, if he never set them:

- The bags' category titles in Colus 15 in place of AgencyFB Bold 16, on the same line of their title
  band (Category title height, 50 by default; G3). The search box as it is.
- If his SaftUI tracker is on (it is off by default), its header line, count and zone headers in Colus 15.
- `/sui`'s titles as they are, whether or not he changed Colus's face on the Fonts tab: at upgrade, once,
  a profile that holds a face for Huge title other than Colus gives that face to Heading (while Heading's
  own face is still Colus), and the profile is marked so it never runs again; any other profile keeps
  Heading at Colus. A profile switched to, copied or imported later takes the same step the first time it
  loads (Question 2, Settled 3).
- On the Fonts tab: the new names and order, Heading's section, no Pixel Huge or Normal Med, no Name rows,
  Window titles gone to the Theme tab.
- Every font row in `/sui`: the new list, and the link icon beside every one (every default is a shared
  font).
- Chat looking as it does, with its Font size row gone (Readers, below).

The zone text, window titles, unit frames, action bars and everything else on Text and Small text look as
they do.

## Window titles in Theme

The Theme tab (`SaftUI-Core/Media/theme.lua`) gets, after Options windows, an inline section **Window
titles** with one row, **Font**: the font row, saved where it is today, `headers.font`, default Text, with
its own reset. Its desc: "The titles of SaftUI's windows: the bags and bank, `/sui`'s title bar under the
Blizzard theme, and Blizzard's color picker while Skinning dresses it. Every theme uses it." A change
applies at once to all three (the color picker's title today waits for the skin's next update; it follows
through `st:FollowFont`).

**One setting for every theme, not one per theme (call).** The owner's aim is to change window titles
without changing Text, which one setting does. Options windows, the row above it, is already one setting
for every theme on that tab. Keeping `headers.font` means no conversion. A per-theme font later would be an
override per theme that falls back to this setting, with nothing saved changing (Later).

The bags' gold and free-slot texts along their bottom read `headers.font` today; they take Text
(**call**: they aren't titles, and a player who sets window titles in Colus shouldn't get Colus gold).
Title bar height stays on General > Layout (**call**: not asked for).

## Readers that copy values

How each place that takes half a font, or copies one, meets the rule:

| Reader | Today | After |
| --- | --- | --- |
| Chat (`chatframe.lua`) | The font's face and outline at chat's own Font size (`chat.fontsize`), shadow forced off, by `SetFont` on Blizzard's chat frame | Font is a font row with dots; **Font size goes** (answer 3: no override on a shared font). Chat's frames take `st:FontValues(chat.font)` whole, again from `OnFontsChanged`. A one-time conversion (`chat.fontsVersion = 1`, the architecture doc's marker rule) writes chat's look as a typeface when it differs from its shared font's (its size, or a shadow other than 0, 0), then clears `chat.fontsize`. As shipped (Text 16, Font size 16) nothing is written and chat follows Text (**call**) |
| Tooltip (`tooltip.lua`) | The font's face, size and outline copied onto each line as it shows | `st:FontValues`, the same three. Shadow and spacing stay Blizzard's (Non-goals) |
| RestedXP (`restedxp.lua`) | Chat's font's face and outline at RestedXP's sizes; the guide title from Huge title | The same from `st:FontValues(chat.font)`, again from `OnFontsChanged`; the title from Heading |
| Buffs and debuffs (`Blizzard_BuffFramePosition.lua`) | A private font object per frame and text, set from a copied face | Their objects set from `st:FontValues(st:FaceFont(font, size, outline))`, so a shared font is followed, again from `OnFontsChanged` |
| Action bar texts (`buttons.lua`) | `SetFont` on the hotkey, count and macro texts | `st:ApplyFont` with `st:FaceFont(...)` |
| Action bar cooldown numbers (`skin.lua`) | Small text or Large numbers by button size, then `SetFont` over it once any of font, size or outline is set | The bar's value or, unset, the shared font by size, through `st:ApplyFont`; no `SetFont` |
| Totem bar (`totemskin.lua`, `totemtimers.lua`) | Button text's font, with the shadow forced off | Button text's font as it is (**call**: Small text's shadow is 0, 0, so nothing changes until a player sets one, and then it shows) |
| Button text, Check box labels | Read when the frames are built | `st:FollowFont`, at once |
| Window titles (bags, `/sui`, color picker) | Bags at once, `/sui` on its next draw, the color picker on its next update | At once |
| Blizzard's tracker, SaftUI's tracker, loot, Skinning, unit frames, bags | `SetFontObject(st:GetFont(...))` | `st:ApplyFont`, as it is now plus Text when a value names nothing |

## Unit frame profiles, Copy from and the history

A unit frame profile has about ten font settings per unit (name; health, power and additional power text;
cast bar text and time; aura and buff and debuff counts; the plates' subtext and threat). Each is a font row
with the caller's `get` and `set` (the element's tab `set` runs `UF:UpdateConfig(unit, '<Element>')`), so a
typeface or a dots change re-applies that element on every frame of the unit, plates included. A plate that
changes kind re-applies its config's fonts with the rest (`UF:ApplyPlateConfig`).

- **Defaults** stay strings at every level (above), so the `**` defaults never touch a typeface table.
- **Copy from** (`UF:CopySettings`) copies each element's table deep (`CopyValue`, `st.tablecopy(value,
  true)`), typeface tables with it, so two units never share one. Nothing changes; a test pins it.
- **The history.** Copy from's step keeps deep copies as `old` and `new`, and `History.Same` compares
  tables deeply, so an undo puts a typeface table back whole and a stale check sees a changed one. When
  `/sui`'s settings join the history (decision 32's second part), a font setting is one value: the dots
  menu writes a whole new value through the row's `set`, so one menu change is one change of the setting.
- **Export and Import** carry the tables as plain data; `st:MigrateTemplateKeys` finds no template key in
  one.
- The health and power texts' own color goes on after `st:ApplyFont`, as after `SetFontObject` today;
  typeface objects are white like the shared fonts.

## Phases

Each phase is one task, with its tests, and passes `tests/run`. Each updates the docs its files are covered
by (`agents-doc-parity-check`): `.agents/architecture.md` (Fonts, the readers), `.agents/edit-mode.md` (the
font row, the Fonts and Theme tabs), and the design system (`docs/design-system/README.md`'s Type table,
`tokens.json`'s font usages, the Icons and Select components, Code change 3 marked as taken up by this
design), whose artifact is republished when `docs/design-system/` changes. Order: 1, 2, 3, then 4 and 5 in
either order, then 6.

**Phase 1: the shared fonts and their values** (Core: `Media/fonts.lua`, `Config/defaults.lua`,
`Config/generators.lua`'s list, `Media/sharedmedia.lua`). `FN.FONTS` with names and jobs in code;
`heading` added, `pixel_huge` and `normal_med` dropped, `FN.DROPPED`; objects named by key and made from the
fixed list; `FN:SetObject`; `st:GetFont` taking both shapes, the typeface objects, `st:ApplyFont`,
`st:FontValues`, `st:FontLabel`, `st:IsSharedFont`, `st:FaceFont`, `st:FollowFont` and `st:RefollowFonts`,
`st:FontsChanged` and `OnFontsChanged` (the Tracker's hook moved onto it). Every face SaftUI registers is set
once on a hidden font object at Core's load (the font demo's preload, which loaded every candidate), so a
first pick mid-session draws (G1 says whether other addons' faces need the same, from LibSharedMedia's
register callback). The old select lists the six names in order. Names in text: `textoptions.lua`'s
sentence ("Large numbers' <field> on buttons of 36px and up, Small text's below (Global settings >
Fonts)"), `tests/actionbars/page_test.lua`. Tests: a new `tests/core/fonts_model_test.lua` (every kind of
string, a dropped key with and without saved edits, a partial table, nil; one object per look, white, the
size nudge on both kinds; the values and labels; `ApplyFont` never errors; `FollowFont` and
`FontsChanged`); `apply_defaults` keeping a table under a string default; `fonts_tab_test.lua` for the
fixed sections and a profile holding a saved `fonts.pixel_huge`.

**Phase 2: the Fonts tab** (Core: `Media/fonts.lua`, `Config/optionsbody.lua`). The tab as above: the top
line, sections in order with their notes, the renamed rows, sentence-case outlines, per-setting resets, no
Name, Kinds of text last with its two rows (Window titles still among them until phase 5). `/sui`'s titles
from Heading's face and outline; `OW:UpdateFonts` from Config's `OnFontsChanged`. Tests:
`fonts_tab_test.lua` (rows, order, resets, a change reaching its object, `/sui`'s fonts and a module's
`OnFontsChanged` at once), an options body check that the section title takes Heading's face.

**Phase 3: the font row** (Core's options kit: a new type file before `optionsposition.lua`, `load.xml`,
`tests/lib/shell.lua`'s list; `optionslist.lua`, `optionsmenu.lua`, `optionsshare.lua`, `optionsmodel.lua`,
`optionswindow.lua`'s `OW:Reveal`; `constants.lua`'s `st.icons.link` and its TGA). The row, the list, the
dots and menu, the link, `faceOnly`, resets, shares and search as above, under Thick, Thin and Blizzard.
Every one of the 18 sites gets it; a typeface picked on any of them draws already, since their readers call
`st:GetFont` (chat still at its own size until phase 4). Tests: a new `tests/core/options_font_test.lua`
(the row in both looks and its slot; the list's headings, order, faces and blue pick; a shared pick saving
a key, a typeface pick saving a table filled from what showed, a face swapped keeping its options; the
dots opening five rows; a menu change calling the caller's `set` with a new table and leaving the old one
as it was; the link's tooltip and its click landing on the Fonts tab with that font's Typeface row in view
and lit, closing a menu; `faceOnly` hiding and showing its neighbours; reset and share texts; whole pixels
with size noise through `tests/lib/pixels.lua`); `config_generators_test.lua`; the options validate and
desc tests.

**Phase 4: every reader on the rule** (every addon; the plan may split it into Core and Misc, then the
rest). `st:ApplyFont` at every reader of a font setting; the value readers on `st:FontValues` and
`OnFontsChanged`; chat's conversion and its Font size row removed; the action bars' texts and cooldown
numbers without `SetFont`; the totem bar's forced shadow gone; Button text, Check box labels and the color
picker's title following at once; the `:SetFont(` scan test. Tests: chat's conversion (as shipped: nothing
written; a changed size or Text shadow: a typeface; run twice: nothing more), a Small text change reaching
hotkeys, totem texts and buff timers that follow it, the Kinds of text rows at once, the Tracker's
`OnFontsChanged` in `tests/tracker/refresh_test.lua`, Copy from carrying a typeface (`tests/unitframes/`),
the scan.

**Phase 5: Heading's defaults and Window titles in Theme** (Core's Theme and Fonts tabs, `panels.lua`;
Bags; Tracker; Misc's RestedXP). The two defaults; the bags' search box and footer texts on Text; the Theme
tab's Window titles section; Kinds of text down to two rows; RestedXP's title from Heading. Tests:
`theme_tab_test.lua` (the section, its reset, a set reaching every header title, `/sui`'s Blizzard title
bar and the color picker's title at once), `fonts_tab_test.lua`, the bags' title, search box and footer
fonts, the tracker's Header font default and its reset text.

**Phase 6: the action bars' and buffs' font lists** (ActionBars: `textoptions.lua`, `options.lua`,
`skin.lua`; Misc: `Blizzard_BuffFramePosition.lua`). Their Font rows become `faceOnly` font rows: the
shared fonts first, Size and Outline hidden while one is picked, the link beside it; the cooldown numbers'
unset Font showing the shared font their buttons' size gives; shares unchanged (font, size and outline each
shared as now). Tests: `tests/actionbars/page_test.lua`, `shared_settings_test.lua`,
`cooldown_numbers_test.lua`, the buff frame's.

**Followups.** "Fonts: separate the fonts users pick per kind of text..." moves to Resolved when phase 6
lands (it is taken up whole). The items under Later become followups as phase 6 ships.

## In-game checks

- **G1.** A typeface no text uses yet, picked mid-session for a unit frame's name, draws at once, and its
  list entry is in its face. Again for a face another addon registers. If not, every face LibSharedMedia
  lists is preloaded at load and on its register callback.
- **G2.** An action bar hotkey switched Small text, then Colus, then Small text follows each, with no
  reload.
- **G3.** The bags' category titles in Colus 15 sit right in their band, down to its least height (20),
  and the tracker's header line and zone headers lay out (the tracker measures its texts).
- **G4.** Heading's face changed on the Fonts tab reaches `/sui`'s titles at once, nothing clipped.
- **G5.** Chat looks the same after the upgrade, with Text unchanged and with Text's size changed first.
- **G6.** The zone name is Huge title at 72, and its subtitle lines as before.
- **G7.** The link lands the Fonts tab on the right section, at full and half size, from a page and from
  the action bars' text menu.
- **G8.** The dots menu over a unit frame page: a Size drag follows on the frame as it moves.

## Risks

1. **A face that doesn't draw the first time it's picked.** The font demo found that a font string's
   `SetFont` fails for a file the game hasn't loaded, while font objects set at load work. Contained:
   typefaces are always font objects, SaftUI's faces are preloaded, and G1 says whether more must be.
2. **A text stuck on a face.** Contained: no `SetFont` on SaftUI's texts, and the scan test.
3. **AceDB merging into a typeface table.** Checked against AceDB's code (above) and tested in phase 1.
4. **A dropped key in a profile.** Contained: the fixed list and the alias; tested with a saved table.
5. **The kit's item branches.** The share, reset, search and body code test `row.type == 'item'` in several
   places (audit section 6); the font type needs its own branches where it opens a menu. Contained: phase
   3's tests run the menu under both looks with a share on the row.

## What's left to the builder

- The helpers' exact names, the type's file name, how a typeface entry's key is kept apart from a shared
  font's in the list, and the shape of `st:FollowFont`'s list.
- How `OW:OpenMenu` is given the font row's menu (the type builds its menu root from the row rather than an
  option's `menu` field), and the dropdown's exact offset from the slot under each look.
- Exact words of descs and tooltips, within the gist above.
- Which code that names a key directly moves to `st:ApplyFont`.
- How far the preload goes, after G1.
- The tests' structure and each task's in-game checklist.

## Later

- The action bars' and buffs' texts default to Small text, with a conversion that writes today's copy
  (Homespun 10, Monochrome outline) into any text that set one of font, size or outline, so they keep their
  look (the audit's recommendation; fixes discrepancy 2 by default rather than by a pick).
- A reset on every font row (`generators.font` given the default, building `default` through the
  inherited `get` and `set` as the number inputs do).
- A window title font per theme, falling back to Window titles.
- The tooltip lines taking SaftUI's shadow and spacing (decision 22's consistency).
- Title bar height beside Window titles on the Theme tab.
- Search into the dots menus.

## Where the audit is out of date or falls short

Line numbers below are at `ccfb21f`. Items 1 and 2 are wrong or stale; 3 to 7 are gaps this design had to
fill.

1. **The tracker's header fonts moved.** The audit cites `SaftUI-Tracker/window.lua:446-500`; since tracker
   task 6 merged they are at `window.lua:501-560` (`header.title`, `header.count`). `rows.lua:167-168` still
   holds.
2. **Window titles doesn't all apply at once.** The audit's table gives `headers.font` "at once". The bags'
   titles do (`st:UpdateHeader`); `/sui`'s title bar under Blizzard takes it on its next draw; Blizzard's
   color picker's title only on the skin's next update, as its own comment says
   (`Blizzard_ColorPicker.lua:574-577`).
3. **Dropping two fonts is more than two lines in `defaults.lua`.** The Fonts module builds an object for
   every key in the profile's `fonts` (`fonts.lua:37`) and `st.Config:GetFontObjects` lists every one
   (`generators.lua:5`). A profile that ever saved an edit to Pixel Huge or Normal Med keeps that partial
   table after the default goes, with no `name`, and `CreateFont('SaftUI_'..config.name..'Font')` would
   fail on it. Both have to walk a fixed list.
4. **Renaming names only isn't enough once the Name row goes.** The audit's "names only" plan changes the
   defaults' `name` and keeps a profile's edited name. With answer 7 a player can't edit it any more, so an
   old edited name would be stuck; the names have to come from code, and the objects' global names from the
   keys.
5. **Chat's Font size is an override of a shared font**, which answer 3 rules out; the audit's shape A kept
   it beside the row. Folding it in is the one conversion here.
6. **The bags' search box follows Title font** (the audit lists it, `inventory.lua:215`), so defaulting
   Title font to Heading would put Colus in it; the audit's Heading row doesn't mention it.
7. **Font lists' headings.** The audit (section 6, point 3) calls a list with "SaftUI fonts" and
   "Typefaces" headings cheap. It is, but a heading in a list drawn in faces is set with `SetFontObject`
   after a face's `SetFont` on a pooled row (`optionslist.lua:59-68`), which in game keeps the face: it must
   be set outright.

Everything else this design leans on checked out: the 18 `generators.font` sites, the dropped fonts'
lack of readers, the `SetFont` list, `/sui`'s `FONTS` table and its profile-change-only refresh, every
`headers.font` reader, the tracker's `header_font` covering its header line and zone headers, and the Kinds
of text rows' reload notes.

## Questions for the owner

1. **The tracker's Header font is its header line too.** `tracker.header_font` sets the "Objectives" line
   and the quest count at the tracker's top as well as the zone headers. As written, Heading takes both. The
   other way is a separate Zone header font, a new setting defaulting to Heading, with Header font staying
   Text.

   **Answered (Settled 2):** as written. Heading takes both.
2. **Did you ever change Colus's face on the Fonts tab?** `/sui`'s titles have followed it. As written,
   Heading starts as Colus whatever Huge title holds, so a changed face would leave `/sui`'s titles. If you
   did, Heading can start from Huge title's face instead, once, at upgrade.

   **Answered (Settled 3):** not known, so both cases are covered: Heading starts from Huge title's face
   once, at upgrade, when the profile holds a changed one, else Colus.

## Calls made while writing this

Ordered by how much the owner is likely to care.

1. **Chat's Font size goes**, folded into its font row, with a one-time conversion that keeps chat's look
   where it differs from its shared font; as shipped nothing is written and chat follows Text.
2. **Window titles is one setting for every theme**, still saved as `headers.font`, in a Window titles
   section after Options windows on the Theme tab.
3. **`/sui`'s titles take Heading's face and outline at their own sizes** (34, 26, 18, 15, 13, 11); Heading's
   size isn't read by `/sui`. Labels and fields keep Text's face.
4. **The bags' search box takes Text**, no longer following Title font; Title font is the category titles
   only.
5. **The bags' gold and free-slot texts take Text**, no longer following Window titles.
6. **Blizzard's tracker's Header font stays Text.**
7. **Names:** Text, Small text, Large numbers, Heading, Huge title, Subtitle, in that order on the tab and
   in every list; names and jobs in code, a profile's saved name ignored, objects named by key.
8. **A dropped font named by a setting reads as the typeface it looked like** (its old default with the
   profile's own edits), and nothing is written until the player changes it.
9. **A typeface is saved as a table with a shared font's own field names**; every default stays a string.
10. **Picking a typeface fills its options from what the row shows**, so only the face changes.
11. **One font object per typeface look, never changed;** the dots menu writes a whole new value through
    the row's `set`, never editing the saved table.
12. **The dots menu holds Size, Outline, Shadow offset X and Y and Line spacing on every row**, with the
    Fonts tab's ranges and no resets of their own.
13. **The link icon is Lucide's `link`**, in the dots' slot, opening the Fonts tab at that font as a search
    result does.
14. **A new kit type, `font`**, with a `faceOnly` mode for the action bars' and buffs' texts; the only font
    row allowed in an item's menu.
15. **Search finds font rows, not their menus' rows.**
16. **Kinds of text keeps Button text and Check box labels**, after the shared fonts on the Fonts tab, both
    applying at once.
17. **The Fonts tab's rows are renamed** Typeface, Size and Outline, outline names go to sentence case,
    every row gets its own reset, and a line at the top says what shared fonts are.
18. **Every font setting applies at once** (`st:FollowFont`, `OnFontsChanged`), `/sui`'s own fonts too.
19. **RestedXP's guide title takes Heading's face.**
20. **The totem bar no longer forces its texts' shadow off.**
21. **The tooltip keeps Blizzard's shadow and spacing on its lines.**
22. **SaftUI's own faces are preloaded at load**; other addons' only if G1 needs it.
23. **The action bars' and buffs' texts keep their saved shape and their copied faces**; moving them onto
    Small text is Later.
24. **Font rows that have no reset stay without one** in this work.
25. **Title bar height stays on General.**
26. **"Text" names both a shared font and a color**, on their own tabs.
27. **The phases' order:** values, Fonts tab, the row, then readers and Heading's defaults in either order,
    then the action bars' and buffs' lists.

## Settled with the owner after the draft (2026-11-14)

These override anything above that they contradict.

1. **The design is approved.** "I'm good with all of those suggestions, if any feel off we can adjust".
   Every call under "Calls made while writing this" (1 to 27) stands as written.
2. **Question 1: Heading takes both.** `tracker.header_font` stays one setting, defaulting to Heading,
   for SaftUI's tracker's header line ("Objectives" and the quest count, `window.lua`) and its zone
   headers (`rows.lua`). There is no separate Zone header font.
3. **Question 2: both cases are covered.** Whether the owner ever changed Colus's face is not known. At
   upgrade, Heading's face starts from Huge title's face when the profile holds a changed one (a face
   other than Colus), as a one-time step marked in the profile; otherwise Heading's face is Colus. The step
   leaves a Heading face the player already set alone, and runs once for each profile, the first time it
   loads (a profile switched to, copied or imported later included). `/sui`'s titles therefore keep the
   face they show today in either case. This replaces "then they go back to Colus, from Heading" under
   "What changes on screen at upgrade", which now says so.
