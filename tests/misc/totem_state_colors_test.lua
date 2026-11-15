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
