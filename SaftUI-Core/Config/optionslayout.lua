local st = SaftUI
local OB = st.OptionsBody

--[[
	The layouts of SaftUI's options window (st.OptionsWindow,
	optionswindow.lua) and the layout math that needs no frame: OW.LAYOUT,
	the sidebar's width and entries, the body's layout (OB's, here for the
	window's tests), the window's height and width limits and the sizes' numbers
	(OW.WindowWidth, OW.CornerOf, OW.MiniLayout, OW.MiniShift and the rest), what changing size needs
	(OW.SIZE_GUARD, OW.FirstInView, OW.OffsetFor, OW.InnerCuts), and where a
	page's footer control sits (OW.FooterPlace) and how a pick's control flows on the picker's line (OW.PickerFlow). It loads first of the window's files
	(Config/load.xml), so it makes OW and OW.S.
]]

local OW = {}
st.OptionsWindow = OW

-- OW.S: what the window's files share with each other and nothing else; not
-- an API. They load in Config/load.xml's order, this file first. The state
-- that more than one of them reads or writes and that is replaced as it
-- changes (the layout, the look, what was drawn, a resize, the scroll
-- offsets) is always read and written as S.name, never kept in a local.
-- The rest (a constant, a table that's only filled, a function) a file sets
-- here at its end and a later file takes as a local of its own at its top;
-- optionswindow.lua calls the later files' functions through S, as they run.
local S = {}
OW.S = S

local floor, max, min = math.floor, math.max, math.min

local CATEGORIES = { 'Frames', 'Combat', 'Info' } -- then any others, then Other

------------------------------------------------------------------ the two layouts

--[[
	Where the window's parts sit, from its edges, in each look: chosen on
	every render by W.BlizzardLook() and applied only when the look changed
	(Relayout). Inside the main column the parts keep their places from its
	top left under both (the mockup's numbers in optionswindow.lua).
	  own       the mockup's, under Thick and Thin: the sidebar and the main
	            column 2 in from the window's border, the footer along the
	            main column's bottom.
	  blizzard  Blizzard's Settings window: the inner frame (st.ThemeArt.
	            Control('optionswindow')) innerX in from the metal's sides and
	            innerTop down, the sidebar on the divider drawn into it
	            (OW.SidebarWidth), the footer across the window under it. The
	            window is wider and taller than the mockup's, so the body keeps
	            its 774 and its height.

	  width                  the window's
	  halfBody               the body's width at half (W3 and W4) and at the bar;
	                         full's is OB.WIDTH (774)
	  height                 its least height, and its height with none saved
	                         (OW.WindowHeight)
	  sideX, sideTop, sideBottom, sideWidth
	                         the sidebar, from the window's left, top and bottom
	  navWidth               the sidebar's rows
	  mainLeft, mainTop, mainRight, mainBottom
	                         the main column, from the window's edges
	  rightPad               the main column right of the content: the body's
	                         right and, under own, Close's
	  bodyBottom             the body's bottom, up from the main column's
	  bodyReach, fillReach   how far the body's scroll frame reaches past the
	                         content, and on a fill page (PlaceBody)
	  footer                 the footer's height: in the main column under own,
	                         across the window under Blizzard
	  innerX, innerTop       the inner frame, from the window's sides and top
	                         (Blizzard); it ends footer up from the bottom
	  footerX, footerY       Reload UI and Close, from the window's bottom
	                         corners (Blizzard; under own they sit in the footer)
]]
OW.LAYOUT = {
	own = {
		width = 1040, height = 700,
		halfBody = 388, -- W3 is 654 wide
		sideX = 2, sideTop = 2, sideBottom = 2, sideWidth = 208,
		navWidth = 207,
		mainLeft = 210, mainTop = 2, mainRight = 2, mainBottom = 2,
		rightPad = 26, -- the main column's 828 less PAD and the content
		bodyBottom = 46, -- over the footer
		bodyReach = 0,
		fillReach = 13, -- over the body's own 3px bar, 10 past the content (OB.BAR_GAP + OB.BAR_WIDTH)
		footer = 46,
	},
	blizzard = {
		width = 1110, height = 728, -- 17 + 1076 + 17 by 28 + 654 + 46, both even (the small dialog sits on the window's centre)
		halfBody = 368, -- W3 is 704 wide
		sideX = 17, sideTop = 28, sideBottom = 46,
		sideWidth = 242, -- OW.SidebarWidth(1076): its right edge on the divider
		navWidth = 226, -- the sidebar less 16: the nav's narrow bar 4 from the rows and 4 from the divider
		mainLeft = 259, mainTop = 28, mainRight = 17, mainBottom = 46,
		-- The dropdown's glow 7, the scroll bar's gap 12 and its 17-wide
		-- arrows less 4 (25 past the content), the inner frame's 2px rim and 5 clear.
		rightPad = 32,
		bodyBottom = 4, -- the inner frame's 2px rim and 2 clear
		bodyReach = 7, -- the dropdown's glow
		fillReach = 25, -- where the Blizzard scroll bar's arrows end
		footer = 46,
		innerX = 17, innerTop = 28, -- Settings' inner frame 17 in; its tabs 27 down, +1 for an even height
		footerX = 16, footerY = 16, -- SettingsPanel's Close: BOTTOMRIGHT -16, 16
	},
}

-- The sidebar's width for an inner frame innerWidth wide: its right edge on
-- the divider drawn into Options_InnerFrame, which is stretched to that width.
function OW.SidebarWidth(innerWidth)
	local look = st.ThemeArt.Control('optionswindow')
	return floor(look.divider * innerWidth / look.width + 0.5)
end

------------------------------------------------------------------ the pure layout

-- The body's layout (optionsbody.lua), here too for the window's tests.
OW.LayoutRows, OW.LayoutSections = OB.LayoutRows, OB.LayoutSections

-- The sidebar's entries from OM.Pages: Global settings and Profiles, then a
-- { group = category } header and its pages for each category, in the fixed
-- order. Pages keep the order they came in (order, then name).
function OW.SidebarEntries(pages)
	local entries, byCategory, others = {}, {}, {}
	for _, special in ipairs({ 'global', 'profiles' }) do
		for _, page in ipairs(pages) do
			if page.special == special then entries[#entries + 1] = page end
		end
	end
	local fixed = { Other = true }
	for _, category in ipairs(CATEGORIES) do fixed[category] = true end
	for _, page in ipairs(pages) do
		if not page.special then
			local category = tostring(page.category or 'Other')
			if not byCategory[category] then
				byCategory[category] = {}
				if not fixed[category] then others[#others + 1] = category end
			end
			local list = byCategory[category]
			list[#list + 1] = page
		end
	end
	table.sort(others)
	local order = {}
	for _, category in ipairs(CATEGORIES) do order[#order + 1] = category end
	for _, category in ipairs(others) do order[#order + 1] = category end
	order[#order + 1] = 'Other'
	for _, category in ipairs(order) do
		if byCategory[category] then
			entries[#entries + 1] = { group = category }
			for _, page in ipairs(byCategory[category]) do entries[#entries + 1] = page end
		end
	end
	return entries
end

-- The page list the title opens (W.OpenList, optionsnav.lua) from
-- OW.SidebarEntries' entries: a page is { key, label = its name, disabled }, and
-- a { group } header a caption, { caption = true, label = the group }.
function OW.PageMenuEntries(entries)
	local list = {}
	for _, entry in ipairs(entries) do
		if entry.group then
			list[#list + 1] = { caption = true, label = tostring(entry.group) }
		else
			list[#list + 1] = { key = entry.key, label = tostring(entry.name), disabled = entry.disabled and true or nil }
		end
	end
	return list
end

------------------------------------------------------------------ the footer control

-- How far the status line keeps from a page's footer control (optionswindow.lua),
-- and the footer's region from Reload UI: 12.
local FOOTER_GAP = 12

--[[
	Where a page's footer control sits in the footer's region (left of Reload
	UI), regionWidth wide. labelWidth is its label's, with the gap
	after it; widgetsWidth its widgets', in a line. Returns the control's left
	edge in the region, and whether its label shows:
	  - centred, while it fits;
	  - else at the region's right end, beside Reload UI, without its label: the
	    label goes first, and the widgets stay there, however narrow the
	    region is.
	Whole pixels: the centre is rounded down.
]]
function OW.FooterPlace(regionWidth, labelWidth, widgetsWidth)
	local full = labelWidth + widgetsWidth
	local centred = floor((regionWidth - full) / 2)
	if centred >= 0 then return centred, true end
	return regionWidth - widgetsWidth, false
end

------------------------------------------------------------------ the picker's line

--[[
	The picker's line: a pick's control (the unit frames' Copy from, Profile
	and Manage) is drawn on the Unit dropdown's line, wrapping when a piece
	would pass the body's width.
	  OW.PickerFlow(widths, width) -> places, height
	widths[1] is the picker with its label, each later entry one piece of the
	control (a button, or a label and its widget). Pieces go left to right,
	PICKER_CONTROL_GAP apart. One that would pass width starts a new line at x 0,
	a line's height and PICKER_LINE_GAP under the last; one wider than the line
	goes alone on one. places[i] = { x, y }, both whole, from the line's
	top left; height = lines * FIELD_HEIGHT + (lines - 1) * PICKER_LINE_GAP.
]]
OW.PICKER_LINE_GAP = 8
OW.PICKER_CONTROL_GAP = 12 -- as the buttons on a line are apart

function OW.PickerFlow(widths, width)
	local line = st.OptionsWidgets.FIELD_HEIGHT
	local places, x, y = {}, 0, 0
	for i, w in ipairs(widths) do
		if i > 1 and x + w > width then
			x, y = 0, y + line + OW.PICKER_LINE_GAP
		end
		places[i] = { x = x, y = y }
		x = x + w + OW.PICKER_CONTROL_GAP
	end
	return places, y + line
end

------------------------------------------------------------------ the window's height

--[[
	The window keeps its art inside the screen edge margin (misc.clamp_inset):
	under Blizzard the metal reaches past its edges (st.ThemeArt.MetalReach:
	16 above, 8 to the left), so the game's clamp (st:KeepInScreenMargin)
	keeps the metal in, and a resize leaves room for it. It never grows past
	the screen, whatever the margin, so its grip and title bar stay on it.
]]

-- How far the metal reaches past the window's edges in layout L: left, right,
-- top and bottom. Under Blizzard the metal does; under Thick and Thin nothing.
local function MetalReach(L)
	if L == OW.LAYOUT.blizzard then return st.ThemeArt.MetalReach() end
	return 0, 0, 0, 0
end

-- How far the window's art reaches past its edges in layout L (MetalReach's),
-- and none at the bar, a panel with no metal: what keeps the window on the
-- screen keeps the bar's own edges on it.
local function ArtReach(L)
	if S.size == 'mini' then return 0, 0, 0, 0 end
	return MetalReach(L)
end

-- How far in from the screen's top and bottom the window's edges keep in
-- layout L: the screen edge margin (none below 0, so the window never grows
-- past the screen) and the art past the window there.
local function Margins(L)
	local margin = max(0, st.config.profile.misc.clamp_inset)
	local _, _, above, below = ArtReach(L)
	return margin + above, margin + below
end

-- The most height the window takes in layout L (the one it's in when nil):
-- the screen less what it keeps at its top and bottom (Margins), even.
function OW.MaxHeight(L)
	local above, below = Margins(L or S.layout)
	return 2 * floor((UIParent:GetHeight() - above - below) / 2)
end

-- The window's height in layout L: the saved height (a number) made even (the
-- small dialog sits on the window's centre), at most
-- OW.MaxHeight(L) and at least L's least height, which wins on a screen too
-- small for it; L's least height with none saved.
function OW.WindowHeight(L)
	local saved = st.config.global.optionsWindow
	local height = type(saved) == 'table' and saved.height
	if type(height) ~= 'number' then return L.height end
	return max(L.height, min(OW.MaxHeight(L), 2 * floor(height / 2 + 0.5)))
end

-- The most width the window takes in layout L (the one it's in when nil): the
-- screen less the margin each side and, under Blizzard, the metal at each
-- side, even; 0 on a screen narrower than that.
function OW.MaxWidth(L)
	L = L or S.layout
	local margin = max(0, st.config.profile.misc.clamp_inset)
	local left, right = MetalReach(L) -- the metal's, even at the bar: what it grows back to has it
	local room = floor(UIParent:GetWidth() + 0.5) - 2 * margin - left - right
	return max(0, 2 * floor(room / 2))
end

-- Whether the window in layout L fits the screen at size with the sidebar
-- shown or collapsed.
function OW.Fits(L, size, sidebar)
	return OW.WindowWidth(L, size, sidebar) <= OW.MaxWidth(L)
end

------------------------------------------------------------------ the window's sizes

--[[
	The window has three sizes, saved in st.config.global.optionsWindow as
	size = 'half' or nil (full) and sidebar = false or nil (shown): 'full'
	(the body 774 wide), 'half' (L.halfBody) and 'mini' (a bar, MINI_HEIGHT
	tall; its own width is the bar's, not a size's). The bar is never saved: it comes back as half.
	Its width in each state, every one even (the window's centre is what the
	small dialog sits on):
	  W1 full with the sidebar   Thick and Thin 1040   Blizzard 1110
	  W2 full, sidebar collapsed 832                   868
	  W3 half with the sidebar   654                   704
	  W4 half, sidebar collapsed 446                   462
]]
OW.MINI_HEIGHT = 42 -- the bar's height
OW.MINI_MAX = 400 -- the most the bar's width takes
OW.MINI_MIN_TAB = 24 -- the least a tab name cut to fit is worth showing

-- The window's width in layout L at size ('full'; anything else gives half's,
-- the size the bar grows back to) with the sidebar shown (true) or collapsed (false).
function OW.WindowWidth(L, size, sidebar)
	local width = L.width
	if sidebar == false then width = width - L.sideWidth end
	if size ~= 'full' then width = width - (OB.WIDTH - L.halfBody) end
	return width
end

-- The bar's width and its texts' (OW.MINI_MAX at most), from the widths of the
-- name, the page's name, the tab's name (0 for none) and the buttons (grow, 8,
-- close). Each width is rounded first (a width the game reads back has float
-- noise). The parts are 12 in, 8 apart and 8 from the end:
-- 12 + brand + 8 + page + 8 + tab + 8 + buttons + 8, the tab and its gap
-- dropped when there is none; the width is rounded up to even (the small
-- dialog sits on the window's centre). Too wide for OW.MINI_MAX, the tab is cut
-- first, to what is left, and dropped with its gap when none is; then the
-- page. Returns the page's and the tab's widths as they are drawn, and the
-- bar's.
function OW.MiniLayout(brand, page, tab, buttons)
	local function Whole(value) return floor(value + 0.5) end
	brand, page, tab, buttons = Whole(brand), Whole(page), Whole(tab), Whole(buttons)
	local function Total()
		return 12 + brand + 8 + page + 8 + (tab > 0 and tab + 8 or 0) + buttons + 8
	end
	local over = Total() - OW.MINI_MAX
	if over > 0 then
		tab = max(0, tab - over)
		-- A tab cut under what shows an ellipsis and a letter or two is dropped
		-- with its gap, and the page takes the room.
		if tab < OW.MINI_MIN_TAB then tab = 0 end
		over = Total() - OW.MINI_MAX
		if over > 0 then page = max(0, page - over) end
	end
	local width = Total()
	return page, tab, width + width % 2
end

-- How far the bar's top right corner sits from the window's, as the offset to
-- add to the corner: under Blizzard the metal's right and top reach, which puts
-- the bar where the metal's corner was; else nothing. At the bar the window is
-- anchored at S.corner plus this, and a drag saves the corner less it.
function OW.MiniShift(L)
	local _, right, top = MetalReach(L)
	return right, top
end

-- The name on the sidebar and the bar: "Saft" in the text colour, "UI" in the
-- accent (Button > Blue), read at each draw so a change of colour shows.
function OW.BrandText()
	local r, g, b = OB.Blue()
	return ('Saft|cff%02x%02x%02xUI|r'):format(floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

-- Where the main column starts, from the window's left: after the sidebar, or
-- at the sidebar's place when it's collapsed.
function OW.MainLeft(L, sidebar)
	if sidebar == false then return L.sideX end
	return L.mainLeft
end

-- The body's width at size: OB.WIDTH at full, L.halfBody at half and at the bar.
function OW.BodyWidth(L, size)
	if size == 'full' then return OB.WIDTH end
	return L.halfBody
end

local SIZES = { 'full', 'half', 'mini' }

-- The size step from size: 1 shrinks (full, half, mini), -1 grows. nil past
-- either end, and for a size that isn't one.
function OW.NextSize(size, step)
	for i, name in ipairs(SIZES) do
		if name == size then return SIZES[i + step] end
	end
end

-- The size and the sidebar the window opens in, from the save: 'full' and
-- shown unless it says otherwise. 'half' and a saved bar ('mini') are half;
-- anything else is full, and only false collapses the sidebar.
function OW.SavedState()
	local saved = st.config.global.optionsWindow
	if type(saved) ~= 'table' then return 'full', true end
	local size = (saved.size == 'half' or saved.size == 'mini') and 'half' or 'full'
	return size, saved.sidebar ~= false
end

-- The TOPRIGHT offset of a width by height window placed by point at x, y on a
-- screenWidth by screenHeight UIParent, in whole units. Arithmetic, so an older
-- save converts without asking a frame that may not be laid out yet.
function OW.CornerOf(point, x, y, width, height, screenWidth, screenHeight)
	local right, top
	if point:find('LEFT') then right = x + width - screenWidth
	elseif point:find('RIGHT') then right = x
	else right = x + (width - screenWidth) / 2 end
	if point:find('TOP') then top = y
	elseif point:find('BOTTOM') then top = y + height - screenHeight
	else top = y + (height - screenHeight) / 2 end
	return floor(right + 0.5), floor(top + 0.5)
end

-- The corner offset, from UIParent's top right, that centres a window width by
-- height on a screen screenWidth by screenHeight: whole, rounded down.
function OW.CentredCorner(screenWidth, screenHeight, width, height)
	return 0 - floor((screenWidth - width) / 2), 0 - floor((screenHeight - height) / 2)
end

------------------------------------------------------------------ between sizes

-- How long a size button ignores clicks after the size last changed, in
-- seconds (OW:Grow, OW:Shrink): the mini bar's grow arrow sits about where
-- half's shrink arrow appears, so a double click would go straight back.
OW.SIZE_GUARD = 0.3

-- The first row in view of a drawn page: the first of cells (the body's, each
-- with its y and height in the content and its row's path) whose bottom is
-- below offset, the scroll offset. Returns its path and how far offset is
-- below its top (negative above it), which OW.OffsetFor puts back after the
-- rows have flowed again. Nothing when no cell reaches offset. A cell with no
-- path can't be found again, so it is skipped.
function OW.FirstInView(cells, offset)
	for _, cell in ipairs(cells) do
		local path = cell.row and cell.row.path
		if path and cell.y and cell.y + cell.height > offset then return path, offset - cell.y end
	end
end

local function SamePath(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- The scroll offset that puts the cell at path (a drawn page's) delta below
-- the top of the view, never under 0; nil when no cell has that path.
function OW.OffsetFor(cells, path, delta)
	if not path then return end
	for _, cell in ipairs(cells) do
		local cellPath = cell.row and cell.row.path
		if cellPath and SamePath(cellPath, path) then return max(0, cell.y + delta) end
	end
end

-- Under Blizzard the inner frame (Options_InnerFrame, height pixels tall in
-- its atlas: C_Texture.GetAtlasInfo's, never a frame's) is cut at its divider
-- into two textures, the list's over the sidebar and the settings' over the
-- main column, so the main column can be narrower than the art. look is
-- st.ThemeArt.Control('optionswindow'). Returns each part's rectangle in the
-- atlas's pixels, { x0, x1, y0, y1 } with exclusive ends (ThemeArt.Cut).
function OW.InnerCuts(look, height)
	return { 0, look.divider, 0, height }, { look.divider, look.width, 0, height }
end

------------------------------------------------------------------ for the later files

S.ArtReach, S.Margins, S.FOOTER_GAP = ArtReach, Margins, FOOTER_GAP
