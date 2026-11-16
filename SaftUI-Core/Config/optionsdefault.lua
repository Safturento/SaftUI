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
	another node; a Width or Height box's get (generators.NumberInputGet) only
	hands on to the group's, so it is looked through unless the box carries its
	own saved or a noReset. noReset is read raw from the option.

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

-- The scratch lists a lookup walks with: the tables AceDB merged into one
-- profile table, in the order they merge. Kept at file level so a lookup makes
-- no table. st:DefaultAt (called from anywhere, a page's get among them) has
-- one pair, the icon's compare (OM.DefaultDiffers, which calls the row's get
-- between reads of the default) its own, so neither clobbers the other.
local listA, listB = {}, {}
local hotA, hotB = {}, {}

--[[
	Walks st.defaults along the keys as AceDB-3.0's copyDefaults fills a profile,
	with the two lists given. For each key, over the tables merged so far, in
	order (copyDefaults' own):
	  - the first table that names the key decides: a plain value is the default
	    and later tables are ignored, a table is merged with every later table
	    that names it;
	  - a table that names the key as a table adds the '**' beside it, which
	    AceDB applies to the child (copyDefaults(dest[k], src['**']));
	  - a table that doesn't name the key but has a '**' or '*' table adds it
	    when an earlier table made the child already ("handle already existing
	    tables in the SV");
	  - when no table names the key, the last merged table's '**' (or '*') gives
	    it: a plain value is the default, a table is the table AceDB makes.
	Returns 'leaf', value; or 'tables', count, list (the tables a table default
	is merged from, in order: the walk's own scratch, valid until the next walk
	with these lists); or nil for no default.
]]
local function Resolve(from, to, ...)
	local defaults = st.defaults
	local n = select('#', ...)
	if n == 0 or type(defaults) ~= 'table' then return nil end
	from[1] = defaults
	local count = 1
	for i = 1, n do
		local key = select(i, ...)
		local made, decided, leaf = 0, nil, nil
		if key ~= nil and key ~= '*' and key ~= '**' then
			for j = 1, count do
				local source = from[j]
				local value = source[key]
				if value ~= nil then
					if decided == nil then
						if type(value) == 'table' then decided = 'table' else decided, leaf = 'leaf', value end
					end
					if decided == 'table' and type(value) == 'table' then
						made = made + 1
						to[made] = value
						local sibling = source['**']
						if type(sibling) == 'table' then
							made = made + 1
							to[made] = sibling
						end
					end
				elseif decided == 'table' then
					local wild = source['**']
					if type(wild) == 'table' then made = made + 1; to[made] = wild end
					wild = source['*']
					if type(wild) == 'table' then made = made + 1; to[made] = wild end
				end
			end
		end
		if decided == 'leaf' then
			if i == n then return 'leaf', leaf end
			return nil
		end
		if made == 0 then
			-- No merged table names the key: the metatable AceDB left on the
			-- table, from the last merged table with a '**' or '*'.
			local wild
			for j = 1, count do
				local source = from[j]
				local value = source['**']
				if value == nil then value = source['*'] end
				if value ~= nil then wild = value end
			end
			if wild == nil then return nil end
			if type(wild) ~= 'table' then
				if i == n then return 'leaf', wild end
				return nil
			end
			made = 1
			to[1] = wild
		end
		from, to, count = to, from, made
	end
	return 'tables', count, from
end

-- A field of the merged tables Resolve listed, as the filled table holds it:
-- the first table that names it, else the last wildcard's plain value (the
-- metatable AceDB leaves). A table value is returned as it is.
local function Field(list, count, name)
	for j = 1, count do
		local value = list[j][name]
		if value ~= nil then return value end
	end
	local wild
	for j = 1, count do
		local source = list[j]
		local value = source['**']
		if value == nil then value = source['*'] end
		if value ~= nil then wild = value end
	end
	if type(wild) ~= 'table' then return wild end
end

-- AceDB's copyDefaults on plain tables (no wildcard metatables: a wildcard
-- only reaches the tables already in dest, as AceDB's own pass does).
local function CopyDefaults(dest, source)
	for key, value in pairs(source) do
		if key == '*' or key == '**' then
			if type(value) == 'table' then
				for existing, child in pairs(dest) do
					if rawget(source, existing) == nil and type(child) == 'table' then CopyDefaults(child, value) end
				end
			end
		elseif type(value) == 'table' then
			if rawget(dest, key) == nil then dest[key] = {} end
			if type(dest[key]) == 'table' then
				CopyDefaults(dest[key], value)
				local sibling = source['**']
				if type(sibling) == 'table' then CopyDefaults(dest[key], sibling) end
			end
		elseif rawget(dest, key) == nil then
			dest[key] = value
		end
	end
end

-- The tables of a list merged into one new table, in AceDB's order.
local function Merge(list, count)
	local merged = {}
	for j = 1, count do CopyDefaults(merged, list[j]) end
	return merged
end

--[[
	The default of a saved path in st.defaults, exactly what a fresh AceDB-3.0
	profile holds there (tests/core/default_at_acedb_test.lua compares every
	leaf and every table of plain values of the real defaults against a real
	AceDB:New): found, value, and found is false when there is none.
	A plain value is the value. A table is st.defaults' own table when one table
	gives it, so copy it before writing; when several merge into it (an own
	table and the '**' beside it, say a position with only some parts of its
	own) it is a new merged table, as AceDB's, which nothing else holds.
	  DefaultAt('chat', 'font')
	  DefaultAt('unitframes', 'profiles', 'Healer', 'player', 'buffs', 'alpha')
	      the element-level '**' alpha, not buffs' own '**' table
	The wildcards (see Resolve) are AceDB's own rules.
]]
function st:DefaultAt(...)
	local kind, a, list = Resolve(listA, listB, ...)
	if kind == 'leaf' then return true, a end
	if kind == 'tables' then
		if a == 1 then return true, list[1] end
		return true, Merge(list, a)
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

-- Lets go of a root's options table (a root asked about no more: optionsOf is
-- weak-keyed but its value holds its key, which Lua 5.1 never frees).
function OM.ForgetRoot(root) optionsOf[root] = nil end

local function OptionsFor(root)
	local options = optionsOf[root]
	if not options then
		options = { type = 'group', name = st.name, args = root }
		optionsOf[root] = options
	end
	return options
end

-- Whether a get only hands on to the group's (a Width or Height box's
-- generators.NumberInputGet, which turns the group's number into text): the
-- group above is what gives the row its value, and its saved reaches the row
-- unless the box carries one of its own, or says it has no reset (Chat's size).
local function HandsOn(group)
	local G = st.Config and st.Config.generators
	return group.saved == nil and group.noReset == nil and G ~= nil and group.get == G.NumberInputGet
end
OM.HandsOn = HandsOn -- the reset walk finds a row's get node by the same rule

-- Walks the row's path as the model does, filling info for it and giving the
-- node that gives the row its get (the option itself, else the nearest group
-- above with one; a get that only hands on, HandsOn, is looked through) and the
-- nearest handler. Nil for a path that isn't there.
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
			-- Nothing of the previous row is left for a differs to read.
			info.options, info.appName, info[0], info.arg, info.handler, info.option, info.type, info.uiType, info.uiName =
				nil, nil, nil, nil, nil, nil, nil, nil, nil
			return nil
		end
		info[i] = path[i]
		if group.get ~= nil and not HandsOn(group) then node = group end
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
	-- Two typefaces by what they draw (st:FontParts: the same as st:FontFields, no table made).
	local n1, s1, o1, x1, y1, p1 = st:FontParts(a)
	local n2, s2, o2, x2, y2, p2 = st:FontParts(b)
	return n1 == n2 and o1 == o2 and SameNumber(s1, s2) and SameNumber(p1, p2) and SameNumber(x1, x2) and SameNumber(y1, y2)
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
			and SamePart('element', a.element, b.element)
			and ((relative and a.element and b.element) or SamePart('frame', a.frame, b.frame, nil, nil, relative))
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
		-- Over the row's values only, as OM.ValueOf is, so the two compare key for key.
		local value = {}
		if type(default) == 'table' then
			for _, entry in ipairs(OM.Values(root, row)) do value[entry.key] = default[entry.key] and true or false end
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

-- The group a row sits in, as the model walks to it.
local function ParentOf(root, row)
	local group = OptionsFor(root)
	local path = row.path
	for i = 1, #path - 1 do
		group = OM.SubOption(group, path[i])
		if not group then return nil end
	end
	return group
end

-- Whether no other Position of the group comes after the row's: by order, then
-- key. A mover's Position goes last in its group (generators.lua: the window
-- gives it a section of its own, after everything else), so a mover links to
-- that one Position only, and a text's or an icon's Position before it never
-- resets the frame.
local function IsLastPosition(root, row)
	local group = ParentOf(root, row)
	local args = group and group.args
	if type(args) ~= 'table' then return false end
	local key = row.path[#row.path]
	local order = row.option.order
	if type(order) ~= 'number' then order = 100 end
	for other, option in pairs(args) do
		if other ~= key and type(option) == 'table' and option.type == 'position' then
			local theirs = option.order
			if type(theirs) ~= 'number' then theirs = 100 end
			if theirs > order or (theirs == order and tostring(other) > tostring(key)) then return false end
		end
	end
	return true
end

-- The registered mover the row's Position resets: the mover whose configPath
-- is the row's group, and the row the last Position of that group.
local function MoverFor(root, row)
	local EM = st.EditModeFrames
	local path = row.path
	if not (EM and EM.MoverAt and path) then return nil end
	local mover = EM:MoverAt(path, #path - 1)
	if mover and IsLastPosition(root, row) then return mover end
	return nil
end

-- The row's source and, for a derived row, the node that gives its get and its
-- handler (info is filled for the row); for a mover row, the mover. See the header.
local function Classify(root, row)
	local option = row.option
	local rowType = RowType(row)
	if NO_VALUE[rowType] then return 'none' end
	local share = option.share
	if type(share) == 'table' and share.own ~= nil then return 'share' end
	if type(option.default) == 'table' then return 'default' end
	if rowType == 'position' then
		local mover = MoverFor(root, row)
		if mover then return 'mover', mover end
	end
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

-- The member of the option as the model reads it, called with info (the scratch
-- one) when it is a function or a handler's method; no table made.
local function Member(option, name, handler)
	local member = option[name]
	if type(member) == 'function' then return member(info) end
	if type(member) == 'string' and handler and handler[member] then return handler[member](handler, info) end
	return member
end

-- Whether a plain default differs from the saved value (toggle, item, range,
-- select, input, keybinding, font key; and what no type claims, a table).
local function LeafDiffers(rowType, node, handler, default)
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
	end
	return not SameDeep(CallGet(node, handler), default)
end

-- Whether the saved value differs from the default at the saved path: node's
-- get against the default, read part by part from the tables AceDB merges (no
-- table made for any type but a merged table nothing here claims).
local function DerivedDiffers(root, row, node, handler)
	local kind, a, list = Resolve(hotA, hotB, node.saved(info))
	if not kind then return false end
	local rowType = RowType(row)
	if kind == 'leaf' then
		if rowType == 'color' or rowType == 'multiselect' or rowType == 'position' then return false end
		return LeafDiffers(rowType, node, handler, a)
	end
	local count, option = a, row.option
	if rowType == 'color' then
		local hasAlpha = Member(option, 'hasAlpha', handler)
		local r1, g1, b1, a1 = CallGet(node, handler)
		local r2, g2, b2, a2
		if Field(list, count, 'r') ~= nil then
			r2, g2, b2, a2 = Field(list, count, 'r'), Field(list, count, 'g'), Field(list, count, 'b'), Field(list, count, 'a')
		else
			r2, g2, b2, a2 = Field(list, count, 1), Field(list, count, 2), Field(list, count, 3), Field(list, count, 4)
		end
		return not SameRGBA(r1, g1, b1, a1, r2, g2, b2, a2, hasAlpha)
	elseif rowType == 'multiselect' then
		local values = Member(option, 'values', handler)
		if type(values) ~= 'table' then return false end
		for key in pairs(values) do
			if (not CallGet(node, handler, key)) ~= (not Field(list, count, key)) then return true end
		end
		return false
	elseif rowType == 'position' then
		local hasFrame, hasElement = PartsOf(option)
		local point = CallGet(node, handler, 'point')
		if point ~= Field(list, count, 'point') then return true end
		local defaultPoint = Field(list, count, 'point')
		if not SamePart('rel_point', CallGet(node, handler, 'rel_point'), Field(list, count, 'rel_point'), point, defaultPoint) then
			return true
		end
		local element
		if hasElement then
			element = CallGet(node, handler, 'element')
			if not SamePart('element', element, Field(list, count, 'element')) then return true end
		end
		-- With an element on both sides the element is the anchor: a frame left beside it counts for nothing.
		if hasFrame and not (element and Field(list, count, 'element'))
				and not SamePart('frame', CallGet(node, handler, 'frame'), Field(list, count, 'frame'), nil, nil, hasElement) then
			return true
		end
		return not SamePart('x_off', CallGet(node, handler, 'x_off'), Field(list, count, 'x_off'))
			or not SamePart('y_off', CallGet(node, handler, 'y_off'), Field(list, count, 'y_off'))
	elseif rowType == 'font' and count == 1 then
		return not SameFont((CallGet(node, handler)), list[1])
	end
	-- Anything else: a table, merged when more than one table gives it.
	return LeafDiffers(rowType, node, handler, count == 1 and list[1] or Merge(list, count))
end

--[[
	Whether the row's hand default says its value differs now, and nothing else
	(no words, no value): the icon asks it for every row on every render, so it
	reads the row with the scratch info (Locate) and makes no table. A differs
	that errors goes to the error handler and counts as false.
]]
function OM.HandDiffers(root, row)
	local default = row.option.default
	if type(default) ~= 'table' or type(default.differs) ~= 'function' then return false end
	Locate(root, row)
	local ok, answer = xpcall(default.differs, geterrorhandler(), info)
	return ok and answer and true or false
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
	if source == 'mover' then return st.EditModeFrames:CanReset(node, true) and true or false end
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
		local default = EM:GetDefaultPosition(node)
		local state = { differs = EM:CanReset(node, true) and true or false }
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

--[[
	The writes that put a position row at value (OM.DefaultValueOf's shape), as a
	list of { part, value } in the order point, rel_point, the anchor, x_off, y_off,
	and only the parts that differ. A row with an element dropdown (target
	'select', a unit frame part) puts its anchor back through its own
	'relative_to' part, as its dropdown does (the row's set clears and sets the
	element and the frame itself), then the frame part for a Global frame's name:
	never the element or the frame part on its own, whose validate refuses the
	cleared frame. A row with a name box (target 'name') writes the frame part.
]]
local function PositionWrites(root, row, value)
	local option = row.option
	local hasFrame, hasElement = PartsOf(option)
	local writes = {}
	local function Add(part, wanted) writes[#writes + 1] = { part, wanted } end
	local point = OM.Get(root, row, 'point')
	if point ~= value.point then Add('point', value.point) end
	local relPoint = value.rel_point or value.point
	if (OM.Get(root, row, 'rel_point') or point) ~= relPoint then Add('rel_point', relPoint) end
	if hasElement and option.unitKey then
		local wanted = value.element or (value.frame and option.nameKey) or option.unitKey
		local changed = OM.Get(root, row, 'relative_to') ~= wanted
		if changed then Add('relative_to', wanted) end
		if wanted == option.nameKey then
			-- Choosing Global frame sets the frame to UIParent; a named one comes after it.
			local now = changed and 'UIParent' or OM.Get(root, row, 'frame')
			if not SamePart('frame', now, value.frame, nil, nil, true) then Add('frame', value.frame) end
		end
	elseif hasElement then
		if not SamePart('element', OM.Get(root, row, 'element'), value.element) then Add('element', value.element or false) end
		if not SamePart('frame', OM.Get(root, row, 'frame'), value.frame, nil, nil, true) then Add('frame', value.frame or false) end
	elseif hasFrame then
		if not SamePart('frame', OM.Get(root, row, 'frame'), value.frame) then Add('frame', value.frame or 'UIParent') end
	end
	if not SamePart('x_off', OM.Get(root, row, 'x_off'), value.x_off) then Add('x_off', value.x_off) end
	if not SamePart('y_off', OM.Get(root, row, 'y_off'), value.y_off) then Add('y_off', value.y_off) end
	return writes
end

-- All parts or none: every write is validated first (a refused one stops the
-- reset before anything is written), then each is set.
local function WritePosition(root, row, value)
	local writes = PositionWrites(root, row, value)
	for _, write in ipairs(writes) do
		local ok, message = OM.Validate(root, row, write[1], write[2])
		if not ok then return false, message end
	end
	for _, write in ipairs(writes) do
		local ok, message = SetPart(root, row, write[1], write[2])
		if not ok then return false, message end
	end
	return true
end

--[[
	Writes value (OM.DefaultValueOf's shape) into the row through its own set,
	so validate runs and a failure stops it: ok, message (false and the
	validation's message, or false alone for a set that errored). An input's is
	text, a color's r, g, b, a, a multiselect calls set only for the keys that
	differ, a position sets only the parts that differ (all or none: see
	PositionWrites). Nothing is cleared.
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
		return st.EditModeFrames:Reset(node)
	elseif source == 'derived' then
		local found, default = st:DefaultAt(node.saved(info))
		if not found then return false, (row.name or tostring(row.key)) .. ' has no default.' end
		return OM.WriteValue(root, row, OM.DefaultValueOf(root, row, default))
	end
	return nil
end
