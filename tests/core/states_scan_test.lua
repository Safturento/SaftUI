-- The states scan: no SaftUI Lua file the TOCs load draws an interaction state by
-- hand. Every state (hover, pushed, selected, focus, disabled) is the helpers'
-- (SaftUI-Core/Widgets/states.lua, with the derivation in
-- SaftUI-Core/Media/states.lua), derived from the one Accent, so the same state
-- looks the same everywhere. Each rule reads the lexer's source (comments and
-- string contents blanked, tests/lib/source_lex.lua) of every file but the two
-- that own the states:
--   S1  no `ColorRGBA('accent'` at a strength but OB.OWN_STRENGTH (a mark at
--       full: the Accent is a color a widget shows, never a tint a state is
--       drawn with);
--   S2  no SetHighlightTexture, SetPushedTexture or SetCheckedTexture call but at
--       the sites of ALLOWED, each file with its count and a reason, of three
--       kinds: 'piece' (the game's own state slot is handed a flat texture of
--       SaftUI's, which the helper adopts as a piece and only colors, or the
--       slot is cleared), 'blizzard' (a Blizzard art branch that hands the
--       helper's own texture back with Blizzard's blend) and 'glyph' (a glyph's
--       own state textures, which the game shows). A new call fails until it is
--       listed with its reason;
--   S3  no SetBlendMode('ADD') (nor 'ADD' handed to SetHighlightTexture) in any
--       file (a flat state is the picked color mixed over what is under it,
--       BLEND; the art tables' 'ADD' values in themeart_data.lua are data, not a call);
--   S4  no read of a retired Buttons color (Normal, Hover, Pushed, Checked), by a
--       colors table or a `'button', 'hover'`-style pair;
--   S5  every st:AddStates names a shape of the list;
--   S6  no CreateTexture(nil, 'HIGHLIGHT') but at the sites of HIGHLIGHT_ALLOWED (a texture
--       the game shows under the mouse is a state drawn by hand unless the helper adopts it);
--   S7  no color setter (SetBackdropBorderColor, SetColorTexture, SetVertexColor,
--       SetTextColor) inside an OnEnter or OnLeave handler that does not go through
--       st:SetState or PaintStates, but the lines of HANDLER_ALLOWED (a color's meaning,
--       Danger, or the Blizzard art's own branch, is no state);
--   S8  no SetAlpha with a literal under 1 on a line that says enable or disabled (a
--       disabled dim is the helper's, st:StateAlpha).
-- The scan reads itself on fixtures: a line per rule fails it.
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')

-- The two files that own the states.
local MIGRATION = 'SaftUI-Core/Media/colors.lua'
local OWNERS = { ['SaftUI-Core/Media/states.lua'] = true, ['SaftUI-Core/Widgets/states.lua'] = true }

local SHAPES = { 'box', 'row', 'tab', 'check', 'thumb', 'knob', 'icon', 'mover', 'glyph' }
local SHAPE = {}
for _, name in ipairs(SHAPES) do SHAPE[name] = true end

-- S2: the calls a file may make, in the file's source order of kinds.
local ALLOWED = {
	['SaftUI-ActionBars/skin.lua'] = { count = 3, kind = 'piece', reason = "AB:SkinButton makes the button's highlight, pushed and checked textures (flat, SaftUI's own) and gives them to the game's setters; the helper adopts them (game = true) and only colors them" },
	['SaftUI-Bags/containers/bag.lua'] = { count = 2, kind = 'piece', reason = "a bag slot's hover and pushed textures, made on the slot and given to the setters; the helper adopts them" },
	['SaftUI-Core/skinning.lua'] = { count = 8, kind = 'piece', reason = "StripTextures clears the game's state slots (two calls, highlight and pushed); st:SkinButton makes its hover and pushed textures and, under the Blizzard look, hands the helper's own hover back with Blizzard's blend (the 'blizzard' branch); st:EnableResizing's corner is a glyph whose normal, pushed and highlight textures are one picture the game shows" },
	['SaftUI-Core/Config/optionsresize.lua'] = { count = 2, kind = 'glyph', reason = "the options window's resize grip: its highlight and pushed textures are glyph pictures the game shows, colored by the helper's glyph shape" },
	['SaftUI-Core/Widgets/checkbutton.lua'] = { count = 4, kind = 'piece', reason = "a check box's checked texture (its Mark, SaftUI's own, colored by the helper) and the highlight held at alpha 0 for Blizzard's art alone; a 'button'-style box clears the checked texture" },
	['SaftUI-Minimap/expansionbutton.lua'] = { count = 1, kind = 'piece', reason = "the expansion button's highlight is handed the flat texture again (SetLandingPageIconFromAtlases puts an atlas on it); RestyleStates colors it" },
	['SaftUI-Minimap/microbuttons.lua'] = { count = 1, kind = 'piece', reason = "the character micro button has no highlight of its own: it is given an empty HIGHLIGHT-layer texture, which MicroMenu.SkinHighlight then replaces" },
	['SaftUI-Minimap/micromenuitems.lua'] = { count = 1, kind = 'piece', reason = "MicroMenu.SkinHighlight: the flat highlight on a Blizzard button, made once, handed to the setter with BLEND, and registered with the helper as the hover piece" },
	['SaftUI-Misc/totemskin.lua'] = { count = 4, kind = 'piece', reason = "the totem buttons' highlight, pushed and checked textures are SaftUI's own flat ones (CreateStateTexture) handed to the setters; the helper adopts them (game = true); the flyout arrow's highlight too" },
}

-- Every call of a state setter in a source, as { line, name }.
local SETTERS = { 'SetHighlightTexture', 'SetPushedTexture', 'SetCheckedTexture' }
local function SetterCalls(mask)
	local out = {}
	for _, name in ipairs(SETTERS) do
		local from = 1
		while true do
			local s, e = mask:find('[:.]%s*' .. name .. '%s*%(', from)
			if not s then break end
			out[#out + 1] = { position = s, name = name }
			from = e + 1
		end
	end
	return out
end

-- The text of a call's arguments, split at the top-level commas of its parentheses,
-- from the position of its opening one. mask carries the structure (strings blanked), code the text.
local function Arguments(code, mask, open)
	local args, depth, start = {}, 0, open + 1
	for i = open, #mask do
		local c = mask:sub(i, i)
		if c == '(' or c == '{' or c == '[' then
			depth = depth + 1
		elseif c == ')' or c == '}' or c == ']' then
			depth = depth - 1
			if depth == 0 then
				args[#args + 1] = code:sub(start, i - 1)
				return args
			end
		elseif c == ',' and depth == 1 then
			args[#args + 1] = code:sub(start, i - 1)
			start = i + 1
		end
	end
	return args
end

local function Trim(text) return (text:gsub('^%s+', ''):gsub('%s+$', '')) end

-- S6: the places CreateTexture is handed the game's HIGHLIGHT layer by its literal name (the form
-- `CreateTexture(nil, st.ThemeArt.HOVER_LAYER)` is the allowed one: it is the layer the theme's
-- hover pieces go in, so the scan does not look for it), with how many each file may
-- make and why (the game shows such a texture only under the mouse).
local HIGHLIGHT_ALLOWED = {
	['SaftUI-Core/Config/optionslook.lua'] = { count = 1, reason = "the kit's box highlight under the mouse, adopted by the helper's box shape" },
	['SaftUI-Core/Config/optionssizes.lua'] = { count = 1, reason = "the size buttons' Blizzard-art highlight (art.glow), shown by the game under the mouse" },
	['SaftUI-Core/Widgets/button.lua'] = { count = 1, reason = "the Blizzard-art button's highlight (art.Highlight), shown by the game under the mouse" },
	['SaftUI-Minimap/microbuttons.lua'] = { count = 1, reason = "the character micro button's empty highlight (the S2 entry's), replaced by MicroMenu.SkinHighlight" },
	['SaftUI-Misc/totemskin.lua'] = { count = 1, reason = "the flyout arrow's thick glyph (skin.hover), shown by the game under the mouse" },
	['SaftUI-Tracker/items.lua'] = { count = 1, reason = "a quest item button's hover texture, adopted by the helper" },
}

local function HighlightTextures(code, mask)
	local out, from = {}, 1
	while true do
		local s, e = code:find('CreateTexture%s*%([^()]*[\'"]HIGHLIGHT[\'"]', from)
		if not s then break end
		if mask:sub(s, s + 12) == 'CreateTexture' then out[#out + 1] = s end
		from = e + 1
	end
	return out
end

-- S7: the color setters of an OnEnter or OnLeave handler (a SetScript or HookScript with a function)
-- that does not go through st:SetState or PaintStates, as positions.
local COLOR_SETTERS = { 'SetBackdropBorderColor', 'SetColorTexture', 'SetVertexColor', 'SetTextColor' }
local HANDLER_ALLOWED = {
	['SaftUI-Core/Config/optionsnav.lua'] = {
		{ line = 'if not self.disabled then self.text:SetTextColor(PickedText()) end', reason = "the Blizzard art's own hover (the handler returns early under Thick and Thin)" },
		{ line = 'if S.blizzard and not (self.active or self.disabled) then self.text:SetTextColor(Normal()) end', reason = "the Blizzard tab's own text color" },
		{ line = 'if S.blizzard and not self.active then self.text:SetTextColor(Muted()) end', reason = "the Blizzard tab's own text color" },
	},
	['SaftUI-Bags/ruleeditor.lua'] = {
		{ line = "remove:SetScript('OnEnter', function(self) self.icon:SetVertexColor(st:Color('text', 'danger'):GetRGB()) end)", reason = "a remove cross is Text > Danger under the mouse: a color's meaning, not a state" },
		{ line = "remove:SetScript('OnLeave', function(self) self.icon:SetVertexColor(Muted()) end)", reason = 'the cross at rest, Text > Muted' },
	},
	['SaftUI-Bags/categoriestab.lua'] = {
		{ line = "remove:SetScript('OnEnter', function(self) self.icon:SetVertexColor(st:Color('text', 'danger'):GetRGB()) end)", reason = "a remove cross is Text > Danger under the mouse: a color's meaning, not a state" },
		{ line = "remove:SetScript('OnLeave', function(self) self.icon:SetVertexColor(Muted()) end)", reason = 'the cross at rest, Text > Muted' },
	},
	['SaftUI-Loot/popup.lua'] = {
		{ line = 'if closes[button] then closes[button].icon:SetVertexColor(CloseColor(true)) end', reason = "the loot window's close cross is Text > Danger under the mouse (CloseColor)" },
		{ line = 'if closes[button] then closes[button].icon:SetVertexColor(CloseColor(false)) end', reason = 'the cross at rest, Text > Muted (CloseColor)' },
	},
}

local function HandlerColors(code, mask)
	local out, from = {}, 1
	while true do
		local s, e = code:find('Script%s*%(%s*[\'"]On[EL][a-z]+[\'"]%s*,', from)
		if not s then break end
		from = e + 1
		local open = code:find('%(', s)
		local name = code:sub(s, e):match('[\'"](On[EL][a-z]+)[\'"]')
		if mask:sub(s, s + 5) == 'Script' and (name == 'OnEnter' or name == 'OnLeave') then
			local depth, close = 0, nil
			for i = open, #mask do
				local c = mask:sub(i, i)
				if c == '(' or c == '{' or c == '[' then depth = depth + 1
				elseif c == ')' or c == '}' or c == ']' then
					depth = depth - 1
					if depth == 0 then close = i; break end
				end
			end
			local body = mask:sub(e + 1, close or #mask)
			if body:find('function') and not body:find('SetState') and not body:find('PaintStates') then
				for _, setter in ipairs(COLOR_SETTERS) do
					local at = 1
					while true do
						local a, b = body:find('[:.]%s*' .. setter .. '%s*%(', at)
						if not a then break end
						out[#out + 1] = e + a
						at = b + 1
					end
				end
			end
		end
	end
	table.sort(out)
	return out
end

-- Every failure of one source, as { rule, line, text }. path picks the exempt files.
local function Scan(path, source, opts)
	opts = opts or {}
	local found = {}
	if OWNERS[path] then return found end
	local code, mask = L.Lex(source)
	local function Fail(rule, position)
		local line = L.LineAt(mask, position)
		local text = source:match('^' .. ('[^\n]*\n'):rep(line - 1) .. '([^\n]*)') or ''
		found[#found + 1] = { rule = rule, line = line, text = Trim(text) }
	end
	local function InCode(s, char) return mask:sub(s, s) == char end

	-- S1
	local from = 1
	while true do
		local s, e = code:find('ColorRGBA%s*%(%s*[\'"]accent[\'"]%s*,', from)
		if not s then break end
		if mask:sub(s, s + 8) == 'ColorRGBA' then
			local args = Arguments(code, mask, code:find('%(', s))
			if #args >= 3 and Trim(args[3]) ~= 'OB.OWN_STRENGTH' then Fail('S1', s) end
		end
		from = e + 1
	end

	-- S2: the listed count is checked by the caller, a file by file.
	if not opts.noS2 then
		local calls = SetterCalls(mask)
		local allowed = ALLOWED[path]
		if #calls > (allowed and allowed.count or 0) then
			for _, call in ipairs(calls) do Fail('S2', call.position) end
		end
	end

	-- S3
	do
		from = 1
		while true do
			local s, e = code:find('SetBlendMode%s*%(%s*[\'"]ADD[\'"]', from)
			if not s then break end
			if mask:sub(s, s + 11) == 'SetBlendMode' then Fail('S3', s) end
			from = e + 1
		end
		from = 1
		while true do
			local s, e = code:find('SetHighlightTexture%s*%(', from)
			if not s then break end
			local args = Arguments(code, mask, e)
			if args[2] and Trim(args[2]):match('^[\'"]ADD[\'"]$') and mask:sub(s, s + 4) == 'SetHi' then Fail('S3', s) end
			from = e + 1
		end
	end

	-- S6
	if not opts.noS6 and #HighlightTextures(code, mask) > (HIGHLIGHT_ALLOWED[path] and HIGHLIGHT_ALLOWED[path].count or 0) then
		for _, position in ipairs(HighlightTextures(code, mask)) do Fail('S6', position) end
	end

	-- S7
	for _, call in ipairs(HandlerColors(code, mask)) do
		local line = Trim(source:match('^' .. ('[^\n]*\n'):rep(L.LineAt(mask, call) - 1) .. '([^\n]*)') or '')
		local listed = false
		for _, entry in ipairs(HANDLER_ALLOWED[path] or {}) do
			if entry.line == line then listed = true end
		end
		if not listed then Fail('S7', call) end
	end

	-- S8
	from = 1
	for line in mask:gmatch('[^\n]*\n?') do
		local lower = line:lower()
		if lower:find('setalpha%s*%(') and (lower:find('disabled') or lower:find('enable')) then
			local text = code:sub(from, from + #line - 1)
			if text:find('[^%w_.]0?%.%d') or text:find('[^%w_.]0%s') then Fail('S8', from + (line:find('[Ss]et[Aa]lpha') or 1) - 1) end
		end
		from = from + #line
	end

	-- S4: a color table's Buttons key, or a literal pair. (SaftUI-Core/Media/colors.lua holds the retired
	-- keys' names as strings: the migration steps and the frozen defaults.)
	for _, key in ipairs(path == MIGRATION and {} or { 'normal', 'hover', 'pushed', 'checked' }) do
		for _, pattern in ipairs({
			'%f[%w_][Cc]olors%s*%.%s*button%s*%.%s*' .. key .. '%f[^%w_]',
			'%f[%w_][Cc]olors%s*%(%s*%)%s*%.%s*button%s*%.%s*' .. key .. '%f[^%w_]',
			'%f[%w_][Cc]olors%s*%.%s*button%s*%[%s*[\'"]' .. key .. '[\'"]',
			'[\'"]button[\'"]%s*,%s*[\'"]' .. key .. '[\'"]',
			'[\'"]button%.' .. key .. '[\'"]',
		}) do
			from = 1
			while true do
				local s, e = code:find(pattern, from)
				if not s then break end
				-- (the opening of a pair or a path is a quote: it is in code, not in a comment, and not inside a longer string)
				local quoted = pattern:sub(1, 1) == '['
				if quoted and mask:sub(s, s) == code:sub(s, s) or not quoted and InCode(s, code:sub(s, s)) then Fail('S4', s) end
				from = e + 1
			end
		end
	end

	-- S5
	from = 1
	while true do
		local s, e = mask:find('AddStates%s*%(', from)
		if not s then break end
		local args = Arguments(code, mask, e)
		local shape = args[2] and Trim(args[2]) or ''
		local ok, names = shape ~= '', 0
		for name in shape:gmatch('[\'"]([^\'"]*)[\'"]') do
			names = names + 1
			if not SHAPE[name] then ok = false end
		end
		if names == 0 then ok = false end
		-- an expression of literals ('box' or 'check') is checked by each; a name or an expression a
		-- file computes its shape with is listed in DYNAMIC, exactly as it reads
		if opts.dynamic and opts.dynamic[shape] then ok = true end
		if not ok then Fail('S5', s) end
		from = e + 1
	end
	return found
end

-- A file that computes its shape names the expression here, exactly as it reads: the kit's wrapper
-- (W.HoverStates, whose callers give `shape` as a literal in their options) and the check box
-- skinner (a 'button'-style box is a box, any other a check).
local DYNAMIC = {
	['SaftUI-Core/Config/optionslook.lua'] = { shape = true },
	['SaftUI-Core/Widgets/checkbutton.lua'] = { ["style == 'button' and 'box' or 'check'"] = true },
}

local function Rules(found)
	local out = {}
	for _, f in ipairs(found) do out[#out + 1] = f.rule end
	return table.concat(out, ',')
end

local files, _, missing = T.saftui_files()

test('every file the TOCs name could be read', function()
	eq(#missing, 0, table.concat(missing, '; '))
	check(#files > 100, 'the TOCs name SaftUI files')
end)

local function Failures(rule)
	local out = {}
	for _, path in ipairs(files) do
		local source = read_saftui_source(path)
		for _, f in ipairs(Scan(path, source, { dynamic = DYNAMIC[path] })) do
			if f.rule == rule then out[#out + 1] = ('%s:%d: %s'):format(path, f.line, f.text) end
		end
	end
	return out
end

test('S1: no file reads the accent at a strength for a state (a mark at full: OB.OWN_STRENGTH)', function()
	local out = Failures('S1')
	eq(#out, 0, 'a state is the helpers\', not the Accent at a strength:\n' .. table.concat(out, '\n'))
end)

test('S2: state textures are set only by the helpers and the listed art branches', function()
	local out = Failures('S2')
	eq(#out, 0, 'a new SetHighlightTexture, SetPushedTexture or SetCheckedTexture needs its ALLOWED entry:\n' .. table.concat(out, '\n'))
end)

test('S2: every listed file has the calls its entry says, so a stale entry is noticed', function()
	local loaded = {}
	for _, path in ipairs(files) do loaded[path] = true end
	for path, entry in pairs(ALLOWED) do
		check(loaded[path], path .. ' is on the list but no TOC loads it')
		check(entry.kind == 'piece' or entry.kind == 'blizzard' or entry.kind == 'glyph', path .. ': a kind of the three')
		check(#entry.reason > 20, path .. ': a reason')
		local _, mask = L.Lex(read_saftui_source(path) or '')
		eq(#SetterCalls(mask), entry.count, path .. ' calls the state setters this many times now: change its count, or take it off the list')
	end
end)

test("S3: no ADD blend on any file's textures", function()
	local out = Failures('S3')
	eq(#out, 0, 'a flat state is BLEND, never ADD:\n' .. table.concat(out, '\n'))
end)

test("S6: a texture in the game's HIGHLIGHT layer is made only at the listed sites", function()
	local out = Failures('S6')
	eq(#out, 0, 'a new CreateTexture(nil, \'HIGHLIGHT\') needs its HIGHLIGHT_ALLOWED entry:\n' .. table.concat(out, '\n'))
	local loaded = {}
	for _, path in ipairs(files) do loaded[path] = true end
	for path, entry in pairs(HIGHLIGHT_ALLOWED) do
		check(loaded[path], path .. ' is on the list but no TOC loads it')
		check(#entry.reason > 20, path .. ': a reason')
		local code, mask = L.Lex(read_saftui_source(path) or '')
		eq(#HighlightTextures(code, mask), entry.count, path .. ' makes this many HIGHLIGHT textures now: change its count, or take it off the list')
	end
end)

test('S7: no hover handler colors by hand, but the listed lines', function()
	local out = Failures('S7')
	eq(#out, 0, 'an OnEnter or OnLeave handler colors through st:SetState, or its line is listed in HANDLER_ALLOWED:\n' .. table.concat(out, '\n'))
	for path, entries in pairs(HANDLER_ALLOWED) do
		local source = read_saftui_source(path) or ''
		local code, mask = L.Lex(source)
		local lines = {}
		for _, position in ipairs(HandlerColors(code, mask)) do
			lines[Trim(source:match('^' .. ('[^\n]*\n'):rep(L.LineAt(mask, position) - 1) .. '([^\n]*)') or '')] = true
		end
		for _, entry in ipairs(entries) do
			check(#entry.reason > 20, path .. ': a reason')
			check(lines[entry.line], path .. ' no longer has the handler line listed: ' .. entry.line)
		end
	end
end)

test('S8: no disabled dim by a literal alpha', function()
	local out = Failures('S8')
	eq(#out, 0, 'a disabled look is the helper\'s (st:StateAlpha), not a literal alpha:\n' .. table.concat(out, '\n'))
end)

test('S4: no Buttons > Normal, Hover, Pushed or Checked read anywhere', function()
	local out = Failures('S4')
	eq(#out, 0, 'those four colors are retired (migration step 8):\n' .. table.concat(out, '\n'))
end)

test('S5: every AddStates names a known shape', function()
	local out = Failures('S5')
	eq(#out, 0, 'the shapes are ' .. table.concat(SHAPES, ', ') .. ':\n' .. table.concat(out, '\n'))
end)

test("S5's shape list is the helper's own", function()
	local source = read_saftui_source('SaftUI-Core/Widgets/states.lua')
	local block = source:match('local SHAPES = (%b{})')
	local seen = {}
	for name in block:gmatch('\n%s*([%a_]+)%s*=%s*%b{}') do seen[name] = true end
	for _, name in ipairs(SHAPES) do check(seen[name], name .. ' is a shape of Widgets/states.lua') end
	for name in pairs(seen) do check(SHAPE[name], name .. ' is a shape of Widgets/states.lua the scan does not know') end
end)

test('the scan catches each: a fixture line per rule fails it', function()
	local function scan(src, opts, path) return Rules(Scan(path or 'sample.lua', src, opts or { helpers = true })) end
	-- S1
	eq(scan("local r, g, b, a = st:ColorRGBA('accent', nil, 0.4)"), 'S1', 'a strength')
	eq(scan("local r, g, b, a = st:ColorRGBA('accent', nil, st.HOVER_STRENGTH)"), 'S1', 'a named strength')
	eq(scan("label:SetTextColor(st:ColorRGBA('accent', nil, OB.OWN_STRENGTH))"), '', 'a mark at full')
	eq(scan("local r, g, b = st:ColorRGBA('accent')"), '', 'the Accent itself')
	eq(scan("-- st:ColorRGBA('accent', nil, 0.4)\nlocal s = \"st:ColorRGBA('accent', nil, 0.4)\""), '', 'a comment and a string')
	eq(scan("local r = st:ColorRGBA('text', 'normal', 0.4)"), '', 'another color')
	-- S2
	for _, name in ipairs(SETTERS) do
		eq(scan('button:' .. name .. '(texture)'), 'S2', name)
		eq(scan('button.' .. name .. '(button, texture)'), 'S2', name .. ' by a dot')
	end
	eq(scan('if frame.SetHighlightTexture then x() end'), '', 'a test for the method is no call')
	eq(scan("-- button:SetHighlightTexture(x)\nlocal s = 'button:SetPushedTexture(x)'"), '', 'a comment and a string')
	eq(scan('button:SetNormalTexture(x)\nbutton:SetDisabledTexture(x)'), '', 'the other two are not states of the helpers')
	eq(scan(('button:SetHighlightTexture(x)\n'):rep(8), nil, 'SaftUI-Core/skinning.lua'), '', 'a listed file at its count')
	eq(scan(('button:SetHighlightTexture(x)\n'):rep(9), nil, 'SaftUI-Core/skinning.lua'), ('S2,'):rep(8) .. 'S2', 'a listed file over its count')
	eq(scan('button:SetHighlightTexture(x)', nil, 'SaftUI-Core/Widgets/states.lua'), '', 'the helper is exempt')
	-- S3
	eq(scan("texture:SetBlendMode('ADD')"), 'S3')
	eq(scan('texture:SetBlendMode("ADD")'), 'S3', 'the other quotes')
	eq(scan("button:SetHighlightTexture(texture, 'ADD')", { helpers = true, noS2 = true }), 'S3', 'a highlight handed ADD')
	eq(scan("texture:SetBlendMode('BLEND')\ntexture:SetBlendMode(blend)"), '', 'BLEND, or a computed blend')
	eq(scan("texture:SetBlendMode('ADD')", {}), 'S3', 'a file that does not use the helpers too')
	eq(scan("button:SetHighlightTexture(texture, 'ADD')", { noS2 = true }), 'S3', 'a highlight handed ADD, in any file')
	eq(scan("-- texture:SetBlendMode('ADD')\nlocal s = \"SetBlendMode('ADD')\""), '', 'a comment and a string')
	-- S6
	eq(scan("local t = button:CreateTexture(nil, 'HIGHLIGHT')"), 'S6', 'a HIGHLIGHT texture')
	eq(scan('local t = button:CreateTexture(nil, "HIGHLIGHT", nil, 1)'), 'S6', 'the other quotes, with a sublevel')
	eq(scan("local t = button:CreateTexture(nil, 'ARTWORK')\nlocal u = button:CreateTexture(nil, st.ThemeArt.HOVER_LAYER)"), '', 'other layers: ARTWORK, and the theme\'s HOVER_LAYER constant, the allowed form')
	eq(scan("-- button:CreateTexture(nil, 'HIGHLIGHT')\nlocal s = \"CreateTexture(nil, 'HIGHLIGHT')\""), '', 'a comment and a string')
	eq(scan("local t = button:CreateTexture(nil, 'HIGHLIGHT')", nil, 'SaftUI-Tracker/items.lua'), '', 'a listed file at its count')
	eq(scan(("local t = button:CreateTexture(nil, 'HIGHLIGHT')\n"):rep(2), nil, 'SaftUI-Tracker/items.lua'), 'S6,S6', 'a listed file over its count')
	-- S7
	eq(scan("frame:SetScript('OnEnter', function(self) self.edge:SetBackdropBorderColor(st:ColorRGBA('accent')) end)"), 'S7', 'a border colored on enter')
	eq(scan("frame:HookScript('OnLeave', function(self)\n\tself.tex:SetColorTexture(0.2, 0.2, 0.2, 1)\nend)"), 'S7', 'a flat grey on leave, over several lines')
	eq(scan("frame:SetScript('OnEnter', function(self) self.text:SetTextColor(1, 1, 1) end)"), 'S7', 'a text color')
	eq(scan("frame:SetScript('OnEnter', function(self) self.tex:SetVertexColor(1, 1, 1) end)"), 'S7', 'a vertex color')
	eq(scan("frame:SetScript('OnEnter', function(self) st:SetState(self, 'hover', true) end)"), '', 'through the helper')
	eq(scan("frame:SetScript('OnEnter', function(self) self.tex:SetVertexColor(1, 1, 1); st:PaintStates(self) end)"), '', 'a handler that paints the states')
	eq(scan("frame:SetScript('OnClick', function(self) self.tex:SetVertexColor(1, 1, 1) end)"), '', 'another script')
	eq(scan("frame:SetScript('OnEnter', nil)\nlocal t = x:SetVertexColor(1, 1, 1)"), '', 'a color outside the handler')
	eq(scan("-- frame:SetScript('OnEnter', function() x:SetVertexColor(1) end)"), '', 'a comment')
	eq(scan("remove:SetScript('OnEnter', function(self) self.icon:SetVertexColor(st:Color('text', 'danger'):GetRGB()) end)", nil, 'SaftUI-Bags/ruleeditor.lua'), '', 'a listed line')
	-- S8
	eq(scan('button:SetAlpha(enabled and 1 or 0.35)'), 'S8', 'a dim beside enabled')
	eq(scan('if disabled then frame:SetAlpha(0.5) end'), 'S8', 'a dim beside disabled')
	eq(scan('frame:SetAlpha(st:StateAlpha())\nif disabled then frame:SetAlpha(1) end'), '', 'the helper, and full alpha')
	eq(scan('frame:SetAlpha(0.5)'), '', 'a dim with no state word')
	eq(scan('-- button:SetAlpha(enabled and 1 or 0.35)'), '', 'a comment')
	-- S4
	for _, key in ipairs({ 'normal', 'hover', 'pushed', 'checked' }) do
		eq(scan('local c = st.config.profile.colors.button.' .. key), 'S4', key)
		eq(scan("local c = Colors().button['" .. key .. "']"), '', 'an indirect form is color_reads_test.lua\'s rule D')
		eq(scan("local c = colors.button['" .. key .. "']"), 'S4', key .. ' by a string')
		eq(scan("local r = st:ColorRGBA('button', '" .. key .. "', 0.4)"), 'S4', key .. ' as a literal pair')
		eq(scan("local path = 'button." .. key .. "'"), 'S4', key .. ' as a path')
		eq(scan('local t = button.' .. key .. '\nbutton.' .. key .. ':Show()'), '', "a button frame's own " .. key .. ' texture is no color')
	end
	eq(scan("local path = 'button.hover'", nil, 'SaftUI-Core/Media/colors.lua'), '', 'the migration names the keys it retires')
	eq(scan("local r = st:ColorRGBA('button', 'danger', 0.4)"), '', 'Danger stays')
	eq(scan("-- st:ColorRGBA('button', 'hover')\nlocal s = 1"), '', 'a comment')
	-- S5
	eq(scan("st:AddStates(frame, 'box', {})"), '', 'a shape')
	eq(scan("st:AddStates(frame, 'button', {})"), 'S5', 'no such shape')
	eq(scan("st:AddStates(frame, style == 'button' and 'box' or 'check', {})"), 'S5', "an expression with a literal that is no shape ('button')")
	eq(scan("st:AddStates(frame, style == 'x' and 'box' or 'check', {})"), 'S5', 'by its literals')
	eq(scan("st:AddStates(frame, flag and 'box' or 'check', {})"), '', 'an expression of shapes')
	eq(scan('st:AddStates(frame, shape, {})'), 'S5', 'a computed shape')
	eq(scan('st:AddStates(frame, shape, {})', { helpers = true, dynamic = { shape = true } }), '', 'a computed shape its file names')
	eq(scan("st:AddStates(frame, style == 'button' and 'box' or 'check', {})", { helpers = true, dynamic = { ["style == 'button' and 'box' or 'check'"] = true } }), '', 'an expression its file names')
	eq(scan("st:AddStates(frame,\n\t'row',\n\t{ edge = false })"), '', 'a call over several lines')
	eq(scan("-- st:AddStates(frame, 'x')\nlocal s = \"st:AddStates(frame, 'x')\""), '', 'a comment and a string')
	for _, name in ipairs(SHAPES) do eq(scan("st:AddStates(frame, '" .. name .. "', {})"), '', name) end
end)
