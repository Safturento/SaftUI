-- A reset on every setting, the kit's half (SaftUI-Core/Config/optionsdefault.lua):
-- st:DefaultAt (what a fresh AceDB profile holds at a saved path), the `saved`
-- field and its builders, the reset sources in order, how each value type
-- compares and writes, a mover's Position resetting through edit mode, and what
-- all of it costs per row per render.
--
-- Real: config_helpers.lua's AceDB, the model, the widgets and the body (the
-- window's world), edit mode (a mover and its history) and optionsdefault.lua.
-- The pages are synthetic, saved under a profile key of this file's own.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsdefault.lua')
local OM, OB, W = st.OptionsModel, st.OptionsBody, st.OptionsWidgets
local EM = st.EditModeFrames
local generators = st.Config.generators

------------------------------------------------------------------ the saved data

local DEFAULTS = {
	toggle = true, range = 0.3, select = 'a', input = '200', keybinding = '', font = 'normal',
	color = { r = 1, g = 0, b = 0, a = 1 },
	multi = { a = true, b = false },
	position = { point = 'TOP', rel_point = 'TOP', frame = 'UIParent', x_off = 0.5, y_off = 0 },
	text = 'Hello',
}

local function fresh_defaults()
	st.defaults.sv_ = {}
	for key, value in pairs(DEFAULTS) do st.defaults.sv_[key] = type(value) == 'table' and st.tablecopy(value, true) or value end
end

-- The saved data, in the active profile (read at call time, so a profile switch reaches it).
local function data() return st.config.profile.sv_ end
local function reset_data()
	fresh_defaults()
	st.config.profile.sv_ = {}
	for key, value in pairs(st.defaults.sv_) do
		st.config.profile.sv_[key] = type(value) == 'table' and st.tablecopy(value, true) or value
	end
end

local counts

local function Page(extra)
	local args = {
		box = {
			type = 'group', name = 'Box', order = 1,
			get = function(info) counts.get = counts.get + 1; return data()[info[#info]] end,
			set = function(info, value) counts.set = counts.set + 1; data()[info[#info]] = value end,
			saved = st.Config.SavedIn('sv_'),
			args = {
				toggle = { type = 'toggle', name = 'A toggle', order = 1 },
				range = { type = 'range', name = 'A range', order = 2, min = 0, max = 1, step = 0.01 },
				select = { type = 'select', name = 'A select', order = 3, values = { a = 'Apple', b = 'Banana' } },
				input = { type = 'input', name = 'An input', order = 4 },
				keybinding = { type = 'keybinding', name = 'A key', order = 5 },
				font = { type = 'font', name = 'A font', order = 6 },
			},
		},
		color = {
			type = 'color', name = 'A color', order = 2, hasAlpha = true,
			get = function() local c = data().color; return c.r, c.g, c.b, c.a end,
			set = function(_, r, g, b, a) local c = data().color; c.r, c.g, c.b, c.a = r, g, b, a end,
			saved = st.Config.SavedAt('sv_', 'color'),
		},
		multi = {
			type = 'multiselect', name = 'Show in', order = 3, values = { a = 'Bags', b = 'Bank' },
			get = function(_, key) return data().multi[key] end,
			set = function(_, key, value) counts.multi = counts.multi + 1; data().multi[key] = value end,
			saved = st.Config.SavedAt('sv_', 'multi'),
		},
		position = generators.position(4, true, function(part) return data().position[part] end,
			function(part, value) data().position[part] = value end, nil, nil, 'Position',
			st.Config.SavedAt('sv_', 'position')),
	}
	for key, value in pairs(extra or {}) do args[key] = value end
	return { Page = { type = 'group', name = 'Page', args = args } }
end

local function new_row(root, ...)
	local path = { ... }
	local option = { args = root }
	for _, key in ipairs(path) do option = OM.SubOption(option, key) end
	return { option = option, path = path, type = option.type, key = path[#path] }
end

local function setup()
	counts = { get = 0, set = 0, multi = 0 }
	reset_data()
	local root = Page()
	return root, function(...) return new_row(root, 'Page', ...) end
end

------------------------------------------------------------------ DefaultAt

test('DefaultAt follows AceDB: a sibling **, a table **, a *', function()
	st.defaults.t_ = { a = { x = 1, ['**'] = { deep = true } }, ['**'] = { y = 2, x = 9 }, star = { ['*'] = 5 } }
	local function at(...) local found, value = st:DefaultAt(...); return found, value end
	local found, value = at('t_', 'a', 'x')
	check(found and value == 1, "an own key beats the sibling '**'")
	found, value = at('t_', 'a', 'y')
	check(found and value == 2, "a key only the sibling '**' names (AceDB copies it into a)")
	found, value = at('t_', 'b', 'y')
	check(found and value == 2, "a key of a table that is only the parent's '**'")
	found, value = at('t_', 'a', 'z', 'deep')
	check(found and value == true, "a's own '**' for a key nothing names")
	found, value = at('t_', 'star', 'q')
	check(found and value == 5, "a '*'")
	eq(select(1, at('t_', 'nope')), false, "a '**' table is not a default for a key")
	eq(select(1, at('t_', 'a', 'x', 'too', 'deep')), false, 'a path below a value is none')
	eq(select(1, at()), false, 'no keys is none')

	-- A table default is the table itself, never a copy.
	local found2, tbl = st:DefaultAt('sv_', 'position')
	reset_data()
	found2, tbl = st:DefaultAt('sv_', 'position')
	check(found2 and tbl == st.defaults.sv_.position, 'a table default is the one in st.defaults')

	-- The unit frames' shape: a profile name and a unit name that nothing names, an element-level '**'.
	load_saftui('SaftUI-Unitframes/config/default.lua')
	found, value = at('unitframes', 'profiles', 'Healer', 'player', 'buffs', 'alpha')
	check(found and value == 1, "an aura element's alpha is the element-level '**' (1), not buffs' own '**' table")
	found, value = at('unitframes', 'profiles', 'Healer', 'player', 'health', 'enable')
	check(found and type(value) == 'boolean', "a profile of another name finds the unit's own defaults")
	found, value = at('unitframes', 'profiles', 'SaftUI', 'player', 'buffs', 'mine', 'filter', 'whitelist', 'enable')
	check(found and value == false, "buffs' own '**' (the aura groups') gives a group its filter defaults")
end)

test('SavedIn and SavedAt give the keys as returns, parts that are functions called with info', function()
	local function keys(f, info) return table.concat({ f(info) }, ',') end
	eq(keys(st.Config.SavedIn('chat'), { 'Chat', 'general', 'font' }), 'chat,font', 'SavedIn: the parts, then the option key')
	eq(keys(st.Config.SavedIn(), { 'Chat', 'size' }), 'size', 'no parts: the key')
	eq(keys(st.Config.SavedAt('a', function(info) return info[1] end, 'c'), { 'p' }), 'a,p,c', 'SavedAt: the parts exactly, a function called')
	eq(keys(st.Config.SavedAt('a'), {}), 'a', 'one part')
	check(not pcall(st.Config.SavedAt), 'none is an error')
	local seven = { 1, 2, 3, 4, 5, 6, 7 }
	eq(keys(st.Config.SavedIn(unpack(seven)), { 'x', 'k' }), '1,2,3,4,5,6,7,k', 'SavedIn takes seven parts')
	check(not pcall(st.Config.SavedIn, 1, 2, 3, 4, 5, 6, 7, 8), 'and no more')
end)

------------------------------------------------------------------ the source

test('the sources in order: share, default, mover, derived, noReset, else nil', function()
	local root = Page({
		shared = { type = 'toggle', name = 'Shared', order = 10, share = { own = true }, default = { differs = function() return false end } },
		hand = { type = 'toggle', name = 'Hand', order = 11, default = { differs = function() return false end, reset = function() end },
			get = function() return true end },
		noreset = { type = 'toggle', name = 'Session only', order = 12, get = function() return true end, noReset = 'session only' },
		empty = { type = 'toggle', name = 'Empty reason', order = 13, get = function() return true end, noReset = '' },
		bare = { type = 'toggle', name = 'Bare', order = 14, get = function() return true end },
		go = { type = 'execute', name = 'Go', order = 15, func = function() end },
		words = { type = 'description', name = 'Words', order = 16 },
		nothing = { type = 'item', name = 'No Show', order = 17, get = false, menu = { type = 'group', name = 'x', args = {} } },
		list = { type = 'bagitems', name = 'List', order = 18 },
	})
	reset_data()
	local function source(...) return OM.DefaultSource(root, new_row(root, 'Page', ...)) end
	eq(source('shared'), 'share', 'a member share with own')
	eq(source('hand'), 'default', 'a default field')
	eq(source('box', 'toggle'), 'derived', "a group's saved over a toggle")
	eq(source('color'), 'derived', "an option's own saved")
	eq(source('noreset'), 'none', 'a noReset')
	eq(source('empty'), nil, 'an empty noReset is none given')
	eq(source('bare'), nil, 'a row with no source')
	eq(source('go'), 'none', 'an execute has no value')
	eq(source('words'), 'none', 'a description has no value')
	eq(source('nothing'), 'none', 'an item with get = false')
	eq(source('list'), 'none', "a bags' list")
	eq(source('position'), 'derived', 'a position with a saved of its own and no mover')
end)

test('saved is read from the node that gives get', function()
	local root = Page()
	root.Page.args.inner = {
		type = 'group', name = 'Inner', order = 20,
		get = function() return true end, saved = st.Config.SavedIn('sv_'),
		args = {
			own = { type = 'toggle', name = 'Own get', order = 1, get = function() return true end },
			ownSaved = { type = 'toggle', name = 'Own get and saved', order = 2, get = function() return true end,
				saved = st.Config.SavedAt('sv_', 'toggle') },
			plain = { type = 'toggle', name = 'Plain', order = 3 },
		},
	}
	root.Page.args.off = {
		type = 'group', name = 'Off', order = 21, get = function() return true end, saved = false,
		args = { plain = { type = 'toggle', name = 'Plain', order = 1 } },
	}
	local function source(...) return OM.DefaultSource(root, new_row(root, 'Page', ...)) end
	eq(source('inner', 'own'), nil, "an option with a get of its own does not take its group's saved")
	eq(source('inner', 'ownSaved'), 'derived', 'with a saved of its own it does')
	eq(source('inner', 'plain'), 'derived', "no get of its own: the group's, with its saved")
	eq(source('off', 'plain'), nil, 'a group saved = false gives none')
end)

------------------------------------------------------------------ comparing

test('SameValue by type', function()
	local S = OM.SameValue
	check(S('toggle', nil, false) and S('toggle', true, true) and not S('toggle', true, false), 'toggle: nil is false')
	check(S('item', nil, false), 'item likewise')
	check(S('range', 0.30000001, 0.3) and not S('range', 0.3, 0.31), 'range within 1e-4')
	check(S('input', '200', 200) and not S('input', 'a', 'A') and S('input', nil, ''), "input: '200' is 200, text is case-exact, nil is empty")
	check(S('select', 'a', 'a') and not S('select', 'a', 'b') and S('select', 2, 2.00001), 'select: the key')
	check(S('multiselect', { a = true }, { a = true, b = false }) and not S('multiselect', { a = true }, { a = true, b = true }),
		'multiselect: nil and false the same')
	check(S('color', { 1, 0, 0 }, { 1, 0, 0, 1 }), 'color: no alpha is 1, and without hasAlpha it does not count')
	check(not S('color', { 1, 0, 0, 0.5 }, { 1, 0, 0, 1 }, { hasAlpha = true }), 'color: alpha counts with hasAlpha')
	check(S('color', { 1, 0, 0, 0.5 }, { 1, 0, 0, 0.5 + 0.5 / 255 }, { hasAlpha = true }), 'color: half a byte off is the same byte')
	check(S('color', { r = 1, g = 0, b = 0 }, { 1, 0, 0 }), 'color: fields or an array')
	check(not S('font', 'normal', { font_name = 'Colus' }), 'font: a key against a table always differs')
	check(not S('font', { font_name = 'Colus' }, 'normal'), 'font: and the other way')
	check(S('font', 'pixel', 'pixel') and not S('font', 'pixel', 'normal'), 'font: keys')
	check(S('font', { font_name = 'Colus', font_size = 12 }, { font_name = 'Colus', font_size = 12 }), 'font: the same fields')
	check(not S('font', { font_name = 'Colus', font_size = 12 }, { font_name = 'Colus', font_size = 13 }), 'font: another size')
	check(S('keybinding', nil, '') and not S('keybinding', 'F', ''), 'keybinding: nil is empty')
	local a = { point = 'TOP', x_off = 3, y_off = 0 }
	check(S('position', a, { point = 'TOP', rel_point = 'TOP', frame = 'UIParent', x_off = '3', y_off = 0 }),
		'position: rel_point defaults to the point, the screen is nothing, offsets are numbers')
	check(not S('position', a, { point = 'TOP', x_off = 4, y_off = 0 }), 'position: an offset')
	check(not S('position', { point = 'TOP' }, { point = 'TOP', frame = 'Foo' }), 'position: a frame')
	check(not S('position', { point = 'TOP', frame = 'UIParent' }, { point = 'TOP' }, { relative = true }),
		'position: with an element dropdown, nothing is the unit frame, not the screen')
	check(S('position', { point = 'TOP', element = false }, { point = 'TOP' }), 'position: no element is false')
	check(not S('position', { point = 'TOP', element = 'health' }, { point = 'TOP' }), 'position: an element')
	check(S('anything', { 1, { 2 } }, { 1, { 2.00001 } }), 'a table otherwise: deep, numbers within 1e-4')
end)

test('offsets compare as the set stores them', function()
	local root, row = setup()
	data().position.x_off = 0.5 -- the profile holds the default as AceDB copied it
	check(not OM.DefaultDiffers(root, row('position')), 'a default of half a pixel is the saved half pixel on a fresh profile')
	data().position.x_off = 7
	check(OM.DefaultDiffers(root, row('position')), 'moved: it differs')
	local ok = OM.DefaultReset(root, row('position'))
	check(ok, 'the reset runs')
	eq(data().position.x_off, tonumber(st:RoundToPixel(0.5)), 'it wrote the offset as the set stores it: whole pixels')
	check(not OM.DefaultDiffers(root, row('position')), 'and the icon is gone, not stuck')
	local o = row('position').option
	eq(o.saved ~= nil, true, "generators.position's saved is on its option")
end)

------------------------------------------------------------------ writing

test('WriteValue goes through set: validate runs, a failure stops it and says why', function()
	local root, row = setup()
	local box = root.Page.args.box
	box.validate = function(info, value) return value ~= 7 or 'seven is not allowed' end
	local ok, message = OM.WriteValue(root, row('box', 'range'), 7)
	check(ok == false and message == 'seven is not allowed', 'a validate refusing 7: false and its message (' .. tostring(message) .. ')')
	eq(counts.set, 0, 'nothing was set')
	eq(data().range, 0.3, 'nothing was written')
	box.validate = nil
	ok = OM.WriteValue(root, row('box', 'range'), 0.5)
	check(ok == true and counts.set == 1 and data().range == 0.5, 'a valid value goes through set')

	-- A color writes r, g, b, a.
	local args
	root.Page.args.color.set = function(_, ...) args = { ... } end
	OM.WriteValue(root, row('color'), { 0.1, 0.2, 0.3, 0.4 })
	eq(table.concat(args, ','), '0.1,0.2,0.3,0.4', 'a color writes r, g, b, a')

	-- A multiselect calls set only for the keys that differ.
	counts.multi = 0
	OM.WriteValue(root, row('multi'), { a = true, b = true })
	eq(counts.multi, 1, 'a multiselect sets only the key that differs')
	check(data().multi.a == true and data().multi.b == true, 'b came on, a stayed')

	-- An input is text.
	root.Page.args.box.args.input.pattern = '^%d+$'
	ok, message = OM.WriteValue(root, row('box', 'input'), 'abc')
	check(ok == false and message ~= nil, "an input's pattern is checked")

	-- A position sets only the parts that differ, in order.
	local order = {}
	local position = root.Page.args.position
	local original = position.set
	position.set = function(info, part, value) order[#order + 1] = part; return original(info, part, value) end
	data().position.point, data().position.rel_point, data().position.x_off, data().position.frame = 'BOTTOM', 'BOTTOM', 9, 'Foo'
	OM.WriteValue(root, row('position'), OM.DefaultValueOf(root, row('position'), st.defaults.sv_.position))
	eq(table.concat(order, ','), 'point,rel_point,frame,x_off', 'a position sets the parts that differ in the order point, rel_point, frame, x_off')
	eq(data().position.point, 'TOP', 'point')
	eq(data().position.frame, 'UIParent', 'frame')
end)

test('a table default is written as a copy, never the table in st.defaults', function()
	local root, row = setup()
	data().font = { font_name = 'Colus' }
	st.defaults.sv_.font = { font_name = 'Colus', font_size = 12, shadow_offset = { 1, -1 } }
	local ok = OM.DefaultReset(root, row('box', 'font'))
	check(ok and data().font ~= st.defaults.sv_.font, 'the saved typeface is a table of its own')
	check(data().font.shadow_offset ~= st.defaults.sv_.font.shadow_offset, 'and so is the shadow offset below it')
	data().font.font_size = 99
	eq(st.defaults.sv_.font.font_size, 12, 'writing it never reaches st.defaults')
	st.defaults.sv_.color.a = nil
	root.Page.args.color.set = function(_, r, g, b, a) data().color = { r = r, g = g, b = b, a = a } end
	data().color = { r = 0, g = 0, b = 0, a = 1 }
	OM.DefaultReset(root, row('color'))
	eq(data().color.a, 1, 'a color default with no alpha writes 1')
end)

test('nothing is written to a profile by merely looking', function()
	local root, row = setup()
	local before = {}
	for key in pairs(st.config.profile) do before[#before + 1] = key end
	for _, name in ipairs({ 'toggle', 'range', 'select', 'input', 'keybinding' }) do OM.DefaultDiffers(root, row('box', name)) end
	OM.DefaultDiffers(root, row('color')); OM.DefaultDiffers(root, row('multi')); OM.DefaultDiffers(root, row('position'))
	OM.SourceState(root, row('box', 'toggle'))
	local after = {}
	for key in pairs(st.config.profile) do after[#after + 1] = key end
	table.sort(before); table.sort(after)
	eq(table.concat(after, ','), table.concat(before, ','), 'the profile has the same keys after the rows were asked')
	eq(counts.set, 0, 'and no set ran')
end)

------------------------------------------------------------------ a mover

test('a mover Position resets through edit mode', function()
	local root = {}
	local frame = CreateFrame('Frame', 'SavedMoverFrame', UIParent)
	frame:SetSize(100, 50)
	local cfg = { position = { point = 'CENTER', rel_point = 'CENTER', frame = 'UIParent', x_off = 0, y_off = 0 } }
	local default = { point = 'TOPRIGHT', rel_point = 'TOPRIGHT', frame = 'UIParent', x_off = -320, y_off = -275 }
	local applied = 0
	st:RegisterConfigMover(frame, { key = 'sv_mover', label = 'Saved mover', config = function() return cfg end,
		apply = function() applied = applied + 1 end, configPath = { 'Page', 'general' },
		getDefaultPosition = function() return st.tablecopy(default, true) end })
	local position = generators.position(1000, true, function(part) return cfg.position[part] end,
		function(part, value) cfg.position[part] = value end)
	root.Page = { type = 'group', name = 'Page', args = { general = { type = 'group', name = 'General', args = { position = position } } } }
	local row = new_row(root, 'Page', 'general', 'position')
	eq(EM:MoverAt({ 'Page', 'general' }), EM.movers.sv_mover, 'EM:MoverAt finds the mover by its configPath')
	eq(EM:MoverAt({ 'Page', 'general', 'position' }, 2), EM.movers.sv_mover, 'a length takes the first keys only')
	eq(EM:MoverAt({ 'Page', 'other' }), nil, 'none for another path')
	eq(OM.DefaultSource(root, row), 'mover', 'a Position in the mover section is a mover row')
	check(OM.DefaultDiffers(root, row), 'in another place than its default: it differs')

	EM.History:Clear()
	local ok = OM.DefaultReset(root, row)
	check(ok, 'the reset ran')
	eq(cfg.position.x_off, -320, 'EM:Reset put the default')
	eq(applied, 1, 'through the mover apply')
	eq(#EM.History:Steps(), 1, 'one history step')
	eq(EM.History:Steps()[1].kind, 'reset', 'a reset')
	check(not OM.DefaultDiffers(root, row), 'the icon is gone')
	EM.History:Undo()
	eq(cfg.position.x_off, 0, 'Undo puts it back')
	check(OM.DefaultDiffers(root, row), 'and it differs again')

	local state = OM.DefaultState(root, row)
	check(state and state.differs and state.value and state.value[1].x_off == -320, "its state has the mover's default position")
	state.value[1].x_off = 1
	eq(EM:GetDefaultPosition(EM.movers.sv_mover).x_off, -320, 'a copy')

	-- No default: no icon, still a mover row.
	EM.movers.sv_mover.def.getDefaultPosition = nil
	EM.movers.sv_mover.def.noDefaultReason = 'Blizzard places it until it is moved.'
	eq(OM.DefaultSource(root, row), 'mover', 'a mover without a default is still a mover row')
	check(not OM.DefaultDiffers(root, row), 'with no default: no icon')

	-- A default anchored to a frame that is anchored to this one.
	local other = CreateFrame('Frame', 'SavedMoverOther', UIParent)
	other:SetSize(10, 10)
	other:SetPoint('CENTER', frame, 'CENTER')
	EM.movers.sv_mover.def.getDefaultPosition = function() return { point = 'TOP', frame = 'SavedMoverOther', x_off = 0, y_off = 0 } end
	check(not OM.DefaultDiffers(root, row), 'a default that would loop shows no icon')
	EM.movers.sv_mover = nil
end)

------------------------------------------------------------------ a profile switch

test('a profile switch: differs reads the new profile, a reset writes the new one', function()
	local root, row = setup()
	data().toggle = false
	check(OM.DefaultDiffers(root, row('box', 'toggle')), 'the first profile differs')
	local first = st.config:GetCurrentProfile()
	st.config:SetProfile('Another')
	st.config.profile.sv_ = {}
	for key, value in pairs(st.defaults.sv_) do st.config.profile.sv_[key] = value end
	check(not OM.DefaultDiffers(root, row('box', 'toggle')), 'the new profile holds the default: no icon')
	data().toggle = false
	check(OM.DefaultDiffers(root, row('box', 'toggle')), 'changed there: it differs')
	OM.DefaultReset(root, row('box', 'toggle'))
	eq(data().toggle, true, 'the reset wrote the new profile')
	st.config:SetProfile(first)
	eq(data().toggle, false, 'and left the first one as it was')
end)

------------------------------------------------------------------ cost

-- GameTooltip, as a stand-in that notes each line.
local function watch_tooltip()
	local tip = { lines = {} }
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) tip.owner = frame; tip.lines = {} end,
		AddLine = function(_, text) tip.lines[#tip.lines + 1] = text end,
		AddDoubleLine = function(_, left) tip.lines[#tip.lines + 1] = left end,
		Show = function() end,
		IsOwned = function(_, frame) return tip.owner == frame end,
		Hide = function() tip.owner = nil end,
	}
	return tip, function() _G.GameTooltip = saved end
end

test('the cost: a draw asks saved once a row and get at most once more, and no words before a tooltip', function()
	local root = setup()
	local saved_calls, get_calls = 0, 0
	local args = {}
	for i = 1, 40 do
		args['t' .. i] = {
			type = 'toggle', name = 'Toggle ' .. i, order = i,
			get = function() get_calls = get_calls + 1; return data().toggle end,
			set = function(_, value) data().toggle = value end,
			saved = function() saved_calls = saved_calls + 1; return 'sv_', 'toggle' end,
		}
	end
	root = { Page = { type = 'group', name = 'Page', args = args } }
	data().toggle = false
	local states, tips = 0, 0
	local state_of = OM.DefaultState
	OM.DefaultState = function(...) states = states + 1; return state_of(...) end
	local tip, restore = watch_tooltip()
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 2400)
	local body = OB.New(content, root, nil, 774)
	body:Draw(OM.BuildView(root, 'Page').sections)
	OM.DefaultState = state_of
	eq(saved_calls, 40, 'saved is asked once for each of 40 rows')
	check(get_calls <= 80, 'get at most twice a row, the widget\'s own read and one more (' .. get_calls .. ')')
	eq(states, 0, 'no default words are worked out while drawing')
	local shown = 0
	for _, cell in ipairs(body.cells) do
		if cell.frame.defaultReset and cell.frame.defaultReset:IsShown() then shown = shown + 1 end
	end
	eq(shown, 40, 'every row differs: 40 icons')

	local count = 0
	OM.DefaultState = function(...) count = count + 1; return state_of(...) end
	local icon = body.cells[1].frame.defaultReset
	stub.fire_script(icon, 'OnEnter', true)
	OM.DefaultState = state_of
	restore()
	eq(count, 1, "the words are worked out when the icon's tooltip opens")
	eq(tip.lines[1], 'Reset', "and the tooltip says Reset")
	eq(tip.lines[2], 'Toggle 1 goes back to its default: on.', 'and the default in words')
end)

test('asking whether a row differs allocates nothing, ten thousand times, on every type', function()
	local root, row = setup()
	root.Page.args.box.args.keybinding = nil
	local rows = {}
	for _, name in ipairs({ 'toggle', 'range', 'select', 'input', 'font' }) do rows[#rows + 1] = row('box', name) end
	rows[#rows + 1] = row('color'); rows[#rows + 1] = row('multi'); rows[#rows + 1] = row('position')
	data().range, data().toggle, data().input, data().font, data().select = 0.9, false, 'x', 'pixel', 'b'
	data().color.r = 0.2
	data().multi.b = true
	data().position.x_off = 9
	for _, each in ipairs(rows) do
		check(OM.DefaultDiffers(root, each), each.type .. ' differs')
		collectgarbage(); collectgarbage('stop')
		local before = collectgarbage('count')
		for _ = 1, 10000 do OM.DefaultDiffers(root, each) end
		local grown = collectgarbage('count') - before
		collectgarbage('restart')
		check(grown < 20, each.type .. ' makes no table per ask (grew ' .. grown .. ' KB)')
	end
	-- And when it is the default.
	reset_data()
	for _, each in ipairs(rows) do
		collectgarbage(); collectgarbage('stop')
		local before = collectgarbage('count')
		for _ = 1, 10000 do OM.DefaultDiffers(root, each) end
		local grown = collectgarbage('count') - before
		collectgarbage('restart')
		check(grown < 20, each.type .. ' at its default makes no table per ask (grew ' .. grown .. ' KB)')
	end
end)
