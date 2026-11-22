-- The compact talent window (SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsLayout.lua):
--   - TW.Layout: the gap between talents becomes the gap to the dividers and the
--     window's sides; every tree gets the widest tree's region; nil without
--     buttons or with one column;
--   - Apply on stand-ins for Blizzard's frames: each button moves by its tree's
--     dx, the headers and dividers follow, the window narrows; off moves nothing.
-- Real: Core's helpers, SaftUI-Misc's config.lua and the module. Blizzard's
-- talent frame is a stand-in built here.
reset_world()
load_core_helpers()
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsLayout.lua')
local st = SaftUI
local TW = st:GetModule('TalentWindow')

local function tree(start, cols)
	local xs = {}
	for c = 0, cols - 1 do xs[#xs + 1] = start + 60 * c end
	return xs
end

test('Layout evens the gaps', function()
	local l = TW.Layout({ tree(70, 4), tree(470, 4), tree(870, 4) }, 40)
	eq(l.gap, 20)
	eq(l.pitch, 60)
	eq(l.cols, 4)
	eq(l.region, 260)
	eq(l.dx[1], -30)
	eq(l.dx[2], -170)
	eq(l.dx[3], -310)
	eq(l.dividers[1], 260)
	eq(l.dividers[2], 520)
	eq(l.width, 780)
end)

test('Layout gives a narrow tree the same region', function()
	local l = TW.Layout({ tree(70, 4), tree(470, 2), tree(870, 4) }, 40)
	eq(l.cols, 4)
	eq(l.region, 260)
	eq(l.dx[2], -170)
end)

test('Layout is nil without buttons or columns', function()
	eq(TW.Layout({}, 40), nil)
	eq(TW.Layout({ {}, {} }, 40), nil)
	eq(TW.Layout({ { 70 } }, 40), nil)
end)

-- Stand-ins: three trees of group ids 11, 12, 13, four columns each, one row.
local function make_frame()
	local window = CreateFrame('Frame', 'PlayerSpellsFrame', UIParent)
	window.talentsWidth = 1218
	window:SetSize(1218, 700)
	function window:UpdateSize() self:SetWidth(self.talentsWidth) end
	local frame = CreateFrame('Frame', nil, window)
	window.TalentsFrame = frame
	frame:SetSize(1212, 681)
	local parent = CreateFrame('Frame', nil, frame)
	frame.ButtonsParent = parent
	local buttons = {}
	function frame:GetPanOffset() return 49, 24 end
	function frame:EnumerateAllTalentButtons() return pairs(buttons) end
	function frame:UpdateTalentButtonPosition(button)
		local info = button:GetNodeInfo()
		button:ClearAllPoints()
		button:SetPoint('CENTER', parent, 'TOPLEFT', info.posX / 10 - 49, -info.posY / 10 + 24)
	end
	function frame:LoadTalentTreeInternal()
		for button in pairs(buttons) do self:UpdateTalentButtonPosition(button) end
	end
	function frame:RefreshTreeHeaders()
		self.treeHeaders = {}
		for i = 1, 3 do
			local header = CreateFrame('Frame', nil, self)
			header:SetPoint('CENTER', self.BackgroundBorder, 'TOPLEFT', 140 + (i - 1) * 400, -100)
			self.treeHeaders[i] = header
		end
	end
	frame.BackgroundBorder = CreateFrame('Frame', nil, frame)
	frame.DividerHorizontalLeft = CreateFrame('Frame', nil, frame)
	frame.DividerHorizontalLeft:SetSize(100, 20)
	frame.DividerVerticalLeft = CreateFrame('Frame', nil, frame)
	frame.DividerVerticalRight = CreateFrame('Frame', nil, frame)
	for t = 0, 2 do
		for c = 0, 3 do
			local button = CreateFrame('Button', nil, parent)
			button:SetSize(40, 40)
			local info = { groupIDs = { 11 + t }, posX = (70 + 400 * t + 60 * c + 49) * 10, posY = 1000 }
			function button:GetNodeInfo() return info end
			buttons[button] = true
		end
	end
	frame:RefreshTreeHeaders()
	return window, frame, buttons
end

local function centers(buttons)
	local out = {}
	for button in pairs(buttons) do
		local _, _, _, x = button:GetPoint()
		out[#out + 1] = x
	end
	table.sort(out)
	return out
end

test('Apply moves the talents, headers and dividers and narrows the window', function()
	local window, frame, buttons = make_frame()
	st.config.profile.talentwindow.compact = true
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	local xs = centers(buttons)
	eq(xs[1], 40)
	eq(xs[4], 220)
	eq(xs[5], 300)
	eq(xs[12], 740) -- 2 * 260 + 40 + 3 * 60
	local _, _, _, hx = frame.treeHeaders[2]:GetPoint()
	eq(hx, 1.5 * 260 + 2)
	local _, _, _, dx = frame.DividerVerticalLeft:GetPoint()
	eq(dx, 262)
	-- 3 * 400 - 780 = 420 narrower
	eq(frame:GetWidth(), 1212 - 420)
	eq(window:GetWidth(), 1218 - 420)
	window:UpdateSize()
	eq(window:GetWidth(), 1218 - 420, 'UpdateSize keeps the narrow width')
end)

test('compact off moves nothing', function()
	local window, frame, buttons = make_frame()
	st.config.profile.talentwindow.compact = false
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	local xs = centers(buttons)
	eq(xs[1], 70)
	eq(frame:GetWidth(), 1212)
	eq(window:GetWidth(), 1218)
end)
