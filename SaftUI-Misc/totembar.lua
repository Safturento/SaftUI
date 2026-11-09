local st = SaftUI
local TB = st:NewModule('TotemBar')

--[[
	/sui options to hide WoW Forever's totem bar, MultiCastActionBarFrame
	(Blizzard_ActionBar/Shared/MultiCastActionBarFrame.xml), and to size and space its
	buttons. Blizzard_ActionBar loads it only for the camelot, wrath and cata game types, so
	retail has no totem bar: nothing here runs there and the /sui section doesn't appear.

	What Blizzard does with the bar:
	  - Shows and hides it in TotemActionBarMixin:UpdateShownState, through the bar's
	    Edit Mode SetShown override. It's shown while a totem slot has spells
	    (numActiveSlots, counted on PLAYER_ENTERING_WORLD and UPDATE_MULTI_CAST_ACTIONBAR)
	    or Edit Mode's Totem Bar checkbox is on, and only while no vehicle or override bar
	    replaces the main action bar (the ActionBarController.MainActionBarStateOverridden
	    callback). That callback runs on every action bar page, bonus bar and vehicle
	    change, so Blizzard re-shows the bar often.
	  - Places it through Blizzard's Edit Mode. It isn't a managed frame. In its default
	    position it's the last of the bottom action bars (Camelot EditModeUtil's
	    GetBottomActionBars), and EditModeManagerFrame:UpdateBottomActionBarPositions
	    re-anchors it above the bars stacked on MainActionBar. That also runs in combat:
	    on each action bar's combat visibility update, when the pet, stance or possess
	    bar or the vehicle leave button shows or hides, and when the XP bars change.
	  - Its buttons are secure action buttons (ActionBarButtonTemplate, and
	    SecureFrameTemplate for the summon and recall buttons), so the bar is
	    protected. Addon code can't show, hide, reparent or move it in combat.

	Hiding parents the bar to a hidden SaftUI frame, out of combat. Blizzard keeps
	showing, hiding and placing the bar as before. Its show and hide calls only change
	the bar's own shown flag, and under a hidden parent the bar never becomes visible.
	So it never flashes, and its buttons' OnShow/OnHide scripts don't run. Nothing of
	Blizzard's reparents this bar (Blizzard's Edit Mode only reparents managed frames
	and the cast bar), so it stays under the hidden frame. Turning the option off puts
	the bar back under its old parent and leaves the shown flag alone. It shows again
	only if Blizzard wants it shown, e.g. not on a character with no totems.

	A state driver (RegisterStateDriver(bar, 'visibility', 'hide')) would have hidden it
	by calling the bar's Hide every 0.2s. After each of Blizzard's re-shows the bar would
	be on screen until the next tick. Turning the option off would also need a Show,
	which overrides Blizzard's own rules for when the bar shows.

	Position. On a shaman SaftUI moves the bar in its own edit mode, the way it moves the
	default tooltip's container (tooltipposition.lua):
	  - A holder of SaftUI's (SaftUITotemBarHolder) is the edit mode mover and the /sui
	    Position. It's placed from the profile's position and is always the bar's size
	    (TB:ApplyButtonLayout sizes both).
	  - The bar is put where the holder is: its bottom-left corner on UIParent's, at the
	    holder's left and bottom in whole pixels (TB:AnchorBar), with the plain widget
	    methods (st:ClearAllPointsDirect, st:SetPointDirect). The bar's own SetPoint and
	    ClearAllPoints are Blizzard's Edit Mode overrides, which write Edit Mode state.
	    It's put there again whenever the holder is placed (a post-hook on the holder's
	    SetPoint: a drag, a nudge, /sui, a profile change) or resized (the button
	    layout), out of combat only.
	  - The bar is never anchored to the holder itself, because Blizzard's Edit Mode
	    reads its anchor. The bar is snapped to MainActionBar in its default position
	    (SetPointOverride's SetSnappedToFrame). When MainActionBar hides, e.g. entering a
	    vehicle out of combat, BreakSnappedFrames runs the bar's BreakFrameSnap, which
	    re-anchors it (the post-hooks below put it back) and then reads GetPoint(1) in
	    UpdateSystemAnchorInfo, into the active layout, which a later save keeps.
	    Anchored to the holder, the layout would name SaftUITotemBarHolder, and on an alt
	    without the holder (another class, SaftUI-Misc off) Blizzard would anchor the
	    bar to a frame that isn't there. On UIParent, Blizzard records the spot the bar
	    is at, as it would for any snap break.
	  - Blizzard re-places the bar when an Edit Mode layout loads, and in its default
	    position from UpdateBottomActionBarPositions (see above), in combat too.
	    Post-hooks on the bar's ClearAllPoints and SetPoint put it back at the holder's
	    spot: straight away, or at the end of combat if it's on, as the bar is protected.
	    SaftUI never changes the bar's Edit Mode position, so these re-places keep coming,
	    until Blizzard itself records a spot for it after a snap break (above), which
	    stops UpdateBottomActionBarPositions from stacking it.
	  - So the buttons don't go with the bar when Blizzard re-places it mid-fight, they're
	    anchored to the holder, not to the bar, as SaftUI-ActionBars/extras.lua does with
	    the extra action button. Blizzard's bar frame then sits at Blizzard's spot until
	    combat ends, empty. Its XML makes it take the mouse though it has nothing to
	    click, so it's made click-through, and it can't catch clicks meant for what's
	    under it there.
	  - Blizzard's Edit Mode box for the bar (its Selection) is kept hidden, so Blizzard's
	    Edit Mode can't move it any more. Blizzard's Totem Bar checkbox still shows the bar
	    while Blizzard's Edit Mode is open. The bar has no other Edit Mode settings.
	  - First load moves nothing. totembar.position has no default: AceDB fills in
	    defaults, so a default couldn't be told apart from a position the user set. A
	    profile with no position takes the bar's spot on screen once Blizzard has placed
	    it, out of combat (TB:CapturePosition), and that's saved. Until then the bar
	    stays Blizzard's, with its buttons on it, and the holder waits in the middle of
	    the screen, unsaved, until it's captured or moved. On a profile change, a profile
	    with no position keeps the holder's spot from the profile before
	    (TB:KeepPlacement), so switching profiles moves nothing either.
	  - Only a shaman has totems, so only a shaman gets the holder, the mover and the
	    hooks. On every other class the bar stays where Blizzard puts it, as before.
	The trade-off is the one that kept SaftUI from moving the bar before: in Blizzard's
	default position Blizzard re-anchors it in combat, and a protected bar can't be put
	back until combat ends. With the buttons on the holder only Blizzard's empty frame
	moves, except as said below for Blizzard's own button update in combat.

	SaftUI writes nothing onto the bar or any Blizzard table, except that hooksecurefunc
	replaces the two methods it hooks on the bar (ClearAllPoints and SetPoint) with its own
	secure wrappers. Blizzard's Edit Mode can write the bar's UIParent anchor into its own
	layout after a snap break (above); that's Blizzard's code, and no SaftUI frame is in it.
	SaftUI's calls on the bar are GetParent, GetFrameLevel, GetPoint,
	GetRect, GetEffectiveScale, IsShown, IsVisible, SetParent, SetFrameLevel, and SetSize,
	ClearAllPoints, SetPoint and EnableMouse through the plain widget methods
	(st:SetSizeDirect and the like; the bar's Edit Mode overrides are SetScale, SetPoint,
	ClearAllPoints, SetShown and Hide), and HookScript for its OnShow. It reads, never
	writes, the bar's systemInfo (its Edit Mode layout entry).

	The buttons' size and the gap between them are settings (button_size, button_spacing),
	laid out by TB:ApplyButtonLayout. Blizzard's XML makes every button 30px, puts the
	first one 3 in from the bar's bottom-left corner and the rest 3 or 8 apart, in a 230x38
	bar. SaftUI keeps that 3px margin and puts one gap between all neighbouring buttons:
	  - The summon button in the corner, then the element buttons, then the recall button
	    after the last element shown. Blizzard hides the summon button without a summon
	    spell, and the elements then start in the corner.
	  - Each element is a slot button with an action button on it per summon page
	    (totemskin.lua). Each page's four action buttons sit in a page frame. The pages go
	    where the first slot button goes, a row of buttons wide and a button tall, and
	    their buttons chain the same way, so every page lines up with the slot buttons.
	  - The corner is the holder's once SaftUI places the bar (a shaman's profile has a
	    position), and the bar's otherwise. Only the summon button, the first slot button
	    and the pages are anchored to it. The other slot buttons chain from the first, the
	    recall button from the last one shown, and each page's buttons from their page.
	  - The bar, and the holder with it, are sized to hold the summon button, four
	    elements and the recall button (margin + buttons + gaps + margin), whichever show,
	    as Blizzard's 230x38 holds them all, so the holder's edit mode outline is on the
	    buttons. Edit Mode never sizes the bar. A new size keeps the holder's anchor point
	    where it is: the bottom-left corner for a bar captured in Blizzard's default
	    position, so the first button stays put, or the centre or an edge for an anchor
	    Blizzard's Edit Mode had saved, so the buttons move around it, as resizing any
	    Edit Mode frame would. On other classes the bar keeps Blizzard's anchor, which
	    works the same way: in its default position UpdateBottomActionBarPositions anchors
	    the bar's bottom-left corner above the bars stacked on MainActionBar. The stack
	    reads each bar's height for the next bar up, and the totem bar is the last one.
	    With Camelot's stacking from MainActionBar (ACTION_BARS_RELATIVE_TO_BASE_POSITIONING)
	    it doesn't read the bars' widths.
	  - The bar's width and height are always rounded up to an even number of pixels.
	    Anchored by its centre on an axis (the holder's position or Edit Mode's anchor can
	    be BOTTOM, TOP or CENTER), an odd length would put its edges, and every button, on
	    half pixels (.agents/architecture.md). So the bar and the holder are even whatever
	    the anchor. The spare pixel is empty bar at the right or the top.
	Blizzard re-anchors some of these in MultiCastActionBarFrame_Update, on
	PLAYER_ENTERING_WORLD, UPDATE_MULTI_CAST_ACTIONBAR and a summon page change, in combat
	too:
	  - MultiCastSummonSpellButton_Update puts the pages and the first slot button 8 after
	    the summon button, or in the corner while it's hidden. Its corner is always the
	    bar's: it anchors them to their parent.
	  - MultiCastRecallSpellButton_Update puts the recall button 8 after the last shown slot
	    button.
	Post-hooks on both put SaftUI's layout back. Everything it sizes and moves is
	protected: the summon, recall and action buttons are secure, the slot buttons are
	protected through the recall button's anchor (.agents/taint.md rule 6), the pages and
	the bar hold secure buttons, and the holder has the buttons anchored to it.
	So in combat the layout waits for the end of combat, and a fight that runs Blizzard's
	update (a summon page change does) shows Blizzard's 8 after the summon button and
	before the recall button until it ends. The sizes and the gaps between elements stay
	SaftUI's, as Blizzard never sets them, and the pages move with the first slot button,
	so they still line up. If Blizzard has also re-placed its bar in that fight, the first
	slot button and the pages, and everything chained from them, go to the bar at
	Blizzard's spot until the fight ends, while the summon button stays on the holder.
	SaftUI anchors these by the points Blizzard re-sets (BOTTOMLEFT for the pages and the
	first slot button, LEFT for the recall button), so Blizzard's SetPoint replaces
	SaftUI's anchor instead of adding a second one that would pull against it.

	SaftUI's look for the bar's buttons and its flyout is in totemskin.lua, and the totem
	timers above its element buttons are in totemtimers.lua. The flyout's choices follow the
	button size (totemskin.lua), and the timers follow the slot buttons' width.
]]

-- Puts the bar under the hidden frame, or back under the parent it had, as the
-- profile says. The bar is protected, so in combat this waits for the end of combat
-- and then reads the profile again.
function TB:Apply()
	local bar, hider = self.bar, self.hider
	if not bar then return end
	if st:QueueAfterCombat('totembar', function() self:Apply() end) then return end

	-- Only reparent when it doesn't change whether the bar is on screen. If it did,
	-- the secure buttons' OnHide/OnShow would run from SaftUI's call chain and can
	-- leave tainted state in Blizzard's shared action button code (an
	-- ADDON_ACTION_BLOCKED later, e.g. entering a vehicle in combat). At login the bar
	-- is still hidden, so a reload always applies the setting cleanly.
	if self.config.hide then
		if bar:GetParent() ~= hider then
			if bar:IsVisible() then
				st:Print('The totem bar will be hidden after a /reload.')
				return
			end
			self.oldParent, self.oldLevel = bar:GetParent(), bar:GetFrameLevel()
			bar:SetParent(hider)
		end
	elseif bar:GetParent() == hider then
		if bar:IsShown() then
			st:Print('The totem bar will show again after a /reload.')
			return
		end
		bar:SetParent(self.oldParent or UIParent)
		-- SetParent can renumber the bar's frame level, so put back the one it had.
		if self.oldLevel then bar:SetFrameLevel(self.oldLevel) end
	end
end

------------------------------------
--- Button layout -------------------
------------------------------------

-- Blizzard's margin between the bar's edges and its buttons: its XML puts the first
-- button 3 in from the bar's bottom-left corner.
local MARGIN = 3

-- Blizzard's button size, which the buttons have until SaftUI first lays them out.
local BLIZZARD_BUTTON_SIZE = 30

-- Blizzard's frames the layout sizes and places, collected once by TB:SetupButtonLayout:
-- { summon, recall, slots = { MultiCastSlotButton1-4 }, pages = { { frame, buttons } } },
-- a page being a MultiCastActionPage and its four MultiCastActionButtons. A SaftUI table,
-- so nothing is written onto Blizzard's frames. nil until the layout is set up.
local layout

-- The button size last laid out. The timers' text is centred from the slot buttons'
-- width, and the cooldown numbers' font depends on the size (totemskin.lua), so both are
-- refreshed when it changes.
local laidOutSize = BLIZZARD_BUTTON_SIZE

-- The frame the buttons were last laid out on (TB:LayoutBase): the holder or the bar.
-- When SaftUI first places the bar, the buttons move from the bar to the holder.
local laidOutOn

-- A length of the bar rounded up to an even number of pixels, counted as
-- SaftUI-ActionBars/bars.lua's EvenIfCentred counts them, in case the UI scale doesn't make
-- one unit one pixel. Unlike EvenIfCentred it doesn't look at the anchor, which can be
-- Edit Mode's (see the top of this file).
local function EvenPixels(length, frame)
	local pixel = st:GetPixelSize(frame)
	if not pixel then return length end
	if math.floor(length / pixel + 0.5) % 2 == 0 then return length end
	return st:RoundToPixel(length + pixel, frame)
end

-- The bar's width and height for the profile's button size and spacing, which the holder
-- has too: room for the summon button, four elements and the recall button, with the
-- margin around them (see the top of this file).
local function BarSize(config, bar)
	local size, spacing = config.button_size, config.button_spacing
	local numSlots = NUM_MULTI_CAST_BUTTONS_PER_PAGE or 4
	return EvenPixels(2 * MARGIN + (numSlots + 2) * size + (numSlots + 1) * spacing, bar),
		EvenPixels(2 * MARGIN + size, bar)
end

-- The frame whose bottom-left corner the buttons are laid out from: the holder once
-- SaftUI places the bar (on a shaman, once the profile has a position), the bar until
-- then and on every other class.
function TB:LayoutBase()
	if self.holder and self.config.position then return self.holder end
	return self.bar
end

-- Sizes a row of buttons and anchors each one after the one before it, spacing apart,
-- LEFT to RIGHT as Blizzard chains them. The caller places the first one.
local function ChainRow(buttons, size, spacing)
	for i, button in ipairs(buttons) do
		button:SetSize(size, size)
		if i > 1 then
			button:ClearAllPoints()
			button:SetPoint('LEFT', buttons[i - 1], 'RIGHT', spacing, 0)
		end
	end
end

-- Lays the bar's buttons out from the profile (see the top of this file): their size,
-- one gap between neighbours, and the bar's and the holder's size around them. Out of
-- combat only, as all of it is protected: in combat this waits for the end of combat,
-- then reads the profile and Blizzard's buttons again.
function TB:ApplyButtonLayout()
	local bar = self.bar
	if not (bar and layout) then return end
	if st:QueueAfterCombat('totembar_layout', function() self:ApplyButtonLayout() end) then return end

	local size, spacing = self.config.button_size, self.config.button_spacing
	local slots = layout.slots
	local numSlots = #slots
	local base = self:LayoutBase()

	-- The holder always has the bar's size, so the bar at its spot covers it exactly and
	-- its outline is on the buttons.
	local width, height = BarSize(self.config, bar)
	st:SetSizeDirect(bar, width, height)
	if self.holder then self.holder:SetSize(width, height) end

	local summon = layout.summon
	summon:SetSize(size, size)
	summon:ClearAllPoints()
	summon:SetPoint('BOTTOMLEFT', base, 'BOTTOMLEFT', MARGIN, MARGIN)

	-- The elements start after the summon button, or in its place while Blizzard hides it.
	local x = summon:IsShown() and MARGIN + size + spacing or MARGIN

	ChainRow(slots, size, spacing)
	slots[1]:ClearAllPoints()
	slots[1]:SetPoint('BOTTOMLEFT', base, 'BOTTOMLEFT', x, MARGIN)

	-- Blizzard anchors each page's first button by its LEFT, so with the page a button
	-- tall the row's bottom is the page's.
	for _, page in ipairs(layout.pages) do
		local frame, buttons = page.frame, page.buttons
		frame:SetSize(numSlots * size + (numSlots - 1) * spacing, size)
		frame:ClearAllPoints()
		frame:SetPoint('BOTTOMLEFT', base, 'BOTTOMLEFT', x, MARGIN)
		ChainRow(buttons, size, spacing)
		buttons[1]:ClearAllPoints()
		buttons[1]:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	end

	-- After the last element shown, as Blizzard does: it shows the first
	-- numActiveSlots slot buttons and hides the rest. With none shown, Blizzard hides the
	-- recall button too, and it goes after the first slot button.
	local last = slots[1]
	for _, slot in ipairs(slots) do
		if slot:IsShown() then last = slot end
	end
	local recall = layout.recall
	recall:SetSize(size, size)
	recall:ClearAllPoints()
	recall:SetPoint('LEFT', last, 'RIGHT', spacing, 0)
	laidOutOn = base

	-- A holder anchored by its centre or an edge moves its bottom-left corner when it's
	-- resized, so the bar goes to its spot again.
	self:AnchorBar()

	if size ~= laidOutSize then
		laidOutSize = size
		self:ApplySkin()
		self:ApplyTimerLayout()
	end
end

-- Collects the frames the layout places, hooks Blizzard's updates that re-anchor them,
-- and lays them out. Once, out of combat, as the layout sizes and moves protected frames:
-- after a /reload in combat the buttons keep Blizzard's layout until the end of combat. Not
-- set up if any of Blizzard's frames is missing.
function TB:SetupButtonLayout()
	if layout then return end
	if st:QueueAfterCombat('totembar_layout_setup', function() self:SetupButtonLayout() end) then return end

	local perPage = NUM_MULTI_CAST_BUTTONS_PER_PAGE or 4
	local frames = {
		summon = _G.MultiCastSummonSpellButton,
		recall = _G.MultiCastRecallSpellButton,
		slots = {},
		pages = {},
	}
	if not (frames.summon and frames.recall) then return end
	for i = 1, perPage do
		local slot = _G['MultiCastSlotButton' .. i]
		if not slot then return end
		frames.slots[i] = slot
	end
	for p = 1, NUM_MULTI_CAST_PAGES or 3 do
		local page = { frame = _G['MultiCastActionPage' .. p], buttons = {} }
		if not page.frame then return end
		for i = 1, perPage do
			local button = _G['MultiCastActionButton' .. ((p - 1) * perPage + i)]
			if not button then return end
			page.buttons[i] = button
		end
		frames.pages[p] = page
	end
	layout = frames

	local function Reapply() self:ApplyButtonLayout() end
	TB.PostHook('MultiCastSummonSpellButton_Update', Reapply)
	TB.PostHook('MultiCastRecallSpellButton_Update', Reapply)

	self:ApplyButtonLayout()
end

------------------------------------
--- Position ------------------------
------------------------------------

-- Where the holder waits while the profile has no position and Blizzard hasn't placed
-- the bar yet (see the top of this file): the middle of the screen. Never saved by
-- itself; moving the holder from here saves it with the move.
local WAITING_POSITION = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 }

-- A copy of the position the holder was last placed from, kept across profile changes
-- for TB:KeepPlacement. nil until a profile's position first places it.
local placedAt

-- How far across and up a frame each anchor point is.
local POINT_X = {
	TOPLEFT = 0, LEFT = 0, BOTTOMLEFT = 0,
	TOP = 0.5, CENTER = 0.5, BOTTOM = 0.5,
	TOPRIGHT = 1, RIGHT = 1, BOTTOMRIGHT = 1,
}
local POINT_Y = {
	BOTTOMLEFT = 0, BOTTOM = 0, BOTTOMRIGHT = 0,
	LEFT = 0.5, CENTER = 0.5, RIGHT = 0.5,
	TOPLEFT = 1, TOP = 1, TOPRIGHT = 1,
}

-- Where one of a frame's anchor points is on screen, in UIParent's units, or nil while
-- the frame has no place.
local function PointPosition(frame, point)
	local left, bottom, width, height = frame:GetRect()
	if not (left and bottom and width and height) then return end
	local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
	return (left + width * POINT_X[point]) * scale, (bottom + height * POINT_Y[point]) * scale
end

local function CopyPosition(position)
	local copy = {}
	for key, value in pairs(position) do copy[key] = value end
	return copy
end

-- The holder's position: the profile's, or a new copy of the waiting spot while the
-- profile has none. The edit mode mover and /sui Position change the table this hands
-- them and save it, so a first move from the waiting spot saves a position.
function TB:GetPosition()
	return self.config.position or CopyPosition(WAITING_POSITION)
end

-- A profile with no position (a new or reset one) keeps the spot the holder was last
-- placed at by another profile, so switching profiles doesn't move the bar. The bar is
-- at the holder's spot then, so there's nothing to read from Blizzard. Safe in combat: it
-- only writes the profile.
function TB:KeepPlacement()
	if self.holder and not self.config.position and placedAt then
		self.config.position = CopyPosition(placedAt)
	end
end

-- Saves the bar's spot on screen as the profile's position, if Blizzard has placed it,
-- and returns whether it did. The bar is placed once Blizzard's Edit Mode has applied its
-- layout to it (EditModeSystemMixin:UpdateSystem sets its systemInfo) and, in Blizzard's
-- default position, once it shows: until then Blizzard leaves it at UIParent's top-left
-- corner (ApplySystemAnchor), as UpdateBottomActionBarPositions only stacks shown bars.
-- The position keeps the bar's own anchor point, moved onto UIParent's same point, so the
-- holder grows from where the bar grew (see the top of this file). Called out of combat,
-- from outside Blizzard's re-places (TB:QueueCapture), so the bar is where Blizzard left it.
function TB:CapturePosition()
	local bar = self.bar
	local info = bar.systemInfo
	if not info then return false end
	if info.isInDefaultPosition and not bar:IsShown() then return false end

	local point = bar:GetPoint(1)
	if not POINT_X[point] then point = 'BOTTOMLEFT' end
	local x, y = PointPosition(bar, point)
	local parentX, parentY = PointPosition(UIParent, point)
	if not (x and parentX) then return false end

	self.config.position = {
		point = point,
		frame = 'UIParent',
		rel_point = point,
		x_off = st:RoundToPixel(x - parentX, self.holder),
		y_off = st:RoundToPixel(y - parentY, self.holder),
	}
	return true
end

-- Captures the bar's spot, if the profile has no position, and places the holder there.
-- Out of combat only, as placing the holder moves the protected bar to its spot: in combat
-- this waits for the end of combat and tries again then.
function TB:TryCapture()
	if self.config.position then return end
	if st:QueueAfterCombat('totembar_capture', function() self:TryCapture() end) then return end
	if self:CapturePosition() then self:ApplyHolder() end
end

-- Tries the capture on the next frame, once however often it's asked for in one frame.
-- It's asked for from post-hooks on Blizzard's own re-places, where the bar can be
-- between two of Blizzard's anchors: an Edit Mode layout load first puts every frame at
-- UIParent's top-left corner, then where the layout says. By the next frame Blizzard is
-- done.
local captureQueued = false
function TB:QueueCapture()
	if captureQueued or not self.holder or self.config.position then return end
	captureQueued = true
	C_Timer.After(0, function()
		captureQueued = false
		self:TryCapture()
	end)
end

-- Puts Blizzard's bar where the holder is: its bottom-left corner on UIParent's, at the
-- holder's left and bottom, in whole pixels. They're the same size (TB:ApplyButtonLayout),
-- so the bar covers the holder exactly. Never anchored to the holder itself, as Blizzard's
-- Edit Mode can record the bar's anchor into its layout (see the top of this file). Plain
-- widget methods, as the bar's own are Edit Mode's overrides; they don't run the
-- post-hooks below either. The bar is protected, so in combat this waits for the end of
-- combat. A holder with no place yet (between ClearAllPoints and SetPoint on a profile
-- change) leaves the bar where it is: placing the holder calls this again.
function TB:AnchorBar()
	local bar, holder = self.bar, self.holder
	if not (holder and self.config.position) then return end
	if st:QueueAfterCombat('totembar_anchor', function() self:AnchorBar() end) then return end
	local left, bottom = holder:GetLeft(), holder:GetBottom()
	if not (left and bottom) then return end
	local scale = holder:GetEffectiveScale() / bar:GetEffectiveScale()
	st:ClearAllPointsDirect(bar)
	st:SetPointDirect(bar, 'BOTTOMLEFT', UIParent, 'BOTTOMLEFT',
		st:RoundToPixel(left * scale, bar), st:RoundToPixel(bottom * scale, bar))
end

-- Sizes and places the holder from the profile, then puts the bar at its spot and lays
-- the buttons out on it, the first time it's placed from a position. The edit mode mover's
-- apply, so it runs at the end of every drag and on every nudge. The holder is protected
-- once the buttons are anchored to it, so in combat it's placed at the end of combat.
-- Placing it puts the bar at its spot through the holder's SetPoint hook (TB:SetupPosition);
-- AnchorBar here covers a holder that was already where the position says.
function TB:ApplyHolder()
	local holder = self.holder
	if not holder then return end
	self:KeepPlacement()

	st:SafeReposition(holder, 'totembar_holder', function()
		holder:SetSize(BarSize(self.config, self.bar))
		local point, relative, rel_point, x, y = st:UnpackPoint(self:GetPosition())
		holder:ClearAllPoints()
		holder:SetPoint(point, st:ResolveFrame(relative) or UIParent, rel_point,
			st:RoundToPixel(x, holder), st:RoundToPixel(y, holder))
	end)

	local position = self.config.position
	if not position then return end
	placedAt = CopyPosition(position)
	self:AnchorBar()
	if laidOutOn ~= holder then self:ApplyButtonLayout() end
end

-- Blizzard's bar takes the mouse (enableMouse in its XML) but has nothing of its own to
-- click. Made click-through, with the plain widget method, so while Blizzard has it
-- somewhere else in combat it can't catch clicks or hovers meant for what's under it
-- there. Protected on a protected frame, so out of combat only.
function TB:DisableBarMouse()
	if st:QueueAfterCombat('totembar_mouse', function() self:DisableBarMouse() end) then return end
	getmetatable(self.bar).__index.EnableMouse(self.bar, false)
end

-- The holder's hooks and mover, on a shaman (see the top of this file). Once. After a
-- /reload in combat the holder is still placed straight away, as nothing is anchored to it
-- yet (the button layout waits for the end of combat), so it isn't protected. The bar and
-- its mouse wait for the end of combat.
function TB:SetupPosition()
	local bar, holder = self.bar, self.holder
	if not holder then return end

	-- Every placement of the holder (ApplyHolder, and a drag, which calls its SetPoint) puts
	-- the bar at its new spot. ClearAllPoints needs no hook: SetPoint follows it.
	hooksecurefunc(holder, 'SetPoint', function() self:AnchorBar() end)

	-- Blizzard's Edit Mode places the bar through these on every layout load, and in its
	-- default position on every bottom bar update, and after a snap break. Put it back at
	-- the holder's spot after each, or, while the profile has no position, take its new
	-- spot once Blizzard is done.
	local function PutBack()
		if self.config.position then
			self:AnchorBar()
		else
			self:QueueCapture()
		end
	end
	hooksecurefunc(bar, 'ClearAllPoints', PutBack)
	hooksecurefunc(bar, 'SetPoint', PutBack)

	-- Blizzard's Edit Mode box for the bar. Not secure, so hiding it is safe in combat.
	local selection = bar.Selection
	if selection then
		selection:HookScript('OnShow', function(box) box:Hide() end)
		selection:Hide()
	end

	self:DisableBarMouse()

	-- A shaman whose bar is hidden at login (no totems yet, or in a vehicle) gets it
	-- placed by Blizzard later, through the hooks above. A bar moved in Blizzard's Edit
	-- Mode isn't re-placed when it shows, so its showing tries too (the capture waits for
	-- it, if it can't read the hidden bar's spot). PLAYER_ENTERING_WORLD also tries, after
	-- every loading screen. On the holder: totemtimers.lua has TB's own
	-- PLAYER_ENTERING_WORLD, and AceEvent keeps one handler per event. Each is a no-op once
	-- the profile has a position.
	bar:HookScript('OnShow', function() self:QueueCapture() end)
	holder:RegisterEvent('PLAYER_ENTERING_WORLD')
	holder:SetScript('OnEvent', function() self:QueueCapture() end)

	self:ApplyHolder()
	self:QueueCapture()

	st:RegisterMover('totembar', {
		frame = holder,
		label = 'Totem Bar',
		getPosition = function() return self:GetPosition() end,
		setPosition = function(position) self.config.position = position end,
		apply = function() self:ApplyHolder() end,
		configPath = { 'TotemBar', 'general' },
	})
end

-- A profile change. The holder's place is the edit mode's (EM:UpdateConfig runs the
-- mover's apply after this), but a profile with no position keeps the holder's spot
-- before the buttons are laid out, so they stay on the holder.
function TB:UpdateConfig()
	self:KeepPlacement()
	self:Apply()
	self:ApplyButtonLayout()
	self:ApplySkin()
	self:ApplyTimerLayout()
	self:QueueCapture()
end

function TB:Setup()
	if self.bar then return end
	local bar = _G.MultiCastActionBarFrame
	if not bar then return end
	self.bar = bar

	-- Never shown. While the bar is under it, it's protected too, and nothing moves it.
	self.hider = CreateFrame('Frame', nil, UIParent)
	self.hider:Hide()

	-- Only a shaman has totems; on other classes nothing moves the bar (see the top of
	-- this file). Made before the layout, which lays the buttons out on it and sizes it.
	if st.my_class == 'SHAMAN' then
		self.holder = CreateFrame('Frame', st.name .. 'TotemBarHolder', UIParent)
	end

	-- Blizzard first counts the totem slots on PLAYER_ENTERING_WORLD, so at login the
	-- bar is still hidden here and reparenting it runs none of its scripts.
	self:Apply()

	self:SetupSkinAndTimers()
	self:SetupButtonLayout()
	self:SetupPosition()
end

-- The timers above the element buttons (totemtimers.lua) and SaftUI's look for the
-- bar's buttons and its flyout (totemskin.lua). The timers are SaftUI's own frames,
-- anchored to the slot buttons but never moving them, so they're made straight away,
-- in combat too: a /reload mid-fight still shows how long the totems have left. The
-- skin anchors regions of the secure buttons, so after a /reload in combat it waits
-- for the end of combat. The two sets of hooks touch separate things, so their order
-- doesn't matter.
function TB:SetupSkinAndTimers()
	self:SetupTimers()
	if st:QueueAfterCombat('totembar_setup', function() self:SetupSkin() end) then return end
	self:SetupSkin()
end

function TB:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_ActionBar' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

function TB:OnEnable()
	st:BindModuleConfig(self, 'totembar')
	if _G.MultiCastActionBarFrame then
		self:Setup()
	elseif st.forever then
		self:RegisterEvent('ADDON_LOADED')
	end
end

-- The Totem Bar section in the /sui tree. Absent until the bar exists, so never shown
-- on retail. On a shaman it's General (these options, with Position merged in at the end
-- by Config:GetOptionsTable), the leaf group the edit mode mover's configPath opens. On
-- other classes the bar has no mover, and the section is these options alone.
function TB:GetConfigTable()
	if not self.bar then return end

	local hide = st.Config.generators.toggle(1, 'Hide totem bar', 'full')
	hide.desc = "Hides Blizzard's totem bar. Turning this off shows it again whenever Blizzard would show it. If the bar is on screen when you change this, it applies after a /reload."

	-- The bar's buttons (TB:ApplyButtonLayout). /sui doesn't open in combat, so these
	-- always apply straight away.
	local buttonSize = st.Config.generators.range(2, 'Button size', 20, 60, 1)
	buttonSize.desc = "Every button on the bar, its border included. The totem choices that open above a button are 6 smaller, so the flyout is as wide as the button. Blizzard's are 30."
	local buttonSpacing = st.Config.generators.range(3, 'Spacing', 0, 20, 1)
	buttonSpacing.desc = 'The gap between buttons.'

	-- The totem timers above the element buttons (totemtimers.lua).
	local timerBar = st.Config.generators.toggle(4, 'Show timer bar', 'full')
	timerBar.desc = "A bar above each element button that drains, in the element's colour, as that element's totem runs out. It turns red in the last 10 seconds."
	local timerText = st.Config.generators.toggle(5, 'Show timer text', 'full')
	timerText.desc = "How long each element's totem has left, above its button. It turns red in the last 10 seconds."

	-- Text alone sits just above the button either way, so this only matters with both on.
	local timerTextPosition = {
		order = 6,
		name = 'Text position',
		desc = 'Where the time goes while both the bar and the text show: above a thin bar, or on a taller one.',
		type = 'select',
		values = { above = 'Above the bar', on = 'On the bar' },
		sorting = { 'above', 'on' },
		disabled = function() return not (self.config.timer_bar and self.config.timer_text) end,
	}

	-- Offsets for the time, from the spot Text position puts it in.
	local timerTextX = st.Config.generators.range(6.1, 'Text X offset', -20, 20, 1)
	timerTextX.desc = 'Moves the time left or right from the middle of its button, in pixels.'
	timerTextX.disabled = function() return not self.config.timer_text end
	local timerTextY = st.Config.generators.range(6.2, 'Text Y offset', -20, 20, 1)
	timerTextY.desc = 'Moves the time up or down from where Text position puts it, in pixels. Moving it up also moves the flyout arrow up to make room.'
	timerTextY.disabled = function() return not self.config.timer_text end

	local timerBarHeight = st.Config.generators.range(7, 'Timer bar height', 2, 20, 1)
	timerBarHeight.desc = "The timer bar's height, its border included. It always leaves room for the bar inside its border, and with the text on the bar it's never shorter than the text needs."
	timerBarHeight.disabled = function() return not self.config.timer_bar end

	local general = {
		name = 'General',
		type = 'group',
		order = 1,
		get = function(info) return self.config[info[#info]] end,
		set = function(info, value)
			local key = info[#info]
			self.config[key] = value
			if key == 'hide' then
				self:Apply()
			elseif key == 'button_size' or key == 'button_spacing' then
				self:ApplyButtonLayout()
			else
				self:ApplyTimerLayout()
			end
		end,
		args = {
			hide = hide,
			button_size = buttonSize,
			button_spacing = buttonSpacing,
			timer_bar = timerBar,
			timer_text = timerText,
			timer_text_position = timerTextPosition,
			timer_text_x = timerTextX,
			timer_text_y = timerTextY,
			timer_bar_height = timerBarHeight,
		},
	}

	if not self.holder then
		general.name = 'Totem Bar'
		general.order = nil
		return general
	end

	-- The holder's position (TB:ApplyHolder). A change saves the table GetPosition hands
	-- out, so a first change from the waiting spot saves a position too.
	local position = st.Config.generators.position(2, true,
		function(key) return self:GetPosition()[key] end,
		function(key, value)
			local pos = self:GetPosition()
			pos[key] = value
			self.config.position = pos
			self:ApplyHolder()
		end,
		function() return self.holder end
	)
	-- The buttons go on the holder and the bar goes to its spot, so the holder anchored to
	-- any of them would be a loop, or the bar would chase the holder. Checked by parent as
	-- well as by st:ValidateAnchor's walk of the anchors: the bar itself is never anchored
	-- to the holder, and until the profile has a position the buttons aren't either, so the
	-- walk can't see either coming.
	local validate = position.args.frame.validate
	position.args.frame.validate = function(info, name)
		local frame = st:ResolveFrame(name)
		while frame do
			if frame == self.bar then
				return "The totem bar's position can't be anchored to the totem bar or its buttons."
			end
			frame = frame.GetParent and frame:GetParent()
		end
		return validate(info, name)
	end

	return {
		name = 'Totem Bar',
		type = 'group',
		category = 'Combat', -- the /sui sidebar's group (optionswindow.lua)
		args = {
			general = general,
			position = position,
		},
	}
end
