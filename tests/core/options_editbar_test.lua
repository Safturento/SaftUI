-- /sui under edit mode's docked bar (SaftUI-Core/Config/optionswindow.lua's
-- Anchor, CoverTop, S.BarCover and S.UpdateBarCover): while the bar is docked
-- and shown at the top of the screen and the window, in every size (the 42
-- tall bar above all), is under its rect (EM:BarRect) horizontally, the window
-- sits no higher than the bar's bottom, as a display offset only: the saved
-- corner is never changed by it, and the window is back at it when the bar
-- hides, detaches, slides clear or edit mode ends. Beside the bar (the two
-- rects do not overlap horizontally, even by a touching edge) the window is
-- not moved and has all the screen's height. With hide until hovered on the
-- bar covers nothing. A drag while offset saves the place it was dropped at,
-- never a doubled offset. Whole pixels throughout. The cases that are about
-- the offset itself slide the bar to the right end (reset), where the window,
-- saved at the top right, is under it.
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
	st.config.global.editModeBar = nil -- docked, shown, not hidden until hovered
	EM:SetBarFloating(false)
	EM:SetBarX(1e5) -- the right end of the top edge: the window saved at the top right is under it
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
		F.window:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', math.floor(UIParent:GetWidth() - F.window:GetWidth()), y) -- at the right end, under the bar
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


------------------------------------------------------------------ beside the bar, under it

local function window_left(F) return F.window:GetLeft() - UIParent:GetLeft() end
local function window_right(F) return F.window:GetRight() - UIParent:GetLeft() end

for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
	for _, size in ipairs({ 'full', 'half', 'mini' }) do
		test(('/sui beside the docked bar is not moved, under it it is, and it follows the bar sliding: %s, %s'):format(look, size), function()
			reset()
			theme(look)
			st.Config:Open('Loot')
			local F = frames()
			go(size)
			local saved_top = top_of(F)
			local max_height = OW.MaxHeight()
			EM:Activate()
			local bar = EM:GetBar()
			local rect = EM:BarRect()
			local cover = EM:BarCoverHeight()
			check(window_left(F) < rect.right and window_right(F) > rect.left, 'the bar is under the window at the right end')
			check(top_of(F) >= cover - 1e-3, 'under the bar: offset below it')
			local under_height = F.window:GetHeight()
			-- Slid to the left end, clear of the window: not offset, and no room taken from its height.
			EM:SetBarX(0)
			rect = EM:BarRect()
			check(rect.right <= window_left(F), 'the bar is clear of the window: ' .. rect.right .. ' vs ' .. window_left(F))
			eq(top_of(F), saved_top, 'beside the bar: where it was saved')
			if size ~= 'mini' then eq(F.window:GetHeight(), OW.WindowHeight(OW.S.layout), 'and as tall as it is saved, not limited to the room under the bar') end
			eq(OW.MaxHeight(), max_height, 'the most height is what it is with edit mode off: nothing taken for the bar')
			-- Back under it.
			EM:SetBarX(1e5)
			check(top_of(F) >= cover - 1e-3, 'slid under it again: offset')
			eq(F.window:GetHeight(), under_height, 'and its height is the one under the bar')
			local off = P.off(F.window)
			eq(#off, 0, 'whole pixels: ' .. P.report(off))
			EM:Deactivate()
			reset()
			eq(#take_errors(), 0, 'no errors')
		end)
	end
end

test('/sui is offset when the bar overlaps its horizontal extent by a pixel, and not when the two only touch', function()
	reset()
	theme('thick')
	st.Config:Open('Loot')
	local F = frames()
	go('full')
	local saved_top = top_of(F)
	EM:Activate()
	local bar = EM:GetBar()
	local inset = st:ThemeInset('theme', 'theme', 'panel')
	local width = bar:GetWidth()
	local left = window_left(F)
	-- The bar's rect (the line its backdrop draws included) ends at the window's left edge: touching.
	EM:SetBarX(left - width - inset)
	eq(EM:BarRect().right, left, 'the rect ends where the window starts')
	eq(top_of(F), saved_top, 'touching: not offset')
	EM:SetBarX(left - width - inset + 1)
	eq(EM:BarRect().right, left + 1, 'one pixel over')
	check(top_of(F) >= EM:BarCoverHeight() - 1e-3, 'overlapping by a pixel: offset')
	-- The same at the window's right end.
	local right = window_right(F)
	st.config.global.optionsWindow = { point = 'TOPRIGHT', x = -700, y = 0 }
	st.Config:Close(); st.Config:Open('Loot')
	F = frames()
	left, right = window_left(F), window_right(F)
	EM:SetBarX(right + inset)
	eq(EM:BarRect().left, right, 'the rect starts where the window ends')
	eq(top_of(F), 0, 'touching: not offset')
	EM:SetBarX(right + inset - 1)
	check(top_of(F) >= EM:BarCoverHeight() - 1e-3, 'one pixel over: offset')
	EM:Deactivate()
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('with hide until hovered on the bar covers nothing: /sui under it is not offset, hidden or down', function()
	reset()
	theme('thick')
	st.Config:Open('Loot')
	local F = frames()
	local saved_top = top_of(F)
	EM:Activate()
	check(top_of(F) >= EM:BarCoverHeight() - 1e-3, 'off: offset under the bar')
	local height = F.window:GetHeight()
	stub.cursor_x, stub.cursor_y = 0, 0
	stub.click(EM:BarControl('hide').frame)
	eq(EM:BarCoverHeight(), 0, 'on: no cover')
	eq(top_of(F), saved_top, 'the window is back where it was saved')
	check(F.window:GetHeight() >= height, 'and has its height')
	-- The bar comes down over it: nothing moves.
	local watch = EM.barWatch
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = (EM.barStrip:GetLeft() + 10) * scale, (UIParent:GetTop() - 2) * scale
	stub.time = stub.time + 1
	stub.fire_script(watch, 'OnUpdate', 0.016)
	check(EM:GetBar():IsShown(), 'down')
	eq(top_of(F), saved_top, 'it draws over /sui and /sui does not move')
	EM:Deactivate()
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('a drag beside the docked bar is saved where it was dropped, even up at the top edge', function()
	reset()
	st.Config:Open('Loot')
	local F = frames()
	EM:Activate()
	local function drop(x, y)
		stub.fire_script(F.header, 'OnDragStart')
		F.window:ClearAllPoints()
		F.window:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', x, y)
		stub.fire_script(F.header, 'OnDragStop')
	end
	drop(5, -5)
	eq(st.config.global.optionsWindow.y, -5, 'at the left end, clear of the bar (at the right end): saved as dropped')
	eq(UIParent:GetTop() - F.window:GetTop(), 5, 'and shown there')
	drop(math.floor(UIParent:GetWidth() - F.window:GetWidth()), -5)
	eq(UIParent:GetTop() - F.window:GetTop(), EM:BarCoverHeight(), 'dropped under the bar: below it')
	EM:Deactivate()
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('/sui offset under the bar sits on whole pixels at 1024, 1920 and 2560 wide, with the read-back noise up, down and off, under each look', function()
	local HAIR = 2 ^ -14
	reset()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		theme(look)
		st.Config:Open('Loot')
		local F = frames()
		EM:Activate()
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			stub.size_noise = noise
			for _, screen in ipairs({ { 1024, 768 }, { 1920, 1080 }, { 2560, 1440 } }) do
				stub.screen_width, stub.screen_height = screen[1], screen[2]
				UIParent:SetScale(768 / screen[2])
				stub.fire_event('DISPLAY_SIZE_CHANGED')
				EM:SetBarX(1e5)
				local where = ('%s noise %s at %d: '):format(look, noise, screen[1])
				check(top_of(F) >= EM:BarCoverHeight() - 1e-3, where .. 'under the bar: offset')
				local off = P.off(F.window)
				eq(#off, 0, where .. P.report(off))
				EM:SetBarX(0)
				off = P.off(F.window)
				eq(#off, 0, where .. 'beside it: ' .. P.report(off))
			end
		end
		EM:Deactivate()
		close_all()
	end
	stub.screen_width, stub.screen_height = 1920, 1080
	UIParent:SetScale(768 / 1080)
	reset()
	eq(#take_errors(), 0, 'no errors')
end)
