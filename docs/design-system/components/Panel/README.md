# Panel

A frame drawn in SaftUI's theme: a fill with a 1px border (Thick adds a dark line outside and inside it), named by its kind, which every SaftUI frame in the world is built on.

## When to use

Every frame SaftUI draws: windows, panels, bars, buttons behind their icons, tooltips. Draw it with `st:SetTemplate(frame, theme, background, kind)`, `st:SetBackdrop(...)` or `st:SetBackdropIn(...)`, always naming the kind last.

## What the consumer provides

- The module's Theme and Background pair (`'theme'` follows SaftUI's; `'thick'`, `'thin'`, `'blizzard'`, `'none'`; Background `'theme'`, `'solid'`, `'transparent'`), offered on the module's page by `generators.theme` and `generators.background`.
- The kind: `panel`, `window`, `bar`, `action`, `slot`, `aura`, `tooltip`, `header`, `close`, `control`, `unitframe`, `member`, `small`.
- Content placed at the theme's inset (`st:ThemeInset(theme, background, kind)`), never at a hard-coded 1 or 2.
- Its own border colour, when it has one (quality, class, selected), through `st:SetBorderColor`, put back in `OnColorsChanged('theme')` or by `st:KeepOwnColors`.

## Sizes and tokens

| | Thick | Thin |
| --- | --- | --- |
| Fill | `backdrop` #1f1f1f | `backdrop` #1f1f1f |
| Border | 1px `border` #4d4d4d | 1px `border` #000000 |
| Outer border | 1px `border-alt` outside and inside the border (3px in all, `thick-width`) | none |
| Content inset | 2 | 1 |
| Transparent background | the fill at `alpha-theme` (0.9) | the same |
| Header and footer strips | `header-strip`: the border colour at 0.4, fill only, 31 tall (`header-height`), title in `normal` centred | the same |
| Close strip | `close-fill`, fill only | the same |

Under Thick and Thin only `header` and `close` draw differently (fill, no lines): a window draws as a panel, a control as a small frame, `unitframe` and `member` as a bar.

## States

The theme's colours change live from Global settings > Theme (`st:RecolorThemed`); a theme change redraws every frame (`st:RedrawThemed`) and every module lays itself out again, since the border's width moves what sits inside it.

## Blizzard theme

Each kind takes Blizzard's art: `window` the character frame's metal (its header moves into the metal's 20px title strip), `panel`, `bar`, `tooltip` and `unitframe` the one Blizzard box (the minimap header button's, 6px corners, drawn over the frame, 4px outside it; a frame drawn on itself takes it inside its bounds), `action` the action ring, `slot` and `aura` the white icon frame in the frame's own colour, `member` a bare fill. A frame's own border colour shows on the box desaturated and tinted. Fills are the Blizzard theme's dark grey (`#1f1f21`, windows and the rest set apart on the Theme tab); a small frame keeps one line in `#808080`; `header`, `close` and `control` are cleared. Insets per kind: window 2; panel, bar, tooltip, action, slot 3; small 1; unitframe 2; aura, member, header, close, control 0.

## Do and don't

- Do name the kind on every draw call (`tests/core/theme_kinds_test.lua` checks).
- Do read the inset from the theme.
- Don't call `SetBackdropBorderColor` on a drawn backdrop; use `st:SetBorderColor`.
- Don't add shadows, gradients or rounded corners.
