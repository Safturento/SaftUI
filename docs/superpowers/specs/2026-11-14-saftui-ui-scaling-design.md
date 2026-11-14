# Scaling SaftUI across screens, pixel perfect

Design, 2026-11-14. It takes up the followup "Scale SaftUI across resolutions and stay pixel perfect"
(`docs/followups.md`) and absorbs the one it links, "UIParent's scale is set once, at login, so plates
leave whole pixels after a UI scale or display change". It is not yet approved as written: every
decision below that the owner didn't make is marked **call** and listed again at the end, under "Calls
made while writing this".

Checked against SaftUI's code on `modular` at `f13a2b7` and Blizzard's source for **Forever 1.60.1
(70938)** and **retail 12.1.5 (70783)** (Gethe/wow-ui-source, branches `forever` and `live`). Every fact
about the game is marked **confirmed** (with its source) or **inferred** (with the experiment that
settles it, E0 to E6 under Testing).

Words used below:

- **Unit**: what every size and offset in SaftUI's code and profile is measured in, a unit of UIParent.
- **Pixel**: a physical pixel of the screen.
- **k**: how many pixels one unit is for SaftUI's frames (UIParent's effective scale times the screen's
  height over 768). Today k is 1 on every screen.
- **Design height**: 1440, the screen height SaftUI's defaults were laid out on.
- **Line weight**: the whole number of pixels every border and line is drawn at.

## Why

SaftUI sets UIParent's scale so that one unit is one pixel on every screen. Its sizes are therefore
pixels: a 45 button is 45 pixels whether the screen is 1080, 1440 or 2234 pixels high. The owner tuned
every default on a 1440p monitor, so the same layout is a third larger, as a share of the screen, on a
1080p monitor and a third smaller on a 3456x2234 MacBook. The owner's friends play on exactly those two.

Scaling the layout is easy (one number on UIParent). Keeping it pixel perfect is the work: every
border, hairline and inset in SaftUI is written as "1" or "2" units, which at a scale other than 1 is
0.75 or 1.55 pixels, and the game then draws a border as no pixel, one or two, differently on each
side of a frame. This design makes the scale automatic, keeps every line on whole pixels at any scale,
and leaves the owner's 1440p screen exactly as it is.

## What the owner decided

1. **The request.** "Another thing I'd like to look at is being able to scale saft UI to work well
   across different resolutions and maintain pixel perfection..."
2. **Who it is for.** "I personally play on 1440p all the time, buuut I have friends who play at
   different resolutions including 1080p and 3456x2234 (mac) that are having scaling issues I'd like to
   resolve for them". So it must work on SaftUI's defaults with no setup (the followup's own reading).
3. **The fix.** Proposed in the followup and accepted, "I like that fix, lets do that" (2026-11-13): the
   scale is automatic, the screen's height over 1440 (0.75 at 1080p, about 1.55 on that Mac), with a
   "UI size" slider in Global settings to override it; borders are whole pixels, their scale rounded to
   a whole number and never under 1 (1 at 1080p and 1440p, 2 on the Mac); every size and position
   rounded to whole pixels.
4. **The pixel font stays.** First: "I almost wonder if this would be a good time to move away from
   pixel fonts anyways, maybe we can find a non pixel font that looks good at smaller sizes, agency fb
   is a great font but looks a bit rough when really small". Then, after trying the candidates in game
   (2026-11-14): "when playing with the scaling while on 1080p homespun actually looks great at .75 so I
   think we'll stick with it for now." So Homespun stays (design-system decision 41, which sets aside
   decision 12), and 0.75, what 1080p gives against 1440, is a size the owner has seen and approved.
5. **Design-system decision 11.** "SaftUI scales with the display: automatic from the screen's height
   against 1440, with a 'UI size' slider to override; borders in whole pixels. A project, after the
   tokens are in code."
6. **Start now.** "btw did the ui scaling work ever get started?", then, to starting the design, "Yeah
   lets start".
7. **A first-run setup dialog, later and separate.** "I wonder if it would be worth having an initial
   setup dialog that can work through a few steps and introduce the UI, this scaling could be a good
   first candidate - set a default based on the user's resolution but allow them to override it. I'm
   probably going to setup a few different unitframe configurations, so a follow up setup could be
   choosing which unitframe theme to choose (also picking which theme from thick, thin, blizzard, and
   any other that gets added)". The dialog is its own design. This one is built to fit it: the default
   SaftUI works out from the screen is kept apart from what the player chose, and the scale has one
   small interface (The scale interface, below) that a setup step and `/sui` both call.

## Goals

- On the friends' screens, with no setup, every part of SaftUI takes the same share of the screen as on
  the owner's 1440p one: 75% of its pixel size at 1080p, 155% on the 3456x2234 Mac.
- Every border, line, hairline and inset on whole pixels at every scale, under Thick, Thin and Blizzard.
- The owner's 1440p setup unchanged: the same UIParent scale to the last bit, the same borders, the same
  positions.
- A "UI size" slider over the automatic size, a "pixel for pixel" mode (today's behavior) and a mode
  that leaves the scale to the game; any choice recoverable, even one that makes `/sui` unusable.
- The scale follows display changes and Blizzard's UI Scale setting without a reload, and never touches
  a protected frame in combat.
- One small scale interface, used by `/sui` now and the first-run setup dialog later.
- Lua tests that prove whole pixels at 0.75, 1, 1.25 and 1.55, without doubling the suite's time.

## Non-goals

- Making other addons' frames, or Blizzard's own art, pixel perfect. They take SaftUI's scale, as they
  do today.
- A scale per profile, or converting saved positions and sizes between screens.
- Fitting the layout to other aspect ratios (an ultrawide's extra width, the Mac's narrower one): frames
  keep their anchors. A centered 16:9 area for ultrawides is under Later.
- Changing fonts: Homespun stays (decision 41). Font roles stay their own followup.
- The setup dialog itself.

## Anti-goals

What would make this a failure even if it works:

- **A blurry, missing or doubled border, or half-pixel text, at any supported scale**, on any theme.
- **The owner's 1440p setup changing at all by default**: a frame a pixel off, a border a different
  width, a font a different size.
- **A friend's layout scattered after the update**: frames leaving the screen, piling up, or losing their
  places relative to each other.
- **Combat errors from setting the scale at the wrong time**: an `ADDON_ACTION_BLOCKED` from
  `UIParent:SetScale` or from the pass that follows it, or taint reaching Blizzard's Edit Mode or action
  bars through it.
- **A scale the player can't get out of**: `/sui` too large to reach its controls, or too small to read,
  with no way back.

## How SaftUI scales today

From the code (confirmed by reading it):

- `SaftUI-Core/constants.lua:14-15`, at file load: `st.screenWidth, st.screenHeight =
  GetPhysicalScreenSize()` and `st.scale = 768/st.screenHeight`.
- `SaftUI-Core/init.lua:12-13`: the first line of `SaftUI:OnEnable` (PLAYER_LOGIN, through AceAddon) is
  `UIParent:SetScale(st.scale)`, before `Config:InitializeAceConfig()` makes the AceDB. There is no
  combat check, no event, and nothing sets it again: the followup "set once at login".
- So UIParent is 768/H, one unit is one pixel, and UIParent is W by H units (2560 by 1440 on the owner's
  screen).
- `SaftUI-Core/api.lua:26-49`: `st:GetPixelSize(frame)` is `(768 / H) / frame:GetEffectiveScale()`, one
  pixel in the frame's units; `st:RoundToPixel(value, frame)` rounds to whole pixels and trims to 1e-4.
  Both are right at any scale. 72 calls in 28 files use them (the action bars, the bags, chat, the buff
  frames, the totem bar, the objective tracker's position, edit mode's drags and nudges).
- Edit mode already works in pixels: the grid's center is rounded to a pixel (`EditMode/grid.lua:32-33`),
  its lines and the snap guides are one pixel thick (`grid.lua:69`, `snap.lua:248`), drags round their
  offsets (`mover.lua:226-227`), arrow keys move one pixel (`mover.lua:284-286`).
- The theme engine works in units that it assumes are pixels: `edgeSize = 1` and insets of 2 (Thick) or
  1 (Thin) (`theme.lua:67`, `428-441`), Thick's dark lines one unit outside and three wide
  (`theme.lua:316-347`), the Blizzard theme's single line on a small frame (`themeart.lua:599-605`). So do
  the options kit's boxes (`Config/optionslook.lua:58-73`, `296`), the close button
  (`panels.lua:335-343`), the color picker's rings (`Config/optionscolorpicker.lua:250-255`) and
  `st.BACKDROP` (`constants.lua:44-49`).
- The nameplates pin each plate's frame to UIParent's effective scale and turn on the game's layout
  rounding for SaftUI's frames on a plate (`SaftUI-Unitframes/nameplates/pixels.lua`), and give the
  driver a size in UIParent's units times UIParent's effective scale over WorldFrame's
  (`nameplates/nameplates.lua:479-486`). They pin again on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`,
  but UIParent is never set back to 768/H, so after either the plates are off whole pixels until a
  reload.
- Five frames listen to those two events (`EditMode/coordinates.lua:153`, `EditMode/settings.lua:56`,
  `EditMode/Bar/bar.lua:385`, `EditMode/Bar/barwindow.lua:386`, `nameplates/pixels.lua:96`); none sets
  the scale. The bar places itself again on the next frame because the events can fire before UIParent
  has its new size (`.agents/edit-mode.md`).
- The design system says it outright: "One unit is one physical pixel at SaftUI's UI scale (768 / screen
  height)" (`docs/design-system/tokens.json`, the `size` group), and `line-width` is "1px".
- The tests do the same: the shell sets `UIParent:SetScale(st.scale)` (`tests/lib/shell.lua:585-587`),
  the stub screen is 1920 by 1080 (`tests/wow/game.lua:17-18`), `set_screen(w, h)` sets 768/h
  (`tests/core/editmode_helpers.lua:20-23`), and the pixel checker counts whole UIParent units, not
  pixels (`tests/lib/pixels.lua`).

What the friends see today, with the owner's layout (taking the Mac's reported height to be 2234; E1
checks it):

| Screen | UIParent scale | UIParent in units | A 45 button | Its share of the height |
| --- | --- | --- | --- | --- |
| 2560 x 1440 (the owner) | 0.5333 | 2560 x 1440 | 45 px | 3.1% |
| 1920 x 1080 | 0.7111 | 1920 x 1080 | 45 px | 4.2%, a third larger |
| 3456 x 2234 (the Mac) | 0.3438 | 3456 x 2234 | 45 px | 2.0%, a third smaller |

## What the game does

- **F1. Units.** A region's size in pixels is its size in units times its effective scale times the
  screen's height over 768; UIParent at scale 1 is 768 units high on any screen. **Confirmed:**
  [warcraft.wiki.gg, UI scaling](https://warcraft.wiki.gg/wiki/UI_scaling); Blizzard's
  `PixelUtil.GetPixelToUIUnitFactor()` is `768.0 / physicalHeight`
  ([PixelUtil.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/PixelUtil.lua),
  the same file on `forever`). So UIParent's height in units depends only on its scale, never on the
  screen.
- **F2. `GetPhysicalScreenSize()`** is the game's drawing size in pixels: "Returns physical screen size of
  game" ([warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/API_GetPhysicalScreenSize)); a 2560x1440
  monitor reports 2560, 1440 ([WoWInterface, "UI Scaling"](https://wowinterface.com/forums/showthread.php?p=329822)).
  **Inferred** for a Retina Mac: it reports device pixels (3456 x 2234 when the game runs at the panel's
  own resolution), not macOS points (1728 x 1117). Blizzard's own checkout window multiplies its size by
  `GetScreenDPIScale()` and compares the result with `GetPhysicalScreenSize()`
  (`Blizzard_SimpleCheckout.lua`, `CalculateDesiredSize`), which only makes sense if the second is in
  device pixels and the first is 2 on a Retina display. The friend may also run the game at a lower
  resolution than the panel's. E1 prints all of it. The design reads the value at run time, so either
  answer works; only the worked numbers below change.
- **F3. Windowed mode.** **Inferred:** in a window, `GetPhysicalScreenSize()` is the window's drawing
  size, so a 1440p monitor in a window with a title bar and taskbar can report about 1377 high. E2
  checks.
- **F4. Render scale** (`RenderScale`, Graphics > Render Scale) is the 3D world's resolution: Blizzard's
  slider labels it as the window's resolution times the value (`FormatDisplayableResolution` in
  [Graphics.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua)).
  **Inferred:** the UI is drawn at the full resolution and `GetPhysicalScreenSize()` doesn't change with
  it. E1 checks on the Mac, where render scale is the usual way to keep frame rates up.
- **F5. Blizzard's UI Scale** is two settings, `useUiScale` (a check box) and `uiScale` (a slider from
  0.65 to 1.15 in steps of 0.01), the same on both clients (`Graphics.lua`, live line 817, forever line
  931). With the box off UIParent takes a default per resolution (1.00 at 1920x1080, 0.64 at 2560x1440
  on retail), and the game ignores a `uiScale` under 0.64, which is why addons call `UIParent:SetScale`
  for anything smaller. **Confirmed:** [warcraft.wiki.gg, UI scaling](https://warcraft.wiki.gg/wiki/UI_scaling).
  The Screen API also has `GetDefaultScale()` and `GetScreenDPIScale()`, on both clients
  ([ScreenDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ScreenDocumentation.lua)).
  **Inferred:** `GetDefaultScale()` is that default; E1 prints it beside the wiki's table.
- **F6. `UI_SCALE_CHANGED`** is a synchronous event
  ([UIManagerDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UIManagerDocumentation.lua),
  the same on both). Blizzard's Lua never sets UIParent's scale: its handler only runs
  `UpdateScaleForFitForOpenPanels()` (`Blizzard_Game/Mainline/EventImplementation.lua:268-270`, both
  branches), and Blizzard's Edit Mode re-places its right action bars on it and on
  `DISPLAY_SIZE_CHANGED` (`Blizzard_EditMode/Shared/EditModeManager.lua:200-202`). **Confirmed** from that
  source. So the engine applies `uiScale` itself. **Inferred, unknown:** whether the engine sets
  UIParent's scale again, over an addon's, when the display changes or when the player moves
  Blizzard's slider, and whether an addon's own `UIParent:SetScale` fires `UI_SCALE_CHANGED`. E3 settles
  both.
- **F7. The MacBook's notch.** `C_UI.ShouldUIParentAvoidNotch()`, `C_UI.GetTopLeftNotchSafeRegion()` and
  `NOTCHED_DISPLAY_MODE_CHANGED` exist on both clients, and Blizzard's `UpdateUIParentPosition()` moves
  UIParent's top left down by the notch's height, on `PLAYER_ENTERING_WORLD` and on that event
  ([UIParentUtil.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIParentUtil/UIParentUtil.lua),
  identical on `forever`; `Blizzard_Game/Shared/EventImplementation.lua:47-49`, `309`). **Confirmed.** So
  on a 3456x2234 MacBook Pro UIParent may be shorter than the screen, its center moves down by half the
  notch, and an odd notch height in pixels puts every center-anchored frame on a half pixel. E1 prints
  the notch.
- **F8. `SetScale` is a protected function** (`IsProtectedFunction = true` in `SimpleFrameAPIDocumentation.lua`,
  both branches): it is refused on a protected frame in combat. **Inferred:** UIParent is protected in
  combat, since protection spreads from a protected frame to its parents (`.agents/taint.md`, rule 6) and
  UIParent is the parent of every secure frame; ElvUI defers its `UIParent:SetScale` to
  `PLAYER_REGEN_ENABLED` for the same reason (`E:UIScale` in
  [ElvUI's PixelPerfect.lua](https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/General/PixelPerfect.lua),
  commit 55de8e8, 2026-09-17). E4 checks.
- **F9. The game's layout rounding.** `SetRoundLayoutToNearestPixel(enabled)` is a ScriptRegion method on
  both clients (protected, so refused only on a protected frame in combat), and Blizzard marks
  `PixelUtil.SetWidth`, `SetHeight`, `SetSize` and `SetPoint` "DEPRECATED: Use SetRoundLayoutToNearestPixel
  instead for native code to automatically apply the same adjustment" (`PixelUtil.lua`). **Confirmed.**
  **Unknown:** whether it rounds each size and offset (as PixelUtil did) or the region's final edges,
  which decides whether a frame anchored to a half-pixel center lands whole. E5 settles it.
- **F10. Textures snap to the pixel grid on their own** (`SetSnapToPixelGrid`, `SetTexelSnappingBias`,
  `IsSnappingToPixelGrid` in `SimpleTextureBaseAPIDocumentation.lua`). **Inferred:** on by default, which
  is why a one-unit line at a scale that isn't 1 comes out as no pixel, one or two (the nameplates saw
  exactly that in game, `pixels.lua`'s header). E5 prints the default.
- **F11. Blizzard's backdrop** draws its edge pieces `edgeSize` units wide, with no pixel rounding
  (`SetupPieceVisuals` and `ApplyBackdrop` in
  [Backdrop.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua),
  identical on `forever`). **Confirmed.** So `edgeSize = 1` at k = 0.75 is a 0.75 pixel line, which F10's
  snapping turns into 0 or 1 pixel by where it falls: the friends' broken borders.
- **F12. ElvUI's model, for reference.** UIParent takes the player's scale; `E.mult = (768 /
  physicalHeight) / scale` is one pixel; borders are multiples of `E.mult`; `E:Scale(x)` snaps a length
  to multiples of it; the scale is read again on `UI_SCALE_CHANGED` and set after combat
  (`PixelPerfect.lua`, above). **Confirmed** from that file. This design is the same idea with an
  automatic scale and a whole-number line weight.

## The scale model

### Where the scale goes

**UIParent's scale, as today (call).** Weighed:

- **UIParent:SetScale** (chosen). One call, out of combat. Everything SaftUI draws, the Blizzard frames it
  skins and moves, and their holders all keep sharing one scale, as they do now. The nameplates already
  pin their frames to UIParent's effective scale and set the game's own plate scaling to 1
  (`nameplates/cvars.lua`), so they follow with no change but the timing of the pin. Nothing is
  re-parented and no saved anchor changes meaning.
- **A SaftUI parent frame with its own scale** (ElvUI's `E.UIParent`): every SaftUI frame made on
  UIParent (104 `st:CreateFrame` and 188 `CreateFrame` calls, in 54 and 84 files) re-parented; the secure
  ones (unit frames, group headers, action bars) only before combat; the 23 default positions anchored
  to `'UIParent'` by name would no longer be in their frame's units; and every Blizzard frame SaftUI holds
  (chat, the buffs, the tracker, the minimap) would stay at UIParent's scale while its holder took
  SaftUI's, so holder and frame would disagree on every size. Rejected.
- **Every size and offset multiplied by k**: 528 size calls and 831 anchor calls in about 110 files, every
  module, never finished. Rejected.

Other addons' frames under UIParent take SaftUI's scale, as they already do (SaftUI overrides the game's
UI scale today). On the 1080p friend's screen they get a quarter smaller than today; on the Mac they get
larger. That is the same share of the screen they would have on the owner's.

### The default and the choice

Two things are kept apart, so `/sui` and a later setup step can each show what SaftUI would pick and
what the player picked:

- **The computed default**: what SaftUI works out from the screen, the automatic factor below. It is
  never saved; it is worked out again whenever the screen changes.
- **The player's choice**: `{ mode, size }`, saved account-wide in `st.config.global.uiScale` (call:
  per WoW account on this computer, never in a profile, so a profile shared with someone else keeps each
  screen's own size, and a profile switch never changes the scale). Nothing saved means the default
  choice, `{ mode = 'auto', size = 1 }`. A per-setting reset removes the save.

### The formula

```
H     = select(2, GetPhysicalScreenSize())        -- read every time, never cached at file load
raw   = H / 1440                                  -- the design height
n     = floor(raw + 0.5)
auto  = (n >= 1 and abs(raw - n) <= 0.05) and n or raw   -- snap to a whole number within 5%
auto  = max(auto, 0.75)                           -- never smaller than the 1080p size

k = auto * size                 -- Automatic (size 0.70 to 1.50, steps of 0.05, default 1.00)
k = 1                           -- Pixel for pixel
k = UIParent:GetScale() * H / 768    -- The game's UI scale: measured, never set

uiScale    = (768 / H) * k      -- what SaftUI sets on UIParent (Automatic and Pixel for pixel)
pixel      = 1 / k              -- one pixel in UIParent's units
lineWeight = max(1, floor(k + 0.5))
line       = lineWeight * pixel -- every border and line, in UIParent's units
```

- **The snap band (call).** Within 5% of a whole number the automatic part is that number, so a screen
  1368 to 1512 pixels high draws pixel for pixel. It keeps the owner's 1440p monitor at exactly 1 in a
  window too (F3: about 1377 high), and a whole k needs no rounding at all, which is the crispest case.
- **The floor (call).** The automatic part never goes under 0.75. Under 1080 pixels high the layout no
  longer fits in proportion (a 768-high screen is 1024 units high), but text stays at the size the owner
  judged "great" at 1080p; without the floor a 768p laptop would draw Homespun at 5.3 pixels.
- **The UI size (call).** 70% to 150% in steps of 5%, default 100%, a multiplier over the automatic part.
  On short screens its top is lowered so UIParent is never under 768 units high (Blizzard's own design
  height, and what `/sui`'s 700 to 728 tall window plus the screen edge margin needs): the top is the
  largest step at or under `H / (auto * 768)`, which only bites under 864 pixels high (a 768p screen
  stops at 130%).
- **Bit for bit at 1440.** On the owner's screen `raw` is exactly 1, `n` is 1, `auto` is the integer 1 and
  `uiScale` is `(768 / 1440) * 1`, the same float as today's `768/st.screenHeight`. Pixel for pixel is
  `k = 1` with no arithmetic at all.

### The three modes

The **Scale** choice (call):

- **Automatic** (default): the formula, with the UI size slider.
- **Pixel for pixel**: k = 1, today's behavior on every screen. Sizes are pixels; SaftUI looks larger on a
  smaller screen. An exact way back for anyone who tuned a layout to today's sizes, and a fallback if the
  automatic size misbehaves on someone's machine.
- **The game's UI scale**: SaftUI stops setting UIParent's scale and leaves it to Blizzard's UI Scale
  setting (F5). On switching to it SaftUI sets UIParent once to the game's own value (`uiScale` while
  `useUiScale` is on, else `GetDefaultScale()`, E1) and never again; on later logins it sets nothing. k is
  then measured, and the line weight and whole-pixel rounding still follow it, so borders stay whole at
  whatever size the game gives.

### Worked values

At 100% UI size, from the formula (the Mac row assumes F2's 2234):

| Screen | k | UIParent scale | UIParent in units | One pixel | Line weight | Homespun 10 | A 45 button |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1366 x 768 | 0.75 (floor) | 0.7500 | 1821 x 1024 | 1.333 u | 1 px | 7.5 px | 34 px |
| 1920 x 1080 (friend) | 0.75 | 0.5333 | 2560 x 1440 | 1.333 u | 1 px | 7.5 px | 34 px |
| 1920 x 1200 | 0.8333 | 0.5333 | 2304 x 1440 | 1.2 u | 1 px | 8.3 px | 38 px |
| 2560 x 1377 (window) | 1 (snap) | 0.5577 | 2560 x 1377 | 1 u | 1 px | 10 px | 45 px |
| 2560 x 1440 (owner) | 1 | 0.5333 | 2560 x 1440 | 1 u | 1 px | 10 px | 45 px |
| 3440 x 1440 | 1 | 0.5333 | 3440 x 1440 | 1 u | 1 px | 10 px | 45 px |
| 2560 x 1600 | 1.1111 | 0.5333 | 2304 x 1440 | 0.9 u | 1 px | 11.1 px | 50 px |
| 3024 x 1964 (MacBook Pro 14) | 1.3639 | 0.5333 | 2217 x 1440 | 0.733 u | 1 px | 13.6 px | 61 px |
| 3456 x 2234 (friend) | 1.5514 | 0.5333 | 2228 x 1440 | 0.645 u | 2 px | 15.5 px | 70 px |
| 3840 x 2160 | 1.5 | 0.5333 | 2560 x 1440 | 0.667 u | 2 px | 15 px | 68 px |
| 5120 x 2880 | 2 | 0.5333 | 2560 x 1440 | 0.5 u | 2 px | 20 px | 90 px |

Outside the snap band and above the floor, UIParent is always 0.5333 times the UI size, and always 1440 /
size units high: a resolution change at the same UI size changes no unit, only the pixel size and the
line weight.

### The owner's 1440p screen

k is 1, so the pixel is 1 unit, the line weight 1, `line` 1, every inset 2 or 1, and every rounding below
is a no-op on the whole numbers SaftUI already uses. UIParent's scale is the same float as today. Nothing
the owner sees changes, in any phase; the only new thing is the UI scale section in `/sui`. The tests
hold the k = 1 numbers exactly (Testing).

## Whole pixels at any scale

### The pixel grid

A frame is on the grid when each of its four edges is a whole number of pixels from the screen's bottom
left. UIParent's own edges always are. A frame SaftUI places is on the grid when:

1. its size is a whole number of pixels, and an even number on an axis it is anchored by its center
   (TOP and BOTTOM center it across, LEFT and RIGHT up and down, CENTER both; the half-pixels rule of
   `.agents/architecture.md`, now in pixels, not units);
2. its offsets are whole numbers of pixels;
3. what it is anchored to is on the grid.

Saved values are never rewritten to suit a screen (call): a profile keeps design units, so it means the
same on every screen, and rounding happens where a frame is placed or sized. (A drag or nudge still
stores whole pixels of the screen it was made on, as now.)

Where the anchor can't be known to be whole (a Blizzard frame, another addon's, UIParent's center on a
screen of odd width or height, or moved by an odd notch, F7), either the game's layout rounding puts the
frame on the grid (if E5 shows it rounds edges) or the frame may sit a fraction off; a border of whole
line weight still draws whole there under F10's snapping, and only its place drifts by under a pixel.

### Tokens and helpers

Core gains (call; names the builder may change, meanings not):

- `st.pixel`: one pixel in UIParent's units (1/k). Not the Pixel font, whose key is the string `'pixel'`.
- `st.lineWeight`: the whole number of pixels a line is (1 or 2 on today's screens).
- `st.line`: `st.lineWeight * st.pixel`, one line in UIParent's units.
- `st:GetPixelSize(frame)` (exists): one pixel in a frame's own units, for frames whose effective scale
  isn't UIParent's (lists and menus matched to their owner, frames of Blizzard's).
- `st:GetLineSize(frame)`: one line in a frame's units. Never trimmed: `st:RoundToPixel`'s 1e-4 trim
  makes a line 0.999975 pixels at k = 0.75, which F10's snapping can round to nothing at a half-pixel
  edge.
- `st:RoundToPixel(value, frame, minPixels)` (exists, gains PixelUtil's `minPixels`): a non-zero gap or
  spacing setting rounds to at least one pixel (call), so a "1" gap never disappears at 0.75.
- `st:FloorToPixel`, `st:CeilToPixel`: the grid's versions of the `floor` and `ceil` that layouts use today
  to make a position whole.
- `st:EvenPixels(value, frame)`: a length rounded up to an even number of pixels, for frames centered on an
  axis. The action bars' `EvenIfCentred` (`SaftUI-ActionBars/bars.lua:167-170`) and the totem bar's
  `EvenPixels` (`SaftUI-Misc/totemlayout.lua:92-95`) already do this in pixels and move onto it, as
  `.agents/architecture.md` says they should once a second addon needs it.

The tokens are set at login and after every change of scale, before anything reads them. The design
system's `line-width` becomes "one line: `lineWeight` pixels", `mark-width` "two lines", `thick-width`
"three lines". If the tokens table (`docs/design-system/30-code-changes.md`, change 1,
`SaftUI-Core/tokens.lua`) lands first, these live there; decision 11 put this work after it, but phase 1
doesn't need it (call), and the table absorbs the tokens when it comes.

### The line weight

Every border and line is `lineWeight` pixels: `max(1, floor(k + 0.5))`, the rule the owner accepted. 1
pixel up to k = 1.49, 2 from 1.5 (the Mac, 4K, 5K), 3 from 2.5. A Thick frame is three lines (dark,
border, dark), each `lineWeight` wide: 6 pixels on the Mac. Marks (`mark-width`: the own mark, the selected
sidebar bar, the tab underline, the edit mode bar's hidden strip, the History list's current step) are two
lines. The button press's 1px shift is one line.

### What scales and what stays in pixels

| What | Rule | 1080p (k 0.75) | 1440p (k 1) | Mac (k 1.55) |
| --- | --- | --- | --- | --- |
| Borders: Thick's three lines, Thin's line, the Blizzard theme's single line on a small frame; hairlines, dividers, outlines, edit mode's grid lines and snap guides | one line | 1 px | 1 px | 2 px |
| Marks | two lines | 2 px | 2 px | 4 px |
| Theme insets: Thick 2, Thin 1 | that many lines | 2 / 1 px | 2 / 1 px | 4 / 2 px |
| Arrow-key nudges in edit mode | one pixel, Shift ten (unchanged, call) | 1 px | 1 px | 1 px |
| Every other size and offset: frames, buttons, gaps, spacing, fonts, icons, the screen edge margin, the grid size, Blizzard-look art | times k, rounded to whole pixels where placed | x0.75 | x1 | x1.55 |

### The theme engine

Phase 1's core. In `SaftUI-Core/theme.lua` and `themeart.lua`:

- `INSETS = { thick = 2, thin = 1 }` becomes a count of lines (`LINES`). `st:ResolveTheme` adds the count
  to the look (`look.lines`) and gives `look.inset` in UIParent's units, `lines * st.line`. A Blizzard
  look's inset is its kind's art inset (`st.ThemeArt.Inset(kind)`), which scales with k like the art,
  rounded to whole pixels.
- `Paint` draws with the drawn frame's own line, `st:GetLineSize(frame)`: `edgeSize` is one line, the
  insets `lines` lines.
- `CreateAltBorder` still makes Thick's four strips once, but `Paint` lays them on every draw: one line
  outside the frame, three lines wide.
- `Placement` puts a backdrop `look.inset` outside its owner, in the owner's units (`lines` lines of the
  owner's).
- `ThemeArt.Paint`'s line on a small frame (`themeart.lua:599-605`) is one line.
- The record of each drawn frame keeps the inset in that frame's units, so `st:DrawnInset(frame)`,
  `st:DrawnKind`, `st:CalculateSpacing` and the 23 readers of `st:ThemeInset` and `st:DrawnInset` (20
  files) get whole-pixel insets with no change; a reader that adds a literal (`Blizzard_BuffFrame.lua:240`
  adds 1, `totemtimers.lua:143` doubles it) is checked in its addon's pass.
- The header strips and the close button draw fills only, as now.
- Every drawn frame gets the game's layout rounding (`SetRoundLayoutToNearestPixel(true)` on the frame,
  its backdrop's pieces and Thick's strips) if E5 shows it rounds edges, as the plates already do; not
  otherwise (call, decided by E5).
- `st.BACKDROP` (`constants.lua:44-49`) and the close button's backdrop and dark line
  (`panels.lua:335-343`) take one line: they're Core's and in-world (the bags' close button).

A theme redraw (`st:RedrawThemed()`) draws every frame at the current line weight, so a scale change
reaches every border through the pass below.

### Placement: sizes, offsets and centered frames

A size or offset SaftUI hands the game, where the frame has a border or meets a line, goes through the
grid's helpers. Where the frame sits flush against a neighbor, both are rounded the same way, so a row of
buttons keeps equal gaps. `st:PlaceAtPosition(frame, position)` rounds its offsets to whole pixels (call):
at k = 1 its inputs are already whole, so nothing moves for the owner, and at 0.75 a saved 5 lands at 4
pixels instead of 3.75. Sites that round already (`st:PlaceHolder`, `AB:PlaceFrame`) keep their own.

### Fonts

Font objects are sized in units (`SaftUI-Core/Media/fonts.lua:48-72`), so text follows k with no code:
Homespun 10 is 7.5 pixels at 1080p (the size the owner saw in `/suifonts` and approved) and 15.5 on the
Mac. **Call: fonts follow the scale, unrounded.** The font demo is the evidence for 0.75; nothing yet
says whether Homespun is crisp at 15.5. E6 shows the Mac friend 15, 15.5 and 20 pixels. If 15.5 is rough,
the one place to change is `FN:UpdateFontConfig`, which every scale change already runs (the pass below
reaches `FN:UpdateConfig`): a rule per face (for example, Homespun at a whole multiple of 10 pixels from
k = 1.5) goes there, with no caller changing. The game draws text on whole pixels itself (the pixel
checker leaves font strings out for that reason), and the 1px outline stays one pixel at any scale.

### Icons, textures and Blizzard's art

- **Lucide icons** are 32x32 TGAs drawn at 16, 20 or 24 units (`.agents/architecture.md`). They are sized
  to an even whole number of pixels, centered on a whole pixel: 12 px for a 16 at 1080p, 24 on the Mac.
  The kit's `W.IconButton` already errors when an icon would sit off whole pixels
  (`optionscontrols.lua:276`); it checks in pixels. **Call:** version one keeps the 32 px files; at k = 2
  they are drawn exactly 1:1, at 1.55 they are shrunk by 1.29, which may look soft (G3). A second size for
  dense screens is under Later.
- **Status bar textures** (SaftUI Flat and the rest) stretch; nothing to do.
- **The Blizzard theme's art** (atlases, the metal, the bronze box) scales with k as Blizzard's own UI does
  at any UI scale. Its offsets and insets (`MetalReach`, `Top`, the kinds' insets) are rounded to whole
  pixels where SaftUI places them; the art itself is not given a line weight (call).

### Nameplates

The plates are WorldFrame's children and the game scales them itself (by distance and for the target);
SaftUI pins its frame on each plate to UIParent's effective scale and sets the game's plate scaling to 1,
so a plate follows k like everything else and keeps the theme's whole-line borders through the engine.
Three changes:

- The pin and the plate size run after Core has set the scale (The order with the nameplates, below), not
  from their own event frame.
- `UF.PlateDriverSize` gives the driver a whole, even number of pixels on each axis. The defaults' rule
  that "every size on a plate is an even number of pixels" (`config/units/nameplate.lua`) holds in units
  only at k = 1: at 0.75 the 20 high bar is 15 pixels. The plates' rounding (`UF.RoundLayout`) already
  turns on the game's layout rounding; the phase 4 pass makes the plate's own parts even in pixels where
  they are centered.
- The followup "set once at login" is resolved: UIParent is set again on every change (below).

### Frames that aren't SaftUI's

Blizzard's frames and other addons' take SaftUI's scale and draw as their own code does. SaftUI's
backdrops behind them (`st:SetBackdropIn`) are SaftUI's and follow the rules above in the backdrop's own
units.

## The audit

Every class of code that assumes one unit is one pixel, with counts from `grep` over the addons' Lua
outside `Libraries/` (228 files) at `f13a2b7`, and the phase that changes it:

| # | Class | Count | Where | Phase |
| --- | --- | --- | --- | --- |
| A1 | Backdrops with a one-unit edge or insets | 11 `edgeSize` in 7 files, 12 raw `SetBackdrop({...})` in 7 | `theme.lua:433`, `themeart.lua:603`, `constants.lua:47`, `panels.lua:335,343` (phase 1); `Config/optionslook.lua:61,71,296`, `Config/optionscolorpicker.lua:250,255` (phase 2); `Dev/fontdemo.lua:146` (goes with the demo) | 1, 2 |
| A2 | Thick's lines and the theme insets | 4 strips, 1 table, 1 placement | `theme.lua:67,316-347,450-453` | 1 |
| A3 | Readers of the theme's inset | 23 calls in 20 files | `st:ThemeInset`, `st:DrawnInset`, `st:CalculateSpacing`; follow by themselves, the two that add a literal are checked | 1, 4 |
| A4 | One-unit lines (textures 1 unit thick) | 17 real lines in 12 files (of 26 `SetHeight(1)`, `SetWidth(1)`, `SetSize(x, 1)` and `SetSize(1, x)` calls; the other 9 are first sizes of frames sized later, which stay); `OB.HAIRLINE`/`OB.LINE` used 12 times in 6 files; 2 already at `st:GetPixelSize` | `optionsbody.lua:1207,1283`, `optionswindow.lua:272,1351,1429,1430`, `optionssmalldialog.lua:173`, `optionscontrols.lua:415`, `EditMode/Bar/bar.lua:236`, `barwindow.lua:269`, `historylist.lua:142` (phase 2); `categoriestab.lua:618,1156`, `ruleeditor.lua:1038`, `Loot/roll.lua:152`, `rollbar.lua:136`, `Feed/feed.lua:636`, and the two at one pixel, `Blizzard_ObjectiveTracker.lua:249` and `Tracker/window.lua:463` (phase 4) | 2, 4 |
| A5 | One-unit offsets putting a line on or inside a border | 53 `SetPoint` calls with a literal ±1 in 22 files, 7 of them in `Core/Config` | the kit's boxes' dark lines, the close button, list rows, the micro menu, chat | 2, 4 |
| A6 | Whole-unit math (`floor` and `ceil` that make a position or size whole) | about 240 calls in 61 files: `Core/Config` 119, `EditMode` 42, Bags 21, Misc and its skins 18, Unitframes 8, Loot 6, Tracker 5, ActionBars 4, Minimap 4, Chat 2 | the options kit's pure layout (`OW.LayoutRows`, `OW.LayoutSections`, `OW.MiniLayout`, `EM.BarLayout`, `EM.WindowLayout`) and every centering `floor((a - b) / 2)`; counts and indices stay | 2, 3, 4 |
| A7 | Already in pixels | 72 calls of `st:RoundToPixel`/`st:GetPixelSize` in 28 files | correct at any k; edit mode's four (`grid.lua:69`, `snap.lua:59,248,274`) move from one pixel to one line, and snapping's "the border's outermost pixel `[p, p + pixel)`" becomes `[p, p + line)` | 3 |
| A8 | Even lengths for centered frames | 9 calls in 2 files (already in pixels); the plates' even sizes in units | `bars.lua:167-170`, `totemlayout.lua:92-95` move onto `st:EvenPixels`; `config/units/nameplate.lua` | 1 (helper), 4 |
| A9 | Frames with a scale of their own | 12 `SetScale` calls in 8 files | lists and menus matched to their owner (`optionslist.lua:273`, `categoriestab.lua:526`), the bag slot cooldown, the buff frame's anchors, the micro buttons, the font demo; their lines use `st:GetLineSize(frame)` | 2, 4 |
| A10 | Every other size and anchor | 528 `SetSize`/`SetWidth`/`SetHeight` and 831 `SetPoint` calls in about 110 files | scale with k by construction; rounded only where they carry or meet a border. E5 decides how many: if the game's layout rounding rounds edges, turning it on in `st:CreateFrame` (104 calls in 54 files) takes most of them | 2, 4 |
| A11 | Fonts | 23 `SetFont` calls in 11 files, the font objects in `Media/fonts.lua` | follow k with no change; a rule per face only if E6 asks | none (5 if needed) |
| A12 | Icons | 51 uses of `st.icons` in 19 files | even whole pixels; `W.IconButton`'s check in pixels | 2, 4 |
| A13 | Constants read once | `constants.lua:14-15` (`st.screenWidth`, `st.screenHeight`, `st.scale`), read only by `init.lua` and the test shell | replaced by the scale interface | 1 |
| A14 | Texts that say "in pixels" | 17 in 11 files (chat's size, the grid size, font shadow and spacing, the minimap, the totem bar, unit frame name width, auras, class power, indicators, plates) | kept (call); the UI scale section says what a SaftUI pixel is | none |
| A15 | Docs and tokens that say a unit is a pixel | `README.md:3,17`; `docs/design-system/tokens.json` (`size` note, `line-width`, `mark-width`, `thick-width`); `docs/design-system/README.md:3,56,62`; `.agents/architecture.md` (the half pixels bullet, the plates' whole pixels) | rewritten for the scale model | 1 |
| A16 | Tests that assume a unit is a pixel | `tests/lib/shell.lua:585-587`; `set_screen` (`tests/core/editmode_helpers.lua:20-23`); `tests/lib/pixels.lua`; 32 files that set the screen or UIParent's scale; 31 files with 102 `P.off` calls | Testing, below | 1 |

## Saved positions and sizes

### What a saved number means now

Positions are `{ point, frame, rel_point, x_off, y_off }` in units, sizes in units. In Automatic mode
UIParent is 1440 / size units high on every screen, so the same numbers put a frame at the same place
as a share of the screen's height, relative to its anchor: the owner's player frame, 157 units left of the
screen's center and 130 below it, is 118 by 98 pixels from the center at 1080p, 157 by 130 at 1440p and
244 by 202 on the Mac, the same share each time. That is the point of the model, and why nothing is
converted.

### Aspect ratios

Width in units is the height in units times the screen's width over its height: 2560 at 16:9, 2304 at
16:10, 2228 on the Mac, 3440 on a 21:9 ultrawide. A frame keeps its distance to its anchor point, in
units, so frames anchored to the center stay centered, frames anchored to an edge stay at that edge, and
on the Mac's narrower screen the left and right groups are each 166 units closer to the middle than on the
owner's. SaftUI's defaults anchor to an edge or to the center with modest offsets (of the 192 anchor
points in the defaults, frames' and their parts': 47 at a top corner, 46 at a bottom corner, 27 CENTER,
72 at an edge's middle), and the largest x offsets from the screen are 500 (the loot feed, from the
bottom right) and 320 (the tracker's nearest quest item button, from the top right), so nothing crosses
the middle on the Mac. A frame a player dragged far from its anchor can overlap one from the other side on a narrower
screen; the screen edge margin keeps everything on screen, and edit mode moves it.

### Nothing is converted

No saved position, size, grid size, margin or window place is rewritten when the scale or the screen
changes (call). Offsets saved by a drag or nudge at k other than 1 are whole pixels at that k, so they
hold fractions of a unit (a nudge at 0.75 stores 1.3333); they are kept to 1e-4 as now, mean the same
place on any screen, and show with one decimal at most (the Coordinates label already does,
`EditMode/coordinates.lua:54-60`; the Position editor's boxes do the same, phase 3).

### What is placed again, and when

On every applied change of scale (login after the scale is set, a choice changed, `UI_SCALE_CHANGED`,
`DISPLAY_SIZE_CHANGED`, `NOTCHED_DISPLAY_MODE_CHANGED`), through the pass below:

- every frame in the screen edge margin is clamped again (`st:UpdateScreenMargin`, step 4 of the
  profile update), with the margin itself rounded to whole pixels (20 units is 31.03 pixels on the Mac);
- `/sui` keeps its saved top right corner and is shown inside the margin, its saved height held to
  `OW.MaxHeight` and its saved size held to what the screen fits (`OW.Fits`, half when full doesn't), the
  save untouched, as for a margin change today;
- the edit mode bar's slide position (`editModeBar.dockX`), the floating window's place and the History
  list are placed again inside the margin, the saves untouched (`EM:PlaceBar`, `EM:PlaceBarWindow`,
  `EM:PlaceHistoryList`);
- the grid and the Coordinates label are drawn again;
- the plates are pinned and sized again.

These listeners already run on the two screen events; each also runs on the scale interface's change
callback, since E3 may show that SaftUI's own `SetScale` fires no event.

### A profile shared between screens

The main case: the owner exports his profile and a friend imports it. The friend's scale choice isn't in
the profile, so the import keeps the friend's own: in Automatic the owner's layout lands at the same
shares of the friend's screen. A friend in Pixel for pixel sees it at today's pixel sizes instead. A
frame the friend then moves is the friend's copy only; profiles are copied by export, not synced.

## When the scale is set

### At login

`SaftUI:OnEnable` runs `Config:InitializeAceConfig()` first (the choice is in `st.config.global`), then the
scale interface's start, then the rest as now. AceAddon enables an addon's modules only after its own
`OnEnable` returns (`AceAddon:EnableAddon`, `SaftUI-Core/Libraries/Ace3/AceAddon-3.0/AceAddon-3.0.lua:516-538`),
so every module builds at the final scale and reads the final tokens. If `InCombatLockdown()` is true
there (a `/reload` in combat), the scale waits for the end of combat (F8): the modules build at whatever
scale the game set, and the pass below puts everything right when the fight ends. Today's line runs with
no check; that is safe only as long as the loading screen is never locked down, which nobody has checked
(G7).

### On a change

One frame of Core's hears `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED` and `NOTCHED_DISPLAY_MODE_CHANGED`
and asks for one check on the next frame (`C_Timer.After(0)`; several events in a frame make one check),
because the events can fire before UIParent has its new size and so SaftUI's scale lands after the
engine's own. The check:

1. works out the current choice on the current screen;
2. in Automatic and Pixel for pixel, if UIParent's scale differs from `uiScale` by more than 1e-5: out of
   combat it calls `UIParent:SetScale(uiScale)`, in combat it waits (`st:QueueAfterCombat('UIScale')`) and
   stops here;
3. sets `st.pixel`, `st.lineWeight` and `st.line` from UIParent's effective scale and the screen;
4. if the scale, the pixel or the line weight differs from what was last applied, runs the pass;
   otherwise only re-applies the screen edge margin.

So an engine reset of UIParent's scale is undone on the next frame, a scale SaftUI set that fires
`UI_SCALE_CHANGED` finds nothing to do the second time (no loop), and a resolution change in Automatic
needs no `SetScale` at all (F1) unless the engine reset it.

**The pass is the profile update, `st.Config:UpdateConfig()` (call).** It already redraws every themed
frame, lays every module out again, re-applies the margin, the headers and every mover, rebuilds an open
`/sui` in place, recolors, and waits for the end of combat for anything protected, with one chat line.
Every module's `UpdateConfig` is idempotent and in `xpcall`, so a scale change needs no new path, and
everything a module rounds with the grid's helpers comes out whole at the new k. Then the change
callbacks run (the plates, the edit mode listeners, the `/sui` row's text). A scale change is rare, so the
pass's cost is fine. It is not a history step.

### In combat

Nothing sets the scale in combat. `/sui` closes in combat, so a choice can't change then; a display
change in combat waits as above; the Keep prompt's timer running out in combat goes back after combat
(below). Settings that are protected in combat go through the pass's own waits.

### Blizzard's UI Scale setting

In Automatic and Pixel for pixel SaftUI sets the scale back on the next frame after the player moves
Blizzard's slider (today it is set back only at the next login, so the slider seems to work until then).
The first time in a session, chat says: "SaftUI sets the UI's scale itself. To use the game's UI Scale,
choose The game's UI scale in /sui > Global settings > General." In The game's UI scale, SaftUI never sets
it and the check only reads it (steps 3 and 4).

### The order with the nameplates

Two frames' handlers for one event run in no set order, so the plates can't pin from their own event
frame (the followup's point). `nameplates/pixels.lua`'s event frame goes; the plates pin
(`UF:PinPlateScale` on every plate) and set their size (`UF:ApplyPlateSize`, which waits for combat
itself) from the scale interface's change callback, after Core has set the scale and the pass has run.

## The scale interface

`st.UIScale`, a table in a new Core file loaded after `api.lua` and before `theme.lua` in both TOCs
(call: a table, not an AceAddon module, because it must run inside `SaftUI:OnEnable` before any module
enables). The `/sui` rows, `/sui scale`, the Keep prompt and the planned setup dialog all go through it:

| Call | What it does |
| --- | --- |
| `UIScale.Resolve(choice, screen, gameScale)` | Pure: `{ mode, auto, size, k, uiScale, pixel, lineWeight, line, width, height, unitsWide, unitsTall, sizeMax }` for a choice on a screen (`{ width, height }`); `gameScale` is UIParent's scale for The game's UI scale. No frame, no API: the tests' core. |
| `UIScale:Default()` | The computed default on this screen: `Resolve({ mode = 'auto', size = 1 }, screen)`. What a setup step shows as "SaftUI's pick for your screen". |
| `UIScale:Saved()` | The player's saved choice, or nil (nothing chosen yet). |
| `UIScale:Current()` | The choice in effect: a preview, else the saved one, else the default. |
| `UIScale:Preview(choice)` | Applies a choice without saving it (`ok, why`; refused in combat and for a size outside the range). The previous choice is kept for `Revert`. |
| `UIScale:Apply(choice)` | Applies and saves (`ok, why`). `Apply(nil)` removes the save: the default. |
| `UIScale:Revert()` | Ends a preview: back to the saved choice, else the default. |
| `UIScale:Describe(resolved)` | The plain line `/sui` and a setup step show, such as "This screen is 1920 x 1080: SaftUI draws at 75% of its 1440p size, with 1 pixel lines." |
| `UIScale:OnChanged(fn)` | `fn(resolved)` after every applied change, once the pass has run. |

A setup step shows `Default()`, lets the player move a size and calls `Preview` when the slider is let go,
calls `Apply` on its Next or Done and `Revert` on Back or Cancel. `/sui` does the same with the Keep
prompt as its confirmation.

## Settings and UI

### Where

**Global settings > General, a new first section, "UI scale"** (call), above Icons and Layout. The values
aren't profile settings: the rows read and write through `st.UIScale`. A first-run setup dialog is planned
as the first place a new player meets this choice (its own design); `/sui` is where it is changed later.
The scaling ships fully usable without the dialog: the automatic default needs no setup, and the slider is
in `/sui`.

### The rows

Section description: "Saved for this computer and account, not in the profile, so a profile you share
keeps the other person's screen size. A change shows at once: keep it within 15 seconds or it goes back.
If SaftUI ever ends up too large or too small to use, type /sui scale reset."

1. **Scale**, a select: Automatic / Pixel for pixel / The game's UI scale. Default Automatic, with its
   per-setting reset. Description: "Automatic: SaftUI is laid out for a screen 1440 pixels high and scales
   to yours, so it takes the same share of any screen. Pixel for pixel: every size is that many pixels on
   your screen, as before this version, so SaftUI looks larger on a small screen and smaller on a large
   one. The game's UI scale: the game's own UI Scale (Options > Graphics) sets the size, and SaftUI keeps
   its lines whole at whatever size that is."
2. **UI size**, a range shown as a percent: 70% to 150% (lower on short screens, The formula), steps of
   5%, default 100%, with its per-setting reset; disabled unless Scale is Automatic. Description: "Makes
   all of SaftUI larger or smaller than the automatic size. 100% is the size SaftUI works out for this
   screen. Every size and position in SaftUI's settings is in pixels of a 1440p screen, so they grow and
   shrink with this."
3. **A line of text** under them: `UIScale:Describe(...)` for what is applied, for example "This screen is
   3456 x 2234: SaftUI draws at 155% of its 1440p size, with 2 pixel lines."

### Applying a change

Live, no reload (call): everything is in units, and the pass re-applies everything that depends on k. A
change applies when the UI size slider is let go, an arrow is clicked or a typed value is entered, never
at each step of a drag (a pass per step would stutter and the window would rescale under the mouse); the
select applies on its pick. Both go through `UIScale:Preview` and then the Keep prompt. A per-setting
reset of either row is a change like any other, with the prompt. The builder chooses how the range
control commits on release (a kit field such as `applyOnRelease`, or the set waiting for the button to
come up).

### The Keep prompt

"Keep this UI size?" with "Going back in 15 s." counting down, and two buttons, **Keep** (`UIScale:Apply`)
and **Go back** (`UIScale:Revert`). Esc and the timer go back (call). A frame of Core's in
`FULLSCREEN_DIALOG` above `/sui`, the edit mode bar and the History list, drawn in the theme on the options
Background, centered on the screen. It ignores its parent's scale (`SetIgnoreParentScale(true)`) and draws
at the automatic size of this screen at 100% (call), so it reads the same however large or small the
previewed size is; it isn't protected, so this is safe at any time. A second change while it shows
restarts it for the new choice; going back then returns to the saved choice. If combat starts, the prompt
stays; if its timer ends in combat, it says "Goes back when combat ends." and the revert waits for the end
of combat.

### Recovery: `/sui scale`

Parsed in `/sui`'s slash handler before the commands (`SaftUI-Core/Config/config.lua:101-119`), like `edit`
and `debug`; no sidebar button:

- `/sui scale`: prints the choice and `Describe`.
- `/sui scale reset`: `UIScale:Apply(nil)`, Automatic at 100%, at once and with no prompt: the way out of
  any size. In combat it waits and says so.
- `/sui scale 90` (or `90%`): Automatic at that size, held to the range, with the prompt.
- `/sui scale auto`, `/sui scale pixel`, `/sui scale game`: that mode, with the prompt.

### The first login after the update

Once per account (a marker in `st.config.global`), when nothing is saved and the automatic size here isn't
pixel for pixel (k isn't 1), chat says (call): "SaftUI now sizes itself to your screen: here it draws at
75% of its 1440p size, so it takes the same share of the screen as on the screen it was laid out on. To
keep the size it had before, type /sui scale pixel. The choices are in /sui > Global settings > General."
The owner never sees it. When the setup dialog exists, its scale step can take this message's place.

### The first-run setup dialog (planned)

Planned separately (the owner's words in "What the owner decided", 7): steps that introduce the UI, the
scale first, then unit frame layouts and the theme. Its scale step needs nothing beyond The scale
interface: it shows `Default()` and `Describe`, previews a size, saves it with `Apply`, and goes back with
`Revert`. This design adds nothing for it and depends on nothing of it.

## Phasing

Each phase is whole and shippable, and each is planned on its own. **The owner's 1440p screen sees no
change in any phase** (k = 1); after phase 1 the only new thing there is the UI scale section. Before
phase 1 is planned, E0 to E6 run (Testing): E3 shapes the change check, and E5 sizes phases 1, 2 and 4.

**Phase 1: the scale and whole borders** (Core and the plates). The scale interface, the three modes, the
saved choice, the order at login, the change check and its combat wait, the pass, the change callbacks;
`st.pixel`, `st.lineWeight`, `st.line` and the grid's helpers; the theme engine (A1, A2, A3), `st.BACKDROP`
and the close button; the screen edge margin rounded; the plates' pin and size from the callback and their
driver size in whole, even pixels; `/sui`'s UI scale section, the Keep prompt, `/sui scale`, the first-login
message, the chat line for Blizzard's slider; the tests' scale model (Testing). Docs: README's
Installation (no longer "ignores Blizzard's UI Scale setting"), `.agents/architecture.md`,
`.agents/edit-mode.md` (the General tab's section), `.agents/clients.md` (F2 to F10), `.agents/taint.md`
(rule 6: `UIParent:SetScale` out of combat only), `.agents/testing.md`, the design system's tokens and
README (A15). The followup "UIParent's scale is set once, at login" moves to Resolved. What the friends get
at once: the right size, and every border SaftUI's theme draws whole (1 pixel at 1080p, 2 on the Mac),
in the world and on SaftUI's windows' frames. Still off at k other than 1: the options kit's hairlines,
dividers and boxes, some gaps uneven by a pixel, and the lines in the addons listed under A4.

**Phase 2: the options kit and SaftUI's windows** (`SaftUI-Core/Config`, `EditMode/Bar`). The kit's boxes
(`Box`, `LookLine`), the color picker's rings, every hairline and divider (A4), the one-unit offsets
(A5), the kit's pure layouts on the grid (A6) or the game's layout rounding over the window if E5 allows,
icons in even pixels (A12), lists and menus with their own scale (A9). `OW.MaxHeight` wins over the
window's least height when the screen is shorter (the window's body scrolls), for The game's UI scale at
1.15 on a short screen (668 units).

**Phase 3: edit mode.** Grid lines and snap guides at one line, snapping's border rule with `line` (A7),
the outline, the Position editor's boxes showing one decimal at most, the picker's list. Nudges unchanged.

**Phase 4: each addon, one plan each**, in the order the friends look at them (call): 4a unit frames and
nameplates (the plates' even pixels, auras' inner line), 4b action bars and their extras (onto
`st:EvenPixels`), 4c bags (the categories tab's and rule editor's lines), 4d Misc (experience bars,
tooltip, totem bar, durability) and the skins (the buff frame's `+ 1`, the objective tracker's line), 4e
loot (the timer lines, the feed's progress line), 4f minimap and micro menu, 4g chat and the tracker. Each:
its one-unit lines to one line, its sizes and offsets that meet a border onto the grid, its centered
frames even, and its layout tests under the scale parameter.

**Phase 5: crispness on dense screens**, only as the in-game checks ask: a rule for Homespun from E6 and
G3, a second size of the Lucide icons, anything the Mac friend reports.

## Testing

### Lua tests

1. **`tests/core/uiscale_test.lua`** (new). `Resolve` over the worked values table, exactly; the snap
   band's edges (1367, 1368, 1512, 1513 high), the floor (768, 900), the UI size's range and its lowered
   top on short screens, a size that isn't a number; each mode. Login: the scale set after the AceDB and
   before any module's `OnEnable` (a module sees the final `st.pixel`), and waiting in combat. The check:
   one per frame however many events, no `SetScale` when equal, none in The game's UI scale, a wait in
   combat, the pass run once per real change and not for a repeat, no loop when `SetScale` fires
   `UI_SCALE_CHANGED`. `Preview`, `Apply`, `Revert`, `Apply(nil)` and the saved shape; the Keep prompt's
   timer, buttons, Esc and combat; `/sui scale` in each form; the first-login message once.
2. **`tests/core/theme_scale_test.lua`** (new). Every kind under Thick, Thin and Blizzard at k 0.75, 1, 1.25
   and 1.55: `edgeSize` one line, insets `lines` lines, Thick's strips one line out and three wide, the
   backdrop's placement, the recorded inset, and the pixel checker on the result. **At k = 1, today's
   numbers exactly** (1, 2 and 1, 1 and 3), for every kind and theme: the guard on the owner's setup.
3. **A scan** (in `tests/core/theme_kinds_test.lua` or beside it): no literal `edgeSize = 1` outside an
   allow-list that shrinks as phases land; from phase 2, no `SetHeight(1)`/`SetWidth(1)` in the areas done.
4. **The pixel checker in pixels.** `tests/lib/pixels.lua`'s `P.off` measures each edge in pixels from the
   screen's bottom left (`edge * (UIParent:GetEffectiveScale() / (768 / stub.screen_height))` for an edge
   in UIParent's units), not in units. At k = 1 that is the same check as today.
5. **The stubs.** `C_UI` (the notch, `stub.notch`), `GetScreenDPIScale`, `GetDefaultScale`, the
   `useUiScale` and `uiScale` CVars, `NOTCHED_DISPLAY_MODE_CHANGED`, UIParent protected in combat
   (`SetScale` blocked there, as `stub.blocked` does for protected frames), `stub.engine_resets_scale` to
   play E3's answer (the engine setting UIParent back on a display change), and the layout rounding and
   texture snapping remembered (as now).
6. **The shell and `set_screen`** go through `UIScale.Resolve`: the shell applies the test's choice instead
   of `st.scale`, and `set_screen(w, h)` keeps its meaning for every existing test by using Pixel for pixel
   (a unit is still a pixel), so the 32 files that call it, and their exact numbers, don't change.

### Running layouts at several scales

Today the suite runs 194 files in about 72 seconds of wall time (419 seconds of file time over the
cores); the 31 files that use the pixel checker take 123 of those seconds. Running all of them at three
more scales would add about 370 seconds, nearly doubling it. So (call):

- A case that holds at any scale is written `scaled_test(name, fn)` (a harness global beside `test`). It
  asserts whole pixels, no overlap, inside its window, fixed corners: never an exact number of units.
  Phase 1 converts the theme cases; each later phase converts its area's layout cases.
- `tests/run` runs every file as now at k = 1, and runs a file's scaled cases once more at one other
  scale picked by the file's path (0.75, 1.25 or 1.55 in turn), in a world whose screen gives it (1920 x
  1080, 3200 x 1800, 3456 x 2234) in Automatic. The runner tells the Lua state through an environment
  variable (`SAFTUI_TEST_SCALE`), as it already keeps one state per file. A normal run grows by at most
  the scaled cases' share of those 123 seconds: under 30% of the file time once every pixel-checked area
  is converted (phase 4), much less before.
- `tests/run --scales=all` runs every scaled case at all three, for the end of a phase and before a merge.
  The sampling follows `options_states_test.lua`'s, which already spreads states over runs by a rule.

### What only the game can confirm

To give with phase 1's build:

- **G1.** The owner, before and after: a screenshot of the same scene at 1440p, compared;
  `/run print(UIParent:GetScale(), 768/1440)` prints the same number twice. Nothing moved, no border
  changed.
- **G2.** The 1080p friend: the size matches E0's; under Thick, Thin and Blizzard every border is one
  pixel, on every side, on the unit frames, bars, bags and windows; Homespun as in the font demo.
- **G3.** The Mac friend: the same with 2 pixel borders; Homespun and the Lucide icons at 1.55 judged crisp
  or soft (decides phase 5).
- **G4.** UI size changed, kept, gone back by the button, by Esc and by the timer; the largest size the
  screen allows, where `/sui` must still fit; `/sui scale reset` from there and from the smallest; the
  three modes.
- **G5.** A display change (resize the window, change resolution, move to another monitor) out of combat
  and in combat: no error, the scale back on the next frame (or after combat), borders whole after.
- **G6.** Blizzard's UI Scale slider moved in each mode: set back in Automatic and Pixel for pixel with the
  one chat line; followed in The game's UI scale with whole borders.
- **G7.** `/reload` in combat: no "Interface action failed", the scale right by the end of the fight.
- **G8.** Plates after a scale change, with no reload: whole borders while strafing past a pack (the
  nameplates' in-game check 2, now at the friends' scales).
- **G9.** `/console taintLog 1`, then G4 to G7: no "blocked" line in `Logs/taint.log` naming SaftUI.

### Experiments to run before the build

In this order. Each says who, the exact steps, what to send back, and what it decides. A `/run` line fits
WoW's 255-character chat box; paste each as one line. `/reload` after each experiment puts everything
back.

**E0. See the new size today (the two friends).** The automatic size at 100% is UIParent at 768/1440 on
any screen. Paste `/run UIParent:SetScale(768/1440)`. Everything takes the share of the screen it has on
the owner's. Borders may look broken: that is what the build fixes; judge only the size. To try a UI size,
multiply: `/run UIParent:SetScale(768/1440*1.1)` for 110%, `*0.9` for 90%. Then `/reload`. *Send:* whether
100% looks right, or the percent that does. *Decides:* the default (100%) and the slider's range (70% to
150%).

**E1. The screen as the game sees it (the owner, both friends).** Paste each:

- `/run local w,h=GetPhysicalScreenSize() print("phys",w,h,"ui",UIParent:GetScale(),UIParent:GetEffectiveScale(),"units",GetScreenWidth(),GetScreenHeight())`
- `/run print("dpi",GetScreenDPIScale(),"def",GetDefaultScale(),"cvar",GetCVar("useUiScale"),GetCVar("uiScale"),"rs",GetCVar("RenderScale"))`
- The Mac friend also: `/run print("notch",C_UI.DoesAnyDisplayHaveNotch(),C_UI.ShouldUIParentAvoidNotch(),C_UI.GetTopLeftNotchSafeRegion())`
  and `/run print("top",UIParent:GetTop(),"height",UIParent:GetHeight(),"full",768/UIParent:GetScale(),"bottom",UIParent:GetBottom())`,
  then changes Render Scale in Options > Graphics, applies, and pastes the first line again.

*Send:* the printed lines, and the Mac friend's Resolution as Options > Graphics shows it. *Decides:* the
Mac's height (2234 device pixels, as F2 infers, or 1117 points, or a lower game resolution), so the worked
values and its line weight (2 at 2234, 1 below 2160); that render scale leaves the physical size alone
(F4); what `GetDefaultScale()` is (F5, for The game's UI scale); whether the notch moves UIParent and by an
even number of pixels (F7: "top" under "full" by the notch).

**E2. A window (the owner).** Switch Display Mode to Windowed, size the window a little smaller than the
screen, and paste E1's first line; then back to Fullscreen. *Send:* the printed line. *Decides:* that the
physical size follows the window (F3), which the snap band relies on to keep the owner at exactly 1.

**E3. Who sets UIParent's scale (the owner).** `/reload`, then paste a listener that prints each event:

`/run SUIW=SUIW or CreateFrame("Frame") SUIW:RegisterEvent("UI_SCALE_CHANGED") SUIW:RegisterEvent("DISPLAY_SIZE_CHANGED") SUIW:SetScript("OnEvent",function(_,e) print(e,GetTime(),UIParent:GetScale(),GetPhysicalScreenSize()) end)`

1. `/run print("now",GetTime(),UIParent:GetScale(),768/select(2,GetPhysicalScreenSize())) C_Timer.After(1,function() print("1s",UIParent:GetScale()) end)`
   (SaftUI's scale: the two numbers match).
2. In Options > Graphics, tick Use UI Scale if it isn't, move the UI Scale slider, Apply, close. Paste
   step 1's line again.
3. Resize the window or change the resolution. Paste step 1's line again.
4. `/run UIParent:SetScale(UIParent:GetScale()+0.01)`, then step 1's line; then `/reload`.

*Send:* everything printed. *Decides:* whether the engine sets UIParent's scale over SaftUI's on a slider
change (2) and on a display change (3), and when (the "1s" line), which the next-frame check is built
for; whether an addon's `SetScale` fires `UI_SCALE_CHANGED` (4: an event line printed or not), which the
loop guard and the change callbacks cover either way.

**E4. The scale in combat (the owner).** Out of combat, paste
`/run print("combat",InCombatLockdown(),"protected",UIParent:IsProtected())`. Then attack a training dummy
and, in combat, paste the same line, then `/run UIParent:SetScale(UIParent:GetScale())`. Leave combat,
`/reload`. *Send:* the two printed lines and any error. *Decides:* F8. The design assumes UIParent is
protected in combat and the second line is blocked ("Interface action failed"); if it isn't, the combat
wait stays anyway (it costs nothing), but G5's in-combat case gets simpler.

**E5. A test card of borders (the owner, then each friend).** `/reload`. Paste these four lines in turn:

1. `/run local t=UIParent:CreateTexture() print("snap",t:IsSnappingToPixelGrid(),t:GetTexelSnappingBias(),"round",UIParent:GetRoundLayoutToNearestPixel())`
2. `/run SUIP=768/select(2,GetPhysicalScreenSize())/UIParent:GetScale() function SUIR(f) f:SetRoundLayoutToNearestPixel(true) for _,t in ipairs({f:GetRegions()}) do t:SetRoundLayoutToNearestPixel(true) end end`
3. `/run function SUIB(x,y,w,r) local p=SUIP local b=CreateFrame("Frame",nil,UIParent,"BackdropTemplate") b:SetSize(20*p,20*p) b:SetPoint("CENTER",x*p,y*p) b:SetBackdrop({edgeFile="Interface/Buttons/WHITE8X8",edgeSize=w*p}) if r then SUIR(b) end end`
4. `/run for i=0,7 do local x=i*30-105 SUIB(x,60,1) SUIB(x+i/8,30,1) SUIB(x+i/8,0,1,1) SUIB(x+i/8,-30,2) SUIB(x+i/8,-60,2,1) end`

Five rows of eight small squares appear above the screen's middle, each a one or two pixel outline. Row 1
sits on whole pixels (the reference). Rows 2 and 3 have one-pixel outlines moved by eighths of a pixel,
row 3 with the game's layout rounding on. Rows 4 and 5 are the same with two-pixel outlines. Look closely
or take a screenshot (Print Screen; it is saved at the screen's own resolution in the Screenshots folder)
and zoom in. Then the owner only: `/reload`, paste
`/run UIParent:SetScale(768/select(2,GetPhysicalScreenSize())*0.75)` (the 1080p friend's scale on the
owner's screen), and lines 2 to 4 again. *Send:* line 1's print and, for each row, whether every square's
four sides are the same width, or the screenshot. *Decides:* F9 and F10. Rows 3 and 5 clean while 2 and 4
are not: the game's layout rounding rounds edges, and phase 1 turns it on for every frame the theme
draws, which shrinks phases 2 and 4 to borders and lines. All rows clean: the texture snapping alone holds
lines of whole width, and the rounding is a nicety. Rows 3 and 5 not clean: every placement is rounded in
Lua, and phase 1 also rounds each drawn frame's rect.

**E6. Homespun on the Mac (the Mac friend; the 1080p friend optional).** `/suifonts` opens the font demo.
Its 1.55 button shows the specimens at exactly the size the Mac will get (UIParent is pixel for pixel on
the Mac today). Then `/run SaftUI.FontDemo:SetScale(1.5)` (15 pixels) and
`/run SaftUI.FontDemo:SetScale(2)` (20 pixels). The 1080p friend can press 0.75. *Send:* which of the
Homespun rows look crisp at each. *Decides:* the font call (follow the scale) or a rule for Homespun in
phase 5.

## What's left to the builder

- The new Core file's name and the split between it and `api.lua`; the helpers' exact names.
- How the range control commits on release.
- The Keep prompt's frame, its exact size and the countdown's look, within the design system (the kit's
  button, the dialog's padding).
- Exact text of descriptions, tooltips and chat lines, within the gist above.
- Whether the first-login marker is a version number or a flag.
- **Docs:** as listed in phase 1, and each later phase's area doc (`.agents/edit-mode.md` for phases 2 and
  3, `.agents/architecture.md` for the addons in phase 4); the design system's tokens and README rules
  ("Whole pixels": round in pixels, not units).
- **Followups:** "Scale SaftUI across resolutions and stay pixel perfect" is taken up by this design and
  moves to Resolved when phase 4 ends; "UIParent's scale is set once, at login" moves to Resolved with
  phase 1; the nameplates' in-game check 2 gets "at the friends' scales" when phase 1 lands; each later
  phase gets a followup when phase 1 ships, so they live outside this document.

## Risks

1. **The engine sets UIParent back over SaftUI's scale** (a display change, Blizzard's slider). Contained:
   the next-frame check sets it again; E3 says when; the comparison makes a second pass do nothing.
2. **`SetScale` or the pass blocked in combat, or taint.** Contained: `SetScale` only out of combat and
   queued otherwise; the pass is the profile update, whose protected parts already wait; `/sui` and the
   slider are closed in combat; E4, G5, G7, G9.
3. **A friend's tuned layout shrinks (1080p) or grows (the Mac).** A friend who moved or resized frames for
   today's sizes sees them change at the update. Contained: positions keep their anchors, so nothing
   scatters; the one-time chat line gives `/sui scale pixel` as the exact way back; Question 1.
4. **The owner's setup changes.** Contained: k = 1 is bit-identical (the formula's integer 1 and today's
   expression), the snap band holds a windowed 1440p at 1, the k = 1 golden tests, G1.
5. **The Mac reports points or a lower resolution.** The formula still gives the 1440 share; only its line
   weight and the worked values change. E1.
6. **Text too small on small screens.** Contained: the floor at the 1080p size, which the owner has seen;
   the UI size slider.
7. **A size that makes `/sui` unusable.** Contained: the range's top lowered so UIParent stays 768 units
   high, the Keep prompt at the automatic size whatever the preview, the timer going back, `/sui scale
   reset`, and `OW.MaxHeight` winning on short screens (phase 2).
8. **Lines vanishing at half pixels** (F10 with float noise, the 1e-4 trim). Contained: lines are never
   trimmed, placements land on whole pixels, and E5 decides whether the game's layout rounding goes on.
9. **Half pixels from the notch or an odd screen** (F7). Contained: E1 measures the notch; frames
   centered on the screen round their offsets from UIParent's real center (the grid already does,
   `EM:GetGridCenter`); borders stay whole width either way.
10. **Blizzard's and other addons' frames at a smaller scale than the game allows.** At 1080p UIParent is
    0.5333, under Blizzard's 0.65 minimum, so Blizzard's own windows (quest log, map, talents) are a
    quarter smaller than today on the friend's screen, the share they have on the owner's. Contained: the
    UI size slider, Pixel for pixel, The game's UI scale; Later has a separate size for Blizzard's windows
    if the friends ask.
11. **A full pass per change is slow or one module errors.** Contained: it runs only on a real change, once
    per frame at most, each module in `xpcall` as now.
12. **Fractions in saved offsets** (a nudge at 0.75 stores 1.3333). Contained: they mean the same place on
    every screen, are kept to 1e-4, and show with one decimal.
13. **Homespun rough at 1.55, icons soft.** Contained: E6 before, G3 after, one place for a font rule,
    phase 5.

## Later

- **The first-run setup dialog**, its own design (the owner's words in "What the owner decided", 7): the
  scale as its first step through The scale interface, then unit frame layouts and the theme. It could
  also show its scale step once to existing players on screens where the automatic size isn't 1, in
  place of the chat line.
- A centered 16:9 area for ultrawide screens (ElvUI's "ultrawide" option), so the layout keeps the
  owner's widths on a 21:9 screen.
- A second size of the Lucide TGAs (48 or 64) for k from 1.25, if G3 finds them soft.
- A separate size for Blizzard's windows (quest log, map, character frame), if the friends find them small.
- A scale per profile, if anyone asks; today a profile carries no screen.

## Questions only the owner can answer

1. **Have your friends moved or resized frames to cope with today's size?** If they have, the automatic
   size shrinks the 1080p friend's tuned layout to three quarters and grows the Mac friend's by half, and
   the one-time chat line points them to `/sui scale pixel`. Assumed: they mostly play on your defaults,
   so Automatic is right for everyone, as "it must work on the addon's defaults with no setup" said. The
   other way is to start existing installs on screens far from 1440 at Pixel for pixel and let them opt in.
2. **Two pixel borders on the Mac.** The rule you accepted gives 2 at 1.55 (and on any 4K screen). It will
   look heavier than at 1440p, by design; confirm once the Mac friend has seen it (G3), or say if you'd
   rather keep one pixel lines at every density.
3. **Screens under 1080 pixels high.** Assumed: SaftUI draws them at the 1080p size (text as you judged it
   at 1080p, the layout no longer fitting in proportion). The other way is the full proportional fit, with
   Homespun under 7.5 pixels.

## Calls made while writing this

Ordered by how much the owner is likely to care.

1. **The scale goes on UIParent**, as today; not a SaftUI parent frame, not each frame's sizes.
2. **The automatic part snaps to a whole number within 5%**, so screens 1368 to 1512 pixels high
   (a 1440p monitor in a window) draw pixel for pixel.
3. **The automatic part never goes under 0.75**, the 1080p size.
4. **UI size: 70% to 150% in steps of 5%, default 100%, over the automatic size**, its top lowered on
   screens under 864 pixels high so UIParent stays 768 units high.
5. **Three modes**: Automatic (default), Pixel for pixel (today's), The game's UI scale.
6. **The choice is saved per account on this computer** (`st.config.global.uiScale`), never in a profile.
7. **Line weight `max(1, floor(k + 0.5))` for every border, hairline, divider, outline, grid line and
   guide**; marks two lines; Thick three lines; insets in lines.
8. **Fonts follow the scale unrounded**, Homespun 7.5 pixels at 1080p as the owner saw it, until E6 says
   otherwise for the Mac.
9. **Nothing saved is converted when the scale or screen changes**; rounding happens where a frame is
   placed.
10. **A scale change runs the profile update pass**, live, with no reload.
11. **A change applies when the slider is let go**, through a 15 second "Keep this UI size?" prompt that Esc
    and the timer answer with Go back.
12. **The prompt draws at the automatic size**, ignoring its parent's scale, so it is readable whatever was
    picked.
13. **`/sui scale` with `reset`, a percent, `auto`, `pixel` and `game`**; reset applies at once, the others
    through the prompt.
14. **A one-time chat line** on the first login after the update where the automatic size isn't 1.
15. **SaftUI sets the scale again on the next frame after `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED` and
    `NOTCHED_DISPLAY_MODE_CHANGED`**, out of combat only, overriding Blizzard's slider in Automatic and
    Pixel for pixel with one chat line a session.
16. **The scale interface is a table in a new Core file**, started inside `SaftUI:OnEnable` after the
    AceDB and before every module.
17. **The UI scale section is the first section of Global settings > General.**
18. **The game's layout rounding on every drawn frame only if E5 shows it rounds edges.**
19. **`st:PlaceAtPosition` rounds offsets to whole pixels**; a non-zero gap is at least one pixel.
20. **Arrow-key nudges stay one pixel**, Shift ten.
21. **The Blizzard theme's art scales with k** like Blizzard's own UI, its offsets rounded, with no line
    weight.
22. **The Lucide icons keep their 32 pixel files** in version one, drawn at even whole pixels.
23. **Texts that say "in pixels" keep the word**; the UI size row says a SaftUI pixel is a pixel of a 1440p
    screen.
24. **Phase 1 doesn't wait for the tokens table** (decision 11 placed this after it); the tokens move there
    when it lands.
25. **Tests: `scaled_test` cases run once more at one rotating scale per file; `--scales=all` runs all
    three; `set_screen` keeps meaning pixel for pixel.**
26. **Phase 4's order**: unit frames and nameplates, action bars, bags, Misc and skins, loot, minimap and
    micro menu, chat and the tracker.
