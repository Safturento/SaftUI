-- Hover is everything under the mouse (Buttons > Hover, drawn at
-- st.HOVER_TINT times its opacity as a highlight over a fill); Normal is a
-- scroll bar thumb at rest. The scan reads every file the TOCs load: no one
-- reads Buttons > Normal by a literal key but the picker's preview, which
-- draws the thumb at rest, and the thumb itself reads it by its state's key
-- (Widgets/scrollbar.lua). A new highlight that reads Normal fails here.
--
-- Real: the source files and Core's constants.
load_test_file('core/config_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')
local st = SaftUI

-- Files that may name Buttons > Normal, with what they read it for.
local ALLOWED = { ['SaftUI-Core/Config/optionspreview.lua'] = "the Rest tile's thumb" }

test('st.HOVER_TINT is the strength a hover highlight draws Hover at, 0.4 as the micro buttons draw it', function()
	eq(st.HOVER_TINT, 0.4)
end)

test("no file reads Buttons > Normal for a highlight: a literal 'button', 'normal' read is the preview's thumb alone", function()
	local found = {}
	for _, path in ipairs((T.saftui_files())) do
		local source = read_saftui_source(path)
		if source and not ALLOWED[path] then
			local code = L.Lex(source) -- comments blanked, strings kept
			for line in (code .. '\n'):gmatch('(.-)\n') do
				if line:find("['\"]button['\"]%s*,%s*['\"]normal['\"]") then found[#found + 1] = path .. ': ' .. (line:gsub('^%s+', '')) end
			end
		end
	end
	eq(table.concat(found, '\n'), '', 'every reader of Normal')
end)

test('the preview reads Normal for the Rest thumb only', function()
	local source = read_saftui_source('SaftUI-Core/Config/optionspreview.lua')
	local count = 0
	for _ in source:gmatch("Shade%('button', 'normal'") do count = count + 1 end
	eq(count, 1, "one read: the thumb at rest")
end)
