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
| Under the mouse | the lighter tone of the Accent at `state-hover`, over the icon (the button's own highlight texture, BLEND, so the icon stays readable) | `state-hover`, `accent-light` |
| Pressed | the darker tone at `state-pushed`, over the icon | `state-pushed`, `accent-dark` |
| Checked (an active ability) | the `accent` edge, and the fade over the icon (the button's own checked texture) | `accent`, `state-selected` |
| Flash | Buttons > Danger at 40% (times its opacity, 100% by default) | `flash-fill` |
| Equipped item | the border in the accent (Theme > Accent): the same edge as a checked button, told apart by the fade | `accent` |
| Unusable | the icon darkened to 0.4 | `alpha-disabled` |
| Faded bar | the whole bar at `alpha-fade` until moused over | `alpha-fade` |

## Blizzard theme

The action ring and Blizzard's state art; an own colour (equipped) shows as `UI-HUD-ActionBar-IconFrame-Border` over the icon's edge in that colour.

Blizzard's template draws every piece over the icon (the ring, the equipped border, hover, pushed, checked and the flash) 46 x 45 from the top left of its 45 x 45 button. SaftUI draws each of them filling the button, cut by texture coordinates to the button's part (the left 45/46 and the whole height), so the metal reaches the button's right edge at any button size; the pieces behind the icon fill the button uncut.

## Known gaps

The states are one set of helpers' (`st:AddStates`, decision 63: action, totem, micro and slot buttons all draw them the same); the countdown size rule is still written three times. The texts copy Pixel's face at load, so a Fonts tab change doesn't reach them (Discrepancies).

## Do and don't

- Do keep text inside the button at 3 from its corner.
- Don't add a glow or a coloured fill of your own for a state; use the set above.
