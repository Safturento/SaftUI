-- The harness's own checks. Every other test trusts what these pin: that the
-- suite really runs WoW's Lua 5.1, that the WoW stubs are strict and fail the
-- way the game does, that load_saftui hands a SaftUI file what WoW does, and
-- that the core shell and reset_world behave as documented in
-- .agents/testing.md. If one of these goes red, fix it before trusting any
-- other result.

test('runs on Lua 5.1, the version WoW uses', function()
	eq(_VERSION, 'Lua 5.1')
end)

-- WoW's Lua has no files, process or module loading. Without this a test
-- could end the run with os.exit before its report, or load a SaftUI file
-- around load_saftui's ... and line-ending handling.
test("Lua's library WoW lacks is out of reach", function()
	local names = { 'io', 'os', 'require', 'dofile', 'loadfile', 'package', 'module', 'python' }
	for _, name in ipairs(names) do
		eq(_G[name], nil, name)
	end
	reset_world()
	for _, name in ipairs(names) do
		eq(_G[name], nil, name .. ' after reset_world')
	end
end)

test('a stub frame answers only the methods it defines', function()
	local frame = CreateFrame('Frame')
	eq(frame.NotAMethod, nil, 'a frame has no NotAMethod')
	local ok, err = pcall(function() frame:NotAMethod() end)
	eq(ok, false, 'calling NotAMethod errors')
	check(tostring(err):find('NotAMethod', 1, true), 'the error names the method: ' .. tostring(err))
end)

test('a FontString method called on a Button errors, as in game', function()
	local b = CreateFrame('Button')
	local fs = b:CreateFontString()
	local ok, err = pcall(fs.SetText, b, 'x')
	eq(ok, false, 'FontString:SetText with a Button as self')
	-- Without the type check SetText would still fail ("Font not set"), so
	-- check it failed for the right reason.
	check(tostring(err):find('Wrong object type', 1, true), "WoW's wrong-object error: " .. tostring(err))

	-- The same method with the right self works.
	fs:SetFont('Fonts\\FRIZQT__.TTF', 12)
	fs:SetText('x')
	eq(fs:GetText(), 'x', 'FontString:SetText on the FontString')
end)

test('a FontString with no font refuses text, as in game', function()
	local fs = CreateFrame('Frame'):CreateFontString()
	local ok, err = pcall(fs.SetText, fs, 'x')
	eq(ok, false, 'SetText before any font is set')
	check(tostring(err):find('Font not set', 1, true), "WoW's error: " .. tostring(err))

	-- Like the game's, the error points at the code that called the method.
	ok, err = pcall(function() fs:SetText('x') end)
	check(tostring(err):find('^tests/lib/harness_self_test%.lua:%d+: '), 'the error starts with the caller\'s file:line: ' .. tostring(err))
end)

test('load_saftui passes the addon folder name and its namespace as ...', function()
	reset_world()
	-- constants.lua (loaded by the shell) builds its media paths from the addon
	-- name it's given.
	eq(SaftUI:TexturePath('x.tga'), 'Interface\\AddOns\\SaftUI-Core\\Media\\Textures\\x.tga',
		'a SaftUI-Core file gets "SaftUI-Core"')

	-- SaftUI-Core's namespace is SaftUI itself, as in game, where init.lua makes
	-- the addon object from it. sharedmedia.lua writes st.LSM onto the namespace
	-- it's given.
	check(addon_namespace('SaftUI-Core') == SaftUI, "SaftUI-Core's namespace is SaftUI")
	load_core_helpers()
	check(SaftUI.LSM ~= nil, 'sharedmedia.lua got SaftUI as its namespace')

	-- Two files of one addon share its namespace: oUF's init.lua puts oUF on it,
	-- and enums.lua reads it back.
	load_saftui('SaftUI-Unitframes/Libraries/oUF/init.lua')
	load_saftui('SaftUI-Unitframes/Libraries/oUF/enums.lua')
	local ns = addon_namespace('SaftUI-Unitframes')
	check(ns.oUF and ns.oUF.Enum and ns.oUF.Enum.SelectionType.Hostile == 0,
		'enums.lua saw the oUF that init.lua put on the shared namespace')
	check(ns ~= addon_namespace('SaftUI-Core'), 'each addon has its own namespace')
end)

test('load_saftui takes one path, inside an addon folder', function()
	check(not pcall(load_saftui, 'SaftUI-Core/constants.lua', 'extra'), 'extra arguments error')
	check(not pcall(load_saftui, 'constants.lua'), 'a path outside any addon folder errors')
	local ok, err = pcall(load_saftui, 'SaftUI-Core/no_such_file.lua')
	eq(ok, false, 'a missing file errors')
	check(tostring(err):find('no_such_file.lua', 1, true), 'the error names the file: ' .. tostring(err))
end)

test('apply_defaults fills the profile from st.defaults and keeps what is there', function()
	reset_world()
	SaftUI.defaults = { a = { b = 1, c = { d = 2 } }, e = 3 }
	SaftUI.config.profile = { a = { b = 9 } }
	apply_defaults()
	local profile = SaftUI.config.profile
	eq(profile.a.b, 9, 'an existing value is kept')
	eq(profile.a.c.d, 2, 'a missing nested value is filled in')
	eq(profile.e, 3, 'a missing top-level value is filled in')
	check(profile.a.c ~= SaftUI.defaults.a.c, 'tables are copied, not shared with st.defaults')

	-- With Core's real defaults file, as tests load it.
	reset_world()
	load_saftui('SaftUI-Core/Config/defaults.lua')
	apply_defaults()
	eq(SaftUI.config.profile.editmode.grid_size, 32, 'editmode.grid_size from defaults.lua')
	check(SaftUI.config.profile.editmode ~= SaftUI.defaults.editmode, 'the profile has its own copy')
	local r, g, b = SaftUI.config.profile.colors.button.blue:GetRGB()
	check(r == 0 and g == 0.68 and b == 0.94, 'colors keep their ColorMixin methods')
end)

test("apply_defaults has AceDB's wildcard keys: '**' fills every sibling, made later too", function()
	reset_world()
	SaftUI.defaults = {
		profiles = { ['**'] = { player = { width = 1, tags = { 'a' } }, ['*'] = 7 } },
		named = { fixed = { own = 1 }, ['**'] = { extra = 2 } },
		scalar = { ['*'] = 'x' },
	}
	SaftUI.config.profile = { profiles = { Old = { player = { width = 9 } } } }
	apply_defaults()
	local profiles = SaftUI.config.profile.profiles
	eq(rawget(profiles, '**'), nil, "'**' is not a key of the profile")
	eq(profiles.Old.player.width, 9, 'a value the profile has is kept')
	eq(profiles.Old.player.tags[1], 'a', 'a table the profile already had gets the defaults')
	eq(rawget(profiles, 'New'), nil, 'a profile nobody has asked for is not there')
	eq(profiles.New.player.width, 1, 'a key made later gets the defaults')
	check(rawget(profiles, 'New') ~= nil, 'and is kept once read')
	check(profiles.New.player ~= profiles.Other.player and profiles.New.player.tags ~= profiles.Other.player.tags,
		'each key gets its own copy')
	profiles.New.player.width = 5
	eq(profiles.Other.player.width, 1, 'changing one leaves the next key at the defaults')
	eq(profiles.New.anything, 7, "'*' with a plain value is what any other key reads as")
	eq(rawget(profiles.New, 'anything'), nil, 'and is not stored')
	eq(SaftUI.config.profile.named.fixed.extra, 2, "a '**' beside a table's key also fills that key's table")
	eq(SaftUI.config.profile.named.fixed.own, 1, 'and its own defaults stay')
	eq(SaftUI.config.profile.named.other.extra, 2, 'and fills any other key')
	eq(SaftUI.config.profile.scalar.whatever, 'x', 'a scalar wildcard answers any key')
	local count = 0
	for _ in pairs(profiles) do count = count + 1 end
	eq(count, 3, 'pairs sees only the profiles made (Old, New, Other)')

	-- With the unit frames' real defaults, where config.lua depends on '**'.
	reset_world()
	load_saftui('SaftUI-Core/Config/defaults.lua')
	load_saftui('SaftUI-Unitframes/config/default.lua')
	apply_defaults()
	local uf = SaftUI.config.profile.unitframes
	eq(rawget(uf.profiles, '**'), nil, "unitframes.profiles has no literal '**' key")
	eq(uf.profiles.Fresh.player.width, 301, 'a new unit frame profile gets the real unit defaults')
end)

test('the shell enables a module once: OnInitialize, then OnEnable, then its submodules', function()
	reset_world()
	local calls = {}
	local M = SaftUI:NewModule('Probe')
	local Sub = M:NewModule('Sub')
	function M:OnInitialize() calls[#calls + 1] = 'init' end
	function M:OnEnable() calls[#calls + 1] = 'enable' end
	function Sub:OnEnable() calls[#calls + 1] = 'sub' end
	-- AceAddon's IsEnabled is the module's enabled state, true by default.
	eq(M:IsEnabled(), true, 'IsEnabled before Enable, as AceAddon has it')
	eq(#calls, 0, 'nothing runs before Enable')
	M:Enable()
	M:Enable()
	eq(table.concat(calls, ','), 'init,enable,sub', 'each runs once, in order')
	eq(M:IsEnabled(), true, 'IsEnabled after Enable')
	check(SaftUI:GetModule('Probe') == M and M:GetModule('Sub') == Sub, 'GetModule finds both')
	check(not pcall(SaftUI.GetModule, SaftUI, 'Missing'), 'GetModule errors on a missing module')
	eq(SaftUI:GetModule('Missing', true), nil, 'unless silent')
	check(not pcall(SaftUI.NewModule, SaftUI, 'Probe'), 'a second module with the same name errors')
end)

test("apply_defaults copies AceDB's conditions: false under a table default, a non-table value, a top-level '*'", function()
	reset_world()
	SaftUI.defaults = { a = { b = 1 }, c = { d = 2 }, e = { f = { g = 3 } } }
	SaftUI.config.profile = { a = false, c = 5, e = { f = false } }
	apply_defaults()
	local profile = SaftUI.config.profile
	-- AceDB: `if not rawget(dest, k) then rawset(dest, k, {})`, so false is replaced.
	eq(type(profile.a), 'table', 'false under a table default becomes a table')
	eq(profile.a.b, 1, 'and is filled with the defaults')
	eq(type(profile.e.f), 'table', 'also when nested')
	eq(profile.e.f.g, 3, 'and filled')
	-- A truthy non-table value is kept, and the table defaults are skipped.
	eq(profile.c, 5, 'a non-table value under a table default is kept')

	reset_world()
	SaftUI.defaults = { ['*'] = { x = 1, list = { 'a' } } }
	SaftUI.config.profile = { Old = { x = 9 } }
	apply_defaults()
	profile = SaftUI.config.profile
	eq(rawget(profile, '*'), nil, "a top-level '*' is not a key of the profile")
	eq(profile.Old.x, 9, 'a value the profile has is kept')
	eq(profile.Old.list[1], 'a', "an existing table gets the '*' defaults")
	eq(profile.New.x, 1, "a key made later gets the '*' defaults")
end)

test('Enable runs every OnInitialize in the subtree before any OnEnable', function()
	reset_world()
	local calls = {}
	local Parent = SaftUI:NewModule('Parent')
	local Child = Parent:NewModule('Child')
	local Grandchild = Child:NewModule('Grandchild')
	for name, module in pairs({ Parent = Parent, Child = Child, Grandchild = Grandchild }) do
		module.OnInitialize = function() calls[#calls + 1] = 'init ' .. name end
		module.OnEnable = function() calls[#calls + 1] = 'enable ' .. name end
	end
	Parent:Enable()
	eq(table.concat(calls, ','),
		'init Parent,init Child,init Grandchild,enable Parent,enable Child,enable Grandchild',
		"a parent's OnEnable runs after its children's OnInitialize")
end)

test('reset_world restores a base global or library member a test replaced', function()
	local print_, pairs_, format_, insert_ = print, pairs, string.format, table.insert
	print = function() end
	pairs = function() return next, {} end
	string.format = function() return 'replaced' end
	table.insert = nil
	string.added_by_a_test = true
	reset_world()
	check(print == print_ and pairs == pairs_, 'print and pairs are back')
	check(string.format == format_ and table.insert == insert_, 'library members are back')
	eq(string.added_by_a_test, nil, 'a member a test added is gone')
	eq(('%d'):format(5), '5', 'string methods work again')
	check(type(table.wipe) == 'function', "the stubs' own additions are still there")
end)

test('a name the trimmed Enum.PowerType lacks errors instead of reading nil', function()
	local ok, err = pcall(function() return Enum.PowerType.Rage end)
	eq(ok, false, 'Enum.PowerType.Rage errors')
	check(tostring(err):find('Enum.PowerType.Rage is not stubbed', 1, true), 'and names the enum and the name: ' .. tostring(err))
	eq(Enum.PowerType.Mana, 0, 'a stubbed name still reads')
	eq(Enum.BagIndex.CharacterBankTab_10, nil, "BagIndex is complete: probing past its last tab reads nil, as in game (inventory.lua relies on it)")
end)

test('module events dispatch the way AceEvent does', function()
	reset_world()
	local M = SaftUI:NewModule('Events')
	local got = {}
	function M:SOME_EVENT(event, arg) got[#got + 1] = event .. ':' .. tostring(arg) end
	function M:Named(event, arg) got[#got + 1] = 'named ' .. event .. ':' .. tostring(arg) end
	M:RegisterEvent('SOME_EVENT')
	M:RegisterEvent('OTHER_EVENT', 'Named')
	stub.fire_event('SOME_EVENT', 1)
	stub.fire_event('OTHER_EVENT', 2)
	M:UnregisterEvent('SOME_EVENT')
	stub.fire_event('SOME_EVENT', 3)
	eq(table.concat(got, ','), 'SOME_EVENT:1,named OTHER_EVENT:2', 'handlers ran with (event, ...)')
	check(not pcall(M.RegisterEvent, M, 'X_EVENT', 'NoSuchMethod'), 'a missing handler method errors')
end)

test("a frame's unit event hears only its units, until RegisterEvent or UnregisterEvent", function()
	reset_world()
	local frame = CreateFrame('Frame')
	local got = {}
	frame:SetScript('OnEvent', function(_, event, unit) got[#got + 1] = event .. ':' .. tostring(unit) end)
	frame:RegisterUnitEvent('UNIT_PET', 'player')
	frame:RegisterUnitEvent('UNIT_HEALTH', 'target', 'focus')
	check(frame:IsEventRegistered('UNIT_PET'), 'registered')
	stub.fire_event('UNIT_PET', 'party1')
	stub.fire_event('UNIT_PET', 'player')
	stub.fire_event('UNIT_HEALTH', 'player')
	stub.fire_event('UNIT_HEALTH', 'focus')
	stub.fire_event('UNIT_HEALTH', 'target')
	eq(table.concat(got, ','), 'UNIT_PET:player,UNIT_HEALTH:focus,UNIT_HEALTH:target', 'only the units it was registered for')
	got = {}
	frame:RegisterEvent('UNIT_PET')
	stub.fire_event('UNIT_PET', 'party1')
	eq(table.concat(got, ','), 'UNIT_PET:party1', 'RegisterEvent hears every unit again')
	got = {}
	frame:RegisterUnitEvent('UNIT_PET', 'player')
	frame:UnregisterEvent('UNIT_PET')
	check(not frame:IsEventRegistered('UNIT_PET'), 'unregistered')
	stub.fire_event('UNIT_PET', 'player')
	eq(table.concat(got, ','), '', 'an unregistered unit event is not heard')
	check(not pcall(frame.RegisterUnitEvent, frame, 'UNIT_PET'), 'a unit event with no unit errors')
	check(not pcall(frame.RegisterUnitEvent, frame, 7, 'player'), 'an event that is not a string errors')
end)

test('errors the game would report go to the error handler, for take_errors', function()
	xpcall(function() error('boom', 0) end, geterrorhandler())
	local errors = take_errors()
	eq(#errors, 1, 'one error reported')
	check(errors[1] and errors[1]:find('boom', 1, true), 'its message: ' .. tostring(errors[1]))
	eq(#take_errors(), 0, 'taking them clears them')
end)

test('stub frames are laid out from their anchors', function()
	reset_world()
	stub.screen_width, stub.screen_height = 1000, 600
	UIParent:SetScale(768 / 600) -- SaftUI's scale: one UIParent unit per physical pixel
	eq(UIParent:GetWidth(), 1000, 'UIParent width')
	eq(UIParent:GetHeight(), 600, 'UIParent height')

	local a = CreateFrame('Frame', nil, UIParent)
	a:SetSize(100, 40)
	a:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 10, 20)
	check(a:GetLeft() == 10 and a:GetRight() == 110 and a:GetBottom() == 20 and a:GetTop() == 60, 'rect from one anchor and a size')

	local b = CreateFrame('Frame', nil, UIParent)
	b:SetAllPoints(a)
	check(b:GetLeft() == 10 and b:GetTop() == 60 and b:GetWidth() == 100, 'SetAllPoints follows the other frame')

	eq(CreateFrame('Frame'):GetLeft(), nil, 'a frame with no anchors has no rect')
	check(not pcall(a.SetPoint, a, 'TOPLEFT', b, 'TOPLEFT'), 'an anchor loop errors')
	check(not pcall(a.SetPoint, a, 'MIDDLE'), 'an unknown point errors')
	check(not pcall(CreateFrame, 'Frame', nil, UIParent, 'NoSuchTemplate'), 'an unknown template errors')
end)

test('a frame marked protected has its moves, sizes and shows blocked in combat, and noted', function()
	reset_world()
	local guarded, free = CreateFrame('Frame', nil, UIParent), CreateFrame('Frame', nil, UIParent)
	for _, f in ipairs({ guarded, free }) do
		f:SetSize(100, 40)
		f:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -20)
	end
	function guarded:IsProtected() return true, true end
	eq(#stub.blocked, 0, 'nothing blocked out of combat')

	stub.in_combat = true
	guarded:ClearAllPoints()
	guarded:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 50, -50)
	guarded:SetHeight(80)
	guarded:Hide()
	free:SetHeight(80)
	free:Hide()
	local names = {}
	for i, call in ipairs(stub.blocked) do
		check(call[1] == guarded, 'blocked call ' .. i .. ' was on the protected frame')
		names[i] = call[2]
	end
	eq(table.concat(names, ','), 'ClearAllPoints,SetPoint,SetHeight,Hide', 'each blocked call noted, in order')
	eq(guarded:GetLeft() .. ',' .. guarded:GetHeight(), '10,40', 'the protected frame kept its place and size')
	check(guarded:IsShown(), 'and stayed shown')
	eq(free:GetHeight(), 80, 'a frame not protected changes in combat')
	check(not free:IsShown(), 'and hides')

	stub.in_combat = false
	guarded:SetHeight(80)
	eq(guarded:GetHeight(), 80, 'out of combat the protected frame changes')
	eq(#stub.blocked, 4, 'nothing more noted')
end)

test("SaftUI's code can't measure an anchor restricted region (a nameplate) or one anchored to it; a test and the stubs can", function()
	reset_world()
	local plate = CreateFrame('Frame', 'NamePlate1', WorldFrame)
	plate:SetSize(200, 20)
	plate:SetPoint('CENTER')
	stub.restrict_anchors(plate)
	-- A bar filling it, and a backdrop 2 round the bar: restricted through
	-- the bar.
	local bar = CreateFrame('StatusBar', nil, plate)
	bar:SetAllPoints(plate)
	local backdrop = CreateFrame('Frame', nil, bar)
	backdrop:SetPoint('TOPLEFT', bar, 'TOPLEFT', -2, 2)
	backdrop:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 2, -2)
	-- The plate's child, anchored elsewhere: not restricted.
	local elsewhere = CreateFrame('Frame', nil, plate)
	elsewhere:SetSize(10, 10)
	elsewhere:SetPoint('CENTER', UIParent, 'CENTER')

	-- SaftUI's code: a chunk named as load_saftui names a SaftUI file's. No
	-- tail call, so the call is seen made from it.
	local saftui = loadstring('local region, method = ... local a, b, c, d, e = region[method](region) return a, b, c, d, e',
		'@SaftUI-Core/measure.lua')
	local MEASURES = { 'GetPoint', 'GetRect', 'GetLeft', 'GetRight', 'GetTop', 'GetBottom', 'GetCenter', 'IsMouseOver' }
	for _, region in ipairs({ plate, bar, backdrop }) do
		for _, method in ipairs(MEASURES) do
			local ok, err = pcall(saftui, region, method)
			check(not ok and tostring(err):find("Can't measure restricted regions", 1, true) ~= nil,
				region:GetObjectType() .. ':' .. method .. ' refused: ' .. tostring(err))
		end
	end
	local _, err = pcall(saftui, backdrop, 'GetPoint')
	eq(err, "SaftUI-Core/measure.lua:1: Frame:GetPoint(): Action[FrameMeasurement] failed because[Can't measure restricted regions]: attempted from: Frame:GetPoint().",
		"the game's message, at the line that asked")

	-- What still answers, to SaftUI too: the number of points and the size.
	eq(saftui(backdrop, 'GetNumPoints'), 2, 'GetNumPoints answers')
	eq(saftui(backdrop, 'GetWidth'), 204, 'GetWidth answers')
	eq(table.concat({ saftui(backdrop, 'GetSize') }, ','), '204,24', 'GetSize answers')
	-- A test measures, as the player sees the screen.
	eq(select(4, backdrop:GetPoint(1)), -2, 'a test reads the anchors')
	eq(backdrop:GetLeft(), bar:GetLeft() - 2, 'and the edges')
	check(pcall(saftui, elsewhere, 'GetPoint'), "a child anchored elsewhere isn't restricted")

	-- Anchors can still be set; anchored elsewhere, a region is free again.
	backdrop:ClearAllPoints()
	backdrop:SetPoint('TOPLEFT', bar, 'TOPLEFT', -1, 1)
	backdrop:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 1, -1)
	eq(select(4, backdrop:GetPoint(1)), -1, 'SetPoint on a restricted region works')
	check(not pcall(saftui, backdrop, 'GetPoint'), 'and it is still restricted')
	backdrop:ClearAllPoints()
	backdrop:SetPoint('CENTER', UIParent, 'CENTER')
	check(pcall(saftui, backdrop, 'GetPoint'), 'anchored outside the family, it measures again')
end)

test('SetAttribute runs OnAttributeChanged on every call, an unchanged value too, and is blocked in combat on a protected frame', function()
	reset_world()
	local frame = CreateFrame('Frame', nil, UIParent)
	eq(frame:GetAttribute('unit'), nil, 'nil until set')
	local seen = {}
	frame:SetScript('OnAttributeChanged', function(_, name, value) seen[#seen + 1] = name .. '=' .. tostring(value) end)
	frame:SetAttribute('unit', 'party1')
	frame:SetAttribute('unit', 'party1')
	frame:SetAttribute('unit', nil)
	eq(table.concat(seen, ','), 'unit=party1,unit=party1,unit=nil', 'the handler ran for each call')
	eq(frame:GetAttribute('unit'), nil, 'cleared')

	function frame:IsProtected() return true, true end
	stub.in_combat = true
	frame:SetAttribute('unit', 'party2')
	stub.in_combat = false
	eq(frame:GetAttribute('unit'), nil, 'blocked in combat')
	eq(#seen, 3, 'and no handler ran')
	check(stub.blocked[1] and stub.blocked[1][2] == 'SetAttribute', 'the blocked call is noted')
end)

test('a secure template frame is protected: in combat it refuses moves, shows, hides and attributes into stub.blocked; alpha and its children are free', function()
	reset_world()
	local layer = CreateFrame('Frame', 'SecureLayer', UIParent, 'SecureHandlerStateTemplate')
	local button = CreateFrame('Button', 'SecureOne', layer, 'SecureActionButtonTemplate')
	local plain = CreateFrame('Frame', nil, UIParent)
	local cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	local child = CreateFrame('Frame', nil, button)
	local protected, explicit = button:IsProtected()
	check(protected and explicit, 'a secure action button is protected')
	check(layer:IsProtected(), 'so is a secure handler')
	check(not plain:IsProtected() and not cooldown:IsProtected() and not child:IsProtected(), 'a plain frame, a cooldown and a child of a secure frame are not')
	button:SetPoint('CENTER', UIParent, 'CENTER')
	button:SetAttribute('type', 'item')
	button:Show()
	eq(#stub.blocked, 0, 'out of combat nothing is refused')
	eq(button:GetAttribute('type'), 'item', 'the attribute is set')

	stub.in_combat = true
	local calls = {
		function() button:SetPoint('TOPLEFT', UIParent, 'TOPLEFT') end,
		function() button:ClearAllPoints() end,
		function() button:SetSize(30, 30) end,
		function() button:Hide() end,
		function() button:Show() end,
		function() button:SetAttribute('type', 'macro') end,
		function() button:SetFrameLevel(40) end,
		function() button:EnableMouse(false) end,
		function() button:RegisterForClicks('AnyUp') end,
		function() layer:SetAllPoints(UIParent) end,
		function() layer:Hide() end,
		function() layer:SetAttribute('state-visibility', 'hide') end,
	}
	for _, call in ipairs(calls) do call() end
	eq(#stub.blocked, #calls, 'each is noted as blocked')
	check(button:IsShown(), 'nothing hid it')
	eq(button:GetAttribute('type'), 'item', 'nor changed its attribute')
	local blocked = #stub.blocked
	button:SetAlpha(0.4)
	eq(button:GetAlpha(), 0.4, 'alpha is free')
	cooldown:SetCooldown(1, 2)
	child:Hide()
	child:SetPoint('CENTER', button, 'CENTER')
	plain:SetPoint('CENTER', UIParent, 'CENTER')
	eq(#stub.blocked, blocked, 'so are a cooldown, a child and a plain frame')
	stub.in_combat = false
end)

test('a secure action button\'s click, as SecureActionButton_OnClick treats an addon\'s button: by useOnKeyDown or the setting, once per click; only with a type; in combat too', function()
	reset_world()
	local button = CreateFrame('Button', nil, UIParent, 'SecureActionButtonTemplate')
	button:RegisterForClicks('AnyUp', 'AnyDown')
	button:Show()
	stub.click(button, 'LeftButton', true)
	stub.click(button, 'LeftButton', false)
	eq(#stub.secure_clicks, 0, 'no type: nothing')
	button:SetAttribute('type', 'item')
	button:SetAttribute('item', 'item:6948')
	stub.click(button, 'LeftButton', true)
	stub.click(button, 'LeftButton', false)
	eq(#stub.secure_clicks, 1, 'cast on key down (the default): the press acts, the release does not')
	check(stub.secure_clicks[1].down, 'on the press')
	eq(stub.secure_clicks[1].item, 'item:6948', 'with the attributes as they stand')
	stub.cast_on_key_down = false
	stub.click(button, 'LeftButton', true)
	stub.click(button, 'LeftButton', false)
	eq(#stub.secure_clicks, 2, 'with it off, the release acts')
	check(not stub.secure_clicks[2].down, 'on the release')
	button:SetAttribute('useOnKeyDown', true)
	stub.click(button, 'LeftButton', true)
	stub.click(button, 'LeftButton', false)
	eq(#stub.secure_clicks, 3, 'a useOnKeyDown attribute decides for itself')
	button:SetAttribute('useOnKeyDown', nil)
	stub.cast_on_key_down = true
	stub.press_key(button, true)
	stub.press_key(button, false)
	eq(#stub.secure_clicks, 4, 'a key press follows the same rule')
	check(stub.secure_clicks[4].key, 'and is told apart')
	stub.in_combat = true
	stub.click(button, 'LeftButton', true)
	eq(#stub.secure_clicks, 5, 'in combat a click still uses it')
	stub.in_combat = false
	button:RegisterForClicks('AnyUp')
	check(not pcall(stub.click, button, 'LeftButton', true), 'a button registered for AnyUp gets no press (stub.click errors)')
	check(stub.try_click(button, 'LeftButton', true) == false, 'try_click says so')
	button:Hide()
	check(not pcall(stub.click, button, 'LeftButton', false), 'a hidden button takes no click (stub.click errors)')
end)

test('a region of a secure frame is protected: its anchors and size are refused in combat, its texture, color and alpha are free', function()
	reset_world()
	local button = CreateFrame('Button', nil, UIParent, 'SecureActionButtonTemplate')
	local icon = button:CreateTexture(nil, 'ARTWORK')
	local text = button:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(GameFontNormal or CreateFont('SelfTestFont'))
	local child = CreateFrame('Frame', nil, button)
	local inner = child:CreateTexture(nil, 'ARTWORK')
	check(icon:IsProtected() and text:IsProtected(), 'a texture and a font string of it are protected')
	check(not child:IsProtected() and not inner:IsProtected(), 'a child frame and its textures are not')
	icon:SetPoint('CENTER', button, 'CENTER')
	eq(#stub.blocked, 0, 'out of combat nothing is refused')
	stub.in_combat = true
	icon:SetPoint('TOPLEFT', button, 'TOPLEFT')
	icon:ClearAllPoints()
	icon:SetAllPoints(button)
	icon:SetSize(4, 4)
	text:SetPoint('CENTER', button, 'CENTER')
	eq(#stub.blocked, 5, 'anchors and sizes of its regions are refused and noted')
	local blocked = #stub.blocked
	icon:SetTexture(1)
	icon:SetVertexColor(1, 0, 0)
	icon:SetAlpha(0.5)
	icon:Show()
	icon:Hide()
	text:SetText('x')
	text:SetTextColor(1, 1, 1)
	inner:SetPoint('CENTER', child, 'CENTER')
	inner:SetSize(2, 2)
	eq(#stub.blocked, blocked, 'its texture, color, text and alpha, and a child frame\'s regions, are free')
	stub.in_combat = false
end)

test('a cooldown keeps SetCooldown\'s start and duration, Clear drops them, and a bad argument errors', function()
	reset_world()
	local cooldown = CreateFrame('Cooldown', nil, UIParent, 'CooldownFrameTemplate')
	cooldown:SetCooldown(10, 5)
	eq(stub.state(cooldown).cooldown_start, 10, 'the start')
	eq(stub.state(cooldown).cooldown_duration, 5, 'the duration')
	cooldown:Clear()
	eq(stub.state(cooldown).cooldown_duration, nil, 'cleared')
	check(not pcall(cooldown.SetCooldown, cooldown, 'x', 5), 'a start that is not a number errors')
end)

test('reset_world rebuilds the stubs and the shell, and keeps the test file\'s locals', function()
	local before = SaftUI
	local keep = 'kept'
	SOME_GLOBAL = true
	CreateFrame('Frame', 'SaftUITestNamedFrame')
	reset_world()
	check(SaftUI ~= before, 'a fresh SaftUI')
	eq(SOME_GLOBAL, nil, 'globals made since the harness loaded are gone')
	eq(SaftUITestNamedFrame, nil, 'named frames are gone')
	eq(keep, 'kept', 'locals survive')
	check(type(CreateFrame) == 'function' and UIParent ~= nil, 'the stubs are back')
end)

test('a status bar, slider, scroll frame and check button have their own methods', function()
	reset_world()
	local bar = CreateFrame('StatusBar', nil, UIParent)
	check(not pcall(function() return CreateFrame('Frame'):SetStatusBarColor(1, 1, 1) end), 'SetStatusBarColor is a StatusBar method')
	bar:SetStatusBarTexture('fill')
	eq(bar:GetStatusBarTexture():GetTexture(), 'fill', 'the fill is a texture of the bar')
	eq(bar:GetStatusBarTexture():GetParent(), bar, 'a region of the bar')
	bar:SetStatusBarColor(0.1, 0.2, 0.3)
	local r, g, b, a = bar:GetStatusBarColor()
	check(r == 0.1 and g == 0.2 and b == 0.3 and a == 1, 'the color, alpha 1 by default')
	bar:SetMinMaxValues(0, 10)
	bar:SetValue(25)
	eq(bar:GetValue(), 10, 'a value is clamped to the maximum')

	local slider = CreateFrame('Slider', nil, UIParent)
	slider:SetThumbTexture('knob')
	local thumb = slider:GetThumbTexture()
	eq(thumb:GetTexture(), 'knob', 'the thumb is a texture')
	slider:SetThumbTexture('other')
	eq(slider:GetThumbTexture(), thumb, 'a later file re-textures the same thumb')
	eq(select('#', slider:GetRegions()), 1, 'and the slider has the one region')
	local changes = 0
	slider:SetScript('OnValueChanged', function() changes = changes + 1 end)
	slider:SetMinMaxValues(0, 5)
	slider:SetValue(3)
	slider:SetValue(3)
	eq(changes, 1, 'OnValueChanged runs when the value changes')

	local scroll = CreateFrame('ScrollFrame', nil, UIParent)
	local child = CreateFrame('Frame', nil, scroll)
	scroll:SetScrollChild(child)
	eq(scroll:GetScrollChild(), child, 'the scroll child')
	check(not pcall(scroll.SetScrollChild, scroll, 'child'), 'a scroll child must be a frame')

	-- The scroll child sits at the scroll frame's top left, moved up by the
	-- vertical scroll, at its own size; what is anchored to it moves with it.
	scroll:SetSize(100, 50)
	scroll:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -20)
	child:SetSize(80, 300)
	local row = CreateFrame('Frame', nil, child)
	row:SetSize(80, 20)
	row:SetPoint('TOPLEFT', child, 'TOPLEFT', 0, -40)
	local top = UIParent:GetTop() - 20
	check(child:GetLeft() == 10 and child:GetTop() == top, 'at the scroll frame\'s top left')
	check(child:GetWidth() == 80 and child:GetHeight() == 300, 'its own size')
	eq(row:GetTop(), top - 40, 'a region anchored to it')
	scroll:SetVerticalScroll(30)
	eq(child:GetTop(), top + 30, 'scrolled 30: 30 higher')
	eq(row:GetTop(), top - 10, 'and what is anchored to it too')
	child:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 500, -500)
	eq(child:GetLeft(), 10, "its own anchors don't place it")
	local other = CreateFrame('Frame', nil, scroll)
	other:SetSize(80, 10)
	scroll:SetScrollChild(other)
	eq(child:GetLeft(), 500, 'no longer the scroll child: its anchors place it again')
	eq(other:GetTop(), top + 30, 'the new one is placed instead')

	local check_button = CreateFrame('CheckButton', nil, UIParent)
	check_button:SetChecked(true)
	eq(check_button:GetChecked(), true, 'checked')
	eq(check_button:IsEnabled(), true, 'a check button is a button')
end)

test("a button's highlight texture takes the blend it's handed, and ADD with none", function()
	reset_world()
	local button = CreateFrame('Button', nil, UIParent)
	local hover = button:CreateTexture(nil, 'OVERLAY')
	hover:SetBlendMode('BLEND')
	button:SetHighlightTexture(hover)
	eq(button:GetHighlightTexture(), hover, 'the texture is the highlight')
	eq(hover:GetBlendMode(), 'ADD', "with no blend, ADD (most likely the client's default)")
	button:SetHighlightTexture(hover, 'BLEND')
	eq(hover:GetBlendMode(), 'BLEND', 'a blend handed with it is put on it')
	button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	eq(button:GetHighlightTexture():GetBlendMode(), 'ADD', 'a file: the texture made for it, ADD too')
	local pushed = button:CreateTexture(nil, 'OVERLAY')
	button:SetPushedTexture(pushed)
	eq(pushed:GetBlendMode(), 'BLEND', "the other states' setters take no blend and leave it")
end)

test("a texture's tex coords: 4 numbers or 8, read back as the 8 corners", function()
	reset_world()
	local texture = CreateFrame('Frame', nil, UIParent):CreateTexture(nil, 'ARTWORK')
	local function corners() return table.concat({ texture:GetTexCoord() }, ',') end
	eq(corners(), '0,0,0,1,1,0,1,1', 'the whole texture before any SetTexCoord')
	texture:SetTexCoord(0.1, 0.9, 0.2, 0.8)
	eq(corners(), '0.1,0.2,0.1,0.8,0.9,0.2,0.9,0.8', 'left, right, top, bottom as the corners UL, LL, UR, LR')
	texture:SetTexCoord(1, 2, 3, 4, 5, 6, 7, 8)
	eq(corners(), '1,2,3,4,5,6,7,8', 'eight numbers are the corners')
	check(not pcall(texture.SetTexCoord, texture, 0, 1, 0), 'three numbers are a usage error')
	check(not pcall(texture.SetTexCoord, texture, 0, 1, 0, 'x'), 'so is a coord that is not a number')
	check(not pcall(texture.SetTexCoord, texture), 'and none')
end)

test("a texture's masks, and a mask is no Texture", function()
	reset_world()
	local frame = CreateFrame('Frame', nil, UIParent)
	local texture = frame:CreateTexture(nil, 'ARTWORK')
	local mask = frame:CreateMaskTexture(nil, 'ARTWORK')
	mask:SetAtlas('a-mask')
	eq(mask:GetObjectType(), 'MaskTexture', "a mask texture's type")
	check(mask:IsObjectType('MaskTexture') and not mask:IsObjectType('Texture'), 'a mask is a MaskTexture, not a Texture')
	check(texture:IsObjectType('Texture'), 'a texture is a Texture')
	eq(mask.AddMaskTexture, nil, 'a mask takes no masks')
	eq(texture:GetNumMaskTextures(), 0, 'no masks to start with')
	texture:AddMaskTexture(mask)
	texture:AddMaskTexture(mask)
	eq(texture:GetNumMaskTextures(), 1, 'added once')
	eq(texture:GetMaskTexture(1), mask, 'by index')
	check(not pcall(texture.AddMaskTexture, texture, frame:CreateTexture()), 'only a mask texture is a mask')
	texture:RemoveMaskTexture(mask)
	eq(texture:GetNumMaskTextures(), 0, 'removed')
	local found = false
	for _, region in ipairs({ frame:GetRegions() }) do found = found or region == mask end
	check(found, "a mask is one of its frame's regions")
end)

test("a cooldown remembers its swipe, edge and numbers' font", function()
	reset_world()
	local cooldown = CreateFrame('Cooldown', nil, UIParent)
	eq(cooldown:GetObjectType(), 'Cooldown', 'a cooldown frame')
	cooldown:SetSwipeColor(0, 0, 0, 0.7)
	eq(table.concat(stub.state(cooldown).swipe_color, ','), '0,0,0,0.7', 'its swipe color')
	cooldown:SetSwipeTexture('Interface\\swipe')
	eq(stub.state(cooldown).swipe_texture, 'Interface\\swipe', 'its swipe texture')
	eq(table.concat(stub.state(cooldown).swipe_color, ','), '0,0,0,0.7', 'a new texture keeps the swipe color')
	cooldown:SetSwipeTexture(nil)
	eq(stub.state(cooldown).swipe_texture, nil, 'Forever takes no texture')
	stub.interface = 120000
	check(not pcall(cooldown.SetSwipeTexture, cooldown, nil), "retail's documentation doesn't")
	stub.interface = 16001
	local numbers = cooldown:GetCountdownFontString()
	check(numbers:IsObjectType('FontString') and numbers:GetParent() == cooldown, 'the numbers are a font string of the cooldown')
	eq(cooldown:GetCountdownFontString(), numbers, 'the same one each time')
	cooldown:SetCountdownFont('GameFontNormal')
	eq(numbers:GetFontObject(), GameFontNormal, 'SetCountdownFont sets their font by name')
	check(not pcall(cooldown.SetCountdownFont, cooldown, 'NoSuchFont'), 'a name that is no font errors')
	cooldown:SetHideCountdownNumbers(true)
	eq(cooldown:GetHideCountdownNumbers(), true, 'the numbers hidden')
end)

test('the mouse focus is the topmost mouse-enabled frame under the cursor', function()
	reset_world()
	stub.screen_width, stub.screen_height = 1000, 600
	UIParent:SetScale(768 / 600)
	local function box(parent, x)
		local f = CreateFrame('Frame', nil, parent)
		f:SetSize(100, 100)
		f:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x, 0)
		f:EnableMouse(true)
		return f
	end
	local a = box(UIParent, 0)
	stub.cursor_x, stub.cursor_y = 50 * UIParent:GetEffectiveScale(), 50 * UIParent:GetEffectiveScale()
	eq(a:IsMouseOver(), true, 'the cursor is inside')
	eq(a:IsMouseMotionFocus(), true, 'and the frame takes it')

	local b = box(UIParent, 0) -- made later, so drawn above a
	eq(a:IsMouseOver(), true, 'a is still under the cursor')
	eq(a:IsMouseMotionFocus(), false, 'but b has the focus')
	eq(b:IsMouseMotionFocus(), true, 'b has the focus')

	a:SetFrameStrata('DIALOG')
	eq(a:IsMouseMotionFocus(), true, 'a higher strata wins over a later frame')
	b:SetFrameStrata('DIALOG')
	b:SetFrameLevel(a:GetFrameLevel() + 5)
	eq(b:IsMouseMotionFocus(), true, 'at one strata, the higher level wins')
	b:EnableMouse(false)
	eq(a:IsMouseMotionFocus(), true, 'a frame that is not mouse-enabled takes nothing')
	b:Hide()
	eq(b:IsMouseOver(), false, 'a hidden frame is not under the cursor')

	stub.cursor_x = 500 * UIParent:GetEffectiveScale()
	eq(a:IsMouseOver(), false, 'outside the rectangle')
	check(not pcall(a.IsMouseOver, a, 5), 'the offsets are not stubbed, so they error rather than answer wrongly')
	eq(CreateFrame('Frame'):IsMouseOver(), false, 'a frame with no anchors is nowhere')
end)

test("PixelUtil follows Blizzard's, in the stubbed screen's pixels", function()
	reset_world()
	eq(PixelUtil.GetPixelToUIUnitFactor(), 768 / 1080, 'one pixel in UI units')
	local f = CreateFrame('Frame', nil, UIParent)
	PixelUtil.SetHeight(f, 1)
	eq(f:GetHeight(), 1, 'one pixel at SaftUI\'s scale is one unit')
	PixelUtil.SetWidth(f, 0)
	eq(f:GetWidth(), 0, 'zero stays zero')
	PixelUtil.SetWidth(f, 0, 2)
	check(f:GetWidth() > 0, 'a minimum pixel count raises it')
	eq(Round(2.5), 3, 'Round: half rounds up')
	eq(Round(-2.5), -3, 'Round: and away from zero below')
end)

test('IsAddOnLoaded answers from stub.loaded_addons', function()
	reset_world()
	eq(C_AddOns.IsAddOnLoaded('SomeAddon'), false, 'not loaded')
	stub.loaded_addons.SomeAddon = true
	eq(C_AddOns.IsAddOnLoaded('SomeAddon'), true, 'loaded once the test says so')
	check(not pcall(C_AddOns.IsAddOnLoaded), 'a name is required')
end)

test('DoesAddOnExist answers from stub.installed_addons and stub.loaded_addons', function()
	reset_world()
	eq(C_AddOns.DoesAddOnExist('SomeAddon'), false, 'not there')
	stub.installed_addons.SomeAddon = true
	eq(C_AddOns.DoesAddOnExist('SomeAddon'), true, 'there once the test says so')
	stub.loaded_addons.OtherAddon = true
	eq(C_AddOns.DoesAddOnExist('OtherAddon'), true, 'a loaded addon exists too')
	check(not pcall(C_AddOns.DoesAddOnExist), 'a name is required')
end)

test('SetDefaultModuleLibraries is AceAddon\'s: before any module, and the libraries the shell has', function()
	reset_world()
	local M = SaftUI:NewModule('Defaults')
	M:SetDefaultModuleLibraries('AceEvent-3.0', 'AceHook-3.0')
	local Sub = M:NewModule('Sub')
	check(type(Sub.RegisterEvent) == 'function' and type(Sub.SecureHook) == 'function', 'a submodule has both')
	local ok, err = pcall(M.SetDefaultModuleLibraries, M, 'AceEvent-3.0')
	eq(ok, false, 'it errors once a module exists')
	check(tostring(err):find('cannot change the module defaults', 1, true), 'AceAddon\'s message: ' .. tostring(err))
	check(not pcall(SaftUI:NewModule('Other').SetDefaultModuleLibraries, SaftUI:GetModule('Other'), 'AceTimer-3.0'), 'a library the shell lacks errors')
end)

test('an edit box, SetFormattedText, the Enums, GameFontNormal and debugprofilestop', function()
	reset_world()
	local box = CreateFrame('EditBox', nil, UIParent)
	eq(box:GetText(), '', 'an edit box starts empty')
	local changes = {}
	box:SetScript('OnTextChanged', function(_, user_input) changes[#changes + 1] = user_input end)
	box:SetText('abc'); box:SetText('abc')
	eq(#changes, 1, 'OnTextChanged runs only when the text changes')
	eq(changes[1], false, 'and says the user did not type it')
	eq(box:GetText(), 'abc')
	check(not pcall(box.SetText, box, {}), 'SetText wants a string')
	check(not pcall(function() return UIParent:NotAMethod() end), 'a frame is still strict')
	local plain = CreateFrame('Frame', nil, UIParent)
	check(not pcall(plain.HighlightText, plain), 'HighlightText on a plain frame errors, wrong object type')

	local fs = UIParent:CreateFontString(nil, 'OVERLAY')
	check(not pcall(fs.SetFormattedText, fs, '%d', 1), 'SetFormattedText needs a font, as SetText does')
	fs:SetFontObject(GameFontNormal)
	fs:SetFormattedText('%.0f', 25.4)
	eq(fs:GetText(), '25', 'SetFormattedText formats')
	check(not pcall(fs.SetFormattedText, fs, '%d', {}), 'and errors as string.format does')
	eq(select(2, GameFontNormal:GetFont()), 12, 'GameFontNormal is 12 high')

	eq(Enum.BagIndex.AccountBankTab_9, 23, 'Enum.BagIndex')
	eq(Enum.StatusBarInterpolation.ExponentialEaseOut, 1, 'Enum.StatusBarInterpolation')
	eq(Enum.PowerType.Mana, 0, 'Enum.PowerType')

	local t0 = debugprofilestop()
	check(type(t0) == 'number' and debugprofilestop() >= t0, 'debugprofilestop is a number that does not go back')
	reset_world()
	check(type(debugprofilestop) == 'function', 'and survives reset_world')
end)

test('where the player is: maps, PvP status, instances and zone names follow stub', function()
	reset_world()
	stub.maps[1415] = { name = 'Eastern Kingdoms', mapType = Enum.UIMapType.Continent }
	stub.maps[1429] = { name = 'Elwynn Forest', mapType = Enum.UIMapType.Zone, parentMapID = 1415,
		levels = { 1, 10 }, area = { 0.4, 0.7, 0.5, 0.8 } }
	eq(C_Map.GetBestMapForUnit('player'), nil, 'no map until the test gives one')
	stub.player_map = 1429
	eq(C_Map.GetBestMapForUnit('player'), 1429, 'the player map')
	local info = C_Map.GetMapInfo(1429)
	check(info.mapID == 1429 and info.name == 'Elwynn Forest' and info.mapType == 3 and info.parentMapID == 1415, 'GetMapInfo')
	check(C_Map.GetMapInfo(1429) ~= info, 'a new table each call')
	eq(C_Map.GetMapInfo(1415).parentMapID, 0, 'a map with no parent has 0')
	eq(C_Map.GetMapInfo(42), nil, 'an unknown map gives nothing')
	check(not pcall(C_Map.GetMapInfo, '1429'), 'a map ID must be a number')
	local min, max, petMin, petMax = C_Map.GetMapLevels(1429)
	check(min == 1 and max == 10 and petMin == 0 and petMax == 0, 'GetMapLevels')
	eq(select(2, C_Map.GetMapLevels(1415)), 0, 'a map without levels gives 0s')
	eq(C_Map.GetMapInfoAtPosition(1415, 0.45, 0.75).mapID, 1429, 'the child map under a position')
	eq(C_Map.GetMapInfoAtPosition(1415, 0.1, 0.1).mapID, 1415, 'else the map itself')
	check(not pcall(C_Map.GetMapInfoAtPosition, 1415), 'a position is required')

	local pvpType, subzone, faction = C_PvP.GetZonePVPInfo()
	check(pvpType == '' and subzone == false and faction == nil, "no PvP status by default: '', as the game gives")
	stub.pvp = { type = 'friendly', faction = 'Alliance' }
	pvpType, subzone, faction = C_PvP.GetZonePVPInfo()
	check(pvpType == 'friendly' and subzone == false and faction == 'Alliance', 'the PvP status')

	local inInstance, instanceType = IsInInstance()
	check(inInstance == false and instanceType == 'none', 'outside an instance')
	eq(select(5, GetInstanceInfo()), 0, 'no players outside one')
	stub.instance = { name = 'The Deadmines', type = 'party', difficulty_id = 1, difficulty_name = 'Normal', max_players = 5 }
	inInstance, instanceType = IsInInstance()
	check(inInstance == true and instanceType == 'party', 'in a dungeon')
	local name, _, difficultyID, difficultyName, maxPlayers = GetInstanceInfo()
	check(name == 'The Deadmines' and difficultyID == 1 and difficultyName == 'Normal' and maxPlayers == 5, 'GetInstanceInfo')
	eq(GetDifficultyInfo(1), 'Normal', 'its difficulty')
	eq(GetDifficultyInfo(2), nil, 'no other')

	stub.zone_text, stub.subzone_text = 'Elwynn Forest', 'Goldshire'
	check(GetZoneText() == 'Elwynn Forest' and GetSubZoneText() == 'Goldshire', 'zone names')
end)

test("FadingFrame keeps a frame's times in its own fields, as Blizzard's does", function()
	reset_world()
	local frame = CreateFrame('Frame', nil, UIParent)
	FadingFrame_OnLoad(frame)
	check(frame.fadeInTime == 0 and frame.holdTime == 0 and frame.fadeOutTime == 0, 'OnLoad zeroes the times')
	eq(frame:IsShown(), false, 'and hides it')
	FadingFrame_SetFadeInTime(frame, 1); FadingFrame_SetHoldTime(frame, 2); FadingFrame_SetFadeOutTime(frame, 3)
	check(frame.fadeInTime == 1 and frame.holdTime == 2 and frame.fadeOutTime == 3, 'the setters')
	stub.time = 7
	FadingFrame_Show(frame)
	check(frame:IsShown() and frame.startTime == 7, 'Show starts it now')
	eq(select(2, SubZoneTextFont:GetFont()), 26, "Blizzard's zone fonts are there")
	eq(Enum.UIMapType.Orphan, 6, 'Enum.UIMapType')
end)

test("LibStub is the real one: a library nobody registered errors, and a fixture's has only its methods", function()
	reset_world()
	load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
	load_test_file('core/fixtures/config_libs.lua')
	check(type(LibStub('AceSerializer-3.0')) == 'table', 'a registered library is found')
	check(not pcall(LibStub, 'AceGUI-3.0'), 'an unregistered one errors')
	eq(LibStub('LibCompress').Compress, nil, 'the fixture has no methods nothing calls')
end)

test("remove_shell_config takes the shell's Config module out, so the real config.lua can make it", function()
	reset_world()
	local shells = SaftUI.Config
	check(shells ~= nil and SaftUI:GetModule('Config', true) == shells, 'the shell makes Config')
	remove_shell_config()
	eq(SaftUI:GetModule('Config', true), nil, 'gone from the modules')
	eq(SaftUI.Config, nil, 'and from st.Config')
	for _, module in ipairs(SaftUI.orderedModules) do
		check(module ~= shells, 'and from the enable order')
	end
	local config = SaftUI:NewModule('Config')
	eq(SaftUI:GetModule('Config'), config, 'so NewModule can make it again')
	reset_world()
	check(SaftUI.Config ~= nil and SaftUI.Config ~= config, 'reset_world brings the shell\'s back')
end)

test("load_options_widgets and load_options_window load the files Core's Config/load.xml lists, in its order", function()
	local xml = assert(read_saftui_source('SaftUI-Core/Config/load.xml')):gsub('<!%-%-.-%-%->', '')
	local listed, from, to = {}, nil, nil
	local windowFrom, windowTo
	for file in xml:gmatch('<Script%s+file%s*=%s*"([^"]+)"') do
		listed[#listed + 1] = 'SaftUI-Core/Config/' .. file
		if file == 'optionsmodel.lua' then from = #listed + 1 end
		if file == 'optionsbody.lua' then to, windowFrom = #listed - 1, #listed + 1 end
		if file == 'generators.lua' then windowTo = #listed - 1 end
	end
	if check(from ~= nil and to ~= nil and from <= to, 'load.xml lists widget files between optionsmodel.lua and optionsbody.lua') then
		eq(table.concat(options_widget_files(), ', '), table.concat(listed, ', ', from, to),
			"the shell's widget files are load.xml's, in its order")
	end
	-- The window's files: after optionsbody.lua and before generators.lua.
	eq(table.concat(options_window_files(), ', '), table.concat(listed, ', ', windowFrom or 1, windowTo or #listed),
		"the shell's window files are load.xml's, in its order")
end)

test('Show, Hide and SetShown fire OnShow and OnHide only for a visibility that changes, as in game', function()
	local parent = CreateFrame('Frame')
	local child = CreateFrame('Frame', nil, parent)
	local fired = {}
	for name, frame in pairs({ parent = parent, child = child }) do
		frame:SetScript('OnShow', function() fired[#fired + 1] = name .. ' shown' end)
		frame:SetScript('OnHide', function() fired[#fired + 1] = name .. ' hidden' end)
	end
	local function took(action)
		fired = {}
		action()
		table.sort(fired)
		return table.concat(fired, ',')
	end

	eq(took(function() parent:Show() end), '', 'Show on a shown frame fires nothing, nor under it')
	eq(took(function() parent:SetShown(true) end), '', 'SetShown(true) on a shown frame fires nothing')
	eq(took(function() parent:SetShown(1) end), '', 'SetShown(1) is shown too')
	eq(took(function() parent:Hide() end), 'child hidden,parent hidden', 'Hide on a shown frame fires OnHide on it and what it hides')
	eq(took(function() parent:Hide() end), '', 'Hide on a hidden frame fires nothing')
	eq(took(function() parent:SetShown(false) end), '', 'SetShown(false) on a hidden frame fires nothing')
	eq(took(function() parent:SetShown(nil) end), '', 'SetShown(nil) is hidden too')
	eq(took(function() child:Hide() end), '', 'a child hidden under a hidden parent was not visible, so it fires nothing')
	eq(took(function() parent:Show() end), 'parent shown', 'Show shows the parent and not the child that was hidden itself')
	eq(took(function() child:Show() end), 'child shown', 'and showing the child fires its OnShow')
	check(parent:IsShown() and child:IsShown() and child:IsVisible(), 'both end up shown')
end)

test('SetAlpha keeps an alpha within 0 to 1 on a frame and on a region, as in game, and still wants a number', function()
	local frame = CreateFrame('Frame')
	local texture = frame:CreateTexture()
	for name, widget in pairs({ frame = frame, texture = texture }) do
		widget:SetAlpha(-0.5)
		eq(widget:GetAlpha(), 0, name .. ': below 0 is 0')
		widget:SetAlpha(1.5)
		eq(widget:GetAlpha(), 1, name .. ': above 1 is 1')
		widget:SetAlpha(0.25)
		eq(widget:GetAlpha(), 0.25, name .. ': in range stays')
		widget:SetAlpha(0)
		eq(widget:GetAlpha(), 0, name .. ': 0 stays')
		widget:SetAlpha(1)
		eq(widget:GetAlpha(), 1, name .. ': 1 stays')
		check(not pcall(widget.SetAlpha, widget, 'x'), name .. ': a non-number is still an error')
	end
	frame:SetAlpha(2)
	eq(frame:GetEffectiveAlpha(), 1, 'and the effective alpha is within 0 to 1 too')
	texture:SetAlpha(-3)
	eq(texture:GetEffectiveAlpha(), 0, 'as a region under it')
end)

test('SetPoint still refuses an anchor that makes a loop, through any chain, as in game', function()
	local a, b, c = CreateFrame('Frame'), CreateFrame('Frame'), CreateFrame('Frame')
	local parent = CreateFrame('Frame')
	local child = CreateFrame('Frame', nil, parent)

	local ok, err = pcall(a.SetPoint, a, 'CENTER', a)
	eq(ok, false, 'a region anchored to itself')
	check(tostring(err):find('Cannot anchor to itself', 1, true), tostring(err))

	b:SetPoint('CENTER', a) -- b depends on a
	ok, err = pcall(a.SetPoint, a, 'CENTER', b)
	eq(ok, false, 'a anchored to b, which depends on a')
	check(tostring(err):find('dependent on it', 1, true), tostring(err))

	c:SetPoint('CENTER', b)
	ok, err = pcall(a.SetPoint, a, 'TOPLEFT', c)
	eq(ok, false, 'through two links')
	ok = pcall(c.SetPoint, c, 'TOPLEFT', a)
	eq(ok, true, 'an anchor that makes no loop is fine')

	-- a parent anchored to its own child can't have the child anchored back to it
	parent:SetPoint('CENTER', child)
	ok, err = pcall(child.SetPoint, child, 'CENTER', parent)
	eq(ok, false, "a child anchored to its parent, which is anchored to the child")
	check(tostring(err):find('dependent on it', 1, true), tostring(err))
	ok, err = pcall(child.SetAllPoints, child, parent)
	eq(ok, false, 'SetAllPoints too')
end)

test('SetPoint finds a loop through an anchor that was cleared, and refuses nothing it should allow', function()
	local x, y = CreateFrame('Frame'), CreateFrame('Frame')
	y:SetPoint('CENTER', x) -- y depends on x
	x:ClearAllPoints()
	-- x has had a region anchored to it, even though nothing is now: x anchored
	-- to y is still a loop for as long as y is anchored to x
	local ok, err = pcall(x.SetPoint, x, 'CENTER', y)
	eq(ok, false, 'a loop through y, still anchored to x')
	check(tostring(err):find('dependent on it', 1, true), tostring(err))

	-- and once y lets go of x, the same anchor is fine
	y:ClearAllPoints()
	ok = pcall(x.SetPoint, x, 'CENTER', y)
	eq(ok, true, 'no loop once y is not anchored to x')
end)

test("use_client gives a fresh world on each client, without the globals that client lacks", function()
	local st = use_client('retail')
	check(not st.forever, 'retail: st.forever off')
	eq(select(4, GetBuildInfo()), 120000, "retail: the game's interface")
	eq(UnitHasEffectivelyTankAura, nil, "retail: Forever's tank aura check is gone")
	st.marked = true

	st = use_client('forever')
	check(st.forever, 'forever: st.forever on')
	eq(select(4, GetBuildInfo()), 16001, "forever: the game's interface")
	eq(type(UnitHasEffectivelyTankAura), 'function', 'forever: it has the tank aura check')
	eq(st.marked, nil, 'a fresh world: SaftUI is made again')

	st = use_client('retail', function() GetRealmName = function() return 'Elsewhere' end end)
	eq(st.my_realm, 'Elsewhere', 'before runs on the fresh stubs, before constants.lua reads them')

	check(not pcall(use_client, 'classic'), 'a client that is neither is an error')
	reset_world()
end)

test("the quest stubs: the two Forever-only C_QuestLog members exist only on Forever, and a questID that isn't a number errors with its Usage", function()
	use_client('retail')
	eq(C_QuestLog.IsEliteQuest, nil, 'retail: no IsEliteQuest')
	eq(C_QuestLog.GetQuestTimers, nil, 'retail: no GetQuestTimers')
	eq(type(C_QuestLog.GetTimeAllowed), 'function', 'retail: the shared ones stay')
	use_client('forever')
	eq(type(C_QuestLog.IsEliteQuest), 'function', 'forever: IsEliteQuest')
	eq(type(C_QuestLog.GetQuestTimers), 'function', 'forever: GetQuestTimers')
	stub.quests.log = { { id = 7, title = 'A', elite = true, timer = 90 } }
	eq(C_QuestLog.IsEliteQuest(7), true, 'an elite quest')
	eq(C_QuestLog.GetQuestTimers()[1].questTimer, 90, 'its timer')
	for _, call in ipairs({
		function() C_QuestLog.GetLogIndexForQuestID('7') end,
		function() C_QuestLog.IsEliteQuest(nil) end,
		function() C_QuestLog.GetInfo({}) end,
	}) do
		local ok, err = pcall(call)
		eq(ok, false, 'a questID that is not a number errors')
		check(tostring(err):find('Usage: ', 1, true), 'with its Usage line: ' .. tostring(err))
	end
	-- Every function that takes a questID refuses a string, with its Usage.
	for _, name in ipairs({ 'GetQuestObjectives', 'IsComplete', 'IsFailed', 'ReadyForTurnIn', 'GetTimeAllowed', 'GetQuestTagInfo',
		'IsQuestDisabledForSession', 'IsQuestCalling', 'GetDistanceSqToQuest', 'GetNextWaypointText', 'GetTitleForQuestID',
		'IsPushableQuest', 'AddQuestWatch', 'RemoveQuestWatch', 'IsWorldQuest', 'IsQuestBounty', 'IsQuestTask',
		'GetHeaderIndexForQuest', 'GetQuestIDForQuestWatchIndex', 'IsEliteQuest' }) do
		local ok, err = pcall(function() C_QuestLog[name]('7') end)
		eq(ok, false, name .. ' refuses a string')
		check(tostring(err):find('Usage: ', 1, true), name .. ' has its Usage line: ' .. tostring(err))
		check(tostring(err):find('harness_self_test', 1, true), name .. "'s error points at its caller: " .. tostring(err))
	end

	-- The watch list: the limit, and its event.
	stub.quests.log = {}
	for i = 1, 30 do stub.quests.log[i] = { id = i, title = 'Q' .. i } end
	stub.quests.watched = {}
	local events = {}
	local frame = CreateFrame('Frame')
	frame:RegisterEvent('QUEST_WATCH_LIST_CHANGED')
	frame:RegisterEvent('SUPER_TRACKING_CHANGED')
	frame:SetScript('OnEvent', function(_, event, ...) events[#events + 1] = event .. ':' .. table.concat({ tostring((...)) }, ',') end)
	for i = 1, 25 do eq(C_QuestLog.AddQuestWatch(i), true, 'watch ' .. i) end
	eq(C_QuestLog.AddQuestWatch(26), false, 'the 26th is refused: the list holds 25')
	eq(#stub.quests.watched, 25, 'the list is 25 long')
	eq(#events, 25, 'one QUEST_WATCH_LIST_CHANGED per change, none for the refusal')
	eq(C_QuestLog.RemoveQuestWatch(3), true, 'a removal')
	eq(#events, 26, 'fires the event too')
	eq(C_QuestLog.RemoveQuestWatch(3), false, 'a quest not on the list')
	eq(#events, 26, 'and fires none')
	C_SuperTrack.SetSuperTrackedQuestID(4)
	eq(events[#events], 'SUPER_TRACKING_CHANGED:nil', 'focusing fires SUPER_TRACKING_CHANGED')
	eq(C_QuestLog.GetMaxNumQuestsCanAccept(), 40, 'Forever: the log holds 40')
	use_client('retail')
	eq(C_QuestLog.GetMaxNumQuestsCanAccept(), 35, 'retail: 35')
	eq(Constants.QuestLogConstsMainlineCamelot, nil, 'retail has no Camelot constants')
	reset_world()
end)

test("load_editmode loads the files Core's EditMode/load.xml lists, in its order; the bar's come last, through Bar/load.xml", function()
	local function scripts(path, dir)
		local xml = assert(read_saftui_source(path)):gsub('<!%-%-.-%-%->', '')
		local listed = {}
		for file in xml:gmatch('<Script%s+file%s*=%s*"([^"]+)"') do
			listed[#listed + 1] = dir .. file
		end
		return listed, xml
	end
	local listed, xml = scripts('SaftUI-Core/EditMode/load.xml', 'SaftUI-Core/EditMode/')
	eq(table.concat(editmode_files(), ', '), table.concat(listed, ', '), "the shell's edit mode files are load.xml's, in its order")
	local bar = scripts('SaftUI-Core/EditMode/Bar/load.xml', 'SaftUI-Core/EditMode/Bar/')
	eq(table.concat(editmode_bar_files(), ', '), table.concat(bar, ', '), "the shell's bar files are Bar/load.xml's, in its order")
	local includes = {}
	for file in xml:gmatch('<Include%s+file%s*=%s*"([^"]+)"') do includes[#includes + 1] = file end
	eq(table.concat(includes, ', '), 'Bar\\load.xml', 'EditMode/load.xml includes the bar')
	check(xml:find('Bar\\load.xml', 1, true) > xml:find('settings.lua', 1, true), 'the bar comes after every other file')
end)

test('near tells float drift from a different number, and nil from any number', function()
	check(near(0.1 + 0.2, 0.3), 'float drift is near')
	check(not near(1, 1.001), 'a different number is not')
	check(not near(nil, 1) and not near(1, nil), 'nil is near nothing')
end)

test("stub.click runs a button's OnClick as the game would; where the game would not, it errors and stub.try_click returns false", function()
	reset_world()
	local button = CreateFrame('Button', nil, UIParent)
	check(stub.click(button, 'LeftButton') == false, 'a button without an OnClick runs nothing')
	local got
	button:SetScript('OnClick', function(self, mouse) got = { self, mouse } end)
	local function refused(fn, ...)
		local ok, err = pcall(fn, ...)
		return not ok and tostring(err):find('would not deliver', 1, true) ~= nil
	end
	check(refused(stub.click, button, 'RightButton'), 'a mouse button the button did not register for errors')
	check(stub.try_click(button, 'RightButton') == false, 'and try_click says false')
	check(stub.click(button) == true, 'the left button is registered until the button says otherwise')
	button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	check(stub.click(button, 'RightButton') == true, 'a button with an OnClick runs it')
	check(got and got[1] == button and got[2] == 'RightButton', 'OnClick gets the button and the mouse button')
	button:RegisterForClicks('AnyDown')
	check(refused(stub.click, button, 'RightButton'), 'a press registration gets no release')
	check(stub.click(button, 'RightButton', true) == true, 'a press registration clicks on the press')
	button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	button:Disable()
	check(refused(stub.click, button), 'a disabled button takes no click')
	eq(stub.try_click(button), false, 'try_click: false')
	button:Enable()
	button:Hide()
	check(refused(stub.click, button), 'nor a hidden one')
	button:Show()
	local parent = CreateFrame('Frame', nil, UIParent)
	local child = CreateFrame('Button', nil, parent)
	child:SetScript('OnClick', function() end)
	parent:Hide()
	check(refused(stub.click, child), 'nor one under a hidden frame')
	eq(stub.try_click(child), false, 'try_click: false')
	check(stub.click_unchecked(child) == true, 'click_unchecked plays no rules')
end)

