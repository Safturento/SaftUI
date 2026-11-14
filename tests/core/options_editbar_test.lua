-- /sui under edit mode's docked bar (SaftUI-Core/Config/optionswindow.lua's
-- Anchor, CoverTop and S.UpdateBarCover): while the bar is docked and shown
-- across the top of the screen the window, in every size (the 42 tall bar
-- above all), sits no higher than the bar's bottom, as a display offset only:
-- the saved corner is never changed by it, and the window is back at it when
-- the bar hides, detaches or edit mode ends. A drag while offset saves the
-- place it was dropped at, never a doubled offset. Whole pixels throughout.
--
-- Real: Core's Config on a real AceDB (config_helpers.lua, which loads edit
-- mode and its bar), the model, the widgets, the body and the window
-- (options_window_helpers.lua). The mouse is played by firing scripts.
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
load_editmode_bar()
local st = SaftUI
local OW = st.OptionsWindow
local EM = st.EditModeFrames
local theme, close_all, frames = H.theme, H.close_all, H.frames
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

local function wait() stub.time = stub.time + 0.31 end

local function reset()
	if EM.active then EM:Deactivate() end
	EM:SetBarFloating(false)
	st.config.global.optionsWindow = { point = 'TOPRIGHT', x = 0, y = 0 }
	close_all()
	st.config.global.optionsWindow = { point = 'TOPRIGHT', x = 0, y = 0 }
	stub.size_noise = 0
	theme('thick')
end

-- How far below the screen's top the window's top (its metal's art too, under
-- Blizzard, when it isn't the bar) shows.
local function top_of(F)
	local top = UIParent:GetTop() - F.window:GetTop()
	if st:IsBlizzardLook('theme', 'theme') and OW:GetWindowSize() ~= 'mini' then
		top = top - st.ThemeArt.MetalAbove()
	end
	return top
end

local RANK = { full = 1, half = 2, mini = 3 }
local function go(size)
	for _ = 1, 3 do
		if OW:GetWindowSize() == size then return end
		wait()
		local step = RANK[size] > RANK[OW:GetWindowSize()] and 1 or -1
		check(OW:SetWindowSize(OW.NextSize(OW:GetWindowSize(), step)), 'a step to ' .. size)
	end
end

for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
	for _, size in ipairs({ 'full', 'half', 'mini' }) do
		test(('the docked edit mode bar never covers /sui at the top of the screen: %s, %s'):format(look, size), function()
			reset()
			theme(look)
			st.Config:Open('Loot')
			local F = frames()
			-- A window as it opens parks at the top: its place is what it was saved.
			go(size)
			EM:Activate()
			check(EM:BarCoverHeight() > 0, 'edit mode\'s bar is docked and shown')
			local cover = EM:BarCoverHeight()
			check(top_of(F) >= cover - 1e-3, ('the window starts %s below the screen\'s top, not under the %s of the bar'):format(top_of(F), cover))
			-- No part of it under the bar: the controls that take the clicks.
			local barBottom = UIParent:GetTop() - cover
			for _, name in ipairs({ 'close', 'shrink', 'grow', 'miniGrow', 'header', 'miniNames' }) do
				local f = F[name]
				if f and f:IsVisible() then check(f:GetTop() <= barBottom + 1e-3, name .. ' is clear of the bar') end
			end
			eq(st.config.global.optionsWindow.y, 0, 'the saved corner is untouched')
			eq(OW.S.corner.y, 0, 'and S.corner')
			local off = P.off(F.window)
			eq(#off, 0, 'whole pixels: ' .. P.report(off))
			-- Detached: back at the saved place.
			EM:SetBarFloating(true)
			eq(EM:BarCoverHeight(), 0, 'the bar floats')
			check(UIParent:GetTop() - F.window:GetTop() < cover, 'the window is back at its saved corner')
			EM:SetBarFloating(false)
			check(top_of(F) >= cover - 1e-3, 'docked again: below the bar')
			EM:Deactivate()
			check(UIParent:GetTop() - F.window:GetTop() < cover, 'edit mode ends: back at its saved corner')
			EM:Activate()
			check(top_of(F) >= cover - 1e-3, 'on again: below the bar')
			-- Combat turns edit mode off.
			stub.in_combat = true
			EM:PLAYER_REGEN_DISABLED()
			stub.in_combat = false
			check(UIParent:GetTop() - F.window:GetTop() < cover, 'combat: back at its saved corner')
			-- A window opened while edit mode is on.
			EM:Activate()
			st.Config:Close(); st.Config:Open('Loot')
			check(top_of(frames()) >= cover - 1e-3, 'opened under the bar: below it')
			reset()
			eq(#take_errors(), 0, 'no errors')
		end)
	end
end

test('a drag while offset saves the place it was dropped at, never a doubled offset', function()
	reset()
	st.Config:Open('Loot')
	local F = frames()
	EM:Activate()
	local cover = EM:BarCoverHeight()
	local function drop(y)
		stub.fire_script(F.header, 'OnDragStart')
		F.window:ClearAllPoints()
		F.window:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 300, y)
		stub.fire_script(F.header, 'OnDragStop')
	end
	drop(-200)
	eq(st.config.global.optionsWindow.y, -200, 'dropped below the bar: saved where it was dropped')
	eq(OW.S.corner.y, -200)
	eq(UIParent:GetTop() - F.window:GetTop(), 200, 'and shown there')
	drop(-5)
	eq(st.config.global.optionsWindow.y, -cover, 'dropped under the bar: clamped to its bottom')
	eq(UIParent:GetTop() - F.window:GetTop(), cover, 'and shown there')
	EM:Deactivate()
	eq(UIParent:GetTop() - F.window:GetTop(), cover, 'edit mode ends: it stays where it was saved')
	reset()
	eq(#take_errors(), 0, 'no errors')
end)
