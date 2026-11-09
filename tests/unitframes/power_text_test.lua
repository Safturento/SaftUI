-- Unit frame power bar text and smoothing: UF:GetSmoothing and
-- UF:SetPowerPercentText (SaftUI-Unitframes/updaters.lua) and the additional
-- power bar's PostUpdate (elements/additionalpower.lua), including secret
-- values. Migrated from the ufsim2 harness. The bar and its text come from
-- the real constructors.lua (UF:AddStatusBarElement, UF:AddText).
--
-- The stubs can't make a secret value: a Lua value the code may pass on but
-- not read, compare or format. So this file does by hand what the game does:
--   * `secret` is a userdata (newproxy, a Lua 5.1 base function the harness
--     keeps) whose metatable errors on indexing (read or write), calling,
--     `#`, `..`, arithmetic and ordering comparisons, as a secret does in
--     game (.agents/clients.md). The one thing Lua 5.1 can't catch is `==`
--     against a number or string: __eq only fires between two tables or two
--     userdata, so `secret == 5` quietly gives false here, where the game
--     errors. Code must guard with issecretvalue before any `==`; nothing
--     here proves it did.
--   * issecretvalue says which values are secret.
--   * A FontString takes a secret in SetText and SetFormattedText, as in
--     game, but the stub's FontString only takes strings and numbers, so
--     secret_text() keeps a secret passed to either on the font string
--     (.secret, and .format) and hands anything else to the stub's own method.
--     For plain values it records .format too (nil after SetText), so a check
--     can tell which of the two the code called.
--   * UnitPowerPercent returns a secret percent, and records its arguments.
load_core_helpers()

local st = SaftUI
local UF = st:NewModule('Unitframes')
-- What unitframes.lua's UF:RegisterElement does (lines 126-134: it keeps the
-- constructor in UF.elements). The real file needs oUF, which isn't loaded here.
UF.elements = {}
function UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable, ValidUnit)
	self.elements[name] = { name = name, Constructor = Constructor, UpdateConfig = UpdateConfig,
		GetConfigTable = GetConfigTable, ValidUnit = ValidUnit }
end

local function make_secret(name)
	local value = newproxy(true)
	local meta = getmetatable(value)
	local function refuse(what)
		return function() error(('attempt to %s a secret value (%s)'):format(what, name), 2) end
	end
	meta.__tostring = function() return name end
	meta.__index, meta.__newindex = refuse('index'), refuse('index')
	meta.__call, meta.__len, meta.__concat = refuse('call'), refuse('take the length of'), refuse('concatenate')
	meta.__lt, meta.__le = refuse('compare'), refuse('compare')
	for _, op in ipairs({ '__add', '__sub', '__mul', '__div', '__mod', '__pow', '__unm' }) do
		meta[op] = refuse('do arithmetic on')
	end
	return value
end
local secret = make_secret('SECRET')
local secret_percent = make_secret('SECRET PERCENT')
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
		else self.secret, self.format = nil, nil; set_text(self, value) end
	end
	text.SetFormattedText = function(self, format, value)
		if issecretvalue(value) then self.secret, self.format = value, format
		else self.secret, self.format = nil, format; set_formatted(self, format, value) end
	end
	return text
end

local function new_text()
	local text = UIParent:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(GameFontNormal)
	return secret_text(text)
end

test('the secret stand-in errors on what a game secret errors on', function()
	for _, s in ipairs({ secret, secret_percent }) do
		check(not pcall(function() return s.x end), 'indexing errors')
		check(not pcall(function() s.x = 1 end), 'assigning a field errors')
		check(not pcall(function() return s < 1 end), 'ordering errors')
		check(not pcall(function() return s + 1 end), 'arithmetic errors')
		check(not pcall(function() return 'a' .. s end), 'concatenation errors')
		check(not pcall(function() return #s end), 'length errors')
		check(not pcall(function() return s() end), 'calling errors')
		check(issecretvalue(s) and not issecretvalue(5) and not issecretvalue({}), 'issecretvalue tells them apart')
	end
	-- Not catchable in Lua 5.1: == against a number is quietly false.
	check(secret ~= 5, "== against a number doesn't error here, though it does in game")
	check(tostring(secret) == 'SECRET', 'tostring is for test messages only')
end)

test('smoothing: eased while on, immediate while off', function()
	check(UF:GetSmoothing(true) == 1 and UF:GetSmoothing(false) == 0 and UF:GetSmoothing(nil) == 0, 'smoothing on/off')
end)

test('a power percent text is a whole percent', function()
	local t = new_text(); UF:SetPowerPercentText(t, 'player', 50, 200)
	check(t.format == '%.0f' and t:GetText() == '25', 'plain percent 25')
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
	ap:PostUpdate(40, 100); check(ap.text.format == nil and ap.text:GetText() == '40', 'value when not full')
	ap.config.text.percent = true
	ap:PostUpdate(40, 100); check(ap.text.format == '%.0f' and ap.text:GetText() == '40', 'percent 40')
end)

test('additional power text with secret values', function()
	ap:PostUpdate(secret, 100); check(ap.text.secret == secret_percent, 'secret mana percent')
	ap.config.text = { hide_full = true, percent = false }
	ap:PostUpdate(secret, 100); check(ap.text.secret == secret, 'secret value passes through, no compare')
end)
