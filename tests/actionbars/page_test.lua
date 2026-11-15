-- The /sui Action Bars page (SaftUI-ActionBars/options.lua and textoptions.lua):
-- All bars first in the Bar picker, then each bar, then the extra buttons; each
-- bar one page with no tabs (This bar, Layout, Visibility, Text, then
-- Position); the four texts as menu items; every shared setting's share (the
-- marks, the hover line, the diff icon and its tooltip, Reset, All and
-- Multiple) and every setting's own reset (default); Blizzard's cooldown
-- numbers setting as the Cooldown item's Show box on All bars; edit mode's
-- click opening a bar's page; search into the texts' menus.
--
-- Real: SaftUI-ActionBars' files but hideblizzard.lua and keybindmode.lua, in
-- TOC order, over Core's helpers (load_core_helpers), and the options model
-- (Config/optionsmodel.lua), which reads the page as the window does. The
-- drawing case also loads the widgets, the body and the window's files and
-- draws the page on a body (OB.New), as the window does.
-- Made by hand (as cooldown_numbers_test.lua does): LibActionButton-1.0 as far
-- as the files use it when they load; every bar a plain table with its 12 or
-- 10 buttons and AB.built set, since AB:Build needs the library's real
-- buttons; the extra buttons' holders plain frames. AB:UpdateBar, AB:LayoutBar,
-- AB:LayoutExtra and AB:UpdateConfig are counters here: the bars are secure,
-- and what they do is tested elsewhere (cooldown_numbers_test.lua and
-- shared_settings_test.lua run them for real). AB:UpdateBars is the real one,
-- so it counts an UpdateBar per bar.

local CVAR = 'countdownForCooldowns'

local FILES = {
	'SaftUI-ActionBars/init.lua',
	'SaftUI-ActionBars/shared.lua',
	'SaftUI-ActionBars/skin.lua',
	'SaftUI-ActionBars/bars.lua',
	'SaftUI-ActionBars/buttons.lua',
	'SaftUI-ActionBars/petbar.lua',
	'SaftUI-ActionBars/stancebar.lua',
	'SaftUI-ActionBars/bindings.lua',
	'SaftUI-ActionBars/extras.lua',
	'SaftUI-ActionBars/textoptions.lua',
	'SaftUI-ActionBars/options.lua',
}

local st, AB, OM, calls

local function count(name)
	return function(_, id) calls[#calls + 1] = name .. (id and (':' .. id) or '') end
end

-- A fresh world (see the top) on a new profile, converted as at login.
local function fresh()
	reset_world()
	load_core_helpers()
	st = SaftUI
	load_test_file('actionbars/fixtures/libactionbutton.lua')
	load_saftui('SaftUI-ActionBars/config.lua')
	apply_defaults()
	for _, file in ipairs(FILES) do load_saftui(file) end
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionsdefault.lua') -- st.Config.SavedIn, the reset sources
	load_test_file('lib/options_walk.lua')
	OM = st.OptionsModel
	AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
	stub.cvars[CVAR] = '1'
	AB:ConvertProfile()
	AB.bars, AB.extras = {}, {}
	for _, id in ipairs(AB.BAR_IDS) do
		-- A named frame, as the game's: st:ValidateAnchor resolves the name a bar
		-- is anchored to and walks the bars' points.
		AB.bars[id] = CreateFrame('Frame', AB:GetBarFrameName(id), UIParent)
		AB.bars[id].id, AB.bars[id].buttons = id, {}
		for i = 1, (id == 'pet' or id == 'stance') and 10 or 12 do AB.bars[id].buttons[i] = {} end
	end
	for _, id in ipairs(AB.EXTRA_IDS) do AB.extras[id] = CreateFrame('Frame', nil, UIParent) end
	AB.built = true
	calls = {}
	AB.UpdateBar, AB.LayoutBar = count('UpdateBar'), count('LayoutBar')
	AB.LayoutExtra, AB.UpdateConfig = count('LayoutExtra'), count('UpdateConfig')
end

-- The tree the window reads, built now.
local function root() return { ActionBars = AB:GetConfigTable() } end

-- The page with pick chosen (nil: the first, All bars).
local function view(r, pick) return OM.BuildView(r, 'ActionBars', { pick = pick }) end

local function titles(v)
	local out = {}
	for _, section in ipairs(v.sections) do out[#out + 1] = section.title or '' end
	return table.concat(out, ',')
end

local function section(v, title)
	for _, s in ipairs(v.sections) do
		if s.title == title then return s end
	end
end

local function keys(s)
	local out = {}
	for _, row in ipairs(s.rows) do out[#out + 1] = row.key end
	return table.concat(out, ',')
end

-- The row with key on pick's page.
local function row(r, pick, key)
	for _, s in ipairs(view(r, pick).sections) do
		for _, each in ipairs(s.rows) do
			if each.key == key then return each end
		end
	end
	error('no row ' .. key .. ' on ' .. tostring(pick), 2)
end

-- An item's menu, as the menu reads it: its tree and its row with key.
local function menu_row(item, key)
	local menuRoot = OM.MenuRoot(item.option)
	for _, s in ipairs(OM.BuildView(menuRoot, OM.MENU_KEY).sections) do
		for _, each in ipairs(s.rows) do
			if each.key == key then return menuRoot, each end
		end
	end
	error('no menu row ' .. key, 2)
end

-- A menu's option as a row, hidden or not: the model leaves a hidden row out
-- of a view (the Size and Outline of a text on a shared font), but its get,
-- set, share and default still work. -> the menu's root, the row.
local function menu_setting(item, key)
	local menuRoot = OM.MenuRoot(item.option)
	return menuRoot, { key = key, option = menuRoot[OM.MENU_KEY].args[key], path = { OM.MENU_KEY, key } }
end

-- The keys of an item's menu as drawn: a hidden row is not among them.
local function menu_keys(item)
	local out = {}
	for _, s in ipairs(OM.BuildView(OM.MenuRoot(item.option), OM.MENU_KEY).sections) do
		for _, each in ipairs(s.rows) do out[#out + 1] = each.key end
	end
	return table.concat(out, ',')
end

local function differs(state)
	local out = {}
	for _, entry in ipairs(state.differs) do out[#out + 1] = entry.name .. ': ' .. entry.value end
	return table.concat(out, '; ')
end

local function labels(list)
	local out = {}
	for _, entry in ipairs(list) do out[#out + 1] = entry.label end
	return table.concat(out, ',')
end

local function dump(value)
	if type(value) ~= 'table' then return tostring(value) end
	local ks = {}
	for k in pairs(value) do ks[#ks + 1] = k end
	table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
	local out = {}
	for _, k in ipairs(ks) do out[#out + 1] = tostring(k) .. '=' .. dump(value[k]) end
	return '{' .. table.concat(out, ',') .. '}'
end

local function no_errors() eq(table.concat(take_errors(), '\n'), '', 'no errors') end

------------------------------------------------------------------ the page

test('the picker: All bars first, then the bars, then the extras; nothing above it', function()
	fresh()
	local r = root()
	local v = view(r)
	local picked = {}
	for _, entry in ipairs(v.picker.values) do picked[#picked + 1] = entry.key end
	eq(table.concat(picked, ','), 'all,bar1,bar2,bar3,bar4,bar5,bar6,bar7,bar8,pet,stance,extra,zone,vehicleleave',
		'All bars, the bars, the extras')
	eq(v.picker.values[1].name, 'All bars', 'named All bars')
	eq(v.picker.name, 'Bar', 'the picker is labelled Bar')
	eq(v.picker.selected, 'all', 'the page opens on All bars')
	for key, option in pairs(r.ActionBars.args) do
		eq(option.type, 'group', key .. ': the page holds only its picks (no Theme, Background or Cooldown numbers above them)')
	end
	no_errors()
end)

test('All bars: Look, Layout, Visibility, Text; no tabs', function()
	fresh()
	local v = view(root())
	eq(titles(v), 'Look,Layout,Visibility,Text', 'its sections, in order')
	eq(#v.tabs, 0, 'no tabs')
	eq(keys(section(v, 'Look')), 'theme,background', 'Look')
	eq(keys(section(v, 'Layout')), 'buttons,perrow,size,spacing,growth', 'Layout')
	eq(keys(section(v, 'Visibility')), 'visibility', 'Visibility (Faded opacity hidden while no bar fades)')
	eq(keys(section(v, 'Text')), 'hotkey,count,macro,countdown', 'Text: the four texts')
	for _, each in ipairs(section(v, 'Text').rows) do
		eq(each.type .. ' ' .. each.size, 'item small', each.key .. ': a small item, so the four make one line')
	end
	local layout = section(v, 'Layout')
	eq(layout.rows[1].option.max, 12, "Buttons goes to a bar's 12")
	eq(layout.rows[2].option.max, 12, 'Buttons per row too')
	eq(layout.rows[5].name, 'First button', 'growth is First button')
	eq(section(v, 'Visibility').rows[1].name, 'Show', 'visibility is Show')
	no_errors()
end)

test('a bar: This bar, Layout, Visibility, Text, then Position last; the pet and stance bars have two texts', function()
	fresh()
	local r = root()
	local v = view(r, 'bar3')
	eq(titles(v), 'This bar,Layout,Visibility,Text,Position', "Bar 3's sections, Position last")
	eq(#v.tabs, 0, 'no tabs')
	eq(keys(section(v, 'This bar')), 'enable', 'This bar holds Enable')
	eq(section(v, 'This bar').rows[1].size, 'small', 'small')
	eq(keys(section(v, 'Layout')), 'buttons,perrow,size,spacing,growth', 'Layout as on All bars')
	eq(section(v, 'Layout').rows[1].option.max, 12, 'Buttons up to its 12')
	eq(section(v, 'Layout').rows[2].option.max, 12, 'Buttons per row up to its 12')
	eq(keys(section(v, 'Text')), 'hotkey,count,macro,countdown', 'its four texts')
	eq(section(v, 'Position').rows[1].type, 'position', 'its Position block')
	eq(section(v, 'Position').rows[1].option.target, 'name', 'with its TO part (the frame it sits on)')
	eq(r.ActionBars.args.bar3.childGroups, nil, 'no childGroups: one page')

	for _, id in ipairs({ 'pet', 'stance' }) do
		local pv = view(r, id)
		eq(titles(pv), 'This bar,Layout,Visibility,Text,Position', id .. "'s sections")
		eq(keys(section(pv, 'Text')), 'hotkey,countdown', id .. ': the hotkey and the cooldown numbers only')
		eq(section(pv, 'Layout').rows[1].option.max, 10, id .. ': Buttons up to its 10')
		eq(section(pv, 'Layout').rows[2].option.max, 10, id .. ': Buttons per row up to its 10')
	end

	-- A bar following All bars' 12 shows at most its own count.
	eq(OM.Get(r, row(r, 'pet', 'buttons')), 10, "the pet bar follows All bars' 12 and shows its 10")
	eq(OM.Get(r, row(r, 'pet', 'perrow')), 10, 'Buttons per row too')
	eq(OM.Get(r, row(r, 'bar3', 'buttons')), 12, 'Bar 3 shows 12')

	-- The extras keep their page: General with Scale or Size, then Position.
	local ev = OM.BuildView(r, 'ActionBars', { pick = 'extra' })
	eq(ev.tabs[1] and ev.tabs[1].key, 'general', 'the extra action button keeps its General tab')
	eq(ev.sections[#ev.sections].title, 'Position', 'and its Position last')
	no_errors()
end)

test('a change on a bar is its own; on All bars every following bar takes it', function()
	fresh()
	local r = root()
	local size = row(r, 'bar3', 'size')
	eq(OM.Set(r, size, 40), true, 'set')
	eq(AB:IsOwn('bar3', 'size'), true, "Bar 3's size is its own now")
	eq(AB:GetBarConfig('bar3').size, 40, 'and it shows')
	eq(AB:GetBarConfig('bar2').size, 45, 'Bar 2 still follows')
	eq(table.concat(calls, ','), 'UpdateBar:bar3', 'Bar 3 is updated, nothing else')
	r = root()
	local state = OM.ShareState(r, row(r, 'bar3', 'size'))
	eq(state.member, true, 'a bar is a member page')
	eq(state.own, true, 'its row is own')
	eq(state.offers, true, 'and offers Reset and Apply to')
	eq(state.page, 'Bar 3', 'named Bar 3')
	eq(state.source, 'All bars', 'following All bars')
	eq(state.shared, '45', "whose value Own's tooltip names")
	eq(OM.ShareState(r, row(r, 'bar3', 'spacing')).offers, false, 'a row the bar follows offers nothing')

	calls = {}
	eq(OM.Set(r, row(r, 'all', 'spacing'), 5), true, "set All bars' spacing")
	eq(#calls, #AB.BAR_IDS, 'every bar is updated')
	for _, id in ipairs(AB.BAR_IDS) do eq(AB:GetBarConfig(id).spacing, 5, id .. ' takes it') end
	calls = {}
	OM.Set(r, row(r, 'all', 'size'), 50)
	eq(AB:GetBarConfig('bar3').size, 40, 'Bar 3 keeps its own size')
	eq(AB:GetBarConfig('pet').size, 30, 'the pet bar its 30')
	eq(AB:GetBarConfig('bar1').size, 50, 'Bar 1 takes 50')

	-- Enable and Position are the bar's own, and apply through UpdateBar and LayoutBar.
	calls = {}
	OM.Set(r, row(r, 'bar3', 'enable'), false)
	eq(AB.config.bar3.enable, false, 'Enable writes the bar')
	eq(table.concat(calls, ','), 'UpdateBar:bar3', 'and updates it')
	calls = {}
	OM.Set(r, row(r, 'bar3', 'position'), 'x_off', 12)
	eq(AB.config.bar3.position.x_off, 12, 'Position writes the bar')
	eq(table.concat(calls, ','), 'LayoutBar:bar3', 'and lays it out')
	no_errors()
end)

test('a new profile: All bars shows the diff icon on Buttons per row and Button size, with who differs', function()
	fresh()
	local r = root()
	local perrow = OM.ShareState(r, row(r, 'all', 'perrow'))
	eq(perrow.member, false, 'All bars is the source page')
	eq(differs(perrow), 'Bar 4: 1; Bar 5: 1; Bar 6: 1; Bar 7: 1; Bar 8: 1', 'Buttons per row: the columns')
	eq(perrow.offers, true, 'it offers Apply to')
	eq(perrow.shared, '12', "All bars' value")
	eq(differs(OM.ShareState(r, row(r, 'all', 'size'))), 'Pet bar: 30; Stance bar: 30', 'Button size: the pet and stance bars')
	for _, key in ipairs({ 'buttons', 'spacing', 'growth', 'visibility' }) do
		local state = OM.ShareState(r, row(r, 'all', key))
		eq(#state.differs, 0, key .. ': no bar differs')
		eq(state.offers, false, key .. ': nothing offered')
	end
	for _, key in ipairs({ 'hotkey', 'count', 'macro', 'countdown' }) do
		eq(#OM.ShareState(r, row(r, 'all', key)).differs, 0, key .. ': no bar differs')
	end
	eq(OM.ShareState(r, row(r, 'all', 'theme')), nil, 'Theme is All bars only: no share')
	no_errors()
end)

test('Reset, All and Multiple on a bar, and on All bars', function()
	fresh()
	local r = root()
	-- Reset: Bar 4 follows All bars' 12 again.
	eq(OM.ShareCall(r, row(r, 'bar4', 'perrow'), 'reset'), true, 'reset ran')
	eq(AB:IsOwn('bar4', 'perrow'), false, 'Bar 4 follows')
	eq(AB:GetBarConfig('bar4').perrow, 12, "and shows All bars' value")
	eq(table.concat(calls, ','), 'UpdateBar:bar4', 'Bar 4 is updated')
	r = root()
	eq(OM.ShareState(r, row(r, 'bar4', 'perrow')).own, false, 'its row is no longer own')

	-- Multiple's list: every other bar; for a text a pet or stance bar lacks, not them.
	eq(labels(OM.ShareTargets(r, row(r, 'bar3', 'size'))),
		'Bar 1,Bar 2,Bar 4,Bar 5,Bar 6,Bar 7,Bar 8,Pet bar,Stance bar', 'every bar but Bar 3')
	eq(labels(OM.ShareTargets(menu_setting(row(r, 'bar3', 'count'), 'size'))),
		'Bar 1,Bar 2,Bar 4,Bar 5,Bar 6,Bar 7,Bar 8', 'Stack count: no Pet bar or Stance bar')
	eq(labels(OM.ShareTargets(menu_setting(row(r, 'bar3', 'hotkey'), 'size'))),
		'Bar 1,Bar 2,Bar 4,Bar 5,Bar 6,Bar 7,Bar 8,Pet bar,Stance bar', 'Hotkey: the pet and stance bars too')
	eq(labels(OM.ShareTargets(r, row(r, 'all', 'size'))), 'Pet bar,Stance bar', "on All bars: the bars that own it")

	-- Multiple from a bar: the picked bars own a copy.
	OM.Set(r, row(r, 'bar3', 'size'), 40)
	calls = {}
	eq(OM.ShareCall(r, row(r, 'bar3', 'size'), 'apply', { 'bar5' }), true, 'apply ran')
	eq(AB:IsOwn('bar5', 'size') and AB:GetBarConfig('bar5').size, 40, 'Bar 5 owns 40')
	eq(AB:GetBarConfig('bar6').size, 45, 'Bar 6 still follows')
	eq(AB:IsOwn('bar6', 'size'), false, 'and owns nothing: an unpicked bar is not written')
	eq(table.concat(calls, ','), 'UpdateBar:bar3,UpdateBar:bar5', 'the bar and each picked bar are updated')

	-- Multiple from All bars: the picked bars follow again.
	calls = {}
	OM.ShareCall(r, row(r, 'all', 'size'), 'apply', { 'pet' })
	eq(AB:IsOwn('pet', 'size'), false, 'the pet bar follows')
	eq(AB:IsOwn('stance', 'size'), true, 'the stance bar keeps its own')
	eq(table.concat(calls, ','), 'UpdateBar:pet', 'the pet bar is updated')

	-- All from a bar: All bars takes its value, and no bar keeps its own.
	calls = {}
	OM.ShareCall(r, row(r, 'bar3', 'size'), 'applyAll')
	eq(AB:GetSetting('all', 'size'), 40, "All bars takes Bar 3's 40")
	eq(#AB:OwnersOf('size'), 0, 'no bar keeps its own')
	eq(#calls, #AB.BAR_IDS, 'every bar is updated')

	-- All from All bars: every bar follows.
	calls = {}
	OM.ShareCall(r, row(r, 'all', 'perrow'), 'applyAll')
	eq(#AB:OwnersOf('perrow'), 0, 'no bar owns Buttons per row')
	eq(#calls, #AB.BAR_IDS, 'every bar is updated')
	r = root()
	eq(OM.ShareState(r, row(r, 'all', 'perrow')).offers, false, 'and the diff icon has gone')
	no_errors()
end)

test("the shares name the members ('bar', 'bars'), and the pet and stance bars with their article", function()
	fresh()
	local r = root()
	for _, case in ipairs({
		{ 'all', 'size', nil }, { 'bar3', 'size', 'Bar 3' }, { 'bar1', 'perrow', 'Bar 1' },
		{ 'pet', 'size', 'the Pet bar' }, { 'stance', 'size', 'the Stance bar' },
	}) do
		local id, key, text = case[1], case[2], case[3]
		local share = AB:ShareFor(id, key)
		eq(share.noun and table.concat(share.noun, ','), 'bar,bars', id .. ': a member is a bar')
		eq(share.pageText, text, id .. ': its page in a sentence')
		local state = OM.ShareState(r, row(r, id, key))
		eq(state.pageText, text, id .. ': as the model hands it on')
		eq(state.noun and state.noun[2], 'bars', id .. ': and its noun')
	end
	eq(AB:ShareFor('pet', 'size').page, 'Pet bar', "the page's own name is as before")
	-- An item's Show, and a setting in its menu, carry them too.
	local item = row(r, 'pet', 'hotkey')
	eq(OM.ShareState(r, item).pageText, 'the Pet bar', "the pet bar's Hotkey")
	eq(OM.ShareState(menu_setting(item, 'size')).pageText, 'the Pet bar', 'and its Size')
	no_errors()
end)

test('a text item: own-marked by its menu, its diff lines naming the settings', function()
	fresh()
	AB:SetSetting('bar3', 'hotkey.size', 8)
	AB:SetSetting('bar3', 'hotkey.position', 'TOPLEFT', 'point')
	local r = root()
	local mine = OM.ShareState(r, row(r, 'bar3', 'hotkey'))
	eq(mine.marked, true, "Bar 3's Hotkey is marked: its menu has own settings")
	eq(mine.own, false, 'its Show is not own')
	eq(mine.offers, false, 'so its line offers nothing')
	eq(mine.item, true, 'an item')
	local all = OM.ShareState(r, row(r, 'all', 'hotkey'))
	eq(differs(all), 'Bar 3: Size, Position', "All bars' Hotkey names Bar 3 and its settings")
	eq(all.offers, false, 'its line acts on Show, which no bar owns')
	eq(differs(OM.ShareState(menu_setting(row(r, 'all', 'hotkey'), 'size'))), 'Bar 3: 8', 'Size, in the menu, names its value')
	eq(differs(OM.ShareState(menu_row(row(r, 'all', 'hotkey'), 'position'))), 'Bar 3: Top Left to Top Right, -3, -3',
		'Position names the whole place')
	eq(OM.ShareState(menu_setting(row(r, 'bar3', 'hotkey'), 'size')).own, true, "Bar 3's menu: Size is own")
	eq(OM.ShareState(menu_row(row(r, 'bar3', 'hotkey'), 'font')).own, false, 'Font follows')

	AB:SetSetting('bar3', 'hotkey.show', false)
	r = root()
	all = OM.ShareState(r, row(r, 'all', 'hotkey'))
	eq(differs(all), 'Bar 3: Show, Size, Position', 'Show first, then the menu')
	eq(all.offers, true, 'now its line offers Apply to')
	eq(OM.ShareState(r, row(r, 'bar3', 'hotkey')).own, true, "Bar 3's Show is own")

	-- A set in the menu makes the setting the bar's own, and applies to the bar.
	calls = {}
	local menuRoot, size = menu_setting(row(r, 'bar2', 'count'), 'size')
	eq(OM.Get(menuRoot, size), 10, "Bar 2's stack count size: All bars' 10")
	OM.Set(menuRoot, size, 13)
	eq(AB:IsOwn('bar2', 'count.size') and AB:GetBarConfig('bar2').text.count.size, 13, 'own now, 13')
	eq(table.concat(calls, ','), 'UpdateBar:bar2', 'Bar 2 is updated')
	calls = {}
	menuRoot, size = menu_setting(row(r, 'all', 'macro'), 'size')
	OM.Set(menuRoot, size, 11)
	eq(AB:GetSetting('all', 'macro.size'), 11, "All bars' macro name size")
	eq(#calls, #AB.BAR_IDS, 'every bar is updated')
	calls = {}
	local posRoot, position = menu_row(row(r, 'bar2', 'hotkey'), 'position')
	OM.Set(posRoot, position, 'x_off', -5)
	eq(AB:IsOwn('bar2', 'hotkey.position'), true, 'a Position part makes the whole Position own')
	eq(AB:GetSetting('bar2', 'hotkey.position', 'x_off'), -5, 'moved')
	eq(AB:GetSetting('bar2', 'hotkey.position', 'point'), 'TOPRIGHT', "the rest copied from All bars'")
	eq(table.concat(calls, ','), 'UpdateBar:bar2', 'Bar 2 is updated')
	no_errors()
end)

test('every action bar row has a reset or its share, and each derived one round-trips', function()
	fresh()
	local R = load_test_file('lib/reset_walk.lua')
	-- The extras' movers, as AB:SetupExtras registers them: their Position rows reset through them.
	for _, file in ipairs(editmode_files()) do load_saftui(file) end
	AB.movers = AB.movers or {}
	for _, id in ipairs(AB.EXTRA_IDS) do AB:RegisterExtraMover(id) end
	R.check_page({ ActionBars = AB:GetConfigTable() }, 'ActionBars')
end)

test("All bars' Cooldown Show resets to Blizzard's default", function()
	fresh()
	load_test_file('lib/reset_walk.lua')
	local r = root()
	local item = row(r, 'all', 'countdown')
	eq(AB.COUNTDOWN_CVAR, CVAR, 'one name for the setting')
	eq(C_CVar.GetCVarDefault(CVAR), '1', "the stub knows Blizzard's default")
	eq(OM.DefaultSource(r, item), 'default', 'a hand default')
	eq(item.option.default.differs(), false, 'on, as the game ships it: no icon')
	C_CVar.SetCVar(CVAR, '0')
	eq(item.option.default.differs(), true, 'off differs')
	eq(item.option.default.value(), true, "the value it goes back to")
	item.option.default.reset()
	eq(C_CVar.GetCVarBool(CVAR), true, 'reset: on')
	eq(stub.cvars[CVAR], '1', "reset: '1'")
	eq(item.option.default.differs(), false, 'and no icon again')
end)

test("All bars' Cooldown Show has no reset on a client with no CVar default", function()
	fresh()
	load_test_file('lib/reset_walk.lua')
	local had = C_CVar.GetCVarDefault
	C_CVar.GetCVarDefault = nil
	local r = { ActionBars = AB:GetConfigTable() }
	local item = row(r, 'all', 'countdown')
	C_CVar.GetCVarDefault = had
	eq(OM.DefaultSource(r, item), 'none', 'none')
	check(type(item.option.noReset) == 'string' and item.option.noReset ~= '', 'with its reason')
end)

test("the cooldown numbers: Show is Blizzard's setting on All bars, none on a bar; no Reset button", function()
	fresh()
	local r = root()
	local item = row(r, 'all', 'countdown')
	eq(item.name, 'Cooldown', 'named Cooldown')
	eq(item.option.menuTitle, 'Cooldown numbers', 'its menu titled Cooldown numbers')
	check(item.desc:find('Show Numbers for Cooldowns', 1, true), "its tooltip names Blizzard's option")
	eq(item.option.share, nil, 'no share: Blizzard keeps it')
	eq(OM.Get(r, item), true, "checked while Blizzard's setting is on")
	local before = dump(st.config.profile)
	OM.Set(r, item, false)
	eq(stub.cvars[CVAR], '0', 'unchecked: off')
	OM.Set(r, item, true)
	eq(stub.cvars[CVAR], '1', 'checked: on')
	eq(dump(st.config.profile), before, 'nothing is written to the profile')
	eq(calls[1], nil, 'and no bar needs an update (the bars follow the setting)')

	local mine = row(r, 'bar3', 'countdown')
	eq(mine.option.get, false, "on a bar no Show box (get = false)")
	eq(OM.Has(r, mine, 'get'), false, 'none inherited')
	eq(mine.option.reserveBox, true, "but the box's room kept (Core's reserveBox), so its name lines up with the other texts'")
	eq(item.option.reserveBox, nil, 'All bars has its box')
	for _, id in ipairs({ 'all', 'bar3', 'pet' }) do
		for _, kind in ipairs({ 'hotkey', 'count', 'macro' }) do
			if id ~= 'pet' or kind == 'hotkey' then
				eq(row(r, id, kind).option.reserveBox, nil, id .. ' ' .. kind .. ': a box of its own, no reserveBox')
			end
		end
	end
	check(mine.desc:find('All bars', 1, true), 'its tooltip says All bars turns them on')

	-- The menu: Font, Size, Outline and Position; no Reset (each setting has its own).
	for _, id in ipairs({ 'all', 'bar3', 'pet' }) do
		local menu = row(r, id, 'countdown').option.menu
		local ks = {}
		for k, option in pairs(menu.args) do ks[#ks + 1] = option.order .. k end
		table.sort(ks)
		eq(table.concat(ks, ','), '1font,2size,3outline,4position', id .. ': Font, Size, Outline, Position')
	end

	-- Until set they show what's drawn: Pixel Med on 45px buttons, Pixel on the pet bar's 30.
	local med, pixel = st.config.profile.fonts.pixel_med, st.config.profile.fonts.pixel
	-- Font shows the shared font drawn, and Size and Outline are hidden with it (what
	-- they hold is still those fonts', which a size set alone shows).
	eq(OM.Get(menu_row(row(r, 'bar3', 'countdown'), 'font')), 'pixel_med', 'Font: Large numbers on 45px')
	eq(OM.Get(menu_row(row(r, 'pet', 'countdown'), 'font')), 'pixel', "the pet bar's: Small text")
	eq(menu_keys(row(r, 'bar3', 'countdown')), 'font,position', 'Size and Outline hidden')
	eq(OM.Get(menu_setting(row(r, 'bar3', 'countdown'), 'size')), med.font_size, "Bar 3's Size: Large numbers'")
	eq(OM.Get(menu_setting(row(r, 'pet', 'countdown'), 'size')), pixel.font_size, "the pet bar's: Small text's")
	eq(OM.Get(menu_setting(row(r, 'bar3', 'countdown'), 'outline')), med.font_outline, 'Outline: the outline drawn')
	eq(AB:GetSetting('bar3', 'countdown.size'), nil, 'which is still unset')

	-- On a bar each setting's reset is its share's: follow All bars again.
	local barRoot, barSize = menu_setting(row(r, 'bar3', 'countdown'), 'size')
	OM.Set(barRoot, barSize, 14)
	r = root()
	eq(OM.ShareState(r, row(r, 'bar3', 'countdown')).marked, true, "Bar 3's Cooldown is marked by its menu")
	-- All bars' Size stays shown while a bar owns it, though its Font is the shared font by
	-- button size, so the diff names Bar 3.
	eq(differs(OM.ShareState(r, row(r, 'all', 'countdown'))), 'Bar 3: Size', "All bars' Cooldown names Bar 3's Size")
	eq(OM.ShareState(r, row(r, 'all', 'countdown')).offers, false, 'with no line: its Show is no shared setting')
	calls = {}
	barRoot, barSize = menu_setting(row(r, 'bar3', 'countdown'), 'size')
	OM.ShareCall(barRoot, barSize, 'reset')
	eq(AB:IsOwn('bar3', 'countdown.size'), false, 'Bar 3 follows All bars again')
	eq(OM.Get(menu_setting(row(r, 'bar3', 'countdown'), 'size')), med.font_size, "and shows Large numbers' again")
	eq(table.concat(calls, ','), 'UpdateBar:bar3', 'Bar 3 is updated')

	-- On All bars: unset is the default; set, its reset unsets it.
	local menuRoot, size = menu_setting(row(r, 'all', 'countdown'), 'size')
	eq(OM.DefaultState(menuRoot, size).differs, false, 'unset: at its default')
	OM.Set(menuRoot, size, 16)
	eq(OM.DefaultState(menuRoot, size).differs, true, 'set: it differs')
	check(OM.DefaultState(menuRoot, size).text:find('Large numbers', 1, true), 'its default says what unset draws')
	calls = {}
	OM.DefaultReset(menuRoot, size)
	eq(AB:GetSetting('all', 'countdown.size'), nil, 'reset: unset again')
	eq(#calls, #AB.BAR_IDS, 'every bar is updated')
	local posRoot, position = menu_row(row(r, 'all', 'countdown'), 'position')
	OM.Set(posRoot, position, 'point', 'TOP')
	eq(OM.DefaultState(posRoot, position).differs, true, 'a moved place differs')
	OM.DefaultReset(posRoot, position)
	eq(AB:GetSetting('all', 'countdown.position', 'point'), 'CENTER', 'its reset puts it in the middle')
	no_errors()
end)

test("Faded opacity shows when the page's Show, or on All bars any bar's, is faded until moused over", function()
	fresh()
	local function hidden(id)
		local option = AB:GetConfigTable().args[id].args.visibility.args.fade_alpha
		return option.hidden()
	end
	eq(hidden('bar3'), true, 'fresh: hidden on Bar 3')
	eq(hidden('all'), true, 'and on All bars')
	AB:SetSetting('bar3', 'visibility', 'mouseover')
	eq(hidden('bar3'), false, 'Bar 3 fades: shown there')
	eq(hidden('all'), false, 'and on All bars, as a bar fades')
	eq(hidden('bar2'), true, 'not on Bar 2')
	AB:ResetSetting('bar3', 'visibility')
	AB:SetSetting('all', 'visibility', 'mouseover')
	eq(hidden('all'), false, 'All bars fades: shown there')
	eq(hidden('bar2'), false, 'and on Bar 2, which follows')
	local option = AB:GetConfigTable().args.all.args.visibility.args.fade_alpha
	eq(option.isPercent, true, 'a percent')
	no_errors()
end)

test('clicking a bar in edit mode opens its page', function()
	fresh()
	local specs = {}
	function st:RegisterConfigMover(_, spec)
		specs[spec.key] = spec
		return { label = { SetText = function() end } }
	end
	AB.movers = {}
	AB:RegisterBarMover('bar3')
	AB:RegisterExtraMover('extra')
	eq(table.concat(specs.ab_bar3.configPath, ','), 'ActionBars,bar3', "Bar 3's mover opens its page")
	local pageKey, selection = OM.SelectionForPath(root(), specs.ab_bar3.configPath)
	eq(pageKey .. ' ' .. tostring(selection.pick), 'ActionBars bar3', 'picking Bar 3')
	eq(table.concat(specs.ab_extra.configPath, ','), 'ActionBars,extra,general', 'the extras keep theirs')
	no_errors()
end)

test("search finds a text menu's settings on All bars and on each bar", function()
	fresh()
	-- A text on Small text, as they ship, hides its Outline and Size (they are the font's).
	for _, result in ipairs(OM.Search(root(), 'Outline')) do
		check(not (result.menu and result.sectionTitle == 'Hotkey'), "no Hotkey Outline while Hotkey is on Small text")
	end
	AB:SetSetting('all', 'hotkey.font', 'Homespun') -- a typeface: its Size and Outline show
	local found = {}
	for _, result in ipairs(OM.Search(root(), 'Outline')) do
		if result.menu and result.sectionTitle == 'Hotkey' then found[#found + 1] = result.path[2] end
	end
	eq(table.concat(found, ','), 'all,bar1,bar2,bar3,bar4,bar5,bar6,bar7,bar8,pet,stance',
		"Hotkey's Outline, on All bars and every bar")
	local onPet = {}
	for _, result in ipairs(OM.Search(root(), 'Outline')) do
		if result.path[2] == 'pet' then onPet[#onPet + 1] = result.sectionTitle end
	end
	eq(table.concat(onPet, ','), 'Hotkey', "on the pet bar: its Hotkey's (the Cooldown's is hidden while its font is a shared one)")
	no_errors()
end)

test('SettingText', function()
	fresh()
	eq(AB:SettingText('all', 'fade_alpha'), '30%', 'Faded opacity as a percent')
	AB:SetSetting('bar3', 'growth', 'TOPRIGHT')
	eq(AB:SettingText('bar3', 'growth'), 'Top right', 'First button by its label')
	eq(AB:SettingText('all', 'visibility'), 'Always', 'Show by its label')
	eq(AB:SettingText('pet', 'size'), '30', 'a number as is')
	eq(AB:SettingText('all', 'hotkey.position'), 'Top Right to Top Right, -3, -3', "a text's place")
	eq(AB:SettingText('all', 'countdown.size'), 'By button size', 'an unset cooldown size')
	eq(AB:SettingText('all', 'countdown.font'), 'By button size', 'font')
	eq(AB:SettingText('all', 'countdown.outline'), 'By button size', 'outline')
	AB:SetSetting('bar3', 'hotkey.show', false)
	eq(AB:SettingText('bar3', 'hotkey.show'), 'Hidden', 'a hidden text')
	eq(AB:SettingText('all', 'hotkey.show'), 'Shown', 'a shown one')
	eq(AB:SettingText('all', 'hotkey.outline'), 'Monochrome outline', "an outline by the Fonts module's label")
	eq(AB:SettingText('all', 'hotkey.font'), 'Small text', 'a text ships Small text: a shared font by its name')
	AB:SetSetting('bar3', 'hotkey.font', 'Colus')
	eq(AB:SettingText('bar3', 'hotkey.font'), 'Colus', 'a face by its name')
	no_errors()
end)

------------------------------------------------------------------ resets

test("every setting's own reset: on All bars against the shipped default, on a bar its share's, Enable and Position the bar's", function()
	fresh()
	local r = root()
	-- All bars: each shared setting, Theme and Background differ from their default once changed.
	for key, value in pairs({ buttons = 8, perrow = 6, size = 30, spacing = 6, growth = 'BOTTOMLEFT',
		visibility = 'combat' }) do
		local each = row(r, 'all', key)
		eq(OM.DefaultState(r, each).differs, false, key .. ': at its default')
		OM.Set(r, each, value)
		eq(OM.DefaultState(r, each).differs, true, key .. ': changed, it differs')
		calls = {}
		eq(OM.DefaultReset(r, each), true, key .. ': reset ran')
		eq(AB:GetSetting('all', key), st.defaults.actionbars.all[key], key .. ': the shipped default again')
		eq(#calls, #AB.BAR_IDS, key .. ': every bar is updated')
	end
	AB:SetSetting('all', 'visibility', 'mouseover')
	r = root()
	local fade = row(r, 'all', 'fade_alpha')
	OM.Set(r, fade, 0.5)
	eq(OM.DefaultState(r, fade).text, '30%', "Faded opacity's default, as a percent")
	OM.DefaultReset(r, fade)
	eq(AB:GetSetting('all', 'fade_alpha'), 0.3, 'back to 30%')
	for _, key in ipairs({ 'theme', 'background' }) do
		local each = row(r, 'all', key)
		OM.Set(r, each, key == 'theme' and 'thin' or 'solid')
		eq(OM.DefaultState(r, each).differs, true, key .. ': changed, it differs')
		calls = {}
		OM.DefaultReset(r, each)
		eq(AB.config[key], 'theme', key .. ': SaftUI\'s theme again')
		eq(table.concat(calls, ','), 'UpdateConfig', key .. ': every bar is drawn again')
	end
	-- The texts on All bars: Show, Font, Size, Outline and Position.
	local hotkey = row(r, 'all', 'hotkey')
	OM.Set(r, hotkey, false)
	eq(OM.DefaultState(r, hotkey).differs, true, 'a hidden hotkey differs')
	calls = {}
	OM.DefaultReset(r, hotkey)
	eq(AB:GetSetting('all', 'hotkey.show'), true, 'shown again')
	eq(#calls, #AB.BAR_IDS, "the Show's reset updates every bar")
	local posRoot, position = menu_row(hotkey, 'position')
	OM.Set(posRoot, position, 'y_off', -6)
	eq(OM.DefaultState(posRoot, position).differs, true, 'a moved text differs, in one offset alone')
	eq(OM.DefaultState(posRoot, position).text, 'Top Right to Top Right, -3, -3', 'its default, as a place')
	calls = {}
	OM.DefaultReset(posRoot, position)
	eq(AB:GetSetting('all', 'hotkey.position', 'y_off'), -3, 'back in its place')
	eq(#calls, #AB.BAR_IDS, "the Position's reset updates every bar")
	eq(OM.DefaultState(posRoot, position).differs, false, 'and it no longer differs')

	-- Every menu setting has its default on All bars, the countdown's too.
	for _, kind in ipairs({ 'hotkey', 'countdown' }) do
		for field, value in pairs({ font = 'Friz Quadrata TT', size = 17, outline = 'THICK' }) do
			local menuRoot, setting = menu_setting(row(r, 'all', kind), field)
			eq(OM.DefaultState(menuRoot, setting).differs, false, kind .. ' ' .. field .. ': at its default')
			OM.Set(menuRoot, setting, value)
			eq(OM.DefaultState(menuRoot, setting).differs, true, kind .. ' ' .. field .. ': set, it differs')
			calls = {}
			OM.DefaultReset(menuRoot, setting)
			eq(AB:GetSetting('all', kind .. '.' .. field), st.defaults.actionbars.all.text[kind][field],
				kind .. ' ' .. field .. ': the shipped value again')
			eq(#calls, #AB.BAR_IDS, kind .. ' ' .. field .. ': every bar is updated')
		end
	end

	-- A bar: a shared setting's reset is the share's (no default drawn: OB.PlaceDefault skips
	-- a member share); Enable and Position against the bar's shipped values.
	check(row(r, 'bar3', 'size').option.default == nil, "Bar 3's Button size has no default of its own")
	local enable = row(r, 'bar3', 'enable')
	eq(OM.DefaultState(r, enable).differs, false, 'Enable: on, its default')
	OM.Set(r, enable, false)
	eq(OM.DefaultState(r, enable).differs, true, 'off: it differs')
	calls = {}
	OM.DefaultReset(r, enable)
	eq(AB.config.bar3.enable, true, 'on again')
	eq(table.concat(calls, ','), 'UpdateBar:bar3', 'Bar 3 is updated')
	eq(OM.DefaultState(r, row(r, 'bar6', 'enable')).differs, false, 'Bar 6 ships off: off is its default')
	local place = row(r, 'bar3', 'position')
	OM.Set(r, place, 'x_off', 40)
	eq(OM.DefaultState(r, place).differs, true, 'a moved bar differs')
	eq(OM.DefaultState(r, place).text, 'Bottom to Top of Bar 2, 0, 3', 'its default names where it ships, in the bar\'s words')
	eq(OM.DefaultState(r, row(r, 'bar1', 'position')).text, 'Bottom to Bottom of the screen, 0, 20', 'the screen for UIParent')
	eq(OM.DefaultState(r, row(r, 'pet', 'position')).text:match(' of (.-),'), 'Bar 3', 'a bar of the pet bar')
	calls = {}
	OM.DefaultReset(r, place)
	eq(AB.config.bar3.position.x_off, 0, 'back in its place')
	eq(table.concat(calls, ','), 'LayoutBar:bar3', 'laid out')
	eq(OM.DefaultState(r, place).differs, false, 'at its default again')
	AB.config.bar3.position.frame = 'UIParent'
	eq(OM.DefaultState(r, place).differs, true, 'on another frame: it differs')
	OM.DefaultReset(r, place)
	eq(AB.config.bar3.position.frame, 'SaftUI_ActionBar2', 'back on Bar 2')
	no_errors()
end)

------------------------------------------------------------------ no-op picks

test('picking the value a control already shows changes nothing and makes nothing own', function()
	fresh()
	local r = root()
	calls = {}
	local function untouched(key, what)
		eq(AB:IsOwn('bar3', key), false, what .. ': not the bar\'s own')
		eq(#calls, 0, what .. ': nothing updated')
	end
	OM.Set(r, row(r, 'bar3', 'growth'), 'TOPLEFT')
	untouched('growth', "First button's current entry")
	OM.Set(r, row(r, 'bar3', 'visibility'), 'always')
	untouched('visibility', 'Show Always')
	OM.Set(r, row(r, 'bar3', 'size'), 45)
	untouched('size', 'the size it shows')
	local menuRoot, font = menu_row(row(r, 'bar3', 'hotkey'), 'font')
	OM.Set(menuRoot, font, OM.Get(menuRoot, font))
	untouched('hotkey.font', 'the current hotkey font')
	menuRoot, font = menu_row(row(r, 'bar3', 'countdown'), 'font')
	OM.Set(menuRoot, font, OM.Get(menuRoot, font))
	untouched('countdown.font', 'the drawn cooldown font')
	eq(AB:GetSetting('bar3', 'countdown.font'), nil, 'an unset cooldown font stays unset')
	local size
	menuRoot, size = menu_setting(row(r, 'bar3', 'countdown'), 'size')
	OM.Set(menuRoot, size, OM.Get(menuRoot, size))
	untouched('countdown.size', 'the drawn cooldown size')
	eq(AB:GetSetting('bar3', 'countdown.size'), nil, 'an unset cooldown size stays unset')
	OM.Set(r, row(r, 'bar3', 'hotkey'), true)
	untouched('hotkey.show', "a text's Show as it is")
	local posRoot, position = menu_row(row(r, 'bar3', 'hotkey'), 'position')
	OM.Set(posRoot, position, 'y_off', AB:GetSetting('bar3', 'hotkey.position', 'y_off'))
	OM.Set(posRoot, position, 'point', AB:GetSetting('bar3', 'hotkey.position', 'point'))
	untouched('hotkey.position', 'a Position part set to where it is')

	-- The pet bar's Buttons, typed as the 10 it shows while following All bars' 12.
	OM.Set(r, row(r, 'pet', 'buttons'), 10)
	eq(AB:IsOwn('pet', 'buttons'), false, "the pet bar's 10 is not its own")
	OM.Set(r, row(r, 'pet', 'perrow'), 10)
	eq(AB:IsOwn('pet', 'perrow'), false, 'nor its Buttons per row')
	eq(#calls, 0, 'nothing updated')
	OM.Set(r, row(r, 'pet', 'buttons'), 8)
	eq(AB:IsOwn('pet', 'buttons') and AB:GetSetting('pet', 'buttons'), 8, 'a real change is its own')

	-- A real change still is, and a bar that owns a setting writes what it is given.
	OM.Set(r, row(r, 'bar3', 'spacing'), 6)
	eq(AB:IsOwn('bar3', 'spacing') and AB:GetSetting('bar3', 'spacing'), 6, 'a changed value is the bar\'s own')
	OM.Set(r, row(r, 'bar3', 'spacing'), 3)
	eq(AB:IsOwn('bar3', 'spacing') and AB:GetSetting('bar3', 'spacing'), 3, 'and an owner writes All bars\' value as its own')
	-- All bars writes what it is given.
	calls = {}
	OM.Set(r, row(r, 'all', 'spacing'), 3)
	eq(#calls, #AB.BAR_IDS, 'All bars always updates')
	no_errors()
end)

test("Faded opacity is a shared setting: own on a bar, and named on All bars", function()
	fresh()
	AB:SetSetting('bar3', 'visibility', 'mouseover')
	local r = root()
	local fade = row(r, 'bar3', 'fade_alpha')
	eq(OM.ShareState(r, fade).own, false, 'it follows All bars to begin with')
	OM.Set(r, fade, 0.5)
	r = root()
	local state = OM.ShareState(r, row(r, 'bar3', 'fade_alpha'))
	eq(state.own, true, 'a change is the bar\'s own')
	eq(state.shared, '30%', "naming All bars' value")
	eq(differs(OM.ShareState(r, row(r, 'all', 'fade_alpha'))), 'Bar 3: 50%', 'and All bars names the bar')
	no_errors()
end)

test('diff and Own tooltips show a bar\'s buttons as the bar shows them', function()
	fresh()
	AB:SetSetting('bar3', 'buttons', 11)
	AB:SetSetting('bar3', 'perrow', 11)
	AB:ApplyTo('bar3', 'buttons', { 'pet', 'bar5' })
	AB:ApplyTo('bar3', 'perrow', { 'pet' })
	local r = root()
	eq(differs(OM.ShareState(r, row(r, 'all', 'buttons'))), 'Bar 3: 11; Bar 5: 11; Pet bar: 10', 'the pet bar shows its 10')
	eq(differs(OM.ShareState(r, row(r, 'all', 'perrow'))),
		'Bar 3: 11; Bar 4: 1; Bar 5: 1; Bar 6: 1; Bar 7: 1; Bar 8: 1; Pet bar: 10', 'Buttons per row too')
	eq(OM.ShareState(r, row(r, 'pet', 'buttons')).shared, '10', "the pet bar's Own tooltip names what following would show")
	eq(OM.ShareState(r, row(r, 'bar3', 'buttons')).shared, '12', 'Bar 3 follows All bars\' 12')
	eq(OM.ShareState(r, row(r, 'all', 'buttons')).shared, '12', 'All bars shows its own 12')
	eq(AB:SettingText('pet', 'buttons'), '10', 'SettingText clamps for a bar')
	eq(AB:SettingText('all', 'buttons'), '12', 'and not for All bars')
	no_errors()
end)

test("a Position's reset is checked as a typed anchor is: a loop moves nothing and says why", function()
	fresh()
	local printed = {}
	st.Print = function(_, ...) printed[#printed + 1] = table.concat({ ... }, ' ') end
	-- Bar 3 on the screen, Bar 2 on Bar 3; Bar 3 ships on Bar 2.
	local bar2, bar3 = AB.bars.bar2, AB.bars.bar3
	AB.config.bar3.position.frame = 'UIParent'
	AB.config.bar2.position.frame = 'SaftUI_ActionBar3'
	bar3:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 0)
	bar2:SetPoint('BOTTOM', bar3, 'TOP', 0, 0)
	local r = root()
	local place = row(r, 'bar3', 'position')
	eq(OM.DefaultState(r, place).differs, true, 'Bar 3 differs from where it ships')
	calls = {}
	OM.DefaultReset(r, place)
	eq(AB.config.bar3.position.frame, 'UIParent', 'Bar 3 stays where it is')
	eq(#calls, 0, 'nothing is laid out')
	eq(#printed, 1, 'the reason is printed')
	check(printed[1]:find('loop', 1, true), 'and it is the loop')
	-- Bar 2 off Bar 3: the reset goes through.
	AB.config.bar2.position.frame = 'UIParent'
	bar2:ClearAllPoints()
	bar2:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 0)
	OM.DefaultReset(r, place)
	eq(AB.config.bar3.position.frame, 'SaftUI_ActionBar2', 'Bar 3 goes back on Bar 2')
	eq(table.concat(calls, ','), 'LayoutBar:bar3', 'laid out')
	eq(#printed, 1, 'and nothing more is printed')
end)

test("the cooldown numbers' unset reads as 'by button size', each with its noun", function()
	fresh()
	local r = root()
	for field, noun in pairs({ font = 'font', size = 'size', outline = 'outline' }) do
		local menuRoot, setting = menu_setting(row(r, 'all', 'countdown'), field)
		local want = "Large numbers' " .. noun .. " on buttons of 36px and up, Small text's below (Global settings > Fonts)"
		eq(OM.DefaultState(menuRoot, setting).text, want, field .. ': the reset names what comes back')
		check(setting.option.desc:find("Until set, it goes by the button's size: " .. want, 1, true), field .. ': the desc says so')
	end
	AB:SetSetting('bar3', 'countdown.size', 14)
	r = root()
	local menuRoot, setting = menu_setting(row(r, 'all', 'countdown'), 'size')
	eq(differs(OM.ShareState(menuRoot, setting)), 'Bar 3: 14', 'the diff names the bar')
	eq(OM.ShareState(menuRoot, setting).shared, 'By button size', "and All bars' unset size as by button size")
	no_errors()
end)

------------------------------------------------------------------ the texts' Font rows

-- A text's menu drawn on a body, with Core's widgets loaded: font_world() makes
-- the world, draw_menu(id, kind) -> menu, its cells by key.
local function font_world()
	fresh()
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
end

local function draw_menu(id, kind)
	local OB = st.OptionsBody
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(376, 800)
	local menuRoot = OM.MenuRoot(row(root(), id, kind).option)
	local menu = OB.New(content, menuRoot, function() end, 376, { oneColumn = true })
	menu:Draw(OM.BuildView(menuRoot, OM.MENU_KEY).sections)
	local by = {}
	for _, c in ipairs(menu.cells) do by[c.row.key] = c end
	return menu, by
end

test("a text's Font lists the shared fonts first; Small text picked saves 'pixel', hides Size and Outline and shows the link", function()
	font_world()
	local W = st.OptionsWidgets
	-- The shipped text is Small text; its look as a face is what an older profile or a pick gives.
	eq(menu_keys(row(root(), 'all', 'hotkey')), 'font,position', 'shipped: Small text, with no Size or Outline')
	AB:SetSetting('all', 'hotkey.font', 'Homespun')
	local r = root()
	local item = row(r, 'all', 'hotkey')
	eq(item.option.menu.args.font.type, 'font', "the Font row is Core's font row")
	eq(item.option.menu.args.font.faceOnly, true, 'in its face-only mode: no menu inside the menu')
	eq(menu_keys(item), 'font,size,outline,position', 'a typeface: Font, Size, Outline, Position')

	local menu, by = draw_menu('all', 'hotkey')
	local w = by.font.widget
	local face = AB:GetSetting('all', 'hotkey.font')
	eq(w.kind, 'typeface', "today's profile names a face")
	eq(w.face.text:GetText(), face, 'and shows it')
	check(not w.dots:IsShown(), 'with no dots: no menu inside a menu')
	stub.click(w.face)
	local list = W.GetListFrames()
	eq(list.entries[1].label, 'SaftUI fonts', 'the list opens on the shared fonts')
	local order = {}
	for i = 2, 7 do order[#order + 1] = list.entries[i].key end
	eq(table.concat(order, ','), 'normal,pixel,pixel_med,heading,title,subtitle', 'the six, in order')
	eq(list.selected, 'face:' .. face, 'the face is the picked entry')
	W.CloseList()

	w:Pick('pixel')
	eq(AB:GetSetting('all', 'hotkey.font'), 'pixel', 'Small text saves its key')
	eq(AB:GetSetting('bar3', 'hotkey.font'), 'pixel', 'a bar that follows has it')
	eq(AB:IsOwn('bar3', 'hotkey.font'), false, 'and owns nothing')
	eq(menu_keys(item), 'font,position', 'Size and Outline are hidden')
	menu:Release()
	menu, by = draw_menu('all', 'hotkey')
	w = by.font.widget
	eq(w.kind, 'shared', 'the row reads a shared font')
	eq(w.face.text:GetText(), 'Small text', 'by its name')
	check(w.dots:IsShown(), 'with the link to the Fonts tab')
	eq(w.dots.icon:GetTexture(), st.icons.link, 'in its slot')
	eq(by.size, nil, 'no Size drawn')
	eq(by.outline, nil, 'no Outline drawn')
	menu:Release()

	-- A bar that owns its own font hides them on its own page alone.
	AB:SetSetting('bar3', 'hotkey.font', 'Colus')
	eq(menu_keys(row(root(), 'bar3', 'hotkey')), 'font,size,outline,position', "Bar 3's own typeface shows them")
	eq(menu_keys(row(root(), 'bar4', 'hotkey')), 'font,position', 'Bar 4 follows the shared font')
	no_errors()
end)

test('a face picked saves its name and shows Size and Outline again, with what they held', function()
	font_world()
	AB:SetSetting('all', 'hotkey.size', 17)
	AB:SetSetting('all', 'hotkey.outline', 'THICKOUTLINE')
	AB:SetSetting('all', 'hotkey.font', 'pixel')
	local item = row(root(), 'all', 'hotkey')
	eq(menu_keys(item), 'font,position', 'on Small text: hidden')
	local menu, by = draw_menu('all', 'hotkey')
	by.font.widget:Pick('face:Colus')
	eq(AB:GetSetting('all', 'hotkey.font'), 'Colus', "the face's name alone, as it was saved before")
	eq(type(AB:GetSetting('all', 'hotkey.font')), 'string', 'a string')
	eq(menu_keys(row(root(), 'all', 'hotkey')), 'font,size,outline,position', 'Size and Outline are back')
	menu:Release()
	local menuRoot, size = menu_row(row(root(), 'all', 'hotkey'), 'size')
	eq(OM.Get(menuRoot, size), 17, 'Size held 17')
	eq(OM.Get(menu_row(row(root(), 'all', 'hotkey'), 'outline')), 'THICKOUTLINE', 'and Outline its value')
	no_errors()
end)

test("the cooldown numbers' unset Font shows Large numbers on 45 px buttons and Small text on 30, with the link; a size set alone shows the face it draws", function()
	font_world()
	local med, pixel = st.config.profile.fonts.pixel_med, st.config.profile.fonts.pixel
	eq(AB:GetBarConfig('bar3').size, 45, 'Bar 3 has 45 px buttons')
	eq(AB:GetBarConfig('pet').size, 30, 'the pet bar 30')
	local W = st.OptionsWidgets
	local menu, by = draw_menu('bar3', 'countdown')
	eq(by.font.widget.kind, 'shared', 'a shared font')
	eq(by.font.widget.face.text:GetText(), 'Large numbers', 'Large numbers on 45 px')
	eq(by.font.widget.dots.icon:GetTexture(), st.icons.link, 'with the link')
	check(by.font.widget.dots:IsShown(), 'shown')
	eq(by.size, nil, 'Size hidden')
	eq(by.outline, nil, 'Outline hidden')
	eq(AB:GetSetting('bar3', 'countdown.font'), nil, 'while the setting is still unset')
	menu:Release()
	menu, by = draw_menu('pet', 'countdown')
	eq(by.font.widget.face.text:GetText(), 'Small text', 'Small text on 30 px')
	menu:Release()

	-- Picking what is shown writes nothing: the bar still follows All bars.
	menu, by = draw_menu('bar3', 'countdown')
	by.font.widget:Pick('pixel_med')
	eq(AB:IsOwn('bar3', 'countdown.font'), false, 'Bar 3 follows')
	-- Picking the other one does.
	by.font.widget:Pick('pixel')
	eq(AB:GetSetting('bar3', 'countdown.font'), 'pixel', 'Small text saved on Bar 3')
	eq(AB:CountdownValue(AB:GetBarConfig('bar3')), 'pixel', 'and drawn')
	menu:Release()
	AB:ResetSetting('bar3', 'countdown.font')

	-- A size set alone: the face it draws, with Size and Outline shown.
	AB:SetSetting('all', 'countdown.size', 20)
	local item = row(root(), 'bar3', 'countdown')
	eq(menu_keys(item), 'font,size,outline,position', 'Size and Outline shown')
	menu, by = draw_menu('bar3', 'countdown')
	eq(by.font.widget.kind, 'typeface', 'a typeface')
	eq(by.font.widget.face.text:GetText(), med.font_name, "the face it draws: Large numbers' face")
	menu:Release()
	menu, by = draw_menu('pet', 'countdown')
	eq(by.font.widget.face.text:GetText(), pixel.font_name, "Small text's face on 30 px")
	menu:Release()
	no_errors()
end)

test("on All bars a text's Size and Outline stay shown while any bar owns them, so the diff icon and Apply to name that bar", function()
	font_world()
	-- A shared font on All bars: nothing is owned, so both are hidden.
	AB:SetSetting('all', 'hotkey.font', 'pixel')
	eq(menu_keys(row(root(), 'all', 'hotkey')), 'font,position', 'no owner: Size and Outline hidden')
	-- Bar 3 owns an Outline alone: All bars shows Outline (and not Size), and names the bar.
	AB:SetSetting('bar3', 'hotkey.outline', 'THICKOUTLINE')
	local r = root()
	eq(menu_keys(row(r, 'all', 'hotkey')), 'font,outline,position', 'an owner of Outline: Outline shown, Size still hidden')
	local menuRoot, outline = menu_row(row(r, 'all', 'hotkey'), 'outline')
	eq(differs(OM.ShareState(menuRoot, outline)), 'Bar 3: Thick outline', "the diff icon names Bar 3's Outline")
	eq(labels(OM.ShareTargets(menuRoot, outline)), 'Bar 3', 'Apply to lists Bar 3')
	eq(differs(OM.ShareState(r, row(r, 'all', 'hotkey'))), 'Bar 3: Outline', "the item's icon names it")
	-- Bar 3's own page hides both while its font is shared.
	eq(menu_keys(row(r, 'bar3', 'hotkey')), 'font,position', "Bar 3's own page hides them while its font is shared")
	-- Apply to All clears it, and the row hides again.
	OM.ShareCall(menuRoot, outline, 'applyAll')
	eq(menu_keys(row(root(), 'all', 'hotkey')), 'font,position', 'nobody owns it: hidden again')
	-- The cooldown numbers: a bar owning a Size alone.
	AB:SetSetting('bar3', 'countdown.size', 14)
	eq(menu_keys(row(root(), 'all', 'countdown')), 'font,size,position', 'Size shown while Bar 3 owns it')
	AB:ResetSetting('bar3', 'countdown.size')
	eq(menu_keys(row(root(), 'all', 'countdown')), 'font,position', 'and hidden again once it follows')
	no_errors()
end)

test("the texts' Outline rows list None first, as every other outline list", function()
	font_world()
	local want = table.concat(st:GetModule('Fonts').OUTLINE_ORDER, ',')
	for _, kind in ipairs({ 'hotkey', 'count', 'macro', 'countdown' }) do
		local sorting = row(root(), 'all', kind).option.menu.args.outline.sorting
		eq(type(sorting) == 'table' and table.concat(sorting, ','), want, kind .. ': Outline sorted as the Fonts tab')
	end
end)

test('re-picking the cooldown font already shown on All bars writes nothing; picking the other one does', function()
	font_world()
	local menu, by = draw_menu('all', 'countdown')
	local w = by.font.widget
	eq(w.value, 'pixel_med', 'All bars shows Large numbers (45 px)')
	calls = {}
	w:Pick('pixel_med')
	eq(AB:GetSetting('all', 'countdown.font'), nil, 'the shown entry writes nothing')
	eq(#calls, 0, 'and updates nothing')
	w:Pick('pixel')
	eq(AB:GetSetting('all', 'countdown.font'), 'pixel', 'another one is written')
	menu:Release()
	no_errors()
end)

------------------------------------------------------------------ the tree

test('every option and menu option has a desc; AceConfig accepts the page and each menu', function()
	fresh()
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	local Registry = LibStub('AceConfigRegistry-3.0')
	local tree = AB:GetConfigTable()
	eq(tree.name, 'Action bars', 'sentence case, as the sidebar shows it')
	local NO_DESC = { group = true, header = true, description = true }
	local menus = 0
	each_option(tree, function(option, path)
		local where = table.concat(path, '.')
		if not NO_DESC[option.type] then
			check((type(option.desc) == 'string' and option.desc ~= '') or type(option.desc) == 'function', where .. ' has a desc')
			check(type(option.desc) ~= 'string' or not option.desc:find('->', 1, true), where .. ': no arrow in its desc')
		end
		check(option.width == nil, where .. ' has no Ace width')
		if option.type == 'item' then
			menus = menus + 1
			local ok, err = pcall(Registry.ValidateOptionsTable, Registry,
				ace_ready({ type = 'group', name = 'Menu', args = { menu = option.menu } }), where)
			check(ok, where .. "'s menu is valid: " .. tostring(err))
		end
	end)
	eq(menus, 9 * 4 + 2 * 2, 'a menu for every text of All bars and each bar')
	local ok, err = pcall(Registry.ValidateOptionsTable, Registry,
		ace_ready({ type = 'group', name = st.name, args = { ActionBars = tree } }), st.name)
	check(ok, 'the page is valid: ' .. tostring(err))
	no_errors()
end)

------------------------------------------------------------------ drawn

-- A piece of a drawn row (Core's optionsshare.lua: frame.share's mark and
-- diff, frame.defaultReset), shown or not; the pieces are made the first time
-- a row needs one.
local function shown(cell, piece)
	local frame, part = cell.frame, nil
	if piece == 'reset' then
		part = frame.defaultReset
	elseif frame.share then
		part = frame.share[piece]
	end
	return part ~= nil and part:IsShown() or false
end

local function rgb(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end

test('drawn under Thick and Blizzard: the diff icons, marks and resets where they belong, the texts on one line, a menu', function()
	fresh()
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	local OB = st.OptionsBody
	AB:SetSetting('bar3', 'size', 40)
	AB:SetSetting('bar3', 'hotkey.position', 'TOPLEFT', 'point')
	AB:SetSetting('all', 'spacing', 5)
	AB.config.bar3.enable = false

	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 2000)
	local function draw(r, pick)
		local body = OB.New(content, r, function() end, 774)
		body:Draw(view(r, pick).sections)
		local by = {}
		for _, c in ipairs(body.cells) do by[c.row.key] = c end
		return body, by
	end

	for _, look in ipairs({ 'thick', 'blizzard' }) do
		st.config.profile.theme.name = look
		local r = root()

		-- All bars: the diff icons on the settings a bar owns, a reset on the one
		-- changed from its default, the four texts on one line.
		local body, by = draw(r, 'all')
		check(shown(by.perrow, 'diff'), look .. ': Buttons per row has its diff icon (Bars 4-8)')
		check(shown(by.size, 'diff'), look .. ': Button size has its diff icon (pet, stance, Bar 3)')
		check(not shown(by.buttons, 'diff'), look .. ': Buttons none')
		check(shown(by.hotkey, 'diff'), look .. ": Hotkey's diff icon, for Bar 3's Position")
		check(not shown(by.count, 'diff'), look .. ': Stack count none')
		check(shown(by.spacing, 'reset'), look .. ': Spacing, at 5, has its reset')
		check(not shown(by.size, 'reset'), look .. ': Button size, at its default, none')
		check(not shown(by.perrow, 'mark'), look .. ': no own marks on All bars')
		local top = by.hotkey.frame:GetTop()
		for _, key in ipairs({ 'count', 'macro', 'countdown' }) do
			eq(by[key].frame:GetTop(), top, look .. ': ' .. key .. ' on the Hotkey line')
		end
		check(by.countdown.widget.box:IsShown(), look .. ": the Cooldown item's box (Blizzard's setting)")
		body:Release()

		-- Bar 3: its own settings marked; its Enable, off, has its reset; a row it
		-- owns has the share's Reset only.
		body, by = draw(r, 'bar3')
		check(shown(by.size, 'mark'), look .. ": Bar 3's Button size is marked")
		check(not shown(by.size, 'reset'), look .. ': with no reset of its own (the hover line has it)')
		check(not shown(by.spacing, 'mark'), look .. ': Spacing follows: no mark')
		check(shown(by.hotkey, 'mark'), look .. ': Hotkey is marked by its menu')
		check(not shown(by.hotkey, 'diff'), look .. ': and no diff icon on a bar')
		check(shown(by.enable, 'reset'), look .. ': Enable, off, has its reset')
		check(not by.countdown.widget.box:IsShown(), look .. ': no Cooldown box on a bar')
		body:Release()

		-- Bar 3's Hotkey menu: its Position title light blue, Size plain; the
		-- pet bar's Text line holds two items.
		local item = row(r, 'bar3', 'hotkey')
		local menuRoot = OM.MenuRoot(item.option)
		local menu = OB.New(content, menuRoot, function() end, 376, { oneColumn = true })
		menu:Draw(OM.BuildView(menuRoot, OM.MENU_KEY).sections)
		eq(#menu.shareTitles, 1, look .. ': the menu draws the Position title marks')
		eq(rgb(menu.shareTitles[1].title:GetTextColor()), rgb(st:ColorRGBA('accent', nil, OB.OWN_STRENGTH)), look .. ': Position is own: the accent')
		for _, c in ipairs(menu.cells) do
			if c.row.key == 'size' then check(not shown(c, 'mark'), look .. ': Size follows: no mark') end
		end
		menu:Release()
		body, by = draw(r, 'pet')
		check(by.hotkey ~= nil and by.countdown ~= nil and by.count == nil and by.macro == nil,
			look .. ': the pet bar draws its two texts')
		body:Release()
	end
	st.config.profile.theme.name = 'thick'
	no_errors()
end)

test('drawn at half under Thick and Blizzard: one column, the texts two lines of two, every piece inside its cell, on whole pixels', function()
	fresh()
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	local OB = st.OptionsBody
	local P = load_test_file('lib/pixels.lua')
	AB:SetSetting('bar3', 'size', 40)
	AB:SetSetting('bar3', 'hotkey.position', 'TOPLEFT', 'point')
	AB:SetSetting('all', 'spacing', 5)
	AB.config.bar3.enable = false

	for _, look in ipairs({ 'thick', 'blizzard' }) do
		st.config.profile.theme.name = look
		local width = look == 'blizzard' and 368 or 388
		local r = root()
		for _, pick in ipairs({ 'all', 'bar3', 'pet' }) do
			local content = CreateFrame('Frame', nil, UIParent)
			content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
			content:SetSize(width, 2400)
			local body = OB.New(content, r, function() end, 774)
			body:SetWidth(width, true)
			body:Draw(view(r, pick).sections)
			local where = look .. ' ' .. pick .. ': '
			check(#body.cells > 0, where .. 'drawn')
			for _, c in ipairs(body.cells) do
				local left, right = c.frame:GetLeft() - content:GetLeft(), c.frame:GetRight() - content:GetLeft()
				check(left >= 0 and right <= width, where .. tostring(c.row.key) .. ' inside the body')
				if c.frame.defaultReset and c.frame.defaultReset:IsShown() then
					check(c.frame.defaultReset:GetRight() <= c.frame:GetRight(), where .. c.row.key .. ': its reset inside its cell')
				end
			end
			-- Every row on a line of its own, but the quarters, which pair.
			local lines = {}
			for _, c in ipairs(body.cells) do
				local top = c.frame:GetTop()
				lines[top] = (lines[top] or 0) + 1
			end
			for top, n in pairs(lines) do check(n <= 2, where .. 'no more than two to a line at ' .. top) end
			local by = {}
			for _, c in ipairs(body.cells) do by[c.row.key] = c end
			if pick == 'all' then
				eq(by.hotkey.frame:GetTop(), by.count.frame:GetTop(), where .. 'Hotkey and Stack count on a line')
				eq(by.macro.frame:GetTop(), by.countdown.frame:GetTop(), where .. 'Macro name and Cooldown on the next')
				check(by.macro.frame:GetTop() < by.hotkey.frame:GetTop(), where .. 'under it')
				eq(math.floor(by.spacing.frame:GetWidth() + 0.5), look == 'blizzard' and width or width - 28, where .. 'a setting takes the whole line')
				check(by.spacing.frame.defaultReset:IsShown(), where .. "Spacing's reset shows")
				check(by.perrow.frame.share and by.perrow.frame.share.diff:IsShown(), where .. 'a diff icon')
			elseif pick == 'bar3' then
				check(by.size.frame.share.mark:IsShown(), where .. 'the own mark')
			end
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				stub.size_noise = noise
				body:Release()
				body:Draw(view(r, pick).sections)
				local off = P.off(content)
				eq(#off, 0, where .. 'noise ' .. noise .. ': ' .. P.report(off))
			end
			stub.size_noise = 0
			body:Release()
		end
	end
	st.config.profile.theme.name = 'thick'
	no_errors()
end)
