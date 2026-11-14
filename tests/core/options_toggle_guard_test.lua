-- The sidebar toggle's double click (SaftUI-Core/Config/optionsnav.lua,
-- S.GuardToggleSpot): the toggle moves when it is clicked (the sidebar's foot
-- to the footer's left and back), so a second click of a double click lands
-- where it was, not on it. For OW.SIZE_GUARD after a change a small frame of
-- the window's own with the mouse (F.toggleGuard) sits on the old spot and
-- takes that click, and the toggle at its new spot ignores clicks for the same
-- time. The frame hides when the guard ends, on a relayout and when the window
-- hides. Both directions, both looks, whole pixels.
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local OW = st.OptionsWindow
local theme, close_all, frames, click = H.theme, H.close_all, H.frames, H.click
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

local function wait() stub.time = stub.time + 0.31 end

local function centre(f)
	local x, y = f:GetCenter()
	return x, y
end

-- Whether (x, y) is inside frame's rect.
local function inside(f, x, y)
	return x >= f:GetLeft() and x <= f:GetRight() and y >= f:GetBottom() and y <= f:GetTop()
end

for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
	for _, size in ipairs({ 'full', 'half' }) do
		test(('a double click on the toggle: the old spot takes the second click, and so does the new one: %s, %s'):format(look, size), function()
			st.config.global.optionsWindow = nil
			close_all()
			theme(look)
			st.Config:Open('Loot')
			if size == 'half' then wait(); OW:SetWindowSize('half') end
			local F = frames()
			wait()
			for _, direction in ipairs({ 'collapse', 'show' }) do
				local x, y = centre(F.sideToggle)
				local before = OW:IsSidebarShown()
				click(F.sideToggle)
				eq(OW:IsSidebarShown(), not before, direction .. ': the first click changes it')
				local g = F.toggleGuard
				check(g and g:IsShown() and g:IsMouseEnabled(), direction .. ': a frame takes the mouse where the toggle was')
				check(inside(g, x, y), direction .. ': the old centre is inside it')
				check(not inside(F.sideToggle, x, y), direction .. ': and the toggle is elsewhere now')
				check(g:GetFrameLevel() > F.sideToggle:GetFrameLevel() and g:GetFrameLevel() > F.window:GetFrameLevel(),
					direction .. ': above the window\'s own frames')
				local off = P.off(F.window)
				eq(#off, 0, direction .. ': whole pixels: ' .. P.report(off))
				-- The toggle at its new spot ignores a click now.
				click(F.sideToggle)
				eq(OW:IsSidebarShown(), not before, direction .. ': its click inside the guard does nothing')
				stub.time = stub.time + 0.29
				stub.fire_script(g, 'OnUpdate', 0.29)
				check(g:IsShown(), direction .. ': the guard lasts OW.SIZE_GUARD')
				stub.time = stub.time + 0.02
				stub.fire_script(g, 'OnUpdate', 0.02)
				check(not g:IsShown(), direction .. ': and ends')
				-- The next click works (it goes back, which the loop's next round does).
			end
			eq(#take_errors(), 0, 'no errors')
			close_all()
		end)
	end
end

test('the guard frame hides on a relayout and when the window hides, and is made once', function()
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
	st.Config:Open('Loot')
	local F = frames()
	wait(); click(F.sideToggle)
	local g = F.toggleGuard
	check(g:IsShown(), 'up')
	wait(); OW:SetWindowSize('half')
	check(not g:IsShown(), 'a size change (a relayout) hides it')
	wait(); click(F.sideToggle)
	check(g:IsShown(), 'up again')
	eq(F.toggleGuard, g, 'the same frame')
	theme('blizzard')
	check(not g:IsShown(), 'a look change hides it')
	wait(); click(F.sideToggle)
	check(g:IsShown(), 'and again')
	st.Config:Close()
	check(not g:IsShown(), 'closing the window hides it')
	st.Config:Open('Loot')
	check(not frames().toggleGuard:IsShown(), 'it is not up when the window opens')
	-- At the bar nothing is guarded: the toggle is not there.
	wait(); OW:SetWindowSize('mini')
	wait(); OW:SetSidebarShown(false)
	check(not frames().toggleGuard:IsShown(), 'no toggle at the bar, so no guard')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)
