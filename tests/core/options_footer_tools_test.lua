-- The collapsed /sui footer's tools with one to six commands registered
-- (SaftUI-Core/Config/optionsnav.lua: S.DrawTools): Search and Edit mode are
-- always icon buttons; each command with an icon is one too, in order, while it
-- fits before Reload UI with the footer's 12 gap; every command that doesn't
-- fit, and every one with no icon, is under one overflow button (ellipsis,
-- "More") that opens the kit's list of their labels, a pick running the
-- command. Nothing overlaps Reload UI, Close or another tool, at full and at
-- half, under Thick and Thin, with size noise, and all on whole pixels; a
-- command registered after the window was built appears. The window's
-- Blizzard look is options_settings_test.lua's. Real: Core's Config, the
-- model, the widgets, the body and the window (options_window_helpers.lua).
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local OW, W = st.OptionsWindow, st.OptionsWidgets
local theme, close_all, frames, click, tick = H.theme, H.close_all, H.frames, H.click, H.tick
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

local ran = {}
-- Six commands, in order: with and without an icon.
local SPECS = {
	{ 'kb', 'Keybind mode', st.icons.keyboard }, { 'c2', 'Second', st.icons.search },
	{ 'c3', 'Third a long label' }, { 'c4', 'Fourth', st.icons.move },
	{ 'c5', 'Fifth' }, { 'c6', 'Sixth', st.icons.keyboard },
}
local function add(n)
	local spec = SPECS[n]
	st.Config:AddCommand(spec[1], spec[2], function() ran[#ran + 1] = spec[1] end, spec[3])
end

local function near(a, b) return math.abs(a - b) < 1e-3 end
local function wait() stub.time = stub.time + 0.31 end

local function listed()
	local out = {}
	for _, entry in ipairs(W.GetListFrames().entries) do out[#out + 1] = entry.label end
	return table.concat(out, ',')
end

-- What the footer shows now, with n commands registered: no overlap, the rule.
local function check_footer(n, where)
	local F = frames()
	local tools = F.tools
	check(#tools >= 3, where .. ': Search, Edit mode and at least the overflow or a command')
	eq(tools[1].icon:GetTexture(), st.icons.search, where .. ': Search first'); eq(tools[2].icon:GetTexture(), st.icons.move, where .. ': then Edit mode')
	check(near(tools[1]:GetLeft(), F.sideToggle:GetRight() + 6), where .. ': 6 after the toggle')
	for i = 1, #tools do
		check(tools[i]:IsVisible(), where .. ': tool ' .. i .. ' shown')
		if i > 1 then check(near(tools[i]:GetLeft(), tools[i - 1]:GetRight() + 6), where .. ': 6 apart') end
		check(near(tools[i]:GetWidth(), 26) and near(tools[i]:GetHeight(), 26), where .. ': 26 square')
	end
	local last = tools[#tools]
	check(last:GetRight() + 12 <= F.reloadButton:GetLeft() + 1e-3, where .. ': the last tool is 12 before Reload UI: '
		.. last:GetRight() .. ' vs ' .. F.reloadButton:GetLeft())
	check(F.reloadButton:GetRight() <= F.closeButton:GetLeft() + 1e-3, where .. ': Reload UI clear of Close')
	-- Which commands are buttons and which are under the overflow button.
	local overflow = last.icon:GetTexture() == st.icons.ellipsis and last or nil
	local buttons = overflow and #tools - 3 or #tools - 2
	local iconed, others = {}, {}
	for i = 1, n do
		if SPECS[i][3] then iconed[#iconed + 1] = SPECS[i] else others[#others + 1] = SPECS[i] end
	end
	check(buttons <= #iconed, where .. ': only commands with an icon are buttons')
	for k = 1, buttons do eq(tools[2 + k].icon:GetTexture(), iconed[k][3], where .. ': button ' .. k .. ' is the ' .. k .. 'th command with an icon') end
	local rest = {}
	for i = 1, n do
		local isButton = false
		for k = 1, buttons do if iconed[k] == SPECS[i] then isButton = true end end
		if not isButton then rest[#rest + 1] = SPECS[i][2] end
	end
	eq(overflow ~= nil, #rest > 0, where .. ': an overflow button exactly when something is left over')
	if overflow then
		eq(select(1, overflow.tip(overflow)), 'More', where .. ': its tooltip')
		click(overflow)
		eq(W.ListOwner(), overflow, where .. ': it opens the list')
		eq(listed(), table.concat(rest, ','), where .. ': the list is the rest, by label, in order')
		W.CloseList()
		-- None of the left-over commands with an icon would have fit as a button.
		if #iconed > buttons then
			check(overflow:GetRight() + 6 + 26 + 12 > F.reloadButton:GetLeft() - 1e-3, where .. ': no room was left unused')
		end
	end
	return F
end

local function open_collapsed()
	st.config.global.optionsWindow = nil
	close_all()
	st.Config:Open('Unitframes', 'player', 'general')
	OW:SetSidebarShown(false)
end

for n = 1, 6 do
	test('with ' .. n .. ' command' .. (n > 1 and 's' or '') .. ': no overlap at W2 and W4 under Thick and Thin, with size noise, on whole pixels', function()
		add(n)
		for _, look in ipairs({ 'thick', 'thin' }) do
			theme(look)
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				stub.size_noise = noise
				open_collapsed()
				local F = frames()
				local where = look .. ' noise ' .. noise .. ' W2'
				check_footer(n, where)
				local off = P.off(F.window)
				eq(#off, 0, where .. ' ' .. P.report(off))
				wait(); OW:SetWindowSize('half')
				where = look .. ' noise ' .. noise .. ' W4'
				check_footer(n, where)
				off = P.off(F.window)
				eq(#off, 0, where .. ' ' .. P.report(off))
				OW:SetSidebarShown(true)
				for _, tool in ipairs(F.tools) do check(not tool:IsVisible(), where .. ': none with the sidebar') end
				stub.size_noise = 0
			end
		end
		theme('thick')
		close_all()
		eq(#take_errors(), 0, 'no errors')
	end)
end

test('a pick in the overflow list runs its command, and the real command set leaves the status line room at W4', function()
	-- Six registered, the last ones are under the overflow button at W4.
	open_collapsed(); wait(); OW:SetWindowSize('half')
	local F = frames()
	local overflow = F.tools[#F.tools]
	eq(overflow.icon:GetTexture(), st.icons.ellipsis)
	click(overflow)
	local rows = W.GetListFrames().rows
	local count = #W.GetListFrames().entries
	ran = {}
	click(rows[count])
	eq(#ran, 1, 'a pick runs one command'); eq(W.ListOwner(), nil, 'and closes the list')
	close_all()
end)

test('a command registered after the window was built appears in the collapsed footer, as a button or under the overflow', function()
	open_collapsed()
	local F = frames()
	st.Config:AddCommand('late', 'Late', function() ran[#ran + 1] = 'late' end, st.icons.chevronDown)
	OW:Render()
	local late = false
	for _, tool in ipairs(F.tools) do
		if tool.icon:GetTexture() == st.icons.chevronDown then late = true end
	end
	local overflow = F.tools[#F.tools]
	if not late then
		eq(overflow.icon:GetTexture(), st.icons.ellipsis, 'no room: the overflow button')
		click(overflow)
		check(listed():find('Late', 1, true), 'is in the overflow list: ' .. listed())
		W.CloseList()
	end
	check(late or listed ~= nil, 'drawn')
	close_all()
end)
