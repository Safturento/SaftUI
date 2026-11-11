-- The bags' Theme and Background (SaftUI-Bags): one pair for the bag and bank
-- windows and one for the item and currency slots, both following SaftUI's
-- theme by default, and what keeps the bags right through a theme change:
--   - the defaults look exactly as the old template names they replace drew,
--     and the buttons the bags drew with a hard-coded look follow the theme
--     as the rest of the window does;
--   - a theme switch with the bags open moves every slot's and window's
--     border to the new theme's inset (st:ThemeChanged);
--   - an item's and a currency's quality border survive a theme recolor (a
--     drag of the Border color picker recolors on every move);
--   - a free slot takes its Slot theme's border, and None leaves slots bare;
--   - Bags > Look offers Theme, Background, Slot theme and Slot background.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 with Core's helpers and
-- edit mode (core/config_helpers.lua), so st:ThemeChanged runs the real
-- Config:UpdateConfig and so the bags' INV:UpdateConfig; Core's Utilities
-- module; the bags' config.lua, inventory.lua, itemclasses.lua, rules.lua,
-- currencies.lua, categorydefaults.lua, categories.lua, category.lua,
-- views.lua, container.lua, containers/warbandbank.lua, slot.lua, movers.lua
-- and options.lua. Each case starts from a fresh world, since cases change the
-- theme.
--
-- Made by hand, for Blizzard templates and API the stubs don't have:
--   - the bag window's frames INV:CreateContainer makes from them: its scroll
--     frame (st:CreateScrollFrame's ScrollFrameTemplate; the bags only anchor
--     to it and its scroll child), its search box (SearchBoxTemplate; a plain
--     edit box with its text, skinned as INV:InitializeSearch skins it) and a
--     category (INV:CreateCategory's filter box is a UICheckButtonTemplate);
--     its header, footer and close button are Core's real ones;
--   - item and currency slots (ContainerFrameItemButtonTemplate and
--     TokenEntryTemplate): check buttons with the regions the bags style (the
--     icon and count, and the item level and reagent marker INV:CreateSlot
--     adds), skinned by the real INV:StyleSlot and INV:SkinSlot, as
--     INV:CreateSlot and INV.CreateCurrencySlot skin them;
--   - the Currencies category's pool (Blizzard's ObjectPool) and
--     C_CurrencyInfo.GetBasicCurrencyInfo, as far as INV:UpdateCurrencyBorders
--     reads them.
local T = load_test_file('lib/theme_helpers.lua')

local st, INV, drawn

local function fresh()
	reset_world()
	load_test_file('core/config_helpers.lua')
	load_test_file('core/options_walk.lua')
	st = SaftUI
	drawn = T.watch()
	load_saftui('SaftUI-Core/Utilities/utilities.lua')
	load_saftui('SaftUI-Bags/config.lua')
	-- AceDB filled the profile from every default at login: the bags'
	-- config.lua loads before SaftUI:OnEnable makes the database.
	apply_defaults()
	-- slot.lua post-hooks Blizzard's stack split button at load, and
	-- currencies.lua keys a table by this enum.
	_G.StackSplitFrameOkay_Click = function() end
	Enum.AccountCurrencyTransferResult = Enum.AccountCurrencyTransferResult
		or { MaxQuantity = 1, NoValidSourceCharacter = 2, CannotUseCurrency = 3 }
	for _, file in ipairs({ 'inventory', 'itemclasses', 'rules', 'currencies', 'categorydefaults', 'categories', 'category', 'views', 'container',
		'containers/warbandbank', 'slot', 'movers', 'options' }) do
		load_saftui('SaftUI-Bags/' .. file .. '.lua')
	end
	INV = st:GetModule('Inventory')
	st:BindModuleConfig(INV, 'inventory')
	-- The windows here are made by hand, with the categories this test wants:
	-- INV:UpdateConfig() isn't to make the rest (their frames are bags/'s).
	function INV:EnsureCategoryFrames() end
	-- Every currency's quality, by id.
	_G.C_CurrencyInfo = { GetBasicCurrencyInfo = function(id) return { quality = id == 1 and 4 or 2 } end }
end

-- An item slot, as INV:CreateSlot makes one from Blizzard's template: its
-- regions, then sized, placed and skinned by INV:StyleSlot.
local function item_slot(container, category)
	local id = #category.slots + 1
	local slot = CreateFrame('CheckButton', category:GetName() .. '_Slot' .. id, category)
	slot.icon = slot:CreateTexture(nil, 'BORDER')
	slot.Count = slot:CreateFontString(nil, 'OVERLAY')
	slot.itemLevel = slot:CreateFontString(nil, 'OVERLAY')
	slot.reagentMarker = slot:CreateTexture(nil, 'OVERLAY')
	slot.id = id
	category.slots[id] = slot
	INV:StyleSlot(slot, category, container)
	return slot
end

-- A category frame with a title, as INV:CreateCategory makes one, placed by
-- hand (the layout isn't what's under test).
local function category(container, name, y)
	local frame = CreateFrame('Frame', container:GetName() .. '_' .. name, container.scrollFrame.ScrollChild)
	frame.container, frame.name, frame.slots = container, name, {}
	frame.header = CreateFrame('Button', nil, frame)
	frame.header.text = frame.header:CreateFontString(nil, 'OVERLAY')
	frame:SetPoint('TOPLEFT', container, 'TOPLEFT', 10, y)
	frame:SetSize(200, 150)
	container.categories[name] = frame
	return frame
end

-- The bag window, open, with a category of three item slots and a Currencies
-- category with one currency slot (Epic), laid out by INV:UpdateConfig as at
-- login. Returns the window, its item slots and the currency slot.
local function bags()
	fresh()
	local container = CreateFrame('Frame', 'SaftUIThemeTestBag', UIParent)
	container.id = 'bag'
	container.slots, container.categories, container.columns = {}, {}, {}
	INV.containers.bag = container

	local scrollFrame = CreateFrame('ScrollFrame', nil, container)
	scrollFrame.ScrollChild = CreateFrame('Frame', nil, scrollFrame)
	scrollFrame:SetScrollChild(scrollFrame.ScrollChild)
	container.scrollFrame = scrollFrame
	st:CreateCloseButton(container)
	st:CreateHeader(container, 'Bags')
	st:CreateFooter(container)

	local search = CreateFrame('EditBox', 'SaftUIThemeTestBagSearch', container.footer)
	search:CreateFontString(nil, 'OVERLAY') -- its text
	st:SkinEditBox(search, 'theme', 'theme') -- as INV:InitializeSearch
	search:SetHeight(20)
	search:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', 10, -10) -- as the layout places it
	container.search = search

	local things = category(container, 'Things', -60)
	local slots = {}
	for i = 1, 3 do slots[i] = item_slot(container, things) end

	local currencies = category(container, 'Currencies', -220)
	local currency = CreateFrame('CheckButton', 'SaftUIThemeTestCurrency1', currencies)
	currency.icon = currency:CreateTexture(nil, 'BORDER')
	currency.Count = currency:CreateFontString(nil, 'OVERLAY')
	currency:SetSize(INV:GetButtonWidth(), INV:GetButtonHeight())
	currency:SetPoint('TOPLEFT', currencies, 'TOPLEFT', 0, -50)
	INV:SkinSlot(currency)
	currency.elementData = { id = 1 }
	local pool = {}
	function pool:EnumerateActive()
		local done
		return function() if not done then done = true; return currency end end
	end
	currencies.slotPool = pool

	container:Show()
	INV:UpdateConfig()
	return container, slots, currency
end

-- The profile's Epic color, 'r,g,b'.
local function epic()
	return T.text(st.config.profile.colors.item_quality[4]:GetRGB())
end

------------------------------------------------------------------ defaults

-- The template names the bags' defaults had before themes (themes' base, 7ec1df8).
local OLD_DEFAULTS = {
	{ 'theme', 'background', 'thicktransparent' }, -- the windows (template)
	{ 'buttontheme', 'buttonbackground', 'thicktransparent' }, -- the slots (buttontemplate)
}

test('bag defaults look as they did', function()
	fresh()
	local config = st.config.profile.inventory
	eq(config.template, nil, 'no template key')
	eq(config.buttontemplate, nil, 'no buttontemplate key')
	for _, entry in ipairs(OLD_DEFAULTS) do
		local theme, background, old = entry[1], entry[2], entry[3]
		eq(config[theme], 'theme', theme .. " follows SaftUI's theme")
		eq(config[background], 'theme', background .. " follows SaftUI's theme")
		local new, was = st:ResolveTheme(config[theme], config[background]), st:ResolveLegacyTemplate(old)
		eq(new.name, was.name, theme .. ': the name ' .. old .. ' drew')
		eq(new.inset, was.inset, theme .. ': the inset ' .. old .. ' drew')
		eq(T.text(new.alpha), T.text(was.alpha), theme .. ': the alpha ' .. old .. ' drew')
	end
end)

test("the bags' buttons with a hard-coded look follow the theme as their window does", function()
	local container = bags()
	container.footer.gold = CreateFrame('Frame', nil, container.footer)
	container.footer.gold:SetPoint('RIGHT')
	container.footer.gold:SetSize(120, 20)
	local deposit = INV:InitializeDepositButton(container)
	local withdraw = INV:InitializeWithdrawButton(container)
	local thick = st:ResolveLegacyTemplate('thick')
	for name, button in pairs({ Deposit = deposit, Withdraw = withdraw }) do
		eq(drawn(button), 'theme,solid,small', name .. ": Use SaftUI's theme and Solid, as a small frame")
		eq(T.inset(button.backdrop), thick.inset, name .. ': the inset thick drew')
		eq(T.text(select(4, button.backdrop:GetBackdropColor())), T.text(thick.alpha), name .. ': the alpha thick drew')
	end

	st.config.profile.theme.name = 'thin'
	st:ThemeChanged()
	eq(T.around(container.backdrop, container), '-1,1,1,-1', "the window takes Thin's 1px")
	for name, button in pairs({ Deposit = deposit, Withdraw = withdraw }) do
		eq(T.around(button.backdrop, button), '-1,1,1,-1', name .. ': Thin\'s 1px, as its window')
		eq(T.inset(button.backdrop), 1, name .. ": Thin's one line")
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ a theme switch

test('a theme switch with the bags open moves every slot and window backdrop to the new inset', function()
	local container, slots = bags()
	eq(drawn(container), 'theme,theme,panel', "the window: the bags' Theme and Background, as a panel")
	for i, slot in ipairs(slots) do
		eq(drawn(slot), 'theme,theme,slot', 'slot ' .. i .. ': the Slot theme and background, as a slot')
	end

	-- Thick, SaftUI's default: each border 2px around what it frames. A slot's
	-- backdrop fills the slot, with the icon inside its border.
	eq(T.around(container.backdrop, container), '-2,2,2,-2', 'the window: Thick, 2px out')
	eq(T.around(container.search.backdrop, container.search), '-2,2,2,-2', 'its search box too')
	for i, slot in ipairs(slots) do
		eq(T.around(slot.backdrop, slot.icon), '-2,2,2,-2', 'slot ' .. i .. ': Thick, 2px around the icon')
		eq(T.around(slot.backdrop, slot), '0,0,0,0', 'slot ' .. i .. ': the backdrop fills the slot')
	end

	st.config.profile.theme.name = 'thin'
	st:ThemeChanged()
	eq(T.around(container.backdrop, container), '-1,1,1,-1', "the window: Thin's 1px, no gap")
	eq(T.inset(container.backdrop), 1, "drawn with Thin's one line")
	eq(T.around(container.search.backdrop, container.search), '-1,1,1,-1', 'its search box too')
	for i, slot in ipairs(slots) do
		eq(T.around(slot.backdrop, slot.icon), '-1,1,1,-1', 'slot ' .. i .. ": Thin's 1px around the icon, no gap or overlap")
		eq(T.around(slot.backdrop, slot), '0,0,0,0', 'slot ' .. i .. ': the backdrop still fills the slot')
		eq(T.inset(slot.backdrop), 1, 'slot ' .. i .. ": drawn with Thin's one line")
	end

	-- And back.
	st.config.profile.theme.name = 'thick'
	st:ThemeChanged()
	eq(T.around(container.backdrop, container), '-2,2,2,-2', 'back to Thick: the window')
	for i, slot in ipairs(slots) do
		eq(T.around(slot.backdrop, slot.icon), '-2,2,2,-2', 'back to Thick: slot ' .. i)
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ recolors

test('quality borders survive a recolor', function()
	local container, slots, currency = bags()
	local filled, free, unused = slots[1], slots[2], slots[3]
	filled.info = { quality = 4 } -- an Epic item, as INV:AssignSlot fills it
	INV:SetSlotQualityBorder(filled)
	free.info = { empty = true }
	INV:SetSlotThemeBorder(free) -- as INV:AssignEmptySlot
	INV:SetCurrencyBorder(currency) -- as INV:UpdateCurrencyCategory
	eq(T.edge_rgb(filled.backdrop), epic(), "the item's border is the profile's Epic")
	eq(T.edge_rgb(currency.backdrop), epic(), "the currency's border is the profile's Epic")

	-- The Border color picker dragged: a new border color, then a recolor, on every move.
	local thick = st.config.profile.templates.thick
	for move = 1, 3 do
		thick.bordercolor = { 0.1 * move, 0.5, 0.5, 1 }
		st:RecolorThemed()
		local border = T.text(unpack(thick.bordercolor))
		eq(T.edge_rgb(filled.backdrop), epic(), 'move ' .. move .. ": the item keeps the profile's Epic")
		eq(T.edge_rgb(currency.backdrop), epic(), 'move ' .. move .. ": the currency keeps the profile's Epic")
		eq(T.edge(free.backdrop), border, 'move ' .. move .. ": a free slot takes the theme's new border")
		eq(T.edge(unused.backdrop), border, 'move ' .. move .. ": a slot with nothing in it too")
		eq(T.edge(container.backdrop), border, 'move ' .. move .. ': the window too')
	end

	-- A theme switch redraws everything, then lays the bags out again.
	st.config.profile.theme.name = 'thin'
	st:ThemeChanged()
	eq(T.edge_rgb(filled.backdrop), epic(), "after a switch to Thin: the item keeps the profile's Epic")
	eq(T.edge_rgb(currency.backdrop), epic(), 'the currency too')
	eq(T.edge(unused.backdrop), T.text(unpack(st.config.profile.templates.thin.bordercolor)), "the unused slot takes Thin's border")
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ Slot theme

test("a free slot takes its Slot theme's border", function()
	local _, slots = bags()
	local slot = slots[1]
	slot.info = { quality = 4 }
	INV:SetSlotQualityBorder(slot)
	slot.info = { empty = true }
	INV:SetSlotThemeBorder(slot)
	eq(T.edge(slot.backdrop), T.text(unpack(st.config.profile.templates.thick.bordercolor)),
		"Use SaftUI's theme: Thick's border, not the quality it had")

	st.config.profile.templates.thin.bordercolor = { 0.5, 0.6, 0.7, 1 }
	INV.config.buttontheme = 'thin'
	INV:ApplyButtonSize()
	slot.info = { quality = 4 }
	INV:SetSlotQualityBorder(slot)
	slot.info = { empty = true }
	INV:SetSlotThemeBorder(slot)
	eq(T.edge(slot.backdrop), '0.50,0.60,0.70,1.00', "a Thin Slot theme: Thin's border")
end)

test('a Slot theme of None leaves the slots bare, with nothing to color', function()
	local container, slots, currency = bags()
	local look = INV:GetConfigTable().args.look
	look.set({ 'buttontheme' }, 'none')
	for i, slot in ipairs(slots) do
		eq(T.inset(slot.backdrop), nil, 'slot ' .. i .. ': no border or background')
		eq(T.around(slot.icon, slot), '0,0,0,0', 'slot ' .. i .. ': the icon fills the slot')
	end
	check(container.backdrop.backdropInfo ~= nil, 'the window keeps its own Theme')

	-- A slot made while the Slot theme is None has no backdrop at all.
	local new = item_slot(container, container.categories.Things)
	eq(new.backdrop, nil, 'a new slot: no backdrop')
	eq(T.around(new.icon, new), '0,0,0,0', 'its icon fills it')
	new.info = { quality = 4 }
	INV:SetSlotQualityBorder(new)
	INV:SetSlotThemeBorder(new)
	st:RecolorThemed()
	st.config.profile.theme.name = 'thin'
	st:ThemeChanged()
	eq(#take_errors(), 0, 'coloring and redrawing a bare slot does nothing, with no error')

	look.set({ 'buttontheme' }, 'theme')
	for i, slot in ipairs(slots) do
		eq(T.around(slot.backdrop, slot.icon), '-1,1,1,-1', 'back on: slot ' .. i .. " has Thin's 1px border")
	end
	eq(T.around(new.backdrop, new.icon), '-1,1,1,-1', 'the new slot too')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ options

local THEME_VALUES = { 'theme', 'thick', 'thin', 'none' }
local BACKGROUND_VALUES = { 'theme', 'solid', 'transparent' }

test('Bags Look offers Theme, Background, Slot theme and Slot background, with descs', function()
	local container, slots = bags()
	local tree = INV:GetConfigTable()
	local look = tree.args.look
	eq(look.args.template, nil, 'no Template')
	local want = {
		theme = { 'Theme', THEME_VALUES },
		background = { 'Background', BACKGROUND_VALUES },
		buttontheme = { 'Slot theme', THEME_VALUES },
		buttonbackground = { 'Slot background', BACKGROUND_VALUES },
	}
	for key, w in pairs(want) do
		local option = look.args[key]
		check(option ~= nil, key .. ' is offered')
		if option then
			eq(option.name, w[1], key .. ' is named ' .. w[1])
			eq(option.type, 'select', key .. ' is a select')
			check(type(option.desc) == 'string' and option.desc ~= '', key .. ' has a desc')
			eq(option.width, nil, key .. ' has no Ace width')
			eq(table.concat(option.sorting, ','), table.concat(w[2], ','), key .. "'s choices, in order")
			eq((option.get or look.get)({ key }), 'theme', key .. " reads inventory." .. key .. ": Use SaftUI's theme")
		end
	end
	check(look.args.theme.order < look.args.background.order
		and look.args.background.order < look.args.buttontheme.order
		and look.args.buttontheme.order < look.args.buttonbackground.order
		and look.args.buttonbackground.order < look.args.padding.order,
		'Theme, Background, Slot theme and Slot background lead Look, in that order')

	-- No template name, Highlight or Close Button anywhere on the page.
	each_option(tree, function(option, path)
		local where = table.concat(path, '.')
		check(option.name ~= 'Template', where .. ' is no Template')
		if type(option.values) == 'table' then
			for value, label in pairs(option.values) do
				check(not tostring(value):find('transparent$') or value == 'transparent', where .. ' offers no ' .. value)
				check(label ~= 'Highlight' and label ~= 'Close Button', where .. ' offers no ' .. tostring(label))
			end
		end
	end)

	-- Setting them writes the profile and restyles the bags at once.
	look.set({ 'theme' }, 'thin')
	eq(INV.config.theme, 'thin', 'Theme writes inventory.theme')
	eq(T.around(container.backdrop, container), '-1,1,1,-1', "the window is Thin while SaftUI's theme stays Thick")
	eq(T.around(slots[1].backdrop, slots[1].icon), '-2,2,2,-2', "the slots still follow SaftUI's theme")
	look.set({ 'background' }, 'solid')
	eq(INV.config.background, 'solid', 'Background writes inventory.background')
	eq(T.text(select(4, container.backdrop:GetBackdropColor())), '1.00', 'the window is solid')
	look.set({ 'buttontheme' }, 'thin')
	eq(INV.config.buttontheme, 'thin', 'Slot theme writes inventory.buttontheme')
	eq(T.around(slots[1].backdrop, slots[1].icon), '-1,1,1,-1', 'the slots are Thin')
	look.set({ 'buttonbackground' }, 'transparent')
	eq(INV.config.buttonbackground, 'transparent', 'Slot background writes inventory.buttonbackground')
	eq(T.text(select(4, slots[1].backdrop:GetBackdropColor())), T.text(st.config.profile.theme.opacity),
		"the slots are see-through at SaftUI's opacity")
	eq(#take_errors(), 0, 'no errors')
end)

-- The columns, from INV:UpdateConfig. While a window is open its layout is
-- held, and a column whose categories all sell out drops to no height. A column
-- chained to the one before it (TOPLEFT to its TOPRIGHT) then lost its place in
-- game, and every category after it vanished (a bank down to a few items). Each
-- column is placed on the scroll child by its own offset instead.
test('each column is placed on the scroll child by its own offset, never on the column before it', function()
	local container = bags()
	local columns = container.columns
	check(#columns >= 3, 'the window has columns')
	local width = columns[1]:GetWidth()
	local spacing = INV.config.buttonspacing
	for i, column in ipairs(columns) do
		eq(column:GetNumPoints(), 1, 'column ' .. i .. ' has one point')
		local point, rel, relPoint, x, y = column:GetPoint(1)
		eq(point, 'TOPLEFT', 'column ' .. i)
		check(rel == container.scrollFrame.ScrollChild, 'column ' .. i .. ' is placed on the scroll child')
		eq(relPoint, 'TOPLEFT', 'column ' .. i)
		eq(x, (i - 1) * (width + spacing), 'column ' .. i .. ' at its own offset')
		eq(y, 0, 'column ' .. i)
	end
end)

------------------------------------------------------------------ the view buttons' spacing

-- The visible gap left between two neighbouring borders, in pixels. Each view
-- button draws its border the theme's inset outside itself (2 Thick, 1 Thin),
-- and the close button draws a 1px outline outside itself.
local VISIBLE_GAP = 3
local VIEWS = { 'onebag', 'multibag', 'compact', 'rows' }

local function check_spacing(container, label)
	local inset = st:ThemeInset('theme', 'theme')
	local close = st:GetCloseButton(container)
	for i = 2, #VIEWS do
		local a, b = container.viewButtons[VIEWS[i - 1]], container.viewButtons[VIEWS[i]]
		eq(b:GetLeft() - a:GetRight() - 2 * inset, VISIBLE_GAP,
			label .. ': ' .. VIEWS[i - 1] .. "'s and " .. VIEWS[i] .. "'s borders are the same visible gap apart")
	end
	eq(close:GetLeft() - container.viewButtons.rows:GetRight() - inset - 1, VISIBLE_GAP,
		label .. ": the close button's outline is the same visible gap from Rows' border")
end

test("the view buttons' borders never overlap, under Thick or Thin, and a theme switch re-spaces them", function()
	local container = bags()
	INV:CreateViewButtons(container)
	INV:UpdateConfig('bag')
	eq(st:ThemeInset('theme', 'theme'), 2, 'Thick is the default')
	check_spacing(container, 'Thick')
	local thickMin = INV:HeaderMinWidth(container)

	st.config.profile.theme.name = 'thin'
	st:ThemeChanged()
	eq(st:ThemeInset('theme', 'theme'), 1, 'Thin')
	check_spacing(container, 'Thin')

	-- The least width keeps clear, on the left, the room the buttons really
	-- take on the right (the title sits between).
	local span = container.header:GetRight() - container.viewButtons.onebag:GetLeft()
	local closeGap = st:GetCloseButton(container):GetLeft() - container.viewButtons.rows:GetRight()
	eq(INV:HeaderMinWidth(container), 2 * (span + closeGap) + container.title:GetStringWidth(),
		'Thin: HeaderMinWidth follows the real anchors')
	check(INV:HeaderMinWidth(container) < thickMin, "Thin's tighter spacing needs less header")

	st.config.profile.theme.name = 'thick'
	st:ThemeChanged()
	check_spacing(container, 'Thick again')
	eq(INV:HeaderMinWidth(container), thickMin, 'back to Thick: the same least width')
	eq(#take_errors(), 0, 'no errors')
end)
