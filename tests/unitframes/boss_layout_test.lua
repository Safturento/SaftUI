-- Boss (and arena) frames laid out like party and raid: the shared layout math
-- in SaftUI-Unitframes/groups.lua (UF.GetGroupLayout, UF.GetGroupLayoutSize,
-- UF.GroupAnchor), which UF:PlaceUnitFrame and UF:PlaceHolder
-- (unitframes.lua) call. Pure functions: no frames are placed here.
--
-- Real: Core's helpers and profile defaults, the unit frames' defaults, and
-- groups.lua. Stand-in: the Unitframes module, which unitframes.lua makes and
-- needs oUF for.
load_core_helpers()
load_saftui('SaftUI-Unitframes/config/default.lua')
load_saftui('SaftUI-Unitframes/config/units/boss.lua')
load_saftui('SaftUI-Unitframes/config/units/arena.lua')
apply_defaults()

local st = SaftUI
local UF = st:NewModule('Unitframes')
load_saftui('SaftUI-Unitframes/groups.lua')

local function expect_anchor(actual, point, relativeTo, relativePoint, x, y)
	eq(#actual, 1, 'one point')
	local a = actual[1]
	eq(a[1], point)
	check(a[2] == relativeTo, 'relative to the expected frame')
	eq(a[3], relativePoint)
	eq(a[4], x)
	eq(a[5], y)
end

test('GroupAnchor: the default boss layout hangs each frame 41 below the one before it', function()
	local layout = UF.GetGroupLayout({ growthDirection = 'TOP', spacing = 41, unitsPerColumn = 5,
		maxColumns = 1, width = 200, height = 30 })
	local _, _, perColumn, columns = UF.GetGroupLayoutSize(layout, 5)
	local container, frames = {}, { {}, {}, {}, {}, {} }
	expect_anchor(UF.GroupAnchor(1, frames, container, layout, perColumn, columns), 'TOP', container, 'TOP', 0, 0)
	expect_anchor(UF.GroupAnchor(2, frames, container, layout, perColumn, columns), 'TOP', frames[1], 'BOTTOM', 0, -41)
	expect_anchor(UF.GroupAnchor(5, frames, container, layout, perColumn, columns), 'TOP', frames[4], 'BOTTOM', 0, -41)
end)

test('GroupAnchor: two columns of three, each growing down and the columns going right, start each column at the first of the last', function()
	local layout = UF.GetGroupLayout({ growthDirection = 'TOP', spacing = 41, unitsPerColumn = 3,
		maxColumns = 2, columnSpacing = 10, initialAnchor = 'LEFT', width = 200, height = 30 })
	local _, _, perColumn, columns = UF.GetGroupLayoutSize(layout, 5)
	eq(perColumn, 3)
	eq(columns, 2)
	local container, frames = {}, { {}, {}, {}, {}, {} }
	expect_anchor(UF.GroupAnchor(4, frames, container, layout, perColumn, columns), 'LEFT', frames[1], 'RIGHT', 10, 0)
	-- the first frame is pinned by both the growth point and the column point
	eq(#UF.GroupAnchor(1, frames, container, layout, perColumn, columns), 2)
end)

test('the boss holder covers the whole layout: five in a column by default, two columns when set (columns going right)', function()
	local layout = UF.GetGroupLayout({ growthDirection = 'TOP', spacing = 41, unitsPerColumn = 5,
		maxColumns = 1, width = 200, height = 30 })
	local w, h = UF.GetGroupLayoutSize(layout, 5)
	eq(w, 200)
	eq(h, 5 * 30 + 4 * 41)

	layout = UF.GetGroupLayout({ growthDirection = 'TOP', spacing = 41, unitsPerColumn = 3,
		maxColumns = 2, columnSpacing = 10, initialAnchor = 'LEFT', width = 200, height = 30 })
	w, h = UF.GetGroupLayoutSize(layout, 5)
	eq(w, 410)
	eq(h, 3 * 30 + 2 * 41)
end)

test("arena's 'DOWN' is no Layout key, so it falls back to one column growing down by its spacing", function()
	local arena = st.defaults.unitframes.profiles['**'].arena
	local layout = UF.GetGroupLayout({ growthDirection = arena.growthDirection, spacing = arena.spacing,
		width = 200, height = 30 })
	eq(layout.point, 'TOP')
	local w, h, perColumn, columns = UF.GetGroupLayoutSize(layout, 5)
	eq(perColumn, 5)
	eq(columns, 1)
	eq(w, 200)
	eq(h, 5 * 30 + 4 * arena.spacing)
	local frames = { {}, {} }
	expect_anchor(UF.GroupAnchor(2, frames, {}, layout, perColumn, columns), 'TOP', frames[1], 'BOTTOM', 0, -arena.spacing)
end)

test("boss's default growth is a Layout dropdown key", function()
	local growth = st.defaults.unitframes.profiles['**'].boss.growthDirection
	eq(growth, 'TOP')
	eq(({ TOP = true, BOTTOM = true, LEFT = true, RIGHT = true })[growth], true)
end)

test('a layout that holds fewer than all the frames: shown is its capacity, and GroupAnchor gives nothing past it', function()
	local layout = UF.GetGroupLayout({ growthDirection = 'TOP', spacing = 41, unitsPerColumn = 3,
		maxColumns = 1, width = 200, height = 30 })
	local _, _, perColumn, columns, shown = UF.GetGroupLayoutSize(layout, 5)
	eq(shown, 3)
	local frames = { {}, {}, {}, {}, {} }
	eq(UF.GroupAnchor(4, frames, {}, layout, perColumn, columns), nil)
	eq(UF.GroupAnchor(5, frames, {}, layout, perColumn, columns), nil)
	check(UF.GroupAnchor(3, frames, {}, layout, perColumn, columns) ~= nil, 'the last one that fits has a place')

	layout = UF.GetGroupLayout({ growthDirection = 'TOP', spacing = 41, unitsPerColumn = 2,
		maxColumns = 2, columnSpacing = 10, initialAnchor = 'LEFT', width = 200, height = 30 })
	_, _, perColumn, columns, shown = UF.GetGroupLayoutSize(layout, 5)
	eq(shown, 4)
	eq(UF.GroupAnchor(5, frames, {}, layout, perColumn, columns), nil)
end)
