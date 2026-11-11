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
		eq(drawn(button), 'theme,solid,control', name .. ": Use SaftUI's theme and Solid, as a control")
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
	eq(drawn(container), 'theme,theme,window', "the window: the bags' Theme and Background, as a window")
	for i, slot in ipairs(slots) do
		eq(drawn(slot), 'theme,theme,slot', 'slot ' .. i .. ': the Slot theme and background, as a slot')
	end

	-- Thick, SaftUI's default: each border 2px around what it frames. A slot's
	-- backdrop fills the slot, with the icon inside its border.
	eq(T.around(container.backdrop, container), '-2,2,2,-2', 'the window: Thick, 2px out')
	eq(T.around(st:DrawnFrame(container.search), container.search), '-2,2,2,-2', 'its search box too')
	for i, slot in ipairs(slots) do
		eq(T.around(slot.backdrop, slot.icon), '-2,2,2,-2', 'slot ' .. i .. ': Thick, 2px around the icon')
		eq(T.around(slot.backdrop, slot), '0,0,0,0', 'slot ' .. i .. ': the backdrop fills the slot')
	end

	st.config.profile.theme.name = 'thin'
	st:ThemeChanged()
	eq(T.around(container.backdrop, container), '-1,1,1,-1', "the window: Thin's 1px, no gap")
	eq(T.inset(container.backdrop), 1, "drawn with Thin's one line")
	eq(T.around(st:DrawnFrame(container.search), container.search), '-1,1,1,-1', 'its search box too')
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

test("under Blizzard an Epic item's slot shows the white icon border in the Epic color, through three recolors and a redraw", function()
	local _, slots, currency = bags()
	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	local filled, free = slots[1], slots[2]
	local WHITE = [[Interface\Common\WhiteIconFrame]]
	local function border(slot)
		local own = st.ThemeArt.Get(slot.backdrop).own
		if not (own and own:IsShown()) then return 'off' end
		return tostring(own:GetTexture()) .. ' ' .. T.text(own:GetVertexColor())
	end
	local epicBorder = WHITE .. ' ' .. epic() .. ',1.00'

	filled.info = { quality = 4 } -- an Epic item, as INV:AssignSlot fills it
	INV:SetSlotQualityBorder(filled)
	free.info = { empty = true }
	INV:SetSlotThemeBorder(free) -- as INV:AssignEmptySlot
	INV:SetCurrencyBorder(currency)
	eq(border(filled), epicBorder, "the item's slot: the white icon border, in the Epic color")
	eq(border(currency), epicBorder, "the currency's slot too")
	eq(border(free), 'off', "a free slot's border is off")
	eq(filled.backdrop.backdropInfo and filled.backdrop.backdropInfo.edgeFile, nil, 'no edge line under it')

	-- The Border color picker dragged: a recolor on every move. A recolor takes
	-- the color off; the bags color the slots again, as on any theme recolor.
	local blizzardColors = st.config.profile.templates.blizzard
	for move = 1, 3 do
		blizzardColors.bordercolor = { 0.1 * move, 0.5, 0.5, 1 }
		st:RecolorThemed()
		eq(border(filled), epicBorder, 'move ' .. move .. ": the item keeps the Epic color")
		eq(border(currency), epicBorder, 'move ' .. move .. ": the currency keeps it")
		eq(border(free), 'off', 'move ' .. move .. ": the free slot stays off")
	end

	-- A redraw: a switch away and back.
	st.config.profile.theme.name = 'thin'
	st:ThemeChanged()
	eq(border(filled), 'off', 'under Thin the piece is off (the line is the border)')
	eq(T.edge_rgb(filled.backdrop), epic(), 'and the line is Epic')
	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	eq(border(filled), epicBorder, 'back under Blizzard: Epic again')
	eq(border(currency), epicBorder, 'the currency too')
	eq(border(free), 'off', 'the free slot still off')

	-- Epic changes to a free slot's: the border goes.
	filled.info = { empty = true }
	INV:SetSlotThemeBorder(filled)
	eq(border(filled), 'off', 'emptied: off')
	eq(#take_errors(), 0, 'no errors')
end)

test("under Blizzard a bag slot's pushed and highlight are Blizzard's files", function()
	local _, slots, currency = bags()
	local LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }
	local function depth(region)
		local layer, sublevel = region:GetDrawLayer()
		return LAYERS[layer] * 100 + (sublevel or 0)
	end
	local PUSHED, HIGHLIGHT = [[Interface\Buttons\UI-Quickslot-Depress]], [[Interface\Buttons\ButtonHilight-Square]]

	-- The blend SetHighlightTexture gives a texture handed with none, which
	-- st:SkinActionButton's flat hover keeps: a blue tint, not an opaque square.
	local probe = CreateFrame('Button')
	local probeTexture = probe:CreateTexture()
	probe:SetHighlightTexture(probeTexture)
	local made = probeTexture:GetBlendMode()

	-- Under Thick: the pushed art is cleared and the hover a flat blue over the icon, as before.
	local slot = slots[1]
	eq(slot:GetPushedTexture():GetTexture(), '', 'Thick: the pushed art is cleared')
	eq(slot.hover:GetTexture(), st.BLANK_TEX, 'Thick: the hover is the flat texture')
	eq(T.text(slot.hover:GetVertexColor()), T.text(st.config.profile.colors.button.blue:GetRGB()) .. ',1.00', 'Thick: blue')
	eq(slot.hover:GetBlendMode(), made, 'Thick: the blend the setter gave it when the slot was made')

	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	INV:SkinSlot(currency) -- the module's own list of currency slots has none here
	for name, button in pairs({ slot = slot, currency = currency }) do
		local pushed, highlight = button:GetPushedTexture(), button:GetHighlightTexture()
		eq(pushed:GetTexture(), PUSHED, name .. ": pushed is Blizzard's file")
		eq(highlight:GetTexture(), HIGHLIGHT, name .. ": the highlight is Blizzard's file")
		eq(highlight:GetBlendMode(), 'ADD', name .. ': the highlight is additive')
		for what, region in pairs({ pushed = pushed, highlight = highlight }) do
			eq(T.text(region:GetVertexColor()), '1.00,1.00,1.00,1.00', name .. ' ' .. what .. ' has no tint')
			eq(T.around(region, button), '0,0,0,0', name .. ' ' .. what .. ' covers the button, the ring\'s footprint')
			local ring = st.ThemeArt.Get(button.backdrop).over.Ring
			check(depth(region) > depth(ring), name .. ' ' .. what .. ' draws over the ring')
			check(depth(region) > depth(button.icon), name .. ' ' .. what .. ' draws over the icon')
			check(depth(region) < depth(button.Count), name .. ' ' .. what .. ' draws under the count')
		end
	end

	-- Back to Thick: the flat hover again, over the icon inside the border, and the pushed art cleared.
	st.config.profile.theme.name = 'thick'
	st:ThemeChanged()
	eq(slot:GetPushedTexture():GetTexture(), '', 'Thick again: the pushed art is cleared')
	eq(slot:GetHighlightTexture():GetTexture(), st.BLANK_TEX, 'Thick again: the flat hover')
	eq(T.around(slot:GetHighlightTexture(), slot.icon), '0,0,0,0', 'Thick again: over the icon')
	eq(T.text(slot:GetHighlightTexture():GetVertexColor()), T.text(st.config.profile.colors.button.blue:GetRGB()) .. ',1.00', 'Thick again: blue')
	eq(slot:GetHighlightTexture():GetBlendMode(), made, 'Thick again: the blend the setter gave it when the slot was made')
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

local THEME_VALUES = { 'theme', 'thick', 'thin', 'blizzard', 'none' }
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
	local inset = st:ThemeInset('theme', 'theme', 'control')
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
	eq(st:ThemeInset('theme', 'theme', 'control'), 2, 'Thick is the default')
	check_spacing(container, 'Thick')
	local thickMin = INV:HeaderMinWidth(container)

	st.config.profile.theme.name = 'thin'
	st:ThemeChanged()
	eq(st:ThemeInset('theme', 'theme', 'control'), 1, 'Thin')
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

test('the view buttons are controls, and their gaps are 3 and 4 under Blizzard', function()
	local container = bags()
	INV:CreateViewButtons(container)
	INV:UpdateConfig('bag')
	for _, view in ipairs(VIEWS) do
		eq(drawn(container.viewButtons[view]), 'theme,theme,control', view .. "'s button draws as a control")
	end
	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	local between, closeGap = INV:ViewButtonGaps()
	eq(between, 3, "a control's inset is 0 under Blizzard: the buttons' frames are the clear room apart")
	eq(closeGap, 4, "the close button's outline 1 more from the first")
	for _, view in ipairs(VIEWS) do
		eq(container.viewButtons[view].backdrop.backdropInfo, nil, view .. ': no backdrop of SaftUI\'s under Blizzard')
	end
	for i = 2, #VIEWS do
		local a, b = container.viewButtons[VIEWS[i - 1]], container.viewButtons[VIEWS[i]]
		eq(b:GetLeft() - a:GetRight(), 3, VIEWS[i - 1] .. ' and ' .. VIEWS[i] .. ' are 3 apart')
	end
	eq(#take_errors(), 0, 'no errors')
end)

-- The panel button's pieces shown on a button, as 'Left=Up,Middle=Up,Right=Up'
-- (each piece by its left texture coordinate and the state its file is).
local PIECE_BY_LEFT = { ['0.00000'] = 'Left', ['0.09375'] = 'Middle', ['0.53125'] = 'Right' }
local function panel(button)
	local out = {}
	for _, region in ipairs({ button:GetRegions() }) do
		local file = region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAlpha() > 0 and region:GetTexture()
		local state = type(file) == 'string' and file:match('^Interface\\Buttons\\UI%-Panel%-Button%-(%a+)$')
		if state and state ~= 'Highlight' then
			out[#out + 1] = (PIECE_BY_LEFT[('%.5f'):format((region:GetTexCoord()))] or '?') .. '=' .. state
		end
	end
	table.sort(out)
	return table.concat(out, ',')
end

test("the window's view button is pressed under Blizzard, through a recolor, a redraw and a view change, and lit Blue under Thick", function()
	local container = bags()
	INV:CreateViewButtons(container)
	INV:UpdateConfig('bag')
	local blue = T.text(st.config.profile.colors.button.blue:GetRGB()) .. ',1.00'
	local function check_lit(label)
		local current = INV:GetView('bag')
		for _, view in ipairs(VIEWS) do
			local button = container.viewButtons[view]
			if st:IsBlizzardLook('theme', 'theme') then
				eq(panel(button), view == current and 'Left=Down,Middle=Down,Right=Down' or 'Left=Up,Middle=Up,Right=Up',
					label .. ': ' .. view .. (view == current and ' (the current view) pressed' or ' up'))
			else
				eq(panel(button), '', label .. ': ' .. view .. ' is no panel button')
				if view == current then
					eq(T.edge(button.backdrop), blue, label .. ': ' .. view .. ' (the current view) lit Blue')
				else
					check(T.edge(button.backdrop) ~= blue, label .. ': ' .. view .. ' not lit')
				end
			end
		end
	end
	check_lit('Thick')

	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	for _, button in pairs(container.viewButtons) do stub.fire_script(button, 'OnSizeChanged', button:GetSize()) end
	check_lit('Blizzard')
	st:RecolorThemed()
	check_lit('Blizzard, after a recolor')
	st:RedrawThemed()
	check_lit('Blizzard, after a redraw')
	-- A view change as INV:SetView makes it, short of laying the window out
	-- (INV:ApplyView needs the bag world this file doesn't build): the view
	-- saved, then its buttons lit.
	local other = INV:GetView('bag') == 'rows' and 'onebag' or 'rows'
	INV.config.bag.view = other
	INV:UpdateViewButtons('bag')
	eq(INV:GetView('bag'), other, 'the view changed')
	check_lit('Blizzard, after a view change')

	st.config.profile.theme.name = 'thick'
	st:ThemeChanged()
	check_lit('Thick again')
	eq(#take_errors(), 0, 'no errors')
end)

test('the Edit toggle is a panel button, pressed while checked', function()
	-- INV:CreateContainer makes it (container.lua), from Blizzard templates the
	-- stubs lack, so its call is read from the source and made here the same
	-- way, on the bag window's header. UICheckButtonTemplate stands in as a
	-- check button with its Text.
	local source = read_saftui_source('SaftUI-Bags/container.lua')
	check(source:find("local filterButton = st:CreateCheckButton(nil, container.header, 'button')", 1, true) ~= nil,
		"container.lua makes the Edit toggle styled 'button'")
	local container = bags()
	load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
	local createFrame = CreateFrame
	_G.CreateFrame = function(frameType, name, parent, template, ...)
		local rest = tostring(template or ''):gsub(',?UICheckButtonTemplate', '')
		local frame = createFrame(frameType, name, parent, rest ~= '' and rest or nil, ...)
		if template and template:find('UICheckButtonTemplate', 1, true) then
			frame.Text = frame:CreateFontString(name and name .. 'Text', 'ARTWORK')
		end
		return frame
	end
	local edit = st:CreateCheckButton(nil, container.header, 'button')
	_G.CreateFrame = createFrame
	edit:SetSize(40, 20)
	edit.text:SetAllPoints(edit)
	edit:SetFont('pixel')
	edit:SetText('Edit')

	eq(panel(edit), '', 'Thick: no panel button')
	eq(edit:GetCheckedTexture():GetAlpha(), 1, "Thick: SaftUI's flat check")
	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	stub.fire_script(edit, 'OnSizeChanged', 40, 20)
	eq(panel(edit), 'Left=Up,Middle=Up,Right=Up', "Blizzard: Blizzard's panel button")
	eq(edit:GetCheckedTexture():GetAlpha(), 0, 'its flat check hidden')
	edit:SetChecked(true)
	eq(panel(edit), 'Left=Down,Middle=Down,Right=Down', 'checked: pressed')
	edit:SetChecked(false)
	eq(panel(edit), 'Left=Up,Middle=Up,Right=Up', 'unchecked: up')
	st.config.profile.theme.name = 'thick'
	st:ThemeChanged()
	eq(panel(edit), '', 'Thick again: no panel button')
	eq(edit:GetCheckedTexture():GetAlpha(), 1, 'its flat check again')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the bank's bag slots

-- Forever's bank bar: its bag-slot buttons are SaftUI's own, made by the real
-- INV:UpdateBankBagSlots (containers/bank.lua). The bar is made by hand, since
-- INV:InitializeBankBagSlots makes its buy button from Blizzard's
-- BankPanelPurchaseButtonScriptTemplate, which the stubs lack. C_Bank,
-- ItemLocation and C_Item.DoesItemExist stand in as far as the update reads
-- them: one bought bag tab, holding no bag, so the buy button stays hidden.
test("under Blizzard, a bank bag-slot button's ring is over its icon", function()
	fresh()
	load_saftui('SaftUI-Bags/containers/bank.lua')
	_G.C_Bank = {
		FetchMaxNumBankTabs = function() return 2 end,
		FetchNumPurchasedBankTabs = function() return 2 end,
		FetchPurchasedBankTabData = function() return { [1] = {}, [2] = {} } end,
	}
	Enum.BankType = { Character = 0, Account = 2 }
	_G.ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end }
	_G.C_Item = { DoesItemExist = function() return false end }
	st.config.profile.theme.name = 'blizzard'

	local bar = st:CreateFrame('Frame', 'SaftUIThemeTestBankBagBar', UIParent)
	bar.slots, bar.purchaseButton = {}, CreateFrame('Button', nil, bar)
	INV:UpdateBankBagSlots(bar)
	local slot = bar.slots[2]
	check(slot ~= nil, 'the bag tab has its button')
	if not slot then return end

	local art = st.ThemeArt.Get(slot.backdrop)
	local ring = art and art.over.Ring
	eq(ring and ring:GetParent(), slot, "the ring is a texture of the button's own")
	local LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }
	local function depth(region)
		local layer, sublevel = region:GetDrawLayer()
		return LAYERS[layer] * 100 + (sublevel or 0)
	end
	check(ring and depth(ring) > depth(slot.icon), 'the ring draws over the icon')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ windows under Blizzard

-- The metal's shown pieces, as T.art lists them.
local METAL = table.concat({
	'BottomEdge=_UI-Frame-Metal-EdgeBottom',
	'BottomLeftCorner=UI-Frame-Metal-CornerBottomLeft',
	'BottomRightCorner=UI-Frame-Metal-CornerBottomRight',
	'LeftEdge=!UI-Frame-Metal-EdgeLeft',
	'RightEdge=!UI-Frame-Metal-EdgeRight',
	'TopEdge=_UI-Frame-Metal-EdgeTop',
	'TopLeftCorner=UI-Frame-Metal-CornerTopLeft',
	'TopRightCorner=UI-Frame-Metal-CornerTopRight',
}, ',')

-- container.lua's CLOSE_INSET: how far in from the header's right edge the
-- close button sits, and the view buttons while it's in the metal's socket.
local CLOSE_INSET = 10

-- Thick's header strip: its border color at 0.4.
local THICK_STRIP = '0.30,0.30,0.30,0.40'

-- A region's first anchor as text, 'POINT relative RELPOINT x,y', with a
-- window's header, close button and drawn frame (its backdrop) named.
local function anchor(region, container)
	local names = { [container.header] = 'header', [st:GetCloseButton(container)] = 'close', [container.backdrop] = 'backdrop' }
	local point, rel, relPoint, x, y = region:GetPoint(1)
	return ('%s %s %s %s'):format(tostring(point), names[rel] or tostring(rel), tostring(relPoint), T.text(x, y))
end

-- Where the close button sits in the metal's socket on this client: TOPRIGHT
-- of the window's drawn frame, at Blizzard's spot (st.ThemeArt.Close).
local function socket()
	local close = st.ThemeArt.Close()
	return 'TOPRIGHT backdrop TOPRIGHT ' .. T.text(close.x, close.y)
end

-- Checks the view buttons line up from the close button (the gap INV:ViewButtonGaps
-- gives), or from the header's right edge while the close button is in the socket.
local function check_view_buttons(container, socketed, label)
	local rows = container.viewButtons.rows
	local _, closeGap = INV:ViewButtonGaps()
	if socketed then
		eq(anchor(rows, container), 'RIGHT header RIGHT ' .. T.text(-CLOSE_INSET, 0),
			label .. ": the last view button lines up from the header's right edge")
		eq(T.text(rows:GetRight()), T.text(container.header:GetRight() - CLOSE_INSET), label .. ': CLOSE_INSET in')
	else
		eq(anchor(rows, container), 'RIGHT close LEFT ' .. T.text(-closeGap, 0),
			label .. ": the last view button lines up from the close button's left")
	end
	-- The least width keeps the room the buttons really take on the right clear
	-- on the left, the title between.
	local span = container.header:GetRight() - container.viewButtons.onebag:GetLeft()
	eq(T.text(INV:HeaderMinWidth(container)), T.text(2 * (span + closeGap) + container.title:GetStringWidth()),
		label .. ': HeaderMinWidth follows the real anchors')
end

-- A slot's white icon border: 'file r,g,b,a' while shown, 'off' otherwise.
local function white_border(slot)
	local art = st.ThemeArt.Get(slot.backdrop)
	local own = art and art.own
	if not (own and own:IsShown()) then return 'off' end
	return tostring(own:GetTexture()) .. ' ' .. T.text(own:GetVertexColor())
end

test('the bag and bank windows are windows', function()
	local bag = bags()
	local bank = CreateFrame('Frame', 'SaftUIThemeTestBank', UIParent)
	bank.id = 'bank'
	bank.slots, bank.categories, bank.columns = {}, {}, {}
	INV.containers.bank = bank
	local scrollFrame = CreateFrame('ScrollFrame', nil, bank)
	scrollFrame.ScrollChild = CreateFrame('Frame', nil, scrollFrame)
	scrollFrame:SetScrollChild(scrollFrame.ScrollChild)
	bank.scrollFrame = scrollFrame
	st:CreateCloseButton(bank)
	st:CreateHeader(bank, 'Bank')
	st:CreateFooter(bank)
	bank:Show()
	INV:UpdateConfig()
	eq(drawn(bag), 'theme,theme,window', "the bag window: the bags' Theme and Background, as a window")
	eq(drawn(bank), 'theme,theme,window', 'the bank window too')

	-- Picking a bank window draws the other one again, as a window.
	local kinds = {}
	local draw = st.SetBackdrop
	st.SetBackdrop = function(self, frame, theme, background, kind)
		kinds[#kinds + 1] = (frame == bank and 'bank' or tostring(frame)) .. ':' .. tostring(kind)
		return draw(self, frame, theme, background, kind)
	end
	INV:SelectBankCategory(bag.header)
	st.SetBackdrop = draw
	eq(table.concat(kinds, ','), 'bank:window', 'the window not picked is drawn again as a window')

	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	eq(T.art(bag.backdrop), METAL, 'under Blizzard the bag window wears the metal')
	eq(T.art(bank.backdrop), METAL, 'the bank window too')
	eq(#take_errors(), 0, 'no errors')
end)

-- Review Focus 1.
test('Thick, Blizzard, Thick with a bag window open', function()
	local container, slots = bags()
	INV:CreateViewButtons(container)
	INV:UpdateConfig('bag')
	local filled = slots[1]
	filled.info = { quality = 4 } -- an Epic item, as INV:AssignSlot fills it
	INV:SetSlotQualityBorder(filled)
	local close = st:GetCloseButton(container)
	local epicBorder = [[Interface\Common\WhiteIconFrame]] .. ' ' .. epic() .. ',1.00'

	local function expect(name)
		local blizzard = name == 'Blizzard'
		if blizzard then
			eq(white_border(filled), epicBorder, name .. ": the Epic item's slot: the white icon border in the Epic color")
			eq(T.art(container.backdrop), METAL, name .. ': the window wears the metal')
			eq(st:CloseButtonInSocket(container), true, name .. ": the close button in the metal's socket")
			eq(anchor(close, container), socket(), name .. ": at TOPRIGHT of the window's drawn frame, at Blizzard's spot")
		else
			eq(T.edge_rgb(filled.backdrop), epic(), name .. ": the Epic item's slot: its border in the Epic color")
			eq(white_border(filled), 'off', name .. ': no white icon border')
			eq(T.art(container.backdrop), '', name .. ': no metal')
			eq(st:CloseButtonInSocket(container), false, name .. ': the close button out of the socket')
			eq(anchor(close, container), 'RIGHT header RIGHT -10.00,0.00', name .. ': at the right of the header')
		end
		check_view_buttons(container, blizzard, name)
	end

	expect('Thick')
	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	expect('Blizzard')
	st.config.profile.theme.name = 'thick'
	st:ThemeChanged()
	expect('Thick again')
	eq(#take_errors(), 0, 'no errors')
end)

-- Review Focus 3. Strips and close buttons follow SaftUI's theme, not their
-- window's Theme.
test("a window overridden to Blizzard under SaftUI's Thick: metal, Thick's strip, SaftUI's close button where it was", function()
	local container = bags()
	INV:CreateViewButtons(container)
	INV:UpdateConfig('bag')
	local look = INV:GetConfigTable().args.look
	look.set({ 'theme' }, 'blizzard') -- Bags > Look > Theme
	local close = st:GetCloseButton(container)
	eq(T.art(container.backdrop), METAL, "the bags' Theme Blizzard: the window wears the metal")
	eq(T.fill(container.header), THICK_STRIP, "the header keeps SaftUI's theme's strip, Thick's")
	eq(T.text(close:GetSize()), '24.00,24.00', 'the close button keeps its own look: 24 square')
	check(close.icon:IsShown(), 'with its X')
	eq(close:GetNormalTexture(), nil, 'and no Blizzard art')
	eq(st:CloseButtonInSocket(container), false, 'not in the socket')
	eq(anchor(close, container), 'RIGHT header RIGHT -10.00,0.00', 'where it was, at the right of the header')
	check_view_buttons(container, false, 'overridden to Blizzard')
	eq(#take_errors(), 0, 'no errors')
end)

-- The other way round: a window's own Theme changes with no theme redraw, and
-- its close button follows into the socket and out at once.
test("a window overridden to Thick under SaftUI's Blizzard: no metal, Blizzard's close button back in the header, and into the socket again", function()
	local container = bags()
	INV:CreateViewButtons(container)
	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	local close = st:GetCloseButton(container)
	eq(st:CloseButtonInSocket(container), true, "SaftUI's theme Blizzard: in the socket")
	check_view_buttons(container, true, 'Blizzard')

	local look = INV:GetConfigTable().args.look
	look.set({ 'theme' }, 'thick') -- Bags > Look > Theme
	eq(T.art(container.backdrop), '', "the bags' Theme Thick: no metal")
	eq(st:CloseButtonInSocket(container), false, 'the close button out of the socket at once')
	eq(close:GetNumPoints(), 1, 'one point')
	eq(anchor(close, container), 'RIGHT header RIGHT -10.00,0.00', 'back at the right of the header')
	eq(close:GetNormalTexture() and close:GetNormalTexture():GetAtlas(), 'RedButton-Exit',
		"in SaftUI's theme's look, Blizzard's")
	check_view_buttons(container, false, 'overridden to Thick')

	look.set({ 'theme' }, 'theme')
	eq(T.art(container.backdrop), METAL, "Use SaftUI's theme again: the metal")
	eq(st:CloseButtonInSocket(container), true, 'back in the socket')
	eq(anchor(close, container), socket(), "at TOPRIGHT of the window's drawn frame, at Blizzard's spot")
	check_view_buttons(container, true, "Use SaftUI's theme again")
	eq(#take_errors(), 0, 'no errors')
end)
