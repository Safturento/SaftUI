# SaftUI talent plan: a leveling order beside the talent window

Date: 2026-11-22. Status: draft for the owner's review (revised 2026-11-22 with the owner's answers on the side, collapsing and a movable window). Lines marked "My call" are the controller's, for the owner to check.

Mockups: the "Talent Leveling Plan" board (https://claude.ai/artifact/KQy7Hvy2WL3PJPJ1WnMWp2), option A.

## Intent

The owner, 2026-11-22:

- "I want to be able to set my talent tree to a planning mode that lets me set which talents I'm going to get in which order as I level - online guides tend to have an ordered list like this and I'd like to see a few designs on how we can represent this list in game."
- With two screenshots: a Classic-style guide list (level, talent icon, talent name, rank, levels 10 to 60 for an Enhancement shaman), and a retail guide whose tree is ringed in colors by phase with numbered notes beside it.
- Of the five mockups: "Actually I really like A, lets go with that". A is the guide's ordered list as a SaftUI panel docked to the talent window, grouped into phases, with the rows already learned checked and dimmed, the waiting pick highlighted, and a hover on a row lighting its node in the tree.
- On how a plan gets in, the owner chose "Paste and click": paste a guide's list as text, or click nodes in order in planning mode, and drag rows in the panel to reorder.

So the job is to follow an online guide's leveling order without alt-tabbing to it: get the guide's list into the game once, then see, each time a point comes in, which talent the plan says to take.

## Goals

1. A **plan panel** docked to the right edge of Blizzard's talent window (the Talents tab of `PlayerSpellsFrame`), in SaftUI's theme, showing the plan as an ordered list of steps: level, talent icon, talent name, rank.
2. Each row shows its state from the character's **real ranks**: learned (checked, dimmed), **waiting** (the first step not learned whose level the character has reached; highlighted in the Accent), and upcoming. The list scrolls to the waiting row when the window opens.
3. A hover on a row lights its node in the tree; the waiting row's node glows in the Accent. Nodes that are not in the plan can be dimmed (a setting, on by default).
4. **Paste:** an Import box takes a guide's list as text and turns it into steps by matching talent names from the character's class tree, in order.
5. **Click:** in planning mode, a click on a node in the tree adds that node's next rank as the next step; a right click removes that node's last planned rank.
6. **Reorder:** rows drag up and down in the panel; a row's level is its position (the first step is level 10, the next 11, and so on).
7. **Phases:** named headers between rows, each with a color from a small fixed palette, added, renamed and removed from the panel. The phase color shows as a dot on the header and on its rows' level numbers.
8. Plans are saved, named, and chosen per spec tab (primary and secondary).

## Non-goals

- Spending points for the player. Nothing in this feature buys a rank (the owner picked A over D, which had a Learn button). The panel only points.
- Badges, rings or phase colors drawn on the tree itself (options B and C). The tree gets only the row-hover light, the waiting glow and the dim.
- A level-up toast or a micro button dot (option D).
- A level slider over the tree (option E).
- Importing another addon's or a website's plan string or a Blizzard loadout string. Text only.
- Checking a whole plan against the tree's point gates and prerequisites before it is played. The waiting row says when its node can't be learned yet (Goal 2, "blocked" below); a full offline check is a later followup.
- Retail-style choice nodes and hero talents. Forever's class trees are ranked nodes; a choice node in a plan is out of scope until a client needs it.
- Inspecting another player: the panel hides while the talent window inspects.

## Anti-goals

- Anything that taints Blizzard's talent window or blocks the player from learning a talent the normal way. A broken talent window is worse than no plan.
- A panel that pushes the talent window around or covers its tree.

## Constraints

- **Forever's talent window** is Blizzard's modern trait frame with Camelot overrides (`Blizzard_PlayerSpells`, load on demand, `[AllowLoadGameType camelot]` files in `Camelot/`; checked 2026-11-22 against the `forever` branch of Gethe/wow-ui-source): `PlayerSpellsFrame.TalentsFrame` (`ClassTalentsFrameTemplate`), one class tree drawn as three groups side by side (`RefreshTreeHeaders`, `C_Traits.GetGroupDisplayInfoByTreeID`), two spec tabs (`C_SpecializationInfo.GetActiveSpecGroup`, `GetCombatConfigIDForSpecGroup`), inspect mode (`IsInspecting`). `TalentFrameBaseMixin` (`Blizzard_SharedTalentUI/Blizzard_SharedTalentFrame.lua`) has `GetTalentButtonByNodeID`, `EnumerateAllTalentButtons` and `GetConfigID`.
- **Data** comes from the trait API, not from the frame: the config (`C_ClassTalents.GetActiveConfigID`), its tree (`C_Traits.GetConfigInfo(...).treeIDs`), the tree's nodes (`C_Traits.GetTreeNodes`), each node's ranks and entries (`C_Traits.GetNodeInfo`: `ranksPurchased`, `maxRanks`, `entryIDs`, and whether a rank can be bought now), its entry's definition and spell (`C_Traits.GetEntryInfo`, `C_Traits.GetDefinitionInfo`), and the spell's name and icon (`C_Spell`). The panel works from that, so the plan's model is testable without the frame.
- **Taint** (`.agents/taint.md`): everything drawn is SaftUI's own frames. The panel, the row-hover light, the waiting glow, the dim and the planning-mode click catchers are SaftUI frames anchored to Blizzard's (a `SetPoint` on our frame relative to theirs), never a field, script, alpha or texture set on Blizzard's buttons (rule 1). The panel follows the window with post-hooks only (rule 2): `HookScript('OnShow'/'OnHide')` on `PlayerSpellsFrame` and its `TalentsFrame`, and a post-hook for the tree redrawing its buttons (the builder finds the right one, e.g. after a config or spec tab change). The frame loads on demand, so the hooks go on through `st:OnBlizzardAddon('Blizzard_PlayerSpells', fn)`.
- **Planning-mode clicks** must never reach Blizzard's button, or a click meant to plan would buy a rank. So in planning mode each node gets a SaftUI click catcher over it that takes the mouse; outside planning mode the catchers are hidden and don't take the mouse.
- **Combat:** ranks can't change in combat, but the plan is SaftUI's own data, so editing works in combat. Nothing here is secure.
- One talent point a level from 10 to 60 on Forever. **My call:** the first step's level is a constant, 10, in one place, for the builder to confirm in game.

## Approaches (for the display, chosen in the mockups)

- **A. Ordered list docked to the window (chosen).** Reads like the guides; a natural home for import, reorder and phases. Costs width beside the window, and the order and the node are in two places (the row hover bridges them).
- **B. Level badges on the nodes.** The order sits on the tree. Costs busy labels on split talents, and reading the order front to back means scanning.
- **C. Phase rings.** Shows a build's shape at a glance but not the order inside a phase.
- **D. Next-pick coach** (toast and Learn button) and **E. level slider**. Helpers more than a way to show the order.

The owner picked A ("I really like A").

## Approaches (for getting a plan in, chosen on a card)

- **Paste and click (chosen).** Paste matches a guide's list; click covers building a plan by hand and small edits; drag covers order.
- **Paste only.** No planning mode in the tree.
- **Click only.** The smallest build; 51 clicks per plan and no import.

## Design

### The panel

- A SaftUI panel (Theme and Background like SaftUI's other windows) as tall as the talent window, on its right edge, about 250 wide (**My call**). Title "Leveling plan", the plan's name as a select (the plans for this class, plus New plan), and the count of steps learned out of the plan's steps ("18/51").
- Below the title, the rows, scrolling. A row: level (tabular), the talent's icon, the name in the talent color, and "R2" when the node has more than one rank. A phase header: color dot, name, its level range.
- Footer buttons: **Plan** (planning mode on and off), **Import**, **Phases** (add a phase at the selected row), and a dots menu with Rename, Duplicate, Delete plan, and Clear steps.
- **Collapsible** (the owner, 2026-11-22: "lets make that list collapsible"). A collapse arrow on the panel's title folds it to a narrow strip on the same side, as tall as the title bar, that shows only the waiting step ("27 Improved Ghost Wolf R2") and an expand arrow (**My call** on the strip's content). The state is saved per character (**My call**).
- The panel shows only while the Talents tab shows and the window isn't inspecting.
- **Side** (the owner, 2026-11-22: "put it to the right or left depending on the position of the talent frame"). The panel docks to whichever side of the talent window has more room on screen, decided each time the window shows and each time it is dropped after a drag. When neither side has room for the whole panel, it takes the side with more room and the screen clamp pushes it over the window's edge.

### Row states

Computed from the live ranks, not from the character's level alone, so a player who strayed from the plan still sees the truth:

- **Learned:** the character has at least that many ranks of the node (the step "Flurry R2" is learned when Flurry has 2 or more ranks). A check, the name dimmed.
- **Waiting:** the first step not learned whose level is at or below the character's level. Accent fill on the row; the node glows. If the game says that node's rank can't be bought yet (the tree's gate or a prerequisite), the row says "blocked" with the reason in its tooltip (**My call**).
- **Upcoming:** the rest.
- **Staged ranks** (clicked in the window but not yet applied with Blizzard's Apply button): **My call:** they don't count as learned. A step whose rank is staged shows "pending" until it is applied, so the waiting row moves on only once the rank is really the character's. The model reads the committed rank, not `ranksPurchased`, which includes staged ranks.
- **The spec tab being viewed:** **My call:** the panel shows the viewed tab's plan against that tab's own config (`GetCombatConfigIDForSpecGroup`). A tab with no config yet (secondary spec not bought) shows its plan with every step upcoming.
- Points spent on talents that aren't in the plan show as one line in the footer, "2 points off plan" (**My call**).

### The tree

- Row hover: a SaftUI highlight frame over that step's node.
- The waiting step's node: a SaftUI glow frame in the Accent over it, while the panel shows.
- Dim unplanned nodes: a dark SaftUI overlay over each node with no step, while the panel shows (setting, on by default).

### Planning mode

- Toggled by the Plan button. While on: the Plan button is selected, a line under the panel's title says "Click talents in the order you'll take them", and each node has a click catcher.
- Left click on a node adds its next planned rank as a step at the end, or after the selected row if one is selected (**My call**). A node whose planned ranks already equal its maximum does nothing and its catcher shows a "maxed" tooltip.
- Right click removes that node's last planned step.
- Each catcher's tooltip lists that node's planned ranks and their levels.
- Planning mode turns off when the window hides.

### Import

- Import opens a SaftUI dialog with a multi-line edit box ("Paste a guide's talent order") and Import and Cancel buttons, plus a choice: Replace this plan, or New plan (named from a box, default "Imported").
- The parser reads the text in order and finds talent names from the character's class tree (case-insensitive, punctuation and extra spaces ignored, longest name first so "Improved Stormstrike" wins over "Stormstrike"). After a name, "Rank N" (or "R N", or "N/M") says the rank; a number before a name is a level and is only used to check the order. Anything else is skipped.
- Each name found becomes one step: its next rank in the plan so far. A "Rank N" that disagrees with that, or a level that skips or repeats, is a warning, not an error.
- Before saving, the dialog shows the result: steps found, the level range, and the warnings and the text it couldn't match (a few lines, then "and N more"). The owner presses Import to keep it.
- **The real text** (the owner's copy of the Enhancement guide, 2026-11-22, kept as `tests/misc/fixtures/talentplan_guide_enhancement.txt`): a "Talent Order" header line, then one token per line: the level, the talent's name, and "Rank N" on its own line. A one-rank talent has no Rank line ("20 / Shamanistic Focus"). The parser must read this exact shape (51 steps, levels 10 to 60, the header skipped silently) as well as the same tokens on one line ("10 Thundering Strikes Rank 1"). Whether every name matches Forever's tree is in-game check 2.
- Guides from other trees or a different class: names that aren't in this class's tree are reported as unmatched, never guessed.

### Reorder

- Rows drag with the same handle, ghost and drop line as the bag categories (`SaftUI-Bags/dragparts.lua`; the builder decides whether to move that to Core or copy its shape). Phase headers drag too.
- A drop that puts a talent's rank 2 above its rank 1 renumbers that talent's ranks in list order (a step stores the node, not the rank; the rank shown is its count so far).

### Phases

**Retired.** The panel no longer draws, adds or edits phases and has no Phases button; a plan saved with phases keeps them in its data, unread. The title strip is the collapse arrow, the plan select button (it takes the room, no heading) and the count. The text below is the original design.

- A phase is a header before a step: a name and one of five colors (**My call**: the board's blue, orange, yellow, red, plus green). Its rows run to the next header. Rows before the first header have no phase.
- Phases are optional; a plan with none shows a plain list.

### Saving

- **My call:** plans are account-wide, by class (in the AceDB global table, `talentplan.plans[classFile][name]`), because a guide's plan is the same for every alt of that class. Each plan: name, steps (node IDs in order), phases (index of the step they start at, name, color).
- **My call:** which plan each spec tab uses is per character (AceDB char, `talentplan.active[specGroup] = name`). A character with no choice yet gets no plan, and the panel shows an empty state with Import and Plan.
- A step stores the node ID. Talent names are looked up live, so a client rename doesn't break a plan. A node ID that no longer exists in the tree shows as a red "Missing talent" row that can be deleted.

### Settings

A "Talent plan" page in `/sui` under Misc (**My call**): Enable (default on), Dim talents not in the plan (default on).

### A movable talent window

The owner, 2026-11-22: "can we make the talent frame movable?". `PlayerSpellsFrame` joins the windows `SaftUI-Misc/movable.lua` already makes draggable (`SettingsPanel`, `AddonList`, `TransmogFrame`), with `addon = 'Blizzard_PlayerSpells'` since it loads on demand. It moves the way those do today: dragged by the mouse, clamped to the screen, and back in Blizzard's spot the next time it opens, since the game lays out its panels on each show (**My call**, to match the others; remembering the spot is a followup if wanted). The plan panel re-docks when the window is dropped. This part ships first and on its own, since it is one line in an existing list.

### A compact talent window

Revised 2026-11-22. The owner: "there's so much empty space currently on the frame, can we reduce it a bit so that the spacing between the talents and the edges separating the specs (and the side of the window) is the same as the spacing between talents?" SaftUI moves each tree's talents sideways so the gap between a tree's outer talents and the dividers (and the window's sides) equals the gap between two talents, centers the tree headers and dividers on the new regions, and narrows the window to match. Post-hooks and plain widget calls only, on by default, with a check box to turn it off (a `/reload` puts Blizzard's layout back). The height is left alone (**My call**). Plan Task 10.

## Where it lives

**My call:** `SaftUI-Misc/TalentPlan/`, a new module beside the other Blizzard-frame additions, with the parser and the row-state model in their own files so `tests/misc/` can test them without the frame. The builder may pick another home if `.agents/architecture.md` says otherwise.

## Left to the builder

- The exact post-hook that tells the panel the tree redrew its buttons (button pool changes, spec tab, config commit, `TRAIT_CONFIG_UPDATED`).
- Sizes, spacing and fonts, from SaftUI's tokens.
- How the drag code is shared.
- The tests: the parser (names, ranks, levels, unmatched text, longest match), rank renumbering after a move, the row states from given ranks and level, the off-plan count.

## In-game checks for the owner

1. Open the talent window on Forever: the panel docks on the right, in the theme, and hides on the Spellbook tab and when inspecting.
2. Paste the shaman list from the guide: 51 steps, no unmatched lines except the guide's own extra text.
3. Planning mode: clicks add steps and never buy a rank.
4. Level up with the plan: the waiting row moves on after learning the talent; the node glows.
5. `/console taintLog 1`, use the window, learn talents, `/reload`: nothing in `Logs/taint.log` blames SaftUI for `Blizzard_PlayerSpells` or `Blizzard_SharedTalentUI`.
