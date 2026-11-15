# Code changes

The organisational changes that would make this system real in the addon: one place for each value, one component for each control, so the tokens here are the code's names and not a copy of its literals. None touches a `Libraries/` folder. Each says what, why, size, risk, where it falls in the order, and what it unblocks.

**Cheap and safe, do first:** 1 (the tokens table), 5 (the icon helper, not yet its sites), 9 (state names), 10 (the scale, written down), 11 (clean-ups), 12 (casing). **Projects, each its own brainstorm, spec and plan:** 3 (font roles), 4 (one button), 6 (one icon-button state skin), 8 (one scroll bar). **A design call before code:** 2, 4 and 9 (see Questions 1, 2 and 3).

## 1. One tokens table

- **What.** `SaftUI-Core/tokens.lua`, loaded after `constants.lua`, holding the colours the kit and Core own (field, edge, alt, bg, sidebar, sidebar hover, line, hairline, panel, own, diff, dot, close red), the state alphas (disabled 0.4, hover 0.25, tint 0.15, pressed 0.1, checked 0.3, flash 0.4, overlay 0.4 and 0.7) and the metrics (field 24, button 26, rows 38 and 34, pad 14, gaps 4, 6, 8, 12, icon sizes), named as this system names them. Replace `st.BOX_COLORS`, the `OB.*` colour constants, `SIDEBAR_BG`, `HOVER`, `DOT_GREY` and the literals listed under Discrepancies with reads.
- **Why.** One place to change or theme a value; this system's token names become the code's.
- **Size.** Medium: about 25 files, mostly one-line swaps.
- **Risk.** Low. Tests compare exact colours, so values must not change in the move.
- **Order.** First.
- **Unblocks.** Everything below, and keeping this system in step with the code.

## 2. Decide and wire the kit's palette

- **What.** Have `Box` resolve the theme (`st:ResolveTheme('theme', 'solid', 'small')`, as `LookLine` does, `optionslook.lua:296-308`) or keep it fixed and name it so; the same for `st:CreateCloseButton`.
- **Why.** Discrepancies 1 and 14: Thick's colours inside a Thin window; a close X that ignores its window's theme.
- **Size.** Small code, one design call (Question 1).
- **Risk.** Medium visually: every control under Thin changes.
- **Order.** After 1.
- **Unblocks.** A Thin column in this system that differs for the kit's colours; Discrepancies 1 and 14.

## 3. Font roles (the followup)

- **What.** Named roles (window title, section title, label, field, caption, small, button, hotkey, count, countdown, timer...) each resolving to a face, size and outline, with "follow" or an override per role, as Themes did for templates (`docs/followups.md:1166-1188`). Action bar and aura texts store "follow role" instead of copied faces, with a migration; one `st:CountdownFont(size)` for the three copies; `st:CreateButton` reads its role; the kit's `OB.FONTS` become roles.
- **Why.** Discrepancies 2 and 20; the owner's ask to set bag category titles in Colus without changing every Normal text.
- **Size.** A project: a brainstorm, a spec and a plan; it touches every module's config and options.
- **Risk.** Medium: saved profiles hold today's keys and copied faces.
- **Order.** After 1; independent of 2.
- **Unblocks.** This system's type styles becoming the code's roles; Discrepancies 2 and 20.
- **Taken up by** the fonts design (`docs/superpowers/specs/2026-11-14-saftui-fonts-design.md`, plan `docs/superpowers/plans/2026-11-14-saftui-fonts.md`).
- **Done, with leftovers (fonts, Tasks 1 to 8).** The roles are six shared fonts named for their jobs (Text, Small text, Large numbers, Heading, Huge title, Subtitle) and a font setting is a shared font's key or a typeface; every text reads one through `st:ApplyFont`, or through `st:FontValues` where it takes values (chat, the tooltip's lines, RestedXP, the buff timers, LibActionButton's texts), and follows its change at once (the tooltip's lines at their next Show, bars 1 to 8 a frame later), every Font row lists them (the action bars' and buffs' texts through the face-only row, keeping their saved shape), `/sui`'s own titles take Heading and its labels Text, and Button text and Check box labels reach every button and label that had them copied. Not done: the three copies of the countdown rule (the action bars' `AB:CountdownValue`, the totem bar's skin and the Cooldown Manager's) still share only `st.LARGE_COUNTDOWN_SIZE`, and the action bars' and buffs' texts still ship the copy by default. Those, a reset on every font row, a window title font per theme, the tooltip lines taking SaftUI's shadow and spacing, Title bar height beside Window titles, and search into the dots menus are followups (`docs/followups.md`, 2026-11-15).

## 4. One button component

- **What.** A Core button with two or three sizes (20, 24, 26) and both looks (the theme's and Blizzard's panel button), used by the kit's execute, the window's own buttons, `W.Confirm`, the edit mode footer, keybind mode, the loot feed and the bag header. Fold `st:CreateButton`/`st:SkinButton` into it as its in-world size.
- **Why.** Discrepancy 15 (six buttons, five heights) and one "on" look (Question 3).
- **Size.** Medium.
- **Risk.** Medium: Blizzard art per button; the edit mode footer's width math (`EditMode/footer.lua:72`).
- **Order.** After 1 and Question 2.
- **Unblocks.** `Button` in this system covering every button; a single "on".

## 5. An icon helper and an icon button

- **What.** `st:CreateIcon(parent, name, glyph, color)` applying the twice-the-glyph rule, and an icon button that requires its tooltip text; one place for the icon sizes (10px cross, 8px chevron, 16 diff, 14 reset). Move the `x`, chevron, diff and reset sites onto it. Add Lucide `funnel`, `chevrons-down`, `grip-vertical`, `square`, `layout-grid`, `grip`, `rows-3`, `eye`, `eye-off` and `mail`, and retire the hand-made TGAs and drawn glyphs (the loot feed's letters, the bag view glyphs, the drag dots, the nudge triangles).
- **Why.** The owner's icon rule everywhere, and a tooltip on every icon that replaces a word (Discrepancies 4 and 29).
- **Size.** Small for the helper; medium to replace every site.
- **Risk.** Low.
- **Order.** Any time; the helper first, sites one module at a time.
- **Unblocks.** `Icons` as the only icon source; Discrepancies 4, 29, 32.

## 6. One icon-button state skin

- **What.** A Core function for hover, pushed, checked and flash on action, totem and slot buttons, used by `ActionBars/skin.lua`, `totemskin.lua` and `st:SkinActionButton`; the countdown font rule in it once.
- **Why.** Discrepancy 11: three copies of the same literals that will drift.
- **Size.** Small to medium.
- **Risk.** Medium: secure buttons, Blizzard's state art, the totem bar's combat rules (`.agents/taint.md`).
- **Order.** After 1 (it reads the state alphas from the table).
- **Unblocks.** `ActionButton`'s states as one definition.

## 7. The bags' editors onto the kit

- **What.** Export `LookInput`, `LookCheckBox`, `Caret` and the selected-row style on `W` (as `LookDropdown` is), and have `ruleeditor.lua` and `categoriestab.lua` use them, with the kit's field height and check box.
- **Why.** Discrepancies 22 and 23: a second set of controls on one `/sui` page, and Box under the Blizzard theme.
- **Size.** One task (as the followup at `docs/followups.md:1025` frames it).
- **Risk.** Low to medium: the rule editor's own cell rects and their tests.
- **Order.** After 1; before any Categories redesign.
- **Unblocks.** The Categories tab in this system's controls and in Blizzard's art.

## 8. One scroll bar

- **What.** `OB.ScrollBar` (or a Core wrapper of it) for the select list (`optionslist.lua:176`), bags, chat and RestedXP, keeping `st:SkinScrollBar` only where Blizzard's own bar must stay.
- **Why.** Discrepancy 6.
- **Size.** Medium.
- **Risk.** Medium: chat and bags scroll Blizzard's frames.
- **Order.** After 1.
- **Unblocks.** A ScrollBar component for this system.

## 9. One state vocabulary

- **What.** Rename Buttons > Normal and Hover in the UI for what they do (keys stay), or remap them so Normal is the resting fill and Hover the hover; route every hover through it.
- **Why.** Discrepancy 3: the names don't say their roles (`colors.lua:64-65`).
- **Size.** Small code, a design call.
- **Risk.** Low.
- **Order.** With 1.
- **Unblocks.** One hover, one pressed, one on.

## 10. A spacing scale

- **What.** Write down a scale (the values in use: 2, 3, 4, 6, 8, 10, 12, 14, 16, 24, 28) with the tokens, then put the dialog paddings and close insets on it (window 28, small dialog 24, confirm 15 and 16, header 10).
- **Why.** Discrepancy 24 and Question 16.
- **Size.** Small to document; medium to apply.
- **Risk.** Low: layout tests pin numbers, so each change is visible in a test.
- **Order.** Document with 1; apply later.
- **Unblocks.** A spacing family in this system that is a scale, not a list.

## 11. Cheap clean-ups

Each a few lines and safe:
- the toggle's literal 34 (`optionstypes.lua:36`) to `OB.FLAT.rowHeight`;
- the close hover red read from `templates.close`;
- the chat prefix `|cff00adef` (`api.lua:122`) and the error `|cFFFF0000` (`:129`) read from the profile's blue and red;
- `OB.SHARE` colours read through `Colors()`;
- the float gap to the owner's 24 (`OB.FLOAT_GAP`, `optionsbody.lua:133`);
- delete the unreferenced TGAs and the 20 x 10 close path once the loot popup is decided;
- fix the bag search's multi-line flag;
- correct the stale followup paragraph (`docs/followups.md:285`);
- the Copy from dialog's labels and title (`Unitframes/config/config.lua:205-300`).

## 12. A casing pass

- **What.** Sidebar names and the Fonts tab's labels to one case, as a single wording change with the page tests' expected names.
- **Why.** Discrepancies 20 and 21; Question 7.
- **Size.** Small.
- **Risk.** Low: search and tests key on names.
- **Order.** After Question 7.
- **Unblocks.** One content rule for casing in this system, with no exceptions listed.
