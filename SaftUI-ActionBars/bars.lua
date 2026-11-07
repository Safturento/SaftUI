local st = SaftUI
local AB = st:GetModule('ActionBars')
local LAB = LibStub('LibActionButton-1.0')

--[[
	The bars. Each one is a SecureHandlerStateTemplate frame (the "header") on
	UIParent, named SaftUI_ActionBar1..8, holding 12 LibActionButton buttons named
	SaftUI_ActionBar<n>Button1..12. AB.bars[id] is the header, and
	AB.bars[id].buttons[i] its buttons.

	Paging (bar 1 only). Bars 2-8 always show their one Blizzard page (state 0).
	Bar 1 has a state per page, 1 to 18, so every page Blizzard's main bar can
	show (Blizzard's pages go up to the override bar, ActionButtonUtil.ActionBarType
	numbers them 16-18). A state driver turns the game's paging conditions into a
	token, and the header's _onstate-page snippet turns the token into a page and
	hands it to the buttons (LibActionButton's _childupdate-state). It's all
	secure: paging in combat needs no Lua of SaftUI's.

	The page follows Blizzard's own main bar (ActionBarController_UpdateAll):
	vehicle, then override, then temporary shapeshift, then the bonus (stance, form
	or stealth) bar if on page 1, then the page picked with Shift+number or the page
	arrows. The tokens, first match wins:
	  [vehicleui]       vehicle    -> GetVehicleBarIndex()
	  [overridebar]     override   -> GetOverrideBarIndex()
	  [shapeshift]      shapeshift -> GetTempShapeshiftBarIndex()
	  [bar:2]..[bar:6]  2..6       -> that page
	  [bonusbar:1..5]   bonus1..5  -> GetBonusBarIndex(), if HasBonusActionBar()
	  [possessbar]      possess    -> Blizzard's order above, worked out again
	  otherwise         1
	The vehicle, override and shapeshift tokens map straight to their page, as
	ElvUI does, so a condition that turns true a moment before the bar's actions
	arrive still lands on the right page. Bonus bars come after the manual pages
	because Blizzard only uses them on page 1. Bonus bar 5 is possess and
	skyriding. Every function the snippet calls is in the restricted environment
	(Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua, the same on
	forever and live). The macro conditions are the client's, the set Bartender4 and
	ElvUI page with on Forever and retail. Each class's stances, forms and stealth
	are bonus bars the client reports, so no class list is needed.

	Visibility. A state driver shows or hides each bar. Bar 1 hides in pet battles,
	whose abilities take its keys. Bars 2-8 also hide while a vehicle or override
	bar replaces bar 1, as ElvUI's do. A disabled bar is always hidden. (The
	Visibility settings arrive with the options; AB:GetVisibilityDriver is where
	they go.)

	Layout. buttons, perrow, size and spacing, pixel-rounded, button 1 at the
	top left, filling rows left to right. A disabled bar keeps its size and place,
	so bars anchored to it stay put. All protected: st:SafeReposition waits for
	the end of combat.
]]

local PAGE_DRIVER = table.concat({
	'[vehicleui] vehicle',
	'[overridebar] override',
	'[shapeshift] shapeshift',
	'[bar:2] 2',
	'[bar:3] 3',
	'[bar:4] 4',
	'[bar:5] 5',
	'[bar:6] 6',
	'[bonusbar:1] bonus1',
	'[bonusbar:2] bonus2',
	'[bonusbar:3] bonus3',
	'[bonusbar:4] bonus4',
	'[bonusbar:5] bonus5',
	'[possessbar] possess',
	'1',
}, '; ')

-- Restricted code: self is the header, newstate the driver's token (a number for
-- the plain pages, as SecureStateDriver converts numeric tokens).
local PAGE_SNIPPET = [[
	local page = tonumber(newstate)
	if newstate == 'vehicle' then
		page = GetVehicleBarIndex()
	elseif newstate == 'override' then
		page = GetOverrideBarIndex()
	elseif newstate == 'shapeshift' then
		page = GetTempShapeshiftBarIndex()
	elseif newstate == 'possess' then
		if HasVehicleActionBar() then
			page = GetVehicleBarIndex()
		elseif HasOverrideActionBar() then
			page = GetOverrideBarIndex()
		elseif HasTempShapeshiftActionBar() then
			page = GetTempShapeshiftBarIndex()
		elseif HasBonusActionBar() then
			page = GetBonusBarIndex()
		else
			page = GetActionBarPage()
		end
	elseif not page then
		if HasBonusActionBar() then
			page = GetBonusBarIndex()
		else
			page = GetActionBarPage()
		end
	end
	page = page or 1
	self:SetAttribute('state', page)
	control:ChildUpdate('state', page)
]]

local VISIBILITY_MAIN = '[petbattle] hide; show'
local VISIBILITY_OTHER = '[petbattle][vehicleui][overridebar] hide; show'

-- The pages bar 1 needs a state for. 18 covers Blizzard's vehicle, temporary
-- shapeshift and override pages; the client's own numbers are checked too.
local function MainBarPages()
	return math.max(18,
		C_ActionBar.GetVehicleBarIndex(),
		C_ActionBar.GetOverrideBarIndex(),
		C_ActionBar.GetTempShapeshiftBarIndex())
end

local function Clamp(value, low, high)
	return math.min(math.max(math.floor(value or low), low), high)
end

-- Makes bar id and its buttons, with their actions, paging and skin. Out of
-- combat only (AB:Build). Returns the existing bar if it's made already.
function AB:CreateBar(id)
	if self.bars[id] then return self.bars[id] end

	local name = 'SaftUI_ActionBar' .. self:GetFrameSuffix(id)
	local bar = CreateFrame('Frame', name, UIParent, 'SecureHandlerStateTemplate')
	bar.id = id
	bar.buttons = {}

	local page = self.BAR_PAGES[id]
	local pages = id == 'bar1' and MainBarPages() or 0
	for i = 1, self.NUM_BUTTONS do
		local button = LAB:CreateButton(i, name .. 'Button' .. i, bar, self:GetButtonConfig(id, i))
		button:SetState(0, 'action', self:GetActionSlot(page, i))
		for state = 1, pages do
			button:SetState(state, 'action', self:GetActionSlot(state, i))
		end
		self:SkinButton(button)
		bar.buttons[i] = button
	end

	if id == 'bar1' then
		-- The snippet first, as registering the driver sets the state straight away.
		bar:SetAttribute('_onstate-page', PAGE_SNIPPET)
		RegisterStateDriver(bar, 'page', PAGE_DRIVER)
	end

	self.bars[id] = bar
	return bar
end

-- The state driver that shows or hides bar id.
function AB:GetVisibilityDriver(id)
	if not self.config[id].enable then
		return 'hide'
	end
	return id == 'bar1' and VISIBILITY_MAIN or VISIBILITY_OTHER
end

-- Sizes bar id, lays out its buttons and places it, from the profile. In combat
-- this waits for the end of combat and reads the profile then.
function AB:LayoutBar(id)
	local bar = self.bars[id]
	if not bar then return end

	st:SafeReposition(bar, 'actionbars_layout_' .. id, function()
		local config = self.config[id]
		local numButtons = Clamp(config.buttons, 1, self.NUM_BUTTONS)
		local perRow = Clamp(config.perrow, 1, numButtons)
		local numRows = math.ceil(numButtons / perRow)
		local size = st:RoundToPixel(config.size, bar)
		local spacing = st:RoundToPixel(config.spacing, bar)

		for i, button in ipairs(bar.buttons) do
			if i <= numButtons then
				local column = (i - 1) % perRow
				local row = math.floor((i - 1) / perRow)
				button:ClearAllPoints()
				button:SetSize(size, size)
				button:SetPoint('TOPLEFT', bar, 'TOPLEFT', column * (size + spacing), -row * (size + spacing))
				button:Show()
			else
				button:Hide()
			end
		end

		bar:SetSize(perRow * size + (perRow - 1) * spacing, numRows * size + (numRows - 1) * spacing)

		local point, frame, relPoint, x, y = st:UnpackPoint(config.position)
		bar:ClearAllPoints()
		bar:SetPoint(point, st:ResolveFrame(frame) or UIParent, relPoint,
			st:RoundToPixel(x, bar), st:RoundToPixel(y, bar))
	end)
end

-- Applies bar id's profile settings: layout, skin and whether it's shown. All
-- protected, so in combat it waits for the end of combat.
function AB:UpdateBar(id)
	local bar = self.bars[id]
	if not bar then return end
	if st:QueueAfterCombat('actionbars_update_' .. id, function() self:UpdateBar(id) end) then return end

	self:LayoutBar(id)
	self:StyleBar(id)

	local driver = self:GetVisibilityDriver(id)
	if bar.visibilityDriver ~= driver then
		bar.visibilityDriver = driver
		RegisterStateDriver(bar, 'visibility', driver)
	end
end
