# RestedXP Guides window in SaftUI's look

**Date:** 2026-11-08
**Status:** Draft, for the user's review

## Intent

The user levels with RestedXP Guides (the third-party addon `RXPGuides`, v4.11.35 on WoW
Forever) open beside SaftUI. Its guide window still wears RestedXP's own theme: blue
rounded-border boxes, a banner image with a logo and class icon, round scroll buttons. It
looks out of place next to SaftUI's chat window. The user wants it to read like SaftUI's
chat: the same panel and the same text.

The user picked the look from mockups: **one panel, like chat** (layout C). Instead of a
stack of separate boxes, the window becomes two SaftUI panels with thin lines between
steps. The user also asked for the guide's name in **Colus**, white, a little larger than
the step text, the way they have Questie's zone titles set up.

## The window today (RestedXP v1 guide window)

Top to bottom (`RXPGuides/GuideWindow.lua`, all frames under the global `RXPFrame`):

- **Current steps** (`RXPFrame.CurrentStepFrame`): the active steps, one bordered box each
  (`CurrentStepFrame.framePool[n]`), stacked with 5px gaps, growing upward from the guide
  name. Each box has a small tab at its top-left with the step's title ("Step 2", or a
  custom title; hidden when the title is empty), and per line a round completion checkbox,
  an icon glyph and the text. A step marked as a tip is moved out of the stack into its
  own floating window on `UIParent` (`RXPCData.tipWindow` holds its spot).
- **Guide name** (`RXPFrame.GuideName`): a 35px banner with RestedXP's banner art, a round
  logo and a class icon, and the guide's name centred on it. It overlaps the top of the
  step list. Right-click opens RestedXP's menu; dragging moves the window.
- **Step list** (`RXPFrame.BottomFrame`, scrolling `RXPFrame.ScrollFrame` /
  `RXPFrame.ScrollChild`): every step of the guide, one box each
  (`ScrollChild.framePool[n]`), with the step number at its bottom right. Steps other than
  the current ones are dimmed (alpha 0.66). Hovering a step lightens its box. Right-click or
  double-click opens a "Go to step" menu. A Blizzard `UIPanelScrollFrameTemplate` scroll
  bar with RestedXP's round button art runs down the right.
- **Footer** (`RXPFrame.Footer`): the version line ("RestedXP Guides v4.11.35"), a
  settings cog at the left and a resize grip at the right.

RestedXP restyles these from its theme in several places: when a theme loads or reloads
(`RXPFrame:UpdateVisuals`, `RXPFrame.UpdateScrollBar`), when a guide loads (the step list
is rebuilt), when the current step changes (`SetStep`, then `CurrentStepFrame.UpdateText`),
and when its font size setting changes. RestedXP's addon table is private; `RXPFrame` and
its children are global or reachable from it.

RestedXP also has a newer "v2" guide window, a beta option (`enableBetaFeatures` and
`enableV2Interface` in its settings). The user doesn't use it.

## Goals

1. **Two SaftUI panels.**
   - The current steps (the ones in the stack, not a tip) share one panel behind them all,
     with a thin line between steps where the 5px gaps are now.
   - The guide name, the step list and the footer share one panel, from the top of the
     guide name to the bottom of the footer. Thin lines separate the name from the list,
     the list from the footer, and each step from the next.
   - The panel is SaftUI's chat panel: SaftUI-Chat's `template` (default
     `thicktransparent`). Thin lines use a colour from SaftUI's palette that reads as a
     faint divider on that panel.
   - RestedXP's own boxes, borders and backgrounds on these frames are gone (no rounded
     borders, no per-step backgrounds).
2. **SaftUI's chat text.** Every text line in the window uses SaftUI-Chat's `font` (its
   face and outline; default `normal`, Agency FB with an outline).
   - Sizes keep following RestedXP's own "Guide font size" setting (default 9), with
     RestedXP's existing offsets: current step text at size + 2, step list at the size,
     step numbers at size − 1, footer at the size. The Agency FB face runs small, so the
     user will raise RestedXP's setting once.
   - RestedXP's text colours stay. The guide text carries colour codes with meaning (yellow
     notes, green NPC names, red warning markers), and the base text stays RestedXP's white.
3. **The guide name in Colus.** SaftUI's `title` font face (Colus), white, a few points
   larger than RestedXP draws it now (it uses size + 2); the user called it "slightly
   larger", as in their Questie tracker zone titles. The banner art, the round logo and the
   class icon are hidden.
4. **Step titles and numbers without boxes.**
   - The current steps' title tab ("Step 2") loses its box; the title becomes plain text in
     the step's top-right corner in a muted grey. (Builder's call where exactly, as long as
     it doesn't sit on the step text.)
   - The step list's numbers stay at the bottom right of each step, plain, in a muted grey.
5. **Hover and dimming keep working.** Hovering a step in the list still highlights it,
   now with SaftUI's highlight colour (the `highlight` template's fill) instead of
   RestedXP's blue. RestedXP's dimming of steps that aren't current (alpha) stays.
6. **A flat scroll bar.** The round up and down buttons are hidden, and the bar becomes a
   thin flat track with a flat grey thumb along the right edge of the list, in SaftUI's
   style. Scrolling by mouse wheel and by dragging the thumb still works.
7. **The tip window** (a current step RestedXP floats on its own) gets its own SaftUI panel,
   since it isn't inside the current steps' panel.
8. **Follows SaftUI's settings.** A profile change, or a change to SaftUI-Chat's panel
   template or font, restyles the window without a `/reload`. With SaftUI-Chat turned off,
   the skin uses SaftUI-Chat's defaults (`thicktransparent`, `normal`).
9. **Stays on through everything RestedXP does.** Loading another guide, advancing steps,
   changing RestedXP's theme or font size, resizing the window, and steps scrolling into
   view all keep the SaftUI look. No visible flash of RestedXP's style.

## Non-goals

- Every other RestedXP frame: the navigation arrow, the active item button, the targeting
  frame, menus, the settings panel, the guide picker, the v2 window. (The user: "let's just
  do that one for now.")
- RestedXP's newer "v2" guide window. While it's on, the skin leaves RestedXP alone.
- A setting to turn the skin off. SaftUI's other addon skins (Hekili, WeakAuras) are always
  on when their addon is loaded; this one matches. (Our call.)
- Changing what RestedXP shows, its text, its colours, or its behaviour.
- Using RestedXP's theme system. A theme can only set colours, a font and RestedXP's own
  border textures; it can't merge the boxes into one panel or use SaftUI's border. While
  the skin is on, RestedXP's theme choice no longer changes the window's look, except the
  settings cog's and the checkboxes' textures (see below). (Our call.)

## Anti-goals (a failure even if it looks right)

- Breaking anything RestedXP's window does: dragging it, resizing it from the grip,
  right-click and double-click menus on the name and on steps, the cog's menu, ticking a
  step line's checkbox, hovering a line for its tooltip, scrolling, RestedXP hiding
  completed steps.
- Errors when RestedXP isn't installed, isn't loaded yet, or a future RestedXP version
  renames a frame the skin expects. The skin should skip what it can't find, silently.
- Replacing RestedXP's scripts (`SetScript` on a frame RestedXP set up). Only add to them:
  `HookScript`, `hooksecurefunc` on RestedXP's frames and functions, or SaftUI's own
  frames layered on top. RestedXP replaces some scripts itself (each list step's
  `OnEnter`/`OnLeave`/`OnMouseDown` on every guide load), so hooks have to survive that.
- Re-styling everything on every frame of game time. RestedXP refreshes often while
  questing; the skin restyles on RestedXP's updates, not in an `OnUpdate`.

## Constraints

- **Where it lives:** a new skin in `SaftUI-Misc/Skinning/`, beside `hekili.lua` and
  `weakauras.lua`, as a module of the `Skinning` module (`SK:NewModule`), listed in
  `SaftUI-Misc/Skinning/load.xml`. It runs only when `RXPGuides` is loaded, including when
  RestedXP loads after SaftUI-Misc (load order isn't guaranteed: `RXPGuides` sorts before
  `SaftUI-Misc`, but the user may load either on demand).
- **Taint:** RestedXP's frames are plain insecure addon frames, so `.agents/taint.md`'s
  rules for Blizzard frames don't bind them, but don't touch a Blizzard frame through them
  (its scroll bar is Blizzard's template, created by RestedXP: restyling its textures is
  fine, it isn't secure). Nothing here runs protected code.
- **Clients:** written and checked against Forever's RestedXP (v4.11.35, interface 16001),
  which is what the user plays. RestedXP ships the same v1 window on its other clients, so
  nothing should be Forever-only, but only Forever gets checked in game.
- **SaftUI helpers:** panels through `st:SetBackdrop(frame, template)` on SaftUI-owned
  frames or on RestedXP frames, fonts through `st:GetFont(name):GetFont()`, colours from
  `st.config.profile.colors` / templates.
- **RestedXP is the user's install, not this repo.** A copy of v4.11.35's source for
  reading sits outside the repo; don't vendor it.

## Left to the builder

- Which RestedXP functions and frames to hook to catch each restyle, as long as goal 9
  holds. Known entry points: `RXPFrame:UpdateVisuals`, `RXPFrame.UpdateScrollBar`,
  `RXPFrame.CurrentStepFrame.UpdateText`, `RXPFrame.BottomFrame:StepScroll` /
  `BottomFrame.UpdateFrame`, the frame pools (`CurrentStepFrame.framePool`,
  `ScrollChild.framePool`), and frames' own `SetBackdrop`/`SetFont` calls.
- How to tell RestedXP's v2 window is on (for example its v1 frames staying hidden, or its
  saved settings) so the skin stands down.
- Whether to clear RestedXP's backdrops or make them transparent, and how the dividers are
  drawn (textures on RestedXP's frames or on SaftUI's panels), as long as hover still
  highlights and nothing flickers.
- The checkboxes (RestedXP's round art from its theme): leave them, or restyle them flat to
  match. Leave them if restyling means fighting RestedXP. Same for the settings cog and the
  resize grip, which keep working either way.
- The exact Colus size step for the guide name, the divider colour and the muted grey.
- Docs: `.agents/` topic docs and the README's Usage section get what a future agent or the
  user needs to know (the skin exists, what it follows, that it stands down for the v2
  window).
