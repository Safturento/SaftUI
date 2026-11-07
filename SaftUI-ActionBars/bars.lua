local st = SaftUI
local AB = st:GetModule('ActionBars')
local LAB = LibStub('LibActionButton-1.0')

--[[
	The bars. Each one is a SecureHandlerStateTemplate frame (the "header") on
	UIParent, named by AB:GetBarFrameName. Bars 1-8 are SaftUI_ActionBar1..8,
	holding 12 LibActionButton buttons named SaftUI_ActionBar<n>Button1..12. The
	pet and stance bars, SaftUI_PetBar and SaftUI_StanceBar, hold 10 of SaftUI's
	own secure buttons each (buttons.lua, made by AB.barTypes, petbar.lua and
	stancebar.lua). AB.bars[id] is the header, and AB.bars[id].buttons[i] its
	buttons. Everything below works the same for every bar, unless it says so.

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
	  [possessbar]      possess    -> Blizzard's order above, worked out again
	  [bar:2]..[bar:6]  2..6       -> that page
	  [bonusbar:1..5]   bonus1..5  -> GetBonusBarIndex(), if HasBonusActionBar()
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
	bar replaces bar 1, as ElvUI's do (AB.HIDE_CONDITIONS). The pet and stance
	bars add their own conditions (petbar.lua, stancebar.lua). A disabled bar is
	always hidden, and so is a bar that isn't available (a class without forms has
	no stance bar). Then the bar's Visibility setting:
	  - always:    '<hide conditions> hide; show'
	  - combat:    '<hide conditions> hide; [combat] show; hide', so bar 2 is
	               '[petbattle][vehicleui][overridebar] hide; [combat] show; hide'
	  - mouseover: shown as with always, and faded to its fade_alpha while the
	               mouse isn't over it (the fader below). Only the bar's alpha
	               changes, which isn't protected, so it fades in combat too.
	               LibActionButton keeps using the buttons' own alpha for empty
	               slots; the two multiply.
	The drivers are secure, so combat starting or ending shows and hides bars
	with no Lua of SaftUI's. Changing them is protected: out of combat only.
	While keybind mode is on (bindings.lua), every enabled bar is shown and not
	faded (AB:SetForceShown), so bars that are only shown in combat or faded can
	be hover-bound.

	Layout. buttons, perrow, size and spacing, pixel-rounded, button 1 at the
	top left, filling rows left to right. A bar shows no more buttons than it has
	something for (the stance bar one per form, AB:GetNumButtons), and at least
	one. A disabled or hidden bar keeps its size and place, so bars anchored to
	it stay put, and its edit mode outline (options.lua) still covers it. All
	protected: st:SafeReposition waits for the end of combat.
]]

local PAGE_DRIVER = table.concat({
	'[vehicleui] vehicle',
	'[overridebar] override',
	'[shapeshift] shapeshift',
	-- Possess before the manual pages and bonus bars, as Blizzard's
	-- ActionBarController orders it: mind control etc. must show the possessed
	-- unit's page, not the stance/form or Shift+number page.
	'[possessbar] possess',
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

-- When each bar hides whatever its Visibility setting says. Bars without an
-- entry use DEFAULT_HIDE_CONDITIONS.
AB.HIDE_CONDITIONS = {
	bar1 = '[petbattle]',
}
local DEFAULT_HIDE_CONDITIONS = '[petbattle][vehicleui][overridebar]'

-- How long the mouseover fade takes from faded to shown, and back.
local FADE_TIME = 0.2

-- True while keybind mode shows every enabled bar (AB:SetForceShown).
local forceShown = false

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

-- A bar anchored by its centre on one axis (BOTTOM and TOP centre it across,
-- LEFT and RIGHT up and down, CENTER both) has its edges half a pixel off the
-- grid when it's an odd number of pixels long on that axis. Every button is
-- then too, and they round to whole pixels in different directions either
-- side of the centre: on a centred row of 12, buttons 6 and 7 end up a pixel
-- closer than the rest. So on a centred axis the bar is rounded up to an even
-- length, with the spare pixel past the last button. Its centre stays on a
-- whole pixel too, so bars stacked on it line up the same way, as long as the
-- frame a bar is anchored to sits on whole pixels.
local function EvenIfCentred(length, point, edge1, edge2, bar)
	if point:find(edge1) or point:find(edge2) then return length end
	local pixel = st:GetPixelSize(bar)
	if not pixel then return length end
	if math.floor(length / pixel + 0.5) % 2 == 0 then return length end
	return st:RoundToPixel(length + pixel, bar)
end

-- Bars 1-8: 12 LibActionButton buttons with their action slots, paging and skin.
local function CreateActionButtons(self, bar)
	local id = bar.id
	local name = bar:GetName()
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
end

-- Makes bar id and its buttons: LibActionButton's for bars 1-8, the bar type's
-- for the others (AB.barTypes). Out of combat only (AB:Build). Returns the
-- existing bar if it's made already.
function AB:CreateBar(id)
	if self.bars[id] then return self.bars[id] end

	local bar = CreateFrame('Frame', self:GetBarFrameName(id), UIParent, 'SecureHandlerStateTemplate')
	bar.id = id
	bar.buttons = {}

	local barType = self.barTypes[id]
	if barType then
		barType.CreateButtons(bar)
	else
		CreateActionButtons(self, bar)
	end

	self.bars[id] = bar
	return bar
end

-- False while bar id has nothing to show whatever its settings (AB.barTypes).
function AB:IsBarAvailable(id)
	local barType = self.barTypes[id]
	return not (barType and barType.IsAvailable) or barType.IsAvailable()
end

-- The state driver that shows or hides bar id (see the top of this file).
function AB:GetVisibilityDriver(id)
	local config = self.config[id]
	if not config.enable or not self:IsBarAvailable(id) then
		return 'hide'
	end
	local hide = (self.HIDE_CONDITIONS[id] or DEFAULT_HIDE_CONDITIONS) .. ' hide'
	if config.visibility == 'combat' and not forceShown then
		return hide .. '; [combat] show; hide'
	end
	return hide .. '; show'
end

------------------------------------
--- Mouseover fade ------------------
------------------------------------

-- The bars faded until moused over: bar -> id. The fader runs while there are any.
local fading = {}
local fader = CreateFrame('Frame')
fader:Hide()

local function FadeAlpha(id)
	local config = AB.config[id]
	local alpha = tonumber(config and config.fade_alpha) or 0
	return math.min(math.max(alpha, 0), 1)
end

-- The mouse is over the bar, or LibActionButton's flyout is open on one of its
-- buttons. The flyout is parented to the button while it's open, so it fades
-- with the bar, and would be invisible if the bar faded under it.
local function IsHovered(bar)
	if bar:IsMouseOver() then return true end
	local flyout = LAB:GetSpellFlyoutFrame()
	local button = flyout and flyout:IsShown() and flyout:GetParent()
	return button and button:GetParent() == bar or false
end

-- Moves each faded bar's alpha toward 1 while hovered, and toward its
-- fade_alpha otherwise, the whole way in FADE_TIME. Alpha only: safe in combat.
-- GetAlpha gives back a float, so a bar within a hair of its target is left be.
fader:SetScript('OnUpdate', function(_, elapsed)
	local step = elapsed / FADE_TIME
	for bar, id in pairs(fading) do
		local target = IsHovered(bar) and 1 or FadeAlpha(id)
		local alpha = bar:GetAlpha()
		if alpha < target - 0.001 then
			bar:SetAlpha(math.min(alpha + step, target))
		elseif alpha > target + 0.001 then
			bar:SetAlpha(math.max(alpha - step, target))
		end
	end
end)

-- Starts or stops fading bar id, from its Visibility setting. A bar that starts
-- fading goes straight to faded unless the mouse is over it. Alpha only.
function AB:UpdateFade(id)
	local bar = self.bars[id]
	if not bar then return end
	local config = self.config[id]
	if config.enable and config.visibility == 'mouseover' and not forceShown then
		if not fading[bar] then
			fading[bar] = id
			bar:SetAlpha(IsHovered(bar) and 1 or FadeAlpha(id))
		end
	else
		fading[bar] = nil
		bar:SetAlpha(1)
	end
	fader:SetShown(next(fading) ~= nil)
end

-- Applies bar id's visibility: its state driver, and its fade. Changing the
-- driver is protected, so in combat that waits for the end of combat. The fade
-- is only alpha, so it applies at once.
function AB:UpdateVisibility(id)
	local bar = self.bars[id]
	if not bar then return end
	self:UpdateFade(id)
	if st:QueueAfterCombat('actionbars_visibility_' .. id, function() self:UpdateVisibility(id) end) then return end

	local driver = self:GetVisibilityDriver(id)
	if bar.visibilityDriver ~= driver then
		bar.visibilityDriver = driver
		RegisterStateDriver(bar, 'visibility', driver)
	end
end

-- Keybind mode (bindings.lua): while on, every enabled bar is shown and not
-- faded, whatever its Visibility setting, so it can be hovered. Turned on out
-- of combat only; turning it off in combat waits for the end of combat.
function AB:SetForceShown(on)
	on = on and true or false
	if forceShown == on then return end
	forceShown = on
	for id in pairs(self.bars) do
		self:UpdateVisibility(id)
	end
end

-- How many of bar id's buttons it shows, its first ones: the buttons setting,
-- from 1 to as many as the bar has something for (all of them but on the
-- stance bar, which has one per form). The keys of the others do nothing
-- (bindings.lua). A bar with nothing still lays out one button, so its edit
-- mode outline has a size.
function AB:GetNumButtons(id)
	local bar = self.bars[id]
	if not bar then return 0 end
	local barType = self.barTypes[id]
	local slots = barType and barType.GetNumSlots and barType.GetNumSlots() or #bar.buttons
	return Clamp(self.config[id].buttons, 1, math.max(math.min(slots, #bar.buttons), 1))
end

-- Sizes bar id, lays out its buttons and places it, from the profile. In combat
-- this waits for the end of combat and reads the profile then.
function AB:LayoutBar(id)
	local bar = self.bars[id]
	if not bar then return end

	st:SafeReposition(bar, 'actionbars_layout_' .. id, function()
		local config = self.config[id]
		local numButtons = self:GetNumButtons(id)
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

		local point, frame, relPoint, x, y = st:UnpackPoint(config.position)
		bar:SetSize(
			EvenIfCentred(perRow * size + (perRow - 1) * spacing, point, 'LEFT', 'RIGHT', bar),
			EvenIfCentred(numRows * size + (numRows - 1) * spacing, point, 'TOP', 'BOTTOM', bar))
		bar:ClearAllPoints()
		bar:SetPoint(point, st:ResolveFrame(frame) or UIParent, relPoint,
			st:RoundToPixel(x, bar), st:RoundToPixel(y, bar))
	end)
end

-- Applies bar id's profile settings: layout, skin and text, whether it's shown
-- or faded, where its keys go (a disabled bar's do nothing) and its edit mode
-- outline's label. The pet and stance bars also take their actions from the
-- game first (AB.barTypes UpdateActions), so a change there (forms learned in
-- combat) is laid out with them. Every /sui option of a bar runs this. All
-- protected, so in combat it waits for the end of combat.
function AB:UpdateBar(id)
	local bar = self.bars[id]
	if not bar then return end
	if st:QueueAfterCombat('actionbars_update_' .. id, function() self:UpdateBar(id) end) then return end

	local barType = self.barTypes[id]
	if barType and barType.UpdateActions then
		barType.UpdateActions(bar)
	end
	self:LayoutBar(id)
	self:StyleBar(id)
	self:UpdateVisibility(id)
	self:UpdateBindings()
	self:UpdateMoverLabel(id)
end
