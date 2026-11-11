# Blizzard Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Blizzard as a third theme beside Thick and Thin. Under it, SaftUI draws each kind of frame in Blizzard's own art for that kind, on SaftUI's own frames, on both clients. Nothing changes for a profile that doesn't pick it.

**Architecture:**
- **The data and the drawing.** A new Core file, `SaftUI-Core/themeart.lua`, holds the Blizzard theme's tables (art pieces, insets, the title bar, the close button and button state art, per client) and the code that draws them. The engine (`SaftUI-Core/theme.lua`) resolves the theme and calls it for a Blizzard look. Thick and Thin keep today's code path.
- **Two engine calls learn the kind.** `st:ThemeInset` takes the kind, and a new `st:SetBorderColor` replaces modules' own `SetBackdropBorderColor` calls on drawn frames, so a module's colors reach art.
- **A new kind,** `window`, marks the frames with SaftUI's title bar.
- **Close buttons and window headers** follow SaftUI's theme.

**Tech Stack:** Lua 5.1 (WoW), Ace3 (AceDB-3.0, AceConfig-style option tables), SaftUI's own options window. Tests run on lupa's Lua 5.1 through `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-10-saftui-blizzard-theme-design.md`. Read it first. Its "My call"s are binding here, and so are the user's answers to its "Questions for the user". Run this plan only after the user has answered them. Where an answer differs from my call, change what that question names before the task starts:
- Q1 changes the window's placement (Task 2) and the title, close button and header buttons (Task 6);
- Q2 the Blizzard Background default (Task 1);
- Q3 the `panel` kind's art (Task 1);
- Q4 the bar art's scale (Tasks 1 and 2);
- Q5 the `small` kind (Tasks 1 and 2).

**Starting point:** `modular` at 57575d0 or later, in the worktree `.claude/worktrees/blizzardtheme` (branch `blizzardtheme`).

## Global Constraints

- **Clients:** WoW Forever (interface 16001) and retail (120000). Read per-client values through `st.forever` at call time, never at file load. Tests switch clients with `T.client(name)` (Task 1).
- **`.agents/taint.md`:**
  - Every piece of art is a texture on a frame of SaftUI's, kept in a weak table in `themeart.lua` keyed by the drawn frame.
  - Nothing is written onto a frame that isn't SaftUI's.
  - No file calls `NineSliceUtil`, and no Blizzard setter runs for the theme.
  - No art is sized by math on a size read back from the game (sizes can be secret). Place pieces by anchors and offsets.
- **Thick and Thin draw exactly as today.** Every existing theme test keeps its assertions, apart from the API changes this plan makes:
  - `st:ThemeInset`'s kind;
  - `st:SetBorderColor`;
  - `'blizzard'` stops being the stand-in for an unknown theme name in `tests/core/theme_test.lua` and `tests/core/theme_tab_test.lua`. Use `'later'`.
- **Defaults:** `st.defaults.theme.name` stays `'thick'`. No default anywhere is `'blizzard'`.
- **The Blizzard theme's colors** (`st.defaults.templates.blizzard`):
  - `bordercolor = { 0.5, 0.5, 0.5, 1 }`;
  - `altbordercolor = { 0, 0, 0, 0 }`;
  - `backdropcolor = { 0.09, 0.09, 0.19, 1 }`.
- **Option values, in this order:**
  - Theme tab: `thick` = "Thick", `thin` = "Thin", `blizzard` = "Blizzard".
  - Override Theme: `theme` = "Use SaftUI's theme", `thick` = "Thick", `thin` = "Thin", `blizzard` = "Blizzard", `none` = "None".
  - Background is unchanged.
- **Kinds:** `panel`, `window` (new), `bar`, `action`, `slot`, `aura`, `tooltip`, `header`, `close`, `small`.
- **The Blizzard look of each kind,** with its starting inset (the same on both clients until the builder measures them in game):

  | Kind | Art on the drawn frame | Art over the icon's edge | Fill | Inset |
  | ---- | ---------------------- | ------------------------ | ---- | ----- |
  | `window` | metal | none | Background | 2 |
  | `panel`, `bar`, `tooltip` | tooltip | none | Background | 3 |
  | `action` | `UI-HUD-ActionBar-IconFrame-Background`, `UI-HUD-ActionBar-IconFrame-Slot` | `UI-HUD-ActionBar-IconFrame` | (slot art) | 3 |
  | `slot` | `bags-item-slot64` | `Interface\Buttons\UI-Quickslot2` (Blizzard's 37-in-64 fit) | (slot art) | 3 |
  | `aura` | none | none | none | 0 |
  | `small` | none: one 1px line in Border | none | Background | 1 |
  | `header` | none: clear | none | none | 0 |
  | `close` | none | none | none | 0 |

- **Tooltip art,** piece keys `TopLeftCorner`, `TopRightCorner`, `BottomLeftCorner`, `BottomRightCorner`, `TopEdge`, `BottomEdge`, `LeftEdge` and `RightEdge`:
  - atlases `Tooltip-NineSlice-CornerTopLeft`, `Tooltip-NineSlice-CornerTopRight`, `Tooltip-NineSlice-CornerBottomLeft`, `Tooltip-NineSlice-CornerBottomRight`, `_Tooltip-NineSlice-EdgeTop`, `_Tooltip-NineSlice-EdgeBottom`, `!Tooltip-NineSlice-EdgeLeft` and `!Tooltip-NineSlice-EdgeRight`;
  - corners at the drawn frame's corners;
  - the top and bottom edges tile across between the corners, the side edges tile down.
- **Metal art** (`window`), the same piece keys:
  - atlases `UI-Frame-Metal-CornerTopLeft`, `-CornerTopRight`, `-CornerBottomLeft`, `-CornerBottomRight`, `_UI-Frame-Metal-EdgeTop`, `_UI-Frame-Metal-EdgeBottom`, `!UI-Frame-Metal-EdgeLeft` and `!UI-Frame-Metal-EdgeRight`;
  - layer OVERLAY, with texel snapping off;
  - corner offsets from the drawn frame's corners:

    | Corner | Retail | Forever |
    | ------ | ------ | ------- |
    | TopLeft | −8, 16 | −8, 16 |
    | TopRight | 4, 16 | 2, 16 |
    | BottomLeft | −8, −3 | −8, −8 |
    | BottomRight | 4, −3 | 2, −8 |

  - edges between the corners.
- **The metal's title bar** reaches 21 (retail) or 20 (Forever) down from the drawn frame's top. A window's backdrop under Blizzard sits its inset (2) outside the window on the left, right and bottom, and the title bar's height above it. The title bar lies above the window's header, and nothing inside the window moves.
- **A frame's own border color under Blizzard:**
  - tooltip and metal art: the pieces tinted;
  - `action`: `UI-HUD-ActionBar-IconFrame-Border` shown, in the color;
  - `slot` and `aura`: `Interface\Common\WhiteIconFrame` shown, in the color;
  - `small`: the line's color.
- **Close button** (SaftUI's theme Blizzard):
  - normal `RedButton-Exit`, pushed `RedButton-exit-pressed`, highlight `RedButton-Highlight` (ADD), disabled `RedButton-Exit-Disabled`;
  - size 24 (retail) or 28 (Forever);
  - on a window, at TOPRIGHT of the window's drawn frame, at (1, 0) on retail and (0, 3) on Forever.
- **Button state art** (SaftUI's theme Blizzard, where SaftUI makes the state textures):
  - `action`: hover `UI-HUD-ActionBar-IconFrame-Mouseover`, pushed `UI-HUD-ActionBar-IconFrame-Down`, checked `UI-HUD-ActionBar-IconFrame-Mouseover` (ADD on Forever, BLEND on retail) and flash `UI-HUD-ActionBar-IconFrame-Flash`, over the ring's footprint;
  - `slot`: pushed `Interface\Buttons\UI-Quickslot-Depress`, highlight `Interface\Buttons\ButtonHilight-Square` (ADD).
- **Words the user sees:** "Blizzard" joins the Themes words. No atlas or file name, and no "Template", "Highlight" or "Close Button", is ever shown.
- **Every option has a desc and no Ace `width`.**
- **Files:** keep each file's line endings (check with `file`), and never `sed -i` a CRLF file. Stage by explicit path only.
- **`tests/run` passes at the end of every task.**
- **Commit trailers,** on every commit:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PYgFsM3V6p9vWPEFz7WA9o
  ```

## Review Focus

1. **Thick → Blizzard → Thick with the bags open,** with an Epic item in a slot. Every slot, the window, its header and its close button change look and back. The Epic border comes back each time. The close button moves into the socket and out, and the header's view buttons move to its right edge and back (Task 6 test).
2. **A module set to None while SaftUI's theme is Blizzard.** It draws nothing and keeps no art from an earlier draw (Task 2 test).
3. **One module overridden to Blizzard while SaftUI's theme is Thick.** Its frames wear the art. Its window header keeps Thick's strip and SaftUI's close button keeps its look and place, because both follow SaftUI's theme (Task 6 test).
4. **A frame drawn for the first time in combat under Blizzard** (a bag opened mid-fight). It gets its art, and nothing errors (Task 2 test). Protection itself is an in-game check: the stubs don't model it.
5. **A profile switch from a Blizzard profile to a Thick one.** The window, its header and its close button take Thick's look, and the tooltip loses its art, with no reload (Task 6 test).

## Order and parallelism

- Task 1 first.
- Tasks 2 and 3 in parallel after 1. They touch disjoint files, except that both add to `tests/lib/theme_helpers.lua` (different functions): keep both sides.
- Task 4 after 2.
- Task 5 after 4. Both convert call sites in the same module files.
- Tasks 6 and 7 in parallel after 5. They touch disjoint files, and both only read the tables Task 1 made.
- Task 8 last. The docs wait for it, so parallel tasks never conflict in `.agents/`.

---

### Task 1: The Blizzard theme's looks: tables, resolution, insets and the window kind

**Files:**
- Create: `SaftUI-Core/themeart.lua`, holding the Blizzard tables in the Global Constraints. Load it right after `theme.lua` in `SaftUI-Core/SaftUI-Core_Forever.toc` and `SaftUI-Core_Mainline.toc`, and in `load_core_helpers` (`tests/lib/shell.lua`, after `theme.lua`).
- Modify:
  - `SaftUI-Core/theme.lua`: the known themes add `blizzard`, `st.THEME_KINDS` adds `window`, and `st:ResolveTheme` and `st:ThemeInset` take a kind;
  - `SaftUI-Core/Config/defaults.lua`: `templates.blizzard`.
- Create: `tests/wow/atlases.lua`, every atlas `st:ThemeAtlases()` returns, with each client's size and tiling from the spec's tables. Load it with the other stubs.
- Modify:
  - `tests/wow/blizzard.lua`: `C_Texture.GetAtlasInfo(name)` answers from `atlases.lua` for `stub.interface`'s client: `{ width, height, tilesHorizontally, tilesVertically }`, or nil for any other name;
  - `tests/lib/theme_helpers.lua`: `T.client(name)`, with name `'forever'` or `'retail'`. It does `reset_world()`, sets `stub.interface`, reloads `constants.lua`, runs `load_core_helpers()` and `apply_defaults()`, as `tests/bags/bag_world.lua`'s `W.fresh` does;
  - `tests/core/theme_test.lua`: the unknown-name case uses `'later'`.
- Test: `tests/core/theme_blizzard_test.lua` (new).

**Interfaces:**
- Produces:
  - `st.THEME_KINDS.window = true`.
  - `st:ResolveTheme(theme, background, kind) -> look | nil`:
    - `look = { name = 'thick'|'thin'|'blizzard', inset = number|nil, alpha = number, colors = st.config.profile.templates[name], kind = kind }`;
    - under Blizzard `inset` is `st.ThemeArt.Inset(kind)`, and nil with no kind;
    - alpha and None follow today's rules.
  - `st:ThemeInset(theme, background, kind) -> number`: 0 for None. Until Task 5, a missing kind under Blizzard reads as `'panel'`.
  - `st.ThemeArt`, the engine's table, private to Core and the tests:
    - `.Client() -> 'forever'|'live'`;
    - `.Inset(kind) -> number`;
    - `.TitleHeight() -> 21|20`;
    - `.Close() -> { size, x, y, normal, pushed, highlight, disabled }`;
    - `.State(kind) -> { hover, pushed, checked, checkedBlend, flash, highlight } | nil` (keys per the Global Constraints);
    - `.KINDS[kind]` and `.ART[name]`, the tables, in the shape the builder picks.
  - `st:ThemeAtlases() -> { [atlasName] = true }`: every atlas the tables name (not files).
  - `T.client(name)` in `tests/lib/theme_helpers.lua`.

- [ ] **Step 1: Write the failing tests** in `tests/core/theme_blizzard_test.lua`:
  - `'Blizzard resolves like Thick and Thin'`, with `profile.theme.name = 'blizzard'`:
    ```lua
    local look = st:ResolveTheme('theme', 'theme', 'tooltip')
    eq(look.name, 'blizzard'); eq(look.alpha, 0.9); eq(look.inset, 3)
    eq(look.colors, st.config.profile.templates.blizzard)
    eq(st:ResolveTheme('theme', 'solid', 'tooltip').alpha, 1)
    eq(st:ResolveTheme('none', 'theme', 'tooltip'), nil)
    eq(st:ResolveTheme('thick', 'theme', 'tooltip').inset, 2)
    eq(st:ResolveTheme('blizzard', 'theme', 'window').inset, 2) -- an override that names Blizzard
    ```
  - `"each kind's inset under Blizzard, on Forever and on retail"`:
    - for each client (`T.client`), `st:ThemeInset('blizzard', 'theme', kind)` equals the Global Constraints' inset for all ten kinds;
    - `st.ThemeArt.TitleHeight()` is 20 on Forever and 21 on retail;
    - `st.ThemeArt.Close().size` is 28 on Forever and 24 on retail.
  - `'Thick and Thin insets ignore the kind'`: for every kind, `st:ThemeInset('thick', 'theme', kind) == 2` and `('thin', ...) == 1`.
  - `'a window draws as a panel under Thick and Thin'`: for each of Thick and Thin, `st:SetBackdrop(a, 'theme', 'theme', 'window')` and `st:SetBackdrop(b, 'theme', 'theme', 'panel')` give equal `T.fill`, `T.edge`, `T.inset` and `T.offset(…, 'TOPLEFT')`.
  - `"the Blizzard theme's default colors"`: `templates.blizzard` equals the Global Constraints' arrays.
  - `'no default names Blizzard'`: `st.defaults.theme.name == 'thick'`, and a walk of `st.defaults` finds no string value `'blizzard'`.
  - `'every atlas the theme names exists on both clients'`: for each client, every name in `st:ThemeAtlases()` gives a `C_Texture.GetAtlasInfo`, and there are at least 30 names.
  - `'an unknown saved theme still reads as Thick, and Blizzard is known'`: name `'later'` resolves as `thick`, and `'blizzard'` as `blizzard`.
- [ ] **Step 2: Run them; they fail.** `tests/run tests/core/theme_blizzard_test.lua` fails: `st:ThemeAtlases` is nil.
- [ ] **Step 3: Implement** `themeart.lua`'s tables and accessors, and the `theme.lua` and defaults changes. Change `tests/core/theme_test.lua`'s unknown-name case to `'later'`. Its behavior is unchanged: only the stand-in name moves, because `'blizzard'` is now known.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `core: the Blizzard theme's looks: art tables per client, insets by kind, the window kind`

### Task 2: Drawing the Blizzard looks

**Files:**
- Modify:
  - `SaftUI-Core/themeart.lua`: paint, color and clear a Blizzard look;
  - `SaftUI-Core/theme.lua`: `Paint`, `Color`, `DrawBackdrop` and `Redraw` hand a Blizzard look to `st.ThemeArt`. Each draw records its inset. Under Blizzard the backdrop has a fill and no edge, Thick's lines are hidden, `header` is cleared and `small` is Thin's drawing in Blizzard's colors. Under Thick and Thin any art the frame has is hidden;
  - `SaftUI-Core/api.lua`: `st:CalculateSpacing` reads `st:DrawnInset` for `frame` and `anchorFrame` in place of `.thick`. A frame that was never drawn counts as 0, as today;
  - `tests/lib/theme_helpers.lua`: `T.art(frame)` and `T.over(frame)`.
- Test: `tests/core/theme_blizzard_draw_test.lua` (new).

**Interfaces:**
- Consumes: Task 1's `st:ResolveTheme`, `st.ThemeArt.*` and `T.client`.
- Produces:
  - `st:DrawnInset(frame) -> number|nil`: the inset `frame` was last drawn at. `frame` is a drawn frame, or the owner of a backdrop the engine drew.
  - `st:DrawnKind(frame) -> kind|nil`: the same lookup, for the kind.
  - `st.ThemeArt.Get(frame) -> { pieces = { [key] = texture }, over = { [key] = texture }, own = texture|nil } | nil`, for a drawn frame. `pieces` are on the drawn frame, `over` over the icon's edge, and `own` is the own-color piece (Task 4).
  - `T.art(frame)` and `T.over(frame)`: the shown pieces as `'key=atlas-or-file'`, sorted and comma-joined.
- Piece keys:
  - tooltip and metal: the eight keys in the Global Constraints;
  - `action`: `SlotBackground` and `SlotArt` on the drawn frame, `Ring` over;
  - `slot`: `SlotArt`, and `Ring` over.
- The fill is the drawn frame's backdrop fill, inset by the kind's inset. For `action` and `slot` that fill is clear, and the slot art takes the look's alpha.

- [ ] **Step 1: Write the failing tests** in `tests/core/theme_blizzard_draw_test.lua`, with `profile.theme.name = 'blizzard'`, on Forever unless named:
  - `'a tooltip: the eight tooltip pieces, edges tiled, no line, the Background at the Opacity'`:
    - `T.art(backdrop)` lists the eight tooltip atlases;
    - `TopEdge` tiles horizontally and `LeftEdge` vertically;
    - `T.fill(backdrop) == '0.09,0.09,0.19,0.9'`;
    - the backdrop has no `edgeFile`;
    - Thick's lines are hidden.
  - `'bars and panels wear the tooltip border, a window the metal'`: `T.art` for `bar` and `panel` is the tooltip's, and for `window` the metal's.
  - `"the metal's corners sit at each client's offsets"`: `T.offset` of `TopRightCorner` and `BottomLeftCorner` is `4,16` and `-8,-3` on retail, `2,16` and `-8,-8` on Forever.
  - `"an action button: the ring over the icon's edge, the slot art behind"`:
    - `T.over(backdrop) == 'Ring=UI-HUD-ActionBar-IconFrame'`;
    - `T.art(backdrop)` has `SlotArt` and `SlotBackground`;
    - the slot art's alpha is 0.9;
    - the fill is clear.
  - `"a slot: the item ring and the empty slot's art"`.
  - `'an aura has no art; small is one line in Border; a header draws nothing'`: for `small`, `T.edge == '0.5,0.5,0.5,1'` and `T.inset == 1`; for a header strip, nothing at all.
  - `"Thick, Blizzard, Thin, Blizzard: art only under Blizzard, Thick's lines only under Thick, each backdrop at its kind's inset"`. A tooltip, a window, an action button and a small frame, each drawn with `st:SetBackdrop`, go through the switches by `st:RedrawThemed()`. `T.offset(backdrop, 'TOPLEFT')` is:
    - `-2,2` under Thick;
    - under Blizzard: `-3,3` (tooltip), `-2,20` (window, Forever), `-3,3` (action) and `-1,1` (small);
    - `-1,1` under Thin;
    - the Blizzard values again.

    Art is shown only under Blizzard.
  - `"a window's metal reaches the title bar above it"`: `T.offset(backdrop, 'TOPLEFT')` is `-2,21` and `BOTTOMRIGHT` `2,-2` on retail; `-2,20` on Forever.
  - `'a recolor under Blizzard: the fill and the small lines follow, the art stays white, nothing moves'`:
    - set `templates.blizzard.backdropcolor` and `.bordercolor`, then run `st:RecolorThemed()`;
    - the fill and the line change;
    - every piece's vertex color is `1,1,1,1`;
    - the points are unchanged.
  - `'None under Blizzard draws nothing and clears the art'` (Review Focus 2): draw a tooltip with `'theme'`, then draw it again with `'none'`: no backdrop shows and `T.art` is `''`. A redraw keeps it bare.
  - `'CalculateSpacing follows the drawn inset'`: 3 for a `st:SetBackdrop` action button under Blizzard, 2 under Thick, 0 for a frame never drawn.
  - `'a frame first drawn in combat under Blizzard gets its art'` (Review Focus 4): with `stub.in_combat = true`, a new slot drawn with `st:SetBackdrop(slot, 'theme', 'theme', 'slot')` has its `T.art` and `T.over`, and `take_errors()` is empty.
  - `"drawing under Blizzard writes nothing onto a frame that isn't SaftUI's"`: `st:SetBackdropIn` for each kind on a frame from `tests/misc/fixtures/locked_widget.lua`.
  - `'no SaftUI file names NineSliceUtil'`: neither `read_saftui_source('SaftUI-Core/theme.lua')` nor `'SaftUI-Core/themeart.lua'` contains `NineSliceUtil`.
- [ ] **Step 2: Run them; they fail.** `tests/run tests/core/theme_blizzard_draw_test.lua`.
- [ ] **Step 3: Implement.** Pieces are textures made once per drawn frame, and shown, hidden and re-pointed on later draws. A window's placement isn't the same on every side, so the record of where a backdrop was placed (`entry.placed`, `IsPlaced`) keeps the top offset apart from the others. A redraw still moves only a backdrop that sits where the engine put it. A piece is set with `SetAtlas(name, true)`, or with `SetTexture(file)` for a file. For the `slot` ring's fit, crop Blizzard's 37-in-64 with `SetTexCoord`, or size it from SaftUI's config; read no size back from the game.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes, and every existing theme test is unchanged.
- [ ] **Step 5: Commit.** `core: draw the Blizzard theme: tooltip border, metal, button rings, the drawn inset`

### Task 3: Blizzard on the Theme tab and in every override

**Files:**
- Modify:
  - `SaftUI-Core/Media/theme.lua`: the Theme select offers Thick, Thin and Blizzard in that order (a sort list, as `OrderedSelect` makes). Under Blizzard, Border's and Background's descs say what they color there: Border is the small frames' line, the art keeps Blizzard's colors, and Background is the fill. Outer border stays hidden (it only shows for Thick). Reset's confirm reads "Reset the Blizzard theme to SaftUI's defaults?";
  - `SaftUI-Core/Config/widgets.lua`: `THEME_VALUES` adds `{ 'blizzard', 'Blizzard' }` before None;
  - `tests/lib/theme_helpers.lua`: `T.check_options` expects Blizzard in the Theme choices;
  - `tests/core/theme_tab_test.lua`: the unknown-name case uses `'later'`.
- Test: `tests/core/theme_tab_test.lua`, `tests/core/config_generators_test.lua`.

**Interfaces:**
- Consumes: Task 1's `templates.blizzard` and `st:ResolveTheme`.
- Produces: `generators.theme(order, desc)` offering `theme, thick, thin, blizzard, none`.

- [ ] **Step 1: Write the failing tests:**
  - `'the Theme tab offers Thick, Thin and Blizzard, in that order'`.
  - `"under Blizzard, Border and Background say what they color there, and Outer border hides"`: the descs differ from Thick's, and both mention Blizzard's art.
  - `'each theme keeps its own colors, Blizzard too'`: set Thick's Border, switch to Blizzard, set Blizzard's Border, switch back. Thick's is still the one set, and `templates.blizzard.bordercolor` holds Blizzard's.
  - `"Reset under Blizzard restores Blizzard's colors and the transparency"`.
  - In `config_generators_test.lua`: `"the Theme builder offers Use SaftUI's theme, Thick, Thin, Blizzard and None, in that order"`.
  - Every module page test that runs `T.check_options` now expects Blizzard.
- [ ] **Step 2: Run them; they fail.** `tests/run tests/core/theme_tab_test.lua tests/core/config_generators_test.lua`.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `config: Blizzard on the Theme tab and in every module's Theme override`

### Task 4: A frame's own border color: `st:SetBorderColor`

**Files:**
- Modify:
  - `SaftUI-Core/theme.lua` (`st:SetBorderColor`) and `SaftUI-Core/themeart.lua` (the own-color piece for each kind).
  - Every module call that colors a drawn backdrop's border, which moves to `st:SetBorderColor`. A reset to the theme's border, by hand or by drawing again, becomes `st:SetBorderColor(frame)`:
    - `SaftUI-ActionBars/skin.lua` (`ColorEquipped`, `AB:UpdateEquippedBorder`);
    - `SaftUI-Bags/container.lua:809`, `currencies.lua:223`, `inventory.lua:85` and `slot.lua` (`INV:SetSlotQualityBorder`, `INV:SetSlotThemeBorder`);
    - `SaftUI-Core/skinning.lua:271` (`ColorFocused`), `Widgets/radiogroup.lua:21` and `EditMode/mover.lua:25`;
    - `SaftUI-Loot/roll.lua:315` and `Feed/feed.lua:235,239`;
    - `SaftUI-Misc/tooltip.lua:23,25` (`ColorUnitBorders`), `totemskin.lua:178` and `Skinning/Blizzard_BuffFrame.lua:116-124` (`UpdateBorderColor`).
  - `tests/core/theme_kinds_test.lua`: the scan, below.
  - `docs/followups.md`: move "Two ways to reset a border to the theme's (bag slots and action buttons)" to Resolved, with a `**Resolved YYYY-MM-DD:**` line naming `st:SetBorderColor`, and update the ToC.
- Test: `tests/core/theme_blizzard_draw_test.lua`, `tests/bags/theme_test.lua`, `tests/actionbars/theme_test.lua`, `tests/misc/tooltip_skin_test.lua` and `tests/core/theme_kinds_test.lua`.

**Interfaces:**
- Consumes: Task 2's `st.ThemeArt.Get`.
- Produces: `st:SetBorderColor(frame, r, g, b, a)`.
  - `frame` is the drawn frame the caller holds: `x.backdrop`, `backdrops[x]`, or a frame drawn with `st:SetTemplate`.
  - With no `r` it puts the look's own border back.
  - Under Thick, Thin and `small` it is `SetBackdropBorderColor`, with the look's border color when no color is given.
  - Under Blizzard art it is the own-color behavior in the Global Constraints.
  - A frame that was never drawn, or is drawn None, is left alone.

- [ ] **Step 1: Write the failing tests:**
  - In `theme_blizzard_draw_test.lua`:
    - `'SetBorderColor under Thick and Thin is the border color, and no color is the theme's'`.
    - `"SetBorderColor under Blizzard: tooltip and metal pieces tinted, the action's equipped border, the slot's and aura's white icon border, no color takes it off"`: check vertex colors and the shown `own` piece's file or atlas.
  - In `theme_kinds_test.lua`, `"no module sets a drawn backdrop's border color itself"`. A scan of every loaded file except `SaftUI-Core/theme.lua` and `themeart.lua` finds no `:SetBackdropBorderColor(` whose receiver ends in `backdrop` or is indexed from a table named `backdrops`. Check it on a sample first, as the draw-call scanner is:
    - `item.backdrop:SetBackdropBorderColor(1,0,0)` is found;
    - `backdrops[t]:SetBackdropBorderColor(1,0,0)` is found;
    - `close:SetBackdropBorderColor(1,0,0)` isn't.
  - In `tests/bags/theme_test.lua`, `"under Blizzard an Epic item's slot shows the white icon border in the Epic color, through three recolors and a redraw"`. A free slot's border is off.
  - In `tests/actionbars/theme_test.lua`, `"under Blizzard an equipped item shows Blizzard's equipped border in the green, through a recolor"`.
  - In `tests/misc/tooltip_skin_test.lua`, `"under Blizzard a unit tooltip's border pieces take the class color, and lose it on the next show"`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement** `st:SetBorderColor` and convert every call site above.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `core: st:SetBorderColor, so a module's own border colors reach Blizzard's art; every module uses it`

### Task 5: Every inset names its kind

**Files:**
- Modify:
  - `SaftUI-Core/theme.lua`: `st:ThemeInset` without a kind is an error, unless the theme is `'none'`, as `CheckKind` does for draws.
  - Each caller, with the kind it draws:
    - `SaftUI-ActionBars/skin.lua:303` (`action`);
    - `SaftUI-Bags/container.lua:843` (`small`, the view buttons);
    - `SaftUI-Core/Config/optionswidgets.lua:1267` (`action`);
    - `SaftUI-Core/EditMode/snap.lua:71` (`small`, the mover overlays);
    - `SaftUI-Loot/roll.lua:369` (`small`) and `Feed/feed.lua:711` (`small`);
    - `SaftUI-Minimap/config.lua:48` (`panel`) and `micromenu.lua:106` (`small`);
    - `SaftUI-Misc/totemskin.lua:228` (`action`), `totemtimers.lua:143,559` (`bar`) and `Skinning/Blizzard_BuffFrame.lua:191` (`aura`).
  - `tests/core/theme_kinds_test.lua`: the scanner checks `st:ThemeInset(` calls for 3 arguments, the kind last, with the `'none'` exemption.
- Test: `tests/core/theme_kinds_test.lua`, `tests/core/theme_blizzard_test.lua`, `tests/actionbars/theme_test.lua`, `tests/bags/theme_test.lua` and `tests/misc/theme_test.lua`.

**Interfaces:**
- Consumes: Task 1's `st:ThemeInset(theme, background, kind)`.
- Produces: `st:ThemeInset` with the kind required.

- [ ] **Step 1: Write the failing tests:**
  - Scanner sample lines `"st:ThemeInset('theme', 'theme')"` (found) and `"st:ThemeInset('none', 'theme')"` (exempt), then `'every st:ThemeInset call names its kind'` over the loaded files.
  - `'st:ThemeInset with no kind is an error'`.
  - `"under Blizzard a 45px action button's icon sits inside the action inset"`: the icon's TOPLEFT is at `3,-3`, and the hotkey's width is `TextWidth`'s at inset 3.
  - `'under Blizzard the view buttons keep a visible gap'`: `INV:ViewButtonGaps()` under Blizzard is `2 * 1 + 3, 1 + 1 + 3`.
  - `'under Blizzard the buff duration clears the icon by the aura inset and one'`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `core: every st:ThemeInset names its kind`

### Task 6: Windows and close buttons

**Files:**
- Modify:
  - `SaftUI-Core/panels.lua`:
    - `st:CreatePanel` draws kind `window`.
    - `st:CreateCloseButton` registers its look with `st:KeepOwnColors`. Under SaftUI's theme Blizzard the look is the close button's four atlases at `st.ThemeArt.Close().size`, with today's backdrop, outline and X hidden.
    - On a window, it anchors at TOPRIGHT of the window's drawn frame, at `Close().x, y`. A window is a frame `st:CreateHeader` made a header for, whose backdrop `st:DrawnKind` says is `window`.
    - Under Thick and Thin it has today's look, back at the placement it had before.
    - Headers and footers keep `profile.headers.height` under every theme.
  - `SaftUI-Bags/inventory.lua:88,212`: the bag and bank windows draw kind `window`.
  - `SaftUI-Bags/container.lua` (`INV:SpaceViewButtons`, `INV:HeaderMinWidth`): while `st:CloseButtonInSocket(container)`, the view buttons line up from the header's right edge, `CLOSE_INSET` in, and the close button's width leaves the header's extent. Otherwise they line up as today.
  - `SaftUI-Misc/Skinning/skinning.lua:84`: `SK:SkinBlizzardPanel` draws kind `window`.
- Test: `tests/core/theme_blizzard_windows_test.lua` (new), `tests/bags/theme_test.lua`.

**Interfaces:**
- Consumes:
  - Task 1's `st.ThemeArt.Close()`;
  - Task 2's `st:DrawnKind`, and a window's placement;
  - `st:KeepOwnColors`.
- Produces: `st:CloseButtonInSocket(frame) -> boolean`, in `panels.lua`. It's true while `frame`'s close button from `st:CreateCloseButton` sits in the metal's socket.

- [ ] **Step 1: Write the failing tests** in `tests/core/theme_blizzard_windows_test.lua`:
  - `'st:CreatePanel draws a window'`: `T.watch()` sees kind `window`.
  - `"under Blizzard a window's header keeps its height and draws nothing; under Thick it has its strip again"`: 31 tall throughout, and the window's content keeps its points.
  - `"SaftUI's close button under Blizzard: Blizzard's four atlases at the client's size; under Thick its own look again"`: `GetNormalTexture():GetAtlas() == 'RedButton-Exit'` and the size is 28 on Forever, 24 on retail. Under Thick it is 24, with its X shown and its normal texture clear.
  - `'on a window the close button sits in the socket, and goes back'`:
    - its point is TOPRIGHT of the window's backdrop at `0, 3` (Forever) or `1, 0` (retail), and `st:CloseButtonInSocket` is true;
    - under Thick it is back at RIGHT of the header at `-10, 0`, and false.
  - `"the /sui window's close button keeps its place under Blizzard"`: it is a panel, not a window. Its point stays TOPRIGHT of the window at `-16, -14`, with Blizzard's atlases.
  - `"Thick, Blizzard, Thick with a bag window open"` (Review Focus 1, in `tests/bags/theme_test.lua`):
    - an Epic item's slot has its quality color after each switch;
    - the window wears the metal only under Blizzard;
    - the close button moves into the socket and out;
    - the last view button's RIGHT is at the header's RIGHT, `-CLOSE_INSET`, under Blizzard, and at the close button's LEFT again under Thick.
  - `"a window overridden to Blizzard under SaftUI's Thick: metal, Thick's strip, SaftUI's close button where it was"` (Review Focus 3, the bags' `theme = 'blizzard'`).
  - `'a profile switch from a Blizzard profile to a Thick one'` (Review Focus 5, in the AceDB world of `tests/core/config_helpers.lua`). A panel from `st:CreatePanel` and a tooltip backdrop are drawn in a Blizzard profile. After `SetProfile` to a Thick profile:
    - `T.art` is `''` for both;
    - the header is 31 tall with its strip;
    - the close button has its own look.
  - `'the bag and bank windows are windows'` (`tests/bags/theme_test.lua`).
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `core, bags: windows in the metal, with Blizzard's close button in its socket under the Blizzard theme`

### Task 7: Blizzard's state art on buttons, and Blizzard's buff borders

**Files:**
- Modify:
  - `SaftUI-ActionBars/skin.lua` (`AB:StyleButton`). When the action bars' Theme resolves to Blizzard (`st:ResolveTheme(theme, background, 'action').name == 'blizzard'`), `skin.hover`, `skin.pushed` and `skin.checked` take `st.ThemeArt.State('action')`'s atlases and blend, over the button's footprint, with no vertex tint. `button.Flash` takes the flash atlas. Otherwise they are today's flat textures, over the icon.
  - `SaftUI-Core/skinning.lua` (`st:SkinActionButton`): under a Blizzard look for kind `slot`, the pushed and highlight textures take `State('slot')`'s files. For `action`, the state atlases.
  - `SaftUI-Bags/slot.lua` (`INV:SkinSlot`): it stops clearing the pushed texture when the slot's look is Blizzard.
  - `SaftUI-Misc/totemskin.lua`: the state textures as for action buttons, set out of combat as today.
  - `SaftUI-Misc/Skinning/Blizzard_BuffFrame.lua`. Under a Blizzard look:
    - `DebuffBorder` and `TempEnchantBorder` show at alpha 1, centred on the icon and sized from the Auras config's icon size (4/3 and 16/15 of it);
    - SaftUI colors no border of its own;
    - a secret atlas still shows Blizzard's border.

    Under Thick and Thin, today's behavior.
- Test: `tests/actionbars/theme_test.lua`, `tests/bags/theme_test.lua`, `tests/misc/theme_test.lua`.

**Interfaces:**
- Consumes:
  - Task 1's `st.ThemeArt.State(kind)`;
  - Task 2's `st.ThemeArt.Get`;
  - Task 4's `st:SetBorderColor`.

- [ ] **Step 1: Write the failing tests:**
  - `"under Blizzard an action button's hover, pushed, checked and flash are Blizzard's atlases over the ring"`. Checked is ADD on Forever and BLEND on retail. Under Thick they are SaftUI's flat textures over the icon again.
  - `"under Blizzard a bag slot's pushed and highlight are Blizzard's files"`.
  - `"under Blizzard the buff skin shows Blizzard's debuff and enchant borders around the icon and colors nothing"`:
    - `DebuffBorder:GetAlpha() == 1`, sized 40 for a 30 icon;
    - its SaftUI backdrop shows no own-color piece;
    - under Thick they are hidden again, and the border color comes back.
  - `"under Blizzard the totem buttons take Blizzard's state art"`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `actionbars, bags, misc: Blizzard's button state art and buff borders under the Blizzard theme`

### Task 8: Docs, followups and the in-game list

**Files:**
- Modify:
  - `.agents/architecture.md` (Themes): Blizzard, `themeart.lua`, the `window` kind and its title bar above the window, `st:ThemeInset`'s kind, `st:SetBorderColor`, `st:DrawnInset` and `st:DrawnKind`, close buttons following the theme, and `st:CloseButtonInSocket`.
  - `.agents/taint.md`: art lives on SaftUI's frames, `NineSliceUtil` is never called, and the buff skin shows Blizzard's two borders.
  - `.agents/clients.md`:
    - Forever's Camelot (`-c60`) art under the same atlas names;
    - the metal and close button differences;
    - the clients' atlas tables on wago.tools (`UiTextureAtlasElement`, `UiTextureAtlasMember`, `UiTextureAtlas`, `GlobalColor`).
  - `.agents/edit-mode.md`: the Theme tab under Blizzard, and Blizzard in the overrides.
  - `.agents/testing.md`: `tests/wow/atlases.lua`, `C_Texture.GetAtlasInfo`, `T.client`, `T.art` and `T.over`, and the new test files.
  - `README.md`: Global Settings → Theme offers Blizzard.
  - `docs/followups.md`, new Active entries in the user-level template:
    - "Blizzard theme: in-game checks": the measured insets and offsets on both clients, the ring's layer, the item ring's fit, texel snapping on the metal, and a theme switch in and out of combat;
    - "Per-dispel-type debuff art on SaftUI's own aura buttons";
    - "Icons drawn as small could be slots under Blizzard".
  - The Themes spec's project 2 line: point it at the new spec.

- [ ] **Step 1: Update the docs.**
- [ ] **Step 2: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 3: Run the doc checks.** `agents-doc-parity-check` and `readme-freshness-check`; fix what they find.
- [ ] **Step 4: Write the in-game checklist** for the user in the task's report: each kind under Blizzard on Forever and retail, and the five Review Focus cases.
- [ ] **Step 5: Commit.** `docs: the Blizzard theme in the agent docs, README and followups`
