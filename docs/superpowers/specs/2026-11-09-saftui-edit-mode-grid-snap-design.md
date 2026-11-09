# SaftUI edit mode: grid and snapping

Date: 2026-11-09. Status: approved in chat by the user ("all of that sounds good").

## Intent

SaftUI's edit mode (`/sui edit`, `SaftUI-Core/EditMode/`) moves frames by dragging and arrow-key nudges. Lining frames up by eye is fiddly. The user wants an alignment grid on screen while editing, and toggleable snapping to it and to other frames.

The original edit mode spec (`docs/superpowers/specs/2026-11-06-saftui-edit-mode-design.md`) planned both as footer buttons on the `/sui` window. The footer exists (`SaftUI-Core/EditMode/footer.lua`, `EM:AddFooterButton`) but has no buttons yet, and snapping was never built.

## What the user decided

- **The grid is visible, and grows outward from a clear vertical and horizontal center line.** In the user's words: "it should be a visible grid growing outwards from a clear vertical and horizontal center line".
- **Snapping to the grid is a toggle, and so is snapping to other frames.** In the user's words: "snapping is toggleable just like snapping to other frames".
- **The design below was played back to the user, who accepted it as a whole.**

## Design

### The grid

- Shows only while edit mode is active and the grid is turned on. Turning edit mode off hides it.
- Two center lines run through the middle of the screen (UIParent's center), one vertical and one horizontal. They are clearly brighter or stronger than the other lines.
- The other lines repeat outward from the center lines every **Grid size** pixels, in all four directions, to the screen edges. The grid is therefore symmetric around the center, and the center lines are always grid lines.
- One Grid size covers both directions. The default is 32px.
- Every line is 1 physical pixel thick and sits on a whole physical pixel, so nothing blurs at SaftUI's pixel-perfect scale.
- The grid draws behind the UI's frames, so frames stay readable over it. It never takes the mouse.
- It redraws when Grid size changes, and when the screen size or UI scale changes.

### Snapping

- **Snap to grid** (toggle): while a frame is dragged, its left edge, right edge or horizontal center snaps to a vertical grid line within a few pixels. Its top edge, bottom edge or vertical center does the same against horizontal lines. This works while the grid is hidden too: it uses the same lines the grid would show.
- **Snap to frames** (toggle): the same, against other edit-mode frames' edges and centers and the screen's center lines. Frames that can snap are those with a mover, other than the dragged one, while they're on screen.
- **When both are on**, the nearest candidate within reach wins, per axis.
- **Snapping only aligns.** As in the original spec, it changes the dragged frame's x/y offsets and never the frame it's anchored to, or its anchor points. Offsets stay whole physical pixels, as every drag already does.
- **Arrow-key nudges ignore snapping.** They stay 1px, or 10px with Shift.
- **Snap reach** is a few pixels: the builder picks a fixed value, around 8px. It isn't a user setting in this version.

### Controls

- **Footer buttons** on the `/sui` window while edit mode is active: **Grid**, **Snap to grid**, **Snap to frames**. Each toggles its setting, and each shows whether it's on.
- **A `/sui` section for edit mode** has the same three toggles plus **Grid size** (a slider, about 8 to 128px). Changing Grid size redraws the grid live.
- **Grid size on the footer** (*revised 2026-11-09*). After reviewing the plan, the user asked: "can we add an adjustment for the grid size as well?"
  - The footer also has **−** and **+** buttons around a label showing the current grid size.
  - Each click steps the size by 4px, within the slider's range, and redraws the grid.
  - The `/sui` slider stays.

### Settings

- **Location:** the profile, in `st.defaults.editmode`. This is where `grid` and `snap` already sit, unused.
- **Keys:** `grid` (on/off), `grid_size`, `snap_grid` and `snap_frames`.
- **Old keys:** `st.defaults.grid` (`horizontalSpacing`, `verticalSpacing`) and `editmode.snap` are removed. Nothing reads them; they were placeholders for this work.

## Constraints

- **Clients:** WoW Forever (16001, what the user plays) and retail (120000). No client-specific code is expected.
- **Taint:** SaftUI-only frames and textures. No Blizzard frame is touched, and `.agents/taint.md` applies as always. Edit mode already closes on entering combat.
- **Testing:** there's no test runner. Logic that can be checked outside the game (line positions, snap choice) should be checked in a lupa mock harness. The rest is checked in game by the user.
- **Docs:** `.agents/edit-mode.md` covers this code and is updated with it.

## Builder's calls

These came from a builder check after the user's approval. They're marked so the user can reject any of them.

- **Units.**
  - "px" means physical pixels.
  - SaftUI sets the UI scale so one UIParent unit is one physical pixel. Grid size and snap reach are therefore whole UIParent units, and every line lands on a pixel.
  - At any other effective scale, each line position is rounded to a physical pixel on its own.
- **The center.**
  - The center lines sit at UIParent's center, rounded to the nearest physical pixel. That pixel is also the "screen center" snap target.
  - Lines repeat outward from it to the screen edges. The outermost cell can be partial.
- **What's measured.**
  - Snapping uses the rects the edit mode overlays outline, for the dragged mover and for the others alike: each mover's overlay (`EM.GetRectInUI(mover.overlay)`). The overlay is parented to UIParent and anchored to the frame, so it moves by the same delta as the frame. For most movers it equals `def.frame`.
  - *Changed 2026-11-09 (final review):* the dragged rect was first taken from `def.frame`. Chat's overlay is its holder plus `padding` (10 by default), so its visible outline snapped 10 units off, more than the snap reach of 8.
  - Everything is compared in UIParent space. The snap correction is converted to the dragged frame's offset units the same way `EM:UpdateDrag` converts the cursor delta, by the ratio of effective scales. It is then rounded with `st:RoundToPixel(value, frame)`.
  - This works with any anchor point and relative frame, since an offset change moves the frame by the same amount on screen.
- **Snap targets for Snap to frames.**
  - Every other mover whose overlay is shown and on screen.
  - Not the dragged one, and not any mover whose frame is anchored to the dragged frame, directly or through other frames. Those move along with the drag, so snapping to them would jitter.
- **Ctrl turns snapping off while held during a drag,** so a frame can sit close to a line or an edge without jumping to it. Alt is already taken by the overlap picker.
- **Blizzard's Edit Mode.** SaftUI's edit mode also turns on with Blizzard's Edit Mode, and the grid shows whenever SaftUI's edit mode is on with Grid enabled. If Blizzard's own grid is on as well, both show.

## Left to the builder

- The look: line colors and alphas, and how the center lines stand out (color, alpha or both). Use SaftUI's palette (`st.config.profile.colors`).
- How a footer button shows it's on: text, color or a highlight.
- The snap reach value, and whether a snapped edge gets a brief guide line. The guide line is optional.
- Where the code lives inside `SaftUI-Core/EditMode/`, for example a new `grid.lua`.
- The name of the `/sui` section, for example "Edit mode".
