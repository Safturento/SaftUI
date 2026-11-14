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
	since SaftUI's own option code walks info.options.args (Config/generators.lua).

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
	as nil. A disabled tab chosen by key opens only while no tab beside it is
	enabled (a page standing down), as AceConfigDialog reopens a saved
	selection; otherwise it's the same as nil. One page keeps one selection
	across its picks, so a tab chosen on one pick can be carried to another
	where it's disabled. Search leaves out the tabs a selection can't open.

	A row is { key, type, name, desc, size = 'small' | 'normal' | 'wide',
	align, disabled, disabledDesc, path, option }: path is the keys from the
	root, option the option table. size is the option's own size member:
	'small' (honored only for a toggle, execute, input or item; a color is a
	field as wide as a dropdown, which a quarter can't hold, so it is normal) or 'wide';
	anything else is normal. Every description and every position row is wide.
	Ace's width is not read. align is an execute's own align member, SaftUI's:
	'right' or 'center' (a button the body lines up with the buttons beside
	it, optionsbody.lua), else nil. disabledDesc is the option's own
	disabledDesc member (SaftUI's: why it's disabled, a string or a function),
	read only while the row is disabled, else nil.
	A position row sits in a section of its own, titled with its name; the
	rows after it continue in an untitled one. When its option has share, the
	section carries it as shareRow, for its title's marks.

	Any option may carry share (SaftUI's own field, read raw from the option,
	never inherited): a setting a source page shares with member pages, each
	of which follows it until the setting is its own. Its functions are each
	called with the option's AceConfigDialog-style info:
	  share = {
	    source = 'Everything',   -- the page everything follows, for texts
	    page = 'Third',          -- a member page: this page's name, for texts
	    pageText = 'the third',  -- optional: page as it reads in a sentence,
	                             -- with any article the module's names take
	                             -- (Core guesses none); page when nil
	    noun = { 'page', 'pages' }, -- optional: what a member is, singular
	                             -- and plural, for texts ('every page', 'which
	                             -- pages'); the wording without one when nil
	    own = function(info) -> bool,           -- a member page: it's this page's own
	    reset = function(info),                 -- a member page: follow the source again
	    differs = function(info) -> { {name, value} }, -- the source page: who owns it, with what
	    shared = function(info) -> string,      -- the source's value, as text
	    targets = function(info) -> { {key, label} }, -- who Multiple lists
	    applyAll = function(info),
	    apply = function(info, keys),           -- the picked targets' keys, in targets' order
	  }
	A page whose share has own is a member page; one with differs the source
	page. OM.ShareState reads it for the marks (an item's menu too: OM.MenuRoot
	is the tree its options' info comes from), OM.ShareCall runs an action,
	OM.ShareTargets lists Multiple's targets. The window draws them in
	optionsshare.lua.

	An item (type = 'item', SaftUI's own type, optionsitem.lua) is one row: a
	Show box, its name and three dots that open a menu of its settings:
	  { type = 'item', name, desc, order, size = 'small' (or none, or 'wide'),
	    get, set,      -- its Show box (no get, or get = false to stop an
	                   -- inherited one: no box)
	    reserveBox,    -- true: with no box, its room kept empty, so the name
	                   -- lines up with boxed items' (read raw)
	    share,         -- its Show's (above)
	    menu = { type = 'group', name, args = { ... }, get, set, ... },
	    menuTitle,     -- the menu's title (a string or a function of info;
	                   -- the item's name when nil) }
	Its menu (SaftUI's own field, never in args) is a group drawn in a menu
	of its own (optionsmenu.lua) from the tree OM.MenuRoot(option) gives:
	{ menu = option.menu }, so a menu option's path is { 'menu', key } and
	it inherits get, set and the rest from the menu group only, not from the
	item's page. Search finds a menu's settings (OM.Search).

	Any option may carry default (SaftUI's own field, read raw from the
	option, never inherited): whether its value differs from its default
	now, and how to put the default back. The window draws a reset icon by
	the control while it differs (optionsshare.lua's OB.PlaceDefault); it is
	the standard for resets, one per setting, in place of a section's or a
	page's Reset button. Its functions are each called with the option's
	info:
	  default = {
	    differs = function(info) -> bool,  -- the value isn't its default now
	    reset = function(info),            -- puts the default back (no confirm)
	    value = function(info) -> ...,     -- the default as get gives it (a
	                                       -- color's r, g, b[, a]), which the
	                                       -- icon's tooltip names by the row's
	                                       -- type: a color's hex (with its
	                                       -- opacity when it hasAlpha), a
	                                       -- select's label, On or Off, ...
	    text = string | function(info),    -- or the default in words, which
	                                       -- wins over value
	  }
	OM.DefaultState reads it, OM.DefaultReset runs reset. A row whose share
	has own (a member page) shows only its share's Reset; a disabled row
	shows none.

	A page's group may carry a footer (SaftUI's own field, never in its args):
	a group of options the window draws in its footer while the page is open,
	its name as their one label (optionswindow.lua). BuildView hands it on as
	view.footer, and Search finds its options as the page's.

	A pick's group (a child of a group whose childGroups is 'select') may carry
	a pickerControl (SaftUI's own field, never in its args): a group of
	options, buttons, the window draws on the picker's line, right of the
	picker, while that pick is shown. BuildView hands the picked one on as
	view.picker.control, and Search finds its options on the pick's path,
	which opens the page at that pick.
]]

local OM = {}
st.OptionsModel = OM

local format, strmatch, tconcat, tsort = string.format, string.match, table.concat, table.sort
local emptyTbl = {}

-- The profile's colors. Not the model's: the one getter the options files that
-- draw (widgets, body, window) share, here as the first of them to load.
function OM.Colors() return st.config.profile.colors end

-- The most results OM.Search gives.
local MAX_RESULTS = 100

-- A pick's control's key in the tree of its own, where Search reads it from
-- and the window draws it from.
local PICKER_CONTROL_KEY = 'pickerControl'
OM.PICKER_CONTROL_KEY = PICKER_CONTROL_KEY

-- The pages the window shows apart from the module groups.
local SPECIAL = { Fonts = 'global', profile = 'profiles' }
local GLOBAL_NAME = 'Global settings'

------------------------------------------------------------------ AceConfigDialog's members

-- Members inherited from parent groups: the nearest one that isn't nil wins
-- (false included, so get = false stops inheriting).
local isInherited = {
	set = true, get = true, func = true, confirm = true, validate = true, disabled = true, hidden = true,
}
-- Members where a string is the value, not a handler method name.
local stringIsLiteral = {
	name = true, desc = true, icon = true, usage = true, width = true, image = true, fontSize = true, tooltipHyperlink = true,
	size = true, target = true, nameKey = true, pickerLabel = true, align = true, disabledDesc = true, justifyH = true,
	menuTitle = true, searchText = true,
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

-- The member as the option tree holds it, uncalled: the option's own, or
-- for an inherited member the nearest one on the path that isn't nil.
local function RawMember(membername, option, options, path)
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
	return member
end

-- AceConfigDialog's GetOptionsMemberValue: the member's value, calling it
-- with info (and ...) when it's a function, or a handler method's name.
local function GetMember(membername, option, options, path, ...)
	local member = RawMember(membername, option, options, path)
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

-- The entry with key, else the first (that isn't disabled, for tabs). A
-- disabled tab named by key opens only while no tab is enabled (a page
-- standing down), so a tab carried over from another pick can't open one
-- the user can't use.
local function Choose(list, key, skipDisabled)
	local named
	if key ~= nil then
		for _, entry in ipairs(list) do
			if entry.key == key then named = entry; break end
		end
	end
	if named and not (skipDisabled and named.disabled) then return named end
	for _, entry in ipairs(list) do
		if not (skipDisabled and entry.disabled) then return entry end
	end
	return named
end

-- The entries of a level a selection can open (Choose): every pick, and the
-- tabs that aren't disabled, or every tab while none is enabled.
local function Openable(list, slot)
	if slot == 'pick' then return list end
	local open = {}
	for _, entry in ipairs(list) do
		if not entry.disabled then open[#open + 1] = entry end
	end
	return #open > 0 and open or list
end

------------------------------------------------------------------ sections and rows

-- The types a setting can be small for. Not a color: its field is a dropdown's
-- width, and a quarter of a line is too narrow for it and its label. An item
-- (a Show box, its name and its dots) fits a quarter.
local canBeSmall = { toggle = true, execute = true, input = true, item = true }

local function SizeOf(option, options, path)
	if option.type == 'description' or option.type == 'position' then return 'wide' end
	local size = GetMember('size', option, options, path)
	if size == 'wide' then return 'wide' end
	if size == 'small' and canBeSmall[option.type] then return 'small' end
	return 'normal'
end

-- The places a button can take on its line.
local canAlign = { right = true, center = true }

local function AlignOf(option, options, path)
	if option.type ~= 'execute' then return nil end
	local align = GetMember('align', option, options, path)
	return canAlign[align] and align or nil
end

local function Row(option, options, path)
	local disabled = IsDisabled(option, options, path)
	return {
		key = path[#path],
		type = option.type,
		name = Text(GetMember('name', option, options, path)),
		desc = Desc(GetMember('desc', option, options, path)),
		size = SizeOf(option, options, path),
		align = AlignOf(option, options, path),
		disabled = disabled,
		-- Why it's disabled (SaftUI's own member, never inherited), read only then.
		disabledDesc = disabled and Desc(GetMember('disabledDesc', option, options, path)) or nil,
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
				-- A shareable block's marks go on its section's title (optionsshare.lua).
				local block = { title = Title(row.name), rows = { row } }
				if type(option.share) == 'table' then block.shareRow = row end
				sections[#sections + 1] = block
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
-- order, then by name. special is 'global' for Fonts (named Global settings)
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
	  picker = { name, values = { {key, name, desc, disabled} }, selected,
	             control = the picked group's pickerControl (a table) or nil } or nil,
	  sections = { { title, note, rows = { row } } },
	  footer = the page group's footer (a table) or nil }
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
		footer = type(page.footer) == 'table' and page.footer or nil,
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
			local control = level.child and level.child.pickerControl
			view.picker = {
				name = pickerName,
				values = level.list,
				selected = key,
				control = type(control) == 'table' and control or nil,
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

-- Whether the row's option has the member (its own, or inherited as
-- OM.Member looks it up) set to anything but nil or false, without calling
-- it: a confirm function counts whatever it would answer, and get = false
-- (AceDBOptions' Copy From and Delete, which show no value) doesn't.
function OM.Has(root, row, membername)
	local member = RawMember(membername, row.option, Options(root), row.path)
	return member ~= nil and member ~= false
end

-- Whether the row's option is disabled now, checked as when the view was
-- built (row.disabled is that answer, which a set since may have changed).
function OM.IsDisabled(root, row)
	return IsDisabled(row.option, Options(root), row.path)
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

------------------------------------------------------------------ shareable options

-- The key an item's menu sits under in OM.MenuRoot's tree.
OM.MENU_KEY = 'menu'

-- The tree an item's menu is read from: { menu = option.menu }, so an option
-- inside it has the path { 'menu', key } and its info comes from there.
function OM.MenuRoot(option)
	return { [OM.MENU_KEY] = option.menu }
end

-- The option's share (SaftUI's field, read raw: never inherited), or nil.
local function ShareOf(option)
	return type(option.share) == 'table' and option.share or nil
end

-- A share function's answer: share[name](info, ...) through safecall, or nil
-- when there's no such function or it errors (the error goes to the handler).
local function ShareAsk(share, name, info, ...)
	local func = share and share[name]
	if type(func) ~= 'function' then return nil end
	local ok, answer = safecall(func, info, ...)
	if ok then return answer end
end

-- A share's noun, { singular, plural } when it's two strings that aren't
-- empty, else nil.
local function NounOf(noun)
	if type(noun) ~= 'table' then return nil end
	local one, many = noun[1], noun[2]
	if type(one) == 'string' and one ~= '' and type(many) == 'string' and many ~= '' then return { one, many } end
end

-- A differs answer as { {name, value} }, names and values as text.
local function DiffList(answer)
	local list = {}
	if type(answer) ~= 'table' then return list end
	for _, entry in ipairs(answer) do
		if type(entry) == 'table' then list[#list + 1] = { name = Text(entry.name), value = Text(entry.value) } end
	end
	return list
end

-- The shareable options directly in an item's menu, in the menu's order and
-- not hidden: { {share, info, name} }, each info from OM.MenuRoot's tree.
local function MenuShares(option)
	local list, menu = {}, option.menu
	if type(menu) ~= 'table' or type(menu.args) ~= 'table' then return list end
	local options = Options(OM.MenuRoot(option))
	local path = { OM.MENU_KEY }
	local keys, opts = SortedOptions(menu, options, path)
	for _, key in ipairs(keys) do
		local inner, innerPath = opts[key], Append(path, key)
		local share = type(inner) == 'table' and ShareOf(inner)
		if share and not IsHidden(inner, options, innerPath) then
			list[#list + 1] = {
				share = share,
				info = (BuildInfo(inner, options, innerPath)),
				name = Text(GetMember('name', inner, options, innerPath)),
			}
		end
	end
	return list
end

--[[
	A shareable row's state: nil when neither the row's option nor (an item's)
	any option directly in its menu has share. A share's own makes its page a
	member page (it follows the source page until a setting is its own), its
	differs the source page.
	{ member, own, marked, offers, source, page, pageText, noun, shared, differs, item }:
	  own      a member page and share.own(info);
	  marked   own, or for an item any option in its menu own;
	  differs  { {name, value} }: the source page's share.differs(info); an
	           item's grouped by name in first-seen order over its own
	           differs (its Show, named 'Show') then each menu option's (by
	           its name), each value the setting names joined with ', ';
	  offers   own on a member page, or a non-empty own differs on the source
	           page (an item's Show alone);
	  source, page, shared: the share's source and page names and its
	           shared(info), as text (shared and page nil when there's none);
	  pageText, noun: the share's pageText (nil when there's none) and noun
	           ({ singular, plural }, nil unless it's two strings).
	A share function that errors is reported and counts as false or empty.
]]
function OM.ShareState(root, row)
	local option = row.option
	local share, item = ShareOf(option), row.type == 'item'
	local inner = item and MenuShares(option) or {}
	if not share and #inner == 0 then return nil end
	local first = share or inner[1].share
	local member = first.own ~= nil
	local info = share and (BuildInfo(option, Options(root), row.path))

	local own = (member and share and ShareAsk(share, 'own', info)) and true or false
	local marked = own
	if member and not marked then
		for _, each in ipairs(inner) do
			if ShareAsk(each.share, 'own', each.info) then marked = true; break end
		end
	end

	local ownDiffers = (share and not member) and DiffList(ShareAsk(share, 'differs', info)) or {}
	local differs = ownDiffers
	if item then
		local byName, order = {}, {}
		local function Add(list, settingName)
			for _, entry in ipairs(list) do
				local group = byName[entry.name]
				if not group then
					group = { name = entry.name, settings = {} }
					byName[entry.name] = group
					order[#order + 1] = group
				end
				group.settings[#group.settings + 1] = settingName
			end
		end
		Add(ownDiffers, 'Show')
		if not member then
			for _, each in ipairs(inner) do Add(DiffList(ShareAsk(each.share, 'differs', each.info)), each.name) end
		end
		differs = {}
		for i, group in ipairs(order) do differs[i] = { name = group.name, value = tconcat(group.settings, ', ') } end
	end

	local shared = share and ShareAsk(share, 'shared', info)
	return {
		member = member,
		own = own,
		marked = marked,
		offers = (member and own) or (not member and #ownDiffers > 0),
		source = Text(first.source),
		page = Title(first.page),
		pageText = Title(first.pageText),
		noun = NounOf(first.noun),
		shared = shared ~= nil and Text(shared) or nil,
		differs = differs,
		item = item,
	}
end

-- The actions a share takes (OM.ShareCall).
local shareActions = { reset = true, applyAll = true, apply = true }

-- Runs the row's share[action](info, ...) ('reset', 'applyAll', or 'apply'
-- with the picked targets' keys) through safecall: true when it ran, false
-- when there's none or it errored (the error goes to the handler).
function OM.ShareCall(root, row, action, ...)
	if not shareActions[action] then error(format('SaftUI options: no share action %q', tostring(action)), 2) end
	local share = ShareOf(row.option)
	local func = share and share[action]
	if type(func) ~= 'function' then return false end
	local info = BuildInfo(row.option, Options(root), row.path)
	return (safecall(func, info, ...)) and true or false
end

-- Who the row's Multiple lists: { {key, label} } from share.targets(info),
-- empty without targets (or when it errors).
function OM.ShareTargets(root, row)
	local list = {}
	local share = ShareOf(row.option)
	if not share then return list end
	local targets = ShareAsk(share, 'targets', (BuildInfo(row.option, Options(root), row.path)))
	if type(targets) ~= 'table' then return list end
	for _, target in ipairs(targets) do
		if type(target) == 'table' and target.key ~= nil then
			list[#list + 1] = { key = target.key, label = Text(target.label) }
		end
	end
	return list
end

-- The option's default (SaftUI's field, read raw: never inherited), or nil.
local function DefaultOf(option)
	return type(option.default) == 'table' and option.default or nil
end

-- safecall's answers packed: ok, then { n, ... }.
local function Packed(ok, ...)
	return ok, { n = select('#', ...), ... }
end

--[[
	A row's default (its option's default field, the header's): nil without
	one; else { differs, text, value }:
	  differs  default.differs(info), true or false
	  text     default.text (a string, or a function's answer) as text, or nil
	  value    default.value(info)'s answers, { n, ... }, when there's no
	           text (the drawing names them by the row's type), or nil
	A function that errors is reported and counts as false or nothing.
]]
function OM.DefaultState(root, row)
	local default = DefaultOf(row.option)
	if not default then return nil end
	local info = BuildInfo(row.option, Options(root), row.path)
	local state = { differs = ShareAsk(default, 'differs', info) and true or false }
	local text = default.text
	if type(text) == 'function' then text = ShareAsk(default, 'text', info) end
	if text ~= nil then
		state.text = Text(text)
	elseif type(default.value) == 'function' then
		local ok, values = Packed(safecall(default.value, info))
		if ok then state.value = values end
	end
	return state
end

-- Runs the row's default.reset(info) through safecall: true when it ran,
-- false when there's none or it errored (the error goes to the handler).
function OM.DefaultReset(root, row)
	local default = DefaultOf(row.option)
	local func = default and default.reset
	if type(func) ~= 'function' then return false end
	local info = BuildInfo(row.option, Options(root), row.path)
	return (safecall(func, info)) and true or false
end

--[[
	Rows whose name, section title or tab title has text in it, ignoring
	case, across every page, tab and pick:
	{ {pageKey, path, name, tabName, sectionTitle, footer, menu} }. tabName is the tab and
	pick names down to the row (e.g. 'Player > Health'), nil on a page with
	none. Function names are called with info. Hidden and guiHidden options
	aren't searched, nor descriptions, nor a tab a selection can't open (a
	disabled one beside an enabled one: Choose). At most 100 results, by page
	order. A page's footer's options come after the page's own, under the
	footer's name as their tabName, with footer = true; their path is the
	page's key and theirs, which opens the page (and nothing more: a footer
	result's path isn't one a selection can follow).
	An item's menu settings follow its row (whether or not the item itself
	matches), found as a page's are: by their name, the item's name (their
	section title) or a tab name above the item; hidden ones aren't. Each is
	{ pageKey, path = the item's path, name = the setting's name, tabName,
	sectionTitle = the item's name, menu = true }, which opens the page with
	the item in view and its menu open; an item in a page's footer gives
	footer = true too, as its own row does (the page opens as it is).
	A pick's control's options (its pickerControl) follow the pick's own
	options, before its tabs', under the pick's name (and the names above
	it); their path is the pick's (the page's key and the pick's), which
	opens the page at that pick. One with searchText (SaftUI's own plain
	string field, more words to match) is a control shared by every pick: it is
	listed once (the first in page order), as footer = true with the path
	{ pageKey, its key }, so a result opens the page as it is.
]]
function OM.Search(root, text)
	local results = {}
	local needle = type(text) == 'string' and strtrim(text):lower() or ''
	if needle == '' then return results end
	local options = Options(root)
	local sharedSeen = {} -- the shared controls (searchText) already listed

	local function matches(value)
		return type(value) == 'string' and value:lower():find(needle, 1, true) ~= nil
	end

	-- Adds the matching settings of an item's menu (row, an item's row): by
	-- their name, the item's name or a tab's (tabMatch), each a result on the
	-- item's path (a footer's item's with footer, as its own row's; at, a
	-- pick's control's, in place of it); true once there are enough.
	local function CollectMenu(pageKey, row, tabMatch, tabName, footer, at)
		local menu = row.option.menu
		if type(menu) ~= 'table' or menu.type ~= 'group' then return end
		local within = Options(OM.MenuRoot(row.option))
		local itemMatch = matches(row.name)
		local sections = {}
		Feed(sections, within, menu, { OM.MENU_KEY }, false)
		for _, section in ipairs(sections) do
			for _, inner in ipairs(section.rows) do
				if inner.type ~= 'description' and (tabMatch or itemMatch or matches(inner.name)) then
					results[#results + 1] = {
						pageKey = pageKey,
						path = at or row.path,
						name = inner.name,
						tabName = tabName,
						sectionTitle = row.name,
						footer = footer or nil,
						menu = true,
					}
					if #results >= MAX_RESULTS then return true end
				end
			end
		end
	end

	-- Adds group's matching rows; true once there are enough. within is the
	-- tree its path is from (the root's, or a footer's or a pick's control's
	-- own); at, the path every result takes in place of its row's (a pick's
	-- control's: the pick's).
	local function Collect(pageKey, group, path, deep, tabNames, within, footer, at)
		local tabMatch = false
		for _, name in ipairs(tabNames) do
			if matches(name) then tabMatch = true end
		end
		local tabName = #tabNames > 0 and tconcat(tabNames, ' > ') or nil
		local sections = {}
		Feed(sections, within or options, group, path, deep)
		for _, section in ipairs(sections) do
			local sectionMatch = matches(section.title)
			for _, row in ipairs(section.rows) do
				-- searchText (SaftUI's own field, a plain string): more words a
				-- search matches, so a control the pick's tabs repeat is found
				-- by what it is. A row with it is one control, whatever pick
				-- drew it: listed once (the first in page order), on the page
				-- as it is (footer = true), its path the page's key and its own.
				local words = type(row.option) == 'table' and rawget(row.option, 'searchText') or nil
				local shared = at ~= nil and type(words) == 'string'
				local hit = row.type ~= 'description'
					and (tabMatch or sectionMatch or matches(row.name) or (shared and matches(words)))
				if hit and shared then
					local id = pageKey .. '\0' .. tostring(row.key)
					if sharedSeen[id] then hit = false end
					sharedSeen[id] = true
				end
				if hit then
					results[#results + 1] = {
						pageKey = pageKey,
						path = shared and { pageKey, row.key } or at or row.path,
						name = row.name,
						tabName = tabName,
						sectionTitle = section.title,
						footer = (footer or shared) or nil,
					}
					if #results >= MAX_RESULTS then return true end
				end
				if row.type == 'item' and CollectMenu(pageKey, row, tabMatch, tabName, footer, at) then return true end
			end
		end
	end

	-- A pick's control (group, the pick's group, at path, in slot 'pick'): its
	-- options, a tree of their own, each on the pick's path; true once there
	-- are enough.
	local function CollectControl(pageKey, slot, group, path, tabNames)
		local control = group.pickerControl
		if slot ~= 'pick' or type(control) ~= 'table' then return end
		local within = Options({ [PICKER_CONTROL_KEY] = control })
		return Collect(pageKey, control, { PICKER_CONTROL_KEY }, false, tabNames, within, nil, path)
	end

	for _, page in ipairs(OM.Pages(root)) do
		local key = page.key
		local pageOption, pagePath = options.args[key], { key }
		if Collect(key, pageOption, pagePath, false, {}) then return results end
		-- The page's footer: a tree of its own under the page's key, so a
		-- result's path names the page.
		local footer = pageOption.footer
		if type(footer) == 'table' then
			local within = Options({ [key] = footer })
			local name = Text(GetMember('name', footer, within, pagePath))
			if Collect(key, footer, pagePath, false, name ~= '' and { name } or {}, within, true) then return results end
		end
		local slot = SlotFor(2, nil, pageOption)
		for _, second in ipairs(Openable(SubGroups(pageOption, options, pagePath), slot)) do
			local group, path = GetSubOption(pageOption, second.key), Append(pagePath, second.key)
			if Collect(key, group, path, false, { second.name }) then return results end
			if CollectControl(key, slot, group, path, { second.name }) then return results end
			local thirdSlot = SlotFor(3, slot, group)
			for _, third in ipairs(Openable(SubGroups(group, options, path), thirdSlot)) do
				local thirdGroup, thirdPath = GetSubOption(group, third.key), Append(path, third.key)
				if Collect(key, thirdGroup, thirdPath, true, { second.name, third.name }) then
					return results
				end
				if CollectControl(key, thirdSlot, thirdGroup, thirdPath, { second.name, third.name }) then return results end
			end
		end
	end
	return results
end
