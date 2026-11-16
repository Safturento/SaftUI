-- The totem bar's timers in the state colors: the text and bar of a totem with
-- ten seconds or less left are Text > Danger, and otherwise the text is Text >
-- Normal (SaftUI-Misc/totemtimers.lua), at values that are not the defaults, so a
-- red of its own fails. The button's flash is Buttons > Danger
-- (totemskin.lua's StyleButton), under SaftUI's flat look.
--
-- Real: totembar.lua, totemtimers.lua and totemskin.lua. Their file-local
-- ColorTimer and StyleButton are taken from the upvalues of the module's methods.

load_core_helpers()
local st = SaftUI
local T = load_test_file('lib/theme_helpers.lua')
for _, file in ipairs({ 'totembar', 'totemtimers', 'totemskin' }) do
	load_saftui('SaftUI-Misc/' .. file .. '.lua')
end
local TB = st:GetModule('TotemBar')

-- The first upvalue called name in fn or in the functions it holds.
local function find_upvalue(fn, name, seen)
	seen = seen or {}
	if seen[fn] then return nil end
	seen[fn] = true
	for i = 1, 60 do
		local n, v = debug.getupvalue(fn, i)
		if not n then return nil end
		if n == name then return v end
		if type(v) == 'function' then
			local found = find_upvalue(v, name, seen)
			if found then return found end
		end
	end
end

local DANGER, NORMAL, BUTTON = { 0.9, 0.2, 0.3 }, { 0.1, 0.5, 0.7 }, { 0.1, 0.8, 0.3 }
st.config.profile.colors.text.danger:SetRGB(unpack(DANGER))
st.config.profile.colors.text.normal:SetRGB(unpack(NORMAL))
st.config.profile.colors.button.danger:SetRGB(unpack(BUTTON))

local function fontstring()
	local fs = CreateFrame('Frame', nil, UIParent):CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(GameFontNormal)
	return fs
end

test('a timer in its last seconds is Text > Danger (text and bar), and otherwise its text is Text > Normal', function()
	local ColorTimer = find_upvalue(TB.UpdateTimers, 'ColorTimer')
	check(ColorTimer, 'the timer coloring')
	TB.GetElementColor = function() return nil end
	local timer = { text = fontstring(), bar = CreateFrame('StatusBar', nil, UIParent), slot = 1 }
	ColorTimer(timer, true)
	eq(T.rgb(timer.text:GetTextColor()), T.rgb(unpack(DANGER)), 'the text in Danger')
	eq(T.rgb(timer.bar:GetStatusBarColor()), T.rgb(unpack(DANGER)), 'the bar in Danger')
	ColorTimer(timer, false)
	eq(T.rgb(timer.text:GetTextColor()), T.rgb(unpack(NORMAL)), 'the text in Text > Normal otherwise')
	eq(T.rgb(timer.bar:GetStatusBarColor()), T.rgb(unpack(NORMAL)), 'and a slot with no element color takes it for its bar')
end)

test("a totem button's flash is Buttons > Danger at 40%, at an odd value", function()
	local StyleButton = find_upvalue(TB.SetupSkin, 'StyleButton')
	check(StyleButton, 'the button styling')
	if not StyleButton then return end
	TB.config = TB.config or {}
	TB.config.button_size = 36
	local button = CreateFrame('Button', nil, UIParent)
	button.icon = button:CreateTexture(nil, 'BACKGROUND')
	button.Flash = button:CreateTexture(nil, 'ARTWORK')
	local skin = { hover = button:CreateTexture(), pushed = button:CreateTexture() }
	local ok, err = pcall(StyleButton, button, skin, 'thick', 'solid')
	check(ok, tostring(err))
	local c = stub.state(button.Flash).color_texture
	check(c, 'the flash is a flat color under Thick')
	if c then eq(T.rgb(c[1], c[2], c[3]) .. ' ' .. string.format('%.2f', c[4]), T.rgb(unpack(BUTTON)) .. ' 0.40', 'Buttons > Danger at 40%') end
end)

test("a totem button's flash is Buttons > Danger at 40% times its opacity: 0.4 at 100%, 0.2 at 50%", function()
	local StyleButton = find_upvalue(TB.SetupSkin, 'StyleButton')
	check(StyleButton, 'the button styling')
	if not StyleButton then return end
	TB.config = TB.config or {}
	TB.config.button_size = 36
	for _, a in ipairs({ 1, 0.5 }) do
		st.config.profile.colors.button.danger.a = a
		local button = CreateFrame('Button', nil, UIParent)
		button.icon = button:CreateTexture(nil, 'BACKGROUND')
		button.Flash = button:CreateTexture(nil, 'ARTWORK')
		local skin = { hover = button:CreateTexture(), pushed = button:CreateTexture() }
		local ok, err = pcall(StyleButton, button, skin, 'thick', 'solid')
		check(ok, tostring(err))
		local c = stub.state(button.Flash).color_texture or { -1, -1, -1, -1 }
		eq(T.rgb(c[1], c[2], c[3]) .. ' ' .. string.format('%.2f', c[4]), T.rgb(unpack(BUTTON)) .. ' ' .. string.format('%.2f', 0.4 * a), 'at ' .. a * 100 .. '%')
	end
	st.config.profile.colors.button.danger.a = 1
end)

-- The retail curve: C_CurveUtil.CreateColorCurve and Enum.LuaCurveType, as the
-- game documents them (Gethe/wow-ui-source, live,
-- Blizzard_APIDocumentationGenerated: CurveUtilDocumentation.lua,
-- LuaColorCurveObjectAPIDocumentation.lua, LuaCurveObjectBaseAPIDocumentation.lua,
-- LuaCurveObjectConstantsDocumentation.lua): CreateColorCurve gives a curve with
-- no points; AddPoint(x, y) takes a number and a color (ColorMixin); SetType
-- takes a LuaCurveType; GetPoints gives { x, y } structures. No kinder than the
-- game: a wrong argument raises. Secret values are not modelled (the curve here
-- never holds one).
local function color_like(y)
	return type(y) == 'table' and type(y.r) == 'number' and type(y.g) == 'number' and type(y.b) == 'number'
end
Enum.LuaCurveType = { Linear = 0, Step = 1, Cosine = 2, Cubic = 3 }
local function CreateColorCurve()
	local curve = { type = Enum.LuaCurveType.Linear, points = {} }
	function curve:SetType(kind)
		if type(kind) ~= 'number' or kind < 0 or kind > 3 then error('LuaColorCurveObject:SetType(): bad curve type', 2) end
		self.type = kind
	end
	function curve:AddPoint(x, y)
		if type(x) ~= 'number' then error('LuaColorCurveObject:AddPoint(): x must be a number', 2) end
		if not color_like(y) then error('LuaColorCurveObject:AddPoint(): y must be a color', 2) end
		self.points[#self.points + 1] = { x = x, y = y }
	end
	function curve:GetPoints() return self.points end
	function curve:GetPointCount() return #self.points end
	return curve
end

test("retail: the warning curve starts in Text > Danger and goes on in the timer's own color, as the game's curve takes them", function()
	_G.C_CurveUtil = { CreateColorCurve = CreateColorCurve }
	local WarningCurve = find_upvalue(TB.UpdateTimers, 'WarningCurve')
	check(WarningCurve, 'the curve builder')
	if not WarningCurve then return end
	local curve = WarningCurve(0.1, 0.5, 0.7)
	eq(curve.type, Enum.LuaCurveType.Step, 'a step curve')
	local points = curve:GetPoints()
	eq(#points, 2, 'two points')
	eq(points[1].x, 0, 'Danger from the start')
	eq(T.rgb(points[1].y.r, points[1].y.g, points[1].y.b), T.rgb(unpack(DANGER)), 'in Text > Danger, at an odd value')
	eq(T.rgb(points[2].y.r, points[2].y.g, points[2].y.b), T.rgb(0.1, 0.5, 0.7), 'then the color it was given')
	check(points[2].x > 10, 'just above the warning seconds')
end)

test("retail: the text's curve goes on in Text > Normal, at an odd value", function()
	_G.C_CurveUtil = { CreateColorCurve = CreateColorCurve }
	local TextCurve = find_upvalue(TB.UpdateTimers, 'TextCurve')
	check(TextCurve, 'the text curve')
	if not TextCurve then return end
	local points = TextCurve():GetPoints()
	eq(T.rgb(points[1].y.r, points[1].y.g, points[1].y.b), T.rgb(unpack(DANGER)), 'Danger first')
	eq(T.rgb(points[2].y.r, points[2].y.g, points[2].y.b), T.rgb(unpack(NORMAL)), 'then Text > Normal')
end)

------------------------------------------------------------------ live colors
-- A pick on the Colors tab reaches the bar at once (TB:OnColorsChanged): Buttons
-- > Danger the buttons' flash, Text > Normal the
-- flyout's arrows, Text > Normal and Danger the timers (TB:ColorTimers). Only
-- colors: nothing is laid out, nothing shown or hidden, in combat too.
local C = load_test_file('lib/color_cost.lua')
local locked = load_test_file('lib/locked_widget.lua')

local function live_world()
	local st = T.client('forever')
	load_editmode()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	for _, file in ipairs({ 'totembar', 'totemlayout', 'totemposition', 'totemoptions', 'totemskin', 'totemtimers' }) do
		load_saftui('SaftUI-Misc/' .. file .. '.lua')
	end
	GetTotemDuration = function() end
	FIRE_TOTEM_SLOT, EARTH_TOTEM_SLOT, WATER_TOTEM_SLOT, AIR_TOTEM_SLOT = 1, 2, 3, 4
	local slots = {}
	for i = 1, 4 do
		local button = CreateFrame('Button', 'MultiCastSlotButton' .. i, UIParent)
		button:SetID(i)
		button:SetSize(30, 30)
		button:SetPoint('CENTER')
		button.background = button:CreateTexture(nil, 'BACKGROUND')
		button.overlayTex = button:CreateTexture(nil, 'OVERLAY')
		slots[i] = locked(button, 'Blizzard totem slot')
	end
	local function totem_button(name, container)
		local button = CreateFrame('CheckButton', name, UIParent)
		button:SetSize(30, 30)
		button:SetPoint('CENTER')
		button.icon = button:CreateTexture(nil, 'BACKGROUND')
		button.Flash = button:CreateTexture(nil, 'ARTWORK', nil, 1)
		local parent = button
		if container then
			button.TextOverlayContainer = CreateFrame('Frame', nil, button)
			parent = button.TextOverlayContainer
		end
		button.Count = parent:CreateFontString(nil, 'ARTWORK')
		button.HotKey = parent:CreateFontString(nil, 'OVERLAY')
		button.Name = button:CreateFontString(nil, 'OVERLAY')
		return locked(button, 'Blizzard totem button')
	end
	local buttons = { totem_button('MultiCastSummonSpellButton') }
	for i = 1, 12 do buttons[#buttons + 1] = totem_button('MultiCastActionButton' .. i, true) end
	local flyout = CreateFrame('Frame', 'MultiCastFlyoutFrame', UIParent)
	flyout.top = flyout:CreateTexture(nil, 'ARTWORK')
	flyout.middle = flyout:CreateTexture(nil, 'ARTWORK')
	locked(flyout, 'Blizzard totem flyout')
	for _, name in ipairs({ 'MultiCastFlyoutFrameOpenButton', 'MultiCastFlyoutFrameCloseButton' }) do
		local arrow = CreateFrame('Button', name, flyout)
		arrow:SetSize(30, 16)
		arrow:SetNormalTexture(arrow:CreateTexture(nil, 'ARTWORK'))
		arrow:SetHighlightTexture(arrow:CreateTexture(nil, 'HIGHLIGHT'))
		locked(arrow, 'Blizzard totem arrow')
	end
	local TB = st:GetModule('TotemBar')
	st:BindModuleConfig(TB, 'totembar')
	TB:SetupSkin()
	TB:SetupTimers()
	return st, TB, buttons
end

local function flash(b)
	local c = stub.state(b.Flash).color_texture
	return c and T.rgb(c[1], c[2], c[3]) .. ' ' .. string.format('%.2f', c[4]) or 'none'
end

local function alone(st, TB, fn)
	local modules = st.modules
	st.modules = { TotemBar = TB }
	local ok, err = pcall(fn)
	st.modules = modules
	if not ok then error(err, 0) end
end

test('Buttons > Danger: the flash of every button under the flat look; the Accent: the derived hover', function()
	local st, TB, buttons = live_world()
	local profile = st.config.profile
	profile.colors.button.danger:SetRGB(unpack(DANGER))
	profile.theme.accent:SetRGB(0.3, 0.9, 0.6)
	local m
	alone(st, TB, function() m = C.measure(function() st:ColorChanged('button', 'danger') end) end)
	eq(m.calls.by.SetColorTexture, #buttons, 'one flash a button')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	for _, b in ipairs({ buttons[1], buttons[7], buttons[13] }) do
		eq(flash(b), T.rgb(unpack(DANGER)) .. ' 0.40', 'Danger at 0.4')
	end
	-- The Accent reaches the buttons' states through the state helper (its own pass, not TB:OnColorsChanged):
	-- tests/misc/totem_interaction_states_test.lua.
	alone(st, TB, function() m = C.measure(function() st:ColorChanged('accent') end) end)
	eq(m.forbidden.total, 0, 'nothing forbidden')
	local hover = stub.state(buttons[1]:GetHighlightTexture()).vertex_color
	eq(T.rgb(hover[1], hover[2], hover[3]), T.rgb(st:StateColor('hover')), 'the hover is the derived hover, not the Accent itself')

	-- Under Blizzard the flash and the hover are Blizzard's art: nothing is colored.
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	TB:ApplySkin()
	alone(st, TB, function() m = C.measure(function() st:ColorChanged('button', 'danger'); st:ColorChanged('accent') end) end)
	eq(m.calls.by.SetColorTexture, nil, 'Blizzard: no flash tint')
	eq(m.calls.by.SetVertexColor, nil, 'Blizzard: no hover tint')
	eq(#take_errors(), 0, 'no errors')
end)

test('Text > Normal: the flyout arrows; Text > Danger: not the arrows', function()
	local st, TB = live_world()
	st.config.profile.colors.text.normal:SetRGB(unpack(NORMAL))
	local m
	alone(st, TB, function() m = C.measure(function() st:ColorChanged('text', 'danger') end) end)
	eq(m.calls.by.SetVertexColor, nil, 'Danger reaches no arrow')
	alone(st, TB, function() m = C.measure(function() st:ColorChanged('text', 'normal') end) end)
	eq(m.calls.by.SetVertexColor, 4, 'both arrows, art and hover')
	eq(m.forbidden.total, 0)
	local arrow = stub.state(MultiCastFlyoutFrameOpenButton:GetHighlightTexture()).vertex_color
	eq(T.rgb(arrow[1], arrow[2], arrow[3]), T.rgb(unpack(NORMAL)), 'the summon button\'s arrows are in Text > Normal')
end)

-- The timers' state as the bar keeps it: the file's own table of timers.
local function timers_of(TB) return find_upvalue(TB.UpdateTimers, 'timers') end

test("Text > Danger and Normal: each shown plain timer is colored at once, nothing laid out", function()
	local st, TB = live_world()
	local profile = st.config.profile
	TB.GetElementColor = function() return nil end
	local list = {}
	for _, timer in pairs(timers_of(TB)) do list[#list + 1] = timer end
	check(#list == 4, 'four timers')
	-- 1: a plain timer in its last seconds, 2: a plain one with time left, 3: a
	-- hidden one.
	list[1].secret, list[1].warning, list[1].slot = false, true, 1
	list[2].secret, list[2].warning, list[2].slot = false, false, 2
	list[1].frame:Show(); list[2].frame:Show(); list[3].frame:Hide()
	list[3].secret, list[3].warning, list[3].slot = false, true, 3
	list[3].text:SetTextColor(1, 1, 1)
	profile.colors.text.danger:SetRGB(0.2, 0.2, 0.9)
	profile.colors.text.normal:SetRGB(0.9, 0.9, 0.1)
	local before = {}
	for _, t in ipairs(list) do before[#before + 1] = t.frame:GetHeight() .. ',' .. tostring(select(2, t.frame:GetPoint(1))) end
	local m
	alone(st, TB, function() m = C.measure(function() st:ColorChanged('text', 'danger') end) end)
	eq(m.forbidden.total, 0, 'nothing laid out or shown')
	eq(m.made, 0, 'nothing made')
	eq(T.rgb(list[1].text:GetTextColor()), T.rgb(0.2, 0.2, 0.9), 'the last seconds: the text in the new Danger')
	eq(T.rgb(list[1].bar:GetStatusBarColor()), T.rgb(0.2, 0.2, 0.9), 'and the bar')
	eq(T.rgb(list[2].text:GetTextColor()), T.rgb(0.9, 0.9, 0.1), 'time left: the text in Normal')
	eq(T.rgb(list[3].text:GetTextColor()), T.rgb(1, 1, 1), 'a hidden timer is left')
	for i, t in ipairs(list) do
		eq(t.frame:GetHeight() .. ',' .. tostring(select(2, t.frame:GetPoint(1))), before[i], 'timer ' .. i .. ' not laid out')
	end
	check(not list[3].frame:IsShown(), 'a hidden timer stays hidden')
end)

-- Four timers on secret values, each with a duration object as the game gives
-- one: its curve evaluation gives the curve's color for the time left (here the
-- last point, past the warning).
local function secret_timers(st, TB)
	_G.C_CurveUtil = { CreateColorCurve = CreateColorCurve }
	Enum.LuaCurveType = { Linear = 0, Step = 1, Cosine = 2, Cubic = 3 }
	TB.GetElementColor = function() return nil end
	local list, evaluated = {}, { n = 0 }
	for _, timer in pairs(timers_of(TB)) do
		list[#list + 1] = timer
		timer.secret, timer.slot, timer.elapsed = true, #list, 0
		timer.duration = {
			IsActive = function() return true end,
			FormatRemainingDuration = function() return '12' end,
			EvaluateRemainingDuration = function(_, curve)
				evaluated.n = evaluated.n + 1
				local p = curve:GetPoints()
				return p[#p].y
			end,
		}
		timer.frame.SetAlphaFromBoolean = function() end
		timer.frame:Show()
	end
	return list, evaluated
end

test("a secret timer: a pass makes no curve and colors nothing; its next refresh (0.1 s) has the new color, bar and text", function()
	local st, TB = live_world()
	local profile = st.config.profile
	local list, evaluated = secret_timers(st, TB)
	profile.colors.text.normal:SetRGB(0.9, 0.9, 0.1)
	-- One refresh first, so the curves exist in the old colors, as after a timer's first tick.
	for _, t in ipairs(list) do stub.fire_script(t.frame, 'OnUpdate', 0.2) end
	eq(evaluated.n, 8, 'a text curve and a bar curve evaluated by each of four timers')
	eq(T.rgb(list[1].text:GetTextColor()), T.rgb(0.9, 0.9, 0.1), 'the old Normal')
	profile.colors.text.normal:SetRGB(0.1, 0.9, 0.9)
	local m
	alone(st, TB, function() m = C.measure(function() st:ColorChanged('text', 'normal') end, 100) end)
	eq(evaluated.n, 8, 'a pass evaluates nothing')
	eq(m.made, 0, 'and makes nothing')
	eq(m.forbidden.total, 0)
	check(m.kb < 4, 'garbage over 100 passes with four secret timers: ' .. m.kb .. ' KB')
	eq(T.rgb(list[1].text:GetTextColor()), T.rgb(0.9, 0.9, 0.1), 'the pass left the secret timer as it was')
	for i, t in ipairs(list) do stub.fire_script(t.frame, 'OnUpdate', 0.2) end
	for i, t in ipairs(list) do
		eq(T.rgb(t.text:GetTextColor()), T.rgb(0.1, 0.9, 0.9), 'timer ' .. i .. ': the text takes the new Normal at its next refresh')
		eq(T.rgb(t.bar:GetStatusBarColor()), T.rgb(0.1, 0.9, 0.9), 'timer ' .. i .. ': and the bar')
	end
end)

test('in combat the timers and the buttons take a pick with no forbidden call and almost no garbage (Review Focus 4)', function()
	local st, TB, buttons = live_world()
	local profile = st.config.profile
	TB.GetElementColor = function() return nil end
	local n = 0
	for _, timer in pairs(timers_of(TB)) do
		n = n + 1
		timer.secret, timer.warning, timer.slot = false, n % 2 == 0, n
		timer.frame:Show()
		timer.text:SetTextColor(1, 1, 1)
		timer.bar:SetStatusBarColor(1, 1, 1)
	end
	for _, b in ipairs(buttons) do b.Flash:SetColorTexture(1, 1, 1, 1) end
	stub.in_combat = true
	local m
	alone(st, TB, function()
		m = C.measure(function()
			st:ColorChanged('text', 'danger')
			st:ColorChanged('button', 'danger')
			st:ColorChanged('accent')
		end, 100)
	end)
	eq(m.forbidden.total, 0, 'nothing forbidden in combat')
	eq(m.made, 0, 'nothing made')
	check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
	C.print('totem bar, text danger + button danger + accent', m)
	stub.in_combat = false
	eq(#stub.blocked, 0, 'nothing blocked')
end)
