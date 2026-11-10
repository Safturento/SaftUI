# SaftUI options, project 2: setting sizes, the Position block, and every page re-sorted

Date: 2026-11-09. Status: draft for the user's review.

This is project 2 of 3 in the options redesign the user asked for on 2026-11-09:
1. The new `/sui` window (`docs/superpowers/specs/2026-11-09-saftui-options-window-design.md`). Done; on `modular`.
2. **This spec:** how settings are sized and laid out, a Position block, and each module's page re-sorted, with the options the 2026-11-09 settings audit found missing.
3. A Global Settings page with editable fonts, templates and colors. It gets its own spec.

## Intent

The user tested the new window in game and found the layout still wastes space and separates things that belong together. Their notes, 2026-11-09:
- "We should have the ability to have smaller chunks instead of just half and half, for example here the Rested and Experience colors could be in the same row together in the left column."
- "The position configs could probably be one module that is in a single row with all 5 blanks, the x and y offsets don't need to have that large of input boxes."
- "I feel like height and width should be in the same row together, also we could include tooltips on mouseover to explain what different configs do, for example it's not immediately clear what the spacing config does here."
- "This check box is soooo far from its label and it should be right next to it" (Loot → Rolls → Test mode).

Today every setting takes half a row: its label on the left, its control at the column's right edge. Position is five separate fields: Anchor, Frame, Relative, X Offset and Y Offset.

Project 2 also carries what project 1 deferred:
- re-sorting each module's settings into sections;
- adding the settings the 2026-11-09 audit found with no option (`docs/followups.md`, "Settings with no /sui option, settings nothing reads, and frames with no edit mode mover");
- two things that differ from the window mockup (below).

## What the user decided

- **Three sizes.** A setting is small (a quarter of the page), normal (half, the default) or wide (the whole row). The two columns stay lined up: sizes snap to quarters, halves and whole rows.
- **Small controls sit right after their label:** checkboxes and color swatches.
- **The Experience page,** in the user's words: "spacing would be next to template so that height and width would be next to each other, and the experience color and rested color would be next to each other occupying the space of one current item, it should probably come before alpha as well." As rows:
  - Template | Spacing
  - Height | Width
  - [Experience color, Rested color] | Rested bar alpha
  - then Position.

  The first part of `docs/superpowers/specs/assets/2026-11-09-options-layout-sizes-mockup.html` shows it. That file's second part (Position options A to C) is superseded by the next item.
- **The Position block** is one unit, the point-picker design. The user picked it ("I like the third one the best for sure") and refined it to "perfect". Reference: `docs/superpowers/specs/assets/2026-11-09-options-position-block-mockup.html`. To view it with SaftUI's fonts, serve it with Colus and Agency FB under `/files/`, as for the window mockup.
  - It reads left to right: **THIS** [3×3 dot square: this frame's point] **TO** [the target frame] **AT ITS** [3×3 dot square: the target's point] **OFFSET** [X over Y].
  - Each part has a caption above it, in Colus 11px, grey and upper case, centered over the part.
  - Parts are 12px apart. Every part is centered on a 48px band, the height of a dot square.
  - A dot square is 48×48. A click on a dot picks that point, and the picked dot is drawn larger in blue.
  - OFFSET stacks X over Y. Each has its label (X, Y) to the left of its box. The boxes are 22px tall with 4px between them, so the stack is 48px. Each box has nudge arrows attached flush on its right, the same height.
  - **Unit frame parts:** the user noted the target "is gonna turn into something a bit more tricky since you can switch between anchoring to the unitframe, anchoring to other uf elements, or anchoring to a global frame name." The TO part becomes a stack like OFFSET: a dropdown on the top row (Unit frame, that unit frame's parts, Global frame), and a name box on the bottom row only when Global frame is picked. Otherwise the bottom row stays empty, so nothing shifts. This is what `generators.uf_element_position` offers today (`SaftUI-Core/Config/widgets.lua`), redrawn.
- **Tooltips:** every option explains itself on hover.
- **Leave Ace's vocabulary where ours is clearer:** "If this are more clear by deviating from the ace options table lets do it - as long as it doesn't break any of the profiles db stuff I don't care and I'd rather just improve things than be trapped in an unuseful standard."
- **The re-sort applies the rules to every page,** and the user checks the result in game. There is no per-page review first ("you can go for it").
- **Missing options:** earlier on 2026-11-09 the user asked for options for every setting the audit found with no option ("can we work on getting config options for all of these items?"). That includes the boss layout settings, "Can we instead implement those options?", rather than removing them.

## Goals

- Every page in `/sui` follows the layout rules below. Related settings share a row, and nothing reads as "tossed in together".
- Every position editor in SaftUI is the Position block, with the unit frame version for unit frame parts.
- Every option has a tooltip (`desc`) that says in plain words what it does. That includes the options Core's shared generators make.
- Every per-module setting the audit found with no option gets one (list below).
- The window's picker is labelled for what it picks, and the Edit mode page is no longer alone under "Other" (below).
- Saved profiles keep working: no saved setting is renamed, moved or reinterpreted.

## Non-goals

- **Global Settings (project 3):** Core's settings stay out of this project:
  - `misc.icon_trim`, `misc.clamp_inset`;
  - the fonts' `shadow_offset` and `spacing`;
  - `headers.*`, `buttons.*`, `panels.*`;
  - editable `templates.*`;
  - the global `colors.*`.
- **The loot window:** its skin and the `loot.popup.*` settings get their own short design pass with design options.
- **Unit frame parts on screen:** edit mode movers for screen-placed unit frame parts have their own followup.
- **Other unit frame features:** Portrait, AuraWatch, aura timer bars, the aura filters and arena frames are their own work.
- **Changing what any setting does,** with two exceptions:
  - fixing a default that would make a newly exposed option error or do nothing (see the builder's calls);
  - the boss layout settings, which nothing reads today and which the user asked to have built (below).

## Anti-goals

- **Columns that stop lining up.** The user's first complaint about the Ace window was items "not well aligned with each other and some are even touching". Sizes must snap to the grid, never to content width.
- **A saved profile that loads differently** after this project.
- **An option that errors, or does nothing, when turned on.** The 2026-11-07 followup lists such defaults ("Unit frame defaults that nothing reads, or that break when turned on").

## Constraints

- The repo's rules apply: `.agents/taint.md` (read it before touching any Blizzard frame), `.agents/edit-mode.md`, `.agents/architecture.md`, `.agents/clients.md` and `.agents/testing.md`.
- Both clients: Forever (16001) and retail (120000).
- `tests/run` must pass, and new layout and Position logic gets tests in `tests/core/`.
- The window stays 1040×700 at SaftUI's pixel-perfect scale. The body is about 774 wide: two 367 columns with a 40 gap (`optionsbody.lua`).
- **Saved data:**
  - AceDB, the profile database and its keys don't change.
  - Option tables may change freely; they're only read by the window and the tests.
  - The Ace-made Profiles page (AceDBOptions) has to keep working unchanged.

## The layout rules

- **Sizes.** An option declares its size with a SaftUI field, `size = 'small'` or `size = 'wide'`; no field means normal.
  - The window no longer reads Ace's `width` for layout.
  - SaftUI's own tables drop their `width` values as their pages are re-sorted.
  - Tables SaftUI doesn't write, like AceDBOptions' Profiles page, draw at normal size.
- **Packing.** Rows fill left to right in the option order:
  - a normal option takes the next free half;
  - a small option takes the next free quarter, and two smalls fill one half;
  - a wide option starts a new row and takes all of it.

  A normal or wide option never starts partway into a half. If one follows a lone small, the rest of that half stays empty.
- **Where controls sit:**
  - A toggle's checkbox and a color's swatch sit right after their label, at any size.
  - Other controls keep their place at the right edge of their cell, so sliders, dropdowns and boxes line up down the column.
- **Order on a page.** Related settings share a row, as in the Experience example: size with size (Height and Width), colors together, toggles together as smalls. Position comes last.

## The Position option

- **One option.** Position is a single option of SaftUI's own type, drawn as the Position block. It replaces the group of five options `generators.position` and `generators.uf_element_position` make today.
- **Its parts:**
  - this frame's point;
  - the target, which is a frame name, or the unit frame dropdown and name;
  - the target's point;
  - X and Y.

  Each part reads and writes the same profile keys the generators use now. The existing checks still run: `st:ValidateAnchor`, the Global frame default of `UIParent`, and writing `false`, not `nil`, to clear a key.
- **Everywhere.** Every position editor in SaftUI shows the block. That includes every module that calls those generators:
  - action bars, bags, chat, loot, minimap, the micro menu;
  - buffs, the swing timer, experience, the tooltip, the totem bar;
  - the unit frame parts.

  It also includes three that place a text or icon inside its own button or icon, with no target to pick:
  - **aura count and timer spots** (`generators.position(order, false, ...)`, `SaftUI-Unitframes/elements/auras.lua`);
  - **the action bars' Text tab** (hotkey, count, macro), built by hand (`SaftUI-ActionBars/options.lua`);
  - **the buff frames' texts,** built the same way (`SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua`).

  For these, the block drops its TO part and reads **THIS** [dots] **AT ITS** [dots] **OFFSET** [X over Y], the same in every other way. Their X and Y sliders, -50 to 50 today, become the block's number boxes with nudge arrows. *(Builder's call; the user didn't see this version.)*

## The two mockup differences

- **The picker's label** says what it picks: "Unit" on Unit frames and "Bar" on Action bars. Today it shows the page's name.
- **The Edit mode page** is today the only entry under "Other", right next to the sidebar's Edit mode button. It moves to Global Settings as an Edit mode tab next to Fonts, and the empty "Other" group disappears. *(Builder's call, below.)*

## Missing options, by module

These come from the audit (`docs/followups.md`). Core's are left to project 3, and `loot.popup.*` to the loot window design.

- **Unit frames:**
  - `range_alpha.inside` and `.outside`;
  - **Boss layout:** `spacing`, `growthDirection`, `maxColumns`, `unitsPerColumn`, `columnSpacing`, `initialAnchor`.
    - Today only `spacing` does anything. `UF:PlaceUnitFrame` and `UF:PlaceHolder` (`SaftUI-Unitframes/unitframes.lua`) stack boss frames in one column, and only `groups.lua` reads the other five keys, for party and raid.
    - The user asked for these to be built, not removed ("Can we instead implement those options?"). Boss frames are laid out by all six, as party and raid are by theirs.
    - The holder and its edit mode outline are sized to that layout.
    - With the defaults (one column of five, growing down), boss frames sit exactly where they do today.
  - `alpha` on every element that has one;
  - `health.texture`, `health.text.boss_percent`;
  - Health's color toggles: `colorTapping`, `colorDisconnected`, `colorHealth`, `colorClass`, `colorClassNPC`, `colorClassPet`, `colorReaction`, `colorSmooth`;
  - Power's color toggles: `colorTapping`, `colorDisconnected`, `colorPower`, `colorClass`, `colorClassNPC`, `colorClassPet`, `colorReaction`;
  - `colorCustom` with its color, on Health, Power and Additional power, now that it works (`33d5118`);
  - `name.show_classification`, `name.colorClass`;
  - the indicators' `template`.
- **Bags:** `inventory.enable`, `template`, `padding`, `categoryTitleHeight`, `scrollSpeed`, `autorepair`, `autovendor`, `combinedBank`, `inverted`, `fonts.titles`, `fonts.icons`.
- **Chat:** `chat.linespacing`.
- **Action bars:** `actionbars.template`.
- **Misc:**
  - `tooltip.template` and `.font`;
  - `skinning.font` and `.template` (Skinning has no page today);
  - `totembar.colors.*`.

If an item on this list turns out not to be read, or to break when set, it's left out and noted in `docs/followups.md`, not exposed.

## What's left to the builder

- **The page order of each module,** following the rules and the Experience example.
- **The tooltip text.** It should be plain words about what the setting changes in game, not what the code does.
- **How the window draws the Position block and packs sizes,** in `optionsbody.lua` and `optionswidgets.lua`, plus the model's support for the new option type and fields (`optionsmodel.lua`).

## Builder's calls (marked so the user can reject any)

- **Small sizes:** `size = 'small'` is for toggles, colors, execute buttons and short number inputs. A slider or dropdown that asks for small is drawn at normal size; there isn't room for one in a quarter.
- **Position nudges:** the arrows move 1px, or 10px with Shift, as nudging does in edit mode. Typing a number and pressing Enter sets it.
- **Position in search:** search finds the Position block as one result, "Position", on its page.
- **The reshaping goes away:**
  - `MergePositionIntoGeneral` and `UseTabsForInnermostSections` (`SaftUI-Core/Config/config.lua`) are removed;
  - each module's table declares its own sections and tabs;
  - Position is its own section, last on its tab.
- **The validation test** (`tests/core/options_validate_test.lua`) strips SaftUI's own fields before Ace's validator runs: `category`, `size` and the Position type.
- **Edit mode's settings move to Global Settings,** as a tab next to Fonts. Project 3 reworks Global Settings anyway, and these are app-wide settings. The sidebar's Edit mode button stays.
- **Boss gets party and raid's Layout group as it is:** Growth, Column growth, Columns, Units per column and Column spacing, with Spacing. Boss's default `growthDirection = 'DOWN'` isn't one of that dropdown's keys (TOP, BOTTOM, LEFT, RIGHT), so the default becomes the key that grows downward. Nothing saved can hold 'DOWN', because no option ever set it.
- **Defaults fixed so their options work:**
  - additional power defaults to `colorPower = true`, so it isn't white when turned on;
  - focus's castbar color default becomes a real color, so focus has its own castbar color again;
  - Health → Text → Deficit gets defaults on every unit.
