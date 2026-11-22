# Spy skin — design

Date: 2026-11-22. Branch `spy-skin`.

## Intent

The owner plays WoW Forever with **Spy Forever** (CurseForge `spy-forever`, Zerkaa's port of
Spy 1.3.8 for Classic Era to Forever, interface 16001). Its windows wear Blizzard's tooltip
art and look out of place next to SaftUI. Owner: "I'd like to skin the spy addon window to
match saftui", then "lets skin all of those for spy, may as well", "just reskin spy's frames".

## Goals

Restyle, in SaftUI's look, every visible piece of Spy:

1. **Nearby window** (`Spy_MainWindow`, made by `Spy:CreateFrame` in `Widgets.lua` and
   `Spy:CreateMainWindow` in `MainWindow.lua`): a SaftUI panel in place of the party
   background texture; the title bar (`TitleBar`, a tooltip-border backdrop) as SaftUI's header
   strip with a one-line divider; the title, the count and the row texts in SaftUI's fonts;
   the close (Blizzard minimize art), left/right arrow, clear and stats buttons as SaftUI
   icon buttons (Lucide icons, `st:AddStates` hover); the four resize grips as a quiet SaftUI
   grip; the rows (`Spy_MainWindow_Bar<n>`, a `StatusBar` per row) on SaftUI's flat bar
   texture with SaftUI's thin border. Spy keeps the class color it gives each bar.
   Spy Forever's own extras (`Display.lua`) stay: the class icon at the start of a row is
   cropped as SaftUI crops icons, and the KoS, guild and tag markers are left as they are.
   Its **Border** setting (`WindowBorder`: classic, forever, none; `Spy:ApplyBorderStyle`)
   is overridden while the skin is on: a post-hook on `ApplyBorderStyle` and
   `ManageBarsDisplayed` clears the title bar's and the alert's backdrops again and hides the
   gold `ForeverBorder` frame, and SaftUI's panel follows the rows shown (the window has no
   backdrop of its own; its edge was the title bar's).
2. **Alert popup** (`Spy_AlertWindow`): a SaftUI panel, the icon (a backdrop of an icon) cropped
   and framed as `st:SkinIcon` does, title, name and location texts in SaftUI's fonts. Spy's
   alert colors (KoS red, stealth, and so on) stay as the panel's border tint, so an alert
   still reads at a glance.
3. **Statistics window** (`SpyStatsFrame`, `SpyStats.xml`): a SaftUI panel and header, SaftUI
   close cross, its `UIPanelButtonTemplate` buttons (Refresh and the like) as SaftUI buttons,
   the tab(s), the search box (a SaftUI Panel round it, R11), the check boxes, the sort headers
   as flat header cells and the list lines' hover in the Accent's states. The
   `FauxScrollFrame`'s bar stays Spy's, as its drop-down menu stays Blizzard's (R12:
   `st:SkinScrollBar` would write a field onto the bar).
4. **KoS button** (`Spy_KoSButton`): a small SaftUI icon button (skull) in place of the
   minimap-style ring. Spy parents it to Blizzard's `TargetFrame` and refreshes it from a
   post-hook on `TargetFrame.Update`. With SaftUI's unit frames on, oUF disables Blizzard's
   target frame, so today the button never shows. The skin anchors it to SaftUI's target
   frame (`SaftUI_Target`, top right corner) and shows, hides and re-icons it itself on
   `PLAYER_TARGET_CHANGED` and Spy's KoS toggle, with Spy's own rule (enemy player target,
   `Spy.db.profile.ShowKoSButton`, on or off from `SpyPerCharDB.KOSData[name]`). With
   SaftUI's unit frames off it stays on Blizzard's frame and is only restyled.

Map notes on the world map and minimap, and Spy's options (an AceConfig page in Blizzard's
settings) are left as they are.

## Non-goals

- No new behavior in Spy: same lists, alerts, sounds, clicks, resizing, saved positions.
- Not moving the windows into SaftUI's edit mode. Spy keeps its own drag and its own saved
  positions.
- Not supporting other Spy flavors on purpose. The skin keys on frame names, so Classic Spy
  and the TBC forks probably work too, but only Spy Forever is checked.

## Anti-goals

- Breaking targeting from a row in combat. Spy Forever says the window itself is protected
  once it holds secure buttons (`Widgets.lua`: "a window holding secure buttons is protected,
  StartMoving is refused in combat"), so the skin never sizes or places `Spy_MainWindow`
  either; SaftUI's panel is a child anchored to it. Rows are `SecureActionButtonTemplate` buttons
  (`SpySecureActionButtonTemplate`). The skin never sizes, places, shows, hides or reparents
  a row or anything anchored to one, and never `SetScript`s it. It only restyles the
  StatusBar and font strings inside, and those writes are not protected.
- A half-skinned window when Spy renames something: every hook target is checked first, and
  a missing piece is left as Spy draws it (the RestedXP skin's rule), never an error.

## Constraints

- `.agents/taint.md`'s third-party note: Spy's frames aren't Blizzard's, so rule 1 doesn't
  bind them, but SaftUI only adds to their scripts (`HookScript`, `hooksecurefunc`, never
  `SetScript`) and keeps its state in weak side tables keyed by Spy's frames. Backdrops go
  through `st:SetBackdropIn` on SaftUI's own child frames.
- **Spy's color system** (`Spy.Colors`, `Colors.lua`) re-colors registered borders,
  backgrounds and font strings whenever its color options change or a profile loads. The
  skin clears Spy's backdrops (as RestedXP's `NoBackdrop`) and draws its own panels, so
  Spy's background and border colors stop showing. Spy's font colors (title, bar text) are
  left to Spy, so the owner can still tint them. The alert border's color is read from
  Spy's alert colors.
- Spy sets font sizes from its Row height and text size settings (`Spy:SetFontSize`). The
  skin keeps the size Spy asks for and puts SaftUI's face and outline on it (RestedXP's
  `HookFont` pattern). The Nearby rows' two texts are the exception (user, 22 Nov): Spy
  sizes them from the bar height, which drew a pixel face at sizes it isn't made for, so
  they take the Skinning font's own size.
- Spy loads after SaftUI-Misc or before it: set up at `ADDON_LOADED` for `Spy`, or at once if
  it's loaded. `SpyStatsFrame` is XML, so it exists at load; the Nearby and alert windows
  are made in `Spy:CreateMainWindow` (post-hook it); the KoS button in `Spy:CreateKoSButton`.
- Both clients: Spy Forever is Forever only, but nothing in the skin is client specific.

## Approaches

1. **Restyle Spy's own frames (picked by the owner).** Post-hooks and side tables, as the
   RestedXP, Hekili and WeakAuras skins. Spy keeps all behavior; a Spy update that renames a
   frame leaves that piece unskinned until the skin follows.
2. **Hide Spy's windows and draw SaftUI's own** from Spy's data. Full control of layout, but
   SaftUI would rebuild the secure targeting rows and break whenever Spy changes its data.
   Several times the work. Rejected.

## Decided

- Approach 1 (owner, 2026-11-22: "yeah just reskin spy's frames").
- Scope: Nearby window, alert popup, Statistics window, KoS button (owner).
- Look (my call, stated to the owner): the Skinning page's Theme, Background and font,
  like the color picker and the Cooldown Manager skins; window titles in the Window
  titles font. A **Spy** toggle on the Skinning page (`skinning.spy`, default on). Off, or
  with the Skinning Theme set to Blizzard, Spy keeps its own look.
- Toggling needs a reload (built: the skin is installed only if the toggle is on and the
  Theme isn't Blizzard when it is set up; the toggle's description says so). A Theme,
  Background or font change after install applies live; a Theme switched to Blizzard after
  install takes effect at the next reload.
- Spy's per-alphabet font family is kept: the skin builds a family per size with SaftUI's
  face as the roman member and Spy's other-alphabet files, so Russian and Asian names don't
  turn to squares.
- Each alert's border takes its kind's color, read from Spy's `RegisterBorder` call (the
  Alert Background color is the fill, not the kind's color). Spy's own Border and window
  colors are not used while the skin is on.
- The Statistics window's check boxes are drawn field-free (a Panel control with faded
  template art and a flat checked texture, in a SaftUI box). Its scroll bar stays Spy's
  (Blizzard's FauxScrollFrame bar, which `st:SkinScrollBar` would write a field onto), and
  so does its drop-down.
- The Nearby window's panel runs to the window's bottom, the same area Spy's own Background
  covered, so some empty panel shows below the rows, as with Spy.
- The skin never touches the secure window's or rows' geometry (`.agents/taint.md`).

## Left to the builder

- The exact Lucide icons (chevrons, eraser or trash, bar chart, x, skull). Built.
- Test fixtures: model Spy's frames from the TBC fork's source (`Widgets.lua`,
  `MainWindow.lua`, `SpyStats.xml`) as the RestedXP tests do; the owner checks in game
  (followups: "Spy skin: in-game checks").

## Source note

Spy Forever's code is not public (CurseForge, all rights reserved). This design was checked
against the owner's installed copy, **Spy 1.3.8-forever28** (`E:\Games\World of
Warcraft\_forever_\Interface\AddOns\Spy`, read 2026-11-22): `Widgets.lua`,
`MainWindow.lua`, `Display.lua`, `SpyStats.xml`, `Colors.lua`. Test fixtures model those
frames; no Spy code is copied into the repo. Also confirmed: SaftUI's oUF
(`Libraries/oUF/blizzard.lua`, `handleFrame`) unregisters `TargetFrame`'s events and sets it
`alwaysBlocked`, which is why Spy's KoS button never shows with SaftUI's unit frames.
