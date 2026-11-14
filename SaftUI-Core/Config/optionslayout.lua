local st = SaftUI
local OB = st.OptionsBody

--[[
	The layouts of SaftUI's options window (st.OptionsWindow,
	optionswindow.lua) and the layout math that needs no frame: OW.LAYOUT,
	the sidebar's width and entries, the body's layout (OB's, here for the
	window's tests), the window's height, and where a page's footer control
	sits (OW.FooterPlace). It loads first of the window's files
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
		width = 1110, height = 728, -- 17 + 1076 + 17 by 28 + 654 + 46, both even (it's centred)
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

------------------------------------------------------------------ the footer control

-- How far a page's footer control (optionswindow.lua) keeps from edit mode's
-- buttons: 12, as the footer's region keeps from Reload UI and Close.
local FOOTER_GAP = 12

--[[
	Where a page's footer control sits in the footer's region (between Reload
	UI and Close), regionWidth wide, whose left inset edit mode's buttons take
	(OW:SetFooterInset; 0 without them). labelWidth is its label's, with the
	gap after it; widgetsWidth its widgets', in a line. Returns the control's
	left edge in the region, and whether its label shows:
	  - centred, while that keeps it FOOTER_GAP clear of the buttons;
	  - else at the region's right end, beside Close;
	  - else, when even there it would come closer, at the right end without
	    its label: the label goes first, and the widgets stay there, however
	    close that brings them.
	Whole pixels: the centre is rounded down.
]]
function OW.FooterPlace(regionWidth, inset, labelWidth, widgetsWidth)
	local clear = inset > 0 and inset + FOOTER_GAP or 0
	local full = labelWidth + widgetsWidth
	local centred = floor((regionWidth - full) / 2)
	if centred >= clear then return centred, true end
	if regionWidth - full >= clear then return regionWidth - full, true end
	return regionWidth - widgetsWidth, false
end

------------------------------------------------------------------ the window's height

--[[
	The window keeps its art inside the screen edge margin (misc.clamp_inset):
	under Blizzard the metal reaches past its edges (st.ThemeArt.MetalReach:
	16 above, 8 to the left), so the game's clamp (st:KeepInScreenMargin)
	keeps the metal in, and a resize leaves room for it. It never grows past
	the screen, whatever the margin, so its grip and title bar stay on it.
]]

-- How far the window's art reaches past its edges in layout L: left, right,
-- top and bottom. Under Blizzard the metal does; under Thick and Thin nothing.
local function ArtReach(L)
	if L == OW.LAYOUT.blizzard then return st.ThemeArt.MetalReach() end
	return 0, 0, 0, 0
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
-- window is centred, so its edges stay on whole pixels), at most
-- OW.MaxHeight(L) and at least L's least height, which wins on a screen too
-- small for it; L's least height with none saved.
function OW.WindowHeight(L)
	local saved = st.config.global.optionsWindow
	local height = type(saved) == 'table' and saved.height
	if type(height) ~= 'number' then return L.height end
	return max(L.height, min(OW.MaxHeight(L), 2 * floor(height / 2 + 0.5)))
end

------------------------------------------------------------------ for the later files

S.ArtReach, S.Margins, S.FOOTER_GAP = ArtReach, Margins, FOOTER_GAP
