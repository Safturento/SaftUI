---
name: clients
description: WoW Forever vs retail, secret values, Blizzard source and icon lookups, and reading the user's in-game logs
last_updated: 2026-11-08
covers:
  - 'SaftUI-Core/constants.lua'
  - 'SaftUI-Core/utilities.lua'
  - 'SaftUI-*/*_Forever.toc'
  - 'SaftUI-*/*_Mainline.toc'
---

# Clients and references

## Two clients

- **WoW Forever.** Interface 16001, game type "Camelot". A mainline-family client with Classic-flavored overrides under `*/Camelot/` dirs in Blizzard's source. **The user plays Forever.** Test against it first.
- **Retail.** Midnight, interface 120000.
- **Flags** (`SaftUI-Core/constants.lua`): `st.retail` is true on **both** (`GAME_VERSION >= 110000 or st.forever`), and `st.forever` is true only on Forever. "Outside retail" means `st.forever`. Prefer feature checks (does the frame or API exist?) over version checks where you can.
- **Forever specifics found so far:**
  - **Swing timer.** Forever has `Blizzard_SwingTimer` (an Edit Mode system); retail doesn't.
  - **Totem bar.** `MultiCastActionBarFrame` is protected; `TotemFrame` isn't loaded.
  - **Action bars.** The same bars as retail (`MainActionBar`, the four multibars and `MultiBar5`–`7` on pages 13–15), with the same binding commands. LibActionButton-1.0 treats Forever as mainline.
  - **Extra action button.** Forever has none: `ActionButtonUtil.IsExtraActionButtonDisabled` (`Blizzard_ActionBar/Camelot`) returns true, there's no `EXTRAACTIONBUTTON1` binding, and Edit Mode hides its Extra Abilities option. `ExtraActionBarFrame` and `ExtraAbilityContainer` still exist, and `Blizzard_ZoneAbility` loads (`AllowLoadGameType: mainline`, which takes in Camelot), so test those on retail.
  - **Minimap.** The day/night indicator is `MinimapCluster.DielFrame`.
  - **Queue eye.** `QueueStatusButton` is an Edit Mode system.
  - **Loot rolls.**
    - The roll frame's buttons live under `frame.LootButtonContainer`.
    - `C_LootHistory`'s drop index is `lootListKey` on Forever and `lootListID` on retail (`EncounterLootDropInfo`). Read either.
    - `C_LootHistory.GetLootHistoryTime()` and the history's `startTime` and `duration` count milliseconds. Blizzard's Loot Rolls window subtracts one from the other for its timer.
    - Forever's Loot Rolls window (`GroupLootHistoryFrame`) never opens by itself: `ShouldAutoOpen` in `Blizzard_FrameXML/Camelot/LootHistory.lua` returns false.
  - **Auras on other players** (checked on a party member, 2026-11-08):
    - `sourceUnit` is nil on every aura, and the `PLAYER` filter keeps them all: `HELPFUL|PLAYER` returns the same list as `HELPFUL`. `isFromPlayerOrPlayerPet` is right (false on others' auras, true on the player's), so unit frame "Only mine" filters on that flag (`SaftUI-Unitframes/elements/auras.lua`).
    - `SetUnitAuraByAuraInstanceID` gives the wrong aura or none for some of them. By index (`SetUnitAura(unit, index, filter)`) it's right. Blizzard's aura buttons build their tooltips by instance ID, so some unit frame aura tooltips are wrong or missing (`docs/followups.md`).
    - `C_Secrets.ShouldAurasBeSecret()` is false out of combat and true in combat. Out of combat, `C_UnitAuras` data is readable. The aura buttons' state isn't, in or out of combat (`.agents/taint.md` rule 11). `print` shows secret values like any other, so a `/run` that prints them can't tell you whether they're secret: test with `issecretvalue`.
  - **Bank.** It's built from bank tabs holding bags (`Enum.BagIndex.CharacterBankTab_*`). There's no `BankPanel.AutoDepositFrame` and no reagent bank, and the warband bank isn't used.
- Neither client has a reagent bank anymore.

## Secret values

On retail (and some Forever paths), protected data such as some unit, aura, power and size values can be a *secret value*. Arithmetic, comparisons, concatenation and table indexing on a secret value error out. Passing one straight into a widget setter (`SetText`, `SetVertexColor`, `SetValue`, `SetPoint`) is allowed.
- Guard with `issecretvalue(v)`. A shim in `SaftUI-Core/utilities.lua` makes it safe on clients without it.
- When a value is secret, skip the math. Either pass it through unchanged, or fold the operation into something widget-side. For example, a power background multiplier becomes an alpha multiplier.
- Sizes and positions read from Blizzard frames can be secret. Guard them before any math.
- Blizzard's Lua wrappers aren't always pass-through. `SetBackdropBorderColor` runs `a or 1` on the alpha, which errors on a secret, so a secret color goes onto the backdrop's edge pieces (`TopEdge`, `TopLeftCorner` and so on) with `SetVertexColor` directly. The unit frame auras' dispel border does this (`SaftUI-Unitframes/elements/auras.lua`).

## Reference sources

- **Blizzard UI code:** `Gethe/wow-ui-source` on GitHub. Branches are `forever` and `live`.
  - Fetch a file: `gh api "repos/Gethe/wow-ui-source/contents/<path>?ref=forever" -H "Accept: application/vnd.github.raw"`.
  - List paths: `gh api "repos/Gethe/wow-ui-source/git/trees/forever?recursive=1" --jq '.tree[].path'`.
  - API docs are in `Interface/AddOns/Blizzard_APIDocumentationGenerated/`. GlobalStrings are not in this repo.
- **Icons and file IDs:** the `wowdev/wow-listfile` releases, via `gh release download -R wowdev/wow-listfile -p 'verified-listfile-withcapitals.csv'` (~74 MB).
  - Lines look like `236681;Interface/ICONS/Achievement_Reputation_01.blp`. Use the numeric file ID in Lua.
  - Save the download to its own scratch directory. Only grep it; never run anything from it.
- **AceGUI/AceConfig:** use the bundled copies in `SaftUI-Core/Libraries/Ace3`. On Forever, a newer copy from another addon (HandyNotes) may be what's actually loaded.

## The user's install and logs (WSL paths)

Reading these from WSL needs the sandbox disabled.

- **Install:** `/mnt/e/Games/World of Warcraft/` (`E:\Games\World of Warcraft\`), with `_forever_` and `_retail_` flavor folders.
  - Each addon folder in `Interface/AddOns` is a Windows `mklink /D` symlink into this repo. Use `mklink /D` from `cmd.exe`, not WSL `ln -s`.
  - Changes go live in game after `/reload`.
- **Lua errors:** BugSack/BugGrabber saves errors to `_forever_/WTF/Account/<account>/SavedVariables/!BugGrabber.lua` (one folder per account; list the `Account` dir to find it).
  - Fields: `message`, `stack`, `locals`, `time`, `session`.
  - It's written only on `/reload`, logout or a clean exit, so ask the user to `/reload` first.
  - A `session` number spans a whole UI load. Compare the `file:line` in the stack with `git show <commit>:<file>` to know which code version produced it.
- **Client crashes:** `_forever_/Errors/<date>_Crash_<n>.txt` has a "Lua Stack" section.
- **Taint log:** `_forever_/Logs/taint.log`, after the user runs `/console taintLog 1`.
