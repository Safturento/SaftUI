-- The temporary small-text font demo (SaftUI-Core/Dev/fontdemo.lua): every
-- candidate font is on disk and static; /suifonts opens and closes the window;
-- its rows; each control (size, outline, shadow, scale) reaches every row's
-- font strings; starring sorts; a font the game can't load says so.
--
-- Real: Core's helpers and panels.lua's window (load_core_helpers) and
-- Widgets/button.lua. A font file is read through read_saftui_source, and
-- "static" is the lack of an fvar table in its table directory.

load_core_helpers()
local st = SaftUI
load_saftui('SaftUI-Core/Dev/fontdemo.lua')
local FD = st.FontDemo

-- The font's file, or nil. Read as text: the tables' directory is plain bytes.
local function FontFile(name)
	return read_saftui_source('SaftUI-Core/Media/Fonts/Candidates/' .. name)
end

-- The tags in a TrueType file's table directory (4 bytes each, 16 apart, from
-- byte 12), or nil if it isn't one.
local function Tags(data)
	if not data or data:sub(1, 4) ~= '\0\1\0\0' then return nil end
	local count = data:byte(5) * 256 + data:byte(6)
	local tags = {}
	for i = 0, count - 1 do tags[data:sub(13 + 16 * i, 16 + 16 * i)] = true end
	return tags
end

test('every candidate font file and its licence are in the Candidates folder', function()
	eq(#FD.CANDIDATES, 9, 'candidates')
	for _, c in ipairs(FD.CANDIDATES) do
		check(not c.file:find('[', 1, true), c.file .. ' is not a variable font (no axis in the name)')
		check(c.file:find(c.weight, 1, true) ~= nil, c.file .. ' names its weight')
		local tags = Tags(FontFile(c.file))
		check(tags ~= nil, c.file .. ' is on disk and a TrueType font')
		check(tags and tags.glyf and tags.fvar == nil, c.file .. ' is static (no fvar table)')
	end
end)

test('the candidates are in LibSharedMedia as "Candidate: <family>"', function()
	for _, c in ipairs(FD.CANDIDATES) do
		local path = st.LSM:Fetch('font', 'Candidate: ' .. c.family, true)
		check(path ~= nil and path:find('Candidates\\' .. c.file, 1, true) ~= nil, c.family .. ' registered')
	end
end)

test('both TOCs and the Dev load.xml load the demo last', function()
	for _, toc in ipairs({ 'SaftUI-Core/SaftUI-Core_Forever.toc', 'SaftUI-Core/SaftUI-Core_Mainline.toc' }) do
		local text = read_saftui_source(toc)
		local last
		for line in text:gmatch('[^\n]+') do last = line end
		eq(last, 'Dev\\load.xml', toc .. ' last line')
	end
	check(read_saftui_source('SaftUI-Core/Dev/load.xml'):find('fontdemo.lua', 1, true) ~= nil, 'load.xml names it')
end)

test('/suifonts opens the window, and again closes it; it is never shown before', function()
	eq(FD.window, nil, 'not built before the command')
	check(type(SlashCmdList.SAFTUIFONTS) == 'function', 'handler')
	eq(_G.SLASH_SAFTUIFONTS1, '/suifonts', 'command')
	SlashCmdList.SAFTUIFONTS()
	check(FD.window:IsShown(), 'opened')
	eq(FD.window.title:GetText(), 'Small text fonts (demo)', 'title')
	SlashCmdList.SAFTUIFONTS()
	check(not FD.window:IsShown(), 'closed')
	SlashCmdList.SAFTUIFONTS()
	check(FD.window:IsShown(), 'opened again')
end)

test('Esc closes it, and another key does not', function()
	local keys
	for _, child in ipairs({ FD.window:GetChildren() }) do
		if child:IsKeyboardEnabled() then keys = child end
	end
	check(keys ~= nil, 'a keyboard catcher')
	stub.fire_script(keys, 'OnKeyDown', 'A')
	check(FD.window:IsShown(), 'A leaves it open')
	eq(stub.state(keys).propagate_keyboard, true, 'A goes on to the game')
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(not FD.window:IsShown(), 'Esc closes it')
	FD.window:Show()
end)

test('the window is movable', function()
	check(FD.window:IsMovable(), 'movable')
	check(FD.window.header ~= nil and FD.window.close_button ~= nil, 'a header and SaftUI\'s close button')
end)

test('rows: today first, Homespun again at its own size, then the nine candidates', function()
	eq(#FD.rows, 12, 'rows')
	local labels = {}
	for i, row in ipairs(FD.rows) do labels[i] = row.def.label end
	eq(labels[1], 'Homespun', 'first')
	check(labels[2]:find('Homespun at its own size', 1, true) ~= nil, 'second: Homespun at its own size')
	eq(labels[3], 'AgencyFB Bold', 'third')
	eq(labels[4], 'Barlow Condensed SemiBold', 'first candidate')
	eq(labels[12], 'PT Sans Narrow Bold', 'last candidate')
	check(FD.rows[1].def.today and FD.rows[2].def.today and FD.rows[3].def.today, 'today marked')
	check(not FD.rows[4].def.today, 'candidates are not')
end)

test('every row holds the specimens', function()
	local want = { 'SQ', 'CE', 'F', 'C2', '34', '3m', '12', '20', '147', 'Southshore', '7:38', '40ms', '144fps',
		'General', 'Combat Log', 'Guild', 'Aldr', 'Maer', 'Bar 3' }
	for _, row in ipairs(FD.rows) do
		local have = {}
		for _, t in ipairs(row.texts) do have[t.fs:GetText()] = t end
		for _, text in ipairs(want) do check(have[text] ~= nil, row.def.label .. ' has ' .. text) end
		eq(have['3m'].mult, 1.7, 'cooldown size multiple')
	end
end)

local function EachFont(fn)
	for _, row in ipairs(FD.rows) do
		for _, t in ipairs(row.texts) do fn(row, t) end
	end
end

test('the defaults: size 11, Outline, no shadow, scale 1', function()
	eq(FD.settings.size, 11, 'size')
	EachFont(function(row, t)
		local path, size, flags = t.fs:GetFont()
		eq(path, row.def.path, row.def.label .. ' path')
		if row.def.fixed then
			eq(size, 10 * t.mult, 'fixed size')
			eq(flags, 'MONOCHROMEOUTLINE', 'fixed flags')
		else
			eq(size, 11 * t.mult, row.def.label .. ' size')
			eq(flags, 'OUTLINE', row.def.label .. ' flags')
		end
		local x, y = t.fs:GetShadowOffset()
		check(x == 0 and y == 0, 'no shadow')
	end)
	eq(FD.rows[1].specimen:GetScale(), 1, 'scale')
end)

test('the Size slider changes every row but the fixed one', function()
	FD.slider:SetValue(14)
	eq(FD.settings.size, 14, 'setting')
	EachFont(function(row, t)
		local _, size = t.fs:GetFont()
		eq(size, (row.def.fixed and 10 or 14) * t.mult, row.def.label)
	end)
	FD.slider:SetValue(11)
	eq(FD.settings.size, 11, 'back')
end)

test('each Outline button sets the game flags on every row', function()
	local want = { NONE = '', OUTLINE = 'OUTLINE', THICK = 'THICKOUTLINE', MONO = 'MONOCHROME', MONOLINE = 'MONOCHROME, OUTLINE' }
	for key, flags in pairs(want) do
		stub.click(FD.outlineButtons[key])
		EachFont(function(row, t)
			local _, _, got = t.fs:GetFont()
			eq(got, row.def.fixed and 'MONOCHROMEOUTLINE' or flags, row.def.label .. ' ' .. key)
		end)
	end
	stub.click(FD.outlineButtons.OUTLINE)
end)

test('Shadow puts a 1px black shadow down and right on every text, and Off takes it away', function()
	stub.click(FD.shadowButtons.on)
	EachFont(function(row, t)
		local x, y = t.fs:GetShadowOffset()
		check(x == 1 and y == -1, row.def.label .. ' offset')
		local r, g, b, a = t.fs:GetShadowColor()
		check(r == 0 and g == 0 and b == 0 and a == 1, 'black')
	end)
	stub.click(FD.shadowButtons.off)
	EachFont(function(row, t)
		local x, y = t.fs:GetShadowOffset()
		check(x == 0 and y == 0, row.def.label .. ' no offset')
	end)
end)

test('Scale scales every row\'s specimens, and the rows grow with it', function()
	local before = FD.rows[4].frame:GetHeight()
	stub.click(FD.scaleButtons[1.55])
	for _, row in ipairs(FD.rows) do eq(row.specimen:GetScale(), 1.55, row.def.label) end
	check(FD.rows[4].frame:GetHeight() > before, 'taller')
	stub.click(FD.scaleButtons[0.75])
	for _, row in ipairs(FD.rows) do eq(row.specimen:GetScale(), 0.75, row.def.label) end
	stub.click(FD.scaleButtons[1])
	eq(FD.rows[4].frame:GetHeight(), before, 'back to its height')
end)

test('clicking a name stars the row and sorts it to the top; again, and it goes back', function()
	local function order()
		local keys = {}
		for i, row in ipairs(FD.ordered) do keys[i] = row.def.key end
		return keys
	end
	local first = order()[1]
	eq(first, 'homespun', 'before: today first')
	local pick = FD.rows[6] -- a candidate
	stub.click(pick.name)
	eq(order()[1], pick.def.key, 'starred first')
	check(pick.marker:IsShown(), 'marker shown')
	local top = pick.frame:GetTop()
	check(top > FD.rows[1].frame:GetTop(), 'placed above the first')
	stub.click(FD.rows[8].name)
	eq(order()[1], pick.def.key, 'earlier row stays first')
	eq(order()[2], FD.rows[8].def.key, 'second star second')
	stub.click(pick.name)
	stub.click(FD.rows[8].name)
	eq(order()[1], 'homespun', 'back to the list order')
	check(not pick.marker:IsShown(), 'marker hidden')
end)

test('a font the game cannot load says "failed to load" in its row', function()
	local row = FD.rows[5]
	local set = FD.SetTextFont
	local mine = {}
	for _, t in ipairs(row.texts) do mine[t] = true end
	FD.SetTextFont = function(text, ...) if mine[text] then return false end return set(text, ...) end
	FD:Refresh()
	check(row.failed, 'failed')
	check(row.failure:IsShown(), 'message shown')
	eq(row.failure:GetText(), 'failed to load', 'message')
	check(not row.specimen:IsShown(), 'specimens hidden')
	eq(row.failure:GetFontObject(), st:GetFont('normal'), 'in the normal font')
	check(not FD.rows[4].failed and FD.rows[4].specimen:IsShown(), 'other rows unaffected')
	FD.SetTextFont = set
	FD:Refresh()
	check(not row.failed and row.specimen:IsShown(), 'recovers when it loads')
end)

test('a text whose own SetFont fails takes a font object set to the same file', function()
	local row = FD.rows[5]
	for _, t in ipairs(row.texts) do t.fs.SetFont = function() return false end end
	FD:Refresh()
	check(not row.failed and row.specimen:IsShown(), 'loaded through the font object')
	local t = row.texts[1]
	eq(t.fs:GetFontObject(), t.object, 'the text takes its font object')
	eq((t.object:GetFont()), row.def.path, 'set to the row\'s file')
	for _, t in ipairs(row.texts) do t.fs.SetFont = nil end
	FD:Refresh()
end)

test('the window scrolls: its content is taller than the window at scale 1.55', function()
	stub.click(FD.scaleButtons[1.55])
	check(FD.content:GetHeight() > FD.scroll:GetHeight(), 'content taller than the scroll frame')
	local wheel = FD.scroll:GetScript('OnMouseWheel')
	wheel(FD.scroll, -1)
	check(FD.scroll:GetVerticalScroll() > 0, 'the wheel scrolls it')
	wheel(FD.scroll, 1)
	eq(FD.scroll:GetVerticalScroll(), 0, 'and back')
end)
