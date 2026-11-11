local st = SaftUI

--[[
	SaftUI's theme engine.

	The profile's theme (st.config.profile.theme) is Thick, Thin or Blizzard,
	with a Transparent background toggle and the Opacity it uses. Each theme
	keeps its own colors in st.config.profile.templates[name]. A module can
	override the theme with a Theme ('theme', 'thick', 'thin', 'blizzard' or
	'none') and a Background ('theme', 'solid' or 'transparent'); 'theme', or
	nil, follows the profile's. st:ResolveTheme turns the pair into the look a
	frame is drawn with.

	Every draw call (st:SetTemplate, st:SetBackdrop, st:SetBackdropIn) names the
	kind of frame it draws (st.THEME_KINDS), last. Under Thick and Thin only the
	header strips and the close button draw differently (a window draws as a
	panel, a control as a small frame). Blizzard draws each kind in Blizzard's
	own art for it, which themeart.lua describes and draws (st.ThemeArt), and
	its inset depends on the kind. A call with no kind is an error, unless
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
	bar = true,     -- a unit frame or one of its bars, cast bars, experience and roll bars, swing timers
	action = true,  -- an action button
	slot = true,    -- bag, bank and currency slots
	aura = true,    -- buffs and debuffs
	tooltip = true,
	header = true,  -- header and footer strips
	close = true,   -- the close button
	control = true, -- a small frame Blizzard draws with art of its own: buttons, check boxes, tabs, edit boxes
	small = true,   -- everything else: indicators, the micro menu's items
}

-- The themes this version has. A saved name that isn't one reads as FALLBACK.
local THEMES = { thick = true, thin = true, blizzard = true }

-- How far in Thick's and Thin's border reaches, whatever the kind: Thick draws
-- a dark line, its border and another dark line, Thin one line. Blizzard's is
-- each kind's own (st.ThemeArt.Inset).
local INSETS = { thick = 2, thin = 1 }

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

-- The look for a Theme and Background override, drawn as kind:
-- { name, inset, alpha, colors, kind }, or nil for None. A transparent
-- background is see-through at the profile's Opacity, even one asked for while
-- the Transparent background toggle is off. The inset is Thick's or Thin's
-- whatever the kind; Blizzard's is the kind's (st.ThemeArt.Inset), and nil
-- with no kind. An unknown saved theme reads as FALLBACK; the saved name stays.
function st:ResolveTheme(theme, background, kind)
	if theme == 'none' then return nil end
	local profile = st.config.profile
	local name = THEMES[theme] and theme or profile.theme.name
	if not THEMES[name] then name = FALLBACK end

	local inset = INSETS[name]
	if name == 'blizzard' then
		inset = kind and st.ThemeArt.Inset(kind) or nil
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
	local look = st:ResolveTheme(theme, background)
	return look ~= nil and look.name == 'blizzard'
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
-- content sits inside a frame drawn with this Theme and Background. 2 for
-- Thick and 1 for Thin whatever the kind, the kind's under Blizzard, 0 for
-- None. The kind is required, as a draw call's is: only a call whose Theme is
-- None may leave it out. Errors at the caller.
function st:ThemeInset(theme, background, kind)
	if kind == nil then
		if theme ~= 'none' then
			error(('st:ThemeInset with Theme %s names no kind of frame (st.THEME_KINDS)'):format(tostring(theme)), 2)
		end
	elseif not st.THEME_KINDS[kind] then
		error(tostring(kind) .. ' is not a kind of frame', 2)
	end
	local look = st:ResolveTheme(theme, background, kind)
	return look and look.inset or 0
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
-- outside owner it was last put ({ side, top }: a window's top differs under
-- Blizzard), so a redraw can tell whether it still sits there.
local drawn = setmetatable({}, { __mode = 'k' })

-- owner -> the backdrop last drawn behind it with st:SetBackdrop or
-- st:SetBackdropIn, for st:DrawnInset. owner may be Blizzard's: it's only a key.
local owners = setmetatable({}, { __mode = 'k' })

local function Record(frame, theme, background, kind, look, owner, backdrops)
	local entry = drawn[frame]
	if not entry then
		entry = {}
		drawn[frame] = entry
	end
	entry.theme, entry.background, entry.kind = theme, background, kind
	entry.inset, entry.look = look and look.inset or 0, look and look.name
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
-- reaches, as st:ThemeInset gives it for the look it was drawn in, and 0 for
-- None. frame is a drawn frame or the owner of a backdrop the engine drew; nil
-- for a frame never drawn.
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
local function DrawLook(theme, background, kind)
	if kind == nil then return nil end
	if IsStrip(kind) then
		return st:ResolveTheme(nil, nil, kind), kind
	end
	return st:ResolveTheme(theme, background, kind), kind
end

-- Thick's dark lines: 3px wide strips under the frame's 1px border, one pixel
-- outside it and one inside.
local function CreateAltBorder(frame)
	frame.altborder = {}

	local offset = 1
	local width = 3

	frame.altborder.LEFT = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.LEFT:SetWidth(width)
	frame.altborder.LEFT:SetPoint('TOPLEFT', frame, 'TOPLEFT', -offset, offset)
	frame.altborder.LEFT:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', -offset, -offset)
	frame.altborder.LEFT:SetTexture(st.BLANK_TEX)

	frame.altborder.RIGHT = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.RIGHT:SetWidth(width)
	frame.altborder.RIGHT:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', offset, offset)
	frame.altborder.RIGHT:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', offset, -offset)
	frame.altborder.RIGHT:SetTexture(st.BLANK_TEX)

	frame.altborder.TOP = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.TOP:SetHeight(width)
	frame.altborder.TOP:SetPoint('TOPLEFT', frame, 'TOPLEFT', offset, offset)
	frame.altborder.TOP:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -offset, offset)
	frame.altborder.TOP:SetTexture(st.BLANK_TEX)

	frame.altborder.BOTTOM = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.BOTTOM:SetHeight(width)
	frame.altborder.BOTTOM:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', offset, -offset)
	frame.altborder.BOTTOM:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -offset, -offset)
	frame.altborder.BOTTOM:SetTexture(st.BLANK_TEX)
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

-- Frames that aren't SaftUI's but are still drawn behind with st:SetBackdrop
-- (st:MarkForeign). Only keys.
local foreign = setmetatable({}, { __mode = 'k' })

-- Marks frame as not SaftUI's, for a caller that draws behind it with
-- st:SetBackdrop or st:SkinActionButton all the same (the bags bar's Blizzard
-- bag slots, Hekili's buttons): the Blizzard theme makes none of its art on
-- it, as for st:SetBackdropIn's frames. Mark it before its first draw. Writes
-- nothing onto frame.
function st:MarkForeign(frame)
	foreign[frame] = true
end

-- The frame of SaftUI's a drawn frame's ring goes on, under the button's texts
-- and cooldown: the frame a backdrop of st:SetBackdrop's sits behind (entry,
-- the drawn frame's record). nil for any other, which st.ThemeArt gives a
-- frame of SaftUI's over the drawn frame: st:SetBackdropIn's frame and a
-- marked one (st:MarkForeign) aren't SaftUI's, a texture holds no textures,
-- and a frame drawn on itself may be a module's backdrop under someone else's
-- button (the totem bar's).
local function Host(entry)
	local owner = entry and entry.owner
	if owner and not entry.backdrops and not foreign[owner] and owner:IsObjectType('Frame') then
		return owner
	end
end

-- Draws a look on frame as kind: Thick's dark lines, the 1px border and the
-- background inside it, or a strip's fill with no lines. A Blizzard look is
-- st.ThemeArt's to draw, with Thick's lines hidden, and a button's ring on
-- host (Host); any other hides the frame's Blizzard art. No look clears it.
local function Paint(frame, look, kind, host)
	if not look or look.name == 'blizzard' then
		if frame.altborder then
			for _, line in pairs(frame.altborder) do line:Hide() end
		end
		if look then
			st.ThemeArt.Paint(frame, look, kind, host)
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
	local outer = look.name == 'thick' and not IsStrip(kind)
	for _, line in pairs(frame.altborder) do
		if outer then line:Show() else line:Hide() end
	end

	local inset = IsStrip(kind) and 0 or look.inset
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = st.BLANK_TEX,
			edgeFile = st.BLANK_TEX,
			edgeSize = 1,
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

-- Where a look's backdrop sits outside its owner, drawn as kind: { side, top },
-- its inset on the sides and the bottom, and above the owner the same, or
-- under Blizzard how far the kind's art reaches down (a window's title bar).
local function Placement(look, kind)
	local top = look.name == 'blizzard' and st.ThemeArt.Top(kind) or look.inset
	return { side = look.inset, top = top }
end

-- Whether a backdrop still sits outside owner where DrawBackdrop put it
-- (placed, a Placement). Many callers anchor their backdrop themselves after
-- drawing it (an action button's fills the button), and a redraw must leave
-- those anchors alone.
local function IsPlaced(backdrop, owner, placed)
	if not placed or backdrop:GetNumPoints() ~= 2 then return false end
	local side = placed.side
	local want = { TOPLEFT = { -side, placed.top }, BOTTOMRIGHT = { side, -side } }
	for i = 1, 2 do
		local point, relativeTo, relativePoint, x, y = backdrop:GetPoint(i)
		if issecretvalue(relativeTo) or issecretvalue(x) or issecretvalue(y) then return false end
		local xy = want[point]
		if not xy or relativeTo ~= owner or relativePoint ~= point or x ~= xy[1] or y ~= xy[2] then
			return false
		end
		want[point] = nil
	end
	return true
end

-- Draws a backdrop frame of SaftUI's behind owner, records it, and places it the
-- look's inset outside owner (a Placement: a window's reaches its title bar
-- above it under Blizzard). A redraw places it only while it still sits where
-- the last draw put it; one its caller anchored is repainted where it is, and
-- the caller's UpdateConfig anchors it again. Sets owner.thick for
-- st:SetBackdrop (not for st:SetBackdropIn, whose frames aren't SaftUI's).
-- Returns the look, nil for None (which only clears it).
local function DrawBackdrop(backdrop, owner, backdrops, theme, background, kind, redraw)
	local look, drawKind = DrawLook(theme, background, kind)
	local entry = Record(backdrop, theme, background, kind, look, owner, backdrops)
	if not redraw then owners[owner] = backdrop end
	if look then
		if not redraw or IsPlaced(backdrop, owner, entry.placed) then
			local place = Placement(look, drawKind)
			backdrop:ClearAllPoints()
			backdrop:SetPoint('TOPLEFT', owner, 'TOPLEFT', -place.side, place.top)
			backdrop:SetPoint('BOTTOMRIGHT', owner, 'BOTTOMRIGHT', place.side, -place.side)
			entry.placed = place
		end
		if not backdrops then
			-- true or false, so thick is only nil on a frame never given a backdrop
			owner.thick = look.name == 'thick'
		end
	end
	Paint(backdrop, look, drawKind, Host(entry))
	return look
end

-- Draws theme and background on frame as kind (see the top of this file).
function st:SetTemplate(frame, theme, background, kind)
	CheckKind(theme, kind)
	local look, drawKind = DrawLook(theme, background, kind)
	Paint(frame, look, drawKind, Host(drawn[frame]))
	Record(frame, theme, background, kind, look)
end

-- Draws theme and background on a frame of SaftUI's (frame.backdrop), made the
-- first time, one level below frame and the theme's border outside it, so frame's
-- own content isn't covered. Sets frame.thick, whether it's drawn Thick. For a
-- frame that isn't SaftUI's use st:SetBackdropIn, which writes nothing onto it.
function st:SetBackdrop(frame, theme, background, kind)
	CheckKind(theme, kind)
	if not frame.backdrop then
		if not DrawLook(theme, background, kind) then return end
		if not frame.GetObjectType then return print('GetObjectType missing', debugstack()) end

		local isTexture = frame:GetObjectType() == 'Texture'
		local parent = isTexture and frame:GetParent() or frame
		frame.backdrop = st:CreateFrame('frame', nil, parent)
		frame.backdrop:SetFrameLevel(max(0, parent:GetFrameLevel() - 1))

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
		backdrop:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
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
function st:SetBorderColor(frame, r, g, b, a)
	local entry = drawn[frame]
	if not entry then return end
	local look, kind = DrawLook(entry.theme, entry.background, entry.kind)
	if not look then return end
	if look.name == 'blizzard' then
		st.ThemeArt.SetBorder(frame, look, kind, Host(entry), r, g, b, a)
	elseif r then
		frame:SetBackdropBorderColor(r, g, b, a or 1)
	elseif IsStrip(kind) then
		frame:SetBackdropBorderColor(0, 0, 0, 0)
	else
		frame:SetBackdropBorderColor(unpack(look.colors.bordercolor))
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

local function PutOwnColors()
	for frame, color in pairs(ownColors) do
		xpcall(color, geterrorhandler(), frame)
	end
end

-- Puts the theme's colors on one recorded frame, moving nothing.
local function Recolor(frame, entry)
	local look, kind = DrawLook(entry.theme, entry.background, entry.kind)
	if look then Color(frame, look, kind) end
end

-- Draws one recorded frame again with the arguments it was drawn with, and
-- records the inset it's now drawn at.
local function Redraw(frame, entry)
	if entry.owner then
		DrawBackdrop(frame, entry.owner, entry.backdrops, entry.theme, entry.background, entry.kind, true)
	else
		local look, kind = DrawLook(entry.theme, entry.background, entry.kind)
		Paint(frame, look, kind)
		entry.inset, entry.look = look and look.inset or 0, look and look.name
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
