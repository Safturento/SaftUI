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
local UF = st:NewModule('Unitframes')
UF.elements = {}
function UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable, ValidUnit)
	self.elements[name] = { name = name, Constructor = Constructor, UpdateConfig = UpdateConfig,
		GetConfigTable = GetConfigTable, ValidUnit = ValidUnit }
end

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
local function near(a, b) return math.abs(a - b) < 1e-6 end
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

test('health PostUpdate keeps the custom color when oUF recolors the bar', function()
	local health = bar('Health')
	health.config.colorCustom = true
	health.config.customColor = rgb(.2, .4, .6)
	health.text = nil
	health:SetStatusBarColor(1, 1, 1)
	health.PostUpdate(health, 'player', 50, 100)
	local r, g, b = bar_color(health)
	check(near(r, .2) and near(g, .4) and near(b, .6), 'custom color applied after the update')
end)

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
	castbar.notInterruptible = false
	castbar.PostCastStart(castbar, 'player')
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
	castbar.notInterruptible = true
	castbar.PostCastStart(castbar, 'player')
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
	castbar.notInterruptible = secret
	castbar.PostCastStart(castbar, 'player')
	check(got and got[1] == secret and got[4] == castbar.config.bg.alpha * castbar.config.bg.multiplier,
		'secret channels passed on, multiplier folded into alpha')
end)

test('castbar: no bg coloring while bg is off', function()
	local castbar = bar('Castbar')
	UF:UpdateStatusBarElement(castbar)
	castbar.notInterruptible = false
	castbar.PostCastStart(castbar, 'player')
	check(not castbar.bg:IsShown(), 'bg hidden')
end)
