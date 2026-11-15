-- The bags' fonts (SaftUI-Bags): the category titles in Heading by default
-- (Title font, inventory.fonts.titles), and the texts that are not titles in
-- Text, whatever Title font and Window titles say: the bag window's search box
-- and the gold and free-slot texts along the bottom of a window.
--
-- Real: SaftUI-Bags' config.lua, inventory.lua, container.lua, search.lua,
-- category.lua and options.lua on Core's real AceDB-3.0 world
-- (core/config_helpers.lua), with the window made by hand as
-- bags/theme_test.lua makes it: its footer by INV:InitializeFooter, its search
-- box a bare edit box skinned as INV:InitializeSearch skins it, one category
-- with a title.
-- Stubbed: INV:UpdateGold (the amount of gold, not its font).
local st

local INV, container

local function fresh(client)
	use_client(client)
	load_test_file('core/config_helpers.lua')
	load_test_file('lib/options_walk.lua')
	st = SaftUI
	load_saftui('SaftUI-Core/Utilities/utilities.lua')
	load_saftui('SaftUI-Bags/config.lua')
	apply_defaults()
	_G.StackSplitFrameOkay_Click = function() end
	Enum.AccountCurrencyTransferResult = Enum.AccountCurrencyTransferResult
		or { MaxQuantity = 1, NoValidSourceCharacter = 2, CannotUseCurrency = 3 }
	for _, file in ipairs({ 'inventory', 'itemclasses', 'rules', 'currencies', 'categorydefaults', 'categories', 'category', 'views',
		'container', 'header', 'layout', 'search', 'containers/warbandbank', 'slot', 'movers', 'options' }) do
		if file == 'options' then
			if not SaftUI.OptionsModel then load_saftui('SaftUI-Core/Config/optionsmodel.lua') end
			if not SaftUI.Config.SavedIn then load_saftui('SaftUI-Core/Config/optionsdefault.lua') end
		end
		load_saftui('SaftUI-Bags/' .. file .. '.lua')
	end
	INV = st:GetModule('Inventory')
	st:BindModuleConfig(INV, 'inventory')
	function INV:EnsureCategoryFrames() end
	-- The gold's amount is not under test (it is formatted by LibStringFormat-1.0,
	-- not loaded): only the font of its text.
	function INV:UpdateGold() end
end

-- The bag window, made by hand, with one category: its footer, its search box
-- and a title.
-- before, if given, runs once the profile exists and before anything is made.
local function window(client, before)
	fresh(client)
	load_saftui('SaftUI-Core/Widgets/checkbutton.lua') -- the category's filter box
	if before then before() end
	container = CreateFrame('Frame', 'SaftUIBagsFontsTestBag', UIParent)
	container.id = 'bag'
	container.categories, container.columns = {}, {}
	INV.containers.bag = container
	local scrollFrame = CreateFrame('ScrollFrame', nil, container)
	scrollFrame.ScrollChild = CreateFrame('Frame', nil, scrollFrame)
	scrollFrame:SetScrollChild(scrollFrame.ScrollChild)
	container.scrollFrame = scrollFrame
	st:CreateCloseButton(container)
	st:CreateHeader(container, 'Bags')
	INV:InitializeFooter(container)

	local search = CreateFrame('EditBox', 'SaftUIBagsFontsTestSearch', container.footer)
	search:CreateFontString(nil, 'OVERLAY') -- its text
	st:SkinEditBox(search, 'theme', 'theme')
	search:SetHeight(20)
	container.search = search

	local frame = CreateFrame('Frame', 'SaftUIBagsFontsTestBag_Things', scrollFrame.ScrollChild)
	frame.container, frame.name, frame.slots = container, 'Things', {}
	frame.header = CreateFrame('Button', nil, frame)
	frame.header.text = frame.header:CreateFontString(nil, 'OVERLAY')
	frame:SetSize(200, 150)
	container.categories.Things = frame
	container:Show()
	INV:UpdateConfig()
	return container
end

local function title() return container.categories.Things.header.text end
local function searchText() return (container.search:GetRegions()) end

local TYPEFACE = { font_name = 'Homespun', font_size = 13, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }

for _, client in ipairs({ 'forever', 'retail' }) do
	test('the category titles in Heading by default; the search box and the gold and free-slot texts in Text [' .. client .. ']', function()
		window(client)
		eq(st.defaults.inventory.fonts.titles, 'heading', 'Title font ships as Heading')
		eq(INV.config.fonts.titles, 'heading', 'a profile that never saved it')
		eq(title():GetFontObject(), st:GetFont('heading'), 'the category titles: Heading')
		eq(searchText():GetFontObject(), st:GetFont('normal'), 'the search box: Text')
		eq(container.footer.slots:GetFontObject(), st:GetFont('normal'), 'the free-slot text: Text')
		eq(container.footer.gold.text:GetFontObject(), st:GetFont('normal'), 'the gold: Text')

		-- Window titles (headers.font) is a title font: it does not reach these,
		-- made after it changed or before.
		window(client, function() st.config.profile.headers.font = 'subtitle' end)
		eq(container.footer.slots:GetFontObject(), st:GetFont('normal'), 'Window titles in Subtitle: the free-slot text stays Text')
		eq(container.footer.gold.text:GetFontObject(), st:GetFont('normal'), 'and the gold')
		eq(title():GetFontObject(), st:GetFont('heading'), 'and the category titles')
		st.config.profile.headers.font = 'pixel'
		st:FontsChanged()
		INV:UpdateConfig()
		eq(container.footer.slots:GetFontObject(), st:GetFont('normal'), 'a later change leaves the free-slot text')
		eq(container.footer.gold.text:GetFontObject(), st:GetFont('normal'), 'and the gold')
		st.config.profile.headers.font = 'normal'

		-- Text itself, edited on the Fonts tab, reaches them (shared object).
		st.config.profile.fonts.normal.font_size = 17
		st:GetModule('Fonts'):UpdateFontConfig('normal')
		eq(select(2, container.footer.gold.text:GetFont()), 17, 'the gold follows Text at once')
		st.config.profile.fonts.normal.font_size = st.defaults.fonts.normal.font_size
		st:GetModule('Fonts'):UpdateFontConfig('normal')
		eq(#take_errors(), 0, 'no errors')
	end)

	test('Title font set to a typeface reaches the titles only, not the search box [' .. client .. ']', function()
		window(client)
		INV.config.fonts.titles = TYPEFACE
		INV:UpdateConfig()
		eq(title():GetFontObject(), st:FontObject(TYPEFACE), 'the category titles: the typeface')
		eq(searchText():GetFontObject(), st:GetFont('normal'), 'the search box stays Text')
		eq(container.footer.gold.text:GetFontObject(), st:GetFont('normal'), 'and the gold')
		INV.config.fonts.titles = 'subtitle'
		INV:UpdateConfig()
		eq(title():GetFontObject(), st:GetFont('subtitle'), 'a shared font: the titles')
		eq(searchText():GetFontObject(), st:GetFont('normal'), 'the search box stays Text')
		eq(#take_errors(), 0, 'no errors')
	end)
end

test("Title font's desc says it is the category titles' font", function()
	window('forever')
	local found
	each_option(INV:GetConfigTable(), function(option)
		if option.name == 'Title font' then found = option end
	end)
	check(found, 'the row exists')
	eq(found.desc, 'The font of the category titles.')
	eq(found.type, 'font')
end)

test("a category made by INV:CreateCategory draws its title in Title font, Heading by default", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		window(client)
		local function pool() return {} end -- the slot pool is not under test
		-- The filter box is Blizzard's check button template, which the stubs lack:
		-- a check button with its Text, as bags/theme_test.lua makes it.
		local createFrame = CreateFrame
		_G.CreateFrame = function(frameType, name, parent, template, ...)
			local rest = tostring(template or ''):gsub(',?UICheckButtonTemplate', '')
			local frame = createFrame(frameType, name, parent, rest ~= '' and rest or nil, ...)
			if template and template:find('UICheckButtonTemplate', 1, true) then
				frame.Text = frame:CreateFontString(name and name .. 'Text', 'ARTWORK')
			end
			return frame
		end
		local ok, made = pcall(INV.CreateCategory, INV, 'bag', 'Armor', pool)
		INV.config.fonts.titles = TYPEFACE
		local ok2, second = pcall(INV.CreateCategory, INV, 'bag', 'Weapons', pool)
		_G.CreateFrame = createFrame
		check(ok and ok2, tostring(made) .. tostring(second))
		eq(made.header.text:GetFontObject(), st:GetFont('heading'), client .. ': Heading by default')
		eq(second.header.text:GetFontObject(), st:FontObject(TYPEFACE), client .. ': a typeface')
		INV.config.fonts.titles = 'heading'
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)
