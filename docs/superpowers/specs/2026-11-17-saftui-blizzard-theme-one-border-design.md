# SaftUI Blizzard theme, round 3: one border for every frame

Date: 2026-11-17. Status: approved by the owner 2026-11-17 ("lets go with this as the design"). Lines marked "My call" are the controller's, for the owner to check.

Rounds 1 and 2 (`2026-11-10-saftui-blizzard-theme-design.md`, `2026-11-11-saftui-blizzard-theme-round2-design.md`) made Blizzard a third theme beside Thick and Thin. They gave each kind of frame a different piece of Blizzard art. In game, the owner found that those pieces don't fit SaftUI's frames and don't match each other. This round gives every frame of SaftUI's one Blizzard border, drawn the same way everywhere.

## Intent

The owner, 2026-11-17, with screenshots of the swing timer, the minimap and XP bar, the micro menu, the tooltip and SaftUI's unit frames under Blizzard on Forever:

- "you can see on the swing timer the border doesn't line up well. you can see the same issue here with the minimap and exp bar. I'd like to get these fixed so they look as good as the default blizzard frames."
- "the micromenu has a lot of inconsistency in the styling, I'd like to make all of these elements even and using consistent textures throughout so that it looks as good as the thick and thin variants."
- The unit frames and tooltip screenshots: "more visual discrepancies I'd like to resolve. there might be even more that I didn't think of here".

On copying each Blizzard frame versus one look: "I think we should go for consistency over matching blizzard's exact frames, for example blizzard is pretty bad at this - the xp bar and minimap and unitframes all have different borders - also the blizzard minimap isn't square so that would break anyways - lets pick a good one and try to be consistent".

So the goal is the Thick theme's virtue (one border everywhere, every frame even) wearing Blizzard's art. It is not to copy each Blizzard frame.

## Why today's art fails

Found in the code and checked against Forever's real textures (2026-11-17):

- **Panels, bars and tooltips** (`KINDS.panel`, `.bar`, `.tooltip` in `SaftUI-Core/themeart_data.lua`) all draw `ART.tooltip`, the tooltip nine-slice, with the fill 3 in. That art has 7px rounded corners and expects about 8px of padding. On an 8 to 10px bar (the swing timer `Blizzard_SwingTimer.lua`, the XP and reputation bars `experience.lua`, the tooltip's health bar `tooltip.lua`) the corners are as tall as the bar, and on the minimap (`SaftUI-Minimap/config.lua`, drawn `panel`) the uneven rim shows a dark gap on one side and a glint on another.
- **The micro menu** (`SaftUI-Minimap/micromenuart.lua`, `ART.microbar`) gives each box its own atlas: the header button behind the zone, clock, latency and FPS (squeezed to 48 wide on the last two), the addon indicator square, the tracking button for search, Camelot's action bar frame as a strip behind the micro buttons, and nothing behind the addon count. Heights and rims differ box to box.
- **Unit frames** wear round 2's bronze box (`ART.unitframe`, cut from the player and target frames), which needs 12px of height: thinner bars fall back to a 1px line, so one screen shows two weights.
- **The layering:** SaftUI draws a border on the backdrop, one frame level *below* the content (`st:SetBackdrop`, `theme.lua`). A fill is a plain rectangle, so wherever the art has a rounded inner corner or an inner shadow, the fill paints over it. Blizzard draws its bar borders over the fill.

On Forever, the client draws the `-c60` (Camelot) member of an atlas name when one exists: that is why the art is bronze there and grey on retail.

## Goals

1. One Blizzard border, **the minimap button box**, on every SaftUI frame that is a panel, a bar, a tooltip, a unit frame or one of its bars, a group of party or raid frames, or a micro menu box.
2. The same weight at every size, from an 8px swing timer to the minimap, with no fallback to another look at small sizes.
3. The border is drawn **over** the frame's content (fill, map, text background), so its rounded inner corners and inner shadow are never painted over.
4. The micro menu reads as one row of even boxes, as it does under Thick and Thin.
5. Nothing changes under Thick or Thin.

## Non-goals

- Copying each Blizzard frame's own art (the owner's call above).
- Windows: they keep the metal frame with the close button in its socket (round 1).
- Action button and bag slot rings, aura borders and the debuff dispel border (round 1).
- `/sui`'s Settings window look and its controls (round 2).
- Status bar fill textures: each frame keeps the fill it has today (the unit frames' `RaidFrame-Hp-Fill` and `_RaidFrame-Resource-Fill`, the rest their own). My call: the owner flagged borders and evenness, not fills.
- Blizzard's own frames that SaftUI only skins or hides (Blizzard's unit frames, nameplates and cast bars in the owner's screenshot are Blizzard's).

## Anti-goals

- A second weight or look appearing at some size (round 2's 1px fallback is what this removes).
- A fill or a texture showing through the border's corners.
- Frames that change size or move under Blizzard to make room for the art: the art goes outside the frame (below), so layouts stay as the owner set them.

## Approaches considered

Shown to the owner as mockups in Forever's real art (artifact "Blizzard theme borders", https://claude.ai/artifact/ERwQjv1Hka8P4PR9NUgaH4; sources in `.scratch/blizzard-borders/`):

- **A. Round 2's bronze unit frame box everywhere.** Already built, but its 8px corners need bars 12 tall, so the swing timer, power and XP bars would grow or fall back to a thin line.
- **B. The cooldown manager bar's rim** (`ui-hud-cooldownmanager-bar-bg`, Blizzard's border for thin bars): one 1px weight at every size. The owner: "B's texture looks really bad unfortunately".
- **C. The minimap button box** (`ui-hud-minimap-header-button`, today's zone box): a 2px bronze rim with rounded corners and a soft inner shadow, cut into a nine-slice. The owner: "I really like C's border texture." **Picked.**

An earlier round of CSS sketches (a gold rim, the tooltip border padded out) was replaced once the real textures were pulled; the owner asked for exact art.

## The design

### The border

- **Forever:** the atlas `ui-hud-minimap-header-button` (Forever draws its `-c60` member: 152 x 23 in atlas file 8026705 at 256,256; measured 2026-11-17), cut by texture coordinates into a nine-slice of 6px corners, with edges stretched, the way round 2 cuts the unit frame box (`ThemeArt.Cut`, `LayCut`). Its rows from the top: 1px soft outline, 2px bronze rim, then a 2 to 3px inner shadow fading into a translucent dark centre; the bottom mirrors it with a 1px rim and a deeper outline. The centre is not drawn: the frame's own fill (the theme's Background) shows.
- **Retail:** `MINIMAP_BUTTON_KIT`, the ui-hud-minimap-button nine-slice retail already draws behind its micro menu boxes (`themeart_data.lua`): the same box in retail's grey art. My call: retail has no `ui-hud-minimap-header-button`, and the kit is its own drawing of the same box.
- **One new kind of art,** `ART.box` (the name is the builder's), replacing `ART.tooltip` on `KINDS.panel`, `.bar` and `.tooltip`, `ART.unitframe` on `KINDS.unitframe`, `ART.groupborder` on the party and raid group border, and the header, square, tracking and strip entries of `ART.microbar`.
- **A frame's own border color** (`st:SetBorderColor`: item quality on tooltips, loot rows and the feed, the Accent on bag containers, state edges) shows on a desaturated box: while a frame has its own color its pieces are desaturated (`SetDesaturated(true)`) and tinted, so the rim reads in the true color in the box's shape; with no own color they are plain bronze again. My call, the controller's recommendation, taken when the owner approved the design without picking (2026-11-17); the other options were tinting the bronze as is (colors go muddy) and no own colors under Blizzard.

### Where it sits

- **Outside the frame.** The art's outer edge sits 4px outside the frame on every side (the starting value; the art's rim then lies just outside the frame's edge and its inner shadow over the frame's outer 1 to 2px). A frame's size, place and content area don't change under Blizzard.
- **Over the content.** The pieces go on a holder one frame level above the frame they border (round 1's `Holder`, which lifts the ring over a button's icon), in a layer over the fill, not on the backdrop below. The backdrop keeps only the fill.
- **Micro menu boxes** are the exception: their art sits inside the box (outset 0), as the boxes stand edge to edge in a row and carry text and icons in them. My call, shown on board C.
- **Nothing moves.** Code that reads a kind's inset to keep content or neighbours clear of the border (`st:CalculateSpacing` in `api.lua`, the loot popup's card `popup.lua`, the totem timers' bar height `totemtimers.lua`, the minimap backdrop's offset `SaftUI-Minimap/config.lua`, the edit mode bar dock, the colour picker skin, and the rest) keeps getting today's value, so every frame and gap stays where it is. The kind gains a separate value for the art's reach (how far it sits outside: 4), which only the art reads. My call, from the builder check: zeroing the inset would have moved about 20 layouts by 3px a side.
- **Frames drawn on themselves** (`st:SetTemplate` on a frame that is the whole look, not a backdrop behind content: `/sui`'s menus, small dialogs, UI scale prompt, colour picker, nav popups, the mini options window, the preview tiles and tip, keybind mode's panel, the bags' category menu) also take the box, drawn inside their bounds (outset 0, like the micro boxes) so nothing is clipped by a parent or the screen edge; their content stays placed by the inset. My call, from the builder check: they use the same `panel` and `tooltip` kinds, and keeping today's tooltip border on them would bring back two looks. Round 2's Settings art (the window, the inner frame, controls, the dropdown list's menu art) is unchanged.
- **Above everything it borders.** The holder takes a level above the bordered frame's highest child, not just one above the frame, so the rim covers the outer pixels of child bars (health, power, castbar), the minimap's child buttons and overlay texts near an edge. Text never sits within 2px of an edge today, so nothing readable is covered. The group border stays its own frame of SaftUI's, the secure header's child as `UF:GroupBorder` is today (an unprotected child of a secure header, which `.agents/taint.md` allows), raised above the members' level out of combat only. The builder picks how the level is kept in step when children re-level.

  **Revised 2026-11-17 (build):** the first draft of this bullet said the group border is "not a child of the secure header". The code keeps it the header's child, as it was before round 3; the sentence was wrong and is corrected above. Also ruled in the build (review of the group border): the border takes the level above the header's children and their children (depth 2: each member and its bars, overlays included), not just its direct children, so the rim covers the outer pixels of the members' bars; the raise is out of combat only (`SetFrameLevel` on SaftUI's own frame), so a member joining in combat can sit above the border until the next out-of-combat draw. The rim covers only the outer pixels, so texts stay readable. Depth-3 overlays are not covered.
- **The micro boxes' centre** is drawn: the atlas's own translucent dark centre, as on board C, so the zone, clock and FPS text sit on a dark box as they do today. Nothing else fills a micro box: a fill on the item's whole rect would show past the art's soft outer pixels as a translucent band outside the rim (the owner caught this on the mockup, 2026-11-17). Its art sits under the item (nothing of the item's is under it to cover), and Blizzard's micro button art stays on top.

### Coverage

| Frame | Today under Blizzard | After |
| --- | --- | --- |
| Minimap (`SaftUI-Minimap/config.lua`, `panel`) | tooltip border, 3 in | the box, outside |
| XP and reputation bars (`SaftUI-Misc/experience.lua`, `bar`) | tooltip border | the box |
| Swing timer (`Blizzard_SwingTimer.lua`, `bar` via `st:SetBackdropIn`) | tooltip border | the box |
| Tooltips and dropdown lists (`SaftUI-Misc/tooltip.lua`, `tooltip`) | tooltip border | the box |
| The tooltip's health bar (`GameTooltipStatusBar`, `bar`) | tooltip border | the box |
| Every other `panel`, `bar` and `tooltip` (loot feed and rolls, chat, bags' sub-panels, edit mode's bar, totem timers, RestedXP and the rest of the files using those kinds) | tooltip border | the box |
| Single unit frames, their separate bars, castbars, boss frames (`unitframe`) | bronze box, or a 1px line under 12px | the box, at every size |
| Party and raid groups (`UF:GroupBorder`, `groups.lua`) | `ART.groupborder` | the box around each group |
| Micro menu: zone, clock, latency, FPS, addon count, expansion, mail, difficulty, queue, search, each micro button | header, square, tracking atlases; the action bar strip | the box, inside each box, every box the bar's height |

Windows (`window`), rings (`action`, `slot`), auras (`aura`), `small` frames and the strips and controls keep what they have.

### The micro menu

- Every item stands on one box of the same height (the bar's height, `MicroMenu:BarHeight()`, 16 to 48, default 25; revised 2026-11-17 after the micro menu settings merged) and the same art, at the item's own width (`S.ItemWidth(item, height)`, a micro button's `MicroMenu:MicroWidth`); the boxes keep the bar's spacing (`MicroMenu:Spacing`). The 6px corners fit the least height, 16. An item turned off (`show[key] == false`) is concealed at alpha 0 on its holder, so its box draws nothing.
- The strip behind the micro buttons (`UpdateStrip`, `ART.microbar.strip`) goes; each micro button gets its own box like every other item. Blizzard's own micro button art (icons, highlights) stays on top as today.
- Search keeps its magnifier as an icon on the box, not the tracking button's drawn-in one.
- The addon count gets a box.

## Constraints

- **Taint** (`.agents/taint.md`): the holder for pieces over Blizzard-owned content (the tooltip's status bar, the swing timer's bar, the micro menu's Blizzard buttons) must be a frame of SaftUI's, never a texture or child made on Blizzard's frame, and nothing may be re-levelled on a protected frame in combat. The micro menu's rule stands: nothing drawn on Blizzard's bar items or micro buttons (`micromenuart.lua`'s header comment).
- **Both clients:** Forever (16001, the owner's) and retail (120000). Atlas names are checked against each client's tables (`ThemeArt.ATLASES`).
- **Whole pixels:** the art's outset and the holder's points are whole pixels of the frame's own (`ThemeArt.Whole`), as every SaftUI line is (decision 58).
- **A theme switch** in and out of combat redraws everything as today (st:ThemeAtlases, the end-of-combat redraw).

## What changes for edit mode and spacing

The art reaches 4px outside each frame, where today's tooltip border sits about 3 to 4px out, so frames placed edge to edge stay where they are and their rims meet or overlap by a pixel. Snapping keeps measuring the frame's own edge (the existing followup "Edit Mode snapping under Blizzard measures the frames' borders, not the selection art").

## What's left to the builder

- The exact nine-slice rectangles for the Forever atlas (6px corners measured on the decoded art, `.scratch/blizzard-borders/art/mm_header.png`), and retail's kit offsets: starting values, tuned in game.
- The outset (4 as the starting value) and whether the bottom needs one more pixel for the art's deeper bottom outline.
- How the holder is shared with round 1's ring holder (`Holder`) and the frame level it takes under frames that re-level themselves (the loot feed, the bags' categories footer).
- Removing what this replaces: `ART.unitframe`, `ART.groupborder`, the microbar strip and atlases, the under-12 fallback, and their tests, with the design system docs (`docs/design-system/05-decisions.md`, a new numbered decision) and the followups they answer.

## In-game checks (for the Test Rounds page)

On Forever, then retail where marked:

1. The swing timer, XP bar, reputation bar and the tooltip's health bar: an even rim on all four sides, nothing of the fill over the rim's corners.
2. The minimap: an even rim, the map's corners under the rounded inner corners.
3. The micro menu: every box the same height and art, the row as even as under Thick; retail the same in grey.
4. The player, target and party frames: one weight on the 34px frame and its 8px power bar; party and raid: one box per group.
5. Tooltips (unit, item, compare) and dropdown lists in the box.
6. Two frames placed edge to edge (the minimap and its XP bar): how their rims meet.
7. Switch Thick, Blizzard, Thin and back, in and out of combat: nothing blocked (`/console taintLog 1`, BugGrabber), Thick and Thin unchanged.
