# UI scaling, phase 1: the in-game checklist

One list for the whole phase (`docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1.md`, Tasks 1 to 8), in the order to play it. Nothing here counts as verified until the owner confirms it in game. The tests run on stubs and a model of the game's pixel grid: they cover which number is set, which function is called, and whether each edge lands on a whole pixel in the model, not what the game draws, what it does in combat, or what its keyboard order is. Nothing here needs a character, realm or account name.

Check on WoW Forever (the client played) first, then once on retail where a line says so. Turn on BugGrabber's log. Everything is at SaftUI's defaults unless a line says to change it, and your screen is the 2560 x 1440 one, Automatic at 100%, so one unit is one pixel and SaftUI should look exactly as it did.

G1 to G9 are the spec's checks (`docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`, "What only the game can confirm"), marked where they come up. G2 and G3 are the friends' (section G).

## A. Your own screen: nothing looks different

Do this before anything else, with `/sui` closed. Anything that moved here is a bug.

1. **G1, the numbers.** `/run print(UIParent:GetScale(), 768/1440, SaftUI.pixel, SaftUI.lineWeight, SaftUI.line)` prints `0.53333336114883 0.53333333333333 1 1 1`: the first two are equal within the game's single precision (not "the same number twice"), and the last three are exactly 1.
2. **G1, the screenshots.** Take the same scene before and after (the old build, then this one) at 1440p and compare: unit frames, action bars, the micro menu and minimap, chat, a bag window, `/sui` open, and edit mode on. No border changed width, no frame moved, no text shifted.
3. **Borders under each theme.** Under Thick, Thin and Blizzard (Global settings > Theme) every border is one pixel (Thick three: the dark line either side) on every side, on the unit frames, bars, bags, `/sui`'s window and panels, the tooltip and the close buttons.
4. **Nameplates.** Strafe and turn past a pack under Thick, Thin and Blizzard: the borders round the health bar, the castbar, its icon and the aura buttons stay whole, with no shimmer or doubling, and the name and health text don't jitter. At the default Width 200 and Height 20 a plate is exactly as before.
5. **The one known change: an odd plate size.** Enemy nameplates > General > Width 201 and Height 21: the plate is now 202 by 22 (a plate is a whole, even number of pixels, so its centred parts land on whole pixels). 199 by 19 becomes 200 by 20. Set them back afterwards. Say whether you mind.
6. **Frames the game scales.** Skinning > Cooldown Manager and the buffs, with Blizzard's Edit Mode Icon size at 80% and at 150% (and the swing timers' Scale on Forever): their borders are now exactly one pixel on every side and the icon meets the border with no gap and no overlap. Before, the line was as thick as the frame's scale made it. This is the owner's call (kept: one-pixel lines stay on frames the game scales); say if it looks wrong.
7. **No first-login line.** Nothing is printed at login about the UI size (your screen is Automatic at 100%), and a `/reload` prints nothing either.
8. **Positions.** Drag a frame in edit mode and release: it lands where it did, and a saved position is where it was before the update. Change the grid size and snap a frame: nothing off.

## B. The new section

Global settings > General, at full and half size, under Thick, Thin and Blizzard.

1. **Order.** UI scale is the first section, then Icons and Layout as before, each with its note.
2. **The line (G1).** Under the rows it reads "This screen is 2560 x 1440: SaftUI draws at 100% of its 1440p size, with 1 pixel lines."
3. **Scale.** The select lists Automatic, Pixel for pixel and The game's UI scale, in that order, and shows Automatic. Hover it: the description says what each does. No reset arrow at the default.
4. **UI size.** A slider with a box, 70% to 150% in 5% steps, showing 100% and no reset arrow. Hover it for the note ("Makes all of SaftUI larger or smaller than the automatic size...").
5. **Dragging does nothing until you let go.** Drag the slider: the box and fill follow, nothing on screen changes. Let go: the size changes at once and the Keep prompt asks (section C). An arrow's click and a typed value (115) do the same. Dragging it back to where it started asks nothing.
6. **G4, the largest size.** At 150% `/sui` still fits and its rows reach (it may drop to half size under the prompt and open at full again after Go back). `/sui scale reset` from there puts Automatic at 100% back.
7. **Pixel for pixel.** Pick it (and Keep): the UI size row greys out and its tooltip says "Only Automatic has a size." On 1440p nothing looks different, as Pixel for pixel is the same size there. Pick Go back instead and the select returns to Automatic. Pick The game's UI scale: the size is the game's. Back to Automatic.
8. **Reset arrows.** A rotate arrow shows beside Scale only while it isn't Automatic, and beside UI size only while it isn't 100%. Clicking one asks through the Keep prompt (it is a preview, never a straight change). Go back puts the row and its arrow back. Scale's reset leaves the UI size alone.
9. **A refused change.** In combat each row says "The UI size can't change in combat." in chat and changes nothing.
10. **The rows after a reload.** Keep 90%, `/reload`: the row says 90% and the screen is at 90%. Everything on the page (Icon zoom, Title bar height, Screen edge margin) still works.

## C. The Keep prompt

Use the UI size slider or `/sui scale 120` to bring it up.

1. **The look.** "Keep this UI size?" with "Going back in 15 s." counting down, a Keep and a Go back button, in the middle of the screen, at the same size whether 70% or 150% is being tried (it is drawn at your automatic size). It is over `/sui`, edit mode's bar and window, the Coordinates label and the History list.
2. **Keep ignores a click for half a second.** Right after it appears, Keep looks dimmed and a click on it does nothing; click it twice quickly (as a double-click on the slider would) and nothing is kept. After that it keeps. Go back and Esc work at once.
3. **The three ways back.** Go back; Esc; and leave it until 0: each returns to the size before the first try. Keep saves it: `/reload` and the size is still there.
4. **Esc with `/sui` open (the order is inferred, so this is the one to watch).** With `/sui` open and the prompt up, press Esc once: the prompt goes back and `/sui` stays open. A second Esc closes `/sui`. If one Esc closes `/sui` and leaves the prompt up instead, say so (the prompt still goes back at 0, so nothing keeps by accident).
5. **Enter and other keys.** Enter does nothing. A bar key and movement still work while it shows.
6. **Not modal.** Clicking beside it reaches what is under it. Closing `/sui` leaves it up.
7. **A second try.** `/sui scale 90`, then `/sui scale 120` while it shows: the countdown starts again, and Go back returns to the size saved before the 90.
8. **At 150% on 1440p** the prompt's border looks heavier (two pixels, Thick six): the weight follows UIParent's scale, whole but jumping (known; say if it bothers you).
9. **Through a fight.** Start a fight (a training dummy) while it is up: it stays, your bar keys and movement work, Esc does nothing. Click Keep: it closes and saves. Click Go back, or let the time run out: the line reads "Goes back when combat ends.", the buttons hide, and the size goes back after the fight.
10. **Open lists and dialogs.** With a select list or a confirm dialog open when the prompt shows, they may cover it (known; its time still runs out).

## D. `/sui scale`

1. `/sui scale` prints "UI scale: Automatic at 100%." and "This screen is 2560 x 1440: SaftUI draws at 100% of its 1440p size, with 1 pixel lines." Nothing else changes.
2. `/sui scale 90`: everything resizes at once with the prompt; Keep, `/reload`, still 90%. `/sui scale 90%` and `/sui scale 0.9` do the same; `/sui scale 1.25` tries 125% (a number under 5 is a factor).
3. `/sui scale auto`, `pixel` and `game`: each tries that mode at the size already chosen, with the prompt.
4. `/sui scale 200` goes to 150% with the prompt; `/sui scale 50` goes to 70%; `/sui scale big` prints the forms line.
5. **`reset`.** From 150% and from 70% (kept): `/sui scale reset` puts Automatic at 100% back at once, with no prompt, and prints "UI scale back to Automatic at 100%." If a prompt is up it goes. In combat it says it goes back when combat ends.
6. At 70% and at 150% (try them) `/sui` is usable and the prompt is readable. Go back from each.

## E. Blizzard's UI Scale slider, a resolution change, a window

1. **G6, the slider.** Options > Graphics, tick Use UI Scale, move the slider and apply: SaftUI's size comes back on the next frame, and chat says once, "SaftUI sets the UI's scale itself. To use the game's UI Scale, choose The game's UI scale in /sui > Global settings > General." A second move says nothing. The size is back and every border is whole.
2. **The game's UI scale.** Choose it in `/sui` (and Keep): the game's slider sets the size, borders whole. Move the slider: the size follows it. Back to Automatic.
3. **A resolution change (G5).** Switch to 1920 x 1080 and back, out of combat: no Lua error, SaftUI's size back on the next frame, nothing said in chat, borders whole. Check the line under the UI scale rows now reads for 1080p ("This screen is 1920 x 1080: SaftUI draws at 75% of its 1440p size, with 1 pixel lines.") and the whole UI is three quarters of its size, taking the same share of the screen.
4. **A windowed change.** Resize the window a little under the screen (it reads about 2560 x 1377): the pixel stays 1 and SaftUI's scale comes back on the next frame. Move the window to another monitor if you have one.
5. **Six quick changes.** Resize the window six times within a second: the line under the rows switches to "The game keeps setting its own UI scale, so SaftUI stopped setting it back...", and chat says it once. Changing Scale or UI size recovers it.
6. **G7.** Nameplates after a UI size change and back (try 125%, then reset): whole borders while strafing past a pack, with no `/reload`.

## F. In combat

1. **E4 first (the one thing no experiment has shown).** With a training dummy, start a fight and paste `/run UIParent:SetScale(0.5)`. Report whether it errors or "Interface action failed" shows, and whether `/run print(UIParent:GetScale())` changed. After the fight, out of combat, paste `/run UIParent:SetScale(768/1440)` and then `/reload`. If you can, do the same on retail. Either answer is safe: SaftUI waits for the end of combat whatever it is, and the answer only changes what the docs call "inferred".
2. **G5, a display change in combat.** In a fight, resize the window or change the resolution: no error, and the scale comes back after the fight (or on the next frame if it wasn't blocked).
3. **G7, a `/reload` in combat.** No "Interface action failed", and the scale and every border are right by the end of the fight.
4. **`/sui` in combat.** It closes in combat and stays shut until it ends; edit mode's Undo, Redo and Reset refuse in combat as before.
5. **`/sui scale 90` in combat** prints "The UI size can't change in combat."; `/sui scale reset` says it goes back when combat ends.
6. **G9, the taint log.** `/console taintLog 1`, play the checks above (a prompt in a fight, a resolution change in a fight, plates), `/reload`: no "blocked" line naming SaftUI in `Logs/taint.log`.

## G. What to ask each friend

Send them the build and these. Nobody needs to change anything first: SaftUI sets its own size.

**Both friends**

1. **E1, the screen as the game sees it.** Paste these two (one line each) and send back what they print, with the monitor's name, whether the game is fullscreen or windowed, and Graphics > Render Scale. The Mac friend also pastes the third.
   - `/run local w,h=GetPhysicalScreenSize() print("phys",w,h,"ui",UIParent:GetScale(),UIParent:GetEffectiveScale(),"units",GetScreenWidth(),GetScreenHeight())`
   - `/run print("dpi",GetScreenDPIScale(),"def",GetDefaultScale(),"cvar",GetCVar("useUiScale"),GetCVar("uiScale"),"rs",GetCVar("RenderScale"))`
   - `/run print("notch",C_UI.DoesAnyDisplayHaveNotch(),C_UI.ShouldUIParentAvoidNotch(),C_UI.GetTopLeftNotchSafeRegion())`
2. **E0, the size.** At the first login the chat line says SaftUI sized itself to the screen. Does 100% look right? If not, which percent does (Global settings > General > UI scale > UI size)? Is 70% to 150% the right range?
3. **The way back.** If a layout you tuned for the old size doesn't suit, `/sui scale pixel` is the old size; `/sui scale reset` is the new one. Did either work?
4. **The UI scale section's boxes.** Open Global settings > General and look at the Scale box, the UI size box and the slider, and the Keep prompt's two buttons: do any look blurry, uneven, or off by a pixel? (These are the options kit's, not yet on whole pixels away from 1440p: phase 2.) A screenshot helps.
5. **Borders.** Under Thick, Thin and Blizzard, every border on the unit frames, bars, bags and windows one pixel (two on the Mac) on every side, none missing a side or doubled; plates too, while moving.
6. **A resolution or window change, and Blizzard's slider.** As section E: the size comes back, nothing breaks, a line in chat once for the slider.

**G2, the 1080p friend.** The size matches what E0 showed. Homespun (the small text on bars and buttons) looks as it did when they judged it at this size.

**G3, the Mac friend.** The same with two-pixel borders. And:
- **E6.** Open `/suifonts` (the demo window; the game must be fully restarted once to see its font files) and judge Homespun at the Mac's scale: crisp or rough? Compare with the Lucide icons (the arrows, the reset icon, the filter funnel) in `/sui`: crisp or soft? This decides whether phase 5 needs a rule (the font demo is deleted once this is in).
- The notch: does anything sit under it?

## H. What is known not to be whole-pixel yet

At a scale other than 1 (your own screen has none of these), each has a followup in `docs/followups.md`:

- The options kit's boxes, buttons, hairlines and labels, including the Keep prompt's buttons and the UI scale section's boxes, on every screen but 1440p (phase 2).
- The docked edit mode bar's place, and the Coordinates label, which shows stored units (phase 3).
- A nameplate's inner parts, the action bars' and the totem bar's own even-pixel helpers, the bags' loading overlay, the two `st:ThemeInset` readers without a frame (`SaftUI-Misc/totemskin.lua`, `SaftUI-Bags/categoriestab.lua`), and every other addon's one-unit lines (phase 4).
- The Blizzard theme's art (its atlas corners and edges, ring and slot art) in a frame with a scale of its own: allowed by the plan, and your eye decides whether it matters.
- The Keep prompt's line weight at a 150% preview, and its Esc order (section C).
- Crispness of Homespun and the Lucide icons on a dense screen (phase 5, from E6).

Open and not part of the checks: E0 may retune the default and range, E1 on the friends' screens may find an odd notch, and the font demo goes once E6 is in. All three have an entry.
