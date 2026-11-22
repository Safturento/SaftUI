-- A compact talent window (the owner's request: "there's so much empty space
-- currently on the frame"). Blizzard lays each spec's tree out in a 400 wide
-- region (Camelot's TREE_HEADER_SPACING_X) whatever the tree needs, so the
-- talents sit far from the dividers between the specs and from the window's
-- sides. This moves each talent sideways so the gap between a talent and a
-- divider (or the window's side) is the gap between talents, moves the tree
-- headers and the vertical dividers to match, and narrows the window by what
-- that saved.
--
-- Post-hooks and plain methods only (.agents/taint.md rules 1 to 3): nothing is
-- written onto a Blizzard frame or table (SaftUI's own state is in locals), no
-- Blizzard function is called but reads, and the window's own width is the one
-- Blizzard sets itself (SetWidth on PlayerSpellsFrame and TalentsFrame, neither
-- protected; nothing in the window is secure). Blizzard's positions are never
-- read back after a shift: they come from each button's node info (posX) and
-- the pan offset, the same numbers ApplyPosition uses.
--
-- Off (talentwindow.compact false): nothing is moved. A /reload puts Blizzard's
-- layout back, a window already shown keeps the compact one until then.
local st = SaftUI
local TW = st:NewModule('TalentWindow')

-- Camelot's ClassTalentsFrameMixin:RefreshTreeHeaders spaces the trees 400 apart
-- (TREE_HEADER_SPACING_X), and the Background border starts 2 left of the frame
-- (Camelot ClassTalents XML: BackgroundBorder is ClassBackground -2, ButtonsParent
-- sits at the frame's left with leftPadding 0).
local BLIZZARD_REGION = 400
local BORDER_INSET = 2
-- Blizzard puts a header's CENTER (icon and name together) 140 in from its
-- region's left (TREE_HEADER_OFFSET_X); kept, so the header sits in its region
-- as it does in Blizzard's.
local HEADER_OFFSET = 140

-- The pure part. trees: a list, left to right, of lists of button center x
-- offsets (Blizzard's, from ButtonsParent's TOPLEFT); size: the button width.
function TW.Layout(trees, size)
	local all, count = {}, 0
	for _, xs in ipairs(trees) do
		for _, x in ipairs(xs) do
			all[#all + 1] = x
			count = count + 1
		end
	end
	if count == 0 then return nil end
	table.sort(all)
	-- Distinct values (within half a pixel) and the smallest step between them.
	local distinct = { all[1] }
	local pitch
	for i = 2, #all do
		local step = all[i] - distinct[#distinct]
		if step > 0.5 then
			distinct[#distinct + 1] = all[i]
			if not pitch or step < pitch then pitch = step end
		end
	end
	if #distinct < 2 then return nil end

	local gap = pitch - size
	local cols = 0
	local mins = {}
	for i, xs in ipairs(trees) do
		local sorted = {}
		for _, x in ipairs(xs) do sorted[#sorted + 1] = x end
		table.sort(sorted)
		local n, lo = 0, sorted[1]
		for j, x in ipairs(sorted) do
			if j == 1 or x - sorted[j - 1] > 0.5 then n = n + 1 end
		end
		mins[i] = lo
		if n > cols then cols = n end
	end
	local region = cols * size + (cols - 1) * gap + 2 * gap
	local dx, dividers = {}, {}
	for i = 1, #trees do
		if mins[i] then dx[i] = (i - 1) * region + gap + size / 2 - mins[i] end
		if i < #trees then dividers[i] = i * region end
	end
	return { gap = gap, pitch = pitch, cols = cols, region = region, dx = dx, dividers = dividers, width = #trees * region }
end

local function Enabled()
	local config = st.config and st.config.profile and st.config.profile.talentwindow
	return config and config.compact
end

-- The layout the last Apply made: { layout =, index = { [groupID] = tree } }.
local current

-- Each button's tree and Blizzard's x, as { button =, group =, x = } (heroes and
-- buttons without a group are left alone).
local function Read(frame)
	local panX = frame:GetPanOffset()
	local entries = {}
	for button in frame:EnumerateAllTalentButtons() do
		local info = button:GetNodeInfo()
		local group = info and not info.subTreeID and info.groupIDs and info.groupIDs[1]
		if group and info.posX then
			entries[#entries + 1] = { button = button, group = group, x = info.posX / 10 - panX }
		end
	end
	return entries
end

local function Compute(entries, size)
	local sums, byGroup = {}, {}
	for _, e in ipairs(entries) do
		local g = byGroup[e.group]
		if not g then
			g = { group = e.group, xs = {}, sum = 0 }
			byGroup[e.group] = g
			sums[#sums + 1] = g
		end
		g.xs[#g.xs + 1] = e.x
		g.sum = g.sum + e.x
	end
	table.sort(sums, function(a, b)
		local ma, mb = a.sum / #a.xs, b.sum / #b.xs
		if ma ~= mb then return ma < mb end
		return a.group < b.group
	end)
	local trees, index = {}, {}
	for i, g in ipairs(sums) do
		trees[i] = g.xs
		index[g.group] = i
	end
	local layout = TW.Layout(trees, size)
	if not layout then return nil end
	return { layout = layout, index = index }
end

local function SetX(region, x)
	local point, rel, relPoint, oldX, y = region:GetPoint()
	if not point or math.abs((oldX or 0) - x) < 0.01 then return end
	region:SetPoint(point, rel, relPoint, x, y)
end

-- The tree headers over their regions and the vertical dividers on the borders.
local function PlaceDecor(frame, layout)
	if not layout then return end
	if frame.treeHeaders then
		for i, header in ipairs(frame.treeHeaders) do
			if i <= #layout.dx then SetX(header, (i - 0.5) * layout.region + BORDER_INSET + (HEADER_OFFSET - (BLIZZARD_REGION / 2 + BORDER_INSET))) end
		end
	end
	local border = frame.BackgroundBorder
	local left, right = frame.DividerVerticalLeft, frame.DividerVerticalRight
	local horizontal = frame.DividerHorizontalLeft
	if not (border and horizontal) then return end
	-- Blizzard hangs these 60 under the horizontal dividers' centre; the same
	-- height, on the region borders, from the border's top left.
	local top = -4 - horizontal:GetHeight() / 2 - 60
	for i, divider in ipairs({ left or false, right or false }) do
		if divider and layout.dividers[i] then
			divider:ClearAllPoints()
			divider:SetPoint('TOP', border, 'TOPLEFT', layout.dividers[i] + BORDER_INSET, top)
		end
	end
end

local baseWidth, appliedWidth
local function PlaceWidths(frame, layout)
	if not layout then return end
	local delta = #layout.dx * BLIZZARD_REGION - layout.width
	local width = frame:GetWidth()
	if appliedWidth and math.abs(width - appliedWidth) < 0.01 then width = baseWidth end
	baseWidth = width
	appliedWidth = width - delta
	frame:SetWidth(appliedWidth)
	current.delta = delta
	PlayerSpellsFrame:SetWidth((PlayerSpellsFrame.talentsWidth or PlayerSpellsFrame:GetWidth()) - delta)
end

function TW:Apply()
	local frame = self.frame
	if not frame or not Enabled() then return end
	local entries = Read(frame)
	local first = entries[1]
	local size = first and first.button:GetWidth() or 40
	if not size or size <= 0 then size = 40 end
	local result = Compute(entries, size)
	if not result then return end
	current = result
	local layout = result.layout
	for _, e in ipairs(entries) do
		local dx = layout.dx[result.index[e.group]]
		if dx then SetX(e.button, e.x + dx) end
	end
	PlaceWidths(frame, layout)
	PlaceDecor(frame, layout)
end

-- A hook runs in the middle of Blizzard's own code: an error in it would stop
-- the caller there, so each runs in xpcall to the error handler.
local function Guarded(fn)
	return function(...)
		local a, b = ...
		xpcall(function() fn(a, b) end, geterrorhandler())
	end
end

function TW:Install()
	local frame = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
	if not frame or self.frame then return end
	self.frame = frame
	hooksecurefunc(frame, 'UpdateTalentButtonPosition', Guarded(function(f, button)
		if not current or not Enabled() then return end
		local info = button:GetNodeInfo()
		local group = info and not info.subTreeID and info.groupIDs and info.groupIDs[1]
		local dx = group and current.layout.dx[current.index[group] or 0]
		if dx and info.posX then SetX(button, info.posX / 10 - (f:GetPanOffset()) + dx) end
	end))
	hooksecurefunc(frame, 'LoadTalentTreeInternal', Guarded(function() self:Apply() end))
	hooksecurefunc(frame, 'RefreshTreeHeaders', Guarded(function(f)
		if current and Enabled() then PlaceDecor(f, current.layout) end
	end))
	-- Blizzard sets the window's width on every show and tab change (the
	-- spellbook's OnShow calls it too); the narrower width goes back on after it
	-- only while the talents tab is the window's tab.
	hooksecurefunc(PlayerSpellsFrame, 'UpdateSize', Guarded(function(window)
		if not (current and current.delta and Enabled() and frame:IsShown()) then return end
		if window:GetTab() ~= window.talentTabID then return end
		window:SetWidth((window.talentsWidth or window:GetWidth()) - current.delta)
	end))
	if frame:IsShown() then xpcall(function() self:Apply() end, geterrorhandler()) end
end

function TW:OnEnable()
	st:OnBlizzardAddon('Blizzard_PlayerSpells', function() self:Install() end)
end
