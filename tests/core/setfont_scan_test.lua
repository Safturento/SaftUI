-- The SetFont scan: no SaftUI Lua file the TOCs load calls SetFont on a text it
-- keeps, because a text that switched between a typeface and a shared font
-- must not be left on a face: SetFontObject with the same object keeps an
-- earlier SetFont (seen in game; whether another object clears it is
-- unverified, testing.md stub rule 3), so a text gets its font from st:ApplyFont
-- (SaftUI-Core/Media/fonts.lua). The rule is the lexer's masked source (comments
-- and string contents blanked, tests/lib/source_lex.lua) holding `:SetFont`,
-- `.SetFont` or a string naming it (hooksecurefunc(x, 'SetFont')); SetFontObject
-- and the like are other words.
--
-- ALLOWED names each file that may call it and why, and the call sites it may
-- have: the receiver text before `:SetFont` (`object`, `fs`, `'SetFont'` for a
-- hook by name) with how many calls each has. Receivers are generic (`line`,
-- `fs`, `frame`), so a count is pinned per receiver: a new call on a listed
-- receiver, or on another one, fails; so does one that goes missing.
-- `any = true` exempts a whole file, for the temporary font demo only: it calls
-- SetFont on font strings, objects and chained calls in a hundred places and is
-- to be deleted. A file on the list with no call, or a listed receiver it no
-- longer has, fails a second case, so a stale entry is noticed.
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')

local ALLOWED = {
	['SaftUI-Core/Media/fonts.lua'] = { reason = "the shared, typeface and preload font objects, and the probe (a font object's SetFont, never a text's)", calls = { object = 4, probe = 2 } },
	['SaftUI-Core/Config/optionsbody.lua'] = { reason = "/sui's own font objects (Heading's and Text's faces)", calls = { ['fontObjects[key]'] = 1 } },
	['SaftUI-Core/Config/optionslook.lua'] = { reason = "the field font object and SetFieldFont, /sui's field texts (a pooled font string that must be put on a face outright)", calls = { fieldFont = 1, fs = 2 } },
	['SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua'] = { reason = "the buff and debuff frames' own font objects", calls = { font = 1 } },
	['SaftUI-Chat/chatframe.lua'] = { reason = "Blizzard's chat frames, which take a face, size and flags and have no font object of SaftUI's", calls = { frame = 1 } },
	['SaftUI-Misc/tooltip.lua'] = { reason = "Blizzard's tooltip lines, copied onto each as it shows", calls = { line = 1 } },
	['SaftUI-Misc/Skinning/addons/restedxp.lua'] = { reason = "RestedXP's texts, its timers' bars and the hook that notices its own SetFont (another addon's font strings)", calls = { fs = 1, bar = 1, ["'SetFont'"] = 1 } },
	['SaftUI-Misc/Skinning/addons/spy.lua'] = { reason = "Spy's texts (another addon's font strings), which keep the size Spy asks for and take SaftUI's face and outline, and the hook that notices Spy's own SetFont", calls = { fs = 1, ["'SetFont'"] = 1 } },
	['SaftUI-Core/Dev/fontdemo.lua'] = { reason = 'the temporary font demo, to be deleted', any = true },
}

-- The calls of a source, as { line, text, receiver } in order.
local function Calls(source)
	local code, mask = L.Lex(source)
	local found = {}
	local from = 1
	while true do
		local s, e = mask:find('[:.]%s*SetFont%f[^%w_]', from)
		if not s then break end
		local receiver = mask:sub(1, s - 1):match('([%w_%.%[%]]*)$')
		found[#found + 1] = { position = s, receiver = receiver }
		from = e + 1
	end
	from = 1
	while true do -- a string naming it, as hooksecurefunc(x, 'SetFont') does
		local s, e = code:find('([\'"])SetFont%1', from)
		if not s then break end
		found[#found + 1] = { position = s, receiver = code:sub(s, e) }
		from = e + 1
	end
	table.sort(found, function(a, b) return a.position < b.position end)
	local out = {}
	for _, call in ipairs(found) do
		local line = L.LineAt(mask, call.position)
		local text = source:match('^' .. ('[^\n]*\n'):rep(line - 1) .. '([^\n]*)') or ''
		out[#out + 1] = { line = line, text = (text:gsub('^%s+', '')), receiver = call.receiver }
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
	local calls = Calls("local x = 1\n\tfontObjects[key]:SetFont(path)")
	eq(calls[1].line, 2, 'its line')
	eq(calls[1].text, 'fontObjects[key]:SetFont(path)', 'its text')
	eq(calls[1].receiver, 'fontObjects[key]', 'its receiver')
	eq(Calls("hooksecurefunc(fs, 'SetFont', f)")[1].receiver, "'SetFont'", 'a hook names the string')
end)

test('the scan counts a receiver: a second call on a listed receiver is one too many', function()
	local calls = Calls("line:SetFont(a)\nline:SetFont(b)")
	eq(#calls, 2, 'two calls')
	eq(calls[1].receiver .. calls[2].receiver, 'lineline', 'on one receiver')
end)

local files, _, missing = T.saftui_files()

test('every file the TOCs name could be read', function()
	eq(#missing, 0, table.concat(missing, '; '))
	check(#files > 100, 'the TOCs name SaftUI files')
end)

test('no file the TOCs load calls SetFont outside the allowed list and its call sites', function()
	local failures = {}
	for _, path in ipairs(files) do
		local allowed = ALLOWED[path]
		if not (allowed and allowed.any) then
			local pinned, seen, byReceiver = allowed and allowed.calls or {}, {}, {}
			for _, call in ipairs(Calls(read_saftui_source(path))) do
				seen[call.receiver] = (seen[call.receiver] or 0) + 1
				byReceiver[call.receiver] = byReceiver[call.receiver] or {}
				table.insert(byReceiver[call.receiver], call)
			end
			-- A receiver over its count lists every call on it (which one is new
			-- is not known from the source's order).
			for receiver, count in pairs(seen) do
				if count > (pinned[receiver] or 0) then
					for _, call in ipairs(byReceiver[receiver]) do
						failures[#failures + 1] = ('%s:%d: %s'):format(path, call.line, call.text)
					end
				end
			end
		end
	end
	eq(#failures, 0, 'a text gets its font from st:ApplyFont, never SetFont:\n' .. table.concat(failures, '\n'))
end)

test('every allowed file and call site still exists, so a stale entry is noticed', function()
	local loaded = {}
	for _, path in ipairs(files) do loaded[path] = true end
	for path, allowed in pairs(ALLOWED) do
		check(loaded[path], path .. ' is on the allowed list but no TOC loads it')
		local calls = Calls(read_saftui_source(path) or '')
		check(#calls > 0, path .. ' has no SetFont call any more: take it off the allowed list')
		local seen = {}
		for _, call in ipairs(calls) do seen[call.receiver] = (seen[call.receiver] or 0) + 1 end
		for receiver, count in pairs(allowed.calls or {}) do
			eq(seen[receiver] or 0, count, path .. ' calls SetFont on ' .. receiver .. ' this many times now: change its count, or take it off its list')
		end
	end
end)
