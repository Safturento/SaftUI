---
name: taint
description: Rules for touching Blizzard frames and code without causing taint, blocked actions or crashes
last_updated: 2026-11-07
covers:
  - 'SaftUI-Core/api.lua'
  - 'SaftUI-Core/taintfix.lua'
  - 'SaftUI-Misc/Skinning/**'
  - 'SaftUI-Misc/totembar.lua'
  - 'SaftUI-Minimap/**'
  - 'SaftUI-ActionBars/hideblizzard.lua'
  - 'SaftUI-ActionBars/skin.lua'
  - 'SaftUI-ActionBars/bindings.lua'
---

# Taint and combat safety

WoW marks every Lua value written by addon code as *tainted* by that addon. Secure Blizzard code that later reads a tainted value runs tainted, and if it then makes a protected call (moving or showing an action bar, `SetAttribute` on a secure button, etc.), the game blocks it with `ADDON_ACTION_BLOCKED` blamed on SaftUI. The error usually fires far from the cause, often in combat, so these rules are strict.

## Rules

1. **Never write Lua fields or methods onto a Blizzard frame or table.** That includes:
   - `frame.backdrop` via `st:SetBackdrop(blizzardFrame)`
   - `frame.SetFoo = st.dummy`
   - `st:Kill` (it replaces `Show`)
   - your own `frame.width`
   - adding keys to Blizzard tables

   Keep SaftUI's per-frame data in a local weak table (`setmetatable({}, { __mode = 'k' })`) or on a SaftUI-owned frame. Writing fields onto frames SaftUI created (including oUF frames it spawned) is fine.
2. **Hook only with post-hooks:** `hooksecurefunc(...)`, native `frame:HookScript(...)`, or AceHook `SecureHook`/`SecureHookScript`. Never AceHook `Hook`/`RawHook`/`HookScript`, which install closures with `SetScript` and replace Blizzard's handlers. Never `SetScript` on a Blizzard frame.
3. **Don't run Blizzard callbacks from SaftUI code.** Calling a Blizzard function that writes Blizzard state (e.g. `HelpTip:HideAllSystem`, a frame's `Update()`, alert or close callbacks) runs that code in SaftUI's tainted context and taints what it writes. Prefer re-applying SaftUI's own state in a post-hook after Blizzard runs.
4. **Moving or showing a frame can run its scripts.** `SetParent`, `Show` and `Hide` on a visible frame fire `OnShow`/`OnHide` in your call chain. For Blizzard secure buttons that writes tainted state. Only reparent or hide when it won't change on-screen visibility, otherwise apply at the next `/reload` (see `SaftUI-Misc/totembar.lua`).
5. **Blizzard Edit Mode system frames have Lua overrides** for `SetPoint`, `ClearAllPoints`, `SetScale`, `SetShown` and `Hide` that write Edit Mode state (e.g. `EditModeManagerFrame.editModeSystemAnchorDirty`). Examples: ChatFrame1, BuffFrame/DebuffFrame, QueueStatusButton (Forever), swing timer bars, the totem bar, MinimapCluster, the micro menu, the status tracking bars.
   - Move them with `st:SetPointDirect` / `st:ClearAllPointsDirect` / `st:SetSizeDirect`. These call the C widget methods via `getmetatable(frame).__index`.
   - Never call the overridden methods from SaftUI code.
   - To keep a position, post-hook their `SetPoint`/`ClearAllPoints` (or `UpdateSystem`) and re-apply with the direct helpers. Hide their Edit Mode box with `frame.Selection:HookScript('OnShow', function(s) s:Hide() end)`.
6. **Combat:**
   - Secure frames (unit frames, action buttons, group headers) can't be moved, sized, shown, hidden, reparented or have attributes set in combat. Neither can any frame a secure frame is anchored to, which becomes implicitly protected.
   - Route every move through `st:SafeReposition(frame, key, fn)`, which runs `fn` now or after combat. Check with `st:CanMoveNow(frame)`. Defer other work with `st:QueueAfterCombat(key, fn)`.
   - Key binding calls are blocked in combat too: `SetBinding`, `SaveBindings`, `SetOverrideBindingClick` and the other `SetOverrideBinding*`, and `ClearOverrideBindings`. Queue them with `st:QueueAfterCombat`, as `SaftUI-ActionBars/bindings.lua` does.
   - Edit mode, `/sui` and the action bars' keybind mode close on `PLAYER_REGEN_DISABLED` and refuse to open in combat.
7. **No arithmetic or comparisons on secret values.** See `.agents/clients.md`.
8. **To hide a Blizzard frame for good**, prefer `frame:SetRolesets('alwaysBlocked')`, as oUF does for party frames and `SaftUI-Unitframes/groups.lua` does for `CompactRaidFrameContainer`. It's one C call that writes nothing onto the frame, and the frame stops drawing whatever Blizzard's own Show/Hide calls do. It's still bound by rule 4: apply it only while the frame isn't on screen, and only out of combat.
   - A frame that's always on screen when SaftUI loads (Blizzard's `MainActionBar`) can be concealed instead, without changing its visibility: `SetAlpha(0)` and `EnableMouse(false)` on it and its mouse-enabled children, called through `getmetatable(frame).__index`. See `SaftUI-ActionBars/hideblizzard.lua`.
9. **Don't override Blizzard globals or APIs**, not even for test data (e.g. faking `GetLootRollItemInfo` or `UnitExists`). Build SaftUI-owned preview frames instead (`SaftUI-Loot/roll.lua` `CreateRollPreviews`).
10. **Ace skin fonts:** never `SetFontObject` with an object you got from `GetFontObject()` unless it's a named global Font. Restoring an engine-made Font made a region inherit from itself and crashed the client with a C stack overflow (`31afa68`). Use `IsNamedFont`/`RestoreFont` in `SaftUI-Core/Config/aceskin.lua`.

## Past incidents (to recognize the pattern)

- **`3211006`** — a `hooksecurefunc` on `MainMenuMicroButton_ShowAlert` called `HelpTip:HideAllSystem`. That ran Blizzard's alert close callback tainted and tainted the micro button alert globals. Opening the spellbook in combat then hit `ADDON_ACTION_BLOCKED` on `MultiBarBottomLeft:SetFrameStrata`.
- **`8bee1ca`..`541efc4`** — the minimap bar replaced Blizzard scripts with AceHook and called Forever's `QueueStatusButton` `SetPoint` override, writing Edit Mode state under taint.
- **`9403497`** — reparenting the visible totem bar ran its secure buttons' `OnHide` from SaftUI, which could leave tainted state that blocks entering a vehicle in combat.
- **`31afa68`** — the Ace skin restored an engine-made font object, which crashed the client (C stack overflow).

## Debugging taint

Ask the user to `/console taintLog 1`, reproduce, then `/reload`. The `Logs/taint.log` file and BugGrabber's saved errors are readable directly; paths are in `.agents/clients.md`.
