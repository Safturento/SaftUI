# Unit frames: small parts on General, and settings shared across units

Design, 2026-11-15. It comes from the brainstorm with the owner that day (the decisions and his words are in
`.superpowers/brainstorm/unitframes-decisions.md`; the mockup is `.superpowers/brainstorm/unitframes-v2.html`,
panel 2 the Parts as half rows, 2b full rows with the Name menu open, 3 B "All units", 4 what moves where). It
takes up the followup "Unit frames: shared settings across units, and small parts as menu items" (2026-11-13).
Every decision the owner didn't make is marked **call** and listed again under "Calls made while writing this".

Checked against SaftUI's code on `modular` at `92b88402`. The audit below was run on that commit (a throwaway
test in the session's scratchpad, as the reset design's audit was). Nothing here has been checked in game; the
checks it needs are G1 to G14 under "In-game checks".

Assumed done before this work starts: **Position is the second section on every `/sui` page**, a separate
small change the owner asked for in the same brainstorm ("feels too important to be at the bottom"). This
design keeps to it everywhere, item menus included.

Words used below:

- **Unit**: a config unit, one entry of the Unit picker (`player`, `target`, ..., `boss`, `party`, `raid10`,
  `raid40`, `nameplate`, `friendlynameplate`). Arena has defaults and no page; it is left as it is.
- **Member**: a unit that follows All units. The eleven units with a page that are not nameplates.
- **Part**: one of a unit frame's texts, icons or small pieces, drawn as one row in the Parts section.
- **Setting**: one value row of a page, a row in a part's menu included. A shared setting has one key, the
  dotted path of what it saves below the unit (`name.font`, `health.text.position`, `frame.theme`).
- **Stored value**: what the unit frame profile holds at the unit's path
  (`unitframes.profiles.<profile>.<unit>.<path>`), which every unit frame reader reads.
- **Own**: a member's setting that does not follow All units.

## Why

`/sui` > Unit frames has a page per unit, and each page a tab per element: Player has 13 (General, Health,
Power, Additional power, Class power, Name, Castbar, Buffs, Debuffs, Raid target, Raid role, Group role,
Quest), which wrap to two lines. Four of them hold six settings each. And there is no way to give the unit
frames one look: a player who wants another name font sets it on eleven pages.

The action bars solved both on 2026-11-13: an "All bars" entry every bar follows, own marks and a hover line
for what a bar sets itself, and small parts as one row with a menu. The owner, of the unit frame version of
that mockup: "the unitframe change is great", and of Apply to: it "is widely used for options across the
action bars (we could also use it elsewhere, like a lot of unit frames changes)".

## What the owner decided

From the brainstorm of 2026-11-15 (his words in quotes):

1. A unit's texts, icons and small parts are rows in a **Parts** section on its General page, each with a
   dots menu holding all of the part's settings; Health, Power, Cast bar and Auras keep tabs. "Five tabs for
   Player, from 13."
2. Parts are **half rows** in the full-size window: "lets go with half rows". One to a line at half size.
3. **Position is the second section**, not the last, on every page with one: "feels too important to be at
   the bottom". (Done before this work.)
4. **Health text and Power text** are Parts rows **and** shown under the Health and Power tabs, "for
   convenience": one setting, two places.
5. **Class power and Additional power** are Parts rows for now: "play it by ear - once one of these expanded
   menus gets too big that can be the point when we shift". The design states the rule and makes the shift
   cheap.
6. **A row never changes height or moves anything on hover** (a mockup bug, fixed in v2).
7. **Sharing model B, All units**: "Lets go with B, apply to is always there if a user wants to be specific".
   One All units entry first in the Unit picker, as the action bars have All bars; own marks, the diff icon,
   the hover line; Apply to stays on each shared setting.
8. Told to him with no objection: the position summary in a half cell shows the anchor only, the full
   position in its tooltip; Name's six toggles stay toggles.

## Goals

- A unit page of five tabs, its small parts as rows on General, with every setting it has today still on it.
- One place to set the unit frames' look, and per unit, per setting, the freedom to differ.
- **Nothing changes on screen at the upgrade**, on an untouched profile or a customized one: every unit keeps
  the values it shows today.
- Every value row keeps a reset; the strict reset coverage scan stays passing.
- Search finds every setting, a setting in a part's menu included, and opens it.
- The kit pieces stay generic: Core names no unit, no part and no "All units".
- Moving a part between a row and a tab is one line.

## Non-goals

Each related project has its followup:

- Test mode choosing which elements its previews show: "Test mode: choose which elements the previews show"
  (2026-11-13).
- Edit mode movers for parts placed on the screen: "Edit mode movers for unit frame parts placed on the
  screen" (2026-11-09). A part's summary says "Screen" for them; nothing more.
- A first-run setup dialog: "A first-run setup dialog: UI size, theme, unit frame layout" (2026-11-14).
- Unit frame presets (layouts shipped as data): the same entry's "a way to ship unit frame layouts as data".
  A preset is a unit frame profile, so it carries its own All units (section 4.10).

And:

- Nameplates following All units (**call**, section 4.9; a new followup).
- Moving Position second (the earlier change).
- The aura filters (whitelist, blacklist, time), which have no row today and get none.
- Changing any default value.
- Every shared row keeping still on hover, outside the part rows (question 5; a followup if he says yes).

## Anti-goals

- Anything on screen changing at the upgrade, or a unit changing because All units changed a setting the unit
  owns.
- A layout, size or show on a secure frame in combat outside the existing queue (`.agents/taint.md`):
  everything new here is table writes, and frames change only through `UF:UpdateConfig`, which waits for the
  end of combat as it does today.
- A second copy of a default, or a reset that writes past a row's own `set`.
- State that can only be seen on hover: own and "a unit differs" are always visible; the hover line only
  offers actions.
- Core's options kit knowing about unit frames.
- A change under any `Libraries/` (oUF included).

## The audit

### How it was done

A throwaway test (`config_test.lua`'s world: the real defaults filled as AceDB fills them, the real element
files and option tables) built `UF:GetConfigTable()`, walked every unit's page with `each_option`, counted the
value rows per tab, and for each row read its saved path from its `saved` and its default with `st:DefaultAt`,
for each unit and for a unit named `all` (what AceDB's `'**'` gives a key no unit's file names).

### The tabs and their rows today

Value rows per tab (the pick line's Copy from, Profile and Manage are not counted).

| Unit | Tabs | General | Health | Power | Add. power | Class power | Name | Castbar | Buffs | Debuffs | Raid target | Raid role | Group role | Ready check | Quest | Others | Rows |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Player | 13 | 6 | 30 | 27 | 25 | 11 | 12 | 27 | 24 | 23 | 6 | 6 | 7 | | 6 | | 210 |
| Target, Focus | 11 | 6 | 35 | 31 | | | 14 | 27 | 24 | 23 | 6 | 6 | 7 | | 6 | | 185 |
| TargetTarget, FocusTarget, PetTarget | 10 | 6 | 35 | 31 | | | 14 | | 24 | 23 | 6 | 6 | 7 | | 6 | | 158 |
| Pet | 11 | 6 | 31 | 28 | | | 12 | 27 | 24 | 23 | 6 | 6 | 7 | | 6 | | 176 |
| Boss | 11 | 9 | 32 | 28 | | | 13 | 27 | 24 | 23 | 6 | 6 | 7 | | 6 | | 181 |
| Party | 12 | 16 | 31 | 28 | | | 12 | 27 | 24 | 23 | 6 | 6 | 7 | 6 | 6 | | 192 |
| Raid 10, Raid 40 | 12 | 15 | 31 | 28 | | | 12 | 27 | 24 | 23 | 6 | 6 | 7 | 6 | 6 | | 191 |
| Enemy nameplates | 10 | 7 | 34 | | | | 14 | 27 | 24 | 23 | 6 | | | | 6 | Threat 4, Subtext 7 | 152 |
| Friendly nameplates | 9 | 6 | 34 | | | | 14 | 27 | 24 | 23 | 6 | | | | 6 | Subtext 7 | 147 |

2284 value rows on 13 pages. A tab's rows differ by unit where an option shows only for the kinds of unit
the frames can show (`UF.CanShow`: Classification, Class color, Color friendly, Boss percent, the color
flags).

### The parts and their settings

| Part | Element (config key) | Units | Settings today (its tab) |
| --- | --- | --- | --- |
| Name | `Name` (`name`) | all 13 | Enable, All caps, Font, Show level, Show same level, Show max level, Classification¹, Class color¹, Color hostile, Color friendly¹, Max length, Max width, Alpha, Position |
| Health text | `Health` (`health.text`) | all 13 | Enable, Hide full, Font, Deficit, Percent, Short, Boss percent¹, Text color, Text position (the Health tab's Text section) |
| Power text | `Power` (`power.text`) | not the plates | Enable, Hide full, Font, Percent, Short, Text color, Text position (the Power tab's Text section) |
| Raid target, Raid role², Quest, Ready check³ | the indicators (`raidtargetindicator`, ...) | all 13; ² not the plates; ³ Party, Raid 10, Raid 40 | Enable, Size, Theme, Background, Alpha, Position |
| Group role | `GroupRoleIndicator` | not the plates | the same, and Show damage dealers |
| Class power | `ClassPower` | Player | Enable, Theme, Background, Alpha, Frame level, Spacing, Width, Relative, Height, Relative, Position |
| Additional power | `AdditionalPower` | Player | Enable, Reverse fill, Vertical fill, Smooth, Theme, Background, Alpha, Frame level, Width, Relative, Height, Relative, Power type, Custom color, the mana text's Enable, Hide full, Font, Percent, Short, Text color, Text position, Bar background's Enable, Brightness, Alpha, Position (25 rows, two position blocks) |
| Subtext | `Subtext` | the plates | NPC titles, Player guilds, Font, Color, Alpha, Max width, Position (no Enable: it is always on) |
| Threat | `Threat` | Enemy nameplates | Enable, Font, Alpha, Position |

¹ only where the unit's frames can show such a unit (`UF.CanShow`).

### Every setting's default, by unit

The appendix lists every setting saved under a part or a bar, and the frame's Theme and Background, with its
every-unit default and the members whose own default differs. What it shows:

- **187 settings exist on two or more members**: 181 saved at one key, and 6 rows with a hand default (the
  Health and Power bars' Custom color, the Health and Power texts' Text color, the Buffs and Debuffs border).
- **Most have one default on every member.** Where members differ it is for a reason the frame's place or
  size gives: Player's power bar, cast bar, class power and additional power are placed on the screen and
  sized to it; Target's, Focus's and Boss's auras grow from the other side; the groups have short centred
  names, deficit health texts and small, many auras; Raid 10 and Raid 40 draw in the theme with Solid.
- **The frame's own settings differ on every unit**: Width (nine values over eleven units), Position (eleven
  of eleven), Enable (FocusTarget and PetTarget off), and the groups' Layout and Range.
- **Single-unit parts**: Class power and Additional power are Player's alone, Subtext the plates', Threat the
  Enemy plates'. Ready check is the three groups'.
- **The value most members show** is the every-unit default for every setting but one: Debuffs > Enable (on
  for six of eleven, off by default).
- A fresh profile converted by section 4.6 owns **156 settings** across the eleven members: Player 29, Target
  19, TargetTarget 2, Focus 21, FocusTarget 2, Pet 2, PetTarget 2, Boss 10, Party 19, Raid 10 25, Raid 40 25.

## The design

### 1. The page after

#### The Unit picker

All units first, then the units in today's order (`UNIT_ORDER`: Player ... Raid 40, Enemy nameplates,
Friendly nameplates). The pick line reads Unit, Profile, Manage (Copy from goes: section 4.11).

#### Tabs

| Unit | Tabs |
| --- | --- |
| All units | General, Health, Power, Cast bar, Auras |
| Player | General, Health, Power (second row: Power bar, Additional power), Cast bar, Auras |
| Target, Focus, Pet, Boss, Party, Raid 10, Raid 40 | General, Health, Power, Cast bar, Auras |
| TargetTarget, FocusTarget, PetTarget | General, Health, Power, Auras (oUF has no cast bar for a unit's target) |
| Enemy nameplates, Friendly nameplates | General, Health, Cast bar, Auras (no power bar on a plate) |

- **Auras** has a second tab row, **Buffs** and **Debuffs**, each today's tab as it is (**call**: two sets of
  five sections of the same titles, four position blocks, on one page would read badly; the kit's second tab
  row exists for this).
- **Additional power** is a page under Power on Player, by the rule in section 2.7 (**call**, question 1): its
  menu would be about 1070 tall. Under Power because it is a power bar; so Player keeps five tabs.
- **Cast bar** is the tab's name, two words (it is "Castbar" today); its element and saved keys stay
  `Castbar` and `castbar`.

#### General

Sections, in order (**call** on the order of the last ones):

1. **Frame**: Enable, Theme, Background, Width, Height (today's untitled first line, now titled). All units
   has Theme and Background only.
2. **Position**: the frame's (not on All units: a place is each unit's own).
3. **Layout** (Party, Raid 10, Raid 40, Boss) and **Range** (Party, Raid 10, Raid 40), as today.
4. **Parts**, its note: "Each text, icon and small part of the unit frame. The dots open its settings."

The nameplate pages keep their own General (section 4.9), with a Parts section last.

#### Parts rows, unit by unit

Half rows, in reading order (left, right, next line). The order is fixed (**call**): Name, Subtext, Health
text, Threat, Power text, Class power, Raid target, Raid role, Group role, Ready check, Quest; a unit lacks
what it doesn't have.

| Unit | Parts (in order) | Lacks |
| --- | --- | --- |
| All units | Name, Health text, Power text, Raid target, Raid role, Group role, Ready check, Quest | Subtext, Threat, Class power, Additional power |
| Player | Name, Health text, Power text, Class power, Raid target, Raid role, Group role, Quest | Ready check, Subtext, Threat |
| Target, TargetTarget, Focus, FocusTarget, Pet, PetTarget, Boss | Name, Health text, Power text, Raid target, Raid role, Group role, Quest | Class power, Ready check, Subtext, Threat |
| Party, Raid 10, Raid 40 | Name, Health text, Power text, Raid target, Raid role, Group role, Ready check, Quest | Class power, Subtext, Threat |
| Enemy nameplates | Name, Subtext, Health text, Threat, Raid target, Quest | Power text, Raid role, Group role, Ready check, Class power |
| Friendly nameplates | Name, Subtext, Health text, Raid target, Quest | the same, and Threat |

#### What each part's menu holds

The menu is titled with the part's name. Its first section is the part's settings, laid out two small rows to
a line (section 6, K4); its second is the Position block, whole, TO dropdown and name box included. The part's
Enable is the row's check box and is not in the menu.

| Part | Menu (first section, in today's order), then Position | Height (Thick, about) |
| --- | --- | --- |
| Name | All caps, Font, Show level, Show same level, Show max level, Classification¹, Class color¹, Color hostile, Color friendly¹, Max length, Max width, Alpha (the toggles stay toggles: decision 8) | 490 on Target |
| Health text | Hide full, Font, Deficit, Percent, Short, Boss percent¹, Text color; Text position | 375 |
| Power text | Hide full, Font, Percent, Short, Text color; Text position | 340 |
| Raid target, Raid role, Quest, Ready check | Size, Theme, Background, Alpha | 340 |
| Group role | Size, Theme, Background, Alpha, Show damage dealers | 375 |
| Class power | Theme, Background, Alpha, Frame level, Spacing, Width, Relative, Height, Relative | 450 |
| Subtext | NPC titles, Player guilds, Font, Color, Alpha, Max width (no box: `reserveBox`) | 375 |
| Threat | Font, Alpha | 260 |
| Additional power, were it a row | everything on its page today but Enable: 17 lines, five section titles, two position blocks | 1070 |

The text parts' position keeps its name, Text position (**call**: the same option is drawn on the Health and
Power tabs, where "Position" is the bar's).

#### The tabs

- **Health**: the bar's settings (Enable, Reverse fill, Vertical fill, Smooth, Theme, Background, Texture,
  Alpha, Frame level, the size line), Position, Colors, **Text** (section 3: the Health text part's settings,
  its Enable first), Bar background.
- **Power**: the same shape. On Player its second row is **Power bar** (all of that) and **Additional power**
  (today's Additional power tab, as it is).
- **Cast bar**: today's Castbar tab (Enable, Bar, Spell name, Time, Icon).
- **Auras**: Buffs and Debuffs, today's tabs.

Rows drawn per view fall: Player's General draws 6 rows and 8 part rows (today it is 6, and Name alone is
12); the tabs that go held 48 of Player's 210 rows (Name 12, Class power 11, the four icons 25), Additional
power's 25 move under Power, and the texts' sections are now both a part and a section. No setting is lost:
every row of the audit has a home in the tables above.

### 2. The part row

A part row is the kit's menu item (`type = 'item'`) with four things added (section 6): a summary, a reset
that covers its menu, a share that covers the whole part, and a hover line that keeps still.

#### 2.1 Anatomy

In a half cell (full size, Thick and Thin: the slot 387, the cell 359 inside the panel's 14 of padding;
Blizzard: the cell 367, no padding), left to right, centred on the 38 row (34 under Blizzard):

| Piece | Where | Size | Look |
| --- | --- | --- | --- |
| Own mark | `markX` in from the slot (5, inside the padding; 0 under Blizzard), 6 in from the top and bottom | 2 wide (two lines) | the kit's `OwnMark` |
| Check box | the cell's left (moved `markShift` right when marked) | 18 (Blizzard's art 23 x 22) | the kit's toggle, its Enable |
| Label | 26 in (`w.labelX`) | its text, cut last | `label` 16, Text > Normal; Text > Muted while the part is off; the accent when own |
| Diff icon | 4 after the label's text (All units) | 16 | the kit's `DiffIcon` |
| Summary | right-aligned, ending 6 before the reset icon, or before the dots without one | what is left after the label and 12; hidden under 24 | `field` 15, Text > Muted, cut with an ellipsis |
| Reset icon | right against the dots | 14 | the kit's `ResetIcon` |
| Dots | the cell's right edge | 16 x 24, `ellipsis-vertical` 16 | the kit's item dots |

At half size the row is a whole line (the body 388, the cell 360; under Blizzard 368): the same pieces, the
summary with more room. Every edge is a whole pixel, as the body's cells are.

#### 2.2 States

The look of each state is the interaction states design's (`docs/superpowers/specs/2026-11-15-saftui-interaction-states-design.md`),
by its helpers, and nothing here draws its own:

- the row: **Row** shape (`st:AddStates(rowFrame, 'row', { bar = false })`, hover by `st:SetState(rowFrame,
  'hover', ...)`): its hover Layer while the mouse is on it. It is never Selected: an open menu is the dots'
  state, so no state bar meets the own mark at the row's left (**call**);
- the check box: **Check box** (`Kit.CheckBox`, as every toggle);
- the dots and the reset icon: **Bare glyph**; the dots drawn selected (the accent) while the part's menu is
  open;
- disabled (a nameplate page standing down for another nameplate addon): Alpha d on the whole row, as every
  row. (A plate page's box hides the part rows instead: 4.9.)

A click on the row anywhere but its check box, the dots, the reset icon and the hover line's links opens its
menu, as the dots do (**call**: the hover Layer says the row can be clicked). Nothing changes height or moves on
hover (decision 6): the Layer is drawn inside the row, and the hover line takes the summary's place (2.5).

#### 2.3 The summary rule

The summary is the **anchor** of the part's Position, one word or name (decision 8):

- an element the unit frame has: that element's name as the page names it: Health, Power, Cast bar, Name,
  Buffs, Debuffs, Class power, Raid target, ...;
- a Global frame that is UIParent: **Screen**;
- another frame: the unit whose frame it is (SaftUI_Player is **Player**), else the name as typed;
- nothing: **Unit frame**.

Its tooltip is the full position, in the words the reset tooltip uses for a unit frame part ("Right of
Health: -7, -1", "Bottom of the unit frame: 0, 0"). It reads the page's own value: on All units, All units'.
A part with no Position has no summary. The summary is not searched and has no mark of its own.

#### 2.4 The reset rule

One reset per row, in every context:

- **On All units and on a page with no sharing** (the nameplate pages, Class power on Player): the row's reset
  icon shows while the part's Enable or any setting in its menu differs from its default, and a click puts
  every one of them back, each through its own row's `set`, the check box first, then the menu's order. Its
  tooltip: "Reset: Name goes back to its defaults: Show, Font, Position." The settings in the menu keep their own
  icons. (**Call**, question 2: the
  owner asked for "a reset icon when anything in the part differs from its default", which this is; decision
  50 kept group resets off pages, and a part is one row, so this design counts it as the row's own reset.)
- **On a member page**: the row's hover line's Reset (2.5), which makes the whole part follow All units again,
  is its reset, as every member row's is (`.agents/edit-mode.md`: a row with a member page's share shows no
  reset icon).

#### 2.5 The hover line

On a member page the part row's line is `Own`, the reset icon, `· Apply to: All | Multiple`, acting on the
**whole part** (section 4.7); on All units it is `Apply to: All | Multiple` while any unit differs in the part.
It **takes the summary's place**: on the label's line, from 12 after the label (or its diff icon) to 6 before
the reset icon or the dots, the summary hidden while it shows. The label does not lift and the row does not
grow (decision 6). Where the line doesn't fit it drops its words as the kit's quarter cells do (`FillLine`:
Own first, then "· Apply to:"), leaving the reset icon and `All | Multiple`.

The rows inside a menu and on the tabs keep the kit's line as it is today (the label lifts) (**call**,
question 5).

#### 2.6 Keyboard, sizes, the bar

No row of the kit takes the keyboard today, and a part row doesn't. Esc closes an open menu, then the window,
as today. At half size the parts are one to a line (`OB.HalfSize`: the item's normal size becomes wide); at
the bar no page is drawn and an open menu closes with the window's other overlays (`S.CloseOverlays`).

#### 2.7 When a part becomes a tab

**The rule** (decision 5's "too big"): a part's menu is too big when, laid out under Thick at full size, it is
taller than the options window's least height, **700** (`OW.LAYOUT.own.height`): it would cover the whole
window with none of the page left to see. A test measures every part's menu on every unit and fails on one
over the rule, naming the part and the line to change.

**Where each part stands** (the table in section 1): every part fits but Additional power, at about 1070
(more than half again over). So it ships as a page, under Power (**call**, question 1). Class power, at about
450, ships as a row.

**The declaration** is `UF.PARTS` in `SaftUI-Unitframes/config/parts.lua`, one line per part:

```lua
{ key = 'additionalpower', element = 'AdditionalPower', name = 'Additional power', place = 'tab', under = 'Power' },
{ key = 'classpower', element = 'ClassPower', name = 'Class power', place = 'row' },
```

`place = 'row'` draws the part in Parts; `'tab'` draws its settings as a tab (its Enable first), at the top
row, or with `under` as a second-row tab of that tab. The settings, their resets, shares and search are the
same option tables either way, so changing the word moves the part and nothing else.

### 3. One setting, two places: Health text and Power text

The Health text part's menu and the Health tab's Text section hold **the same option tables**: the leaves are
one set of objects, and the two groups that hold them (the item's menu, and the tab's inline Text section,
which adds the Enable row the item draws as its check box) read and write the same saved keys through the same
`get` and `set`. So:

- a change in one place shows in the other at the next draw, which every set causes;
- a reset is the same function in both places, and so are the shares, own marks and diff icons;
- **search lists each setting once**, at the part (its canonical home): the Text section carries SaftUI's new
  `mirrorOf` field (`mirrorOf = { 'general', 'parts', 'healthtext' }`, the part's path in the unit page), and
  `OM.Search` skips a group that has one (**call**: the part is the home decided first; a result opens General
  and the part's menu);
- **the reset walk counts it once**: `tests/lib/reset_walk.lua` skips a `mirrorOf` group and checks that each
  of its leaves is the very table (`rawequal`) the part's menu holds, so the two can't drift.

Power text is the same with the Power tab.

### 4. All units

#### 4.1 The model

The action bars' model: a value set on All units is used by every member that has not set its own; a setting
a member changes becomes its own, marked; Reset makes it follow again; Apply to: All and Multiple spread a
value. All units is a page of the picker like a unit's, drawn by the same builders.

#### 4.2 What shares

**The rule** (**call**): *a unit frame's own Enable, size, place and group layout are always its own; its look
(Theme, Background) and everything in its parts and bars is shared, on every member that has it.* So:

| Shared on every member that has it | Each unit's own |
| --- | --- |
| Frame: Theme, Background | Frame: Enable, Width, Height, Position |
| Health, Power, Cast bar, Buffs, Debuffs: every row of their tabs (their Position and size included) | Layout and Test mode (groups and boss), Range (groups) |
| Name, Health text, Power text, Raid target, Raid role, Group role, Ready check, Quest: the Enable and every menu row | Class power, Additional power (Player alone has them) |
| | The nameplate pages, all of them (4.9) |

The frame's own settings differ on every unit by design (the audit), and a place or a size shared between a
Player frame and a raid button would mean nothing. A bar's or a part's place and size inside the frame do mean
the same on every member, and where a unit's differs today the upgrade makes it that unit's own (4.6): Player's
power bar placed on the screen is Player's own; Target's power bar 5 tall at its bottom follows All units with
seven others.

**A member has a setting** when its page shows the row: the element is valid for it (`ValidUnit`: no cast bar
on a unit's target, Ready check on the groups), and the option shows for it (`UF.CanShow`: Classification,
Class color, Color friendly, Boss percent, the color flags). A setting a member doesn't have is never its own,
never in a diff list or a Multiple list, and its stored value is never written.

The settings are listed once, in `UF.SHARED` (`SaftUI-Unitframes/config/shared.lua`), each `{ key, part,
element, name, type, paths, shows, since }`, 187 today. A test derives the same list from the member pages' rows and
fails when the two differ, so a new row can't be forgotten.

#### 4.3 Storage

Inside the unit frame profile, so a profile copy, rename, export and import carry it with no change to
`profiles.lua`:

- **All units' values**: `unitframes.profiles.<profile>.all`, a unit-shaped table. Its defaults are AceDB's
  every-unit `'**'`, which the profile's wildcard gives any unit key, with one line of its own
  (`config/units/all.lua`: Debuffs on, the one setting whose majority is not the every-unit default, so a fresh
  profile's All units shows no reset icon).
- **The own flags**: `unitframes.profiles.<profile>.<unit>.own['<key>'] = true | false`, dotted keys, like the
  action bars' `<bar>.own`. Clearing writes `false`, never nil. (AceDB's element wildcard fills an `own` table
  with an element's defaults, `enable`, `width` and the rest; no key is bare, so none can be read as a flag,
  and AceDB strips them again at logout.)
- **The marker**: `all.version` (`UF.SHARED_VERSION`, 1), read and written with `rawget` and `rawset`: a key
  missing from a unit-shaped table reads as a new table through AceDB's wildcard.
- **Each member's values stay where they are today**, and hold what the member shows (4.4).

#### 4.4 The effective config: one function, and every reader as it is

Every unit frame reader reads the unit's stored values today: `frame:GetConfig()` is
`UF:GetProfileConfig()[unit or self.base_unit]`, each element's, text's and icon's `GetConfig` reads under it,
`element.config` caches those tables (re-pointed by `UF:RefreshFrameConfig`), and oUF's hooks read them on
every update, the health text's on every health tick. About sixty call sites in all.

**The design keeps them all as they are** (**call**) by keeping each member's stored value equal to its
effective value:

- `UF:SharedValue(unit, key)` is the one definition: the member's stored value where it owns the key or
  doesn't have it, else All units' stored value.
- A member that follows a setting holds a copy of All units' value, written whenever All units' value changes
  (4.5). A member that owns it holds its own.
- `UF:SyncShared()` makes every stored value agree with `UF:SharedValue`, and runs after the upgrade and on
  every profile load (4.6), so a drift (a hand edit, a default a later SaftUI changes) is put right before
  anything is drawn.

Why not the action bars' way, a resolved table built per call (`AB:GetBarConfig(id)`): the unit frames'
readers hold references into the stored tables and read them on hot paths. A table per call would allocate on
every health tick; a cached resolved copy would need every reader moved to it and invalidated on every write,
and would break the readers that write through their cached table (the Custom color rows write a color in
place). Materializing changes no reader, no oUF element and no hot path, and makes "nothing changes at the
upgrade" hold by construction: the upgrade writes nothing a reader reads.

#### 4.5 Writes

All in `config/shared.lua`, table writes only, safe in combat; none applies anything.

- `UF:SetShared(unit, key, value, part)`: on `'all'`, All units' value and every follower's copy; on a member,
  the member owns the key and its value is written. A position is written part by part, every part (point,
  relative point, offsets, and an anchor that isn't set as `false`, as `uf_element_position` clears one); a
  color in place, in the shape the follower's table has (a color object's `r`, `g`, `b`, a list's 1 to 3); a
  typeface as a copy.
- `UF:FollowAll(unit, key)`, `UF:ApplyToAll(unit, key)`, `UF:ApplyTo(unit, key, targets)`, `UF:OwnersOf(key)`
  as the action bars' (an owner counts as differing even when its value equals All units', the action bars'
  ruling 5), and the same for a whole part (`UF:PartKeys`, `UF:PartIsOwn`, `UF:FollowAllPart`,
  `UF:ApplyPartToAll`, `UF:ApplyPartTo`, `UF:PartOwners`).
- **The pages write through these.** On a member page the share field's decorator (4.7) wraps each shared
  row's `set` so the member owns the key before the write. On All units the rows' own sets write `all` and run
  `UF:UpdateConfig('all', element)`, as every unit's do; `UF:UpdateConfig` with `'all'` copies All units'
  values for that element's keys into each follower (`UF:PropagateShared(element)`), and nothing else.
- **What applies a change**: `UF:UpdateShared(units, element)` runs `UF:UpdateConfig(unit, element)` for each
  member whose stored value changed, once on the next frame however many changes came (a held slider on All
  units costs one update of each follower per frame). `UF:UpdateConfig` waits for the end of combat as today.

#### 4.6 The upgrade, and nothing changing

`UF:ConvertShared(profile)` runs once per unit frame profile, while `all.version` is under
`UF.SHARED_VERSION`, through `UF:TryConvertShared()` (reports an error through the game's handler and lets the
frames build from the profile as it is), from `UF:OnEnable` before anything is spawned and from
`UF:UpdateConfig()` with no unit (a profile switch, copy, reset or import, and a unit frame profile switch)
before its combat queue. Then `UF:SyncShared()`.

**Step 1** (every setting):

1. All units takes, per setting, **the value most members show** (among the members that have it); a tie goes
   to All units' default when that is among the tied values, else to the first member in the picker's order
   (**call**: on a profile whose user changed a font on every unit, All units takes that font and no unit owns
   it, where taking the defaults would make every unit own it).
2. Each member **owns** exactly the settings where what it shows differs from that value (the compare is the
   kit's `OM.SameValue` by the row's type: offsets as whole pixels, `"0"` and `0` the same, a frame of nil,
   false or UIParent the screen, colors as bytes).
3. **Nothing is written into a member's values.** What every member shows is what it showed.

On an untouched profile All units ends equal to its defaults (the audit's majorities; `all.lua`'s Debuffs on)
and the members own the 156 settings the audit lists. On a customized profile the owns follow what was set.

**A setting added later** comes with a step of its own (its entry in `UF.SHARED` says `since = n`, and
`UF.SHARED_VERSION` rises to n): the step does 1 and 2 for those keys alone, so a unit whose default for the new
setting differs owns it from the start and nothing on screen moves. A test fails a key in `UF.SHARED` that no
step covers.

**The sync** (`UF:SyncShared()`): for every member that follows a setting it has, All units' value is copied
in where the stored one differs. After step 1 it writes nothing. Later it puts right a drift: a unit whose
shipped default changed in a later SaftUI while it follows All units keeps following (the rule "a member that
follows shows All units' value").

A **fresh profile**, or one reset, has no marker: it converts on its first load.

#### 4.7 On the pages

The decorator `UF.DecorateShares(unit, page)` (`config/sharedoptions.lua`) gives every shared row of a page
its `share` field after the page is built, from `UF.SHARED`, by the row's saved path (the six rows with a hand
default are given a `saved` for it; their reset stays their hand `default`). Core's kit draws the rest, as on
the action bars:

- **A member page**: an own setting has the own mark and the accent label; its hover line is `Own`, the
  reset icon ("Reset: Font follows All units again. Player's own value is dropped."), `· Apply to: All |
  Multiple`. Multiple lists the other members that have the setting. A followed setting is plain.
- **All units**: a setting some member owns has the diff icon after its label; its tooltip is "All units:
  <value>", then each owner and its value. The hover line is `Apply to: All | Multiple` (All: every member
  follows; Multiple lists the owners). Each row keeps its derived reset to the default.
- **A part row** carries a share for the **whole part** (the kit's new `whole` share, section 6): on a member
  page it is own-marked while its Enable or any of its settings is own, and its line's Reset makes the whole
  part follow All units again, All gives All units this member's part and every member follows it, Multiple
  gives the picked members this member's part. On All units its diff icon lists each member that owns
  anything in the part, with those settings' names ("Party: Show level, Max length, Position"), and its line's
  All and Multiple make the whole part followed. Inside the menu each setting has its own share as anywhere.
- **Tooltips name what a member is**: the share's noun is `{ 'unit frame', 'unit frames' }` and the page reads
  "Player", "Raid 10" (`pageText`).
- **Resets**: a member's shared row resets by its line's Reset (follow again: the kit's `share` source); its
  own rows (Enable, Width, Height, Position, Layout, Range) keep their derived resets; All units' rows reset to
  All units' defaults (derived), and a reset there reaches every follower through the row's own `set`. Test
  mode and the Profile select keep their `noReset`.

#### 4.8 Groups and boss

Party, Raid 10, Raid 40 and Boss are members like any unit: their parts and bars share; their Layout, Range,
Test mode, Width, Height and Position are their own. A group's change reaches every button of its header by
`UF:UpdateConfig(group, element)`, as today. Arena has no page and is not a member; when it gets one it joins
by a step (4.6).

#### 4.9 Nameplates

The two plate pages **stay out of All units** (**call**, question 4): their defaults differ in nearly every
part (names without level and cut to 150, short health, the cast bar under the bar, debuffs above, the
friendly plate a name alone), so they would own most settings anyway, and they already share with each other
through their boxes ("Use friendly nameplates' settings", "Use enemy nameplates' settings"). Two ways to share
on one page would be hard to read. They get the new layout (Parts on General, four tabs) with no share marks;
every row keeps its derived reset and each part row its menu reset.

While a page's box is checked, General's own settings hide as today, and so does its Parts section, but on the
Enemy page **Threat** stays (the Threat tab was kept before: threat is always the Enemy page's). So the page's
`kept` gains `keptParts = { threat = true }`; every other part row hides with General's settings.

#### 4.10 Unit frame profiles

Sharing is per unit frame profile: each has its own `all`, own flags and marker, so a copy carries them, New
starts converted from defaults, an import of an older export converts when it is switched to, and switching
moves nothing (the new profile's stored values are already what its frames show).

#### 4.11 Copy from

**Dropped** (**call**, question 3). With All units, making units alike is All units and its follow; copying a
part between units is the part row's Apply to: Multiple. Copy from wrote another unit's tables into this one
past the own flags, which would make a following unit drift from All units without being marked. It takes
with it `UF:OpenCopyTable`, `UF:CopySettings`, `CopyNames`, `UF:PositionCopyProblem` and the `ufsetting`
history kind (only Copy from pushed it; edit mode's history is cleared on a unit frame profile switch anyway).
If the owner keeps it, it stays on the pick line and writes each copied shared setting through `UF:SetShared`
(so it becomes the unit's own) and the frame's own settings as today.

#### 4.12 Test mode

The previews read the group's stored values (`grouppreview.lua`), which hold the effective values, so they
follow All units with no change. Test mode itself stays each group's own and not saved.

### 5. Search

Search runs over every pick as today, All units included:

- a part row by its name; a setting in a part's menu by its name, the part's name (its section title) or a tab
  above it, the kit's menu search: the result opens the unit's General, scrolls to the part and opens its menu;
- the Text sections on the Health and Power tabs are skipped (`mirrorOf`): each text setting is listed once,
  at its part;
- a part declared a tab is searched as a tab's rows.

### 6. The kit changes

Each a generic field or behaviour of `SaftUI-Core/Config/`, named nowhere for unit frames, each in
`SAFTUI_FIELDS` and `.agents/edit-mode.md`:

- **K1. An item's `summary`** (`summary = function(info) -> text, tip`, read raw): drawn as 2.1 says, its
  tooltip the `tip`. An item with a summary is a **part row**: K5 and K6 apply to it.
- **K2. An item's `resetsMenu = true`**: the row's reset covers its Show box and every row of its menu, nested
  inline groups included. `OM.DefaultSource` gives `'menu'` (after `'default'`, before `'mover'`):
  `OM.DefaultDiffers` is true while any of them differs (asked per row, no table made), `OM.DefaultReset` resets
  each that differs through its own row, in menu order (a refused one stops it and its message goes to the
  status line, as today), and the tooltip names the settings that go back. `tests/lib/reset_walk.lua` takes
  `'menu'` as a source.
- **K3. A share's `whole = true`** (on an item's share): the item's share stands for the whole part. The model
  takes its `own` and `differs` from it alone (no aggregation of the menu's shares, no "Show" entry), `offers`
  is its own on a member page and a non-empty differs on the source page, and the tooltips name the part, not
  "<name>'s Show" ("Name follows All units again. Player's own values are dropped.", "All units takes Name from
  Player, and no unit frame keeps its own any more.").
- **K4. Menus lay out as a half body**: two small rows to a line (the 376 body's halves), every other row a
  line of its own, as the window's half size lays a page out (`body:SetWidth(376, true)` in place of
  `oneColumn`). No menu the action bars or the fonts draw has a small row, so none changes.
- **K5. The part row's hover line** takes the summary's place (2.5); the label never lifts.
- **K6. The part row's click and hover**: a click on the row (not on its box, dots, reset icon or links) opens
  its menu; its hover Layer is the states design's Row (2.2).
- **K7. A group's `mirrorOf`** (a path in the page): `OM.Search` skips its rows; the reset walk skips them and
  checks they are the canonical rows' very tables.

### 7. Cost

- **Drawing**: a unit page draws fewer rows (Player's General 14, against 6 here and 12 on Name today). Each
  part row asks its share state and its menu reset per draw: about ten menu rows' `DefaultDiffers` and the
  whole share's `own` (a few `rawget`s) per part, eight parts, well under a millisecond; menus build their rows
  only when opened.
- **The tree**: one page more (All units) when `/sui` opens; the part groups are built once and shared by the
  item and the tab's Text section.
- **An All units change** updates each follower once per frame (4.5): at most eleven units, and through them
  every group button (a raid of 40 included), as a change on Raid 40's own page does today. In combat nothing
  runs: `/sui` closes in combat, and a profile switch in combat converts and syncs (table writes) and waits for
  the end of combat to draw, as `UF:UpdateConfig` does today.
- **The upgrade and every profile load**: 187 settings over eleven members compared once (conversion) and once
  more (sync), a few milliseconds.

### 8. Docs, design system and followups

- `AGENTS.md` (the Unitframes row: `config/parts.lua`, `config/shared.lua`, `config/sharedoptions.lua`,
  `config/units/all.lua`, Copy from gone), `.agents/architecture.md` (Unit frames: the parts, All units, the
  storage, the effective config and its sync, the conversion's marker beside the other modules' in "A module
  that converts its profile once"), `.agents/edit-mode.md` (the unit pages, the plate pages' kept parts, the
  kit's K1 to K7), `.agents/testing.md` (the new tests).
- `docs/design-system/`: `README.md` (rule 3, menus for parts: the part row, its summary, the too-big rule;
  rule 4, shared settings: All units; the States table's Own row for a part), `05-decisions.md` (the owner's
  decisions of this brainstorm, numbered on), `components/MenuItem/` (README and preview: the part row, its
  summary, its reset and its still hover line), `components/Row/`, `components/OwnMark/`,
  `components/DiffIcon/`, `components/ResetIcon/` (the part reset), `components/ApplyList/` (units),
  `components/PositionBlock/` (in a two-column menu), `components/OptionsWindow/` (the Unit picker's All units,
  the second tab row), and `tokens.json` (`menu-max-height` 700, the rule's number). Then the Design System
  artifact is republished.
- `docs/followups.md`: the entry "Unit frames: shared settings across units, and small parts as menu items"
  resolves; "Test mode: choose which elements the previews show", "Edit mode movers for unit frame parts placed
  on the screen", "A first-run setup dialog" (presets carry All units), "A font Size drag restyles too much"
  and "A Position reset runs a unit frame's update once for every part it writes" (an All units change
  reaches every follower: the once-a-frame update is what bounds it) each gain a dated line; new entries for
  "Nameplates and All units" and, if the owner says so, "Every shared row keeps still on hover".

## What the builder decides

- The exact shape of `UF.SHARED` (built by loops over the indicators and the two bars, which share their
  shapes), its `name` words, and the value words in diff tooltips (the action bars' `AB:ValueText` is the
  pattern).
- How the decorator finds each row's saved path and wraps an inherited `set`.
- The once-a-frame update's frame and its tests' stepping (the colors' `CO.ticker` is the pattern).
- The summary's ellipsis (the game's own truncation on a sized font string) and its tooltip's frame.
- The menu reset's tooltip when many settings go back (names joined, cut after five with "and N more").
- Whether the Position block, 351 wide, fits the menu's 348 cell under Thick and Thin (the 376 body less the
  panel's padding): if it passes, the menu grows to 404 (`MENU_WIDTH`), or the block's TO dropdown narrows by
  4; a pixel test pins it.

## Risks and how each is contained

- **R1. A follower's copy drifts from All units** (a write past the API, a hand edit, a default changed in a
  later SaftUI). Contained by: every page writes through the API (the decorator, and All units' sets through
  `UF:PropagateShared`); Copy from, the one writer past it, goes; `UF:SyncShared` on every profile load; an
  invariant test after every API call and every page set (`stored == UF:SharedValue` for every member and
  key).
- **R2. The upgrade changes what a unit shows.** Contained by writing nothing into a member's values (step 1),
  and a test comparing every member's values for every shared key before and after, on the real defaults and on
  a customized profile, through a real AceDB logout and login.
- **R3. AceDB's wildcards** (a missing key under a unit reads as a new table): the marker and `own` are read
  with `rawget`; flags are dotted so no element default reads as one; the test above goes through a real
  `AceDB:New`, its logout strip and a second login.
- **R4. An All units Position that loops** (anchored to a frame that is anchored back to a follower): the All
  units Position's validate checks the anchor against every follower's frame (`st:ValidateAnchor` on each
  `UF:ConfigTarget`), and refuses naming the unit.
- **R5. A held slider on All units** costs one update per follower per frame (4.5); the followups on font
  drags and Position resets name the rest.
- **R6. A new setting added to a unit without a step** would make that unit follow All units at once: the test
  that fails a key no step covers.
- **R7. A menu over the rule** (a part that grows): the menu height test fails, naming the part and the one
  line.
- **R8. Work in flight**: the interaction states plan edits the same kit files (`optionsbody.lua`,
  `optionsitem.lua`, `optionsshare.lua`): this work's kit task lands after it or merges by hand, and the part
  row's hover look waits for its helpers if they are not in yet (the click works without them).
- **R9. Taint**: nothing here touches a Blizzard frame or runs a layout itself; every frame change goes through
  `UF:UpdateConfig`, whose combat queue is unchanged. A test in combat checks that a shared write makes no frame
  call until combat ends.

## In-game checks

- G1. An untouched profile: log in on both clients after the update. Every unit frame, the groups (in a group
  or in Test mode), the boss frames and the plates look exactly as before.
- G2. Your own profile, the same.
- G3. `/sui` > Unit frames: the picker starts with All units; Player has five tabs; General reads Frame,
  Position, Parts; the parts are two to a line at full size, one at half; the bar shows no page.
- G4. Player > General > Parts > Name: hover lights the row and nothing moves; the dots (or a click on the row)
  open the menu: the toggles two to a line, the Font row with its link, the Position block with its TO
  dropdown, all inside the screen; Esc closes it.
- G5. All units > Parts > Name > Font: every unit's names change but a unit that owns its font; the groups'
  too.
- G6. Party > Name > Show level: the Name row gets the own mark, and the setting in the menu too; All units'
  Name row shows the diff icon, "Party: Show level"; Party's line Reset puts it back to All units'.
- G7. Target > Health text row > Apply to: Multiple > Focus and Boss: both take Target's health text.
- G8. Health text in Parts and in the Health tab's Text section: a change in one shows in the other; each has
  its reset; search lists "Deficit" once.
- G9. Player > Power > Additional power (or wherever question 1 puts it).
- G10. Enemy nameplates: Parts on General; check "Use friendly nameplates' settings": only Threat stays.
- G11. Unit frame profiles: New, Copy and switch: each has its own All units; nothing moves on a switch.
- G12. A profile switch in combat (a macro): nothing errors, the frames change when combat ends.
- G13. Search "Show level": opens Player's General and Name's menu.
- G14. Under the Blizzard theme: the part row, its menu and the second tab row.

## Calls made while writing this

1. **The effective config is materialized**: each member's stored values hold what it shows, All units' copied
   into followers on every change, `UF:SharedValue` the definition and `UF:SyncShared` the check, so no reader
   changes (4.4).
2. **What shares**: the frame's Theme and Background and everything in its parts and bars; Enable, Width,
   Height, Position, Layout, Range and Test mode stay each unit's; Class power and Additional power (Player's
   alone) and the plates don't share (4.2).
3. **All units starts at what most members show**, ties to its default; a fresh profile is the every-unit
   defaults with Debuffs on, and owns 156 settings over eleven units (4.6).
4. **Nameplates stay out of All units** and keep their boxes (4.9).
5. **Additional power is a page under Power on Player**, by the rule, so Player keeps five tabs (2.7).
6. **Auras has a second tab row**, Buffs and Debuffs (section 1).
7. **The tab name "Cast bar"**, two words.
8. **General's order**: Frame, Position, Layout, Range, Parts.
9. **The parts' order** in section 1, and the text parts' position named Text position.
10. **Health text's and Power text's tab copy is the inline Text section**, the same option tables; search lists
    each once, at the part (section 3).
11. **A part row's share acts on the whole part**; each setting in its menu has its own (4.7).
12. **The part row's reset covers the part** on All units and on unshared pages (2.4).
13. **The part row's hover line takes the summary's place**; other rows' lines lift as today (2.5).
14. **A click on a part row opens its menu**, and the row has the Row hover; its open state is the dots' (2.2).
15. **Menus lay out two small rows to a line** (K4).
16. **"Too big" is taller than 700 under Thick**, checked by a test (2.7).
17. **Copy from is dropped**, with its history kind (4.11).
18. **A setting added later comes with a conversion step** (4.6).

## Questions for the owner

1. **Additional power**: its menu would be about 1070 tall, over the 700 rule by half again, so this design
   puts it under the Power tab on Player (Power bar | Additional power), keeping five tabs. Good, or a row
   anyway, or a tab of its own?
2. **A part row's reset puts back the whole part** (on All units and on unshared pages; every setting inside
   keeps its own). Keep that, or should the row's icon put back only its check box?
3. **Copy from goes** (All units and Apply to cover it). Drop it, or keep it?
4. **The nameplates stay out of All units.** Fine, or should they follow it too (owning most of their settings
   from the start)?
5. **Every shared row still on hover?** Part rows keep still (the line takes the summary's place); the rows in
   menus and on tabs lift their label as the action bars' do. Make every shared row keep still too (a change to
   every page)?

## Appendix: every shared setting's default, by member

From the audit. "Every-unit default" is what AceDB gives a unit that names nothing (`'**'`); the third column
lists the members whose own default differs, by value. Single-unit parts (Class power, Additional power,
Subtext, Threat) and the frame's own settings are left out: they don't share.

**Frame (Theme, Background).** Same on every unit that has it: none.

| Setting | Every-unit default | Units whose default differs |
| --- | --- | --- |
| `background` | theme | solid: Raid 10, Raid 40 |
| `theme` | none | theme: Raid 10, Raid 40 |

**Health.** Same on every unit that has it: `Smooth` true, `alpha` 1, `background` theme, `bg.alpha` 1, `bg.enable` false, `bg.multiplier` 0.2, `colorClass` true (not Pet, Boss), `colorClassNPC` false (not Player, Party, Raid 10, Raid 40), `colorClassPet` false (not Player, Boss, Party, Raid 10, Raid 40), `colorDisconnected` true (not Player, Pet, Boss), `colorHealth` false, `colorReaction` true, `colorSmooth` false, `colorTapping` true (not Player, Pet, Party, Raid 10, Raid 40), `enable` true, `framelevel` 10, `height` 0, `position` TOPRIGHT>TOPRIGHT frame 0,0, `relative_height` true, `relative_width` true, `text.boss_percent` true (not Player, Pet, Party, Raid 10, Raid 40), `text.font` normal, `text.percent` false, `text.position` RIGHT>RIGHT Health -7,-1, `text.short` false, `texture` SaftUI Flat, `theme` theme, `vertical_fill` false, `width` 0.

| Setting | Every-unit default | Units whose default differs |
| --- | --- | --- |
| `reverse_fill` | false | true: Focus |
| `text.deficit` | false | true: Party, Raid 10, Raid 40 |
| `text.enable` | true | false: PetTarget, Boss, Party, Raid 10, Raid 40 |
| `text.hide_full` | false | true: Raid 10, Raid 40 |

**Power.** Same on every unit that has it: `Smooth` true, `alpha` 1, `background` theme, `bg.alpha` 1, `bg.enable` false, `bg.multiplier` 0.6, `colorClass` true (not Pet, Boss), `colorClassNPC` false (not Player, Party, Raid 10, Raid 40), `colorClassPet` false (not Player, Boss, Party, Raid 10, Raid 40), `colorDisconnected` false (not Player, Pet, Boss), `colorReaction` true, `colorTapping` false (not Player, Pet, Party, Raid 10, Raid 40), `framelevel` 10, `relative_height` false, `reverse_fill` false, `text.font` normal, `text.hide_full` false, `text.percent` false, `text.short` false, `theme` theme, `vertical_fill` false.

| Setting | Every-unit default | Units whose default differs |
| --- | --- | --- |
| `colorPower` | false | true: Player |
| `enable` | false | true: Player |
| `height` | 5 | 20: Player; 3: Raid 10, Raid 40 |
| `position` | BOTTOMRIGHT>BOTTOMRIGHT frame 0,0 | TOP>CENTER UIParent 0.5,-144: Player |
| `relative_width` | true | false: Player |
| `text.enable` | false | true: Player |
| `text.position` | LEFT>LEFT Health 7,0 | CENTER>CENTER Power 0,0: Player |
| `width` | 0 | 299: Player |

**Name.** Same on every unit that has it: `allCaps` false, `alpha` 1, `colorClass` false (not Pet, Boss), `color_friendly` false (not Player, Party, Raid 10, Raid 40), `color_hostile` false, `font` normal, `max_width` 0, `showMaxLevel` false, `showSameLevel` false, `show_classification` true (not Player, Pet, Party, Raid 10, Raid 40).

| Setting | Every-unit default | Units whose default differs |
| --- | --- | --- |
| `enable` | true | false: Player, TargetTarget, FocusTarget, Pet |
| `maxLength` | 30 | 4: Party, Raid 10, Raid 40 |
| `position` | LEFT>LEFT Health 7,-1 | CENTER>CENTER Health 0,0: Party, Raid 10, Raid 40 |
| `showLevel` | true | false: Party, Raid 10, Raid 40 |

**Cast bar** (every unit but TargetTarget, FocusTarget and PetTarget). Same on every unit that has it: `alpha` 1, `colors.nointerrupt` #B26666, `framelevel` 15, `icon.background` solid, `icon.enable` false, `icon.framelevel` 15, `icon.theme` theme, `relative_height` false, `text.enable` true, `text.font` pixel, `time.enable` true, `time.font` pixel.

| Setting | Every-unit default | Units whose default differs |
| --- | --- | --- |
| `background` | solid | theme: Player, Target, Focus |
| `colors.normal` | #80B2E6 | #80E6B2: Focus |
| `enable` | false | true: Player, Target, Focus, Boss |
| `height` | 15 | 24: Player; 30: Target, Focus |
| `icon.height` | -4 | 40: Player, Target, Focus |
| `icon.position` | LEFT>RIGHT Castbar -3,0 | TOP>BOTTOM Castbar 0,-20: Player; BOTTOM>TOP Castbar 0,20: Target, Focus; TOPRIGHT>TOPLEFT Castbar -6,-2: Boss |
| `icon.relative_height` | true | false: Player, Target, Focus |
| `icon.relative_width` | true | false: Player, Target, Focus |
| `icon.width` | -4 | 40: Player, Target, Focus |
| `position` | BOTTOM>BOTTOM frame 0,0 | TOP>CENTER UIParent 0.5,-226: Player; BOTTOM>CENTER UIParent 0,120: Target; BOTTOM>CENTER UIParent 0,180: Focus |
| `relative_width` | true | false: Player, Target, Focus |
| `text.position` | TOPLEFT>BOTTOMLEFT Castbar 0,-3 | LEFT>LEFT Castbar 4,0: Player, Target, Focus |
| `theme` | thin | theme: Player, Target, Focus |
| `time.position` | RIGHT>RIGHT Castbar -5,0 | RIGHT>RIGHT Castbar -3,0: Player, Target, Focus |
| `width` | 0 | 299: Player; 300: Target, Focus |

**Buffs.** Same on every unit that has it: `alpha` 1, `background` solid, `cooldown.enable` true, `cooldown.reverse` true, `cooldown.timer.position` CENTER>BOTTOM frame 2,0, `count.font` pixel, `count.position` BOTTOMRIGHT>BOTTOMRIGHT frame 0,1, `grow_up` true, `max` 8, `per_row` 9, `purgeable` false, `relative_size` false, `spacing` 7.

| Setting | Every-unit default | Units whose default differs |
| --- | --- | --- |
| `cooldown.alpha` | 0.7 | 1: Party, Raid 10, Raid 40 |
| `cooldown.timer.enable` | false | true: Party, Raid 10 |
| `enable` | false | true: Player, Target, Focus, Boss, Party |
| `framelevel` | 15 | 50: Party, Raid 10, Raid 40 |
| `grow_right` | true | false: Target, Boss |
| `initial_anchor` | BOTTOMLEFT | TOPRIGHT: Target, Boss; LEFT: Party, Raid 10, Raid 40 |
| `onlyShowPlayer` | false | true: Player, Party, Raid 10, Raid 40 |
| `position` | BOTTOMLEFT>TOPLEFT frame 0,7 | BOTTOMRIGHT>TOPRIGHT frame 0,7: Target; BOTTOMRIGHT>TOPRIGHT frame 0,3: Boss; TOPLEFT>TOPRIGHT frame 7,0: Party; TOPLEFT>TOPLEFT frame 0,0: Raid 10, Raid 40 |
| `size` | 24 | 34: Party; 15: Raid 40 |
| `theme` | theme | thin: Raid 10, Raid 40 |

**Debuffs.** Same on every unit that has it: `alpha` 1, `background` solid, `cooldown.enable` true, `cooldown.reverse` true, `cooldown.timer.enable` false, `cooldown.timer.position` CENTER>BOTTOM frame 2,0, `count.font` pixel, `count.position` BOTTOMRIGHT>BOTTOMRIGHT frame 0,1, `grow_up` true, `onlyShowPlayer` false, `relative_size` false.

| Setting | Every-unit default | Units whose default differs |
| --- | --- | --- |
| `cooldown.alpha` | 0.7 | 1: Target |
| `enable` | false | true: Player, Target, Focus, Boss, Party, Raid 10 |
| `framelevel` | 15 | 50: Party, Raid 10, Raid 40 |
| `grow_right` | true | false: Player, Focus, Party |
| `initial_anchor` | BOTTOMLEFT | RIGHT: Player, Focus, Party; LEFT: Boss, Raid 10, Raid 40 |
| `max` | 8 | 2: Raid 10, Raid 40 |
| `per_row` | 9 | 2: Raid 10, Raid 40 |
| `position` | BOTTOMLEFT>TOPLEFT frame 0,7 | BOTTOMRIGHT>BOTTOMLEFT frame -7,0: Player, Party; BOTTOMRIGHT>BOTTOMLEFT frame -7,2: Focus; BOTTOMLEFT>BOTTOMRIGHT frame 7,2: Boss; BOTTOMLEFT>BOTTOMLEFT frame 0,0: Raid 10; LEFT>LEFT frame 4,0: Raid 40 |
| `size` | 24 | 34: Player, Party; 25: Focus, Boss; 12: Raid 10; 8: Raid 40 |
| `spacing` | 7 | 3: Raid 10, Raid 40 |
| `theme` | theme | thin: Raid 10, Raid 40 |

**Raid target.** Same on every unit that has it: `alpha` 1, `background` theme, `enable` true, `position` CENTER>TOP frame 0,0, `size` 16, `theme` none.

**Raid role.** Same on every unit that has it: `alpha` 1, `background` theme, `enable` true, `position` CENTER>TOPRIGHT Health 0,0, `size` 16, `theme` none.

**Group role.** Same on every unit that has it: `alpha` 1, `background` theme, `position` BOTTOMRIGHT>BOTTOMRIGHT Health 2,-2, `showDps` false, `size` 16, `theme` none.

| Setting | Every-unit default | Units whose default differs |
| --- | --- | --- |
| `enable` | false | true: Party |

**Ready check** (Party, Raid 10, Raid 40). Same on every unit that has it: `alpha` 1, `background` theme, `enable` true, `position` BOTTOMRIGHT>BOTTOMRIGHT Health 0,0, `size` 16, `theme` none.

**Quest.** Same on every unit that has it: `alpha` 1, `background` theme, `enable` false, `position` RIGHT>LEFT frame -7,0, `size` 16, `theme` none.
