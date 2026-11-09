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

test("the real st:CreateButton's SetText alias errors, as in game", function()
	-- SaftUI-Core/Widgets/button.lua sets button.SetText = button.text.SetText,
	-- so button:SetText passes the button as the FontString. That's the bug
	-- behind the 2026-11-09 footer error. load_core_helpers loads button.lua
	-- through load_saftui, with the real panels.lua and fonts it needs.
	load_core_helpers()
	local button = SaftUI:CreateButton(nil, UIParent, 'x')
	eq(button.text:GetText(), 'x', 'the button was built, with its label')

	local ok, err = pcall(function() button:SetText('y') end)
	eq(ok, false, 'button:SetText errors')
	check(tostring(err):find('Wrong object type', 1, true), "WoW's wrong-object error: " .. tostring(err))

	button.text:SetText('y')
	eq(button.text:GetText(), 'y', 'setting the label through button.text works')
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

	local check_button = CreateFrame('CheckButton', nil, UIParent)
	check_button:SetChecked(true)
	eq(check_button:GetChecked(), true, 'checked')
	eq(check_button:IsEnabled(), true, 'a check button is a button')
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
