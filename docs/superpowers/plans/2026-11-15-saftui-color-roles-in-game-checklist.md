# Color roles: in-game checklist

> **Revised 2026-11-15:** its reload steps (the line under the title, step 3 of section 4, step 4 of section 5 on Damage and Muted, and the reload in section 6) now show at once: every color follows a pick as it is made. They are checked by the live colors plan's checklist, `2026-11-15-saftui-live-colors-in-game-checklist.md`. Read each "reload" below as "at once".

One pass for the whole color roles plan (`2026-11-14-saftui-color-roles.md`, Tasks 1 to 5), in the order you would play it. Do it on both clients (WoW Forever, interface 16001, and retail, interface 120000) unless an item says one. Everything is at SaftUI's defaults unless it says "customized". Nothing here needs a character, realm or account name.

Reload (`/reload`) after you change a color, where an item says so: most of SaftUI reads a color when it builds its frames, as the Colors page's note says.

## 1. What changes on screen at upgrade

On a profile that never changed a color, these are the only visible changes. Everything else must look exactly as before; if something else moved, that is a bug.

1. **The chat prefix** is `#00adf0` where it was `#00adef`: one step lighter in the last digit, invisible.
2. **The Error prefix** in chat (the word Error before a SaftUI error) is the soft red `#dc6464` where it was a pure red; DEBUG was that red already. Run `/sui debug` and trigger an error, or read any SaftUI error line.
3. **The two lighter greys:** the combined bank's eye toggle and edit mode's "Alt: next" line (in the picker under the cursor where frames overlap) were `#969696` and are `#b4b4b4`, the Muted default. They look a little lighter. (Controller's ruling, see section 8.)
4. **The diff icon and the bag category's marker are Muted grey.** The diff icon beside a setting that differs on a shared page (All bars against a bar), and the `edited` and `yours` markers in Bags > Categories, were orange.
5. **An equipped item's border on an action button is the accent** (blue by default) where it was green.
6. **AND rails and the other accent uses are the same blue as before** at the default accent: the bag rule editor's AND line, connectors and badge, "Category: <name>" in a bag item's tooltip, the bags' loading bar, the loot roll timer bars, an own mark (the icon), links, the tab underline, a selected mover. The accent is the same `0, 0.68, 0.94` the blues were. The OR groups and the Caught now highlight stay orange (Warning).
7. **Own labels and titles are the accent.** The own label, an own section title, the hover line's Own and the diff tooltip's per-page values on shared pages (All bars against a bar) were a light blue `#8fd8ff`. They are now the accent `#00adf0`, drawn at `OB.OWN_STRENGTH` (1). **This one is yours to judge:** if they look too strong or too like ordinary accent text, say so, and it is one number (spec call 17, "play with individual opacity for those highlights").
8. **Buttons are drawn at their opacity, which now defaults to 100%.** Nothing changes at the defaults: every reader draws the alpha it drew before. The Colors page's four Buttons fields now show no percent (they showed 60% and 80%). (Section 6.)

## 2. What a customized profile sees after the migration

**What you can still see.** Your profiles have already been through steps 1 to 4 (the builds with Tasks 1 to 4 migrated them at login), so items 1 to 5 below are done for them and can't be seen again. What is still to come on such a profile is item 6 (step 5, the opacities). To see items 1 to 5 happen, restore a copy of the SavedVariables file from before Task 1 merged (WoW keeps `SaftUI.lua.bak` beside it) as a spare profile, or copy an old profile into a spare folder, log in on it, and look at the Colors page. Either way: no Lua error.

1. **Text > Red** (customized) now colors Pass, Damage, Horde and Danger, all the same new color; each is its own color from here on (change one on the Colors page and the others stay).
2. **Text > White, Orange, Yellow, Green, Cyan** (customized) are now Strong, Warning, Caution, Success and Shared; Yellow also fed Greed and Neutral, Green fed Healer, White fed Need, Purple became Transmog, Buttons > Yellow became Mount, Blue became Tank and Alliance.
3. **Buttons > Blue** (customized) is now the Theme tab's Accent. Text > Blue is not the accent: it went to Tank and Alliance.
4. **Text > Grey** (customized) is now Muted. A **customized Buttons > Grey and Buttons > Green are dropped**: Muted and the accent stay at their defaults.
5. **Buttons > Red** (customized) is now Buttons > Danger, with its color and no opacity of its own.
6. **Every saved Buttons opacity went back to 100% once** (Normal, Hover, Pushed, Danger): none was ever drawn before, so a slider left at 30% did nothing. Their colors are kept. An opacity you choose after this stays.
7. **A profile you create after the upgrade** has every Buttons color at 100%.
8. Switch to, copy from and reset a profile that has not been used since: each carries its colors the same way. For a switch in combat (`/sui` can't open in combat), make two macros, `/run SaftUI.config:SetProfile("Two")` and `/run SaftUI.config:SetProfile("Old")` (your profile names), and press one in combat: no `ADDON_ACTION_BLOCKED`, and the accent follows when combat ends.
9. **A customized color now reaches readers that were hardcoded before.** A customized Text > White also colors the share line under the mouse, roll timers over a minute, and the tracker's percent and chevron. A customized Buttons > Blue also colors the own labels, the chat prefix, the equipped border, "Category:", selected rows and links. A customized Text > Red also colors the Error prefix. This is by design (spec calls 3, 8 and 18), not a bug.

## 3. Global settings > Colors

1. The Colors page has twelve sections in this order: Text, Buttons, Class, Roles, Reputation, Factions, Power, Item quality, Loot, Status, Threat, Objectives. Text has Text, Muted, Strong, Danger, Warning, Caution, Success, Shared. Buttons has Normal, Hover, Pushed, Danger. No Blue, no Grey, no Green, no Purple, no hue names.
2. Hover each new color: its description says what it colors, never a hue.
3. Buttons' note ends "Opacity sets how strongly each is drawn: 100% is SaftUI's own." Each Buttons swatch has an opacity in the picker; at 100% the field shows no percent, below it shows `· NN%`.
4. Each color that differs has its own reset arrow by its field; there is no section Reset.
5. Switch profiles and back: the colors follow.

## 4. Global settings > Theme: the Accent

1. Accent sits between Background and Options windows, with Window titles after it. It has no opacity, and its reset arrow shows only while it differs and puts `#00adf0` back.
2. Change it. At once: the `/sui` sidebar bar, tab underline, sliders (reopen a page), check marks, picked list entries, the edit mode bar and a selected mover, the tracker's focus bar and hover (turn the tracker on), a held roll's border and label, the bags' lit view buttons and the loot feed's lit buttons.
3. After a reload: bag and totem hover, an equipped item's border, and the bag and roll timer bars on the next open or roll.
4. Roles > Tank and Factions > Alliance stay put when the accent changes.
5. "Category: <name>" in a bag item's tooltip, the rule editor's AND (OR stays orange), the bags' loading bar and the roll timer bars follow the accent.
6. Swap profiles in combat with the macros from section 2.8: no `ADDON_ACTION_BLOCKED`.
7. Own labels, titles and the diff tooltip's values on a shared page (All bars) follow the accent when the page draws again.

## 5. Roles, Factions, Loot, Muted and the state colors

Roles, Factions and Loot (Task 1):
1. Roll letters and counts, the feed's roll tooltip and a mount entry look as before.
2. Zone text in a friendly, a hostile and a contested zone as before; change Factions and a shown line recolors.
3. Role corners in a group and in test mode as before.
4. Change Pass, Horde and Damage on the Colors page: each moves alone (Damage after a reload). Text > Danger still colors errors.

Muted (Task 3):
1. `/sui`: hints, captions, section titles, notes, disabled rows, the search hint, the profile line and the tabs you are not on look as before.
2. A setting that differs on All bars has a grey diff icon, and its tooltip's source line is grey. In Bags > Categories the `edited` and `yours` markers are grey.
3. Edit mode: the History list and bar texts look as before. Open the combined bank: the eye toggle is a little lighter (section 8).
4. Change Muted: the open page's notes, description and hint follow when it redraws, the rest after a reload.
5. SaftUI's tracker (turn it on): other zones' titles, counts and chevrons, and the empty line are grey. A unit frame's level tag for a mob far below you, RestedXP's skinned scroll bar and titles, and the skinned Blizzard tracker's chevrons are grey as before.

State colors (Task 4):
1. Errors and refusals (a status line, a disabled row's why, the edit mode bar's refusal, "Close the color picker first.") are soft red as before; the chat Error prefix is soft red. Change Danger: errors, DEBUG, the close button's hover, remove icons and loot roll timers under a minute move; Pass, Damage and Horde stay.
2. Loot roll timers (white over a minute, red under) and expiring totems.
3. Level tags, the micro menu's latency and stats, the alert flash, the durability tooltip (green, orange, red bands).
4. Item levels (white, Bind on Equip green, Warbound cyan), the reagent marker, a bank price you can or can't afford, "Caught by:", the rule editor's OR and Caught now in bags and on the character frame.
5. SaftUI's tracker: progress percent and the chevron under the mouse are white; the skinned Blizzard tracker's chevron under the mouse too (section 8).

## 6. Buttons at their opacity (Task 5)

At the defaults (100%), all of these look as they did, except that every highlight under the mouse is now Buttons > Hover at 40% (a blue tint over the fill, where it was Normal's near-black) since the hover change ("Hover is everything under the mouse", decision 54):
1. A SaftUI button's highlight (Hover at 40% now) and pressed fill (a bag header button, keybind mode's Done, the loot feed's F and V), the filter box of a bag category or of the currency list (a SaftUI check box: its checked fill, now Buttons > Checked, and its highlight, Hover at 40%), and the scroll bar thumb of a bag window or of chat, at rest, under the mouse and pressed. (`/sui`'s own scroll bar and check boxes are the options kit's and don't read Buttons colors.)
2. The resize corners: the grip at the `/sui` window's bottom right and the world map's corner (`st:EnableResizing`, under Thick or Thin).
3. The micro menu: each micro button's highlight (40%) and pushed fill (60%), a bar item's highlight and pressed fill, the tracking button, the queue eye and the expansion button under the mouse.
4. The bank's unbought tabs tinted red (30% on the slot), and the flash on an action button and a totem button (40%).
5. The action button's hover is a white tint at 15%, not a Buttons color: it never changes with Buttons.

Then lower Buttons > Hover to 50% (picker's opacity), reload:
6. A bag header button's, an unchecked filter box's and a zone text or addon compartment item's highlight (now 20%), a hovered bag or chat scroll bar thumb, the world map's resize corner and the `/sui` grip, the tracking, queue and expansion buttons' highlight and each micro button's highlight (now 20%) are fainter. Normal, Checked, Pushed and Danger are untouched. Do the same for Normal (a bag scroll bar thumb at rest, nothing else), Checked (a checked bag category or currency filter box), Pushed (a held bag header button, a micro button's pushed fill, now 30%) and Danger (the flash, now 20%, and an unbought bank tab, now 15%: 50% on the tint times its own 30%).
7. Hover's reset arrow puts 100% back (and its color).
8. Set an opacity of 0%: the highlight is not drawn, and nothing errors.
9. Nothing changes in combat: no `ADDON_ACTION_BLOCKED` while the action bars, totem bar and micro menu are in use.

## 7. Both clients

1. Forever: the totem bar's flash and the action buttons' flash; the diff icon; the Colors page.
2. Retail: the same, plus the retail-only reagent and Warbound item levels and the warband bank count (Shared, Success).
3. The same customizations made on each client migrate the same way (each client has its own saved file).

## 8. Rulings the controller made, for the owner to check

Each is a call the design left open; if it looks wrong in game, say so and it changes.

1. **The frozen grey is 180.** Text > Grey's default became `#b4b4b4` (decision 49) after the migration's table was written, so a profile whose grey is still `#b4b4b4` copies nothing to Muted, and one saved at exactly 150 counts as a customized Muted.
2. **The bank's eye and the picker's "Alt: next" are lighter** (`#969696` to `#b4b4b4`), because both read Buttons > Grey, which folded into Muted.
3. **The skinned Blizzard tracker's chevron under the mouse is Strong**, as SaftUI's own tracker's is. White by default, so nothing changes on screen.
4. **The diff, reset and dots icons all rest in Muted** (the reset arrow lights in the accent under the mouse).
5. **The equipped border follows the accent only at a theme redraw** (a theme switch, or a reload), not live like the other accent uses.
6. **A customized Buttons > Grey and Buttons > Green are dropped.** Muted and the accent keep their defaults.
7. **Saved Buttons opacities were reset to 100% once**, because none was ever drawn.
8. **Own labels and titles are the accent**, drawn at `OB.OWN_STRENGTH` (1), where they were the light blue `#8fd8ff`. Look at them and judge (section 1, item 7).
