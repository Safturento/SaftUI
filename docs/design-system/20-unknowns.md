# Questions for the owner

Choices the code doesn't settle: two candidates for one standard, or a value with no stated reason. Each has the options and a recommendation. Until one is answered, this system documents what the code does.

## 1. Do the options window's controls follow the theme?

The kit's Box (`kit-field`, `kit-edge`, `kit-alt`, `kit-bg`) is Thick's default palette frozen into constants: under Thin, and under a recoloured Thick, the window changes and the controls don't. The close button on every in-world window uses the same frozen palette.
- **A.** Keep it fixed, and call it the options palette on purpose (rename `st.BOX_COLORS`, document that `/sui` and the close X look the same in every theme).
- **B.** Follow the theme fully: `Box` resolves the theme (as `LookLine` already does, `optionslook.lua:296-308`), so Thin's controls are #333333 inside a black line.
- **C.** Follow the theme's lines, keep a dark field: edges take the theme's `border` (and Thick's outer line), fields keep `kit-field`, so inputs still read as wells under Thin.

Recommendation: **C** for the kit, and the close button drawn in its window's theme. It keeps fields legible in both themes and ends the Thick-inside-Thin mismatch.

## 2. What is the standard in-world button?

Core's `st:CreateButton`/`st:SkinButton` (drawn `control` in the theme, Pixel 10, Buttons colours for its states) and the kit's Box button (`field` 15, `accent` edge on hover) sit side by side in the edit mode footer, at 22 and 26 tall.
- **A.** One button component with a `/sui` size (26, `field`) and an in-world size (22, Pixel), both drawn in the theme, both with the kit's states.
- **B.** Keep two families: kit buttons in `/sui`, Core buttons in the world, and move the edit mode footer to kit buttons.

Recommendation: **A** (Code changes 4). The in-world size keeps the pixel font where text is small.

## 3. What does "on" look like?

`accent` (the kit's check mark, the bag view button's lit border, a chosen roll) or green text (the edit mode footer's Grid and Snap toggles).
- **A.** Accent everywhere: a toggle button that is on takes an `accent` edge and `text` label.
- **B.** Keep green text for footer toggles only.

Recommendation: **A**. Green is never used for "on" elsewhere, and accent is SaftUI's one active colour.

## 4. The range knob's colour

The code (and the 11-09 mockup) draws a `text` knob over an `accent` fill; the approved v6 mockup drew an `accent` knob with no fill.
- **A.** Keep the code's: the fill shows the value at a glance.
- **B.** The v6 knob.

Recommendation: **A**; v6's change looks incidental to what that mockup was deciding (shared settings).

## 5. The close X's size

Code: a 24 box with a 10px cross. v6: a 20 box with a 12px cross on the window's fill.
- **A.** Keep 24 / 10 (also the 11-09 mockup's).
- **B.** 20 / 12.

Recommendation: **A**, which also matches the header's 23-tall buttons better.

## 6. A menu's row height and width

v6 drew menu rows 30 tall in a 330-wide menu for the bars and 400 for unit frames; the spec says about 400 and the body's rows are 38.
- **A.** The body's rows (38, with marks and hover lines) in a 400-wide menu.
- **B.** Denser 30 rows in menus only.

Recommendation: **A**: the hover line needs the 38 row's height, and one row metric keeps marks aligned.

## 7. Sidebar page names: which case?

"Action Bars", "Micro Menu", "Totem Bar", "Swing Timer", "Global Settings" are Title Case; "Unitframes" is one word; nameplate pages and every option are sentence case; descs say "unit frames".
- **A.** Sentence case everywhere: "Action bars", "Unit frames", "Global settings".
- **B.** Title Case for page names only, and "Unit Frames" as two words.

Recommendation: **A**, matching every option name and desc. Page titles in Colus read as capitals either way.

## 8. Spelling in the docs

The UI and code say "color"; the docs mix (README 5 "colour" to 22 "color"; followups 21 to 163); this system's prose follows the owner's "colour".
- **A.** "color" everywhere, docs included.
- **B.** "colour" in docs and comments, "color" in UI strings and identifiers.

Recommendation: **A**: one spelling makes the docs searchable alongside the code. Either way, fix the one UI desc that says "colour" (`totemoptions.lua:21`).

## 9. What do `/sui` tooltips look like?

The code uses GameTooltip as Misc's skin leaves it: SaftUI's frame and the Normal font, the title white, the desc in Blizzard's gold (the kit passes no colour). v6 drew its own: a #101010 box, a white title, a grey source line, `text` for the rest.
- **A.** Keep GameTooltip in SaftUI's frame, and pass `text` for the desc so it stops being Blizzard's gold.
- **B.** A kit tooltip as v6 drew it.
- **C.** Leave it as it is.

Recommendation: **A**: one tooltip in and out of `/sui`, in SaftUI's colours.

## 10. The item tooltip's fonts

Misc's skin sets the Normal font on every line of GameTooltip, ItemRefTooltip and the shopping tooltips (`tooltip.lua:46-58,113-115,175-179`); the screenshot notes read the item lines as Blizzard's. Is Blizzard's look intended on item tooltips?
- **A.** Normal on every line (what the code means to do; check in game why it may not).
- **B.** Blizzard's fonts and colours on item lines, SaftUI's frame only.

Recommendation: **A**, after an in-game check of the compare tooltips.

## 11. The colour bar's code on light colours

Always white with the outline (code), which is hard to read on #E6E6CC, white and grey fills.
- **A.** Keep white with the outline.
- **B.** Black or white by the fill's brightness, whichever contrasts more (what an old followup said it did).
- **C.** White on a dark backing behind the text.

Recommendation: **B**, using `text-outline` (black) where white falls under 3:1.

## 12. Thin's grey and red text

Under Thin, `text-grey` and `text-red` miss 4.5:1 on `backdrop` (4.3:1, 3.6:1).
- **A.** Accept it (Thin is a look choice).
- **B.** A darker default for Thin's backdrop, or a lighter grey and red.
- **C.** Keep small grey text on panels under Thin.

Recommendation: decide with question 1; **C** costs nothing and fixes section notes and titles' readability.

## 13. Section-level resets that remain

The owner's rule is per-setting reset. Two resets don't map to one setting: the cooldown numbers' menu Reset (the spec kept it: it resets font, size, outline and position together) and Categories' "Reset all" (the whole list).
- **A.** Replace both with per-setting icons (Categories' "Reset to default" too), keeping "Reset all" as a confirm-guarded action.
- **B.** Keep both as buttons as exceptions.

Recommendation: **A**.

## 14. Hover fills

0.25 (kit rows, sidebar) or 0.1 and 0.15 (Categories, rule editor, movers).
Recommendation: `accent-fill` (0.25) for a hovered or selected row; `accent-tint` (0.15) only for a selected object's fill (a mover).

## 15. Under the Blizzard theme

Should the rule editor's AND/OR keep blue and orange (`docs/followups.md:1027`), and own and diff keep SaftUI's colours (they do, `.agents/edit-mode.md`)?
Recommendation: yes to both: they carry meaning Blizzard's art has no colour for.

## 16. Values with no stated reason

- `TABS_TOP` 87, `BRAND_HEIGHT` 73, `HEAD_TOP` 20: measured from the 11-09 mockup.
- The small dialog's 24 padding against the window's 28.
- The rule editor's 26 rows and 22 fields, Categories' 22 rows, against 24 fields and 38 rows: density, or drift?
- In-world gaps 3, 5 x 15, 7, 8, 10, 12, with no scale written down.
- `pixel_huge` and `normal_med` have no reader.
- `cornerbr` is the resize grip, the group role wedge and the reagent wedge: one shape on purpose?

Recommendation: write a spacing scale (2, 3, 4, 6, 8, 10, 12, 14, 16, 24, 28) and say which of these are on it; keep the measured window values as they are.

## 17. Overlapping mover labels

In edit mode, labels pile up where movers overlap (bars 4 to 8, the extra buttons).
- **A.** Leave it to the picker list.
- **B.** Hide every overlapping mover's label but the one under the mouse.

Recommendation: **B**, if it can be done without moving frames.
