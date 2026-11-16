local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The unit frame pages' parts: the small things a unit frame draws (its name,
	its texts, its icons, a row of class power points) as half rows in General's
	Parts section, each with a check box (its Enable), a summary (where it sits),
	and a menu of its other settings; and the bars and auras as tabs.

	UF.PARTS says, in one line each, which element is a part and where it is
	drawn. The option tables are the elements' own (their GetConfigTable, as
	they are): a part row's menu holds the very tables of its element's group
	but its Enable, which is the row's box; a part drawn as a tab is the group
	as it is. So declaring a part a tab (place = 'tab') moves it and changes
	nothing else: the settings, their resets and their saved paths are the same.

	  key       the part's name in the page and in the tests
	  name      what the page calls it
	  element   its element's key (UF:RegisterElement), whose tab the options
	            come from
	  config    the key of its settings in the unit's config
	  sub       the settings are the tab's group of this key (the Health tab's
	            Text), not the whole tab
	  place     'row' (the Parts section of General) or 'tab'
	  under     a tab placed as a second-row tab of this element's tab
	  mirror    the part's menu is also drawn on that element's tab (its sub
	            group, which then says mirrorOf: the options kit finds and
	            walks those rows once, at the part)

	A part is on a unit when its element is (the element's ValidUnit). The row
	order of the Parts section is this list's.

	Additional power ships as a page under Power, not a row: its menu laid out
	under Thick at full size would be about 1070 tall, over the rule that a
	part's menu fits in the options window's least height (st.OptionsWindow.LAYOUT.own
	.height, 700). Moving it to a row is the word 'row' here, and a test fails any
	part whose menu is over the rule.
]]
UF.PARTS = {
	{ key = 'name', name = 'Name', element = 'Name', config = 'name', place = 'row' },
	{ key = 'subtext', name = 'Subtext', element = 'Subtext', config = 'subtext', place = 'row' },
	{ key = 'healthtext', name = 'Health text', element = 'Health', config = 'health', sub = 'text', place = 'row', mirror = 'Health' },
	{ key = 'threat', name = 'Threat', element = 'Threat', config = 'threat', place = 'row' },
	{ key = 'powertext', name = 'Power text', element = 'Power', config = 'power', sub = 'text', place = 'row', mirror = 'Power' },
	{ key = 'classpower', name = 'Class power', element = 'ClassPower', config = 'classpower', place = 'row' },
	{ key = 'additionalpower', name = 'Additional power', element = 'AdditionalPower', config = 'additionalpower', place = 'tab', under = 'Power' },
	{ key = 'raidtarget', name = 'Raid target', element = 'RaidTargetIndicator', config = 'raidtargetindicator', place = 'row' },
	{ key = 'raidrole', name = 'Raid role', element = 'RaidRoleIndicator', config = 'raidroleindicator', place = 'row' },
	{ key = 'grouprole', name = 'Group role', element = 'GroupRoleIndicator', config = 'grouproleindicator', place = 'row' },
	{ key = 'readycheck', name = 'Ready check', element = 'ReadyCheckIndicator', config = 'readycheckindicator', place = 'row' },
	{ key = 'quest', name = 'Quest', element = 'QuestIndicator', config = 'questindicator', place = 'row' },
}

-- An element as the pages name it: the words of a part's summary and of its
-- position's tooltip ("Right of Cast bar: 2, 3").
UF.ELEMENT_NAMES = {
	Health = 'Health',
	Power = 'Power',
	Castbar = 'Cast bar',
	Name = 'Name',
	Subtext = 'Subtext',
	Threat = 'Threat',
	Buffs = 'Buffs',
	Debuffs = 'Debuffs',
	ClassPower = 'Class power',
	AdditionalPower = 'Additional power',
	RaidTargetIndicator = 'Raid target',
	RaidRoleIndicator = 'Raid role',
	GroupRoleIndicator = 'Group role',
	ReadyCheckIndicator = 'Ready check',
	QuestIndicator = 'Quest',
}

local function ElementName(element)
	return UF.ELEMENT_NAMES[element] or tostring(element)
end

function UF.PartFor(key)
	for _, part in ipairs(UF.PARTS) do
		if part.key == key then return part end
	end
end

-- Whether unit's frames have the element (it is registered with options, and
-- its ValidUnit passes).
local function HasElement(unit, element)
	local registered = UF.elements and UF.elements[element]
	if unit == 'all' then
		-- All units: the elements some unit has a shared setting of (sharedoptions.lua).
		return registered ~= nil and registered.GetConfigTable ~= nil and UF.SharesElement ~= nil and UF.SharesElement(element)
	end
	return registered ~= nil and registered.GetConfigTable ~= nil
		and (not registered.ValidUnit or registered.ValidUnit(unit) and true or false)
end

-- The parts unit has, in UF.PARTS' order.
function UF.UnitParts(unit)
	local parts = {}
	for _, part in ipairs(UF.PARTS) do
		if HasElement(unit, part.element) then parts[#parts + 1] = part end
	end
	return parts
end

-- The part's settings in unit's config, looked up on every call (a profile
-- change replaces the tables).
local function PartConfig(unit, part)
	local config = UF:GetProfileConfig()[unit][part.config]
	if part.sub then config = config[part.sub] end
	return config
end

-- A unit's name as its page is named, for a frame named SaftUI_<label>: the
-- label with the spaces taken out ("Raid10"), else the label as it is.
local function UnitLabelName(label)
	for _, names in ipairs({ UF.unit_strings or {}, UF.group_strings or {} }) do
		for _, name in pairs(names) do
			if name:gsub(' ', '') == label then return name end
		end
	end
	return label
end

--[[
	The one word a part's summary shows: what its Position is anchored to
	(UF:GetFrame's order: an element the unit frame has, else a global frame,
	else the unit frame).
	  an element        its name as the pages name it (Health, Cast bar)
	  UIParent          Screen
	  SaftUI_<label>    the unit whose frame it is (SaftUI_Player: Player)
	  another frame     the name as typed
	  nothing           Unit frame
]]
function UF.PartAnchorWord(unit, position)
	if type(position) ~= 'table' then return nil end
	local element = position.element
	if element and HasElement(unit, element) then return ElementName(element) end
	local frame = position.frame
	if frame and frame ~= '' then
		if frame == 'UIParent' or frame == UIParent then return 'Screen' end
		if type(frame) ~= 'string' then return frame.GetName and frame:GetName() or '?' end
		local label = frame:match('^SaftUI_(.+)$')
		return label and UnitLabelName(label) or frame
	end
	return 'Unit frame'
end

-- function(info) -> word, tip: the part's summary. The tip is the whole position
-- in edit mode's words ("Right of Health: -7, -1"); nil without edit mode. Run on
-- every draw of the row, so it only reads.
function UF.PartSummary(unit, part)
	return function()
		local position = PartConfig(unit, part).position
		local word = UF.PartAnchorWord(unit, position)
		if not word then return nil end
		return word, st.OptionsBody.PositionText(position, true, ElementName)
	end
end

-- What a part with no Enable (Subtext) says its row does.
local NO_ENABLE_DESC = {
	subtext = "The line under the plate's name: an NPC's title or a player's guild. Always on; its settings are in the menu.",
}

-- The part's menu: a group with the very option tables of the part's group but
-- its Enable (the row's check box). A menu option inherits its get, set, saved
-- and handler from the menu group alone, so the group's are carried over.
local function MenuOf(part, group)
	local menu = {}
	for key, value in pairs(group) do menu[key] = value end
	menu.type = 'group'
	menu.name = part.name
	menu.inline = nil
	menu.order = nil
	menu.args = {}
	for key, option in pairs(group.args) do
		if key ~= 'enable' then menu.args[key] = option end
	end
	return menu
end

--[[
	A part as a row of General's Parts section (the options kit's part row:
	SaftUI-Core/Config/optionsitem.lua). group is the part's settings group as
	its element built it (for a part with a sub, that sub group). The check box
	is the part's Enable, written where the element's tab writes it and applied
	as it applies it (UF:UpdateConfig(unit, element)); a part with no Enable
	(Subtext) has no box and keeps its room.
]]
function UF.PartRow(unit, part, group, order)
	local enable = group.args.enable
	local item = {
		type = 'item',
		name = part.name,
		desc = enable and enable.desc or NO_ENABLE_DESC[part.key],
		order = order,
		menu = MenuOf(part, group),
		menuTitle = part.name,
		summary = UF.PartSummary(unit, part),
	}
	if enable then
		item.get = function() return PartConfig(unit, part).enable end
		item.set = function(_, value)
			PartConfig(unit, part).enable = value
			UF:UpdateConfig(unit, part.element)
		end
		if part.sub then
			item.saved = UF.SavedAt(unit, part.config, part.sub, 'enable')
		else
			item.saved = UF.SavedAt(unit, part.config, 'enable')
		end
	else
		-- Not the page's own get, which General's group would hand down.
		item.get = false
		item.reserveBox = true
	end
	return item
end

-- A part as a tab: its group as it is, its Enable first, named for the part.
function UF.PartTab(unit, part, group)
	group.inline = false
	group.name = part.name
	return group
end

--[[
	Puts the element tabs the unit has (built: element key -> the group its
	GetConfigTable made) where UF.PARTS says: a part row into General's Parts
	section, a part tab as a tab (or, with under, a second-row tab of that
	tab, whose own settings move into a tab named 'Power bar'), Buffs and
	Debuffs under Auras, every other element a tab. Health's and Power's Text
	groups say they mirror their part's row. UF:GetConfigTable (config.lua)
	calls it once every element is built, so a tab that parts nest under is
	there.
]]
function UF.PlaceElements(unit, config_table, built)
	local args = config_table.args
	local rows, placed, nested = {}, {}, {}
	for index, part in ipairs(UF.PARTS) do
		local tab = built[part.element]
		if tab then
			local group = part.sub and tab.args[part.sub] or tab
			if part.place == 'row' then
				rows[part.key] = UF.PartRow(unit, part, group, index)
				if part.mirror and part.sub then
					group.mirrorOf = { 'general', 'parts', part.key }
				end
				if not part.sub then placed[part.element] = true end
			else
				if part.under then
					nested[#nested + 1] = { part = part, tab = UF.PartTab(unit, part, group) }
				else
					args[part.element] = UF.PartTab(unit, part, group)
				end
				placed[part.element] = true
			end
		end
	end

	for element, group in pairs(built) do
		if not placed[element] and element ~= 'Buffs' and element ~= 'Debuffs' then
			args[element] = group
		end
	end

	-- Auras: Buffs and Debuffs, each as its tab was.
	if built.Buffs or built.Debuffs then
		local auras = {}
		if built.Buffs then built.Buffs.order = 1; auras.Buffs = built.Buffs end
		if built.Debuffs then built.Debuffs.order = 2; auras.Debuffs = built.Debuffs end
		args.Auras = {
			type = 'group', name = 'Auras', order = 7, childGroups = 'tab',
			args = auras,
		}
	end

	-- Second-row tabs, once every tab is there: the tab they nest under keeps
	-- its settings as its first child.
	for _, entry in ipairs(nested) do
		local under = args[entry.part.under]
		if not under then
			-- Not dropped: its settings stay reachable as a tab of their own, and the declaration is reported.
			args[entry.part.element] = entry.tab
			geterrorhandler()(("UF.PARTS: %s is declared under %s, which unit %s has no tab for"):format(entry.part.key, tostring(entry.part.under), unit))
		else
			local bar = {}
			for key, value in pairs(under) do bar[key] = value end
			bar.name = entry.part.under .. ' bar'
			bar.order = 1
			entry.tab.order = 2
			args[entry.part.under] = {
				type = 'group', name = under.name, order = under.order, childGroups = 'tab',
				args = { bar = bar, [entry.part.element] = entry.tab },
			}
		end
	end

	local general = args.general
	if general and next(rows) then
		general.args.parts = {
			order = 2000,
			name = 'Parts',
			desc = 'Each text, icon and small part of the unit frame. The dots open its settings.',
			type = 'group',
			inline = true,
			args = rows,
		}
	end
end
