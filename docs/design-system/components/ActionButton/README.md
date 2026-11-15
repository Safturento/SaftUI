# ActionButton

An icon button in the `action` kind: the ability's icon inside the theme's border, with its hotkey, stack count and cooldown numbers in the pixel font.

## When to use

Action bars 1-8 (LibActionButton buttons), the pet, stance and leave vehicle buttons (SaftUI's own secure buttons), and the totem bar, which copies the same states. Bag slots (`BagSlot`) and auras (`AuraButton`) are their cousins.

## What the consumer provides

The bar's effective config (`AB:GetBarConfig(id)`): size, spacing, and each text's show, font, size, outline and position. The button is secure: never lay it out in combat (`.agents/taint.md`).

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Button | 45 on bars 1-8; 30 on pet, stance, leave vehicle and totems; Blizzard's 52 for the extra buttons | `action-button`, `small-button` |
| Spacing | 3 | `button-spacing` |
| Frame | `action` kind: the theme's border; the icon inside the inset, trimmed by `icon_trim` | `border`, `backdrop` |
| Hotkey | `pixel` 10, white, top right, 3 in; shortened ("S3" for Shift-3) | `pixel`, `hotkey-inset` |
| Count | `pixel`, bottom right, 3 in | `pixel`, `hotkey-inset` |
| Macro name | `pixel`, bottom centre, 3 up | `pixel` |
| Cooldown numbers | centred; `pixel-med` 18 on buttons of 36 and up, `pixel` below, unless the bar sets a font | `pixel-med`, `countdown-large` |

## States

| State | Look | Tokens |
| --- | --- | --- |
| Under the mouse | a white square at 15%, added over the icon (faint, so the icon stays readable) | white (`text-strong`'s value, hardcoded) at 0.15 |
| Pressed | black at 10% | `pressed-fill` |
| Checked (an active ability) | white at 30%, added | `checked-fill` |
| Flash | Buttons > Danger at 40% (times its opacity, 100% by default) | `flash-fill` |
| Equipped item | the border in the accent (Theme > Accent) | `accent` |
| Unusable | the icon darkened to 0.4 | `alpha-disabled` |
| Faded bar | the whole bar at `alpha-fade` until moused over | `alpha-fade` |

## Blizzard theme

The action ring and Blizzard's state art; an own colour (equipped) shows as `UI-HUD-ActionBar-IconFrame-Border` over the icon's edge in that colour.

## Known gaps

The states are written three times (action, totem, `st:SkinActionButton` for slots) with the same literals, and the countdown size rule three times; one icon-button state skin is proposed under Code changes. The texts copy Pixel's face at load, so a Fonts tab change doesn't reach them (Discrepancies).

## Do and don't

- Do keep text inside the button at 3 from its corner.
- Don't add a glow or a coloured fill of your own for a state; use the set above.
