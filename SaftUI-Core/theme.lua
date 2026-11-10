local st = SaftUI

--[[
	SaftUI's theme engine.

	The profile's theme (st.config.profile.theme) is Thick or Thin, with a
	Transparent background toggle and the Opacity it uses. Each theme keeps its
	own colors in st.config.profile.templates[name]. A module can override the
	theme with a Theme ('theme', 'thick', 'thin' or 'none') and a Background
	('theme', 'solid' or 'transparent'); 'theme', or nil, follows the profile's.
	st:ResolveTheme turns the pair into the look a frame is drawn with.

	Every draw call (st:SetTemplate, st:SetBackdrop, st:SetBackdropIn) names the
	kind of frame it draws (st.THEME_KINDS). Under Thick and Thin only the
	header strips and the close button draw differently; the kinds are there so
	a theme can draw each its own way.

	A call with no kind comes from code that hasn't moved to themes yet. Its
	theme argument is an old template name ('thicktransparent', 'thin',
	'highlight', ...), read through LEGACY, so it draws exactly as before.

	Each drawn frame is recorded with the arguments it was last drawn with, so a
	change to the theme reaches every frame: st:RecolorThemed for a color or the
	opacity, st:RedrawThemed for the theme or the toggle, which move borders.
	Colors a frame's own code puts on its backdrop (a scroll bar thumb's fill, a
	focused edit box's border) go back on after either (st:KeepOwnColors).
]]

-- The kinds of frame a draw call names.
st.THEME_KINDS = {
	panel = true,   -- a window: bags, bank, chat, the options window, the loot feed
	bar = true,     -- a unit frame or one of its bars, cast bars, experience and roll bars, swing timers
	action = true,  -- an action button
	slot = true,    -- bag, bank and currency slots
	aura = true,    -- buffs and debuffs
	tooltip = true,
	header = true,  -- header and footer strips
	close = true,   -- the close button
	small = true,   -- everything else: indicators, class power points, micro menu buttons
}

-- How far in a theme's border reaches: Thick draws a dark line, its border and
-- another dark line, Thin one line.
local INSETS = { thick = 2, thin = 1 }

-- A header or footer strip is the theme's border color at this alpha.
local HEADER_ALPHA = 0.4

-- An old template name's Theme and Background. highlight and close were never
-- real choices: they follow the theme (as draw calls they're the header and
-- close kinds, LEGACY_KINDS). none leaves the background unset.
local LEGACY = {
	thicktransparent = { theme = 'thick', background = 'transparent' },
	thintransparent = { theme = 'thin', background = 'transparent' },
	thick = { theme = 'thick', background = 'solid' },
	thin = { theme = 'thin', background = 'solid' },
	none = { theme = 'none' },
	highlight = {},
	close = {},
}
local LEGACY_KINDS = { highlight = 'header', close = 'close' }

-- The look for a Theme and Background override: { name, inset, alpha, colors },
-- or nil for None. A transparent background is see-through at the profile's
-- Opacity, even one asked for while the Transparent background toggle is off.
function st:ResolveTheme(theme, background)
	if theme == 'none' then return nil end
	local profile = st.config.profile
	local name = INSETS[theme] and theme or profile.theme.name

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
		inset = INSETS[name],
		alpha = transparent and profile.theme.opacity or 1,
		colors = profile.templates[name],
	}
end

-- The look an old template name drew: nil for none, and for no name, which drew
-- nothing. A name LEGACY doesn't know reads as a Theme.
function st:ResolveLegacyTemplate(name)
	if name == nil or name == '' then return nil end
	local legacy = LEGACY[name]
	if legacy then return st:ResolveTheme(legacy.theme, legacy.background) end
	return st:ResolveTheme(name)
end

-- How far in from a frame's edge its border reaches (2, 1, or 0 for None): where
-- content sits inside a frame drawn with this Theme and Background. An old
-- template name with no background is read as it drew.
function st:ThemeInset(theme, background)
	local look
	if background == nil and LEGACY[theme] then
		look = st:ResolveLegacyTemplate(theme)
	else
		look = st:ResolveTheme(theme, background)
	end
	return look and look.inset or 0
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

-- frame -> { theme, background, kind, owner, backdrops, placed }: the
-- arguments each drawn frame was last drawn with. For a backdrop made by
-- st:SetBackdrop or st:SetBackdropIn, owner is the frame it sits behind,
-- backdrops the caller's table st:SetBackdropIn keeps it in, and placed the
-- offset outside owner it was last put at, so a redraw can tell whether it
-- still sits there.
local drawn = setmetatable({}, { __mode = 'k' })

local function Record(frame, theme, background, kind, owner, backdrops)
	local entry = drawn[frame]
	if not entry then
		entry = {}
		drawn[frame] = entry
	end
	entry.theme, entry.background, entry.kind = theme, background, kind
	-- A backdrop drawn again with st:SetTemplate (to reset a border a module
	-- tinted) still belongs to its frame.
	if owner then
		entry.owner, entry.backdrops = owner, backdrops
	end
	return entry
end

-- Header and footer strips and the close button: SaftUI's theme's fill, no lines.
local function IsStrip(kind)
	return kind == 'header' or kind == 'close'
end

-- The look a draw call draws, and the kind it draws it as. A header or close
-- button takes SaftUI's theme whatever its call says. With no kind, theme is an
-- old template name.
local function DrawLook(theme, background, kind)
	if kind == nil then
		kind = LEGACY_KINDS[theme]
		if not kind then return st:ResolveLegacyTemplate(theme) end
	else
		assert(st.THEME_KINDS[kind], tostring(kind) .. ' is not a kind of frame')
	end
	if IsStrip(kind) then
		return st:ResolveTheme(), kind
	end
	return st:ResolveTheme(theme, background), kind
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

-- Puts a look's colors and alpha on a drawn frame. Moves nothing.
local function Color(frame, look, kind)
	if kind == 'header' then
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

-- Draws a look on frame as kind: Thick's dark lines, the 1px border and the
-- background inside it, or a strip's fill with no lines. No look clears it.
local function Paint(frame, look, kind)
	if not look then
		frame:SetBackdrop(nil)
		if frame.altborder then
			for _, line in pairs(frame.altborder) do line:Hide() end
		end
		return
	end

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

-- Whether a backdrop still sits offset outside owner, where DrawBackdrop put
-- it. Many callers anchor their backdrop themselves after drawing it (an action
-- button's fills the button), and a redraw must leave those anchors alone.
local function IsPlaced(backdrop, owner, offset)
	if not offset or backdrop:GetNumPoints() ~= 2 then return false end
	local want = { TOPLEFT = { -offset, offset }, BOTTOMRIGHT = { offset, -offset } }
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
-- look's inset outside owner. A redraw places it only while it still sits where
-- the last draw put it; one its caller anchored is repainted where it is, and
-- the caller's UpdateConfig anchors it again. Sets owner.thick for
-- st:SetBackdrop (not for st:SetBackdropIn, whose frames aren't SaftUI's).
-- Returns the look, nil for None (which only clears it).
local function DrawBackdrop(backdrop, owner, backdrops, theme, background, kind, redraw)
	local look, drawKind = DrawLook(theme, background, kind)
	local entry = Record(backdrop, theme, background, kind, owner, backdrops)
	if look then
		if not redraw or IsPlaced(backdrop, owner, entry.placed) then
			local offset = look.inset
			backdrop:ClearAllPoints()
			backdrop:SetPoint('TOPLEFT', owner, 'TOPLEFT', -offset, offset)
			backdrop:SetPoint('BOTTOMRIGHT', owner, 'BOTTOMRIGHT', offset, -offset)
			entry.placed = offset
		end
		-- Code not yet moved to themes reads the old name back from here.
		backdrop.template = kind == nil and theme or nil
		if not backdrops then
			-- true or false, so thick is only nil on a frame never given a backdrop
			owner.thick = look.name == 'thick'
		end
	end
	Paint(backdrop, look, drawKind)
	return look
end

-- Draws theme and background on frame as kind (see the top of this file). With
-- no kind, theme is an old template name.
function st:SetTemplate(frame, theme, background, kind)
	local look, drawKind = DrawLook(theme, background, kind)
	Paint(frame, look, drawKind)
	Record(frame, theme, background, kind)
end

-- Draws theme and background on a frame of SaftUI's (frame.backdrop), made the
-- first time, one level below frame and the theme's border outside it, so frame's
-- own content isn't covered. Sets frame.thick for st:CalculateSpacing. For a
-- frame that isn't SaftUI's use st:SetBackdropIn, which writes nothing onto it.
function st:SetBackdrop(frame, theme, background, kind)
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
-- nil for None. Frames only, not textures.
function st:SetBackdropIn(backdrops, frame, theme, background, kind)
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

-- After a theme color or the opacity changed: puts the colors and alpha on every
-- drawn frame, moving nothing, and the colors kept with st:KeepOwnColors back
-- on, then tells modules (OnColorsChanged('theme')), so borders they color
-- themselves are colored again.
function st:RecolorThemed()
	for frame, entry in pairs(drawn) do
		local look, kind = DrawLook(entry.theme, entry.background, entry.kind)
		if look then Color(frame, look, kind) end
	end
	PutOwnColors()
	st:ColorsChanged('theme')
end

-- After the theme or the Transparent background toggle changed: draws every
-- drawn frame again, itself and once, with the arguments it was drawn with, and
-- clears one that now resolves to None; then puts the colors kept with
-- st:KeepOwnColors back on. A backdrop drawn with a kind moves to the theme's
-- border if it still sits where it was drawn. Anything drawn with no kind is
-- code not yet moved to themes: it's repainted where it is, so it keeps the
-- place it has always had.
function st:RedrawThemed()
	-- Drawing records again, so walk a copy.
	local frames = {}
	for frame in pairs(drawn) do frames[#frames + 1] = frame end

	for _, frame in ipairs(frames) do
		local entry = drawn[frame]
		if entry.owner and entry.kind ~= nil then
			DrawBackdrop(frame, entry.owner, entry.backdrops, entry.theme, entry.background, entry.kind, true)
		else
			Paint(frame, DrawLook(entry.theme, entry.background, entry.kind))
		end
	end
	PutOwnColors()
end
