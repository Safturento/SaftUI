local st = SaftUI

--[[
	A reset on every setting: defaults derived from where a setting is saved.

	A page says once, beside the get that reads a group's settings, where they
	are saved (SaftUI's own field `saved`); the kit reads the default from
	st.defaults at that path as AceDB-3.0 fills a profile (st:DefaultAt), so a
	derived default is what a fresh profile holds. A reset writes it through the
	row's own set (OM.WriteValue), or for a mover's Position through edit mode's
	Reset. optionsshare.lua draws the icon while OM.DefaultDiffers.

	  saved = function(info) -> key1, key2, ...   the saved path, as returns
	  saved = false                               not a profile value
	  noReset = '<why>'                           the row has no reset, said

	saved is read from the node that gives the row its get (the option itself
	when it has one, else the nearest group above it with one), never from
	another node. noReset is read raw from the option.

	A row's reset source, in order (OM.DefaultSource):
	  'share'    a member page's share (share.own): its hover line's Reset
	  'default'  SaftUI's hand-written default field
	  'mover'    a Position whose group is a mover's configPath: edit mode's own
	             default and Reset, one step its Undo takes back
	  'derived'  saved and st:DefaultAt
	  'none'     no value (execute, description, header, the bags' lists, a get
	             of false) or a stated noReset
	  nil        none of these: the reset walk's failure

	Cost: OM.DefaultDiffers is asked for every row on every render. It allocates
	nothing: it fills one scratch info table, saved returns keys (no table),
	st:DefaultAt keeps two scratch lists, and each type compares in place.
	The words of a default (OM.SourceState's value) are worked out when the
	tooltip opens, never when a row is drawn.
]]
local OM = st.OptionsModel

local type, select, tostring, tonumber, pairs, rawget, error = type, select, tostring, tonumber, pairs, rawget, error
local abs, floor = math.abs, math.floor

local TOLERANCE = 1e-4

------------------------------------------------------------------ st:DefaultAt

-- The scratch lists st:DefaultAt walks with: the tables AceDB merged into
-- one profile table, in the order that wins. Kept at file level so a lookup
-- makes no table; a lookup never calls out, so one pair is enough.
local listA, listB = {}, {}

--[[
	The default of a saved path in st.defaults, as AceDB-3.0 fills a profile:
	found, value (false when there is none), the value itself, never a copy.
	AceDB merges, into a table at a key, the table's own default there and then
	the '**' beside that key in its parent, so an own key beats the sibling '**',
	which beats nothing; a key no merged table names takes the '**' or '*' of
	the table (a non-table value is the default; a table only gives the tables
	below it its defaults, so as the last key it is no default).
	  DefaultAt('chat', 'font')                       'chat' > 'font'
	  DefaultAt('unitframes', 'profiles', 'Healer', 'player', 'buffs', 'alpha')
	      the element-level '**' alpha, not buffs' own '**' table
]]
function st:DefaultAt(...)
	local defaults = st.defaults
	local n = select('#', ...)
	if n == 0 or type(defaults) ~= 'table' then return false end
	local from, to = listA, listB
	from[1] = defaults
	local count = 1
	for i = 1, n do
		local key = select(i, ...)
		local last = i == n
		local made = 0
		if key ~= nil and key ~= '*' and key ~= '**' then
			for j = 1, count do
				local source = from[j]
				local value = source[key]
				if value ~= nil then
					if type(value) ~= 'table' then
						if last then return true, value end
						return false
					end
					-- The key's own table, then its parent's '**', as AceDB's copyDefaults.
					made = made + 1
					to[made] = value
					local sibling = source['**']
					if type(sibling) == 'table' then
						made = made + 1
						to[made] = sibling
					end
				end
			end
		end
		if made > 0 then
			if last then return true, to[1] end
		else
			-- No merged table names the key: the metatable AceDB left on the
			-- table, the last merged table's '**' (or '*').
			local wild
			for j = 1, count do
				local source = from[j]
				local value = source['**']
				if value == nil then value = source['*'] end
				if value ~= nil then wild = value end
			end
			if wild == nil then return false end
			if type(wild) ~= 'table' then
				if last then return true, wild end
				return false
			end
			if last then return false end
			made = 1
			to[1] = wild
		end
		from, to, count = to, from, made
	end
	return false
end

------------------------------------------------------------------ SavedIn, SavedAt

-- A part that is a function is called with info.
local function Part(part, info)
	if type(part) == 'function' then return (part(info)) end
	return part
end

-- Unrolled by the number of parts, so a call returns its keys and makes no table.
local IN = {
	[0] = function() return function(info) return info[#info] end end,
	function(a) return function(info) return Part(a, info), info[#info] end end,
	function(a, b) return function(info) return Part(a, info), Part(b, info), info[#info] end end,
	function(a, b, c) return function(info) return Part(a, info), Part(b, info), Part(c, info), info[#info] end end,
	function(a, b, c, d)
		return function(info) return Part(a, info), Part(b, info), Part(c, info), Part(d, info), info[#info] end
	end,
	function(a, b, c, d, e)
		return function(info)
			return Part(a, info), Part(b, info), Part(c, info), Part(d, info), Part(e, info), info[#info]
		end
	end,
	function(a, b, c, d, e, f)
		return function(info)
			return Part(a, info), Part(b, info), Part(c, info), Part(d, info), Part(e, info), Part(f, info), info[#info]
		end
	end,
	function(a, b, c, d, e, f, g)
		return function(info)
			return Part(a, info), Part(b, info), Part(c, info), Part(d, info), Part(e, info), Part(f, info),
				Part(g, info), info[#info]
		end
	end,
}
local AT = {
	function(a) return function(info) return Part(a, info) end end,
	function(a, b) return function(info) return Part(a, info), Part(b, info) end end,
	function(a, b, c) return function(info) return Part(a, info), Part(b, info), Part(c, info) end end,
	function(a, b, c, d) return function(info) return Part(a, info), Part(b, info), Part(c, info), Part(d, info) end end,
	function(a, b, c, d, e)
		return function(info) return Part(a, info), Part(b, info), Part(c, info), Part(d, info), Part(e, info) end
	end,
	function(a, b, c, d, e, f)
		return function(info)
			return Part(a, info), Part(b, info), Part(c, info), Part(d, info), Part(e, info), Part(f, info)
		end
	end,
	function(a, b, c, d, e, f, g)
		return function(info)
			return Part(a, info), Part(b, info), Part(c, info), Part(d, info), Part(e, info), Part(f, info),
				Part(g, info)
		end
	end,
	function(a, b, c, d, e, f, g, h)
		return function(info)
			return Part(a, info), Part(b, info), Part(c, info), Part(d, info), Part(e, info), Part(f, info),
				Part(g, info), Part(h, info)
		end
	end,
}

--[[
	st.Config.SavedIn(...): a group's saved, for a get that reads
	self.config[ info[#info] ]: those parts, then the option's own key.
	  saved = st.Config.SavedIn('chat')            -> 'chat', info[#info]
	A part that is a function is called with info ({ 'Chat', 'general', 'font' }
	-> info[2], say). Up to seven parts and the key.
]]
function st.Config.SavedIn(...)
	local build = IN[select('#', ...)]
	if not build then error('SavedIn takes at most seven parts', 2) end
	return build(...)
end

--[[
	st.Config.SavedAt(...): an option's own saved: those parts exactly, for a get
	of its own.  saved = st.Config.SavedAt('chat', 'editbox', 'height').
	From one part to eight.
]]
function st.Config.SavedAt(...)
	local build = AT[select('#', ...)]
	if not build then error('SavedAt takes one to eight parts', 2) end
	return build(...)
end

------------------------------------------------------------------ finding the row's get

-- The scratch info a row's saved and get are read with (OM.DefaultDiffers is
-- asked for every row on every render, and makes no table). Never kept.
local info, infoSize = {}, 0
local optionsOf = setmetatable({}, { __mode = 'k' }) -- root -> the options table info.options is

local function OptionsFor(root)
	local options = optionsOf[root]
	if not options then
		options = { type = 'group', name = st.name, args = root }
		optionsOf[root] = options
	end
	return options
end

-- Walks the row's path as the model does, filling info for it and giving the
-- node that gives the row its get (the option itself, else the nearest group
-- above with one) and the nearest handler. Nil for a path that isn't there.
local function Locate(root, row)
	local options = OptionsFor(root)
	local path = row.path
	local size = #path
	local group, handler, node = options, nil, nil
	for i = 1, size do
		group = OM.SubOption(group, path[i])
		if not group then
			for j = 1, infoSize do info[j] = nil end
			infoSize = 0
			return nil
		end
		info[i] = path[i]
		if group.get ~= nil then node = group end
		handler = group.handler or handler
	end
	for i = size + 1, infoSize do info[i] = nil end
	infoSize = size
	local option = row.option
	info.options, info.appName, info[0] = options, st.name, st.name
	info.arg, info.handler, info.option, info.type = option.arg, handler, option, option.type
	info.uiType, info.uiName = 'dialog', st.name
	return node, handler
end

-- The node's get called as the model calls it: a function with info (and ...),
-- or a handler method. get = false answers false.
local function CallGet(node, handler, ...)
	local member = node.get
	if type(member) == 'function' then return member(info, ...) end
	if type(member) == 'string' then
		if handler and handler[member] then return handler[member](handler, info, ...) end
		error(("Method %s doesn't exist in handler for type get"):format(member))
	end
	return member
end

------------------------------------------------------------------ compares

local function Byte(value) return floor((value or 0) * 255 + 0.5) end

-- r, g, b, a of a color: a table with r, g, b, a, or an array.
local function RGBA(color)
	if color.r ~= nil then return color.r, color.g, color.b, color.a end
	return color[1], color[2], color[3], color[4]
end

local function SameRGBA(r1, g1, b1, a1, r2, g2, b2, a2, hasAlpha)
	if Byte(r1) ~= Byte(r2) or Byte(g1) ~= Byte(g2) or Byte(b1) ~= Byte(b2) then return false end
	if not hasAlpha then return true end
	if a1 == nil then a1 = 1 end
	if a2 == nil then a2 = 1 end
	return Byte(a1) == Byte(a2)
end

local function SameNumber(a, b)
	if type(a) == 'number' and type(b) == 'number' then return abs(a - b) <= TOLERANCE end
	return a == b
end

local function SameText(a, b)
	local na, nb = tonumber(a), tonumber(b)
	if na and nb then return abs(na - nb) <= TOLERANCE end
	if a == nil then a = '' end
	if b == nil then b = '' end
	if a == b then return true end
	return tostring(a) == tostring(b)
end

local function SameFont(a, b)
	if type(a) == 'string' and type(b) == 'string' then return a == b end
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end -- a key against a table always differs
	local fa, fb = st:FontFields(a), st:FontFields(b)
	return fa.font_name == fb.font_name and fa.font_outline == fb.font_outline
		and SameNumber(fa.font_size, fb.font_size) and SameNumber(fa.spacing, fb.spacing)
		and SameNumber(fa.shadow_offset[1], fb.shadow_offset[1]) and SameNumber(fa.shadow_offset[2], fb.shadow_offset[2])
end

-- The offset as the position set stores it: a number rounded to the pixel.
local function Offset(value) return tonumber(st:RoundToPixel(tonumber(value) or 0)) or 0 end

-- What a position's anchor frame is. With a name box (global frame), nothing,
-- false, 'UIParent' and UIParent are the screen; with an element dropdown
-- (anchored to its unit frame unless it names a frame) nothing and false are
-- the unit frame, which 'UIParent' is not.
local function FrameKey(frame, relative)
	if frame == UIParent or frame == 'UIParent' then return 'UIParent' end
	if not frame then
		if relative then return false end
		return 'UIParent'
	end
	if type(frame) == 'table' and frame.GetName then return frame:GetName() or frame end
	return frame
end

-- Whether a position part is the same: part is 'point', 'rel_point', 'frame',
-- 'element', 'x_off' or 'y_off'. The point on the frame is the point when it
-- is missing, offsets are compared as the set stores them.
local function SamePart(part, a, b, pa, pb, relative)
	if part == 'rel_point' then return (a or pa) == (b or pb) end
	if part == 'frame' then return FrameKey(a, relative) == FrameKey(b, relative) end
	if part == 'element' then return (a or nil) == (b or nil) end
	if part == 'x_off' or part == 'y_off' then return abs(Offset(a) - Offset(b)) <= TOLERANCE end
	return a == b
end

-- The deep, number-tolerant compare for a table no type claims.
local function SameDeep(a, b)
	if type(a) == 'number' and type(b) == 'number' then return abs(a - b) <= TOLERANCE end
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for key, value in pairs(a) do
		if not SameDeep(value, b[key]) then return false end
	end
	for key in pairs(b) do
		if a[key] == nil then return false end
	end
	return true
end

--[[
	Whether two values are the same for a row type, pure. a and b are in the
	row's shapes (OM.ValueOf, OM.DefaultValueOf). opts = { hasAlpha, relative }:
	hasAlpha makes a color's opacity count, relative says a position's frame is
	an element dropdown's (nothing is its unit frame, not UIParent).
	  toggle, item   nil and false are the same
	  range          numbers within 1e-4
	  input          as numbers when both read as numbers ('200' is 200), else the same text
	  select         the same key, numbers within 1e-4
	  multiselect    every key's truth the same, nil and false alike
	  color          r, g, b as whole bytes, and the opacity's byte with hasAlpha
	  font           the same key, or two typefaces with the same st:FontFields; a key
	                 against a table always differs
	  position       per part, as the set stores them (see SamePart)
	  keybinding     the same key, nil and '' alike
	  else           deep, numbers within 1e-4
]]
function OM.SameValue(rowType, a, b, opts)
	if rowType == 'toggle' or rowType == 'item' then
		return (not a) == (not b)
	elseif rowType == 'range' or rowType == 'select' then
		return SameNumber(a, b)
	elseif rowType == 'input' then
		return SameText(a, b)
	elseif rowType == 'keybinding' then
		return (a or '') == (b or '')
	elseif rowType == 'font' then
		return SameFont(a, b)
	elseif rowType == 'color' then
		if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
		local r1, g1, b1, a1 = RGBA(a)
		local r2, g2, b2, a2 = RGBA(b)
		return SameRGBA(r1, g1, b1, a1, r2, g2, b2, a2, opts and opts.hasAlpha)
	elseif rowType == 'multiselect' then
		a, b = type(a) == 'table' and a or {}, type(b) == 'table' and b or {}
		for key, value in pairs(a) do
			if (not value) ~= (not b[key]) then return false end
		end
		for key, value in pairs(b) do
			if (not value) ~= (not a[key]) then return false end
		end
		return true
	elseif rowType == 'position' then
		if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
		local relative = opts and opts.relative
		return SamePart('point', a.point, b.point)
			and SamePart('rel_point', a.rel_point, b.rel_point, a.point, b.point)
			and SamePart('frame', a.frame, b.frame, nil, nil, relative)
			and SamePart('element', a.element, b.element)
			and SamePart('x_off', a.x_off, b.x_off) and SamePart('y_off', a.y_off, b.y_off)
	end
	return SameDeep(a, b)
end

------------------------------------------------------------------ values in one shape

local function AsText(value)
	if value == nil then return '' end
	if type(value) == 'string' then return value end
	return tostring(value)
end

-- The parts a position row has: its anchor is a frame's name (target 'name'),
-- or an element or a frame (target 'select').
local function PartsOf(option)
	return option.target == 'name' or option.target == 'select', option.target == 'select'
end

local function RowType(row) return row.type or row.option.type end

--[[
	The row's value as one Lua value in one shape, read through get (a fresh
	table for a color, multiselect or position):
	  color        { r, g, b, a }
	  multiselect  { [key] = boolean } over its values
	  position     { point, rel_point, frame, element, x_off, y_off } as the row has them
	  input        its text
	  else         get's first answer
]]
function OM.ValueOf(root, row)
	local rowType = RowType(row)
	if rowType == 'color' then
		local r, g, b, a = OM.Get(root, row)
		return { r, g, b, a }
	elseif rowType == 'multiselect' then
		local value = {}
		for _, entry in ipairs(OM.Values(root, row)) do
			value[entry.key] = OM.Get(root, row, entry.key) and true or false
		end
		return value
	elseif rowType == 'position' then
		local hasFrame, hasElement = PartsOf(row.option)
		local value = {
			point = OM.Get(root, row, 'point'), rel_point = OM.Get(root, row, 'rel_point'),
			x_off = OM.Get(root, row, 'x_off'), y_off = OM.Get(root, row, 'y_off'),
		}
		if hasFrame then value.frame = OM.Get(root, row, 'frame') end
		if hasElement then value.element = OM.Get(root, row, 'element') end
		return value
	elseif rowType == 'input' then
		return AsText((OM.Get(root, row)))
	end
	return (OM.Get(root, row))
end

--[[
	A saved default as the row's get gives it, in OM.ValueOf's shape: an input's
	as text (nil as ''), a color as { r, g, b, a } (a missing a is 1), a
	multiselect's as { [key] = boolean }, a position's with the parts the row
	has. A table is a deep copy, never the one in st.defaults.
]]
function OM.DefaultValueOf(root, row, default)
	local rowType = RowType(row)
	if rowType == 'input' then
		return AsText(default)
	elseif rowType == 'color' then
		if type(default) ~= 'table' then return default end
		local r, g, b, a = RGBA(default)
		if a == nil then a = 1 end
		return { r, g, b, a }
	elseif rowType == 'multiselect' then
		local value = {}
		if type(default) == 'table' then
			for key, on in pairs(default) do value[key] = on and true or false end
		end
		return value
	elseif rowType == 'position' then
		if type(default) ~= 'table' then return default end
		local hasFrame, hasElement = PartsOf(row.option)
		local value = {
			point = default.point, rel_point = default.rel_point or default.point,
			x_off = default.x_off, y_off = default.y_off,
		}
		if hasFrame then value.frame = default.frame end
		if hasElement then value.element = default.element end
		return value
	elseif rowType == 'toggle' or rowType == 'item' then
		return default and true or false
	end
	if type(default) == 'table' then return st.tablecopy(default, true) end
	return default
end

------------------------------------------------------------------ the source

local NO_VALUE = {
	execute = true, description = true, header = true, group = true, bagcategories = true, bagitems = true,
}

local function MoverFor(row)
	local EM = st.EditModeFrames
	local path = row.path
	if not (EM and EM.MoverAt and path) then return nil end
	return EM:MoverAt(path, #path - 1)
end

-- The row's source, and for a derived one the node that gives its get and its
-- handler (info is filled for the row). See the header.
local function Classify(root, row)
	local option = row.option
	local rowType = RowType(row)
	if NO_VALUE[rowType] then return 'none' end
	local share = option.share
	if type(share) == 'table' and share.own ~= nil then return 'share' end
	if type(option.default) == 'table' then return 'default' end
	if rowType == 'position' and MoverFor(row) then return 'mover' end
	local node, handler = Locate(root, row)
	if node and node.get == false then return 'none' end
	if node and type(node.saved) == 'function' then return 'derived', node, handler end
	local why = option.noReset
	if type(why) == 'string' and why ~= '' then return 'none' end
	return nil
end

--[[
	The row's reset source: 'share', 'default', 'mover', 'derived', 'none' (no
	value, or a stated noReset) or nil (none: the walk's failure). The order is
	the header's.
]]
function OM.DefaultSource(root, row)
	return (Classify(root, row))
end

-- Whether the saved value differs from the default, node's get against the
-- default at the saved path. Allocates nothing for a toggle, item, range,
-- select, input, keybinding, color, multiselect, position or a font key.
local function DerivedDiffers(root, row, node, handler)
	local found, default = st:DefaultAt(node.saved(info))
	if not found then return false end
	local option = row.option
	local rowType = RowType(row)
	if rowType == 'toggle' or rowType == 'item' then
		return (not CallGet(node, handler)) ~= (not default)
	elseif rowType == 'range' or rowType == 'select' then
		return not SameNumber(CallGet(node, handler), default)
	elseif rowType == 'input' then
		return not SameText(CallGet(node, handler), default)
	elseif rowType == 'keybinding' then
		return (CallGet(node, handler) or '') ~= (default or '')
	elseif rowType == 'font' then
		return not SameFont((CallGet(node, handler)), default)
	elseif rowType == 'color' then
		if type(default) ~= 'table' then return false end
		local hasAlpha = option.hasAlpha
		if type(hasAlpha) == 'function' then hasAlpha = hasAlpha(info) end
		local r1, g1, b1, a1 = CallGet(node, handler)
		local r2, g2, b2, a2 = RGBA(default)
		return not SameRGBA(r1, g1, b1, a1, r2, g2, b2, a2, hasAlpha)
	elseif rowType == 'multiselect' then
		local values = option.values
		if type(values) == 'function' then values = values(info) end
		if type(values) ~= 'table' or type(default) ~= 'table' then return false end
		for key in pairs(values) do
			if (not CallGet(node, handler, key)) ~= (not default[key]) then return true end
		end
		return false
	elseif rowType == 'position' then
		if type(default) ~= 'table' then return false end
		local hasFrame, hasElement = PartsOf(option)
		local point = CallGet(node, handler, 'point')
		if point ~= default.point then return true end
		if not SamePart('rel_point', CallGet(node, handler, 'rel_point'), default.rel_point, point, default.point) then
			return true
		end
		if hasElement and not SamePart('element', CallGet(node, handler, 'element'), default.element) then return true end
		if hasFrame and not SamePart('frame', CallGet(node, handler, 'frame'), default.frame, nil, nil, hasElement) then
			return true
		end
		return not SamePart('x_off', CallGet(node, handler, 'x_off'), default.x_off)
			or not SamePart('y_off', CallGet(node, handler, 'y_off'), default.y_off)
	end
	return not SameDeep(CallGet(node, handler), default)
end

--[[
	Whether the row's value differs from its default now, for the icon (asked
	for every row on every render): a hand default's differs, a mover's
	EM:CanReset, a derived row's compare of its value with the default at its
	saved path; false for a row with none (or none found).
]]
function OM.DefaultDiffers(root, row)
	local source, node, handler = Classify(root, row)
	if source == 'derived' then return DerivedDiffers(root, row, node, handler) and true or false end
	if source == 'default' then return OM.HandDiffers(root, row) end
	if source == 'mover' then
		local mover = MoverFor(row)
		return mover ~= nil and (st.EditModeFrames:CanReset(mover) and true or false)
	end
	return false
end

-- The packed answers the tooltip names a default by.
local function Pack(root, row, default)
	local value = OM.DefaultValueOf(root, row, default)
	if RowType(row) == 'color' and type(value) == 'table' then
		return { n = 4, value[1], value[2], value[3], value[4] }
	end
	return { n = 1, value }
end

--[[
	A derived or mover row's { differs, value }, as OM.DefaultState gives a hand
	default's: value is the default packed { n, ... } as OM.DefaultValueOf has it (a
	color's four numbers; a mover's, its default position). Nil for any other
	source. The words are the tooltip's (optionsshare.lua).
]]
function OM.SourceState(root, row)
	local source, node, handler = Classify(root, row)
	if source == 'derived' then
		local found, default = st:DefaultAt(node.saved(info))
		local state = { differs = found and DerivedDiffers(root, row, node, handler) and true or false }
		if found then state.value = Pack(root, row, default) end
		return state
	elseif source == 'mover' then
		local EM = st.EditModeFrames
		local mover = MoverFor(row)
		local default = mover and EM:GetDefaultPosition(mover)
		local state = { differs = mover ~= nil and (EM:CanReset(mover) and true or false) }
		if default then state.value = { n = 1, default } end
		return state
	end
	return nil
end

------------------------------------------------------------------ writing

-- OM.Set's answers as ok, message: true; false and the validation message; or
-- false alone when the set errored.
local function SetPart(root, row, ...)
	local ok, message = OM.Set(root, row, ...)
	if ok == false then return false, message end
	return true
end

local function WritePosition(root, row, value)
	local hasFrame, hasElement = PartsOf(row.option)
	local function Write(part, wanted, write)
		local now = OM.Get(root, row, part)
		local same
		if part == 'rel_point' then
			same = (now or OM.Get(root, row, 'point')) == (wanted or value.point)
		elseif part == 'frame' then
			same = SamePart('frame', now, wanted, nil, nil, hasElement)
		else
			same = SamePart(part, now, wanted)
		end
		if same then return true end
		return SetPart(root, row, part, write)
	end
	local ok, message = Write('point', value.point, value.point)
	if ok then ok, message = Write('rel_point', value.rel_point, value.rel_point or value.point) end
	if ok and hasElement then ok, message = Write('element', value.element, value.element or false) end
	if ok and hasFrame then
		local frame = value.frame
		if not frame then frame = (not hasElement) and 'UIParent' or false end
		ok, message = Write('frame', value.frame, frame)
	end
	if ok then ok, message = Write('x_off', value.x_off, value.x_off) end
	if ok then ok, message = Write('y_off', value.y_off, value.y_off) end
	return ok, message
end

--[[
	Writes value (OM.DefaultValueOf's shape) into the row through its own set,
	so validate runs and a failure stops it: ok, message (false and the
	validation's message, or false alone for a set that errored). An input's is
	text, a color's r, g, b, a, a multiselect calls set only for the keys that
	differ, a position sets only the parts that differ in the order point,
	rel_point, element, frame, x_off, y_off. Nothing is cleared.
]]
function OM.WriteValue(root, row, value)
	local rowType = RowType(row)
	if rowType == 'color' then
		return SetPart(root, row, value[1], value[2], value[3], value[4])
	elseif rowType == 'multiselect' then
		for _, entry in ipairs(OM.Values(root, row)) do
			local wanted = value[entry.key] and true or false
			if (OM.Get(root, row, entry.key) and true or false) ~= wanted then
				local ok, message = SetPart(root, row, entry.key, wanted)
				if not ok then return false, message end
			end
		end
		return true
	elseif rowType == 'position' then
		return WritePosition(root, row, value)
	end
	return SetPart(root, row, value)
end

--[[
	Puts the row's default back: ok, message, or nil when it has no derived or
	mover source. A mover's Position goes through edit mode's Reset (one step
	its Undo takes back); a derived default goes through OM.WriteValue, copied
	(OM.DefaultValueOf), so a table in st.defaults is never shared.
]]
function OM.SourceReset(root, row)
	local source, node = Classify(root, row)
	if source == 'mover' then
		local EM = st.EditModeFrames
		local mover = MoverFor(row)
		if not mover then return false end
		return EM:Reset(mover)
	elseif source == 'derived' then
		local found, default = st:DefaultAt(node.saved(info))
		if not found then return false, (row.name or tostring(row.key)) .. ' has no default.' end
		return OM.WriteValue(root, row, OM.DefaultValueOf(root, row, default))
	end
	return nil
end
