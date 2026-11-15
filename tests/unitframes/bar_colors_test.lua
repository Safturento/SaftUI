-- Unit frame bar colors: colorCustom on the health, power and additional power
-- bars (UF:UpdateStatusBarElement and health's PostUpdate in updaters.lua and
-- elements/health.lua), and the castbar's background (elements/castbar.lua).
-- The bars come from the real constructors and the real default configs.
--
-- customColor is a plain { r, g, b } list in the defaults, and a saved profile
-- can hold a color object too; both must work.
--
-- Stand-ins: UF:RegisterElement (unitframes.lua needs oUF; a copy of its table
-- store) and the secret value (the stubs can't make one, so a newproxy that
-- errors on use, as in power_text_test.lua) with C_CurveUtil's
-- EvaluateColorValueFromBoolean returning it, which is what the game hands a
-- secret notInterruptible castbar.
load_core_helpers()
load_saftui('SaftUI-Core/Config/defaults.lua')
load_saftui('SaftUI-Unitframes/config/default.lua')

local st = SaftUI
-- The module by hand, UF:RegisterElement as unitframes.lua's table store
-- (uf_world.lua's UW.module): the real file needs oUF.
local UF = load_test_file('unitframes/uf_world.lua').module()

local secret = newproxy(true)
do
	local meta = getmetatable(secret)
	local function refuse() error('attempt to use a secret value', 2) end
	meta.__index, meta.__newindex, meta.__call, meta.__len, meta.__concat = refuse, refuse, refuse, refuse, refuse
	meta.__lt, meta.__le = refuse, refuse
	for _, op in ipairs({ '__add', '__sub', '__mul', '__div', '__mod', '__pow', '__unm' }) do meta[op] = refuse end
end
function issecretvalue(v) return v == secret end
C_CurveUtil = { EvaluateColorValueFromBoolean = function() return secret end }

load_saftui('SaftUI-Unitframes/updaters.lua')
load_saftui('SaftUI-Unitframes/constructors.lua')
load_saftui('SaftUI-Unitframes/elements/health.lua')
load_saftui('SaftUI-Unitframes/elements/power.lua')
load_saftui('SaftUI-Unitframes/elements/additionalpower.lua')
load_saftui('SaftUI-Unitframes/elements/castbar.lua')

local function copy(t)
	if type(t) ~= 'table' then return t end
	local c = {}
	for k, v in pairs(t) do c[k] = copy(v) end
	if t.GetRGB then return CreateColor(t:GetRGB()) end
	return c
end

local unit_defaults = st.defaults.unitframes.profiles['**']
local function new_unitframe()
	local frame = CreateFrame('Button', 'TestUnitFrame', UIParent)
	local defaults = unit_defaults['**'] or unit_defaults
	frame.config = {}
	for _, key in ipairs({ 'health', 'power', 'additionalpower', 'castbar' }) do
		frame.config[key] = copy(defaults[key])
	end
	frame.GetConfig = function(self) return self.config end
	frame.TextOverlay = CreateFrame('Frame', nil, frame)
	return frame
end

local function bar(element_name)
	local frame = new_unitframe()
	local element = UF.elements[element_name].Constructor(frame)
	return element, frame
end

local function rgb(r, g, b) return { r, g, b } end
local function bar_color(element)
	local r, g, b = element:GetStatusBarColor()
	return r, g, b
end

for _, name in ipairs({ 'Health', 'Power', 'AdditionalPower' }) do
	test(name .. ': colorCustom colors the bar with the default customColor list', function()
		local element = bar(name)
		local config = element.config
		check(type(config.customColor) == 'table' and config.customColor.GetRGB == nil, 'the default is a plain list')
		config.colorCustom = true
		config.enable = true
		UF:UpdateStatusBarElement(element)
		local r, g, b = bar_color(element)
		check(near(r, config.customColor[1]) and near(g, config.customColor[2]) and near(b, config.customColor[3]),
			('bar color is customColor, got %s %s %s'):format(r, g, b))
	end)

	test(name .. ': colorCustom takes a color object too', function()
		local element = bar(name)
		element.config.colorCustom = true
		element.config.customColor = CreateColor(.1, .2, .3)
		UF:UpdateStatusBarElement(element)
		local r, g, b = bar_color(element)
		check(near(r, .1) and near(g, .2) and near(b, .3), 'bar color is the color object')
	end)

	test(name .. ': colorCustom off leaves the bar color alone', function()
		local element = bar(name)
		element:SetStatusBarColor(.9, .8, .7)
		UF:UpdateStatusBarElement(element)
		local r = bar_color(element)
		check(near(r, .9), 'bar color unchanged')
	end)
end

-- oUF recolors a bar for any color flag (UpdateColor: SetStatusBarColor), then
-- calls the element's PostUpdateColor; its Path runs Update before ColorPath, so
-- PostUpdate runs before the recolor. oUF can't load here, so this does that order
-- by hand with each element's real callbacks and oUF's callback signatures.
local function oUF_path(element, name)
	if name == 'Health' then element.text = nil; element:PostUpdate('player', 50, 100) -- no text: its Unit* calls aren't stubbed
	elseif name == 'AdditionalPower' then element:PostUpdate(40, 100) end
	element:SetStatusBarColor(1, 0, 0) -- oUF's recolor for colorPower / colorClass / ...
	if name == 'Health' then element:PostUpdateColor('player', nil)
	elseif name == 'Power' then element:PostUpdateColor('player', nil, nil, nil, nil)
	else element:PostUpdateColor(nil) end
end

for _, name in ipairs({ 'Health', 'Power', 'AdditionalPower' }) do
	test(name .. ': colorCustom wins over a color flag after oUF recolors the bar', function()
		local element = bar(name)
		element.config.colorPower, element.config.colorClass = true, true
		element.config.colorCustom = true
		element.config.customColor = rgb(.2, .4, .6)
		element.bg:SetVertexColor(1, 1, 1)
		oUF_path(element, name)
		local r, g, b = bar_color(element)
		check(near(r, .2) and near(g, .4) and near(b, .6), ('bar ends in customColor, got %s %s %s'):format(r, g, b))
		if name ~= 'Health' then
			local br = element.bg:GetVertexColor()
			check(near(br, .2 * element.config.bg.multiplier), 'background follows the custom color')
		end
	end)

	test(name .. ': without colorCustom oUF\'s color stays', function()
		local element = bar(name)
		element.config.colorPower = true
		oUF_path(element, name)
		local r = bar_color(element)
		check(near(r, 1), 'oUF color kept')
	end)
end

test('castbar bg defaults have the same shape as health and power', function()
	local bg = unit_defaults['**'] and unit_defaults['**'].castbar.bg or unit_defaults.castbar.bg
	check(type(bg.alpha) == 'number' and type(bg.multiplier) == 'number', 'castbar.bg has alpha and multiplier')
end)

test('castbar: enabling bg shows a colored background with no error', function()
	local castbar = bar('Castbar')
	castbar.config.bg.enable = true
	castbar.config.enable = true
	UF:UpdateStatusBarElement(castbar)
	check(castbar.bg:IsShown(), 'bg shown')
	castbar.PostCastStart(castbar, 'player', 1, false)
	local c = { castbar.bg:GetVertexColor() }
	local normal, mu = castbar.config.colors.normal, castbar.config.bg.multiplier
	check(near(c[1], normal.r * mu) and near(c[2], normal.g * mu) and near(c[3], normal.b * mu),
		'bg is the bar color times the multiplier')
	eq(c[4], castbar.config.bg.alpha, 'bg alpha')
end)

test("castbar: a cast that can't be interrupted colors the bg from its color", function()
	local castbar = bar('Castbar')
	castbar.config.bg.enable = true
	UF:UpdateStatusBarElement(castbar)
	castbar.PostCastStart(castbar, 'player', 1, true)
	local c = { castbar.bg:GetVertexColor() }
	local color, mu = castbar.config.colors.nointerrupt, castbar.config.bg.multiplier
	check(near(c[1], color.r * mu) and near(c[2], color.g * mu) and near(c[3], color.b * mu), 'bg is the nointerrupt color times the multiplier')
end)

test('castbar: a secret color goes to the bg without arithmetic', function()
	local castbar = bar('Castbar')
	castbar.config.bg.enable = true
	UF:UpdateStatusBarElement(castbar)
	local got
	-- The stub's SetVertexColor takes numbers only; a secret goes through in game.
	castbar.bg.SetVertexColor = function(_, r, g, b, a) got = { r, g, b, a } end
	castbar.SetStatusBarColor = function() end -- likewise
	castbar.PostCastStart(castbar, 'player', 1, secret)
	check(got and got[1] == secret and got[4] == castbar.config.bg.alpha * castbar.config.bg.multiplier,
		'secret channels passed on, multiplier folded into alpha')
end)

test('castbar: no bg coloring while bg is off', function()
	local castbar = bar('Castbar')
	UF:UpdateStatusBarElement(castbar)
	castbar.PostCastStart(castbar, 'player', 1, false)
	check(not castbar.bg:IsShown(), 'bg hidden')
end)

local function fill(castbar) return stub.state(castbar).color_fill end
test("castbar: oUF's notInterruptible argument picks the bar color", function()
	local castbar = bar('Castbar'); UF:UpdateStatusBarElement(castbar)
	local c = castbar.config.colors
	castbar.PostCastStart(castbar, 'target', 133, true)
	check(near(fill(castbar)[1], c.nointerrupt.r) and near(fill(castbar)[3], c.nointerrupt.b), "can't interrupt: its color")
	castbar.PostCastStart(castbar, 'target', 133, false)
	check(near(fill(castbar)[1], c.normal.r) and near(fill(castbar)[3], c.normal.b), 'interruptible: the castbar color')
end)
test('castbar: a cast turning uninterruptible mid-cast recolors', function()
	local castbar = bar('Castbar'); UF:UpdateStatusBarElement(castbar)
	castbar.PostCastStart(castbar, 'target', 133, false)
	castbar.PostCastInterruptible(castbar, 'target', 133, true)
	check(near(fill(castbar)[1], castbar.config.colors.nointerrupt.r), "now the can't-interrupt color")
end)
test('castbar: a secret notInterruptible is handed to EvaluateColorValueFromBoolean', function()
	local castbar = bar('Castbar'); UF:UpdateStatusBarElement(castbar)
	local got = {}
	local original = C_CurveUtil.EvaluateColorValueFromBoolean
	C_CurveUtil.EvaluateColorValueFromBoolean = function(b, t, f) got[#got + 1] = { b, t, f }; return secret end
	castbar.SetStatusBarColor = function() end -- the stub's takes numbers only
	-- Put back even when the call errors, so the cases after it see the real one.
	local ok, err = pcall(castbar.PostCastStart, castbar, 'target', 133, secret)
	C_CurveUtil.EvaluateColorValueFromBoolean = original
	check(ok, 'no error: ' .. tostring(err))
	eq(#got, 3, 'r, g and b')
	check(got[1][1] == secret and near(got[1][2], castbar.config.colors.nointerrupt.r) and near(got[1][3], castbar.config.colors.normal.r), 'the secret, then true and false colors')
end)
test("castbar: the icon is oUF's; no CastingInfo is read", function()
	local castbar = bar('Castbar'); UF:UpdateStatusBarElement(castbar)
	-- Classic-only (Blizzard_DeprecatedUnitScript); Forever and retail lack it,
	-- so it's taken away for the call and put back after, whatever happens.
	local castingInfo = CastingInfo
	CastingInfo = nil
	castbar.Icon.texture:SetTexture([[Interface\ICONS\INV_Misc_QuestionMark]])
	local ok, err = pcall(castbar.PostCastStart, castbar, 'target', 133, false)
	CastingInfo = castingInfo
	check(ok, 'no error: ' .. tostring(err))
	eq(castbar.Icon.texture:GetTexture(), [[Interface\ICONS\INV_Misc_QuestionMark]], 'the icon left as oUF set it')
end)

-- The defaults a newly exposed option would error or do nothing with, as AceDB
-- fills a profile from them: the base defaults, then each unit's (the TOC's
-- config/load.xml order), read through the profile.
test('defaults that block their options are fixed', function()
	for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget',
			'boss', 'arena', 'party', 'raid10', 'raid40' }) do
		load_saftui('SaftUI-Unitframes/config/units/' .. unit .. '.lua')
	end
	apply_defaults()
	local profiles = st.config.profile.unitframes
	local P = profiles.profiles[profiles.config_profile]

	-- Additional power: colored by the mana color, not left white.
	eq(unit_defaults['**'].additionalpower.colorPower, true, 'additional power defaults to Color by power type')
	eq(P.player.additionalpower.colorPower, true, "and the player's has it")

	-- Focus's castbar color is its own: a keyed color, which GetRGB reads.
	local focus, target = P.focus.castbar.colors.normal, P.target.castbar.colors.normal
	local r, g, b = focus:GetRGB()
	check(near(r, .5) and near(g, .9) and near(b, .7), ('focus castbar color is .5 .9 .7, got %s %s %s'):format(r, g, b))
	r, g, b = UF.UnpackColor(focus)
	check(near(r, .5) and near(g, .9) and near(b, .7), 'UF.UnpackColor reads it too')
	check(near(focus.r, .5) and near(focus.g, .9) and near(focus.b, .7), "and the castbar's Color option, which reads r, g and b")
	r, g, b = target:GetRGB()
	check(near(r, .5) and near(g, .7) and near(b, .9), 'other units keep the base color')
	-- The focus castbar takes it, as UpdateConfig copies it into castbar.colors.
	local frame = new_unitframe()
	frame.config.castbar = P.focus.castbar
	local castbar = UF.elements.Castbar.Constructor(frame)
	r, g, b = castbar.colors.normal:GetRGB()
	check(near(r, .5) and near(g, .9) and near(b, .7), "the focus castbar's color")

	-- Health text's Deficit on every unit: on for party and raid, off elsewhere.
	for unit, on in pairs({ player = false, target = false, targettarget = false, focus = false, focustarget = false,
			pet = false, pettarget = false, boss = false, arena = false, party = true, raid10 = true, raid40 = true }) do
		eq(P[unit].health.text.deficit, on, unit .. "'s health text Deficit default")
	end
end)

------------------------------------------------------------------ the text colors

-- The health, power and additional power texts' own color (text.colorCustom
-- and text.customColor, UF:UpdateText in updaters.lua). Off, a text has its
-- font's color, white, as it always had; nothing in these elements recolors a
-- text afterwards (their PostUpdates only set its string), so the color
-- UpdateText gave stays through a unit change, a power type change, Dead and
-- the rest. The stub's SetFontObject keeps a color set on the font string
-- itself, which is the stricter reading of the game's.
local function text_rgb(text) return { text:GetTextColor() } end
-- A bar whose text UF:UpdateText can place. Stand-in: UF:GetFrame (it finds the
-- frame a position names; unitframes.lua has it, which needs oUF) gives the unit frame.
function UF:GetFrame(unitframe) return unitframe end
local function text_bar(name) return (bar(name)) end
local function same(rgba, r, g, b) return near(rgba[1], r) and near(rgba[2], g) and near(rgba[3], b) end

for _, name in ipairs({ 'Health', 'Power', 'AdditionalPower' }) do
	local key = name:lower()

	test(name .. ' text: every unit has the text color off, white, in its defaults', function()
		for unit, config in pairs(unit_defaults) do
			if unit ~= '**' and type(config) == 'table' and type(config[key]) == 'table' and type(config[key].text) == 'table' then
				eq(config[key].text.colorCustom, nil, unit .. ': the unit sets none of its own (the shared default applies)')
			end
		end
		local text = (unit_defaults['**'] or unit_defaults)[key].text
		eq(text.colorCustom, false, 'off by default')
		check(type(text.customColor) == 'table' and text.customColor.GetRGB == nil and same(text.customColor, 1, 1, 1),
			'white as a plain list')
	end)

	test(name .. ' text: off keeps the font\'s color; on takes the custom color, a list or a color object; off again puts the font\'s back', function()
		local element = text_bar(name)
		local text, config = element.text, element.config.text
		UF:UpdateText(text)
		local font = { st:GetFont(config.font):GetTextColor() }
		check(same(text_rgb(text), font[1], font[2], font[3]), 'off: the font\'s color')
		check(same(text_rgb(text), 1, 1, 1), 'which is white')

		config.colorCustom, config.customColor = true, { 0.2, 0.4, 0.6 }
		UF:UpdateText(text)
		check(same(text_rgb(text), 0.2, 0.4, 0.6), 'on: the list\'s color')
		config.customColor = CreateColor(0.9, 0.8, 0.1)
		UF:UpdateText(text)
		check(same(text_rgb(text), 0.9, 0.8, 0.1), 'a color object, as a saved profile can hold one')

		config.colorCustom = false
		UF:UpdateText(text)
		check(same(text_rgb(text), font[1], font[2], font[3]), 'off again: the font\'s color is back')
	end)

	test(name .. ' text: a font change keeps the custom color, and the bar\'s color is not the text\'s', function()
		local element = text_bar(name)
		local text, config = element.text, element.config.text
		config.colorCustom, config.customColor = true, { 0.5, 0.6, 0.7 }
		element:SetStatusBarColor(0.1, 0.1, 0.1)
		config.font = 'pixel'
		UF:UpdateText(text)
		check(same(text_rgb(text), 0.5, 0.6, 0.7), 'a new font object, the same color')
		check(same({ element:GetStatusBarColor() }, 0.1, 0.1, 0.1), 'the bar keeps its own')
	end)
end

test('health text: the custom color stays through updates, Dead and a unit change', function()
	local health = text_bar('Health')
	local text, config = health.text, health.config.text
	config.colorCustom, config.customColor = true, { 0.3, 0.9, 0.3 }
	UF:UpdateText(text)
	stub.units.target = { name = 'Mob', dead = true }
	health.PostUpdate(health, 'target', 0, 100)
	eq(text:GetText(), 'Dead', 'the dead text')
	check(same(text_rgb(text), 0.3, 0.9, 0.3), 'in the custom color: Dead is not recolored by the element')
	stub.units.target = nil
	health.PostUpdate(health, 'player', 50, 100)
	health.PostUpdateColor(health, 'player')
	check(same(text_rgb(text), 0.3, 0.9, 0.3), 'a health update and a recolor leave it')
end)

test('power text: the custom color stays through a power type change', function()
	local power = text_bar('Power')
	local text, config = power.text, power.config.text
	config.colorCustom, config.customColor = true, { 0.3, 0.9, 0.3 }
	power.config.enable = true
	UF:UpdateText(text)
	power.PostUpdate(power, 'player', 40, 0, 100)
	power.PostUpdateColor(power, 'player', CreateColor(1, 0, 0), 1, 0, 0)
	check(same(text_rgb(text), 0.3, 0.9, 0.3), 'oUF recoloring the bar leaves the text')
	power.PostUpdate(power, 'player', 90, 0, 100)
	check(same(text_rgb(text), 0.3, 0.9, 0.3), 'and so does the next update')
end)

test("a typeface on a unit frame's health text draws at once, and a value naming nothing draws Text", function()
	local health = text_bar('Health')
	local text, config = health.text, health.config.text
	config.font = { font_name = 'Friz Quadrata TT', font_size = 13, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 0 }
	UF:UpdateText(text)
	eq(text:GetFontObject(), st:GetFont(config.font), "the typeface's object")
	eq(select(2, text:GetFont()), 13, 'at its size')
	eq(stub.state(text).font, nil, 'by SetFontObject, never SetFont')

	config.colorCustom, config.customColor = true, { 0.2, 0.4, 0.6 }
	UF:UpdateText(text)
	check(same(text_rgb(text), 0.2, 0.4, 0.6), 'the custom color goes on after the font')
	config.colorCustom = false
	UF:UpdateText(text)
	check(same(text_rgb(text), 1, 1, 1), "turned off: the typeface object's color, white")

	config.font = 'a font that does not exist'
	UF:UpdateText(text)
	eq(text:GetFontObject(), st:GetFont('normal'), 'a value that names nothing draws Text')
	config.colorCustom = true
	UF:UpdateText(text)
	config.colorCustom = false
	UF:UpdateText(text)
	check(same(text_rgb(text), 1, 1, 1), 'and turning the color off with it puts Text\'s color back, with no error')
end)
