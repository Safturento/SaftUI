-- Unit frame power bar text and smoothing: UF:GetSmoothing and
-- UF:SetPowerPercentText (SaftUI-Unitframes/updaters.lua) and the additional
-- power bar's PostUpdate (elements/additionalpower.lua), including secret
-- values. Migrated from the ufsim2 harness. The bar and its text come from
-- the real constructors.lua (UF:AddStatusBarElement, UF:AddText).
--
-- The stubs can't make a secret value: a Lua value the code may pass on but
-- not read, compare or format. So this file does by hand what the game does:
--   * `secret` is a table. Comparing it with a number errors in Lua, as
--     reading a secret does in game, so code that compares it fails here.
--   * issecretvalue says which values are secret.
--   * A FontString takes a secret in SetText and SetFormattedText, as in
--     game, but the stub's FontString only takes strings and numbers, so
--     secret_text() keeps a secret passed to either on the font string
--     (.secret, and .format) and hands anything else to the stub's own method.
--   * UnitPowerPercent returns a secret percent, and records its arguments.
load_core_helpers()

local st = SaftUI
local UF = st:NewModule('Unitframes')
-- What unitframes.lua's UF:RegisterElement does (it keeps the constructor in
-- UF.elements). The real file needs oUF, which isn't loaded here.
UF.elements = {}
function UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable, ValidUnit)
	self.elements[name] = { name = name, Constructor = Constructor, UpdateConfig = UpdateConfig,
		GetConfigTable = GetConfigTable, ValidUnit = ValidUnit }
end

local secret = setmetatable({}, { __tostring = function() return 'SECRET' end })
local secret_percent = setmetatable({}, { __tostring = function() return 'SECRET PERCENT' end })
function issecretvalue(v) return v == secret or v == secret_percent end
CurveConstants = { ScaleTo100 = {} } -- Blizzard's 0-100 curve; only its identity matters here
local lastPercentArgs
function UnitPowerPercent(unit, powerType, unmodified, curve)
	lastPercentArgs = { unit, powerType, unmodified, curve }
	return secret_percent
end

load_saftui('SaftUI-Unitframes/updaters.lua')
load_saftui('SaftUI-Unitframes/constructors.lua')
load_saftui('SaftUI-Unitframes/elements/additionalpower.lua')

local function secret_text(text)
	local set_text, set_formatted = text.SetText, text.SetFormattedText
	text.SetText = function(self, value)
		if issecretvalue(value) then self.secret, self.format = value, nil
		else self.secret = nil; set_text(self, value) end
	end
	text.SetFormattedText = function(self, format, value)
		if issecretvalue(value) then self.secret, self.format = value, format
		else self.secret = nil; set_formatted(self, format, value) end
	end
	return text
end

local function new_text()
	local text = UIParent:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(GameFontNormal)
	return secret_text(text)
end

test('smoothing: eased while on, immediate while off', function()
	check(UF:GetSmoothing(true) == 1 and UF:GetSmoothing(false) == 0 and UF:GetSmoothing(nil) == 0, 'smoothing on/off')
end)

test('a power percent text is a whole percent', function()
	local t = new_text(); UF:SetPowerPercentText(t, 'player', 50, 200)
	eq(t:GetText(), '25', 'plain percent 25')
	t = new_text(); UF:SetPowerPercentText(t, 'player', 0, 0)
	eq(t:GetText(), '', 'zero max -> empty')
end)

test('a secret value goes through UnitPowerPercent with the 0-100 curve', function()
	local t = new_text(); UF:SetPowerPercentText(t, 'player', secret, 100, 0)
	check(t.secret == secret_percent and t.format == '%.0f' and lastPercentArgs[2] == 0 and lastPercentArgs[4] == CurveConstants.ScaleTo100,
		'secret -> UnitPowerPercent with the 0-100 curve')
end)

-- The additional power bar as its constructor makes it on a player frame.
local ap
local function make_bar()
	local unitframe = CreateFrame('Button', 'TestPlayerFrame', UIParent)
	unitframe.config = { additionalpower = { text = {} } }
	unitframe.GetConfig = function(self) return self.config end
	unitframe.TextOverlay = CreateFrame('Frame', nil, unitframe)
	local bar = UF.elements.AdditionalPower.Constructor(unitframe)
	secret_text(bar.text)
	bar.__owner = { unit = 'player' }
	return bar
end

test('additional power text: hide full, value, percent', function()
	ap = make_bar()
	ap.config = { text = { hide_full = true, percent = false } }
	ap:PostUpdate(100, 100); eq(ap.text:GetText(), '', 'hide full when full')
	ap:PostUpdate(40, 100); eq(ap.text:GetText(), '40', 'value when not full')
	ap.config.text.percent = true
	ap:PostUpdate(40, 100); eq(ap.text:GetText(), '40', 'percent 40')
end)

test('additional power text with secret values', function()
	ap:PostUpdate(secret, 100); check(ap.text.secret == secret_percent, 'secret mana percent')
	ap.config.text = { hide_full = true, percent = false }
	ap:PostUpdate(secret, 100); check(ap.text.secret == secret, 'secret value passes through, no compare')
end)
