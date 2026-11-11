# SaftUI options, project 3b-3: the Blizzard theme, round 2 — the Settings window and unit frame borders

Date: 2026-11-11. Status: no open questions. The user's answers are binding; the calls marked "My call" are the controller's, for the user to check. Revised after the builder check (2026-11-11): the window may grow under Blizzard, the footer spans the window, the dropdown list takes the Settings list art, one group border per group header, and which Theme turns each piece on ("The builder check's answers" below).

Project 3b-2, the Blizzard theme (`docs/superpowers/specs/2026-11-10-saftui-blizzard-theme-design.md`, shipped 2026-11-11), made Blizzard a third theme beside Thick and Thin. The user checked it in game the morning after and asked for more of Blizzard's own look in two places. This spec covers those two. Four smaller fixes from the same feedback are being built separately and are assumed done here (see "Today").

## Intent

The user, 2026-11-11, after checking the Blizzard theme in game:

- "Can you look at using the assets from the Options menu for the panels, tabs, sidebars, checkboxes, dropdowns, etc", with a screenshot of Blizzard's own Settings panel (the Options window). The same message: "the sidebar on the SaftUI Options doesn't seem to be getting skinned", with a screenshot of `/sui` under Blizzard, where the sidebar keeps a flat dark fill.
- "For the unitframe borders can you look at the blizzard default unit frames look and feel and see if you can replicate that border?"

After the research (below), the user picked, from the options they were shown:

1. **`/sui`'s look:** "Full Settings window": a metal frame with "SaftUI Options" in the title bar and the close button in its socket, Blizzard's inner frame over the sidebar and the content (the sidebar widening to line up with the divider drawn into it), banner headers for FRAMES / COMBAT / INFO, gold nav text, a fading line under the page title, no lines between body sections, bigger check boxes and slim Blizzard scroll bars. Only the layout under Blizzard changes.
2. **Dropdowns:** "Settings style + arrows": the Settings panel's dropdown (a rounded bronze button) with ◀ ▶ arrows either side that step through the choices; clicking an arrow picks the previous or next choice straight away.
3. **Single unit frames** (player, target, focus, pet, target of target, boss): "Bronze frame box": the bronze outline with rounded corners cut from Blizzard's own player and target frame art, around SaftUI's frame at any size; the bars inside lose their own borders; no portrait ring, name plate or level badge; retail shows the same cut in retail's art; the bars use Blizzard's bar texture, which still takes class colors.
4. **Party and raid frames:** "Group border": Blizzard's own raid look, one thin rounded border around each group of frames, as Blizzard's raid frames draw with Display Border on; the frames inside have no border of their own and use Blizzard's raid bar fills.

So under the Blizzard theme, `/sui` looks like Blizzard's Settings window, and unit frames wear Blizzard's unit frame and raid border. Nothing changes under Thick or Thin.

## Today

Assumed done before this work starts (being built 2026-11-11, merged before this plan runs):

- **Dark grey everywhere:** the Blizzard theme's `backdropcolor` default is the window grey (`windowcolor`, {0.12, 0.12, 0.13, 1}), so tooltips, bars and panels are grey, not navy.
- **A window's header in the title bar:** under Blizzard a window's header items (title, buttons) sit in the metal's title bar, not in a strip below it.
- **The Categories tab** (`SaftUI-Bags/categoriestab.lua`): its category list and its editor are two scroll areas, each with the options body's 3px scroll bar, and the options body can give a widget the rest of its visible height. A Caught now item's tooltip opens beside the `/sui` window.

The `/sui` window today (`SaftUI-Core/Config/optionswindow.lua`, `optionsbody.lua`, `optionswidgets.lua`):

- **The window** is drawn `st:SetTemplate(window, 'theme', 'solid', 'panel')`: under Blizzard the tooltip border and the Background fill. Its close button (`st:CreateCloseButton`) is at TOPRIGHT -16,-14, in no header, so it never moves to a socket.
- **The sidebar** (`BuildSidebar`): a brand block ("SAFTUI / Options"), the Edit mode and Keybind mode buttons, the nav (groups FRAMES / COMBAT / INFO, each a grey text header and its pages), and a foot ("Profile: Default"). Its background is a flat texture, `SIDEBAR_BG` {0.09, 0.09, 0.09, 1}, made once and never themed: **this is why it isn't skinned.** 1px lines (`OB.LINE`, `EdgeLine`) separate its parts and edge it on the right. Under Blizzard the nav rows already show `Options_List_Hover` / `Options_List_Active` (`ART.optionslist`).
- **The main column** has no fill of its own (the window's shows): the page title, the tabs (already `Options_Tab_*` under Blizzard), the search box (`common-search-border-*`, the glass drawn 24 wide), the body (a scroll frame of sections with 1px rules between sections), and the footer (Reload UI and Close, already Blizzard's red panel buttons; a status line between them; a 1px line above).
- **Controls under Blizzard** (project 3b-2's table): check boxes `checkbox-minimal` / `checkmark-minimal` in a 12px box; dropdowns in Blizzard's other dropdown style (`common-dropdown-textholder`, `common-dropdown-a-button`, list `common-dropdown-bg`); sliders `Minimal_SliderBar_*` with no end arrows; text boxes `auctionhouse-ui-inputfield-*`; scroll: the 3px bar only, no Blizzard scroll bar.

SaftUI's unit frames today (`SaftUI-Unitframes/`):

- `unitframes.lua` draws the frame `st:SetBackdrop(frame, config.theme, config.background, 'bar')`; the root default is Theme None (no backdrop); raid10 and raid40 use the theme with a Solid background. `groups.lua` draws test frames the same way.
- Health, power and additional power each draw their own `bar` backdrop 3px outside the bar: under Blizzard, the tooltip border. Health fills the frame, so its border is the frame's border today. Power is on by default only for the player, as a separate 299x20 bar. The castbar defaults to Thin (Theme on the player's and target's own castbars).
- Bar fills are SaftUI's flat texture (`SaftUI Flat`, `Interface\BUTTONS\WHITE8X8`), tinted by oUF (class, reaction, power colors); a dark `bg` behind.
- Sizes: default 301x34; party 200 wide; pet and target of target 120; boss 200; raid10 80x50; raid40 57x30. Raid frames sit 3px apart.

## Blizzard's art

Researched 2026-11-11 from Gethe/wow-ui-source (`forever` and `live`, identical for every file below but trivia) and wago.tools' atlas tables at the builds `tests/wow/atlases.lua` names (Forever 1.60.1.70888, retail 12.1.5.70783). **Every atlas below exists on both clients at the same size** (UI units). Forever draws an atlas's Camelot member (`-c60`) where it has one: same size, bronze art where retail's is gold or grey. Forever's Settings panel is the Mainline one. The researchers' full reports: the controller's scratchpad, `report-research-settings-art.md` and `report-research-unitframe-art.md`; their main facts are below.

### The Settings panel (`Blizzard_Settings_Shared`, `SettingsFrameTemplate`, 920x724)

| Part | Art | How Blizzard lays it out |
| ---- | --- | ------------------------ |
| Frame | the character frame's metal (`ART.metal`, already SaftUI's `window` kind), title text at TOP 0,-5, the close button in the socket (`ART.close`) | `ButtonFrameTemplateNoPortrait` |
| Background | no atlas: `PANEL_BACKGROUND_COLOR` (0.12, 0.118, 0.129, 0.8) | `FlatPanelBackgroundTemplate` |
| Inner frame | `Options_InnerFrame` 886x618, **one bitmap**: a dark vignette edge, a bronze outline and the sidebar/content divider drawn in at x ≈ 199 of 886; transparent middle. Not sliceable | OVERLAY 2, TOPLEFT 17,-64, at its atlas size |
| Sidebar | no panel of its own: a 199-wide list over the inner frame | rows spaced 2 |
| Section header ("Gameplay") | `Options_CategoryHeader_1`, `_2`, `_3`, each 199x144 with art only in the top ~30 rows (a dark banner, bronze rim) | header 175x30; the art TOPLEFT, at atlas size; label `GameFontHighlightMedium` (white) at LEFT 20,-1; the nth header uses `((n-1) % 3) + 1` |
| Category row | normal: no art, gold text (`GameFontNormal`); hover `Options_List_Hover` 187x21; selected `Options_List_Active` 187x21 (no Camelot member), white text (`GameFontHighlight`) | row 175x20, art centred at atlas size (6 over each side), label TOPLEFT 36,1 |
| Tabs | `Options_Tab_Left/Middle/Right` 7x23, 1x23, 7x23; picked `Options_Tab_Active_*` 7x26, 1x26, 7x26 | already SaftUI's `ART.optionstab` |
| Search box | `common-search-border-left/middle/right` (16x40, 224x40, 16x40) drawn 8x20, 10x20, 8x20; glass `common-search-magnifyingglass` drawn **10x10** at LEFT 1,-1 | box 350x22 |
| Page header | title `GameFontHighlightHuge` at TOPLEFT 7,-22; divider `Options_HorizontalDivider` 630x1 (a fading line, not tiled) at y -50 | `SettingsListTemplate.Header` |
| Body section header | text only (`GameFontHighlightLarge`), **no rules** | |
| Check box | `checkbox-minimal` 30x29, `checkmark-minimal` 30x29, `checkmark-minimal-disabled` | a 30x29 control |
| Dropdown | **WowStyle2**: `common-dropdown-c-button` 39x39 and `-hover-1`, `-pressed-1`, `-pressedhover-1`, `-open`, `-disabled`; one texture anchored (-7,7) to (7,-7) around a 25-tall button, so its 7px glow spills outside the button; hover arrow `common-dropdown-c-button-hover-arrow` 12x5; text `GameFontNormal` centred, insets 13, pressed offset (2,-1) | `WowStyle2DropdownTemplate` |
| Dropdown steppers | `WowStyle2IconButtonTemplate` 26x25: background `common-dropdown-c-button` with `-hover-2`, `-pressed-2`, `-pressedhover-2`, `-disabled`; icons `common-dropdown-icon-back` / `-next` (and `-disabled`) 17x17, yellow triangles | `DropdownWithSteppersTemplate` 223x38 |
| Dropdown list | `common-dropdown-c-bg` 90x90, placed (-17,12) to (17,-22) around the menu, inset 3/6/3/7; row hover `common-dropdown-customize-mouseover` 20x20 | `MenuStyle2Mixin` |
| Slider | track `Minimal_SliderBar_Left` 11x17, `_Minimal_SliderBar_Middle` 1x17 (tiled across), `Minimal_SliderBar_Right` 11x17; thumb `Minimal_SliderBar_Button` 20x19; end arrows `Minimal_SliderBar_Button_Left` 11x19 (4 left of the track) and `Minimal_SliderBar_Button_Right` 9x18 (4 right) | `MinimalSliderWithSteppersTemplate` |
| Buttons | the red panel button (`Interface\Buttons\UI-Panel-Button-*`), already SaftUI's `ART.button`; the grey ones in the screenshot are the same button disabled | |
| Scroll bar | `MinimalScrollBar`, 8 wide: track `minimal-scrollbar-track-top` / `-bottom` 8x8 and `!minimal-scrollbar-track-middle` 8x1 (tiled down); thumb `minimal-scrollbar-small-thumb-top` / `-bottom` 8x8 and `-middle` 8x715, each with `-over` and `-down`; arrows `minimal-scrollbar-arrow-top` / `-bottom` 17x11 with `-over` and `-down` | track inset 19 for the arrows; thumb at least 23 |

Don't use `uiframebackground-nineslice-cornertop*`, `-edge*` or `-center`: those names exist on neither client. Use `Options_Tab_Left`, not Forever's stray `Options_Tab_Left_`.

### Blizzard's unit frames (`Blizzard_UnitFrame`)

- **The player, target, target of target, focus, party, pet and boss frames are each one shaped texture** with the portrait ring, the bar wells and their dividers drawn in, at a fixed size (`UI-HUD-UnitFrame-Player-PortraitOn` 198x71; `UI-HUD-UnitFrame-Target-PortraitOn` 194x68 on Forever, 192x67 on retail). None can wrap a rectangle of another size as shipped.
- **Their rectangular ends can be cut into a box.** The target art's left end and the player art's right end are a plain bronze-lined rectangle (gold and grey on retail), which cut by texture coordinates gives 8 pieces: four 8x8 corners, edges a 1px slice stretched. The researcher's starting rectangles on Forever's Camelot art (atlas-local pixels, x range × y range, ends exclusive), to be tuned in game:

  | Piece | From | Rectangle |
  | ----- | ---- | --------- |
  | top left | `UI-HUD-UnitFrame-Target-PortraitOn` | 2-10 × 8-16 |
  | bottom left | same | 2-10 × 50-58 (align its bottom with the bottom right's: the mockup showed a 1px step) |
  | left edge, stretched down | same | 2-10 × 30-40 |
  | top right | `UI-HUD-UnitFrame-Player-PortraitOn` | 187-195 × 11-19 |
  | bottom right | same | 187-195 × 52-60 |
  | right edge, stretched down | same | 187-195 × 34-42 |
  | top and bottom edges, stretched across | same | 120-121 × 11-19 and 120-121 × 52-60 |

  Retail's art is a different drawing at nearly the same size: its rectangles are measured from retail's members, not copied. Cutting an atlas by texture coordinates has precedent in SaftUI (`LayButton` in `themeart.lua`).
- **Blizzard's raid and party frames** (`CompactUnitFrame`, identical on both branches) have no border per member. The border is on the group: `CompactRaidGroupTemplate`'s `borderFrame.Background`, atlas `options_frame_child` 28x26 (a Camelot member on Forever: bronze, a faint dark middle; retail's middle is clear), anchored from member 1's top left (-2, 2) to member 5's bottom right (2, -3), shown with Edit Mode's Display Border. Blizzard stretches it whole; **sliced at 6px margins it stays crisp at any size** (a 2-3px border with 4px rounded corners).
- **Bar fills:** the compact frames' `RaidFrame-Hp-Fill` 32x32 (tiled, neutral grey, tinted by code), their background `raidframe-hp-bg-white` 32x32 (tiled, tinted), power `_RaidFrame-Resource-Fill` and `_RaidFrame-Resource-Background` 16x6 (tiled across). No Camelot members. The player frame's own fills (`UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health` and the like) are pre-coloured, so a class color tinting them comes out muddy: not used.

## Goals

### 1. `/sui` as Blizzard's Settings window, under the Blizzard theme

Under Thick and Thin `/sui` is exactly as today: every frame, size and cell rect.

**The window**
- Drawn as kind `window`: the metal, with the Window background fill (the dark grey). The title bar reads **"SaftUI Options"** in the header font, centred, as a window's header now does (the title-bar fix above).
- The close button sits in the metal's socket, as a window's does.
- **My call: the window may grow under Blizzard,** in width and height, by what the metal, the inner frame's rim and the scroll bar need, so the body keeps its 774 width and no cell rect or row height changes. Under Thick and Thin the window is today's 1040 by its height.
- **My call:** the sidebar's brand block ("SAFTUI / Options") is hidden under Blizzard, since the title bar names the window; the window is dragged by its title bar. Under Thick and Thin the brand stays.

**The inner frame**
- `Options_InnerFrame` is drawn over the area inside the metal, under the title bar, down to the footer, covering the sidebar and the main column. It's one bitmap, stretched to that area.
- **My call: under Blizzard the footer spans the whole window under the inner frame,** as Blizzard's Settings window has its buttons below the inner frame: Reload UI at its left, Close at its right, the status line between. The sidebar's foot ("Profile: …") moves up inside the inner frame, at the sidebar's bottom.
- **The sidebar's width follows the divider drawn into it:** `round(199 / 886 × the inner frame's width)`, so the sidebar's right edge sits on the drawn divider (about 225–235, against 210). The main column takes the rest, which is why the window grows. Under Thick and Thin the widths are today's.
- No fill of the window's own shows through anywhere but where the inner frame's middle is clear, which is the Window background.

**The sidebar**
- No background of its own and no 1px lines (its edge, and the lines around the Edit mode buttons and the foot): the inner frame shows. Under Thick and Thin the flat `SIDEBAR_BG` and the lines are as today. **This fixes "the sidebar doesn't get skinned".**
- **Section headers** (FRAMES, COMBAT, INFO, and any later group): the Settings banner, `Options_CategoryHeader_n` cycling 1, 2, 3, at Blizzard's layout (the art TOPLEFT at its atlas size, so it hangs below the header's 30; the label at LEFT 20,-1 in white).
- **Nav rows:** the hover and selected art they have today; text gold (Blizzard's normal font color, 1, 0.82, 0) and white when selected or hovered, as the Settings category list does.
- The Edit mode and Keybind mode buttons and the foot keep their places inside the inner frame.

**The main column**
- **The page title** keeps its place and font; under it, across the main column, `Options_HorizontalDivider` (stretched across, a fading line) in place of the tab row's 1px line.
- **Tabs and subtabs:** as today (`Options_Tab_*`).
- **The search box:** as today, the glass drawn 10x10 at LEFT 1,-1, as Settings draws it.
- **Body sections:** the section titles stay; the 1px rules between sections are not drawn under Blizzard. Column dividers inside a widget (the Categories tab's) stay.
- **The footer:** spans the window under the inner frame (above); the 1px line above it is not drawn under Blizzard; Reload UI and Close stay the red panel buttons; the status line stays.

**Fonts** — **My call:** no font changes. SaftUI's fonts stay everywhere (a fonts restructure is its own parked project); only art and the text colors named here change.

**Controls under Blizzard**
- **Check boxes** (toggles, the multiselect's rows, the check lists): the same art, drawn larger, as the Settings box is: the largest whole size up to 30x29, in proportion, that fits the row without changing any row's height or any cell rect.
- **Dropdowns** (every `select` in `/sui`: option rows, the picker row, the position block's frame dropdown, the Categories tab's rule editor): the WowStyle2 button (`common-dropdown-c-button` and its states, the hover arrow), text centred, its list on `common-dropdown-c-bg` with Blizzard's outsets, **in place of the list's tooltip-border frame** (c-bg is the list's own border and shadow, as Blizzard's menu has; no double border), its rows hovering on `common-dropdown-customize-mouseover`. The list is a top-level frame, so its outsets are never clipped.
  - The button's 7px glow may spill outside the control's rect, as Blizzard's does, but must never be clipped by a scroll frame or overlap the neighbouring cell's control.
- **Steppers:** a `select` in an option row (the widget a page's option draws, and the picker row's) gets Blizzard's ◀ ▶ steppers (`WowStyle2IconButtonTemplate`'s art) either side of the button, inside the widget's current width (the button narrows; no cell moves).
  - A click picks the previous or next choice in the list's order straight away, exactly as picking it from the list does (validate, set, the window re-renders).
  - At the first or last choice the arrow at that end is disabled (no wrap, as Blizzard's); a disabled select's arrows are disabled.
  - **My call:** the compact dropdowns (the position block's frame dropdown, the rule editor's) take the button art without steppers, since they have no room.
- **Sliders:** Blizzard's end arrows (`Minimal_SliderBar_Button_Left` / `_Right`) either side of the track, inside the slider's current width. A click moves the value one step (the option's step) down or up, as dragging would, clamped to its range; an arrow at the end of the range is disabled.
- **Scroll bars:** every scroll area in `/sui` (the body, the sidebar's nav when it scrolls, the Categories tab's list and editor, `W.Prompt`'s and `W.Confirm`'s boxes if they scroll, a dropdown list that scrolls) shows Blizzard's `MinimalScrollBar` in place of the 3px bar, only when it has something to scroll.
  - It works as a scroll bar: drag the thumb, click an arrow to step, click the track to page, the wheel as today. The thumb uses `-over` and `-down` art.
  - It sits in the room the 3px bar has today (right of the area, inside the existing padding), without moving content. Where 17 (the arrows' width) doesn't fit, the arrows may be drawn at the track's 8 width (the art scaled) — **say which in the report.**
- **Unchanged under Blizzard:** text boxes and value boxes (`auctionhouse-ui-inputfield-*`), color swatches, the keybinding button, the position block's nudges and point dots, the multiselect's 1px box, buttons, tabs.

**Elsewhere**
- **The Categories tab's category list** (a sidebar of categories) takes the nav rows' look under Blizzard: `Options_List_Hover` and `Options_List_Active`, gold text, white when selected. Its drag handles, counts and the drop line stay.
- **My call:** the bag window's bank tabs and the confirm and prompt dialogs' frames stay as they are (the tooltip border, now grey). Blizzard's Settings panel has no equivalent for the bank tabs; Blizzard's dialogs use another border.

**Switching:** a theme switch Thick → Blizzard → Thick (and a profile switch) with `/sui` open re-lays it out with no /reload, as the theme does elsewhere, and nothing of one look is left in the other.

### 2. Unit frame borders under the Blizzard theme

Under Thick and Thin unit frames are exactly as today.

**A new kind, `unitframe`**
- Under Thick and Thin it draws exactly as `bar` does (same inset, same lines, same fill).
- Under Blizzard it draws **the bronze box**: the 8 pieces cut from the player and target art (above), per client, laid out by SaftUI around the drawn frame (never `NineSliceUtil`), with the Background fill inside. The box's inset (how far its art reaches in) and its offsets are per client, measured in game from the starting rectangles.
- `ThemeArt` grows the box's art table with a slice table per client; every atlas it names is in `tests/wow/atlases.lua` for both clients.

**Single frames** (player, target, focus, pet, target of target, boss, and any other unit that isn't party or raid)
- Every draw in `SaftUI-Unitframes` that uses kind `bar` today for a unit frame or one of its bars (the frame, health, power, additional power, the castbar when it uses the theme, `groups.lua`'s test frames) uses `unitframe`.
- **No unit frame shows two boxes on the same edge.** Today health fills the frame, so with the frame's own Theme on, the frame's box and health's would coincide: only one shows. Bars that sit apart (the player's separate power bar, a castbar) have their own box.
- A Theme override of Thin on an element keeps Thin's line (the castbar's default).

**Party and raid frames**
- **My call: one group border per group header.** `groups.lua` makes one secure group header each for party, raid10 and raid40; a raid header fills rows of five in group order, so a row is only a real raid group while every earlier group is full. The border goes around each header's shown members: one around the party, one around the whole raid (as Blizzard's raid frames read with Keep Groups Together off). A border per real raid group would need a secure header per group, a rework of the raid frames: a followup if wanted.
- The **group border** is `options_frame_child` sliced at 6px margins (8 pieces, no middle drawn), with Blizzard's offsets (-2, 2) and (2, -3) around the header's shown members. Anchored to the header, which sizes itself to its shown members, so it follows joins and leaves, in combat too, with no code of SaftUI's running.
- The frames inside draw no border of their own under Blizzard (the frame, health and power).
- **Which Theme turns it on** (my call): the group border shows when the unit's frames are drawn in Blizzard's look: the unit's frame Theme, or its health Theme where the frame's is None (today's party default), resolves to Blizzard. A unit set to Thick while SaftUI's theme is Blizzard keeps Thick borders on each member and shows no group border.
- The border must follow a group whose size changes in combat without a protected call: it's a SaftUI frame anchored to the group, written onto no secure frame (`.agents/taint.md`).
- Under Thick and Thin each frame keeps today's border and no group border shows.

**Bar fills under Blizzard**
- Health on every unit frame draws `RaidFrame-Hp-Fill` (tintable: class, reaction and SaftUI's own colors still apply), its background `raidframe-hp-bg-white`, tinted as the `bg` is today. Power and additional power draw `_RaidFrame-Resource-Fill` over `_RaidFrame-Resource-Background`.
- **My call:** only where the element's texture is the default (`SaftUI Flat`); a texture the user picked stays. The castbar keeps its texture.
- **Which Theme** (my call): each bar's own resolved Theme. Health set to None while SaftUI's theme is Blizzard resolves to None, so it keeps the flat fill.
- Under Thick and Thin the fills are today's.

## Combat and taint

- Every piece is a texture on a SaftUI frame. Nothing is written onto a Blizzard frame, no Blizzard setter runs for the theme, no `NineSliceUtil`.
- `/sui` is SaftUI's own window. The steppers and slider arrows call the same set path a pick or a drag does.
- Unit frames are secure: the box and the group border are SaftUI frames and textures; nothing protected is called to draw, size or move them, in or out of combat. A theme switch in combat applies after combat, as today.
- Frame levels that are secret get no math (`issecretvalue`).

## Both clients

Every atlas above exists on both, same sizes. Forever draws the Camelot members (bronze); retail draws gold and grey. The bronze box's slice rectangles differ per client. The tests run each look on both (`T.client`).

## Constraints

- **`.agents/taint.md`** and **`.agents/edit-mode.md`**'s whole-pixel layout rules under every theme.
- **Saved profiles keep working,** with no step the user has to take.
- **Words the user sees:** no atlas or file name.

## Non-goals

- Blizzard's portrait ring, name plate, level badge, bar dividers, vehicle and class-resource frame variants, or any of Blizzard's frame shapes.
- Settings' row hover (the white 0.1 behind a hovered option row).
- Settings' fonts.
- A Blizzard look for text boxes, the multiselect box and the point dots (Settings has none).
- Nameplates.
- The bank tabs and the dialogs' frames (above).

## Anti-goals

- Anything different under Thick or Thin, or for a profile that never picks Blizzard.
- A cell rect or row height that changes under Blizzard (the controls fit their current rects).
- Art clipped by a scroll frame, or over content (text, icons, bar fills) past its inset.
- A protected call, or a write onto a secure or Blizzard frame, to draw a unit frame's border.
- A frame left in one look after a switch to another, until a reload.

## Tests

- **`/sui` under Blizzard, on both clients:** the window drawn as `window` with "SaftUI Options" in its title bar and the close button in the socket; the inner frame over the area under the title bar; the sidebar's width from the divider (and the main column's); no sidebar fill or lines; the brand hidden; banners by index; nav text colors; the page title's divider; no body rules; no footer line; the 10x10 glass. Under Thick and Thin every frame, width and cell rect is as before (compare against the values today's tests assert).
- **Controls:** the check box size and that no row height changed; the WowStyle2 button and its states; steppers on option-row selects (a click picks the previous or next choice through the same path as a pick; disabled at the ends and when the select is); no steppers on the compact dropdowns; the list's art; the slider arrows (a click steps by the option's step, clamped, disabled at the ends); the scroll bar on each scroll area (only with something to scroll; thumb drag, arrows, track click; the wheel).
- **The Categories tab's list** in the nav rows' look under Blizzard.
- **Switches:** Thick → Blizzard → Thick and a profile switch with `/sui` open: the layout, the art and the widths come and go.
- **Unit frames:** `unitframe` is `bar` under Thick and Thin (same draws); under Blizzard the 8 pieces, their texture coordinates per client, layers and placement; one box per edge (frame and health coinciding); the player's separate power bar boxed; Thin overrides stay lines; party and raid frames bare inside and the group border around each group's shown members, following a member joining in combat with nothing written onto a secure frame (the locked fixture); the fills under Blizzard only for the default texture.
- **Atlases:** every new atlas exists on both clients (`tests/wow/atlases.lua`).
- **Taint and scans:** the existing ones pass (no `NineSliceUtil`, kinds named, no foreign writes).

## Left to the builder

- Exact sizes and offsets: the inner frame's area, the banner's place in SaftUI's nav rows, the check box size, the steppers' and slider arrows' fit, the scroll bar's place and its arrows' size, the bronze box's inset and offsets per client, the group border's offsets around SaftUI's group layouts. Measured against the art, then tuned in game by the user.
- How `/sui` re-lays out under Blizzard (constants per look, or one layout with the widths computed).
- How "no two boxes on one edge" is decided (the frame's box hides the coinciding element's, or the reverse).
- Where the group border's frame lives (it follows the header by its anchors).
- The window's exact size under Blizzard, and where the sidebar's foot sits inside the inner frame.
- Retail's bronze-box rectangles, measured from retail's members.

## The user's answers (2026-11-11)

1. `/sui`'s look: "Full Settings window (Recommended)".
2. Dropdowns: "Settings style + arrows (Recommended)".
3. Single unit frames: "Bronze frame box (Recommended)".
4. Party and raid frames: "Group border (Recommended)".

## The builder check's answers (2026-11-11, the controller's)

1. **Raid groups:** one border around each group header's shown members (above), not per real raid group: no secure-frame rework, nothing running in combat.
2. **`/sui` can't fit at 1040 under Blizzard:** the window grows under Blizzard; the body keeps 774; the footer spans the window under the inner frame; the sidebar's foot moves up inside it.
3. **Which Theme:** the group border by the unit's frame Theme (or health's where the frame's is None); fills by each bar's own Theme.
4. **The dropdown list:** c-bg replaces the list's tooltip-border frame.
5. **Order:** the plan is written after the four fixes in "Today" are on `modular`, against their code.

## Questions for the user

None open.
