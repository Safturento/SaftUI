-- The lexer tests that scan SaftUI's source share (tests/core/color_reads_test.lua):
-- a Lua file's text with its comments blanked (code), and with its comments and
-- the contents of its strings blanked too (mask), and the line a position is on.
-- The one lexer the scans share (core/color_reads_test.lua,
-- core/setfont_scan_test.lua, core/theme_kinds_test.lua,
-- tracker/source_scan_test.lua). Not a test (no _test suffix), so the runner
-- doesn't run it. Load it with
-- `local L = load_test_file('lib/source_lex.lua')`; it makes no globals.
local L = {}

-- text with everything but its newlines turned to spaces.
local function Blank(text) return (text:gsub('[^\n]', ' ')) end

-- source with its comments blanked (code), and with its comments and the
-- contents of its strings blanked (mask). Both are as long as source and keep
-- its newlines, so a position or a line is the same in all three.
function L.Lex(source)
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

-- The line a position in text is on.
function L.LineAt(text, position)
	local _, newlines = text:sub(1, position):gsub('\n', '')
	return newlines + 1
end

return L
