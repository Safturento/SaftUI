# SaftUI codebase analysis: dead code and organization

Date: 2026-11-12. Tree: `modular` at cb95022. This is a report only. Nothing in the repo was changed to produce it, and nothing here proposes a change inside a `Libraries/` folder.

## Summary

- **Dead code is a small share of the code.** About 1,000 to 1,400 of the 47,900 lines of SaftUI's own Lua (2 to 3%) are dead or probably dead. Removing it is cheap and safe, but it won't change how the code feels to work in.
- **The bigger win is organization.** Ten files hold four or more jobs each, and the same few blocks of setup are copied across addons: placing a Blizzard frame on a holder, waiting for a Blizzard addon to load, mover registration, plain-value helpers.
- **`st.retail` is true on both clients.** Every `else` of it and every `not st.retail` guard is dead (about 130 lines in 30 places), and the name misleads a reader. Only `st.forever` tells the clients apart.
- **The audit turned up 13 bugs,** most of them small. They are listed first because they matter more than the cleanup.
- **The test run is slow because of the test stubs, not the addon code.** Running the files in parallel and three small edits to the widget stub should take it from about 130 seconds to under 30.

## How this was done, and how sure it is

Seven read-only passes, one per area: Core, Core's Config, Unitframes, Bags, Loot with ActionBars and Chat, Misc with Minimap, and `tests/`. Each pass searched the whole repo for callers before calling something dead. I then re-checked the main claims of each pass by hand: every bug below, every "no callers" claim over 20 lines, and a sample of the rest.

Each item carries one of three labels:

- **Certain:** no caller or reader anywhere in the repo, and I re-checked it.
- **Likely:** the pass found no caller, and I did not re-check each one. Check before deleting.
- **Decide:** the code is unused or finished, but removing it is a product decision or needs an in-game check.

Limits:

- A search can miss a name that is built at run time (`self[name]`, `_G[prefix .. n]`). The passes looked for these, but that is where a wrong "dead" call would come from.
- Line numbers are as of cb95022.
- Line counts for savings are estimates.

## 1. Bugs found on the way

| # | Where | What happens | Label |
| --- | --- | --- | --- |
| 1 | `SaftUI-Chat/chatframe.lua:400-413` | `CHT:FCFDock_UpdateTabs` sets `prev` only for the first tab, so the third and later docked chat tabs are all anchored to tab 1 and sit on top of tab 2. | Certain |
| 2 | `SaftUI-Bags/containers/bag.lua:28-33` | `INV:HideBags` loops over `containers.bag.slots`, which is always empty, so closing the bags never clears the new-item glow. | Certain |
| 3 | `SaftUI-Bags/currencies.lua:198` | `INV:CurrencyOnClick(slot)` reads `self.currencyIndex` where it means `slot.currencyIndex`, so shift-clicking a currency links nothing. | Certain |
| 4 | `SaftUI-Bags/container.lua:300` | `if not container and container:IsShown()` errors when `container` is nil and never returns early for a hidden one. It means `not (container and container:IsShown())`. | Certain |
| 5 | `SaftUI-Bags/category.lua:101` | The sort key reads `item.itemCount` and `item.itemId`. The game's fields are `stackCount` and `itemID`, so count and ID never take part in the sort. | Certain |
| 6 | `SaftUI-Bags/inventory.lua:74-91` | `INV:SelectBankCategory` sets the Character bank type for the `warband` container and Account for `bank`. They look swapped. | Decide (in-game check) |
| 7 | `SaftUI-Bags/categoriestab.lua:253-257` | The `combinedbank` window is offered only when `HasWarbandBank()` is true. | Likely |
| 8 | `SaftUI-Bags/slot.lua:396-399` | A value is read before the assert that guards it. | Likely |
| 9 | `SaftUI-Unitframes/updaters.lua:229` | `UF:UpdateElementPosition(element, unitframe, configOverride)` is called as `(element, configOverride)` at lines 110 and 123, so a config override never reaches the position. | Likely |
| 10 | `SaftUI-Unitframes/config/units/pet.lua:6,14` | The table has two `power` keys. The second silently replaces the first. | Certain |
| 11 | `SaftUI-Core/taintfix.lua:4` | `TaintFix:OnInitalize` is misspelled, so it never runs. Fixing the spelling alone would error at login, because `ClickBindingFrame` belongs to a load-on-demand Blizzard addon. | Certain |
| 12 | `SaftUI-Misc/movable.lua:5-14` | `TransmogFrame` is load-on-demand, so the module prints "Frame not found: TransmogFrame" at every login and the frame never becomes movable. | Likely (in-game check) |
| 13 | `SaftUI-Misc/Skinning/Blizzard_SwingTimer.lua:134-139` | On retail the file registers `ADDON_LOADED` and never unregisters it. | Likely |

### Accidental globals

Each of these writes a global that any other addon, or Blizzard's code, can read or overwrite.

| Where | Global | Note |
| --- | --- | --- |
| `SaftUI-Unitframes/elements/health.lua:74` | `r`, `g`, `b` | Written on every health color update. |
| `SaftUI-Core/EditMode/grid.lua:65` | `Draw` | `function Draw()` should be `local function`. |
| `SaftUI-Core/api.lua:219` | `debug` | Overwrites Lua's `debug` library when `st.DEBUG` is on. |
| `SaftUI-Core/utilities.lua:177-206` | `ScanningTooltip` | A frame made at file scope for `st:ScanEquippedItem`, which has no caller. |
| `SaftUI-Core/Widgets/scrolllist.lua` | `SaftUIScrollListItemMixin` | Goes with the unused scroll list (section 3.1). |
| `SaftUI-Minimap/micromenu.lua:321-324` | `MiniMapMailFrame_UpdatePosition` | In a branch that never runs (section 2.1). |
| `SaftUI-Loot/popup.lua` | `LootFrameTitle`, `LOOTFRAME_NUMBUTTONS` | In a file that never runs (section 3.4). |

### Writes onto Blizzard frames (taint rule 1)

`.agents/taint.md` rule 1 says SaftUI writes no fields on Blizzard frames. These still do. I did not trace whether each one can cause a blocked action in combat.

- `SaftUI-Misc/Skinning/Blizzard_WeeklyRewards.lua:8` replaces `WeeklyRewardsFrame.ShouldShowOverlay`, and does so again on every `ADDON_LOADED`. No followup exists.
- `st:EnableResizing` (`SaftUI-Core/skinning.lua:441-460`) writes `frame.ResizeButton`. It is called on `WorldMapFrame`. No followup exists.
- `st:Kill` (`SaftUI-Core/api.lua:224-241`, 43 callers) writes `_Show`, `Show`, `_SetAtlas` and `SetAtlas` onto the frame it is given. A followup exists ("st:Kill and st:SkinIcon still write onto Blizzard pieces", 2026-11-09), but it covers the roll bars. The other callers aren't traced.
- The totem bar's setup runs on classes that have no totems (`SaftUI-Misc/totembar.lua`). Likely harmless, and worth a class check.

## 2. Themes that cross addons

### 2.1 `st.retail` is always true

`SaftUI-Core/constants.lua` defines:

```lua
st.forever = st.GAME_VERSION == 16001
st.retail  = st.GAME_VERSION >= 110000 or st.forever
```

Both supported clients satisfy it. So `if st.retail then A else B end` always runs A, and `if not st.retail then ... end` never runs. The flag is left over from Classic support.

| Addon | Sites | Dead lines |
| --- | --- | --- |
| Minimap | `minimap.lua:11-16,26,29-31,34-46`, `killblizz.lua:23,131-135`, `micromenu.lua:318,321-324,333-334,375-390`, `queuebutton.lua:30,33,54,172-175,190`, `instancedifficulty.lua:6`, `zonetextbutton.lua:5` | about 55 |
| Bags | `inventory.lua:39-44`, `containers/bag.lua:219-222`, `slot.lua:405`, `currencies.lua:45` | about 30 |
| Misc | `Skinning/Blizzard_WatchFrame.lua` (the whole 29-line file returns at once), `experience.lua:210,446`, `Skinning/Blizzard_BuffFrame.lua:380` | about 30 |
| Unitframes | `elements/health.lua:43`, `power.lua:61`, `additionalpower.lua:34,196`, `tags.lua:41` | about 15 |
| Core, Loot, Chat | `Media/fonts.lua:8`, `Utilities/itemupgrades.lua:38,46,55`, `Feed/feed.lua:46,48`, `chatframe.lua:78` | a few |

Suggestion: delete the flag and its dead branches in one pass, and keep `st.forever` as the only client switch. Label: Certain for the logic. Each site still needs a read, because a few `if st.retail then` bodies only lose their wrapper.

### 2.2 The same setup, written out many times

| What is repeated | Where | Suggested home | Saves |
| --- | --- | --- | --- |
| Holding a Blizzard Edit Mode frame on a SaftUI holder. The snippet that hides the frame's `Selection` is copied 9 times across 6 sites. | Misc, Minimap | Core: `st:HideEditModeSelection`, `st:PlaceHolder`, `st:HoldFrame` | about 150 lines |
| Waiting for a Blizzard addon with an `ADDON_LOADED` handler | 10 handlers, mostly `SaftUI-Misc/Skinning` | Core: `st:OnBlizzardAddon(name, fn)` | about 90 lines |
| Mover closures written by hand: 14 `getPosition =` blocks and about 20 `UnpackPoint` sites | Misc, Chat, ActionBars, Loot, Bags | Core: `st:PlaceAtPosition`, `st:RegisterConfigMover` | about 100 lines |
| The action button state-texture recipe | `SaftUI-ActionBars/skin.lua:316-340`, `SaftUI-Misc/totemskin.lua:288-312` | One helper in Core's `skinning.lua` | about 25 lines |
| Plain-value helpers that guard secret values | Five copies in Loot, one in `SaftUI-Unitframes/tags.lua:11` | Core: `st.PlainNumber`, `st.PlainString` | about 40 lines |
| `issecretvalue` shims | Four in Misc, beside Core's | Core's shim only | about 15 lines |
| `Clamp` | `ActionBars/bars.lua:148`, `ActionBars/extras.lua:209`, `Misc/Skinning/Blizzard_BuffFramePosition.lua` | Core | small |
| Joining tooltip lines into text | `SaftUI-Core/Utilities/tooltipscanner.lua:19-28`, `SaftUI-Bags/tooltipscanner.lua:44-52` | Core's scanner | about 10 lines |
| `CopyTree` and `SameTree` beside `R.Copy` and `R.Equal` | Bags | One pair | about 30 lines |
| Constants: `LARGE_COUNTDOWN_SIZE = 36` (3 places), `BLIZZARD_SIZE = 52` (2), `FIELD_HEIGHT = 24` (2) | ActionBars, Misc, Core Config | One definition each | small |

### 2.3 Profile migrations that may be finished

These run at every login to convert an old profile shape. If every profile the user cares about has loaded once since, they can go. This is a decision, because a profile that hasn't been opened since would lose its conversion.

- Bags: `categories.lua:672-718`, `movers.lua:39-91`.
- Chat: `CHT:MigratePosition` (`chatframe.lua:221`).
- Core: `st:ResolveLegacyTemplate` (`theme.lua:132`) has no caller in addon code any more. Only tests call it (section 6).

## 3. Dead code by addon

### 3.1 Core

| Item | Where | Lines | Label |
| --- | --- | --- | --- |
| Eleven `st:Snap*` helpers, and `st:Hide`, which reads an undefined global `HiddenFrame` | `api.lua:130-204`, `:243-248` | 85 | Certain. Keep `st:CalculateSpacing`. |
| Unused utilities: `string.findnocase`, `st:createBarrier` and `isBlocking`, `st.tableinvert`, `st.imap`, `st.tablepurge`, `string.escape`, `st:ScanEquippedItem`, `Util:ScanBagItem`, `Util:ScanEquipmentSlotItem`, the `st.util` alias | `utilities.lua`, `Utilities/tooltipscanner.lua:31-37`, `Utilities/itemupgrades.lua:78-84`, `Utilities/utilities.lua:4` | 90 | Likely |
| `taintfix.lua` never runs (bug 11) | Both TOCs, `.agents/taint.md`, `.agents/architecture.md:36` | the file | Decide: delete it, or rewrite it on `ADDON_LOADED` after an in-game check of the Click Casting window |
| The scroll list widget, its XML template and mixin; `st:CreateScrollBar`; broken `SetFont` and `SetText` aliases on `st:CreateButton` and `st:CreateStatusBar`; `editbox.Label` and `SetLabel` | `Widgets/scrolllist.lua`, `templates.xml`, `scrollbar.lua:89-96`, `button.lua:8-9`, `statusbar.lua:9-10`, `editbox.lua:11-14` | 130 | Likely |
| `OnSetCooldown` and `OnUpdateCooldown`; an unused FontString in `st:SkinCooldown`; `EnableHorizontalResizing`, which calls `SetScript()` with no arguments; a debug `print` at `:109` | `skinning.lua:113-126`, `:436-439` | 30 | Likely |
| `st:CreatePanel` (tests only), `CreateArrowButton`, `CreateArrowCluster` | `panels.lua:435-482`, `:501-514` | 50 | Likely |
| Unread constants: `st.mult`, `st.my_race`, `st.my_faction`, `st.ICON_COORDS`, `st.INVERSE_ANCHORS`, `st.TAB_HEIGHT`, `st.textures.mail`, `st.textures.glow` | `constants.lua` and others | 10 | Likely |
| `EM:IsActive` | `EditMode/` | small | Likely |
| Time played: `total_time` is computed and dropped, and `RequestTimePlayed()` may print to chat at login | `init.lua:23-41` | 10 | Decide. **Keep the `summary.class` write in the same handler: Bags reads it (`container.lua:239-253`).** |
| Debug `print` | `theme.lua:513` | 1 | Certain |
| Typo "Monochrome Thick Outine" and a dead `'NONE'` branch | `Media/fonts.lua:8-13` | small | Certain |
| `Righteous` registered twice | `sharedmedia.lua:21-22` | 1 | Certain |

### 3.2 Core's Config (the `/sui` window)

| Item | Where | Lines | Label |
| --- | --- | --- | --- |
| `st.Config.options` is assigned and never read | `Config/widgets.lua:3-9` | 7 | Certain |
| Unused local `tconcat`; unused exports `OB.COLUMN_GAP`, `QUARTER_GAP`, `SMALL_INPUT_WIDTH` | `optionswidgets.lua:58`, `optionsbody.lua:82-83` | 4 | Certain |
| The keybinding widget has no user: no option in the repo has `type = 'keybinding'` | `optionswidgets.lua:2393-2570`, with `ThemeArt.Control('binding')` and about four test blocks | 180 | Decide. It works and is tested. Keep it if a keybinding option is planned. |
| Parts of the AceConfig contract that are honoured but unused: `plugins`, `guiInline`, `guiHidden`, `softMin`, `softMax`, `bigStep` | `optionsmodel.lua`, `optionswidgets.lua` | 30 | Leave. Low value, and other option tables may use them later. |

`SAFTUI` at `config.lua:94` is the `/sui` slash handler. It looks unused in a search, and is not.

### 3.3 Unitframes

| Item | Where | Label |
| --- | --- | --- |
| `elements/powerprediction.lua` is an empty file in no TOC | the file | Certain |
| `UF.RMH`, `self.unitLabel`; `UF.allUnits` is read by tests only | `unitframes.lua:696`, `:116`, `:166`, `:680` | Certain |
| `GetDisplayPower`, an unused local, and a local `Update` that nothing calls | `elements/power.lua:4-17`, `:27`, `additionalpower.lua:4-23` | Certain |
| `DEBUG` hooks | `elements/indicators.lua:5` | Certain |
| Two identical functions | `elements/castbar.lua:54-60` | Certain |
| Extra arguments passed to `GetConfigTable` | `config/config.lua:937` | Certain |
| Small leftovers | `elements/name.lua:39,41`, `updaters.lua:86,88` | Likely |
| Aura `filter`, whitelist, blacklist and `spellIds` default tables that the filters in `purge.lua` replaced | unit default files, about 130 lines | Likely. Check that no profile reads them. |
| `arena` has a config and is never spawned | `unitframes.lua:27` | Decide: spawn it or drop the config |
| Portrait and AuraWatch are parked | `elements/portrait.lua:9`, `aurawatch.lua:35` | Keep. A followup covers them (2026-11-09). |

### 3.4 Bags

| Item | Where | Lines | Label |
| --- | --- | --- | --- |
| The old Edit view can't be reached | `container.lua:391-403`, `:927-945` (`CreateEditToggle`), `category.lua:416-426`, `categories.lua:772-777` | 70 | Decide. First settle what happens to profiles that hid categories through it. |
| `INV:GetAutoVendorProfit` has no caller | `autovendor.lua:75-92` | 18 | Certain |
| Fields written and never read: `INV.OnUseItems`, `slot.type`, `container.slots`, `unitPrice`, `bindType` | several, with `container.lua:622-636` | 20 | Likely. `container.slots` is the table bug 2 loops over. |
| A branch that can't be reached | `rules.lua:359-363` | 5 | Likely |

### 3.5 Loot, ActionBars, Chat

| Item | Where | Lines | Label |
| --- | --- | --- | --- |
| The loot popup is wired on neither client: the call to `LT:InitializeLootFrame` is commented out | `SaftUI-Loot/popup.lua`, `init.lua:17`, `config.lua:4-12` (`loot.popup` defaults), TOC line 10 | 120 | Decide: restore or remove. Removing it also settles the followup "The disabled loot popup writes nametext onto Blizzard's LootButton". |
| `CHT:ChatFrame_OnUpdate` and the `chat.linespacing` setting | `SaftUI-Chat/chatframe.lua:41-65` | 25 | Likely |
| The honor feed can't be reached: its patterns are commented out | `Feed/feed.lua:181-184`, with `:51`, `:132`, `:552`, `:856` | 35 | Decide: restore or remove |
| Small: `'MainMenuBar'` in a list, `AB.blizzardBars`, `LT.DEBUG`, two `categories` tables, unused locals in `roll.lua`, commented code | `hideblizzard.lua:122,144`, `skin.lua:309`, `Loot/init.lua:4`, `feed.lua:117-135`, `roll.lua:91,102,119`, `Feed/filter.lua:56-59` | 25 | Likely |

### 3.6 Misc and Minimap

| Item | Where | Lines | Label |
| --- | --- | --- | --- |
| `SkinBlizzardPanel`, `SkinTab`, `UpdateTab`, `SkinTabHeader`: one test calls them, no addon code does | `SaftUI-Misc/Skinning/skinning.lua:73-200`, `tests/misc/theme_test.lua:681` | 128 | Certain |
| `Blizzard_WatchFrame.lua` never runs (section 2.1) | the file and its TOC line | 29 | Certain |
| A dead branch, and globals that exist on neither client | `tooltip.lua:111-113`, `:183,186,187` | 10 | Likely |
| Leftovers in the experience bar | `experience.lua:202-204`, `:256-263`, `:452` | 15 | Likely |

## 4. Organization

Ordered by payoff. Each of these moves code and should change no behaviour.

### 4.1 Split `SaftUI-Core/Config/optionswidgets.lua` (3,188 lines, 14 jobs)

This is the largest file by a factor of two, and every options change lands in it.

| New file | Holds | About |
| --- | --- | --- |
| `optionswidgets.lua` | The registry, the pool, `W.Create` | 250 |
| `optionslook.lua` | Shared drawing for the controls | 570 |
| `optionstypes.lua` | toggle, input, color, execute, description | 560 |
| `optionsposition.lua` | The Position block | 410 |
| `optionsselect.lua` | select, multiselect | 315 |
| `optionslist.lua` | The check list | 295 |
| `optionsrange.lua` | range | 260 |
| `optionsbar.lua` | The button bar | 255 |
| `optionsdialog.lua` | The confirm dialog | 205 |
| `optionskeybinding.lua` | keybinding (if kept, section 3.2) | 180 |

The files would share one `W.Kit` table of about 35 names. Things to watch:

- The `BUILT_IN` snapshot at `:3096` must be taken after every type file has loaded.
- `define` at `:1461` and a literal `34` at `:1477` are used across what would become file boundaries.
- 14 test files load `optionswidgets.lua` by path. Add one `load_options_widgets()` to `tests/lib/shell.lua` first, so the split touches one place.
- A `Config/load.xml` would keep both TOCs short.
- `.agents/edit-mode.md` lists these files by name in `covers:`.

### 4.2 Split `SaftUI-Core/Config/optionswindow.lua` (1,793 lines)

Into `optionslayout.lua` (about 220 lines of pure layout math, the easiest to test alone), `optionsresize.lua` (165), `optionsnav.lua` (300), `optionssmalldialog.lua` (145), and a core of about 900. Its 21 file-level locals would become one `OW.S` state table.

### 4.3 Shared Core helpers for holders, addon waits and movers

Section 2.2's first three rows. Together they remove about 340 lines from Misc, Minimap, Chat, ActionBars, Loot and Bags. More important, the taint-sensitive steps (hiding `Selection`, placing a protected frame after combat) would live in one reviewed place, not nine.

### 4.4 Unitframes

- **Split `config/config.lua` (962 lines):** profiles (about 215), the plate pages into `nameplates/options.lua` (about 240), group options.
- **Split `groups.lua` (951):** `grouplayout.lua`, `blizzardraid.lua`, `grouppreview.lua` (about 400).
- **Add `config/builders.lua`** for option boilerplate that every element repeats (150 to 200 lines saved). `generators.uf_element_position` at `SaftUI-Core/Config/widgets.lua:130` belongs here too: it is Unitframes code living in Core.
- **Move plate logic out of `unitframes.lua`:** it has seven `isNamePlate` branches.
- **Share per-unit default bases** between the unit files.
- **Rename `purge.lua` to `aurafilters.lua`.** It holds every aura group's filter, not only purge.
- **Merge the two `PostUpdateColor` bodies.**

### 4.5 Bags

- **Split `container.lua` (1,033 lines)** into header, layout and search.
- **Share the open and close code, the gold frame and the deposit buttons** across `containers/*.lua`.
- **Use Core's widgets from `ruleeditor.lua` (1,210) and `categoriestab.lua` (1,155),** which carry their own copies of widget code. Move `INV.DragParts` to `dragparts.lua`.
- **Rename `category.lua`** (it sits next to `categories.lua` and does a different job), and fold `utilities.lua` into its callers.

### 4.6 Loot, ActionBars, Chat

- `Loot/roll.lua` (997) into `rollbar.lua` and `rolltest.lua`.
- `Loot/Feed/rolls.lua` (729): move about 380 lines to a `loothistory.lua` loaded before it.
- `Loot/Feed/feed.lua` (863): move the message parsing to `Feed/parse.lua`.
- `ActionBars/bindings.lua` (472): move hover binding to `keybindmode.lua`.
- The pet and stance bars each have their own `RefreshAll`. Share it.
- Chat: `SkinChatFrame` and `ApplyChatFrameConfig` repeat the same setup.

### 4.7 Misc and Minimap

- **Reorganize `Misc/Skinning/`** into `blizzard/` and `addons/`.
- **`totembar.lua` (817) does four jobs.** `TB.PostHook` is defined in `totemskin.lua`, which loads later.
- **`micromenu.lua` (487) does four jobs.** Its options are in `config.lua:239-324`.
- **`st.defaults.experience` is split** between Core and Misc.
- **`tooltip.lua:175` hooks `GameTooltip:GetUnit`.** Worth a look against the taint rules.

### 4.8 Core, outside Config

- **Split `themeart.lua` (1,270):** about 520 lines are data (`KINDS`, `ART`), and could be `themeart_data.lua`. The nine-slice layout is duplicated in `EditMode/mover.lua:19-30` and `:49-60`.
- **One Core TOC.** The two TOCs differ only in their `## Interface` line. `## Interface: 120000, 16001` in one file would do, if both clients accept the list. Needs a load check on both.
- **Names that collide:**
  - Two files named `theme.lua`: Core's root file is the engine, `Media/theme.lua` is an options tab. `Media/fonts.lua` and `Media/colors.lua` are options tabs too.
  - Two "utilities": the root `utilities.lua` and the `Utilities/` module. Rename the module after what it does, for example `ItemQuality`.
  - Two `skinning.lua`: Core's and `Misc/Skinning/skinning.lua`.
  - `Config/widgets.lua` holds `st.Config.generators`, not widgets. Rename it `generators.lua`.
- **Two live widget sets:** Core's `Widgets/*` and the options window's own. Checkbutton, editbox, radiogroup and statusbar are used by Bags only, and dropdown by the loot feed filter only. Write down why both exist, or move Bags to the options window's set.
- **Small:** `st:SetHeight` and `st:SetWidth` are pass-throughs (9 callers). `st:barrier(self, ...)` shadows `self`.
- **Duplicates inside Config:** color getters in 3 files, the Esc key catcher 5 times, the `ColorPickerFrame:IsShown()` check 6 times.

## 5. Libraries and media (observations only)

Nothing here proposes editing a library. The only change available is which TOC lines load them.

**Loaded and called by nothing in SaftUI:** AceConfigDialog, AceConfigCmd, AceGUI-3.0, AceGUI-3.0-SharedMediaWidgets, AceTimer, AceBucket, AceConsole, AceComm, AceTab, AceLocale.

**Used:** LibStub, CallbackHandler, LibSharedMedia, LibStringFormat, LibCompress, LibBase64, AceAddon, AceEvent, AceHook, AceDB, AceDBOptions, AceSerializer, AceConfigRegistry.

- `.agents/edit-mode.md` says AceGUI, AceConfigDialog and the SharedMedia widgets are loaded on purpose, "as libraries for other addons". The other seven have no written reason.
- AceConfigRegistry is used only to announce changes. `Config:Refresh` does nothing until `/sui` has been opened once.
- Dropping the seven would be TOC lines only, and needs a load check on both clients, since other addons the user runs may count on SaftUI having loaded them.

**Core TOC `OptionalDeps`:** `RealMobHealth, ItemRack, WoWUnit, WeakAuras`. Nothing reads ItemRack (a followup exists) or WoWUnit. The other two belong on the Unitframes and Misc TOCs, where the code that reads them lives.

**Media nothing references (about 1 MB):**

- Textures: `circle.tga`, `goldstring.tga`, `search.tga`, `thickborder.tga`, and `mail.tga` (reached only through the unread `st.textures.mail`).
- Fonts: `Dosis-Regular`, `Dosis-SemiBold`, `Oswald-Light`, `Oswald-Regular`, `visitor2`, `FiraCode-Light`, `FiraCode-Retina`, `FiraCode-SemiBold`.

A font may be named in a saved profile, so check the user's profiles before deleting one.

## 6. The test tree

101 test files, about 52,000 lines, more than the addon code.

### 6.1 Why `tests/run` takes over two minutes

Measured by running each file alone and sampling where the time goes.

- **The runner runs files one after another.** The slowest single file takes 12 seconds, so running files across the machine's cores would bring about 130 seconds to 25 to 30. About 40 lines in `tests/runner.py`, and no test changes.
- **In the slowest Bags files, about 88% of the time is the widget stub's own bookkeeping,** not addon code (`tests/wow/widgets.lua`):
  - `Show`, `Hide` and `SetShown` walk the whole subtree twice even when nothing changes. Return early when the value is already set.
  - `SetPoint` searches the anchor graph for loops on every call. Skip it when the anchor is the parent.
  - Sizes and scales are worked out again on every read. A cache would fix that, and is the riskiest of the three.
- **`apply_defaults()` runs twice per nameplate world** (`tests/unitframes/nameplate_world.lua:65` after `tests/lib/theme_helpers.lua:39`). It is 55% of `nameplate_theme_test`'s time.

The shares are measured. The gains are estimates: none of the edits was tried.

### 6.2 Setup that is copied, not shared

| Block | Copies | Suggested home |
| --- | --- | --- |
| "Fresh world on a client", in three versions that differ. Two of them skip `stub.apply_client()`, so a retail world keeps a Forever-only global. | `T.client`, `W.fresh`, `bags/theme_test.lua:48` | One `use_client(name)` in the shell |
| Loading the four options window files | 11 files | `load_options_window()` in `core/config_helpers.lua` |
| The unit frames world: unit list, oUF colors stub, defaults, elements loop | about 8 files | `tests/unitframes/uf_world.lua`, with `nameplate_world.lua` built on it (about 400 lines saved) |
| The edit mode file loop | 7 files | `load_editmode()` in the shell |
| Small helpers: `click` (7), `tick` (4), `near` (4), `rgb` (3), `enemy` and `friend` (10 and 6), a local theme switcher (9) | many | `tests/lib/` and `nameplate_world.lua` |

`tests/misc/fixtures/locked_widget.lua` is loaded by 15 files in five addons, and belongs in `tests/lib/`. `tests/core/options_walk.lua` defines globals that `tests/lib/theme_helpers.lua` depends on, a hidden load-order link from `lib` to `core`.

### 6.3 Checks for a migration that is over

- Seven "defaults look as they did" cases compare today's defaults with the template names of an old commit. They are the only callers of `st:ResolveLegacyTemplate`. About 90 test lines and 10 addon lines. Label: Decide.
- "Each page offers Theme and Background, not Template" is written by hand in six addons (28 to 109 lines each). One `T.check_theme_page(spec)` helper would save 150 to 250 lines.
- The Thick, Blizzard, Thick round trip is written out in full in many theme tests. A `T.round_trip` helper would save 300 to 500 lines, and fits about half of them.

### 6.4 Large test files

`core/options_widgets_test.lua` (3,333 lines), `core/options_window_test.lua` (2,259) and `bags/categories_tab_test.lua` (1,950, the slowest at 12 seconds) already have section banners that mark where to split. The three `restedxp_task1/2/3_test.lua` files are named after plan tasks, not after what they test.

### 6.5 Where the stubs differ from the game

- Alpha isn't clamped to 0 to 1, as the game does.
- `stub.apply_client()` removes one global. The stubs otherwise answer with retail's API on both clients, so a call to something Forever lacks passes the tests. Growing that list from the two Blizzard source trees is likely the highest-value stub change.
- Getters never return secret values, so a missing guard on an aura button (taint rule 11) passes everywhere.
- `IsForbidden` is always false.

### 6.6 Getters that exist only for tests

Eleven getters in the options window code are called only by tests, about 230 call sites: `OW:GetState`, `OW.GetFrames`, `OW.GetDrawnRows`, `OW.GetDialogFrames`, `OW.GetRenderCount`, `OW.GetRoot`, `W.GetListFrames`, `W.GetDialogFrames`, `W.PromptBox`, `W.Pooled`, `OM.Info`. Others: `UF:SetProfile`, `UF.allUnits`, `INV.ItemClasses.Reset`, `INV.CategoryDefaults.Reset`, `st:CloseButtonInSocket`, `MicroMenu:GetItemArt`, `MicroMenu:GetStrip`.

- They are fine to keep. Grouping them under `OW.Seam` and `W.Seam` would make it plain what is test-only.
- `GetDialogFrames` is defined on both `OW` and `W` with different meanings.
- `OW.GetRenderCount` has 57 assertions that count renders, so any change to how renders are batched breaks tests that have nothing to do with it.

### 6.7 What is in good shape

No skipped or commented-out tests, no duplicate case names, no file the runner misses, no test for removed code, and no case that can't fail. The fresh Lua state per file and the world reset per case are cheap (6 ms) and are the suite's main strength.

## 7. Looked at and left alone

- `EM:OnInitialize`, `EM:On` and `EM:Fire`, `TaintLess.xml`, Core's `issecretvalue` shim, `st:SetTexture`, the registered fonts.
- `st:ThemeAtlases`, `ThemeArt.Client` and `ThemeArt.Get` are proper seams.
- `tests/lib/harness_self_test.lua`, the runner's broken-on-purpose fixtures, and the large fixtures (each has two or more users).
- `core/theme_migration_test.lua` and `bags/category_migration_test.lua` test migration code that still runs.
- Eight TODO comments, none of them stale enough to list.

## 8. Not covered

- **Performance of the addons in game.** This was a read of the code, with no profiling in the client.
- **The libraries' insides.**
- **Whether each "Likely" item is truly unreachable.** Each needs a last search before deletion.
- **About 80 test bodies** were checked by search and case titles, not read in full.
- **In-game behaviour of the bugs.** All 13 come from reading the code. None was reproduced in the client.

## 9. A suggested order

1. **The bugs in section 1,** starting with the five Certain ones in Chat and Bags (1 to 5). Each is a one-line or few-line fix with a test.
2. **`st.retail`** (section 2.1): one pass, about 130 lines, and it removes the most misleading name in the code.
3. **The Certain dead code** (section 3): about 400 lines, no decisions needed.
4. **The test run's speed** (section 6.1): the parallel runner first. Every later step runs the suite many times, so this pays for itself at once.
5. **The shared Core helpers** (section 4.3), then the two Config splits (4.1, 4.2).
6. **The Decide items,** once you've chosen: the loot popup, the honor feed, the keybinding widget, the old bag Edit view, `taintfix.lua`, the finished migrations, the unused libraries' TOC lines, the unused media.
7. **The per-addon splits** (4.4 to 4.8), each when that addon is next worked on.
