-- AceConfigRegistry-3.0's own validator over the real /sui tree, so a module
-- table AceConfig wouldn't accept fails the suite.
--
-- Config:RegisterOptions registers the tree with validation skipped:
-- AceConfigRegistry only validates when its getter hands a table to a UI,
-- nothing asks it for SaftUI's, and the validator rejects SaftUI's own fields
-- (category, size, target, nameKey) and its own option type, position. So
-- this runs it instead, over ace_ready (options_walk.lua) of the tree as
-- registered: a copy with those left out, so AceConfig checks the rest.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua: Fonts, Edit mode and AceDBOptions' profiles), and the
-- modules whose tables build here with no frames of their own made:
-- Experience, the minimap and the micro menu. The others (action bars, bags,
-- chat, loot, buffs, the swing timer, the totem bar, the tooltip) build their
-- table only once OnEnable has made their frames, which needs Blizzard frames
-- the stubs don't have. Unit frames need oUF; tests/unitframes/config_test.lua
-- validates their table, built with stand-ins.

load_test_file('core/config_helpers.lua')
load_test_file('core/options_walk.lua')
local st = SaftUI
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')

CreateFrame('Frame', 'Minimap', UIParent) -- Blizzard's, which experience.lua and the minimap's files find
for _, file in ipairs({
	'SaftUI-Misc/experience.lua',
	'SaftUI-Minimap/minimap.lua', 'SaftUI-Minimap/config.lua', 'SaftUI-Minimap/micromenu.lua',
}) do
	load_saftui(file)
end

-- The table Config:RegisterOptions registers.
local function Registered(root)
	return { name = st.name, type = 'group', args = root }
end

local function Validate(options)
	return pcall(AceConfigRegistry.ValidateOptionsTable, AceConfigRegistry, options, st.name)
end

test("every page of the /sui tree passes AceConfigRegistry validation, SaftUI's fields aside", function()
	local root = st.Config:GetOptionsTable()
	local keys = {}
	for key in pairs(root) do keys[#keys + 1] = key end
	table.sort(keys)
	eq(table.concat(keys, ','), 'Experience,Fonts,MicroMenu,Minimap,profile', 'the pages built here')
	local ok, err = Validate(ace_ready(Registered(root)))
	check(ok, 'valid: ' .. tostring(err))
	check(root.Experience.category ~= nil, "the modules' own tables keep their category")
	eq(root.Experience.args.general.args.position.type, 'position', 'and their Position option')
end)

test('the check is real: a malformed option fails it, and so does each field ace_ready leaves off', function()
	local root = st.Config:GetOptionsTable()
	root.Experience.args.bogus = { type = 'toggle', name = 'Bogus', widht = 'full' }
	local ok, err = Validate(ace_ready(Registered(root)))
	check(not ok and tostring(err):find('unknown parameter', 1, true) ~= nil, 'a misspelt field: ' .. tostring(err))

	root = st.Config:GetOptionsTable()
	root.Minimap.args.bad = { type = 'range', name = 'Bad', min = 'low' }
	check(not Validate(ace_ready(Registered(root))), 'a field of the wrong type')

	root = st.Config:GetOptionsTable()
	root.MicroMenu.args.odd = { type = 'slider', name = 'Odd' }
	check(not Validate(ace_ready(Registered(root))), 'a type AceConfig has no widget for')

	-- Why ace_ready leaves them off, and why registering skips validation:
	-- AceConfig doesn't know SaftUI's fields or its position type.
	for _, field in ipairs({ 'category', 'size', 'target', 'nameKey' }) do
		local page = { type = 'group', name = 'Page', args = { t = { type = 'toggle', name = 'T' } } }
		page.args.t[field] = 'x'
		ok, err = Validate(Registered({ Page = page }))
		check(not ok and tostring(err):find(field, 1, true) ~= nil, field .. ' is unknown to it: ' .. tostring(err))
		check(Validate(ace_ready(Registered({ Page = page }))), 'and passes once left off')
		eq(page.args.t[field], 'x', 'the original keeps it')
	end
	local page = { type = 'group', name = 'Page', args = { pos = st.Config.generators.position(1, true, {}) } }
	ok, err = Validate(Registered({ Page = page }))
	check(not ok and tostring(err):find('position', 1, true) ~= nil, 'a Position option is unknown to it: ' .. tostring(err))
	check(Validate(ace_ready(Registered({ Page = page }))), 'and passes once left out')
	check(page.args.pos ~= nil, 'the original keeps it')
end)
