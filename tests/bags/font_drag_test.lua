-- Dragging the Size slider in the dots menu of Bags > Look > Title font (or
-- Icon font), set to a typeface: what one step of the drag does. A bag font is
-- a setting that restyles texts, so a step must restyle the category titles and
-- the slots' item levels and counts, and nothing else: no re-sort of the bags,
-- no repack of the windows, no restyle of every slot's border, no new frame.
-- And a held slider must survive its own writes (the menu and its slider stay
-- the same frames until the button is let go).
--
-- Real: Core's /sui window, model, widgets and body (core/options_window_
-- helpers.lua), Core's AceDB world, edit mode's helpers, the bags' config.lua,
-- inventory.lua, itemclasses.lua, rules.lua, currencies.lua, categorydefaults.lua,
-- categories.lua, category.lua, views.lua, container.lua, header.lua,
-- layout.lua, search.lua, containers/warbandbank.lua, slot.lua, movers.lua
-- and options.lua. The bag window is made by hand, as theme_test.lua makes it:
-- a category of item slots and a category of a currency slot.
load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_options_window()
local OW = st.OptionsWindow

local H = {
	tick = tick_options_window,
	cell = function(key)
		for _, c in ipairs(OW.GetDrawnRows()) do
			if c.row.key == key then return c end
		end
	end,
	close_all = function()
		st.Config:Close()
		stub.in_combat = false
	end,
}

_G.StackSplitFrameOkay_Click = function() end
Enum.AccountCurrencyTransferResult = Enum.AccountCurrencyTransferResult
	or { MaxQuantity = 1, NoValidSourceCharacter = 2, CannotUseCurrency = 3 }
load_saftui('SaftUI-Core/Utilities/utilities.lua')
load_saftui('SaftUI-Bags/config.lua')
apply_defaults()
for _, file in ipairs({ 'inventory', 'itemclasses', 'rules', 'currencies', 'categorydefaults', 'categories', 'category', 'views',
	'container', 'header', 'layout', 'search', 'containers/warbandbank', 'slot', 'movers', 'options' }) do
	load_saftui('SaftUI-Bags/' .. file .. '.lua')
end
local INV = st:GetModule('Inventory')
st:BindModuleConfig(INV, 'inventory')
-- The windows here are made by hand (their frames are bags/'s other tests').
function INV:EnsureCategoryFrames() end
_G.C_CurrencyInfo = { GetBasicCurrencyInfo = function() return { quality = 2 } end }

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

local container = CreateFrame('Frame', 'SaftUIFontDragBag', UIParent)
container.id = 'bag'
container.categories, container.columns = {}, {}
INV.containers.bag = container
local scrollFrame = CreateFrame('ScrollFrame', nil, container)
scrollFrame.ScrollChild = CreateFrame('Frame', nil, scrollFrame)
scrollFrame:SetScrollChild(scrollFrame.ScrollChild)
container.scrollFrame = scrollFrame
st:CreateCloseButton(container)
st:CreateHeader(container, 'Bags')
st:CreateFooter(container)
local search = CreateFrame('EditBox', 'SaftUIFontDragBagSearch', container.footer)
search:CreateFontString(nil, 'OVERLAY')
st:SkinEditBox(search, 'theme', 'theme')
search:SetHeight(20)
search:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', 10, -10)
container.search = search

local things, slots = category(container, 'Things', -60), {}
for i = 1, 6 do slots[i] = item_slot(container, things) end
local armor = category(container, 'Armor', -220)
for i = 1, 6 do item_slot(container, armor) end
container:Show()
INV:UpdateConfig()

------------------------------------------------------------------ counting

local counts
local function reset_counts() counts = {} end
reset_counts()
local function count(name) counts[name] = (counts[name] or 0) + 1 end

-- Counts a module function's calls (it still runs).
local function watch(owner, key, name)
	local real = owner[key]
	owner[key] = function(...) count(name or key); return real(...) end
	return function() owner[key] = real end
end

local restorers = {}
local function start_counting()
	reset_counts()
	for _, key in ipairs({ 'UpdateConfig', 'StyleContainerContents', 'StyleSlot', 'SkinSlot', 'CategoriesChanged',
		'QueueUpdate', 'ReleaseLayout', 'UpdateContainer', 'UpdateVisibleContainers', 'UpdateBagSlotBars',
		'StyleCurrencySlots', 'RegisterMovers', 'MigrateCategories', 'ApplyPosition' }) do
		if INV[key] then restorers[#restorers + 1] = watch(INV, key) end
	end
	restorers[#restorers + 1] = watch(OW, 'Render')
	restorers[#restorers + 1] = watch(st.Config, 'Refresh')
	restorers[#restorers + 1] = watch(LibStub('AceConfigRegistry-3.0'), 'NotifyChange')
	local createFrame, createFont = CreateFrame, CreateFont
	_G.CreateFrame = function(...) count('CreateFrame'); return createFrame(...) end
	_G.CreateFont = function(...) count('CreateFont'); return createFont(...) end
	restorers[#restorers + 1] = function() _G.CreateFrame, _G.CreateFont = createFrame, createFont end
end
local function stop_counting()
	for i = #restorers, 1, -1 do restorers[i]() end
	restorers = {}
end

local COLUS = { font_name = 'Colus', font_size = 15, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }

local function open_title_menu()
	INV.config.fonts.titles = { font_name = 'Colus', font_size = 15, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
	st.Config:Open('Inventory', 'look')
	local c = H.cell('titles')
	stub.click(c.widget.dots)
	return c
end

local function mcell(key)
	for _, c in ipairs(OW.GetMenuFrames().body.cells) do
		if c.row.key == key then return c end
	end
end

local function close_all()
	stub.mouse_buttons.LeftButton = nil
	H.close_all()
end

-- The row's typeface, size set by the drag.
local function look(size)
	return { font_name = 'Colus', font_size = size, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
end

-- Opens Bags > Look, sets the row to a typeface and opens its dots menu.
local function open_menu(key)
	INV.config.fonts[key] = look(15)
	st.Config:Open('Inventory', 'look')
	stub.click(H.cell(key).widget.dots)
	check(OW:IsMenuShown(), key .. ": the typeface menu is open")
end

-- Drags the Size slider of the open menu from 16 up one by one, as the game
-- does: the button held, each step a write. Returns the counts of the steps
-- after the first (which makes what is made once), the slider and its frame.
local function drag(steps, each)
	local slider = mcell('font_size').widget
	local frame = slider.frame
	stub.mouse_buttons.LeftButton = true
	slider.dragging = true
	slider:Commit(16)
	H.tick()
	start_counting()
	for size = 17, 16 + steps do
		local now = mcell('font_size').widget
		check(now == slider and now.frame == frame, 'the held slider is still the slider, at size ' .. size)
		slider.dragging = true
		slider:Commit(size)
		H.tick()
		if each then each(size) end
	end
	stop_counting()
	return slider
end

local function counted(name) return counts[name] or 0 end

test('Title font: a step of the Size drag restyles the titles and nothing else (bug 3)', function()
	open_menu('titles')
	local first = things.header.text
	local slider = drag(10, function(size)
		eq(first:GetFontObject(), st:GetFont(look(size)), 'the title wears the new size at once, ' .. size)
		eq(armor.header.text:GetFontObject(), st:GetFont(look(size)), 'in every category')
	end)
	eq(INV.config.fonts.titles.font_size, 26, 'the last step is saved')
	-- What a step must not do, per ten steps.
	for _, name in ipairs({ 'UpdateConfig', 'StyleContainerContents', 'StyleSlot', 'SkinSlot', 'CategoriesChanged', 'QueueUpdate',
		'ReleaseLayout', 'UpdateBagSlotBars', 'StyleCurrencySlots', 'RegisterMovers', 'MigrateCategories', 'ApplyPosition' }) do
		eq(counted(name), 0, name .. ': no call in ten steps')
	end
	eq(counted('CreateFrame'), 0, 'no frame made')
	eq(counted('Render'), 0, 'the window did not render under the held slider')
	eq(counted('Refresh'), 0, 'no refresh of the options')
	eq(counted('NotifyChange'), 0, 'no change notified')
	eq(counted('CreateFont'), 10, 'a font object for each new size, the one cost left')
	check(OW:IsMenuShown() and mcell('font_size').widget == slider, 'the menu and the slider are still there')
	-- The button let go: one render, as for any slider.
	stub.fire_script(slider.slider, 'OnMouseUp')
	stub.mouse_buttons.LeftButton = nil
	H.tick()
	close_all()
end)

test('Icon font: a step restyles the slots\' texts and nothing else (bug 3)', function()
	open_menu('icons')
	local slot = things.slots[1]
	local other = armor.slots[3]
	drag(10, function(size)
		eq(slot.itemLevel:GetFontObject(), st:GetFont(look(size)), 'the item level, ' .. size)
		eq(slot.Count:GetFontObject(), st:GetFont(look(size)), 'the count')
		eq(other.Count:GetFontObject(), st:GetFont(look(size)), 'every slot of every category')
		eq(slot:GetNormalFontObject(), st:GetFont(look(size)), 'and its button font')
	end)
	for _, name in ipairs({ 'UpdateConfig', 'StyleContainerContents', 'StyleSlot', 'SkinSlot', 'CategoriesChanged', 'QueueUpdate',
		'ReleaseLayout', 'StyleCurrencySlots', 'RegisterMovers' }) do
		eq(counted(name), 0, name .. ': no call in ten steps')
	end
	eq(counted('CreateFrame'), 0, 'no frame made')
	eq(counted('Render'), 0)
	check(counted('CreateFont') <= 10, 'at most a font object for each new size')
	close_all()
end)

test('Icon font reaches a currency slot too', function()
	load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
	local createFrame = CreateFrame
	_G.CreateFrame = function(frameType, name, parent, template, ...)
		if template == 'TokenEntryTemplate' then
			-- Blizzard's template: a button with its icon, count and content.
			local slot = createFrame('CheckButton', name, parent)
			slot.icon = slot:CreateTexture(nil, 'BORDER')
			slot.Count = slot:CreateFontString(nil, 'OVERLAY')
			slot.Count:SetFontObject(st:GetFont('normal'))
			slot.Content = { WatchedCurrencyCheck = slot:CreateTexture(nil, 'OVERLAY') }
			return slot
		end
		local rest = tostring(template or ''):gsub(',?UICheckButtonTemplate', '')
		local frame = createFrame(frameType, name, parent, rest ~= '' and rest or nil, ...)
		if template and template:find('UICheckButtonTemplate', 1, true) then
			frame.Text = frame:CreateFontString(name and name .. 'Text', 'ARTWORK')
		end
		return frame
	end
	local ok, slot = pcall(INV.CreateCurrencySlot, armor)
	_G.CreateFrame = createFrame
	check(ok, tostring(slot))
	INV.config.fonts.icons = look(21)
	start_counting()
	INV:ApplyFonts('icons')
	stop_counting()
	eq(slot.Count:GetFontObject(), st:GetFont(look(21)), "the currency slot's count")
	eq(counted('StyleCurrencySlots'), 0)
	eq(counted('UpdateConfig'), 0)
end)

test('a pick from the list restyles the texts once, not the bags', function()
	INV.config.fonts.titles = 'heading'
	st.Config:Open('Inventory', 'look')
	local w = H.cell('titles').widget
	start_counting()
	w:Pick('face:Colus')
	stop_counting()
	eq(things.header.text:GetFontObject(), st:GetFont(INV.config.fonts.titles), 'the title is in the typeface')
	eq(counted('UpdateConfig'), 0)
	eq(counted('CategoriesChanged'), 0)
	eq(counted('StyleSlot'), 0)
	close_all()
end)

test('a bag font set to a shared font that the Fonts tab then edits still reaches the texts (Heading)', function()
	INV.config.fonts.titles = 'heading'
	INV:ApplyFonts('titles')
	eq(things.header.text:GetFontObject(), st:GetFont('heading'))
	st.config.profile.fonts.heading.font_size = 31
	st:GetModule('Fonts'):UpdateFontConfig('heading')
	eq(select(2, things.header.text:GetFont()), 31, "Heading's object changed, the title follows with no restyle")
	st.config.profile.fonts.heading.font_size = st.defaults.fonts.heading.font_size
	st:GetModule('Fonts'):UpdateFontConfig('heading')
end)

test('no errors', function()
	eq(#take_errors(), 0)
end)
