# MenuItem

A small part on one line: a Show box, the part's name and Lucide's `ellipsis-vertical`, which opens a menu titled with the part's name holding the part's settings.

## When to use

The owner's rule: a part with three or more settings, or with settings that only apply sometimes, is a menu item. Texts (hotkey, stack count, macro name, cooldown numbers), icons (raid target, group role, ready check) and small parts (portrait, class power) qualify; big parts with their own colours, textures or filters (health, power, cast bar, auras) keep a tab. "Play it by ear" where a page feels crowded: Visibility's dependents or a Look section may become menus later.

## What the consumer provides

- The item: the part's Show option (a toggle, the item's box), a short `name` that fits a quarter ("Cooldown"), the menu's title if longer ("Cooldown numbers").
- An item with no Show (no box) whose names should line up with the boxed items beside it: `reserveBox = true`, which keeps the box's room empty (a bar's Cooldown).
- The menu: an option group (Font, Size, Outline, then the part's position block, last). Shared settings inside carry their own marks.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Item | a quarter cell: check box, label, menu icon; four to a line, a hairline after each but the last | `toggle-size`, `label`, `hairline` |
| Menu icon | `ellipsis-vertical` 16, `text-muted`, `accent` under the mouse | `icon-chevron`, `text-muted`, `accent` |
| Menu | about 400 wide, one column, a frame in the theme above the window, its own click catcher | `menu-width`, `strata-options` |
| Menu title | the part's name in `group-title`, `text-muted` | `group-title` |
| Menu rows | the body's rows, one column | `row-height` |

## States

- Off: the Show box empty, the label `text-muted`; the menu still opens.
- Own: the item is own-marked when its Show or anything inside its menu is a member's own (`OwnMark`); on the All page a `DiffIcon` follows the name.
- One menu at a time; it closes on Esc, a click outside, a page change and the window closing; it stays on screen near the window's right and bottom edges; a dropdown or TO list opened inside draws above it.

## Status

Specified and mocked (`actionbars-shared-v6.html`, spec decisions 4, 5, 9 and 10); the build is in the `sb-task5` worktree, not read for this system. The preview follows the spec: rows as the body draws them. The mockup's menu rows are 30 tall and the mockup's menu 330 wide for the bars, 400 for unit frames; which height and width win is an open question.

## Blizzard theme

The item's box is the Settings check box (about 12px wider than a quarter allows for "Cooldown numbers", hence "Cooldown"); the menu is drawn in the theme's panel art with flat rows.

## Do and don't

- Do put the part's position block last in its menu.
- Do keep the item's label to one or two words.
- Don't hang a menu off a setting row named for one of its settings ("Cooldown text size" holding more than size).
- Don't use `ellipsis` (horizontal) or `settings` for this; the owner chose `ellipsis-vertical`.
