# Colors that show at once, and a preview in the color picker

Design, 2026-11-15. A draft for the owner to approve. Every decision he didn't make is marked **call** and
listed again at the end, under "Calls made while writing this". Checked against SaftUI's code on `modular`
at `b6f86f3c`; line numbers are that commit's. Nothing here has been checked in game; the checks it needs
are L1 to L9 and P1 to P5 under "In-game checks".

Words used below:

- **Color**: one swatch of Global settings > Colors (a **group**, its section and profile table, such as
  `class`, and a **key** in it, such as `MAGE`), or the Theme tab's Accent (group `accent`, no key). Renown
  is group `renown` with no key. There are 80: Text 8, Buttons 4, Class 13, Roles 3, Reputation 8 and
  Renown 1, Factions 3, Power 19, Item quality 9, Loot 5, Status 2, Threat 2, Objectives 2, and the Accent.
- **Reader**: code that draws something in one of those colors.
- **Pass**: one run of the readers after a change.
- **Edit**: the time SaftUI's color picker (`SaftUI-Core/Config/optionscolorpicker.lua`) is open on a color.
- **Live**: a reader on screen shows a change in the frame it is made or the next, with no reload and
  nothing else done.

## Why

The owner, testing the color roles work in game (2026-11-15): "one thing that's a bit annoying is that I
can't actually see how the button changes will look without reloading - that's a real pain if you're
trying to dial in a color. Maybe we get a preview button for those changes? honestly adding a 'preview'
component to the color picker would be awesome, we can include a context of what to load there based on
what we're modifying".

He was offered both: the colors apply live, so the real UI changes as he picks (live first, with Cancel
putting the old color back), and a preview area in the picker that draws a sample of what the color
affects, for when that thing isn't on screen. His answer: "I like this, I'm curious about lag but lets see
how well it goes".

## What the owner decided

1. **Live first.** The real UI follows the picker as he drags.
2. **Cancel puts the opening color back**, everywhere it went.
3. **A preview in the picker**, chosen by what the open option colors ("a context of what to load there
   based on what we're modifying").
4. **Lag is the worry**, so it is measured, in the tests and in game.

## Goals

- Every one of the 80 colors reaches every SaftUI reader on screen while the picker is dragged, with no
  reload.
- A drag stays smooth: at most one pass per frame; each pass under the budget below in the heaviest case;
  nothing made, rebuilt, re-sorted or laid out; no table or closure made per step.
- Cancel puts the opening color back through the same path as a pick.
- The picker can show a preview of what the color being edited colors, built from real SaftUI pieces and
  chosen by the option that opened it.
- The Colors page says nothing that stops being true: its "reload" notes go.

## Non-goals

- **The Theme tab's own colors** (Border, Outer border, Window background, Background). They are live
  already: each set runs `st:RecolorThemed()` (`SaftUI-Core/theme.lua:679`), which repaints every drawn
  frame and then runs every module's `'theme'` handler. The debug line below times that pass too during an
  edit, changing nothing in it; if the owner's line shows it over the budget, that is a followup, not this
  work (**call**).
- **Color options that aren't the Colors page's or the Accent**: a unit's Custom color and text color, the
  cast bar's colors, the totem bar's element colors, the experience bar's. Their sets already apply what
  they color.
- **`/sui` following during a drag** (under "What stays as it is").
- **Recoloring lines already printed to chat.**
- **Remapping what Buttons > Normal and Hover color** (the color roles spec's non-goal stands; the preview
  shows the mapping as it is).
- **A preview for the Theme tab's colors or for other color options.** The field below lets any option add
  one later.

## Anti-goals

What would make this a failure even if it works:

- **A drag that drops frames because of SaftUI.** A pass that makes a frame, a texture, a font string, a
  table or a closure; that runs a module's `UpdateConfig`, lays out, re-sorts or rebuilds; or that redoes a
  whole roster for one color.
- **Taint or a blocked action.** A pass that calls a protected function or one of Blizzard's, or does
  anything to a Blizzard or secure frame but set the color of a region that exists.
- **A slower hot path.** Unit frames, nameplates, action buttons and bag updates run exactly the code they
  run today. Nothing reads the follower lists on an update.
- **A Cancel that leaves any reader on the picked color.**
- **A preview drawn by hand** where the theme engine draws the real piece, or one on half pixels.

## Part A: colors that show at once

### How a change travels today

- A Colors row's `set` (`SaftUI-Core/Media/colors.lua:510`) writes the profile's color object in place and
  calls `st:ColorsChanged(group)` (`colors.lua:12`), which runs every module's `OnColorsChanged(group)` in
  `xpcall`. The Accent row (`colors.lua:557`) does the same with `'accent'`. The rows' resets do too.
- The picker calls `onChange` on every change. A drag in the square or a strip reads the cursor in an
  `OnUpdate` (`optionscolorpicker.lua:427`), so a drag is one change per rendered frame: 60 a second at
  60 fps, 144 at 144. Each is a set (`optionstypes.lua:430`, `optionswidgets.lua:141`) and a whole
  `st:ColorsChanged`.
- `/sui` doesn't redraw while the picker is open (`optionswindow.lua:508`): a redraw would release the
  field the picker writes through. It redraws once as the picker closes.
- Most readers set a color when they build or restyle a frame and never hear a change. A few that do
  hear it (the unit frames, the bags' quality borders, SaftUI's tracker) redo everything they color, for
  any color of the group, on every frame of a drag.

### The audit

Every reader of every color, by code. **Today** and **After** say when a reader on screen shows a change:
**live**; **next** (its next show, update, draw or roll); **close** (`/sui`'s redraw as the picker closes);
**reload**. After this work every reader is live except those under "What stays as it is". **The live
call** is what a pass runs for it after this work. **Per change** is what one pass costs in the full UI the
budget assumes: a 40-player raid with 40 nameplates and 10 single frames, every bag and both banks open
(about 700 slots), 12 action bars of 12 with the pet and stance bars (164 buttons).

**In combat**, for every row: each live call only sets the color of a region or frame that exists, or runs
an oUF element's own update (which oUF runs in combat on its events). None is a protected call
(`.agents/taint.md` rule 6: color and alpha aren't protected). The picker refuses to open in combat and
cancels when combat starts (`optionscolorpicker.lua:849`), so a live pass never runs in combat; a whole
pass can (Cancel's restore when combat starts it, a profile switch made in combat once step 8's queue
runs), and the rules below hold for it the same.

#### Text (Text, Muted, Strong, Danger, Warning, Caution, Success, Shared)

| Reader (keys) | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| `/sui`: labels, notes, titles, hints, status lines, the share line, the diff icon (normal, muted, strong, danger) | close | read as the page draws, and no redraw while the picker is open | unchanged: the redraw as it closes | one page, once |
| The kit's field font (normal): every field's text, `SaftUI_OptionsFieldFont` and `/sui`'s font objects | reload | their color is set only by `W.UpdateFonts` and `OB.UpdateFonts` (`optionslook.lua:33`), on a font or profile change | `Config:OnColorsChanged('text', key)` runs `OB.UpdateFonts()` for normal | 8 font objects |
| The picker's own captions, box labels, chevron (normal, muted) | next open | its `Look()` runs as it opens (`optionscolorpicker.lua:889`) | the picker paints them on the pass | 12 regions |
| Edit mode: the bar, its status line, the History list, the overlap list (normal, muted, danger) | live | `EM:OnColorsChanged` fires `ColorsChanged`, and the bar looks again (`bar.lua:573`) on every group | as today, for `text`, `button`, `accent` and `theme` only | about 30 controls |
| Bags: the view buttons' glyphs (normal) | live | `INV:ColorViewButtons` (`header.lua:225`) | as today, for normal only | under 20 textures |
| Bags: the currency filter's funnel (normal) | reload | set once (`currencies.lua:172`) | follower | 1 |
| Bags: armor and weapon item levels (strong, success, shared) | next | set as a slot is assigned (`slot.lua:139`) | `INV:OnColorsChanged`: the item levels of the slots whose kind takes that key | about 100 |
| Bags: reagent markers (success) | next | set at build and assign (`slot.lua:483,506`) | the reagent bag's markers | up to 36 |
| Bags: currency counts (shared, strong) | next | set as the list fills (`currencies.lua:263`) | the shown counts | up to 30 |
| Bags: footer counts, the reagent bag's and the warband bank's (success, shared) | next | baked into the text as a color code (`containers/bag.lua:199`, `combinedbank.lua:135`) | the footer texts set again | 4 |
| Bags: a bank slot's price (strong, danger) | next | set at update (`bank.lua:165`) | the price text | 1 |
| Bags: a special bag's title, its type in Muted | next | baked into the title (`views.lua:192`) | the titles' text set again, nothing laid out | up to 20 |
| Bags: the combined bank's eye (muted) | reload | set at build (`combinedbank.lua:51`) | follower | up to 6 |
| Bags: Categories tab and rule editor (normal, muted, warning, danger, accent) | close | `/sui` pages | unchanged | — |
| Loot: roll timers' text, Blizzard's frames and SaftUI's held bars (strong, danger) | live | read on every tick (`roll.lua:225`, `rollbar.lua:204`) | as today | — |
| Loot: the feed's two buttons (normal) | live | `LT:ColorFeed` | as today | 2 |
| SaftUI's tracker (normal, muted, strong, danger) | live | `TR:OnColorsChanged` repaints on every group (`init.lua:146`) | as today, for `text`, `objectives`, `accent` and `theme` only | the shown rows (about 100 texts) |
| Unit frames: the level tag; hostile and unfriendly names (danger, warning, caution, success, muted) | next | read as a tag updates (`tags.lua:8,59`); `UF:OnColorsChanged` skips `text` | `UpdateTags` on frames showing a unit | up to 90 |
| Nameplates: the threat text while threat is fine (normal) | next | read on a threat update (`threat.lua:154`) | `UF:UpdatePlateThreat` on shown plates | up to 40 |
| Unit frames' test previews: names (danger, caution) | next | previews redraw for class, reaction, power and status only | `UF:UpdateGroupPreview` for shown test groups | up to 3 previews |
| Totem bar: timers and their warning curve (normal, danger) | reload | the text curve is made once and kept (`totemtimers.lua:236`); each bar curve until its slot changes | the curves dropped, each shown timer colored again | up to 4 |
| Totem bar: the flyout's arrow (normal) | reload | set at skin (`totemskin.lua:363`) | `TB:OnColorsChanged` | 1 |
| Zone text and the map's zone line (normal) | live | `ZT:OnColorsChanged` | as today | 2 |
| Character frame: item levels (strong) | next | set at update (`characterframe.lua:69,115`) | the shown slots' texts | up to 19 |
| RestedXP: its scroll bar thumb, step numbers, titles (muted) | next | set as the skin styles (`restedxp.lua:167`) | `RX:OnColorsChanged` | a few |
| Blizzard's tracker skin: chevrons (muted, strong) | live | `OT:OnColorsChanged` on every group | as today | a few |
| Minimap: latency and frame rate (warning, caution, success) | live | read on every update (`stats.lua:6`) | as today | — |
| Micro buttons: the alert flash (caution) | reload | set at skin (`microbuttons.lua:138`) | each micro button's flash texture, under Thick and Thin | up to 12 |
| Core: a close button's cross at rest (muted) | next | set at build and on leave (`panels.lua:366`) | follower | under 10 |
| Tooltips: a bag item's Caught by and category, the roll tooltip, the durability tooltip, keybind mode's hint | next | read as each shows | unchanged | — |
| Chat: the prefix, Error and DEBUG (danger) | next | read as each line prints (`api.lua:285`) | unchanged | — |

#### Buttons (Normal, Hover, Pushed, Danger; each reader draws its own strength times the opacity)

| Reader (keys) | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| SaftUI buttons' highlight and pressed fill (normal, pushed) | reload | set at skin (`Widgets/button.lua:253,263`) | follower | every SaftUI button (about 40) |
| Check boxes' checked fill and highlight (hover, normal) | reload | set at skin (`checkbutton.lua:49,112,118`) | follower | about 20 |
| Scroll bar thumbs (normal, hover, pushed) | next | read on enter and leave (`scrollbar.lua:7`) | follower: the thumb's own state picks the key | about 10 |
| Resize corners and `/sui`'s grip (hover) | reload | set at skin (`skinning.lua:459`, `optionsresize.lua:163`) | follower | 2 |
| Micro buttons: highlight at 0.4, pushed fill at 0.6 (hover, pushed) | reload | set at skin (`microbuttons.lua:123,180`) | the micro menu's handler, under Thick and Thin | up to 12 each |
| The micro bar's items; the tracking, queue and expansion buttons (normal, pushed, hover) | reload | set at build (`micromenuitems.lua:35,41,95`, `queuebutton.lua:44`, `expansionbutton.lua:51`) | follower | under 10 |
| Bank: unbought slots (danger) | reload | set at build (`bank.lua:56`) | `INV:OnColorsChanged` | up to 98 |
| Action bars: the flash at 0.4 (danger) | reload | set at skin (`ActionBars/skin.lua:410`) | `AB:OnColorsChanged`: each button's flash under Thick and Thin (under Blizzard the flash is Blizzard's art) | 164 |
| Totem bar: the flash at 0.4 (danger) | reload | set at skin (`totemskin.lua:306`) | `TB:OnColorsChanged` | up to 4 |

#### Class (13)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Unit frames and nameplates: health and power by class, names | live | `UF:OnColorsChanged` (`unitframes.lua:249`) merges every color group into oUF's and runs `ForceUpdate` on Health, Power, AdditionalPower and ClassPower of every frame with a unit, then its tags | the one class: oUF's copy of that key; frames whose unit is of that class (a secret class counts as a match); Health and Power, and the tags | today about 450 calls a step; after, the frames of that class (about 5) |
| Test previews | live | redrawn on every step | per key, as above | up to 3 |
| The unit tooltip on screen | next | colored as it shows (`tooltip.lua:75`) | `TT:OnColorsChanged`: a shown unit tooltip of that class | 1 |
| The bags' gold tooltip, the roll tooltip | next | at show | unchanged | — |

#### Roles (Tank, Healer, Damage)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Role corners on unit frames | next | read in the indicator's update (`indicators.lua:61`), which runs on a roster change | `ForceUpdate` on the indicator of frames showing that role (Damage for none) | up to 40 |
| Test previews | next | not among the previews' groups | `UF:UpdateGroupPreview` | up to 3 |

#### Reputation (Hated to Exalted) and Renown

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Unit frames: health and names by standing | live | as Class: every frame with a unit | per key: frames whose unit has that standing (a secret one counts), Health and Power, and the tags | the plates of that standing (about 30 in a big pull) |
| The experience bar's reputation bar | live | `XP:OnColorsChanged` (`experience.lua:272`) | as today | 1 |
| The loot feed's reputation and renown bars | next | a shown line keeps its bar's color until the feed updates (`Feed/progress.lua:104`) | `LT:ColorFeed`: the shown progress lines' bars, from the color they hold | up to 20 |
| The unit tooltip on screen | next | as Class | as Class | 1 |

#### Factions (Alliance, Horde, Neutral)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Zone text and the map's zone line | live | `ZT:OnColorsChanged('factions')` | as today | 2 |

#### Power (19)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Unit frames: power bars, the mana bar, class power points | live | as Class: every frame with a unit, all four elements | per key: Power on frames whose unit's power type is that key; AdditionalPower for Mana; ClassPower on the player's frame for its own points | the frames of that power type |
| Test previews | live | redrawn on every step | per key | up to 3 |

#### Item quality (Poor to WoW Token)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Bags: item and currency borders | live | `INV:OnColorsChanged` (`slot.lua:107`) repaints every filled slot of every window, and the currencies | per key: the slots and currencies of that quality | today about 600 a step; after, that quality's slots |
| The loot feed's item names | next | the name is stored with its color code baked in (`Feed/feed.lua:317,363`) | the feed keeps the plain name and the quality; the shown lines of that quality set their name again | up to 20 |
| Loot rolls: the item's name on Blizzard's roll frames and SaftUI's held bars | next | read as a roll shows (`roll.lua:188`) | the shown rolls of that quality color their name again | up to 4 |
| The minimap's difficulty badge (Common, Rare, Epic) | next | read on the difficulty event (`instancedifficulty.lua:52`) | the badge colored again for those three | 1 |
| The durability and roll tooltips | next | at show | unchanged | — |

#### Loot (Need, Greed, Transmog, Pass, Mount)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Roll buttons' letters (need, greed, transmog, pass) | reload | set once as each roll frame is skinned (`roll.lua:89`) | `LT:ColorRollBars`: the letters again (SaftUI's font strings on Blizzard's buttons, kept in the skin's side table) | up to 16 |
| Roll counts | next | set at the next count (`rollinfo.lua:113`) | the shown counts | up to 16 |
| The feed's mount entries (mount) | next | colored again on `theme` only (`feed.lua:163`) | the shown mount entries | up to 20 |
| The roll tooltip | next | at show | unchanged | — |

#### Status (Disconnected, Tapped)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Unit frames' health | live | as Class: every frame with a unit | per key: Health of frames whose unit is offline, or tapped | the frames in that state |

#### Threat (Warning, Bad)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Nameplates: the tint and the threat text | live | `UF:UpdatePlateThreat` on every plate | as today | up to 40 |

#### Objectives (Completed, Failed)

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| Blizzard's tracker skin, SaftUI's tracker | live | `OT:OnColorsChanged`, `TR:OnColorsChanged` | as today | the shown lines |

#### The Accent

| Reader | Today | Why | The live call | Per change |
| --- | --- | --- | --- | --- |
| `/sui`: the sidebar's bar, the tab underline, sliders, check marks, picked entries, links, own marks | close | as Text | unchanged | — |
| Edit mode: a selected mover, the bar, the docked bar's strip, the Coordinates label | live | `EM:OnColorsChanged` | as today | — |
| Edit mode: the grid's centre lines | next | read as the grid draws (`grid.lua:74`) | the two lines colored again | 2 |
| The bags' lit view buttons, a held roll's border and label, the feed's lit buttons, SaftUI's tracker | live | their handlers | as today | — |
| Bag and loot popup slots' hover (`st:SkinActionButton`), the bag bar's slots | reload | set at skin (`skinning.lua:281`, `containers/bag.lua:76`) | follower | every slot (about 700) |
| The bags' loading bar, the selected bank window's border | next | set at build and on a switch (`container.lua:85`, `inventory.lua:84`) | `INV:OnColorsChanged` | 4 |
| SaftUI's held roll bars' timers | next | set as a bar is held (`rollbar.lua:195`) | `LT:ColorRollBars` | up to 4 |
| Totem buttons' hover | reload | set at skin (`totemskin.lua:298`) | `TB:OnColorsChanged` | up to 4 |
| Action bars: an equipped item's border | next | colored on `theme` only (`skin.lua:524`) | `AB:OnColorsChanged('accent')` | the equipped buttons (a few) |
| A radio group's picked button | next | colored again only on a theme recolor (`radiogroup.lua:27`) | follower | under 5 |
| Keybind mode's highlight | next | set as the mode opens (`keybindmode.lua:254`) | unchanged (the mode closes `/sui`) | — |
| Blizzard's color picker skin: its hovers | live | `CP:OnColorsChanged` on every group | as today, for `accent` only | a few |
| The chat prefix | next | read as each line prints | unchanged | — |

### Live today, and after

**Today 41 of the 80 colors are live**: Class (13), Factions (3), Power (19), Status (2), Threat (2) and
Objectives (2), counting a tooltip's next show, `/sui`'s redraw at close and the picker's own chips as
live. 34 of those 41 (Class,
Power, Status) reach the unit frames by redoing every frame's four bars and its tags on every frame of a
drag. The other 39 are not: Text, Buttons, Roles, Loot and the Accent have readers that only a reload
reaches, and Reputation, Renown and Item quality have readers that keep the old color until their next
update (the loot feed, a roll, the difficulty badge).

**After this work all 80 are live**, each reader repainting only what that one color colors. No color
needs a reload.

### The mechanism

**One notification per color.** `st:ColorChanged(group, key)` (new, `SaftUI-Core/Media/colors.lua`) is what
every Colors row's set and reset, and the Accent row's set and reset, call in place of
`st:ColorsChanged(group)` (key nil for the Accent and Renown) (**call**). It marks the color.

- **During an edit** it asks for one pass on the next frame, from one SaftUI frame's `OnUpdate`, shown only
  while a pass is due. However many changes come before it, one pass runs, and a color marked twice is
  passed once (**call**: the pass is a frame late, and in exchange no frame ever runs two).
- **Outside an edit** (a reset arrow, a set made by code) it runs the pass at once.

**A pass** runs, for each marked color in the order it was marked: the followers of that color, then the
followers of its whole group, then every module's `OnColorsChanged(group, key)`, each in `xpcall` to
`geterrorhandler()`, as `st:ColorsChanged` runs them today.

**The whole pass** is `st:ColorsChanged(group)`, which keeps its name and its callers: every follower of the
group, then every module's `OnColorsChanged(group)` with no key, meaning every color of the group. It runs:

- **when an edit ends**: once for each group the edit touched, in the order first touched (**call**). A
  pass still due is dropped, since this covers it. Cancel's restore is a change like any other, made
  before the edit ends, so it lands this way;
- **at the profile update's step 8** (`Config:UpdateConfig`, out of combat at `config.lua:341`, and in
  `RedrawTheme`, its queued form in combat, at `config.lua:252`), after `'theme'` and `'accent'`: once for
  every group in `st.COLOR_GROUPS`, in the Colors page's order (**call**). A profile switch, copy, reset or
  import can change every color, and today nothing tells the readers that only a reload reached. In combat
  it waits with the rest of step 8, as today;
- `'theme'` and `'accent'` as today.

**An edit.** The picker calls `st:BeginColorEdit()` as it opens and `st:EndColorEdit()` as it closes,
after Cancel's restore (`onChange`) and `onCancel`. Opening it for another field accepts the first as Okay,
so that edit ends before the next begins. The whole passes at its end cover a pass the budget guard held
back, and any reader that filters by key and missed one.

**Followers**, for what has no module to color it again (Core's widgets, `st:SkinActionButton`'s hover, a
few regions of the modules'). `st:FollowColor(object, group, key, paint)`: `paint(object)` runs on every
pass of that color (key nil: of any color of the group) and on the group's whole pass. As
`st:FollowFont`:

- weak on `object`; `paint` is a shared function that reads its color with `st:Color` or `st:ColorRGBA`
  when it runs, and never closes over its object (Lua 5.1 has no ephemerons: the entry would keep the
  object alive);
- `st:UnfollowColor(object)` forgets every registration of an object, and a pool that releases one must
  call it;
- no paint runs at registration: the caller has just colored it;
- a follow made during a pass takes effect after it;
- a paint that errors is reported once and forgotten, so a drag doesn't report it on every frame
  (**call**).

**Modules.** `OnColorsChanged(group, key)` keeps its name and gains `key`: given, that one color changed;
nil, every color of the group may have. A handler that ignores the key does what it does today, so
nothing breaks before its module's task lands. A handler colors and does nothing else.

**What a pass may call:**

- color setters on regions and frames that exist: `SetVertexColor`, `SetTextColor`, `SetColorTexture`,
  `SetStatusBarColor`, `SetGradient`, `SetBackdropColor`, and `st:SetBorderColor` (which under the
  Blizzard theme shows or hides its own-color texture);
- `SetText` on SaftUI's own font strings whose text carries a color code (a bag title, a footer count, a
  feed line);
- a font object's `SetTextColor` (`OB.UpdateFonts`);
- on SaftUI's unit frames, an oUF element's `ForceUpdate` and the frame's `UpdateTags`.

Nothing else: no frame, texture or font string made; no `Show`, `Hide`, `SetShown`, `SetParent`, `SetPoint`,
`ClearAllPoints`, size, `SetAttribute` or `SetScript` on any frame; no `UpdateConfig`, layout, sort or
rebuild; no Blizzard function; no table or closure. So a pass is safe in combat and taints nothing
(`.agents/taint.md` rules 1, 3 and 6). On a Blizzard frame it only sets the color of a region that is
already there (the roll frame's `Name`, a micro button's highlight, the unit tooltip's first line), as the
skins already do when they style.

**Hot paths untouched.** Nothing is added to an element's update, a plate's arrival, an action button's
update or a bag update. Only a pass reads the follower lists.

**The budget guard.** A pass times itself with `debugprofilestop()`. A pass during an edit that took more
than `CO.PASS_BUDGET_MS` (8 ms, half a 60 fps frame) makes the next one wait one frame for each 8 ms it
took, at most 3 (**call**). The picker's own square, strips and blocks never wait, so a heavy reader makes
the UI follow at a lower rate instead of the drag stuttering.

**The number in game.** With `/sui debug` on, an edit that ran a pass ends with one chat line (**call**):
`<DEBUG:Colors> 54 passes, slowest 1.4 ms (class MAGE), mean 0.5 ms, 2 frames waited.` A Theme tab color
dragged in the picker counts its `st:RecolorThemed()` runs the same way, named `theme`. That is how the
owner sees the lag he asked about, on his own machine and UI.

### The budget, and how it is measured

**The target** (**call**): a pass during an edit costs at most 2 ms of SaftUI's Lua in the heaviest case of
each group, in the full UI above, and never more than 8 ms (the guard's line). At 60 fps a frame is
16.7 ms.

**What the tests pin.** The harness runs on stubs, so its clock is not the game's, and the tests pin what
can be counted. For each heavy reader a test builds the full UI's share of that reader and asserts, for one
pass:

- the calls it makes, under the bound in the table below;
- that it makes no frame, texture or font string, and calls none of `Show`, `Hide`, `SetShown`, `SetParent`,
  `SetPoint`, `ClearAllPoints`, `SetSize`, `SetWidth`, `SetHeight`, `SetAttribute` or `SetScript` on any
  frame (a texture may be shown or hidden: `st:SetBorderColor` under Blizzard);
- that 100 passes leave under 4 KB of garbage (`collectgarbage('count')`, as
  `tests/core/button_opacity_test.lua` measures `st:ColorRGBA`);
- its stub time, printed under `-v` as `tests/bags/container_pack_test.lua` prints its layout's, under a
  20 ms ceiling per pass that only catches a loop gone wrong.

A shared helper, `tests/lib/color_cost.lua` (new), counts the calls by wrapping the stub widgets'
methods, as the tracker's `RW.calls` (`tests/tracker/rows_world.lua:98`) counts setters.

**What only the game tells** is the time: the debug line.

| Heavy reader | Case | Today, one step | After, one pass |
| --- | --- | --- | --- |
| Unit frames | Class > Mage: 40 raid frames (5 mages), 40 plates, 10 single frames | every frame with a unit: 4 element updates and its tags (about 450 calls) | the 5 mages' frames: Health, Power and tags, 15 calls at most |
| Unit frames | Reputation > Hostile, 30 hostile plates | as above | the 30 plates: Health and tags, 60 at most |
| Unit frames | Text > Danger | nothing: not live | `UpdateTags` on every frame with a unit (90 at most), no element update |
| Nameplates | Threat > Bad | every plate (40) | the same |
| Bags | Item quality > Epic, 700 slots with 40 epic items | every filled slot's border (about 600) | the 40 epic slots |
| Bags | the Accent | nothing: not live | every slot's hover: 700 `SetVertexColor` at most |
| Action bars | Buttons > Danger | nothing: not live | 164 `SetColorTexture` under Thick and Thin, none under Blizzard |
| SaftUI's tracker | Class > Mage | every shown row repainted | nothing |
| Edit mode bar | Class > Mage | every control looked again | nothing |

The heavy readers, by name: the **action bars' 164 buttons** (one flash texture each, for Buttons >
Danger; an equipped button's border for the Accent); a **40-player raid's frames** and the **nameplates**
(each frame's bars through oUF, now only the frames and elements one color reaches); the **bags' hundreds
of slots** (one hover each for the Accent, one border per slot of the quality changed). Beside them, the
debug line times the Theme tab's `st:RecolorThemed()` passes made during an edit, as `theme`.

### What stays as it is, and why

- **`/sui` redraws once as the picker closes** (Okay or Cancel), as today (**call**). A redraw while it is
  open would release the field the picker writes through; repainting in place would touch every widget
  file of the options kit, which branches in flight are editing and the reset-on-every-setting design is
  reworking. While the picker is open, the preview (Part B) shows the text roles and the Accent on SaftUI's
  panels and controls. The kit's field font follows at once (its font objects).
- **Tooltips** take a color when they next show: each is drawn again whenever it shows. The unit tooltip
  on screen follows.
- **Chat lines already printed** keep theirs; new ones take the new color.
- **Keybind mode's highlight** takes it when the mode next opens: the mode closes `/sui`, so it can't be
  open with the picker.
- **What is built when it shows** (a roll that starts later, a new feed line, a plate that appears, a bag
  opened) reads the color then.

### The Colors page's notes

- Text, Buttons, Roles, Factions and Loot lose "Most of SaftUI reads these when it builds its frames: reload
  (Reload UI, bottom right) to see a change everywhere." (`RELOAD_NOTE`, `colors.lua:283`). Buttons keeps
  "Opacity sets how strongly each is drawn: 100% is SaftUI's own." The other sections have no note, as
  today.
- The Accent's description loses its last sentence (`ACCENT_RELOAD_NOTE`).
- The Colors tab gains one line at its top (**call**), a description at order 0 as the Fonts tab's intro
  is: "A change shows everywhere as you pick it. This window takes it when the picker closes."
- The color roles spec's non-goal "Live Text and Buttons colors" gets a dated "Revised 2026-11-15" note that
  points here, and its in-game checklist
  (`docs/superpowers/plans/2026-11-15-saftui-color-roles-in-game-checklist.md`) gets a note at its top
  that its "after a reload" items now show at once, checked by this plan's checklist.

## Part B: a preview in the picker

### Where it sits

Two placements, drawn for the owner in `.superpowers/brainstorm/color-preview-v1.html` (three contexts each:
Text > Danger, Buttons > Hover, Class > Mage). The picker today: a 170 square at 20, 48; the hue strip and,
with an opacity, its strip; a 152 column of the two blocks and the number boxes; Last used at 248 (the owner
took the Class colors row out of the picker on 2026-11-15: the Colors page edits those), Okay and Cancel at
the bottom right; 410 wide (442 with an opacity) by 342.

- **A, under the square** (recommended, **call**; Question 1). A caption "Preview" at 248 and a strip the
  picker's inner width (370, or 402 with an opacity) and 64 tall at 266, between the square and Last used.
  Last used (now at 342 and 360) and the buttons move down 94, so the picker is 436 tall. **Chosen by the
  owner, 2026-11-15.** Trade-off: it
  keeps today's width, so it opens beside its field as now, and the preview sits in the eye line between
  the square and the chips; it is 94 taller.
- **B, beside the numbers.** A caption at 48 and a column 176 wide and 172 tall from 66 to 238, 16 right of
  the number column. The picker keeps its height and grows 192 wider (602, or 634 with an opacity).
  Trade-off: nothing moves down, but beside a full-size `/sui` it flips to the field's left more often and
  covers more of the page.

**No preview.** An option with no `preview`, or one the kit can't read, opens today's picker, 410 or 442
by 342, with nothing added and nothing moved.

### The field

`preview` on a `color` option is SaftUI's own field, read raw from the row's option and never inherited, as
`toggle` is. It is a kind's name, or a table `{ kind = <name>, ... }` whose other fields are that kind's
own. The color type's `Pick` (`optionstypes.lua:414`) passes it on:
`W.OpenColorPicker(owner, { r, g, b, a, hasAlpha, onChange, stale, preview = <the field> })`. A kind the
kit doesn't know, or a value that is neither a string nor a table with a string `kind`, shows no preview
and never errors (**call**: no function form).

`W.DefinePreview(name, def)` registers a kind: `def = { Build = function(area, width, height) -> pieces,
Paint = function(pieces, r, g, b, a, spec), note = string or nil }`. It refuses a built-in kind's name, as
`W.Define` refuses a built-in type. Build runs the first time a kind shows and its pieces are kept, hidden
while another kind shows. Paint runs as the picker opens and on every change, with the color being chosen;
every other color a kind shows it reads from the profile as it paints. So a module can add a kind for a
piece of its own later.

### The kinds

| Kind | Its fields | What it draws under A (64 tall) | Under B (172 tall) |
| --- | --- | --- | --- |
| `text` | `sample` (default: the color's name), `font` (a shared font's key, default Text: **not built**, no row needs it; add it with the first row that does, applied with `st:ApplyFont` at each opening, never `SetFont` in a paint) | three tiles 118 by 44, each "Text" in Text > Normal beside the sample in the color: on Thick's panel, on Thin's panel, and on the Options windows background as the theme in use draws it, see-through over a strip of the `world` stand-in when that background is (**call**); captions Thick, Thin, Options windows | the three stacked, 176 by 36 |
| `button` | `key` (the Buttons key edited) | five tiles 74 by 44, the states: Rest (a SaftUI button; a scroll bar thumb at rest: Normal), Hover (the button's highlight: Normal; a thumb under the mouse: Hover), Pressed (the button's pressed fill and a pressed thumb: Pushed), Checked (a check box: Hover), Flash (an action button's flash at 0.4, and an unbought bank slot: Danger); every piece at its reader's strength times the opacity; the captions of the tiles the edited key reaches in Text, the rest in Muted | five rows, the caption at the left |
| `bar` | `style` (`'unit'`, `'role'`, `'reputation'`, `'power'`, `'points'`, `'plate'`), `label`, `threat` | `unit`: a unit frame's health bar 200 by 28 (filled 70%, the label at its left and 70% at its right), a raid frame 80 by 40, a unit tooltip with its name and border in the color; `role`: a raid frame with the role corner; `reputation`: the experience bar's reputation bar and an NPC's health bar; `power`: a health bar with the power bar under it; `points`: five class power points, three lit; `plate`: a nameplate 200 by 20 with its name and, with `threat`, the percent above its right end in the color | stacked, each at its own size |
| `border` | `style` (`'slot'`, `'entry'`) | `slot`: a bag slot (the Slot theme's slot, an icon, its border in the color) and a loot feed line with an item's name in the color; `entry`: a loot feed entry, its border and its fill at 60% in the color | stacked |
| `accent` | none | four tiles: a field's edge as under the mouse, a ticked check box, a slider's fill, a selected sidebar row (the 25% tint and the bar); under the Blizzard theme, where the kit's controls wear Blizzard's art and draw no accent: a link, a picked list entry, an own mark, the edit mode grid's centre lines (a selected mover wears Blizzard's Edit Mode art under Blizzard, so it is not shown) | stacked |

**Each Colors row's preview** (the Colors tab's `SectionGroup` and `CO:AccentOption` add them):

| Section | `preview` |
| --- | --- |
| Text | `'text'` |
| Buttons | `{ kind = 'button', key = <its key> }` |
| Class | `{ kind = 'bar', style = 'unit', label = <the class's name> }` |
| Roles | `{ kind = 'bar', style = 'role' }` |
| Reputation, Renown | `{ kind = 'bar', style = 'reputation', label = <the standing's name, or Renown> }` |
| Factions | `{ kind = 'text', sample = '(Alliance territory)' }`, `'(Horde territory)'`, `'(Contested territory)'` |
| Power | `{ kind = 'bar', style = 'power', label = <its name> }`; the five that are class power points (Combo points, Chi, Holy power, Soul shards, Arcane charges) `{ kind = 'bar', style = 'points' }` |
| Item quality | `{ kind = 'border', style = 'slot' }` |
| Loot | Need, Greed, Transmog, Pass: `'text'`; Mount: `{ kind = 'border', style = 'entry' }` |
| Status | `{ kind = 'bar', style = 'unit', label = 'Offline' }`, `label = 'Tapped'` |
| Threat | `{ kind = 'bar', style = 'plate', threat = true }` |
| Objectives | `{ kind = 'text', sample = '8/8 Things slain' }`, `sample = 'Escort failed'` |
| Accent | `'accent'` |

### Real pieces

Every tile is a SaftUI frame drawn through the theme engine as its piece is drawn in the UI:

- the text kind's tiles with `st:SetTemplate(tile, 'thick' | 'thin' | 'theme', 'solid' | 'options', 'panel')`;
- buttons with `st:CreateButton` and `st:SkinButton`, a state held with `LockHighlight` and
  `SetButtonState('PUSHED', true)`; a check box with `st:SkinCheckButton`; the flash as the action bars'
  skin draws it;
- bars with `st:CreateStatusBar` (kind `bar`) at the defaults' sizes (a unit frame's, a raid frame's, a
  plate's), the role corner with `st.textures.cornerbr`, the tooltip as a `tooltip` kind panel;
- the slot as a `slot` with `st:SetBorderColor`, the feed entry as the feed draws a mount;
- the accent's controls with the kit's own `Kit.CheckBox`, `W.Box`, `W.Edge` and the range's track and
  fill.

The colors other than the one edited are the profile's, read as the kind paints. Nothing the engine draws
is drawn by hand.

**Under Thick, Thin and Blizzard** the tiles follow the theme in use (the picker's panel is the theme's,
solid), with two exceptions: the text kind's first two tiles are always Thick's and Thin's panels, and
under the Blizzard theme the button kind draws its pieces as Thick, because there SaftUI's buttons wear
Blizzard's art and draw no Buttons color. Its caption row then says, at its right in Muted: "Shown as
Thick: under Blizzard, SaftUI's buttons wear Blizzard's art." (**call**)

**Whole pixels.** Every size and offset is whole, every piece placed by its top left, and nothing is placed
from a size read back. The tests check the area with `tests/lib/pixels.lua` under Thick, Thin and Blizzard,
with sizes read back a hair off.

**Cost.** A paint sets at most 24 colors and makes no table or closure: 1000 paints leave under 4 KB, and
each makes at most 24 setter calls. The pieces are built once per kind and kept. A theme recolor or
redraw while the picker is open takes the preview's own colors off its tiles (a slot's border), so the
picker keeps them with `st:KeepOwnColors` on its preview area, which paints again.

## Phases

1. **The pass** (Task 1): the notification, edits, followers, the whole passes, the guard, the debug line,
   the cost helper. Nothing visible changes but the picker's own captions and chips, the kit's field
   font, and readers whose handlers already exist following each step.
2. **The readers** (Tasks 2 to 7), in groups whose files don't overlap, so they can run side by side:
   Core's widgets and edit mode; the unit frames; the bags; the action bars, totem bar and minimap; Loot;
   Misc's skins, the tooltip and SaftUI's tracker.
3. **The notes and docs** (Task 8), once every reader is live.
4. **The preview** (Tasks 9 to 11): the area, its field and the `text` kind; the `button` and `accent`
   kinds; the `bar` and `border` kinds.

## Testing

Every task leaves `tests/run` passing. Part A's tests are per reader: each reader task's tests change a
color through `st:ColorChanged` during an edit (`st:BeginColorEdit()`, run the ticker's `OnUpdate`,
`st:EndColorEdit()`) and assert what its readers show, with the cost cases above for the heavy ones. The
mechanism's tests (Task 1) run on followers and stand-in modules. Part B's run the picker as
`tests/core/options_color_picker_test.lua` does, with the pixels check under each look.

## In-game checks

Part A, on both clients:

- **L1.** Open Global settings > Colors and drag Text > Danger: an error status line, the edit mode bar's
  refusal, a roll timer under a minute, expiring totems, a level tag on a much higher mob follow as you
  drag. Cancel: every one goes back.
- **L2.** Buttons > Hover at 50%: a bag window's scroll bar thumb under the mouse, a checked category filter
  box, the micro buttons' highlight change as you drag, with no reload.
- **L3.** Class > (your class) in a group: your raid frame, your name and your nameplate follow; nothing
  else updates (the others' bars don't flicker).
- **L4.** Item quality > Epic with the bags and bank open: only epic slots' borders change; the loot feed's
  epic lines' names follow.
- **L5.** The Accent: bag slot hover, totem hover, an equipped item's border, the bags' loading bar, the
  grid's centre lines, a held roll's timer follow at once; `/sui`'s sidebar and tabs follow when the picker
  closes.
- **L6.** Roles and Loot: role corners in a group and in Test mode; roll letters and the feed's mount lines.
- **L7.** With `/sui debug` on, drag a color for a few seconds in a raid or a busy city with every bag open:
  the chat line's slowest pass stays under 2 ms (say if not, with the line).
- **L8.** Switch profiles to one with other colors, out of combat and with the macro from the color roles
  checklist (2.8) in combat: every reader takes the new profile's colors (in combat once it ends), with no
  `ADDON_ACTION_BLOCKED`.
- **L9.** Start combat with the picker open (a training dummy): the picker cancels, every reader is back on
  the opening color, no error, no blocked action.

Part B:

- **P1.** A Text color shows the preview: the three tiles, Text beside the color, on Thick, Thin and the
  Options windows background. Under each theme.
- **P2.** A Buttons color: the five states, the edited key's tiles lit, the opacity drawn; under Blizzard
  the note.
- **P3.** Class, Power, Reputation, Threat and Roles colors: the bar kinds at their sizes.
- **P4.** Item quality and Mount: the slot and the feed entry; the Accent: its four tiles, and under
  Blizzard the other four.
- **P5.** A color option outside the Colors page (a unit's Custom color): no preview, today's picker size.

## What's left to the builder

- Names of locals, and how the ticker's frame and the marked colors are kept without allocating.
- Which oUF elements a per-key unit frame pass updates, within the table's bounds.
- Each kind's exact layout inside its tiles, and the samples' words beyond those given above.
- The tests' structure, and the full UI each cost test builds, within the cases above.
- The in-game checklist each task ends with.

## Calls made while writing this

1. **Two entry points**: `st:ColorChanged(group, key)` for one color (the rows), and
   `st:ColorsChanged(group)` kept as the whole pass. Modules' `OnColorsChanged(group, key)` gains the key,
   nil meaning the whole group.
2. **Both kinds of reader**: a follower list (`st:FollowColor`) for what has no module, and the modules'
   own handlers for the rest.
3. **During an edit, the pass runs on the next frame**, once however many changes; outside one, at once.
4. **An edit's end runs the whole pass** of each group it touched, in the order first touched, and drops a
   pass still due.
5. **The profile update's step 8 runs every group's whole pass**, after `'theme'` and `'accent'`.
6. **The budget**: 2 ms a pass in the heaviest case; the guard at 8 ms, one frame waited per 8 ms over,
   three at most.
7. **The debug line** at an edit's end, with `/sui debug` on.
8. **`/sui` redraws at close**; its field font follows at once.
9. **A follower that errors is forgotten** after its first report.
10. **The Colors tab gains an intro line**, and the reload notes go.
11. **The Theme tab's colors are out of scope**: their recolor is timed in the debug line, a followup if
    over budget.
12. **Unit frames by key**: a secret class, standing or power type counts as a match (the frame is
    updated), never skipped.
13. **SaftUI's tracker and the edit mode bar repaint only for the groups they draw.**
14. **The loot feed keeps an item's plain name and quality**, and colors the name as it draws.
15. **Placement A**, under the square (Question 1: chosen by the owner, 2026-11-15), and no Class colors row in the picker.
16. **`preview` is a kind's name or a table**, no function; a module adds a kind with `W.DefinePreview`.
17. **Five kinds** (`text`, `button`, `bar`, `border`, `accent`), and the rows' previews as tabled.
18. **The button kind under Blizzard** draws as Thick, with a note.
19. **The Options windows tile** sits on a strip of the `world` stand-in, so its see-through shows.
20. **The samples**: a text role's own name beside "Text"; the factions' and objectives' lines as tabled.

## Questions for the owner

1. **Where does the preview go: A, under the square (the picker 94 taller), or B, beside the numbers (192
   wider)?** Open `.superpowers/brainstorm/color-preview-v1.html`. The plan builds A; B changes Tasks 9 to
   11's layout numbers only.
2. **Is `/sui` following when the picker closes all right?** The rest of the UI follows as you drag, and
   the preview shows the text roles and the Accent meanwhile. Making the window itself follow during the
   drag is a larger change across the options kit, best made after the branches editing it land. Not
   blocking: the plan builds "at close".
