# Questions for the owner

Four questions are left. Each was asked too tersely the first time, so each is restated here in plain words, and drawn side by side in the mockup tab (`open-questions-v1.html`). Everything else that was on this page has been answered and moved to Decisions.

## 1. The slider's knob

Every slider in `/sui` (Spacing, Alpha, Size and so on) has a track and a knob. Two drawings exist.

- **A.** What the game draws today: the knob is the light text colour, and the track behind it fills with blue up to the knob, so the blue shows how far along the value is.
- **B.** What the action bars mockup happened to draw: only the knob is blue, and the track stays dark.

Recommendation: **A**. The fill shows the value at a glance, and the mockup's version was a side effect of a drawing about something else.

## 2. Rows inside a text's menu

On the new Action Bars page, the three dots on a text (Hotkey, Stack count, Macro name, Cooldown) open a small menu with Font, Size, Outline and Position. The page's own rows are 38 tall.

- **A.** Menu rows are 38 tall too and the menu is 400 wide. This is what is built. There is room for the blue "own" mark and the hover line under a label, and it lines up with the page.
- **B.** Menu rows are 30 tall and the menu is 330 wide. Smaller, but the hover line under a label no longer fits inside a row.

Recommendation: **A**.

## 3. Grey and red text under the Thin theme

Thin's panels are a lighter grey than Thick's. Grey text (section titles, notes) and red text (errors) therefore stand out less on them than they should: both fall a little short of the usual legibility bar.

- **A.** Leave it: Thin is a look the player chose.
- **B.** Change Thin's default colours (a darker panel, or a lighter grey and red).
- **C.** Make sure small grey and red text always sits on a darker section panel under Thin. The new section backgrounds already do this for most pages.

Recommendation: **C**. It costs nothing and changes no colour.

## 4. How strong a hover or selection tint is

A hovered or selected row gets a see-through blue tint. Today the strength differs by where you are: dropdown lists and the sidebar use 25%; the bags' category list uses 10% for hover and 15% for the selected row; a selected mover in edit mode uses 15%.

- **A.** Two strengths, by meaning: 25% for any hovered or selected row, everywhere; 15% only for a selected object's fill, such as a mover, where a stronger tint would hide what is under it.
- **B.** Leave each as it is.

Recommendation: **A**.
