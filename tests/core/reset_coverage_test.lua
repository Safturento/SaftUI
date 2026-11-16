-- Every /sui page is walked for resets. Each file the game loads that defines
-- a module's GetConfigTable is a page; PAGES names, for each, the page's key in
-- the options tree and the test file that walks it with
-- tests/lib/reset_walk.lua's R.check_page. A page added with no walk fails the
-- first case; a page whose walk was dropped fails the second. The scan wants
-- the call as written (a receiver, then the key as the second argument): a
-- test's own local check_page is not it. The walk itself checks that every
-- value row has a reset source or a stated reason (tests/lib/reset_walk.lua).
local T = load_test_file('lib/theme_helpers.lua')

-- The file that defines GetConfigTable -> the page's root key, and the test file that walks it.
local PAGES = {
	['SaftUI-Core/Config/general.lua'] = { page = 'Fonts', test = 'core/options_desc_test.lua' },
	['SaftUI-Core/EditMode/settings.lua'] = { page = 'Fonts', test = 'core/options_desc_test.lua' },
	['SaftUI-Core/Media/fonts.lua'] = { page = 'Fonts', test = 'core/options_desc_test.lua' },
	['SaftUI-Core/Media/colors.lua'] = { page = 'Fonts', test = 'core/options_desc_test.lua' },
	['SaftUI-Core/Media/theme.lua'] = { page = 'Fonts', test = 'core/options_desc_test.lua' },
	['SaftUI-Unitframes/config/config.lua'] = { page = 'Unitframes', test = 'unitframes/config_test.lua' },
	['SaftUI-ActionBars/options.lua'] = { page = 'ActionBars', test = 'actionbars/page_test.lua' },
	['SaftUI-Bags/options.lua'] = { page = 'Inventory', test = 'bags/theme_test.lua' },
	['SaftUI-Misc/tooltipposition.lua'] = { page = 'Tooltip', test = 'misc/options_pages_test.lua' },
	['SaftUI-Misc/totemoptions.lua'] = { page = 'TotemBar', test = 'misc/options_pages_test.lua' },
	['SaftUI-Misc/Skinning/skinning.lua'] = { page = 'Skinning', test = 'misc/options_pages_test.lua' },
	['SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua'] = { page = 'Auras', test = 'misc/options_pages_test.lua' },
	['SaftUI-Misc/Skinning/blizzard/Blizzard_SwingTimerPosition.lua'] = { page = 'SwingTimer', test = 'misc/options_pages_test.lua' },
	['SaftUI-Misc/experience.lua'] = { page = 'Experience', test = 'misc/experience_test.lua' },
	['SaftUI-Misc/durability.lua'] = { page = 'Durability', test = 'misc/durability_position_test.lua' },
	['SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua'] = { page = 'ObjectiveTracker', test = 'misc/objective_tracker_position_test.lua' },
	['SaftUI-Chat/options.lua'] = { page = 'Chat', test = 'chat/theme_test.lua' },
	['SaftUI-Loot/options.lua'] = { page = 'Loot', test = 'loot/theme_test.lua' },
	['SaftUI-Minimap/config.lua'] = { page = 'Minimap', test = 'minimap/theme_test.lua' },
	['SaftUI-Minimap/micromenuoptions.lua'] = { page = 'MicroMenu', test = 'minimap/theme_test.lua' },
	['SaftUI-Tracker/options.lua'] = { page = 'Tracker', test = 'tracker/options_test.lua' },
}

-- Whether a test file's text walks the page: R.check_page(root, 'Page'), a
-- receiver and the page's key as the second argument.
local L = load_test_file('lib/source_lex.lua')

-- The text of the top-level arguments of the call whose '(' is at open (in code
-- with comments blanked), or nil.
local function Args(code, open)
	local args, depth, from = {}, 0, open + 1
	for i = open, #code do
		local c = code:sub(i, i)
		if c == '(' or c == '{' or c == '[' then
			depth = depth + 1
		elseif c == ')' or c == '}' or c == ']' then
			depth = depth - 1
			if depth == 0 then
				args[#args + 1] = code:sub(from, i - 1)
				return args
			end
		elseif c == ',' and depth == 1 then
			args[#args + 1] = code:sub(from, i - 1)
			from = i + 1
		end
	end
end

-- Whether a test file's code walks the page: R.check_page(root, 'Page'), a
-- receiver and the page's key as the second argument, a literal. Comments are
-- blanked by the repo's lexer, so a commented call is not a walk.
local function Walks(source, page)
	local code, mask = L.Lex(source)
	local from = 1
	while true do
		local at, to = mask:find('[%w_]%.check_page%(', from)
		if not at then return false end
		local args = Args(code, to)
		local second = args and args[2] and args[2]:match('^%s*(.-)%s*$')
		if second == "'" .. page .. "'" or second == '"' .. page .. '"' then return true end
		from = to + 1
	end
end

test('the scan reads code, not comments, and a call over several lines', function()
	check(not Walks("-- R.check_page(root, 'Chat')", 'Chat'), 'a commented call is not a walk')
	check(not Walks("--[[ R.check_page(root, 'Chat') ]]", 'Chat'), 'nor a call in a block comment')
	check(Walks("R.check_page(\n\troot,\n\t'Chat'\n)", 'Chat'), 'a call over several lines is')
	check(Walks("R.check_page(st.Config:GetOptionsTable(), 'Chat', { probe = false })", 'Chat'), 'with a call as its first argument')
	check(Walks('R.check_page(root, "Chat")', 'Chat'), 'double quotes')
	check(not Walks('check_page(root, "Chat")', 'Chat'), 'a double-quoted local call with no receiver is not it')
	check(not Walks("local s = \"R.check_page(root, 'Chat')\"", 'Chat'), 'nor a call inside a string')
end)

test('the scan tells a call on the walk helper from a local of the same name', function()
	check(Walks("R.check_page(root, 'Chat')", 'Chat'), 'a call on the helper')
	check(Walks('R.check_page(st.Config:GetOptionsTable(), "Chat", { fresh = true })', 'Chat'), 'double quotes and options')
	check(not Walks("local function check_page(name, tree) end; check_page('Chat', tree)", 'Chat'), "a test's own local is not it")
	check(not Walks("R.check_page(root, 'Chatty')", 'Chat'), 'nor another page whose key starts the same')
	check(not Walks("R.check_page(root, 'Loot')", 'Chat'), 'nor another page')
end)

test('every page with a GetConfigTable is in PAGES, and its test file is there', function()
	local files, _, missing = T.saftui_files()
	eq(#missing, 0, 'every file a TOC names can be read: ' .. table.concat(missing, ', '))
	local found = 0
	for _, path in ipairs(files) do
		local source = read_saftui_source(path)
		if source and source:find('function %w+:GetConfigTable%(') then
			found = found + 1
			check(PAGES[path] ~= nil, path .. ' defines GetConfigTable: add it to PAGES, with the test that walks its resets')
		end
	end
	check(found > 0, 'some page was found')
	for path, entry in pairs(PAGES) do
		local source = read_saftui_source(path)
		check(source ~= nil and source:find('function %w+:GetConfigTable%(') ~= nil,
			path .. " is in PAGES but defines no GetConfigTable (a page that moved or went)")
		check(read_test_source(entry.test) ~= nil, path .. "'s test file " .. entry.test .. ' is not there')
	end
end)

test('every page is walked', function()
	local paths = {}
	for path in pairs(PAGES) do paths[#paths + 1] = path end
	table.sort(paths)
	for _, path in ipairs(paths) do
		local entry = PAGES[path]
		local source = read_test_source(entry.test) or ''
		check(Walks(source, entry.page), ('%s (page %s) is not walked: call R.check_page(root, %q) in %s'):format(path, entry.page, entry.page, entry.test))
	end
end)

------------------------------------------------------------------ the world builds the whole page

-- A walk checks the rows its world builds. A file that defines options and is not loaded by the world
-- is a part of a page nobody walks (the plate pages' Subtext tab was missed that way). So every file
-- the TOCs load that defines options (lib/options_files.lua states the rule) is either a page above, a
-- part of a page (PARTS: the file and the test whose world must load it), or an exception with its
-- reason (OF.EXCEPTIONS); and the world of its test names it.
local OF = load_test_file('lib/options_files.lua')

-- Files that define a part of a page, not a page: the test that walks that page.
local PARTS = {
	['SaftUI-Unitframes/elements/'] = 'unitframes/config_test.lua', -- a folder: every element file
	['SaftUI-Unitframes/config/position.lua'] = 'unitframes/config_test.lua',
	['SaftUI-Unitframes/config/groupoptions.lua'] = 'unitframes/config_test.lua',
	['SaftUI-Unitframes/config/parts.lua'] = 'unitframes/config_test.lua',
	['SaftUI-Unitframes/nameplates/threat.lua'] = 'unitframes/config_test.lua',
	['SaftUI-Unitframes/nameplates/subtext.lua'] = 'unitframes/config_test.lua',
	['SaftUI-Unitframes/nameplates/options.lua'] = 'unitframes/config_test.lua',
	['SaftUI-ActionBars/textoptions.lua'] = 'actionbars/page_test.lua',
	['SaftUI-Bags/categoriestab.lua'] = 'bags/categories_editor_test.lua',
	['SaftUI-Core/Media/states.lua'] = 'core/accent_menu_test.lua', -- the Accent row's menu
}

-- The text of a test world: the test, the helper files it loads (load_test_file, to two levels) and
-- the core shell's loader (load_core_helpers).
local function WorldText(testPath)
	local seen, parts = {}, {}
	local function Add(path, depth)
		if seen[path] then return end
		seen[path] = true
		local source = read_test_source(path)
		if not source then return end
		parts[#parts + 1] = source
		if depth < 3 then
			local _, code = L.Lex(source)
			for helper in source:gmatch("load_test_file%('([^']+)'%)") do Add(helper, depth + 1) end
		end
	end
	Add(testPath, 1)
	parts[#parts + 1] = read_test_source('lib/shell.lua') or ''
	return table.concat(parts, '\n')
end

-- Worlds that load an addon's whole TOC by a helper of their own: the helper call, and the folder it loads.
local WHOLE_TOC = { ['TW.toc_files()'] = 'SaftUI-Tracker/' }

-- Whether a world's text loads path: it names the path, loads every option file under a folder with
-- OF.Files, or calls a helper that loads the addon's whole TOC.
local function Loads(world, path)
	if world:find("'" .. path .. "'", 1, true) then return true end
	for call, prefix in pairs(WHOLE_TOC) do
		if path:sub(1, #prefix) == prefix and world:find(call, 1, true) then return true end
	end
	for prefix in world:gmatch("OF%.Files%('([^']*)'%)") do
		if path:sub(1, #prefix) == prefix then return true end
	end
	return false
end

test('every file that defines options is a page, a part of a page or an exception, and its test world loads it', function()
	local worlds = {}
	local function World(testPath)
		worlds[testPath] = worlds[testPath] or WorldText(testPath)
		return worlds[testPath]
	end
	local files = OF.Files()
	check(#files > 20, 'the rule finds the option files (' .. #files .. ')')
	for _, path in ipairs(files) do
		local test = PAGES[path] and PAGES[path].test or PARTS[path]
		for prefix, partTest in pairs(PARTS) do
			if prefix:sub(-1) == '/' and path:sub(1, #prefix) == prefix then test = partTest end
		end
		if not test then
			check(false, path .. ' defines options (lib/options_files.lua): add it to PAGES, to PARTS with the test that walks its page, or to OF.EXCEPTIONS with a reason')
		else
			check(Loads(World(test), path), ('%s defines options but %s does not load it: the walk would never meet its rows'):format(path, test))
		end
	end
	for path in pairs(OF.EXCEPTIONS) do
		check(read_saftui_source(path) ~= nil, path .. ' is in OF.EXCEPTIONS but is not there')
	end
	for path, test in pairs(PARTS) do
		check(read_test_source(test) ~= nil, path .. "'s test file " .. test .. ' is not there')
		check(not PAGES[path], path .. ' is a page and a part')
		check(path:sub(-1) == '/' or read_saftui_source(path) ~= nil, path .. ' is in PARTS but is not there')
	end
end)

test('the rule that finds option files', function()
	check(OF.Defines('local o = st.Config.generators.toggle(1)'), 'a generator call')
	check(OF.Defines('function UF:GetConfigTable() end'), 'a page')
	check(OF.Defines('saved = UF.SavedIn(unit)'), 'a saved field')
	check(not OF.Defines('-- generators are in Core\nlocal x = "SavedIn"'), 'not a comment or a string')
	check(not OF.Defines('local x = 1'), 'not a plain file')
end)

