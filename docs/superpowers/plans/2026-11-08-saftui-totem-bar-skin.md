# Totem Bar Skin and Timers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Skin Forever's totem bar (`MultiCastActionBarFrame`) and its flyout like SaftUI's action bars, and show a toggleable status bar and text countdown above each element button while that element has a totem down.

**Architecture:** Two new files in `SaftUI-Misc` next to `totembar.lua`, both extending the existing `TotemBar` module. `totemskin.lua` restyles Blizzard's buttons in place with post-hooks and SaftUI-owned pieces held in a side table. `totemtimers.lua` adds SaftUI timer frames parented to the four slot buttons, makes the flyout and its open arrow taller so they reach above the timers, and adds the timer settings. `totembar.lua`'s `Setup`, `UpdateConfig` and `GetConfigTable` call into both.

**Tech Stack:** WoW Forever (interface 16001) addon Lua and Blizzard's widget API. Ace3 (AceConfig) for `/sui`. No build step and no test runner: steps are verified by reading the code, by grep checks, and by the user in game.

**Spec:** `docs/superpowers/specs/2026-11-08-saftui-totem-bar-skin-design.md`. Read it in full, including "Settled after the builder check". It is the authority, and this plan only adds names and order.

## Global Constraints

- Forever only. Nothing runs on retail (no `MultiCastActionBarFrame`), and no `/sui` options appear there (`TB:GetConfigTable` already returns nil without `self.bar`).
- `.agents/taint.md` rules, in full:
  - No field writes on any Blizzard frame or table. That means no `st:SetBackdrop` or `st:SkinActionButton` on Blizzard frames, since both write `frame.backdrop`.
  - Post-hooks only.
  - Never `Show`, `Hide` or `SetParent` a visible secure button.
  - `st:QueueAfterCombat` for anything blocked in combat.
- Template and font: `st.config.profile.buttons.template` and `st.config.profile.buttons.font`. Blizzard's button sizes are kept.
- Element colours, sampled from Blizzard's `UI-TotemBar` border art. These are the defaults, by totem slot global:

  | Element | Global | RGB |
  | --- | --- | --- |
  | Earth | `EARTH_TOTEM_SLOT` | `0.29, 0.55, 0.16` |
  | Fire | `FIRE_TOTEM_SLOT` | `0.71, 0.28, 0.13` |
  | Water | `WATER_TOTEM_SLOT` | `0.22, 0.57, 0.71` |
  | Air | `AIR_TOTEM_SLOT` | `0.51, 0.22, 0.90` |

- Warning: the last 10 seconds, in `st.config.profile.colors.text.red`.
- Text format: `m:ss` from 60 seconds up (`4:12`, `1:00`), whole seconds below (`45`), rounded up like Blizzard's (`math.ceil` of the time left).
- New config keys and defaults, in `st.defaults.totembar`:
  - `timer_bar = true`, `timer_text = true`, `timer_text_position = 'above'` (or `'on'`).
  - `colors = { earth = {0.29, 0.55, 0.16}, fire = {0.71, 0.28, 0.13}, water = {0.22, 0.57, 0.71}, air = {0.51, 0.22, 0.90} }`. Not in `/sui`.
- `/sui` labels, verbatim: "Show timer bar", "Show timer text", "Text position", with the choices "Above the bar" and "On the bar".
- Comments in plain language that say why, in the tone of `totembar.lua`.

## Review Focus

1. **Summon page swap.** Changing the summon page swaps which four action buttons show, in or out of combat. The new page's buttons must already be skinned (Task 1 skins all 12 at setup).
2. **Bar hidden by the option or by Blizzard.** With "Hide totem bar" on, or on a character with no totems, setup must not error. No timers show, since they're children of the slot buttons.
3. **Totem replaced, destroyed early or recalled.**
   - Dropping a new totem of the same element restarts its timer at the new duration.
   - Destroying or recalling a totem hides its timer straight away (`PLAYER_TOTEM_UPDATE`).
4. **New totem slot learned.** Blizzard re-orders the slot buttons and re-sets their IDs (`MultiCastSlotButton_Update`). Each timer must then show its own element's totem and colour, read from `slotButton:GetID()` on every update.
5. **Secret values.** No Lua error if `GetTotemInfo` returns secrets: the bar keeps working through the duration object, and the text falls back to the duration object's formatting.

---

### Task 1: Skin the bar, its buttons and the flyout

**Files:**
- Create: `SaftUI-Misc/totemskin.lua`
- Modify:
  - `SaftUI-Misc/totembar.lua`: `TB:Setup` calls `self:SetupSkin()` once the bar is known; `TB:UpdateConfig` calls `self:ApplySkin()`.
  - `SaftUI-Misc/config.lua`: the `colors` default.
  - `SaftUI-Misc/SaftUI-Misc.toc`: `totemskin.lua` right after `totembar.lua`.
  - `.agents/taint.md`: add `SaftUI-Misc/totemskin.lua` to `covers`, and add any new pattern an agent would need.

**Interfaces:**
- Produces:
  - `TB:SetupSkin()`: runs once, out of combat (`TB:Setup` runs at load or on `ADDON_LOADED`). It skins `MultiCastSummonSpellButton`, `MultiCastRecallSpellButton`, `MultiCastSlotButton1..4`, `MultiCastActionButton1..12`, `MultiCastFlyoutFrame` with its `MultiCastFlyoutButton<n>` (lazily made, so post-hook `MultiCastFlyoutFrame_LoadSlotSpells` and `MultiCastFlyoutFrame_LoadPageSpells`), `MultiCastFlyoutFrameOpenButton` and `MultiCastFlyoutFrameCloseButton`. It registers the post-hooks that put the skin back after Blizzard's redraws (spec, Constraints, "Blizzard keeps redrawing the bar").
  - `TB:ApplySkin()`: re-applies template, font and element colours, for a profile change.
  - `TB:GetElementColor(slot) -> r, g, b`, or nil for a slot that isn't 1–4. It reads `self.config.colors` by element key, mapping `EARTH_TOTEM_SLOT` to `earth` and so on.
  - Layout contract for Task 2:
    - The flyout's SaftUI panel is anchored to the flyout's first and last shown buttons, not to `MultiCastFlyoutFrame`'s edges.
    - The open arrow's and close arrow's visible art is anchored to the TOP of their own button frame.
    - So when Task 2 makes these frames taller and moves the column of buttons up, the panel and arrows follow.

- [ ] **Step 1: Read.**
  - The spec in full, `SaftUI-Misc/totembar.lua`, `.agents/taint.md`, and `SaftUI-ActionBars/skin.lua` as the visual reference.
  - Blizzard's Forever source:
    - `Blizzard_ActionBar/Shared/MultiCastActionBarFrame.lua` and `.xml`
    - `Blizzard_ActionBar/Camelot/MultiCastActionBarOverrides.lua`
    - the action button template and mixin these buttons inherit (`ActionBarButtonTemplate`, `ActionButtonTemplate`, `ActionBarActionButtonMixin`), for every region Blizzard re-sets on update.
- [ ] **Step 2: Write `totemskin.lua`.**
  - A local `skins` table keyed by Blizzard frame, holding SaftUI's pieces: a backdrop frame using `st.config.profile.buttons.template`, and flat hover, pushed and checked textures. Blizzard's own regions get widget calls only.
  - Blizzard's art is faded with `SetAlpha(0)`, or reset in post-hooks where Blizzard re-sets it.
  - The element border goes on the slot button's backdrop, coloured with `TB:GetElementColor(slotButton:GetID())`. Re-colour it in a post-hook on `MultiCastSlotButton_Update`, since that's where the ID changes.
  - The flyout's "none" choice (`spellId == 0`) is an empty button in its element's colour.
- [ ] **Step 3: Wire it in.** Edit `totembar.lua`, `config.lua` and the TOC as listed under Files.
- [ ] **Step 4: Verify by reading.**
  - Grep for field writes on Blizzard frames: `grep -nE "(MultiCast[A-Za-z0-9]*|_G\[[^]]*\]|button|frame|slot)\.[A-Za-z_]+ *= " SaftUI-Misc/totemskin.lua`. Every hit must be on a SaftUI-created object or a local. Account for each one in the report.
  - Grep for calls to the field-writing helpers: `grep -n "SetBackdrop\|SkinActionButton" SaftUI-Misc/totemskin.lua` must only hit SaftUI frames.
  - Read every post-hook against Blizzard's function it follows. Confirm each one restores everything that function resets.
  - Walk through Review Focus items 1 and 2 against the code.
- [ ] **Step 5: Commit.** Message `misc: skin the totem bar and its flyout`.

### Task 2: Timers above the element buttons, the taller flyout, and the settings

**Files:**
- Create: `SaftUI-Misc/totemtimers.lua`
- Modify:
  - `SaftUI-Misc/totembar.lua`:
    - `TB:Setup` calls `self:SetupTimers()` after `SetupSkin`.
    - `TB:UpdateConfig` calls `self:ApplyTimerLayout()`.
    - `TB:GetConfigTable` adds the three options after `hide`, before `move_note`. The `set` handler applies them straight away.
  - `SaftUI-Misc/config.lua`: the three `timer_*` defaults.
  - `SaftUI-Misc/SaftUI-Misc.toc`: `totemtimers.lua` after `totemskin.lua`.
  - `.agents/taint.md`: add `SaftUI-Misc/totemtimers.lua` to `covers`.
  - `README.md`: a Usage bullet for `/sui` → Totem Bar, covering the skin and the timers, in its style.

**Interfaces:**
- Consumes (Task 1):
  - `TB:GetElementColor(slot) -> r, g, b`
  - the layout contract: the panel anchored to the buttons, the arrow art to the TOP.
- Produces:
  - `TB:SetupTimers()`: once, out of combat. It makes one timer per slot button, parented to that slot button so it hides with the bar and with an unlearned slot. Each timer is a status bar and a font string, with `EnableMouse(false)`, in a local table keyed by slot button. It registers `PLAYER_TOTEM_UPDATE` and `PLAYER_ENTERING_WORLD`, post-hooks `MultiCastSlotButton_Update`, and adds the flyout growth hooks. Register its hooks after Task 1's, so they run after the skin.
  - `TB:UpdateTimers()`: refreshes all four from `GetTotemInfo` / `GetTotemDuration(slotButton:GetID())`.
  - `TB:ApplyTimerLayout()`: bar and text visibility, text position, bar heights and the flyout growth height, from the profile.
  - `TB:GetTimerAreaHeight() -> number`: the height the timers take above a button under the current settings. It is 0 when both are off, and it doesn't depend on whether a totem is down.

- [ ] **Step 1: Read.**
  - The spec's Timers, Settings and "Settled after the builder check" sections.
  - Forever's `Blizzard_APIDocumentationGenerated`: `TotemDocumentation.lua`, `SimpleStatusBarAPIDocumentation.lua` (`SetTimerDuration(duration, interpolation, direction)`), `LuaDurationObjectAPIDocumentation.lua` and the `DurationTextBinding*` docs.
  - `MultiCastFlyoutFrameOpenButton_Show` / `_Hide`, `MultiCastFlyoutFrame_ToggleFlyout` / `_Hide` / `_LoadSlotSpells`, and the slot and action buttons' `OnLeave`, for the mouse checks that the growth has to satisfy.
- [ ] **Step 2: Write `totemtimers.lua`.**
  - The bar drains through `SetTimerDuration` with the remaining-time direction.
  - The text and the warning colour come from plain math while `GetTotemInfo`'s values aren't secret (`issecretvalue`), and from the duration object's formatting and colour curve when they are.
  - Update the text on a throttled OnUpdate (about 0.1s) that only runs while a timer shows.
  - Layouts:
    - Above: a thin bar right above the button, with the text over the bar.
    - On: a taller bar with the text on it.
    - Text only: the text just above the button.
  - Flyout growth:
    - After Blizzard places the open arrow (`MultiCastFlyoutFrameOpenButton_Show`), make it `GetTimerAreaHeight()` taller. Its BOTTOM stays at the button's TOP.
    - After `MultiCastFlyoutFrame_ToggleFlyout` and the load functions, make the flyout that much taller and move its first button up by the same amount.
    - Check whether either frame is protected or blocked in combat. If it is, skip the growth for in-combat openings and say so in the report.
- [ ] **Step 3: Wire it in.** Add the settings to `totembar.lua`, the defaults to `config.lua`, update the TOC, `taint.md` and the README.
  - "Text position" is a `select` with `sorting = {'above', 'on'}`.
  - It's greyed out (`disabled`) unless both `timer_bar` and `timer_text` are on.
- [ ] **Step 4: Verify by reading.**
  - Run the same field-write and helper greps as Task 1 on `totemtimers.lua`.
  - Confirm `GetTimerAreaHeight()` returns 0 with both toggles off, and that the arrow and flyout heights come back to Blizzard's then.
  - Walk through Review Focus items 3, 4 and 5 against the code.
  - Confirm a profile switch (`TB:UpdateConfig`) applies all three settings.
- [ ] **Step 5: Commit.** Message `misc: totem timers above the totem bar's element buttons`.
