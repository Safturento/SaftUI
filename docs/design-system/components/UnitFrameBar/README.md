# UnitFrameBar

A unit frame's bar: a flat fill in the unit's class, reaction or power colour inside the theme's border, with the name at its left and the value at its right in the Normal font.

## When to use

Health, power, additional power and class power on every oUF unit frame (player, target, focus, party, raid, boss, arena, pets) and, sized down, nameplates. Cast bars and swing timers follow the same flat bar.

## What the consumer provides

The unit frame profile's element config: size (or relative to the frame), theme and background, texture (`SaftUI Flat` by default, or `SaftUI Gloss`), the colour rules in order (class, reaction, gradient, health colour, custom; the bar takes the first that fits the unit), texts with their font object key and position.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Frame | 301 x 34 by default; the frame itself is drawn None, its health bar in the theme | `unitframe-width`, `unitframe-height` |
| Health | the frame's size, `unitframe` kind (a bar under Thick and Thin), see-through at 0.9 | `backdrop`, `border`, `alpha-theme` |
| Fill | flat (`SaftUI Flat`, WHITE8X8), class colour for players, reaction colour for NPCs, `status-offline` for disconnected or tapped | `class-*`, `reaction-*`, `status-offline` |
| Deficit | the bar's backdrop shows through; an optional background is the fill colour times 0.2 (health) or 0.6 (power) | `backdrop` |
| Name | `normal` (AgencyFB Bold 16, OUTLINE), white, left, 7 in, 1 down | `normal`, `bar-text-inset` |
| Value | `normal`, white, right, 7 in, 1 down; boss frames show a percent | `normal`, `bar-text-inset` |
| Player power | its own bar, 299 x 20, value centred | `power-*` |
| Out of range | the frame at 0.4 | `alpha-out-of-range` |
| Levels | bars at 10, texts at 99 over every bar | `level-element`, `level-unit-text` |

Party and raid frames are `member` frames with names centred in Normal; a corner wedge (the `cornerbr` texture) marks the group role.

## Blizzard theme

The frame and its bars take the one Blizzard box (`unitframe`, inset 2) at any size, with Blizzard's bar fills (there is no thin-line fallback under 12px); party and raid members take a bare fill; each party and raid group sits in the same box, drawn over the members.

## Do and don't

- Do read every colour from the profile (Colors tab), so a player's class palette reaches every bar.
- Do keep texts whole-pixel: plates and frames round their layout (`UF.RoundLayout`).
- Don't add a gradient or gloss by default; the default fill is flat.
