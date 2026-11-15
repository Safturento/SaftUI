-- The SetFont scan: no SaftUI Lua file the TOCs load calls SetFont on a text it
-- keeps, because in game SetFontObject doesn't undo an earlier SetFont (the
-- testing guide's stub rule 3), so a text that switched between a typeface and a
-- shared font would stay on the face. A text gets its font from st:ApplyFont
-- (SaftUI-Core/Media/fonts.lua). The rule is the lexer's masked source (comments
-- and string contents blanked, tests/lib/source_lex.lua) holding `:SetFont`,
-- `.SetFont` or a string naming it (hooksecurefunc(x, 'SetFont')); SetFontObject
-- and the like are other words.
--
-- ALLOWED names each file that may call it, and why. A file on it that no
-- longer calls it fails the second test, so a stale entry is noticed.
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')

local ALLOWED = {
	['SaftUI-Core/Media/fonts.lua'] = "the shared, typeface and preload font objects, and the probe (a font object's SetFont, never a text's)",
	['SaftUI-Core/Config/optionsbody.lua'] = "/sui's own font objects (Heading's and Text's faces)",
	['SaftUI-Core/Config/optionslook.lua'] = "the field font and SetFieldFont, /sui's field texts (a pooled font string that must be put on a face outright)",
	['SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua'] = "the buff and debuff frames' own font objects",
	['SaftUI-Chat/chatframe.lua'] = "Blizzard's chat frames, which take a face, size and flags and have no font object of SaftUI's",
	['SaftUI-Misc/tooltip.lua'] = "Blizzard's tooltip lines, copied onto each as it shows",
	['SaftUI-Misc/Skinning/addons/restedxp.lua'] = "RestedXP's texts and its timers' bars (another addon's font strings)",
	['SaftUI-Core/Dev/fontdemo.lua'] = 'the temporary font demo, to be deleted',
}

-- The lines of a source that call SetFont, as { line, text }.
local function Calls(source)
	local code, mask = L.Lex(source)
	local found = {}
	for _, pattern in ipairs({ '[:.]%s*SetFont%f[^%w_]' }) do
		local from = 1
		while true do
			local s, e = mask:find(pattern, from)
			if not s then break end
			found[#found + 1] = s
			from = e + 1
		end
	end
	local from = 1
	while true do -- a string naming it, as hooksecurefunc(x, 'SetFont') does
		local s, e = code:find('([\'"])SetFont%1', from)
		if not s then break end
		found[#found + 1] = s
		from = e + 1
	end
	table.sort(found)
	local out = {}
	for _, position in ipairs(found) do
		local line = L.LineAt(mask, position)
		local text = source:match('^' .. ('[^\n]*\n'):rep(line - 1) .. '([^\n]*)') or ''
		out[#out + 1] = { line = line, text = (text:gsub('^%s+', '')) }
	end
	return out
end

test('the scan, on samples: it finds a SetFont and passes the rest', function()
	local function count(source) return #Calls(source) end
	eq(count("fs:SetFont(path, 12, '')"), 1, 'a method call')
	eq(count('pcall(object.SetFont, object, path)'), 1, 'a function value')
	eq(count("hooksecurefunc(fs, 'SetFont', f)"), 1, 'a hook by name')
	eq(count('fs:SetFontObject(object) fs:SetFontString(1)'), 0, 'other words that start with it')
	eq(count("-- fs:SetFont(a)\nlocal s = 'x:SetFont(y)'"), 0, 'a comment and a string')
	eq(count('--[[ fs:SetFont(a) ]] local x = 1'), 0, 'a long comment')
	eq(count("a:SetFont(1)\nb:SetFont(2)"), 2, 'two calls')
	local calls = Calls("local x = 1\n\tfs:SetFont(path)")
	eq(calls[1].line, 2, 'its line')
	eq(calls[1].text, 'fs:SetFont(path)', 'its text')
end)

local files, _, missing = T.saftui_files()

test('every file the TOCs name could be read', function()
	eq(#missing, 0, table.concat(missing, '; '))
	check(#files > 100, 'the TOCs name SaftUI files')
end)

test('no file the TOCs load calls SetFont outside the allowed list', function()
	local failures = {}
	for _, path in ipairs(files) do
		if not ALLOWED[path] then
			for _, call in ipairs(Calls(read_saftui_source(path))) do
				failures[#failures + 1] = ('%s:%d: %s'):format(path, call.line, call.text)
			end
		end
	end
	eq(#failures, 0, 'a text gets its font from st:ApplyFont, never SetFont:\n' .. table.concat(failures, '\n'))
end)

test('every allowed file still has a call, so a stale entry is noticed', function()
	local loaded = {}
	for _, path in ipairs(files) do loaded[path] = true end
	for path in pairs(ALLOWED) do
		check(loaded[path], path .. ' is on the allowed list but no TOC loads it')
		check(#Calls(read_saftui_source(path) or '') > 0, path .. ' has no SetFont call any more: take it off the allowed list')
	end
end)
