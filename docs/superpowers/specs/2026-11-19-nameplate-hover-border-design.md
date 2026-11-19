# Nameplate hover border

Status: agreed 19 Nov 2026, built on branch np-hover-border.

## Goal

When the cursor is over a nameplate, colour that plate's border so it's clear which unit a click will target.

## Behaviour

- **Thick and Thin themes:** the hovered plate's border line turns the hover colour. Both colours are options: Target color (white by default, today's look) and Hover color (light blue by default). If the target is also hovered it keeps the target colour, since clicking it changes nothing.
- **Blizzard theme:** the box keeps its colour. Blizzard's target art (`nameplatetarget`) is drawn round the hovered plate's bar too, tinted by Hover color. White leaves the art as Blizzard draws it; any other colour desaturates the atlas first (Forever's is yellow) and tints it. Target color tints the target's art the same way.
- **None, and name-only plates:** nothing is drawn, the same as the target border.

## How it works

- Hover is found by the plate's frame: `C_NamePlate.GetNamePlateForUnit('mouseover')`. It is never found with UnitIsUnit, which can return a secret value. This matches how target.lua finds the target.
- `UPDATE_MOUSEOVER_UNIT` fires when the cursor enters a unit. Nothing fires when it leaves, so while a plate is hovered, a C_Timer ticker checks every 0.05 s whether the mouseover plate is still the same, and is cancelled once nothing is hovered.
- Each plate reads the config it's drawn from (frame.base_unit), so Enemy and Friendly nameplates each have their own colours.
- This lives in target.lua, next to the target border. `UF:UpdatePlateTarget` becomes the one place that picks a plate's border state (target, hover or plain), so recolours and redraws through `RecolorBorder` keep working.

## Options

On both the Enemy and the Friendly nameplates pages' General tab:
- Target color, white by default;
- Highlight on hover, on by default;
- Hover color, light blue (0.4, 0.7, 1) by default, disabled while Highlight on hover is off.

## Tests

- Hovering a plate colours its border and leaving clears it.
- The target and the hovered plate are the same plate.
- Hover moves straight from one plate to another.
- A theme redraw while hovered keeps the colour.
- The option is off.
- Blizzard theme shows and hides the art.
- The tests need a `mouseover` unit in the stubs.

## In-game check

A new check goes on Test Rounds: hover a few plates under each theme, including the current target, and confirm the highlight follows the cursor and clears when it leaves.

## Decisions (the user, 19 Nov)

- Colour choices for both the target and the hover, in the nameplate config.
- A hovered target isn't highlighted: it keeps the target's look.
- Friendly plates get the same options.
