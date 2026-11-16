local st = SaftUI

--[[
	The drawing helpers of the interaction states (the spec,
	docs/superpowers/specs/2026-11-15-saftui-interaction-states-design.md,
	section 3): a widget says once what shape it is (st:AddStates) and which of
	its parts are its edge, text, mark and glyph; from then on its code only says
	which states hold (st:SetState). The colors come from Media/states.lua
	(st:StateColor and its kin: the Accent, derived), and every state frame
	follows the 'accent' group, so a change of the Accent or of a derivation
	setting reaches it through the live color mechanism (Media/colors.lua).

	The pieces, all textures of SaftUI's, never a field on any frame (taint rule
	1: the record is kept here, in weak tables keyed by the frame):
	  Layer  hover and pushed: the body's tint, BLEND, ARTWORK -8, inside the edge
	  Fill   selected: Fill's ramp texture (st.textures.stateFade), ARTWORK -7
	  Edge   selected and focus: the widget's own border in the Accent
	  Bar    a row's left bar or a tab's underline, two lines, ARTWORK 1
	  Mark   a check box's square, floor(size / 6) in
	  Solid  a thumb's or knob's whole fill
	  Glyph  a bare icon's or link's own color
	  Alpha  disabled
	An icon button (shape 'icon') is shown by the game: its pieces are the
	button's own highlight, pushed and checked textures, which a pass colors.

	What a pass touches (Ruling 12): every game piece, on every call; a scripted
	piece only while it shows; an edge only while selected or focused; a text only
	while it sits on a piece. A widget at rest costs a pass one call and no setter.
	st:PaintStates and what a pass runs only color, set a Fill's texture
	coordinates and set an alpha (.agents/taint.md): nothing is shown, hidden,
	placed or made there, so a pass is safe in combat. st:SetState shows and hides.

	Under the Blizzard look (opts.blizzard, else the theme the frame was drawn in)
	the pieces are held at alpha 0 and the edge is left to the art, which draws
	the states itself.
]]

local SHAPES = {
	box = { layer = true, fill = true, edge = true },
	row = { layer = true, fill = true, bar = 'left' },
	tab = { layer = true, fill = true, bar = 'bottom' },
	check = { layer = true, fill = true, edge = true, mark = true },
	thumb = { solid = true },
	knob = { solid = true },
	icon = {},
	mover = { layer = true, fill = true, edge = true },
	glyph = {},
}
local KEYS = { hover = true, pushed = true, selected = true, focus = true, disabled = true }

-- frame -> its record, the pieces ever made for it (a pool that releases a frame
-- and adds it again finds its textures), and the frames whose scripts are hooked.
local records = setmetatable({}, { __mode = 'k' })
local made = setmetatable({}, { __mode = 'k' })
local hooked = setmetatable({}, { __mode = 'k' })

local function ST() return st.States end

-- (a font string has SetVertexColor too: it is colored with SetTextColor)
local function IsTexture(object) return type(object.SetTextColor) ~= 'function' and type(object.SetVertexColor) == 'function' end

------------------------------------------------------------------ what shows

-- The Layer's, the Fill's and the Edge's color names for the states that hold:
-- pushed wins over hover; selected + hover is the lighter tone unless pushed;
-- focus is the Accent edge while not selected. nil: not shown.
local function View(rec)
	local layer = rec.pushed and 'pushed' or rec.hover and 'hover' or nil
	local fill, edge
	if rec.selected then
		local lit = rec.hover and not rec.pushed
		fill, edge = lit and 'fillHover' or 'fill', lit and 'edgeHover' or 'edge'
	elseif rec.focus then
		edge = 'edge'
	end
	return layer, fill, edge
end

-- The edge, in r, g, b, or the widget's own back (r nil), by the record's kind
-- (Ruling 10).
local function PutEdge(rec, r, g, b)
	local kind = rec.edgeKind
	if not kind then return end
	local frame = rec.frame
	if kind == 'backdrop' then
		if r then frame:SetBackdropBorderColor(r, g, b, 1) else frame:SetBackdropBorderColor(unpack(st.BOX_COLORS.edge)) end
	elseif kind == 'theme' then
		local drawn = rec.drawn or st:DrawnFrame(frame)
		if not drawn then return end
		if r then st:SetBorderColor(drawn, r, g, b, 1) else st:SetBorderColor(drawn) end
	elseif type(kind) == 'function' then
		kind(frame, r, g, b)
	end
end

local function PutText(rec, r, g, b)
	local texts = rec.texts
	for i = 1, #texts do texts[i]:SetTextColor(r, g, b) end
end

-- A color the glyph or solid takes, by the kind of object it is.
local function Tint(object, r, g, b)
	if IsTexture(object) then object:SetVertexColor(r, g, b, 1) else object:SetTextColor(r, g, b) end
end

local function TintGlyphs(rec, r, g, b)
	local glyphs = rec.glyphs
	for i = 1, #glyphs do Tint(glyphs[i], r, g, b) end
end

-- What the label takes over its body: the body, the Layer, the Fill at its
-- strongest, then Text > Normal or the dark text by contrast.
local function PickText(rec, d, layer, fill)
	local r, g, b = rec.bodyR, rec.bodyG, rec.bodyB
	local c
	if layer then
		c = d[layer]
		r, g, b = ST().Mix(r, g, b, c[1], c[2], c[3], c[4])
	end
	if fill then
		c = d[fill]
		r, g, b = ST().Mix(r, g, b, c[1], c[2], c[3], c[4])
	end
	local n = st:Color('text', 'normal')
	return ST().PickText(n.r, n.g, n.b, r, g, b)
end

local function TextRest(rec)
	local fn = rec.opts.textRest
	if fn then return fn(rec.frame) end
	local n = st:Color('text', 'normal')
	return n.r, n.g, n.b
end

-- The solid a thumb or knob wears under hover or pushed, in the object it has.
local function PutSolid(rec, r, g, b)
	local opts = rec.opts
	local target = opts.solid
	if type(target) == 'function' then
		target(rec.frame, r, g, b)
	elseif target or rec.glyphs[1] or opts.mark then
		local t = target or rec.glyphs[1] or opts.mark
		t:SetVertexColor(r, g, b, 1)
	else
		local drawn = rec.drawn or st:DrawnFrame(rec.frame) or rec.frame
		if drawn.SetBackdropColor then drawn:SetBackdropColor(r, g, b, 1) end
	end
end

local function SolidRest(rec)
	local fn = rec.opts.solidRest
	if fn then return fn(rec.frame) end
	local rest = ST().THUMB_REST
	return rest[1], rest[2], rest[3]
end

------------------------------------------------------------------ painting (colors only)

-- Colors everything that shows, from the cache or a preview's derived. Only
-- colors, a Fill's texture coordinates and the disabled alpha are set. explicit
-- (st:PaintStates, a widget's own redraw) also puts a thumb's, knob's or glyph's
-- rest color back, which a theme redraw may have reset; a pass of the Accent
-- group does not.
local function Colors(rec, d, explicit)
	local active = rec.hover or rec.pushed or rec.selected or rec.focus
	if not active and not rec.game and not rec.disabled and not (explicit and (rec.solid or rec.glyphObject)) then return end
	d = d or ST().Current()
	local host = rec.host
	if rec.disabled then host:SetAlpha(d.d) end
	if rec.blizzard then return end
	local c
	if rec.hoverPiece then
		c = d.hover
		rec.hoverPiece:SetVertexColor(c[1], c[2], c[3], c[4])
	end
	if rec.pushedPiece then
		c = d.pushed
		rec.pushedPiece:SetVertexColor(c[1], c[2], c[3], c[4])
	end
	if rec.checkedPiece then
		c = d.fill
		rec.checkedPiece:SetVertexColor(c[1], c[2], c[3], c[4])
		rec.checkedPiece:SetTexCoord(0, 1 / d.f, 0, 1)
	end
	if not active then
		if explicit then
			if rec.solid then PutSolid(rec, SolidRest(rec)) end
			if rec.glyphObject and rec.glyphRest then TintGlyphs(rec, rec.glyphRest(rec.frame)) end
		end
		return
	end
	local layer, fill, edge = View(rec)
	if layer and rec.layer then
		c = d[layer]
		rec.layer:SetVertexColor(c[1], c[2], c[3], c[4])
	end
	if fill and rec.fill then
		c = d[fill]
		rec.fill:SetVertexColor(c[1], c[2], c[3], c[4])
		rec.fill:SetTexCoord(0, 1 / d.f, 0, 1)
	end
	if edge then
		c = d[edge]
		if rec.selected then
			if rec.bar then rec.bar:SetVertexColor(c[1], c[2], c[3], c[4]) end
			if rec.mark then rec.mark:SetVertexColor(c[1], c[2], c[3], c[4]) end
		end
		if rec.edgeKind then PutEdge(rec, c[1], c[2], c[3]) end
	end
	if #rec.texts > 0 and (layer or fill) then PutText(rec, PickText(rec, d, layer, fill)) end
	if rec.glyphObject and (layer or rec.selected) then
		c = d[(rec.hover or rec.pushed) and 'edgeHover' or 'edge']
		TintGlyphs(rec, c[1], c[2], c[3])
	end
	if rec.solid and (rec.hover or rec.pushed) then
		local sr, sg, sb = SolidRest(rec)
		PutSolid(rec, st:StateSolid(rec.pushed and 'pushed' or 'hover', sr, sg, sb, d))
	end
end

-- What a pass of the Accent group runs for a record.
local function PaintRecord(rec) Colors(rec, nil) end

------------------------------------------------------------------ showing

local function Place(texture, host, inset)
	texture:ClearAllPoints()
	texture:SetPoint('TOPLEFT', host, 'TOPLEFT', inset, -inset)
	texture:SetPoint('BOTTOMRIGHT', host, 'BOTTOMRIGHT', -inset, inset)
end

local function PlaceBar(rec)
	local bar, host, inset = rec.bar, rec.host, rec.inset
	local thick = 2 * (st:GetLineSize(host) or 1)
	bar:ClearAllPoints()
	if rec.barSide == 'bottom' then
		bar:SetPoint('BOTTOMLEFT', host, 'BOTTOMLEFT', inset, inset)
		bar:SetPoint('BOTTOMRIGHT', host, 'BOTTOMRIGHT', -inset, inset)
		bar:SetHeight(thick)
	else
		bar:SetPoint('TOPLEFT', host, 'TOPLEFT', inset, -inset)
		bar:SetPoint('BOTTOMLEFT', host, 'BOTTOMLEFT', inset, inset)
		bar:SetWidth(thick)
	end
end

-- The check's square: floor(size / 6) units in from each side (Ruling 14).
local function PlaceMark(rec)
	local host = rec.host
	local w, h = host:GetWidth(), host:GetHeight()
	if type(w) ~= 'number' or type(h) ~= 'number' then return end
	local m = st:RoundToPixel(math.floor(math.min(w, h) / 6), host)
	rec.mark:ClearAllPoints()
	rec.mark:SetPoint('TOPLEFT', host, 'TOPLEFT', m, -m)
	rec.mark:SetPoint('BOTTOMRIGHT', host, 'BOTTOMRIGHT', -m, m)
end

-- Shows and hides what the states say, then colors it. What SetState runs: out of
-- a pass.
local function Refresh(rec)
	local layer, fill, edge = View(rec)
	if rec.layer then rec.layer:SetShown(layer ~= nil) end
	if rec.fill then rec.fill:SetShown(fill ~= nil) end
	local selected = rec.selected and true or false
	if rec.bar then
		if selected then PlaceBar(rec) end
		rec.bar:SetShown(selected)
	end
	if rec.mark then
		if selected then PlaceMark(rec) end
		rec.mark:SetShown(selected)
	end
	local d = ST().Current()
	Colors(rec, d)
	if rec.blizzard then return end
	-- the edge back to the widget's own when no state holds it
	if not edge and rec.edgeLit then PutEdge(rec) end
	rec.edgeLit = edge ~= nil
	-- the label's own color back when nothing is under it
	if #rec.texts > 0 then
		if layer or fill then
			rec.textLit = true
		elseif rec.textLit then
			rec.textLit = false
			PutText(rec, TextRest(rec))
		end
	end
	if rec.glyphObject then
		if layer or selected then
			rec.glyphLit = true
		elseif rec.glyphLit then
			rec.glyphLit = false
			if rec.glyphRest then TintGlyphs(rec, rec.glyphRest(rec.frame)) end
		end
	end
	if rec.solid then
		if rec.hover or rec.pushed then
			rec.solidLit = true
		elseif rec.solidLit then
			rec.solidLit = false
			PutSolid(rec, SolidRest(rec))
		end
	end
end

------------------------------------------------------------------ the record

-- The Blizzard look: the caller's say, else the theme the frame was drawn in.
local function IsBlizzard(rec)
	local fn = rec.opts.blizzard
	if fn then return fn(rec.frame) and true or false end
	return st:DrawnTheme(rec.frame) == 'blizzard'
end

-- What the label sits on, for the text pick (Ruling 8, 11): the caller's body, else the
-- fill the theme drew behind it, else the kit's button fill.
local function ReadBody(rec)
	local body = rec.opts.body
	if type(body) == 'function' then
		rec.bodyR, rec.bodyG, rec.bodyB = body(rec.frame)
	elseif type(body) == 'table' then
		rec.bodyR, rec.bodyG, rec.bodyB = body[1], body[2], body[3]
	else
		local drawn = rec.drawn or st:DrawnFrame(rec.frame)
		local r, g, b
		if drawn and drawn.GetBackdropColor then r, g, b = drawn:GetBackdropColor() end
		if type(r) ~= 'number' then
			local bg = st.BOX_COLORS.bg
			r, g, b = bg[1], bg[2], bg[3]
		end
		rec.bodyR, rec.bodyG, rec.bodyB = r, g, b
	end
end

local function Texts(rec)
	local text = rec.opts.text
	local list = {}
	if text then
		if type(text.GetObjectType) == 'function' then list[1] = text else
			for i = 1, #text do list[i] = text[i] end
		end
	end
	rec.texts = list
end

local function Piece(rec, kind, layer, sublevel)
	local pieces = made[rec.frame]
	local texture = pieces[kind]
	if not texture then
		texture = rec.host:CreateTexture(nil, layer)
		texture:SetDrawLayer(layer, sublevel)
		pieces[kind] = texture
	end
	return texture
end

-- Makes the pieces the shape and the options call for, once each.
local function MakePieces(rec)
	local opts, shape = rec.opts, SHAPES[rec.shape]
	local host = rec.host
	if shape.layer and not rec.layer then
		local t = Piece(rec, 'layer', 'ARTWORK', -8)
		t:SetTexture(st.BLANK_TEX)
		t:SetBlendMode('BLEND')
		t:Hide()
		rec.layer = t
	end
	if shape.fill and not rec.fill then
		local t = Piece(rec, 'fill', 'ARTWORK', -7)
		t:SetTexture(st.textures.stateFade, 'CLAMP', 'CLAMP')
		t:SetBlendMode('BLEND')
		t:SetTexCoord(0, 1, 0, 1)
		t:Hide()
		rec.fill = t
	end
	local side = opts.bar or shape.bar
	if side and not rec.bar then
		local t = Piece(rec, 'bar', 'ARTWORK', 1)
		t:SetTexture(st.BLANK_TEX)
		t:Hide()
		rec.bar = t
	end
	rec.barSide = side
	if opts.mark then
		rec.mark = opts.mark
	elseif shape.mark and not rec.mark then
		local t = Piece(rec, 'mark', 'OVERLAY', 0)
		t:SetTexture(st.BLANK_TEX)
		t:Hide()
		rec.mark = t
	end
	-- an icon button's pieces: the game's own highlight, pushed and checked textures. With
	-- game the button's current ones are adopted and only the missing ones made and handed over.
	local given = opts.pieces
	if given then
		rec.hoverPiece, rec.pushedPiece, rec.checkedPiece = given.hover, given.pushed, given.checked
	elseif opts.game and rec.shape == 'icon' then
		if not rec.hoverPiece then
			rec.hoverPiece = host.GetHighlightTexture and host:GetHighlightTexture() or nil
			if not rec.hoverPiece then
				rec.hoverPiece = Piece(rec, 'hover', 'OVERLAY', 0)
				rec.hoverPiece:SetTexture(st.BLANK_TEX)
				if host.SetHighlightTexture then host:SetHighlightTexture(rec.hoverPiece, 'BLEND') end
			end
		end
		if not rec.pushedPiece then
			rec.pushedPiece = host.GetPushedTexture and host:GetPushedTexture() or nil
			if not rec.pushedPiece then
				rec.pushedPiece = Piece(rec, 'pushed', 'OVERLAY', 0)
				rec.pushedPiece:SetTexture(st.BLANK_TEX)
				if host.SetPushedTexture then host:SetPushedTexture(rec.pushedPiece) end
			end
		end
		if opts.checked and not rec.checkedPiece and host.SetCheckedTexture then
			rec.checkedPiece = host.GetCheckedTexture and host:GetCheckedTexture() or nil
			if not rec.checkedPiece then
				rec.checkedPiece = Piece(rec, 'checked', 'OVERLAY', 0)
				host:SetCheckedTexture(rec.checkedPiece)
			end
		end
	end
	rec.game = (rec.hoverPiece or rec.pushedPiece or rec.checkedPiece) and true or false
end

local function OnEnter(self)
	local rec = records[self]
	if rec and not rec.noWire then st:SetState(self, 'hover', true) end
end
local function OnLeave(self)
	local rec = records[self]
	if rec and not rec.noWire then st:SetState(self, 'hover', false) end
end
local function OnMouseDown(self, button)
	local rec = records[self]
	if rec and not rec.noWire and (button == nil or button == 'LeftButton') then st:SetState(self, 'pushed', true) end
end
local function OnMouseUp(self, button)
	local rec = records[self]
	if rec and not rec.noWire and (button == nil or button == 'LeftButton') then st:SetState(self, 'pushed', false) end
end
local function OnHide(self)
	local rec = records[self]
	if not rec or rec.noWire then return end
	if rec.hover then st:SetState(self, 'hover', false) end
	if rec.pushed then st:SetState(self, 'pushed', false) end
end

-- After a theme recolor or redraw (st:KeepOwnColors): the look may have changed
-- (Blizzard or not, the edge's inset, the body), so what changed is read again,
-- and the edge the theme just reset is put back. No point is moved unless the
-- inset did.
local Restyle, StyleGame
local function Kept(rec)
	local frame = rec.frame
	if records[frame] ~= rec then return end
	local blizzard = IsBlizzard(rec)
	local inset = rec.opts.inset or st:DrawnInset(rec.host) or 0
	local drawn = rec.edgeKind == 'theme' and st:DrawnFrame(frame) or nil
	if blizzard ~= rec.blizzard or inset ~= rec.inset or drawn ~= rec.drawn then
		Restyle(rec)
		return
	end
	ReadBody(rec)
	Colors(rec, nil)
end

-- Puts the game pieces' texture, wrap, blend and texture coordinates back to SaftUI's look
-- (after Blizzard's art, or a skinner's own styling, drew on them): the highlight and pushed
-- textures are flat and BLEND, the checked one the fade. The points and draw layers are the
-- skinner's. Never under the Blizzard look.
function StyleGame(rec)
	local host, hover, pushed, checked = rec.host, rec.hoverPiece, rec.pushedPiece, rec.checkedPiece
	if hover then
		hover:SetTexture(st.BLANK_TEX)
		hover:SetTexCoord(0, 1, 0, 1)
		hover:SetBlendMode('BLEND')
		-- a highlight handed no blend mode is additive: hand it again with BLEND
		if rec.opts.game and host.SetHighlightTexture and host.GetHighlightTexture and host:GetHighlightTexture() == hover then
			host:SetHighlightTexture(hover, 'BLEND')
		end
	end
	if pushed then
		pushed:SetTexture(st.BLANK_TEX)
		pushed:SetTexCoord(0, 1, 0, 1)
		pushed:SetBlendMode('BLEND')
	end
	if checked then
		checked:SetTexture(st.textures.stateFade, 'CLAMP', 'CLAMP')
		checked:SetTexCoord(0, 1 / st:StateFade(), 0, 1)
		checked:SetBlendMode('BLEND')
	end
end

-- Reads the look again and puts the pieces where it says: out of a pass.
function Restyle(rec)
	local opts, frame = rec.opts, rec.frame
	rec.host = opts.host or frame
	rec.blizzard = IsBlizzard(rec)
	rec.inset = opts.inset or st:DrawnInset(rec.host) or 0
	local kind = opts.edge
	-- no edge said: a frame the theme engine drew has its border colored through the engine
	if kind == nil and SHAPES[rec.shape].edge and st:DrawnFrame(frame) then kind = 'theme' end
	rec.edgeKind = kind or nil
	rec.drawn = kind == 'theme' and st:DrawnFrame(frame) or nil
	rec.solid = SHAPES[rec.shape].solid and true or false
	-- glyph (a texture, a font string or a list) is painted on every shape; with no glyphRest
	-- its rest color is left alone
	local glyph, glyphs = opts.glyph, {}
	if glyph then
		if type(glyph.GetObjectType) == 'function' then glyphs[1] = glyph else
			for i = 1, #glyph do glyphs[i] = glyph[i] end
		end
	end
	rec.glyphs, rec.glyphObject, rec.glyphRest = glyphs, glyphs[1], opts.glyphRest
	Texts(rec)
	ReadBody(rec)
	MakePieces(rec)
	-- Under Blizzard the scripted pieces SaftUI made are held at alpha 0. The game pieces
	-- (an icon button's highlight, pushed and checked textures, and opts.pieces) and a
	-- mark the caller gave are left wholly alone: ThemeArt.StyleState draws Blizzard's art on them.
	local alpha = rec.blizzard and 0 or 1
	local mine = made[frame]
	for _, kind in ipairs({ 'layer', 'fill', 'bar', 'mark' }) do
		if mine[kind] then mine[kind]:SetAlpha(alpha) end
	end
	if rec.layer then Place(rec.layer, rec.host, rec.inset) end
	if rec.fill then Place(rec.fill, rec.host, rec.inset) end
	if rec.bar then PlaceBar(rec) end
	if rec.mark then PlaceMark(rec) end
	for _, kind in ipairs({ 'hover', 'pushed', 'checked' }) do
		if mine[kind] then Place(mine[kind], rec.host, rec.inset) end
	end
	if rec.game and not rec.blizzard then StyleGame(rec) end
	rec.noWire = opts.wire == false or (opts.wire == nil and rec.shape == 'icon')
	if not rec.noWire and not hooked[frame] then
		hooked[frame] = true
		frame:HookScript('OnEnter', OnEnter)
		frame:HookScript('OnLeave', OnLeave)
		frame:HookScript('OnMouseDown', OnMouseDown)
		frame:HookScript('OnMouseUp', OnMouseUp)
		frame:HookScript('OnHide', OnHide)
	end
	st:KeepOwnColors(rec, rec.edgeKind == 'theme' and Kept or nil)
	Refresh(rec)
end

------------------------------------------------------------------ the API

-- Makes frame a state frame of shape ('box', 'row', 'tab', 'check', 'thumb',
-- 'knob', 'icon', 'mover' or 'glyph'). opts, all optional:
--   host       the frame the pieces are made on (default frame): a frame of SaftUI's when frame is Blizzard's
--   inset      units in from host's edges for the Layer, Fill and Bar (default: st:DrawnInset(host), else 0)
--   edge       'backdrop' (SetBackdropBorderColor), 'theme' (st:SetBorderColor on the drawn frame), function(frame, r, g, b)
--              (r nil: the rest edge back), or false
--   bar        'left' | 'bottom' (a row's, a tab's by default)
--   text       a font string or a list of them; textRest = function(frame) -> r, g, b (Text > Normal if nil)
--   body       { r, g, b } or function(frame) -> r, g, b: what the text sits on, for the pick
--   mark       the check's square (a texture; one is made when the shape is a check)
--   glyph      a texture, a font string or a list of them, colored by the states on every shape; glyphRest = function(frame) -> r, g, b
--   solid      a thumb's or knob's fill: a texture, or function(frame, r, g, b); else the knob's glyph or the thumb's backdrop
--   solidRest  function(frame) -> r, g, b: a thumb's or knob's rest color (ST.THUMB_REST if nil)
--   game       true for 'icon': the button's own highlight, pushed and (checked = true) checked textures are adopted, the missing made
--   pieces     for 'icon' instead of game: { hover =, pushed =, checked = } existing textures, colored only
--   wire       false: no scripts (default true but for 'icon': HookScript on OnEnter, OnLeave, OnMouseDown, OnMouseUp, OnHide)
--   blizzard   function(frame) -> boolean: while true the pieces are held at alpha 0 and the edge is left alone
-- A second call merges: each field it gives replaces the first's, the pieces stay, and the frame is restyled.
function st:AddStates(frame, shape, opts)
	if not frame then error('SaftUI: AddStates needs a frame', 2) end
	if not SHAPES[shape] then error('SaftUI: AddStates: no shape ' .. tostring(shape), 2) end
	local rec = records[frame]
	if rec then
		if rec.shape ~= shape then
			error(('SaftUI: AddStates: the frame is a %s already, not a %s'):format(rec.shape, shape), 2)
		end
	else
		rec = { frame = frame, shape = shape, opts = {}, texts = {}, hover = false, pushed = false, selected = false,
			focus = false, disabled = false }
		made[frame] = made[frame] or {}
		records[frame] = rec
	end
	for key, value in pairs(opts or {}) do rec.opts[key] = value end
	if not rec.followed then
		rec.followed = true
		st:FollowColor(rec, 'accent', nil, PaintRecord)
	end
	Restyle(rec)
	return frame
end

-- key: 'hover', 'pushed', 'selected', 'focus' or 'disabled'. Shows, hides and
-- colors what that changes. Hover and pushed are ignored while disabled, which
-- also dims the frame (Ruling 13).
function st:SetState(frame, key, on)
	local rec = records[frame]
	if not rec then error('SaftUI: SetState: not a state frame (st:AddStates first)', 2) end
	if not KEYS[key] then error('SaftUI: SetState: no state ' .. tostring(key), 2) end
	on = on and true or false
	if key == 'disabled' then
		rec.disabled = on
		if on then rec.hover, rec.pushed = false, false end
		rec.host:SetAlpha(on and st:StateAlpha() or 1)
	elseif rec.disabled and (key == 'hover' or key == 'pushed') then
		rec[key] = false
	else
		rec[key] = on
	end
	Refresh(rec)
end

function st:GetState(frame, key)
	local rec = records[frame]
	if not rec then return nil end
	if not KEYS[key] then error('SaftUI: GetState: no state ' .. tostring(key), 2) end
	return rec[key]
end

-- Colors only: what a pass runs. derived is optional, a preview's own.
function st:PaintStates(frame, derived)
	local rec = records[frame]
	if not rec then error('SaftUI: PaintStates: the frame has no states (st:AddStates first)', 2) end
	Colors(rec, derived, true)
end

-- After a look change (Blizzard or not, a new inset): out of a pass.
function st:RestyleStates(frame)
	local rec = records[frame]
	if rec then Restyle(rec) end
end

-- A pool releasing the frame: its states are cleared (the widget looks at rest),
-- and it and its follow are forgotten. Its pieces stay for the next AddStates.
function st:RemoveStates(frame)
	local rec = records[frame]
	if not rec then return end
	rec.hover, rec.pushed, rec.selected, rec.focus = false, false, false, false
	Refresh(rec)
	if rec.disabled then rec.host:SetAlpha(1) end
	st:FollowColor(rec, 'accent', nil, nil)
	st:KeepOwnColors(rec, nil)
	records[frame] = nil
end

------------------------------------------------------------------ the test seam

local function Rgb(get, object)
	local r, g, b, a = get(object)
	return { r, g, b, a }
end

-- What a state frame looks like now, as plain data. Allocates: tests only,
-- never in a pass.
function st:StateLook(frame)
	local rec = records[frame]
	if not rec then return nil end
	local look = { shape = rec.shape, hover = rec.hover, pushed = rec.pushed, selected = rec.selected, focus = rec.focus,
		disabled = rec.disabled, alpha = rec.host:GetAlpha(), blizzard = rec.blizzard, pieces = {} }
	local function texture(t)
		local r, g, b, a = t:GetVertexColor()
		local layer, sublevel = t:GetDrawLayer()
		return { shown = t:IsShown(), r = r, g = g, b = b, a = a, layer = layer, sublevel = sublevel,
			blend = t:GetBlendMode(), alpha = t:GetAlpha(), texture = t:GetTexture(), right = select(5, t:GetTexCoord()) }
	end
	if rec.layer then look.layer = texture(rec.layer); look.pieces.layer = rec.layer end
	if rec.fill then look.fill = texture(rec.fill); look.pieces.fill = rec.fill end
	if rec.bar then
		local t = texture(rec.bar)
		t.width = rec.barSide == 'bottom' and rec.bar:GetHeight() or rec.bar:GetWidth()
		look.bar = t; look.pieces.bar = rec.bar
	end
	if rec.mark then look.mark = texture(rec.mark); look.pieces.mark = rec.mark end
	if rec.hoverPiece then look.hover_piece = texture(rec.hoverPiece); look.pieces.hover = rec.hoverPiece end
	if rec.pushedPiece then look.pushed_piece = texture(rec.pushedPiece); look.pieces.pushed = rec.pushedPiece end
	if rec.checkedPiece then look.checked_piece = texture(rec.checkedPiece); look.pieces.checked = rec.checkedPiece end
	local edged = rec.edgeKind == 'theme' and (rec.drawn or st:DrawnFrame(frame)) or rec.edgeKind == 'backdrop' and frame or nil
	if edged and edged.GetBackdropBorderColor then
		local r, g, b, a = edged:GetBackdropBorderColor()
		look.edge = { r = r, g = g, b = b, a = a }
	end
	if rec.texts[1] then
		local r, g, b = rec.texts[1]:GetTextColor()
		look.text = { r = r, g = g, b = b }
	end
	if rec.glyphObject then
		local r, g, b
		local g1 = rec.glyphObject
		if IsTexture(g1) then r, g, b = g1:GetVertexColor() else r, g, b = g1:GetTextColor() end
		look.glyph = { r = r, g = g, b = b }
	end
	if rec.solid then
		local opts = rec.opts
		local target = type(opts.solid) ~= 'function' and (opts.solid or rec.glyphs[1] or opts.mark) or nil
		local r, g, b
		if target then
			r, g, b = target:GetVertexColor()
		else
			local drawn = rec.drawn or st:DrawnFrame(frame) or frame
			if drawn.GetBackdropColor then r, g, b = drawn:GetBackdropColor() end
		end
		look.solid = { r = r, g = g, b = b }
	end
	return look
end
