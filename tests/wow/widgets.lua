--[[
	The game's widget API: frames, buttons, cooldowns, tooltips, textures and
	mask textures, font strings and fonts, CreateFrame and CreateFont, UIParent
	and WorldFrame. Method names and arguments follow
	Blizzard_APIDocumentationGenerated (Gethe/wow-ui-source, forever branch).

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
	itself (fire it with stub.fire_script), and nothing is placed on whole
	pixels (SetRoundLayoutToNearestPixel is only remembered); a size read back
	in single precision (GetWidth and GetHeight are exact unless a test sets
	stub.size_noise, game.lua); text wrapping
	(a font string is one line); OnUpdate; a backdrop's border textures; secret
	values; taint, and which frames are protected (a frame a test marks
	protected has its moves blocked in combat: see "Protected frames in
	combat"); RegisterEvent takes any event name (the game errors
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
	Cooldown = { 'Object', 'ScriptRegion', 'Frame', 'Cooldown' },
	-- 'Texture' is the methods every texture has (TextureBase's in the API
	-- documentation), 'Masked' a texture's masks (SimpleTextureAPI's, which a
	-- MaskTexture doesn't have).
	Texture = { 'Object', 'ScriptRegion', 'Region', 'Texture', 'Masked' },
	MaskTexture = { 'Object', 'ScriptRegion', 'Region', 'Texture', 'MaskTexture' },
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
	Cooldown = { 'OnCooldownDone' },
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
local EditBox, Cooldown, Masked = API.EditBox, API.Cooldown, API.Masked

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

-- The game keeps an alpha within 0 to 1.
local function alpha_arg(s, alpha)
	return math.max(0, math.min(1, number_arg(s, alpha, 'alpha')))
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

-- A widget's scale times its parents', up to the first that ignores its own
-- parent's scale (SetIgnoreParentScale), whose own scale is the last taken.
local function effective_scale(s)
	local scale = s.scale
	while not s.ignore_parent_scale and s.parent do
		s = states[s.parent]
		scale = scale * s.scale
	end
	return scale
end

local rect_of

-- A scroll frame's scroll child (ScrollFrame.SetScrollChild) is placed by the
-- scroll frame, not by anchors of its own: its top left at the scroll frame's,
-- moved up by the vertical scroll, at its own size (SetSize). That's how the
-- game shows one: Blizzard's scroll children (a ScrollFrameTemplate's
-- <ScrollChild> in its XML) have a size and no anchors and show at the frame's
-- top left, and SetVerticalScroll(offset) shows the child from offset down
-- (ScrollFrame_OnVerticalScroll puts the scroll bar's value at the offset).
-- The offset is in the scroll frame's units; SaftUI's scroll children share
-- its scale. Not mimicked: the horizontal scroll, and the clipping (a part of
-- the child outside the frame is still drawn, and IsMouseOver stays the
-- rectangle test, which the game's is too).
local function scroll_child_rect(s, visiting)
	local frame = s.scroll_frame
	local fs = states[frame]
	local l, _, _, t = rect_of(frame, visiting)
	if not l then return nil end
	local k = effective_scale(fs) / effective_scale(s) -- its units to the child's
	local left, top = l * k, (t + (fs.vertical_scroll or 0)) * k
	return left, left + (s.width or 0), top - (s.height or 0), top
end

-- widget's left, right, bottom and top in its own units, or nil if it can't
-- be placed (no anchors, or anchored to something that can't be).
function rect_of(widget, visiting)
	local s = states[widget]
	if s.fills_screen then
		-- One physical pixel in this widget's units, times the screen's pixels.
		local pixel = (768 / stub.screen_height) / effective_scale(s)
		return 0, stub.screen_width * pixel, 0, stub.screen_height * pixel
	end
	if s.scroll_frame then
		if visiting[widget] then return nil end
		visiting[widget] = true
		local l, r, b, t = scroll_child_rect(s, visiting)
		visiting[widget] = nil
		return l, r, b, t
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
	-- A region nothing has been anchored to (anchor_target is set the first time
	-- any region is, and never cleared) can't be what relativeTo depends on, so
	-- the search for a loop through the anchor graph is skipped for it. This is
	-- the usual case: a frame is placed on its parent before it has anything of
	-- its own anchored to it. This relies on every relativeTo written into
	-- s.points having come through here, so a stub method that writes points
	-- some other way must set anchor_target on its relativeTo too.
	if s.anchor_target and depends_on(relativeTo, self, {}) then
		usage(s, method .. '(): Cannot anchor to a region dependent on it')
	end
	states[relativeTo].anchor_target = true
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
-- The API groups a type has that aren't object types it is: a MaskTexture has
-- every texture's methods (the 'Texture' group here) but isn't a Texture, as in
-- the API documentation (SimpleMaskTexture and SimpleTexture both inherit
-- SimpleTextureBase).
local NOT_OBJECT_TYPES = { MaskTexture = { Texture = true } }
function Object.IsObjectType(self, s, typeName)
	local not_types = NOT_OBJECT_TYPES[s.type]
	return s.groups[typeName] == true and not (not_types and not_types[typeName])
end
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
			-- The game moves the frame's children back above it with it (SaftUI's range
			-- widget saw its track drawn over by a child frame after a reparent), so each
			-- descendant is one level above its parent. SetFrameLevel alone moves no child
			-- here: whether the game's does is not established.
			local function above(frame_state)
				for _, child in ipairs(frame_state.children or {}) do
					states[child].level = frame_state.level + 1
					above(states[child])
				end
			end
			above(s)
		end
	end)
end

-- Showing a shown widget or hiding a hidden one changes nothing, so, as in the
-- game, no OnShow or OnHide fires and nothing under it is walked.
function ScriptRegion.Show(self, s)
	if s.shown then return end
	changing_visibility(self, function() s.shown = true end)
end
function ScriptRegion.Hide(self, s)
	if not s.shown then return end
	changing_visibility(self, function() s.shown = false end)
end
function ScriptRegion.SetShown(self, s, shown)
	shown = shown and true or false
	if s.shown == shown then return end
	changing_visibility(self, function() s.shown = shown end)
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
-- A stub widget is protected only when it was made from a secure template
-- (SecureActionButtonTemplate, SecureHandlerStateTemplate: s.protected, set by
-- CreateFrame), or a test gives it an IsProtected of its own. The game also
-- protects what a protected frame is a child of or anchored to; the stubs don't
-- model that spread (a test checks the anchors instead). The two values are
-- isProtected and isProtectedExplicitly: a secure template is both.
-- A region (a texture or a font string) of a protected frame is protected too:
-- the region functions the docs mark IsProtectedFunction (REGION_PROTECTED
-- below) are refused on it in combat. SimpleScriptRegionResizingAPIDocumentation
-- marks SetPoint, SetAllPoints, ClearAllPoints, SetSize, SetWidth, SetHeight and
-- the rest of the anchor family IsProtectedFunction for every region, and
-- SimpleRegionAPIDocumentation SetScale and SetIgnoreParentScale (both
-- branches of Gethe/wow-ui-source, read 2026-11-14); a region's own state is its
-- frame's, since a region can't be made secure by a template. Making a
-- region (CreateTexture, CreateFontString) is not marked protected in
-- SimpleFrameAPIDocumentation, so it isn't refused here; the tracker still builds
-- every region of a secure button when the button is made, out of combat.
function ScriptRegion.IsProtected(self, s)
	-- UIParent is the parent of every secure frame: protected in combat (inferred,
	-- .agents/taint.md rule 6, the E4 experiment), never out of it.
	if s.is_uiparent then return stub.in_combat == true, stub.in_combat == true end
	local protected = s.protected == true
	if not protected and not s.groups.Frame and s.parent then
		protected = states[s.parent].protected == true
	end
	return protected, protected
end

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
-- A size as the game reads it back: stub.size_noise off, unless it's 0.
local function read_back(size)
	if size == 0 then return 0 end
	return size + stub.size_noise
end
function ScriptRegion.GetWidth(self, s) return read_back(width_of(self, s)) end
function ScriptRegion.GetHeight(self, s) return read_back(height_of(self, s)) end
function ScriptRegion.GetSize(self, s) return read_back(width_of(self, s)), read_back(height_of(self, s)) end

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

-- Rounding the region's layout to whole pixels (SetRoundLayoutToNearestPixel,
-- SimpleScriptRegionAPIDocumentation.lua, both clients: one bool, not
-- nilable): off until set. The client then places the region on the pixel
-- grid whenever it lays it out. Nothing is laid out by pixels here, so it's
-- only remembered, in stub.state(region).round_layout. Anything but a boolean
-- errors, the strict side of the documentation's bool.
function ScriptRegion.SetRoundLayoutToNearestPixel(self, s, enabled)
	if type(enabled) ~= 'boolean' then
		usage(s, 'SetRoundLayoutToNearestPixel(): enabled must be a boolean, got ' .. type(enabled))
	end
	s.round_layout = enabled
end

------------------------------------------------------------------ Region (textures, font strings)

function Region.SetAlpha(self, s, alpha) s.alpha = alpha_arg(s, alpha) end
function Region.GetAlpha(self, s) return s.alpha end
function Region.GetEffectiveAlpha(self, s)
	local alpha, parent = s.alpha, s.parent
	while parent do
		alpha = alpha * states[parent].alpha
		parent = states[parent].parent
	end
	return alpha
end
-- UIParent's SetScale fires UI_SCALE_CHANGED at once while stub.scale_fires_event
-- (off: the game fires neither screen event for an addon's own SetScale, E3).
local function set_scale(s, scale)
	s.scale = number_arg(s, scale, 'scale')
	if s.is_uiparent and stub.scale_fires_event then stub.fire_event('UI_SCALE_CHANGED') end
end
function Region.SetScale(self, s, scale) set_scale(s, scale) end
function Region.GetScale(self, s) return s.scale end
function Region.GetEffectiveScale(self, s) return effective_scale(s) end
-- Ignoring the parent's scale, as a frame's (Frame.SetIgnoreParentScale).
function Region.SetIgnoreParentScale(self, s, ignore) s.ignore_parent_scale = ignore and true or false end
function Region.IsIgnoringParentScale(self, s) return s.ignore_parent_scale == true end
-- Writes a color into the table the field already holds, so a color setter makes
-- nothing per call, as the game's makes nothing (a reader's cost case counts
-- garbage: tests/lib/color_cost.lua).
local function put_color(s, field, r, g, b, a)
	local c = s[field]
	if not c then
		c = {}
		s[field] = c
	end
	c[1], c[2], c[3], c[4] = r, g, b, a or 1
end
-- stub.color_bytes (a test opts in): a vertex or text color is kept as bytes, 8 bits a channel
-- (byte x 0.00392156), as the game hands one back.
local function byte(v) if stub.color_bytes then return math.floor(v * 255 + 0.5) * 0.00392156 end return v end
function Region.SetVertexColor(self, s, r, g, b, a)
	put_color(s, 'vertex_color', byte(number_arg(s, r, 'r')), byte(number_arg(s, g, 'g')), byte(number_arg(s, b, 'b')), a)
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
	put_color(s, 'color_texture', number_arg(s, r, 'r'), number_arg(s, g, 'g'), number_arg(s, b, 'b'), a)
	s.texture, s.atlas = nil, nil
end
-- Takes left, right, top, bottom, or the eight corners (ULx, ULy, LLx, LLy,
-- URx, URy, LRx, LRy); any other count of numbers is a usage error, as in
-- game. GetTexCoord gives the eight corners either way, the whole texture
-- (0, 0, 0, 1, 1, 0, 1, 1) before any SetTexCoord.
-- It writes into the table it has, so a color pass that sets a Fill's
-- coordinates makes no garbage (tests/lib/color_cost.lua counts it).
local COORD_NAMES = { 'coord 1', 'coord 2', 'coord 3', 'coord 4', 'coord 5', 'coord 6', 'coord 7', 'coord 8' }
function Texture.SetTexCoord(self, s, ...)
	local n = select('#', ...)
	if n ~= 4 and n ~= 8 then
		usage(s, ('SetTexCoord(): expects 4 or 8 numbers, got %d'):format(n))
	end
	for i = 1, n do number_arg(s, (select(i, ...)), COORD_NAMES[i]) end
	local c = s.tex_coord
	if not c then
		c = {}
		s.tex_coord = c
	end
	if n == 4 then
		local left, right, top, bottom = ...
		c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8] = left, top, left, bottom, right, top, right, bottom
	else
		c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8] = ...
	end
end
function Texture.GetTexCoord(self, s)
	local c = s.tex_coord or { 0, 0, 0, 1, 1, 0, 1, 1 }
	return c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8]
end
-- Texture:SetGradient(orientation, minColor, maxColor) (TextureBase, both
-- clients): 'HORIZONTAL' runs minColor at the left to maxColor at the right,
-- 'VERTICAL' minColor at the bottom to maxColor at the top. The colors are
-- ColorMixin tables (CreateColor), with their alpha: a missing r, g or b is
-- a usage error, as in game, and the game reads a missing alpha as 1. Only
-- remembered, in stub.state(texture).gradient = { orientation, min = { r, g,
-- b, a }, max = { r, g, b, a } }; nothing is drawn.
local function gradient_color(s, color, what)
	if type(color) ~= 'table' or type(color.r) ~= 'number' or type(color.g) ~= 'number' or type(color.b) ~= 'number' then
		usage(s, 'SetGradient(): ' .. what .. ' must be a color (CreateColor)')
	end
	return { color.r, color.g, color.b, color.a or 1 }
end
function Texture.SetGradient(self, s, orientation, minColor, maxColor)
	if orientation ~= 'HORIZONTAL' and orientation ~= 'VERTICAL' then
		usage(s, 'SetGradient(): orientation must be HORIZONTAL or VERTICAL, got ' .. tostring(orientation))
	end
	s.gradient = {
		orientation = orientation,
		min = gradient_color(s, minColor, 'minColor'),
		max = gradient_color(s, maxColor, 'maxColor'),
	}
end
-- An atlas by name, in place of a texture or color; nil clears it. Not
-- mimicked: the atlas's file (any name is taken). With useAtlasSize the
-- texture takes the atlas's size, as the client does, when the atlas tables
-- (C_Texture.GetAtlasInfo) have it.
function Texture.SetAtlas(self, s, atlas, useAtlasSize, filterMode, resetTexCoords)
	if atlas ~= nil and type(atlas) ~= 'string' then usage(s, 'SetAtlas(): atlas must be a name') end
	s.atlas, s.texture, s.color_texture = atlas, nil, nil
	-- As the client does: the coordinates a texture has stay, applied relative
	-- to the atlas, unless resetTexCoords is true: then they are the whole atlas.
	if resetTexCoords then s.tex_coord = nil end
	if atlas and useAtlasSize and C_Texture and C_Texture.GetAtlasInfo then
		local info = C_Texture.GetAtlasInfo(atlas)
		if info then s.width, s.height = info.width, info.height end
	end
	return true
end
function Texture.GetAtlas(self, s) return s.atlas end
-- Tiling across (SetHorizTile) and down (SetVertTile): off until set. Nothing
-- is drawn here, so they're only remembered.
function Texture.SetHorizTile(self, s, tiling) s.horiz_tile = tiling and true or false end
function Texture.GetHorizTile(self, s) return s.horiz_tile == true end
function Texture.SetVertTile(self, s, tiling) s.vert_tile = tiling and true or false end
function Texture.GetVertTile(self, s) return s.vert_tile == true end
-- Snapping to the pixel grid: on until turned off, which is why Blizzard's
-- nine-slice code turns it off (with the texel snapping bias at 0) for art
-- drawn without sharpening. Only remembered; the bias is read with
-- stub.state(texture).texel_snapping_bias.
function Texture.SetSnapToPixelGrid(self, s, snap) s.snap_to_pixel_grid = snap and true or false end
function Texture.IsSnappingToPixelGrid(self, s) return s.snap_to_pixel_grid ~= false end
function Texture.SetTexelSnappingBias(self, s, bias) s.texel_snapping_bias = number_arg(s, bias, 'bias') end
-- 0.3 until set (the game's default, as an in-game print showed: 0.3000000119).
function Texture.GetTexelSnappingBias(self, s) return s.texel_snapping_bias or 0.3000000119 end
-- Drawn in grey: off until set. Only remembered.
function Texture.SetDesaturated(self, s, desaturated) s.desaturated = desaturated and true or false end
function Texture.IsDesaturated(self, s) return s.desaturated == true end
function Texture.SetBlendMode(self, s, mode) s.blend_mode = mode end
function Texture.GetBlendMode(self, s) return s.blend_mode or 'BLEND' end

-- A texture's masks (SimpleTextureAPIDocumentation.lua, both clients): mask
-- textures (Frame.CreateMaskTexture) that cut what it shows, as Blizzard's
-- templates cut icons round (<MaskTexture> with <MaskedTextures> in XML).
-- Only remembered, in the order added; adding one twice keeps one, and
-- removing one it doesn't have does nothing (neither is checked in game).
function Masked.AddMaskTexture(self, s, mask)
	if not is_widget(mask, 'MaskTexture') then usage(s, 'AddMaskTexture(): mask must be a mask texture') end
	s.masks = s.masks or {}
	for _, m in ipairs(s.masks) do
		if m == mask then return end
	end
	table.insert(s.masks, mask)
end
function Masked.GetNumMaskTextures(self, s) return #(s.masks or {}) end
function Masked.GetMaskTexture(self, s, index) return (s.masks or {})[number_arg(s, index, 'index')] end
function Masked.RemoveMaskTexture(self, s, mask)
	for i, m in ipairs(s.masks or {}) do
		if m == mask then
			table.remove(s.masks, i)
			return
		end
	end
end

------------------------------------------------------------------ FontInstance (font strings, fonts)

-- The font a font string or font object draws with: its own SetFont, or its
-- font object's (font objects are shared, so a later change shows through).
local function font_of(s)
	if s.font then return s.font end
	if s.font_object then return font_of(states[s.font_object]) end
end

-- stub.refused_fonts[path] = true makes SetFont refuse that file (false, and no
-- font set), 'error' makes it raise: the game's answer for a file it can't load
-- is documented as `success` on a font string (SimpleFontStringAPIDocumentation)
-- and not said for a font object, so both are played; 'silent' refuses with no
-- return and no font set.
stub.refused_fonts = {}
function FontInstance.SetFont(self, s, path, size, flags)
	if type(path) ~= 'string' and type(path) ~= 'number' then usage(s, 'SetFont(): path must be a font file') end
	local refused = stub.refused_fonts[path]
	if refused == 'error' then usage(s, "SetFont(): couldn't load the font file") end
	if refused == 'silent' then return end -- refuses and says nothing: no font set
	if refused then return false end
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
	put_color(s, 'text_color', byte(number_arg(s, r, 'r')), byte(number_arg(s, g, 'g')), byte(number_arg(s, b, 'b')), a)
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
-- font string is one line here), so this only remembers the setting; a font
-- string set to wrap (true, not the default) and given a width reports the
-- height of the lines its text would take (GetStringHeight).
function FontString.SetWordWrap(self, s, wrap) s.word_wrap = wrap and true or false end
function FontString.CanWordWrap(self, s) return s.word_wrap ~= false end
-- The most lines the text shows (0, the default, is no limit); a wrapped
-- font string's height stops there (GetStringHeight).
function FontString.SetMaxLines(self, s, lines) s.max_lines = number_arg(s, lines, 'maxLines') end
function FontString.GetMaxLines(self, s) return s.max_lines or 0 end
-- The text's full width, however narrow the font string is.
function FontString.GetUnboundedStringWidth(self, s)
	local font = font_of(s)
	if not font or not s.text then return 0 end
	return #s.text * font[2] / 2
end
-- Whether the text is cut at its width (the game ends it with "..."): a font
-- string that doesn't wrap whose full width is wider than the room its anchors
-- or its width give it. As the width of a character is a guess here (see
-- above), so is this; a test sets the label's length to make it so.
function FontString.IsTruncated(self, s)
	if s.word_wrap ~= false then return false end
	local room = width_of(self, s)
	return room > 0 and FontString.GetUnboundedStringWidth(self, s) > room
end
-- Like the modern client, a fixed-width font string that doesn't wrap reports
-- the truncated width: never more than its width.
function FontString.GetStringWidth(self, s)
	local full = FontString.GetUnboundedStringWidth(self, s)
	if s.width and s.word_wrap == false then return math.min(full, s.width) end
	return full
end
-- Like the game, a font string with a height (not 0) lays its text out inside
-- it: lines past it are dropped, so the height never exceeds what it was given
-- until it is set to 0 again.
function FontString.GetStringHeight(self, s)
	local font = font_of(s)
	if not font or not s.text or s.text == '' then return 0 end
	local height = font[2]
	-- Wrapped (SetWordWrap(true) said so, and it has a width): as many lines as
	-- the text's full width needs of that width.
	if s.word_wrap == true and s.width and s.width > 0 then
		local lines = math.ceil(#s.text * font[2] / 2 / s.width)
		if s.max_lines and s.max_lines > 0 then lines = math.min(lines, s.max_lines) end
		height = lines * font[2]
	end
	if s.height and s.height > 0 then height = math.min(height, s.height) end
	return height
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

-- A mask texture (Masked.AddMaskTexture), one of the frame's regions as a
-- texture is. No templates, as for CreateTexture.
function Frame.CreateMaskTexture(self, s, name, layer, inherits, sublevel)
	if inherits ~= nil then usage(s, ('CreateMaskTexture(): Couldn\'t find inherited node "%s"'):format(tostring(inherits))) end
	local mask = create_region(self, s, 'MaskTexture', name, layer)
	states[mask].sublevel = sublevel or 0
	return mask
end

function Frame.GetChildren(self, s) return unpack(s.children) end
function Frame.GetNumChildren(self, s) return #s.children end
function Frame.GetRegions(self, s) return unpack(s.regions) end
function Frame.GetNumRegions(self, s) return #s.regions end
-- Nothing is drawn here, so a layer turned off or on is only remembered.
-- Every layer is on until turned off.
function Frame.DisableDrawLayer(self, s, layer)
	if not DRAW_LAYERS[layer] then usage(s, 'DisableDrawLayer(): invalid layer ' .. tostring(layer)) end
	s.disabled_layers = s.disabled_layers or {}
	s.disabled_layers[layer] = true
end
function Frame.EnableDrawLayer(self, s, layer)
	if not DRAW_LAYERS[layer] then usage(s, 'EnableDrawLayer(): invalid layer ' .. tostring(layer)) end
	if s.disabled_layers then s.disabled_layers[layer] = nil end
end
function Frame.IsDrawLayerEnabled(self, s, layer)
	if not DRAW_LAYERS[layer] then usage(s, 'IsDrawLayerEnabled(): invalid layer ' .. tostring(layer)) end
	return not (s.disabled_layers and s.disabled_layers[layer])
end

-- A frame's ID (0 until set), which Blizzard's buttons use for their slot or index.
function Frame.SetID(self, s, id) s.id = number_arg(s, id, 'id') end
function Frame.GetID(self, s) return s.id or 0 end

-- Attributes: named values on a frame, nil until set (SimpleFrameAPI's
-- SetAttribute and GetAttribute), which secure templates and oUF read. Every
-- SetAttribute runs the frame's OnAttributeChanged(name, value), the value it
-- already has too; the API's SetAttributeNoHandler is the way to set one
-- without it. We know from Blizzard's state driver: RegisterAttributeDriver
-- sets the manager's "setframe" and then "setstate" (SecureStateDriver.lua,
-- forever and live), and the manager registers the driver from its setstate
-- handler, so two frames registering the same driver one after the other
-- would otherwise leave the second unregistered.
function Frame.SetAttribute(self, s, name, value)
	if type(name) ~= 'string' then usage(s, 'SetAttribute(): name must be a string') end
	s.attributes = s.attributes or {}
	s.attributes[name] = value
	run_script(self, 'OnAttributeChanged', name, value)
end
function Frame.GetAttribute(self, s, name)
	return s.attributes and s.attributes[name]
end

-- How far the client widens (negative) or narrows (positive) where a frame
-- takes the mouse, past its edges. Only remembered: clicks by position aren't modelled.
function Frame.SetHitRectInsets(self, s, left, right, top, bottom)
	s.hit_insets = {
		number_arg(s, left, 'left'), number_arg(s, right, 'right'),
		number_arg(s, top, 'top'), number_arg(s, bottom, 'bottom'),
	}
end
function Frame.GetHitRectInsets(self, s)
	local i = s.hit_insets
	if not i then return 0, 0, 0, 0 end
	return i[1], i[2], i[3], i[4]
end

-- Whether the frame clips what its children (and its own regions) draw to its
-- rect. Only remembered: nothing is clipped here.
function Frame.SetClipsChildren(self, s, clips) s.clips_children = clips and true or false end
function Frame.DoesClipChildren(self, s) return s.clips_children == true end

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

function Frame.SetAlpha(self, s, alpha) s.alpha = alpha_arg(s, alpha) end
function Frame.GetAlpha(self, s) return s.alpha end
-- Ignoring the parent's alpha: off until set. Only remembered.
function Frame.SetIgnoreParentAlpha(self, s, ignore) s.ignore_parent_alpha = ignore and true or false end
function Frame.IsIgnoringParentAlpha(self, s) return s.ignore_parent_alpha == true end
function Frame.GetEffectiveAlpha(self, s)
	local alpha, parent = s.alpha, s.parent
	while parent do
		alpha = alpha * states[parent].alpha
		parent = states[parent].parent
	end
	return alpha
end
function Frame.SetScale(self, s, scale) set_scale(s, scale) end
function Frame.GetScale(self, s) return s.scale end
function Frame.GetEffectiveScale(self, s) return effective_scale(s) end
-- Ignoring the parent's scale (SetIgnoreParentScale, SimpleFrameAPIDocumentation.lua
-- and SimpleRegionAPIDocumentation.lua, both clients): off until set. A widget
-- that ignores it has its own scale as its effective scale, and the widgets
-- under it build on that (effective_scale): what the API's name says, and what
-- Inomena's nameplates rely on (its PixelPerfect gives each frame it walks on a
-- plate SetIgnoreParentScale(true) and SetScale(768 / the screen's height)).
function Frame.SetIgnoreParentScale(self, s, ignore) s.ignore_parent_scale = ignore and true or false end
function Frame.IsIgnoringParentScale(self, s) return s.ignore_parent_scale == true end

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
	-- Registered for every unit again: warcraft.wiki.gg's Frame:RegisterUnitEvent
	-- has RegisterEvent on the same event drop its units (not checked in game;
	-- nothing in SaftUI relies on it).
	if s.unit_events then s.unit_events[event] = nil end
	return true
end
-- RegisterUnitEvent(event, unit, ...) (SimpleFrameAPIDocumentation.lua, both
-- clients: the units a stride of unit tokens, at least one): the frame hears
-- the event only when its first payload argument is one of them (the unit
-- the event is about).
function Frame.RegisterUnitEvent(self, s, event, ...)
	if type(event) ~= 'string' then usage(s, 'RegisterUnitEvent(): event must be a string') end
	local units = {}
	for i = 1, select('#', ...) do
		local unit = select(i, ...)
		if type(unit) ~= 'string' then usage(s, 'RegisterUnitEvent(): each unit must be a string') end
		units[unit] = true
	end
	if next(units) == nil then usage(s, 'RegisterUnitEvent(): at least one unit') end
	Frame.RegisterEvent(self, s, event)
	s.unit_events = s.unit_events or {}
	s.unit_events[event] = units
	return true
end
function Frame.UnregisterEvent(self, s, event)
	if not s.events[event] then return end
	s.events[event] = nil
	if s.unit_events then s.unit_events[event] = nil end
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
-- Without this a disabled button runs no OnEnter or OnLeave (stub.fire_script).
function Button.SetMotionScriptsWhileDisabled(self, s, enabled) s.motion_while_disabled = enabled and true or false end
function Button.GetMotionScriptsWhileDisabled(self, s) return s.motion_while_disabled == true end
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
-- Held states: LockHighlight shows the highlight texture as if under the mouse
-- until UnlockHighlight; SetButtonState('PUSHED', true) shows the pushed look
-- and, locked, keeps it through the mouse (a SaftUI preview's pieces use both).
-- GetButtonState is 'NORMAL' until set. stub.state(button).highlight_locked and
-- .button_state record them.
function Button.LockHighlight(self, s) s.highlight_locked = true end
function Button.UnlockHighlight(self, s) s.highlight_locked = false end
local BUTTON_STATES = { NORMAL = true, PUSHED = true }
function Button.SetButtonState(self, s, state, locked)
	if not BUTTON_STATES[state] then usage(s, 'SetButtonState(): state must be NORMAL or PUSHED, got ' .. tostring(state)) end
	s.button_state, s.button_state_locked = state, locked and true or false
end
function Button.GetButtonState(self, s) return s.button_state or 'NORMAL' end
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
-- SetHighlightTexture also takes a blend mode, which it puts on the texture:
-- ADD when none is given. Blizzard's API documentation only says the blend is
-- optional; ADD is most likely the client's default (SaftUI's flat hover, set
-- with none, shows in game as a tint over the icon, not an opaque square).
-- It also puts the texture in the HIGHLIGHT layer, which the client shows only
-- under the mouse: a hover made in OVERLAY and handed to it shows only on
-- hover in game, and one moved back out of HIGHLIGHT shows all the time
-- (2026-11-11, every slot and action button washed blue).
for state, layer in pairs({ Normal = 'ARTWORK', Pushed = 'ARTWORK', Disabled = 'ARTWORK', Highlight = 'HIGHLIGHT' }) do
	local key = state:lower() .. '_texture'
	Button['Set' .. state .. 'Texture'] = function(self, s, asset, blend)
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
		if state == 'Highlight' and s[key] then
			local rs = states[s[key]]
			rs.blend_mode = blend or 'ADD'
			rs.draw_layer, rs.sublevel = 'HIGHLIGHT', 0
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

-- The child is placed by the scroll frame from now on (rect_of); one it
-- replaces goes back to its own anchors.
function ScrollFrame.SetScrollChild(self, s, child)
	if not is_widget(child, 'Frame') then usage(s, 'SetScrollChild(): child must be a frame') end
	if s.scroll_child then states[s.scroll_child].scroll_frame = nil end
	s.scroll_child = child
	states[child].scroll_frame = self
end
function ScrollFrame.GetScrollChild(self, s) return s.scroll_child end
-- The vertical scroll offset: the scroll child shows from it down, moved up by
-- it (rect_of).
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
		-- In game this sets the bar's texture region to that file, which shows
		-- no atlas any more.
		states[s.bar_texture].texture, states[s.bar_texture].color_texture, states[s.bar_texture].atlas = asset, nil, nil
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
	put_color(s, 'bar_color', number_arg(s, r, 'r'), number_arg(s, g, 'g'), number_arg(s, b, 'b'), a)
end
function StatusBar.GetStatusBarColor(self, s)
	local c = s.bar_color or { 1, 1, 1, 1 }
	return c[1], c[2], c[3], c[4]
end

------------------------------------------------------------------ Cooldown

--[[
	A cooldown's swipe, edge and countdown numbers (FrameAPICooldownDocumentation.lua;
	the same on both clients, but that SetSwipeTexture's texture may be nil on
	Forever). Nothing is drawn or timed here: what the swipe and edge are drawn
	with, and whether they and the numbers show, are only remembered, in
	stub.state(cooldown): swipe_texture, swipe_color, edge_texture,
	draw_swipe, draw_edge and reverse. The numbers are a font string the
	cooldown owns (GetCountdownFontString), made the first time it's asked
	for. It isn't among the cooldown's regions here (GetRegions doesn't give
	it); whether the game lists it there is unverified. Not mimicked:
	SetCooldown and the rest of the timing, the color SetSwipeTexture and
	SetEdgeTexture take after the texture (Blizzard passes the texture alone
	and keeps the swipe's color: TotemFrame.lua sets only the texture), and the
	secret values the getters give for a cooldown or a style set from one.
]]
local function countdown_string(self, s)
	if not s.countdown then
		local text, ts = new_widget('FontString', nil, self)
		ts.draw_layer, ts.sublevel = 'OVERLAY', 0
		s.countdown = text
	end
	return s.countdown
end
-- texture is a file path or file ID (nil too on Forever, whose documentation
-- has it nilable). The swipe's color (SetSwipeColor) is kept.
function Cooldown.SetSwipeTexture(self, s, texture)
	local nilable = stub.interface == 16001
	if not (type(texture) == 'string' or type(texture) == 'number' or (texture == nil and nilable)) then
		usage(s, 'SetSwipeTexture(): texture must be a path or a file ID')
	end
	s.swipe_texture = texture
end
function Cooldown.SetSwipeColor(self, s, r, g, b, a)
	s.swipe_color = { number_arg(s, r, 'r'), number_arg(s, g, 'g'), number_arg(s, b, 'b'), a or 1 }
end
function Cooldown.SetEdgeTexture(self, s, texture)
	if type(texture) ~= 'string' and type(texture) ~= 'number' then
		usage(s, 'SetEdgeTexture(): texture must be a path or a file ID')
	end
	s.edge_texture = texture
end
function Cooldown.SetDrawSwipe(self, s, draw) s.draw_swipe = draw and true or false end
function Cooldown.SetDrawEdge(self, s, draw) s.draw_edge = draw and true or false end
function Cooldown.SetReverse(self, s, reverse) s.reverse = reverse and true or false end
function Cooldown.SetHideCountdownNumbers(self, s, hide) s.hide_numbers = hide and true or false end
function Cooldown.GetHideCountdownNumbers(self, s) return s.hide_numbers == true end
-- SetCooldown(start, duration, modRate) and Clear (FrameAPICooldownDocumentation.lua,
-- both clients; both are IsProtectedFunction, blocked only on a protected frame,
-- which a cooldown child of a secure button is not). Nothing is timed or drawn:
-- the start and duration are kept (cooldown_start, cooldown_duration, nil once
-- cleared), and a start or duration that isn't a number errors as the game's
-- argument check does.
function Cooldown.SetCooldown(self, s, start, duration, modRate)
	s.cooldown_start = number_arg(s, start, 'start')
	s.cooldown_duration = number_arg(s, duration, 'duration')
	s.cooldown_mod_rate = modRate or 1
end
function Cooldown.Clear(self, s)
	s.cooldown_start, s.cooldown_duration = nil, nil
end
-- The numbers' font, by a font object's global name.
function Cooldown.SetCountdownFont(self, s, fontName)
	local font = type(fontName) == 'string' and _G[fontName]
	if not is_widget(font, 'FontInstance') then usage(s, 'SetCountdownFont(): ' .. tostring(fontName) .. ' is not a font') end
	states[countdown_string(self, s)].font_object = font
end
function Cooldown.GetCountdownFontString(self, s) return countdown_string(self, s) end

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
function GameTooltip.ClearLines(self, s) s.lines, s.texts, s.rights, s.colors = 0, {}, {}, {} end
function GameTooltip.NumLines(self, s) return s.lines or 0 end
-- SetText starts the tooltip over with one line; AddLine and AddDoubleLine add one.
function GameTooltip.SetText(self, s, text) s.lines, s.texts, s.rights, s.colors = 1, { text }, {}, {} end
-- A line's color, if one was given, is kept in stub.state(tooltip).colors[line]
-- as { r, g, b }.
function GameTooltip.AddLine(self, s, text, r, g, b)
	s.lines = (s.lines or 0) + 1
	s.texts, s.rights = s.texts or {}, s.rights or {}
	s.texts[s.lines] = text
	s.colors = s.colors or {}
	s.colors[s.lines] = r and { r, g, b } or nil
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
-- The party's progress on a quest. In the game this is a tooltip data accessor
-- (Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua, the same on both
-- branches: SetQuestPartyProgress is mapped to C_TooltipInfo.GetQuestPartyProgress,
-- arguments questID, omitTitle, ignoreActivePlayer; MayReturnNothing): like every
-- Set* accessor it starts the tooltip over, and with no data to show (a party
-- with no progress on the quest) it hides the tooltip. stub.party_progress =
-- false is that case. The Blizzard tracker's own OnEnter calls it with the
-- questID alone. Here the one line it makes is 'party <id>'.
function GameTooltip.SetQuestPartyProgress(self, s, questID, omitTitle, ignoreActivePlayer)
	if type(questID) ~= 'number' then usage(s, 'SetQuestPartyProgress(): questID must be a number') end
	if stub.party_progress == false then
		s.lines, s.texts, s.rights, s.colors = 0, {}, {}, {}
		self:Hide()
		return
	end
	s.lines, s.texts, s.rights, s.colors = 1, { ('party %d'):format(questID) }, {}, {}
end
-- TooltipDataHandlerMixin:AppendInfo(getterName, ...): the accessor's data added
-- after what the tooltip has (nothing happens, and nothing is hidden, when there
-- is none). Only 'GetQuestPartyProgress' is modelled.
function GameTooltip.AppendInfo(self, s, getter, questID)
	if getter ~= 'GetQuestPartyProgress' or type(questID) ~= 'number' then
		usage(s, 'AppendInfo(): only GetQuestPartyProgress, with a questID, is modelled')
	end
	if stub.party_progress == false then return end
	s.lines = (s.lines or 0) + 1
	s.texts, s.rights = s.texts or {}, s.rights or {}
	s.texts[s.lines] = ('party %d'):format(questID)
end
-- A quest's item by its quest log index (the quest item buttons' own tooltip,
-- Blizzard_ObjectiveTracker's QuestObjectiveItemButtonMixin:OnEnter): one line,
-- 'quest item <index>', as SetBagItem makes one.
function GameTooltip.SetQuestLogSpecialItem(self, s, questLogIndex)
	if type(questLogIndex) ~= 'number' then usage(s, 'SetQuestLogSpecialItem(): questLogIndex must be a number') end
	s.lines, s.texts, s.rights = 1, { ('quest item %d'):format(questLogIndex) }, {}
end
function GameTooltip.SetItemByID(self, s, itemID)
	if type(itemID) ~= 'number' then usage(s, 'SetItemByID(): itemID must be a number') end
	s.lines, s.texts, s.rights = 1, { ('item %d'):format(itemID) }, {}
end
-- The tooltip's unit: name and unit token, or nothing (nil, nil) when it isn't
-- showing a unit. Nothing in the stubs sets one yet.
function GameTooltip.GetUnit(self, s) return s.unit_name, s.unit_token end

------------------------------------------------------------------ method tables

--[[
	Protected frames in combat. While InCombatLockdown(), the game refuses
	addon code that moves, sizes, shows, hides or reparents a protected frame,
	or sets its attributes: the call does nothing and the game fires
	ADDON_ACTION_BLOCKED ("AddOn 'SaftUI' tried to call the protected function
	'X:SetPoint()'";
	.agents/taint.md, rule 6 and its past incidents). A frame is protected when
	it's secure, or a protected frame is its child or anchored to it; the stubs
	can't tell, so a stub widget is protected only when a test gives it an
	IsProtected of its own. Such a call is noted in stub.blocked and does
	nothing.
]]
local PROTECTED_IN_COMBAT = {
	SetPoint = true, SetAllPoints = true, ClearAllPoints = true,
	SetSize = true, SetWidth = true, SetHeight = true,
	Show = true, Hide = true, SetShown = true, SetParent = true,
	SetAttribute = true,
	-- Protected functions in SimpleFrameAPIDocumentation and
	-- SimpleScriptRegionAPIDocumentation (both clients), blocked the same way.
	SetClampedToScreen = true, EnableMouse = true,
	-- IsProtectedFunction in their documentation, both clients.
	SetRoundLayoutToNearestPixel = true, SetIgnoreParentScale = true,
	-- More of SimpleFrameAPIDocumentation's, SimpleScriptRegionAPIDocumentation's,
	-- SimpleRegionAPIDocumentation's and SimpleButtonAPIDocumentation's
	-- IsProtectedFunction entries (read on the forever branch of
	-- Gethe/wow-ui-source, 2026-11-14), the ones the stubs have: a secure button's
	-- strata and level, its mouse, hit rect, scale, ID, raising, its enabled state
	-- and the mouse buttons it takes can't change in combat either.
	-- SimpleScriptRegionAPIDocumentation's, which a region has too.
	EnableMouseMotion = true, SetPassThroughButtons = true, SetPropagateMouseClicks = true,
	SetPropagateMouseMotion = true, SetMouseClickEnabled = true, SetMouseMotionEnabled = true,
	SetCollapsesLayout = true,
	SetFrameStrata = true, SetFrameLevel = true, EnableMouseWheel = true, SetHitRectInsets = true,
	SetScale = true, SetID = true, Raise = true, Lower = true, SetToplevel = true,
	RegisterForClicks = true, Enable = true, Disable = true, SetEnabled = true,
}

--[[
	Anchor restricted regions (warcraft.wiki.gg, "Object security": since
	8.2.0). The game's nameplates are restricted, and so is every region
	anchored to one, directly or through other regions (its anchor family).
	Insecure code can't ask where such a region is: GetPoint, GetRect, the
	edges (GetLeft, GetRight, GetTop, GetBottom), GetCenter and IsMouseOver
	error "<Type>:<Method>(): Action[FrameMeasurement] failed because[Can't
	measure restricted regions]", in combat and out (the 8.2.0 notes list the
	rect and edge getters; GetPoint and IsMouseOver are the game's errors as
	reported). Its anchors can still be set, and GetNumPoints and its size
	(GetWidth, GetHeight, GetSize) still answer: neither the 8.2.0 notes nor
	the wiki list them, and SaftUI's backdrops on plates read their size each
	time they're drawn.
	stub.restrict_anchors(region) marks a region restricted, as the game marks
	its plates (game.lua's stub.add_nameplate marks every plate it makes).
	Only addon code is refused: a call from a SaftUI file (load_saftui's
	chunks, the bundled libraries among them). A test, which looks at the
	screen as the player does, and the stubs, which stand in for the game's
	own secure code, still measure. Not mimicked: chat bubbles (restricted in
	game too), and the anchor family rule (in game a SetPoint that would
	anchor a restricted region to two families errors).
]]
-- The functions of PROTECTED_IN_COMBAT that are also a region's (not only a
-- frame's): the anchor family and scale, as the region docs mark them.
local REGION_PROTECTED = {
	-- (the ScriptRegion functions too: SimpleScriptRegionAPIDocumentation marks them
	-- for every ScriptRegion, and textures are ScriptRegions)
	SetParent = true, EnableMouse = true, EnableMouseMotion = true, SetPassThroughButtons = true,
	SetPropagateMouseClicks = true, SetPropagateMouseMotion = true, SetMouseClickEnabled = true,
	SetMouseMotionEnabled = true, SetCollapsesLayout = true, SetRoundLayoutToNearestPixel = true,
	SetPoint = true, SetAllPoints = true, ClearAllPoints = true,
	SetSize = true, SetWidth = true, SetHeight = true,
	SetScale = true, SetIgnoreParentScale = true,
}

local MEASURES_POSITION = {
	GetPoint = true, GetRect = true, GetLeft = true, GetRight = true, GetTop = true, GetBottom = true,
	GetCenter = true, IsMouseOver = true,
}

local any_restricted = false -- whether any region was marked, so the rest skip the walk

-- Whether s is restricted: marked, or anchored to a region that is.
local function anchor_restricted(s, seen)
	if s.anchor_restricted then return true end
	if seen[s] then return false end
	seen[s] = true
	for _, p in ipairs(s.points) do
		if anchor_restricted(states[p.relativeTo], seen) then return true end
	end
	return false
end

function stub.restrict_anchors(region)
	stub.state(region).anchor_restricted = true
	any_restricted = true
end

-- Errors as the game does when addon code measures a restricted region: at
-- the code that called the method, found as usage() finds it.
local function refuse_measure(s, name)
	if not (any_restricted and anchor_restricted(s, {})) then return end
	local level = 2
	local info
	while true do
		info = debug.getinfo(level, 'S')
		if not info or (info.source ~= THIS_FILE and info.what ~= 'tail') then break end
		level = level + 1
	end
	if info and info.source:sub(1, #'@SaftUI-') == '@SaftUI-' then
		error(("%s:%s(): Action[FrameMeasurement] failed because[Can't measure restricted regions]: attempted from: %s:%s().")
			:format(s.type, name, s.type, name), level)
	end
end

-- Whether the code that called the stub method (the first caller outside this
-- file) is a SaftUI file, as refuse_measure finds it.
local function called_from_saftui()
	local level = 2
	while true do
		local info = debug.getinfo(level, 'S')
		if not info then return false end
		if info.source ~= THIS_FILE and info.what ~= 'tail' then
			return info.source:sub(1, #'@SaftUI-') == '@SaftUI-'
		end
		level = level + 1
	end
end

-- Wraps a method so it checks its self, then gets the widget's state.
local function method(group, name, impl)
	local guarded = PROTECTED_IN_COMBAT[name]
	local measures = MEASURES_POSITION[name]
	return function(self, ...)
		local s = states[self]
		if not (s and s.groups[group]) then
			error(('Wrong object type for function %s:%s (called on %s)'):format(group, name, describe(self)), 2)
		end
		if measures then refuse_measure(s, name) end
		if guarded and stub.in_combat and (s.groups.Frame or REGION_PROTECTED[name]) and self:IsProtected() then
			-- UIParent: only its SetScale is modelled, and only addon code (a
			-- SaftUI file) is refused; a test's own call, or the stubs' own (the
			-- game's), still goes through.
			if not s.is_uiparent or (name == 'SetScale' and called_from_saftui()) then
				stub.blocked[#stub.blocked + 1] = { self, name }
				return
			end
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
	cooldown = 'Cooldown',
}

-- What a secure action button does on a click, as SecureActionButton_OnClick
-- reads the frame's attributes (Blizzard_FrameXMLBase/SecureTemplates.lua):
-- acts on the press when useOnKeyDown is true (its attribute, else the
-- "cast on key down" setting) and on the release otherwise; a button with no
-- type does nothing. Only noted (stub.secure_clicks): nothing is used or cast.
local function secure_action_click(self, mouse, down, is_key_press, is_secure_action)
	-- SecureActionButton_OnClick (Blizzard_FrameXML/SecureTemplates.lua, line 802
	-- on forever and 805 on live):
	--   isSecureMousePress = not isKeyPress and isSecureAction
	--   useOnKeyDown = not isSecureMousePress and (ShouldUseOnKeyDown(self) or pressAndHoldAction)
	--   clickAction = (down and useOnKeyDown) or (not down and not useOnKeyDown)
	-- ShouldUseOnKeyDown is the useOnKeyDown attribute, else the
	-- ActionButtonUseKeyDown setting (SecureTemplates.lua, line 792). The template's
	-- XML (SecureTemplates.xml, both branches) says an addon's button never gets the
	-- two extra arguments ("for now AddOns won't be able to have isKeyPress or
	-- isSecureAction set"): Blizzard's own action buttons pass them
	-- (ActionBarActionButtonMixin:TriggerSecureClick, TryUseActionButton). So for an
	-- addon's button, a mouse click and a key press alike act on the press when the
	-- setting is on and on the release when it is off. Only a caller that passes
	-- isSecureAction without isKeyPress (a Blizzard-style mouse click) acts on the
	-- release whatever the setting says.
	local on_key_down = false
	if not (is_secure_action and not is_key_press) then
		on_key_down = self:GetAttribute('useOnKeyDown')
		if on_key_down == nil then on_key_down = stub.cast_on_key_down end
	end
	if (down and true or false) ~= (on_key_down and true or false) then return end
	local kind = self:GetAttribute('type')
	if not kind then return end
	stub.secure_clicks[#stub.secure_clicks + 1] = {
		button = self, type = kind, item = self:GetAttribute('item'),
		macrotext = self:GetAttribute('macrotext'), mouse = mouse, down = down and true or false,
	}
end

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
	-- Secure templates (Blizzard_FrameXMLBase/SecureTemplates.xml, both clients):
	-- the frame is protected, so in combat addon code can't move, size, show,
	-- hide, reparent or set attributes on it (stub.blocked). The button's click
	-- is the template's own OnClick; a script set over it replaces it, as in game.
	SecureActionButtonTemplate = function(frame)
		states[frame].protected = true
		frame:SetScript('OnClick', secure_action_click)
	end,
	SecureHandlerStateTemplate = function(frame)
		states[frame].protected = true
	end,
	-- Blizzard_FrameXMLBase/Cooldown.xml: the cooldown frame's own art and
	-- scripts, none of which the stubs draw or time.
	CooldownFrameTemplate = function() end,
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
	-- A disabled button gets no OnEnter or OnLeave unless it asked for them
	-- with SetMotionScriptsWhileDisabled(true) (SimpleButtonAPIDocumentation,
	-- both branches of Gethe/wow-ui-source, read 2026-11-15).
	if (script == 'OnEnter' or script == 'OnLeave') and s.groups.Button and s.enabled == false
		and not s.motion_while_disabled then
		return false
	end
	return run_script(widget, script, ...)
end

-- The user clicks a button as the game lets them: its OnClick, with any
-- arguments given (the mouse button, down), through stub.fire_script, which
-- returns what it returns. The game delivers no click to a hidden button (or one
-- under a hidden frame), a disabled one, or for a mouse button the button did not
-- register (RegisterForClicks: LeftButtonUp until it says otherwise; a
-- <button>Down or 'AnyDown' registration clicks on the press, 'AnyUp' on any
-- release). stub.click ERRORS then, so a test that clicks a button it forgot to
-- show fails loudly instead of passing without its click; a test that means to
-- show a refusal says so with stub.try_click, which returns false for it.
local function click_refusal(button, mouse, down)
	local s = stub.state(button)
	local which = mouse or 'LeftButton'
	if not is_visible(s) then return 'it is hidden (or under a hidden frame)' end
	if s.enabled == false then return 'it is disabled' end
	-- A press is the Down half of a registration, a release the Up half.
	local half = down == true and 'Down' or 'Up'
	for _, name in ipairs(s.click_buttons or { 'LeftButtonUp' }) do
		if name == which .. half or name == 'Any' .. half then return nil end
	end
	return 'it is not registered for the ' .. (down == true and 'press' or 'release') .. ' of ' .. tostring(which)
end

function stub.click(button, mouse, down, ...)
	local why = click_refusal(button, mouse, down)
	if why then error('stub.click: the game would not deliver this click: ' .. why .. ' (stub.try_click is for a test that means to show that)', 2) end
	return stub.fire_script(button, 'OnClick', mouse, down, ...)
end

-- A key binding's click (CLICK <button>:LeftButton) on a secure button: the
-- press (down true) or the release, delivered under the same registration as a
-- mouse click. An addon's button is not told which it is (SecureTemplates.xml:
-- "for now AddOns won't be able to have isKeyPress or isSecureAction set"), so
-- the click carries no extra arguments, and the template acts on the press when
-- ActionButtonUseKeyDown is on, as for a mouse click.
function stub.press_key(button, down)
	local why = click_refusal(button, 'LeftButton', down)
	if why then error('stub.press_key: the game would not deliver this click: ' .. why, 2) end
	return stub.fire_script(button, 'OnClick', 'LeftButton', down and true or false)
end

-- stub.click for a refusal that is the point of the test: false when the game
-- would not deliver the click, else what stub.click returns.
function stub.try_click(button, mouse, down, ...)
	if click_refusal(button, mouse, down) then return false end
	return stub.fire_script(button, 'OnClick', mouse, down, ...)
end

-- The click of the harness before it played the game's rules: OnClick runs
-- whatever the button's state, with the arguments as given. For a test whose
-- window or bar is never shown in the stubs' world; a new test uses stub.click.
function stub.click_unchecked(button, ...)
	return stub.fire_script(button, 'OnClick', ...)
end

-- Fires a game event: every frame registered for it gets OnEvent(event, ...),
-- in registration order; a frame registered for it with RegisterUnitEvent
-- only when the first argument is one of its units. Shell modules hear it
-- through the shell's AceEvent.
function stub.fire_event(event, ...)
	local frames = {}
	for i, frame in ipairs(eventFrames[event] or {}) do frames[i] = frame end
	local unit = ...
	for _, frame in ipairs(frames) do
		local s = states[frame]
		local units = s.unit_events and s.unit_events[event]
		if s.events[event] and (not units or units[unit]) then
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
states[UIParent].is_uiparent = true

-- The screen's size in UIParent's units, as the game gives it.
function GetScreenWidth() return UIParent:GetWidth() end
function GetScreenHeight() return UIParent:GetHeight() end
