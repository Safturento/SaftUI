-- The color scan: every SaftUI Lua file the TOCs load is read for a color the
-- profile no longer has, or a read of one that has no default. The rules (each
-- grows as the colors' renaming goes on):
--   A  a retired key (text.purple, button.yellow): read as `group.key` or
--      `group['key']`;
--   B  a local bound to colors.text or colors.button, read for a retired key
--      of that group;
--   C  an st:Color or st:ColorRGBA call with a literal group or key that has
--      no default, or a key given with 'accent'.
-- SaftUI-Core/Media/colors.lua, which holds the retired keys' old values and
-- the migration, is exempt from every rule but C. Real: the source files, and
-- Core's defaults (core/config_helpers.lua).
load_test_file('core/config_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')
local st = SaftUI

local EXEMPT = 'SaftUI-Core/Media/colors.lua'

-- Retired keys by group; a task adds its own.
local RETIRED = {
	text = { 'purple' },
	button = { 'yellow' },
}

local function LineText(source, position)
	local from = (source:sub(1, position):match('.*\n()') or 1)
	return (source:match('^[^\n]*', from):gsub('^%s+', ''))
end

local function Fail(found, path, rule, mask, position, source)
	found[#found + 1] = ('%s:%d: %s: %s'):format(path, L.LineAt(mask, position), rule, LineText(source, position))
end

-- Every failure in one file's source, as 'path:line: rule: the line'.
-- defaults is the table the literal keys are checked against.
local function Scan(path, source, defaults)
	local found = {}
	local code, mask = L.Lex(source)
	local exempt = path == EXEMPT

	if not exempt then
		-- A. Retired keys.
		for group, keys in pairs(RETIRED) do
			for _, key in ipairs(keys) do
				local from = 1
				while true do
					local s, e = mask:find('%f[%w_]' .. group .. '%s*%.%s*' .. key .. '%f[^%w_]', from)
					if not s then break end
					Fail(found, path, 'A retired key', mask, s, source)
					from = e + 1
				end
				from = 1
				while true do
					local s, e = code:find('%f[%w_]' .. group .. '%s*%[%s*([\'"])' .. key .. '%1%s*%]', from)
					if not s then break end
					Fail(found, path, 'A retired key', mask, s, source)
					from = e + 1
				end
			end
		end

		-- B. A local bound to a group, read for a retired key of it.
		local bound = {}
		local position = 1
		for line in (mask .. '\n'):gmatch('(.-)\n') do
			local name, expression = line:match('^%s*local%s+([%w_]+)%s*=%s*(.-)%s*;?%s*$')
			if name then
				local group = expression:match('%f[%w_][Cc]olors%s*%.%s*(%a+)$')
					or expression:match('%f[%w_]Colors%s*%(%s*%)%s*%.%s*(%a+)$')
				if group and RETIRED[group] then bound[#bound + 1] = { name = name, group = group, from = position + #line } end
			end
			position = position + #line + 1
		end
		for _, binding in ipairs(bound) do
			for _, key in ipairs(RETIRED[binding.group]) do
				local from = binding.from
				while true do
					local s, e = mask:find('%f[%w_]' .. binding.name .. '%s*%.%s*' .. key .. '%f[^%w_]', from)
					if not s then break end
					Fail(found, path, 'B group alias', mask, s, source)
					from = e + 1
				end
				from = binding.from
				while true do
					local s, e = code:find('%f[%w_]' .. binding.name .. '%s*%[%s*([\'"])' .. key .. '%1%s*%]', from)
					if not s then break end
					Fail(found, path, 'B group alias', mask, s, source)
					from = e + 1
				end
			end
		end
	end

	-- C. Literal keys.
	local calls = {}
	for _, name in ipairs({ 'Color', 'ColorRGBA' }) do
		local from = 1
		while true do
			local s, e = mask:find('%f[%w_]st%s*:%s*' .. name .. '%s*%(', from)
			if not s then break end
			calls[#calls + 1] = { s = s, e = e }
			from = e + 1
		end
	end
	for _, call in ipairs(calls) do
		local s, e = call.s, call.e
		local group, rest = code:match('^%s*([\'"])([^\'"]*)%1(.*)', e + 1)
		if group then
			local name = code:match('^%s*[\'"]([^\'"]*)[\'"]', e + 1)
			local after = code:match('^%s*[\'"][^\'"]*[\'"](.*)', e + 1)
			local bad
			if name == 'accent' then
				local second = after:match('^%s*,%s*([^,%)%s][^,%)]*)')
				if second and second ~= 'nil' then bad = true end
			elseif type(defaults[name]) ~= 'table' then
				bad = true
			else
				local literal = after:match('^%s*,%s*[\'"]([^\'"]*)[\'"]')
				if literal and defaults[name][literal] == nil then bad = true end
			end
			if bad then Fail(found, path, 'C literal key', mask, s, source) end
		end
	end
	return found
end

local function Rules(found)
	local out = {}
	for _, f in ipairs(found) do out[#out + 1] = f:match(': ([A-F]) ') end
	return table.concat(out, ',')
end

test('the rules, on samples: each fails what it names and passes the rest', function()
	local d = { text = { normal = 1 }, loot = { pass = 1 } }
	local function scan(src) return Rules(Scan('sample.lua', src, d)) end
	-- A
	eq(scan('local c = st.config.profile.colors.text.purple:GetRGB()'), 'A')
	eq(scan("local c = colors.button['yellow']"), 'A')
	eq(scan("local a = colors.text.normal -- text.purple\nlocal b = 'button.yellow'"), '', 'a comment and a string name a retired key')
	eq(scan('local c = config.text.size'), '', 'an action bar text table is not a color group')
	eq(scan('local c = colors.text.purples'), '', 'a longer name is not the key')
	-- B
	eq(scan('local textColors = st.config.profile.colors.text\nlocal c = textColors.purple'), 'B')
	eq(scan("local Buttons = Colors().button\nlocal c = Buttons['yellow']"), 'B')
	eq(scan('local textColors = st.config.profile.colors.text\nlocal c = textColors.normal'), '')
	eq(scan('local textColors = st.config.profile.colors.loot\nlocal c = textColors.purple'), '', 'only text and button')
	-- C
	eq(scan("local c = st:Color('text', 'normal')"), '')
	eq(scan("local c = st:Color('text', 'normal2')"), 'C')
	eq(scan("local c = st:ColorRGBA('hues', 'x', 0.5)"), 'C')
	eq(scan("local c = st:Color('accent')"), '')
	eq(scan("local c = st:Color('accent', nil)"), '')
	eq(scan("local c = st:Color('accent', 'x')"), 'C')
	eq(scan('local c = st:Color(group, key)'), '', 'a variable is not a literal')
	eq(scan("local c = st:Color('loot', key)"), '', 'a variable key is not a literal')
	eq(scan("-- st:Color('hues', 'x')\nlocal s = \"st:Color('hues', 'x')\""), '', 'a comment and a string')
end)

test('the scan reads every file the TOCs load, colors.lua among them', function()
	local files = T.saftui_files()
	check(#files > 200, 'more than 200 files')
	local have = {}
	for _, path in ipairs(files) do have[path] = true end
	check(have['SaftUI-Tracker/rows.lua'], 'the tracker')
	check(have[EXEMPT], 'colors.lua')
end)

test('no SaftUI file reads a retired color key or a literal key with no default', function()
	local found = {}
	for _, path in ipairs((T.saftui_files())) do
		local source = read_saftui_source(path)
		if source then
			for _, failure in ipairs(Scan(path, source, st.defaults.colors)) do found[#found + 1] = failure end
		end
	end
	eq(table.concat(found, '\n'), '', 'every failure, as path:line: rule: the line')
end)
