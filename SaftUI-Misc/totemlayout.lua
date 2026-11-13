local st = SaftUI
local TB = st:GetModule('TotemBar')
local S = TB.S

--[[
	The totem bar's button layout (totembar.lua says what the bar is).

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
]]

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

-- S.laidOutOn: the frame the buttons were last laid out on (TB:LayoutBase), the holder
-- or the bar. When SaftUI first places the bar, the buttons move from the bar to the
-- holder (TB:ApplyHolder, totemposition.lua). nil until the first layout.

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
	S.laidOutOn = base

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

-- For totemposition.lua, which sizes the holder as the bar.
S.BarSize = BarSize
