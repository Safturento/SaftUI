local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	All units on the /sui pages, and the shares on each unit's. The storage and the rules are in
	shared.lua; this file draws them with the options kit's shareable options (the action bars' All
	bars and each bar are the model) and does nothing else.

	UF.DecorateShares(unit, page) runs last in a page's construction (config.lua's GetUnitConfig):
	for a member (UF.SHARE_MEMBERS) or 'all', every value row whose saved path is a shared setting
	(UF.SHARED_BY_PATH) gets its `share` field (UF.SettingShare) and, on a member, a `set` that first
	makes the unit own the setting (UF:OwnShared). A part row's box is its Enable's setting, so it is
	shared like any other. The walk reads each row's saved path as the kit does (its get node's
	`saved`); a leaf reached twice (Health text is the part's menu and the Health tab's Text section)
	is decorated once. Nothing is decorated while the profile in use does not share (UF:SharedReady):
	the page then has no share on any row, and All units' entry is UF.SharedNoticePage, which says why.

	On All units the rows keep their own sets, which write All units' values; UF:UpdateConfig('all',
	element) (unitframes.lua) copies them into the followers once, on the next frame. Writes a share
	action makes (reset, Apply to) go through the API and are applied with UF:UpdateShared.

	This file also holds the words the shares use (UF.SharedText) and `/sui uf restore` and
	`/sui uf share`.
]]

local OM -- st.OptionsModel, looked up when used: the options kit loads after the unit frames' files in some worlds

------------------------------------------------------------------ names and words

-- A unit's name as its page is named; 'all' is All units.
function UF.UnitPageName(unit)
	if unit == 'all' then return 'All units' end
	return (UF.unit_strings and UF.unit_strings[unit]) or (UF.group_strings and UF.group_strings[unit]) or unit
end

local function Get(config, path)
	local node = config
	for i = 1, #path do
		if type(node) ~= 'table' then return nil end
		node = node[path[i]]
	end
	return node
end

-- An entry's value in a unit's config table, as UF.SharedText takes it: the first path's value; a color
-- toggle's both, { toggle, color }.
function UF.SharedWhole(entry, config)
	if type(config) ~= 'table' then return nil end
	if entry.type == 'colortoggle' then
		return { toggle = Get(config, entry.paths[1]) and true or false, color = Get(config, entry.paths[2]) }
	end
	return Get(config, entry.paths[1])
end

local function Hex(color)
	if type(color) ~= 'table' then return '' end
	local r, g, b
	if color.r ~= nil then r, g, b = color.r, color.g, color.b else r, g, b = color[1], color[2], color[3] end
	local function byte(v) return math.max(0, math.min(255, math.floor((tonumber(v) or 0) * 255 + 0.5))) end
	return ('#%02X%02X%02X'):format(byte(r), byte(g), byte(b))
end

-- A setting's value in words for a tooltip (a share's `shared` and its owners' values): on or off, a select's
-- label, a font's name, a color's hex, a position in edit mode's words, a number as it is. option, optional,
-- is the row (a select's values, a percent range).
function UF.SharedText(entry, value, option)
	local kind = entry.type
	if kind == 'toggle' then
		return value and 'on' or 'off'
	elseif kind == 'select' then
		local values = option and option.values
		if type(values) == 'function' then
			local ok, list = pcall(values)
			values = ok and list or nil
		end
		if type(values) == 'table' and values[value] ~= nil then return tostring(values[value]) end
		return value == nil and 'none' or tostring(value)
	elseif kind == 'font' then
		return st:FontLabel(value)
	elseif kind == 'color' then
		return Hex(value)
	elseif kind == 'colortoggle' then
		if type(value) ~= 'table' or not value.toggle then return 'off' end
		return Hex(value.color)
	elseif kind == 'position' then
		local OB = st.OptionsBody
		return OB and OB.PositionText and OB.PositionText(value, true, UF.ELEMENT_NAMES and function(element)
			return UF.ELEMENT_NAMES[element] or element
		end) or ''
	elseif kind == 'range' and option and option.isPercent and tonumber(value) then
		return ('%d%%'):format(math.floor(value * 100 + 0.5))
	end
	if value == nil or value == '' then return 'empty' end
	return tostring(value)
end

------------------------------------------------------------------ what is on All units

-- Whether All units has the element's settings: some member has a setting of it (so Ready check is there,
-- and Class power, Additional power, Subtext and Threat, which no entry names, are not).
function UF.SharesElement(element)
	for _, entry in ipairs(UF.SHARED) do
		if entry.element == element then
			for _, unit in ipairs(UF.SHARE_MEMBERS) do
				if UF:HasShared(unit, entry.key) then return true end
			end
		end
	end
	return false
end

-- The members whose frames can have the element (its ValidUnit passes), in the members' order: who a
-- Position on All units places a part of (position.lua).
function UF.MembersWith(element)
	local registered = UF.elements and UF.elements[element]
	local list = {}
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if registered and (not registered.ValidUnit or registered.ValidUnit(unit)) then list[#list + 1] = unit end
	end
	return list
end

------------------------------------------------------------------ the shares

-- After a share action: the units whose stored value changed are updated once on the next frame.
local function Applied(changed, entry)
	if type(changed) == 'table' then UF:UpdateShared(changed, entry.element) end
end

-- The other members that have the setting, for Multiple.
local function Targets(entry, unit)
	return function()
		local list = {}
		for _, other in ipairs(UF.SHARE_MEMBERS) do
			if other ~= unit and UF:HasShared(other, entry.key) then
				list[#list + 1] = { key = other, label = UF.UnitPageName(other) }
			end
		end
		return list
	end
end

local function AllValue(entry)
	local all = UF:SharedReady() and rawget(UF:GetProfileConfig(), 'all')
	return UF.SharedWhole(entry, all)
end

--[[
	The kit's `share` for a shared setting (SaftUI-Core/Config/optionsshare.lua). On a member: it is own
	while the unit owns the key; its hover line's Reset makes it follow All units again, All gives All
	units this unit's value and every unit follows it, Multiple gives the picked units this unit's value as
	their own. On All units: a diff icon listing each unit that owns the setting and its value, and the
	line's All (every unit follows) and Multiple (the picked owners follow). option is the row, for a
	select's words.
]]
function UF.SettingShare(unit, entry, option)
	local key = entry.key
	local name = UF.UnitPageName(unit)
	local share = {
		source = 'All units',
		page = name,
		pageText = name,
		noun = { 'unit frame', 'unit frames' },
		shared = function() return UF.SharedText(entry, AllValue(entry), option) end,
		applyAll = function() Applied(UF:ApplyToAll(unit, key), entry) end,
		apply = function(_, keys) Applied(UF:ApplyTo(unit, key, keys or {}), entry) end,
	}
	if unit == 'all' then
		share.differs = function()
			local list = {}
			for _, owner in ipairs(UF:OwnersOf(key)) do
				local config = UF:GetProfileConfig()[owner]
				list[#list + 1] = { name = UF.UnitPageName(owner), value = UF.SharedText(entry, UF.SharedWhole(entry, config), option) }
			end
			return list
		end
		share.targets = function()
			local list = {}
			for _, owner in ipairs(UF:OwnersOf(key)) do
				list[#list + 1] = { key = owner, label = UF.UnitPageName(owner) }
			end
			return list
		end
	else
		share.own = function() return UF:IsOwn(unit, key) end
		share.reset = function() Applied(UF:FollowAll(unit, key), entry) end
		share.targets = Targets(entry, unit)
	end
	return share
end

-- A part row's share: its Enable's, which is the setting its check box is. nil for a part with no Enable.
function UF.PartShare(unit, part)
	local key = part.config .. (part.sub and ('.' .. part.sub) or '') .. '.enable'
	local entry = UF.SHARED_BY_KEY[key]
	return entry and UF.SettingShare(unit, entry) or nil
end

------------------------------------------------------------------ decorating a page

local VALUE = {
	toggle = true, range = true, select = true, multiselect = true, input = true, color = true,
	keybinding = true, font = true, position = true, item = true,
}

-- Option tables already decorated: a leaf one tree holds in two places (Health text) is wrapped once.
local decorated = setmetatable({}, { __mode = 'k' })

-- The member owns the key first, then the row's own set runs. Setting a row to the value it already has (a unit
-- that follows All units, left showing All units' value) is no change: it keeps following.
local function OwnThenSet(unit, entry, set)
	local key = entry.key
	return function(info, ...)
		local was = UF:IsOwn(unit, key)
		UF:OwnShared(unit, key)
		local a, b, c = set(info, ...)
		if not was then
			local profile = UF:GetProfileConfig()
			local all, config = rawget(profile, 'all'), profile[unit]
			local own = type(config) == 'table' and rawget(config, 'own')
			if all and own and UF.SameShared(entry, config, all) then own[key] = false end
		end
		return a, b, c
	end
end

-- While sharing is paused the rows have no share, but a Reset still means what it does in normal sharing: the unit
-- follows All units again (its value becomes All units' and its flag false). A hand default says so.
local function PausedReset(unit, entry, option)
	if type(option.default) == 'table' then return end
	option.default = {
		differs = function() return UF:IsOwn(unit, entry.key) end,
		reset = function()
			local profile = UF:GetProfileConfig()
			local all, config = rawget(profile, 'all'), profile[unit]
			if all and type(config) == 'table' then
				UF.CopyShared(entry, all, config)
				local own = rawget(config, 'own')
				if own then own[entry.key] = false end
				UF:UpdateConfig(unit, entry.element)
			end
		end,
		text = "All units' value",
	}
end

-- The saved path of the row below the unit ('name.font'), from the node that gives it its get, or nil.
local function SavedRelative(root, path, getNode, unit)
	if not (getNode and type(getNode.saved) == 'function') then return end
	local ok, keys = pcall(function() return { getNode.saved(OM.Info(root, path)) } end)
	if not ok or keys[1] ~= 'unitframes' or keys[2] ~= 'profiles' or keys[4] ~= unit then return end
	return table.concat(keys, '.', 5)
end

-- All units' defaults that differ from the every-unit defaults a row's derived reset reads (st.ALL_UNITS_DEFAULTS:
-- Debuffs on): a hand default says them. Toggles only, which is what there is.
local function AllUnitsDefault(option, entry, getNode, setNode)
	local default = Get(st.ALL_UNITS_DEFAULTS or {}, entry.paths[1])
	if default == nil or entry.type ~= 'toggle' or type(option.default) == 'table' then return end
	local get = option.get ~= nil and option.get or getNode and getNode.get
	local set = option.set ~= nil and option.set or setNode and setNode.set
	if type(get) ~= 'function' or type(set) ~= 'function' then return end
	option.default = {
		differs = function(info) return (get(info) and true or false) ~= (default and true or false) end,
		reset = function(info) set(info, default) end,
		value = function() return default end,
	}
end

-- An All units Position that would put a follower's part on itself through the frame it names is
-- refused, naming the unit: each follower's own check (the position editor's, on its frame) runs.
local function CheckFollowers(option, entry)
	local spec = UF.positionSpecs and UF.positionSpecs[option]
	local validate = option.validate
	if not spec then return end
	option.validate = function(info, part, value)
		local ok = true
		if validate then ok = validate(info, part, value) end
		if ok ~= true and ok ~= nil then return ok end
		if part ~= 'frame' and part ~= 'relative_to' and part ~= 'element' then return ok end
		local generators = st.Config.generators
		for _, follower in ipairs(UF.SHARE_MEMBERS) do
			if UF:HasShared(follower, entry.key) and not UF:IsOwn(follower, entry.key) then
				local target = UF:ConfigTarget(follower, spec.element, spec.key)
				if target() then
					local probe = generators.uf_element_position(0, function() end, function() end, target)
					local result = probe.validate(info, part, value)
					if result ~= true and result ~= nil then
						return UF.UnitPageName(follower) .. ': ' .. tostring(result)
					end
				end
			end
		end
		return ok
	end
end

local function Decorate(unit, option, root, path, getNode, setNode, ownOnly)
	if decorated[option] or not VALUE[option.type] then return end
	local relative = SavedRelative(root, path, getNode, unit)
	local entry = relative and UF.SHARED_BY_PATH[relative]
	if not entry then return end
	local isAll = unit == 'all'
	if not isAll and not UF:HasShared(unit, entry.key) then return end
	decorated[option] = true
	-- Sharing is paused or a newer version's (ownOnly): no share is drawn, but an edit is still the unit's own.
	if not ownOnly then option.share = UF.SettingShare(unit, entry, option) end
	if isAll and not ownOnly then
		AllUnitsDefault(option, entry, getNode, setNode)
		if option.type == 'position' then CheckFollowers(option, entry) end
		return
	end
	local set = option.set ~= nil and option.set or setNode and setNode.set
	if type(set) == 'function' then
		option.set = OwnThenSet(unit, entry, set)
	end
	-- A color with a check box (a Custom color): the box's own set.
	if type(option.toggle) == 'table' and type(option.toggle.set) == 'function' then
		option.toggle.set = OwnThenSet(unit, entry, option.toggle.set)
	end
	if ownOnly then PausedReset(unit, entry, option) end
end

local function Walk(unit, root, group, path, getNode, setNode, ownOnly)
	for key, option in pairs(group.args or {}) do
		if type(option) == 'table' then
			path[#path + 1] = key
			local get = (option.get ~= nil and not OM.HandsOn(option)) and option or getNode
			local set = option.set ~= nil and option or setNode
			if option.type == 'group' then
				Walk(unit, root, option, path, get, set, ownOnly)
			else
				Decorate(unit, option, root, path, get, set, ownOnly)
				-- An item's menu is read through the menu's own root, as the kit reads it.
				if option.type == 'item' and type(option.menu) == 'table' then
					local menu = option.menu
					Walk(unit, OM.MenuRoot(option), menu, { OM.MENU_KEY },
						(menu.get ~= nil and not OM.HandsOn(menu)) and menu or nil, menu.set ~= nil and menu or nil, ownOnly)
				end
			end
			path[#path] = nil
		end
	end
end

-- Gives a member's or All units' page its shares (the header). Does nothing, and leaves the page exactly as
-- it was built, for a unit that is not a member and while the profile in use does not share.
function UF.DecorateShares(unit, page)
	if unit ~= 'all' and not UF.IsShareMember(unit) then return end
	local ownOnly = false
	if not UF:SharedReady() then
		-- Not sharing (paused, a newer version's marker): no share on any row, but on a converted profile an
		-- edit of a unit's shared setting is still marked as the unit's own, so no later sync puts it back.
		if unit == 'all' or not UF:CanMarkOwn() then return end
		ownOnly = true
	end
	OM = OM or st.OptionsModel
	local root = { Unitframes = { type = 'group', name = 'Unit frames', childGroups = 'select', args = { [unit] = page } } }
	Walk(unit, root, page, { 'Unitframes', unit }, nil, nil, ownOnly)
end

------------------------------------------------------------------ the page while sharing is off

-- What All units' entry shows while the profile in use does not share: why, and, where it can be asked
-- for, a button. No share is drawn on any page then, and nothing is read through All units.
function UF.SharedNoticePage()
	local state = UF:SharedState()
	local text = UF.SharedStateText(state, UF:GetProfileConfig())
		or 'Shared settings have not been set up for this unit frame profile yet.'
	local canTurnOn = state == 'restored' or state == 'failed' or state == 'pending'
	return {
		name = 'All units',
		order = 0,
		type = 'group',
		childGroups = 'tab',
		pickerControl = { type = 'group', name = '', args = UF.GenerateProfileControl() },
		args = {
			general = {
				order = 0,
				name = 'General',
				type = 'group',
				args = {
					notice = { order = 1, type = 'description', name = text, fontSize = 'medium' },
					turnOn = {
						order = 2,
						type = 'execute',
						name = 'Turn on shared settings',
						desc = "Sets up All units from what each unit frame shows now, so nothing changes on screen. A backup is kept, and /sui uf restore puts it back.",
						hidden = not canTurnOn,
						confirm = state == 'restored' and UF.ShareConfirmText(UF:GetProfile()) or nil,
						func = function()
							local ok, why, queued = UF:RequestShare()
							local OW = st.OptionsWindow
							if OW and OW.SetStatus then
								OW:SetStatus(queued and 'In combat: shared settings turn on when combat ends.'
									or ok and 'Shared settings are on.' or why)
							end
						end,
					},
				},
			},
		},
	}
end

------------------------------------------------------------------ /sui uf restore and /sui uf share

local function Say(text) st:Print(text) end

-- A restore or a share asked in combat runs when combat ends, for the profile TABLE it was asked on: another
-- SaftUI profile switched to meanwhile has a unit frame profile of the same name, which must not be touched.
-- One key, so the last command asked in a fight is the one that runs.
local REQUEST_KEY = 'UnitframesShareRequest'

-- Whether the unit frame profile in use is no longer the table asked on; says so once if it is not.
local function DropIfChanged(profile)
	if UF:GetProfileConfig() == profile then return false end
	Say('The unit frame profile changed during combat, so the request was dropped and nothing was done.')
	return true
end

local function WhenText(profile)
	local backup = rawget(profile, 'backup')
	local when = type(backup) == 'table' and backup.when
	if type(when) ~= 'number' then return 'as they were before sharing' end
	local ok, text = pcall(date, '%Y-%m-%d %H:%M', when)
	return 'as they were on ' .. (ok and text or tostring(when))
end

-- Puts the named profile's shared settings back as the backup has them (see UF:RestoreShared), refreshes
-- the frames and /sui, and says what it did. No reload. Table writes, then UF:UpdateConfig, which waits for
-- combat to end for the frames themselves.
function UF:RestoreSharedNow(name, profile)
	profile = profile or rawget(st.config.profile.unitframes.profiles, name)
	if not profile then
		Say('There is no unit frame profile named ' .. tostring(name) .. ' any more.')
		return false
	end
	local ok, why = self:RestoreShared(profile)
	if not ok then
		Say(why)
		return false
	end
	if self:GetProfile() == name then
		self:UpdateConfig()
		UF.RefreshPages()
	end
	Say(('Unit frame profile %s: its shared settings are back %s, and sharing is off for it. Your units\' places, sizes and nameplates were not touched. Type /sui uf share to turn sharing on again.')
		:format(name, WhenText(profile)))
	return true
end

-- /sui uf restore: says what it would do; /sui uf restore confirm does it (in combat, once combat ends).
function UF:RestoreSharedCommand(confirmed)
	local name = self:GetProfile()
	local profile = self:GetProfileConfig()
	if type(profile) ~= 'table' or not UF.HasSharedBackup(profile) then
		Say('There is no backup of unit frame profile ' .. tostring(name) .. ' from before sharing, so there is nothing to restore.')
		return false
	end
	local missing = self:SharedState(profile) == 'missing'
	if missing then
		Say(UF.SharedStateText('missing', profile))
		return false
	end
	if not confirmed then
		Say(('This puts the shared settings of unit frame profile %s (every unit\'s look, parts, bars and auras) back %s, and turns sharing off for it. Places, sizes and nameplates are kept; shared settings changed since go back too. Type /sui uf restore confirm to do it.')
			:format(name, WhenText(profile)))
		return false
	end
	if st:QueueAfterCombat(REQUEST_KEY, function()
		if DropIfChanged(profile) then return end
		UF:RestoreSharedNow(name, profile)
	end) then
		Say('You are in combat: the unit frame settings will be restored when combat ends.')
		return false
	end
	return self:RestoreSharedNow(name)
end

-- What turning sharing on again after a restore does, said before it acts (the command and the page's button).
function UF.ShareConfirmText(name)
	return ('Turning sharing on for unit frame profile %s sets All units up from what the units show NOW (nothing changes on screen) and replaces the old backup with one of this moment, so a later /sui uf restore returns to this point, not to before sharing was first turned on.')
		:format(tostring(name))
end

-- Turns sharing on for the named profile (UF:EnableShared), then, when it is the profile in use, applies what
-- the sync changed (UF:UpdateConfig: the frames are updated without a reload) and refreshes /sui. Returns what
-- EnableShared does. Table writes, then UF:UpdateConfig, which waits for combat to end for the frames themselves.
function UF:ShareNow(name, profile)
	profile = profile or rawget(st.config.profile.unitframes.profiles, name)
	if not profile then return false, 'There is no unit frame profile named ' .. tostring(name) .. ' any more.' end
	local ok, why = self:EnableShared(profile)
	if self:GetProfile() == name then
		if ok then self:UpdateConfig() end
		UF.RefreshPages()
	end
	return ok, why
end

local function SaySharedOn(name, ok, why)
	if ok then
		Say('Shared settings are on for unit frame profile ' .. tostring(name) .. '. Nothing changed on screen; /sui > Unit frames > All units has them.')
	else
		Say(why)
	end
end

-- Asks for sharing to be turned on for the profile in use, as restore does: in combat nothing is written (a
-- conversion never runs in combat), one chat line says so, and the conversion and its line come when combat
-- ends. Returns ok, why, queued.
function UF:RequestShare()
	local name, profile = self:GetProfile(), self:GetProfileConfig()
	if st:QueueAfterCombat(REQUEST_KEY, function()
		if DropIfChanged(profile) then return end
		SaySharedOn(name, UF:ShareNow(name, profile))
	end) then
		Say('You are in combat: shared settings will be turned on for unit frame profile ' .. tostring(name) .. ' when combat ends.')
		return false, nil, true
	end
	local ok, why = self:ShareNow(name)
	return ok, why, false
end

-- /sui uf share: turns sharing on for the profile in use after a restore (or a failed setup).
function UF:ShareCommand(confirmed)
	if self:SharedState() == 'restored' and not confirmed then
		Say(UF.ShareConfirmText(self:GetProfile()) .. ' Type /sui uf share confirm to do it.')
		return false
	end
	local name = self:GetProfile()
	local ok, why, queued = self:RequestShare()
	if queued then return false end
	SaySharedOn(name, ok, why)
	return ok
end

function UF:RunShareCommand(text)
	local word, rest = (text or ''):lower():match('^%s*(%S*)%s*(.-)%s*$')
	if word == 'restore' then
		return self:RestoreSharedCommand(rest == 'confirm')
	elseif word == 'share' then
		return self:ShareCommand(rest == 'confirm')
	end
	Say('/sui uf restore puts the unit frames\' shared settings back as they were before sharing; /sui uf share turns sharing on again after a restore.')
end

if st.Config and st.Config.AddSubcommand then
	st.Config:AddSubcommand('uf', function(rest) UF:RunShareCommand(rest) end)
end
