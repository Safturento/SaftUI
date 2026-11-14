# Fonts in SaftUI: an audit

2026-11-14. Read from the main checkout, branch `modular` at `e9b5197`. The unit frame lines are as they stand after that commit's merge of `fb-uftext`. Line numbers will move as work lands. All of this comes from reading the code and the docs. None of it has been checked in game.

It is groundwork for your ask: rename the font objects by what they're for, and let a font dropdown take either a font object or a plain typeface. Picking a typeface shows the three dots, which hold its size, outline, shadow and so on.

This is the same subject as the followup "Fonts: separate the fonts users pick per kind of text from SaftUI's internal font objects" (`docs/followups.md:1296`) and the design system's Code change 3, "Font roles" (`docs/design-system/30-code-changes.md:25`). Both of those planned a role layer on top of the objects. What you describe now is a more direct version of that:

- **The objects become the roles,** named by what they're for.
- **Typefaces in the dropdowns are the per-text overrides.** That's what the followup wanted for the bag category titles: Colus at label size, without changing Normal.

---

## 1. The font objects today

`SaftUI-Core/Media/fonts.lua` makes one font object per entry in `st.config.profile.fonts`. `FN:UpdateFontConfig` (`fonts.lua:35-72`) creates it with `CreateFont('SaftUI_<name>Font')` and sets the face (LibSharedMedia's file for `font_name`), size, outline, an opaque black shadow color, the shadow offset and line spacing. It then nudges the size up one and back, so texts get measured again. The text color is set to white once, when the object is made. `st:GetFont(key)` (`fonts.lua:74`) returns the object, or nil for a key that doesn't exist. The defaults are in `SaftUI-Core/Config/defaults.lua:26-55`. Four of the seven are copies of another with a new size.

| Key (`st:GetFont`) | Name on the Fonts tab | Face (LibSharedMedia name, file) | Size | Outline | Shadow offset | Line spacing | Used for |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `pixel` | Pixel | Homespun, `homespun.ttf` | 10 | Monochrome Outline | 0, 0 | 4 | Small numbers and small labels nearly everywhere (section 2) |
| `pixel_med` | Pixel Med | Homespun | 18 | Monochrome Outline | 0, 0 | 4 | Cooldown numbers on buttons 36 and up; the player's mana text |
| `pixel_huge` | Pixel Huge | Homespun | 32 | Monochrome Outline | 0, 0 | 4 | **Nothing** |
| `normal` | Normal | AgencyFB Bold, `AgencyFB_Bold.ttf` | 16 | Outline | 0, 0 | 4 | Almost every readable text in the world |
| `normal_med` | Normal Med | AgencyFB Bold | 24 | Outline | 0, 0 | 4 | **Nothing** |
| `title` | **Colus** | Colus, `Colus-Regular.otf` | 72 | Outline | 0, 0 | 4 | The zone name when you enter a zone, and nothing else |
| `subtitle` | Subtitle | Colus | 24 | Outline | 0, 0 | 4 | The lines under the zone name |

**What the player can change**, on Global settings > Fonts, one section per object (`fonts.lua:152-189`):

- Name (free text)
- Font Name: any LibSharedMedia face, each drawn in its own face
- Font Size, 1 to 100
- Font Outline: None, Outline, Thick Outline, Monochrome, Monochrome Outline, Monochrome Thick Outline (`FN.outlines`, `fonts.lua:7-14`)
- Shadow offset X and Y, -5 to 5
- Line spacing, 0 to 20

Every change applies at once to every text set to that object. The shadow color (always opaque black) and the text color (always white) are not settings. No row on this tab has a per-setting reset.

**Above the objects, a "Kinds of text" section** (`fonts.lua:98-131`) picks an object for three kinds of text:

| Row | Saved as | Applies |
| --- | --- | --- |
| Window titles | `headers.font` | at once |
| Button text | `buttons.font` | after a reload |
| Check box labels | `panels.font` | after a reload |

**`/sui` has fonts of its own,** which no player picks (`SaftUI-Core/Config/optionsbody.lua:244-270`, `optionslook.lua:22-37`). They take the face and outline of Colus and Normal, at fixed sizes:

- **From Colus:** page title 34, brand 26, the bar's brand 18, section titles 15, group titles 13, position captions 11.
- **From Normal:** tabs 17, labels 16, fields 15, the small line 13.

They are re-read only on a profile change (`Config/config.lua:313-316`).

### The bundled faces

LibSharedMedia lists these faces (`SaftUI-Core/Media/sharedmedia.lua:13-27`):

- envypn, Semplice, Colus, Rainy Hearts, VCR OSD Mono, Charles Wright Bold
- AgencyFB, AgencyFB Bold
- Homespun, Visitor, Righteous, Bebas Neue
- FiraCode, FiraCode Medium, FiraCode Bold

Also listed:

- **The font demo's nine "Candidate: <family>" faces.** The demo registers them (`SaftUI-Core/Dev/fontdemo.lua:48-50`) until it's deleted.
- **LibSharedMedia's own defaults** (Blizzard's Friz Quadrata, Arial Narrow, Morpheus, Skurri), and any other addon's registrations.

**Bundled but never registered:** Dosis Regular and SemiBold, Oswald Light and Regular, `visitor2.ttf`, FiraCode Light, Retina and SemiBold. There are also three stray copies:

- `FiraCode-Medium.ttf` and `FiraCode-Regular.ttf` sit at the folder's top level. The registered ones are in `FiraCode\`.
- `BarlowCondensed-SemiBold.ttf` and `barlowtest.ttf` sit at the top level as well.
- `Candidates/agencycopy.ttf` and `Candidates/barlowtest.ttf` are left over from the demo's loading test.

**Licences:**

- Only the nine candidates have a licence file in the repo: each has an `*-OFL.txt` in `Media/Fonts/Candidates/`.
- The only licensing note anywhere is in the small-fonts mockup (`.superpowers/brainstorm/46409-1794604463/content/small-fonts-v1.html`): "All candidates are free to bundle (SIL Open Font License), unlike Agency FB."
- From outside the repo, not something the repo records: Agency FB is a commercial Font Bureau typeface that ships with Microsoft Office.
- The repo says nothing about the licences of Colus or Homespun.

---

## 2. Where each is used

Counts are code lines outside `Libraries/`, the font demo and `tests/`. "Default of" means a setting whose shipped value names the object. A player who changes that setting moves those texts to another object.

### Pixel (`pixel`): about 42 code lines in about 30 files

**Code that names it directly:**

| Addon | Text |
| --- | --- |
| Core | Every SaftUI button's text: `st:CreateButton` and `st:SkinButton`'s default (`Widgets/button.lua:5,215`). That's the bags' header buttons, Warband bank, Buy, the loot feed's buttons, the clock button, radio groups and the key binding mode's Done. Also status bar text (`Widgets/statusbar.lua:5,21`: the bags' loading bar), `st:CreateFontString`'s default (`panels.lua:464`), `st:SkinCooldown`'s text (`skinning.lua:121`) and the item upgrade text (`Utilities/itemupgrades.lua:16`). |
| Edit mode | Mover labels (`EditMode/mover.lua:321`), the picker list (`picker.lua:209`), the Coordinates label (`coordinates.lua:149`) |
| Chat | Chat tabs (`SaftUI-Chat/chatframe.lua:90-91`) |
| Bags | The hidden Edit filter toggle (`header.lua:172`) |
| Loot | The roll bars' choice text (`rollbar.lua:64,174`), the roll counts (`rollinfo.lua:83`) |
| Minimap | Micro menu item text (`micromenu.lua:79`), SaftUI's bar buttons (`micromenuitems.lua:18`), latency and frame rate (`stats.lua:25,83`), instance difficulty (`instancedifficulty.lua:11`) |
| Misc | Cooldown numbers on small Cooldown Manager items (`Blizzard_CooldownViewer.lua:166`) and small totem buttons (`totemskin.lua:325`), the totem timers' fallback (`totemtimers.lua:124`) |
| Tracker | The progress bars' percent (`rows.lua:169,309`) |
| Unit frames | The aura cooldown timer text (`elements/auras.lua:169`). It has no setting. |
| Action bars | Cooldown numbers on buttons under 36 (`skin.lua:288`), key binding mode's title and text (`keybindmode.lua:212,215`) |

**Default of:**

| Setting | Texts |
| --- | --- |
| `buttons.font` (Fonts > Button text) | Totem bar button texts and totem timers (`totemskin.lua:312`, `totemtimers.lua:121`). Also the bag slot bars' and bank bag slots' texts (`Bags/containers/bag.lua:134`, `bank.lua:60`, through `st:SkinActionButton`), which the row's description doesn't mention. |
| `skinning.font` | Buff Symbol and fallback count (`Blizzard_BuffFrame.lua:57,280,344`), swing timer labels (`Blizzard_SwingTimer.lua:91`), Cooldown Manager texts (`Blizzard_CooldownViewer.lua:200`), the color picker's texts (`Blizzard_ColorPicker.lua:168`), character frame item levels (`characterframe.lua:68,113`), the objective tracker's counts (`Blizzard_ObjectiveTracker.lua:154`) |
| `inventory.fonts.icons` | Bag slot counts and item levels (`Bags/slot.lua:90-94,462,505`) |
| Unit frames | Cast bar text and time (`config/default.lua:102,113`), aura stack count (`default.lua:301`), enemy plate threat (`units/nameplate.lua:40`), the plates' cast bar text (`nameplate.lua:92`, `friendlynameplate.lua:74`) |
| `loot.popup.font` | The loot window skin, which doesn't run (`SaftUI-Loot/init.lua:16` is commented out) |

**Copied by value when the file loads, so they never follow Pixel:**

- **Action bar hotkey, stack count and macro name** (`SaftUI-ActionBars/config.lua:83,103-107`). They copy Pixel's face, size and outline.
- **Buff and debuff duration and stack count** (`SaftUI-Misc/config.lua:163,175-188`). Same copy.

### Pixel Med (`pixel_med`): 4 lines in 4 files

- **Cooldown numbers on buttons 36 and up** (`st.LARGE_COUNTDOWN_SIZE`, `constants.lua:25`):
  - action bars (`skin.lua:288`, read as values for `/sui` at `skin.lua:301`)
  - the Cooldown Manager (`Blizzard_CooldownViewer.lua:166`)
  - the totem bar (`totemskin.lua:325`)
- **The player's mana text** (additional power): `units/player.lua:14`.

### Normal (`normal`): 23 lines in 14 files

**Default of:**

| Setting | Texts |
| --- | --- |
| `headers.font` (Fonts > Window titles) | Bag, bank and combined bank window titles (`panels.lua:205,276`); the bags' gold and free-slot text (`Bags/container.lua:105,143`); `/sui`'s title bar under the Blizzard theme (`optionswindow.lua:1208,1508`); the color picker's title (`Blizzard_ColorPicker.lua:167`) |
| `panels.font` (Fonts > Check box labels) | Check box labels (`Widgets/checkbutton.lua:122`: the bags' filters, currencies) |
| `chat.font` | Chat text, using the object's face and outline at chat's own Font size, with no shadow (`chatframe.lua:43-47`); the edit box (`chatframe.lua:78,129`); and RestedXP's texts, using its face and outline at RestedXP's sizes (`restedxp.lua:55-58,101-110,455-459`) |
| `inventory.fonts.titles` | Bag category titles (`category.lua:411`, `inventory.lua:243-246`), the bag search box (`inventory.lua:215`) |
| `loot.feed.font` | Loot feed text, timer and counts (`Feed/feed.lua:585-620`) |
| `loot.roll.font` | SaftUI's roll bars (`rollbar.lua:55-59,127,167,181`) and Blizzard's roll frames when skinned (`roll.lua:120-176`) |
| `tooltip.font` | Every tooltip line: its face, size and outline are copied onto the line with `SetFont` each time it shows (`SaftUI-Misc/tooltip.lua:46-58`) |
| `objectivetracker.font` and `.header_font` | Blizzard's tracker when skinned: titles and objectives, and its headers (`Blizzard_ObjectiveTracker.lua:153-155`) |
| `tracker.font` and `.header_font` | SaftUI's tracker: titles and objectives, zone headers, and the window header's title and count (`rows.lua:167-168`, `window.lua:446-500`) |
| Unit frames | Name (`default.lua:382`); health, power and additional power text (`default.lua:160,214,266`; the player's power text at `player.lua:28`); plate subtext (`nameplate.lua:52`, `friendlynameplate.lua:32`). `auras.font` (`default.lua:296`) is effectively never read, because the count has its own font. |

**Also:**

- **`/sui` reads Normal's face and outline** for its tabs, labels, fields and small line, at fixed sizes. It does not use the object.
- **Fallbacks:** the tracker (`rows.lua:167-168`), RestedXP (`restedxp.lua:58`) and a hidden debug text (`Feed/feed.lua:742`).

### Colus (`title`): 3 lines in 3 files

- **The object at 72:** only the zone name (`Skinning/blizzard/ZoneText.lua:307`).
- **Its face and outline, at other sizes:**
  - RestedXP's guide title, at RestedXP's size plus 3 (`restedxp.lua:102-110,572`)
  - every `/sui` title, through `/sui`'s fonts (`optionsbody.lua:248-251`)

  So changing Colus's face on the Fonts tab changes `/sui`'s titles too, after a profile change or reload. Changing its size doesn't.

### Subtitle (`subtitle`): 4 lines in 1 file

The subzone name and the PvP arena line (`ZoneText.lua:308-309`), and SaftUI's level and faction line and difficulty line under them (`ZoneText.lua:315,317`).

### Pixel Huge and Normal Med

No code reads either one. They still show on the Fonts tab and in every font list.

### Places that bypass the objects with `SetFont`

There are 23 calls in 11 files, as the earlier audit counted. Leaving out the font demo (8 calls) and the objects' own (`fonts.lua:55,70,71`):

| Where | What it passes | On a |
| --- | --- | --- |
| `ActionBars/buttons.lua:59` | Hotkey, count and macro: the bar's face (LibSharedMedia path), size and flags | font string |
| `ActionBars/skin.lua:337` | Cooldown numbers: the bar's own face, size and outline, set over the object | font string |
| `ActionBars/skin.lua:340` | The object's own `GetFont()` again, when the bar's own settings are cleared | font string |
| `Chat/chatframe.lua:45` | Normal's face and outline (whichever chat object is picked), chat's own size | chat frame |
| `Misc/tooltip.lua:50` | The tooltip object's face, size and outline | font string (Blizzard's lines) |
| `Misc/Skinning/addons/restedxp.lua:110,459` | Chat object's face and outline (or Colus's), RestedXP's size | font string |
| `Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua:473` | Buff and debuff duration and count: face, size, outline | a private font object per frame and text |
| `Core/Config/optionsbody.lua:258`, `optionslook.lua:36` | `/sui`'s fonts: Colus's and Normal's faces at fixed sizes | private font objects |
| `Core/Config/optionslook.lua:48` | A field, or a font list's entry in its own face | font string |
| `Bags/header.lua:172` | `SetFont('pixel')`, the check button's helper that sets an object | (not really a bypass) |

---

## 3. Where the player picks a font

There are two kinds of Font list today:

- **SaftUI's objects, by name.** These come from `generators.font` (`Config/generators.lua:231-239`), at 18 call sites. The list is sorted by key, so it reads Normal, Normal Med, Pixel, Pixel Huge, Pixel Med, Subtitle, **Colus** (key `title`, so last).
- **LibSharedMedia's faces,** each drawn in its own face (`dialogControl = 'LSM30_Font'`).

| Page and row | Lists | Saved | Beside it | How it's applied |
| --- | --- | --- | --- | --- |
| Global settings > Fonts > Kinds of text: Window titles, Button text, Check box labels | objects | `headers.font`, `buttons.font`, `panels.font` | nothing | `SetFontObject`. Window titles apply at once (`st:UpdateHeader`), the other two after a reload. |
| Global settings > Fonts > each object: Font Name | faces | `fonts.<key>.font_name` | Name, Font Size, Font Outline, Shadow X and Y, Line spacing | The shared object, at once |
| Action bars > All bars or a bar > Text line > Hotkey, Stack count, Macro name (each a menu item) | faces | `text.<kind>.font`, on All bars or as the bar's own | In the same menu: Size 6-32, Outline, Position. Each one is shared (own mark, diff icon, Apply to); All bars has per-setting resets. | Given to LibActionButton, which calls `SetFont` on the font string (`buttons.lua:59`) |
| Same > Cooldown (menu "Cooldown numbers") | faces; unset by default | `text.countdown.font`, `.size`, `.outline` | Same | Pixel or Pixel Med by button size, with `SetFont` over it once any one is set (`skin.lua:329-341`) |
| Auras > Buffs or Debuffs > Text > Duration, Stack count (inline sections) | faces | `auras.<buffs/debuffs>.<duration/count>.font` | Size 6-40, Outline, its position | A private font object per frame and text, shadow off (`Blizzard_BuffFramePosition.lua:465-495`) |
| Unit frames > a unit > Name; Health, Power, Additional power text; Cast bar Text and Time; Buffs and Debuffs > Count | objects | `unitframes.profiles.<profile>.<unit>.<element>.font` (for example `castbar.text.font`, `buffs.count.font`) | Enable, Position; health and power text now have a text color too | `SetFontObject` (`updaters.lua:151,400`; `name.lua:42`; `auras.lua:145`) |
| Unit frames > the plates > Subtext; enemy plates > Threat ("which sets its size") | objects | `.subtext.font`, `.threat.font` | Colors, opacity, position | `SetFontObject` |
| Bags > Look: Title font, Icon font | objects | `inventory.fonts.titles`, `.icons` | nothing | `SetFontObject`. The slots' texts are set by `st:SkinActionButton`; the search box by `st:StyleEditBox`. |
| Chat > General: Font | objects | `chat.font` | Font size 8-32 (`chat.fontsize`) | The object's face and outline, chat's own size, no shadow (`SetFont` on the chat frame). A Fonts tab change reaches chat only when chat applies its settings again. |
| Loot > rolls: Font; Loot > feed: Font | objects | `loot.roll.font`, `loot.feed.font` | nothing | `SetFontObject` |
| Skinning > General: Font | objects | `skinning.font` | nothing | `SetFontObject` across six skins |
| Tooltip > General: Font | objects | `tooltip.font` | nothing | The object's face, size and outline copied onto each line as the tooltip shows. Its shadow and spacing are dropped. |
| Objective tracker > General: Font, Header font | objects | `objectivetracker.font`, `.header_font` | Dimmed while the skin is off | `SetFontObject` |
| Tracker > General > Text: Font, Header font | objects | `tracker.font`, `.header_font` | Per-setting resets | `SetFontObject`, checked on every draw, and it follows Fonts tab changes (a hook on `FN:UpdateFontConfig`, `Tracker/init.lua:69-72`) |

Only the Tracker's and All bars' font rows have per-setting resets. No other font row on any page has one.

---

## 4. What is confusing today

1. **Names describe the face, not the job.**
   - "Colus" is named after its face. Its key is `title` and its one job is the zone name at 72. If you set its face to Bebas Neue, the Fonts tab still calls it Colus.
   - "Pixel", "Pixel Med" and "Pixel Huge" are named after a bitmap face that may be replaced (decisions 12 and 41).
   - "Normal" says nothing about what it's for.
   - Because the lists sort by key, Colus sits last in every one of them.
2. **Two objects serve unrelated jobs.**
   - Normal is window titles, body text, unit frame names and values, tooltips, chat, check boxes, and the face of `/sui`'s labels.
   - Pixel is numbers on icons, labels on buttons, chat tabs, the micro menu, mover labels and cast bar text.
   - So restyling one kind of text restyles all the others: the followup's bag titles example.
3. **One job is served by several objects or settings.**
   - Cooldown numbers are Pixel or Pixel Med, chosen by button size, on the action bars, Cooldown Manager and totem bar. The unit frame aura timer is always Pixel.
   - Item levels on bag slots use `inventory.fonts.icons`; on the character frame they use `skinning.font`.
   - Headings use four settings: window titles, bag category titles, the tracker's header font and the objective tracker's header font. All four are Normal.
   - Stack counts come from four sources: bag icons, button text, the action bars' copied face, and the auras' face.
4. **"Font" means two things** (discrepancy 20). 18 lists offer objects; the action bars and auras offer faces.
5. **Copies don't follow** (discrepancy 2). The action bars' three texts and the buffs' two texts copy Pixel's face when the file loads. Changing Pixel changes unit frames, bags and chat tabs, but not hotkeys or buff timers.
6. **Settings that pick an object, then override half of it:**
   - Chat takes the face and outline but has its own size and no shadow.
   - The tooltip copies face, size and outline but not shadow or spacing.
   - RestedXP takes chat's face and outline at its own sizes.
   - Totem bar texts take the object but force the shadow off (`totemskin.lua:317-318`).
   - The action bars' cooldown numbers take the object until any one of font, size or outline is set, then use `SetFont` on top.
7. **"Changes at once" isn't always true.** Texts set to an object follow it at once. Texts that copied its values don't, until their module applies its settings again:
   - chat
   - `/sui`'s own fonts (profile change only)
   - RestedXP
   - Kinds of text's Button text and Check box labels (after a reload)
8. **Unused:**
   - Pixel Huge and Normal Med, which still appear on the Fonts tab and in every list
   - `unitframes.auras.font`
   - `loot.popup.font`, whose code doesn't run
9. **The Fonts tab's own rough edges:**
   - The labels are in title case (discrepancy 20).
   - Its sections sort by the editable Name, so a renamed font moves.
   - There are no per-setting resets.
   - Button text's description misses the bag slot bars and bank bag slots.
   - Each object's global name is built from the editable Name (`SaftUI_<name>Font`). Two fonts given the same Name would ask `CreateFont` for a name already taken. What the game does then isn't known.
10. **`/sui`'s titles hang off the zone title's face.** Changing the face of "Colus", an object only the zone name uses, changes every `/sui` title.
11. **Pixel Med's size isn't a multiple of 10.** It is 18, though the font demo calls Homespun "only crisp at 10" (`fontdemo.lua:125-130`). Whether 18 is sharp at each scale is worth a look in game.

---

## 5. Proposed role names

These are a starting point for you to edit. Players see the names on the Fonts tab and in every font list, so the list is kept short.

| Today | What it really does | Proposed name | Alternative | Notes |
| --- | --- | --- | --- | --- |
| Normal (`normal`) | Body text in the world | **Text** | Body | Unchanged look |
| Pixel (`pixel`) | Small numbers and labels on buttons, icons and bars | **Small** | Small text | Unchanged look. Decision 41 keeps Homespun for now. |
| Pixel Med (`pixel_med`) | Cooldown numbers on large buttons; the player's mana text | **Large numbers** | Countdown | |
| Colus (`title`) | The zone name, 72 | **Huge title** | Zone title, Banner | Your "really just for huge titles" |
| Subtitle (`subtitle`) | The lines under the zone name, 24 | **Subtitle** | Zone subtitle | Keep |
| (none) | Headings in the world: window titles, bag category titles, the trackers' headers | **Heading** (new) | Title | New. It could ship as Colus around 16-18, or as Text's look so nothing changes until you choose. Window titles, Bag titles and both trackers' header fonts would default to it. |
| Pixel Huge, Normal Med | Nothing | (drop) | | Take them off the tab and out of the lists |

**What's still missing a role:** `/sui`'s own fonts. Its titles follow Huge title's face and its labels follow Text's. With a Heading role, its titles could follow Heading instead (question 4).

### What a rename costs

**Names only.** Change the `name` field and keep the keys. AceDB saves only what differs from the defaults, so every profile that never edited a name picks up the new names at once. A profile with an edited name keeps it. The work is:

- 5 names, plus dropping 2 entries, in `defaults.lua:26-55`
- the one sentence players see that names them (`ActionBars/textoptions.lua:72`), and 2 test lines (`tests/actionbars/page_test.lua:474,779`)
- the design system's type table and token usage strings

The objects' global names change with them; nothing reads those (checked).

**Keys too** (for example `normal` to `text`, `pixel` to `small`). Every saved value naming an old key has to be migrated, or `st:GetFont` returns nil for it:

| What | Size |
| --- | --- |
| Code lines naming a key | about 76 lines in about 39 files: `pixel` about 42 lines in about 30 files, `normal` 23 in 14, `title` 3 in 3 (one is `/sui`'s fonts table), `subtitle` 4 in 1, `pixel_med` 4 in 4, plus the 7 entries in `defaults.lua` |
| Tests that name a key | about 92 lines in 21 files. The most are in `tests/core/fonts_tab_test.lua` (22), `tests/actionbars/cooldown_numbers_test.lua` (16), `tests/tracker/rows_test.lua` (12) and `tests/misc/cooldown_viewer_test.lua` (8). |
| Saved profile data | The 7 `fonts.<key>` tables. 15 module settings that hold a key: `headers`, `buttons` and `panels.font`; `inventory.fonts.titles` and `.icons`; `chat.font`; `loot.popup`, `.feed` and `.roll.font`; `tooltip.font`; `skinning.font`; `objectivetracker.font` and `.header_font`; `tracker.font` and `.header_font`. And about 10 per unit in every unit frame profile: cast bar text and time, health, power and additional power text, name, aura and buff and debuff count, threat, subtext. |

My recommendation: rename the names now and keep the keys internal, the way the Theme work hid the template strings. If the keys are renamed, do it in the same migration that brings in the new saved shape (section 6), with an alias table in `st:GetFont` as a safety net.

---

## 6. The dropdown you described

### What the code allows

1. **There are no menus inside menus.** `OW:OpenMenu` closes any open menu before it opens one (`Config/optionsmenu.lua:322-333`). Inside an item's menu (the action bars' texts), a face's settings have to be rows of that same menu. They can't be dots of their own.
2. **Any widget with dots can open a menu.** `OW:OpenMenu` only needs the widget's `rowBody` and `dots`, and the option's `menu`. Elsewhere, though, the kit treats the item type as special: the body, shared settings, resets and search all have `row.type == 'item'` branches (search's is `optionsmodel.lua:1240`).
3. **The kit's list already draws headings** (`caption = true`, `Config/optionslist.lua:296`) and draws entries in their own faces (font mode). A list with "SaftUI fonts" and "Typefaces" sections is cheap.
4. **`SetFontObject` doesn't undo an earlier `SetFont`.** This was seen in game; see the testing guide's stub rule 3, `optionslook.lua:42-49` and `ActionBars/skin.lua:308-314`. A text that switches between a face and an object gets stuck on the face. So a face should get a font object of its own, and texts should only ever call `SetFontObject`.
5. **A file the game hasn't loaded can't be set on a font string.** On your client a font string's `SetFont` fails for such a file. Font objects set while the addon loads work (`Dev/fontdemo.lua:52-74`, from the 2026-11-13 test). So a face is set on a `CreateFont` object, and every face a profile saves is set on its object at load. Whether a face picked for the first time mid-session loads at once is unproven (the demo retries); it needs an in-game check. The action bars' hotkey texts already `SetFont` faces straight onto font strings, so a face nothing else uses may fail there today.
6. **Never reuse an engine-made font object.** Taint rule 10: restoring one crashed the client. Private objects must be named `CreateFont` objects that SaftUI keeps.
7. **A font object's color counts.** `SetFontObject` gives a text its font's color again (the new note in `updaters.lua:402-406`). A face's private object should be white, like the roles.

### Three shapes

**A. A font row with dots (recommended)**

- **The row:** its label, a dropdown, and, only while a face is picked, the three dots after the dropdown. It's a Core type made by `generators.font`, whose arguments stay `(order, desc)`, so all 18 call sites get it at once. That includes the Fonts tab's Kinds of text.
- **The list:** a "SaftUI fonts" heading, then the roles by name, each drawn in its own face. Then a "Typefaces" heading and LibSharedMedia's faces.
- **Picking a role** saves its key, a string as today, and shows no dots. The tooltip says the role is edited on Global settings > Fonts.
- **Picking a face** saves a table, `{ face = 'Colus', size = 16, outline = 'OUTLINE', shadow = { 0, 0 } }`. It's filled from the role it replaces, so nothing jumps. The dots open a menu with Size, Outline, Shadow X and Shadow Y, plus Line spacing where the text wraps (tracker, tooltip, chat).
- **How a text applies it:** `st:GetFont(value)` also accepts the table. It returns a private font object made once for that saved table, and set again from the table whenever the menu changes it, so every text on it follows at once. Because the menu edits the table in place, the object stays the same one. The roughly 49 call sites that pass a saved value don't change. Chat, the tooltip and RestedXP still read `GetFont()` off what they're given.
- **Texts that already have their own size menus** (the action bars' four texts and the Auras' Duration and Stack count): the same list, with no dots. Their Size and Outline rows stay where they are and hide while a role is picked. Their saved shape stays (`font` is a face name, with `size` and `outline` beside it), except that `font` may also hold a role key. A string that names a role is a role; any other string is a face.
- **Resets:**
  - A page row's reset compares the whole value. Its tooltip names a role ("Text") or a face ("Colus 16, Outline"). Putting the role back is the reset, so the menu's rows have none of their own on page rows.
  - The action bars keep their per-setting shares and resets.
- **Search:** the menu's settings can be found the way an item's are, once search's menu step knows the new type.
- **Cost:**
  - **Core** (the bulk):
    - the type: a select plus the item's dots and menu
    - list headings in a select
    - the table branch in `st:GetFont` and its private objects, with one routine shared with `FN:UpdateFontConfig` (including its size nudge)
    - the share, reset and search branches
    - tests like `options_item_test.lua` and `options_menu_test.lua`
  - **Modules:** none at the 18 generator sites. The action bars and Auras need roles in their Font lists, the "hide while a role is picked" rule, and their apply paths taking an object.
  - **Migration:** none for loading. Every old saved string still loads. The defaults stay strings, so AceDB never merges a default table into a saved face.

**B. A dropdown with rows under it**

- `generators.font`'s list gains the two parts. A second generator adds Size, Outline and Shadow rows after it, hidden while a role is picked. The face's settings are saved beside it (`font`, `font_size`, `font_outline`, `font_shadow`).
- **Cost:** the least Core code. But all 18 sites have to add the rows and the keys. Pages grow by three or four rows and shift when a face is picked. The "role or face?" rule depends on key lookups, so a renamed key would read as an unknown face. And it isn't what you described: there are no dots.

**C. Every text becomes a menu item**

- Each kind of text becomes an `item` row (its Show box is its Enable where it has one). The menu holds Font (the two-part list), the face's rows (hidden for a role) and its Position. The action bars already work this way. It is the unit frames followup's "small parts as menu items" (`docs/followups.md:311`).
- **Cost:** no new kit type, but every page with a font gets redesigned: the unit frames' text tabs, cast bar, auras, trackers, loot, chat, tooltip. The font work would then wait on the unit frames redesign.

### Recommendation

Build A. C can come later on top of it, because an item's menu would just hold A's list inline.

Two more pieces fit with it:

- **Make the action bars' and buffs' texts default to the Small role** instead of copying Pixel's face. That fixes discrepancy 2. A one-time migration would write the old copy (Homespun 10, Monochrome Outline) into any text that set one of font, size or outline, so those texts keep their look.
- **Size ranges:** today they are 1-100, 6-32, 6-40 and 8-32. The face menu needs one range.

---

## 7. Questions for you

1. **Once any text can take a face directly, do the roles stay editable on the Fonts tab** (face, size, outline, shadow)? Or do they become fixed house styles, as the templates became Theme, with faces the only way to change one text?
2. **With a role picked, does the row have no dots?** Or do the dots offer one override, a Size, kept as `{ role, size }`? Chat already has its own Font size beside its Font, and the threat text's description says its font "sets its size".
3. **Rename the names players see only, or the internal keys too?** Names alone are cheap, with no migration. Keys touch about 39 code files and 21 test files and need a profile migration (section 5).
4. **Should `/sui`'s own titles keep following the zone title's face (Colus), and its labels Text's?** Or should they follow a new Heading role, or stay fixed?
5. **Should Homespun be offered as a face at any size,** given it's only crisp at its own sizes? (Pixel Med's 18 isn't a multiple of 10.) Or should it be listed once with a note, or limited to the roles?
6. **Add a Heading role?** If yes, should it ship as Colus (your bag titles idea) or look like Text until you change it?
7. **Drop Pixel Huge and Normal Med,** and stop letting players rename roles on the Fonts tab?
