--[[
	The game's widget API: frames, buttons, tooltips, textures, font strings
	and fonts, CreateFrame and CreateFont, UIParent and WorldFrame. Method
	names and arguments follow Blizzard_APIDocumentationGenerated (Gethe/
	wow-ui-source, forever branch).

	Strict: a widget answers only the methods defined here. Any other name is
	nil, so calling it errors with the method's name, as a missing API would.
	Add a method when a test needs it, and make it behave like the real one,
	including how it fails.

	Faithful:
	- Every method checks that its self is a widget of the right type, and
	  errors with "Wrong object type" if not, as the game does when a
	  FontString's SetText is called on a Button.
	- Widget state lives in a side table (stub.state), so a widget's own table
	  holds only what code puts on it, as in game. getmetatable(widget).__index
	  is the type's method table, which api.lua's *Direct helpers rely on.
	- Frames are laid out from their anchors and sizes, so GetLeft, GetWidth
	  and the rest work. UIParent fills the screen: its size is
	  GetPhysicalScreenSize times one pixel at its scale.
	- Showing or hiding runs OnShow / OnHide on every widget whose visibility
	  changes. Errors in scripts go to the game's error handler.

	Not mimicked: the game's layout pass, so OnSizeChanged never fires by
	itself (fire it with stub.fire_script); text wrapping (a font string is one
	line); OnUpdate; a backdrop's border textures; secret values; taint and
	protected frames; RegisterEvent takes any event name (the game errors
	"Attempt to register unknown event"); SetFont and SetTexture always
	succeed (in game a file that doesn't exist fails the call, or draws
	nothing).
]]

local states = setmetatable({}, { __mode = 'k' }) -- widget -> its state

-- A widget's state, for reading what the API has no getter for (e.g. a
-- texture's color: stub.state(texture).color_texture).
function stub.state(widget)
	return states[widget] or error('stub.state: not a widget: ' .. tostring(widget), 2)
end

-- Each widget type and the API groups it has, in order. A method checks that
-- its self has the group it's defined in.
local TYPES = {
	Frame = { 'Object', 'ScriptRegion', 'Frame' },
	Button = { 'Object', 'ScriptRegion', 'Frame', 'Button' },
	CheckButton = { 'Object', 'ScriptRegion', 'Frame', 'Button', 'CheckButton' },
	GameTooltip = { 'Object', 'ScriptRegion', 'Frame', 'GameTooltip' },
	ScrollFrame = { 'Object', 'ScriptRegion', 'Frame', 'ScrollFrame' },
	Slider = { 'Object', 'ScriptRegion', 'Frame', 'Slider' },
	EditBox = { 'Object', 'ScriptRegion', 'Frame', 'FontInstance', 'EditBox' },
	StatusBar = { 'Object', 'ScriptRegion', 'Frame', 'StatusBar' },
	Texture = { 'Object', 'ScriptRegion', 'Region', 'Texture' },
	FontString = { 'Object', 'ScriptRegion', 'Region', 'FontInstance', 'FontString' },
	Font = { 'Object', 'FontInstance', 'Font' },
}

-- The scripts each group has. SetScript, HookScript and GetScript error on
-- any other name, as the game does.
local SCRIPTS = {
	ScriptRegion = { 'OnShow', 'OnHide', 'OnEnter', 'OnLeave', 'OnMouseDown', 'OnMouseUp', 'OnMouseWheel' },
	Frame = { 'OnEvent', 'OnUpdate', 'OnSizeChanged', 'OnLoad', 'OnKeyDown', 'OnKeyUp', 'OnChar',
		'OnDragStart', 'OnDragStop', 'OnReceiveDrag', 'OnAttributeChanged' },
	Button = { 'OnClick', 'PreClick', 'PostClick', 'OnDoubleClick', 'OnEnable', 'OnDisable' },
	ScrollFrame = { 'OnScrollRangeChanged', 'OnVerticalScroll', 'OnHorizontalScroll' },
	Slider = { 'OnValueChanged', 'OnMinMaxChanged' },
	StatusBar = { 'OnValueChanged', 'OnMinMaxChanged' },
	EditBox = { 'OnTextChanged', 'OnEnterPressed', 'OnEscapePressed', 'OnTabPressed', 'OnEditFocusGained', 'OnEditFocusLost' },
}

local POINTS_H = {
	TOPLEFT = 'left', LEFT = 'left', BOTTOMLEFT = 'left',
	TOP = 'middle', CENTER = 'middle', BOTTOM = 'middle',
	TOPRIGHT = 'right', RIGHT = 'right', BOTTOMRIGHT = 'right',
}
local POINTS_V = {
	TOPLEFT = 'top', TOP = 'top', TOPRIGHT = 'top',
	LEFT = 'middle', CENTER = 'middle', RIGHT = 'middle',
	BOTTOMLEFT = 'bottom', BOTTOM = 'bottom', BOTTOMRIGHT = 'bottom',
}
local STRATA = {
	PARENT = true, BACKGROUND = true, LOW = true, MEDIUM = true, HIGH = true, DIALOG = true,
	FULLSCREEN = true, FULLSCREEN_DIALOG = true, TOOLTIP = true,
}
local DRAW_LAYERS = { BACKGROUND = true, BORDER = true, ARTWORK = true, OVERLAY = true, HIGHLIGHT = true }

local API = {} -- group -> { name = function(self, state, ...) }
for _, groups in pairs(TYPES) do
	for _, group in ipairs(groups) do
		API[group] = API[group] or {}
	end
end
local Object, ScriptRegion, Region, Frame, Button, GameTooltip, Texture, FontInstance, FontString =
	API.Object, API.ScriptRegion, API.Region, API.Frame, API.Button, API.GameTooltip,
	API.Texture, API.FontInstance, API.FontString
local CheckButton, ScrollFrame, Slider, StatusBar = API.CheckButton, API.ScrollFrame, API.Slider, API.StatusBar
local EditBox = API.EditBox

------------------------------------------------------------------ helpers

local function pack(...)
	return { n = select('#', ...), ... }
end

local function describe(widget)
	local s = states[widget]
	if not s then return type(widget) end
	return s.name and (s.type .. ' ' .. s.name) or ('unnamed ' .. s.type)
end

local THIS_FILE = debug.getinfo(1, 'S').source

-- Errors as the game's usage errors do: at the code that called the widget
-- method, the first stack level outside this file. Levels Lua 5.1 shows as
-- "(tail call)" (a method's wrapper tail-calls it) are skipped too.
local function usage(s, text)
	local level = 2
	while true do
		local info = debug.getinfo(level, 'S')
		if not info or (info.source ~= THIS_FILE and info.what ~= 'tail') then break end
		level = level + 1
	end
	error(('%s: %s'):format(s.name or ('<unnamed ' .. s.type .. '>'), text), level)
end

local function is_widget(value, group)
	local s = states[value]
	return s ~= nil and (group == nil or s.groups[group] == true)
end

local function number_arg(s, value, what)
	if type(value) ~= 'number' then usage(s, ('%s must be a number, got %s'):format(what, type(value))) end
	return value
end

local function has_script(s, script)
	for group in pairs(s.groups) do
		local names = SCRIPTS[group]
		if names then
			for _, name in ipairs(names) do
				if name == script then return true end
			end
		end
	end
	return false
end

local function check_script(s, script, method)
	if type(script) ~= 'string' or not has_script(s, script) then
		usage(s, ('%s(): %s doesn\'t have a "%s" script'):format(method, s.type, tostring(script)))
	end
end

-- Runs a widget's script handler and then its hooks, through the game's error
-- handler. Returns true if anything ran.
local function run_script(widget, script, ...)
	local s = states[widget]
	local args = pack(...)
	local ran = false
	local function call(fn)
		ran = true
		xpcall(function() fn(widget, unpack(args, 1, args.n)) end, geterrorhandler())
	end
	if s.scripts[script] then call(s.scripts[script]) end
	for _, hook in ipairs(s.hooks[script] or {}) do call(hook) end
	return ran
end

local serial = 0 -- creation order, which breaks ties between frames drawn at one level

local function new_widget(typeName, name, parent)
	local widget = setmetatable({ [0] = newproxy() }, TYPES[typeName].metatable)
	serial = serial + 1
	local s = {
		type = typeName, groups = TYPES[typeName].groups, name = name, parent = parent, serial = serial,
		points = {}, shown = true, alpha = 1, scale = 1, scripts = {}, hooks = {},
	}
	states[widget] = s
	if name then _G[name] = widget end
	return widget, s
end

------------------------------------------------------------------ visibility

local function is_visible(s)
	while s do
		if not s.shown then return false end
		s = s.parent and states[s.parent]
	end
	return true
end

-- widget and everything under it, parents before children.
local function subtree(widget, out)
	out[#out + 1] = widget
	local s = states[widget]
	for _, region in ipairs(s.regions or {}) do out[#out + 1] = region end
	for _, child in ipairs(s.children or {}) do subtree(child, out) end
	return out
end

-- Runs change, then OnShow / OnHide on each widget under widget whose
-- visibility it changed.
local function changing_visibility(widget, change)
	local tree = subtree(widget, {})
	local before = {}
	for i, w in ipairs(tree) do before[i] = is_visible(states[w]) end
	change()
	for i, w in ipairs(tree) do
		local now = is_visible(states[w])
		if now ~= before[i] then
			run_script(w, now and 'OnShow' or 'OnHide')
		end
	end
end

------------------------------------------------------------------ layout

local function effective_scale(s)
	local scale = s.scale
	local parent = s.parent
	while parent do
		local ps = states[parent]
		scale = scale * ps.scale
		parent = ps.parent
	end
	return scale
end

-- widget's left, right, bottom and top in its own units, or nil if it can't
-- be placed (no anchors, or anchored to something that can't be).
local function rect_of(widget, visiting)
	local s = states[widget]
	if s.fills_screen then
		-- One physical pixel in this widget's units, times the screen's pixels.
		local pixel = (768 / stub.screen_height) / effective_scale(s)
		return 0, stub.screen_width * pixel, 0, stub.screen_height * pixel
	end
	if #s.points == 0 or visiting[widget] then return nil end
	visiting[widget] = true
	local scale = effective_scale(s)
	local h, v = {}, {}
	for _, p in ipairs(s.points) do
		local l, r, b, t = rect_of(p.relativeTo, visiting)
		if not l then
			visiting[widget] = nil
			return nil
		end
		local k = effective_scale(states[p.relativeTo]) / scale -- its units to ours
		local side = POINTS_H[p.relativePoint]
		local x = side == 'left' and l or side == 'right' and r or (l + r) / 2
		side = POINTS_V[p.relativePoint]
		local y = side == 'bottom' and b or side == 'top' and t or (b + t) / 2
		h[POINTS_H[p.point]] = x * k + p.x
		v[POINTS_V[p.point]] = y * k + p.y
	end
	visiting[widget] = nil

	local w, ht = s.width or 0, s.height or 0
	local left, right = h.left, h.right
	if left and not right then right = left + w
	elseif right and not left then left = right - w
	elseif not left then left, right = h.middle - w / 2, h.middle + w / 2 end
	local bottom, top = v.bottom, v.top
	if bottom and not top then top = bottom + ht
	elseif top and not bottom then bottom = top - ht
	elseif not bottom then bottom, top = v.middle - ht / 2, v.middle + ht / 2 end
	return left, right, bottom, top
end

-- True if s is anchored on both of the opposite sides a and b, so its size
-- comes from its anchors rather than SetWidth / SetHeight.
local function anchored_across(s, sides, a, b)
	local has = {}
	for _, p in ipairs(s.points) do has[sides[p.point]] = true end
	return has[a] and has[b]
end

local function width_of(widget, s)
	if s.fills_screen or anchored_across(s, POINTS_H, 'left', 'right') then
		local l, r = rect_of(widget, {})
		if l then return r - l end
	end
	return s.width or 0
end

local function height_of(widget, s)
	if s.fills_screen or anchored_across(s, POINTS_V, 'bottom', 'top') then
		local _, _, b, t = rect_of(widget, {})
		if b then return t - b end
	end
	return s.height or 0
end

-- True if from's position depends on target: it is target, or anchored to
-- it directly or through other regions.
local function depends_on(from, target, seen)
	if from == target then return true end
	if seen[from] then return false end
	seen[from] = true
	for _, p in ipairs(states[from].points) do
		if depends_on(p.relativeTo, target, seen) then return true end
	end
	return false
end

-- Where a widget anchors when no relative region is given: its parent, or
-- the screen.
local function default_relative(s)
	return s.parent or WorldFrame
end

-- The region self would anchor to: relativeTo itself, the region a name
-- names, or by default the parent. Errors, as the game does, on anything
-- else and on an anchor that would make a loop.
local function resolve_relative(self, s, relativeTo, method)
	if type(relativeTo) == 'string' then
		local name = relativeTo
		relativeTo = _G[name]
		if not is_widget(relativeTo, 'ScriptRegion') then
			usage(s, ("%s(): Couldn't find region named '%s'"):format(method, name))
		end
	elseif relativeTo == nil then
		relativeTo = default_relative(s)
	elseif not is_widget(relativeTo, 'ScriptRegion') then
		usage(s, method .. '(): relativeTo must be a region')
	end
	if relativeTo == self then usage(s, method .. '(): Cannot anchor to itself') end
	if depends_on(relativeTo, self, {}) then usage(s, method .. '(): Cannot anchor to a region dependent on it') end
	return relativeTo
end

-- A point name, uppercased (the game ignores case). Errors on anything else.
local function point_name(s, point, what)
	local name = type(point) == 'string' and point:upper()
	if not POINTS_H[name] then usage(s, ('SetPoint(): invalid %s %s'):format(what, tostring(point))) end
	return name
end

------------------------------------------------------------------ Object

function Object.GetName(self, s) return s.name end
function Object.GetObjectType(self, s) return s.type end
function Object.IsObjectType(self, s, typeName) return s.groups[typeName] == true end
-- Forbidden objects (Blizzard's secure-only ones) are never made here.
function Object.IsForbidden(self, s) return false end

------------------------------------------------------------------ ScriptRegion (frames, textures, font strings)

function ScriptRegion.GetParent(self, s) return s.parent end

function ScriptRegion.SetParent(self, s, parent)
	if parent ~= nil and not is_widget(parent, 'Frame') then usage(s, 'SetParent(): parent must be a frame') end
	if parent == nil and not s.groups.Frame then usage(s, 'SetParent(): a region needs a parent') end
	if parent == s.parent then return end
	changing_visibility(self, function()
		local list = s.groups.Frame and 'children' or 'regions'
		if s.parent then
			local siblings = states[s.parent][list]
			for i, w in ipairs(siblings) do
				if w == self then table.remove(siblings, i) break end
			end
		end
		s.parent = parent
		if parent then
			table.insert(states[parent][list], self)
		end
		if s.groups.Frame then
			s.level = parent and states[parent].level + 1 or 0
		end
	end)
end

function ScriptRegion.Show(self, s)
	changing_visibility(self, function() s.shown = true end)
end
function ScriptRegion.Hide(self, s)
	changing_visibility(self, function() s.shown = false end)
end
function ScriptRegion.SetShown(self, s, shown)
	changing_visibility(self, function() s.shown = shown and true or false end)
end
function ScriptRegion.IsShown(self, s) return s.shown end
function ScriptRegion.IsVisible(self, s) return is_visible(s) end

function ScriptRegion.EnableMouse(self, s, enable) s.mouse_enabled = enable and true or false end
function ScriptRegion.IsMouseEnabled(self, s) return s.mouse_enabled == true end

-- Whether the cursor (stub.cursor_x, stub.cursor_y) is inside the region: a
-- rectangle test, in the region's own units.
local function cursor_inside(widget, s)
	local l, r, b, t = rect_of(widget, {})
	if not l then return false end
	local scale = effective_scale(s)
	local x, y = stub.cursor_x / scale, stub.cursor_y / scale
	return x >= l and x <= r and y >= b and y <= t
end

-- IsMouseOver is only the rectangle test, so it is true for a frame under
-- another one. The offsets aren't stubbed.
function ScriptRegion.IsMouseOver(self, s, ...)
	if select('#', ...) > 0 then usage(s, 'IsMouseOver(): offsets are not stubbed') end
	return is_visible(s) and cursor_inside(self, s)
end

-- The frame under the cursor that gets its OnEnter and OnLeave: the topmost
-- visible, mouse-enabled frame there. Higher strata win, then higher levels,
-- then the frame made later. A frame under another mouse-enabled frame (a menu
-- opened at the cursor) is under the cursor without being the focus.
local STRATA_ORDER = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }

local function draws_above(widget, s, other, os)
	local a, b = STRATA_ORDER[Frame.GetFrameStrata(widget, s)], STRATA_ORDER[Frame.GetFrameStrata(other, os)]
	if a ~= b then return a > b end
	if s.level ~= os.level then return s.level > os.level end
	return s.serial > os.serial
end

function ScriptRegion.IsMouseMotionFocus(self, s)
	local function takes_mouse(widget, ws)
		return ws.groups.Frame and ws.mouse_enabled and is_visible(ws) and cursor_inside(widget, ws)
	end
	if not takes_mouse(self, s) then return false end
	for other, os in pairs(states) do
		if other ~= self and takes_mouse(other, os) and draws_above(other, os, self, s) then
			return false
		end
	end
	return true
end
-- Stub widgets are never secure frames.
function ScriptRegion.IsProtected(self, s) return false, false end

function ScriptRegion.HasScript(self, s, script) return has_script(s, script) end
function ScriptRegion.GetScript(self, s, script)
	check_script(s, script, 'GetScript')
	return s.scripts[script]
end
-- Setting a script also drops its HookScript hooks, as in game.
function ScriptRegion.SetScript(self, s, script, fn)
	check_script(s, script, 'SetScript')
	if fn ~= nil and type(fn) ~= 'function' then usage(s, 'SetScript(): the handler must be a function or nil') end
	s.scripts[script] = fn
	s.hooks[script] = nil
end
function ScriptRegion.HookScript(self, s, script, fn)
	check_script(s, script, 'HookScript')
	if type(fn) ~= 'function' then usage(s, 'HookScript(): the hook must be a function') end
	s.hooks[script] = s.hooks[script] or {}
	table.insert(s.hooks[script], fn)
end

-- Anchors and size (the game's ScriptRegionResizing).
-- Setting a point the region already has replaces it.
function ScriptRegion.SetPoint(self, s, point, relativeTo, relativePoint, x, y)
	if type(relativeTo) == 'number' then -- SetPoint(point, x, y)
		relativeTo, relativePoint, x, y = nil, nil, relativeTo, relativePoint
	elseif type(relativePoint) == 'number' then -- SetPoint(point, relativeTo, x, y)
		relativePoint, x, y = nil, relativePoint, x
	end
	point = point_name(s, point, 'point')
	local p = {
		point = point,
		relativeTo = resolve_relative(self, s, relativeTo, 'SetPoint'),
		relativePoint = relativePoint and point_name(s, relativePoint, 'relative point') or point,
		x = number_arg(s, x or 0, 'offsetX'),
		y = number_arg(s, y or 0, 'offsetY'),
	}
	for i, existing in ipairs(s.points) do
		if existing.point == point then
			s.points[i] = p
			return
		end
	end
	s.points[#s.points + 1] = p
end
function ScriptRegion.SetAllPoints(self, s, relativeTo)
	relativeTo = resolve_relative(self, s, relativeTo, 'SetAllPoints')
	s.points = {
		{ point = 'TOPLEFT', relativeTo = relativeTo, relativePoint = 'TOPLEFT', x = 0, y = 0 },
		{ point = 'BOTTOMRIGHT', relativeTo = relativeTo, relativePoint = 'BOTTOMRIGHT', x = 0, y = 0 },
	}
end
function ScriptRegion.ClearAllPoints(self, s) s.points = {} end
function ScriptRegion.GetNumPoints(self, s) return #s.points end
function ScriptRegion.GetPoint(self, s, index)
	local p = s.points[index or 1]
	if p then return p.point, p.relativeTo, p.relativePoint, p.x, p.y end
end

function ScriptRegion.SetWidth(self, s, width) s.width = number_arg(s, width, 'width') end
function ScriptRegion.SetHeight(self, s, height) s.height = number_arg(s, height, 'height') end
function ScriptRegion.SetSize(self, s, width, height)
	s.width, s.height = number_arg(s, width, 'width'), number_arg(s, height, 'height')
end
function ScriptRegion.GetWidth(self, s) return width_of(self, s) end
function ScriptRegion.GetHeight(self, s) return height_of(self, s) end
function ScriptRegion.GetSize(self, s) return width_of(self, s), height_of(self, s) end

function ScriptRegion.GetLeft(self, s) return (rect_of(self, {})) end
function ScriptRegion.GetRight(self, s) return (select(2, rect_of(self, {}))) end
function ScriptRegion.GetBottom(self, s) return (select(3, rect_of(self, {}))) end
function ScriptRegion.GetTop(self, s) return (select(4, rect_of(self, {}))) end
function ScriptRegion.GetCenter(self, s)
	local l, r, b, t = rect_of(self, {})
	if l then return (l + r) / 2, (b + t) / 2 end
end
function ScriptRegion.GetRect(self, s)
	local l, r, b, t = rect_of(self, {})
	if l then return l, b, r - l, t - b end
end

------------------------------------------------------------------ Region (textures, font strings)

function Region.SetAlpha(self, s, alpha) s.alpha = number_arg(s, alpha, 'alpha') end
function Region.GetAlpha(self, s) return s.alpha end
function Region.GetEffectiveAlpha(self, s)
	local alpha, parent = s.alpha, s.parent
	while parent do
		alpha = alpha * states[parent].alpha
		parent = states[parent].parent
	end
	return alpha
end
function Region.SetScale(self, s, scale) s.scale = number_arg(s, scale, 'scale') end
function Region.GetScale(self, s) return s.scale end
function Region.GetEffectiveScale(self, s) return effective_scale(s) end
function Region.SetVertexColor(self, s, r, g, b, a)
	s.vertex_color = { number_arg(s, r, 'r'), number_arg(s, g, 'g'), number_arg(s, b, 'b'), a or 1 }
end
function Region.GetVertexColor(self, s)
	local c = s.vertex_color or { 1, 1, 1, 1 }
	return c[1], c[2], c[3], c[4]
end
function Region.SetDrawLayer(self, s, layer, sublevel)
	if not DRAW_LAYERS[layer] then usage(s, 'SetDrawLayer(): invalid layer ' .. tostring(layer)) end
	s.draw_layer, s.sublevel = layer, sublevel or 0
end
function Region.GetDrawLayer(self, s) return s.draw_layer, s.sublevel end

------------------------------------------------------------------ Texture

-- asset is a file path or file ID; nil clears the texture.
function Texture.SetTexture(self, s, asset)
	if asset ~= nil and type(asset) ~= 'string' and type(asset) ~= 'number' then
		usage(s, 'SetTexture(): asset must be a path or a file ID')
	end
	s.texture, s.color_texture, s.atlas = asset, nil, nil
	return true
end
function Texture.GetTexture(self, s) return s.texture end
function Texture.SetColorTexture(self, s, r, g, b, a)
	s.color_texture = { number_arg(s, r, 'r'), number_arg(s, g, 'g'), number_arg(s, b, 'b'), a or 1 }
	s.texture, s.atlas = nil, nil
end
-- Takes left, right, top, bottom, or the eight corners (ULx, ULy, LLx, LLy,
-- URx, URy, LRx, LRy); any other count of numbers is a usage error, as in
-- game. GetTexCoord gives the eight corners either way, the whole texture
-- (0, 0, 0, 1, 1, 0, 1, 1) before any SetTexCoord.
function Texture.SetTexCoord(self, s, ...)
	local n = select('#', ...)
	if n ~= 4 and n ~= 8 then
		usage(s, ('SetTexCoord(): expects 4 or 8 numbers, got %d'):format(n))
	end
	local c = {}
	for i = 1, n do c[i] = number_arg(s, (select(i, ...)), 'coord ' .. i) end
	if n == 4 then
		local left, right, top, bottom = c[1], c[2], c[3], c[4]
		c = { left, top, left, bottom, right, top, right, bottom }
	end
	s.tex_coord = c
end
function Texture.GetTexCoord(self, s)
	local c = s.tex_coord or { 0, 0, 0, 1, 1, 0, 1, 1 }
	return c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8]
end
-- An atlas by name, in place of a texture or color; nil clears it. Not
-- mimicked: the atlas's file and size (any name is taken).
function Texture.SetAtlas(self, s, atlas, useAtlasSize, filterMode, resetTexCoords)
	if atlas ~= nil and type(atlas) ~= 'string' then usage(s, 'SetAtlas(): atlas must be a name') end
	s.atlas, s.texture, s.color_texture = atlas, nil, nil
	return true
end
function Texture.GetAtlas(self, s) return s.atlas end
function Texture.SetBlendMode(self, s, mode) s.blend_mode = mode end
function Texture.GetBlendMode(self, s) return s.blend_mode or 'BLEND' end

------------------------------------------------------------------ FontInstance (font strings, fonts)

-- The font a font string or font object draws with: its own SetFont, or its
-- font object's (font objects are shared, so a later change shows through).
local function font_of(s)
	if s.font then return s.font end
	if s.font_object then return font_of(states[s.font_object]) end
end

function FontInstance.SetFont(self, s, path, size, flags)
	if type(path) ~= 'string' and type(path) ~= 'number' then usage(s, 'SetFont(): path must be a font file') end
	s.font = { path, number_arg(s, size, 'height'), flags or '' }
	return true
end
function FontInstance.GetFont(self, s)
	local font = font_of(s)
	if font then return font[1], font[2], font[3] end
end
function FontInstance.SetFontObject(self, s, font)
	if type(font) == 'string' then font = _G[font] end
	if not is_widget(font, 'FontInstance') then usage(s, 'SetFontObject(): font must be a font object') end
	s.font_object = font
	-- A font set with SetFont stays: in game a reused dropdown kept a font
	-- list's face through SetFontObject with the same object. Whether another
	-- object clears it is unverified; keeping it is the stricter reading.
end
function FontInstance.GetFontObject(self, s) return s.font_object end
function FontInstance.SetTextColor(self, s, r, g, b, a)
	s.text_color = { number_arg(s, r, 'r'), number_arg(s, g, 'g'), number_arg(s, b, 'b'), a or 1 }
end
-- Its own SetTextColor, else its font object's, else white.
local function text_color_of(s)
	if s.text_color then return s.text_color end
	if s.font_object then return text_color_of(states[s.font_object]) end
end
function FontInstance.GetTextColor(self, s)
	local c = text_color_of(s) or { 1, 1, 1, 1 }
	return c[1], c[2], c[3], c[4]
end
function FontInstance.SetJustifyH(self, s, justify) s.justify_h = justify end
function FontInstance.GetJustifyH(self, s) return s.justify_h or 'CENTER' end
function FontInstance.SetJustifyV(self, s, justify) s.justify_v = justify end
function FontInstance.GetJustifyV(self, s) return s.justify_v or 'MIDDLE' end
function FontInstance.SetShadowOffset(self, s, x, y) s.shadow_offset = { x, y } end
function FontInstance.SetShadowColor(self, s, r, g, b, a) s.shadow_color = { r, g, b, a or 1 } end
function FontInstance.GetShadowColor(self, s)
	local c = s.shadow_color or { 0, 0, 0, 0 }
	return c[1], c[2], c[3], c[4]
end
function FontInstance.GetShadowOffset(self, s)
	local o = s.shadow_offset or { 0, 0 }
	return o[1], o[2]
end
function FontInstance.SetSpacing(self, s, spacing) s.spacing = number_arg(s, spacing, 'spacing') end
function FontInstance.GetSpacing(self, s) return s.spacing or 0 end

------------------------------------------------------------------ FontString

-- Like the game, a font string needs a font before it takes text. text is a
-- string or number; nil sets "".
function FontString.SetText(self, s, text)
	if not font_of(s) then usage(s, 'SetText(): Font not set') end
	if text ~= nil and type(text) ~= 'string' and type(text) ~= 'number' then
		usage(s, 'SetText(): text must be a string')
	end
	s.text = text == nil and '' or tostring(text)
end
function FontString.GetText(self, s) return s.text end

-- SetText of string.format(format, ...). Secret values can't be mimicked, so
-- the arguments are plain; format errors as string.format does.
function FontString.SetFormattedText(self, s, format, ...)
	if not font_of(s) then usage(s, 'SetFormattedText(): Font not set') end
	if type(format) ~= 'string' then usage(s, 'SetFormattedText(): format must be a string') end
	s.text = string.format(format, ...)
end

-- There are no font metrics outside the game, so each character counts as
-- half the font's height wide, and a line of text is one font height tall.
-- Whether the text wraps at the font string's width. Wrapping itself isn't done (a
-- font string is one line here), so this only remembers the setting.
function FontString.SetWordWrap(self, s, wrap) s.word_wrap = wrap and true or false end
function FontString.CanWordWrap(self, s) return s.word_wrap ~= false end
-- The text's full width, however narrow the font string is.
function FontString.GetUnboundedStringWidth(self, s)
	local font = font_of(s)
	if not font or not s.text then return 0 end
	return #s.text * font[2] / 2
end
-- Like the modern client, a fixed-width font string that doesn't wrap reports
-- the truncated width: never more than its width.
function FontString.GetStringWidth(self, s)
	local full = FontString.GetUnboundedStringWidth(self, s)
	if s.width and s.word_wrap == false then return math.min(full, s.width) end
	return full
end
function FontString.GetStringHeight(self, s)
	local font = font_of(s)
	if not font or not s.text or s.text == '' then return 0 end
	return font[2]
end

------------------------------------------------------------------ Frame

local function create_region(self, s, typeName, name, layer)
	layer = layer or 'ARTWORK'
	if not DRAW_LAYERS[layer] then usage(s, ('Create%s(): invalid layer %s'):format(typeName, tostring(layer))) end
	local region, rs = new_widget(typeName, name, self)
	rs.draw_layer, rs.sublevel = layer, 0
	table.insert(s.regions, region)
	return region
end

-- No texture templates are stubbed yet, so inherits must be nil.
function Frame.CreateTexture(self, s, name, layer, inherits, sublevel)
	if inherits ~= nil then usage(s, ('CreateTexture(): Couldn\'t find inherited node "%s"'):format(tostring(inherits))) end
	local texture = create_region(self, s, 'Texture', name, layer)
	states[texture].sublevel = sublevel or 0
	return texture
end
-- inherits names a font object (e.g. 'GameFontNormal'), which the font string
-- then uses.
function Frame.CreateFontString(self, s, name, layer, inherits)
	local font
	if inherits ~= nil then
		font = _G[inherits]
		if not is_widget(font, 'FontInstance') then
			usage(s, ('CreateFontString(): Couldn\'t find inherited node "%s"'):format(tostring(inherits)))
		end
	end
	local fontString = create_region(self, s, 'FontString', name, layer)
	states[fontString].font_object = font
	return fontString
end

function Frame.GetChildren(self, s) return unpack(s.children) end
function Frame.GetNumChildren(self, s) return #s.children end
function Frame.GetRegions(self, s) return unpack(s.regions) end
function Frame.GetNumRegions(self, s) return #s.regions end
-- Nothing is drawn here, so a disabled layer is only remembered.
function Frame.DisableDrawLayer(self, s, layer)
	if not DRAW_LAYERS[layer] then usage(s, 'DisableDrawLayer(): invalid layer ' .. tostring(layer)) end
	s.disabled_layers = s.disabled_layers or {}
	s.disabled_layers[layer] = true
end

-- A frame's ID (0 until set), which Blizzard's buttons use for their slot or index.
function Frame.SetID(self, s, id) s.id = number_arg(s, id, 'id') end
function Frame.GetID(self, s) return s.id or 0 end

function Frame.SetFrameLevel(self, s, level) s.level = number_arg(s, level, 'level') end
function Frame.GetFrameLevel(self, s) return s.level end
function Frame.SetFrameStrata(self, s, strata)
	if not STRATA[strata] then usage(s, 'SetFrameStrata(): invalid strata ' .. tostring(strata)) end
	s.strata = strata ~= 'PARENT' and strata or nil
end
function Frame.GetFrameStrata(self, s)
	if s.strata then return s.strata end
	return s.parent and states[s.parent].groups.Frame and Frame.GetFrameStrata(s.parent, states[s.parent]) or 'MEDIUM'
end

function Frame.SetAlpha(self, s, alpha) s.alpha = number_arg(s, alpha, 'alpha') end
function Frame.GetAlpha(self, s) return s.alpha end
function Frame.GetEffectiveAlpha(self, s)
	local alpha, parent = s.alpha, s.parent
	while parent do
		alpha = alpha * states[parent].alpha
		parent = states[parent].parent
	end
	return alpha
end
function Frame.SetScale(self, s, scale) s.scale = number_arg(s, scale, 'scale') end
function Frame.GetScale(self, s) return s.scale end
function Frame.GetEffectiveScale(self, s) return effective_scale(s) end

function Frame.EnableMouseWheel(self, s, enable) s.mouse_wheel_enabled = enable and true or false end
function Frame.IsMouseWheelEnabled(self, s) return s.mouse_wheel_enabled == true end
function Frame.EnableKeyboard(self, s, enable) s.keyboard_enabled = enable and true or false end
function Frame.IsKeyboardEnabled(self, s) return s.keyboard_enabled == true end
function Frame.SetPropagateKeyboardInput(self, s, propagate) s.propagate_keyboard = propagate and true or false end
function Frame.GetPropagateKeyboardInput(self, s) return s.propagate_keyboard == true end
-- The insets the clamp rectangle is grown by. Not mimicked: clamping.
function Frame.SetClampRectInsets(self, s, left, right, top, bottom)
	s.clamp_insets = { number_arg(s, left, 'left'), number_arg(s, right, 'right'), number_arg(s, top, 'top'), number_arg(s, bottom, 'bottom') }
end
function Frame.GetClampRectInsets(self, s)
	local i = s.clamp_insets or { 0, 0, 0, 0 }
	return i[1], i[2], i[3], i[4]
end
function Frame.SetMovable(self, s, movable) s.movable = movable and true or false end
function Frame.IsMovable(self, s) return s.movable == true end
function Frame.SetClampedToScreen(self, s, clamped) s.clamped = clamped and true or false end
function Frame.IsClampedToScreen(self, s) return s.clamped == true end
function Frame.RegisterForDrag(self, s, ...) s.drag_buttons = { ... } end
-- Moving by the mouse: StartMoving errors on a frame that isn't movable, as
-- in game. Not mimicked: the frame following the cursor, and the anchor the
-- game gives it when the move stops (a test places the frame itself between
-- the two calls). The state is in stub.state(frame).moving.
function Frame.StartMoving(self, s)
	if not s.movable then usage(s, 'StartMoving(): the frame is not movable') end
	s.moving = true
end
function Frame.StopMovingOrSizing(self, s) s.moving = false end

-- Events: frames registered for an event, in registration order, so
-- stub.fire_event runs them in a stable order.
local eventFrames = {} -- event -> list of frames

function Frame.RegisterEvent(self, s, event)
	if type(event) ~= 'string' then usage(s, 'RegisterEvent(): event must be a string') end
	if not s.events[event] then
		s.events[event] = true
		eventFrames[event] = eventFrames[event] or {}
		table.insert(eventFrames[event], self)
	end
	return true
end
function Frame.UnregisterEvent(self, s, event)
	if not s.events[event] then return end
	s.events[event] = nil
	for i, frame in ipairs(eventFrames[event]) do
		if frame == self then table.remove(eventFrames[event], i) break end
	end
end
function Frame.UnregisterAllEvents(self, s)
	for event in pairs(s.events) do Frame.UnregisterEvent(self, s, event) end
end
function Frame.IsEventRegistered(self, s, event) return s.events[event] == true end

------------------------------------------------------------------ Button

function Button.RegisterForClicks(self, s, ...) s.click_buttons = { ... } end
function Button.IsEnabled(self, s) return s.enabled end
function Button.Enable(self, s)
	if not s.enabled then
		s.enabled = true
		run_script(self, 'OnEnable')
	end
end
function Button.Disable(self, s)
	if s.enabled then
		s.enabled = false
		run_script(self, 'OnDisable')
	end
end
function Button.SetEnabled(self, s, enabled)
	if enabled then Button.Enable(self, s) else Button.Disable(self, s) end
end
function Button.SetPushedTextOffset(self, s, x, y) s.pushed_text_offset = { x, y } end
function Button.GetPushedTextOffset(self, s) return s.pushed_text_offset[1], s.pushed_text_offset[2] end

-- Font objects for the button's text in each state. A font is required.
for _, state in ipairs({ 'Normal', 'Highlight', 'Disabled' }) do
	local key = state:lower() .. '_font_object'
	Button['Set' .. state .. 'FontObject'] = function(self, s, font)
		if type(font) == 'string' then font = _G[font] end
		if not is_widget(font, 'FontInstance') then
			usage(s, ('Set%sFontObject(): font must be a font object'):format(state))
		end
		s[key] = font
	end
	Button['Get' .. state .. 'FontObject'] = function(self, s) return s[key] end
end

-- The texture for each button state: a texture of the button's, or a file
-- (path or ID), which the button makes a texture for. nil clears it.
for state, layer in pairs({ Normal = 'ARTWORK', Pushed = 'ARTWORK', Disabled = 'ARTWORK', Highlight = 'HIGHLIGHT' }) do
	local key = state:lower() .. '_texture'
	Button['Set' .. state .. 'Texture'] = function(self, s, asset)
		if asset == nil then
			s[key] = nil
		elseif is_widget(asset, 'Texture') then
			s[key] = asset
		elseif type(asset) == 'string' or type(asset) == 'number' then
			local texture = create_region(self, s, 'Texture', nil, layer)
			states[texture].texture = asset
			s[key] = texture
		else
			usage(s, ('Set%sTexture(): asset must be a texture, a path or a file ID'):format(state))
		end
	end
	Button['Get' .. state .. 'Texture'] = function(self, s) return s[key] end
end

------------------------------------------------------------------ CheckButton

function CheckButton.SetChecked(self, s, checked) s.checked = checked and true or false end
function CheckButton.GetChecked(self, s) return s.checked == true end

-- The checked state's textures, as the button's other states' (above): a
-- texture of the button's, or a file it makes a texture for. nil clears it.
for _, state in ipairs({ 'Checked', 'DisabledChecked' }) do
	local key = state:lower() .. '_texture'
	CheckButton['Set' .. state .. 'Texture'] = function(self, s, asset)
		if asset == nil then
			s[key] = nil
		elseif is_widget(asset, 'Texture') then
			s[key] = asset
		elseif type(asset) == 'string' or type(asset) == 'number' then
			local texture = create_region(self, s, 'Texture', nil, 'ARTWORK')
			states[texture].texture = asset
			s[key] = texture
		else
			usage(s, ('Set%sTexture(): asset must be a texture, a path or a file ID'):format(state))
		end
	end
	CheckButton['Get' .. state .. 'Texture'] = function(self, s) return s[key] end
end

------------------------------------------------------------------ ScrollFrame

function ScrollFrame.SetScrollChild(self, s, child)
	if not is_widget(child, 'Frame') then usage(s, 'SetScrollChild(): child must be a frame') end
	s.scroll_child = child
end
function ScrollFrame.GetScrollChild(self, s) return s.scroll_child end
-- The vertical scroll offset, remembered. Not mimicked: the scroll child is
-- drawn where its own anchors put it, not shifted up by the offset.
function ScrollFrame.SetVerticalScroll(self, s, offset) s.vertical_scroll = number_arg(s, offset, 'offset') end
function ScrollFrame.GetVerticalScroll(self, s) return s.vertical_scroll or 0 end
-- The game re-reads the scroll child's size only when told to; the stub reads
-- it whenever asked, so this only counts the calls (stub.state(frame).child_rect_updates).
function ScrollFrame.UpdateScrollChildRect(self, s) s.child_rect_updates = (s.child_rect_updates or 0) + 1 end

------------------------------------------------------------------ Slider and StatusBar

-- The two share a value between a minimum and a maximum.
local function min_max(group)
	group.SetMinMaxValues = function(self, s, min, max)
		s.min, s.max = number_arg(s, min, 'min'), number_arg(s, max, 'max')
		s.value = math.max(s.min, math.min(s.max, s.value or s.min))
		run_script(self, 'OnMinMaxChanged', s.min, s.max)
	end
	group.GetMinMaxValues = function(self, s) return s.min or 0, s.max or 1 end
	group.SetValue = function(self, s, value)
		value = math.max(s.min or 0, math.min(s.max or 1, number_arg(s, value, 'value')))
		if value ~= s.value then
			s.value = value
			run_script(self, 'OnValueChanged', value)
		end
	end
	group.GetValue = function(self, s) return s.value or s.min or 0 end
end
min_max(Slider)
min_max(StatusBar)

-- The thumb is a texture of the slider, made the first time one is set.
-- asset is a file, or a Texture of the slider's.
-- The step and orientation are remembered. The value isn't snapped to the step
-- (the game does it for a drag; code that needs a grid snaps itself and tests it).
function Slider.SetValueStep(self, s, step) s.value_step = number_arg(s, step, 'step') end
function Slider.GetValueStep(self, s) return s.value_step or 0 end
function Slider.SetObeyStepOnDrag(self, s, obey) s.obey_step = obey and true or false end
function Slider.GetObeyStepOnDrag(self, s) return s.obey_step == true end
function Slider.SetOrientation(self, s, orientation)
	if orientation ~= 'HORIZONTAL' and orientation ~= 'VERTICAL' then
		usage(s, 'SetOrientation(): orientation must be HORIZONTAL or VERTICAL')
	end
	s.orientation = orientation
end
function Slider.GetOrientation(self, s) return s.orientation or 'VERTICAL' end

function Slider.SetThumbTexture(self, s, asset)
	if is_widget(asset, 'Texture') then
		s.thumb = asset
	elseif type(asset) == 'string' or type(asset) == 'number' then
		s.thumb = s.thumb or create_region(self, s, 'Texture', nil, 'ARTWORK')
		states[s.thumb].texture, states[s.thumb].color_texture = asset, nil
	else
		usage(s, 'SetThumbTexture(): asset must be a texture, a path or a file ID')
	end
end
function Slider.GetThumbTexture(self, s) return s.thumb end

-- The bar's fill is a texture of the status bar, made the first time one is
-- set; its color tints that texture.
function StatusBar.SetStatusBarTexture(self, s, asset)
	if is_widget(asset, 'Texture') then
		s.bar_texture = asset
	elseif type(asset) == 'string' or type(asset) == 'number' then
		s.bar_texture = s.bar_texture or create_region(self, s, 'Texture', nil, 'ARTWORK')
		states[s.bar_texture].texture, states[s.bar_texture].color_texture = asset, nil
	else
		usage(s, 'SetStatusBarTexture(): asset must be a texture, a path or a file ID')
	end
end
function StatusBar.GetStatusBarTexture(self, s) return s.bar_texture end
-- A solid fill in place of the bar's texture.
function StatusBar.SetColorFill(self, s, r, g, b, a)
	s.color_fill = { number_arg(s, r, 'r'), number_arg(s, g, 'g'), number_arg(s, b, 'b'), a or 1 }
end
function StatusBar.SetReverseFill(self, s, reverse)
	if type(reverse) ~= 'boolean' then usage(s, 'SetReverseFill(): reverse must be a boolean, got ' .. type(reverse)) end
	s.reverse_fill = reverse
end
function StatusBar.GetReverseFill(self, s) return s.reverse_fill or false end
function StatusBar.SetOrientation(self, s, orientation)
	if orientation ~= 'HORIZONTAL' and orientation ~= 'VERTICAL' then
		usage(s, 'SetOrientation(): unknown orientation ' .. tostring(orientation))
	end
	s.orientation = orientation
end
function StatusBar.GetOrientation(self, s) return s.orientation or 'HORIZONTAL' end
function StatusBar.SetStatusBarColor(self, s, r, g, b, a)
	s.bar_color = { number_arg(s, r, 'r'), number_arg(s, g, 'g'), number_arg(s, b, 'b'), a or 1 }
end
function StatusBar.GetStatusBarColor(self, s)
	local c = s.bar_color or { 1, 1, 1, 1 }
	return c[1], c[2], c[3], c[4]
end

------------------------------------------------------------------ EditBox

-- Setting different text runs OnTextChanged(self, false): the change didn't
-- come from the user typing.
function EditBox.SetText(self, s, text)
	if type(text) ~= 'string' and type(text) ~= 'number' then usage(s, 'SetText(): text must be a string') end
	text = tostring(text)
	local changed = text ~= (s.text or '')
	s.text = text
	if changed then run_script(self, 'OnTextChanged', false) end
end
function EditBox.GetText(self, s) return s.text or '' end
-- The cap on how many letters the box takes (0 is no cap, the default). Only
-- remembered: this stub doesn't cut text that is set or typed past it.
function EditBox.SetMaxLetters(self, s, n) s.max_letters = number_arg(s, n, 'maxLetters') end
function EditBox.GetMaxLetters(self, s) return s.max_letters or 0 end

-- Focus. One edit box has the keyboard at a time: taking it makes the one that
-- had it lose it (OnEditFocusLost), then OnEditFocusGained. Not mimicked: the
-- game also drops focus when the box hides, and a box made with autofocus
-- (the default) takes focus when shown. SetAutoFocus only remembers the setting.
local focused
function EditBox.SetAutoFocus(self, s, auto) s.auto_focus = auto and true or false end
function EditBox.HasFocus(self, s) return focused == self end
function EditBox.ClearFocus(self, s)
	if focused ~= self then return end
	focused = nil
	run_script(self, 'OnEditFocusLost')
end
function EditBox.SetFocus(self, s)
	if focused == self then return end
	local previous = focused
	focused = self
	if previous then run_script(previous, 'OnEditFocusLost') end
	run_script(self, 'OnEditFocusGained')
end
function GetCurrentKeyBoardFocus() return focused end
function EditBox.SetTextInsets(self, s, left, right, top, bottom)
	s.text_insets = { number_arg(s, left, 'left'), number_arg(s, right, 'right'), number_arg(s, top, 'top'), number_arg(s, bottom, 'bottom') }
end
function EditBox.GetTextInsets(self, s)
	local i = s.text_insets or { 0, 0, 0, 0 }
	return i[1], i[2], i[3], i[4]
end
-- Selects text from start to stop (0 and -1: all of it). The selection is
-- kept in stub.state(editbox).highlight as { start, stop }.
function EditBox.HighlightText(self, s, start, stop)
	s.highlight = { start or 0, stop or -1 }
end

------------------------------------------------------------------ GameTooltip

function GameTooltip.SetOwner(self, s, owner, anchor)
	if not is_widget(owner, 'Frame') then usage(s, 'SetOwner(): owner must be a frame') end
	s.owner, s.anchor = owner, anchor or 'ANCHOR_LEFT'
end
function GameTooltip.GetOwner(self, s) return s.owner end
function GameTooltip.IsOwned(self, s, frame) return s.owner ~= nil and s.owner == frame end
-- The lines' texts are kept in stub.state(tooltip).texts (the left text of
-- each line) and .rights (a double line's right text), by line.
function GameTooltip.ClearLines(self, s) s.lines, s.texts, s.rights = 0, {}, {} end
function GameTooltip.NumLines(self, s) return s.lines or 0 end
-- SetText starts the tooltip over with one line; AddLine and AddDoubleLine add one.
function GameTooltip.SetText(self, s, text) s.lines, s.texts, s.rights = 1, { text }, {} end
function GameTooltip.AddLine(self, s, text)
	s.lines = (s.lines or 0) + 1
	s.texts, s.rights = s.texts or {}, s.rights or {}
	s.texts[s.lines] = text
end
function GameTooltip.AddDoubleLine(self, s, left, right)
	s.lines = (s.lines or 0) + 1
	s.texts, s.rights = s.texts or {}, s.rights or {}
	s.texts[s.lines], s.rights[s.lines] = left, right
end
-- Shows what a link names (an item, a spell, ...): the tooltip starts over with
-- it, here one line whose text is the link.
function GameTooltip.SetHyperlink(self, s, link)
	if type(link) ~= 'string' then usage(s, 'SetHyperlink(): link must be a string') end
	s.lines, s.texts, s.rights = 1, { link }, {}
end
-- An item in a bag slot, and an item by its ID: the tooltip starts over with
-- one line naming it, 'bag item <bag> <slot>' and 'item <id>', as SetHyperlink
-- makes one line of its link.
function GameTooltip.SetBagItem(self, s, bag, slot)
	if type(bag) ~= 'number' or type(slot) ~= 'number' then usage(s, 'SetBagItem(): bag and slot must be numbers') end
	s.lines, s.texts, s.rights = 1, { ('bag item %d %d'):format(bag, slot) }, {}
end
function GameTooltip.SetItemByID(self, s, itemID)
	if type(itemID) ~= 'number' then usage(s, 'SetItemByID(): itemID must be a number') end
	s.lines, s.texts, s.rights = 1, { ('item %d'):format(itemID) }, {}
end
-- The tooltip's unit: name and unit token, or nothing (nil, nil) when it isn't
-- showing a unit. Nothing in the stubs sets one yet.
function GameTooltip.GetUnit(self, s) return s.unit_name, s.unit_token end

------------------------------------------------------------------ method tables

-- Wraps a method so it checks its self, then gets the widget's state.
local function method(group, name, impl)
	return function(self, ...)
		local s = states[self]
		if not (s and s.groups[group]) then
			error(('Wrong object type for function %s:%s (called on %s)'):format(group, name, describe(self)), 2)
		end
		return impl(self, s, ...)
	end
end

for typeName, groups in pairs(TYPES) do
	local methods, isa = {}, { [typeName] = true }
	for _, group in ipairs(groups) do
		isa[group] = true
		for name, impl in pairs(API[group]) do
			methods[name] = method(group, name, impl)
		end
	end
	TYPES[typeName] = { groups = isa, metatable = { __index = methods } }
end

------------------------------------------------------------------ globals

-- Frame types CreateFrame knows, by lowercase name (the game ignores case).
local FRAME_TYPES = {
	frame = 'Frame', button = 'Button', checkbutton = 'CheckButton', gametooltip = 'GameTooltip',
	scrollframe = 'ScrollFrame', slider = 'Slider', statusbar = 'StatusBar', editbox = 'EditBox',
}

-- Templates CreateFrame knows. Each sets up a new frame the way the template
-- would.
local TEMPLATES = {
	-- Blizzard_SharedXML/Backdrop.xml: the mixin, its OnSizeChanged, then OnLoad.
	BackdropTemplate = function(frame)
		Mixin(frame, BackdropTemplateMixin)
		frame:SetScript('OnSizeChanged', function(self, ...) self:OnBackdropSizeChanged(...) end)
		frame:OnBackdropLoaded()
	end,
	-- The tooltip's text lines (TextLeft1, ...) aren't made. Add them when a
	-- test needs them.
	GameTooltipTemplate = function() end,
}

function CreateFrame(frameType, name, parent, template, id)
	local typeName = type(frameType) == 'string' and FRAME_TYPES[frameType:lower()]
	if not typeName then
		error(("CreateFrame: Unknown frame type '%s'"):format(tostring(frameType)), 2)
	end
	if name ~= nil and type(name) ~= 'string' then
		error('CreateFrame: name must be a string or nil', 2)
	end
	if parent ~= nil and not is_widget(parent, 'Frame') then
		error('CreateFrame: parent must be a frame or nil', 2)
	end
	local templates = {}
	for templateName in tostring(template or ''):gmatch('[^,%s]+') do
		if not TEMPLATES[templateName] then
			error(('CreateFrame: Couldn\'t find inherited node "%s"'):format(templateName), 2)
		end
		templates[#templates + 1] = TEMPLATES[templateName]
	end

	local frame, s = new_widget(typeName, name, parent)
	s.children, s.regions, s.events, s.id = {}, {}, {}, id
	s.level = parent and states[parent].level + 1 or 0
	if s.groups.Button then
		s.enabled, s.pushed_text_offset = true, { 0, 0 }
	end
	if parent then table.insert(states[parent].children, frame) end
	for _, setup in ipairs(templates) do setup(frame) end
	return frame
end

function CreateFont(name)
	local font = new_widget('Font', name, nil)
	return font
end

-- Runs a frame's script (its handler, then its hooks) as the game would,
-- e.g. stub.fire_script(frame, 'OnSizeChanged', width, height). Returns true
-- if anything ran.
function stub.fire_script(widget, script, ...)
	local s = stub.state(widget)
	check_script(s, script, 'fire_script')
	return run_script(widget, script, ...)
end

-- Fires a game event: every frame registered for it gets OnEvent(event, ...),
-- in registration order. Shell modules hear it through the shell's AceEvent.
function stub.fire_event(event, ...)
	local frames = {}
	for i, frame in ipairs(eventFrames[event] or {}) do frames[i] = frame end
	for _, frame in ipairs(frames) do
		if states[frame].events[event] then
			run_script(frame, 'OnEvent', event, ...)
		end
	end
end

-- The screen, and UIParent filling it. Their size follows stub.screen_width
-- and stub.screen_height; UIParent's units also follow its scale, which the
-- core shell sets as SaftUI does.
WorldFrame = CreateFrame('Frame', 'WorldFrame')
states[WorldFrame].fills_screen = true
UIParent = CreateFrame('Frame', 'UIParent')
states[UIParent].fills_screen = true

-- The screen's size in UIParent's units, as the game gives it.
function GetScreenWidth() return UIParent:GetWidth() end
function GetScreenHeight() return UIParent:GetHeight() end
