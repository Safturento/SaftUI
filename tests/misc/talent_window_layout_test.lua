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

-- Stand-ins: three trees in Blizzard's 400 wide regions, four columns each, one row.
local function make_frame(groupsOf)
	local window = CreateFrame('Frame', 'PlayerSpellsFrame', UIParent)
	window.talentsWidth = 1218
	window:SetSize(1218, 700)
	window.talentTabID, window.spellBookTabID = 1, 2
	window.tab = 1
	function window:GetTab() return self.tab end
	function window:UpdateSize()
		self:SetWidth(self.tab == 1 and self.talentsWidth or 1154)
	end
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
	-- Camelot's DividerHorizontalLeft and Right: atlas sized (here 600 wide, so
	-- 600 either side of the border's centre, wider than the narrowed window's
	-- 390), one ending at the border's centre, the other starting there.
	frame.DividerHorizontalLeft = frame:CreateTexture(nil, 'OVERLAY')
	frame.DividerHorizontalLeft:SetSize(600, 20)
	frame.DividerHorizontalLeft:SetPoint('RIGHT', frame.BackgroundBorder, 'CENTER')
	frame.DividerHorizontalLeft:SetTexCoord(0.1, 0.9, 0.2, 0.8)
	frame.DividerHorizontalRight = frame:CreateTexture(nil, 'OVERLAY')
	frame.DividerHorizontalRight:SetSize(600, 20)
	frame.DividerHorizontalRight:SetPoint('LEFT', frame.BackgroundBorder, 'CENTER')
	frame.DividerHorizontalRight:SetTexCoord(0.1, 0.9, 0.2, 0.8)
	frame.DividerVerticalLeft = CreateFrame('Frame', nil, frame)
	frame.DividerVerticalRight = CreateFrame('Frame', nil, frame)
	frame.DividerVerticalLeft:SetPoint('TOP', frame.BackgroundBorder, 'TOPLEFT', 402, -74)
	frame.DividerVerticalRight:SetPoint('TOP', frame.BackgroundBorder, 'TOPLEFT', 802, -74)
	for t = 0, 2 do
		for c = 0, 3 do
			local button = CreateFrame('Button', nil, parent)
			button:SetSize(40, 40)
			local info = { groupIDs = groupsOf and groupsOf(t, c) or { 11 + t }, posX = (70 + 400 * t + 60 * c + 49) * 10, posY = 1000 }
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

test('the horizontal dividers are cut off at the narrowed window\'s edges', function()
	local window, frame = make_frame()
	st.config.profile.talentwindow.compact = true
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	-- the layout's width is 780: 390 each side of the centre
	local left, right = frame.DividerHorizontalLeft, frame.DividerHorizontalRight
	eq(left:GetWidth(), 390, 'left ends at the left edge')
	eq(right:GetWidth(), 390, 'right ends at the right edge')
	eq(left:GetHeight(), 20, 'height kept')
	-- the art is cropped, not squashed: the outer 210 of 600 (0.35 of the 0.8 span) is cut
	local ulx, uly, llx, lly, urx, ury, lrx, lry = left:GetTexCoord()
	near(ulx, 0.1 + 0.8 * (210 / 600)); near(urx, 0.9); eq(uly, 0.2); eq(lly, 0.8)
	ulx, uly, llx, lly, urx, ury, lrx, lry = right:GetTexCoord()
	near(ulx, 0.1); near(urx, 0.9 - 0.8 * (210 / 600)); eq(ury, 0.2); eq(lry, 0.8)
	-- the inner ends stay on the centre
	local point, rel, relPoint = left:GetPoint()
	eq(point, 'RIGHT'); eq(rel, frame.BackgroundBorder); eq(relPoint, 'CENTER')
	-- a second pass crops from the same original, not the cropped one
	frame:LoadTalentTreeInternal()
	eq(left:GetWidth(), 390)
	near(select(1, left:GetTexCoord()), 0.1 + 0.8 * (210 / 600))
end)

test('a narrower divider loses the same 210, in proportion', function()
	local window, frame = make_frame()
	frame.DividerHorizontalLeft:SetWidth(300)
	st.config.profile.talentwindow.compact = true
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	eq(frame.DividerHorizontalLeft:GetWidth(), 90)
	near(select(1, frame.DividerHorizontalLeft:GetTexCoord()), 0.1 + 0.8 * (210 / 300))
end)

test('Revert puts the horizontal dividers back', function()
	local window, frame, buttons = make_frame()
	st.config.profile.talentwindow.compact = true
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	eq(frame.DividerHorizontalLeft:GetWidth(), 390)
	local n = 0
	for button in pairs(buttons) do
		n = n + 1
		local info = button:GetNodeInfo()
		local spread = { groupIDs = {}, posX = (70 + 400 * ((n - 1) % 3) + 100 * math.floor((n - 1) / 3) + 49) * 10, posY = info.posY }
		function button:GetNodeInfo() return spread end
	end
	frame:LoadTalentTreeInternal()
	for _, d in ipairs({ frame.DividerHorizontalLeft, frame.DividerHorizontalRight }) do
		eq(d:GetWidth(), 600, 'width back')
		local ulx, uly, _, lly, urx = d:GetTexCoord()
		near(ulx, 0.1); near(urx, 0.9); eq(uly, 0.2); eq(lly, 0.8)
	end
end)

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
	eq(hx, 330, 'header keeps Blizzard\'s offset in its region')
	local _, _, _, dx = frame.DividerVerticalLeft:GetPoint()
	eq(dx, 262)
	-- 3 * 400 - 780 = 420 narrower
	eq(frame:GetWidth(), 1212 - 420)
	eq(window:GetWidth(), 1218 - 420)
	window:UpdateSize()
	eq(window:GetWidth(), 1218 - 420, 'UpdateSize keeps the narrow width')
end)

-- Forever's nodes don't carry their spec as groupIDs[1]: a node can be in
-- groups of its own (gates, choice sets), or none. The tree is the 400 wide
-- region Blizzard put the node in, so grouping never follows groupIDs.
local function expect_compact(groupsOf, label)
	local window, frame, buttons = make_frame(groupsOf)
	st.config.profile.talentwindow.compact = true
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	local xs = centers(buttons)
	eq(xs[1], 40, label)
	eq(xs[12], 740, label)
	eq(frame:GetWidth(), 1212 - 420, label)
	eq(window:GetWidth(), 1218 - 420, label)
end

test('a group of its own on every node still gives three trees', function()
	local n = 0
	expect_compact(function() n = n + 1; return { 900 + n } end, 'own groups')
end)

test('nodes with no group, or one group across specs, still give three trees', function()
	expect_compact(function() return {} end, 'no groups')
	expect_compact(function() return { 5 } end, 'one shared group')
end)

test('the window is never narrowed to nothing', function()
	local window, frame = make_frame()
	st.config.profile.talentwindow.compact = true
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	check(frame:GetWidth() > 0 and window:GetWidth() > 0)
	frame:LoadTalentTreeInternal()
	window:UpdateSize()
	eq(frame:GetWidth(), 1212 - 420, 'a second pass narrows no further')
	eq(window:GetWidth(), 1218 - 420)
end)

test('a pass the layout can\'t use puts Blizzard\'s layout back', function()
	local window, frame, buttons = make_frame()
	st.config.profile.talentwindow.compact = true
	local _, _, _, blizzardDivider = frame.DividerVerticalLeft:GetPoint()
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	eq(frame:GetWidth(), 1212 - 420, 'first pass compacts')
	-- Next pass: the talents are spread so wide the layout would not narrow.
	for button in pairs(buttons) do
		local info = button:GetNodeInfo()
		local spread = { groupIDs = {}, posX = info.posX, posY = info.posY }
		function button:GetNodeInfo() return spread end
	end
	local n = 0
	for button in pairs(buttons) do
		n = n + 1
		local info = button:GetNodeInfo()
		info.posX = (70 + 400 * ((n - 1) % 3) + 100 * math.floor((n - 1) / 3) + 49) * 10
	end
	frame:LoadTalentTreeInternal()
	window:UpdateSize()
	for button in pairs(buttons) do
		local _, _, _, x = button:GetPoint()
		eq(x, button:GetNodeInfo().posX / 10 - 49, 'talent at Blizzard\'s x')
	end
	eq(frame:GetWidth(), 1212, 'talents frame back to Blizzard\'s width')
	eq(window:GetWidth(), 1218, 'window back to Blizzard\'s width')
	local _, _, _, x = frame.DividerVerticalLeft:GetPoint()
	eq(x, blizzardDivider, 'divider back')
end)

test('the spellbook keeps Blizzard width', function()
	local window, frame = make_frame()
	st.config.profile.talentwindow.compact = true
	TW.frame = nil
	TW:Install()
	frame:LoadTalentTreeInternal()
	window.tab = 2 -- the spellbook shows while the talents frame is still shown
	window:UpdateSize()
	eq(window:GetWidth(), 1154)
end)

test('an error in a hook does not reach Blizzard', function()
	local window, frame = make_frame()
	st.config.profile.talentwindow.compact = true
	TW.frame = nil
	TW:Install()
	local old = TW.Apply
	TW.Apply = function() error('boom') end
	local handler = geterrorhandler()
	seterrorhandler(function() end)
	local ok = pcall(frame.LoadTalentTreeInternal, frame)
	seterrorhandler(handler)
	TW.Apply = old
	check(ok, 'LoadTalentTreeInternal still returns')
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

test('on retail nothing is hooked and the width is Blizzard\'s', function()
	use_client('retail')
	load_core_helpers()
	apply_defaults()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsLayout.lua')
	st = SaftUI
	TW = st:GetModule('TalentWindow')
	local window, frame, buttons = make_frame()
	st.config.profile.talentwindow.compact = true
	local isLoaded = C_AddOns.IsAddOnLoaded
	C_AddOns.IsAddOnLoaded = function(name) return name == 'Blizzard_PlayerSpells' or isLoaded(name) end
	TW:OnEnable()
	C_AddOns.IsAddOnLoaded = isLoaded
	frame:LoadTalentTreeInternal()
	window:UpdateSize()
	eq(TW.frame, nil, 'not installed')
	eq(centers(buttons)[1], 70, 'talents where Blizzard puts them')
	eq(frame:GetWidth(), 1212)
	eq(window:GetWidth(), 1218)
end)
