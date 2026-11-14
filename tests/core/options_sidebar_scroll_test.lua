-- The /sui window's sidebar toggle and the sidebar's scroll
-- (SaftUI-Core/Config/optionsnav.lua): with twenty pages in the sidebar, so
-- that its list scrolls, collapsing and showing it again keep the page's and
-- the list's offsets exactly. A file of its own: its pages would make the
-- sidebar scroll in every case of options_sidebar_test.lua, where the whole
-- pixel checks read the list's scroll child, whose height the stub gives noise.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OW = st.OptionsWindow
local theme, close_all, frames, click = H.theme, H.close_all, H.frames, H.click

local function wait() stub.time = stub.time + 0.31 end

local function reset()
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
end

-- Twenty small pages, so the sidebar's list scrolls.
for i = 1, 20 do
	local module = st:NewModule('SideN' .. i)
	function module:GetConfigTable()
		return {
			name = 'Side page ' .. i, type = 'group', category = 'Frames', order = 100 + i,
			args = { general = { name = 'General', type = 'group', args = {
				on = { type = 'toggle', name = 'Side ' .. i .. ' on', get = function() return true end, set = function() end },
			} } },
		}
	end
end

-- Sixty toggles: a page that scrolls.
local manyValue = {}
local MANY = st:NewModule('SideMany')
function MANY:GetConfigTable()
	local args = {}
	for i = 1, 60 do
		args['t' .. i] = { order = i, type = 'toggle', name = 'Toggle ' .. i, desc = 'Toggle ' .. i,
			get = function() return manyValue[i] end, set = function(_, v) manyValue[i] = v end }
	end
	return { name = 'Many', type = 'group', category = 'Frames', args = args }
end

test("the page's and the nav's scroll are kept exactly across a collapse", function()
	reset()
	st.Config:Open('SideMany')
	local F, S = frames(), OW.S
	S.SetScroll(240)
	check(S.navHeight > F.navFrame:GetHeight(), 'the sidebar scrolls')
	S.SetNavScroll(37)
	eq(S.navOffset, 37)
	local page, nav = F.body:GetVerticalScroll(), F.navFrame:GetVerticalScroll()
	eq(page, 240)
	click(F.sideToggle)
	eq(S.scrollOffset, 240, 'the page is kept'); eq(F.body:GetVerticalScroll(), page)
	eq(S.navOffset, 37, "the nav's offset is kept")
	click(F.sideToggle)
	eq(S.scrollOffset, 240); eq(F.body:GetVerticalScroll(), page)
	eq(S.navOffset, 37); eq(F.navFrame:GetVerticalScroll(), nav, "the nav's scroll comes back as it was")
	-- At half too.
	wait(); OW:SetWindowSize('half')
	S.SetScroll(100); S.SetNavScroll(11)
	click(F.sideToggle); click(F.sideToggle)
	eq(S.scrollOffset, 100); eq(S.navOffset, 11)
	-- The grip's resize while collapsed leaves the nav's offset be.
	click(F.sideToggle)
	S.SetNavScroll(11)
	F.navFrame:SetHeight(F.navFrame:GetHeight()) -- a hidden frame's view
	S.SetNavScroll(500)
	eq(S.navOffset, 11, 'a nav offset is not taken while its sidebar is hidden')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

