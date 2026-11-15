-- Edit mode's alignment grid (SaftUI-Core/EditMode/grid.lua) and its
-- settings (settings.lua): the line math, the grid's center, drawing and the
-- line pool, redraws, EM:SetSetting and EM:SetGridSize (which tell the grid
-- through 'SettingsChanged'), the screen events and the /sui options. Migrated from the emsim harness (test_grid.lua). The cases share
-- one world and run in order, each going on from the state the last left.

load_core_helpers() -- panels, fonts and the profile defaults
load_editmode()

local st = SaftUI
local EM = st.EditModeFrames
local settings = EM:GetSettings()

-- set_screen: a screen of width x height physical pixels, at the scale SaftUI
-- sets at login (one UIParent unit per pixel).
local EMH = load_test_file('core/editmode_helpers.lua')
local set_screen = EMH.set_screen

local function eqlist(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- The grid's lines that are showing. Lines are pooled textures on the grid
-- frame; a vertical line is placed by its TOPLEFT x offset, a horizontal one
-- by its BOTTOMLEFT y offset.
local function shownLines()
	local lines = {}
	for _, region in ipairs({ EM.gridFrame:GetRegions() }) do
		if region:IsShown() then lines[#lines + 1] = region end
	end
	return lines
end

-- The color a line was given with SetColorTexture, which has no getter.
-- A copy: the stub writes a set into the table it has, so the table itself
-- would follow the line.
local function colorOf(line)
	return { unpack(stub.state(line).color_texture) }
end

local function colorEq(a, b)
	for i = 1, 4 do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- True if a vertical line shows at x.
local function hasVerticalLineAt(x)
	for _, line in ipairs(shownLines()) do
		local point, _, _, lineX = line:GetPoint(1)
		if point == 'TOPLEFT' and lineX == x then return true end
	end
	return false
end

test('GridLinePositions', function()
	local p = EM.GridLinePositions(960, 0, 1920, 32)
	check(#p == 61, '32: 61 entries')
	check(p[1] == 0, '32: first 0')
	check(p[#p] == 1920, '32: last 1920')
	local has = false
	for _, v in ipairs(p) do
		if v == 960 then has = true end
	end
	check(has, '32: contains center')
	p = EM.GridLinePositions(960, 0, 1920, 100)
	check(#p == 19, '100: 19 entries')
	check(p[1] == 60, '100: from 60')
	check(p[#p] == 1860, '100: to 1860')
	p = EM.GridLinePositions(720, 0, 1440, 128)
	check(#p == 11, '128: 11 entries')
	check(p[1] == 80, '128: from 80')
	check(p[#p] == 1360, '128: to 1360')
	check(eqlist(EM.GridLinePositions(500, 0, 1000, 0), { 500 }), 'size 0 -> center only')
end)

test('GetGridCenter rounds to a physical pixel', function()
	set_screen(1921, 1081)
	local cx, cy = EM:GetGridCenter()
	check(cx == 961 and cy == 541, 'GetGridCenter 961, 541')
end)

test('drawing', function()
	EM.active = true
	settings.grid = true
	settings.grid_size = 32
	EM:UpdateGrid()
	check(EM.gridFrame:IsShown(), 'grid shown when active and on')

	local vcenter, hcenter = 0, 0
	local isCenter = {}
	for _, line in ipairs(shownLines()) do
		local point, _, _, x, y = line:GetPoint(1)
		if point == 'TOPLEFT' then
			if x == 961 then vcenter = vcenter + 1; isCenter[line] = true end
		else
			if y == 541 then hcenter = hcenter + 1; isCenter[line] = true end
		end
	end
	check(vcenter == 1, 'one center vertical line at x=961')
	check(hcenter == 1, 'one center horizontal line at y=541')

	local centerColor, otherColor
	for _, line in ipairs(shownLines()) do
		if isCenter[line] then centerColor = colorOf(line) else otherColor = colorOf(line) end
	end
	check(centerColor and otherColor and not colorEq(centerColor, otherColor), 'center color distinct from the others')
	for _, line in ipairs(shownLines()) do
		if isCenter[line] then
			check(colorEq(colorOf(line), centerColor), 'center lines all same color')
		else
			check(colorEq(colorOf(line), otherColor), 'other lines all same color')
		end
	end
	do -- the center lines are the accent: a non-default one, so a literal blue fails
		local accent = SaftUI.config.profile.theme.accent
		accent:SetRGB(0.9, 0.1, 0.2)
		EM:UpdateGrid()
		for _, line in ipairs(shownLines()) do
			local c = colorOf(line)
			if not colorEq(c, otherColor) then
				check(math.abs(c[1] - 0.9) < 1e-3 and math.abs(c[2] - 0.1) < 1e-3 and math.abs(c[3] - 0.2) < 1e-3, 'a center line in the accent')
			end
		end
		accent:SetRGB(0, 0.68, 0.94)
		EM:UpdateGrid()
	end
	local first = shownLines()[1]
	check(first:GetWidth() == 1 or first:GetHeight() == 1, 'lines 1 pixel thick')

	EM.active = false
	EM:UpdateGrid()
	check(not EM.gridFrame:IsShown(), 'UpdateGrid hides when inactive')
	EM.active = true
	settings.grid = false
	EM:UpdateGrid()
	check(not EM.gridFrame:IsShown(), 'UpdateGrid hides when grid off')
end)

test('the line pool', function()
	settings.grid = true
	set_screen(3840, 2160)
	settings.grid_size = 8
	EM:UpdateGrid()
	local created = select('#', EM.gridFrame:GetRegions())
	settings.grid_size = 64
	EM:UpdateGrid()
	check(select('#', EM.gridFrame:GetRegions()) == created, 'pool: no new textures on second draw')
	local cx, cy = EM:GetGridCenter()
	local expected = #EM.GridLinePositions(cx, 0, 3840, 64) + #EM.GridLinePositions(cy, 0, 2160, 64)
	check(#shownLines() == expected, 'pool: exactly the second draw shown (' .. #shownLines() .. ' vs ' .. expected .. ')')
end)

-- UIParent may resize after the screen events fire. The game then fires the
-- grid frame's OnSizeChanged from its layout pass, which the stubs don't run,
-- so the test fires it.
test('OnSizeChanged', function()
	check(EM.gridFrame:GetScript('OnSizeChanged') ~= nil, 'grid frame has an OnSizeChanged script')
	settings.grid = true
	settings.grid_size = 32
	EM.active = true
	EM:UpdateGrid()
	set_screen(2001, 1081)
	stub.fire_script(EM.gridFrame, 'OnSizeChanged', 2001, 1081)
	check(hasVerticalLineAt(1001), 'OnSizeChanged redraws: center line moves to x=1001')

	EM.active = false
	EM:UpdateGrid()
	set_screen(2001, 1081)
	stub.fire_script(EM.gridFrame, 'OnSizeChanged', 2001, 1081)
	check(not EM.gridFrame:IsShown(), 'OnSizeChanged does not draw while hidden')
	EM.active = true
end)

test('UpdateConfig', function()
	settings.grid = false
	EM:UpdateConfig()
	check(not EM.gridFrame:IsShown(), 'UpdateConfig hides grid')
	settings.grid = true
	EM:UpdateConfig()
	check(EM.gridFrame:IsShown(), 'UpdateConfig shows grid')
end)

test('SetGridSize', function()
	-- Count the Refresh calls that redraw an open /sui.
	local refreshes = 0
	local refresh = st.Config.Refresh
	st.Config.Refresh = function(...)
		refreshes = refreshes + 1
		return refresh(...)
	end

	local before
	-- SetGridSize: a whole size within the range, the grid redrawn at once.
	settings.grid = true
	EM:SetGridSize(30)
	check(settings.grid_size == 30, 'SetGridSize sets it')
	check(hasVerticalLineAt(EM:GetGridCenter() + 30), 'and the grid redraws with lines 30 apart')
	EM:SetGridSize(33.6)
	check(settings.grid_size == 34, 'a whole number')
	EM:SetGridSize(7)
	check(settings.grid_size == 8, 'at least 8')
	EM:SetGridSize(500)
	check(settings.grid_size == 128, 'at most 128')
	before = refreshes
	EM:SetGridSize(64)
	check(refreshes == before + 1, 'SetGridSize refreshes /sui')
	settings.grid_size = 32

	st.Config.Refresh = refresh
end)

test('the screen events', function()
	-- Enable runs OnInitialize and OnEnable, which registers them. AceAddon
	-- would report an error in them to the error handler rather than raise it.
	local ok, err = pcall(EM.Enable, EM)
	local reported = take_errors()
	check(ok and #reported == 0, 'OnEnable runs without error: ' .. tostring(not ok and err or reported[1]))

	-- The grid redraws on each screen event. Fire it and see the center line
	-- follow a new screen size.
	set_screen(2101, 1081)
	stub.fire_event('UI_SCALE_CHANGED')
	check(hasVerticalLineAt(1051), 'registers UI_SCALE_CHANGED')
	set_screen(2201, 1081)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	check(hasVerticalLineAt(1101), 'registers DISPLAY_SIZE_CHANGED')
end)

test('the /sui options', function()
	local opts = EM:GetConfigTable()
	local g = opts.args.general.args
	check(g.grid and g.grid_size and g.snap_grid and g.snap_frames, 'options: all four keys')
	check(g.grid_size.min == 8 and g.grid_size.max == 128, 'options: grid_size 8..128')
	check(opts.name == 'Edit mode', 'options name')
	settings.grid_size = 32
	opts.args.general.set({ 'EditMode', 'general', 'grid_size' }, 48)
	check(settings.grid_size == 48, 'options set writes settings')
	check(opts.args.general.get({ 'EditMode', 'general', 'grid_size' }) == 48, 'options get reads settings')
end)

test('Dim world: a full-screen black layer at 50%, under the grid, only while edit mode and Dim are on', function()
	settings.grid = false
	check(settings.dim == true, 'Dim world is on by default')
	check(settings.coordinates == false, 'Coordinates is off by default')
	if EM.active then EM:Deactivate() end
	EM:UpdateDim()
	check(not EM.dimFrame:IsShown(), 'edit mode off: hidden')

	EM:Activate()
	local dim = EM.dimFrame
	check(dim:IsShown(), 'edit mode and Dim on: shown')
	check(dim:GetFrameStrata() == 'BACKGROUND', 'BACKGROUND strata')
	check(dim:GetFrameLevel() < EM.gridFrame:GetFrameLevel(), "under the grid's level")
	check(not dim:IsMouseEnabled(), 'takes no mouse')
	check(dim:GetParent() == UIParent, "a child of UIParent")
	check(dim:GetLeft() == 0 and dim:GetBottom() == 0 and dim:GetRight() == UIParent:GetWidth()
		and dim:GetTop() == UIParent:GetHeight(), 'over all of UIParent')
	check(EM.DIM_ALPHA == 0.5, 'DIM_ALPHA')
	local color
	for _, region in ipairs({ dim:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and stub.state(region).color_texture then color = stub.state(region).color_texture end
	end
	check(color and color[1] == 0 and color[2] == 0 and color[3] == 0 and color[4] == 0.5, 'one black texture at 50%')

	EM:SetSetting('dim', false)
	check(not dim:IsShown(), 'Dim off: hidden')
	EM:SetSetting('dim', true)
	check(dim:IsShown(), 'Dim on again: shown')
	EM:Deactivate()
	check(not dim:IsShown(), 'edit mode off: hidden')
	EM:SetSetting('dim', false)
	EM:Activate()
	check(not dim:IsShown(), 'edit mode on, Dim off: hidden')
	EM:SetSetting('dim', true)
	check(dim:IsShown(), 'turned on in edit mode: shown')
	EM:Deactivate()
end)

test('the /sui options gain Dim world and Coordinates', function()
	local g = EM:GetConfigTable().args.general.args
	check(g.dim and g.coordinates, 'options: dim and coordinates')
	check(g.dim.name == 'Dim world' and g.coordinates.name == 'Coordinates', 'their names')
end)
