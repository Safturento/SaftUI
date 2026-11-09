-- The guide name grows to fit its title (FitTitle in
-- SaftUI-Misc/Skinning/restedxp.lua). Migrated from the rxpsim harness's
-- test_title.lua.
--
-- The stubs have no text layout (a font string is one line tall), so a test
-- sets what the title measures with H.text_height, and what the game's layout
-- pass does on a resize with the watcher frame's OnSizeChanged.
local H = load_test_file('misc/restedxp_helpers.lua')
local RXP = H.RXP

local function setup(before)
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	if before then before(R) end
	local RX = H.get_rx()
	local ok, err = pcall(RX.OnEnable, RX)
	return R, RX, ok, err
end
-- The frame that follows the title text's laid-out size (a stand-in for WoW's
-- layout pass, which the stubs don't have).
local function textWatcher(R)
	for _, child in ipairs({ R.GuideName:GetChildren() }) do
		local _, rel = child:GetPoint(1)
		if rel == R.GuideName.text and child:GetScript('OnSizeChanged') then return child end
	end
end
-- WoW lays the text out: it now measures h, and the watcher sees the new size.
local function layout(R, h)
	H.text_height(R.GuideName.text, h)
	local w = textWatcher(R)
	if w then stub.fire_script(w, 'OnSizeChanged', 200, h) end
end

test('one line keeps RestedXP height', function()
	local R, _, ok, err = setup(function(R) H.text_height(R.GuideName.text, 14) end)
	check(ok, 'enable ok ' .. tostring(err))
	check(R.GuideName:GetHeight() == 35, 'one-line title stays 35, got ' .. tostring(R.GuideName:GetHeight()))
end)

test('two lines grow it on SetText', function()
	local R = setup(function(R) H.text_height(R.GuideName.text, 14) end)
	H.text_height(R.GuideName.text, 44)
	R.GuideName.text:SetText('23-24 Wetlands\nSpeedrun Guide 20-30')
	check(R.GuideName:GetHeight() == 56, 'two lines -> 44 + 2*6 = 56, got ' .. tostring(R.GuideName:GetHeight()))
	check(R.GuideName.text:GetText() == '23-24 Wetlands\nSpeedrun Guide 20-30', 'text still set')
	H.text_height(R.GuideName.text, 14)
	R.GuideName.text:SetText('Short')
	check(R.GuideName:GetHeight() == 35, 'back to one line -> 35, got ' .. tostring(R.GuideName:GetHeight()))
end)

test('long title at load is fitted', function()
	local R = setup(function(R) H.text_height(R.GuideName.text, 40.4) end)
	check(R.GuideName:GetHeight() == 53, 'ceil(40.4 + 12) = 53, got ' .. tostring(R.GuideName:GetHeight()))
end)

test('font change refits', function()
	local R = setup(function(R) H.text_height(R.GuideName.text, 30) end)
	check(R.GuideName:GetHeight() == 42, 'start 42, got ' .. tostring(R.GuideName:GetHeight()))
	H.text_height(R.GuideName.text, 50)  -- RestedXP's font size went up
	R.GuideName.text:SetFont('rxpfont', 15, '')
	check(R.GuideName:GetHeight() == 62, 'font change -> 62, got ' .. tostring(R.GuideName:GetHeight()))
end)

test('resize rewrap refits', function()
	local R = setup(function(R) H.text_height(R.GuideName.text, 14) end)
	check(textWatcher(R) ~= nil, 'a frame follows the title text')
	layout(R, 44) -- a narrower window wrapped it
	check(R.GuideName:GetHeight() == 56, 'rewrap -> 56, got ' .. tostring(R.GuideName:GetHeight()))
	layout(R, 44)
	check(R.GuideName:GetHeight() == 56, 'same size again is a no-op')
end)

test('text wrapped after load is refit when laid out', function()
	-- At load the text isn't laid out yet: it measures as its two lines unwrapped.
	local R = setup(function(R) H.text_height(R.GuideName.text, 28) end)
	check(R.GuideName:GetHeight() == 40, 'load-time fit 28 + 12 = 40, got ' .. tostring(R.GuideName:GetHeight()))
	layout(R, 58) -- laid out, it wraps to four lines
	check(R.GuideName:GetHeight() == 70, 'laid out -> 58 + 12 = 70, got ' .. tostring(R.GuideName:GetHeight()))
end)

test('no text height', function()
	local R, _, ok = setup(function(R) H.text_height(R.GuideName.text, nil) end)
	check(ok and R.GuideName:GetHeight() == 35, 'nil string height -> 35')
end)
