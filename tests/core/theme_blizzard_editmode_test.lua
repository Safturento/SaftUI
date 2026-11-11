-- Edit Mode's outlines and picker list under the Blizzard theme
-- (SaftUI-Core/EditMode/mover.lua and picker.lua, with theme.lua and
-- themeart.lua):
--   - a mover's overlay is a control: under Thick and Thin SaftUI's line and
--     the blue fill of the selected one, and under Blizzard nothing of
--     SaftUI's but Edit Mode's own selection art, drawn on the overlay by
--     mover.lua: the highlight kit on every mover, and the selected kit, in
--     its place, on the one selected, laid out as Blizzard's
--     EditModeSystemSelectionLayout lays it;
--   - a switch of theme reaches the overlays (the colors pass that follows
--     every redraw), and the outline's outset, which snapping measures by,
--     doesn't change with it;
--   - the picker's list is drawn as a tooltip.
--
-- Real: Core's helpers, theme.lua and themeart.lua, and the Edit Mode files in
-- EditMode/load.xml's order.
load_core_helpers()
local T = load_test_file('lib/theme_helpers.lua')
for _, file in ipairs({ 'editmode', 'mover', 'picker', 'footer', 'grid', 'snap', 'settings' }) do
	load_saftui('SaftUI-Core/EditMode/' .. file .. '.lua')
end
local drawn = T.watch()

local st = SaftUI
local EM = st.EditModeFrames
local profile = st.config.profile

-- Registers a mover for a frame, as a module would.
local function add_mover(key)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	frame:SetPoint('CENTER')
	local position = { point = 'CENTER', x_off = 0, y_off = 0 }
	return st:RegisterMover(key, {
		frame = frame,
		getPosition = function() return position end,
		setPosition = function(pos) position = pos end,
		apply = function() end,
	})
end

-- A switch of SaftUI's theme as Config:UpdateConfig runs it: every drawn frame
-- redrawn, then the modules color what they color themselves.
local function switch(name)
	profile.theme.name = name
	st:RedrawThemed()
	st:ColorsChanged('theme')
end

-- Edit Mode's pieces shown on an overlay, as 'atlas' entries sorted, for the
-- ones that are its selection art.
local function kit_pieces(overlay)
	local out = {}
	for _, region in ipairs({ overlay:GetRegions() }) do
		local atlas = region:GetObjectType() == 'Texture' and region:GetAtlas()
		if atlas and atlas:find('editmode%-actionbar') and region:IsShown() then out[#out + 1] = atlas end
	end
	table.sort(out)
	return out
end

local function kit_of(overlay)
	local pieces = kit_pieces(overlay)
	local kits = {}
	for _, atlas in ipairs(pieces) do kits[atlas:match('editmode%-actionbar%-(%a+)')] = true end
	local names = {}
	for kit in pairs(kits) do names[#names + 1] = kit end
	table.sort(names)
	return table.concat(names, '+'), #pieces
end

local function piece(overlay, atlas)
	for _, region in ipairs({ overlay:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:GetAtlas() == atlas and region:IsShown() then return region end
	end
end

test("under Blizzard a mover shows Blizzard's highlight kit, and the selected kit while selected", function()
	profile.theme.name = 'thick'
	local mover = add_mover('first')
	local other = add_mover('second')
	local overlay = mover.overlay
	local backdrop = overlay.backdrop

	-- Thick: SaftUI's line, white, and the dim fill; no Blizzard art.
	eq(drawn(overlay), 'theme,solid,control', 'the overlay is a control')
	eq(T.inset(backdrop), 2, "Thick: drawn as a small frame, SaftUI's line")
	eq(T.edge(backdrop), '1.00,1.00,1.00,1.00', 'Thick: a white line')
	eq(T.fill(backdrop), '0.00,0.00,0.00,0.30', 'and the dim fill')
	eq(kit_of(overlay), '', 'Thick: no selection art')

	switch('blizzard')
	local kit, count = kit_of(overlay)
	eq(kit, 'highlight', "Blizzard: the highlight kit on every mover")
	eq(count, 9, 'its four corners, four edges and its fill')
	eq(kit_of(other.overlay), 'highlight', 'on the other too')
	eq(T.art(backdrop) .. T.over(backdrop), '', "and none of SaftUI's own art")
	eq(backdrop.backdropInfo, nil, 'with no line or fill')
	local corner = 'editmode-actionbar-highlight-NineSlice-Corner'
	local top_left = piece(overlay, corner)
	check(top_left ~= nil, 'the corner shows')

	-- The layout: a corner atlas mirrored into the four corners, 8px outside
	-- the frame; edges between them, tiled; the fill between the corners.
	local function corners()
		local out = {}
		for _, region in ipairs({ overlay:GetRegions() }) do
			if region:GetObjectType() == 'Texture' and region:GetAtlas() == corner and region:IsShown() then
				local point, rel, _, x, y = region:GetPoint(1)
				out[#out + 1] = ('%s %s,%s %s'):format(point, T.text(x, y), tostring(rel == overlay),
					T.text(region:GetTexCoord()))
			end
		end
		table.sort(out)
		return table.concat(out, ' | ')
	end
	eq(corners(), table.concat({
		'BOTTOMLEFT -8.00,-8.00,true ' .. T.text(0, 1, 0, 0, 1, 1, 1, 0),
		'BOTTOMRIGHT 8.00,-8.00,true ' .. T.text(1, 1, 1, 0, 0, 1, 0, 0),
		'TOPLEFT -8.00,8.00,true ' .. T.text(0, 0, 0, 1, 1, 0, 1, 1),
		'TOPRIGHT 8.00,8.00,true ' .. T.text(1, 0, 1, 1, 0, 0, 0, 1),
	}, ' | '), 'a corner at each corner, mirrored, 8px out')
	local edge = piece(overlay, '_editmode-actionbar-highlight-NineSlice-EdgeTop')
	check(edge ~= nil and edge:GetHorizTile() and not edge:GetVertTile(), 'the top edge tiles across')
	edge = piece(overlay, '!editmode-actionbar-highlight-NineSlice-EdgeLeft')
	check(edge ~= nil and edge:GetVertTile() and not edge:GetHorizTile(), 'the left edge tiles down')
	local fill = piece(overlay, 'editmode-actionbar-highlight-NineSlice-Center')
	check(fill ~= nil, 'the fill shows')
	if fill then
		eq(T.offset(fill, 'TOPLEFT') .. ' ' .. T.offset(fill, 'BOTTOMRIGHT'), '-8.00,8.00 8.00,-8.00',
			"the fill runs between the corners' inner points, 8px back out")
	end

	-- The outline measures the same under every theme.
	eq(EM.OutlineOutset(), 1, "snapping's outline stays SaftUI's small frame's border")

	-- Selected: the selected kit in its place, on that mover only.
	EM:Select(mover)
	kit, count = kit_of(overlay)
	eq(kit, 'selected', 'selected: the selected kit, instead')
	eq(count, 9, 'all nine')
	eq(kit_of(other.overlay), 'highlight', 'the other still has the highlight')
	EM:Select(other)
	eq(kit_of(overlay), 'highlight', 'unselected: the highlight again')
	eq(kit_of(other.overlay), 'selected', 'and the other is selected')

	-- Back to Thick: SaftUI's line and blue, and no art.
	switch('thick')
	eq(kit_of(overlay) .. '/' .. kit_of(other.overlay), '/', 'Thick again: no selection art on either')
	eq(T.inset(backdrop), 2, "SaftUI's line is back")
	eq(T.edge(backdrop), '1.00,1.00,1.00,1.00', 'white')
	eq(T.fill(backdrop), '0.00,0.00,0.00,0.30', 'with the dim fill')
	local blue = T.text(st.config.profile.colors.button.blue:GetRGB())
	eq(T.edge(other.overlay.backdrop), blue .. ',1.00', 'the selected one: a blue line')
	eq(T.fill(other.overlay.backdrop), blue .. ',0.15', 'and its blue fill')

	-- And Blizzard once more reuses the pieces it made.
	switch('blizzard')
	eq(kit_of(other.overlay), 'selected', 'Blizzard again: the selected one wears the selected kit')
	eq(kit_of(overlay), 'highlight', 'the other the highlight')
	local before = #({ overlay:GetRegions() })
	switch('thick')
	switch('blizzard')
	eq(#({ overlay:GetRegions() }), before, 'a switch makes no new pieces')

	EM:Select(nil)
	switch('thick')
end)

test('the picker list is drawn as a tooltip', function()
	local lists = {}
	local draw = st.SetBackdrop
	st.SetBackdrop = function(self, frame, theme, background, kind)
		if kind == 'tooltip' then lists[#lists + 1] = frame end
		return draw(self, frame, theme, background, kind)
	end
	EM:Fire('Enabled')
	st.SetBackdrop = draw
	eq(#lists, 1, 'one frame is drawn as a tooltip')
	eq(drawn(lists[1]), 'theme,solid,tooltip', "in SaftUI's theme, solid")
	EM:Fire('Disabled')
end)
