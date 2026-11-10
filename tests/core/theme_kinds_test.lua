-- Every draw call names its kind, and nothing offers the old template picker's
-- choices:
--   - a scan of the source of every SaftUI Lua file the game loads (each addon's
--     TOCs, and the XML files they include, read with read_saftui_source):
--     each st:SetTemplate and st:SetBackdrop call passes 4 arguments and each
--     st:SetBackdropIn call 5 (the kind last), unless its theme is the literal
--     'none'; none of them is made another way (self:SetTemplate, a
--     SaftUI-style self:SetBackdrop, st.SetTemplate), which the scan couldn't
--     see; and nothing outside SaftUI-Core/theme.lua reads an old template name
--     (st:ResolveLegacyTemplate). The scanner is checked on a sample first.
--   - the /sui tree built from Core's real config.lua offers no Template,
--     Highlight or Close Button and no old template name, the old picker
--     (generators.template, st.Config:GetFrameTemplates) is gone, and no SaftUI
--     file assigns one of those labels. The module pages, which build only once
--     their frames exist, are walked the same way in their own tests
--     (T.check_no_old_names).
--
-- Real: the source files; Core's Config/config.lua on a real AceDB-3.0
-- (core/config_helpers.lua).
load_test_file('core/config_helpers.lua')
load_test_file('core/options_walk.lua')
local T = load_test_file('lib/theme_helpers.lua')
local st = SaftUI

------------------------------------------------------------------ the scanner

-- text with everything but its newlines turned to spaces.
local function Blank(text) return (text:gsub('[^\n]', ' ')) end

-- source with its comments blanked (code), and with its comments and the
-- contents of its strings blanked (mask). Both are as long as source and keep
-- its newlines, so a position or a line is the same in all three.
local function Lex(source)
	local code, mask = {}, {}
	local function add(c, m)
		code[#code + 1], mask[#mask + 1] = c, m or c
	end
	local i, n = 1, #source
	while i <= n do
		local c = source:sub(i, i)
		local long = source:match('^%[(=*)%[', i)
		if source:sub(i, i + 1) == '--' then
			local level = source:match('^%[(=*)%[', i + 2)
			local stop
			if level then
				local _, e = source:find(']' .. level .. ']', i + 2, true)
				stop = e or n
			else
				stop = (source:find('\n', i, true) or (n + 1)) - 1
			end
			add(Blank(source:sub(i, stop)))
			i = stop + 1
		elseif long then
			local open = #long + 2
			local _, e = source:find(']' .. long .. ']', i + open, true)
			e = e or n
			add(source:sub(i, e),
				source:sub(i, i + open - 1) .. Blank(source:sub(i + open, e - open)) .. source:sub(e - open + 1, e))
			i = e + 1
		elseif c == '"' or c == "'" then
			local j = i + 1
			while j <= n do
				local d = source:sub(j, j)
				if d == '\\' then
					j = j + 2
				elseif d == c or d == '\n' then
					break
				else
					j = j + 1
				end
			end
			add(source:sub(i, j), c .. Blank(source:sub(i + 1, j - 1)) .. source:sub(j, j))
			i = j + 1
		else
			local j = source:find('[%-%[\'"]', i + 1) or (n + 1)
			add(source:sub(i, j - 1))
			i = j
		end
	end
	return table.concat(code), table.concat(mask)
end

local function LineAt(text, position)
	local _, newlines = text:sub(1, position):gsub('\n', '')
	return newlines + 1
end

local function Trim(text) return (text:gsub('^%s+', ''):gsub('%s+$', '')) end

-- The arguments of the call whose '(' is at open: their source text, trimmed,
-- split at the commas that aren't inside brackets or strings.
local function Arguments(code, mask, open)
	local args, depth, start = {}, 0, open + 1
	for i = open, #mask do
		local c = mask:sub(i, i)
		if c == '(' or c == '{' or c == '[' then
			depth = depth + 1
		elseif c == ')' or c == '}' or c == ']' then
			depth = depth - 1
			if depth == 0 then
				local last = Trim(code:sub(start, i - 1))
				if last ~= '' or #args > 0 then args[#args + 1] = last end
				return args
			end
		elseif c == ',' and depth == 1 then
			args[#args + 1] = Trim(code:sub(start, i - 1))
			start = i + 1
		end
	end
	return args
end

-- The draw calls, the argument count each needs (the kind is the last), and
-- which argument is the theme.
local DRAWS = {
	{ name = 'SetTemplate', count = 4, theme = 2 },
	{ name = 'SetBackdrop', count = 4, theme = 2 },
	{ name = 'SetBackdropIn', count = 5, theme = 3 },
}

local function IsNone(arg) return arg == "'none'" or arg == '"none"' end

-- Scans one file's source (path names it in what's found). Returns the draw
-- calls it makes in the st: form, and the problems, in line order: a call
-- without its kind, a draw made another way, and an old template name read
-- outside theme.lua.
local function Scan(path, source)
	local code, mask = Lex(source)
	local calls, found = {}, {}
	local function problem(position, text)
		found[#found + 1] = { line = LineAt(mask, position), text = text }
	end
	-- Positions of the names the st: calls and definitions account for.
	local accounted = {}

	for _, rule in ipairs(DRAWS) do
		local name = rule.name
		local from = 1
		while true do
			local s, e = mask:find('st:' .. name .. '%s*%(', from)
			if not s then break end
			from = e + 1
			local before = mask:sub(s - 1, s - 1)
			if not before:find('[%w_%.:]') then
				accounted[s + 3] = true
				local lineStart = mask:sub(1, s - 1):match('.*\n()') or 1
				if not mask:sub(lineStart, s - 1):find('function%s+$') then
					local args = Arguments(code, mask, e)
					calls[#calls + 1] = { name = name, args = args }
					if #args ~= rule.count and not IsNone(args[rule.theme]) then
						problem(s, ('st:%s with %d arguments: it needs %d, the kind last (%s)'):format(
							name, #args, rule.count, table.concat(args, ', ')))
					end
				end
			end
		end
	end

	-- st:SetTemplate and st:SetBackdropIn are SaftUI's alone: any other use of
	-- their names is a draw the scan can't check.
	for _, name in ipairs({ 'SetTemplate', 'SetBackdropIn' }) do
		local from = 1
		while true do
			local s, e = mask:find('%f[%w_]' .. name .. '%f[^%w_]', from)
			if not s then break end
			from = e + 1
			if not accounted[s] then
				problem(s, name .. ' used other than as st:' .. name .. '(...)')
			end
		end
	end

	-- Blizzard's frame:SetBackdrop(backdropInfo) takes one argument; SaftUI's
	-- takes the frame, Theme, Background and kind.
	local from = 1
	while true do
		local s, e = mask:find('[%.:]SetBackdrop%s*%(', from)
		if not s then break end
		from = e + 1
		if not accounted[s + 1] then
			local args = Arguments(code, mask, e)
			if mask:sub(s, s) == '.' or #args > 1 then
				problem(s, 'SaftUI\'s SetBackdrop called other than as st:SetBackdrop(...)')
			end
		end
	end

	if path ~= 'SaftUI-Core/theme.lua' then
		local s = mask:find('%f[%w_]ResolveLegacyTemplate%f[^%w_]')
		if s then problem(s, 'reads an old template name (st:ResolveLegacyTemplate) outside theme.lua') end
	end

	table.sort(found, function(a, b)
		if a.line ~= b.line then return a.line < b.line end
		return a.text < b.text
	end)
	local problems = {}
	for i, p in ipairs(found) do problems[i] = ('%s:%d: %s'):format(path, p.line, p.text) end
	return calls, problems
end

------------------------------------------------------------------ the files

-- SaftUI's addons. A new addon goes here.
local ADDONS = {
	'SaftUI-Core', 'SaftUI-ActionBars', 'SaftUI-Bags', 'SaftUI-Chat',
	'SaftUI-Loot', 'SaftUI-Minimap', 'SaftUI-Misc', 'SaftUI-Unitframes',
}
-- The TOC names the game reads: <addon>.toc and the per-client ones.
local TOC_SUFFIXES = { '', '_Mainline', '_Forever', '_Classic', '_Vanilla', '_TBC', '_Wrath', '_Cata', '_Mists' }

-- Every SaftUI Lua file the game loads, by path from the repo root, in load
-- order and once each; the TOCs read; and the files a TOC or XML names that
-- can't be read. Third-party libraries (an addon's Libraries folder) are left
-- out: they aren't SaftUI's.
local function LoadedFiles()
	local files, seen, tocs, missing = {}, {}, {}, {}
	local function add(path)
		if not seen[path] then
			seen[path] = true
			files[#files + 1] = path
		end
	end
	local function entry(dir, name, from)
		name = Trim(name):gsub('\\', '/')
		local path = dir .. '/' .. name
		if path:find('^SaftUI%-[^/]+/Libraries/') then return end
		if path:find('%.lua$') then
			add(path)
		elseif path:find('%.xml$') then
			local xml = read_saftui_source(path)
			if not xml then
				missing[#missing + 1] = path .. ' (from ' .. from .. ')'
				return
			end
			xml = xml:gsub('<!%-%-.-%-%->', '')
			local xmlDir = path:match('^(.*)/[^/]*$')
			for _, file in xml:gmatch('<(%a+)%s+file%s*=%s*"([^"]+)"') do
				entry(xmlDir, file, path)
			end
		end
	end
	for _, addon in ipairs(ADDONS) do
		for _, suffix in ipairs(TOC_SUFFIXES) do
			local toc = addon .. '/' .. addon .. suffix .. '.toc'
			local text = read_saftui_source(toc)
			if text then
				tocs[#tocs + 1] = toc
				for line in (text .. '\n'):gmatch('(.-)\r?\n') do
					if Trim(line) ~= '' and not line:find('^%s*#') then
						entry(addon, line, toc)
					end
				end
			end
		end
	end
	return files, tocs, missing
end

------------------------------------------------------------------ tests

test('the scanner: argument counts, the none exemption, definitions, comments, strings and other forms', function()
	local SAMPLE = table.concat({
		"function st:SetTemplate(frame, theme, background, kind) end",          -- 1 a definition
		"st:SetTemplate(f, 'theme', 'solid', 'panel')",                          -- 2
		"st:SetTemplate(f, 'thick')",                                            -- 3 no kind
		"st:SetBackdrop(f, 'none')",                                             -- 4 none needs none
		"st:SetBackdrop(f, a(b, c), { x = 1, y = { 2, 3 } }, 'bar')",            -- 5 brackets
		"st:SetBackdropIn(t, f, 'theme', 'theme')",                              -- 6 no kind
		"-- st:SetTemplate(f, 'thick')",                                         -- 7 a comment
		"local s = \"st:SetTemplate(f, 'thick')\"",                              -- 8 a string
		"st:SetBackdrop(f,",                                                     -- 9 over lines
		"	'theme', -- a comment, with a comma",                                -- 10
		"	'solid', 'small')",                                                  -- 11
		"self:SetTemplate(f, 'theme', 'theme', 'small')",                        -- 12 not st:
		"frame:SetBackdrop({ bgFile = x, insets = { left = 1, right = 1 } })",   -- 13 Blizzard's
		"frame:SetBackdrop(f, 'theme', 'theme', 'small')",                       -- 14 SaftUI's, not st:
		"--[[ st:SetTemplate(f)",                                                -- 15 a block comment
		"]] st:SetBackdropIn(t, f, 'none')",                                     -- 16
		"x = st:ResolveLegacyTemplate('thin')",                                  -- 17
		"st:SetTemplate(f, \"a, b\", 'c)', 'small')",                            -- 18 commas in strings
		"local draw = st.SetBackdropIn",                                         -- 19 an alias
	}, '\n')
	local calls, problems = Scan('sample.lua', SAMPLE)
	eq(#calls, 8, 'the st: calls outside comments and strings, definitions aside')
	eq(table.concat(problems, '\n'), table.concat({
		"sample.lua:3: st:SetTemplate with 2 arguments: it needs 4, the kind last (f, 'thick')",
		"sample.lua:6: st:SetBackdropIn with 4 arguments: it needs 5, the kind last (t, f, 'theme', 'theme')",
		'sample.lua:12: SetTemplate used other than as st:SetTemplate(...)',
		"sample.lua:14: SaftUI's SetBackdrop called other than as st:SetBackdrop(...)",
		'sample.lua:17: reads an old template name (st:ResolveLegacyTemplate) outside theme.lua',
		'sample.lua:19: SetBackdropIn used other than as st:SetBackdropIn(...)',
	}, '\n'), 'what the scan finds in the sample')
	local _, ok = Scan('SaftUI-Core/theme.lua', "local look = st:ResolveLegacyTemplate(name)")
	eq(#ok, 0, 'theme.lua may read the old names')
end)

test('the scan reads every SaftUI Lua file through the TOCs', function()
	local files, tocs, missing = LoadedFiles()
	eq(table.concat(missing, ', '), '', 'every XML a TOC or XML names can be read')
	eq(#tocs, 10, 'the TOCs: Core and the unit frames have one per client, the rest one: ' .. table.concat(tocs, ', '))
	for _, addon in ipairs(ADDONS) do
		local any = false
		for _, path in ipairs(files) do
			if path:find(addon .. '/', 1, true) == 1 then any = true end
		end
		check(any, addon .. ' has files')
	end
	local listed = {}
	for _, path in ipairs(files) do listed[path] = true end
	for _, path in ipairs({
		'SaftUI-Core/theme.lua', 'SaftUI-Core/panels.lua', 'SaftUI-Core/Widgets/radiogroup.lua',
		'SaftUI-Core/EditMode/mover.lua', 'SaftUI-Core/Utilities/utilities.lua',
		'SaftUI-Misc/Skinning/Blizzard_BuffFrame.lua', 'SaftUI-Misc/Skinning/characterframe/gems.lua',
		'SaftUI-Unitframes/elements/auras.lua', 'SaftUI-Unitframes/config/units/player.lua',
		'SaftUI-Bags/containers/warbandbank.lua', 'SaftUI-Loot/Feed/feed.lua', 'SaftUI-Minimap/microbuttons.lua',
	}) do
		check(listed[path], path .. ' is read (a TOC, a load.xml, or an XML one includes)')
	end
	for _, path in ipairs(files) do
		check(not path:find('/Libraries/'), path .. " is a library's, not SaftUI's")
	end
	check(#files > 140, 'every file, not a few: ' .. #files)
end)

test('every draw call passes a kind', function()
	local files = LoadedFiles()
	local all, total = {}, 0
	for _, path in ipairs(files) do
		local source, err = read_saftui_source(path)
		if check(source ~= nil, path .. ' can be read: ' .. tostring(err)) then
			local calls, problems = Scan(path, source)
			total = total + #calls
			for _, p in ipairs(problems) do all[#all + 1] = p end
		end
	end
	eq(table.concat(all, '\n'), '', 'every st:SetTemplate, st:SetBackdrop and st:SetBackdropIn names its kind')
	check(total > 60, 'the scan found the draw calls: ' .. total)
end)

-- Labels the old picker showed, assigned anywhere in SaftUI's source (a name
-- or a select's value).
local OLD_LABELS = { 'Template', 'Highlight', 'Close Button', 'ThickTransparent', 'ThinTransparent' }

test('no option anywhere offers Template, Highlight or Close Button', function()
	local root = st.Config:GetOptionsTable()
	check(root.Fonts and root.Fonts.args.theme and root.profile, 'the tree has Global Settings, its Theme tab and the profiles')
	T.check_no_old_names({ type = 'group', args = root }, '/sui')

	eq(st.Config.generators.template, nil, 'the Template dropdown builder is gone')
	eq(st.Config.GetFrameTemplates, nil, 'and the old names it listed')

	-- The module pages build only once their frames exist; their own tests walk
	-- them. Their source, and every other file's, assigns none of the labels.
	local found = {}
	for _, path in ipairs((LoadedFiles())) do
		local source = read_saftui_source(path)
		if source then
			local code = Lex(source)
			for _, label in ipairs(OLD_LABELS) do
				for _, quote in ipairs({ "'", '"' }) do
					local s = code:find('[^=~<>]=%s*' .. quote .. label .. quote)
					if s then found[#found + 1] = path .. ':' .. LineAt(code, s) .. ': ' .. label end
				end
			end
			local s = code:find('[%.:]template%s*%(')
			if s then found[#found + 1] = path .. ':' .. LineAt(code, s) .. ': a template(...) builder call' end
		end
	end
	eq(table.concat(found, '\n'), '', 'no SaftUI file offers an old label or builds a Template dropdown')
end)
