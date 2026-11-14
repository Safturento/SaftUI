# Decisions

Answers the owner has given to the questions and discrepancies. Each stands as a rule from its date; the pages below it (Discrepancies, Questions, Code changes) and the components are updated as the work lands, and until then this page wins where they differ.

## 2026-11-13

1. **The options window follows the theme.** Its controls' lines follow the theme's (Thin's under Thin, a recoloured Thick's under that) while fields stay dark, and the in-world close button is drawn in its window's theme. (Question 1, option C.)
2. **Panels are see-through or solid across the whole UI from one theme setting, and `/sui` follows it too.** The theme's Background carries the opacity; every panel follows it, the options window included; an individual panel can still override. (New.)
3. **A colour and its opacity are one control.** Wherever a setting has both a colour and an opacity today (two rows, or a colour beside an Alpha slider), they become one colour control whose picker sets the opacity, as the theme's Background does. (New; the pairs still to convert are listed under Code changes once audited.)
4. **One button, one size.** A single button component for `/sui` and the world, at one height and in one font; no second size. The edit mode footer's mixed sizes and fonts are the example of what this ends. (Question 2, stricter than either option.)
5. **Edit mode's controls leave `/sui`'s footer** for a bar of their own across the top of the screen while edit mode is on, with toggles for which modules' movers show. Being designed (mockup `window-and-editmode-v1.html`). (New.)
6. **The `/sui` window collapses:** its sidebar can be collapsed, and the window shrinks to a half-width, one-column size and then to a small floating bar, and grows back. Being designed (same mockup). (New.)
7. **"On" is the accent colour,** never green text. **The accent is a theme colour** the player can change, with its own swatch in the Theme section. (Question 3, option A, plus the swatch.)
8. **`/sui` tooltips stay Blizzard's tooltip frame, with the description in SaftUI's normal text colour** in place of Blizzard's gold. (Question on tooltips.)
9. **The colour control's code is one colour everywhere.** Not black or white by brightness. The control is being redrawn with the code beside the swatch on the control's own dark field (mockup, part 1). (Question on the hex code's legibility.)
10. **Resets are per setting:** a `rotate-ccw` icon beside a control whose value differs from its default; no section or page Reset buttons. Built in the kit as the `default` option field. (Was already a rule; confirmed as general.)
11. **SaftUI scales with the display:** automatic from the screen's height against 1440, with a "UI size" slider to override; borders in whole pixels. A project, after the tokens are in code. (New; see the repo's followups.)
12. **The pixel font is likely to go** in favour of a face that reads well small at any scale; candidates are being compared in game (`/suifonts`). (New; undecided which.)
