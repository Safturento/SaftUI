-- Buttons > Hover is the highlight of SaftUI's buttons, check boxes and micro
-- menu bar items under the mouse (drawn at st.HOVER_TINT times its opacity),
-- beside the readers that always read it; Normal is a scroll bar thumb at rest.
-- The scan reads every file the TOCs load: no file reads Buttons > Normal but
-- the two named below (by a literal 'button', 'normal' pair, or directly as
-- colors.button.normal). A new highlight that reads Normal fails here.
--
-- Real: the source files and Core's constants.
load_test_file('core/config_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')
local st = SaftUI

-- The files that may read Buttons > Normal, with what each reads it for. The
-- thumb (Widgets/scrollbar.lua) takes the key of its state, so it names no pair.
local ALLOWED = {
	['SaftUI-Core/Widgets/scrollbar.lua'] = 'the scroll bar thumb at rest',
	['SaftUI-Core/Config/optionspreview.lua'] = "the preview's Rest tile, a copy of the thumb",
}

local PATTERNS = {
	"['\"]button['\"]%s*,%s*['\"]normal['\"]",
	'colors%s*%.%s*button%s*%.%s*normal%f[%W]',
	"colors%s*%.%s*button%s*%[%s*['\"]normal['\"]%s*%]",
	'%.button%.normal%f[%W]',
	"%.button%[%s*['\"]normal['\"]%s*%]",
}

test('st.HOVER_TINT is the strength a hover highlight draws Hover at, 0.4 as the micro buttons draw it', function()
	eq(st.HOVER_TINT, 0.4)
end)

test('no file but the scroll bar thumb (and the preview that copies it) reads Buttons > Normal, by a pair or directly', function()
	local found = {}
	for _, path in ipairs((T.saftui_files())) do
		local source = read_saftui_source(path)
		if source and not ALLOWED[path] then
			local code = L.Lex(source) -- comments blanked, strings kept
			for line in (code .. '\n'):gmatch('(.-)\n') do
				for _, pattern in ipairs(PATTERNS) do
					if line:find(pattern) then found[#found + 1] = path .. ': ' .. (line:gsub('^%s+', '')); break end
				end
			end
		end
	end
	eq(table.concat(found, '\n'), '', 'every reader of Normal')
end)

test('the scan catches what it is for', function()
	local function hits(line)
		for _, pattern in ipairs(PATTERNS) do if line:find(pattern) then return true end end
		return false
	end
	check(hits("st:ColorRGBA('button', 'normal')"), 'a pair')
	check(hits('local c = st.config.profile.colors.button.normal'), 'a direct read')
	check(hits("local c = colors.button['normal']"), 'a direct indexed read')
	check(hits('local c = Colors().button.normal'), 'through Colors()')
	check(not hits("st:ColorRGBA('button', 'hover', st.HOVER_TINT)"), 'Hover is no read of Normal')
	check(not hits('colors.button.normalize'), 'a longer key')
end)

test('the preview reads Normal for the Rest thumb only', function()
	local source = read_saftui_source('SaftUI-Core/Config/optionspreview.lua')
	local count = 0
	for _ in source:gmatch("Shade%('button', 'normal'") do count = count + 1 end
	eq(count, 1, 'one read: the thumb at rest')
end)
