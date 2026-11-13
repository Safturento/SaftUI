-- The action bars' growth direction (First button): AB.ButtonPoint, LayoutBar
-- laying the buttons out from the chosen corner, the setting's storage, and the
-- interim option on each bar's General.
--
-- The world is shared_settings_test.lua's (the action bars' files but
-- hideblizzard.lua and keybindmode.lua, bars as plain frames).
local T = load_test_file('lib/theme_helpers.lua')

local CVAR = 'countdownForCooldowns'

local FILES = {
	'SaftUI-ActionBars/init.lua',
	'SaftUI-ActionBars/shared.lua',
	'SaftUI-ActionBars/skin.lua',
	'SaftUI-ActionBars/bars.lua',
	'SaftUI-ActionBars/buttons.lua',
	'SaftUI-ActionBars/petbar.lua',
	'SaftUI-ActionBars/stancebar.lua',
	'SaftUI-ActionBars/bindings.lua',
	'SaftUI-ActionBars/extras.lua',
	'SaftUI-ActionBars/options.lua',
}

local st, AB, LAB
local fader -- bars.lua's fader frame, caught while the file loads

-- A fresh world with Blizzard's setting on. saved is the action bars' part of
-- a profile saved earlier (AceDB keeps only what differs from the defaults).
local function fresh(saved, convert)
	reset_world()
	load_core_helpers()
	st = SaftUI
	LAB = load_test_file('actionbars/fixtures/libactionbutton.lua')
	load_saftui('SaftUI-ActionBars/config.lua')
	if saved then st.config.profile.actionbars = saved end
	apply_defaults()
	fader = nil
	for _, file in ipairs(FILES) do
		if file == 'SaftUI-ActionBars/bars.lua' then
			-- The fader is the file's only unnamed Frame.
			local real = CreateFrame
			CreateFrame = function(kind, name, ...)
				local frame = real(kind, name, ...)
				if kind == 'Frame' and name == nil then fader = frame end
				return frame
			end
			load_saftui(file)
			CreateFrame = real
		else
			load_saftui(file)
		end
	end
	AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
	stub.cvars[CVAR] = '1'
	function LAB:GetSpellFlyoutFrame() end -- what bars.lua asks of the library when a bar fades
	if convert ~= false then AB:ConvertProfile() end
end

-- A button as LibActionButton makes one, skinned by AB:SkinButton.
local function button(name)
	local b = CreateFrame('CheckButton', name, UIParent)
	b.icon = b:CreateTexture(nil, 'BACKGROUND')
	b.Flash = b:CreateTexture(nil, 'ARTWORK')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		b[key] = b:CreateFontString(nil, 'OVERLAY')
		b[key]:SetFontObject(GameFontNormal)
	end
	b.cooldown = CreateFrame('Cooldown', nil, b)
	function b:UpdateConfig(config) self.labConfig = config end
	AB:SkinButton(b)
	return b
end

-- Bar id holding the buttons, then updated from the profile (see the top).
local function bar(id, ...)
	local frame = CreateFrame('Frame', AB:GetBarFrameName(id), UIParent)
	frame.id = id
	frame.buttons = { ... }
	AB.bars[id] = frame
	AB:UpdateBar(id)
	return ...
end


local CORNERS = { 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT' }

test('ButtonPoint: rows fill across from the first corner, the next row away from it', function()
	fresh()
	local function p(...) return table.concat({ AB.ButtonPoint(...) }, ',') end
	eq(p(1, 12, 45, 3, 'TOPLEFT'), 'TOPLEFT,0,0', 'today')
	eq(p(2, 12, 45, 3, 'TOPLEFT'), 'TOPLEFT,48,0', 'then right')
	eq(p(2, 12, 45, 3, 'TOPRIGHT'), 'TOPRIGHT,-48,0', 'a row from the right runs right to left')
	eq(p(2, 1, 45, 3, 'BOTTOMLEFT'), 'BOTTOMLEFT,0,48', 'a column from the bottom runs upward')
	eq(p(5, 4, 30, 2, 'BOTTOMRIGHT'), 'BOTTOMRIGHT,0,32', 'the second row goes away from the corner')
	eq(p(7, 6, 45, 3, 'TOPRIGHT'), 'TOPRIGHT,0,-48', 'down from a top corner')
	eq(p(1, 12, 45, 3, 'MIDDLE'), 'TOPLEFT,0,0', 'an unknown corner is top left')
	eq(p(1, 12, 45, 3, nil), 'TOPLEFT,0,0', 'no corner is top left')
end)

test("the bar's size and place don't change with it, and every offset is a whole pixel", function()
	fresh()
	local buttons = {}
	for i = 1, 12 do buttons[i] = button('GrowthButton' .. i) end
	bar('bar1', unpack(buttons))
	AB:SetSetting('bar1', 'perrow', 6)
	AB:SetSetting('bar1', 'spacing', 3)
	AB:UpdateBar('bar1')
	local frame = AB.bars.bar1
	local w, h = frame:GetWidth(), frame:GetHeight()
	local point, rel, relPoint, x, y = frame:GetPoint(1)
	for _, corner in ipairs(CORNERS) do
		AB:SetSetting('bar1', 'growth', corner)
		AB:UpdateBar('bar1')
		local label = corner .. ': '
		eq(T.text(frame:GetWidth(), frame:GetHeight()), T.text(w, h), label .. 'the bar keeps its size')
		local q, r2, rp2, x2, y2 = frame:GetPoint(1)
		eq(table.concat({ q, tostring(r2), rp2, x2, y2 }, ','), table.concat({ point, tostring(rel), relPoint, x, y }, ','), label .. 'and its place')
		local p1, r1, rp1, x1, y1 = buttons[1]:GetPoint(1)
		eq(table.concat({ p1, rp1, x1, y1 }, ','), corner .. ',' .. corner .. ',0,0', label .. 'button 1 sits in the corner')
		eq(r1, frame, label .. 'anchored to the bar')
		for i = 1, 12 do
			local _, _, _, bx, by = buttons[i]:GetPoint(1)
			eq(bx == math.floor(bx) and by == math.floor(by), true, label .. 'button ' .. i .. ' on a whole pixel')
		end
		local _, _, _, x7, y7 = buttons[7]:GetPoint(1)
		eq(x7, 0, label .. 'button 7 starts the second row in the first column')
		eq(math.abs(y7), 48, label .. 'one pitch away')
		eq(y7 > 0, corner:find('BOTTOM') ~= nil, label .. 'upward from a bottom corner')
	end
end)

test('a profile from before has every bar follow All bars at top left', function()
	fresh({ bar2 = { size = 30 } })
	for _, id in ipairs(AB.BAR_IDS) do
		eq(AB:GetBarConfig(id).growth, 'TOPLEFT', id .. ' grows from the top left')
		eq(AB:IsOwn(id, 'growth'), false, id .. ' follows All bars')
	end
	eq(AB.SHARED_KEYS[5], 'growth', 'growth follows spacing in the keys')
end)

test('anything but a corner reads as top left', function()
	fresh()
	AB:SetSetting('all', 'growth', 'MIDDLE')
	eq(AB:GetBarConfig('bar1').growth, 'TOPLEFT', 'a stored value that is no corner')
	AB:SetSetting('all', 'growth', 'BOTTOMRIGHT')
	eq(AB:GetBarConfig('bar1').growth, 'BOTTOMRIGHT', 'a corner')
	eq(AB:GetBarConfig('all').growth, 'BOTTOMRIGHT', "All bars' own")
end)

test("First button on a bar's General writes the setting as the bar's own", function()
	fresh()
	AB.built = true
	AB.bars.bar3 = { buttons = {} }
	for i = 1, 12 do AB.bars.bar3.buttons[i] = {} end
	for i, v in ipairs({ 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT' }) do
		eq(AB.GROWTH_ORDER[i], v, 'order ' .. i)
	end
	eq(AB.GROWTH_VALUES.TOPRIGHT, 'Top right', 'a name')
	local updated = {}
	function AB:UpdateBar(id) updated[#updated + 1] = id end
	local growth = AB:GetBarOptions('bar3', 3).args.general.args.growth
	eq(growth.type, 'select', 'a select')
	eq(growth.name, 'First button', 'named')
	eq(growth.sorting, AB.GROWTH_ORDER, 'sorted by the order')
	eq(type(growth.desc), 'string', 'with a description')
	local general = AB:GetBarOptions('bar3', 3).args.general
	eq(general.get({ 'growth' }), 'TOPLEFT', 'reads the effective value')
	general.set({ 'growth' }, 'BOTTOMRIGHT')
	eq(AB:IsOwn('bar3', 'growth'), true, "the bar's own now")
	eq(AB:GetBarConfig('bar3').growth, 'BOTTOMRIGHT', 'and it shows')
	eq(AB:GetBarConfig('bar4').growth, 'TOPLEFT', 'another bar is unmoved')
	eq(table.concat(updated, ','), 'bar3', 'the bar was updated')
end)
