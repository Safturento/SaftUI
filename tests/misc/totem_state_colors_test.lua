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
