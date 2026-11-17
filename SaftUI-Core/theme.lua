local st = SaftUI

--[[
	SaftUI's theme engine.

	The profile's theme (st.config.profile.theme) is Thick, Thin or Blizzard,
	with whether backgrounds are see-through and the opacity they use (the Theme tab's Background alpha). Each theme
	keeps its own colors in st.config.profile.templates[name]. A module can
	override the theme with a Theme ('theme', 'thick', 'thin', 'blizzard' or
	'none') and a Background ('theme', 'solid' or 'transparent'); 'theme', or
	nil, follows the profile's. st:ResolveTheme turns the pair into the look a
	frame is drawn with. SaftUI's own config windows (the /sui window, edit
	mode's bar, window and History list, the small dialogs) are drawn with the
	Background 'options', which follows the Theme tab's Options windows choice
	(profile.theme.optionsbackground) and so the theme's Background by default.

	Every draw call (st:SetTemplate, st:SetBackdrop, st:SetBackdropIn) names the
	kind of frame it draws (st.THEME_KINDS), last. Under Thick and Thin only the
	header strips and the close button draw differently (a window draws as a
	panel, a control as a small frame, a unit frame and a party or raid member
	as a bar). Blizzard draws each kind in Blizzard's own art for it, which
	themeart.lua describes and draws (st.ThemeArt), and its inset depends on
	the kind. A call with no kind is an error, unless
	its theme is 'none', which only clears (tests/core/theme_kinds_test.lua
	scans every SaftUI file for calls without one).

	Profiles saved before themes kept template names ('thicktransparent', 'thin',
	'highlight', ...) in keys named template or <something>template.
	st:MigrateTemplateKeys rewrites them into a Theme and a Background through
	LEGACY. Config/config.lua runs it wherever saved data enters a profile: at
	login, on every profile change, copy or reset, and on an imported string.

	Each drawn frame is recorded with the arguments it was last drawn with, so a
	change to the theme reaches every frame: st:RecolorThemed for a color or the
	opacity, st:RedrawThemed for the theme or the toggle, which move borders, and
	for every profile switch, copy or reset. Each frame is drawn on its own, so
	one that errors doesn't keep the rest in the old look. Colors a frame's own
	code puts on its backdrop (a scroll bar thumb's fill, a focused edit box's
	border) go back on after either (st:KeepOwnColors).

	A saved theme this version doesn't know (a later version's) reads as Thick.
]]

-- The kinds of frame a draw call names.
st.THEME_KINDS = {
	panel = true,   -- a background: chat, the minimap, the options window, the loot feed
	window = true,  -- a window with SaftUI's title bar (st:CreateHeader): the bags, the bank, st:CreatePanel
	bar = true,     -- a status bar outside the unit frames: experience and roll bars, swing timers
	action = true,  -- an action button
	slot = true,    -- bag, bank and currency slots
	aura = true,    -- buffs and debuffs
	tooltip = true,
	header = true,  -- header and footer strips
	close = true,   -- the close button
	control = true, -- a small frame Blizzard draws with art of its own: buttons, check boxes, tabs, edit boxes, the micro menu's items
	small = true,   -- everything else: indicators
	unitframe = true, -- a unit frame or one of its bars
	member = true,    -- a party or raid member's frame or bar
}

-- The themes this version has. A saved name that isn't one reads as FALLBACK.
local THEMES = { thick = true, thin = true, blizzard = true }

-- How far in Thick's and Thin's border reaches, whatever the kind, in lines
-- (a line is st.lineWeight pixels: st:GetLineSize): Thick draws a dark line,
-- its border and another dark line, Thin one line. Blizzard's is each kind's
-- own, in whole pixels (st.ThemeArt.WholeInset).
local LINES = { thick = 2, thin = 1 }

-- A header or footer strip is the theme's border color at this alpha.
local HEADER_ALPHA = 0.4

-- An old template name's Theme and Background. highlight and close were never
-- real choices: they follow the theme. none leaves the background unset.
local LEGACY = {
	thicktransparent = { theme = 'thick', background = 'transparent' },
	thintransparent = { theme = 'thin', background = 'transparent' },
	thick = { theme = 'thick', background = 'solid' },
	thin = { theme = 'thin', background = 'solid' },
	none = { theme = 'none' },
	highlight = {},
	close = {},
}

-- The theme a profile saved that this version doesn't have (a later version's)
-- reads as this one, so every frame still draws.
local FALLBACK = 'thick'

-- The name a Theme override draws in: it, or the profile's, or FALLBACK for a
-- name this version doesn't have. (st:SetBorderColor asks it without a look.)
-- InsetIn(look, kind, frame), below.
local InsetIn

local function ResolveName(theme)
	local name = THEMES[theme] and theme or st.config.profile.theme.name
	if not THEMES[name] then name = FALLBACK end
	return name
end

-- The look for a Theme and Background override, drawn as kind:
-- { name, lines, inset, alpha, colors, kind }, or nil for None. A transparent
-- background is see-through at the profile's Opacity, even one asked for while
-- the Transparent background toggle is off. lines is how many lines in the
-- border reaches, Thick's 2 or Thin's 1 whatever the kind, and nil under
-- Blizzard. inset is that in UIParent's units (lines * st.line); Blizzard's is
-- the kind's art inset in whole pixels (st.ThemeArt.WholeInset), and nil with
-- no kind. A frame draws in its own units: InsetIn. An unknown saved theme
-- reads as FALLBACK; the saved name stays.
function st:ResolveTheme(theme, background, kind, skipInset)
	if theme == 'none' then return nil end
	local profile = st.config.profile
	local name = ResolveName(theme)

	local lines = LINES[name]
	local inset = lines and lines * st.line
	if name == 'blizzard' then
		-- skipInset: the caller reads no inset (a color pass), so none is worked out.
		inset = kind and not skipInset and st.ThemeArt.WholeInset(kind, UIParent) or nil
	end

	-- 'options' is SaftUI's own config windows' Background: the Theme tab's
	-- Options windows choice ('theme', 'solid' or 'transparent'), read here at
	-- each draw, so a change of it reaches every window on a recolor.
	if background == 'options' then
		background = profile.theme.optionsbackground
	end

	local transparent
	if background == 'transparent' then
		transparent = true
	elseif background == 'solid' then
		transparent = false
	else
		transparent = profile.theme.transparent
	end

	return {
		name = name,
		lines = lines,
		inset = inset,
		alpha = transparent and profile.theme.opacity or 1,
		colors = profile.templates[name],
		kind = kind,
	}
end

-- Whether a Theme and Background draw in Blizzard's art: an override to
-- Blizzard, or SaftUI's theme Blizzard for 'theme'. False for None. A
-- control's own code asks this to show its Blizzard art or its own look.
function st:IsBlizzardLook(theme, background)
	-- The name alone, as ResolveTheme draws it: no look table is made, so a color pass may ask.
	if theme == 'none' then return false end
	return ResolveName(theme) == 'blizzard'
end

-- The border color a Theme override draws (r, g, b), which is
-- st:ResolveTheme(theme).colors.bordercolor, or the profile's own theme's for None
-- (as a header line's callers fall back), with no look table made: a color pass may ask.
function st:ThemeBorderColor(theme)
	local name = ResolveName(theme ~= 'none' and theme or nil)
	return unpack(st.config.profile.templates[name].bordercolor)
end

-- The look an old template name drew: nil for none, and for no name, which drew
-- nothing. A name LEGACY doesn't know reads as a Theme. Nothing draws with an
-- old name any more; the tests compare a module's new defaults with the old
-- names they replaced through it.
function st:ResolveLegacyTemplate(name)
	if name == nil or name == '' then return nil end
	local legacy = LEGACY[name]
	if legacy then return st:ResolveTheme(legacy.theme, legacy.background) end
	return st:ResolveTheme(name)
end

-- How far in from a frame's edge its border reaches, drawn as kind: where
-- content sits inside a frame drawn with this Theme and Background. 2 lines
-- for Thick and 1 for Thin whatever the kind, the kind's under Blizzard in
-- whole pixels, 0 for None. In UIParent's units and pixels, or with frame (the
-- frame the content sits in, which may have a scale of its own: Blizzard
-- scales the Cooldown Manager's items and the buffs) in that frame's units and
-- whole pixels of it, as the border was drawn there (st:DrawnInset). The kind
-- is required, as a draw call's is: only a call whose Theme is None may leave
-- it out. Errors at the caller.
function st:ThemeInset(theme, background, kind, frame)
	if kind == nil then
		if theme ~= 'none' then
			error(('st:ThemeInset with Theme %s names no kind of frame (st.THEME_KINDS)'):format(tostring(theme)), 2)
		end
	elseif not st.THEME_KINDS[kind] then
		error(tostring(kind) .. ' is not a kind of frame', 2)
	end
	local look = st:ResolveTheme(theme, background, kind, frame ~= nil)
	if not look then return 0 end
	if frame then return InsetIn(look, kind, frame) end
	return look.inset or 0
end

-- Rewrites every saved template choice in tbl, at any depth, into a Theme and
-- a Background: a key template or <prefix>template (buttontemplate) holding a
-- string, an old name, becomes <prefix>theme and <prefix>background through
-- LEGACY, and is removed. none sets only the Theme; highlight, close and a
-- name that was never a template only go, so the module's defaults apply.
-- Every old choice was saved as a string, so any other value under such a key
-- is data and stays: a table is walked like any other (a unit frame profile
-- the user named 'raid template'). templates (the themes' colors) isn't a
-- template key. Only what's saved is read: the walk goes by pairs, never
-- through a table's __index (AceDB's '**' defaults would make keys), and each
-- table once. Running it again changes nothing.
function st:MigrateTemplateKeys(tbl)
	local seen = {}
	local function walk(t)
		if seen[t] then return end
		seen[t] = true
		-- Keys are added below, so they're collected before anything changes.
		local old, children = {}, {}
		for key, value in pairs(t) do
			if type(key) == 'string' and key:find('template$') and type(value) == 'string' then
				old[#old + 1] = key
			elseif type(value) == 'table' then
				children[#children + 1] = value
			end
		end
		for _, key in ipairs(old) do
			local prefix = key:sub(1, -#'template' - 1)
			local legacy = LEGACY[t[key]]
			if legacy then
				if legacy.theme then t[prefix .. 'theme'] = legacy.theme end
				if legacy.background then t[prefix .. 'background'] = legacy.background end
			end
			t[key] = nil
		end
		for _, child in ipairs(children) do walk(child) end
	end
	if type(tbl) == 'table' then walk(tbl) end
	return tbl
end

-- The fill of a header or footer strip: SaftUI's theme's border color, faint.
-- Strips follow the theme, not their window's override.
function st:ThemeHeaderColor()
	local r, g, b = unpack(st:ResolveTheme().colors.bordercolor)
	return r, g, b, HEADER_ALPHA
end

------------------------------------
--- Drawing ------------------------
------------------------------------

-- frame -> { theme, background, kind, inset, look, owner, backdrops, placed }:
-- the arguments each drawn frame was last drawn with, and the inset and name
-- of the look it was drawn in (0 and nil for None). For a backdrop made by
-- st:SetBackdrop or st:SetBackdropIn, owner is the frame it sits behind,
-- backdrops the caller's table st:SetBackdropIn keeps it in, and placed where
-- outside owner the engine last put it ({ side, top }: a window's top differs
-- under Blizzard), until anyone else moves it (Watch), so a redraw can tell
-- whether it still sits there.
local drawn = setmetatable({}, { __mode = 'k' })

-- owner -> the backdrop last drawn behind it with st:SetBackdrop or
-- st:SetBackdropIn, for st:DrawnInset. owner may be Blizzard's: it's only a key.
local owners = setmetatable({}, { __mode = 'k' })

-- The frame whose pixel a draw on frame is measured in: frame itself, where it
-- hangs under UIParent, else UIParent. Two kinds of frame don't: one under no
-- parent (a pooled widget waiting to be used, which a theme change draws again)
-- has a scale of 1, which isn't the one it will show at; and one under
-- WorldFrame (a plate's frame, drawn when it is made, before its scale is
-- pinned to UIParent's: UF:PinPlateScale) is about to take UIParent's. Both
-- are drawn in lines of UIParent's, the pixel they will have.
function st:DrawingFrame(frame)
	local top = frame
	for _ = 1, 100 do
		local parent = top:GetParent()
		if not parent then
			return top == UIParent and frame or UIParent
		end
		top = parent
	end
	return frame
end

-- One pixel of the frame a draw on frame is measured in (st:DrawingFrame), or
-- nil while the game can't say (no screen, or a secret scale).
function st:DrawPixelSize(frame)
	local scale = st:DrawingFrame(frame):GetEffectiveScale()
	if issecretvalue(scale) then return nil end
	return st:PixelFromScale(scale)
end

-- One line in frame's own units: lineWeight pixels of st:DrawPixelSize, or the
-- token's while the game can't say.
function st:DrawLineSize(frame)
	local pixel = st:DrawPixelSize(frame)
	return pixel and st.lineWeight * pixel or st.line
end

-- One line for a pixel st:DrawPixelSize gave (nil: the token's).
local function LineOf(pixel)
	return pixel and st.lineWeight * pixel or st.line
end

-- How far in a look reaches on frame, drawn as kind, in frame's own units and a
-- whole number of its pixels: lines of its line under Thick and Thin, the
-- kind's art inset in whole pixels under Blizzard, 0 for None. (look.inset is
-- the same in UIParent's units.)
-- pixel, when the caller has measured it already (a draw measures a frame once),
-- is st:DrawPixelSize(frame).
function InsetIn(look, kind, frame, pixel)
	if not look then return 0 end
	pixel = pixel or st:DrawPixelSize(frame)
	if look.lines then return look.lines * LineOf(pixel) end
	return kind and st.ThemeArt.WholeInset(kind, frame, pixel) or 0
end

local function Record(frame, theme, background, kind, look, owner, backdrops, pixel)
	local entry = drawn[frame]
	if not entry then
		entry = {}
		drawn[frame] = entry
	end
	entry.theme, entry.background, entry.kind = theme, background, kind
	entry.inset, entry.look = InsetIn(look, kind, frame, pixel), look and look.name
	-- A backdrop drawn again with st:SetTemplate (to reset a border a module
	-- tinted) still belongs to its frame.
	if owner then
		entry.owner, entry.backdrops = owner, backdrops
	end
	return entry
end

-- The record of frame, a drawn frame, or of the backdrop last drawn behind it.
local function DrawnEntry(frame)
	local entry = drawn[frame]
	if entry then return entry end
	local backdrop = owners[frame]
	return backdrop and drawn[backdrop]
end

-- The inset frame was last drawn at: how far in from its edge its border
-- reaches, as st:ThemeInset gives it for the look it was drawn in but in
-- frame's own units, a whole number of its pixels, and 0 for None. frame is a
-- drawn frame or the owner of a backdrop the engine drew; nil for a frame
-- never drawn.
function st:DrawnInset(frame)
	local entry = DrawnEntry(frame)
	return entry and entry.inset
end

-- The kind frame was last drawn as, by the same lookup as st:DrawnInset; nil
-- for a frame never drawn, or drawn None with no kind.
function st:DrawnKind(frame)
	local entry = DrawnEntry(frame)
	return entry and entry.kind
end

-- The theme frame was last drawn in, by the same lookup: 'thick', 'thin' or
-- 'blizzard'; nil for a frame never drawn, or drawn None. Whether a window
-- wears the metal (a close button's socket, panels.lua).
function st:DrawnTheme(frame)
	local entry = DrawnEntry(frame)
	return entry and entry.look
end

-- The frame frame's look is drawn on: frame itself (st:SetTemplate), or the
-- backdrop last drawn behind it (st:SetBackdrop, st:SetBackdropIn); nil for
-- a frame never drawn. What sits on the look anchors to it: a window's close
-- button in the metal's socket.
function st:DrawnFrame(frame)
	if drawn[frame] then return frame end
	return owners[frame]
end

-- Header and footer strips and the close button: SaftUI's theme's fill, no lines.
local function IsStrip(kind)
	return kind == 'header' or kind == 'close'
end

-- A draw call names the kind of frame it draws. Only one drawing None may
-- leave it out: it only clears. Errors at the draw call's caller.
local function CheckKind(theme, kind)
	if kind == nil then
		if theme ~= 'none' then
			error(('a draw call with Theme %s names no kind of frame (st.THEME_KINDS)'):format(tostring(theme)), 3)
		end
	elseif not st.THEME_KINDS[kind] then
		error(tostring(kind) .. ' is not a kind of frame', 3)
	end
end

-- The look a draw call draws (nil for None), and the kind it draws it as. A
-- header or close button takes SaftUI's theme whatever its call says. No kind
-- is None (CheckKind lets nothing else through).
local function DrawLook(theme, background, kind, skipInset)
	if kind == nil then return nil end
	if IsStrip(kind) then
		return st:ResolveTheme(nil, nil, kind, skipInset), kind
	end
	return st:ResolveTheme(theme, background, kind, skipInset), kind
end

-- Thick's dark lines: four strips, 3 lines wide under the frame's border line,
-- one line outside the frame and one inside it. This makes them; LayAltBorder
-- anchors and sizes them.
local function CreateAltBorder(frame)
	local strips = {}
	frame.altborder = strips
	for _, key in ipairs({ 'LEFT', 'RIGHT', 'TOP', 'BOTTOM' }) do
		local strip = frame:CreateTexture(nil, 'BACKGROUND')
		strip:SetTexture(st.BLANK_TEX)
		strips[key] = strip
	end
end

-- frame -> the line its strips were last laid at (only keys: frame.altborder is
-- walked as the strips).
local altLaid = setmetatable({}, { __mode = 'k' })

-- Lays Thick's strips for a line of frame's own units: each one line outside
-- the frame and three lines wide. A draw lays them, and a draw at the same line
-- finds them laid; a redraw after the scale changed lays them again (a color
-- pass never does: it draws nothing). A frame that can't be moved now (a
-- protected one in combat) keeps the strips it has until its next draw, unless
-- they were never laid.
local function LayAltBorder(frame, line)
	local laid = altLaid[frame]
	if laid == line then return end
	if laid ~= nil and not st:CanMoveNow(frame) then return end
	altLaid[frame] = line
	local strips, width = frame.altborder, 3 * line

	local left = strips.LEFT
	left:ClearAllPoints()
	left:SetWidth(width)
	left:SetPoint('TOPLEFT', frame, 'TOPLEFT', -line, line)
	left:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', -line, -line)

	local right = strips.RIGHT
	right:ClearAllPoints()
	right:SetWidth(width)
	right:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', line, line)
	right:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', line, -line)

	local top = strips.TOP
	top:ClearAllPoints()
	top:SetHeight(width)
	top:SetPoint('TOPLEFT', frame, 'TOPLEFT', line, line)
	top:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -line, line)

	local bottom = strips.BOTTOM
	bottom:ClearAllPoints()
	bottom:SetHeight(width)
	bottom:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', line, -line)
	bottom:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -line, -line)
end

-- Puts a look's colors and alpha on a drawn frame. Moves nothing. A Blizzard
-- look is st.ThemeArt's to color.
local function Color(frame, look, kind)
	if look.name == 'blizzard' then
		st.ThemeArt.Color(frame, look, kind)
	elseif kind == 'header' then
		frame:SetBackdropColor(st:ThemeHeaderColor())
		frame:SetBackdropBorderColor(0, 0, 0, 0)
	elseif kind == 'close' then
		frame:SetBackdropColor(unpack(st.config.profile.templates.close.backdropcolor))
		frame:SetBackdropBorderColor(0, 0, 0, 0)
	else
		local colors = look.colors
		local r, g, b, a = unpack(colors.backdropcolor)
		frame:SetBackdropColor(r, g, b, a * look.alpha)
		frame:SetBackdropBorderColor(unpack(colors.bordercolor))
		if look.name == 'thick' and frame.altborder then
			for _, line in pairs(frame.altborder) do
				line:SetVertexColor(unpack(colors.altbordercolor))
			end
		end
	end
end

------------------------------------
--- Snapping -----------------------
------------------------------------

--[[
	How the engine treats the game's pixel snapping on what it draws:
	'unsnap' (shipped), 'round' or 'none'. Every width the engine draws is a
	whole number of pixels (the line tokens), but in-game experiment E5b
	(rerun, confirmed) showed that at a fractional scale a one-pixel line with
	the game's default texture snapping lost a side when it sat half a pixel off
	whole pixels, while with snapping off it was whole wherever it sat, and a
	two-pixel line was whole either way. So:
	  'unsnap'  turns texture snapping off (SetSnapToPixelGrid(false) and
	            SetTexelSnappingBias(0)) on the border and line textures the
	            engine owns: the pieces of a backdrop it drew, Thick's strips
	            and the own-color piece. A texture without the methods is left
	            alone. Never on a Blizzard frame's own regions.
	  'round'   turns SetRoundLayoutToNearestPixel(true) on for the drawn frame
	            and its own regions (the plates already do), and leaves texture
	            snapping as the game has it (E5's row 3). Kept as a switch.
	  'none'    nothing.
	It is done when a texture is made or drawn (a redraw), never by a color
	pass. Edges are still placed on whole pixels wherever the engine computes a
	placement: 'unsnap' is the safety for what sits off them.
]]
st.SNAP_DRAWN = 'unsnap'

-- The frames SnapDrawn found protected in combat, which it does after.
local snapWaiting = setmetatable({}, { __mode = 'k' })

local function SnapAfterCombat()
	-- PLAYER_REGEN_ENABLED can fire while combat is still on; wait again then.
	if st:QueueAfterCombat('SnapDrawn', SnapAfterCombat) then return end
	local frames = {}
	for frame in pairs(snapWaiting) do frames[#frames + 1] = frame end
	snapWaiting = setmetatable({}, { __mode = 'k' })
	for _, frame in ipairs(frames) do st:SnapDrawn(frame) end
end

-- Rounds one region's layout, or, for a protected one in combat, notes the
-- drawn frame to do it after.
local function SnapOne(region, drawnFrame)
	if type(region.SetRoundLayoutToNearestPixel) ~= 'function' then return end
	if InCombatLockdown() and region:IsProtected() then
		snapWaiting[drawnFrame] = true
		st:QueueAfterCombat('SnapDrawn', SnapAfterCombat)
		return
	end
	region:SetRoundLayoutToNearestPixel(true)
end

-- Turns texture snapping off on one texture the engine owns (not protected, so
-- it is done in combat too). A region without the methods is left alone.
local unsnapped = setmetatable({}, { __mode = 'k' }) -- textures already done; only keys

local function UnsnapOne(region)
	-- Nothing resets it, so once is enough.
	if unsnapped[region] then return end
	if type(region.SetSnapToPixelGrid) ~= 'function' or type(region.SetTexelSnappingBias) ~= 'function' then return end
	unsnapped[region] = true
	region:SetSnapToPixelGrid(false)
	region:SetTexelSnappingBias(0)
end

-- Handles one region of the engine's (the own-color piece, made after the draw).
function st:SnapRegion(region)
	local mode = st.SNAP_DRAWN
	if mode == 'unsnap' then
		UnsnapOne(region)
	elseif mode == 'round' then
		SnapOne(region, region)
	end
end

-- BackdropTemplate's own pieces, as fields of the frame.
local BACKDROP_PIECES = { 'TopLeftCorner', 'TopRightCorner', 'BottomLeftCorner', 'BottomRightCorner',
	'TopEdge', 'BottomEdge', 'LeftEdge', 'RightEdge', 'Center' }

-- After every draw and redraw (Paint), by st.SNAP_DRAWN: 'unsnap' turns
-- texture snapping off on the textures the engine owns on frame (a backdrop's
-- pieces, Thick's strips); 'round' puts the layout rounding on frame and its
-- own regions, never on a protected frame in combat (that waits for the end of
-- it); 'none' does nothing.
function st:SnapDrawn(frame)
	local mode = st.SNAP_DRAWN
	if mode == 'unsnap' then
		if frame.backdropInfo then
			-- The pieces of the backdrop the engine just set, not a region of the frame's own.
			for _, key in ipairs(BACKDROP_PIECES) do
				local piece = frame[key]
				if type(piece) == 'table' then UnsnapOne(piece) end
			end
		end
		if frame.altborder then
			for _, strip in pairs(frame.altborder) do UnsnapOne(strip) end
		end
		return
	end
	if mode ~= 'round' then return end
	SnapOne(frame, frame)
	for _, key in ipairs(BACKDROP_PIECES) do
		local piece = frame[key]
		if type(piece) == 'table' then SnapOne(piece, frame) end
	end
	if frame.altborder then
		for _, strip in pairs(frame.altborder) do SnapOne(strip, frame) end
	end
	local art = st.ThemeArt.Get(frame)
	if art then
		for _, set in ipairs({ art.pieces, art.over }) do
			for _, piece in pairs(set) do SnapOne(piece, frame) end
		end
		if art.own then SnapOne(art.own, frame) end
	end
end

-- Frames that aren't SaftUI's but are still drawn behind with st:SetBackdrop
-- (st:MarkForeign). Only keys.
local foreign = setmetatable({}, { __mode = 'k' })

-- Marks frame as not SaftUI's, for a caller that draws behind it with
-- st:SetBackdrop or st:SkinActionButton all the same (a frame drawn so that isn't
-- SaftUI's; the bags bar's slots, Hekili's and WeakAuras' frames now draw
-- through st:SetBackdropIn and keep the mark only for the record): the Blizzard
-- theme makes none of its art on it, as for st:SetBackdropIn's frames. Mark it
-- before its first draw. Writes nothing onto frame.
function st:MarkForeign(frame)
	foreign[frame] = true
end

-- The frame of SaftUI's a drawn frame's ring goes on, under the button's texts
-- and cooldown: the frame a backdrop of st:SetBackdrop's sits behind (entry,
-- the drawn frame's record). nil for any other, which st.ThemeArt gives a
-- frame of SaftUI's over the drawn frame: st:SetBackdropIn's frame and a
-- marked one (st:MarkForeign) aren't SaftUI's, a texture holds no textures,
-- and a frame drawn on itself may be a module's backdrop under someone else's
-- button (the totem bar's), which names the button as host in st:SetTemplate.
local function Host(entry)
	if entry and entry.host then return entry.host end
	local owner = entry and entry.owner
	if owner and not entry.backdrops and not foreign[owner] and owner:IsObjectType('Frame') then
		return owner
	end
end

-- Draws a look on frame as kind: Thick's dark lines, the border one line wide
-- and the background inside it, or a strip's fill with no lines. Every width
-- is lines of frame's own (LineIn), the record's inset in its own units
-- (InsetIn: Record has already made it). A Blizzard look is st.ThemeArt's to
-- draw, with Thick's lines hidden, a button's ring on host (Host) and the box
-- over over (the frame a backdrop sits behind, or the frame st:SetTemplate
-- was given); any other hides the frame's Blizzard art. No look clears it.
local function PaintLook(frame, look, kind, host, pixel, over)
	if not look or look.name == 'blizzard' then
		if frame.altborder then
			for _, line in pairs(frame.altborder) do line:Hide() end
		end
		if look then
			st.ThemeArt.Paint(frame, look, kind, host, pixel, over)
		else
			frame:SetBackdrop(nil)
			st.ThemeArt.Clear(frame)
		end
		return
	end

	st.ThemeArt.Clear(frame)
	if not frame.altborder then
		CreateAltBorder(frame)
	end
	local line = LineOf(pixel)
	local outer = look.name == 'thick' and not IsStrip(kind)
	LayAltBorder(frame, line)
	for _, strip in pairs(frame.altborder) do
		if outer then strip:Show() else strip:Hide() end
	end

	local inset = IsStrip(kind) and 0 or InsetIn(look, kind, frame, pixel)
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = st.BLANK_TEX,
			edgeFile = st.BLANK_TEX,
			edgeSize = line,
			tile = false, tileSize = 0,
			insets = {
				left = inset,
				right = inset,
				top = inset,
				bottom = inset
			}
		})
	end

	Color(frame, look, kind)
end

-- Draws a look on frame (PaintLook), then st:SnapDrawn.
local function Paint(frame, look, kind, host, pixel, over)
	PaintLook(frame, look, kind, host, pixel, over)
	st:SnapDrawn(frame)
end

-- Where a look's backdrop sits outside its owner, drawn as kind: { side, top },
-- its inset on the sides and the bottom, and above the owner the same, or
-- under Blizzard how far the kind's art reaches down (a window's title bar). In
-- the owner's units: lines of the owner's line, or whole pixels of the owner.
local function Placement(look, kind, owner)
	local pixel = st:DrawPixelSize(owner)
	if look.name == 'blizzard' then
		return { side = st.ThemeArt.WholeInset(kind, owner, pixel), top = st.ThemeArt.WholeTop(kind, owner, pixel) }
	end
	local side = look.lines * LineOf(pixel)
	return { side = side, top = side }
end

--[[
	Whether a backdrop still sits outside its owner where DrawBackdrop put it.
	Many callers anchor their backdrop themselves after drawing it (an action
	button's fills the button), and a redraw must leave those anchors alone.

	The engine keeps that in its own record (placed) and never asks the game
	where a backdrop is: a backdrop on a nameplate (a plate's bars, its cast
	icon, its aura buttons) is anchored to the plate through its owner, and the
	game's plates are anchor restricted, so GetPoint, GetRect and the edges
	error for addon code on anything anchored to one ("Can't measure
	restricted regions"). Setting its anchors is allowed, in combat too.

	So every way of moving a region's anchors is post-hooked on the backdrop,
	once, when the engine first places it (SaftUI's own frame: rule 1 of
	.agents/taint.md is about Blizzard's), and a call by anyone but the engine
	forgets placed: the backdrop is then its caller's, wherever the caller put
	it, until a draw (not a redraw) places it again. The ones the client
	lacks are skipped.
]]
local MOVES = { 'ClearAllPoints', 'SetPoint', 'SetAllPoints', 'ClearPoint', 'SetPointsOffset', 'AdjustPointsOffset', 'ClearPointsOffset' }

local watched = setmetatable({}, { __mode = 'k' }) -- backdrops whose moves are hooked; only keys
local placing -- the backdrop DrawBackdrop is placing now: its own moves don't count

local function Moved(backdrop)
	if backdrop == placing then return end
	local entry = drawn[backdrop]
	if entry then entry.placed = nil end
end

local function Watch(backdrop)
	if watched[backdrop] then return end
	watched[backdrop] = true
	for _, name in ipairs(MOVES) do
		if type(backdrop[name]) == 'function' then hooksecurefunc(backdrop, name, Moved) end
	end
end

-- Places a backdrop the look's inset outside owner (place, a Placement) and
-- notes it. placed is nil while it's moved, so a call that errors on the way
-- leaves the backdrop counted as its caller's, never moved by a redraw.
local function Place(backdrop, owner, entry, place)
	Watch(backdrop)
	entry.placed = nil
	placing = backdrop
	backdrop:ClearAllPoints()
	backdrop:SetPoint('TOPLEFT', owner, 'TOPLEFT', -place.side, place.top)
	backdrop:SetPoint('BOTTOMRIGHT', owner, 'BOTTOMRIGHT', place.side, -place.side)
	placing = nil
	entry.placed = place
end

-- Draws a backdrop frame of SaftUI's behind owner, records it, and places it the
-- look's inset outside owner (a Placement: a window's reaches its title bar
-- above it under Blizzard). A redraw places it only while it still sits where
-- the engine last put it (placed, which nothing measures: Watch); one its
-- caller anchored is repainted where it is, and the caller's UpdateConfig
-- anchors it again. Sets owner.thick for st:SetBackdrop (not for
-- st:SetBackdropIn, whose frames aren't SaftUI's). Returns the look, nil for
-- None (which only clears it).
local function DrawBackdrop(backdrop, owner, backdrops, theme, background, kind, redraw)
	local look, drawKind = DrawLook(theme, background, kind)
	local pixel = look and st:DrawPixelSize(backdrop)
	local entry = Record(backdrop, theme, background, kind, look, owner, backdrops, pixel)
	if not redraw then owners[owner] = backdrop end
	if look then
		if not redraw or entry.placed then
			Place(backdrop, owner, entry, Placement(look, drawKind, owner))
		end
		if not backdrops then
			-- true or false, so thick is only nil on a frame never given a backdrop
			owner.thick = look.name == 'thick'
		end
	end
	Paint(backdrop, look, drawKind, Host(entry), pixel, owner)
	return look
end

-- Draws theme and background on frame as kind (see the top of this file).
-- host, for a frame drawn on itself behind a button that holds its own icon
-- and texts (the totem bar's, which is Blizzard's and so isn't marked as an
-- owner), is that button: under Blizzard the frame's ring and own-color piece
-- are textures of it, between its icon and its texts, where a holder frame
-- over it would cover them. It's remembered for a redraw.
-- over, for a frame drawn on itself that is another frame's backdrop (a
-- module's own), is that frame: under Blizzard the box sits around it, the
-- kind's reach outside it, as around a backdrop's owner; with none the box is
-- on frame's own bounds. It's remembered for a redraw too, and a backdrop the
-- engine drew behind an owner keeps its owner.
function st:SetTemplate(frame, theme, background, kind, host, over)
	CheckKind(theme, kind)
	local look, drawKind = DrawLook(theme, background, kind)
	-- The host of this draw: the one given, or the last draw's. The record is
	-- made first, so what the art reads of it (st:DrawnInset) is this draw's.
	local last = drawn[frame]
	local useHost = host or Host(last)
	local useOver = over or (last and (last.over or last.owner))
	local pixel = look and st:DrawPixelSize(frame)
	local entry = Record(frame, theme, background, kind, look, nil, nil, pixel)
	entry.host, entry.over = host, useOver
	Paint(frame, look, drawKind, useHost, pixel, useOver)
end

-- Draws theme and background on a frame of SaftUI's (frame.backdrop), made the
-- first time, one level below frame and the theme's border outside it, so frame's
-- own content isn't covered. Sets frame.thick, whether it's drawn Thick. For a
-- frame that isn't SaftUI's use st:SetBackdropIn, which writes nothing onto it.
function st:SetBackdrop(frame, theme, background, kind)
	CheckKind(theme, kind)
	if not frame.backdrop then
		if not DrawLook(theme, background, kind) then return end
		if not frame.GetObjectType then return end

		local isTexture = frame:GetObjectType() == 'Texture'
		local parent = isTexture and frame:GetParent() or frame
		frame.backdrop = st:CreateFrame('frame', nil, parent)
		local level = parent:GetFrameLevel()
		if not issecretvalue(level) then frame.backdrop:SetFrameLevel(max(0, level - 1)) end

		if isTexture then
			-- The backdrop lives on the texture, not its parent
			frame:HookScript('OnShow', function(self)
				self.backdrop:Show()
			end)

			frame:HookScript('OnHide', function(self)
				self.backdrop:Hide()
			end)
		end
	end

	DrawBackdrop(frame.backdrop, frame, nil, theme, background, kind)
end

-- st:SetBackdrop for a frame that isn't SaftUI's (a Blizzard tooltip, a dropdown
-- list): the backdrop frame is kept in `backdrops`, the caller's weak table keyed
-- by the frame, and nothing is written onto the frame (.agents/taint.md, rule 1;
-- st:SetBackdrop would set .backdrop and .thick). Returns the backdrop frame, or
-- nil for None.
--
-- Made here, the backdrop is a child of frame one level under it. A caller that
-- wants it elsewhere makes its own frame of SaftUI's and puts it in
-- backdrops[frame] first; this draws on that one and places it the theme's
-- border outside frame. That's also how to draw behind a texture, which has no
-- frame level to make one under (a buff's icon, Misc's Blizzard_BuffFrame.lua;
-- a micro button's panel with its own alpha, Minimap's microbuttons.lua).
function st:SetBackdropIn(backdrops, frame, theme, background, kind)
	CheckKind(theme, kind)
	local backdrop = backdrops[frame]
	if not backdrop then
		if not DrawLook(theme, background, kind) then return end
		backdrop = st:CreateFrame('frame', nil, frame)
		local level = frame:GetFrameLevel()
		if not issecretvalue(level) then backdrop:SetFrameLevel(max(0, level - 1)) end
		backdrops[frame] = backdrop
	end

	if DrawBackdrop(backdrop, frame, backdrops, theme, background, kind) then
		return backdrop
	end
end

-- Puts a frame's own border color on a drawn frame (the frame the caller
-- holds: x.backdrop, backdrops[x], or one drawn with st:SetTemplate), or with
-- no r puts the look's own border back. Under Thick and Thin that is the
-- backdrop's border (a strip's none); under Blizzard it is the look's own
-- (st.ThemeArt.SetBorder): the border art tinted, the white icon border or the
-- equipped border shown in the color, or a small frame's line. A control, a
-- frame never drawn and one drawn None are left alone: a control shows its
-- state in art of its own. A recolor or redraw takes the color off again, so
-- the module that set it sets it on OnColorsChanged('theme') too.
-- What ThemeArt.SetBorder reads of a look (its colors), reused: a recolor runs
-- this for every border it holds, so it makes no look table per call.
local borderLook = {}

function st:SetBorderColor(frame, r, g, b, a)
	local entry = drawn[frame]
	if not entry then return end
	local kind = entry.kind
	if kind == nil then return end
	-- The look's name and colors, as DrawLook would resolve them, with no table.
	local strip = IsStrip(kind)
	local theme = (not strip) and entry.theme or nil
	if theme == 'none' then return end
	local name = ResolveName(theme)
	local colors = st.config.profile.templates[name]
	if name == 'blizzard' then
		borderLook.name, borderLook.colors = name, colors
		st.ThemeArt.SetBorder(frame, borderLook, kind, Host(entry), r, g, b, a)
	elseif r then
		frame:SetBackdropBorderColor(r, g, b, a or 1)
	elseif strip then
		frame:SetBackdropBorderColor(0, 0, 0, 0)
	else
		frame:SetBackdropBorderColor(unpack(colors.bordercolor))
	end
end

-- frame -> color(frame), which puts back the colors frame's own code gives its
-- backdrop (st:KeepOwnColors).
local ownColors = setmetatable({}, { __mode = 'k' })

-- Keeps the colors color(frame) puts on a drawn frame's backdrop through a
-- theme recolor or redraw: color(frame) runs again after each. For a widget's
-- state (a thumb under the mouse, a picked button); nil forgets it. frame may
-- be Blizzard's: it's only a key here.
function st:KeepOwnColors(frame, color)
	ownColors[frame] = color
end

-- A color(frame) can keep the colors of another frame, one first drawn by
-- this redraw (a plate's border moving to another frame), which would add a
-- key while ownColors is walked (undefined for next in Lua 5.1: keys skipped
-- or seen twice). So the frames are taken first and walked as a copy, each
-- with the color kept for it when its turn comes; one first kept during the
-- walk waits for the next.
local function PutOwnColors()
	local frames = {}
	for frame in pairs(ownColors) do frames[#frames + 1] = frame end
	for _, frame in ipairs(frames) do
		local color = ownColors[frame]
		if color then xpcall(color, geterrorhandler(), frame) end
	end
end

-- Puts the theme's colors on one recorded frame, moving nothing.
local function Recolor(frame, entry)
	-- A color pass reads no inset: Blizzard's is not worked out.
	local look, kind = DrawLook(entry.theme, entry.background, entry.kind, true)
	if look then Color(frame, look, kind) end
end

-- Draws one recorded frame again with the arguments it was drawn with, and
-- records the inset it's now drawn at.
local function Redraw(frame, entry)
	if entry.owner then
		DrawBackdrop(frame, entry.owner, entry.backdrops, entry.theme, entry.background, entry.kind, true)
	else
		local look, kind = DrawLook(entry.theme, entry.background, entry.kind)
		local pixel = look and st:DrawPixelSize(frame)
		entry.inset, entry.look = InsetIn(look, kind, frame, pixel), look and look.name
		Paint(frame, look, kind, Host(entry), pixel, entry.over)
	end
end

-- After a theme color or the opacity changed: puts the colors and alpha on every
-- drawn frame, moving nothing, and the colors kept with st:KeepOwnColors back
-- on, then tells modules (OnColorsChanged('theme')), so borders they color
-- themselves are colored again. Each frame is colored on its own: one that
-- errors is reported and the rest are still colored.
function st:RecolorThemed()
	for frame, entry in pairs(drawn) do
		xpcall(Recolor, geterrorhandler(), frame, entry)
	end
	PutOwnColors()
	st:ColorsChanged('theme')
end

-- After the theme or the Transparent background toggle changed, and on every
-- profile switch, copy or reset (Config:UpdateConfig): draws every drawn frame
-- again, itself and once, with the arguments it was drawn with, and clears one
-- that now resolves to None; then puts the colors kept with st:KeepOwnColors
-- back on. A backdrop moves to the theme's border if it still sits where it was
-- drawn; one its caller anchored itself is repainted where it is. Each frame is
-- drawn on its own: one that errors is reported and the rest are still drawn.
function st:RedrawThemed()
	-- Drawing records again, so walk a copy.
	local frames = {}
	for frame in pairs(drawn) do frames[#frames + 1] = frame end

	for _, frame in ipairs(frames) do
		xpcall(Redraw, geterrorhandler(), frame, drawn[frame])
	end
	PutOwnColors()
end
