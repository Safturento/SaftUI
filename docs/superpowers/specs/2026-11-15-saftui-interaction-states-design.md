# One accent, every state

Design, 2026-11-15. A draft for the owner to approve. Every decision he didn't make is marked **call** and
listed again at the end, under "Calls made while writing this". Checked against SaftUI's code on `modular`
at `e592f835`; the audit it builds on (`scratchpad/feedback/states-audit.md`, read-only, 79 Accent reader
sites in 41 files) was taken at `ebfaf766`, and nothing it cites changed between the two. The mockups are
`.superpowers/brainstorm/states-v2.html` (the one he approved) and `states-v1.html`. Nothing here has been
checked in game; the checks it needs are G1 to G16 under "In-game checks".

Words used below:

- **State**: rest, hover (under the mouse), pushed (held down), selected (also checked, on, current, picked:
  one state), selected + hover, focus (the keyboard is in it), disabled.
- **Shape**: the form a widget takes, which decides how a state is drawn on it: a boxed control, a row, a
  tab, a check box, a thumb or knob, an in-world icon button, a mover, a bare glyph (section 1).
- **Body**: the widget's own fill at rest, under everything a state adds.
- **A**: the Accent (Global settings > Theme > Accent, `st:Color('accent')`). **T+** and **T-**: its lighter
  and darker tone (section 2); under Layers both are A.
- **h, p, s, f, d**: the Hover strength, Pushed strength, Selected fill, Selected fade and Disabled opacity
  settings (section 2), 16%, 32%, 24%, 70% and 40% by default.
- **Line**: one line of the frame, `st:GetLineSize(frame)` (whole pixels of that frame at any UI scale).
  **Two lines** is the design system's `mark-width`.

## Why

After the color picker's preview shipped, the owner saw that interaction states are drawn differently
across the UI: "as far as hovers are concerned I feel like there's still inconsistencies in the color - for
example: /sui buttons (close/reloadui/color swatch) have borders colored by the accent color, action bars
are highlighted by what seems like a soft white hover, and bag items are highlighted by the accent color".
Then: "I think this accent vs button state things goes even deeper than hover ... we have the /sui button
hover as accent but the bag view buttons on the bag header as the hover texture (not border color) set to
the hover color but checked as the accent. if we just find conformity everywhere I think it will be
better. I also think we need conformity in hover meaning the body changes, selected buttons maybe we can
explore doing the border plus the background with a slight fade on the background like what we have here"
(the options sidebar's selected row: a left bar and a fill).

The audit confirms it and finds more: hover takes five unrelated forms and seven strengths, selected takes a
dozen forms, focus is accent in the kit and white in Core's edit box, disabled is a frame alpha in one place
and a black overlay in another (audit C, items 1 to 16).

His model: "What if we were to ONLY have an Accent color, and we interally generated Hover/Pushed/Checked as
three variants of that color?"

## What the owner decided

1. **One color setting, the Accent.** Every interaction state of every interactive widget in every addon is
   derived from it by rule. Buttons > Normal, Hover, Pushed and Checked go. Buttons > Danger stays: it is a
   meaning, not a state. The Accent's uses that are not a state (links, the chat prefix, progress fills,
   markers) keep the Accent itself.
2. **The rules** (agreed on the mockup): hover changes the body, never only the border; pushed is the same,
   stronger; selected, checked or current is a full-strength accent border (a left bar on a row, an
   underline on a tab) and a fill that fades out across the widget; selected + hover composes; keyboard focus
   is an accent border; disabled dims the whole widget; text on a derived fill is light or dark by contrast.
3. **Three derivations, all built and selectable**: Layers (the Accent at an opacity over the body), Tones
   (the Accent made lighter or darker in OKLCH), Hue-shifted tones (lighter tones turn warm, darker cool, or
   the reverse). "this looks great, I like the way the Tones look".
4. **The defaults: Tones**, with the mockup's numbers: Hover 16%, Pushed 32%, Selected fill 24%, Selected fade
   70%, Disabled 40%, Lightness step 0.08; for the hue-shifted mode Hue shift 20 degrees, Chroma change 10%,
   warm light and cool shadow. Confirmed 2026-11-15: "yeah that default is good, if I want to change it once
   it's in game I'll let you know". He may retune them in game; nothing here waits on it.
5. **The controls live in the Accent row's dots menu**: "can we set this config menu you have in the mockup
   up in the 3-dot menu of the accent color? that way if someone just wants to change the accent color they
   get the defaults for free, but if they want to get fancy they can". The row keeps its swatch and reset.

## Goals

- Every interaction state of every SaftUI widget, in every addon, is drawn by the rules of section 1 from
  colors derived from the Accent by section 2, through one cache and one set of drawing helpers (section 3).
- The same state looks the same on every widget of a shape, and the same idea (under the mouse, chosen)
  takes the same form across shapes.
- A change of the Accent or of a derivation setting reaches every state on screen as it is dragged, within
  the live colors budget (section 6).
- The Colors page keeps only colors that mean something: Buttons > Danger stays, the four state colors go,
  and a profile that had changed them loses those changes once, by a migration step.
- The docs, the design system and its published artifact say the one rule.

## Non-goals

- **Markers and data colors.** The equipped item's border, the tracker's focus bar, the grid's centre lines,
  the own mark, a nameplate's target border, class, quality and power colors: not states (section 4 lists
  them). They keep their colors.
- **Blizzard's own art.** Where SaftUI wears Blizzard's art (the Blizzard theme, Blizzard's roll buttons,
  chat tabs), Blizzard draws the states (section 1, "Under the Blizzard theme").
- **LibActionButton's unusable look** and SaftUI's range coloring: game state, not a widget's disabled.
- **The Theme tab's other colors**, the close button's Danger hover, Buttons > Danger's value.
- **Retuning the defaults.** Decided; the owner says if he wants them changed.

## Anti-goals

What would make this a failure even if it works:

- **A state drawn by hand.** A widget that reads the Accent at a strength, or a Buttons key, or a constant
  tint (white 15%, black 10%) for a state, instead of the helpers.
- **A visible change the design doesn't name.** Every change is in "Visible changes by area"; a widget at
  rest looks exactly as it does today.
- **Taint.** A new field on a Blizzard frame, a new call on a secure button beyond a texture's color, alpha
  or texture coordinates, or a pre-hook.
- **A slower drag.** A pass that makes a frame, a texture or a table, lays out, or goes over the budget.
- **Unreadable text.** Text that loses contrast on a fill because the fill is drawn over it.

## 1. The state model

### The states, and which wins

| State | Means | Comes from |
| --- | --- | --- |
| Rest | none of the others | |
| Hover | the mouse is over the widget | the widget's `OnEnter`/`OnLeave`, or the game's highlight (icon buttons) |
| Pushed | the mouse button is held on it | `OnMouseDown`/`OnMouseUp`, or the game's pushed state (icon buttons) |
| Selected | checked, on, current, picked: the widget stands for what is chosen now | the widget's code (`st:SetState`), or the game's checked state (icon buttons) |
| Selected + hover | both | composes |
| Focus | the keyboard is in it (an edit box) | `OnEditFocusGained`/`Lost` |
| Disabled | it does nothing now | the widget's code |

Several can hold at once. They compose by these rules, in this order (**call**: the mockup draws each; the
order is how its CSS composes them):

1. **Disabled** dims the whole widget to the Disabled opacity and clears hover and pushed (the widget keeps
   the mouse where it does today, so its tooltip still says why). Selected and focus still draw, dimmed.
2. **The layer** (the body's tint) is pushed's while pushed, else hover's while hovered, else none. Pushed
   wins over hover: while held, the mouse is over it too.
3. **The selected fill and edge** draw while selected, in the hover tone while hovered and not pushed
   (selected + hover), else in the Accent.
4. **Focus** draws the edge in the Accent while not selected (the same color: no conflict).
5. **Text** on the widget takes the light or dark text color by contrast over what is under it (below).

### The pieces

Every state is drawn with these pieces and nothing else. Each is a texture of SaftUI's (on a frame of
SaftUI's, or made on the button where taint rule 1's recipe already makes state textures), colored only by
the helpers of section 3.

| Piece | What it is | Drawn with |
| --- | --- | --- |
| **Layer** | the body's tint for hover or pushed | one texture `st.BLANK_TEX`, blend mode `BLEND`, inside the widget's edge (inset by the edge as drawn: `st:DrawnInset(frame)` for a frame the theme engine drew, the kit Box's own edge for the kit), draw layer `ARTWORK` sublevel -8, so under the widget's text and icons. Vertex color `st:StateColor('hover')` (T+ at h) or `('pushed')` (T- at p). On an icon button it is the button's own highlight or pushed texture instead (below). |
| **Fill** | the selected body | one texture `st.textures.stateFade` (new: white, alpha falling evenly from 1 at its left to 0 at its right, made by `tools/fade-to-tga.cjs`), set with wrap mode `CLAMP` both ways, blend `BLEND`, the same inset as the layer, `ARTWORK` sublevel -7 (over the layer, as the mockup composes), texture coordinates `(0, 1 / f, 0, 1)`: the fade ends f of the way across and the rest is clear. Vertex color `st:StateColor('fill')` (A at s) or `('fillHover')` (T+ at s). A horizontal fade, left to right, on every shape (the mockup's). |
| **Edge** | the widget's own border line | the kit Box's `SetBackdropBorderColor`, or `st:SetBorderColor` on a frame the theme engine drew (under Thick the middle of its three lines). `st:StateColor('edge')` (A) or `('edgeHover')` (T+), at full. At rest the widget's own edge color, as today. |
| **Bar** | a row's left bar, a tab's underline | one texture `st.BLANK_TEX`, `ARTWORK` sublevel 1, two lines (`2 * st:GetLineSize(frame)`) wide at the row's left edge over its full height, or two lines tall along the tab's bottom, where today's underline sits (1 below the tab). `edge` or `edgeHover`. |
| **Mark** | a check box's square | the kit's: a square `floor(size / 6)` units in from each side of the box (3 on the kit's 18, 2 on Core's 12, 1 on the bags' 8: **call**), `OVERLAY`, `edge` or `edgeHover`. |
| **Solid** | a thumb's or knob's own fill | its existing fill (a thumb's backdrop color, the knob's texture) in `st:StateSolid('hover' or 'pushed', restR, restG, restB)` |
| **Glyph** | a bare icon's or a link's own color | its vertex or text color |
| **Alpha** | disabled | `frame:SetAlpha(st:StateAlpha())`, the Disabled opacity |

### The table: shape by state

| Shape | Rest | Hover | Pushed | Selected | Selected + hover | Focus | Disabled |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Boxed control**: a button, icon button, select face, color field, input, keybinding button, `st:SkinButton`'s and `st:CreateButton`'s buttons, a bag view button, a radio button | its body and its edge, as today | Layer `hover` (T+ at h); edge unchanged | Layer `pushed` (T- at p); the kit's label or icon still moves down one line | Edge `edge` (A); Fill `fill` (A at s, fading over f) | Layer `hover` + Fill `fillHover` (T+ at s) + Edge `edgeHover` (T+) | Edge `edge` (A); body unchanged; a hover Layer composes | Alpha d |
| **Row**: a sidebar page, a dropdown or check list row, a search result, a category, a History step, a tracker quest row, a popup row | no fill | Layer `hover` over the whole row (the tracker's 2 past it, as today) | Layer `pushed` | Bar `edge` (A) at its left + Fill `fill` | Layer `hover` + Bar `edgeHover` + Fill `fillHover` | none (no row takes the keyboard) | Alpha d |
| **Tab**: the page tabs | text Muted, no fill | Layer `hover` over the tab's rect as laid out today; text Normal | Layer `pushed`; text Normal | Bar `edge` (the underline) + Fill `fill`; text Normal | Layer `hover` + Bar `edgeHover` + Fill `fillHover` | none | Alpha d |
| **Check box**: the kit's toggle, the multiselect and check list boxes, the rule editor's, `st:SkinCheckButton`'s (its default style) | its box: body and edge | Layer `hover` inside the box (a check list row's box takes its row's hover) | Layer `pushed` | Edge `edge` + Mark `edge` + Fill `fill` inside the box | Layer `hover` + Edge, Mark `edgeHover` + Fill `fillHover` | none | Alpha d on the box and its label |
| **Thumb or knob**: a scroll bar thumb, a slider's knob | thumb: `kit-edge` #4d4d4d (**call**, the mockup's; today Buttons > Normal #1a1a1a); knob: Text > Normal, as decision 26 keeps it | Solid `hover` | Solid `pushed` (dragging) | n/a | n/a | none | the slider's Alpha d, as today |
| **In-world icon button**: action buttons (bars 1 to 8, pet, stance, the extra and zone buttons, leave vehicle), totem buttons, bag, bank, bank tab and bag bar slots, SaftUI's tracker's quest item buttons, Blizzard's tracker's quest item (skinned), the loot window's slot | as today | the button's highlight texture (the game shows it under the mouse, in `HIGHLIGHT`, so over the icon and its texts: an icon button's body is its icon), inside the icon's rect, `BLEND`, `hover` | its pushed texture (shown by the game while held), `BLEND`, `pushed`; slots gain it | its checked texture (shown by the game while checked) as the Fill (`fill`, fading), plus Edge `edge` on its backdrop, set from a post-hook on the button's `SetChecked` (action, pet and stance buttons; not totem buttons, below) | the highlight composes over the checked fill; the edge and fill keep A (**call**: no `OnEnter` hook on secure buttons) | n/a | the game's: an unusable action's tint, the disabled texture `st:SkinActionButton` makes (black 40%, kept: **call**) |
| **Mover**: edit mode's overlays | 1 line white edge, black 30% body, as today | Layer `hover` (new: today nothing on the box) | as hover (a drag is a move, not a press: **call**) | Edge `edge` + Fill `fill` (today a flat accent 15%) | Layer `hover` + Edge, Fill in `edgeHover`, `fillHover` | n/a | the overlap picker's other movers keep their 40% (they aren't disabled: **call**) |
| **Bare glyph**: an icon with no box (icon links, the reset icon, item dots and the font row's link, the title's page arrow, nudge arrows, the position block's dots, the tracker's chevrons, the resize grip and corners) and a text link | its own: Text > Muted (the dots grey, the corners white); a link the Accent | the glyph in `edgeHover` (T+; the Accent under Layers); a link Text > Strong, as today | as hover | its own selected look where it has one: a picked dot 8 square in A, an icon in A while its button is on | `edgeHover` | n/a | Alpha d |

**Text on a fill.** A label or a row's text that sits on a Layer or a Fill takes Text > Normal or the dark
text color `#111111` (`ST.DARK_TEXT`), whichever has the higher WCAG contrast (formula in section 2) over
the composite under its start: the body, then the Layer, then the Fill at its strongest (its left end). At
rest it is the widget's own color, as today (a tab's Muted, a disabled label's Muted). At the defaults every
composite is dark and the text stays light (the table of worked values); the dark text appears only at
strong settings (Hover 60%, Pushed 80%) with a pale Accent. Icons are not text: an icon button's glyph keeps
its rules (Muted, A while on; a `hoverIcon` button's A under the mouse). In-world icon buttons' texts
(hotkeys, counts) keep theirs.

**Meanings that keep their own colors.** These are not states and the rules leave them as they are: the close
button under the mouse (its border and cross in Text > Danger, its body the close template's fill: the body
changes, in red, because it closes), a remove (x) icon's Text > Danger, an action or totem button's flash
(Buttons > Danger at 0.4), an unbought bank slot's tint (Danger at 0.3), the micro buttons' alert pulse
(Text > Caution), the rule editor's Caught now tint (Text > Warning at 25%: its own constant now), a search's
non-match fading slots to 10% (a filter's answer, not disabled), the tracker's quest items dimmed to 40% in
combat when their row moved (a hold, not disabled: **call**), the totem flyout arrow's thick arrow under the
mouse (a shape, not a color: **call**).

### Under the Blizzard theme

Where a widget wears Blizzard's art, Blizzard's art draws its states and SaftUI draws none of its own: the
helpers hold their pieces at alpha 0 (as `st:SkinButton`'s flat textures are today) and leave the edge to the
art. Where nothing of Blizzard's stands in, SaftUI draws the derived states in every theme.

| Widget | Under Blizzard | Why |
| --- | --- | --- |
| The kit's controls (buttons, fields, selects, color, keybinding, toggles, the range), list rows, sidebar rows, tabs | Blizzard's Settings art and its highlight; the item dots and font link turn white under the mouse; the sidebar's hover turns the name white | they wear Settings art there (`optionslook.lua`), whose own states are the theme |
| `st:SkinButton`'s buttons, `st:SkinCheckButton`'s boxes, the bag view buttons (current: the pressed panel button), a radio group (Blizzard's top tabs) | Blizzard's | panel button and tab art |
| Scroll thumbs | MinimalScrollBar's | its art |
| Action, pet, stance, totem, slot buttons, the bag bar's slots | Blizzard's state art (`ThemeArt.StyleState`), untinted | the action ring's art |
| Movers | Blizzard's Edit Mode selection kit | its art |
| Micro buttons, the minimap's buttons | Blizzard's highlight and pushed art | their art |
| SaftUI's tracker's rows, the loot window's cards, the History list rows (dropdown art), the Categories list (Settings list art) | rows on art: Blizzard's; the tracker's rows (no art): SaftUI's derived states | the tracker draws its own rows in every theme today |
| Edge focus on a kit input, Core's edit box | the input's own art, no SaftUI edge | `st:SetBorderColor` leaves a control's border under Blizzard alone |
| Loot roll buttons, chat tabs | Blizzard's in every theme | SaftUI draws no state on them today (audit, "could not determine": their template's), and still doesn't |

## 2. The derivation

### The settings

Saved in the profile beside the Accent, `st.config.profile.theme.states`, defaults in
`st.defaults.theme.states` (`SaftUI-Core/Config/defaults.lua`), shared by every theme as the Accent is.

| Key | Name in the menu | Range, step | Default | Used by |
| --- | --- | --- | --- | --- |
| `mode` | Derivation | `'layers'`, `'tones'`, `'hue'` | `'tones'` | all |
| `hover` | Hover | 0 to 0.60, 0.01 (a percent) | 0.16 | all |
| `pushed` | Pushed | 0 to 0.80, 0.01 | 0.32 | all |
| `selected` | Selected fill | 0 to 0.60, 0.01 | 0.24 | all |
| `fade` | Selected fade | 0.10 to 1, 0.01 | 0.70 | all |
| `disabled` | Disabled | 0.10 to 0.90, 0.01 | 0.40 | all |
| `step` | Lightness step | 0.02 to 0.20, 0.01 | 0.08 | Tones, Hue-shifted tones |
| `shift` | Hue shift | 0 to 60 degrees, 1 | 20 | Hue-shifted tones |
| `chroma` | Chroma change | 0 to 0.30, 0.01 (a percent) | 0.10 | Hue-shifted tones |
| `direction` | Direction | `'warm'` (warm light, cool shadow), `'cool'` (cool light, warm shadow) | `'warm'` | Hue-shifted tones |

The ranges are the mockup's sliders'. A saved value outside its range is clamped to it when read; a `mode` or
`direction` that isn't one of these reads as the default (a hand edit or a later version's).

### Color spaces

All channels are numbers from 0 to 1 (WoW's). sRGB to linear: `lin(v) = v / 12.92` when `v <= 0.04045`,
else `((v + 0.055) / 1.055) ^ 2.4`; back: `unlin(v) = 12.92 * v` when `v <= 0.0031308`, else
`1.055 * v ^ (1 / 2.4) - 0.055`. `cbrt(x)` is `x ^ (1/3)` with the sign kept (`-(-x) ^ (1/3)` for a negative
x: Lua 5.1's `^` gives NaN for a negative base).

**To OKLCH** (Ottosson's OKLab, the mockup's constants): with `r, g, b = lin(R), lin(G), lin(B)`,

```
l = cbrt(0.4122214708 r + 0.5363325363 g + 0.0514459929 b)
m = cbrt(0.2119034982 r + 0.6806995451 g + 0.1073969566 b)
s = cbrt(0.0883024619 r + 0.2817188376 g + 0.6299787005 b)
L = 0.2104542553 l + 0.7936177850 m - 0.0040720468 s
a = 1.9779984951 l - 2.4285922050 m + 0.4505937099 s
b = 0.0259040371 l + 0.7827717662 m - 0.8086757660 s
C = sqrt(a^2 + b^2),  H = atan2(b, a)            (radians, -pi to pi; math.atan2 in Lua 5.1)
```

**From OKLCH** to linear sRGB: `a = C cos H`, `b = C sin H`, then

```
l = (L + 0.3963377774 a + 0.2158037573 b)^3
m = (L - 0.1055613458 a - 0.0638541728 b)^3
s = (L - 0.0894841775 a - 1.2914855480 b)^3
r =  4.0767416621 l - 3.3077115913 m + 0.2309699292 s
g = -1.2684380046 l + 2.6097574011 m - 0.3413193965 s
b = -0.0041960863 l - 0.7034186147 m + 1.7076147010 s
```

and each channel `unlin`, then clamped to 0 to 1.

**In gamut**: each linear channel from the step above lies in `[-0.0005, 1.0005]`.

**Gamut fit**: a color out of gamut keeps its L and H and loses chroma: if `(L, C, H)` is in gamut, C; else
24 rounds of halving `[lo, hi] = [0, C]`: `mid = (lo + hi) / 2`, in gamut sets `lo = mid`, else `hi = mid`;
the result is `lo`.

### The three modes

`Tone(A, k)`, the tone k steps from the Accent (k = +1 lighter, -1 darker; the ramps in the tests use up to
3 either way), with the settings `step`, `shift`, `chroma`, `direction`:

1. `L, C, H = OKLCH(A)`.
2. `L = clamp(L + k * step, 0, 1)`.
3. Hue-shifted tones only (k not 0): the target hue is 100 degrees (warm) when `(k > 0) == (direction ==
   'warm')`, else 280 degrees (cool), in radians. `d = (target - H) mod 2 pi`, taken in `[0, 2 pi)` (Lua's
   `%` already gives that); if `d > pi`, `d = d - 2 pi` (the shortest way round). `rot = min(|d|, shift * pi /
   180 * |k|)`: it never passes the target. `H = H + sign(d) * rot`. `C = max(0, C * (1 + (k > 0 and -1 or 1)
   * chroma * |k|))`: lighter loses chroma, darker gains it.
4. `C = fit(L, C, H)`, then the sRGB color of `(L, C, H)`.

The modes give the colors the states use:

| Mode | T+ | T- | What hover, pushed and selected draw |
| --- | --- | --- | --- |
| Layers | A | A | the Accent itself at h, p, s over the body |
| Tones | `Tone(A, +1)` (plain: step 3 skipped) | `Tone(A, -1)` | the lighter tone at h, the darker at p, the Accent at s |
| Hue-shifted tones | `Tone(A, +1)` with step 3 | `Tone(A, -1)` with step 3 | as Tones |

The cache's named colors (what `st:StateColor` returns):

| Name | Color | Alpha |
| --- | --- | --- |
| `hover` | T+ | h |
| `pushed` | T- | p |
| `fill` | A | s |
| `fillHover` | T+ | s |
| `edge` | A | 1 |
| `edgeHover` | T+ | 1 |

**Solids** (a thumb or knob, whose fill is its whole look): Tones and Hue-shifted tones, `hover` is T+ and
`pushed` T-, solid. Layers, the Accent mixed into the piece's rest color: `mix(rest, A, 0.6)` for hover and
`mix(rest, A, 0.85)` for pushed (the mockup's), where `mix(x, y, a) = x * (1 - a) + y * a` per channel in sRGB
(as `BLEND` draws).

**The composite** of a fill over a body is the same `mix(body, color, alpha)`, one fill after another.

**The text pick** (WCAG 2): relative luminance `Y = 0.2126 lin(R) + 0.7152 lin(G) + 0.0722 lin(B)`;
contrast `(max(Y1, Y2) + 0.05) / (min(Y1, Y2) + 0.05)`. Over the composite, Text > Normal if its contrast is
at least the dark text's (`#111111`), else the dark text. Ties go to Text > Normal.

### Extreme accents

- **Near black** (L under about 0.1): T- is black (L clamps at 0) and T+ is barely lighter: the hover layer
  darkens a dark body a little and pushed darkens it more. #000000 gives T+ #020202, T- #000000; the hover
  composite over the kit's button fill is #1a1a1a against its #1f1f1f. Edges and bars in black on a dark
  frame hardly show. Nothing corrects it (**call**): the Accent is the player's, and the picker's preview
  shows what it does before Okay.
- **Near white**: T+ is white (L clamps at 1) and T- a light grey: #ffffff gives #ffffff and #e4e4e4. Every
  state is grey and light; text stays light at the defaults, and goes dark only at strong settings.
- **Grey, no hue** (C under about 1e-7): the hue is meaningless (atan2 of nearly zero), so Hue-shifted tones
  turn a hue that has no chroma, the chroma change scales nothing, and the result is the Tones result:
  #808080 gives #989898 and #696969 in both modes.
- **The far side of the hue wheel**: a yellow's darker tone in the warm direction turns toward 280 degrees
  the short way, through orange and red (95.6 to 75.6 degrees), not through green: #e6c84a's pushed tone is
  #e99f00. The mockup does the same and the owner saw it (G6 checks it).
- **NaN guards**: every input is clamped to 0 to 1 first, `cbrt` keeps the sign, and L is clamped, so no
  step divides by zero or takes a root of a negative; a channel that is not a number (a hand edit) reads as
  the default Accent, as `st:Color` already does.

### Worked values (the test vectors)

Computed from the formulas above at the default settings, in doubles (twice, independently: once on 0 to 255
channels as the mockup's JS does, once on 0 to 1 as the Lua will; both agree to the byte). Hex is each channel
`floor(v * 255 + 0.5)`. The tests compare each channel to within 1 of these. OKLCH of the presets:
#00adf0 L 0.7061, C 0.1505, h 235.32 degrees; #8a5cf5 L 0.6040, C 0.2177, h 292.50; #e6c84a L 0.8360, C
0.1450, h 95.58.

**The tones** (Layers: T+ = T- = the Accent):

| Accent | Mode | -3 | -2 | T- (-1) | T+ (+1) | +2 | +3 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| #00adf0 | Tones | #006189 | #007aaa | #0093cd | #5cc6ff | #a1dcff | #dbf1ff |
| #00adf0 | Hue, warm | #4c3fc2 (h 280.0) | #5660d7 (275.3) | #3888e9 (255.3) | #1ccef0 (215.3) | #5fecec (195.3) | #b5ffea (175.3) |
| #00adf0 | Hue, cool | | | #0098b2 (215.3) | #89bcff (255.3) | | |
| #8a5cf5 | Tones | #49009c | #5e22be | #7441d9 | #9f7fff | #b5a2ff | #cdc2ff |
| #8a5cf5 | Hue, warm | #3700ac (280.0) | #490edd (280.0) | #5a44ed (280.0: stops at the target) | #c26eef (312.5) | #f184e2 (332.5) | #ffb1d2 (352.5) |
| #8a5cf5 | Hue, cool | | | #9721c9 (312.5) | #878aff (280.0) | | |
| #e6c84a | Tones | #967d00 | #b19500 | #ccae28 | #ffe370 | #fffef9 | #ffffff |
| #e6c84a | Hue, warm | #d7461d (35.6) | #e27600 (55.6) | #e99f00 (75.6) | #f7e579 (100.0: stops at the target) | #fffef7 | #ffffff |
| #e6c84a | Hue, cool | | | #c8b100 (100.0) | #ffdeaf (75.6) | | |

Gamut-limited, so they test the fit: #00adf0's +1 (C 0.1505 to 0.1271), +2 and -3; #8a5cf5's +1 and -3;
#e6c84a's +2 and +3 (white at L 0.996 and 1).

**The composites and the text pick** over the kit's button fill (`st.BOX_COLORS.bg`, 0.12, #1f1f1f), at the
defaults, with the contrast of the text picked (light is Text > Normal #e6e6cc, dark #111111):

| Accent | Mode | Hover (T+ at 16%) | Pushed (T- at 32%) | Selected fill start (A at 24%) | Selected + hover start | Thumb solid hover, pushed (rest #4d4d4d) | Knob solid hover, pushed (rest Text > Normal) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| #00adf0 | Layers | #1a3540 light 10.1 | #154c62 light 7.3 | #174151 light 8.6 | #14526a light 6.7 | #1f86af, #0b9fd7 | #5cc4e2, #22b5eb |
| #00adf0 | Tones | #283943 light 9.3 | #154456 light 8.3 | #174151 light 8.6 | #355b70 light 5.7 | #5cc6ff, #0093cd | #5cc6ff, #0093cd |
| #00adf0 | Hue | #1e3b40 light 9.4 | #27405f light 8.3 | #174151 light 8.6 | #1e5e6a light 5.7 | #1ccef0, #3888e9 | #1ccef0, #3888e9 |
| #8a5cf5 | Layers | #302841 light 10.9 | #413263 light 8.8 | #382d52 light 9.9 | #45356c light 8.3 | #7156b2, #815adc | #af93e5, #9871ef |
| #8a5cf5 | Tones | #332e43 light 10.2 | #3a2a5a light 10.0 | #382d52 light 9.9 | #4d4170 light 7.1 | #9f7fff, #7441d9 | the same |
| #8a5cf5 | Hue | #392b40 light 10.3 | #322b61 light 10.0 | #382d52 light 9.9 | #5a3b6a light 7.3 | #c26eef, #5a44ed | the same |
| #e6c84a | Layers | #3f3a26 light 9.0 | #5e552c light 5.9 | #4e4729 light 7.3 | #675c2e light 5.3 | #a9974b, #cfb54a | #e6d47e, #e6cc5e |
| #e6c84a | Tones | #433e2c light 8.4 | #564d22 light 6.7 | #4e4729 light 7.3 | #70653c light 4.5 | #ffe370, #ccae28 | the same |
| #e6c84a | Hue | #413e2d light 8.4 | #5f4815 light 6.8 | #4e4729 light 7.3 | #6d663f light 4.5 | #f7e579, #e99f00 | the same |

"Selected + hover start" is the hover layer, then the hover fill at its left end, over the body. Over the
kit's field fill (0.078, #141414) the Tones hovers are #1f303a, #2a253a and #3a3523, all light.

**Where the text turns dark** (the pick's other branch), over the same body: Hover at 60%: #00adf0 Tones
#4383a5 dark 4.5, Layers #0c749c light 4.1; #e6c84a Tones #a5944f dark 6.3, Layers #968439 dark 5.1, Hue
#a19655 dark 6.3; #8a5cf5 Tones #6c58a5 light 4.6. Pushed at 80%: #00adf0 Tones #067caa dark 4.0, Layers
#0691c6 dark 5.3; #e6c84a Tones #a99126 dark 6.1.

**Extremes** (Tones and Hue-shifted alike unless shown): #000000 T+ #020202, T- #000000; #ffffff #ffffff,
#e4e4e4; #808080 #989898, #696969; #0a0a0a #1c1c1c, #010101; #f5f5f5 #ffffff, #dbdbdb; #ff0000 Tones
#ff6a59, #d50000, Hue #fa7400, #d00055.

## 3. The API

### One place that derives and caches: `SaftUI-Core/Media/states.lua` (new)

Loaded right after `Media/colors.lua` in both of Core's TOCs. A plain table `st.States` (`ST`), no module: it
has no `OnColorsChanged` of its own.

**Pure functions** (no profile, no frames; what the derivation tests call):

```lua
ST.Oklch(r, g, b) -> L, C, H                -- 0..1 sRGB to OKLCH (H in radians)
ST.Srgb(L, C, H) -> r, g, b                 -- back, each channel clamped to 0..1 (no fit)
ST.InGamut(L, C, H) -> boolean
ST.FitChroma(L, C, H) -> C
ST.Tone(r, g, b, k, settings) -> r, g, b    -- section 2's Tone; Layers returns r, g, b
ST.Mix(r1, g1, b1, r2, g2, b2, a) -> r, g, b
ST.Contrast(r1, g1, b1, r2, g2, b2) -> ratio
ST.Derive(r, g, b, settings, out) -> out    -- fills out's named colors in place (no table made)
ST.NewDerived() -> out                      -- a table Derive fills: made once by each holder
```

**The settings**: `ST.Settings()` is the profile's `theme.states` (AceDB fills its defaults), clamped as
read into one scratch table made at load (so a hand edit never reaches the math). `ST.RANGES`, `ST.MODES`,
`ST.DIRECTIONS` hold section 2's table.

**The cache.** One derived table, `ST.cache`, made at load. It is current while the Accent's r, g and b, the
profile's `theme.states` table and `ST.serial` are the ones it was computed from; every read checks those
five values (no allocation, a few comparisons) and computes again in place when one differs. So it computes
once per change, whoever changed it: the Accent row, its reset, the picker, a profile switch, copy or reset,
a migration. `ST.serial` counts the derivation settings' changes.

**What readers call** (on `st`, as `st:Color` is; each returns plain numbers):

```lua
st:StateColor(name, derived) -> r, g, b, a  -- 'hover', 'pushed', 'fill', 'fillHover', 'edge', 'edgeHover';
                                            -- derived optional (a preview's own); an unknown name errors at the caller
st:StateSolid(name, r, g, b, derived) -> r, g, b   -- 'hover' | 'pushed' over a rest color (thumb, knob)
st:StateText(name, r, g, b, derived) -> r, g, b    -- the text color over a body r, g, b under that state's
                                            -- pieces ('rest', 'hover', 'pushed', 'fill', 'fillHover')
st:StateFade(derived) -> right              -- the Fill's right texture coordinate, 1 / f
st:StateAlpha(derived) -> d                 -- the Disabled opacity
```

**How a change reaches readers.** Through the live color mechanism, unchanged: every state reader follows
the `accent` group (`st:FollowColor(object, 'accent', nil, paint)`, or a module's `OnColorsChanged('accent')`),
which every Accent change already passes. A derivation setting's set and reset call `ST.Changed()`:
`ST.serial = ST.serial + 1`, then `st:ColorChanged('accent')`. No new group, no new key (**call**: one group
means one place to look, and the derivation can't change without the Accent's readers hearing it).

**What a pass may call** gains two, for the state pieces only (`.agents/architecture.md`'s list and
`tests/lib/color_cost.lua`'s): a Fill's `SetTexCoord` (Selected fade), and `SetAlpha` on a disabled frame
of SaftUI's or on a state piece (Disabled opacity, and a piece's 0 under Blizzard). Both are a region's or a
frame's look, not protected and run no script. Nothing else changes: no frame, texture or table made, no
layout.

### One set of helpers that draw a state: `SaftUI-Core/Widgets/states.lua` (new)

Loaded first in `SaftUI-Core/Widgets/load.xml`, so every widget file after it can take them. Each widget
says once what shape it is and which of its parts are its edge, text, mark and glyph; from then on its code
only says which states hold.

```lua
st:AddStates(frame, shape, opts) -> frame
  -- shape: 'box', 'row', 'tab', 'check', 'thumb', 'knob', 'icon', 'mover', 'glyph'
  -- opts (all optional):
  --   host    the frame the pieces are made on (default frame); on a Blizzard frame, a frame of SaftUI's
  --   inset   units in from host's edges for the Layer and Fill (default: st:DrawnInset(host), else 0)
  --   edge    'backdrop' (the kit Box: SetBackdropBorderColor), 'theme' (st:SetBorderColor on the drawn
  --           frame), or function(frame, r, g, b) (r nil: put the rest edge back), or false
  --   bar     'left' | 'bottom' (row, tab)
  --   text    a font string, or a list; textRest = function(frame) -> r, g, b (its rest color; Normal if
  --           nil); body = { r, g, b } or function(frame) -> r, g, b (what it sits on, for the pick)
  --   mark    the check's square texture; glyph = the glyph texture or font string, glyphRest = fn
  --   solidRest function(frame) -> r, g, b: a thumb's or knob's rest color
  --   checked true for 'icon' with game: make the checked texture too (action, pet, stance, totem buttons)
  --   game    true for 'icon': the pieces are the button's highlight, pushed and (checked = true) checked
  --           textures, made and handed to SetHighlightTexture(t, 'BLEND'), SetPushedTexture, SetCheckedTexture
  --   pieces  for 'icon', instead of game: { hover =, pushed =, checked = } textures that exist and the game
  --           shows (Blizzard's regions on a micro button, a HIGHLIGHT texture of SaftUI's never handed to a
  --           setter): the helper colors them and makes nothing; a checked one gets the fade texture once, here,
  --           out of combat (a style change, as today's SetColorTexture on it)
  --   wire    false to skip the scripts (default true but for 'icon': HookScript OnEnter, OnLeave,
  --           OnMouseDown, OnMouseUp and OnHide set hover and pushed)
  --   blizzard function(frame) -> boolean: while true the pieces are held at alpha 0 and the edge is left
st:SetState(frame, key, on)       -- key 'hover', 'pushed', 'selected', 'focus', 'disabled'; shows, hides and paints
st:GetState(frame, key) -> boolean
st:PaintStates(frame, derived)    -- colors only: what a pass runs (derived optional, a preview's)
st:RestyleStates(frame)           -- after a look change (Blizzard or not, a new inset): out of a pass
st:RemoveStates(frame)            -- a pool releasing it: forgets it and its follow
```

The record for a frame lives in a weak table of the file's, keyed by the frame: nothing is written onto a
frame that isn't SaftUI's (taint rule 1), and on SaftUI's own frames nothing either. `st:AddStates` follows
`accent` with `st:FollowColor(record, 'accent', nil, PaintRecord)` and, where it colors a drawn frame's edge,
keeps it through a theme recolor with `st:KeepOwnColors(record, PaintRecord)` (keyed by the record, so it
never takes a module's own kept color off the frame). A second `st:AddStates` on a frame restyles it and
adds nothing.

**What a paint touches** (the budget's rule, **call**): every game-shown piece (an icon button's highlight,
pushed and checked textures, a micro button's) on every pass, since the game shows them without SaftUI's
code; a scripted piece (Layer, Fill, Bar, Mark) only while it shows, since `st:SetState` colors it as it
shows it; an edge only while selected or focused; a text only while it sits on a piece. A widget at rest
costs a pass one function call and no setter.

**How Core's skinners use them:**

- `st:CreateButton` and `st:SkinButton` (`Widgets/button.lua`): `st:AddStates(button, 'box', { edge =
  'theme', text = <its label>, blizzard = <its look> })`. Its flat highlight and pushed textures go (no
  `SetHighlightTexture` on it any more: a game highlight sits over the label); its disabled texture goes, and
  post-hooks on the button's `Enable`, `Disable` and `SetEnabled` set the disabled state (Alpha d). On a
  Blizzard panel button it skins (retail's bank deposit button: `skin.own`) the game's disabled art stays
  under Blizzard and its alpha is left alone (**call**). `st:SetButtonPressed` (the bags' current view under
  Blizzard) stays for Blizzard's look and calls `st:SetState(button, 'selected', ...)` too.
- `st:SkinCheckButton` (`Widgets/checkbutton.lua`): style default, `'check'` (its box drawn, its checked
  texture the Mark, inset by the rule above, in `edge`; a post-hook on `SetChecked` and `PostClick` sets
  selected); style `'button'`, `'box'` (selected while checked: Edge and Fill, no mark: the Edit toggle and
  the currency funnel); style `'bare'`, only the Layer for hover (its checked texture is its caller's).
- `st:SkinActionButton` (`skinning.lua`): `'icon'`, `game = true`. The hover follows the Accent through the
  helper, not `PaintHover`; under Blizzard its state art (`ThemeArt.StyleState`) as today.
- `st:SkinNewScrollBar` (`Widgets/scrollbar.lua`): `'thumb'` on the thumb, rest `kit-edge`.
- `st:CreateRadioGroup` (`Widgets/radiogroup.lua`): its buttons are `st:SkinButton`'s; the pick is
  `st:SetState(button, 'selected', true)` (its own `ColorPicked` and `KeepOwnColors` go; the None guard of
  the followup "Retail bank leftovers" comes free: no backdrop, no edge, nothing indexed).
- `st:SkinEditBox` (`skinning.lua`): focus is `st:SetState(box, 'focus', ...)` on its backdrop of SaftUI's,
  in the Accent (was white).
- `st:EnableResizing` and the options window's grip: `'glyph'` on the corner texture.

**How the options kit uses them** (`SaftUI-Core/Config/`): `W.Box` keeps the body and edge;
`W.HoverEdge(frame, isDisabled)` becomes `W.HoverStates(frame, isDisabled)`, which calls `st:AddStates(frame,
'box', { edge = 'backdrop' })` and honours `isDisabled`; `W.Edge(frame, lit)` stays only for focus
(`st:SetState(frame, 'focus', lit)`); `optionscontrols.lua`'s `Paint` sets `selected` from `control.on`,
`hover` from `control.hovered`, `disabled` from `control.disabled`; `Base:SetDisabled` (`optionswidgets.lua`)
sets `disabled` (Alpha d) in place of its 0.4. The check box (`Kit.CheckBox`, `Kit.SetCheck`) is `'check'`,
the select face, color field, keybinding and font face `'box'`, list rows, search results and sidebar rows
`'row'` (text: their label; body: the list's or sidebar's fill), tabs `'tab'` (rest Muted), the range's knob
`'knob'`, icon links, reset icons, slots and the position block's dots `'glyph'`.

**A widget made by another addon** (or a module's own) calls the same: `st:AddStates(frame, shape, opts)` once
and `st:SetState` as its state changes, `st:RemoveStates` when a pool releases it. A module that colors a
state any other way fails the source scan (section 8, Task 11 of the plan).

## 4. The mapping

Every row of the audit's table (A1 to A10) and every non-state use of the Accent (B). "Today" is the audit's,
checked against the code; "After" is the shape and anything special. Under Blizzard is the table in section
1, unless a row says otherwise.

### A1. The options window kit (`SaftUI-Core/Config/`)

| Widget | Today | After |
| --- | --- | --- |
| Labelled button (`W.Button`, execute, sidebar commands, dialog buttons, Reload UI, Close's kit look) | hover: edge A; held: label 1 down; on: edge A; disabled: alpha 0.4 | box: hover Layer; held Layer `pushed` and the label 1 down; on: Edge + Fill; disabled Alpha d. Under Blizzard: panel art, the label in A while on (today's) |
| Icon button (`W.IconButton`) | hover edge A (icon A with `hoverIcon`); on: edge A + icon A | box; on: Edge + Fill, the icon A (kept: an icon is not text); `hoverIcon` keeps the icon in `edgeHover` under the mouse |
| Icon link (`W.IconLink`) | icon Muted, hover A, on A | glyph |
| Reset icon | Muted, hover A | glyph |
| Item dots, font row link | Muted, hover A (white under Blizzard) | glyph (white under Blizzard: kept) |
| Toggle (18 check box) | hover edge A; on: an A square | check: hover Layer; on: Edge + Mark + Fill |
| Toggle on a field (`MakeCheck`) | as toggle | check |
| Multiselect and check list box | the row's hover lights the box's edge | check, its hover from its row's |
| Input, number box, search box, dialog input, range value box | hover edge A (not while focused); focus edge A | box: hover Layer; focus Edge |
| Range | track `kit-edge`, fill A, knob Text > Normal; no hover | the fill is a progress fill (stays A); the knob a knob: Solid on hover and drag |
| Select face | hover edge A | box |
| Color field | hover edge A | box (the Accent row's gains the dots, section 6) |
| Keybinding button | hover edge A; waiting: edge A, "Press a key" in A | box; waiting is selected (Edge + Fill), "Press a key" stays A (a prompt, text) |
| Dropdown and check list rows | hover A at 25%; picked: text A | row: hover Layer; picked: Bar + Fill, text by the pick (was A) |
| Search result rows | hover A at 25% | row |
| Sidebar page rows | hover #222 grey; current: A at 25% over the row, flat, + 2px bar | row: hover Layer (the grey goes); current: Bar (two lines) + Fill (fading) |
| Page tabs | text Muted, hover Normal; active: Normal + 2px underline | tab |
| Title page-list arrow | Muted, hover A | glyph |
| Share line links ("All", "Multiple") | A, hover Strong | glyph (a link): unchanged |
| Own mark and label | A bar, label A | a marker: unchanged |
| Position block dots | grey 4x4, hover Normal, picked 8x8 A | glyph: hover `edgeHover` 4x4; picked 8x8 A; picked + hover 8x8 `edgeHover` |
| Position nudge arrows | Muted, hover Normal | glyph |
| Color picker chips and blocks | hover edge A | box |
| Color picker ring | white over black | a marker: unchanged |
| Close button (`st:CreateCloseButton`) | hover: edge and X Danger, fill the close template's | unchanged (a meaning) |
| Resize grip | highlight and pushed Buttons > Hover at 1 | glyph |
| Sizes bar, edit mode bar icon buttons | as icon button | box (`W.IconButton`) |

### A2. Core's widgets

| Widget | Today | After |
| --- | --- | --- |
| `st:CreateButton` / `st:SkinButton` | highlight Buttons > Hover at 0.4 BLEND over the whole button; pushed Buttons > Pushed; disabled black 40% | box (above); Alpha d for disabled |
| `st:SkinCheckButton` (12) | highlight Hover at 0.4; checked: the whole box in Buttons > Checked | check (Mark 8 square), `'button'` style box, `'bare'` the Layer only |
| Radio group | picked: edge A | box: picked = selected (Edge + Fill) |
| Scroll bar thumb | Normal at rest, Hover, Pushed | thumb (rest #4d4d4d) |
| `st:SkinEditBox` (bag search, chat edit box) | focus edge white | focus Edge A |
| `st:SkinActionButton` (bag, bank, bank tab slots, the loot window's slot) | hover A at full, blend not set (additive); pushed black 10%; disabled black 40% | icon: hover `BLEND` T+ at h, pushed T- at p; the disabled texture kept |
| `st:EnableResizing` corners | Hover at 1, BLEND | glyph |

### A3. Edit mode

| Widget | Today | After |
| --- | --- | --- |
| Mover overlay | white edge, black 30%; hover: nothing on the box (name label; the overlap list's `> name`); selected: edge A, fill A at 15% | mover |
| History list rows | hover A at 25%; current step: 2px mark | row: hover Layer; current step: the selected row (Bar + Fill) |
| History list's and the bar's number boxes (`W.NumberBox`; `EM.RecolorNumberBox`) | edge A under the mouse and with the keyboard | box: hover Layer, focus Edge (the kit's); `EM.RecolorNumberBox` keeps only the arrows' Muted |
| Docked bar's hide-until-hovered strip | 2px A along the top | a marker: unchanged |

### A4. Action bars

| Widget | Today | After |
| --- | --- | --- |
| Action, pet, stance, extra, zone, leave vehicle buttons (`AB:SkinButton`) | hover white 15% ADD; pushed black 10%; checked white 30% ADD; equipped: edge A; flash Danger 40% | icon (game pieces): hover `BLEND` T+ at h; pushed T- at p; checked: the Fill as the checked texture + Edge A from a `SetChecked` post-hook (LibActionButton's and SaftUI's own buttons: both SaftUI's frames); equipped edge A (a marker, same color: an equipped, checked button is one edge); flash unchanged |
| Keybind mode's highlight (the button under the mouse while binding) | overlay A at 40% | the overlay is SaftUI's frame: selected (Edge + Fill) while it marks a button (**call**: it marks the one you bind, which is a choice, and a 16% hover would be too faint over an icon) |
| Keybind mode's Done | `st:SkinButton` | box |

### A5. Bags

| Widget | Today | After |
| --- | --- | --- |
| View buttons | hover Buttons > Hover 40% (body); current: edge A | box: hover Layer; current: Edge + Fill. Under Blizzard: pressed panel button, as today |
| Edit toggle, currency funnel (`'button'` style) | checked: Buttons > Checked over the whole button | box: checked = Edge + Fill |
| Bag Slots, Warband Bank, bank deposit | `st:SkinButton` | box |
| Item slots | hover A at full additive; pushed cleared | icon: hover, pushed (gains one) |
| Bag bar slots (Blizzard's `BaseBagSlotButtonMixin`, restyled after `UpdateTextures`) | hover A, ADD, alpha 1; pushed black 10% | icon: the restyle sets the textures' look out of combat as today; colors by the helper |
| Bank tab slots | as item slot; unbought: Danger at 30% | icon; Danger unchanged |
| Selected bank window | window edge A | a marker on a window: unchanged (no fill on a window: **call**) |
| Categories list rows | hover A 25%; selected: the same 25% + 3px bar | row: hover Layer; selected Bar (two lines, was 3) + Fill |
| `+ New category`, `+ Block`, `+ Group` | text A, hover A at 70% | glyph (a link): hover Text > Strong (was a dimmed A) |
| Remove (x) icons | Muted, hover Danger | unchanged (a meaning) |
| Rule editor NOT box | hover edge A; on: text A + edge A | box: on = Edge + Fill, the label by the pick (was A) |
| Rule editor fields and boxes | the kit's | the kit's |
| Rule editor insert line, AND and OR connectors | A, Warning | markers: unchanged |
| Bag search box | focus white | focus Edge A (Core) |
| Category header filter box (8), currency veil and bank eye (`'bare'`) | Hover 40%; checked Buttons > Checked; veil black 60%; eye Muted | check (Mark 6 square); `'bare'` Layer only, their checked looks the callers' |

### A6. Minimap and the micro menu

| Widget | Today | After |
| --- | --- | --- |
| Micro buttons (Blizzard's, flat under Thick and Thin) | highlight Buttons > Hover at 0.4 BLEND; pushed (its frame open) Buttons > Pushed at 0.6; alert Caution | icon (game pieces): the highlight `hover`; the pushed background is the Fill (a frame open is current: **call**) and the panel's Edge goes A from a post-hook on the button's `SetButtonState` (a post-hook on Blizzard's button: rule 2); alert unchanged |
| Bar items (zone text, compartment, clock) | Hover 40% BLEND, Pushed at 1, disabled black 40% | box: Layer for hover and pushed, Alpha d |
| Tracking, queue, expansion buttons | highlight Buttons > Hover at 1, blend not set | icon: the highlight `hover` at h, `BLEND`; the expansion button's pushed art is Blizzard's (left) |
| Minimap addon buttons | Blizzard's menu | Blizzard's |

### A7. Loot

| Widget | Today | After |
| --- | --- | --- |
| Roll buttons (Blizzard's template) | hover and pressed Blizzard's; chosen: icon edge A + "Choice" in A; the others at 35% | Blizzard's hover and press; chosen: selected on the icon's backdrop of SaftUI's (Edge + Fill), "Choice" A (a label); the others at Alpha d (40%, was 35%: they can no longer be picked, so disabled) |
| Loot window rows (cards) | card edge A under the mouse | row on the card (SaftUI's frame): hover Layer, the edge stays the theme's |
| Feed icon buttons | `st:CreateButton` + icon A while hovered | box; icon A under the mouse (a `hoverIcon`) |
| Feed filter menu | the kit's check list | the kit's |

### A8. Misc

| Widget | Today | After |
| --- | --- | --- |
| Totem buttons (Blizzard's secure `MultiCast` buttons, skinned by the recipe) | hover A ADD; pushed black 10%; checked white 30% ADD; flash Danger | icon (game pieces): hover, pushed, checked as the Fill; no edge on check (no new hook on Blizzard's secure buttons: **call**); flash unchanged |
| Totem flyout arrow | thick arrow on hover | unchanged |
| Blizzard color picker skin: Okay, Cancel | edge A on hover (SaftUI's box over the button) | box on SaftUI's box (host), the Layer inside it |
| Blizzard color picker skin: hex box | focus white | focus Edge A |
| Blizzard tracker skin: quest item | hover A ADD (SaftUI's own texture in HIGHLIGHT) | icon: that texture, `hover`, `BLEND` |
| RestedXP guide steps | hover: the header strip's color | row: its highlight texture (SaftUI's) colored `hover` at h, shown by the existing `SetBackdropColor` hook |

### A9. SaftUI's tracker

| Widget | Today | After |
| --- | --- | --- |
| Quest rows | hover A 25%, 2 past the row; focused quest's bar | row: hover Layer (2 past, as today); the focus bar a marker: unchanged |
| Quest item buttons | hover A at 0.4, HIGHLIGHT, blend not set; inside quest area: edge A; combat dim 0.4 | icon: hover `BLEND`; the edge and the dim markers: unchanged |
| Collapse chevrons | Muted, hover Strong | glyph: hover `edgeHover` |
| Popup rows | bar and label A; row hover A 25% | row hover Layer; the bar and label markers: unchanged |

### A10. Unit frames and chat

Nothing changes. Unit frames draw no state (a tooltip only). A nameplate's target border stays white: a
marker over data colors, where an Accent border would clash with a class or reaction color it sits on
(**call**; it also stays Blizzard's convention). Chat's tabs are Blizzard's; its edit box's focus is Core's
(`st:SkinEditBox`, A2).

### B. The Accent where it is not a state: stays the Accent

The chat prefix; the window's and bar's "UI"; links (the share line's, `+ New category`); an own label, its
section title and the own mark; a found setting's label; "Press a key"; the slider fill, the bags' loading
bar and the roll timers (progress); the bags' "Category:" tooltip line and the share tooltip's value (text);
an equipped item's border; the selected bank window's border; edit mode's grid centre lines, snap guides,
Coordinates label, the overlap list's `> name` (a list in one text, **call**) and the docked bar's strip; the
tracker's focus bar, popup bar and label, item number tag and in-area border; the rule editor's AND and the
drag insertion line; the Accent row's own swatch. And within the state rules, at full: the check mark, the
selected Edge and Bar (the sidebar's bar, a tab's underline, a picked radio's border), a picked dot.

### The audit's inconsistencies, each settled

| # (audit C) | Settled by |
| --- | --- |
| 1 `/sui` borders light on hover | hover is the body (box) |
| 2 bag view buttons: hover body, current border | box: hover Layer, current Edge + Fill |
| 3 action bars white 15%, slots A at full | one icon rule: T+ at h, `BLEND` |
| 4 five forms of hover | one per shape (the table) |
| 5 seven hover strengths | one, h; the constants `HOVER_TINT`, `TINT_ROW`, `TINT_OBJECT`, `HOVER_ALPHA` and the rest go |
| 6 sidebar's grey hover; Categories' same fill for hover and selected, its 3px bar | row: Layer for hover, Bar + Fill for selected, the bar two lines |
| 7 a dozen selected forms | one per shape: Edge + Fill (box, mover), Bar + Fill (row, tab), Edge + Mark + Fill (check), checked Fill + Edge (icon) |
| 8 focus white in Core's edit box and the color picker skin's hex box | focus is Edge A everywhere |
| 9 icon hover through five colors | glyph: `edgeHover`; links Strong; Danger icons Danger (meanings) |
| 10 pressed in six forms | Layer `pushed` (box, row, tab, check), the pushed texture (icon), Solid (thumb, knob); the kit's 1-line label move stays |
| 11 two 40% mechanisms | Alpha d for every widget SaftUI disables; the game's for icon buttons (named) |
| 12 the Accent only under Thick and Thin | the Blizzard table: Blizzard's art draws its states; SaftUI's elsewhere |
| 13 the docs disagree with the code | the design system rewritten (section 7) |
| 14 the close button and Hover's description | the close button keeps Danger (a meaning); Hover's description goes with Hover |
| 15 a current marker white on a plate, A on a mover | markers keep their meaning's color: a plate's target white over data colors, SaftUI's own UI in A; a mover's rest edge is white (rest, not a state) |
| 16 search non-match at 10% | a filter's answer, not disabled: unchanged |

### Visible changes by area

What the owner will see differently, at the defaults with the default Accent:

- **`/sui`**: every control's hover tints its body (#283943 over a button's fill) and its edge no longer
  turns blue; a pressed button tints darker as its label drops; an "on" button (the edit mode bar's toggles,
  the sizes bar) gets a blue edge and a fill fading left to right; a ticked check box gets a blue edge and the
  fade besides its square; the sidebar's hover is a blue tint (not grey) and the current page's fill fades
  out across 70% (was flat 25%); a tab gets a tint under the mouse and the fade over its underline; dropdown
  and check list rows hover in the lighter tone at 16% (was the Accent at 25%) and the picked entry gets a
  bar and the fade instead of blue text; the slider's knob turns light blue under the mouse and darker while
  dragged; icon links, the reset icon and the dots turn the lighter blue (#5cc6ff) under the mouse (was the
  Accent); nudge arrows and position dots too (was Text); a key binding button waiting for a key has the
  selected look; the Accent row gains the dots.
- **Edit mode**: movers tint under the mouse (new); a selected mover's fill fades (was flat 15%); History
  rows hover in the tone; the current step is a selected row.
- **Bags**: view buttons tint under the mouse (was Buttons > Hover's blue at 40%) and the current one adds the
  fade to its edge; the Edit toggle and the currency funnel, checked, show an edge and the fade (was a solid
  fill); item, bank and bag bar slots under the mouse are a faint 16% tint (was the full Accent, added: much
  softer) and tint darker while clicked (new); the Categories list's hover is a tint and the selected one a
  2-line bar and the fade (was 3 and flat); `+ New category` under the mouse is white (was dimmed blue); the
  category filter box (8) shows an edge, a small square and the fade when ticked (was solid); the search box's
  focus edge is blue (was white); the NOT box when on shows the fade, its label in Text (was blue).
- **Action bars** (and pet, stance, extra): hover is a 16% tint of the lighter blue (was white 15%, added);
  pressed a 32% darker tint (was black 10%); an active ability shows a blue edge and the fade (was white 30%);
  keybind mode's highlight is an edge and the fade (was a 40% wash).
- **Totem bar**: hover a tint (was the full Accent, added); pressed and checked as action buttons, no edge.
- **Micro menu and minimap**: micro buttons' highlight is the tone at 16% (was Buttons > Hover at 40%); a
  micro button whose window is open shows a blue edge and the fade (was a 60% fill); the bar's items tint for
  hover and press and dim to 40% when disabled (was a black overlay); the tracking, queue and expansion
  buttons' hover is a 16% tint (was solid Buttons > Hover, added).
- **Loot**: the chosen roll's icon gains the fade, and the others dim to 40% (was 35%); a loot window row
  tints under the mouse instead of its edge lighting.
- **Misc**: the color picker skin's Okay and Cancel tint (was an edge) and its hex box focuses blue (was
  white); Blizzard's tracker's quest items tint (was added blue); RestedXP's steps tint in the tone (was the
  header strip's grey); scroll thumbs rest lighter (#4d4d4d, was #1a1a1a) and turn the light tone under the
  mouse and the dark one held.
- **SaftUI's tracker**: rows hover at 16% in the tone (was the Accent at 25%); quest item buttons tint at 16%
  (was the Accent at 40%, added); chevrons turn light blue under the mouse (was white).
- **Global settings**: Colors > Buttons keeps only Danger; Theme > Accent has the dots menu.
- **Unit frames, chat, the close button, the flash, the markers**: nothing.

## 5. Settings and migration

**Removed**: Buttons > Normal, Hover, Pushed and Checked: their defaults (`st.defaults.colors.button.normal`,
`.hover`, `.pushed`, `.checked`), their rows on the Colors page, their previews, their resets, their
followers and readers, and the constants `st.HOVER_TINT`, `st.TINT_ROW`, `st.TINT_OBJECT` and the files' own
(`HOVER_ALPHA` in the action bars' skin and the micro buttons, `PUSHED_ALPHA`, the sidebar's `HOVER`). Rule
A of `tests/core/color_reads_test.lua` lists the four keys as retired, so a read of one fails the scan, and
`st:Color('button', 'hover')` errors at the caller (no default).

**Danger** stays where it is (**call**): Global settings > Colors > Buttons > Danger, the section's one row,
key `colors.button.danger`, its value and opacity unchanged, so no key moves and nothing visible changes. The
section's note becomes "Opacity sets how strongly it is drawn: 100% is SaftUI's own." Its readers (the action
and totem flash, the unbought bank slot) are untouched.

**Storage**: section 2's settings in `st.config.profile.theme.states`, defaults in
`st.defaults.theme.states`. AceDB saves only what differs.

**Migration step 7** (`CO.MIGRATION_STEPS`, appended as the earlier steps: never edited once shipped):
`{ retire = { 'button.normal', 'button.hover', 'button.pushed', 'button.checked' } }`. A profile that had
customized any of them loses those values once, at its next login or profile load; they become nothing
(**call**: no color they held means the same under the new rules, and the owner said "they are dropped").
Nothing is told in chat (**call**). `CO.OLD_COLORS` gains their shipped values for the record, frozen, as
the convention says every retired key's is: normal (0.1, 0.1, 0.1, 1), hover (0.3, 0.5, 0.7, 1), pushed
(0.3, 0.4, 0.5, 1), checked (0.3, 0.5, 0.7, 1). `colors.version` becomes 7. The derivation settings need no
step: a profile without them reads the defaults.

**The Colors page after**: Text, Buttons (Danger only), Class, Roles, Reputation, Factions, Power, Item
quality, Loot, Status, Threat, Objectives, as today otherwise.

**The Theme tab after**: Theme, Border, Outer border, Window background, Background, Accent (with its dots),
Options windows, Window titles. The Accent's desc: "SaftUI's accent under every theme: what is on, picked or
current, a field you type in, links and marks, fills that show progress, and the chat prefix. Hover, pushed
and selected are made from it; the dots set how."

**The picker's previews**: the `button` and `accent` kinds go, and two take their place
(`Config/optionspreview.lua`; the built-in kinds' list changes):

- **`states`**, the Accent row's: six tiles 58 wide across the strip's 370, the first at its left edge and the
  last at its right (about 4 apart), each a kit button ("Okay", 46 by 20, centred) held in one state with `st:SetState` (it takes no mouse) and its caption under
  it: Rest, Hover, Pushed, Selected, Selected + hover (the caption may shorten to fit: the builder's), and
  Disabled. Its Paint derives from the picked color into the kind's own derived table (`ST.Derive`) and paints
  each piece with it (`st:PaintStates(piece, derived)`), so it is the picked color's states in the frame of
  the change, with the profile's derivation settings. Under Blizzard it draws as Thick with the note "Shown as
  Thick: under Blizzard, SaftUI's controls wear Blizzard's art." (as the button kind's). The dots menu shows
  the same strip (section 6).
- **`danger`**, Buttons > Danger's: two tiles 118 wide, the first at the strip's left edge and the second at
  its right: an action button's flash at 0.4 ("Flash") and an unbought bank slot's tint at 0.3 ("Locked
  slot"), in the picked color times its opacity; under Blizzard the flash is Blizzard's art, so it draws as
  Thick with the same note.

## 6. The dots menu on the Accent row

**The row.** A color option may now carry `menu` and `menuTitle` (SaftUI's own fields, read raw), as an item
does (`optionsmodel.lua`'s header). The color widget (`optionstypes.lua`) then has a slot at its right
(`Kit.NewSlot`, Lucide's `ellipsis-vertical`), as the font row has its link: the field `W.WIDTH.color` (170),
`Kit.FONT_SLOT_GAP` (4, 8 under Blizzard), the slot 16, so the control is 190 wide like a font row. The slot's
tooltip: "Accent states" and "How hover, pushed, selected and disabled are made from the Accent." A click
opens the menu (`OW:OpenMenu`), or closes it when it's this row's. The swatch and its reset are unchanged;
the reset icon sits by the control as on any row. A color row without `menu` is as today. `OM.Search` finds
the menu's settings on the row's path, and `tests/lib/reset_walk.lua` walks a color row's menu as it walks an
item's.

**The menu** (`ST.MenuGroup()`, built in `Media/states.lua`; `optionsmenu.lua` draws it as every menu: 400
wide, the page's rows, 38 tall), titled "Accent", in this order:

1. **The preview**: the `states` strip (section 5) as a row of its own (a bare custom type, `statepreview`,
   `W.Define`), painted from the profile's settings, under the title. It takes no mouse. `noReset = 'a picture
   of the states, not a setting'`.
2. **Derivation**, a select: Layers, Tones, Hue-shifted tones. Desc: "How hover, pushed and selected are
   made from the Accent. Layers lays the Accent itself over a widget. Tones uses a lighter tone of it under
   the mouse and a darker one while held. Hue-shifted tones also turn the lighter tone toward warm and the
   darker toward cool, as a painter shades."
3. **Strengths** (a section):
   - **Hover** (0 to 60%): "How strongly a widget under the mouse is tinted: its body, never only its edge."
   - **Pushed** (0 to 80%): "How strongly a widget is tinted while it's held down."
   - **Selected fill** (0 to 60%): "How strongly the fill of a selected, checked or current widget starts, at
     its left. Its edge, bar or underline is always the full Accent."
   - **Selected fade** (10 to 100%): "How far across a selected widget its fill fades to nothing: at 100% it
     fades over the whole width."
   - **Disabled** (10 to 90%): "How see-through a disabled widget is: at 40% it shows at 40%."
4. **Tones** (a section): **Lightness step** (0.02 to 0.20): "How much lighter the hover tone and how much
   darker the pushed tone are than the Accent, in OKLCH lightness (0 to 1)."
5. **Hue shift** (a section): **Hue shift** (0 to 60): "How far the tones' hue turns, in degrees, toward warm
   (yellow) or cool (violet blue). It never turns past it." **Direction**, a select: "Warm light, cool
   shadow", "Cool light, warm shadow": "Which way the hue turns: warm light turns the lighter tone toward
   yellow and the darker toward blue; cool light the reverse." **Chroma change** (0 to 30%): "How much less
   colorful the lighter tone is, and how much more the darker, as a share of the Accent's."

**By mode** (**call**: dimmed, not hidden, so the menu doesn't jump in height as the select changes, the
mockup's): under Layers the Tones and Hue shift sections are disabled, their `disabledDesc` "Only for Tones
and Hue-shifted tones." and "Only for Hue-shifted tones."; under Tones the Hue shift section is disabled.
A disabled row shows no reset icon (the kit's rule), but keeps its value.

**Resets**: every setting row has its own, from where it is saved (`saved = st.Config.SavedAt('theme',
'states', <key>)`: the default is `st.defaults.theme.states[key]`, and a reset writes through the row's set,
which calls `ST.Changed()`). No section Reset.

**Live while dragging.** Every set calls `ST.Changed()`, so every state on screen follows: the /sui page under
the menu (the sidebar's current page, the tabs, the Accent row's own field), the bags, the bars. To keep a
drag at one pass a frame, the menu begins a color edit as it opens and ends it as it closes
(`st:BeginColorEdit()` and `st:EndColorEdit()`, the picker's): changes mark the Accent and one pass runs on the
next frame however many came, the budget guard applies, the whole pass runs at close, and with `/sui debug`
on the close prints the debug line (**call**). The menu and the picker never overlap (the menu's catcher
takes the click outside it, and the menu holds no color row), and the menu ends only the edit it began.
The menu's own preview row repaints on the pass too (it follows the Accent).

**The cost of a drag.** Each frame of a drag runs one Accent pass. What it touches, in the live colors spec's
full UI (a raid, every bag and both banks, 12 bars), with `/sui` open on Global settings > Theme:

| Reader | Pieces painted per pass | Count | Setter calls |
| --- | --- | --- | --- |
| Bag, bank, bank tab and bag bar slots | highlight, pushed (game pieces) | about 700 | 1,400 |
| Action, pet, stance, extra buttons | highlight, pushed, checked (vertex and texture coordinates) | 164 | 656, plus an edge per checked button |
| Totem buttons, micro buttons, bar and minimap buttons | 2 to 3 game pieces | about 30 | 80 |
| SaftUI's tracker's item buttons | highlight | up to 40 | 40 |
| Scripted pieces shown (a hover, the selected rows, tabs, toggles, checked boxes on the page; selected movers with edit mode on) | at most 5 each | about 40 | 200 |
| Everything at rest | none (one function call each) | about 400 | 0 |
| The cache | two tones computed once | 1 | 0 |

So a pass is under 2,500 setter calls and the derivation's one recompute (two tones, at most 48 gamut tests:
well under a millisecond of Lua). The budget is the live colors spec's (**call**): 2 ms of SaftUI's Lua per
pass in that UI, never more than the guard's 8 ms; the stubs pin the calls (under 2,500), nothing made or
forbidden, under 4 KB of garbage over 100 passes; the game's debug line gives the time (G11). The slots are
most of it. If the line shows a pass over 2 ms, the followup is to paint game pieces only on the slots shown
(a bag window closed paints nothing).

## 7. Docs and the design system

- `.agents/architecture.md`: colors (the four keys gone, Danger alone, migration step 7), the live color
  mechanism (what a pass may call gains a Fill's `SetTexCoord` and `SetAlpha` on disabled frames and state
  pieces; state readers follow `accent`; `ST.Changed`), the new files `Media/states.lua` and
  `Widgets/states.lua`, the readers' sentences of each addon (action bars, totem bar, minimap, bags, loot,
  tracker).
- `.agents/edit-mode.md`: the kit (the states helpers, `W.HoverStates`, `W.Edge` for focus only, the color row's
  menu and slot, the `states` and `danger` preview kinds, the menu's edit), the movers' look.
- `.agents/taint.md`: the recipe's state textures (`BLEND` everywhere, the action buttons' `SetChecked`
  post-hook, the micro buttons' `SetButtonState` post-hook, the bag bar's restyle), rule 1's list of what the
  helpers write (nothing on a frame).
- `.agents/testing.md`: the new tests and `color_cost.lua`'s two counted setters.
- `AGENTS.md`: Core's row (the states files).
- The design system (`docs/design-system/`), and its published artifact republished after (the controller's):
  - `README.md`: the Accent bullet (it is also what states are made from), the "Profile Buttons colours" bullet
    (Danger only), the States table rewritten from section 1 (one row per state, its form by shape), the
    in-world line, and a rule: "12. One accent. Hover, pushed and selected are derived from it; never read a
    color for a state."
  - `05-decisions.md`: decision 55 (this design: one Accent, the rules, the three modes, Tones and its numbers,
    the dots menu), noting it supersedes 29 (two tint strengths), 30 (the action buttons' hover, now the rule's)
    and 54 (Hover's meaning, Checked).
  - `25-colour-roles.md`: the Buttons section (Danger only), the Accent section (its non-state uses; the states
    derived), the hover readers' list.
  - `tokens.json`: `button-normal`, `button-hover`, `button-checked`, `button-pushed`, `accent-fill`,
    `accent-tint`, `pressed-fill`, `checked-fill`, `alpha-hover`, `alpha-tint`, `alpha-hover-soft`,
    `alpha-pressed`, `alpha-checked`, `alpha-micro-hover`, `alpha-micro-pushed` and `alpha-locked` (the roll
    buttons take Disabled) go; new `state-hover` (0.16), `state-pushed` (0.32), `state-selected` (0.24),
    `state-fade` (0.70), `state-step` (0.08), `state-shift` (20), `state-chroma` (0.10), and the default
    Accent's tones `accent-light` (#5cc6ff) and `accent-dark` (#0093cd), each usage naming `st:StateColor`;
    `alpha-disabled` stays (0.40, now the Disabled setting's default); `disabled-overlay` and `alpha-overlay`
    stay for the icon buttons' disabled texture only (`st:SkinActionButton`), no longer Core's buttons;
    `mark-width` stays.
  - `10-discrepancies.md` and `30-code-changes.md`: the entries on hover, the tints and the Buttons mapping
    marked settled by decision 55.
  - Components whose README states a state (and whose `preview.html` draws one): `Button`, `Toggle`,
    `Input`, `Select`, `ColorBar` (the Accent row's dots), `Range` (the knob), `Row`, `MenuItem`, `CheckList`,
    `OptionsWindow` (sidebar, tabs), `ActionButton`, `BagSlot`, `Mover`, `ResetIcon`, `Icons` (the glyph rule),
    `PositionBlock` (its dots), `Dialog` (its buttons). `CloseButton` keeps its hover and says why.
- `docs/followups.md`: "The color picker's preview copies other widgets' geometry" loses its `accent` kind
  part (the `states` kind uses the kit's own pieces); the radio group's None error in "Retail bank leftovers"
  is fixed by the radio group's change; a new entry if the budget's followup is needed (G11).

## 8. Risks, and how each is contained

- **Readability with a pale or dark Accent.** The text pick keeps labels readable on any fill; a near-black
  Accent's states barely show. Contained: the pick (tested with the vectors above); the picker's preview and
  the menu's show it before Okay; G5 and G6 try the three presets and a pale and a dark one.
- **The cost of a pass**, now that every hover follows the Accent. Contained: game pieces are the only ones
  painted on every pass, scripted ones only while shown; one pass a frame during a drag (the menu's edit, the
  picker's); the stubs pin the calls; the guard; the debug line (G11).
- **Taint on secure buttons.** Every new call on an action, pet, stance or totem button is a texture's color,
  alpha or texture coordinates, made out of combat at skin time as today; the only new hooks are post-hooks on
  `SetChecked` (SaftUI's own LibActionButton, pet and stance buttons, none on Blizzard's totem buttons) and on
  the micro buttons' `SetButtonState` (Blizzard's, a `hooksecurefunc` that colors SaftUI's own panel).
  Contained: taint rules 1 to 6, the cost scan's forbidden list in combat, and G12 (`/console taintLog 1`).
- **The Blizzard theme.** Contained: the helpers hold their pieces at 0 under Blizzard's look and leave the
  edge to the art; each area's tests run under Thick, Thin and Blizzard (the theme round trip).
- **The size of the change** (about 60 files across 8 addons). Contained: Task 1 lands the engine alone with
  nothing visible changed; the area tasks share no source file; each pins its rest look before and after (a
  widget at rest is unchanged); the source scan (Task 11) forbids a hand-rolled state, a retired key or
  constant, and a state texture set outside the helpers.
- **A profile's lost customizations.** Buttons > Hover and the rest are dropped. Contained: one migration step,
  tested; the owner's own profile is the only one known to have changed them.

## 9. In-game checks

On both clients, Thick, Thin and Blizzard where a check says, at the defaults unless it says otherwise.

- **G1.** `/sui`: a button, a field, a select, a color field and a check box under the mouse tint their body
  and keep a grey edge; a pressed button tints darker; Reload UI pressed and released works as before.
- **G2.** The sidebar: hover tints a page; the current page has a two-line bar and a fill fading out across it.
  The tabs: a tint under the mouse; the current tab's fill over its underline.
- **G3.** A dropdown open: rows tint under the mouse; the picked one has the bar and the fade, its text white.
- **G4.** Theme > Accent's dots: the menu opens with the preview, every setting has a reset once changed, the
  Tones and Hue shift sections dim by mode, and dragging Hover, Selected fill, Selected fade and Disabled
  changes the preview and the page behind it as you drag.
- **G5.** Pick #8a5cf5, then #e6c84a (the presets): every state follows; text on fills stays readable. Set
  Hover to 60% with the yellow: the preview's hover text turns dark.
- **G6.** Hue-shifted tones with the yellow: the pushed tone is orange (#e99f00), the hover tone a paler yellow;
  with the blue, hover turns cyan and pushed toward violet. Say if it reads wrong.
- **G7.** Bags: view buttons (hover tint, current edge and fade), item slots (faint tint under the mouse, darker
  when clicked), the Categories list, the Edit toggle, the category filter box, the search box's focus.
- **G8.** Action bars: hover, press, an active ability (auto attack on: an edge and the fade), an equipped
  trinket's edge; keybind mode's highlight. Pet and stance bars the same. Under Blizzard: Blizzard's art.
- **G9.** Micro menu: hover; open the character window: its micro button shows the edge and the fade, and
  goes back when it closes. The tracking, queue and expansion buttons' hover.
- **G10.** Edit mode: a mover tints under the mouse; a selected one has the edge and the fade. History rows.
- **G11.** With `/sui debug` on, in a raid or a busy city with every bag and the bank open: drag the Accent in
  the picker a few seconds and press Okay, then drag Hover in the dots menu and close it. Each debug line's
  slowest pass is under 2 ms; say if not, with the line.
- **G12.** `/console taintLog 1`; in combat use action, pet and stance buttons, toggle auto attack, open and
  close windows from the micro menu, use a totem; no `ADDON_ACTION_BLOCKED`, nothing in `taint.log` naming
  SaftUI's states.
- **G13.** A profile that had Buttons > Hover changed: after the update the Colors page shows only Danger,
  nothing errors, and the hovers follow the Accent.
- **G14.** Loot: a roll, chosen: the chosen icon's edge and fade, the others at 40%; the loot window's rows
  tint under the mouse.
- **G15.** SaftUI's tracker: rows and quest items under the mouse, the chevrons; a scroll bar's thumb.
- **G16.** Under the Blizzard theme, `/sui`, bags, bars and edit mode wear Blizzard's states and nothing of
  SaftUI's tint shows over them.

## What's left to the builder

- Names of locals, the record's fields, and how the helpers keep their pieces without allocating per state
  change.
- The exact word of each caption in the `states` strip within its tile, and its button's label.
- Each area's tests' structure and full-UI share, within the bounds of section 6.
- Whether a module's `OnColorsChanged('accent')` or a follower repaints a module's state frames (either is a
  pass; the helpers follow on their own).
- The in-game checklist each task ends with.

## Calls made while writing this

1. **Precedence**: disabled, then pushed over hover for the layer, then selected (in the hover tone while
   hovered and not pushed), then focus.
2. **Pieces**: a Layer under the text (`ARTWORK` -8) and a Fill over it (-7), both inside the edge, on every
   scripted shape; on icon buttons the game's own highlight, pushed and checked textures, over the icon.
3. **The fade** is a texture of SaftUI's with an alpha ramp, its length set by texture coordinates, so a
   Selected fade change is a pass and never a layout; horizontal, left to right, on every shape (tabs too).
4. **The Mark's size**: `floor(size / 6)` in from each side.
5. **The thumb's rest color** is `kit-edge` #4d4d4d (the mockup's); the knob's stays Text > Normal (decision 26).
6. **Checked icon buttons** take an accent Edge from a `SetChecked` post-hook (SaftUI's own buttons); totem
   buttons, Blizzard's secure ones, take the checked Fill only.
7. **Selected + hover on icon buttons** keeps the Accent's edge and fill (no `OnEnter` hook on secure buttons).
8. **Icon buttons keep the game's disabled texture**; everything SaftUI disables takes Alpha d.
9. **A mover's drag** draws as hover; the overlap picker's other movers keep their 40%.
10. **Glyphs** hover in the hover tone at full (`edgeHover`; the Accent under Layers); links in Text > Strong.
11. **Keybind mode's highlight** is a selection (Edge + Fill), not a hover.
12. **A micro button whose window is open** is current: the Fill and an edge from a `SetButtonState`
    post-hook.
13. **Roll buttons that can no longer be picked** are disabled (40%, was 35%).
14. **Markers keep their color**: a plate's target border white, the selected bank window's edge A with no
    fill, the overlap list's `> name` text in A, the tracker's in-combat dim, the totem flyout's arrow.
15. **Text pick**: light is Text > Normal, dark `#111111`, over the composite at the text's start.
16. **One group**: the derivation settings pass as `accent` (`ST.Changed`); the cache checks itself on read.
17. **A pass may call** a Fill's `SetTexCoord` and `SetAlpha` on disabled frames and state pieces.
18. **Painting**: game pieces every pass; scripted pieces only while shown.
19. **Danger stays** as Colors > Buttons > Danger, its key unchanged.
20. **Migration**: the four keys are dropped with no chat line.
21. **The `states` preview**: six buttons in six states; **`danger`**: the flash and a locked slot.
22. **The dots menu**: dimmed by mode, not hidden; the menu holds an edit while open.
23. **The budget** is the live colors spec's, 2 ms a pass.
24. **`st:SkinButton` on Blizzard's panel button** keeps the game's disabled art and alpha.

## Questions for the owner

1. **An active ability now shows an accent edge, the same as an equipped item's.** The fade tells them apart
   (only the active one has it). Is one accent edge for both all right, or should the equipped item's border
   become something else? Not blocking: the plan builds the edge.
2. **The scroll bar thumb rests lighter** (#4d4d4d, the mockup's) so its hover and held tones read against
   it; today it is near black (#1a1a1a). Keep the mockup's, or today's? Not blocking: the plan builds the
   mockup's, one constant.
3. **Buttons > Danger stays alone in a Buttons section.** Fine, or should it move (beside the Accent on the
   Theme tab, say)? Not blocking: the plan leaves it.
</content>
</invoke>
