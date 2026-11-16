-- The world the shared-settings tests (shared_test.lua, shared_upgrade_test.lua) stand in, returned as
-- SW. Not a test (no _test suffix); load it with `local SW = load_test_file('unitframes/shared_world.lua')`.
-- It makes no globals.
--
--   SW.world(opts) -> st, UF, P
--     A fresh world (reset_world()): uf_world.lua's (opts as UW.world's) with config/shared.lua and every unit's config file,
--     'all' too, and every element file, Name's too. UF.units, UF.groups and UF.holders hold a frame
--     by config unit, so UF:GetConfigTable builds the member pages (the frames have no elements).
--     opts.bare: the world without Task 2's files (no units/all.lua, no shared.lua): the base the inertness
--     test compares the saved data of the same operations with.
--   SW.MEMBERS, SW.ELEMENTS, SW.NOT_SHARED(path)
--   SW.rows(UF, unit) -> { { path, type, key, name, hand, at }, ... }
--     Every value row of the member's page with the path below the unit it saves at (nil for the six
--     hand-default rows), and where it sits on the page (at).
--   SW.page_keys(UF, unit) -> { [key] = true }, { <paths no entry covers> }
--   SW.snapshot(profile) -> plain table
--     Every member's every UF.SHARED path, and its enable, width, height and position: what each
--     member shows, as plain values (a color as r, g, b, a table as a copy).
--   SW.same(a, b) -> ok, { '<unit>.<path>', ... }
--     Two snapshots compared as the shared compare does, per path.
--   SW.customize(profile)
--     The fixed changes the upgrade tests make to a unit frame profile.
--   SW.acedb(saved) -> db
--     A real AceDB-3.0 over st.defaults (as tests/core/default_at_acedb_test.lua builds one) whose
--     unit frame profile 'SaftUI' is saved (a table, as AceDB keeps it: only what differs),
--     with st.config pointed at it. db.profile.unitframes.profiles.SaftUI is the profile.
--   SW.relog(db) -> db
--     PLAYER_LOGOUT (AceDB strips what equals a default), then a new AceDB over the stripped saved data.
--   SW.step(UF)
--     The once-a-frame update's next frame: UF.sharedTicker's OnUpdate, while it is shown.
local UW = load_test_file('unitframes/uf_world.lua')

local SW = {}

SW.MEMBERS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40' }

-- UW.ELEMENTS with the Name element, which the member pages need.
SW.ELEMENTS = { 'name', 'auras', 'power', 'additionalpower', 'health', 'castbar', 'classpower', 'indicators' }

local PLATES = { 'nameplate', 'friendlynameplate' }

function SW.world(opts)
	opts = opts or {}
	reset_world()
	local units = {}
	for _, unit in ipairs(UW.UNITS) do
		if not (opts.bare and unit == 'all') then units[#units + 1] = unit end
	end
	for _, unit in ipairs(PLATES) do units[#units + 1] = unit end
	local after = opts.bare and {} or { 'config/shared' }
	for _, file in ipairs(opts.after or {}) do after[#after + 1] = file end
	local st, UF, P = UW.world({
		client = opts.client, position = true, units = units, after = after, elements = opts.elements or SW.ELEMENTS,
		colors = opts.colors, ouf = opts.ouf,
	})
	UF.units, UF.groups = UF.units or {}, UF.groups or {}
	for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss' }) do
		UF.units[unit] = CreateFrame('Frame', nil, UIParent)
	end
	for _, group in ipairs({ 'party', 'raid10', 'raid40' }) do
		UF.groups[group] = CreateFrame('Frame', nil, UIParent)
		UF.holders[group] = CreateFrame('Frame', nil, UIParent)
	end
	return st, UF, P
end


local VALUE = {
	toggle = true, range = true, select = true, multiselect = true, input = true, color = true,
	keybinding = true, font = true, position = true, item = true,
}

--   SW.rows(UF, unit) -> { { path = '<a.b.c>', type = <row type>, key = <option key>, name = <its name>,
--     hand = <true for a row with a hand default>, at = '<the option path joined by />' }, ... }
--     Every value row of the member's page (UF:GetConfigTable()), by the path below the unit that it
--     saves at (its `saved` field, as the options kit's reset reads it; an item row, a part row, counts
--     too), in page order. A row with no saved path (the six with a hand default) has path nil.
function SW.rows(UF, unit)
	local st = SaftUI
	local OM = st.OptionsModel
	if not each_option then load_test_file('lib/options_walk.lua') end
	local tree = UF:GetConfigTable()
	local page = tree.args[unit]
	local root = { Unitframes = { type = 'group', name = 'Unit frames', childGroups = 'select', args = { [unit] = page } } }
	local out = {}
	-- The saved path of the row at path in root (below the unit), as the model finds it.
	local function SavedPath(root, path)
		-- The node that gives the row its get, as the model finds it.
		local group, node = { args = root }, nil
		for _, key in ipairs(path) do
			group = OM.SubOption(group, key)
			if not group then return nil end
			if group.get ~= nil and not OM.HandsOn(group) then node = group end
		end
		if not (node and type(node.saved) == 'function') then return nil end
		local parts = { node.saved(OM.Info(root, path)) }
		if parts[1] ~= 'unitframes' or parts[4] ~= unit then return nil end
		return table.concat(parts, '.', 5)
	end
	local function Hand(option)
		return type(option.default) == 'table' and type(option.default.differs) == 'function' or nil
	end
	-- The row's place as the old pages had it: the elements' own tab, whatever tab or part holds them now
	-- ('Unitframes/<unit>/Health/colors/custom/customColor', '.../Buffs/buttons/border'), which page_keys reads.
	local function Legacy(keys)
		local out = { 'Unitframes', unit }
		for i, key in ipairs(keys) do
			if not ((i == 1 and key == 'Auras') or (i == 2 and key == 'bar' and keys[1] == 'Power')) then out[#out + 1] = key end
		end
		return table.concat(out, '/')
	end
	-- each_option visits an item's menu under the item's path and 'menu'; a menu's rows are saved and
	-- read through OM.MenuRoot, and sit where the old page had them (the part's element and sub group).
	each_option({ args = root }, function(option, path)
		if type(option) ~= 'table' or not VALUE[option.type] then return end
		local at, itemAt
		for i = 2, #path do
			if path[i] == 'menu' and i > 2 then at = i break end
		end
		local walkRoot, full, keys = root, path, nil
		if at then
			local item = { args = root }
			for i = 1, at - 1 do item = OM.SubOption(item, path[i]) end
			walkRoot, full = OM.MenuRoot(item), {}
			for i = at, #path do full[#full + 1] = path[i] end
			local part
			for _, candidate in ipairs(UF.PARTS) do
				if candidate.key == path[at - 1] then part = candidate end
			end
			keys = { part and part.element or tostring(path[at - 1]) }
			if part and part.sub then keys[#keys + 1] = part.sub end
			for i = at + 1, #path do keys[#keys + 1] = path[i] end
		else
			-- Inside a mirror group: the part's own rows are counted at the part.
			local node = { args = root }
			for i, key in ipairs(path) do
				node = OM.SubOption(node, key)
				if node and node.mirrorOf and i < #path then return end
			end
			keys = {}
			for i = 3, #path do keys[#keys + 1] = path[i] end
		end
		-- A part row's box is its Enable, the toggle it was (L10): an entry's type is toggle.
		local row = { type = option.type == 'item' and 'toggle' or option.type, key = path[#path], name = option.name }
		row.path = SavedPath(walkRoot, full)
		row.hand = Hand(option)
		row.at = Legacy(keys)
		out[#out + 1] = row
	end)
	return out
end

-- What no entry covers: the frame's own Enable, size, place and the group layout, Range, and the two
-- bars only Player has.
local NOT_SHARED = {
	enable = true, width = true, height = true, position = true, growthDirection = true, spacing = true,
	columnSpacing = true, initialAnchor = true, maxColumns = true, unitsPerColumn = true, showPlayer = true,
}
local function NotShared(path)
	return NOT_SHARED[path] or path:match('^range_alpha%.') or path:match('^classpower%.') or path:match('^additionalpower%.')
end
SW.NOT_SHARED = NotShared

--   SW.page_keys(UF, unit) -> { [key] = true }, { '<path>', ... }
--     The keys of UF.SHARED the member's page has a row for (the six hand-default rows by where they sit
--     on the page), and the saved paths of rows that are neither an entry nor one of the unit's own.
function SW.page_keys(UF, unit)
	local keys, extra = {}, {}
	for _, row in ipairs(SW.rows(UF, unit)) do
		if row.path then
			local entry = UF.SHARED_BY_PATH[row.path]
			if entry then
				keys[entry.key] = true
			elseif not NotShared(row.path) then
				extra[#extra + 1] = row.path
			end
		elseif row.hand and not row.at:find('/AdditionalPower/', 1, true) then
			local element, rest = row.at:match('^Unitframes/[^/]+/(%w+)/(.*)$')
			local config = element and element:lower()
			if rest == 'colors/custom/customColor' then
				keys[config .. '.customColor'] = true
			elseif rest == 'text/customColor' then
				keys[config .. '.text.customColor'] = true
			elseif rest == 'buttons/border' then
				keys[config .. '.border'] = true
			else
				extra[#extra + 1] = row.at
			end
		end
	end
	return keys, extra
end

local function Plain(value)
	if type(value) ~= 'table' then return value end
	local copy = {}
	for k, v in pairs(value) do
		-- (A color's methods are fields of its table: they are not values.)
		if type(v) ~= 'function' then copy[k] = Plain(v) end
	end
	return copy
end

local function Join(path) return table.concat(path, '.') end

function SW.snapshot(profile)
	local UF = SaftUI:GetModule('Unitframes')
	local out = {}
	for _, unit in ipairs(SW.MEMBERS) do
		local config = profile[unit]
		local shown = {}
		out[unit] = shown
		if type(config) == 'table' then
			for _, entry in ipairs(UF.SHARED) do
				for _, path in ipairs(entry.paths) do
					local node = config
					for _, key in ipairs(path) do
						if type(node) ~= 'table' then node = nil break end
						node = node[key]
					end
					shown[Join(path)] = Plain(node)
				end
			end
			for _, key in ipairs({ 'enable', 'width', 'height', 'position' }) do shown[key] = Plain(config[key]) end
		end
	end
	return out
end

local function Equal(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for k, v in pairs(a) do
		if not Equal(v, b[k]) then return false end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

-- Two snapshots, key for key: exactly the same values (stricter than the shared compare, which takes
-- '5' for 5).
function SW.same(a, b)
	local diffs = {}
	for _, unit in ipairs(SW.MEMBERS) do
		local keys = {}
		for k in pairs(a[unit] or {}) do keys[k] = true end
		for k in pairs(b[unit] or {}) do keys[k] = true end
		for k in pairs(keys) do
			if not Equal((a[unit] or {})[k], (b[unit] or {})[k]) then diffs[#diffs + 1] = unit .. '.' .. k end
		end
	end
	table.sort(diffs)
	return #diffs == 0, diffs
end

-- The fixed changes of the upgrade tests, on the unit frame profile in use.
function SW.customize(profile)
	for _, unit in ipairs(SW.MEMBERS) do profile[unit].name.font = 'pixel' end
	profile.party.name.showLevel = true
	profile.raid40.health.text.enable = true
	profile.target.buffs.size = 30
	profile.focus.castbar.colors.normal = { r = 1, g = 0, b = 0 }
	local green = CreateColor(1, 1, 1)
	green:SetRGB(0, 1, 0)
	profile.target.castbar.colors.normal = green
	profile.boss.raidtargetindicator.position.x_off = '5'
	profile.player.theme = 'thin'
	profile.pet.power.enable = true
	profile.target.name.font = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }
	profile.focus.name.position = { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 2, element = false }
end

local sv_count = 0

function SW.acedb(saved)
	local st = SaftUI
	if not LibStub('AceDB-3.0', true) then
		load_saftui('SaftUI-Core/Libraries/CallbackHandler-1.0/CallbackHandler-1.0.lua')
		load_saftui('SaftUI-Core/Libraries/Ace3/AceDB-3.0/AceDB-3.0.lua')
	end
	local AceDB = LibStub('AceDB-3.0')
	local sv = { profiles = { SaftUI = { unitframes = { profiles = { SaftUI = saved or {} } } } } }
	sv_count = sv_count + 1
	local db = AceDB:New(sv, { profile = st.defaults }, 'SaftUI')
	st.config = db
	return db
end

-- What WoW's SavedVariables file keeps: strings, numbers, booleans and tables; functions are dropped (a
-- color object's methods are fields of its table in game, and are not in the file).
local function SavedCopy(value, seen)
	if type(value) ~= 'table' then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local copy = {}
	seen[value] = copy
	for k, v in pairs(value) do
		if type(v) ~= 'function' and type(v) ~= 'userdata' then copy[k] = SavedCopy(v, seen) end
	end
	return copy
end
SW.saved_copy = SavedCopy

-- A login over saved data (a table as SW.acedb's db.sv, or SW.relog's): AceDB fills the defaults in.
function SW.acedb_from(sv)
	local st = SaftUI
	if not LibStub('AceDB-3.0', true) then
		load_saftui('SaftUI-Core/Libraries/CallbackHandler-1.0/CallbackHandler-1.0.lua')
		load_saftui('SaftUI-Core/Libraries/Ace3/AceDB-3.0/AceDB-3.0.lua')
	end
	local db = LibStub('AceDB-3.0'):New(sv, { profile = st.defaults }, 'SaftUI')
	st.config = db
	return db
end

-- A logout and a login, as the game does them: PLAYER_LOGOUT (AceDB strips what equals a default), the saved
-- data written out and read back (functions dropped, no table shared with the old session), then AceDB over it.
function SW.logout(db)
	stub.fire_event('PLAYER_LOGOUT')
	LibStub('AceDB-3.0').db_registry[db] = nil
	return SavedCopy(db.sv)
end

function SW.relog(db)
	return SW.acedb_from(SW.logout(db))
end

function SW.step(UF)
	local frame = UF.sharedTicker
	if frame and frame:IsShown() then stub.fire_script(frame, 'OnUpdate', 0.016) end
end

return SW
