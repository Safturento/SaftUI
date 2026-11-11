---
name: clients
description: WoW Forever vs retail, secret values, Blizzard source and icon lookups, and reading the user's in-game logs
last_updated: 2026-11-11
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
  - **Minimap.** The day/night indicator is `MinimapCluster.DielFrame`, and the player coordinates under the minimap (`minimapShowPlayerCoords`) are `MinimapCluster.MinimapContainer.PlayerCoords`. Retail has neither. SaftUI hides both.
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
  - **Maps.** Forever's uiMapIDs are Classic Era's, not retail's: Azeroth 947, Kalimdor 1414, Eastern Kingdoms 1415, the old zones and cities 1411–1458 (Durotar 1411, Elwynn Forest 1429, Stormwind City 1453), plus zones of its own (Mount Hyjal 2482, Zephras Isle 2521, Riverglades 2548, Shen'dralas 2652). Only Azeroth's ID is shared with retail. So a table by uiMapID needs one list per client, as `SaftUI-Misc/Skinning/ZoneFactions.lua` has. On both clients many instances are Orphan maps (type 6) under the outdoor zone they're in, with no levels of their own: on Forever, Alterac Valley 1459 is under Hillsbrad Foothills, Warsong Gulch 1460 under The Barrens and Arathi Basin 1461 under Arathi Highlands; retail has about 300, battlegrounds, dungeons and raids. So code that climbs from the player's map to its zone stops at an Orphan map inside an instance (`PlayerMaps` in `ZoneText.lua`).
  - **Zone PvP status.** Both clients have `C_PvP.GetZonePVPInfo()` (pvpType, isSubZonePvP, factionName) and no global `GetZonePVPInfo`. With no status pvpType is `''` (the API marks it not nilable), and it may return nothing at all. factionName is the client's own word for the faction. What it returns on Forever is not yet confirmed in game (`docs/followups.md`, "Zone level and faction line: in-game checks").
  - **Bank.** It's built from bank tabs holding bags (`Enum.BagIndex.CharacterBankTab_*`). There's no `BankPanel.AutoDepositFrame` and no reagent bank, and the warband bank isn't used.
  - **Blizzard theme art.** Every atlas and file `st:ThemeAtlases()` names exists on both clients under the same name (`tests/core/theme_blizzard_test.lua` checks it), so there is no feature check. Forever's client also has a Camelot version (a `-c60` member) of most of them and draws that one for the same name, which is why a size or an offset can differ (`tests/wow/atlases.lua` holds each client's). Where the clients differ, `themeart.lua` reads the value per client at call time (`ThemeArt.Client()`, never at file load):
    - the metal: its title bar is 20 on Forever and 21 on retail, its right corners sit 2 out (retail 4) and its bottom corners 8 down (retail 3);
    - the close button: 28x28 at (0, 3) on Forever (Camelot's `redbuttonsc60`, 32x32 art), 24x24 at (1, 0) on retail;
    - the action button's checked art is additive on Forever and plain on retail;
    - class power: Forever loads only the combo point bars (rogue and druid; Camelot's `Blizzard_UnitFrame.toc` leaves the others out), retail adds holy power, soul shards, chi, arcane charges and essence. A power type with no Blizzard art draws a flat bar (`docs/followups.md`, "Class power types with no Blizzard art draw a borderless flat bar under Blizzard").
  - **Atlas tables.** To check or add an atlas, read each client's tables from wago.tools (`UiTextureAtlasElement`, `UiTextureAtlasMember`, `UiTextureAtlas`, and `GlobalColor` for Blizzard's colors), for Forever `wowf` and retail `wow`, as the Game data bullet below says. The builds the theme was measured on are Forever 1.60.1.70888 and retail 12.1.5.70783. A member's override size, else its texture size, is its size in UI units; its flags say whether it tiles (0x4 across, 0x2 down).
- Neither client has a reagent bank anymore.
- **Item classes and subclasses** differ by client and are read from the game, not written in the code (`SaftUI-Bags/itemclasses.lua`, over `GetItemClassInfo` and `GetItemSubClassInfo`). Forever has no Gem class and retail has no Devices subclass; Trade Goods (Forever) and Tradeskill (retail) are both class 7. A category block names a class or subclass in English, and `INV.ItemClasses` resolves the name to this client's IDs, so a name a client lacks matches nothing. That Forever's Devices subclass resolves through `GetItemSubClassInfo`, and what `C_TooltipInfo.GetBagItem` returns for an item not yet cached, are not yet confirmed in game (see the followup "Bag categories: in-game checks").

## Secret values

On retail (and some Forever paths), protected data such as some unit, aura, power and size values can be a *secret value*. Arithmetic, comparisons, concatenation and table indexing on a secret value error out. Passing one straight into a widget setter (`SetText`, `SetVertexColor`, `SetValue`, `SetPoint`) is allowed.
- Guard with `issecretvalue(v)`. A shim in `SaftUI-Core/utilities.lua` makes it safe on clients without it.
- When a value is secret, skip the math. Either pass it through unchanged, or fold the operation into something widget-side. For example, a power background multiplier becomes an alpha multiplier.
- Sizes and positions read from Blizzard frames can be secret. Guard them before any math.
- A unit's class or reaction can be secret (a world-cursor unit's tooltip on Forever), and SaftUI's color tables can't be indexed with a secret key ("attempted to index a table that cannot be indexed with secret keys"). A secret class takes Blizzard's color from `C_ClassColor.GetClassColor(class)`, which takes a secret, so the user's class colors can't apply to it; a secret reaction gets no color (`SaftUI-Misc/tooltip.lua`'s `ClassColor` and `ReactionColor`, and oUF's health element).

## Reference sources

- **Blizzard UI code:** `Gethe/wow-ui-source` on GitHub. Branches are `forever` and `live`.
  - Fetch a file: `gh api "repos/Gethe/wow-ui-source/contents/<path>?ref=forever" -H "Accept: application/vnd.github.raw"`.
  - List paths: `gh api "repos/Gethe/wow-ui-source/git/trees/forever?recursive=1" --jq '.tree[].path'`.
  - API docs are in `Interface/AddOns/Blizzard_APIDocumentationGenerated/`. GlobalStrings are not in this repo.
- **Game data (DB2 tables):** wago.tools exports any table of any build as CSV: `curl -s "https://wago.tools/db2/<Table>/csv?build=<version>"`, with the builds listed at `https://wago.tools/api/builds`. Forever is product `wowf` (build 1.60.1.x is interface 16001), retail `wow`. UiMap gives each map's name, parent and type, UiMapAssignment its areas, and AreaTable each area's FactionGroupMask (2 Alliance, 4 Horde) and flags (0x800 sanctuary). Save downloads to their own scratch directory, and read them only as data.
- **Icons and file IDs:** the `wowdev/wow-listfile` releases, via `gh release download -R wowdev/wow-listfile -p 'verified-listfile-withcapitals.csv'` (~74 MB).
  - Lines look like `236681;Interface/ICONS/Achievement_Reputation_01.blp`. Use the numeric file ID in Lua.
  - Save the download to its own scratch directory. Only grep it; never run anything from it.
- **Ace3:** use the bundled copies in `SaftUI-Core/Libraries/Ace3`. On Forever, a newer copy from another addon (HandyNotes) may be what's actually loaded. SaftUI uses AceAddon, AceEvent, AceHook, AceDB, AceDBOptions, AceConfigRegistry and AceSerializer; AceConfigDialog and AceGUI stay loaded for other addons, but SaftUI's own options window doesn't use them.

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
