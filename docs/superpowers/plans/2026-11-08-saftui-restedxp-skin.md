# RestedXP Guides Window Skin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle RestedXP Guides' v1 guide window into two SaftUI chat-style panels (current steps; guide name + step list + footer) with thin dividers, SaftUI's chat font, a Colus guide title and a flat scroll bar.

**Architecture:** One new skin module in `SaftUI-Misc/Skinning/restedxp.lua`. It never replaces RestedXP code. It post-hooks the four RestedXP functions that restyle the window (`RXPFrame:UpdateVisuals`, `RXPFrame.UpdateScrollBar`, `RXPFrame.CurrentStepFrame.UpdateText`, `RXPFrame.BottomFrame.UpdateFrame`), and each RestedXP frame's own `SetBackdrop` / `SetBackdropColor` and each FontString's `SetFont`. It draws its panels on SaftUI-owned frames anchored to RestedXP's frames.

**Tech Stack:** WoW Lua (Forever 16001, RestedXP v4.11.35), AceAddon/AceHook via SaftUI's `Skinning` module, a lupa mock harness in the session scratchpad for logic checks.

**Spec:** `docs/superpowers/specs/2026-11-08-saftui-restedxp-skin-design.md`

## Global Constraints

- New file `SaftUI-Misc/Skinning/restedxp.lua`, module `local RX = SK:NewModule('RestedXP')` (`SK = st:GetModule('Skinning')`), listed in `SaftUI-Misc/Skinning/load.xml` right after `hekili.lua`.
- RestedXP source to read (read-only, not in the repo): `/tmp/claude-1000/-mnt-c-Github-wow-addons-SaftUI-Modular/f9fdefff-45d5-4c08-9fb0-3c0ba643bed7/scratchpad/rxp/RXPGuides/GuideWindow.lua`. Line numbers below refer to it.
- Never `SetScript` on a RestedXP frame and never call a RestedXP function. Hook only: AceHook `self:SecureHook(obj, 'method', handler)` for the four RestedXP functions; `hooksecurefunc(frame, 'Method', fn)` for per-frame and per-FontString hooks (each hooked once, tracked in a side table); `frame:HookScript` for show/hide syncing.
- SaftUI's own state for RestedXP frames lives in module-local side tables keyed by the RestedXP frame, never as fields on RestedXP frames. SaftUI may create textures on RestedXP frames and SaftUI frames parented to them. Never call `st:SetBackdrop` on a RestedXP frame (`RXPFrame.backdrop` is RestedXP's own table): only on SaftUI-owned frames.
- Style source: template `st.config.profile.chat.template`, font `st.config.profile.chat.font`; when `st.config.profile.chat` or the key is nil, `'thicktransparent'` and `'normal'`. Face and outline come from `st:GetFont(fontName):GetFont()`; sizes stay what RestedXP asks for.
- Title: face and outline from `st:GetFont('title'):GetFont()` (Colus), size = RestedXP's requested size + `TITLE_SIZE_BONUS = 3`, colour left as RestedXP sets it (white).
- Colours: muted grey = `st.config.profile.colors.text.grey:GetRGB()`; hover highlight = `st.config.profile.templates.highlight.backdropcolor`; divider = the active template's `bordercolor` RGB at alpha `0.5`. Dividers are 1 pixel tall (`PixelUtil.SetHeight(tex, 1)`).
- Silent when RestedXP or any frame it expects is missing: no errors, skip what isn't there.
- The window's look follows SaftUI profile changes (`SK:UpdateConfig` reaches `RX:UpdateConfig`) and SaftUI-Chat's own config updates (post-hook `st:GetModule('Chat', true):UpdateConfig` when that module exists) without a `/reload`.

## Review Focus

1. RestedXP re-applies its theme (`RXPFrame:UpdateVisuals`, a theme switch, a font size change): every backdrop SaftUI cleared comes back cleared, every font comes back SaftUI's. (Task 1 test `theme_reapply_stays_skinned`)
2. A guide with hidden or optional steps (RestedXP sets those frames' alpha to 0, 1px tall): no divider shows for them, because dividers live on the step frame and fade with it. (Task 2 test `hidden_step_divider_fades`)
3. A tip step joins or leaves the current steps (a pooled step frame switches between the stack and the floating tip window): it gets its own panel only while it's a tip, and no stack divider. (Task 3 test `tip_frame_switches_role`)
4. RestedXP's v2 window is turned on: RestedXP hides the v1 frames (`addon.v2:DisableLegacyGuideWindow`, `UI/V2/Core.lua:1536`), and SaftUI's guide panel must hide with them though it's parented to `RXPFrame`, which stays shown. (Task 1 test `v2_hides_guide_panel`)
5. RestedXP loads after SaftUI-Misc, or isn't installed: setup waits for `ADDON_LOADED` `RXPGuides`, or never runs, without errors. (Task 1 tests `late_load_sets_up`, `no_rxp_no_error`)

## The harness

There is no test runner in the repo. Each task's tests run in a lupa (Lua 5.5) mock harness kept outside the repo, at `HARNESS=/tmp/claude-1000/-mnt-c-Github-wow-addons-SaftUI-Modular/f9fdefff-45d5-4c08-9fb0-3c0ba643bed7/scratchpad/rxpsim`, run with `PY=/tmp/claude-1000/-mnt-c-Github-wow-addons-SaftUI-Modular/f9fdefff-45d5-4c08-9fb0-3c0ba643bed7/scratchpad/lupavenv/bin/python` (lupa installed). Task 1 creates it; later tasks add test files.

- `mocks.lua`: `unpack = unpack or table.unpack`; frames, textures and FontStrings as tables with the methods the skin calls (record calls, keep points/size/alpha/shown/level/font/color); `hooksecurefunc(tbl, key, fn)` that wraps `tbl[key]`; `CreateFrame`, `UIParent`, `PixelUtil`, `C_AddOns.IsAddOnLoaded`; a Backdrop mock (`SetBackdrop` sets `backdropInfo`, `ClearBackdrop` clears it, `SetBackdropColor` is a no-op without `backdropInfo`, as Blizzard's `Backdrop.lua:406`); SaftUI mocks: `SaftUI` with `GetModule`/`NewModule` returning AceAddon-like modules whose `SecureHook` uses `hooksecurefunc` and `RegisterEvent` records handlers, `st:GetFont(name)` returning an object whose `GetFont()` gives `(face, size, outline)` per name (`normal` → `'AgencyFB', 16, 'OUTLINE'`; `title` → `'Colus', 72, 'OUTLINE'`), `st:SetBackdrop(frame, template)` recording `frame.backdrop.template`, `st:CreateFrame`, and `st.config.profile` with `chat = { template = 'thicktransparent', font = 'normal' }`, `templates.thicktransparent.bordercolor = {0.3,0.3,0.3,1}`, `templates.highlight.backdropcolor = {0.3,0.3,0.3,0.4}`, `colors.text.grey` with `GetRGB()` → `0.59,0.59,0.59`.
- `rxp_mock.lua`: `MakeRXP()` builds global `RXPFrame` with `BottomFrame`, `GuideName` (+`text`, `bg`, `icon`, `classIcon`), `Footer` (+`text`, `bg`, `cog`, `icon`), `CurrentStepFrame` (+`framePool`), `ScrollFrame` (+`ScrollBar` with `ScrollUpButton`, `ScrollDownButton`, `SetThumbTexture`/`GetThumbTexture`, `GetRegions`), `ScrollChild` (+`framePool`), anchored as `GuideWindow.lua:473-474, 1402-1427, 1508-1510`. Its `UpdateVisuals`, `UpdateScrollBar`, `CurrentStepFrame.UpdateText`, `BottomFrame.UpdateFrame` and helpers `AddCurrentStep(opts)` / `AddListStep(opts)` / `LoadGuide(n)` mimic RestedXP's calls on those frames (the `SetBackdrop`, `SetBackdropColor`, `SetFontObject`+`SetFont`, `SetTextColor`, `SetAlpha`, `SetPoint` calls in `GuideWindow.lua` lines 52-82, 146-180, 990-1062, 1240-1394, 2000-2110, 1512-1526).
- `run.py`: loads `mocks.lua`, `rxp_mock.lua`, the repo's `SaftUI-Misc/Skinning/restedxp.lua`, then each `test_*.lua` given on the command line in a fresh `LuaRuntime`; each test file defines `check(cond, name)` results and ends with `print(fails == 0 and 'ALL PASS' or fails .. ' FAILED')`. Exit code 1 on any failure.

Run: `$PY $HARNESS/run.py $HARNESS/test_task1.lua` (and so on). Expected: every check `ok:`, last line `ALL PASS`.

---

### Task 1: Module, setup, fonts, and the guide panel's frame

**Files:**
- Create: `SaftUI-Misc/Skinning/restedxp.lua`
- Modify: `SaftUI-Misc/Skinning/load.xml` (add `<Script file="restedxp.lua"/>` after `hekili.lua`)
- Modify: `README.md` (Usage bullet), `.agents/taint.md` (rules intro or rule 1: third-party addon frames)
- Test: `$HARNESS/mocks.lua`, `$HARNESS/rxp_mock.lua`, `$HARNESS/run.py`, `$HARNESS/test_task1.lua`

**Interfaces:**
- Produces (used by Tasks 2 and 3):
  - `RX:GetStyle() -> template: string, fontName: string`
  - `local function HookFont(fs, kind)`: `kind` is `'text'` or `'title'`. Idempotent. Remembers RestedXP's requested size (`requestedSize[fs]`, from `fs:GetFont()` at hook time and from every later RestedXP `SetFont`) and applies SaftUI's face and outline at that size (title: Colus at size + `TITLE_SIZE_BONUS`). A re-entrancy guard keeps SaftUI's own `SetFont` from being re-handled. A FontString with no font yet is tracked and styled on RestedXP's first `SetFont`.
  - `local function NoBackdrop(frame)`: clears the frame's backdrop now and after every `SetBackdrop` RestedXP makes on it. Idempotent.
  - `local function MakeDivider(frame) -> texture`: a 1px texture on `frame`, coloured as Global Constraints say, recoloured by `RX:UpdateConfig`.
  - `local function MakePanel(parent) -> frame`: a SaftUI frame (`st:CreateFrame`) on which `st:SetBackdrop(panel, template)` is called; tracked so `RX:UpdateConfig` re-applies the template.
  - `RX:UpdateConfig()`: re-applies every panel's template, every hooked FontString's font, every divider's and highlight's colour.
  - `RX.frames`: the RestedXP frames table `{ RXPFrame=, GuideName=, Footer=, BottomFrame=, ScrollFrame=, ScrollChild=, CurrentStepFrame= }`, set by `Setup`.

- [ ] **Step 1: Build the harness and write `test_task1.lua`** with these checks:
  - `no_rxp_no_error`: with no `RXPFrame` and `IsAddOnLoaded('RXPGuides') == false`, `RX:OnEnable()` runs without error and installs no hooks.
  - `late_load_sets_up`: `RX:OnEnable()` before `MakeRXP()`, then `MakeRXP()` and the recorded `ADDON_LOADED` handler called with `'RXPGuides'` → `GuideName.bg`, `GuideName.icon`, `GuideName.classIcon`, `Footer.bg` are hidden; an `ADDON_LOADED` for another addon does nothing.
  - `chrome_skinned`: after setup, `GuideName`, `Footer`, `BottomFrame` have `backdropInfo == nil`; a guide panel frame exists with `backdrop.template == 'thicktransparent'`, anchored `TOPLEFT` to `GuideName` `TOPLEFT` and `BOTTOMRIGHT` to `Footer` `BOTTOMRIGHT`.
  - `title_font`: `GuideName.text` font is `('Colus', 11 + 3, 'OUTLINE')` when RestedXP had set `(GameFontFace, 11, '')`; RestedXP then calling `GuideName.text:SetFont(face, 13, '')` gives `('Colus', 16, 'OUTLINE')`.
  - `footer_font`: `Footer.text` gets `('AgencyFB', 9, 'OUTLINE')` from RestedXP's `(face, 9, '')`.
  - `title_recentred`: `GuideName.text` is anchored `LEFT` and `RIGHT` to `GuideName` with equal insets (no 29px logo offset).
  - `scroll_below_title`: `ScrollFrame`'s `TOPLEFT` point is relative to `GuideName`'s `BOTTOMLEFT`; its `BOTTOMRIGHT` is unchanged from RestedXP's.
  - `dividers_title_footer`: one divider under the guide name (anchored to `GuideName`'s bottom edge) and one at `Footer`'s top edge, colour `(0.3, 0.3, 0.3, 0.5)`.
  - `theme_reapply_stays_skinned`: `RXPFrame:UpdateVisuals()` (mock re-sets backdrops and banner textures) → backdrops still `nil`, banner textures still hidden.
  - `v2_hides_guide_panel`: `GuideName:Hide()` hides the guide panel; `GuideName:Show()` shows it again.
  - `config_follows_chat`: set `st.config.profile.chat.font = 'pixel'` (mock `pixel` → `'Homespun', 10, 'MONOCHROMEOUTLINE'`) and `template = 'thick'`, call `RX:UpdateConfig()` → `Footer.text` font `('Homespun', 9, 'MONOCHROMEOUTLINE')`, guide panel `backdrop.template == 'thick'`; with `st.config.profile.chat = nil`, `RX:GetStyle()` returns `'thicktransparent', 'normal'`.
  - `chat_update_hooked`: with a mock `Chat` module present, calling its `UpdateConfig` triggers `RX:UpdateConfig` (spy).

- [ ] **Step 2: Run, verify the checks fail** (module file missing or empty).
Run: `$PY $HARNESS/run.py $HARNESS/test_task1.lua` — Expected: errors or FAILED.

- [ ] **Step 3: Implement in `SaftUI-Misc/Skinning/restedxp.lua`:**
  - `RX:OnEnable()`: if `C_AddOns.IsAddOnLoaded('RXPGuides')` and `RXPFrame`, `self:Setup()`; else `self:RegisterEvent('ADDON_LOADED')`, and the handler calls `Setup` (and unregisters) when the name is `'RXPGuides'`. Hook the Chat module's `UpdateConfig` here if it exists.
  - `RX:Setup()`: once only; collect `RX.frames` from `RXPFrame` and return if any is nil. Then:
    - `NoBackdrop` on `BottomFrame`, `GuideName`, `Footer`; `Hide()` `GuideName.bg`, `GuideName.icon`, `GuideName.classIcon`, `Footer.bg` (RestedXP only ever re-`SetTexture`s them, never `Show`s).
    - Guide panel: `MakePanel(RXPFrame)`, anchored as in `chrome_skinned`, frame level `RXPFrame:GetFrameLevel() + 1` (its backdrop sits one below), shown state synced to `GuideName` by `HookScript('OnShow'/'OnHide')` and set once now.
    - Dividers: under the title (on the guide panel, `TOPLEFT`/`TOPRIGHT` to `GuideName` `BOTTOMLEFT`/`BOTTOMRIGHT`) and at the footer's top (`BOTTOMLEFT`/`BOTTOMRIGHT` to `Footer` `TOPLEFT`/`TOPRIGHT`).
    - Re-anchor `GuideName.text` `LEFT` (`GuideName`, 4, 0) and `RIGHT` (`GuideName`, -4, 0); re-anchor `ScrollFrame` `TOPLEFT` to `GuideName` `BOTTOMLEFT` (5, 0), keeping its `BOTTOMRIGHT` (`BottomFrame`, -20, 7). RestedXP sets these points only once, at load (`GuideWindow.lua:1409-1410, 1508`).
    - `HookFont(GuideName.text, 'title')`, `HookFont(Footer.text, 'text')`.
    - `self:SecureHook(RXPFrame, 'UpdateVisuals', 'SkinChrome')`, where `RX:SkinChrome()` re-hides the four textures (cheap safety; `NoBackdrop`'s hooks already handle the backdrops).
    - Later tasks add their hooks and first passes at the end of `Setup`.
  - `RX:UpdateConfig()` and the helpers as in Interfaces.

- [ ] **Step 4: Run, verify all pass.**
Run: `$PY $HARNESS/run.py $HARNESS/test_task1.lua` — Expected: `ALL PASS`.

- [ ] **Step 5: Docs.**
  - `README.md` Usage: one bullet saying SaftUI restyles RestedXP Guides' guide window into SaftUI's chat look. It follows SaftUI-Chat's panel and font and RestedXP's "Guide font size", and leaves RestedXP's newer (beta) guide window alone.
  - `.agents/taint.md` (it covers `SaftUI-Misc/Skinning/**`): one line saying third-party addon frames (RestedXP in `restedxp.lua`) aren't Blizzard frames, so rule 1 doesn't bind them, but SaftUI still only adds to their scripts (no `SetScript`) and keeps its state in side tables. Bump `last_updated`.

- [ ] **Step 6: Commit.**
```bash
git add SaftUI-Misc/Skinning/restedxp.lua SaftUI-Misc/Skinning/load.xml README.md .agents/taint.md
git commit -m "misc: skin RestedXP Guides' window frame in SaftUI's chat look"
```

---

### Task 2: The step list and the scroll bar

**Files:**
- Modify: `SaftUI-Misc/Skinning/restedxp.lua`
- Test: `$HARNESS/test_task2.lua` (extend `rxp_mock.lua` only where a RestedXP call isn't mocked yet)

**Interfaces:**
- Consumes: `HookFont`, `NoBackdrop`, `MakeDivider`, `RX.frames`, `RX:UpdateConfig` from Task 1.
- Produces: `RX:SkinList()` and `RX:SkinScrollBar()`, both idempotent and called once at the end of `Setup`.

- [ ] **Step 1: Write `test_task2.lua`** with these checks:
  - `list_frames_skinned`: after `LoadGuide(5)` (mock: creates `ScrollChild.framePool[1..5]` as `GuideWindow.lua:2000-2110` does, then calls `BottomFrame.UpdateFrame()`), each frame has `backdropInfo == nil`; `frame.text` font `('AgencyFB', 9, 'OUTLINE')`; `frame.number.text` font `('AgencyFB', 8, 'OUTLINE')` and colour grey.
  - `list_dividers`: frames 2-5 each have one divider anchored `BOTTOMLEFT`/`BOTTOMRIGHT` to the frame's `TOPLEFT`/`TOPRIGHT` at y offset `1`; frame 1 has none (the title divider covers it).
  - `hidden_step_divider_fades`: the divider is a region of its step frame (`divider:GetParent() == frame`), so the mock frame's `SetAlpha(0)` makes `divider:GetEffectiveAlpha() == 0`.
  - `hover_highlight`: with the frame's `IsMouseOver()` true, RestedXP's `OnEnter` path (`frame:SetBackdropColor(highlightRGBA)`) shows the frame's highlight texture coloured `(0.3, 0.3, 0.3, 0.4)`; with it false, the `OnLeave` path (`SetBackdropColor(bgRGBA)`) hides it.
  - `reload_guide_keeps_skin`: `LoadGuide(7)` again (RestedXP `SetScript`s `OnEnter`/`OnLeave` anew, re-sets backdrops and fonts) → frames 1-7 still skinned, hover still works, no frame hooked twice (hook counter per frame is 1).
  - `scrollbar_flat`: after `RXPFrame.UpdateScrollBar()` (mock sets RestedXP's button and knob textures), `ScrollUpButton` and `ScrollDownButton` have alpha 0 and mouse disabled, the thumb texture is `st.BLANK_TEX` (mock value) sized `4 x 32` and coloured grey, a track texture exists on the bar, and the bar is anchored `TOPLEFT` to `ScrollFrame` `TOPRIGHT` (6, 0) and `BOTTOMLEFT` to `ScrollFrame` `BOTTOMRIGHT` (6, 0), width `8`.

- [ ] **Step 2: Run, verify they fail.** `$PY $HARNESS/run.py $HARNESS/test_task2.lua` — Expected: FAILED.

- [ ] **Step 3: Implement.**
  - `RX:SkinList()`: for each frame in `ScrollChild.framePool` not yet skinned (side table): `NoBackdrop(frame)`; a highlight texture (`BACKGROUND`, all points) shown or hidden by a `hooksecurefunc(frame, 'SetBackdropColor', …)` that checks `frame:IsMouseOver()` (RestedXP's `OnEnter`/`OnLeave` call `SetBackdropColor` and survive its `SetScript`s); `HookFont(frame.text, 'text')`; for `frame.number.text`: `HookFont(…, 'text')` and grey `SetTextColor` (RestedXP colours it only when it creates it); `MakeDivider(frame)` for every frame but `framePool[1]`, anchored as in `list_dividers`. Post-hook `BottomFrame.UpdateFrame` with `self:SecureHook(BottomFrame, 'UpdateFrame', 'SkinList')`. A pooled frame keeps its skin across guide loads.
  - `RX:SkinScrollBar()`: on `ScrollFrame.ScrollBar`: up and down buttons `SetAlpha(0)` and `EnableMouse(false)`; every other region of the bar hidden except the thumb and SaftUI's track; `SetThumbTexture(st.BLANK_TEX)`, thumb `SetSize(4, 32)` and grey; a track texture (`BACKGROUND`, 4px wide, full height, centred, black at alpha 0.5); bar re-anchored and sized as in `scrollbar_flat`. Post-hook `RXPFrame.UpdateScrollBar` with `self:SecureHook(RXPFrame, 'UpdateScrollBar', 'SkinScrollBar')`.
  - Call both once at the end of `Setup`; `RX:UpdateConfig` recolours highlights, dividers and the thumb.

- [ ] **Step 4: Run, verify all pass (Task 1's too).**
Run: `$PY $HARNESS/run.py $HARNESS/test_task1.lua $HARNESS/test_task2.lua` — Expected: `ALL PASS` for both.

- [ ] **Step 5: Commit.**
```bash
git add SaftUI-Misc/Skinning/restedxp.lua
git commit -m "misc: RestedXP step list and scroll bar in SaftUI's look"
```

---

### Task 3: The current steps and the tip window

**Files:**
- Modify: `SaftUI-Misc/Skinning/restedxp.lua`
- Test: `$HARNESS/test_task3.lua`

**Interfaces:**
- Consumes: `HookFont`, `NoBackdrop`, `MakeDivider`, `MakePanel`, `RX.frames`, `RX:UpdateConfig` from Task 1.
- Produces: `RX:SkinCurrentSteps()`, idempotent, called once at the end of `Setup` and post-hooked to `CurrentStepFrame.UpdateText`.

- [ ] **Step 1: Write `test_task3.lua`** with these checks:
  - `steps_panel`: after setup, a SaftUI panel parented to `CurrentStepFrame`, all points on it, `backdrop.template == 'thicktransparent'`; `CurrentStepFrame`'s `BOTTOMLEFT`/`BOTTOMRIGHT` are re-anchored to `GuideName`'s `TOPLEFT`/`TOPRIGHT` at y `9` (RestedXP had `2`).
  - `steps_panel_hidden_when_empty`: after `UpdateText` leaves `CurrentStepFrame` at height ≤ 2, the panel is hidden; at height 40 it shows.
  - `current_steps_skinned`: after `AddCurrentStep` ×3 and `UpdateText()` (mock follows `GuideWindow.lua:990-1062, 1240-1394`: first step anchored to `CurrentStepFrame`, others to the previous frame's bottom at y `-5`), each step frame and its `number` frame have `backdropInfo == nil`; every element's `text` font is `('AgencyFB', 11, 'OUTLINE')` (RestedXP's size + 2 kept); `number.text` is grey, anchored `TOPRIGHT` to the step frame at (-5, -1), justified right, font `('AgencyFB', 9, 'OUTLINE')`.
  - `current_dividers`: step 1 (anchored to `CurrentStepFrame`) has its divider hidden; steps 2 and 3 have theirs shown, anchored `BOTTOMLEFT`/`BOTTOMRIGHT` to the frame's `TOPLEFT`/`TOPRIGHT` at y `2`.
  - `tip_frame_switches_role`: a step added with `tip = true` (mock anchors it to `UIParent`, as `GuideWindow.lua:1001-1009`) gets a SaftUI panel (parented to it, all points, template set) and its divider hidden; next `UpdateText` with that pooled frame as a normal second step → its tip panel hidden, divider shown.
  - `theme_reapply_current`: the mock re-runs RestedXP's theme branch (`stepframe:SetBackdrop(...)` when `stepframe.theme` changes) → backdrops cleared again.
  - `config_current`: `RX:UpdateConfig()` after switching chat's template to `'thick'` → steps panel and any tip panel get `'thick'`.

- [ ] **Step 2: Run, verify they fail.** `$PY $HARNESS/run.py $HARNESS/test_task3.lua` — Expected: FAILED.

- [ ] **Step 3: Implement `RX:SkinCurrentSteps()`.**
  - In `Setup`: re-anchor `CurrentStepFrame` as `steps_panel` says (RestedXP anchors it once, `GuideWindow.lua:473-474`). Create the steps panel: `MakePanel(CurrentStepFrame)` on all points, which hides with `CurrentStepFrame`. Then `self:SecureHook(CurrentStepFrame, 'UpdateText', 'SkinCurrentSteps')` and one pass.
  - Each pass, for every frame in `CurrentStepFrame.framePool`:
    - Skin it once: `NoBackdrop` on it and on its `number`; `HookFont` on its `number.text`; grey colour, re-anchor and right-justify `number.text` as in `current_steps_skinned`; `MakeDivider(frame)`.
    - `HookFont` every `elements[i].text` not yet hooked. Leave `elements[i].icon` and the checkbox art alone.
    - Set its role from its first point's relative frame: `UIParent` (or `frame.step and frame.step.tip`) → tip; `CurrentStepFrame` → first in stack; anything else → later in stack.
    - Show the divider only for "later in stack". Show its tip panel (a lazily made `MakePanel(frame)` on all points, kept in a side table) only for "tip".
  - Then `panel:SetShown(CurrentStepFrame:GetHeight() > 2)`.

- [ ] **Step 4: Run all three test files, verify all pass.**
Run: `$PY $HARNESS/run.py $HARNESS/test_task1.lua $HARNESS/test_task2.lua $HARNESS/test_task3.lua` — Expected: `ALL PASS` ×3.

- [ ] **Step 5: Commit.**
```bash
git add SaftUI-Misc/Skinning/restedxp.lua
git commit -m "misc: RestedXP current steps and tip window in SaftUI's look"
```

---

## In-game checks for the user (after Task 3)

1. `/reload` with a guide loaded. The window should be two SaftUI panels, the current steps above and the guide below. Expect thin lines between steps, the guide name in white Colus, the step text in the chat font, grey step numbers, and a thin scroll bar.
2. Raise RestedXP's "Guide font size" (its settings): every text should grow, and the step titles ("Step 2") should still clear the first line.
3. Hover, right-click, and double-click a step in the list. Tick a line's checkbox. Drag the window from its name, resize it from the grip, and scroll by wheel and by dragging the thumb.
4. Switch RestedXP's theme, then advance a few steps and load another guide. The SaftUI look should stay.
5. A step that pops out as a tip window should get its own panel.
