# BagSlot

An item slot in a bag, bank or combined bank window: the item's icon in the `slot` kind, its border in the item's quality colour, its stack count and item level in the pixel font.

## When to use

Every item and currency slot SaftUI's bags draw, skinned with `st:SkinActionButton` and the Bags' Slot theme (`buttontheme`, `buttonbackground`). Laid out by category, each under its title in the bag window.

## What the consumer provides

The slot's item info (quality, count, class, item level, bound state, bag), read when the bag updates; never build slots in combat for a new category.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Slot | 60 wide x 50 tall (the height is `inventory.iconsize`, the width 6:5 to it), 3 apart; windows padded 10; category titles 50 tall in `normal` | `slot-width`, `slot-height`, `button-spacing`, `frame-padding` |
| Border | the item's quality colour (every quality, Poor to Heirloom); black for no quality; the Slot theme's border on a free slot | `quality-*`, `border` |
| Count | `pixel`, bottom right, 4 in | `pixel` |
| Item level (armour and weapons) | `pixel` beside the count, on a black 80% backing to the icon's corner; `text-strong`, `text-success` if bind on equip, `text-shared` if warbound | `ilvl-backing`, `text-strong`, `text-success`, `text-shared` |
| Auto-vendor item | Blizzard's junk coin (`bags-junkcoin`) at the icon's top left | |
| Reagent bag | a 14px `text-success` wedge in the icon's top right (the `cornerbr` texture, flipped) | `reagent-wedge`, `text-success` |
| States | hover, pressed and disabled as `ActionButton`'s (`st:SkinActionButton`) | `accent`, `pressed-fill` |

## Blizzard theme

The slot ring art; the quality colour shows as `Interface\Common\WhiteIconFrame` over the icon's edge; a free slot has no border.

## Do and don't

- Do colour borders through `INV:QualityBorderColor` (`st:QualityColor`), so the profile's quality colours apply.
- Do keep markers in their corners: count and item level bottom right, the coin top left, the wedge top right, clear of the crafting quality pip.
- Don't put text over the middle of the icon.
