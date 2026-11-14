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

------------------------------------------------------------------ a tall window

-- The game's clamp of a clamped frame, which the stub does not mimic: the
-- frame's rect grown by its clamp insets is kept inside the screen, here
-- lifted by what its bottom passes (a window lowered under the edit bar and
-- tall is pushed back up under it). Returns how far up it moves.
local function lift_of(w)
	if not w:IsClampedToScreen() then return 0 end
	local _, _, _, bottomInset = w:GetClampRectInsets()
	local pass = UIParent:GetBottom() - (w:GetBottom() + bottomInset)
	return pass > 0 and pass or 0
end

local function drag_grip(handle, dy)
	local scale = frames().window:GetEffectiveScale()
	stub.mouse_buttons.LeftButton = true
	stub.cursor_y = 500 * scale
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	stub.cursor_y = (500 - dy) * scale
	stub.fire_script(handle, 'OnUpdate', 0.016)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
end

for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
	for _, margin in ipairs({ 20, 0 }) do
		for _, saved in ipairs({ 1018, 2000 }) do
			test(('a window taller than the room under the bar is shown no taller, and the game does not push it back under: %s, margin %d, saved height %d'):format(look, margin, saved), function()
				reset()
				local default = st.config.profile.misc.clamp_inset
				st.config.profile.misc.clamp_inset = margin
				st:UpdateScreenMargin()
				theme(look)
				st.config.global.optionsWindow = { point = 'TOPRIGHT', x = 0, y = 0, height = saved }
				st.Config:Open('Loot')
				local F = frames()
				local height = F.window:GetHeight()
				eq(height, OW.WindowHeight(OW.S.layout), 'opens at the height it should')
				EM:Activate()
				local cover = EM:BarCoverHeight()
				local barBottom = UIParent:GetTop() - cover
				local room = height
				check(F.window:GetHeight() <= UIParent:GetHeight() - cover - margin, 'no taller than the room under the bar: ' .. F.window:GetHeight())
				local lift = lift_of(F.window)
				eq(lift, 0, 'the game has nothing to push back up')
				for _, name in ipairs({ 'close', 'shrink', 'grow', 'header' }) do
					local f = F[name]
					if f and f:IsVisible() then check(f:GetTop() + lift <= barBottom + 1e-3, name .. ' is clear of the bar') end
				end
				check(F.window:GetTop() + lift - (look == 'blizzard' and st.ThemeArt.MetalAbove() or 0) <= barBottom + 1e-3, 'nothing of the window is under the bar')
				eq(st.config.global.optionsWindow.height, saved, 'the saved height is untouched')
				local off = P.off(F.window)
				eq(#off, 0, 'whole pixels: ' .. P.report(off))
				-- Detached: the window is as tall as it was saved (within the screen), back at its corner.
				EM:SetBarFloating(true)
				eq(F.window:GetHeight(), OW.WindowHeight(OW.S.layout), 'the height is the uncovered one again')
				check(F.window:GetHeight() >= height, 'taller than under the bar')
				eq(st.config.global.optionsWindow.height, saved, 'still saved')
				EM:SetBarFloating(false)
				check(F.window:GetHeight() <= UIParent:GetHeight() - cover - margin, 'docked again: under the bar')
				EM:Deactivate()
				eq(F.window:GetHeight(), OW.WindowHeight(OW.S.layout), 'edit mode ends: the height comes back')
				eq(st.config.global.optionsWindow.height, saved, 'and the save')
				st.config.profile.misc.clamp_inset = default
				st:UpdateScreenMargin()
				reset()
				eq(#take_errors(), 0, 'no errors')
			end)
		end
	end
end

test('a resize by the grip while the bar covers the top is limited to the room under it and saves the height chosen within it', function()
	reset()
	theme('thick')
	st.config.global.optionsWindow = { point = 'TOPRIGHT', x = 0, y = 0, height = 800 }
	st.Config:Open('Loot')
	local F = frames()
	EM:Activate()
	local cover = EM:BarCoverHeight()
	local most = UIParent:GetHeight() - cover - st.config.profile.misc.clamp_inset
	most = 2 * math.floor(most / 2)
	eq(OW.MaxHeight(), most, 'the most height is the room under the bar')
	drag_grip(F.grip, 100)
	eq(st.config.global.optionsWindow.height, 900, 'a drag within the room saves what was chosen')
	drag_grip(F.grip, 900)
	eq(F.window:GetHeight(), most, 'a drag past it stops at the room')
	eq(st.config.global.optionsWindow.height, most, 'and saves that')
	check(lift_of(F.window) == 0, 'the game pushes nothing back up')
	EM:Deactivate()
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('with edit mode off, a corner past the top of the screen is as it was saved, and a drag there is saved as dropped', function()
	reset()
	local default = st.config.profile.misc.clamp_inset
	st.config.profile.misc.clamp_inset = -20
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		theme(look)
		st.config.global.optionsWindow = { point = 'TOPRIGHT', x = 0, y = 10 }
		st.Config:Open('Loot')
		local F = frames()
		local _, _, _, _, y = F.window:GetPoint(1)
		eq(y, 10, look .. ': anchored where it was saved')
		stub.fire_script(F.header, 'OnDragStart')
		F.window:ClearAllPoints()
		F.window:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 300, 10)
		stub.fire_script(F.header, 'OnDragStop')
		eq(st.config.global.optionsWindow.y, 10, look .. ': a drop past the top is saved as it was')
		st.Config:Close()
	end
	st.config.profile.misc.clamp_inset = default
	reset()
	eq(#take_errors(), 0, 'no errors')
end)
