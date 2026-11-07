# SaftUI Action Bars — Design

**Date:** 2026-11-07
**Status:** Ready for approval (builder check done)

## Intent

SaftUI owns the action bars completely, the same way it already owns the minimap, chat, buffs and unit frames:
- layout, spacing and size
- text styling
- visibility
- position, through SaftUI's edit mode

Blizzard's Edit Mode no longer controls them.

Today SaftUI only skins Blizzard's action buttons. `SaftUI-Misc/actionbars.lua` hard-codes them to 39×39. That leaves the user, and a friend playing at 1080p who finds the 1440p-sized UI too big, with no way to size or arrange them.

## Decided by the user

- **SaftUI's own bars, built on LibActionButton-1.0.** This is the library ElvUI and Bartender use, and SaftUI hides Blizzard's bars.
  - **Rejected:** keeping Blizzard's buttons and re-arranging them after Blizzard's layout. The buttons are secure, and Blizzard re-lays its bars out in combat (e.g. when a pet or stance bar appears). SaftUI couldn't put them back until combat ends, so layouts would jump mid-fight. That's the same problem that left the Forever totem bar without a mover.
- **Bars:**
  - **Main bar.** It follows Blizzard's paging: stance and form, stealth, vehicle, possess, override bar and pet battle.
  - **Every extra bar the client has.** These are Blizzard's MultiBars (Bottom Left, Bottom Right, Right, Left, and on retail MultiBar 5–7). Check which exist on Forever.
  - **Pet bar.**
  - **Stance bar.**
- **Also SaftUI's (decided after the builder check):**
  - The **extra action button** and the **zone ability button** get SaftUI holders and edit mode movers, like ElvUI. Blizzard positions them relative to its own (now hidden) bar stack, so leaving them to Blizzard would leave them somewhere awkward once SaftUI's bars are rearranged.
  - SaftUI provides its own **vehicle leave button** as a mover.
  - Possess and override paging are handled by the main bar's paging.
- **Left to Blizzard:** only Forever's totem bar. It can't be moved safely in combat (see `SaftUI-Misc/totembar.lua`) and keeps its existing SaftUI hide option. It may sit where Blizzard's hidden bars were; the user can move it in Blizzard's Edit Mode.
- **Keybinds map to Blizzard's existing binding commands.** Each SaftUI button takes over the keys bound to the matching Blizzard command:
  - `ACTIONBUTTON1–12` → main bar
  - `MULTIACTIONBAR1BUTTON1–12` → the bar Blizzard calls Bottom Left, and so on through `MULTIACTIONBAR7BUTTON*`
  - `BONUSACTIONBUTTON*` → pet bar
  - `SHAPESHIFTBUTTON*` → stance bar

  So:
  - The user's existing binds keep working with no changes.
  - Binding a key in Blizzard's Key Bindings menu applies to SaftUI's bars.
  - Turning SaftUI-ActionBars off gives Blizzard's bars their binds back.

  Binds are re-applied whenever bindings change (`UPDATE_BINDINGS`), and only out of combat.
- **Hover binding must work.** Hovering a SaftUI button and pressing a key binds that key to the button's Blizzard binding command. It's saved the normal way, so it shows in Blizzard's Key Bindings menu.
  - **Preferred:** make Blizzard's own Quick Keybind Mode work with SaftUI's buttons.
  - **If that's not possible taint-free:** a SaftUI hover-bind mode, e.g. `/sui kb`, with the same result.
- **Every bar is an edit mode mover.** Each has a `/sui` section with tabs:
  - **General:** buttons shown, buttons per row, icon size, spacing.
  - **Text:** hotkey, stack count and macro name, each with font, size, position and show/hide.
  - **Visibility:** always, in combat only, or faded until moused over.
  - **Position.**
- **Combat:** layout, size, visibility-setting and binding changes only happen out of combat. Edit mode and `/sui` already close when combat starts and refuse to open during it.

## Builder's calls (made with the user's go-ahead; reject any you disagree with)

- **Where it lives.** A new addon `SaftUI-ActionBars` (TOC `## RequiredDeps: SaftUI-Core`, interface `120000, 16001`). It bundles LibActionButton-1.0 and the libraries it needs. It replaces `SaftUI-Misc/actionbars.lua` and the legacy `st.defaults.actionbars` per-bar config, which points at `SaftUIActionBar1..` frames that no longer exist. Remove both, and keep the useful skin parts (button template, cooldown styling).
- **Default layout (the user's screenshot, decided after the builder check).** Things move once on first load. After that, the user arranges everything in SaftUI's edit mode.
  - Bars 1–3 are rows of 12, stacked at the bottom centre: bar 1 at the bottom, 20px from the bottom edge, with bars 2 and 3 above it.
  - Bars 4 and 5 are vertical columns of 12, side by side at the right edge, 20px from it (the same gap the minimap uses), centred vertically.
  - Buttons sit on a ~47px pitch with thin gaps: 45px icons, 2px spacing.
  - Bars 6–8 are off by default.
  - The pet and stance bars are smaller, defaulting to about 30px, and placed just above the bottom stack, pet on the left and stance on the right.
  - The extra action button, zone ability and vehicle leave button sit above the bottom stack, near where Blizzard puts them today.

  The builder picks exact pixel offsets that match the screenshot, saved in the plan as the reference.
- **Turning a bar off (controller's call, after the builder check).** Every bar has an **Enable** toggle. Defaults follow the layout above.
  - A disabled bar is hidden.
  - **Its keys do nothing.** SaftUI keeps the keys of a disabled bar bound to a no-op instead of releasing them, because Blizzard's own (hidden) button for that command would otherwise still fire.
  - Turning SaftUI-ActionBars off entirely gives every bind back to Blizzard.
- **Pet and stance bars (controller's call)** get SaftUI's skin and their own size settings, like every other bar.
- **Visibility macros.** Bars use secure state drivers for paging and for show/hide. The mouseover fade is driven by alpha only, so it's safe in combat.
- **Cooldown text and the out-of-range/usable tints** use LibActionButton's built-in handling, styled to SaftUI.

## Constraints

- All of `.agents/taint.md` applies:
  - Hide Blizzard's bars taint-free, only while they're not on screen, at load.
  - No writes onto Blizzard frames.
  - No protected calls in combat.
  - No calling Blizzard Lua that writes Blizzard state.
- **Clients:** retail (Midnight, 120000) and WoW Forever (16001, the "Camelot" game type, a mainline-family client; the user plays it).
  - LibActionButton-1.0 must work on both. Check how it detects the game version, and that its retail branch is right for Forever.
  - Secret values (Midnight): LibActionButton must not do arithmetic on secret values. Use a version that handles Midnight, or guard it.
- **Positions** use the shared `{ point, frame, rel_point, x_off, y_off }` shape and `st:RoundToPixel`. Every SetPoint field stays editable, including the typed relative frame, validated with `target`.
- **Profile switches** re-apply everything live, deferring protected parts until after combat (see `.agents/architecture.md`).
- **Testing:** there's no Lua tooling. The user checks in game on Forever first.

## Non-goals

- Moving the Forever totem bar.
- Masque support, and paging customisations beyond Blizzard's own (custom paging macros could come later).

## Left to the builder

- How to hide each Blizzard bar and its art (main menu bar art, end caps, page arrows, status bars are already hidden by `SaftUI-Misc/experience.lua`), and the vehicle/override bar behavior.
- Which LibActionButton version to bundle, and where to get it.
- The exact paging conditions for each class, using LibActionButton's or Blizzard's standard paging.
- The edit mode outline when a bar is hidden by its visibility setting (e.g. "in combat only"). The outline must still show while editing.
