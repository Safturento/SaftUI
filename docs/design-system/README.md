SaftUI replaces World of Warcraft's interface with flat, dark frames that sit quietly over the game world: 1px lines, square corners, one blue accent, and every edge on a whole pixel. It is a set of Lua addons (unit frames, action bars, bags, chat, minimap, loot, skins) sharing one core, with its own options window (`/sui`) and its own edit mode. Use this system when you build any frame, control or option page for it.

**Why it looks this way.** The game world behind the UI is busy and colourful, so SaftUI's frames recede: near-black fills, grey lines, no gradients, shadows or rounded corners. Colour is spent on information (class, quality, power, threat) and on one accent that means "this is the active thing". SaftUI sets the UI scale so one unit is one physical pixel; a 1px line is only crisp on a whole pixel, so every size and offset is whole.

## Reading this system

- Colour tokens have two themes, **Thick** (the default, first) and **Thin**. Only the theme's own colours change between them: `backdrop`, `border`, `border-alt`, `header-strip`. The options kit's colours (`kit-field`, `kit-edge`, `kit-alt`, `kit-bg`, `sidebar`, `line`) hold one value in both, because the code fixes them today (see Discrepancies). The **Blizzard** theme is not a colour theme: it draws Blizzard's own art, and each component's guidelines say what it keeps.
- Type styles are classes (`.label`, `.field`, `.section-title`, `.pixel`); families are `--font-colus`, `--font-agency`, `--font-pixel`.
- `size`, `spacing`, `opacity`, `strata` and `frameLevel` hold the code's exact numbers; each usage note names the constant or the file.
- In the addon a colour is an RGB triple from the profile (`st.config.profile.colors.text.grey`) or a constant (`st.BOX_COLORS.field`). Read the profile's colours at call time, never cache them, so a Colors tab change reaches your frame.

## Content

**Casing.** Option names, labels, descs and notes are sentence case: "Buttons per row", "Faded until moused over", "Custom color". Write section titles in their real case too ("Bar background", "Text position"); Colus sets lowercase as small capitals, so they read as capitals on screen. Sidebar page names are mixed today ("Action Bars", "Micro Menu" against "Unitframes"); that is an open question for the owner, not a pattern to copy.

**Spelling.** Every string a player reads says "color" ("Colors", "Custom color", "Text color"); one desc says "colour" (`SaftUI-Misc/totemoptions.lua:21`), a slip. Write "color" in the UI. The docs mix both; this system's prose says "colour", the owner's spelling, and quotes the UI as it is.

**Naming.** A label names the setting, not the action: "First button", not "Set growth direction". A picker's label says what it picks: "Unit", "Bar". A part's Position names itself: "Count position". Never show an internal key ("grouproleindicator") or Ace's internal words ("Template", "Highlight", "Close Button").

**Tooltips.** Every option on a finished page has a desc, and the desc is its label's tooltip: the name in `white`, the desc under it, and, while the option is disabled, why, in `text-red`. An icon that stands in for a word always has a tooltip saying what it does ("Reset: Buttons per row follows All bars again. Bar 3's own value is dropped."). Name a path with a plain greater-than sign, "Global settings > Theme", never an arrow glyph: SaftUI's fonts may not have one. Say "reload to apply" in a desc when a setting can't apply live, and let a section note say what waits for a reload: "Most of SaftUI reads these when it builds its frames: reload (Reload UI, bottom right) to see a change everywhere."

**Numbers.** Colours read as `#RRGGBB`, and `#RRGGBB · 60%` with opacity under 100%. Offsets and sizes are whole numbers. No emoji, no exclamation marks; short, plain sentences.

## Visual foundations

### Colour

- **Surfaces.** In-world frames take `backdrop` at `alpha-theme` (0.9) with a `border` line; Thick adds `border-alt` lines outside and inside it. The options window draws `backdrop` solid, its sidebar `sidebar`, and each section's rows sit on `panel-fill` with `hairline` lines between them. Controls are Boxes: `kit-field` inside a `kit-edge` line with a `kit-alt` line outside; buttons and open lists fill with `kit-bg`.
- **Text.** `text` for labels, values, titles and the tab you are on; `text-grey` for section titles, notes, captions, other tabs, carets and anything dimmed; `white` for a tooltip's title and the colour bar's hex code; `text-red` for errors and why something is disabled. Under Thin, `text-grey` and `text-red` miss 4.5:1 on `backdrop` (4.3:1 and 3.6:1); on `panel-fill` grey passes (5.2:1) and red is still short (4.4:1).
- **Accent.** `accent` is the only accent: the check mark, slider fill, picked dot, the selected sidebar entry's bar and the tab underline, a hovered or focused control's edge, links, the own mark, a selected mover. `accent-fill` (25%) sits behind a selected or hovered row. Never use a second blue for these.
- **Shared settings.** `own` (light blue) marks a member's own value; `diff` (orange) marks a setting some member changed. They differ from each other in lightness as well as hue. Use them for nothing else.
- **Data colours.** `class-*`, `reaction-*`, `power-*`, `quality-*` (through `st:QualityColor`), `threat-*` and `status-offline` colour bars, names and borders by what they show. They are profile settings: never hard-code them, never use them as decoration.
- **Profile Buttons colours.** `button-normal` is a Core button's highlight and `button-hover` a checked Core check box, despite their names. New work uses the kit's states below instead.

### Type

| Role | Style | Face | Where |
| --- | --- | --- | --- |
| Page title | `page-title` 34 | Colus | the `/sui` page's name |
| Brand, dialog title | `brand` 26 | Colus | sidebar brand, small dialog |
| Bar brand | `brand-mini` 18 | Colus | the mini bar's name: Saft in the text colour, UI in the accent |
| Section title | `section-title` 15 | Colus | over each panel, in `text-grey` |
| Group title | `group-title` 13 | Colus | sidebar groups, a menu's title |
| Caption | `caption` 11 | Colus | position block parts |
| Tab | `tab` 17 | AgencyFB Bold | tabs |
| Label | `label` 16 | AgencyFB Bold | row labels, sidebar entries |
| Field | `field` 15 | AgencyFB Bold | values, list rows, buttons, page description |
| Small | `small` 13 | AgencyFB Bold | hover line, section notes |
| In-world text | `normal` 16 | AgencyFB Bold | window titles, unit frame names and values, tooltip lines |
| Pixel text | `pixel` 10, `pixel-med` 18 | Homespun | hotkeys, counts, mover labels, cooldown numbers (`pixel-med` on buttons of `countdown-large` and up) |

Every text in SaftUI's font objects carries a 1px black outline (`text-outline`; Homespun's is MONOCHROMEOUTLINE). On SaftUI's dark grounds the outline only shows where text crosses colour: the colour bar's hex, texts on icons and bars. The faces come from the profile's font objects (Huge title, Text, Small text); the kit uses the Heading and Text faces at its own fixed sizes. Use a role, not a face: today that means passing the right font object key, and the font roles change (Code changes) will make it a role name.

### Spacing and layout

- **Whole pixels.** Round every size and offset (`st:RoundToPixel`). A frame centred on an axis gets an even length on that axis. Icons are even sizes on whole centres. The kit rounds halves and quarters down.
- **The options page.** `window-pad` (28) from the sidebar; rows `row-height` (38) on panels padded `panel-pad` (14); sections `section-margin` (14) apart, a title `title-gap` (6) over its panel. Cells are a quarter, a half or a whole line of `content-width` (774). Labels sit left, controls right-aligned in their cell, check boxes and colour bars too.
- **In the world.** Buttons and slots `button-spacing` (3) apart; auras and roll bars `aura-spacing` (7); windows padded `frame-padding` (10); frames kept `screen-margin` (20) in from the screen's edge.

### Lines, corners, depth

All lines are `line-width` (1px); marks and underlines are `mark-width` (2px). A Thick frame is three lines (`thick-width`); a Thin frame is one. Corners are `radius` (0) everywhere. There are no shadows, glows or gradients in SaftUI's own drawing; bars fill flat (`SaftUI Flat`). Depth comes from the panel's darker fill and from strata.

### States

| State | Standard (the kit's) | Tokens |
| --- | --- | --- |
| Hover | a control's edge turns accent; a row fills | `kit-edge` to `accent`; `accent-fill` |
| Pressed | the text or icon moves down 1px | `line-width` |
| Focus | the box's edge stays accent | `accent` |
| On | an accent square inside the check box | `accent`, `check-inset` |
| Selected | accent fill with an accent bar (sidebar), accent underline (tab) | `accent-fill`, `mark-width` |
| Disabled | the control at 40%, its label grey; the tooltip says why | `alpha-disabled`, `text-grey`, `text-red` |
| Own | 2px accent bar, label light blue | `accent`, `own` |
| Differs | orange diff icon after the label | `diff` |
| Error | the status line or tooltip line in red | `text-red` |

State is always visible; hover only offers actions. In-world icon buttons keep their own set: hover `accent` added, pressed `pressed-fill`, checked `checked-fill`, flash `flash-fill`, equipped `button-green` border.

### Layering

Frames stack by strata, lowest first: `strata-grid`, `strata-skins`, `strata-frames`, `strata-windows`, `strata-rolls`, `strata-options`, `strata-popups`. The `/sui` window sits at `level-options` (100), its small dialog at `level-small-dialog` (300); dropdown lists and the confirm draw in `strata-popups` so nothing cuts them off.

## Iconography

- Lucide (lucide.dev, ISC) wherever an icon fits. In the addon each is a 32x32 white TGA (`st.icons`, made by `tools/lucide-to-tga.cjs`), Lucide's 24 grid with the glyph in its middle half, so draw it at twice the glyph: `icon-close` 20 for a 10px cross, `icon-chevron` 16 for an 8px caret, `icon-diff` 16, `icon-reset` 14. In HTML, inline the SVG on a 24 viewBox, stroke 2, round caps and joins, no fill.
- Tint an icon with a colour token (`SetVertexColor`), never bake colour into the file: carets and the close X rest in `text-grey`, reset is `accent` and white under the mouse, diff is `diff`, the close X turns `text-red` under the mouse.
- In use: `x`, `chevron-down`, `rotate-ccw`, `diff`; registered for the menus and nudges: `ellipsis-vertical`, `ellipsis`, `chevron-up`, `settings`. Still hand-made, to be replaced by Lucide: the loot feed's "F" and "V" letters, the bag view glyphs, the drag handle's dots, the resize corner, and the funnel, eye and mail TGAs.
- No emoji, ever.

## Themes

- **Thick** (default): `backdrop` #1f1f1f, `border` #4d4d4d between two `border-alt` #1a1a1a lines; content insets 2.
- **Thin**: `backdrop` #1f1f1f inside a black `border`; content insets 1.
- **Blizzard**: Blizzard's own art on SaftUI's frames, per kind (the character frame's metal for windows, the tooltip border, the action ring, the bronze unit frame box). The options window keeps Blizzard's flat layout (rows `row-height-flat` 34, columns 40 apart, no panels), and every control with a Settings equivalent takes that art. SaftUI's own marks keep their colours (`own`, `diff`, `accent`).

Every page whose frames SaftUI draws offers Theme and Background, with "Use SaftUI's theme" as the follow choice. Every draw call names its kind (`panel`, `window`, `bar`, `action`, `slot`, `aura`, `tooltip`, `header`, `close`, `control`, `unitframe`, `member`, `small`).

## Rules

1. **Lucide icons** wherever an icon fits (see `Icons`). An icon that replaces a word has a tooltip saying what it does.
2. **Reset per setting.** A `ResetIcon` (rotate-ccw, `icon-reset`, `accent`) sits beside a control, shown only while its value differs from its default, or from the shared value on a member page. No section or page Reset buttons.
3. **Menus for parts.** A part with three or more settings, or settings that only apply sometimes, is a one-line `MenuItem` (Show box, name, `ellipsis-vertical`) with its settings in a menu titled with the part's name, `menu-width` (400) wide. Play it by ear where a page feels crowded.
4. **Shared settings.** An "All" entry first in the picker, which every member follows. A member's own setting is marked with `OwnMark` (`accent` bar, `own` label) and a hover line: Own, the reset icon, Apply to: All | Multiple (`ApplyList`). The All page shows an orange `DiffIcon` whose tooltip lists who differs and with what. State is always visible; hover only offers actions.
5. **Sections on panels.** Under Thick and Thin a `Section`'s rows sit on `panel-fill` with a `hairline` column divider and hairlines between lines. The Blizzard theme keeps Blizzard's art and flat layout.
6. **Buttons float.** A line that holds only buttons has no panel behind it. A section's or dialog's closing buttons float under the panel with `float-gap` (24) above and below.
7. **The color field** (`ColorBar`) is as wide as a dropdown (`control-width`): a swatch at its left (a see-through color over a checker), its hex code beside it in `text`, with `· NN%` when its opacity is under 100%.
8. **Carets and close.** The dropdown arrow is `chevron-down`; the close button is `x` (`CloseButton`).
9. **Position goes last** on a page (`PositionBlock`), in a section of its own.
10. **Whole pixels** everywhere. **Corners are square** (`radius` 0).
11. **Three themes**: Thick, Thin, Blizzard. Build for Thick and Thin with tokens, and say what keeps Blizzard's art.
