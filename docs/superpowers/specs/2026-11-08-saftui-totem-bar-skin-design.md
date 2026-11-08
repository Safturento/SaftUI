# Totem bar skin and totem timers (Forever)

Status: approved in conversation, 2026-11-08.

## Intent

The user plays a shaman on WoW Forever. Forever has Blizzard's Wrath-style totem
bar (`MultiCastActionBarFrame`): a summon button (Call of the Elements and the
like), one button per element (Earth, Fire, Water, Air), a recall button, and a
flyout above each button to choose which totem goes in it (and which totem set
the summon button uses). It still has Blizzard's art, so it looks out of place
next to SaftUI's flat bars. And nothing on screen says how long a totem has left.
What the user wants from the timers, in their words: "I mostly just want to know
if my totems are about to fall off."

So:
1. Skin the totem bar and its flyout to match SaftUI's action bars.
2. Above each element button, while that element has a totem down, show how long
   it has left: a status bar and a text countdown, each toggleable.

## Scope

- Forever only. Retail has no totem bar (`Blizzard_ActionBar` loads it only for
  the camelot, wrath and cata game types), so nothing here runs there and no
  `/sui` options appear, as with today's Totem Bar section.
- Builds on `SaftUI-Misc/totembar.lua` (module `TotemBar`, config
  `st.defaults.totembar`, today only `hide`). Read its header comment first: it
  explains how Blizzard shows, hides and places the bar, and why SaftUI leaves the
  bar's position to Blizzard.

## Goals (decided with the user)

### Skin
- Every button looks like SaftUI's action bar buttons (`SaftUI-ActionBars/skin.lua`
  is the reference look): flat backdrop in the profile's button template, icon
  cropped square, SaftUI's flat hover / pushed / checked, SaftUI's pixel font for
  keybinds. That covers the summon button, the four element buttons, the recall
  button, and every totem choice in the flyout.
- Each element button's border is its element's colour, so the elements stay
  apart once Blizzard's coloured art is gone. An element slot with no totem
  assigned shows as an empty dark button with that border.
- The flyout gets a SaftUI panel behind its column of choices. The flyout's first
  choice ("none", clears the slot) is an empty button in the element's colour. The
  flyout's open and close arrows get a flat SaftUI look.
- Blizzard's flyout open arrow appears right above a hovered button, and the
  flyout opens upward from the top of the button: exactly where the timers sit.
  The arrow and the flyout are shifted up to sit above the timers, so neither
  hides the other.

### Timers
- Above each element button, while that element has a totem down: a status bar
  draining as the totem's time runs out, and a text countdown. Both hide when the
  totem expires, is destroyed or recalled, and for an element with no totem.
- Text format: `m:ss` from a minute up (`4:12`), whole seconds below (`45`).
- In the last 10 seconds the bar and text turn the warning colour (the profile's
  `colors.text.red`). 10 seconds is fixed, not a setting.
- Bar colour: the element's colour (the same as its button border).
- Text position, a setting:
  - **Above the bar:** a thin bar right above the button, the text over the bar.
  - **On the bar:** a taller bar with the text written on it.
  - With the bar turned off, the text sits just above the button either way.
- Display only: the timers never take the mouse.
- They follow the bar and its buttons wherever Blizzard's Edit Mode puts them,
  and wherever Blizzard's bar update moves the element buttons (it re-orders them
  when slots are learned).
- With "Hide totem bar" on, there are no timers either.

### Settings (Totem Bar section of `/sui`)
- Existing: `hide`.
- New, all on the bar's existing config table:
  - `timer_bar` (toggle, default `true`): "Show timer bar".
  - `timer_text` (toggle, default `true`): "Show timer text".
  - `timer_text_position` (select, default `'above'`): "Text position",
    choices "Above the bar" (`'above'`) and "On the bar" (`'on'`). It only
    matters while both the bar and the text are on (text alone sits above the
    button either way), so it's greyed out otherwise (my call).
  - Revised 2026-11-08: "Button size" (`button_size`, 20–60, default 30),
    "Spacing" (`button_spacing`, 0–20, default 3) and "Timer bar height"
    (`timer_bar_height`, 2–20, default 8; with the text on the bar, never shorter
    than the text needs). See the revised note under "Settled after the builder
    check".
- Changing any of them applies straight away, and profile switches apply them
  (`TB:UpdateConfig`).

## Non-goals

- Moving the bar. Its position stays Blizzard's (see `totembar.lua`'s header for
  why); the timers and the flyout shift are relative to Blizzard's buttons.
- Retail's `TotemFrame` (the totem icons by the player frame).
- Clicking a timer to destroy a totem.
- A skin toggle. The skin is always on while the bar is shown.
- A configurable warning threshold or configurable element colours in `/sui`.

## Constraints

- **Taint (`.agents/taint.md`), read it in full first.** The bar is protected:
  its element, summon and recall buttons are secure action buttons. In
  particular:
  - **No field writes on any Blizzard frame or table** (rule 1). That rules out
    `st:SetBackdrop` and `st:SkinActionButton` on Blizzard's buttons as they stand:
    `st:SetBackdrop` writes `frame.backdrop` and `frame.thick`. Keep SaftUI's
    pieces (backdrop frames, textures, timer frames) in a table of SaftUI's keyed
    by the Blizzard frame, like `SaftUI-ActionBars/skin.lua`'s `skins` table.
    Changing an existing region of Blizzard's (SetTexture, SetTexCoord, SetAlpha,
    SetPoint, SetVertexColor) is a widget call, not a field write.
  - **Post-hooks only** (`hooksecurefunc`, native `HookScript`); never replace a
    Blizzard function or script.
  - Never `Show`, `Hide` or `SetParent` a visible secure button from SaftUI's
    call chain (rule 4; the `9403497` incident was this bar).
  - Anything SaftUI changes on a protected frame waits for the end of combat
    (`st:QueueAfterCombat`). Check, for each Blizzard frame you move or resize
    (in particular the flyout open arrow and the flyout, for the shift above the
    timers), whether it's protected or anchored in a way that makes the call
    blocked in combat. Blizzard re-anchors both every time they open, so the shift
    has to follow each opening (post-hook `MultiCastFlyoutFrameOpenButton_Show`
    and `MultiCastFlyoutFrame_ToggleFlyout`, or equivalent) and has to work in
    combat, or be dropped for in-combat openings with a note to the user.
- **Blizzard keeps redrawing the bar.** `MultiCastSlotButton_Update` re-sets the
  element art's tex coords, `MultiCastFlyoutFrame_LoadSlotSpells` /
  `LoadPageSpells` create the flyout buttons lazily (`MultiCastFlyoutButton<n>`)
  and re-set their icon and tex coords on every opening,
  `MultiCastFlyoutFrame_ToggleFlyout` re-sets the flyout and close arrow tex
  coords, `MultiCastButton_ApplyOverrides` (Camelot) sizes some regions. The skin
  has to survive all of these (post-hooks that re-apply, or fading Blizzard's
  regions out for good with SetAlpha(0) where they're replaced).
- **Secret values (`.agents/clients.md`).** `GetTotemInfo` and
  `GetTotemTimeLeft` are documented `SecretWhenTotemSlotSecret`. Forever has
  `GetTotemDuration(slot)` (a duration object), `StatusBar:SetTimerDuration`,
  duration text bindings and colour curves. Prefer one code path that works
  whether or not the values are secret (the duration object path), and only fall
  back to plain math if those APIs turn out unusable here. The warning colour
  then likely comes from a colour curve rather than a comparison.
- Element to slot: each element button's `GetID()` is its totem slot (set in
  `MultiCastSlotButton_Update`), and Blizzard re-orders the buttons by
  `SHAMAN_TOTEM_PRIORITIES`. Read the element from the button each update rather
  than assuming an order.
- Today's `hide` option reparents the whole bar under a hidden frame; the skin
  and timers must not undo or fight that.

## Settled after the builder check (my calls, 2026-11-08)

- **The element button is two layers, skinned as one.** Each element has a slot
  button (`MultiCastSlotButton1..4`: `GetID()` is its totem slot, it shows the
  empty art and it's what the flyout opens from) with an action button stacked
  on it (`MultiCastActionButton1..12`, four per summon page, the secure buttons
  with the spell and keybind). Skin all 16 together: all 12 action buttons, since
  Blizzard swaps pages (`ChangeMultiCastActionPage`), plus the 4 slot buttons.
  The backdrop and element border belong to the slot button (it's stable per
  element and is what shows when the slot is empty). The action buttons get the
  cropped icon, flat states, fonts and faded art. Timers anchor to the slot
  buttons, and the element is always `slotButton:GetID()`. The summon and
  recall buttons get the normal (non-element) border.
- **The arrow and flyout grow instead of jumping a gap.** Blizzard hides the
  open arrow, and closes the flyout, as soon as the mouse is over neither them
  nor the button (`MultiCastFlyoutFrameOpenButton_Hide`, `MultiCastFlyoutFrame_Hide`),
  so a gap over the timers would make the arrow impossible to reach. They stay
  anchored where Blizzard puts them, at the button's top. SaftUI makes them
  taller by the height of the timer area and moves their visible parts (the arrow
  art, the column of choices and its panel) to the top. The mouse never leaves
  them on the way up, and the space over the timers becomes part of their hover
  and click area, which is fine because the timers take no mouse. The extra
  height is fixed by the settings (bar, text and text position), not by whether a
  totem is down, so the arrow doesn't move as totems come and go. With both
  timers off there's no extra height. This has to keep working in combat: check
  that neither frame is protected. If something blocks it in combat, skip the
  change for openings in combat, and say so in the report.
- **The skin is self-contained in SaftUI-Misc.** Misc depends only on Core, so
  it must work without SaftUI-ActionBars loaded. `SaftUI-ActionBars/skin.lua` is
  the visual reference, not code to call. The template and font come from the
  profile's shared button settings, `st.config.profile.buttons.template` and
  `.font` (`SaftUI-Core/Config/defaults.lua`). `st:SkinActionButton` and
  `st:SetBackdrop` write fields onto the frame they're given, so they can't be
  used on Blizzard's buttons. Build the backdrops as SaftUI frames in a side
  table. Buttons keep Blizzard's sizes, since resizing secure buttons is blocked
  in combat and Blizzard sizes them. Keybinds use the profile's button font. No
  hotkey shortening: that lives in ActionBars.
  - **Revised 2026-11-08:** sizes are now settings, applied out of combat. Button
    size (`button_size`, default 30) and one gap between neighbouring buttons
    (`button_spacing`, default 3, in place of Blizzard's 3 and 8) are laid out by
    `SaftUI-Misc/totembar.lua`, which also sizes the bar to fit and puts the layout
    back after Blizzard's bar update re-anchors the buttons (waiting for the end of
    combat in a fight). The flyout's choices follow the button size, 6 smaller.
    The timer bar's height is a setting too (`timer_bar_height`, default 8). See
    `totembar.lua`'s header for the details.
- **Timer data path.** What the user sees comes first: the format and the
  warning colour. The other rule is to never error on a secret value.
  - **The bar:** `GetTotemDuration(slot)` with `StatusBar:SetTimerDuration`,
    which works whether or not the values are secret, with no per-frame math.
  - **The text and the warning colour:** plain math on `GetTotemInfo` while its
    values aren't secret (`issecretvalue`). When they are, use the duration
    object's own formatting and colour curve, as close to the format as those
    allow.
  - Confirm each API exists on Forever from `Blizzard_APIDocumentationGenerated`
    before relying on it.

## Left to the builder

- Element colour values: sample Blizzard's `Interface\Buttons\UI-TotemBar` art
  for each element so they read as the same elements; define them in the
  module's defaults so they could become settings later.
- Bar heights for the two text positions, the gap above the button, the font
  size, and how the flyout and arrow arrows are drawn.
- How the skin is structured in code (new file(s) next to `totembar.lua` is
  fine; add them to `SaftUI-Misc/SaftUI-Misc.toc`).
- Docs: `.agents/taint.md` covers `SaftUI-Misc/totembar.lua`; update it (and add
  any new file to its `covers`) if the change adds a pattern or exception an agent
  would need. `README.md` mentions the totem bar option; update it in its own
  style.
