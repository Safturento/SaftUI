# SaftUI options, project 3b-1: Themes

Date: 2026-11-10. Status: for the user's review, after a builder check. The calls marked "my call" are mine, not the user's.

Project 3 of the options redesign (asked for on 2026-11-09) is Global Settings with editable fonts, colors and templates. Fonts and Colors (3a, `docs/superpowers/specs/2026-11-10-saftui-colors-tab-design.md`) are done. Templates turned into three projects, agreed with the user on 2026-11-10, in this order:

1. **Themes (this spec):** the Theme tab, Thick and Thin as themes, editable theme colors and transparency, every module's template option becoming a Theme override that follows the theme by default, and every frame tagged with its kind so a theme can draw each kind its own way.
2. **The Blizzard theme** (its own spec, after this one): panels in the character frame's metal border with Blizzard's close button, Blizzard's own art on action buttons, bag slots and buffs, and the tooltip border on bars. It builds on this spec's kinds of frames.
3. **Core's leftover settings** (its own small design): font shadow and spacing, the header, button and panel fonts, `misc.icon_trim` and the rest of the followups' "Core" list.

## Intent

The user wants a choice of styles for all of SaftUI: thick borders, thin borders and a Blizzard-art one. Seeing today's template dropdown (Close Button, Highlight, None, Thick, ThickTransparent, Thin, ThinTransparent), they said "the template string we're using right now feels more like an internal implementation than a user facing one. Can we abstract template away in the user facing functionality and replace it with 'Theme' instead? I also feel like '*Transparent' template should be trimmed into a toggle to make the background transparent that works with any of the themes."

On how modules pick: "I think we should have all of those options default to inherit from the base theme and that dropdown becomes an override option only that way they all follow the style by default."

So: one theme for everything, set in Global Settings, that any module can override; transparency as its own switch; and the word "template" gone from what the user sees.

## Today

- **Templates** live in the profile (`st.defaults.templates`, `SaftUI-Core/Config/defaults.lua`):
  - `thick`, `thin`, `thicktransparent` and `thintransparent`: the transparent ones are copies whose background alpha is 0.9.
  - `highlight` and `close`: the header and footer strips, and the close button (`SaftUI-Core/panels.lua`).
  - A template has `bordercolor`, `altbordercolor`, `backdropcolor`, `border` and `thick`.
- **How they're drawn** (`st:SetTemplate`, `st:SetBackdrop`, `SaftUI-Core/panels.lua`; `st:SetBackdropIn`, `SaftUI-Core/api.lua`):
  - Thick draws three 1px lines: dark, border color, dark. Its content sits 2px in.
  - Thin draws one 1px line. Its content sits 1px in.
  - Layouts use that 2px or 1px (`frame.thick`, `st:CalculateSpacing`, and per-module `config.thick and 2 or 1` reads in ActionBars, Minimap, Misc, Loot and Bags).
- **Each module picks a template by name.**
  - The pickers are `generators.template` dropdowns (`SaftUI-Core/Config/widgets.lua`), which list every template plus None.
  - They appear on ActionBars, Bags, Chat, Loot (roll bars, feed), Minimap, Experience, Tooltip, Skinning, and the unit frames: the frame, Health, Power, Additional power, Castbar and its icon, Class power, Auras and Indicators.
  - Bags also has `buttontemplate` for item and currency slots.
  - Core has `buttons.template` and `panels.template` with no option.
  - The `/sui` window and its dialog are always `'thick'` (`SaftUI-Core/Config/optionswindow.lua`).
  - About 50 call sites draw a template.
- **Redrawing is broken.** `st:SetTemplate` records each frame's template in `st.template_cache`. `st.Config:UpdateTemplateConfig` (`SaftUI-Core/Config/widgets.lua`) means to redraw from it. But it iterates the table without `pairs`, and reads `st.Config.template_cache`, which isn't where the cache is. Nothing calls it.

## Goals

### The Theme tab

- **Global Settings' tabs become Fonts | Colors | Theme | Edit mode.**
- **What the tab holds:**
  - **Theme:** Thick or Thin. Blizzard joins in project 2; until then it isn't offered.
  - **The chosen theme's colors:** Border, Outer border (the dark lines; Thick only) and Background.
  - **Transparent background:** a toggle.
  - **Opacity:** a slider for how see-through the background is while Transparent background is on. It's disabled while the toggle is off.
  - **A Reset button** that puts the chosen theme's colors and the transparency settings back to SaftUI's defaults. It asks first, like the Colors sections' Reset.
- **Each theme keeps its own colors.** Switching Thick, then Thin, then back to Thick brings your Thick colors back.
- **The defaults are today's look:** Thick, Transparent background on, opacity 90%. That's today's `thicktransparent`.

### Each module's override

- **Every template dropdown becomes two options:**
  - **Theme:** Use SaftUI's theme, Thick, Thin or None. None means no border and no background.
  - **Background:** Use SaftUI's theme, Solid or Transparent.
- **The word "Template" leaves the options.** Close Button and Highlight are never offered.
- **None stays a choice everywhere.** The user, on keeping it: "that gives a lot of extra unitframe customization."
- **Bags' slot template** (`buttontemplate`) gets the same pair, for item and currency slots.

### SaftUI looks exactly as it does today until the user changes something

- **A default of `thicktransparent`** becomes Use SaftUI's theme for both Theme and Background.
- **Other defaults are kept as explicit choices**, so the look doesn't change:
  - `thick` → Use SaftUI's theme + Solid;
  - `thin` → Thin + Solid;
  - `thintransparent` → Thin + Use SaftUI's theme;
  - `none` → None.
- **A saved choice keeps its exact look.** A profile that saved a template name reads as follows:
  - `thicktransparent` → Thick + Transparent;
  - `thintransparent` → Thin + Transparent;
  - `thick` → Thick + Solid;
  - `thin` → Thin + Solid;
  - `none` → None.
  - `highlight` or `close`, saved on a module: Use SaftUI's theme for both. The old dropdown offered them, but the user never meant them as choices ("out of all of these options the only ones that make sense are the last four"). My call.

  A saved Background choice wins over the one a saved name implies.

### Theme parts the user never picks

- **The header and footer strips** (today `highlight`) take the theme's border color at 40% opacity as their fill. Under the default Thick that's exactly today's `highlight`. They follow SaftUI's theme, not their window's override, so a bag window saved as Thin or None keeps today's strips. My call.
- **The close button** (today `close`) keeps its red tint.
- **Both take the theme's border thickness.**
- **The `/sui` window and its dialog follow SaftUI's theme's border**, instead of always drawing Thick, and keep a Solid background, so they don't turn see-through by default. They're SaftUI panels. My call.
- **Hard-coded template names** at call sites with no option resolve the way defaults do (above): `'thick'` → Use SaftUI's theme + Solid, `'thin'` → Thin + Solid. These are edit mode's movers and picker, scroll bar thumbs, bag slot bars, the character frame gems, zone text and the like. My call.
- **A module overridden to Transparent while the Transparent background toggle is off** uses the Opacity slider's stored value. My call.
- **Borders a module colors itself** stay colored after a theme recolor: they're applied again after it. These are an item's quality, a debuff's type and an equipped item's border; `docs/followups.md` already notes that a recolor would wipe them. My call.

### Every frame gets a kind

Each draw call says what kind of frame it's drawing:
- panel: a window, such as bags, bank, chat, the options window or the loot feed;
- bar: a unit frame or one of its bars, a cast bar, experience and reputation bars, roll bars, swing timers;
- action button;
- item slot: bag, bank and currency slots;
- aura: buffs and debuffs, the unit frame auras;
- tooltip;
- header, footer and close button;
- small: everything else, such as indicators, class power points and micro menu buttons.

Under Thick and Thin the kind changes nothing. It's there for project 2. A module's override applies to every frame that option governs, and each frame keeps its own kind.

### When a change shows

- **A color or opacity change only recolors.** A drag of the color picker sets a color on every cursor move. Every frame drawn with that theme is recolored, and nothing is re-laid-out.
- **A switch of theme or of the transparency toggle re-applies every module's config**, like a profile switch (`st.Config:UpdateConfig`), because Thick and Thin set content 2px or 1px in and layouts use it. So does a module's own Theme or Background override (its module's `UpdateConfig`). `/sui` closes in combat, so none of this runs in combat from the window.
- **Anything that still needs a reload says so** in the tab's note, as Text and Buttons do on Colors. The builder should aim for none.
- **The broken redraw is replaced.** `st.Config:UpdateTemplateConfig` is fixed or removed in favour of whatever the builder uses.

## Constraints

- **Saved profiles keep working, with no step the user has to take.** Code and saved variables may keep the word "template" inside. Only what the user sees changes.
- **`.agents/taint.md`.** Drawing onto frames that aren't SaftUI's goes through `st:SetBackdropIn` and the caller's own tables, never fields on Blizzard frames. A kind is passed in the call, not stored on someone else's frame.
- **The finished-page rules from project 2:** every option has a desc and SaftUI's `size`, and no Ace `width`. `tests/core/options_desc_test.lua` and the per-module page tests check this.
- **Both clients.** Forever (16001) and retail (120000).

## Non-goals

- The Blizzard theme and any art (project 2).
- Core's leftover settings, including options for `buttons.*` and `panels.*` fonts (project 3). Their template keys still change: `buttons.template` and `panels.template` default to following the theme like every other `thicktransparent` default.
- New themes beyond Thick and Thin.
- Colors on the Colors tab (3a). Theme colors are the Theme tab's own.

## Anti-goals

- SaftUI looking any different after the update, for a profile the user never touched or one with saved template choices.
- Any frame left in the old look after a theme change, until a reload.
- "Template", "Highlight" or "Close Button" in front of the user.

## Tests

- **The tab:**
  - It sits between Colors and Edit mode, with the theme, its colors, the toggle, the opacity and Reset.
  - Opacity is disabled while Transparent background is off.
  - Each theme's colors are kept apart.
  - Reset restores the chosen theme's colors and the transparency settings.
- **Resolution:**
  - For each override combination (Theme × Background, against each theme and toggle), the frame is drawn with the right lines, colors and alpha.
  - None draws nothing.
- **Defaults and migration:**
  - Every module's default resolves to exactly today's look: the lines, colors and alpha of today's default template name.
  - Each saved legacy name reads as above.
  - A saved Background beats the implied one.
- **Live:**
  - A theme or toggle switch redraws every frame and re-applies module configs, with the insets right.
  - A color change recolors without a re-layout.
  - No frame keeps the old look.
- **Options:** no template name, Highlight or Close Button is offered anywhere. Every Theme and Background option has a desc and a size.
- **Kinds:** every draw call passes a kind. A test fails if a call site passes none. The test harness has no `io`, so this test needs a way to read the source files; the builder adds one to the harness.

## Left to the builder

- **Storage shape:** where the theme, its per-theme colors and the transparency live in the profile, and the new per-module Background key's name, within the constraints above.
- **How the kind is passed:** an argument, or a variant of the draw functions.
- **The kind of each call site,** from what the frame is.
- **How live re-application is wired,** and which modules' layouts actually depend on the inset.
- **The Theme tab's descs, and the Theme and Background descs on each module.**
