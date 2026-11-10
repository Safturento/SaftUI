local st = SaftUI

--[[
	The options model: turns the /sui option tree into what SaftUI's options
	window draws, and runs AceConfig-3.0's contract for it. Pure logic over
	tables, with no frames.

	The tree is AceConfig option tables, as every module's GetConfigTable makes
	them. It follows AceConfigDialog-3.0, which drew /sui before
	(SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigDialog-3.0/
	AceConfigDialog-3.0.lua): its GetOptionsMemberValue (members that can be
	functions or handler method names, and the ones inherited from parent
	groups), how it builds info tables, ActivateControl's set, validate and
	confirm, BuildSortedOptionsTable's order, and its hidden and disabled checks.

	root is the args table Config:GetOptionsTable() returns: one group per page.
	Every function takes it first. info.options is the table AceConfig had
	registered around it ({ type = 'group', name = st.name, args = root }),
	since SaftUI's own option code walks info.options.args (Config/widgets.lua).

	How a page is laid out (the spec's nesting rule):
	  - Each top-level group is a page. topmenu is left out.
	  - A page's non-inline child groups are its tabs, or the picker when it
	    says childGroups = 'select'.
	  - Inside the selected tab or pick, non-inline child groups are a second
	    tab row, or the picker when that group says 'select' (when the picker
	    is already the page's, they're the tabs).
	  - Anything deeper, inline or not, is drawn as sections. Nothing is
	    dropped.
	  - A group's child groups are inline with inline = true (or guiInline,
	    dialogInline) or when the group says childGroups = 'inline', and every
	    group inside an inline group is too.
	The sections are the page's own options, then the tab or pick's, then the
	second level's. Options before any group or header form an untitled
	section; an inline (or deeper) group is a section titled with its name,
	with its desc as a note; a header starts a section titled with its name;
	options after a group continue in an untitled section. Sections with no
	rows are left out.

	A selection is { tab = key, subtab = key, pick = key }. Each is nil for the
	first: the first tab that isn't disabled, or the first pick, as
	AceConfigDialog selects. A key that isn't there (or is hidden) is the same
	as nil. A disabled tab chosen by key still opens, as AceConfigDialog
	reopens a saved selection.

	A row is { key, type, name, desc, size = 'small' | 'normal' | 'wide',
	disabled, path, option }: path is the keys from the root, option the option
	table. size is the option's own size member: 'small' (honored only for a
	toggle, color, execute or input) or 'wide'; anything else is normal. Every
	description and every position row is wide. Ace's width is not read.
	A position row sits in a section of its own, titled with its name; the
	rows after it continue in an untitled one.
]]

local OM = {}
st.OptionsModel = OM

local format, strmatch, tconcat, tsort = string.format, string.match, table.concat, table.sort
local emptyTbl = {}

-- The most results OM.Search gives.
local MAX_RESULTS = 100

-- The pages the window shows apart from the module groups.
local SPECIAL = { Fonts = 'global', profile = 'profiles' }
local GLOBAL_NAME = 'Global Settings'

------------------------------------------------------------------ AceConfigDialog's members

-- Members inherited from parent groups: the nearest one that isn't nil wins
-- (false included, so get = false stops inheriting).
local isInherited = {
	set = true, get = true, func = true, confirm = true, validate = true, disabled = true, hidden = true,
}
-- Members where a string is the value, not a handler method name.
local stringIsLiteral = {
	name = true, desc = true, icon = true, usage = true, width = true, image = true, fontSize = true, tooltipHyperlink = true,
	size = true, target = true, nameKey = true, pickerLabel = true,
}
-- Members that are never a function or method.
local allIsLiteral = { type = true, descStyle = true, imageWidth = true, imageHeight = true }

-- AceConfigDialog's safecall: an error goes to the error handler, and the
-- call gives false. (WoW's xpcall takes arguments, Lua 5.1's doesn't.)
local function safecall(func, ...)
	local n, args = select('#', ...), { ... }
	return xpcall(function() return func(unpack(args, 1, n)) end, geterrorhandler())
end

local function pickfirstset(...)
	for i = 1, select('#', ...) do
		local value = select(i, ...)
		if value ~= nil then return value end
	end
end

-- A group's child: its plugins' first, then its args, as AceConfigDialog.
local function GetSubOption(group, key)
	if group.plugins then
		for _, t in pairs(group.plugins) do
			if t[key] then return t[key] end
		end
	end
	return group.args[key]
end

-- The table AceConfig registered: what info.options is.
local function Options(root)
	return { type = 'group', name = st.name, args = root }
end

-- A copy of path with key added.
local function Append(path, key)
	local copy = {}
	for i = 1, #path do copy[i] = path[i] end
	copy[#copy + 1] = key
	return copy
end

-- The info table for option at path, and the nearest handler.
local function BuildInfo(option, options, path)
	local info = {}
	local group, handler = options, options.handler
	for i = 1, #path do
		group = GetSubOption(group, path[i])
		info[i] = path[i]
		handler = group.handler or handler
	end
	info.options = options
	info.appName = st.name
	info[0] = st.name
	info.arg = option.arg
	info.handler = handler
	info.option = option
	info.type = option.type
	info.uiType = 'dialog'
	info.uiName = st.name
	return info, handler
end

-- AceConfigDialog's GetOptionsMemberValue: the member's value, calling it
-- with info (and ...) when it's a function, or a handler method's name.
local function GetMember(membername, option, options, path, ...)
	local member
	if isInherited[membername] then
		local group = options
		if group[membername] ~= nil then member = group[membername] end
		for i = 1, #path do
			group = GetSubOption(group, path[i])
			if group[membername] ~= nil then member = group[membername] end
		end
	else
		member = option[membername]
	end

	if not allIsLiteral[membername]
			and (type(member) == 'function' or (not stringIsLiteral[membername] and type(member) == 'string')) then
		local info, handler = BuildInfo(option, options, path)
		if type(member) == 'function' then
			return member(info, ...)
		end
		if handler and handler[member] then
			return handler[member](handler, info, ...)
		end
		error(format("Method %s doesn't exist in handler for type %s", member, membername))
	end
	return member
end

-- AceConfigDialog's CheckOptionHidden and CheckOptionDisabled: the dialog's
-- own flags (guiHidden, ...) win, even false, over the inherited member.
local function IsHidden(option, options, path)
	local hidden = pickfirstset(option.dialogHidden, option.guiHidden)
	if hidden == nil then
		hidden = GetMember('hidden', option, options, path)
	end
	return hidden and true or false
end

local function IsDisabled(option, options, path)
	local disabled = pickfirstset(option.dialogDisabled, option.guiDisabled)
	if disabled == nil then
		disabled = GetMember('disabled', option, options, path)
	end
	return disabled and true or false
end

-- A child group drawn inside its parent rather than as a tab or pick.
local function IsInline(option, parent)
	return pickfirstset(option.dialogInline, option.guiInline, option.inline, parent.childGroups == 'inline') and true or false
end

-- A name as text: AceConfigDialog shows a string or a number, nothing else.
local function Text(value)
	if type(value) == 'string' then return value end
	if type(value) == 'number' then return tostring(value) end
	return ''
end

local function Title(value)
	value = Text(value)
	return value ~= '' and value or nil
end

local function Desc(value)
	return type(value) == 'string' and value or nil
end

------------------------------------------------------------------ order

-- AceConfigDialog's compareOptions: by order (100 when there's none), with
-- negative orders after all the others, then by name ignoring case. Then by
-- key, so equal names keep one order.
local function Before(a, b, orders, names)
	local orderA, orderB = orders[a] or 100, orders[b] or 100
	if orderA == orderB then
		local nameA = type(names[a]) == 'string' and names[a]:upper() or ''
		local nameB = type(names[b]) == 'string' and names[b]:upper() or ''
		if nameA ~= nameB then return nameA < nameB end
		return tostring(a) < tostring(b)
	end
	if orderA < 0 then
		if orderB >= 0 then return false end
	elseif orderB < 0 then
		return true
	end
	return orderA < orderB
end

-- AceConfigDialog's BuildSortedOptionsTable: a group's child keys (its
-- plugins' and args'), in order, and the options by key.
local function SortedOptions(group, options, path)
	local keys, opts, orders, names = {}, {}, {}, {}
	local function add(key, option)
		if opts[key] then return end
		keys[#keys + 1] = key
		opts[key] = option
		local childPath = Append(path, key)
		orders[key] = GetMember('order', option, options, childPath)
		names[key] = GetMember('name', option, options, childPath)
	end
	if group.plugins then
		for _, t in pairs(group.plugins) do
			for key, option in pairs(t) do add(key, option) end
		end
	end
	for key, option in pairs(group.args or emptyTbl) do add(key, option) end
	tsort(keys, function(a, b) return Before(a, b, orders, names) end)
	return keys, opts
end

------------------------------------------------------------------ pages and levels

-- The group at root[key] if it's a page: a group, not topmenu, not hidden.
local function PageOption(options, key)
	if key == nil or key == 'topmenu' then return nil end
	local option = options.args[key]
	if type(option) ~= 'table' or option.type ~= 'group' then return nil end
	if IsHidden(option, options, { key }) then return nil end
	return option
end

local function PageName(key, option, options, path)
	if SPECIAL[key] == 'global' then return GLOBAL_NAME end
	return Text(GetMember('name', option, options, path))
end

-- A group's child groups that are tabs or picks: not inline, not hidden. As
-- AceConfigDialog's BuildGroups: { key, name, desc, disabled }, in order.
local function SubGroups(group, options, path)
	local list = {}
	local keys, opts = SortedOptions(group, options, path)
	for _, key in ipairs(keys) do
		local option = opts[key]
		if option.type == 'group' and not IsInline(option, group) then
			local childPath = Append(path, key)
			if not IsHidden(option, options, childPath) then
				list[#list + 1] = {
					key = key,
					name = Text(GetMember('name', option, options, childPath)),
					desc = Desc(GetMember('desc', option, options, childPath)),
					disabled = IsDisabled(option, options, childPath),
				}
			end
		end
	end
	return list
end

-- Which selection a level below the page is: depth 2 is the page's tabs or
-- picker, depth 3 the selected one's second tab row or picker (or tabs, when
-- the picker is taken).
local function SlotFor(depth, previous, group)
	local select = group.childGroups == 'select'
	if depth == 2 then
		return select and 'pick' or 'tab'
	elseif previous == 'pick' then
		return 'tab'
	end
	return select and 'pick' or 'subtab'
end

-- The levels below a page: up to two, each { slot, group, path, list, entry,
-- child, childPath }. choose(slot, list, depth) gives the selected entry, or
-- nil to stop there.
local function Levels(options, page, pagePath, choose)
	local levels = {}
	local group, path, slot = page, pagePath, nil
	for depth = 2, 3 do
		local list = SubGroups(group, options, path)
		if #list == 0 then break end
		slot = SlotFor(depth, slot, group)
		local entry = choose(slot, list, depth)
		local level = { slot = slot, group = group, path = path, list = list, entry = entry }
		levels[#levels + 1] = level
		if not entry then break end
		level.child = GetSubOption(group, entry.key)
		level.childPath = Append(path, entry.key)
		group, path = level.child, level.childPath
	end
	return levels
end

-- The entry with key, else the first (that isn't disabled, for tabs).
local function Choose(list, key, skipDisabled)
	if key ~= nil then
		for _, entry in ipairs(list) do
			if entry.key == key then return entry end
		end
	end
	for _, entry in ipairs(list) do
		if not (skipDisabled and entry.disabled) then return entry end
	end
end

------------------------------------------------------------------ sections and rows

-- The types a setting can be small for.
local canBeSmall = { toggle = true, color = true, execute = true, input = true }

local function SizeOf(option, options, path)
	if option.type == 'description' or option.type == 'position' then return 'wide' end
	local size = GetMember('size', option, options, path)
	if size == 'wide' then return 'wide' end
	if size == 'small' and canBeSmall[option.type] then return 'small' end
	return 'normal'
end

local function Row(option, options, path)
	return {
		key = path[#path],
		type = option.type,
		name = Text(GetMember('name', option, options, path)),
		desc = Desc(GetMember('desc', option, options, path)),
		size = SizeOf(option, options, path),
		disabled = IsDisabled(option, options, path),
		path = path,
		option = option,
	}
end

-- Adds group's options to sections, as AceConfigDialog's FeedOptions feeds a
-- container: rows, headers and inline groups in order. deep draws every child
-- group as a section (inside an inline group, and below the levels the
-- window selects); otherwise non-inline child groups are left to the levels.
local function Feed(sections, options, group, path, deep, title, note)
	local section = { title = title, note = note, rows = {} }
	sections[#sections + 1] = section
	local keys, opts = SortedOptions(group, options, path)
	for _, key in ipairs(keys) do
		local option = opts[key]
		local childPath = Append(path, key)
		if not IsHidden(option, options, childPath) then
			if option.type == 'group' then
				if deep or IsInline(option, group) then
					Feed(sections, options, option, childPath, true,
						Title(GetMember('name', option, options, childPath)),
						Desc(GetMember('desc', option, options, childPath)))
					section = { rows = {} }
					sections[#sections + 1] = section
				end
			elseif option.type == 'header' then
				section = { title = Title(GetMember('name', option, options, childPath)), rows = {} }
				sections[#sections + 1] = section
			elseif option.type == 'position' then
				local row = Row(option, options, childPath)
				sections[#sections + 1] = { title = Title(row.name), rows = { row } }
				section = { rows = {} }
				sections[#sections + 1] = section
			else
				section.rows[#section.rows + 1] = Row(option, options, childPath)
			end
		end
	end
end

local function WithRows(sections)
	local kept = {}
	for _, section in ipairs(sections) do
		if #section.rows > 0 then kept[#kept + 1] = section end
	end
	return kept
end

------------------------------------------------------------------ the API

-- The sidebar's pages: { key, name, desc, category, special, disabled }, in
-- order, then by name. special is 'global' for Fonts (named Global Settings)
-- and 'profiles' for profile. category is the group's own category field
-- (Frames, Combat, Info), or 'Other'.
function OM.Pages(root)
	local options = Options(root)
	local pages = {}
	local keys = SortedOptions(options, options, {})
	for _, key in ipairs(keys) do
		local option = PageOption(options, key)
		if option then
			local path = { key }
			pages[#pages + 1] = {
				key = key,
				name = PageName(key, option, options, path),
				desc = Desc(GetMember('desc', option, options, path)),
				category = option.category or 'Other',
				special = SPECIAL[key],
				disabled = IsDisabled(option, options, path),
			}
		end
	end
	return pages
end

--[[
	A page as the window draws it, with selection's tab, subtab and pick (see
	the top). nil when there's no such page.
	{ title, desc,
	  tabs = { {key, name, desc, disabled} }, tab,
	  subtabs = { ... }, subtab,
	  picker = { name, values = { {key, name, desc, disabled} }, selected } or nil,
	  sections = { { title, note, rows = { row } } } }
	tabs and subtabs are empty when there are none. The picker's name is the
	group's pickerLabel when it has one, else the name of the
	group whose children it picks, as AceConfigDialog titles its dropdown.
]]
function OM.BuildView(root, pageKey, selection)
	selection = selection or emptyTbl
	local options = Options(root)
	local page = PageOption(options, pageKey)
	if not page then return nil end
	local pagePath = { pageKey }

	local view = {
		title = PageName(pageKey, page, options, pagePath),
		desc = Desc(GetMember('desc', page, options, pagePath)),
		tabs = {},
		subtabs = {},
		sections = {},
	}
	local levels = Levels(options, page, pagePath, function(slot, list)
		return Choose(list, selection[slot], slot ~= 'pick')
	end)

	local sections = {}
	Feed(sections, options, page, pagePath, false)
	for i, level in ipairs(levels) do
		local key = level.entry and level.entry.key
		if level.slot == 'pick' then
			-- A page's pickerLabel names its picker; else the group's own name.
			local pickerName = Text(GetMember('pickerLabel', level.group, options, level.path))
			if pickerName == '' then
				pickerName = Text(GetMember('name', level.group, options, level.path))
			end
			view.picker = {
				name = pickerName,
				values = level.list,
				selected = key,
			}
		elseif level.slot == 'tab' then
			view.tabs, view.tab = level.list, key
		else
			view.subtabs, view.subtab = level.list, key
		end
		if level.child then
			-- The selected group at the last level draws everything below it.
			Feed(sections, options, level.child, level.childPath, i == 2)
		end
	end
	view.sections = WithRows(sections)
	return view
end

-- The page and selection a path of option keys opens, e.g.
-- { 'Unitframes', 'player', 'general' } (st.Config:Open's arguments, an edit
-- mode mover's configPath). Keys past the tab and picker levels are sections
-- on the page, so they select nothing more; nor does a key that isn't a tab
-- or pick there. nil when the first key is no page.
function OM.SelectionForPath(root, path)
	local pageKey = path and path[1]
	local options = Options(root)
	local page = PageOption(options, pageKey)
	if not page then return nil end
	local selection = {}
	Levels(options, page, { pageKey }, function(slot, list, depth)
		local key = path[depth]
		for _, entry in ipairs(list) do
			if entry.key == key then
				selection[slot] = key
				return entry
			end
		end
	end)
	return pageKey, selection
end

-- AceConfigDialog's info table for the option at path (keys from the root).
function OM.Info(root, path)
	local options = Options(root)
	local option = options
	for i = 1, #path do
		option = GetSubOption(option, path[i])
		if not option then
			error(format('No option at %s', tconcat(path, '.', 1, i)), 2)
		end
	end
	return (BuildInfo(option, options, path))
end

-- Any member of the row's option as AceConfigDialog reads it: a function or
-- handler method is called with info and ..., inherited members are looked
-- up the tree. For the widgets (hasAlpha, image, fontSize, ...).
function OM.Member(root, row, membername, ...)
	return GetMember(membername, row.option, Options(root), row.path, ...)
end

-- The row's value: its get, called with info and ... (a multiselect's key).
-- A color gives r, g, b, a. get = false gives false; no get gives nil.
function OM.Get(root, row, ...)
	return GetMember('get', row.option, Options(root), row.path, ...)
end

-- Walks the path from the root as ActivateControl does, picking up the
-- inherited set (or func, for an execute), validate and confirm, and the
-- nearest handler.
local function Inherited(options, path, funcname)
	local group = options
	local func, validate, confirm, handler = group[funcname], group.validate, group.confirm, group.handler
	for i = 1, #path do
		group = GetSubOption(group, path[i])
		if group[funcname] ~= nil then func = group[funcname] end
		handler = group.handler or handler
		if group.confirm ~= nil then confirm = group.confirm end
		if group.validate ~= nil then validate = group.validate end
	end
	return func, validate, confirm, handler
end

local function FuncName(option)
	return option.type == 'execute' and 'func' or 'set'
end

-- ActivateControl's checks before a set: an input's pattern, then validate
-- (not for an execute). A validate that errors is reported and fails.
local function Validate(option, info, validate, handler, ...)
	local validated = true
	local pattern = option.pattern
	if option.type == 'input' and type(pattern) == 'string' then
		if not strmatch((...), pattern) then validated = false end
	end
	if validated and option.type ~= 'execute' then
		local ok
		if type(validate) == 'string' then
			if handler and handler[validate] then
				ok, validated = safecall(handler[validate], handler, info, ...)
				if not ok then validated = false end
			else
				error(format("Method %s doesn't exist in handler for type execute", validate))
			end
		elseif type(validate) == 'function' then
			ok, validated = safecall(validate, info, ...)
			if not ok then validated = false end
		end
	end
	if not validated or type(validated) == 'string' then
		if not validated then
			local name = option.name
			if type(name) == 'function' then
				name = name(info)
			elseif type(name) ~= 'string' then
				name = ''
			end
			if option.usage then
				validated = name .. ': ' .. option.usage
			elseif pattern then
				validated = name .. ': Expected ' .. pattern
			else
				validated = name .. ': Invalid Value'
			end
		end
		return false, validated
	end
	return true
end

-- Whether ... would pass the row's pattern and validate: true, or false and
-- the message AceConfigDialog shows. Set runs it too; the window can call it
-- before asking to confirm, as AceConfigDialog validates first.
function OM.Validate(root, row, ...)
	local options = Options(root)
	local _, validate, _, handler = Inherited(options, row.path, FuncName(row.option))
	local info = BuildInfo(row.option, options, row.path)
	return Validate(row.option, info, validate, handler, ...)
end

-- Sets the row to ... (an execute runs its func): validates first, then calls
-- the inherited set or func with info and .... Returns true; false and the
-- message when validation fails; false when the set errors (the error goes
-- to the error handler, as AceConfigDialog's safecall sends it). It doesn't
-- confirm: the window asks first (OM.Confirm).
function OM.Set(root, row, ...)
	local options = Options(root)
	local option, path = row.option, row.path
	local func, validate, _, handler = Inherited(options, path, FuncName(option))
	local info = BuildInfo(option, options, path)
	local ok, err = Validate(option, info, validate, handler, ...)
	if not ok then return false, err end
	if type(func) == 'string' then
		if handler and handler[func] then
			return (safecall(handler[func], handler, info, ...))
		end
		error(format("Method %s doesn't exist in handler for type func", func))
	elseif type(func) == 'function' then
		return (safecall(func, info, ...))
	end
	return true
end

-- AceGUI's dropdown order for values without sorting: keys as numbers when
-- both are numbers, else as strings.
local function KeyBefore(a, b)
	local numberA, numberB = tonumber(a), tonumber(b)
	if numberA and numberB then return numberA < numberB end
	return tostring(a) < tostring(b)
end

-- The row's values as { {key, name} }, read again on every call (a values
-- function can depend on other settings). In sorting's order if the option
-- has one, else by key, as AceGUI's dropdown lists them.
function OM.Values(root, row)
	local options = Options(root)
	local list = {}
	local values = GetMember('values', row.option, options, row.path)
	if type(values) ~= 'table' then return list end
	local sorting = GetMember('sorting', row.option, options, row.path)
	local keys = {}
	if type(sorting) == 'table' then
		for _, key in ipairs(sorting) do
			if values[key] ~= nil then keys[#keys + 1] = key end
		end
	else
		for key in pairs(values) do keys[#keys + 1] = key end
		tsort(keys, KeyBefore)
	end
	for i, key in ipairs(keys) do
		list[i] = { key = key, name = values[key] }
	end
	return list
end

-- The text to confirm with before setting the row to ... (or running it),
-- or nil when it doesn't confirm. As AceConfigDialog: confirm is inherited;
-- a function or method is called with info and ..., and a string it gives is
-- the text; true uses confirmText, else the option's name and desc.
function OM.Confirm(root, row, ...)
	local options = Options(root)
	local option, path = row.option, row.path
	local _, _, confirm, handler = Inherited(options, path, FuncName(option))
	local info = BuildInfo(option, options, path)
	local confirmText = option.confirmText
	local ok
	if type(confirm) == 'string' then
		if handler and handler[confirm] then
			ok, confirm = safecall(handler[confirm], handler, info, ...)
		else
			error(format("Method %s doesn't exist in handler for type confirm", confirm))
		end
	elseif type(confirm) == 'function' then
		ok, confirm = safecall(confirm, info, ...)
	else
		ok = true
	end
	if not ok then return nil end
	if type(confirm) == 'string' then
		confirmText, confirm = confirm, true
	end
	if confirm ~= true then return nil end
	if not confirmText then
		local name, desc = option.name, option.desc
		if type(name) == 'function' then name = name(info) end
		if type(desc) == 'function' then desc = desc(info) end
		confirmText = Text(name)
		if desc then confirmText = confirmText .. ' - ' .. desc end
	end
	return confirmText
end

--[[
	Rows whose name, section title or tab title has text in it, ignoring
	case, across every page, tab and pick:
	{ {pageKey, path, name, tabName, sectionTitle} }. tabName is the tab and
	pick names down to the row (e.g. 'Player > Health'), nil on a page with
	none. Function names are called with info. Hidden and guiHidden options
	aren't searched, nor descriptions. At most 100 results, by page order.
]]
function OM.Search(root, text)
	local results = {}
	local needle = type(text) == 'string' and strtrim(text):lower() or ''
	if needle == '' then return results end
	local options = Options(root)

	local function matches(value)
		return type(value) == 'string' and value:lower():find(needle, 1, true) ~= nil
	end

	-- Adds group's matching rows; true once there are enough.
	local function Collect(pageKey, group, path, deep, tabNames)
		local tabMatch = false
		for _, name in ipairs(tabNames) do
			if matches(name) then tabMatch = true end
		end
		local tabName = #tabNames > 0 and tconcat(tabNames, ' > ') or nil
		local sections = {}
		Feed(sections, options, group, path, deep)
		for _, section in ipairs(sections) do
			local sectionMatch = matches(section.title)
			for _, row in ipairs(section.rows) do
				if row.type ~= 'description' and (tabMatch or sectionMatch or matches(row.name)) then
					results[#results + 1] = {
						pageKey = pageKey,
						path = row.path,
						name = row.name,
						tabName = tabName,
						sectionTitle = section.title,
					}
					if #results >= MAX_RESULTS then return true end
				end
			end
		end
	end

	for _, page in ipairs(OM.Pages(root)) do
		local key = page.key
		local pageOption, pagePath = options.args[key], { key }
		if Collect(key, pageOption, pagePath, false, {}) then return results end
		for _, second in ipairs(SubGroups(pageOption, options, pagePath)) do
			local group, path = GetSubOption(pageOption, second.key), Append(pagePath, second.key)
			if Collect(key, group, path, false, { second.name }) then return results end
			for _, third in ipairs(SubGroups(group, options, path)) do
				if Collect(key, GetSubOption(group, third.key), Append(path, third.key), true, { second.name, third.name }) then
					return results
				end
			end
		end
	end
	return results
end
