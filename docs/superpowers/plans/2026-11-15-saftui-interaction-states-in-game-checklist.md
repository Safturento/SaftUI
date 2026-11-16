# Interaction states: the in-game checklist

For the owner. The whole plan in one list, in the order you would play it: first what changed on screen, area by
area, then the checks, then the calls the reviews left to you, then the one-line commands.

Do it on both clients (WoW Forever, interface 16001, and retail, interface 120000), at SaftUI's defaults unless a step
says otherwise, under Thick, then Thin, then Blizzard where a step says. The defaults are the Tones derivation,
Hover 16%, Pushed 32%, Selected fill 24%, Selected fade 70%, Disabled 40%, Lightness step 0.08. At the default Accent
(0, 0.68, 0.94) the lighter tone T+ is #5bc6ff and the darker tone T- is #0093cc.

Before the combat steps, turn the taint log on and keep BugGrabber open: `/console taintLog 1`, then `/reload`.
Each step ends with the code that makes it true, so a step that does not happen tells you where to look.

## Part 1. What changed on screen, by area

Read it once; the checks in Part 2 are these changes, played. A state on a widget is now the same everywhere:
hover tints the body (never only the edge), pressed tints it darker, selected is an Accent edge (a left bar on a
row, an underline on a tab) with a fill that fades out to the right, focus is an Accent edge, disabled dims to
40%. The Buttons colors Normal, Hover, Pushed and Checked are gone.

**`/sui` and every window of SaftUI's (the options kit).**

- A button, field, select, color field, check box, chip and the search box under the mouse tint their body in T+ and
  keep their grey edge. A held button tints darker as its label drops one line.
- A ticked check box, an "on" icon button (the edit mode bar's, the size buttons) and a keybinding waiting for a key
  have the Accent edge and the fade. A ticked check box also has a small Accent square inside it.
- Sidebar: a page tints under the mouse (it was grey); the open page has a two-line bar at its left and the fade
  (it was a 2 px bar and a flat 25%), lighter when you hover it. Tabs tint under the mouse; the open tab's underline
  is two lines with the fade over it.
- Dropdown and check list rows tint at 16% (they were the Accent at 25%); the picked row has the bar and the fade
  and its text is Text > Normal (it was the Accent). A disabled entry or sidebar page dims to the Disabled opacity.
- The slider's knob turns T+ under the mouse and T- while dragged (it had no hover); its fill stays the Accent.
- Icon links, the reset icon, the title's page arrow, the item and font slots, the nudge arrows, the position
  block's dots and the resize grip's corner turn T+ under the mouse. The grip's corner is white at rest.
- The color picker's chips and the was/new blocks show their color exactly under the mouse (no tint over a color).
- Search result rows tint at 16%.

**Core's widgets (bags' header buttons, Bag Slots, warband buttons, the loot feed's buttons, radio tabs, keybind
mode's Done, check boxes, scroll bars, edit boxes, resize corners).**

- A SaftUI button tints its body under the label (it was an additive flat highlight over the label); disabled is
  40% on the whole button (it was a black texture).
- A radio group's picked button has the Accent edge and the fade (it was an edge only). A ticked `'button'`-style
  check box (the Currencies funnel; the Edit toggle is hidden in the code today) is the same.
- A scroll bar thumb rests at #4d4d4d (it was #1a1a1a, almost invisible), T+ under the mouse, T- while dragged.
- The bag search box and the chat edit box: the focus edge is the Accent (it was white).
- Bag, bank and bank tab slots: a faint 16% tint under the mouse (it was the full Accent, additive) and a darker
  tint while held (it showed nothing).

**Colors page and Theme > Accent.**

- Buttons holds one color, Danger. A profile that had changed Normal, Hover, Pushed or Checked loses those once, at
  the update, and nothing else.
- The Accent row (Global settings > Theme) has a dots button at its right. Its menu opens beside the dots and holds a live strip of six
  buttons (Rest, Hover, Pushed, Selected, + hover, Disabled), then Derivation, Strengths (Hover, Pushed, Selected
  fill, Selected fade, Disabled), Tones (Lightness step) and Hue shift (Hue shift, Direction, Chroma change). The
  Accent's picker shows the same strip under its square.
- Buttons > Danger's picker shows the flash and a locked slot, not five tiles.
- At strong settings (Hover 60%) on a pale Accent, a label turns dark where the light text would not read.

**Edit mode.**

- A mover under the mouse (or being dragged) tints in T+; its white line stays. A selected mover has the Accent
  edge and a fade over its dim body (it was a flat Accent 15%); lighter when hovered. The overlap picker's other
  movers keep their 40%.
- History list: a row under the mouse tints; the current step has the two-line bar and the fade (it was a 2 px
  mark). The Filter movers box tints under the mouse and lights its edge when typed in.

**Bags.**

- View buttons: a body tint under the mouse; the current view has the Accent edge and the fade. Their icons stay
  Text > Normal.
- Categories list: the selected row has the two-line bar and the fade (it was a 3 px bar and a flat 25%); hover is
  the body tint. An off category that is hovered or selected is drawn in Text > Normal, with its strike line.
- `+ New category`, `+ Block`, `+ Group` turn Text > Strong under the mouse (they dimmed to 70%).
- Rule editor: NOT on shows the edge and the fade with a light label; its check boxes have a 10 px square on the
  14 box with the edge and the fade. The AND / OR badge now tints its body under the mouse like the other boxes
  and keeps its label at full strength (it dimmed the label to 70%): a hand-rolled hover the spec had dropped,
  drawn through the helpers in the final fix round.

**Action bars, totems, micro menu, minimap.**

- Action, pet and stance buttons: hover is T+ at 16% over the icon, pushed T- at 32%, a checked button (an active
  ability, an auto attack, a stance) has the Accent edge and the fade from the left; an equipped item has the same
  edge with no fade.
- Totem buttons: hover is T+ at 16% (it was the full Accent, additive); pressed and checked as the action buttons,
  with no edge.
- Micro buttons: highlight T+ at 16%; a micro button whose window is open has the Accent edge and the fade (it was a
  60% fill). The bar's items (zone text, clock, compartment) tint under the mouse and press, and dim when disabled.
  The tracking, queue and expansion buttons: T+ at 16%.
- Keybind mode: the button being bound shows a thin Accent edge and the fade (it was an Accent wash at 40%).

**Loot.**

- A chosen roll's icon keeps the Accent edge and gains the fade; the other buttons dim to 40% (they were 35%).
- A loot window row under the mouse tints its body; its border no longer turns Accent. The feed's two buttons tint
  and their icon turns T+ under the mouse.

**SaftUI's tracker, Blizzard's tracker skin, the picker's skin, RestedXP.**

- Tracker rows tint at 16% under the mouse and darker when held (a left press), 2 above and below the row (the list
  clips the sides; they were Accent at 25%); popup rows and zone header rows tint (new); a press on a row's slot or
  quest icon pushes the row (new). Quest item buttons: 16% (they were 40% added). Chevrons: T+ under the mouse.
- Blizzard's color picker (with the skin on): Okay and Cancel tint under the mouse and darker while held, their edge
  unchanged; the hex box's focus is the Accent (it was white). Blizzard's tracker's quest item hover is T+ at 16%
  and its collapse chevron is Muted, T+ under the mouse. RestedXP's step hover is the derived tint.

**Under Blizzard.** Wherever Blizzard's art draws a state (the kit's controls, `/sui`, bags, action, pet, stance,
totem and micro buttons, the movers' kits), SaftUI draws nothing over it. SaftUI's own tracker rows and item buttons,
the micro menu's bar items, the minimap's buttons and the keybind marker keep SaftUI's look in every theme, and so do the bag bar's slots (call 1 below). The close button
keeps its own red Danger hover on purpose (call 10).

**Behaviors the engine now has.** A control enabled again while the mouse is over it shows hover at once. A label
you recolor while a state is on it comes back in your color, not a default. A selected row's bar and a tab's
underline keep their two-pixel thickness when you change the UI size.

## Part 2. The checks, in play order

### Setup

1. **A profile that changed Buttons > Hover.** Your profile has already run the update, and Colors has no Hover row
   to change, so this can only be played by editing the saved variables. Skip it if you would rather not. Close the
   game and, in the SaftUI saved variables file, give a spare profile (`SaftUI_DB.profiles.<name>`) the whole entry
   `colors = { version = 7, button = { hover = { r = 1, g = 0, b = 0 } } }` (a spare profile may have no `colors`
   table at all). Start the game and switch to that profile: Colors shows Buttons with Danger only, BugGrabber
   shows nothing, and after you log out the saved file no longer lists `hover` for it. The switch is what migrates
   it: to try Copy from, close the game and make the same edit again first.
   *Code: `CO.MIGRATION_STEPS[8]` in `SaftUI-Core/Media/colors.lua`, run by `st:MigrateColors` at login and by
   `Config:UpdateConfig` on a switch, copy and reset; the Buttons section is `Danger` alone (`CO.SECTIONS`).*

### `/sui`

2. **Boxes and buttons (G1).** In `/sui`, put the mouse over Reload UI, a field, a select, a color field and a check
   box. Each tints its body light blue and keeps its grey edge. Hold the left button on Reload UI: it tints darker and
   the label drops one line; move off it before you let go, or it reloads.
   *Code: `W.HoverStates` (`Config/optionslook.lua`); the label offset is `PlaceLabel` (`Config/optionscontrols.lua`).*
3. **A check box.** Tick one. It shows a blue edge, a small blue square and a fade from the left; hover it while
   ticked and the edge and square turn lighter. Disable something (an option whose toggle greys it out): it dims to
   40% and shows no tint under the mouse.
   *Code: the `'check'` shape in `Widgets/states.lua`, `Kit.SetCheck`; `Base:SetDisabled` in `Config/optionswidgets.lua`.*
4. **Sidebar and tabs (G2).** Hover a sidebar page: a blue tint, not grey. The open page has a two-line bar on its
   left and a fill fading across; hover it and both go lighter. On the tabs: a tint under the mouse and the text turns
   light; the open tab's underline is two lines with the fade above it.
   *Code: `StyleNavItem` and the tab registration in `Config/optionsnav.lua` (`'row'` with `bar = 'left'`, `'tab'`
   with `bar = 'bottom'`).*
5. **Dropdown (G3).** Open a dropdown: rows tint under the mouse; the picked row has the bar and the fade with light
   text. Hover a check list's row: its box takes the row's hover. If you find a dropdown whose choice enables a control that sits
    under its open list, pick that choice and move the mouse out of the list away from that control: the control shows no
    hover (the tests cover this; skip it if none is at hand).
   *Code: the `'row'` records in `Config/optionslist.lua`.*
6. **Slider and links.** Hover a slider's knob: it turns light blue and darker while dragged; the fill stays blue.
   Hover the position block's dots (the picked one is the big blue dot), a reset icon, a nudge arrow and an item's
   dots: each turns the lighter tone. A share line's "All" link turns Text > Strong under the mouse.
   *Code: the `'knob'` in `Config/optionsrange.lua`; the `'glyph'` records in `optionsposition.lua`, `optionscontrols.lua`
   and `optionsitem.lua`.*
7. **The resize grip.** Drag `/sui`'s bottom right grip. Under Thick and Thin the corner stays visible, in the
   lighter blue, while you hold it. The world map's resize corner does the same: white, T+ under the mouse and
   while you drag.
   *Code: `Config/optionsresize.lua` (the glyph is the normal and the pushed texture).*
8. **A keybinding.** Click a keybinding button: it waits with a blue edge and the fade and "Press a key" in blue.
   Press a key or Esc: the edge goes. Hover it while waiting and read the prompt (call 5).
   *Code: `StartWaiting` and `StopWaiting` set `selected` (`Config/optionskeybinding.lua`).*
9. **Focus.** Click into `/sui`'s search box: the blue focus edge. Click a picker's hex box, then press Tab: the edge
   moves with the keyboard. Close `/sui` with a box focused and reopen it: no box keeps a blue edge.
   *Code: `W.Edge` and the helper's `'focus'` state (`Config/optionslook.lua`).*
10. **The picker's chips.** Open a color's picker and hover a chip and the was/new blocks: the color stays exact and
    only the body around it tints.
    *Code: the chips and blocks in `Config/optionscolorpicker.lua` draw their color above the hover Layer.*

### Colors and the Accent

11. **Buttons.** Global settings > Colors: Buttons has only Danger, and its picker shows a flash and a locked slot,
    both fading when you lower the opacity. Every other row's preview looks as before.
    *Code: `CO.SECTIONS` and the `'danger'` preview kind (`Config/optionspreview.lua`).*
12. **The dots menu (G4).** Open the dots on Global settings > Theme > Accent. The menu opens beside the dots (not
    over the row) with the strip first, then Derivation, Strengths, Tones and Hue shift. Drag Hover, Pushed, Selected
    fill, Selected fade and Disabled: the strip and the page behind follow as you drag. Each changed setting shows
    its own reset arrow; a click puts the default back. Esc closes the menu. Hue shift reads "20", not "20 degrees".
    *Code: `ST.MenuGroup()` (`Media/states.lua`) drawn by `Config/optionsmenu.lua`; the strip's six captions are
    `STATE_NAMES` in `Config/optionspreview.lua`.*
13. **By mode (G6).** Layers dims Tones and Hue shift; Tones dims Hue shift; a dimmed row keeps its value and comes
    back unchanged. Change Hover, close the menu: the dots rest lighter and their tooltip says "1 setting here
    differs from its default." The strip's fifth caption reads "+ hover" and is not cut off. Under Blizzard the dots turn white under the mouse and the strip is drawn Thick with the note "Shown as Thick:
    Blizzard's art draws its own." (not cut off). Search `/sui` for "hover", "pushed" and "tones": the Accent's rows
    come up and a click opens the menu.
    *Code: `disabled` and `disabledDesc` on the settings in `ST.MenuGroup()`; `Kit.DotsTip` (`Config/optionsitem.lua`).*
14. **Presets (G5).** Pick #8a5cf5, then #e6c84a: every state follows, and text on a fill stays readable. With
    #e6c84a, set Hover to 60%: the strip's Hover "Okay" and a hovered button on the page turn dark. Set Hover back
    to 16%, then change Text > Normal and press Okay: the buttons you hovered follow the new color at once.
    *Code: `textKeep` and `st:RepaintKeptText()` (`Widgets/states.lua`, called from `Config:OnColorsChanged`).*
15. **Hue-shifted tones (G6).** Set Derivation to Hue-shifted tones. With #e6c84a: pushed is orange (#e99f00) and
    hover a paler yellow (#f7e579). With the default blue: hover turns cyan (#1ecfef) and pushed toward violet
    (#3888e9). Say if it reads wrong (call 6).
    *Code: `ST.Tone` (`Media/states.lua`).*
16. **Picker and menu together.** Turn `/sui debug` on first. Open the Accent's color picker, click the dots, press Cancel on the picker, then
    drag Hover in the menu: it stays smooth, and closing the menu ends the edit (one `<DEBUG:Colors>` line). If the
    picker covers the Accent row's dots, drag the picker by its title strip first. In the picker, Cancel puts every
    state back; the strip's buttons take no mouse; Danger's two slots sit centred in their tiles.
    *Code: `st:HoldColorEdit()` and `st:ReleaseColorEdit()` (`Media/colors.lua`).*

### Edit mode

17. **Movers (G10).** Over a mover its body tints light blue and its white line stays. Drag one fast so the cursor runs
    ahead: it stays tinted for the whole drag and the tint goes when you let go. Start a drag and press Esc, or start
    one and enter combat: nothing stays tinted when edit mode comes back. Click a mover: a blue line and a fade over the dim body; hover it and the line, fade and tint
    go lighter. On a wide mover, can you see the selection on a bright frame (call 7)?
    Two overlapping movers: only the one under the cursor tints; hold Alt to cycle and the others stay at 40%.
    *Code: the `'mover'` records in `EditMode/mover.lua` (`st:AddStates(overlay, 'mover', ...)` after the overlay's scripts: the helper's press hook sets `pushed`, which a mover draws as hover).*
18. **The bar and the History list.** A History row tints under the mouse; the current step has the two-line bar and
    the fade and moves with Undo, Redo and a row click; a hovered undone (grey) row's label turns light. The Filter
    movers box tints and lights its edge when typed in; the length box and Grid size tint and light their edge; Esc clears the Filter movers box; at your UI size the bar and the movers' labels read as
    before; with
    nothing selected and no changes, Reset, Undo and Redo are dimmed and do not tint under the mouse. Then select a
    mover, rest the mouse on the dimmed Undo and press an arrow key: Undo comes back and tints at once, with the
    mouse not moved.
    *Code: `EditMode/Bar/historylist.lua` (`SetState(row, 'selected', index == position)`).*
19. **A mover while you recolor.** With a mover selected, drag Theme > Border color, then Background's opacity, which its picker has (Border has none): the movers' lines stay white (the
    selected one blue) and their bodies stay dim during and after. Switch Thick, Thin and Blizzard with one selected. With `/sui debug` on and bags and bank open, each Border-drag
    line naming `theme` is under 2 ms.
    *Code: the overlay's `SetBorderColor` in `EditMode/mover.lua` restyles only when the look or the inset changed.*

### Bags

20. **Windows (G7).** Right after a `/reload`, hover each view button that is not the current one, and the Currencies
    funnel: each tints at once. The current view button has the blue edge and the fade; its icon is Text > Normal.
    Hover Bag Slots, and Warband Bank (both are in the bank window at a banker, and Warband Bank only where the game
    has the warband bank): the label stays the same white after you leave. The bag bar's slots keep the tint after a
    bag swap. Switch to Blizzard with the mouse on a view button and move away: no icon stays light blue. Press and hold an item slot, a
    bag bar slot and a bank tab: a darker tint while held, nothing after release.
    *Code: `Widgets/button.lua` and `header.lua`; `containers/bag.lua` (the bag bar's slots are `'icon'` records).*
21. **Categories.** Hover a row (a tint) and select one (the two-line bar and the fade); drag a handle and drop, or
    drop outside to cancel: no row stays tinted. An off category, hovered or selected, reads in normal text with its
    strike line (call 3). `+ New category`, `+ Block` and `+ Group` are blue at rest and white under the mouse.
    *Code: `categoriestab.lua` (`'row'`, `'glyph'`).*
22. **Rule editor.** NOT on shows the edge and the fade with a light label; its check boxes ("whole word", on a name or text block) show the
    10 px square, the edge and the fade (call 4). Its dropdown fields and check boxes look enabled and tint under the
    mouse. "Caught now" is still a faint orange. With Theme on Blizzard and back, a rule editor check box's mark is a small square inside the box, not over it. The
    AND / OR badge of a group tints its body under the mouse and its label
    stays at full strength (no 70% dim); a click still flips the group.
    *Code: `ruleeditor.lua` (`W.HoverStates(check, { shape = 'check', mark = check.mark })`).*
23. **Check boxes of the bags and the bank.** The currency veil and the combined bank's eye (bare check boxes) keep
    their look through a theme and a profile switch. (The category filter box and the Edit toggle that shows it are
    hidden in the code today, so there is nothing to play there.) Retail: the combined bank's Bank / Warband tabs
    (edge and fade on the picked one) and the deposit button, which reads as disabled under Thick when a bank tab
    has nothing to deposit; after a hover the bank's Buy label keeps its red price color. Forever: with the bank's
    Bag Slots open and too little gold for the next tab, the Buy label is red; hover it and move away: still red.
    *Code: `st:SkinCheckButton` styles in `Widgets/checkbutton.lua`; `containers/combinedbank.lua`.*

### Action bars, micro menu, minimap

24. **Action bars (G8).** Hover a button (a faint tint over the icon), press and hold (darker), let go. Turn auto attack
    on: the Accent edge and the fade from the left. An equipped trinket on a bar: the Accent edge, no fade. Both on one
    button: one edge, with the fade. A pet action toggled (assist, passive) and a stance change: the active one has
    the edge and fade. A totem button (a shaman with the totem bar, on Forever): hover T+ at 16%.
    *Code: `AB:PaintEdge` and `AB.OnChecked` (`SaftUI-ActionBars/skin.lua`); the totem buttons are `totemskin.lua`.*
25. **Keybind mode.** `/sui kb`: the button under the mouse shows a thin Accent edge and the fade (call 2).
    *Code: `keybindmode.lua` (the binder is a `'box'`, selected while it marks a button).*
26. **Micro menu and minimap (G9).** Hover a micro button (a faint tint). Open the character window: its micro button
    shows the Accent edge and the fade, and both go when it closes. Watch the game menu button for a few seconds: no
    flicker. The guild button's highlight, the tracking, queue and expansion buttons, the zone text and the addon
    compartment: each tints under the mouse; click the compartment and its pressed tint clears once its menu opens
    and closes.
    *Code: `MicroMenu.OnButtonState` (`SaftUI-Minimap/microbuttons.lua`), `MicroMenu.SkinHighlight`
    (`micromenuitems.lua`).*

### Loot, tracker, skins

27. **A real group roll (G14).** Choose Need or Greed. The chosen button has the Accent border all round and a faint
    fade around the art's edges; the others are at 40%; "Choice" and the timer are in the Accent; the roll bar is held as before, and the chat lines
    with `/sui debug` on are `choice pending:`, `bar hid:`, `held roll`. Loot > Test mode's previews look the same;
    change the Accent and the border and "Choice" follow at once (call 8).
    *Code: `rollbar.lua`'s `ApplyBarConfig` (`SetState(backdrop, 'selected', true)`) and `DimOthers` (`st:StateAlpha()`).*
28. **The loot window and the feed.** Hover a row: its body tints, its border does not change; loot by clicking, in
    combat and out. Open and close many loot windows: no card stays tinted. On the feed, the two buttons show under
    the mouse, tint, and their icon turns T+ and goes back to Text > Normal when you leave; the filter menu behaves as a `/sui`
    list. Under Blizzard nothing of SaftUI's shows on the loot window.
    *Code: `popup.lua` (`HoverCard`), `Feed/feed.lua` (`CreateFeedIconButton`).*
29. **SaftUI's tracker (G15).** A quest row tints faint light blue under the mouse (softer than before) and darker
    while the left button is held; a right press does not darken it. Move from the row onto its item slot, quest icon
    and item button: the row stays tinted. A popup ("Quest discovered", "Quest complete") tints too; a zone header
    row tints and its chevron is grey, light blue under the mouse and while held. Quest item buttons tint faintly.
    Any scroll bar's thumb: lighter grey at rest, light blue under the mouse. Left click, Shift-click and the
    right-click menu on a row still work, and a popup's click still opens the offer or the turn-in; the combat dim
    (40%) and the blue in-area edge on quest items are as before; a chevron's tooltip and collapse work. Open the
    Accent's picker (Global settings > Theme > Accent), click its hex box, rest the mouse on a quest row, type a hex
    (8a5cf5) and press Enter: the row's tint follows. Press Cancel to put the Accent back. Complete an objective while hovering a row: a row that
    goes or is reused for another quest keeps no tint.
    *Code: `SaftUI-Tracker/rows.lua`, `items.lua`, `window.lua` (`TR:HoverRow`, the `'icon'` records).*
30. **Skins.** Blizzard's color picker (skin on): Okay and Cancel tint their body under the label, darker while held,
    the edge stays grey; click into the hex box: the edge turns blue, grey again when you click out. With SaftUI's
    tracker off (turn "SaftUI's tracker" off on its `/sui` page and `/reload`: it is read once at login), Blizzard's tracker's quest item shows a faint tint under the mouse and its chevron is grey, light
    blue under the mouse. A RestedXP step tints under the mouse, the tint clears when you leave, and it follows RestedXP's right-click.
    With the Skinning Theme set to Blizzard, Blizzard's picker shows Blizzard's own look and no tint, and
    Blizzard's tracker's quest item shows Blizzard's highlight.
    *Code: `SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua`, `Blizzard_ObjectiveTracker.lua`,
    `addons/restedxp.lua`.*

### Chat, scale, Blizzard

31. **Chat edit box.** Press Enter: a blue edge while it has focus; send a message, a `/` command and, in combat, a
    `/cast` line: the edge goes back each time, nothing blocked. A bag search box the same: click in, blue edge;
    Esc or click away, the theme's edge.
    *Code: `st:SkinEditBox` (`SaftUI-Core/skinning.lua`).*
32. **Scale and recolor.** `/sui scale 90`, press Keep; then `/sui scale 100`, Keep. A selected tab's underline and a
    selected row's bar stay two pixels (the underline one pixel below its tab). With a selected button (the bags'
    current view button) and the bags' Currencies funnel ticked (a `/sui` toggle will not do: its edge is its own), open Global settings > Theme, open Border's picker and
    drag, then drag Background's opacity: their Accent edge stays.
    *Code: the scale callback in `Widgets/states.lua` (`UIScale:OnChanged`); `st:KeepOwnColors` keeps a selected
    edge through a recolor.*

33. **Blizzard theme (G16).** Set Theme to Blizzard (Global settings > Theme). `/sui`, the bags, the action, pet,
    stance, totem and micro buttons and edit mode's movers wear Blizzard's states and no SaftUI tint shows over them
    (the bag bar's slots are the exception: they keep SaftUI's tint, call 1);
    switch Thick, Thin, Blizzard and back with a hovered button, a checked box and a scroll bar on screen: nothing
    stays drawn under Blizzard and everything is back under Thick. A chosen roll still has an Accent line around its
    icon. In `/sui`, a picked dropdown entry keeps its text in the Accent (the Settings art has no picked mark), and an
    item's dots are white under the mouse. The tab label goes back to Muted and a button's to white after a hover.
    *Code: each record's `blizzard` option; `W.WearsBlizzard` for the kit.*

### Combat and the taint log

34. **In combat (G12).** With the taint log on: cast from bars 1 to 8; toggle auto attack; open and use a spell
    flyout; use pet abilities (summon or revive a pet too) and change a stance or form; use a totem and its flyout; ride a vehicle or a taxi and
    press the leave button; open and close the character window and the spellbook from the micro menu; use a quest
    item by click and by the nearest item's key. Expected: every action works, no `ADDON_ACTION_BLOCKED`, and nothing
    in `Logs/taint.log` or BugGrabber naming SaftUI, `OnChecked`, `Widgets/states.lua` or `microbuttons.lua`. Press and
    hold a bag slot in combat and use, drag, split and sell: they work.
    *Code: a pass and a state only color SaftUI's own textures and frames (`.agents/taint.md`, rules 20 to 22);
    `AB.OnChecked` is a post-hook that sets a state and a color.*

### Timing

35. **The pass time (G11).** `/sui debug` on, in a raid or a busy city with every bag and the bank open. Drag the
    Accent in the picker for a few seconds and press Okay. Then open the Accent's dots, drag Hover for a few seconds
    and close the menu. Each `<DEBUG:Colors>` line's slowest pass should be under 2 ms. If one is over, say which
    line: the followup "The full-UI Accent pass is about 2,500 setters" is for exactly that.
    *Code: `st:EndColorEdit()` prints the line (`Media/colors.lua`).*

## Part 3. Your calls

Each is a one-line change after you have seen it. Say which way you want it.

1. **Bar items, minimap buttons and the keybind marker under Blizzard.** The micro menu's bar items (zone text,
   clock, compartment), the minimap's tracking, queue and expansion buttons, and keybind mode's marker keep SaftUI's
   tint under the Blizzard theme (the marker wears the Thin look in every theme), and so do the bag bar's slots, where the spec's table said
   "Blizzard's highlight and pushed art". Keep, or wear Blizzard's art there?
2. **The keybind marker under Blizzard.** Same question for the marker alone: follow the theme?
3. **An off category hovered or selected.** It is drawn in Text > Normal over the fade, with its strike line, instead
   of Muted. Readable as off? (Step 21.)
4. **The rule editor's check mark.** A 10 px square on the 14 px box (it was 8, 3 in), with the edge and the fade.
   Right size? (Step 22.)
5. **"Press a key".** In the Accent on the selected look it is 4.3:1 at best with the mouse away and 2.9 to 4.1
   right after the click that starts the wait (it was 6.5:1). Leave it, draw it in Text > Strong while waiting, or
   keep the Accent only at rest? (Step 8.)
6. **Hue-shifted tones.** Do pushed orange on gold and hover cyan on the default blue read right? (Step 15.)
7. **A selected mover.** On a wide mover the right third is only the line. Hard to see on a bright frame? (Step 17.)
8. **The chosen roll's fade.** It sits behind the roll icon's art, so it shows only around the art's edges. Does it
   read as chosen, or does the border alone do it? (Step 27.)
9. **Under Blizzard, small ones.** The History list's current step has an Accent label (Blizzard's art draws no
   mark; the old 2 px mark showed under Blizzard too). The loot feed's two icons are white under Blizzard. A disabled
   Bag Slots Buy button under Blizzard shows only Blizzard's -Disabled art: too faint?
10. **The close button.** Its Danger hover is unchanged on purpose: under the mouse its border and X turn red and its
    body is the close fill (a meaning, not a state), while every other button tints in the Accent. Keep it red, or
    make it wear the Accent's states too? (Step 2 and any window's close.)
11. **One Accent edge for two things.** A checked action button (an active ability, an auto attack) and an equipped
    item both wear the Accent edge; only the fade tells them apart. Right, or should the equipped item look
    different? (Step 24.) One condition in `AB:PaintEdge`.
12. **The scroll thumb at rest.** It rests at #4d4d4d (it was #1a1a1a, almost invisible). Too light or too dark?
    (Step 29, any scroll bar.) One constant, `ST.THUMB_REST`.
13. **Buttons holds Danger alone.** The Colors page's Buttons section has one row now. Keep Danger there, or move it
    to Text? (Step 11.)

Not in this list: a unit frame's hidden state against a dimmed one, which is the unit frames plan's.

## Part 4. One-line commands

- `/sui debug`: prints each color edit's slowest pass (`<DEBUG:Colors> N passes, slowest X ms ...`), and the roll
  lines of step 27. Run it again to turn it off.
- `/console taintLog 1`, then `/reload`: the taint log. `Logs/taint.log` and BugGrabber's list are where to look.
- `/sui kb`: keybind mode. `/sui edit`: edit mode. `/sui scale` prints the current mode; `/sui scale 90` (a size), `auto`, `pixel` or `game` tries one
  with the Keep prompt, and `reset` goes back.
- Does the game keep label colors as bytes? On each client:
  `/run local f=UIParent:CreateFontString(nil,'OVERLAY','GameFontNormal') f:SetTextColor(0.9,0.9,0.8) print(f:GetTextColor())`
  Printing `0.89803...` or `0.90195...` means bytes, `0.89999997...` single precision only. The states are right
  either way; it settles which the tests should model.
