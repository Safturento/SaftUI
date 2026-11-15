-- Every /sui page is walked for resets. Each file the game loads that defines
-- a module's GetConfigTable is a page; PAGES names, for each, the page's key in
-- the options tree and the test file that walks it with
-- tests/lib/reset_walk.lua's R.check_page. A page added with no walk fails the
-- first case; a page whose walk was dropped fails the second once STRICT is on.
--
-- Lenient until the last task of "A reset on every setting" (STRICT = false):
-- a page whose test doesn't call R.check_page(root, '<page key>') is printed,
-- not failed. The scan wants the call as written (a receiver, then the key as
-- the second argument): a test's own local check_page is not it.
local T = load_test_file('lib/theme_helpers.lua')

local STRICT = false

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

test('every page is walked (lenient until the last task)', function()
	local paths = {}
	for path in pairs(PAGES) do paths[#paths + 1] = path end
	table.sort(paths)
	local missed = 0
	for _, path in ipairs(paths) do
		local entry = PAGES[path]
		local source = read_test_source(entry.test) or ''
		local walked = Walks(source, entry.page)
		if not walked then
			missed = missed + 1
			if STRICT then
				check(false, ('%s (page %s) is not walked: call check_page(root, %q) in %s'):format(path, entry.page, entry.page, entry.test))
			else
				print(('not yet walked: %s (page %s, in %s)'):format(path, entry.page, entry.test))
			end
		end
	end
	check(STRICT == false or missed == 0, 'every page is walked')
	check(true, ('%d of %d pages not walked yet'):format(missed, #paths))
end)
