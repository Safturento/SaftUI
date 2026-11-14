# SaftUI's own color picker, and a skin for Blizzard's

## Why

The owner's in-game pass (2026-11-13): "I'd also like to skin the color picker and enhance it with opacity and rgb values." Three pickers were drawn (`colour-picker-options.html` on the mockup server: P1 Blizzard's frame skinned, P2 the same with number boxes, P3 a picker of SaftUI's own). The owner chose P3 and asked for Blizzard's to be skinned too: "That third color picker is awesome, I'm okay with the additional work so lets do it. Lets also skin the blizzard color picker anyways just to make it look nice".

## Goals

- `/sui`'s color fields open SaftUI's picker, never Blizzard's.
- The picker shows what Blizzard's lacks: number boxes for red, green and blue, a number for opacity, a hex box, class colors and the last colors used.
- Blizzard's `ColorPickerFrame`, which every other addon still opens, wears SaftUI's look.

## Non-goals

- Replacing Blizzard's picker for other addons (no hook that redirects `ColorPickerFrame`).
- Gradients, named palettes, an eyedropper.

## Anti-goals

- Writing a Lua field onto `ColorPickerFrame`, or changing how it behaves. The skin only changes how it looks.
- A picker that sits on half pixels, or that works on one client only.

## Part one: SaftUI's picker (Core's options kit)

**Where.** A new file `SaftUI-Core/Config/optionscolorpicker.lua`, loaded after `optionstypes.lua`'s needs (the builder places it in `load.xml` and `tests/lib/shell.lua`). The `color` type's `Pick` calls it in place of `OpenPicker`; `OpenPicker` and its `ColorPickerFrame` calls go from `optionstypes.lua`, and so does every other read of `ColorPickerFrame` in `SaftUI-Core/Config/` that existed only for this (the window's `ColorPickerShown` guard then asks the kit's picker).

**The interface.** `W.OpenColorPicker(owner, spec)`; `spec = { r, g, b, a, hasAlpha, onChange = function(r, g, b, a), onCancel = function() }`. `W.CloseColorPicker()`; `W.ColorPickerShown()`. One picker frame, reused. Opening it for another field while it is open cancels nothing: it accepts the first (as Okay) and opens on the second.

**What it draws** (P3 of the mockup, in the kit's own parts: a Thick/Thin/Blizzard panel as the kit's dialogs are, `W.Button`, the kit's input boxes, Text > Grey captions):

- Title "Color".
- A 170 by 170 square for shade: saturation left to right, brightness bottom to top, of the current hue. A thumb marks the place. Click or drag sets it.
- A vertical strip for hue, 16 wide and as tall as the square, and beside it one for opacity (only when `hasAlpha`; without it the strip is not drawn and the panel is narrower by its width and gap). Opacity's strip shows the color over the kit's checker, solid at the top.
- Captions under them: "Shade", "Hue", "Opacity".
- To the right, a column 150 wide: two halves side by side, "New" (the color being chosen) and "Was" (the color it opened with); a click on "Was" goes back to it. Under them, number boxes: Red, Green, Blue (0 to 255, whole numbers), Opacity (0 to 100, with a % sign, only when `hasAlpha`), and Hex (six hex digits, with or without a leading #; eight digits set the opacity too when `hasAlpha`). A box takes its value on Enter or on losing the keyboard; a value out of range is clamped; text that isn't a number puts the old value back. Tab moves through the boxes in order.
- Under the body, "Class colors": one chip per class the client has, in SaftUI's class colors (the Colors page's), each with the class's name as its tooltip. Then "Last used": up to 12 chips, newest first; an empty row shows nothing but its caption.
- Okay and Cancel at the bottom right, Okay first.

**How it behaves.**

- Every change is live: `onChange` runs as the square, a strip, a box or a chip changes the color, as Blizzard's picker does today, so the page shows it at once.
- Okay closes it and adds the color to "Last used" (moved to the front if it is already there; compared by its six-digit code and opacity). Cancel, Escape, and closing `/sui` put the opening color back through `onChange`, then `onCancel`, and add nothing. A click outside the picker does nothing (the window behind stays usable; clicking another color field accepts and reopens, as above).
- "Last used" is saved account-wide in `st.config.global.colorPicker.recent` (a list of `{ r, g, b, a }`).
- A hue is kept while the color is grey or black (saturation or brightness at 0), so the thumb and the hue strip don't jump when the shade is dragged through a corner. The picker holds hue, saturation and brightness as its own state and derives red, green and blue from them; typed red, green, blue or hex set them back.
- It opens beside the field that opened it: its top left at the field's top right, 8 apart; flipped to the field's left, or shifted up, when it would leave the screen. Strata and level above the options window, as menus are.
- It hides in combat with the window, as a Cancel.
- Whole pixels everywhere: even sizes, placed by top-left, thumbs on whole pixels, a `tests/lib/pixels.lua` check under Thick, Thin and Blizzard with size noise.

**Builder's calls.** How the square and strips are drawn (gradient textures: a hue-colored base under a white-to-clear horizontal gradient and a clear-to-black vertical one; the hue strip as six gradient segments; `Texture:SetGradient` with `CreateColor` on both clients). The thumb's art. Whether the number boxes are the kit's small input or a narrower one.

## Part two: Blizzard's picker, skinned (Misc's Skinning)

A new file `SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua`, registered with the Skinning module like its neighbours, with its toggle on the Skinning page.

- `ColorPickerFrame` gets SaftUI's panel in place of its border and header art, its Okay and Cancel buttons the kit's button look, its hex box the kit's input look, and its title SaftUI's title font. Under the Blizzard theme it is left as Blizzard draws it.
- Only looks: textures hidden with `SetAlpha(0)` or `Hide` on regions, backdrops on SaftUI's own child frames, fonts and colors set. No field written onto the frame, no script replaced, no size or point of Blizzard's controls changed beyond what the skin needs to sit its panel; nothing in combat. `.agents/taint.md` is read first. The picker is not a secure frame, but other addons drive it, so its behaviour must be untouched.
- Both clients: the frame's parts are read from Gethe/wow-ui-source (`Blizzard_ColorPickerFrame`), and every part is nil-guarded, so a missing region skips its step.

## What's left to the builder

Names of locals, the exact layout numbers inside the 150 column, the tests' structure. The in-game checklist each task ends with.

## Calls made while writing this (the controller's, for the owner to check)

1. Changes are live and Cancel restores, as today; Okay is what records a color under "Last used".
2. Twelve "Last used" colors, saved account-wide.
3. Class colors are SaftUI's (the Colors page's), not the game's defaults.
4. A click outside the picker does not close it.
5. The title reads "Color", following the decision that text spells it that way.
