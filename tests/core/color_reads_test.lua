-- The color scan: every SaftUI Lua file the TOCs load is read for a color the
-- profile no longer has, or a read of one that has no default. The rules (each
-- grows as the colors' renaming goes on):
--   A  a retired key (text.purple, text.grey, button.yellow): read as `group.key` or
--      `group['key']`;
--   B  a local bound to colors.text or colors.button, read for a retired key
--      of that group (a binding of either fails rule D itself);
--   C  an st:Color or st:ColorRGBA call with a literal group or key that has
--      no default, or a key given with 'accent';
--   D  a direct read of a role color: `colors.text`, `colors.roles`,
--      `colors.factions`, `colors.loot`, `colors.button`, `Colors().text` and
--      the like, or `theme.accent`. Every Text, Buttons, Roles, Factions, Loot
--      and accent read goes through st:Color or st:ColorRGBA. Groups named for
--      game concepts (class, reaction, power, item quality, status, threat,
--      objectives) keep their own reads;
--   E  a retired wrapper or constant, by its hue name in code (Blue, LinkBlue,
--      OWN_TEXT: the accent is OB.Accent and OB.OWN_STRENGTH; Grey, GreyRGB,
--      DIFF_COLOR: Text > Muted is OB.Muted, and the diff icon is Muted at
--      OB.DIFF_STRENGTH), and the tip line's field `red = true` (it is
--      `danger = true`);
--   F  a Buttons read through st:Color: every Buttons color is drawn at its
--      own strength times its opacity, so it is st:ColorRGBA('button', key,
--      strength) (a read of `button` through st:Color leaves the opacity
--      out).
-- SaftUI-Core/Media/colors.lua, which holds the retired keys' old values and
-- the migration, is exempt from every rule but C (it holds strings of the retired keys today, and from Task 4 the one direct read, rule D's, that the accessor makes: don't remove the exemption as dead). Real: the source files, and
-- Core's defaults (core/config_helpers.lua).
load_test_file('core/config_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')
local st = SaftUI

local EXEMPT = 'SaftUI-Core/Media/colors.lua'

-- Retired keys by group; a task adds its own.
local RETIRED = {
	text = { 'purple', 'blue', 'grey', 'white', 'red', 'orange', 'yellow', 'green', 'cyan' },
	button = { 'yellow', 'blue', 'green', 'grey', 'red' },
}

-- Rule E's identifiers, word-bounded, in code (comments and strings blanked).
local HUE_NAMES = { 'Blue', 'LinkBlue', 'OWN_TEXT', 'Grey', 'GreyRGB', 'DIFF_COLOR' }

-- Rule D: the groups whose every read goes through the accessor.
local DIRECT_GROUPS = { 'text', 'roles', 'factions', 'loot', 'button' }

local function LineText(source, position)
	local from = (source:sub(1, position):match('.*\n()') or 1)
	return (source:match('^[^\n]*', from):gsub('^%s+', ''))
end

-- Each statement of mask (a line split at ';') as { text, finish }: finish is
-- where it ends, so a binding is read for what follows it on its own line too.
local function Statements(mask)
	local out, position = {}, 1
	for line in (mask .. '\n'):gmatch('(.-)\n') do
		local offset = 0
		for statement in (line .. ';'):gmatch('(.-);') do
			offset = offset + #statement + 1
			out[#out + 1] = { text = statement, finish = position + offset - 1 }
		end
		position = position + #line + 1
	end
	return out
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
		local statements = Statements(mask)
		for _, statement in ipairs(statements) do
			local name, expression = statement.text:match('^%s*local%s+([%w_]+)%s*=%s*(.-)%s*$')
			if name then
				local group = expression:match('%f[%w_][Cc]olors%s*%.%s*(%a+)$')
					or expression:match('%f[%w_]Colors%s*%(%s*%)%s*%.%s*(%a+)$')
				if group and RETIRED[group] then bound[#bound + 1] = { name = name, group = group, from = statement.finish } end
			end
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

		-- D. Direct reads of a role color.
		for _, group in ipairs(DIRECT_GROUPS) do
			for _, pattern in ipairs({ 'colors%s*%.%s*' .. group .. '%f[^%w_]', 'Colors%s*%(%s*%)%s*%.%s*' .. group .. '%f[^%w_]' }) do
				local from = 1
				while true do
					local s, e = mask:find(pattern, from)
					if not s then break end
					Fail(found, path, 'D direct read', mask, s, source)
					from = e + 1
				end
			end
			local from = 1
			while true do
				local s, e = code:find('colors%s*%[%s*[\'"]' .. group .. '[\'"]', from)
				if not s then break end
				Fail(found, path, 'D direct read', mask, s, source)
				from = e + 1
			end
		end
		for _, pattern in ipairs({ 'theme%s*%.%s*accent%f[^%w_]', 'Theme%s*%(%s*%)%s*%.%s*accent%f[^%w_]' }) do
			local from = 1
			while true do
				local s, e = mask:find(pattern, from)
				if not s then break end
				Fail(found, path, 'D direct read', mask, s, source)
				from = e + 1
			end
		end

		-- D, aliases: a local bound to the whole colors table (colors, Colors() or
		-- profile.colors), read for a role group; a local bound to the theme
		-- table, read for the accent; and the ['colors'] and rawget forms.
		local whole = {}
		for _, statement in ipairs(statements) do
			local name, expression = statement.text:match('^%s*local%s+([%w_]+)%s*=%s*(.-)%s*$')
			if name then
				if expression:match('%f[%w_][Cc]olors$') or expression:match('%f[%w_]Colors%s*%(%s*%)$') then
					whole[#whole + 1] = { name = name, kind = 'colors', from = statement.finish }
				elseif expression:match('%f[%w_]theme$') or expression:match('%f[%w_]Theme%s*%(%s*%)$') then
					whole[#whole + 1] = { name = name, kind = 'theme', from = statement.finish }
				end
			end
		end
		for _, binding in ipairs(whole) do
			local keys = binding.kind == 'theme' and { 'accent' } or DIRECT_GROUPS
			for _, key in ipairs(keys) do
				local from = binding.from
				while true do
					local s, e = mask:find('%f[%w_]' .. binding.name .. '%s*%.%s*' .. key .. '%f[^%w_]', from)
					if not s then break end
					Fail(found, path, 'D direct read', mask, s, source)
					from = e + 1
				end
				from = binding.from
				while true do
					local s, e = code:find('%f[%w_]' .. binding.name .. '%s*%[%s*[\'"]' .. key .. '[\'"]', from)
					if not s then break end
					Fail(found, path, 'D direct read', mask, s, source)
					from = e + 1
				end
			end
		end
		for _, group in ipairs(DIRECT_GROUPS) do
			for _, pattern in ipairs({
				'%[%s*[\'"]colors[\'"]%s*%]%s*%.%s*' .. group .. '%f[^%w_]',
				'%[%s*[\'"]colors[\'"]%s*%]%s*%[%s*[\'"]' .. group .. '[\'"]%s*%]',
			}) do
				local from = 1
				while true do
					local s, e = code:find(pattern, from)
					if not s then break end
					if mask:sub(s, s) == '[' then Fail(found, path, 'D direct read', mask, s, source) end -- not inside a string
					from = e + 1
				end
			end
			for _, pattern in ipairs({
				'rawget%s*%([^,%)]*[cC]olors%s*,%s*[\'"]' .. group .. '[\'"]',
				'rawget%s*%(%s*[%w_%.%[%]\'" ]*Colors%s*%(%s*%)%s*,%s*[\'"]' .. group .. '[\'"]',
			}) do
				local from = 1
				while true do
					local s, e = code:find(pattern, from)
					if not s then break end
					if mask:sub(s, s + 5) == 'rawget' then Fail(found, path, 'D direct read', mask, s, source) end -- not inside a string
					from = e + 1
				end
			end
		end

		-- F. A Buttons read through st:Color leaves the opacity out.
		local from = 1
		while true do
			local s, e = code:find('st%s*:%s*Color%s*%(%s*[\'"]button[\'"]', from)
			if not s then break end
			if mask:sub(s, s) == 's' then Fail(found, path, 'F button strength', mask, s, source) end -- not inside a string
			from = e + 1
		end

		-- E. Hue names in code.
		for _, name in ipairs(HUE_NAMES) do
			local from = 1
			while true do
				local s, e = mask:find('%f[%w_]' .. name .. '%f[^%w_]', from)
				if not s then break end
				Fail(found, path, 'E hue name', mask, s, source)
				from = e + 1
			end
		end
		-- E. The tip line's old field.
		from = 1
		while true do
			local s, e = mask:find('%f[%w_]red%s*=%s*true%f[^%w_]', from)
			if not s then break end
			Fail(found, path, 'E hue name', mask, s, source)
			from = e + 1
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
	local d = { text = { normal = 1 }, loot = { pass = 1 }, button = { normal = 1, hover = 1 } }
	-- Rule D has its own samples below; the others' samples read `colors.text` freely.
	local function without(src, keep)
		local out = {}
		for _, f in ipairs(Scan('sample.lua', src, d)) do
			if (f:match(': ([A-F]) ') == 'D') == keep then out[#out + 1] = f end
		end
		return Rules(out)
	end
	local function scan(src) return without(src, false) end
	local function scanD(src) return without(src, true) end
	-- A
	eq(scan('local c = st.config.profile.colors.text.purple:GetRGB()'), 'A')
	eq(scan("local c = colors.button['yellow']"), 'A')
	eq(scan("local a = colors.text.normal -- text.purple\nlocal b = 'button.yellow'"), '', 'a comment and a string name a retired key')
	eq(scan('local c = config.text.size'), '', 'an action bar text table is not a color group')
	eq(scan('local c = colors.text.purples'), '', 'a longer name is not the key')
	eq(scan('local c = colors.text.blue:GetRGB()'), 'A')
	eq(scan('local c = colors.button.blue:GetRGB()'), 'A')
	eq(scan("local c = colors.button['green']"), 'A')
	eq(scan('local c = colors.text.green:GetRGB()'), 'A', 'Text > Green is Success now')
	for _, key in ipairs({ 'white', 'red', 'orange', 'yellow', 'cyan' }) do
		eq(scan('local c = colors.text.' .. key .. ':GetRGB()'), 'A', key)
	end
	eq(scan("local c = st.config.profile.colors.text['red']"), 'A')
	eq(scan('local c = colors.button.red:GetRGB()'), 'A', 'Buttons > Red is Buttons > Danger')
	eq(scan("local c = colors.button['red']"), 'A')
	eq(scan('local c = colors.text.reddish'), '', 'a longer name is not the key')
	eq(Rules(Scan('sample.lua', "local c = st:Color('text', 'danger')\nlocal b = st:ColorRGBA('button', 'danger', 0.4)", { text = { danger = 1 }, button = { danger = 1 } })), '', 'the new keys')
	eq(scan('local c = colors.text.bluegreen'), '', 'a longer name is not the key')
	eq(scan('local c = colors.text.grey:GetRGB()'), 'A')
	eq(scan("local c = colors.button['grey']"), 'A')
	eq(scan('local c = colors.text.greyish'), '', 'a longer name is not the key')
	eq(scan('local c = colors.text.muted:GetRGB()'), '', 'the new key')
	-- B
	eq(scan('local textColors = st.config.profile.colors.text\nlocal c = textColors.purple'), 'B')
	eq(scan("local Buttons = Colors().button\nlocal c = Buttons['yellow']"), 'B')
	eq(scan('local textColors = st.config.profile.colors.text\nlocal c = textColors.blue'), 'B')
	eq(scan('local textColors = st.config.profile.colors.text\nlocal c = textColors.grey'), 'B')
	eq(scan("local Buttons = Colors().button\nlocal c = Buttons['grey']"), 'B')
	eq(scan('local textColors = st.config.profile.colors.text\nlocal c = textColors.normal'), '', 'its own rule is D, below')
	eq(scan('local textColors = st.config.profile.colors.text\nlocal c = textColors.red'), 'B', 'its retired key too')
	eq(scan("local Buttons = Colors().button\nlocal c = Buttons['red']"), 'B')
	eq(scan('local textColors = st.config.profile.colors.loot\nlocal c = textColors.purple'), '', 'only text and button')
	-- E
	eq(scan('local r, g, b = OB.Blue()'), 'E')
	eq(scan('local function LinkBlue() end'), 'E')
	eq(scan('label:SetTextColor(unpack(OB.OWN_TEXT))'), 'E')
	eq(scan('local r, g, b = OB.Accent()\nlocal s = OB.OWN_STRENGTH'), '', 'the new names')
	eq(scan("-- OB.Blue and OWN_TEXT\nlocal s = 'LinkBlue'"), '', 'a comment and a string')
	eq(scan('local Blues = 1\nlocal NotBlue = 2'), '', 'a longer name is not the word')
	eq(scan('local r, g, b = OB.Grey()'), 'E')
	eq(scan('local function Grey() return 1 end'), 'E')
	eq(scan('local function GreyRGB() return 1 end'), 'E')
	eq(scan('icon:SetVertexColor(unpack(OB.DIFF_COLOR))'), 'E')
	eq(scan('local r, g, b = OB.Muted()\nlocal s = OB.DIFF_STRENGTH'), '', 'the new names')
	eq(scan("-- OB.Grey and DIFF_COLOR\nlocal s = 'GreyRGB'"), '', 'a comment and a string')
	eq(scan('local DOT_GREY = 1\nlocal Greyed = 2'), '', 'a longer name is not the word')
	eq(scan('local f = { text = x, red = true }'), 'E', 'the tip line field')
	eq(scan('local f = { text = x, danger = true }'), '', 'its new name')
	eq(scan("-- red = true\nlocal s = 'red = true'\nlocal red = 1\nlocal unred = true"), '', 'a comment, a string, a longer or different name')
	-- D
	for _, group in ipairs({ 'text', 'roles', 'factions', 'loot' }) do
		eq(scanD('local c = st.config.profile.colors.' .. group .. '.x'), 'D', group)
		eq(scanD('local c = Colors().' .. group .. '.x'), 'D', 'Colors() ' .. group)
		eq(scanD("local c = st.config.profile.colors['" .. group .. "']"), 'D', group .. ' by a string')
		eq(scanD('local c = colors . ' .. group), 'D', group .. ' with spaces')
	end
	eq(scanD('local c = profile.theme.accent'), 'D', 'the accent')
	eq(scanD('local c = Theme().accent'), 'D', 'the accent through Theme()')
	eq(scanD('local c = defaults.theme.accent'), 'D', 'the shipped accent too')
	eq(scanD("local c = st:Color('accent')\nlocal t = st:Color('text', 'normal')\nlocal l = st:Color('loot', 'pass')"), '', 'the accessor')
	eq(scanD('local c = colors.class.MAGE\nlocal d = colors.threat.bad\nlocal f = colors.objectives.failed'), '', 'game-named groups keep their reads')
	eq(scanD('local c = colors.button.hover:GetRGB()'), 'D', 'Buttons go through the accessor too')
	eq(scanD('local c = Colors().button.normal'), 'D', 'Buttons through Colors()')
	eq(scanD("local c = st.config.profile.colors['button']"), 'D', 'Buttons by a string')
	eq(scanD("local c = st.config.profile.colors.button\nlocal d = c.hover"), 'D', 'a binding of Buttons fails itself')
	eq(scanD('local c = colors.buttons\nlocal d = Colors().buttonsize'), '', 'a longer name is not the group')
	eq(scanD("-- colors.text.normal and theme.accent\nlocal s = 'colors.loot'"), '', 'a comment and a string')
	eq(scanD('local c = config.text.size\nlocal d = self.theme.accents\nlocal e = colors.texture'), '', 'a longer name is not the group')
	eq(scanD('local textColors = st.config.profile.colors.text\nlocal c = textColors.normal'), 'D', 'a binding of text fails itself')
	eq(scanD('local c = colors.text.reddish'), 'D', 'a longer key is still a direct read')
	eq(scanD('local c = colors.texture\nlocal d = Colors().texts'), '', 'a longer name is not the group')
	-- D, aliases of the whole table
	eq(scanD('local c = st.config.profile.colors\nreturn c.text.danger'), 'D', 'an alias of profile.colors')
	eq(scanD('local c = Colors()\nreturn c.text.danger'), 'D', 'an alias of Colors()')
	eq(scanD("local c = Colors()\nreturn c['loot'].pass"), 'D', 'by a string key')
	eq(scanD('local t = st.config.profile.theme\nreturn t.accent'), 'D', 'an alias of the theme')
	eq(scanD('local t = Theme()\nreturn t.accent'), 'D', 'an alias of Theme()')
	eq(scanD("return st.config.profile['colors'].text"), 'D', "the ['colors'] form")
	eq(scanD("return rawget(st.config.profile.colors, 'text')"), 'D', 'rawget on the table')
	eq(scanD('local colors = st.config.profile.colors\nreturn colors.threat.bad, colors.class.MAGE'), '', 'game-named groups through an alias')
	eq(scanD('local c = st.config.profile.colors\nreturn c.button.hover'), 'D', 'Buttons through an alias')
	eq(scanD("local c = Colors()\nreturn c['button'].hover"), 'D', 'Buttons through an alias, by a string')
	-- D, the one-line and bracket forms
	eq(scanD('local c = st.config.profile.colors; return c.text.danger'), 'D', 'an alias read on the same line')
	eq(scanD("local c = Colors(); return c['loot'].pass"), 'D', 'by a string, on the same line')
	eq(scanD('local t = Theme(); return t.accent'), 'D', 'the theme alias on the same line')
	eq(scanD('local c = st.config.profile.colors; return c.threat.bad'), '', 'the same line, a game-named group')
	eq(scanD("local c = 'a; local x = colors'; return c.text"), '', 'a semicolon in a string is no statement')
	eq(scanD("return st.config.profile['colors']['text'].danger"), 'D', "the ['colors']['text'] form")
	eq(scanD("return Colors()['colors']['button']"), 'D', "the ['colors']['button'] form")
	eq(scanD("return st.config.profile['colors'].threat, st.config.profile['colors']['class']"), '', "game-named groups by the ['colors'] forms")
	eq(scanD("return rawget(Colors(), 'roles')"), 'D', 'rawget on Colors()')
	eq(scanD("return rawget(OB.Colors(), 'button')"), 'D', 'rawget on OB.Colors()')
	eq(scanD("return rawget(Colors(), 'class')"), '', 'rawget on a game-named group')
	eq(scanD("-- rawget(Colors(), 'roles') and profile['colors']['text']\nlocal s = \"rawget(Colors(), 'roles')\""), '', 'a comment and a string')
	eq(scanD('local t = st.config.profile.theme\nreturn t.name'), '', 'the theme alias read for something else')
	eq(scanD("-- local c = Colors(); c.text.danger\nlocal s = 'rawget(colors, \"text\")'"), '', 'a comment and a string')
	-- F
	eq(scan("local c = st:Color('button', 'normal')"), 'F', 'a Buttons read through st:Color')
	eq(scan("local r, g, b = st:Color('button', 'hover'):GetRGB()"), 'F')
	eq(scan('local c = st:Color ( "button", key )'), 'F', 'with spaces and the other quotes')
	eq(scan("local r, g, b, a = st:ColorRGBA('button', 'normal', 1)"), '', 'st:ColorRGBA at a strength')
	eq(scan("local c = st:Color('buttons', 'x')"), 'C', 'a longer group is no Buttons read (and has no default)')
	eq(scan("-- st:Color('button', 'danger')\nlocal s = \"st:Color('button', 'danger')\""), '', 'a comment and a string')
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
