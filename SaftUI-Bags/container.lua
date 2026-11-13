local st = SaftUI
local INV = st:GetModule('Inventory')


-- The title bar's view buttons: the gap left visible between two neighbouring
-- borders (see INV:ViewButtonGaps). How far in from the header's right edge
-- the close button sits in the header (st:CreateHeader) is Core's
-- st.CLOSE_INSET; while it sits in the metal's socket, with the header in the
-- metal's title bar, how far in it reaches is st:SocketReach.
local VISIBLE_GAP = 3

function INV:GetContainer(containerName)
	return self.containers[containerName]
end

function INV:CreateContainer(id, name, isBankContainer)
	local container = CreateFrame('frame', st.name ..name, UIParent)
	container.id = id
	container:SetFrameStrata('HIGH')
	self.containers[id] = container

	container.scrollFrame = st:CreateScrollFrame(container)
	container.scrollFrame:SetScript('OnMouseWheel', function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * INV.config.scrollSpeed * (INV:GetButtonHeight() + INV.config.buttonspacing))

        newScroll = max(0, min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

	st:CreateCloseButton(container)
	st:CreateHeader(container, name)
	self:InitializeFooter(container)
	if id == 'bag' then
		self:InitializeSearch(container)
	end

    if container.search then
        container.scrollFrame:SetPoint('TOPLEFT', container.search, 'BOTTOMLEFT', 0, -self.config.padding)
    else
        container.scrollFrame:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
    end

	container.categories = {}
	container.columns = {}
	container.bag_ids = self.bagIds[id]

	if not INV.config.filters.categories[id] then
		INV.config.filters.categories[id] = {}
	end

	self:CreateViewButtons(container)
	self:CreateEditToggle(container)

	container.bags = {}
	for _, bag_id in pairs(container.bag_ids) do
		local bag = CreateFrame('frame', 'SaftUI_Bag'..bag_id, container.scrollFrame.ScrollChild)
		bag:SetID(bag_id)
		container.bags[bag_id] = bag
	end

	self:InitializeLoadingOverlay(container)

	-- The next time it opens, the window is packed afresh.
	container:HookScript('OnHide', function() INV:ReleaseLayout(container) end)

	if isBankContainer and id ~= 'combinedbank' then
		 self:HookScript(container.header, 'OnClick', 'SelectBankCategory')
	end

	self:UpdateConfig(id)
	return container
end

function INV:InitializeLoadingOverlay(container)
	local loadingOverlay = st:CreateFrame('frame', container:GetName().."LoadingOverlay", container)
	loadingOverlay:SetBackdrop(st.BACKDROP)
	loadingOverlay:SetBackdropColor(0, 0, 0, .7)
	loadingOverlay:SetAllPoints()
	loadingOverlay:SetFrameStrata('HIGH')
	loadingOverlay:SetFrameLevel(50)

	local loadingBar = st:CreateStatusBar(container:GetName().."LoadingBar", loadingOverlay, '-/-', 'theme', 'solid')
	loadingBar:SetPoint('CENTER')
	loadingBar:SetSize(300, 30)
	loadingBar:SetStatusBarColor(st.config.profile.colors.button.blue:GetRGB())
	loadingOverlay.loadingBar = loadingBar

	container.loadingOverlay = loadingOverlay
	container.SetLoading = function(self, current, max)
		if current == max then
			loadingOverlay:Hide()
			return
		end
		loadingOverlay:Show()
		loadingBar:SetMinMaxValues(0, max)
		loadingBar:SetValue(current)
		loadingBar.text:SetFormattedText('%d / %d', current, max)
	end
end

function INV:InitializeFooter(container)
	st:CreateFooter(container)

	local slottext = container.footer:CreateFontString(nil, 'OVERLAY')
	slottext:SetFontObject(st:GetFont(st.config.profile.headers.font))
	slottext:SetPoint('LEFT', 10, 0)
	slottext:SetText('#/# Slots Used')
	slottext:SetJustifyH('LEFT')
	container.footer.slots = slottext

	if container.id == 'bag' then
		local gold = CreateFrame('frame', nil, container.footer)
		gold:EnableMouse(true)
		gold:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
		gold:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
		gold:SetWidth(120)

		gold.text = gold:CreateFontString(nil, 'OVERLAY')
		gold.text:SetFontObject(st:GetFont(st.config.profile.headers.font))
		gold.text:SetPoint('RIGHT', gold, 'RIGHT', -10, 0)
		gold.text:SetJustifyH('RIGHT')

		gold:SetScript('OnEnter', function(self) INV:DisplayServerGold() end)
		gold:SetScript('OnLeave', st.HideGameTooltip)

		container.footer.gold = gold
		self:UpdateGold()
	elseif container.id == 'bank' and self:HasWarbandBank() then
		-- Neither client has a reagent bank anymore, so the separate bank only
		-- needs the way into the warband window.
		local warbandButton = st:CreateButton('WarbandBankButton', container, 'Warband Bank', 'theme', 'solid')
		warbandButton:SetPoint('BOTTOMRIGHT', container.footer, -6, 6)
		warbandButton:SetScript('OnClick', function()
			if not self.containers.warband then
				self:InitializeWarbandBank()
			else
				ToggleFrame(self.containers.warband)
			end
		end)
		warbandButton:SetSize(100, 16)
		warbandButton:SetFrameLevel(90)
	end
end

function INV:CreateGoldString(container)
    local goldString = CreateFrame('frame', nil, container.footer)
    goldString:EnableMouse(true)
    goldString:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
    goldString:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
    goldString:SetWidth(120)

    goldString.text = goldString:CreateFontString(nil, 'OVERLAY')
    goldString.text:SetFontObject(st:GetFont(st.config.profile.headers.font))
    goldString.text:SetPoint('RIGHT', goldString, 'RIGHT', -10, 0)
    goldString.text:SetJustifyH('RIGHT')

    goldString:SetScript('OnEnter', function() INV:DisplayServerGold() end)
    goldString:SetScript('OnLeave', st.HideGameTooltip)

	container.footer.gold = goldString

    return goldString
end

function INV:UpdateGold()
	local money = GetMoney()
	self:GetContainer('bag').footer.gold.text:SetText(st.StringFormat:GoldFormat(money))
	self:UpdateWarbandMoney()
	self:UpdateCombinedBankWarbandMoney()
	st.config.realm.summary[st.my_name].gold = money
end

function INV:DisplayServerGold()
	GameTooltip:SetOwner(self.containers.bag, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('TOPRIGHT', self.containers.bag, 'TOPLEFT', -10, 0)

	GameTooltip:ClearLines()
	-- List server wide gold
	GameTooltip:AddLine('Gold on ' .. st.my_realm)
	local totalGold = 0
	for toonName, summary in pairs(st.config.realm.summary) do
		local color = summary.class
			and (st.config.profile.colors.class[summary.class] or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[summary.class]))
			or { r = 1, g = 1, b = 1 }
		GameTooltip:AddDoubleLine(toonName, summary.gold and st.StringFormat:GoldFormat(summary.gold) or "??", color.r, color.g, color.b)
		totalGold = totalGold + (summary.gold or 0)
	end


	if self:HasWarbandBank() then
		local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
		totalGold = totalGold + warbandGold
		GameTooltip:AddLine(' ')
		GameTooltip:AddDoubleLine("Warband bank", st.StringFormat:GoldFormat(warbandGold))
	end

	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Total', st.StringFormat:GoldFormat(totalGold))

	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Vendor profit', st.StringFormat:GoldFormat(select(2, self:GetVendorItems())))

	GameTooltip:Show()
end

function INV:GetNumContainerSlots(bagIds)
	local empty, total = 0, 0
	for _,bagID in pairs(bagIds) do
		empty = empty + C_Container.GetContainerNumFreeSlots(bagID)
		total = total + C_Container.GetContainerNumSlots(bagID)
	end

	return empty, total
end

-- The loading bar and the footer's count of used slots.
local function ShowSlotCounts(self, container, numItems, numLoading)
	container:SetLoading(numItems - numLoading, numItems)

	if container.UpdateContainerSlots then
		container:UpdateContainerSlots()
	else
		local empty, total = self:GetNumContainerSlots(container.bag_ids)
			container.footer.slots:SetFormattedText('%d/%d', total-empty, total)
	end
end

-- A window that isn't open waits for its next update, unless whileHidden asks
-- for this one (the first update makes every slot before the window opens).
function INV:UpdateContainer(id, updateLayout, whileHidden)
	local container = self.containers[id]
	if not container or not (whileHidden or container:IsShown()) then return end
	self:EnsureSlotPools(id)

	-- One bag, Multi bag and Rows lay their sections out on every update.
	local view = self:GetLaidOutView(container)
	if view ~= 'compact' then
		local sections, numItems, numLoading = self:GetViewSections(id, view)
		self:LayoutSections(container, sections)
		ShowSlotCounts(self, container, numItems, numLoading)
		return
	end

	local sortedInventory, numItems, numLoading = self:GetSortedInventory(id)

	for name, items in pairs(sortedInventory) do
		self:UpdateCategory(id, name, items)
	end

	self:UpdateCurrencyCategory(container.filterButton:GetChecked())

	self:FlushCategories(container, sortedInventory)

	-- A layout is only held once every item is in it (see HoldLayout).
	container.loadingItems = numLoading > 0

	-- Items whose data is still loading (cold item cache after a reload) are left
	-- out until GET_ITEM_INFO_RECEIVED fires, and those updates don't request a
	-- layout. Keep relaying out until loading finishes so they actually appear.
	if updateLayout or container.layoutPending then
		self:UpdateContainerLayout(id)
	end
	container.layoutPending = numLoading > 0

	ShowSlotCounts(self, container, numItems, numLoading)
end

------------------------------------------------------------------ the view buttons

--[[
	Each window's title bar has a small square button per view (INV.viewIds),
	left of the close button in the order One bag, Multi bag, Compact, Rows
	(container.viewButtons, by view). Their icons are plain colored textures,
	the same on both clients: a square, four squares, a dot grid and lines,
	drawn on a 12 by 12 grid (GLYPHS: x, y, width, height of each piece) whose
	unit is a whole number of pixels, so the pieces stay sharp at any title bar
	height. The button for the window's view is lit with Buttons -> Blue, kept
	with st:KeepOwnColors so a theme recolor and redraw don't take it away;
	under the Blizzard theme, whose panel buttons they are, it's pressed.
	The buttons are SaftUI's own plain buttons, so lighting one is fine in
	combat; the layout is what waits (INV:SetView, INV:ApplyView).

	The title bar is the window's header (st:CreateHeader): under the
	Blizzard theme it sits in the metal's title bar above the window
	(st:HeaderInTitleBar), and every button in it (the view buttons, the Edit
	toggle, Bag Slots) is sized to it (st:HeaderButtonSize,
	INV:SizeHeaderButtons) and stops short of the close button in the metal's
	socket (INV:SpaceViewButtons).
]]
local GLYPHS = {
	onebag = { { 0, 0, 12, 12 } },
	multibag = { { 0, 0, 5, 5 }, { 7, 0, 5, 5 }, { 0, 7, 5, 5 }, { 7, 7, 5, 5 } },
	compact = {
		{ 0, 0, 2, 2 }, { 5, 0, 2, 2 }, { 10, 0, 2, 2 },
		{ 0, 5, 2, 2 }, { 5, 5, 2, 2 }, { 10, 5, 2, 2 },
		{ 0, 10, 2, 2 }, { 5, 10, 2, 2 }, { 10, 10, 2, 2 },
	},
	rows = { { 0, 1, 12, 2 }, { 0, 5, 12, 2 }, { 0, 9, 12, 2 } },
}

-- The lit button's border: Buttons -> Blue.
local function ColorLit(button)
	st:SetBorderColor(button.backdrop, st.config.profile.colors.button.blue:GetRGB())
end

-- A button's glyph is drawn in Colors -> Text -> Normal.
local function ColorGlyph(button)
	for _, piece in ipairs(button.glyph) do
		piece:SetColorTexture(st.config.profile.colors.text.normal:GetRGB())
	end
end

-- A button is size square (the title bar's st:HeaderButtonSize: its height
-- less 8, or the metal's title bar strip less 4), and its glyph is drawn at
-- the largest whole pixel unit that fits inside with room to spare, at least
-- 1 (12px, inside the title bar's 16px buttons).
local function SizeViewButton(button, size)
	button:SetSize(size, size)
	local unit = max(1, floor((size - 8) / 12))
	for i, piece in ipairs(button.glyph) do
		local x, y, w, h = unpack(GLYPHS[button.view][i])
		piece:ClearAllPoints()
		piece:SetPoint('TOPLEFT', button, 'CENTER', (x - 6) * unit, (6 - y) * unit)
		piece:SetSize(w * unit, h * unit)
	end
end

-- The Edit toggle is 40 by 20, and never taller than the title bar's other
-- buttons.
local EDIT_WIDTH, EDIT_HEIGHT = 40, 20
-- Bag Slots is 64 wide, 8 in from the title bar's left.
local SLOTS_WIDTH, SLOTS_INSET = 64, 8

-- Sizes every button in a window's title bar to it (st:HeaderButtonSize): the
-- view buttons square, Bag Slots 64 wide, the Edit toggle 40 wide and no
-- taller than 20. Runs whenever the title bar's height can change: Title bar
-- height (st:UpdateHeader), and a theme switch or the window's own Theme
-- putting it in the metal's title bar or back (INV:UpdateConfig).
function INV:SizeHeaderButtons(container)
	local header = container.header
	if not header then return end
	local size = st:HeaderButtonSize(container)
	for _, button in pairs(container.viewButtons or {}) do SizeViewButton(button, size) end
	if header.slotToggle then header.slotToggle:SetSize(SLOTS_WIDTH, size) end
	if header.filterButton then header.filterButton:SetSize(EDIT_WIDTH, min(EDIT_HEIGHT, size)) end
end

-- The distance between the view buttons' frames, and between the first of them
-- and the close button: each button draws its border the theme's inset for a
-- control outside itself (2 Thick, 1 Thin, none under Blizzard, whose panel
-- button lies inside it) and the close button a 1px outline outside itself,
-- so the frames are that far apart plus VISIBLE_GAP of clear room between the
-- borders, in every theme.
function INV:ViewButtonGaps()
	local inset = st:ThemeInset('theme', 'theme', 'control')
	return 2 * inset + VISIBLE_GAP, inset + 1 + VISIBLE_GAP
end

-- Puts the view buttons (and the Edit check button before them) the
-- INV:ViewButtonGaps apart, lined up from the close button. While the header
-- sits in the metal's title bar (st:HeaderInTitleBar) the close button is in
-- the metal's socket at its right end, which isn't centred on the title bar's
-- strip, so they line up from the header's right edge instead, as far in as
-- the close button reaches (st:SocketReach) and the gap: they stop short of
-- it and stay centred on the strip. A theme switch changes the inset and the
-- title bar, so INV:UpdateConfig(id) runs it again.
function INV:SpaceViewButtons(container)
	local close = st:GetCloseButton(container)
	if not (container.viewButtons and close) then return end
	local buttonGap, closeGap = self:ViewButtonGaps()
	local right, side, gap = close, 'LEFT', closeGap
	if st:HeaderInTitleBar(container) then
		right, side, gap = container.header, 'RIGHT', st:SocketReach(container) + closeGap
	end
	for i = #self.viewIds, 1, -1 do
		local button = container.viewButtons[self.viewIds[i]]
		button:ClearAllPoints()
		button:SetPoint('RIGHT', right, side, -gap, 0)
		right, side, gap = button, 'LEFT', buttonGap
	end
	local filterButton = container.header and container.header.filterButton
	if filterButton then
		filterButton:ClearAllPoints()
		filterButton:SetPoint('RIGHT', container.viewButtons[self.viewIds[1]], 'LEFT', -closeGap, 0)
	end
end

function INV:CreateViewButtons(container)
	local header = container.header
	container.viewButtons = {}
	for i = #self.viewIds, 1, -1 do
		local view = self.viewIds[i]
		local button = st:CreateButton(nil, header, nil, 'theme', 'theme')
		button:SetFrameLevel(header:GetFrameLevel() + 4)
		button.view, button.viewLit, button.glyph = view, false, {}
		for p = 1, #GLYPHS[view] do
			button.glyph[p] = button:CreateTexture(nil, 'OVERLAY')
		end
		ColorGlyph(button)
		SizeViewButton(button, st:HeaderButtonSize(container))

		button:SetScript('OnClick', function() INV:SetView(container.id, view) end)
		button:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOP')
			GameTooltip:SetText(INV.viewLabels[view])
			GameTooltip:Show()
		end)
		button:SetScript('OnLeave', st.HideGameTooltip)

		container.viewButtons[view] = button
	end
	self:SpaceViewButtons(container)
	self:UpdateViewButtons(container.id)
end

-- The Edit toggle (container.filterButton, and the header's filterButton): a
-- check button styled 'button', left of the view buttons in the title bar,
-- that shows or hides the categories the window hides, re-packing it. It's
-- made hidden; nothing shows it today. Made by INV:CreateContainer.
function INV:CreateEditToggle(container)
	local filterButton = st:CreateCheckButton(nil, container.header, 'button')
	container.header.filterButton = filterButton
	filterButton.text:SetAllPoints(filterButton)
	filterButton:SetFont('pixel')
	filterButton:SetText('Edit')
	filterButton:SetScript('OnClick', function()
		-- Showing or hiding the hidden categories re-packs the window.
		INV:ReleaseLayout(container)
		INV:UpdateContainer(container.id, true)
		INV:ShowFilterCheckboxes(container, filterButton:GetChecked())
	end)
	filterButton:Hide()
	container.filterButton = filterButton
	-- Hidden, but sized and anchored clear of the view buttons.
	self:SizeHeaderButtons(container)
	self:SpaceViewButtons(container)
	return filterButton
end

-- The Bag Slots button at the left of a window's title bar (the header's
-- slotToggle), which shows and hides bar, the window's bag slot bar. name, if
-- given, names it (st:CreateButton). The bag window's (containers/bag.lua) and
-- the bank's (containers/bank.lua) make it.
function INV:CreateSlotToggle(container, bar, name)
	local slotToggle = st:CreateButton(name, container.header, 'Bag Slots', 'none', 'theme')
	slotToggle:SetPoint('LEFT', SLOTS_INSET, 0)
	slotToggle:SetScript('OnClick', function() bar:SetShown(not bar:IsShown()) end)
	container.header.slotToggle = slotToggle
	self:SizeHeaderButtons(container)
	return slotToggle
end

-- Lights the window's view's button and puts the others back to the theme's
-- border, when that changed (a button that kept its look isn't drawn again).
-- Under the Blizzard theme, where a control's border is left alone, the lit
-- one shows Blizzard's panel button pressed (st:SetButtonPressed).
function INV:UpdateViewButtons(id)
	local container = self.containers[id]
	if not (container and container.viewButtons) then return end
	local current = self:GetView(id)
	for view, button in pairs(container.viewButtons) do
		local on = view == current
		if on ~= button.viewLit then
			button.viewLit = on
			st:SetButtonPressed(button, on)
			if on then
				ColorLit(button)
				st:KeepOwnColors(button, ColorLit)
			else
				st:KeepOwnColors(button, nil)
				st:SetBackdrop(button, 'theme', 'theme', 'control')
			end
		end
	end
end

-- A color the view buttons are drawn in changed (st:ColorsChanged's group):
-- Buttons -> Blue lights the lit buttons, Text -> Normal draws every glyph.
function INV:ColorViewButtons(group)
	for _, container in pairs(self.containers) do
		for _, button in pairs(container.viewButtons or {}) do
			if group == 'button' and button.viewLit then ColorLit(button) end
			if group == 'text' then ColorGlyph(button) end
		end
	end
end

-- Switches a window's view: saves it, lights its button, shows it in an open
-- /sui's View select (st.Config:Refresh) and lays the window out
-- (INV:ApplyView, which waits for the end of combat). The window's own view
-- does nothing: the layout is only touched for a reason.
function INV:SetView(id, view)
	if not self.viewLabels[view] or self:GetView(id) == view then return end
	self.config[id].view = view
	self:UpdateViewButtons(id)
	st.Config:Refresh()
	self:ApplyView(id)
end

-- The title bar's height follows Global Settings (st:UpdateHeader), and so
-- do the buttons in it. st:UpdateHeader also puts a header in the metal's
-- title bar or back, so this sizes them for that too.
hooksecurefunc(st, 'UpdateHeader', function()
	for _, container in pairs(INV.containers or {}) do INV:SizeHeaderButtons(container) end
end)

-- The narrowest a window can be with its title between the view buttons and
-- the window's left edge: the title is centered, so the room the buttons and
-- the close button take on the right is also kept clear on the left. With the
-- header in the metal's title bar the close button takes how far in it
-- reaches from the socket (st:SocketReach), as INV:SpaceViewButtons lines the
-- buttons up.
function INV:HeaderMinWidth(container)
	local close = st:GetCloseButton(container)
	if not (container.viewButtons and close and container.title) then return 0 end
	local count = #self.viewIds
	local size = st:HeaderButtonSize(container)
	local buttonGap, closeGap = self:ViewButtonGaps()
	local extent = count * size + (count - 1) * buttonGap + closeGap
	if st:HeaderInTitleBar(container) then
		extent = extent + st:SocketReach(container)
	else
		extent = extent + st.CLOSE_INSET + close:GetWidth()
	end
	return 2 * (extent + closeGap) + container.title:GetStringWidth()
end
