-- Every file a SaftUI TOC lists exists, and so does every Lua or XML file an
-- XML file the TOCs load names. A line left behind by a deleted file would
-- make the game print "couldn't open" at login and skip the rest of that
-- addon's load order silently on some clients.
--
-- Real: every SaftUI-*/ TOC, the XML files they load and the files they name,
-- read as text.
local T = load_test_file('lib/theme_helpers.lua')

local function Trim(text) return (text:gsub('^%s+', ''):gsub('%s+$', '')) end

-- Every line of a TOC that names a file (not a comment, a blank or a
-- `## Field: value` line), as a path from the repo root.
local function Listed(toc)
	local addon = toc:match('^([^/]+)/')
	local paths = {}
	for line in (read_saftui_source(toc) .. '\n'):gmatch('(.-)\r?\n') do
		line = Trim(line)
		if line ~= '' and not line:find('^#') then
			paths[#paths + 1] = addon .. '/' .. line:gsub('\\', '/')
		end
	end
	return paths
end

test('every file a TOC lists exists', function()
	local _, tocs = T.saftui_files()
	check(#tocs > 0, 'the TOCs were found')
	local missing = {}
	for _, toc in ipairs(tocs) do
		for _, path in ipairs(Listed(toc)) do
			if not read_saftui_source(path) then missing[#missing + 1] = path .. ' (from ' .. toc .. ')' end
		end
	end
	eq(table.concat(missing, '; '), '', 'files a TOC lists that are not there')
end)

test('every Lua file the TOCs load, through XML too, exists', function()
	local files, _, unreadable = T.saftui_files()
	eq(table.concat(unreadable, '; '), '', 'XML files that cannot be read')
	local missing = {}
	for _, path in ipairs(files) do
		if not read_saftui_source(path) then missing[#missing + 1] = path end
	end
	eq(table.concat(missing, '; '), '', 'Lua files a TOC or XML names that are not there')
end)

test('taintfix.lua is gone from the Core TOCs', function()
	for _, toc in ipairs({ 'SaftUI-Core/SaftUI-Core_Forever.toc', 'SaftUI-Core/SaftUI-Core_Mainline.toc' }) do
		for _, path in ipairs(Listed(toc)) do
			check(not path:find('taintfix', 1, true), toc .. ' still lists ' .. path)
		end
	end
end)
