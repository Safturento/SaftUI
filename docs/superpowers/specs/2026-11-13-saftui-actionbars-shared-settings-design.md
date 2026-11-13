# Action bars: shared settings, menus for small parts, growth direction

Design, 2026-11-13. Approved by the user from mockups in the session ("Looks good, lets
send it. growth direction can be baked in"). The mockups are in
`.superpowers/brainstorm/46409-1794604463/content/` (`actionbars-shared-v3.html`, part 1,
is the page this spec describes; `-v4.html`, part 2, is the unit frame idea, out of scope
here).

## Why

`/sui` → Action Bars sets almost everything per bar. A player who wants one look for the
bars sets the same font, size and spacing ten times. The user:

- "a lot of these settings in the action bar (theme, font, size, are most likely things we
  want to have a shared config across all bars, we should have an option to have those
  common settings modifiable in one place for all bars"
- "I think a single bar should be able to override, but by default they all take the same
  configs"
- "The idea of making the overrides per setting is a good idea and may actually make it
  worth extending to other settings like button count, buttons per row, size, spacing, and
  combat fade. position and enable are of course always going to be individual"
- "The cooldown numbers checkbox just being randomly placed at the top seems kind of
  weird, that checkbox should be an Enable checkbox in the Cooldown numbers section."
- On the page getting busy: "can we mock up designs for keeping this state management
  visually clean and understandable? it might get messy if we just throw it all in there."

They looked at the Ellesmere UI addon and liked two of its ideas: a hover line under a
setting's label offering "Apply to: All | Multiple", and tucking a part's lesser settings
behind a small menu. They disliked that Ellesmere's menu hangs off a row called "Cooldown
Text Size" when it holds more than size.

## What the user decided

1. **An "All bars" entry**, first in the Bar picker. A bar follows All bars for every
   shared setting until that setting is changed on the bar; it is then the bar's **own**.
   (Mockup option C.)
2. **Marks only where something differs.** On a bar, an own setting is marked blue. On
   All bars, a setting that some bar has as its own shows a **diff icon** beside its name
   (Lucide's "diff": a plus over a minus, orange), and hovering the icon shows a tooltip
   listing each differing bar and its value. The list lives in the tooltip so it can be
   long. (Option C1.)
3. **A hover line under the label**, Ellesmere's idea: the label lifts and a small line
   appears under it. On a bar's own setting: `Own · Reset · Apply to: All | Multiple`.
   On All bars, for a setting with the diff icon: `Apply to: All | Multiple`.
4. **Small parts are one-line items with a menu**: a Show box, the part's name, and three
   dots that open a menu titled with the part's name and holding its settings, including
   today's position block unchanged. All four texts sit on one line. (Options T1b/T1c.)
5. **The rule for menus:** a part with three or more settings, or with settings that only
   apply sometimes, gets a menu; "we can play it by ear on if things feel more crowded and
   need to be tucked away or left open".
6. **No tabs on a bar.** With text reduced to one line, Text and Visibility fold into the
   one page.
7. **Growth direction** is a new setting, part of this work.
8. **Enable and Position are always a bar's own.** Theme and Background are all-bars only.

## Goals

- One place to set the bars' shared look and layout; a bar can still differ, per setting.
- A page that stays plain until something differs, and then says exactly what and where.
- Nothing a player has set changes when they update: every bar looks and behaves as it
  did.
- The new page pieces (own marks and the hover line, the diff icon, the menu item) are
  parts of Core's options kit that another module can use, because the user wants the
  same on unit frames later.

## Non-goals

- Unit frames, or any page but Action Bars. (A followup; see the end.)
- Per-bar Theme or Background.
- The extra action button, zone ability and leave vehicle button: their pages don't change.
- A new position block. The menu holds the existing one.

## Anti-goals

- A bar silently changing because All bars changed a setting the bar owns, or an update
  moving or restyling a bar.
- State that can only be seen on hover. Own and "some bar differs" are always visible; the
  hover line only offers actions.
- Core's options kit knowing about action bars.

## The settings

| Setting | All bars | A bar |
| --- | --- | --- |
| Enable, Position | not shown | the bar's own, always |
| Theme, Background | set here | not shown |
| Buttons, Buttons per row, Button size, Spacing, First button (growth) | shared value | follows, or own |
| Show (visibility), Faded opacity | shared value | follows, or own |
| Each text's Show, Font, Size, Outline, Position | shared value | follows, or own |
| Cooldown numbers' Enable (Blizzard's setting) | set here | not shown |

A text's Position (the text's point, the button's point, the X and Y offsets) is one
setting: it is own or shared as a whole.

Texts are the hotkey, stack count, macro name and cooldown numbers. The pet and stance
bars have only the hotkey and cooldown numbers, as today; their pages show only those two.

**Cooldown numbers.** The Enable box is Blizzard's "Show Numbers for Cooldowns"
(`countdownForCooldowns`), read and set as today, never saved in the profile. It is the
Show box of the Cooldown numbers item on All bars. On a bar the item has no Show box, and
its tooltip says the numbers are turned on for every bar on All bars. The numbers' font,
size and outline stay unset by default, meaning "Pixel Med on buttons of 36px and up,
Pixel below" per bar as today; the menu's Reset puts them back to unset (and the position
back to the middle), on All bars for the shared value and on a bar for its own.

**Growth direction** ("First button"): which corner of the bar button 1 sits in: Top left
(today's behaviour and the default), Top right, Bottom left, Bottom right. Rows still fill
across, `Buttons per row` at a time, away from that corner; the next row goes away from
that corner too. The bar's frame, size and position don't change with it. A bar of one
row with Top right runs right to left; a column with Bottom left runs upward.

## How shared and own behave

- **Changing a setting on All bars** changes it for every bar that follows it. Bars that
  own that setting keep theirs.
- **Changing a shared setting on a bar** makes it the bar's own, from that change on.
- **Reset** (on a bar's own setting) makes the bar follow All bars again: the control
  shows All bars' value. (Builder's call: the bar's old own value needn't come back.)
- **Apply to: All** on a bar: All bars takes this bar's value, and every bar follows it
  (no bar owns the setting any more).
- **Apply to: Multiple** on a bar: a check list of the other bars; the chosen bars get
  this value as their own (or, when the value equals All bars', simply follow).
- **Apply to: All** on All bars: every bar follows All bars for that setting.
- **Apply to: Multiple** on All bars: the chosen bars follow All bars for that setting.
- A value a bar can't take is clamped as today (the pet and stance bars have 10 buttons;
  All bars' Buttons goes to 12). The check list leaves out bars a setting doesn't exist on
  (stack count and macro name on the pet and stance bars).
- Every change applies at once through the existing update path (`AB:UpdateBar`,
  `AB:UpdateConfig`), which already waits for the end of combat.

**What ships as a bar's own by default**, so a new profile looks as it does today: Buttons
per row on bars 4 to 8 (1, a column) and Button size on the pet and stance bars (30). All
bars' defaults are today's bar 1: 12 buttons, 12 per row, size 45, spacing 3, Always
shown, faded opacity 30%, first button Top left, and today's text defaults.

**Existing profiles.** On first load after the update, each profile is converted once:
All bars takes bar 1's values (what bar 1 shows today, set or default), and every other
bar owns exactly the settings where it differs from that. Nothing on screen changes. A
bar's Theme and Background were already shared. The conversion must be safe to meet a
profile twice, and must also run for a profile switched to or imported later.

## The page

`/sui` → Action Bars. The Bar picker lists All bars, then Bar 1 to 8, Pet, Stance, then
the extra buttons as today. All bars and each bar are one page with no tabs. Sections, in
order:

**All bars**
- **Look:** Theme, Background (two plain rows: under three settings).
- **Layout:** Buttons, Buttons per row, Button size, Spacing, First button.
- **Visibility:** Show; Faded opacity, shown only for "Faded until moused over" as today.
- **Text:** the four items on one line: Hotkey, Stack count, Macro name, Cooldown numbers.

**A bar**
- **This bar:** Enable.
- **Layout, Visibility, Text:** as on All bars, showing what the bar has (its own value,
  or All bars').
- **Position:** the bar's position option, last, as on every SaftUI page.

The page above the picker loses its loose Theme, Background and Cooldown numbers rows.
Clicking a bar in edit mode opens that bar's page.

**A text's menu** holds Font, Size, Outline, then the position block, then (cooldown
numbers only) Reset. Inside the menu, each setting carries the same own mark and hover
line as a row on the page.

**Marks**
- An own row: a 2px blue bar at its left edge and its label in light blue. An item (a
  text) is own-marked when any setting inside it is own.
- The diff icon: orange, after the label, on All bars only, always visible. Its tooltip is
  the setting's name, "All bars: value", then a line per differing bar. For an item it
  lists each differing bar with the names of the settings that differ ("Bar 3: Size,
  Position").
- The hover line appears only on rows that have something to offer (own rows on a bar,
  diff rows on All bars), so a plain row doesn't move under the mouse.

## What's left to the builder

- **How own is stored.** It has to survive AceDB's defaults: a value that equals a default
  isn't saved, and a default can't be set to nil. A workable shape (the builder's to
  confirm or better): each bar keeps its values as today, All bars' values live in
  `actionbars.all`, and each bar has a table of own flags (defaulting true for the shipped
  overrides above). The effective value is the bar's when the flag is set, else All bars'.
  Every reader of a bar's config (`bars.lua`, `skin.lua`, `buttons.lua`, `bindings.lua`,
  the pet and stance bars) must read the effective value, through one function.
- **The kit pieces, in Core, generic:** an option says it is shareable through SaftUI-only
  fields (is it own, reset it, who differs and with what, who it can be applied to, apply
  it); the kit draws the mark, the hover line, the diff icon and tooltip, and the Multiple
  check list (`W.OpenCheckList` exists). A menu item is an option type or field that draws
  Show box, name and dots and opens a small menu drawn from an option group, position
  block included. New fields go in `SAFTUI_FIELDS` and `.agents/edit-mode.md`.
- **The diff icon** is three lines, so it can be drawn from plain textures; no image file
  is needed.
- **The menu:** closes on Escape, a click outside, a page change and the window closing;
  only one is open at a time; a dropdown's list or the position block's TO list opened
  inside it draws above it and isn't cut off by it; it stays on screen near the window's
  right and bottom edges. Both looks (Thick/Thin and Blizzard).
- **Search:** a setting inside a menu is found by search, and its result opens the page
  and the menu (or at least the page with the item in view; say which).
- Tooltips, wording, exact sizes and spacing, within the kit's existing style.

## Risks to check

- The game calls `OnEnter`/`OnLeave` with a second argument; a tooltip helper bound
  straight as a script took it for an owner earlier today (b4e218c). Tests fire hover
  scripts as the game does.
- The bars are secure frames: nothing new may run a layout in combat. `/sui` can't be open
  in combat, and the update path already defers; a profile switch in combat must still
  wait (`AB:UpdateConfig`).
- Blizzard's cooldown setting is read live; All bars' Show box must follow a change made
  in Blizzard's own options while `/sui` is open, as today's box does.
- Reversed growth must keep whole-pixel placement and the bar's size; the edit mode
  outline covers the same rectangle.
- The flyout direction (`skin.lua`) depends on `perrow`; it must read the effective value.

## Later (not this work)

- **Unit frames.** The same own/shared model across units, and texts, icons and small
  parts as menu items on a unit's General page, cutting about thirteen tabs to five. The
  unit frame position block's TO part fits a 400 wide menu (the block is 351 wide today).
  The user: "the unitframe change is great". To be planned after the bars prove the
  pattern.
- Using a menu for Visibility's dependents or the Look settings, if the page feels crowded
  in use.
