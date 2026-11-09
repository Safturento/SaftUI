-- AceConfigRegistry-3.0's own validator over the real /sui tree, so a module
-- table AceConfig wouldn't accept fails the suite.
--
-- Config:RegisterOptions registers the tree with validation skipped:
-- AceConfigRegistry only validates when its getter hands a table to a UI,
-- nothing asks it for SaftUI's, and the validator rejects the `category` field
-- SaftUI's module tables carry. So this runs it instead, over the tree as
-- registered, with category left off a shallow copy of each page.
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
local st = SaftUI
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')

CreateFrame('Frame', 'Minimap', UIParent) -- Blizzard's, which experience.lua and the minimap's files find
for _, file in ipairs({
	'SaftUI-Misc/experience.lua',
	'SaftUI-Minimap/minimap.lua', 'SaftUI-Minimap/config.lua', 'SaftUI-Minimap/micromenu.lua',
}) do
	load_saftui(file)
end

-- The table Config:RegisterOptions registers, with each page's category left
-- off a shallow copy (the modules' own tables are untouched).
local function Registered(root)
	local args = {}
	for key, page in pairs(root) do
		local copy = {}
		for k, v in pairs(page) do copy[k] = v end
		copy.category = nil
		args[key] = copy
	end
	return { name = st.name, type = 'group', args = args }
end

local function Validate(options)
	return pcall(AceConfigRegistry.ValidateOptionsTable, AceConfigRegistry, options, st.name)
end

test('every page of the /sui tree passes AceConfigRegistry validation, category aside', function()
	local root = st.Config:GetOptionsTable()
	local keys = {}
	for key in pairs(root) do keys[#keys + 1] = key end
	table.sort(keys)
	eq(table.concat(keys, ','), 'EditMode,Experience,Fonts,MicroMenu,Minimap,profile', 'the pages built here')
	local ok, err = Validate(Registered(root))
	check(ok, 'valid: ' .. tostring(err))
	check(root.Experience.category ~= nil, "the modules' own tables keep their category")
end)

test('the check is real: a malformed option fails it, and so does category itself', function()
	local root = st.Config:GetOptionsTable()
	root.Experience.args.bogus = { type = 'toggle', name = 'Bogus', widht = 'full' }
	local ok, err = Validate(Registered(root))
	check(not ok and tostring(err):find('unknown parameter', 1, true) ~= nil, 'a misspelt field: ' .. tostring(err))

	root = st.Config:GetOptionsTable()
	root.Minimap.args.bad = { type = 'range', name = 'Bad', min = 'low' }
	check(not Validate(Registered(root)), 'a field of the wrong type')

	root = st.Config:GetOptionsTable()
	root.MicroMenu.args.odd = { type = 'slider', name = 'Odd' }
	check(not Validate(Registered(root)), 'a type AceConfig has no widget for')

	-- Why it's left off, and why registering skips validation.
	ok, err = Validate({ name = st.name, type = 'group', args = st.Config:GetOptionsTable() })
	check(not ok and tostring(err):find('category', 1, true) ~= nil, 'category is unknown to it: ' .. tostring(err))
end)
