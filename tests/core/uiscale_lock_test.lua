-- Blizzard's Use UI Scale row while SaftUI sets the scale
-- (SaftUI-Core/uiscalelock.lua): a cover of SaftUI's own over the row, with a
-- tooltip, in Automatic and Pixel for pixel; none in The game's UI scale. The
-- row is found by post-hooks on its mixin; nothing of the row's is written or
-- called.
--
-- Stubbed: Blizzard's SettingsCheckboxSliderControlMixin (only Init and
-- Release, which the hooks follow) and a row frame with a Checkbox, as
-- Blizzard_SettingControls.lua makes them. Real: uiscale.lua's runtime and
-- uiscalelock.lua.

local st

local function setting(variable)
	return { GetVariable = function() return variable end }
end

local function initializer(variable)
	return { data = { cbSetting = setting(variable) } }
end

-- A fresh world with Blizzard's mixin and one row, the lock file loaded after
-- the mixin exists (as in game: Blizzard's settings load before addons).
-- Returns the row and a log of the mixin's own calls.
local function world(choice)
	use_client('forever')
	st = SaftUI
	stub.screen_width, stub.screen_height = 2560, 1440
	local log = { init = 0, release = 0 }
	SettingsCheckboxSliderControlMixin = {
		Init = function() log.init = log.init + 1 end,
		Release = function() log.release = log.release + 1 end,
	}
	load_saftui('SaftUI-Core/uiscalelock.lua')
	if choice then st.config.global.uiScale = choice end
	st.UIScale:Start()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	local row = CreateFrame('Frame', nil, UIParent)
	row:SetSize(280, 26)
	row:SetFrameLevel(5)
	row.Checkbox = CreateFrame('CheckButton', nil, row)
	row.Checkbox:SetPoint('LEFT', row, 'CENTER', -80, 0)
	return row, log
end

local function init(row, variable)
	SettingsCheckboxSliderControlMixin.Init(row, initializer(variable))
end

local function cover_of(row)
	for _, child in ipairs({ row:GetChildren() }) do
		if child ~= row.Checkbox then return child end
	end
	return nil
end

test('the Use UI Scale row gets a cover in Automatic, over its checkbox and slider, with a tooltip', function()
	local row, log = world()
	init(row, 'PROXY_USE_UI_SCALE')
	eq(log.init, 1, "Blizzard's Init ran")
	check(st.UIScale:IsLocked(), 'locked')
	local cover = cover_of(row)
	check(cover ~= nil, 'a cover on the row')
	check(cover:IsShown(), 'shown')
	check(cover:IsMouseEnabled(), 'takes the clicks')
	check(cover:GetFrameLevel() > row.Checkbox:GetFrameLevel(), 'above the checkbox')

	stub.fire_script(cover, 'OnEnter')
	eq(GameTooltip:GetOwner(), cover, 'the tooltip is the cover\'s')
	stub.fire_script(cover, 'OnLeave')
end)

test('another row (a pooled one, taken for another setting) gets no cover', function()
	local row = world()
	init(row, 'PROXY_RENDER_SCALE')
	check(not st.UIScale:IsLocked(), 'not locked')
	local cover = cover_of(row)
	check(cover == nil or not cover:IsShown(), 'no cover shown')

	init(row, 'PROXY_USE_UI_SCALE')
	check(cover_of(row):IsShown(), 'covered once it is the UI scale row')
	init(row, 'PROXY_RENDER_SCALE')
	check(not cover_of(row):IsShown(), 'off again when the pool hands it to another setting')
end)

test('Release takes the cover off', function()
	local row, log = world()
	init(row, 'PROXY_USE_UI_SCALE')
	SettingsCheckboxSliderControlMixin.Release(row)
	eq(log.release, 1, "Blizzard's Release ran")
	check(not st.UIScale:IsLocked(), 'not locked')
	check(not cover_of(row):IsShown(), 'cover hidden')
end)

test("The game's UI scale has no cover, and a choice made with the options open follows", function()
	local row = world({ mode = 'game', size = 1 })
	init(row, 'PROXY_USE_UI_SCALE')
	check(not st.UIScale:IsLocked(), 'not locked in the game\'s UI scale')
	local cover = cover_of(row)
	check(cover == nil or not cover:IsShown(), 'no cover')

	st.UIScale:Apply({ mode = 'pixel', size = 1 })
	check(cover_of(row):IsShown(), 'covered after choosing Pixel for pixel')
	st.UIScale:Apply({ mode = 'game', size = 1 })
	check(not cover_of(row):IsShown(), 'uncovered after choosing the game\'s again')
end)

test('nothing is written onto the row or its checkbox', function()
	local row = world()
	local before, checkbox_before = {}, {}
	for k in pairs(row) do before[k] = true end
	for k in pairs(row.Checkbox) do checkbox_before[k] = true end
	init(row, 'PROXY_USE_UI_SCALE')
	SettingsCheckboxSliderControlMixin.Release(row)
	for k in pairs(row) do check(before[k], 'a field written onto the row: ' .. tostring(k)) end
	for k in pairs(row.Checkbox) do check(checkbox_before[k], 'a field written onto the checkbox: ' .. tostring(k)) end
end)

test('with no mixin at load, it hooks once the mixin appears', function()
	use_client('forever')
	st = SaftUI
	SettingsCheckboxSliderControlMixin = nil
	load_saftui('SaftUI-Core/uiscalelock.lua')
	eq(st.UIScale:HookOptions(), false, 'nothing to hook yet')
	SettingsCheckboxSliderControlMixin = { Init = function() end, Release = function() end }
	stub.fire_event('ADDON_LOADED', 'Blizzard_Settings_Shared')
	eq(st.UIScale:HookOptions(), true, 'hooked')
end)
