# Nameplate preview on the plate pages

Status: draft for the owner's approval, 2026-11-28.

## Intent

The owner asked (2026-11-28): "can we add a preview nameplate frame for editing
nameplates where you can see auras with all of the text up?" Today the only way
to see a change on the Enemy or Friendly nameplates page is to find a real mob
(or friend) that has debuffs on it, a purgeable buff, a cast going and threat.
Most of those are rare at once, so placing a part, sizing the aura rows or
choosing a font is guesswork. The preview is one sample plate, drawn from the
page's settings, showing every part at once and following each change live.

Asked where it lives, the owner chose "at the top of the nameplate config
frame" (over docked beside `/sui`). The approach below (a fixed band) was
recommended and taken unless the owner says otherwise.

## Goals

- A sample plate at the top of both nameplate pages (Enemy nameplates and
  Friendly nameplates), on every tab of the page, under the Unit picker line
  and above the settings.
- It does not scroll with the settings: a slider at the bottom of a long tab
  (Castbar, Debuffs) still shows its effect.
- Every part the page has turned on is drawn at once, with made-up data:
  health bar and its text, name, castbar with its spell name, time and icon,
  debuffs (as many as Max), purgeable buffs (as many as Max), quest icon, raid
  mark, threat text (Enemy page) and the subtext line.
- Drawn from the same settings and the same placing code as a real plate, at
  true size (a plate's frame is pinned to UIParent's scale, and the options
  window is at UIParent's scale too), so spacing read off the preview is the
  spacing in the world.
- Follows every setting on the page as it changes: a part on or off, its
  position, size, font, theme, colour, the plate's width and height; and the
  global changes that restyle plates (theme, fonts, colours, profile switch).

## Non-goals

- Not a fake unit. No oUF frame, no secure frame, no unit token, no Blizzard
  aura container. Plain frames, like the group Test mode previews
  (`grouppreview.lua`), so it is safe in combat and touches nothing of
  Blizzard's (`.agents/taint.md`).
- Not on screen in the world, and not in edit mode. Only inside `/sui`.
- No editing by dragging the preview's parts. Parts are moved with the page's
  Position rows as today.
- No aura tooltips, clicks or real cooldown ticking on the sample icons.
- Not the group Test mode element toggles (followup 2026-11-13 stays open; this
  may inform it).

## Anti-goals

- A preview that disagrees with the real plate. If it places or sizes a part by
  its own sums, it will drift the first time the real code changes. It places
  through the same functions (`UF:UpdateElement`, `UF:UpdateElementPosition`,
  `UF:ElementSize`, `UF:UpdateText`, `UF:GetFrame`) wherever they can take a
  plain frame.
- Settings pages that jump or reflow while dragging a slider.

## Constraints

- Real plate auras come from Blizzard's CustomAuraContainer
  (`elements/auras.lua`, `unitframe:CreateAuras()`), which only shows real
  auras and whose buttons are restricted (taint rule 11). The preview's aura
  areas are SaftUI-drawn icons styled like the real buttons (`StyleButton`'s
  look: icon skin, border, count, timer text where enabled) and laid out by the
  area's config (size, max, per row, spacing, growth, initial anchor).
- Core cannot depend on Unitframes. The window gets a generic "band" a pick can
  ask for; Unitframes supplies what is drawn in it.
- The options window has three sizes. At half (body 368 or 388 wide) the
  default plate's row (quest icon 22 + bar 200 + buffs 104 = 326) fits; wider
  layouts are clipped at the band's edges, not allowed to push the page.
- WoW Forever and retail both.

## Approaches

1. **A fixed band between the picker line and the settings (taken).** The
   window draws a band of a height the pick asks for under the Unit picker line
   and puts the body under it (`DrawPage` in `optionswindow.lua`:
   `DrawPickerControl` returns the line's bottom, then `PlaceBody(bottom)`). The
   band never scrolls. Costs a small, generic addition to the window and about
   130 pixels of the settings' height on the two plate pages.
2. **The first row of the page's settings.** A bare custom row (`W.Define`) in
   the pick's own options, which the body draws first on every tab. Uses only
   what the kit has, but scrolls away with the settings, so it is out of sight
   on long tabs exactly when a setting is being changed. Rejected for that.
3. **Docked beside `/sui`.** Offered first; the owner preferred the top of the
   page.

## Design

### The window's band (Core)

- A pick's group may carry `pickerBand` (SaftUI's field, read raw, never in
  `args`, like `pickerControl`): `{ height = function(width) -> n, draw =
  function(holder, width, height), release = function(holder) }`.
  `OM.BuildView` hands the picked group's on as `view.picker.band`.
- `DrawPage`: after the picker line, when `view.picker.band` exists, a holder
  frame (one, the window's own, `F.band`) is placed at the line's bottom plus a
  gap, the body's width wide and `height(width)` tall (whole pixels), `draw` is
  called, and the body is placed under the holder. Search results, pages and
  picks without one draw none; a page change or pick change calls `release`
  and hides the holder.
- The holder clips its children (`SetClipsChildren(true)`), so a part placed far
  off the plate is cut at the band's edge and never draws over the tabs or the
  settings.
- It is drawn on every tab of the pick and at every window size; a window
  resize draws the page again (it already does), so `draw` gets the new width.
- Under Thick and Thin the band sits on a panel like a section's
  (`OB.PANEL_FILL`) so it reads as part of the page; under Blizzard on the
  page's own background. Builder's call on the exact look, within the kit's
  existing tokens.

### The preview plate (Unitframes)

- New file `SaftUI-Unitframes/nameplates/preview.lua` (loaded after the other
  plate files). It builds one preview frame per plate page, lazily, parented to
  the band's holder, centred in it.
- The frame has the fields a real plate's frame has for placing
  (`base_unit`, `config`, `GetConfig`, `TextOverlay`, `isNamePlate = true`,
  `friendly` for the Friendly page, and each part as a named field: `Health`,
  `Castbar`, `Debuffs`, `Buffs`, `QuestIndicator`, `RaidTargetIndicator`,
  `Threat`, `Subtext`, `Name`), so `UF:GetFrame` resolves anchors between parts
  exactly as on a plate, and `UF:UpdateElement` sizes, themes and places each
  part.
- Which config: the page's own, or the source page's while its box is checked
  (`UF.PlateConfigKey`), since that is what real plates of that kind draw from.
  Threat always reads the Enemy page's threat, and is drawn on the Enemy page's
  preview only (`UF.PLATE_ENEMY_ONLY`), as on a friendly real plate.
- A part shows when `UF:ElementWanted` says so for the preview frame: off in
  settings means hidden in the preview, so toggling a part on or off shows.
  Situational parts show whenever they are on: the castbar is mid-cast, threat
  shows solo as well, the raid mark and quest icon are always set.
- Sample data (made up, fixed):
  - Enemy page: a hostile NPC, "Thornfang Ravager", health at 72%, max 250,000
    (so the short value reads 180K), castbar "Shadow Bolt" at 60% with its icon,
    interruptible (the cast colour; the not-interruptible grey is not shown),
    time text "1.2" if Time is on, threat "87%", subtext "<Pack Leader>" when the
    page's NPC box is on, raid mark skull, quest icon.
  - Friendly page: a friendly player of the player's own class, "Aldric", health at
    full, subtext "<Emerald Wardens>" when the page's Player box is on; castbar
    "Flash Heal"; no threat.
  - Debuffs: up to Max of six fixed spell icons with mixed sample stacks and
    remaining times (some with a stack count, one of each dispel type when the
    area colours by type), cooldown swipe frozen part way, timer text only when
    the area's timer is on.
  - Buffs: up to Max of four purgeable-looking (Magic) buffs, stealable border
    where the area colours stealable.
  - Texts use the real formatters where they exist (health text's short or
    percent, `UF.ShortNumber`; the name's level and classification options,
    `color_hostile`).
- Bars and texts are coloured as a real plate of that kind would be (reaction
  colour for a hostile NPC, class colour for a friendly player where the bar
  colours by class), through the same colour helpers as `grouppreview.lua`.
- The plate wears neither the target nor the hover border.

### Keeping it current

- The band's `draw` runs on every render of the page, and every setting change
  that isn't a slider drag renders the page (`Changed` -> `OW:Render()` ->
  `DrawPage`). So the preview redraws from the page itself, not from
  `UF:UpdateConfig`, which waits for the end of combat: a change made in combat
  shows on the preview at once, as out of combat (the preview is plain
  frames). **Builder's call made by the designer.**
- A slider drag skips the render and calls `body:Refresh` instead. The band gets
  the same refresh (`pickerBand.refresh(holder)`, called from the window's
  drag path), so the plate follows the slider while it moves.
- Global restyles that don't render the page (a theme recolor, a profile switch
  while `/sui` is open) redraw it through the window's own follow-up render;
  where one doesn't, the preview listens to the same signal the options window
  does.
- While the window is closed, or another page is shown, the preview is hidden
  and does no work.

### What the preview reuses, and what it copies

**Designer's call:** reuse the real code where it takes a plain frame, and
lift small pure helpers out of the element files where a preview needs the
same answer, without changing what real plates do:

- Reused as is: `UF:UpdateElement` (size, theme, place, level, status bar,
  font, texts, icons) and each element's own `UpdateConfig` where it takes a
  plain frame (castbar colours, subtext colour, the quest and raid icons, the
  health bar's colour flags).
- Lifted into exported pure functions, called by both the real code and the
  preview: the name's level and classification text and its hostile colour
  (today file-local in `tags.lua`, reading a unit token), and the health text's
  value formatting (inside `PostUpdateHealth`). The real paths keep their unit
  reads and secret-value checks and pass plain values to the helper. Existing
  plate tests must pass unchanged.
- Copied, since the real one can't run on a plain frame: the aura areas (the
  real constructor makes Blizzard's container) and the name's text (oUF's
  `Tag`). The aura icons' look calls the same styling where it can
  (`StyleButton`'s pieces) and the layout follows the area's config; the
  copy's sums are covered by a test that compares it to the config's
  documented layout (6 x 20 + 5 x 6 = 150 for the default debuffs).

### Threat

**Designer's call:** the sample is untinted: the health bar keeps its
reaction colour and the threat text reads "87%" in its normal text colour.
Showing a tint would hide the reaction colour, which is the more common state
to judge. (A followup can add a tinted state if wanted.)

### Edge cases

- Another nameplate addon draws the plates (`UF:NameplateAddon`): the pages are
  disabled and stand down; no band is drawn.
- The plate is wider than the band (big Width, buffs to the right): clipped at
  the band's edges. Centring is on the health bar's frame, so the bar stays in
  view.
- Height of the band: from the preview's extent by the config (the lowest and
  highest edges of the parts that show), plus a margin, between a minimum (the
  default layout's, about 130) and a maximum (about 200), so moving a part a
  little doesn't make the page jump. **Designer's call:** the height is
  measured when the page, tab, pick or window size changes, and kept through
  the renders in between, so a toggle or a drag never moves the settings under
  the cursor. A part moved past the band's edge is clipped until the next of
  those.
- In combat: plain frames, nothing restricted, works as out of combat.

## Tests (Lua, `tests/`)

- Core: a pick with `pickerBand` gets a band at the picker line's bottom, the
  body moves down by its height; a pick without one, search results and a page
  change draw none and release it; the band is redrawn at the new width on a
  resize.
- Unitframes: the preview frame's parts are placed by the page's config through
  the real updaters (an anchor change on the page moves the part on the
  preview); a part turned off hides; Friendly page shows no threat; the source
  page's config is used while the page's box is checked; Max debuffs gives
  that many icons laid out by per row, spacing and growth; a config update
  redraws the preview.

## Left to the builder

- The band's look under each theme (within the kit's tokens) and its gap to
  the picker line.
- The exact band height rule within the limits above.
- Sample spell icons (any icon file IDs both clients have).
