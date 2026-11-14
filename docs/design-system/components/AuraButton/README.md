# AuraButton

A buff or debuff icon in the `aura` kind, its stack count in the pixel font at its bottom right; the player's buffs carry their time left under them.

## When to use

Unit frame auras (oUF's Buffs and Debuffs elements, `elements/auras.lua`) and the player's buff and debuff frames, which SaftUI skins on Blizzard's buttons (`Skinning/blizzard/Blizzard_BuffFrame.lua`).

## What the consumer provides

Unit frames: the element's size, spacing, per row, max, growth and filter (`aurafilters.lua`), the count's font object and position. Buff frame: the Auras page's size, spacings, per row, max, grow and wrap, and the duration and count texts' font, size, outline and position.

## Sizes and tokens

| Part | Unit frame auras | Buffs and debuffs |
| --- | --- | --- |
| Icon | 24, `aura` kind | 30 (`small-button`) |
| Spacing | 7 | 5 across, 15 down (room for the duration) |
| Count | `pixel`, bottom right, 1 up | `pixel`, bottom right, 1 up |
| Time left | a countdown, off by default | `pixel`, 3 under the icon, centred |
| Border | the theme's; Thick adds its inner dark line (`ColorInnerLine`, in `border-alt`, Thick only) | debuffs by type (Blizzard's colours); a temporary enchant in `temp-enchant` |
| Tokens | `aura-size`, `aura-spacing`, `pixel` | `small-button`, `buff-spacing-x`, `buff-spacing-y`, `hotkey-inset`, `temp-enchant` |

## Blizzard theme

`Interface\Common\WhiteIconFrame` in the aura's own colour (a dispel type); Blizzard's debuff and enchant borders at 4/3 and 16/15 of the icon.

## Known gaps

The duration and count copy Pixel's face, size and outline at load (`SaftUI-Misc/config.lua:125-135`), so a Fonts tab change doesn't reach them.

## Do and don't

- Do keep the time left outside the icon, under it, clear of the border.
- Don't colour an aura's border for decoration: colour means its type.
