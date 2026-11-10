# Themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace SaftUI's user-facing templates with one theme (Thick or Thin, with editable colors and a transparency switch), set on a Theme tab in Global Settings. Every module's look becomes a Theme and Background override that follows the theme by default. Every draw call names the kind of frame it draws.

**Architecture:**
- **Core resolves and draws.** A small resolver in Core turns a module's `theme` and `background` values (or, during the transition, an old template name) into a look: lines, inset, colors and alpha.
- **Drawing goes through the existing functions,** `st:SetTemplate`, `st:SetBackdrop` and `st:SetBackdropIn`. They take the new arguments plus a kind, and record every frame they draw so a theme change can recolor or redraw them.
- **Modules move one at a time.** Each moves from its `template` keys to `theme` and `background` keys, and its call sites to the new arguments.
- **A final task switches on the migration** of saved `template` keys, and adds a source scan that every draw call passes a kind.

**Tech Stack:** Lua 5.1 (WoW), Ace3 (AceDB-3.0, AceConfig option tables), SaftUI's own options window; tests on lupa's Lua 5.1 through `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-10-saftui-themes-design.md` (approved by the user, 2026-11-10). Read it first. Each "My call" in it is binding here.

**Starting point:** `modular` with the `coresettings` branch merged (Core's leftover settings). Global Settings' tabs are then General | Fonts | Colors | Edit mode. The Theme tab goes between Colors and Edit mode.

## Global Constraints

- **Clients:** WoW Forever (interface 16001) and retail (120000).
- **`.agents/taint.md`:** never write a field onto a frame that isn't SaftUI's. Frames that aren't SaftUI's are drawn through `st:SetBackdropIn` and the caller's own table. A kind is an argument, never a field on someone else's frame.
- **Saved profiles keep working with no step the user takes.** "Template" may stay inside code and saved variables; only what the user sees changes.
- **Words the user sees:** Theme, Background, Use SaftUI's theme, Thick, Thin, None, Solid, Transparent, Transparent background, Opacity, Border, Outer border, Reset. "Template", "Highlight" and "Close Button" are never shown.
- **Option values, in this order:**
  - Theme: `theme` = "Use SaftUI's theme", `thick` = "Thick", `thin` = "Thin", `none` = "None";
  - Background: `theme` = "Use SaftUI's theme", `solid` = "Solid", `transparent` = "Transparent".
- **Defaults:** `st.defaults.theme = { name = 'thick', transparent = true, opacity = 0.9 }`.
- **Theme colors** stay arrays in `st.defaults.templates.thick` and `.thin`, with today's values. `templates.close` keeps `backdropcolor = { 0.5, 0.1, 0.1, 0.4 }`. The `highlight`, `thicktransparent` and `thintransparent` entries go.
- **Old template name → theme and background** (one table, `LEGACY`, used by the transition mode and the migration):

  | Old name | theme | background |
  | -------- | ----- | ---------- |
  | `thicktransparent` | `thick` | `transparent` |
  | `thintransparent` | `thin` | `transparent` |
  | `thick` | `thick` | `solid` |
  | `thin` | `thin` | `solid` |
  | `none` | `none` | (unchanged) |
  | `highlight`, `close` | (unchanged) | (unchanged) |

  For `highlight` and `close` the key is just removed, so the module's defaults apply.
- **Old default → new default** (a module's defaults, and hard-coded names at call sites):

  | Old default | theme | background |
  | ----------- | ----- | ---------- |
  | `thicktransparent` | `theme` | `theme` |
  | `thick` | `theme` | `solid` |
  | `thin` | `thin` | `solid` |
  | `thintransparent` | `thin` | `theme` |
  | `none` | `none` | (background default `theme`) |

- **Kinds:** `panel`, `bar`, `action`, `slot`, `aura`, `tooltip`, `header` (header and footer strips), `close` (the close button) and `small` (everything else). Under Thick and Thin only `header` and `close` draw differently.
- **Every option has a desc, and no Ace `width`.** A select with no `size` is a half line, which is fine.
- **Files:** keep each file's line endings (check with `file`); never `sed -i` a CRLF file.
- **`tests/run` passes at the end of every task.**
- **Commit trailers,** on every commit:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PYgFsM3V6p9vWPEFz7WA9o
  ```

## Review Focus

1. **A theme switch (Thick → Thin) with the bags open.** Slot and window backdrops move to the new 1px inset, with no gaps or overlaps (Task 5 test).
2. **Dragging the Border color picker with bags open.** Item quality borders survive every recolor (Task 5 test).
3. **A profile switch to a profile saved by the old version.** Its template keys migrate on the switch, not only at login (Task 7 test).
4. **A frame set to None when the theme or transparency switches.** It stays bare (Task 1 test).
5. **A module overridden to Transparent while the global toggle is off.** It uses the stored Opacity, not fully solid (Task 1 test).

## Order and parallelism

- Task 1 comes first.
- Tasks 2 and 3 can run in parallel after 1.
- Tasks 4, 5 and 6 can run in parallel after both 2 and 3: they touch disjoint addons. They use Task 2's `st:ThemeChanged`, and Task 3's option builders and Core keys.
- Task 7 runs last.

---

### Task 1: Core theme engine

**Files:**
- Create: `SaftUI-Core/theme.lua`. Load it after `panels.lua` in `SaftUI-Core/SaftUI-Core_Forever.toc` and `_Mainline.toc`, and in the test shell's Core loader (`tests/lib/shell.lua` / `load_core_helpers`).
- Modify:
  - `SaftUI-Core/panels.lua` (`st:SetTemplate`, `st:SetBackdrop`);
  - `SaftUI-Core/api.lua` (`st:SetBackdropIn`, `st:CalculateSpacing` stays on `frame.thick`);
  - `SaftUI-Core/Config/defaults.lua`;
  - `SaftUI-Core/Config/widgets.lua`: remove `st.Config:UpdateTemplateConfig`, and keep `generators.template` working until Task 7;
  - every direct `st.config.profile.templates[...]` read outside Core: `SaftUI-ActionBars/skin.lua:77`, `SaftUI-Bags/slot.lua:34`, `SaftUI-Minimap/config.lua:47`, `microbuttons.lua:154`, `micromenu.lua:106`, `SaftUI-Misc/totemskin.lua:161`, `SaftUI-Misc/Skinning/Blizzard_SwingTimer.lua:92`, `Blizzard_BuffFrame.lua`, `restedxp.lua` and `SaftUI-Unitframes/elements/auras.lua:71`. They switch to `st:ThemeInset` or `st:ResolveTheme`, so the trimmed `templates` table breaks nothing.
- Test: `tests/core/theme_test.lua` (new).

**Interfaces (produces):**
- `st.THEME_KINDS`: a set table of the nine kind strings.
- `st:ResolveTheme(theme, background) -> look | nil`. `theme` is `'theme'`/nil, `'thick'`, `'thin'` or `'none'`; `background` is `'theme'`/nil, `'solid'` or `'transparent'`.
  - `look = { name = 'thick'|'thin', inset = 2|1, alpha = number, colors = st.config.profile.templates[name] }`.
  - `alpha` is `profile.theme.opacity` when the resolved background is transparent, else 1. An explicit `'transparent'` uses the stored opacity even while `profile.theme.transparent` is false.
  - Returns nil for `'none'`. An unknown theme reads as `'theme'`.
- `st:ResolveLegacyTemplate(name) -> look | nil`: an old template name through `LEGACY`. `highlight` and `close` read as `'theme', 'theme'`.
- `st:ThemeInset(theme, background) -> 2|1|0`, through the legacy reading when `theme` is an old name with no background.
- `st:SetTemplate(frame, theme, background, kind)`, `st:SetBackdrop(frame, theme, background, kind)`, `st:SetBackdropIn(backdrops, frame, theme, background, kind)`.
  - **Transition mode:** while `kind == nil`, `theme` is read as an old template name (`st:ResolveLegacyTemplate`), so unconverted call sites draw exactly as today. The names `'highlight'` and `'close'` draw as kinds `header` and `close` (below).
  - **Kinds `header` and `close` ignore `theme`/`background`** and draw SaftUI's theme's strip or close look:
    - `header`: fill = the resolved theme's `bordercolor` RGB at alpha 0.4, no border lines;
    - `close`: fill = `templates.close.backdropcolor`, no border lines;
    - both: SetBackdrop offset = the theme's inset.
  - Drawing is today's: Thick's alt border, the 1px edge, the inset. The background alpha is `backdropcolor[4] * look.alpha`.
  - `frame.thick` (SaftUI frames only) stays `look.name == 'thick'`.
- `st:RecolorThemed()`: re-applies colors and alpha to every recorded frame, without moving anything. Then `st:ColorsChanged('theme')`.
- `st:RedrawThemed()`: re-runs the full draw for every recorded frame with its recorded arguments. That moves `SetBackdrop`/`SetBackdropIn` backdrops to the current inset, and clears a frame that now resolves to nil.
- **The record:** a weak-keyed table in `theme.lua`, frame → `{ theme, background, kind, owner, backdrops }`. It replaces `st.template_cache`. `owner` and `backdrops` let a redraw re-run `SetBackdrop`/`SetBackdropIn`.

- [ ] **Step 1: Write the failing tests** in `tests/core/theme_test.lua` (with `load_core_helpers()` and `apply_defaults()`, as other Core tests do):
  - `'the theme follows the profile: thick, transparent at 0.9 by default'`:
    - `ResolveTheme('theme','theme')` is name `thick`, inset 2, alpha 0.9;
    - `ResolveTheme('thin','solid')` is inset 1, alpha 1;
    - `ResolveTheme('none','transparent')` is nil.
  - `'an explicit Transparent uses the stored opacity while the toggle is off'`: with `profile.theme.transparent = false` and `opacity = 0.7`, `ResolveTheme('theme','transparent').alpha == 0.7`, and `ResolveTheme('theme','theme').alpha == 1`.
  - `'old names read as LEGACY'`: `ResolveLegacyTemplate('thicktransparent')` is thick at 0.9; `'thick'` is alpha 1; `'thintransparent'` is thin at 0.9; `'none'` is nil; `'highlight'` follows the theme.
  - `'a call with no kind draws an old name exactly as today'`: `st:SetTemplate(f, 'thick')` gives border color `0.3,0.3,0.3,1` and background alpha 1; `'thicktransparent'` gives background alpha 0.9.
  - `'header and close draw their own looks from the theme'`: header fill `0.3,0.3,0.3,0.4` under the default Thick; after `profile.templates.thick.bordercolor = {1,0,0,1}` and `RedrawThemed`, `1,0,0,0.4`; close fill `0.5,0.1,0.1,0.4`.
  - `'a recolor changes colors, not places, and calls ColorsChanged theme once'`:
    - a SetBackdrop'd panel's backdrop keeps its points;
    - a Thin frame keeps Thin's color when Thick's changes;
    - spy `st.ColorsChanged` sees `'theme'` once.
  - `'a redraw moves backdrops to the new inset and keeps None bare'`:
    - `st:SetBackdrop(f, 'theme', 'theme', 'panel')`, then set `profile.theme.name = 'thin'` and `RedrawThemed()`: the backdrop's TOPLEFT offset is `-1, 1`;
    - a frame drawn `'none'` has no backdrop after a redraw, and after `profile.theme.transparent = false` and a redraw.
  - `'ThemeInset'`: `('theme')` is 2 under Thick, `('thin')` is 1, `('none')` is 0, `('thicktransparent')` is 2.
  - `'every override combination resolves by the rule'`. Cover theme in `theme, thick, thin, none` × background in `theme, solid, transparent` × `profile.theme.name` in `thick, thin` × `profile.theme.transparent` in `true, false`, with opacity 0.6. `ResolveTheme` gives:
    - nil for none;
    - otherwise the name (`theme` → the profile's), and inset 2 or 1;
    - alpha 0.6 when the background is `transparent`, or `theme` with the toggle on; otherwise 1.
  - `'old highlight and close names still draw their own looks'`: `st:SetTemplate(f, 'highlight')` fills `0.3,0.3,0.3,0.4`, with no border lines.
- [ ] **Step 2: Run them; they fail.** `tests/run tests/core/theme_test.lua` fails, since `st:ResolveTheme` is nil.
- [ ] **Step 3: Implement.** Write `theme.lua` and the panels/api changes. Change the defaults:
  - add `st.defaults.theme`;
  - trim `templates` to `thick`, `thin` and `close`. The theme's name decides thickness, so their `border` and `thick` flags can go.

  Convert the direct `profile.templates[...]` reads listed above.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes. Existing tests use 2-argument calls, which the transition mode keeps as they were.
- [ ] **Step 5: Commit.** `core: theme engine: one resolver for theme and background, kinds on every draw, recolor and redraw of drawn frames`

### Task 2: The Theme tab

**Files:**
- Create: `SaftUI-Core/Media/theme.lua`, the module `Theme`, with `GetConfigTable`. Load it after `Media/colors.lua` in both Core TOCs and the test shell.
- Modify: `SaftUI-Core/Config/config.lua`. Global Settings' tabs become General | Fonts | Colors | Theme | Edit mode, with Global Settings' desc covering themes.
- Test: `tests/core/theme_tab_test.lua` (new). Update `tests/core/options_window_test.lua` (tab order); `tests/core/options_desc_test.lua` covers the new page.

**Interfaces:**
- Consumes `st:RecolorThemed()`, `st:RedrawThemed()` and `st:ColorsChanged`.
- Produces `st:ThemeChanged()`: `st:RedrawThemed()`, then `st.Config:UpdateConfig()`, then `st:ColorsChanged('theme')`. Task 3 onward rely on a theme switch doing this.
- The tab reads `st.config.profile.theme` and `st.config.profile.templates[name]` at call time. Never cache them: AceDB swaps tables on a profile change.

**The tab's rows,** in order:
1. **Theme** (select: Thick, Thin). Set → `st:ThemeChanged()`.
2. **Border, Outer border and Background** (color, no `hasAlpha`), for the chosen theme's `bordercolor`, `altbordercolor` and `backdropcolor`. Outer border is hidden unless the theme is Thick. Set writes r, g and b into the array in place → `st:RecolorThemed()`.
3. **Transparent background** (toggle). Set → `st:ThemeChanged()`.
4. **Opacity** (range 0-1, `isPercent`). Disabled while Transparent background is off. Set → `st:RecolorThemed()`.
5. **Reset** (execute, `confirm`). It restores the chosen theme's three colors and `transparent` and `opacity` from `st.defaults` → `st:ThemeChanged()`. Its confirm text: `"Reset the <Thick|Thin> theme to SaftUI's defaults?"`.

Descs are the builder's, plain and specific, in the Colors tab's voice.

If a module can't re-lay itself out live on a theme switch, and that can't be fixed within this plan, the tab's note says a reload is needed, as Colors' Text and Buttons do. The aim is no note.

- [ ] **Step 1: Write the failing tests:**
  - `'the Theme tab sits between Colors and Edit mode'`.
  - `'its rows, in order, with descs'`.
  - `'Outer border shows only for Thick'`.
  - `'Opacity is disabled while Transparent background is off'`.
  - `'each theme keeps its own colors'`: set Thick's Border, switch to Thin, set Thin's Border, switch back; Thick's is still the one set.
  - `'a color set recolors without a config update'`: spy `RecolorThemed` once and `st.Config.UpdateConfig` zero times.
  - `'a theme or toggle switch runs ThemeChanged'`: the spy sees RedrawThemed, then UpdateConfig, then `ColorsChanged('theme')`.
  - `'Reset restores the chosen theme and the transparency'`.
  - `'after a profile switch the rows reach the new profile'`. Use the AceDB world in `tests/core/config_helpers.lua`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement** `Media/theme.lua` and the config.lua tab wiring.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `config: a Theme tab in Global Settings: Thick or Thin, its colors, transparent background and opacity`

### Task 3: Core's own frames and keys

- **The option builders:** `SaftUI-Core/Config/widgets.lua` gets `generators.theme(order, desc)` and `generators.background(order, desc)`. Both return selects with the values, order and words in Global Constraints, named "Theme" and "Background".
  - Theme's desc is the caller's desc plus " Use SaftUI's theme follows Global Settings → Theme; None draws no border or background."
  - Background's desc defaults to "Solid, or see-through by Global Settings → Theme's Opacity. Use SaftUI's theme follows its Transparent background."

**Files:** every draw call in `SaftUI-Core/`:
- `panels.lua`: the header and footer → kind `header`; the close button → `close`; `st:CreatePanel`'s `panels.template` → `panels.theme`/`panels.background`, kind `panel`;
- `skinning.lua`: the wrappers `st:SkinActionButton(button, config)` and `st:SkinEditBox` take theme and background (from `config.theme`/`config.background`, or arguments) and pass a kind;
- `Widgets/*` (`button`, `checkbutton`, `editbox`, `radiogroup`, `scrollbar`, `statusbar`);
- `EditMode/mover.lua` and `picker.lua`;
- `Config/optionswindow.lua`: the window and its dialog → `'theme', 'solid', 'panel'`.

Plus:
- **The defaults** `buttons.template` and `panels.template` (`Config/defaults.lua`) → `buttons.theme`/`.background` and `panels.theme`/`.background`, by the old→new defaults table.
- **Their readers outside Core,** changed to the new keys: `SaftUI-ActionBars/bindings.lua:385`, `SaftUI-Bags/containers/bank.lua:98`, `SaftUI-Misc/totemskin.lua:469,571`, `SaftUI-Misc/totemtimers.lua:142,557` and `SaftUI-Misc/Skinning/skinning.lua:72`.
- **Edit mode's movers** recolor on `OnColorsChanged('theme')`. The movers' own colors are re-applied after a recolor.

Hard-coded names map by the old→new defaults table.

- Test: `tests/core/theme_core_frames_test.lua` (new), plus updates to existing Core tests that read `.template` fields.

- [ ] **Step 1: Write the failing tests:**
  - `'window headers and footers follow SaftUI's theme, not their window's'`: a panel drawn `'thin','solid'` still gets a header fill of the theme's border color at 0.4.
  - `'the /sui window takes the theme's border and stays solid'`: under the default theme, background alpha 1, border 0.3 grey; after a switch to Thin, 1px.
  - `'Core defaults: buttons and panels follow the theme'`: their theme and background resolve to today's `thicktransparent` look (`ResolveLegacyTemplate`).
  - `'a mover keeps its color through a recolor'`.
  - `'the theme and background builders: names, values in order, descs'`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.** Every Core draw call passes a kind; convert the keys and their readers.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `core: Core's frames draw with the theme and a kind; buttons and panels follow the theme`

### Task 4: Unit frames

**Files:**
- **Defaults:** `SaftUI-Unitframes/config/default.lua` and `config/units/*.lua`. Every `template` → `theme` + `background`, by the old→new defaults table. The `**` element default `'none'` becomes `theme = 'none'`, and the portrait's too.
- **Options:** `config/config.lua:634` and `elements/{castbar,classpower,auras,additionalpower,health,power,indicators}.lua`. Each `template = generators.template(...)` becomes `theme = generators.theme(order, desc)` plus `background = generators.background(order + 0.5)`. Change the desc's "look of" wording to fit Theme.
- **Draw calls:** `updaters.lua`, `unitframes.lua`, `groups.lua` (previews draw like their real frames) and the elements. Kinds: the frame and its bars → `bar`; auras → `aura`; the castbar icon, class power points and indicators → `small`.
- **Tests:** update `tests/unitframes/*` that read `template`. Add `tests/unitframes/theme_test.lua`.

**Interfaces:** consumes `generators.theme(order, desc)` and `generators.background(order, desc)` (Task 3).

- [ ] **Step 1: Write the failing tests:**
  - `'every unit frame default looks as it did'`. For each unit and element whose old default is known, `ResolveTheme(cfg.theme, cfg.background)` matches `ResolveLegacyTemplate(old)` on name, inset and alpha (nil for none). Take the old defaults from the base commit's `default.lua` and write them into the test as a table.
  - `'each element tab offers Theme and Background, with descs, and no template'`.
  - `'a boss or party preview draws like its real frame'`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `unitframes: Theme and Background on every element, following SaftUI's theme by default`

### Task 5: Bags and action bars

**Files:**
- **Bags:** `SaftUI-Bags/config.lua`. `template` → `theme`/`background`; `buttontemplate` → `buttontheme`/`buttonbackground`.
- **Bags options and draw calls:** `options.lua` (Look: Theme and Background for the windows, and Slot theme and Slot background for the slots), and the draw calls in `container.lua`, `inventory.lua`, `slot.lua`, `currencies.lua` and `containers/*`. Kinds: windows → `panel`; item, currency and bag-bar slots → `slot`; small toggles → `small`.
- **Bags on a theme change:** `INV:OnColorsChanged` also handles `'theme'`, redrawing the slots' quality borders and `INV:UpdateCurrencyBorders()`.
- **Action bars:** `SaftUI-ActionBars/config.lua`, `options.lua:379` and `skin.lua`. Buttons → kind `action`.
- **Action bars on a theme change:** `OnColorsChanged('theme')` re-applies the equipped border (`skin.lua:387`).
- **Tests:** update `tests/bags/*` and `tests/actionbars/*` that read `template`. Add `tests/bags/theme_test.lua` and `tests/actionbars/theme_test.lua`.

**Interfaces:** consumes the option builders (Task 3), `st:ThemeChanged()` (Task 2) and `st:RecolorThemed()` (Task 1).

- [ ] **Step 1: Write the failing tests:**
  - `'bag and action bar defaults look as they did'` (as in Task 4).
  - `'a theme switch with the bags open moves every slot and window backdrop to the new inset'` (Review Focus 1). Build a bag window with slots, set `profile.theme.name = 'thin'`, run `st:ThemeChanged()`: every slot backdrop's TOPLEFT is `-1, 1`.
  - `'quality borders survive a recolor'` (Review Focus 2). Fill a slot with an Epic item, run `st:RecolorThemed()` three times: its border is the profile's Epic color.
  - `'the equipped border survives a recolor'`.
  - `'Bags Look offers Theme, Background, Slot theme and Slot background, with descs'`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `bags, actionbars: Theme and Background overrides; quality and equipped borders survive a theme recolor`

### Task 6: Loot, chat, minimap and Misc

**Files:**
- **Loot:** `SaftUI-Loot/config.lua`, `options.lua:78,107`, `roll.lua` (roll bars → `bar`, their icons → `small`), `Feed/feed.lua` (entries → `panel`, icons → `small`) and `popup.lua` (not loaded; convert its calls anyway so the scan passes).
- **Loot on a theme change:** `OnColorsChanged('theme')` re-applies shown feed entries' quality borders (`feed.lua:254-256`).
- **Chat:** `config.lua`, `options.lua:80` and `chatframe.lua` (→ `panel`).
- **Minimap:** `config.lua:96`, `minimap.lua`, `stats.lua`, `micromenu.lua` and `microbuttons.lua` (the minimap → `panel`, micro menu buttons → `small`).
- **Misc:**
  - `config.lua`;
  - `experience.lua` (bars → `bar`);
  - `tooltip.lua` and `tooltipposition.lua:235` (→ `tooltip`);
  - `totemskin.lua` and `totemtimers.lua` (buttons → `action`, timers → `bar`);
  - `Skinning/skinning.lua:42`, `Blizzard_BuffFrame.lua` (→ `aura`), `Blizzard_SwingTimer.lua` (→ `bar`), `ZoneText.lua`, `hekili.lua`, `weakauras.lua`, `restedxp.lua` (its window → `panel`, its timer bars → `bar`) and `characterframe/gems.lua` (→ `small`).
- **Misc on a theme change:** the buff skin re-applies debuff-type and enchant borders, and the totem skin its element borders.
- **Tests:** update `tests/loot/*`, `tests/chat/*`, `tests/minimap/*` and `tests/misc/*` that read `template` (`tooltip_skin_test.lua` checks `backdrop.template`). Add a defaults-look test per addon, as in Task 4.

**Interfaces:** consumes the option builders (Task 3), `st:RecolorThemed()` (Task 1) and `OnColorsChanged('theme')`.

- [ ] **Step 1: Write the failing tests:**
  - `'<addon> defaults look as they did'`, for loot, chat, minimap and misc.
  - `'shown feed entries keep their quality border through a recolor'`.
  - `'a debuff's type border survives a recolor'`.
  - `'each page offers Theme and Background, not Template'`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `loot, chat, minimap, misc: Theme and Background overrides, drawn with a kind`

### Task 7: Migration on, transition off, the kind scan and docs

**Files:**
- **The migration:** `SaftUI-Core/theme.lua`, `st:MigrateTemplateKeys(tbl)`.
- **Where it runs:** `SaftUI-Core/Config/config.lua` (after the AceDB is made, at the start of `Config:UpdateConfig`, after `Config:Import`) and `SaftUI-Unitframes/config/config.lua` (after a unit frame profile import or copy, if those write outside a Core profile change).
- **Retire the old picker:** remove `generators.template` and `st.Config:GetFrameTemplates` from `widgets.lua`.
- **End the transition mode:** a draw call with no kind and a theme other than `'none'` is an error.
- **The harness:** `tests/lib/harness.lua` gets `read_saftui_source(path)`: the source of a repo-relative path, through the existing `read_source` and the `check_relative_path` rules.
- **Tests:** `tests/core/theme_migration_test.lua` and `tests/core/theme_kinds_test.lua` (both new).
- **Docs:** `.agents/architecture.md` (themes, `OnColorsChanged('theme')`, the migration), `.agents/edit-mode.md` (Global Settings' Theme tab; Theme and Background options), `.agents/testing.md` (the new tests and `read_saftui_source`) and `README.md` (Global Settings → Theme, module overrides). Also `docs/followups.md`: mark the "Core" list's template items done, and mention project 2 (the Blizzard theme) as next.

**Interfaces:** `st:MigrateTemplateKeys(tbl)` walks `tbl` recursively. Every string key matching `^(.*)template$` (`template`, `buttontemplate`; not `templates`) is rewritten through `LEGACY` into `<prefix>theme` and `<prefix>background`, then set to nil. It's idempotent.

- [ ] **Step 1: Write the failing tests:**
  - `'old template keys migrate'`:
    ```lua
    local legacy = {
      bags = { template = 'thin', buttontemplate = 'thicktransparent' },
      chat = { template = 'highlight' },
      unitframes = { profiles = { SaftUI = { player = {
        health = { template = 'thicktransparent' }, portrait = { template = 'none' } } } } },
    }
    st:MigrateTemplateKeys(legacy)
    eq(legacy.bags.theme, 'thin'); eq(legacy.bags.background, 'solid'); eq(legacy.bags.template, nil)
    eq(legacy.bags.buttontheme, 'thick'); eq(legacy.bags.buttonbackground, 'transparent')
    eq(legacy.chat.theme, nil); eq(legacy.chat.background, nil); eq(legacy.chat.template, nil)
    local player = legacy.unitframes.profiles.SaftUI.player
    eq(player.health.theme, 'thick'); eq(player.health.background, 'transparent')
    eq(player.portrait.theme, 'none')
    st:MigrateTemplateKeys(legacy) -- a second run changes nothing
    eq(legacy.bags.background, 'solid')
    ```
  - `'a profile saved by the old version migrates on a profile switch'` (Review Focus 3). In the AceDB world of `tests/core/config_helpers.lua`, write a second profile with `bags.template = 'thin'` into the saved variables, switch to it: `bags.theme == 'thin'` and `bags.background == 'solid'`.
  - `'an imported old profile string migrates'`.
  - `'every draw call passes a kind'`:
    - read every SaftUI Lua file named in each addon's TOCs, and the `load.xml` files they include, through `read_saftui_source`;
    - find each `st:SetTemplate(`, `st:SetBackdrop(` and `st:SetBackdropIn(` call, scanning to the matching parenthesis;
    - require 4, 4 and 5 arguments respectively;
    - exempt function definitions, and calls whose theme argument is the literal `'none'`.

    Core's own calls must use the `st:` form (rewrite `self:SetBackdrop` in Core methods), so the scan finds them.
  - `'no option anywhere offers Template, Highlight or Close Button'`: walk the built `/sui` tree.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.** Write the migration and its hooks, the harness reader, the transition mode's removal and the generator cleanup. Update the docs.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes. Run `agents-doc-parity-check` and `readme-freshness-check`.
- [ ] **Step 5: Commit.** `core: saved template choices migrate to theme and background; every draw call names its kind; docs`
