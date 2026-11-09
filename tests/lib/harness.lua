--[[
	The test API and the loader. runner.py runs this file in each test file's
	fresh Lua state, with REPO_ROOT and TESTS_DIR set, and calls the function
	it returns to run that test file. How to use the API is in
	.agents/testing.md. It's all globals:

	  test(name, fn)                 registers a case. Cases run in order once the file has loaded.
	  check(cond, message)           records a pass, or a failure with message. Returns cond as a boolean.
	  eq(actual, expected, message)  check(actual == expected), failing with "expected <e>, got <a>".
	  load_saftui(path)              runs a SaftUI file, from the repo root, the way WoW does.
	  load_test_file(path)           runs a helper or fixture file, from tests/.
	  addon_namespace(addon)         the namespace table load_saftui hands that addon's files.
	  reset_world()                  rebuilds the WoW stubs and the core shell.
	  take_errors()                  the errors reported to the game's error handler so far in this case.
	  report_error(message)          what the stubbed error handler calls.
	  REPO_ROOT, TESTS_DIR           absolute paths, without a trailing slash.
]]

local REPO_ROOT, TESTS_DIR = REPO_ROOT, TESTS_DIR

-- Keep our own references, so a test or a SaftUI file replacing a global
-- can't break the harness.
local io, loadstring, xpcall, error, type, tostring, select, ipairs, pairs =
	io, loadstring, xpcall, error, type, tostring, select, ipairs, pairs
local traceback, getinfo = debug.traceback, debug.getinfo
local format, concat = string.format, table.concat

-- The WoW stubs and the core shell, from tests/, in load order. Every test
-- file starts in this world, and reset_world rebuilds it.
local WORLD = { 'wow/lua.lua', 'wow/game.lua', 'wow/widgets.lua', 'wow/blizzard.lua', 'lib/shell.lua' }

------------------------------------------------------------------ loading

-- A file's source as WoW reads it. Some working copies have CRLF line
-- endings, which Lua 5.1 would keep inside long strings, so they become LF.
local function read_source(path)
	local file, err = io.open(path, 'rb')
	if not file then return nil, err end
	local source = file:read('*a')
	file:close()
	return (source:gsub('\r\n', '\n'))
end

-- Compiles the file at path (absolute). name is how errors and tracebacks name
-- it. A missing file errors at the caller's stack level; a syntax error
-- carries its own file and line.
local function compile(path, name, level)
	local source, err = read_source(path)
	if not source then
		error(format("can't read %s (%s)", name, tostring(err)), level + 1)
	end
	local chunk, syntax_error = loadstring(source, '@' .. name)
	if not chunk then error(syntax_error, 0) end
	return chunk
end

local function check_relative_path(path, fn, level)
	if type(path) ~= 'string' or path:find('^/') or path:find('%.%.') then
		error(format('%s needs a relative path without "..", got %s', fn, tostring(path)), level + 1)
	end
end

local namespaces = {} -- addon folder name -> the table its files get as the second ...

function addon_namespace(addon)
	local ns = namespaces[addon]
	if not ns then
		ns = {}
		namespaces[addon] = ns
	end
	return ns
end

-- Runs a SaftUI file by its path from the repo root, e.g.
-- 'SaftUI-Core/EditMode/grid.lua', and returns what it returns. Like WoW, it
-- passes the file the addon's folder name and that addon's namespace table as
-- its `...`, the same table for every file of the addon.
function load_saftui(path, ...)
	if select('#', ...) > 0 then
		error('load_saftui takes one path: the addon name and namespace come from the path, as in WoW', 2)
	end
	check_relative_path(path, 'load_saftui', 2)
	local addon = path:match('^(SaftUI%-[^/]+)/')
	if not addon then
		error(format('load_saftui loads files from the SaftUI-* addon folders, not %s', path), 2)
	end
	return compile(REPO_ROOT .. '/' .. path, path, 2)(addon, addon_namespace(addon))
end

-- Runs a helper or fixture file by its path from tests/, e.g.
-- 'misc/fixtures/restedxp_world.lua', and returns what it returns.
function load_test_file(path)
	check_relative_path(path, 'load_test_file', 2)
	return compile(TESTS_DIR .. '/' .. path, 'tests/' .. path, 2)()
end

------------------------------------------------------------------ results

local cases, case_names = {}, {}
local running_cases = false
-- The record that checks, prints and reported errors go to: the case running
-- now, or the file's own while it loads.
local current

local function new_record(name)
	return { name = name, checks = 0, problems = {}, output = {}, reported = {} }
end

function test(name, fn)
	if type(name) ~= 'string' or type(fn) ~= 'function' then
		error('usage: test(name, function() ... end)', 2)
	end
	if running_cases then
		error('test() goes at the top level of a test file, not inside a case', 2)
	end
	if case_names[name] then
		error(format('there is already a test named %q', name), 2)
	end
	case_names[name] = true
	cases[#cases + 1] = { name = name, fn = fn }
end

-- Counts a check in the running case. depth is the stack level, counted from
-- here, of the test code that called check or eq.
local function record(passed, message, depth)
	if not running_cases then
		error('check() and eq() only work inside a test() case', depth)
	end
	current.checks = current.checks + 1
	if not passed then
		local info = getinfo(depth, 'Sl')
		local where = info and format('%s:%d: ', info.short_src, info.currentline) or ''
		current.problems[#current.problems + 1] = where .. (message ~= nil and tostring(message) or 'check failed')
	end
	return passed
end

function check(cond, message)
	return record(cond and true or false, message, 3)
end

local function show(value)
	if type(value) == 'string' then return format('%q', value) end
	return tostring(value)
end

function eq(actual, expected, message)
	local passed = actual == expected
	local text
	if not passed then
		local e, a = show(expected), show(actual)
		-- tostring rounds numbers to 14 digits, so show more when that hides the difference
		if e == a and type(expected) == 'number' and type(actual) == 'number' then
			e, a = format('%.17g', expected), format('%.17g', actual)
		end
		text = format('%sexpected %s, got %s', message ~= nil and (tostring(message) .. ': ') or '', e, a)
	end
	return record(passed, text, 3)
end

-- WoW's print writes to chat. Here it goes to the running case's output,
-- which the report shows when the case fails (or with tests/run -v).
function print(...)
	local parts = {}
	for i = 1, select('#', ...) do
		parts[i] = tostring((select(i, ...)))
	end
	current.output[#current.output + 1] = concat(parts, ' ')
end

-- The game shows an error passed to its error handler (geterrorhandler) and
-- carries on, so the stubbed handler records it here and the code goes on as
-- in game. A case fails if errors are left over at its end, so a test that
-- expects one takes it with take_errors().
function report_error(message)
	current.reported[#current.reported + 1] = { message = tostring(message), trace = traceback(tostring(message), 3) }
end

function take_errors()
	local messages = {}
	for i, reported in ipairs(current.reported) do
		messages[i] = reported.message
	end
	current.reported = {}
	return messages
end

------------------------------------------------------------------ the world

local base_globals -- every global that exists once this file has loaded

-- Rebuilds the stubbed WoW world and the core shell in this Lua state: every
-- global made since the harness loaded (by stubs, SaftUI files or tests) is
-- removed, namespaces start empty, and the stub files and shell load again.
-- Values the test file holds in locals survive. Load SaftUI files again after
-- calling it.
function reset_world()
	for name in pairs(_G) do
		if not base_globals[name] then
			_G[name] = nil
		end
	end
	namespaces = {}
	for _, file in ipairs(WORLD) do
		load_test_file(file)
	end
end

------------------------------------------------------------------ running a file

local function on_error(err)
	return traceback(tostring(err), 2)
end

-- A traceback without the frames that only add noise: the harness's own,
-- and the error and xpcall calls. The first line, the error message itself,
-- is always kept.
local function trim(trace)
	local lines = {}
	for line in (trace .. '\n'):gmatch('(.-)\n') do
		if #lines == 0 or not (line:find('tests/lib/harness.lua', 1, true) or line:find("in function 'xpcall'", 1, true)
				or line:find("in function 'error'", 1, true)) then
			lines[#lines + 1] = line
		end
	end
	if lines[#lines] == 'stack traceback:' then lines[#lines] = nil end
	return concat(lines, '\n')
end

-- Moves errors still reported at the end of a load or case into its problems.
local function flush_reported(rec)
	for _, reported in ipairs(rec.reported) do
		rec.problems[#rec.problems + 1] = 'error reported to the error handler (the game would show it):\n' .. trim(reported.trace)
	end
	rec.reported = {}
end

-- Loads the test file at path (shown in reports as shown) in a fresh world,
-- runs its cases, and returns the result for runner.py.
local function run_file(path, shown)
	local result = { path = shown, ok = false, checks = 0, failures = 0, cases = {} }

	current = new_record('(loading)')
	local loaded, err = xpcall(function()
		reset_world()
		compile(path, shown, 1)()
	end, on_error)
	local load = current
	if not loaded then
		load.problems[#load.problems + 1] = 'error while loading the file:\n' .. trim(err)
	end
	flush_reported(load)
	if loaded and #cases == 0 then
		load.problems[#load.problems + 1] = 'no checks ran: the file registers no test() cases'
	end
	result.problems, result.output = load.problems, load.output
	result.failures = #load.problems

	if loaded then
		running_cases = true
		for _, case in ipairs(cases) do
			current = new_record(case.name)
			local ok, case_err = xpcall(case.fn, on_error)
			if not ok then
				current.problems[#current.problems + 1] = 'error: ' .. trim(case_err)
			end
			flush_reported(current)
			if ok and current.checks == 0 then
				current.problems[#current.problems + 1] = 'no checks ran in this case'
			end
			result.checks = result.checks + current.checks
			result.failures = result.failures + #current.problems
			result.cases[#result.cases + 1] = {
				name = case.name, ok = #current.problems == 0, checks = current.checks,
				problems = current.problems, output = current.output,
			}
		end
		running_cases = false
	end

	if result.failures == 0 and result.checks == 0 then
		result.problems[#result.problems + 1] = 'no checks ran'
		result.failures = 1
	end
	result.ok = result.failures == 0
	return result
end

-- What WoW's Lua doesn't have, so neither test files nor SaftUI files can use
-- it: lupa's bridge to Python, files and the process (io, os, whose os.exit
-- would end the run before its report and exit status), and loading code
-- from disk around load_saftui (require, dofile, loadfile, package, module).
-- The harness keeps its own io above (a local, hence clearing through _G). If
-- SaftUI code needs WoW's time or date, add them to tests/wow/lua.lua.
for _, name in ipairs({ 'python', 'io', 'os', 'require', 'dofile', 'loadfile', 'package', 'module' }) do
	_G[name] = nil
end

base_globals = {}
for name in pairs(_G) do
	base_globals[name] = true
end

return run_file
