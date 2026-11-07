# SaftUI Action Bars Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Blizzard's action bars with SaftUI's own bars (LibActionButton-1.0), fully configurable in `/sui` and SaftUI's edit mode, keeping the user's existing keybinds and hover binding.

**Architecture:** A new addon `SaftUI-ActionBars` holds:
- one module `ActionBars`
- a bar factory (a secure header per bar, with LibActionButton-1.0 buttons inside)
- a binding layer that maps Blizzard's binding commands onto SaftUI buttons through override bindings
- an options file

Blizzard's bars are hidden at load, taint-free. The pieces SaftUI also takes over get SaftUI holders that act as edit mode movers: the pet bar, the stance bar, the extra action button, the zone ability button, and a SaftUI vehicle leave button.

**Tech Stack:** Lua and WoW secure templates (SecureHandlerStateTemplate), LibActionButton-1.0 (minor 168+), LibButtonGlow-1.0, and Ace3 via SaftUI-Core.

**Spec:** `docs/superpowers/specs/2026-11-07-saftui-action-bars-design.md`

## Global Constraints

- Read `AGENTS.md` and `.agents/taint.md`, `.agents/architecture.md`, `.agents/edit-mode.md` and `.agents/clients.md` before coding. Every rule there applies.
- Clients: retail (Midnight, 120000) and WoW Forever (16001; the user plays it). TOC `## Interface: 120000, 16001`, `## RequiredDeps: SaftUI-Core`, `## Group: SaftUI-Core`.
- LibActionButton-1.0 comes from `github.com/Nevcairiel/LibActionButton-1.0` master (minor 168 at plan time). It detects Forever (`buildInfo >= 16001 and < 20000`) and Midnight. Its dependency LibButtonGlow-1.0 comes from `repos.wowace.com/wow/libbuttonglow-1-0`. Record each library's source URL and version in `SaftUI-ActionBars/Libraries/README.md`. LibStub and CallbackHandler come from SaftUI-Core; don't duplicate them.
- Blizzard's action IDs and binding commands for each bar:

  | Bar | Blizzard frame | Action IDs | Binding command |
  |---|---|---|---|
  | 1 (main) | MainMenuBar / MainActionBar | 1–12, paged | `ACTIONBUTTON1–12` |
  | 2 | MultiBarBottomLeft | 61–72 | `MULTIACTIONBAR1BUTTON1–12` |
  | 3 | MultiBarBottomRight | 49–60 | `MULTIACTIONBAR2BUTTON1–12` |
  | 4 | MultiBarRight | 25–36 | `MULTIACTIONBAR3BUTTON1–12` |
  | 5 | MultiBarLeft | 37–48 | `MULTIACTIONBAR4BUTTON1–12` |
  | 6 | MultiBar5 | 145–156 | `MULTIACTIONBAR5BUTTON1–12` |
  | 7 | MultiBar6 | 157–168 | `MULTIACTIONBAR6BUTTON1–12` |
  | 8 | MultiBar7 | 169–180 | `MULTIACTIONBAR7BUTTON1–12` |
  | pet | PetActionBar | pet slots 1–10 | `BONUSACTIONBUTTON1–10` |
  | stance | StanceBar | stance slots | `SHAPESHIFTBUTTON1–10` |

  Verify every row against the forever and live source before relying on it.
- Default layout (spec):
  - Bars 1–3 are rows of 12, bottom centre: bar 1 at the bottom, 20px from the bottom edge, with 2 and 3 stacked above.
  - Bars 4 and 5 are vertical columns of 12, side by side, 20px from the right edge, centred vertically.
  - Icons are 45px with 2px spacing.
  - Bars 6–8 are disabled.
  - Pet and stance bars use ~30px icons, just above the bottom stack (pet on the left, stance on the right).
  - The extra action button, the zone ability and the vehicle leave button sit above the bottom stack.
- Disabled bar: hidden, and its keys are bound to a no-op so Blizzard's hidden button can't fire. With SaftUI-ActionBars disabled, every bind goes back to Blizzard.
- Settings live in `st.defaults.actionbars`, which replaces the legacy table in `SaftUI-Misc/config.lua`. Read through `st:BindModuleConfig(self, 'actionbars')`.
- Positions use `{ point, frame, rel_point, x_off, y_off }` and `st:RoundToPixel`. The Position tab uses `st.Config.generators.position(order, true, get, set, frame)`.
- Combat: no `SetPoint`/`SetSize`/`SetAttribute`/`Show`/`Hide`/`SetParent`/binding changes on secure frames in combat. Go through `st:SafeReposition`/`st:CanMoveNow`/`st:QueueAfterCombat`.
- No Lua tooling. Verify by re-reading changed files and checking Blizzard and LibActionButton names against their source. Each task ends with an in-game checklist for the user.

## Review Focus

1. **Logging in or `/reload` in combat** (including mid-boss): bars must exist with working buttons and binds. Anything protected that couldn't run gets queued and applied after combat, without errors. → Task 1 and Task 2 checks.
2. **Paging changes in combat** (form/stance swap, stealth, vehicle, possess, override bar, pet battle): the main bar shows the right page through the secure state driver alone, with no Lua re-layout. → Task 1 check.
3. **A bind changed while in combat** (Blizzard menu or hover bind): applied when combat ends. Never a blocked action. → Task 2 check.
4. **Turning a bar off and on, live and on a profile switch**: its buttons hide or show, its keys go to the no-op and back, its mover outline still shows in edit mode. → Task 2 and Task 3 checks.
5. **Small icon sizes (e.g. 28px for the 1080p friend)**: hotkey, count and macro text stay inside the button. Cooldown text stays readable. → Task 3 check.

---

### Task 1: SaftUI-ActionBars addon, bars 1–8, Blizzard bars hidden

**Files:**
- Create: `SaftUI-ActionBars/SaftUI-ActionBars.toc`, `SaftUI-ActionBars/init.lua` (module), `SaftUI-ActionBars/config.lua` (defaults), `SaftUI-ActionBars/bars.lua` (bar factory and layout), `SaftUI-ActionBars/hideblizzard.lua`, `SaftUI-ActionBars/skin.lua`, `SaftUI-ActionBars/Libraries/` (LibActionButton-1.0, LibButtonGlow-1.0, README.md)
- Delete: `SaftUI-Misc/actionbars.lua` and its TOC line. Delete the legacy `st.defaults.actionbars` block in `SaftUI-Misc/config.lua`.
- Add the addon to the user's AddOns folders: tell the user the `mklink /D` command (see `.agents/clients.md`). Don't run it.

**Interfaces:**
- Produces:
  - `AB = st:NewModule('ActionBars')`
  - `AB.bars[id]`, keyed by the strings `'bar1'`..`'bar8'`
  - `AB:CreateBar(id) -> barFrame`
  - `AB:LayoutBar(id)`, which sizes and positions buttons from config out of combat
  - `AB:UpdateBar(id)`, which applies enable, layout and skin
  - `AB:UpdateConfig()`
  - Each `bar.buttons[i]` is a LibActionButton button named `SaftUI_ActionBar<id>Button<i>`
  - `AB:GetBindingCommand(id, i) -> string`, from the table in Global Constraints. Task 2 uses it.
  - Config shape per bar: `st.defaults.actionbars[id] = { enable, buttons, perrow, size, spacing, position = {...}, visibility = 'always', text = { hotkey = {...}, count = {...}, macro = {...} } }`. Task 3 adds the Text and Visibility behaviour; this task only stores the defaults.

- [ ] **Step 1:** Fetch LibActionButton-1.0 and LibButtonGlow-1.0 into `Libraries/` and load them from the TOC after SaftUI-Core's libraries. Record source URLs and versions in `Libraries/README.md`.
- [ ] **Step 2:** Bar factory.
  - Each bar is a `SecureHandlerStateTemplate` frame parented to UIParent.
  - Create 12 LibActionButton buttons with the action IDs from the table.
  - The main bar pages through a state driver using the standard LibActionButton paging conditions (as Bartender4/ElvUI do) for stance, form, stealth, vehicle, possess, override and pet battle. Verify each condition against the forever source.
  - Layout: `buttons` shown, `perrow`, `size`, `spacing`, all pixel-rounded.
- [ ] **Step 3:** Skin. Apply SaftUI's button template (backdrop, cropped icon, flat pushed/highlight/checked states, cooldown styling) using SaftUI-owned frames and LibActionButton's own hooks or callbacks. Never write fields onto Blizzard frames.
- [ ] **Step 4:** Hide Blizzard's bars at load, out of combat, taint-free: the main menu bar and its art, the MultiBars, the pet, stance and possess bars, and the vehicle leave button. Prefer `SetRolesets('alwaysBlocked')` and `UnregisterAllEvents` as oUF does, subject to `.agents/taint.md` rules 4 and 8. Don't hide the totem bar (`MultiCastActionBarFrame`), which keeps its own module. If Blizzard re-anchors the totem bar off a hidden bar, note where it ends up.
- [ ] **Step 5:** Defaults from Global Constraints. `UpdateConfig` re-applies every bar; protected parts are deferred in combat.
- [ ] **Step 6: In-game check (user, Forever):**
  - bars 1–5 appear in the default layout and cast on click
  - the main bar pages with stance or form, stealth, a vehicle and a possess
  - Blizzard's bars are gone
  - `/reload` in combat gives no errors
  - no `ADDON_ACTION_BLOCKED` in combat (check `taint.log`)
- [ ] **Step 7: Commit:** `actionbars: add saftui action bars on libactionbutton`

### Task 2: Keybinds and hover binding

**Files:** Create `SaftUI-ActionBars/bindings.lua`.

**Interfaces:**
- Consumes: `AB.bars`, `AB:GetBindingCommand(id, i)`
- Produces: `AB:UpdateBindings()`

- [ ] **Step 1:** `AB:UpdateBindings()` works out of combat only, otherwise it queues. For each button, it calls `SetOverrideBindingClick(owner, false, key, buttonName)` for every key returned by `GetBindingKey(command)`. Disabled bars bind their keys to a no-op (an override binding to an empty or SaftUI no-op click target) so Blizzard's hidden button can't fire. It clears all overrides first with `ClearOverrideBindings(owner)`. It runs on `PLAYER_LOGIN`/enable, `UPDATE_BINDINGS`, and enable/disable changes. The hotkey text shows the bound key (LibActionButton's hotkey support).
- [ ] **Step 2: Hover binding.** Research Blizzard's Quick Keybind Mode in the forever source (`QuickKeybindFrame`, `QuickKeybindButtonTemplate`, how it finds the hovered button and its `commandName`). If SaftUI buttons can join it without writing onto Blizzard frames or tables, make them work in it. Otherwise add a SaftUI hover-bind mode (`/sui kb`, plus a button in `/sui`): hover a button and press a key to call `SetBinding(key, command)` for that button's Blizzard command, then `SaveBindings(GetCurrentBindingSet())`. Escape leaves the mode, and right-click clears the button's binds. Out of combat only.
- [ ] **Step 3: In-game check:**
  - Existing binds fire SaftUI buttons, including paged main bar binds while shapeshifted.
  - A bind set in Blizzard's Key Bindings menu works immediately.
  - Hover binding binds, and the bind shows in Blizzard's menu after `/reload`.
  - A disabled bar's keys do nothing.
  - Disabling SaftUI-ActionBars and reloading gives Blizzard's bars their binds back.
  - Changing a bind in combat applies after combat with no errors.
- [ ] **Step 4: Commit:** `actionbars: map blizzard binding commands and add hover binding`

### Task 3: Movers, `/sui` options, text and visibility

**Files:** Create `SaftUI-ActionBars/options.lua`. Modify `bars.lua` and `skin.lua`.

**Interfaces:**
- Consumes: `AB:UpdateBar(id)`, `AB:LayoutBar(id)`
- Produces:
  - `AB:GetConfigTable()`, a `/sui` section "Action Bars" with one subsection per bar. Each has General (enable, buttons, per row, size, spacing), Text (hotkey, count and macro name: font, size, outline, anchor point, x/y, show), Visibility and Position. The innermost groups become tabs automatically.
  - Movers `ab_bar1`..`ab_bar8`, configPath `{ 'ActionBars', '<id>', 'general' }`.

- [ ] **Step 1:** Register a mover per bar. The overlay covers the bar's full layout even while the bar is hidden by visibility or disabled.
- [ ] **Step 2:** Text tab, applied through LibActionButton's text elements. Restyled live.
- [ ] **Step 3:** Visibility: `always`, `combat` (a secure state driver `[combat] show; hide`), or `mouseover` (alpha fade on enter and leave, combat-safe, alpha only).
- [ ] **Step 4:** Profile switch and live updates through `UpdateConfig`, deferring in combat.
- [ ] **Step 5: In-game check:**
  - Every setting applies live.
  - At 28px, the text stays inside the buttons.
  - Edit mode drag, nudge and click work, and so does `/reload`.
  - Toggling visibility in and out of combat gives no errors.
- [ ] **Step 6: Commit:** `actionbars: add bar options, text and visibility settings`

### Task 4: Pet and stance bars

**Files:** Create `SaftUI-ActionBars/petbar.lua` and `SaftUI-ActionBars/stancebar.lua`. Modify `options.lua`.

**Interfaces:**
- Produces: bars `'pet'` and `'stance'` in `AB.bars`, the same config shape, movers `ab_pet` and `ab_stance`, and `/sui` subsections. Bindings come from `BONUSACTIONBUTTON*` and `SHAPESHIFTBUTTON*`, through Task 2's `UpdateBindings`.

- [ ] **Step 1:** Pet bar (note from Task 1's review: on a `/reload` with a pet out, Blizzard's pet bar is on screen, so `hideblizzard.lua` takes the conceal path instead of blocking it; make sure it stays hidden and unclickable): LibActionButton pet buttons if supported, otherwise SaftUI secure buttons with `type = 'pet'` attributes. It shows only with a pet bar (state driver `[pet,nooverridebar,novehicleui,nopossessbar] show; hide`). Autocast and cooldown work.
- [ ] **Step 2:** Stance bar: secure buttons with `type = 'spell'` built from `GetShapeshiftFormInfo`. It's re-laid out when forms change, out of combat only. It's hidden when the class has no forms.
- [ ] **Step 3: In-game check:**
  - Pet abilities, autocast and pet commands work.
  - Stance switching works.
  - Both use SaftUI's skin at about 30px.
  - Both hide when not applicable.
  - Binds work.
  - Learning a new form updates the bar after combat.
- [ ] **Step 4: Commit:** `actionbars: add pet and stance bars`

### Task 5: Extra action button, zone ability and vehicle leave button

**Files:** Create `SaftUI-ActionBars/extras.lua`. Modify `options.lua`.

**Interfaces:**
- Produces: movers `ab_extra`, `ab_zone` and `ab_vehicleleave`, and `/sui` subsections with General (scale or size) and Position.

- [ ] **Step 1:** Research in the forever and live source how `ExtraActionBarFrame`/`ExtraAbilityContainer` and `ZoneAbilityFrame` are positioned. They're managed frames. Re-anchor them to SaftUI holders the taint-safe way: post-hooks plus `st:SetPointDirect` where `SetPoint` is a Lua override, and never moves in combat. Deferring to after combat is acceptable, as long as they're never stuck where they can't be reached.
- [ ] **Step 2:** Vehicle leave button: a SaftUI secure button with the `VehicleExit` behaviour, shown by state driver `[canexitvehicle] show; hide`, skinned. It must also cover **taxi early landing** (Blizzard's leave button does `TaxiRequestEarlyLanding()` while `UnitOnTaxi('player')`). Task 1 hid Blizzard's button, so that's currently missing.
- [ ] **Step 3: In-game check:**
  - In a quest or encounter with an extra action button, it shows at SaftUI's spot and works.
  - The zone ability shows and works.
  - The vehicle leave button exits the vehicle.
  - Dragging all three works.
  - No errors when these appear in combat.
- [ ] **Step 4: Commit:** `actionbars: add movers for the extra action, zone ability and vehicle leave buttons`

---

**Docs:** In whichever task finishes first, add a `SaftUI-ActionBars/` row to the `AGENTS.md` repo layout table and remove the "Action bars are deferred" note from the edit mode plan. Update `.agents/architecture.md` if anything there changes.
