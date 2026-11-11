-- What the bag layout tests share: the world with SaftUI-Bags' container.lua
-- loaded, and the containers and categories the layout works on. Not a test
-- (no _test suffix), so the runner doesn't run it; container_hold_test.lua,
-- container_pack_test.lua and views_layout_test.lua (the views world, at the
-- end) load it with load_test_file('bags/container_helpers.lua').
--
-- The layout (INV:UpdateContainerLayout) is the real one. So are the rest of
-- the module's files it calls into: inventory.lua (GetButtonHeight), movers.lua
-- (SyncAnchorSize, which sizes the window's edit mode anchor), category.lua
-- (FlushCategory), categories.lua and categorydefaults.lua (the category
-- store EnsureConfigTables makes) and views.lua (the window's view), and the
-- module's defaults
-- (config.lua). What the tests make
-- by hand is what the real code builds around the layout: the container's
-- frames, the column frames and the category frames.

local H = {}

-- The height of one row of items, button and spacing.
function H.row() return H.INV:GetButtonHeight() + H.INV.config.buttonspacing end

-- A fresh world with container.lua loaded. The module's config is the real
-- defaults (padding 10, spacing 3, icon height 50, inverted, the bag window
-- 15 rows by 3 columns).
function H.fresh()
	reset_world()
	load_core_helpers()
	load_saftui('SaftUI-Bags/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Bags/inventory.lua')
	load_saftui('SaftUI-Bags/itemclasses.lua')
	load_saftui('SaftUI-Bags/rules.lua')
	load_saftui('SaftUI-Bags/categorydefaults.lua')
	load_saftui('SaftUI-Bags/categories.lua')
	load_saftui('SaftUI-Bags/category.lua')
	load_saftui('SaftUI-Bags/views.lua')
	load_saftui('SaftUI-Bags/movers.lua')
	load_saftui('SaftUI-Core/Widgets/scrollframe.lua') -- st:ScrollBarRoom
	load_saftui('SaftUI-Bags/container.lua')
	local INV = SaftUI:GetModule('Inventory')
	H.INV = INV
	-- As INV:OnEnable binds it.
	SaftUI:BindModuleConfig(INV, 'inventory')
	INV.containers.bag = {} -- so EnsureConfigTables makes the bag's filter table
	INV:EnsureConfigTables()
	INV.containers.bag = nil
end

-- A frame of the given height (and width), parented to UIParent.
local function frame(height, width, parent)
	local f = CreateFrame('Frame', nil, parent or UIParent)
	f:SetSize(width or 0, height)
	return f
end

-- A category the way INV:UpdateCategory leaves one: a name, the rows of items
-- it holds, and the height of the title plus the rows.
function H.cat(name, rows)
	local category = frame(0)
	category.name = name
	category.slots = {} -- what INV:FlushCategory walks
	H.set_rows(category, rows)
	return category
end

function H.set_rows(category, rows)
	category:SetHeight(rows * H.row() + H.INV.config.categoryTitleHeight)
	category.numRows = rows
end

-- A bag window with the given categories and k columns, 200 wide each, and
-- the frame's name, if given.
--
-- The scroll frame stands in for st:CreateScrollFrame (SaftUI-Core/Widgets/
-- scrollframe.lua), which needs Blizzard's ScrollFrameTemplate and the
-- scroll bar skin. The layout reaches it through SetContentSize, which
-- there sizes the scroll child; so does this one (the real one also calls
-- UpdateScrollChildRect, which the stubs don't have), and through its
-- ScrollBar (st:ScrollBarRoom), which has the anchors and width Blizzard's
-- template gives it.
function H.container(categories, k, name)
	local container = CreateFrame('Frame', name, UIParent)
	container:SetSize(0, 0)
	container.id = 'bag'
	container.categories, container.columns = {}, {}
	container.header, container.footer = frame(30), frame(20)
	container.filterButton = CreateFrame('CheckButton', nil, container)

	local scrollFrame = CreateFrame('ScrollFrame', nil, container)
	local content = frame(0, 0, scrollFrame)
	scrollFrame:SetScrollChild(content)
	scrollFrame.ScrollChild = content
	scrollFrame.SetContentSize = function(self, width, height) content:SetSize(width, height) end
	-- Blizzard's template puts a MinimalScrollBar just outside the scroll
	-- frame's right edge (ScrollFrame_OnLoad: SCROLL_FRAME_SCROLL_BAR_OFFSET_LEFT 6, _TOP 2,
	-- _BOTTOM 5; the bar is 8 wide).
	local bar = CreateFrame('Frame', nil, scrollFrame)
	bar:SetWidth(8)
	bar:SetPoint('TOPLEFT', scrollFrame, 'TOPRIGHT', 6, -2)
	bar:SetPoint('BOTTOMLEFT', scrollFrame, 'BOTTOMRIGHT', 6, 5)
	scrollFrame.ScrollBar = bar
	container.scrollFrame = scrollFrame

	for i = 1, k or 3 do
		container.columns[i] = frame(0, 200, scrollFrame)
		container.columns[i].categories = {}
	end
	for _, category in ipairs(categories) do
		category:SetParent(container)
		container.categories[category.name] = category
	end
	return container
end

-- Lays the container out, as INV:UpdateContainer does when its items change.
function H.layout(container)
	H.INV.containers = { bag = container }
	H.INV:UpdateContainerLayout('bag')
end

-- Which column (index) and position each shown category is in: name -> '2:1'.
function H.where(container)
	local out = {}
	for i, column in ipairs(container.columns) do
		for pos, category in ipairs(column.categories) do out[category.name] = i .. ':' .. pos end
	end
	return out
end

function H.same(a, b)
	for k, v in pairs(a) do if b[k] ~= v then return false end end
	for k, v in pairs(b) do if a[k] ~= v then return false end end
	return true
end

------------------------------------------------------------------ the views

--[[
	The views' layout tests (views_layout_test.lua) lay windows out with real
	slots: H.views_world(client) is bag_world.lua's stubbed bags under the
	module's real files, with container.lua, movers.lua and currencies.lua as
	well, Core's check button and status bar, and the item upgrade helpers and
	tooltip scanner of Core's Utilities module. H.window(id) is a window in it.

	Made by hand, for Blizzard templates and API the stubs don't have, as far
	as INV:CreateSlot, INV:AssignSlot, INV:CreateCategory and the currency
	slots use them:
	  - ContainerFrameItemButtonTemplate: a check button (on retail too, where
	    it is an ItemButton) with the regions the template names: its
	    IconTexture, Count and NormalTexture, and a Cooldown (a frame with the
	    one cooldown method st:SkinCooldown calls, a no-op) and its JunkIcon,
	    the hidden junk coin texture. Blizzard's also
	    gives it the item button's mixins and scripts, which the layout
	    never runs;
	  - TokenEntryTemplate (a currency slot): a check button with its icon,
	    Count, NormalTexture and Content.WatchedCurrencyCheck;
	  - UICheckButtonTemplate (a category's and a currency's check boxes): a
	    check button with its Text;
	  - the item button helpers SetItemButtonTexture, SetItemButtonCount,
	    SetItemButtonDesaturated and SetItemButtonTextureVertexColor, the
	    crafting quality overlay's SetItemCraftingQualityOverlay,
	    ClearItemCraftingQualityOverlay and
	    SetItemCraftingQualityOverlayOverride (Forever counts as retail, so
	    the slots set it), and CooldownFrame_Set, which only change how a slot
	    looks: no-ops;
	  - C_Container.GetContainerItemCooldown: no cooldown;
	  - C_CurrencyInfo: empty, so the bag window has no Currencies category
	    unless a test gives it the currency API (views_layout_test.lua's
	    currencies);
	  - CreateObjectPool (Blizzard's ObjectPool), which INV:CreateCategory
	    gives every category (only the currencies use theirs): Acquire,
	    ReleaseAll and EnumerateActive.
	H.frames_made() counts the frames CreateFrame has made since the world
	was made. H.search(container) gives a window the bag window's search box.
]]

local made = 0
function H.frames_made() return made end

local TEMPLATE_STAND_INS = {
	ContainerFrameItemButtonTemplate = function(slot, name)
		slot.icon = slot:CreateTexture(name .. 'IconTexture', 'BORDER')
		slot:CreateFontString(name .. 'Count', 'ARTWORK'):SetFontObject(GameFontWhiteSmall)
		slot:CreateTexture(name .. 'NormalTexture', 'ARTWORK')
		slot.JunkIcon = slot:CreateTexture(nil, 'OVERLAY')
		slot.JunkIcon:Hide()
		-- A Cooldown, which the stubs don't have: a frame with the one cooldown
		-- method st:SkinCooldown calls.
		local cooldown = CreateFrame('Frame', name .. 'Cooldown', slot)
		cooldown.SetHideCountdownNumbers = function() end
	end,
	TokenEntryTemplate = function(slot, name)
		slot.icon = slot:CreateTexture(nil, 'ARTWORK')
		slot.Count = slot:CreateFontString(nil, 'ARTWORK')
		slot.Count:SetFontObject(GameFontWhiteSmall)
		slot:CreateTexture(name .. 'NormalTexture', 'ARTWORK')
		slot.Content = CreateFrame('Frame', nil, slot)
		slot.Content.WatchedCurrencyCheck = slot.Content:CreateTexture(nil, 'ARTWORK')
	end,
	UICheckButtonTemplate = function(button, name)
		button.Text = button:CreateFontString(name and name .. 'Text', 'ARTWORK')
	end,
}

local function stand_in_templates()
	made = 0
	local createFrame = CreateFrame
	_G.CreateFrame = function(frameType, name, parent, template, ...)
		made = made + 1
		local rest, standIns = {}, {}
		for templateName in tostring(template or ''):gmatch('[^,%s]+') do
			local standIn = TEMPLATE_STAND_INS[templateName]
			if standIn then standIns[#standIns + 1] = standIn else rest[#rest + 1] = templateName end
		end
		if #standIns > 0 and frameType == 'ItemButton' then frameType = 'CheckButton' end
		local frame = createFrame(frameType, name, parent, #rest > 0 and table.concat(rest, ',') or nil, ...)
		for _, standIn in ipairs(standIns) do standIn(frame, name) end
		return frame
	end
end

local function noop() end

local function stand_in_api()
	_G.SetItemButtonTexture = noop
	_G.SetItemButtonCount = noop
	_G.SetItemButtonDesaturated = noop
	_G.SetItemButtonTextureVertexColor = noop
	_G.SetItemCraftingQualityOverlay = noop
	_G.ClearItemCraftingQualityOverlay = noop
	_G.SetItemCraftingQualityOverlayOverride = noop
	_G.CooldownFrame_Set = noop
	C_Container.GetContainerItemCooldown = function() return 0, 0, 0 end
	_G.C_CurrencyInfo = {}
	_G.CreateObjectPool = function(create, reset)
		local pool, active, free = {}, {}, {}
		function pool:Acquire()
			local object = table.remove(free) or create(pool)
			active[object] = true
			return object
		end
		function pool:ReleaseAll()
			for object in pairs(active) do
				if reset then reset(pool, object) end
				free[#free + 1] = object
			end
			active = {}
		end
		function pool:EnumerateActive() return pairs(active) end
		return pool
	end
end

-- A fresh views world on client ('forever', the default, or 'retail'; see
-- bag_world.lua). Returns the module and bag_world's W, to fill the bags.
function H.views_world(client)
	local W = load_test_file('bags/bag_world.lua')
	local INV = W.fresh(client)
	load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
	load_saftui('SaftUI-Core/Widgets/statusbar.lua')
	load_saftui('SaftUI-Core/Utilities/itemupgrades.lua')
	load_saftui('SaftUI-Core/Utilities/tooltipscanner.lua') -- no C_TooltipInfo: no text
	-- currencies.lua keys a table by this enum when it loads.
	Enum.AccountCurrencyTransferResult = Enum.AccountCurrencyTransferResult
		or { MaxQuantity = 1, NoValidSourceCharacter = 2, CannotUseCurrency = 3 }
	load_saftui('SaftUI-Bags/currencies.lua')
	load_saftui('SaftUI-Bags/movers.lua')
	load_saftui('SaftUI-Core/Widgets/scrollframe.lua') -- st:ScrollBarRoom
	load_saftui('SaftUI-Bags/container.lua')
	H.INV = INV
	stand_in_templates()
	stand_in_api()
	return INV, W
end

-- A window as INV:CreateContainer makes one, as far as the layout reads it:
-- H.container's frames, named, with Core's header and footer, a frame per bag ID (container.bags, each item
-- slot's parent, which tells the item button its bag), its footer's slot
-- count, the real loading overlay (INV:InitializeLoadingOverlay), and its
-- columns, widths and backdrop from the real INV:UpdateConfig(id). The bag
-- window also gets every category as INV:InitializePlayerBags makes them
-- (INV:InitializeAllCategories: the rules' categories, Empty Slots, and
-- Currencies where C_CurrencyInfo can give them). Open, with no items laid
-- out yet. H.search gives it the bag window's search box.
function H.window(id)
	local INV = H.INV
	local container = H.container({}, 0, 'SaftUITest_' .. id)
	container.id = id
	-- Core's real header and footer, which INV:CreateContainer makes, in place
	-- of H.container's plain frames: the layout places the scroll frame under
	-- the header.
	SaftUI:CreateCloseButton(container)
	SaftUI:CreateHeader(container, id)
	SaftUI:CreateFooter(container)
	-- The game puts a scroll frame's child at its top left (less the scroll,
	-- none here); the stubbed scroll frame doesn't place it.
	container.scrollFrame.ScrollChild:SetPoint('TOPLEFT', container.scrollFrame, 'TOPLEFT')
	container.bag_ids = INV.bagIds[id]
	container.bags = {}
	for _, bagID in pairs(container.bag_ids) do
		local bag = CreateFrame('Frame', nil, container.scrollFrame.ScrollChild)
		bag:SetID(bagID)
		container.bags[bagID] = bag
	end
	-- As INV:InitializeFooter makes it.
	container.footer.slots = container.footer:CreateFontString(nil, 'OVERLAY')
	container.footer.slots:SetFontObject(SaftUI:GetFont(SaftUI.config.profile.headers.font))
	INV.containers[id] = container
	INV:CreateViewButtons(container) -- in the title bar, as INV:CreateContainer makes them
	INV:EnsureConfigTables()
	INV:InitializeLoadingOverlay(container)
	INV:UpdateConfig(id)
	if id == 'bag' then INV:InitializeAllCategories('bag') end
	return container
end

-- Gives a window the search box INV:InitializeSearch gives the bag window, so
-- the layout sizes the window around it and INV:UpdateVisibleContainers reads
-- it: an edit box with the text region st:StyleEditBox sets the font of (a
-- plain one, for Blizzard's SearchBoxTemplate), skinned and hooked as there,
-- so setting its text runs INV:UpdateSearchFilter.
function H.search(container)
	local search = CreateFrame('EditBox', container:GetName() .. 'Search', container.footer)
	search:CreateFontString(nil, 'OVERLAY')
	SaftUI:SkinEditBox(search, 'theme', 'theme')
	search:SetHeight(20)
	H.INV:HookScript(search, 'OnTextChanged', 'UpdateSearchFilter')
	container.search = search
	return search
end

-- Where every shown category frame and slot of a window is, and the window's
-- size: name -> 'left,top,width,height'.
function H.snapshot(container)
	local function rect(region)
		return ('%s,%s,%s,%s'):format(region:GetLeft(), region:GetTop(), region:GetWidth(), region:GetHeight())
	end
	local out = { window = rect(container), scroll = rect(container.scrollFrame) }
	for name, category in pairs(container.categories) do
		if category:IsShown() then
			out[name] = rect(category)
			for i, slot in ipairs(category.slots) do
				if slot:IsShown() then out[name .. '#' .. i] = rect(slot) end
			end
		end
	end
	return out
end

return H
