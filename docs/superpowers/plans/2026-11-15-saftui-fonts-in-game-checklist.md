# SaftUI fonts: the in-game checklist

One list for the whole fonts plan (`docs/superpowers/plans/2026-11-14-saftui-fonts.md`, Tasks 1 to 8), in the order to play it. Nothing here counts as verified until the owner confirms it in game. The tests run on stubs: they cover logic, whole pixels and which function is called, not what the game draws.

Check on WoW Forever (the client played) first, then once on retail where a line says so. Turn on BugGrabber's log, and `/console taintLog 1` where a line asks for it.

G1 to G8 are the spec's checks (`docs/superpowers/specs/2026-11-14-saftui-fonts-design.md`, "In-game checks").

## A. Check first: what the tests could not answer

These six depend on how the game behaves, and each has a fallback written down.

1. **Chat with Blizzard's line spacing 0 (G5).** Chat keeps Blizzard's line spacing (0) while Text's is 4, and takes the face, size, outline and shadow from its font.
   - With Text unchanged, chat looks the same after the upgrade. Then change Text's size on the Fonts tab before the upgrade on a spare profile, and look again.
   - Judge the line gaps. If they are off, say so: the fix is chat's `fields` or taking Text's spacing (the plan's Ruling 7).
   - After login, is chat at SaftUI's size or at Blizzard's chat-cache size? Does a Fonts tab change that leaves chat's font alone keep a size picked from the chat tab's own Font Size menu?
2. **A typeface registered by another addon, picked right after login (G1).** Before opening any font list or the Fonts tab, have (or pick) a typeface another addon registers on a unit frame's name, or in chat. It must draw in its own face, not Text's. Open a font list, pick the face again and change any font setting: it must still draw in its own face (a refusal is retried on each of those).
   - If it shows Text's face until the first font change, the load probe misjudges that file: report which addon's face.
   - If a typeface that no text has used yet does not draw when picked mid-session, the fix is preloading every face LibSharedMedia lists, at load and on its register callback (the spec's G1 fallback). Raise it as a followup then; none is written, because SaftUI's own faces are preloaded and this check is what decides it.
3. **Macro names on bars 1 to 8 keep their old shadow.** After the upgrade, an untouched profile's hotkeys, stack counts and macro names must look exactly as before: no shadow on the hotkey and count, and no shadow on any of the three, as before (these texts are typefaces, so `AB:StyleButton` sets their shadow to 0, 0, as the old forced one did, not the template's 1, -1). Then, with `/run`:
   - `local AB=SaftUI:GetModule('ActionBars') AB:SetSetting('bar1','hotkey.font','pixel') AB:UpdateBar('bar1')`, then `/run local b=SaftUI_ActionBar1Button1 print(b.Name:GetShadowOffset(), b.Name:GetFontObject():GetName())` on a button whose macro has a name.
   - Also try it from the text's menu (section G).
4. **Totem texts set in combat, with the taint log.** `/console taintLog 1`, the totem bar showing, then change Button text (a typeface) from a profile switch in combat if you can. Nothing is blocked. The one inferred point is `SetFontObject` on the secure buttons' regions in combat. Do the same with chat and tooltips showing while changing a Fonts tab setting.
5. **Compact bag titles cut with Heading.** In Compact, a bag holding Flasks/Potions/Food, Professions/Recipes or a Paladin/Priest/Warlock category: count how many default titles are cut with dots at Colus 15 in the 186 px column (by measurement about three, and two more within a few pixels). Decide: leave it, Heading at a smaller size, a narrower face, or Text for Title font.
6. **The tracker's headers in Heading (G3).** Turn SaftUI's tracker on and `/reload`. Its header line, count, zone headers and popup labels are Colus 15, laid out, with the zone rows 20 tall and the header 24. Then set Heading to a large size (30 or 40) and look once: the 1.25 factor is a measurement of Colus's line height, not seen in game, so check nothing clips and the chevrons sit centred.

## B. Login and the upgrade (Tasks 1, 5, 7)

- Log in on both clients with no Lua errors, and `/reload` once.
- An old profile looks as before, except the listed changes in section K. If Huge title's face was changed before the upgrade, Heading has that face (one time, on the first login), and `/sui`'s titles show it. Switch to a fresh profile and back: nothing changes again.
- Switch profiles with the Fonts tab open: the tab and the fonts follow, no errors.
- A font setting that names Pixel Huge or Normal Med in the old build still draws as it did, and its Font row shows "Homespun" or "AgencyFB Bold".
- G6: the zone name is Huge title at 72, and its subtitle lines are as before.

## C. Global settings > Fonts (Tasks 1, 2)

- The top line, then Text, Small text, Large numbers, Heading, Huge title and Subtitle in that order with a note each, Kinds of text last (Button text only). No Pixel Huge, Normal Med or Name rows. Rows are Typeface, Size, Outline, Shadow offset X and Y, Line spacing; outline names in sentence case.
- Change Small text's size: its reset icon shows ("Size goes back to its default: 10."); click it and the size and every text on it return at once. Same for Shadow offset X (Y alone shows no icon) and Outline ("... default: Monochrome outline."). The Typeface reset tooltip names the face ("... default: Homespun.").
- Hotkeys and counts that are on Small text follow at once; the totem timers and the tracker re-lay out at once. Drag Text's Size on the Fonts tab and watch for a stutter.
- G4: change Heading's Typeface: `/sui`'s page title, section and group titles change at once, nothing clipped, under Thick, Thin and Blizzard. Change Heading's Size: they stay. Change Huge title's face: `/sui` does not change. Change Text's Typeface: labels, tabs and fields follow, and a profile switch redraws them.
- Kinds of text: change Button text and see it reach the totem bar's key bindings, counts and names and the bag slot bars (not the totem timers, which have their own Timer font), and the bags' and keybind mode's buttons (section N). Its reset tooltip names "Small text". There is no Check box labels row.

## D. The font row and its list (Task 3)

- Every Font row shows the new list: a caption "SaftUI fonts" over the six, then "Typefaces" over every face, each entry in its own face. The picked entry is blue. A list opened on Text or Heading shows "SaftUI fonts" and the fonts above the pick.
- Beside a shared font, the link. Its tooltip names the font, says it is set on Global settings > Fonts and changes every text that uses it, and says "Click to go there." (G7) A click lands on that font's Typeface row with its label lit, the section title whole at the top, at full and half size, under Thick, Thin and Blizzard, from a page and from the action bars' text menu (the menu closes).
- Pick a typeface: the row shows the face, and a different face keeps its size and outline. Pick a shared font again: the link is back.
- G1, first part: a typeface no text used yet, picked mid-session for a unit frame's name, draws at once, and its list entry is in its face.
- A face whose file the game refuses (a shared font on it, Text's own face, a typeface in a row, chat, the tooltip, RestedXP's texts and timers, the buff timers): covered by the tests only. It can't be tried in game: LibSharedMedia refuses to register a face with an invalid path ("Attempt to register an invalid font"), so no refused face can be put in the list.
- Text on a face SaftUI does not preload (Friz Quadrata TT, on the Fonts tab): a unit frame's name set to a typeface in Friz Quadrata TT at another size draws in Friz, not in AgencyFB Bold. Put Text back afterwards.
- A refused face retried: register a face right after login, pick it on a row, and if it drew in Text's face, open the list again or pick it again: it now draws in its own face.
- Under Blizzard the face and slot gap look right (a 194 wide row). A disabled row's face and slot take no click.

## E. The dots and their menu (Task 4)

- G8: a typeface on a unit frame's name, then its dots: a menu "Name font: Colus" (the row's own name) with Size, Outline, Shadow offset X and Y and Line spacing. A Size drag follows on the frame as it moves. Outline and the shadows reach it at once. Try Outline on chat, a bag title and loot too.
- The dots' tooltip lists only what the row's menu shows ("Size, outline, shadow and line spacing for Colus"; chat's "Size, outline and shadow"; the tooltip's "Size and outline").
- The menu hangs from the dots, stays inside the screen margin, and closes on Esc, a click outside and a page or tab change. Pick a shared font while it is open: it closes and the link shows. Reset the row with it open: it closes. A disabled row's dots take no click, and no menu opens in combat.
- Under Blizzard the dots turn white under the mouse.

## F. Readers (Tasks 5, 6)

- Chat: pick a typeface on chat, then Text again: every chat window and the edit box follow at once. The Chat page has no Font size row.
- Tooltips, RestedXP's window and timers, and the buff and debuff timers look as before; a Fonts tab change to Text reaches RestedXP at once. If the tooltip is on a monochrome typeface, `/run print(GameTooltipTextLeft1:GetFont())` after a Show gives the flags SaftUI sets.
- With Skinning's color picker on, a Window titles change reaches its title at once; off, the title is Blizzard's. A Skinning font change reaches its buttons and hex box.
- Blizzard's objective tracker (the skin), the Cooldown Manager, the swing timers and the character frame's item levels follow the Skinning font, a typeface too.
- A typeface picked for a unit frame's health text, a name, an aura count, the bags' Icon font and Category titles, the loot feed's Font, a roll bar and the tracker's Font and Header font each draws at once.
- Copy from on a unit frame with a typeface, then Undo: the typeface is back whole.
- The tracker's item buttons' count and key texts (in and out of combat) look as before and nothing is blocked (`/console taintLog 1` while changing a Font setting with a quest item button showing).

## G. The action bars' and buffs' Font rows (Task 8)

- **G7, from a text's menu:** on `/sui` > Action Bars, open Hotkey's dots, and click the link beside a shared font (pick Small text first): the menu closes and the Fonts tab shows Small text's Typeface row.
- **G2, from the hotkey's Font row:** Small text, then Colus, then Small text. Each draws at once with no reload, on bars 1 to 8 and on the pet and stance bars. Size and Outline are hidden while Small text is picked and come back, holding the values they had, when Colus is.
- A hotkey on Small text follows a Small text change on the Fonts tab (size, outline, shadow) within a frame. Out of combat only: in combat the restyle waits for the end of it.
- A fresh profile's texts look exactly as before, and they are Small text (so their Font rows read "Small text" with the link, and Size and Outline are hidden); the reset arrow on All bars' text Font row says "default: Small text" (section N).
- All bars' Apply to with a shared font reaches the chosen bars: set Bar 3's hotkey to Heading, Apply to > Multiple > Bar 5, and Bar 5 shows Heading. The orange diff icon on All bars' Hotkey names a bar that owns a font by its name ("Bar 3: Heading").
- Cooldown numbers: on a 45 px bar the Font row shows "Large numbers" with the link, on the 30 px pet bar "Small text", and Size and Outline are hidden. To reach a size alone, pick a typeface in the Font row, set Size, then reset Font (All bars' reset arrow, or a bar's share Reset): the row then shows the face drawn, with Size and Outline shown, and resetting Size too puts the shared font back. On All bars Size and Outline stay shown while any bar owns one, so a bar that owns only a size or outline is named by the orange icon and can be made to follow with Apply to. The numbers look as before on 30, 36 and 45 px buttons, with a custom size or font on a bar and back to none.
- Hotkeys, counts and macro names show no shadow by default: they are Small text, whose shadow is 0, 0. Give Small text a shadow on the Fonts tab and they show it (section N); a face picked on a text shows none.
- Re-click the entry the cooldown Font row already shows on All bars (Large numbers): nothing changes, and no reset arrow appears; the 30 px pet and stance bars stay on Small text.
- The Outline rows list None first, as the Fonts tab does.
- **Buffs:** `/sui` > Buffs and debuffs (the Auras page) > Text: Duration's and Stack count's Font lists the shared fonts. Pick Small text: Size and Outline hide, and the timers on the buff and debuff icons draw in Small text and follow a Small text change on the Fonts tab. Pick a face: Size and Outline return and apply.

## H. Theme > Window titles (Task 7)

- Global settings > Theme: a Window titles section after Options windows with one Font row (Text, no reset while it is Text). Pick Subtitle: the bags' and bank's titles, `/sui`'s title bar under Blizzard and Blizzard's color picker's title (Skinning on) change at once; the gold and free-slot texts and the search box do not. Reset puts Text back. Pick a typeface in its dots: the same. Do it under Thick, Thin and Blizzard.
- The bag window after a wider Window titles font: the title may run over the view buttons until the window is next laid out (an open followup).
- RestedXP's guide title is in Heading's face; change Heading's face and it follows at once.

## I. Bags and the tracker after the upgrade (Task 7)

- G3: the bags' category titles are Colus 15 and sit right in their band, down to Category title height 20. The search box and the gold and free-slot texts are as before.
- If Title font or Header font had been set to Text before the upgrade, the profile has nothing saved for it and moved to Heading: re-pick Text if wanted.
- The tracker's Header font row: its reset names Heading; set Text and the header and zone headers go to Text.

## J. Reload, downgrade and the profile marker

- After a `/reload`, everything above still holds.
- Do not load a profile that has run this build in an older checkout: the older Fonts code reads `fonts.version` and a moved Heading as fonts and errors. The upgrade is one way.

## K. What an upgraded profile shows differently

- A profile that never saved the bags' category title font or the tracker's Header font: titles move from Text to Heading (Colus 15); the tracker's header line, count, zone headers and popup labels too (it is off by default).
- A profile that saved them keeps its pick; one imported from before the upgrade carries `'normal'` and keeps Text.
- A profile that changed Window titles keeps its titles, but its bags' gold and free-slot texts now take Text. A profile whose Title font was Small text or a typeface has its bag search box in Text.
- A profile that changed Huge title's outline (not its face) sees `/sui`'s titles and RestedXP's guide title take Heading's outline.
- Hotkeys, counts, macro names and the buff timers: nothing, until a shared font is picked.
- A profile that set a bar's cooldown font, size or outline, and whose Small text or Large numbers has an edited shadow or line spacing, loses that shadow and spacing on those numbers: they are a typeface with Text's default shadow (0, 0) and spacing (4) (Task 6, Ruling 18).

## L. For the owner's decision: what the controller ruled

Each of these is a call made while building, and the tests pin it as it stands. Say if one should change.

1. **The dots' tooltip wording.** "Size, outline, shadow and line spacing for Colus", listing only what the row's menu shows, in place of the spec's "<face> for <row>" with a second line. The menu's title stays "<row name>: <face>" ("Font: Colus" on rows named Font).
2. **Compact bag titles are cut.** Compact now cuts a category title to its column with dots, as the other views do, with no tooltip on a title. At Colus 15 about three default titles are cut (section A, 5).
3. **The tracker's header heights come from the font.** The header line is at least 24 tall and a zone row at least 20, growing to about 1.25 times the Header font's size, kept even so the chevrons sit on whole pixels. Heading at 40 gives a 54 header and 50 zone rows.
4. **Action bars restyle on a shared font change.** A text on a shared font follows the Fonts tab through `AB:OnFontsChanged`: one restyle per frame at most (a Size drag restyles on each step's frame), and once after combat. Bars on faces are not touched. Bars 1 to 8 keep LibActionButton's own `SetFont`, fed from the same look.
5. **The upgrade is one way.** A profile that has run the new build must not be loaded by the old code (section J). Heading's face step is one time (`fonts.version`).
6. **A face the game refuses draws in the fallback face.** That is the profile's Text when it loads, else SaftUI's default Text face, for value readers, typeface objects and the six shared fonts alike. The texts keep the size and outline picked. A refusal lasts until the next font change, a font row's pick or a font list opening, so a face fixed later is tried again; a good face is remembered for the session.
7. **Chat keeps Blizzard's line spacing.** Chat takes the face, size, outline and shadow and leaves the spacing at Blizzard's 0 (Text's is 4), so chat's dots list four rows and the tooltip's two (section A, 1).
8. **Size and Outline hide while a shared font is picked.** On the action bars' and buffs' texts, and on a bar's own page. On All bars they stay shown while any bar owns one, so the diff icon and Apply to name that bar.
9. **The Fonts tab's top line** keeps its Task 2 wording ("Font rows throughout SaftUI choose from these") where the spec says "Every Font row in SaftUI lists these first"; it also says a typeface's size and outline are in its dots, or beside the row on the action bars' and buffs' texts.
10. **A shared font in a text's Font row replaces the text's own size and outline** (they stay saved and come back with a face). The defaults are now Small text itself (section N), with a conversion for a profile saved with a copy.

## M. Design System

`docs/design-system/` changed across the plan (README's Type table, `tokens.json`, the Select, Icons, Options window and Position block pages, discrepancies 2 and 20, Code change 3): republish the Design System artifact.

## N. Feedback round: Kinds of text, the totem timers' font, the action bars' defaults (branch fb-fontfeat)

Kinds of text does what its rows say:

- Global settings > Fonts > Kinds of text > Button text: pick Heading. The labels of the bags' Bag Slots button (open a bag), the bank's Warband Bank and Deposit buttons and its category tabs, and keybind mode's Done (`/sui kb`) change at once, in size and face, with no reload. Pick a typeface: the same. Reset: they are back in Small text (Homespun 10, monochrome outline, no shadow), exactly as before the change. The micro menu's clock does not change (it keeps Small text).
- The same Button text pick still changes the totem bar's key bindings, counts and names and the bag slot bars' texts, and no longer the totem timers.
- Check box labels has no row on the Fonts tab (no visible check box label exists; see the followup "Check box labels: no font setting until a SaftUI check box has a visible label"). The hidden Edit toggle is styled as a button and follows Button text.
- Pick Text, then a typeface of 24: Warband Bank, Deposit, Withdraw, Buy and keybind mode's Done (16 px tall) still show a label (cut at the sides if too wide, never blank), and the buttons do not grow.

The totem timers' font (Totem bar page > Timer font):

- A fresh profile: the countdown over each element button looks exactly as it did (Small text: Homespun 10, monochrome outline, no shadow). The Timer font row sits beside Timer bar height, just after Text position, with its reset arrow absent; Text X offset and Text Y offset stay a pair.
- Pick Large numbers, then a typeface with its dots (Size, Outline, Shadow offset X and Y, Line spacing): the countdowns change at once, the bar under or behind them gets taller or shorter with the text, and the flyout arrow moves with it. Reset puts Small text back (its tooltip says "Small text").
- A profile that had changed Button text before this build: the totem timers now draw Small text (Button text no longer reaches them; they used to follow it). Pick the font again on the Timer font row if it is wanted. The key bindings, counts and names on the totem buttons still follow Button text.
- Totem bar in combat: change the Timer font from a profile switch if you can: nothing is blocked (only fonts on regions of SaftUI's own timer frames, which are children of the secure slot buttons).
- The Timer font row is greyed out while Show timer text is off.

The action bars' and buffs' texts default to Small text:

- A profile you have never changed (or a new one): hotkeys, stack counts and macro names on bars 1 to 8 and the pet and stance bars, and the buff and debuff durations and stack counts, look exactly as before (Homespun 10, monochrome outline, no shadow, the macro names too). Their Font rows read "Small text" with the link, Size and Outline are hidden, and the reset arrows are absent.
- Fonts > Small text: change its Size, Outline or Typeface. All of those texts follow within a frame (out of combat; in combat once it ends), on every bar. Give Small text a shadow: they show it (that is the one thing that now differs from a typeface, which has none).
- A profile that had a customised text before this build (a hotkey size changed, an outline changed, a face picked, on All bars or on one bar, or on a buff's Duration): after the first login on this build each draws exactly as before. A size or outline changed without a face now shows Homespun in its Font row as a typeface, with its Size and Outline shown. A face picked stays. Try one bar that had only its size changed while All bars was left alone: it shows Homespun at its size and the others follow Small text.
- A profile in which you had picked Small text on a text while an old size was still saved beside it: it now shows Homespun at that size (the one case the conversion reads the other way, see `docs/followups.md`, Resolved). Pick Small text again to follow it.
- A profile in which you changed Small text itself before this build: the action bars' and buffs' texts now show that change (they used to ignore it).
- Reset arrows: on All bars, a text's Font after a face is picked says "default: Small text" and puts it back; on a buff's Duration or Stack count the Font, Size and Outline rows have a reset that puts Small text, 10 and monochrome outline back.
- The cooldown numbers are as before: Large numbers on buttons of 36 pixels and up, Small text below, unset by default.

- Drag Small text's Size, then Heading's Size and Text's Size, with every bar shown: only a Small text change restyles the bars (once per frame); Heading and Text leave them alone, with no stutter beyond the drag itself.
