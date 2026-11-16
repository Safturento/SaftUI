-- tests/lib/color_cost.lua, the helper every reader's cost case uses, and the
-- stubs' color setters it measures: a reader that calls a setter, makes a
-- frame, moves a point or makes garbage is seen as such; the methods are put
-- back; nothing in the helper hides a reader's own painting.
local T = load_test_file('lib/theme_helpers.lua')
local st = T.client('forever') -- Core's helpers, the colors and the theme, as a reader has them
local C = load_test_file('lib/color_cost.lua')

-- Garbage made by n calls of fn, in KB, with the collector stopped.
local function garbage(fn, n)
	collectgarbage(); collectgarbage()
	collectgarbage('stop')
	local before = collectgarbage('count')
	for _ = 1, n do fn() end
	local grown = collectgarbage('count') - before
	collectgarbage('restart')
	return grown
end

local function backdrop_frame()
	local f = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
	f:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = 'Interface\\Buttons\\WHITE8x8', edgeSize = 1 })
	return f
end

test("the stubs' color setters write into the table they have and make nothing per call", function()
	local texture = UIParent:CreateTexture(nil, 'ARTWORK')
	local text = UIParent:CreateFontString(nil, 'OVERLAY')
	local bar = CreateFrame('StatusBar')
	local font = CreateFont('SaftUI_ColorCostTestFont')
	local framed = backdrop_frame()
	local cases = {
		SetVertexColor = function() texture:SetVertexColor(0.1, 0.2, 0.3, 0.4) end,
		SetColorTexture = function() texture:SetColorTexture(0.1, 0.2, 0.3, 0.4) end,
		SetTextColor = function() text:SetTextColor(0.1, 0.2, 0.3) end,
		['Font SetTextColor'] = function() font:SetTextColor(0.1, 0.2, 0.3) end,
		SetStatusBarColor = function() bar:SetStatusBarColor(0.1, 0.2, 0.3) end,
		SetBackdropColor = function() framed:SetBackdropColor(0.1, 0.2, 0.3, 0.4) end,
		SetBackdropBorderColor = function() framed:SetBackdropBorderColor(0.1, 0.2, 0.3, 0.4) end,
	}
	for name, fn in pairs(cases) do
		fn() -- the first call may make the table
		local kb = garbage(fn, 1000)
		check(kb < 1, name .. ': 1000 calls made ' .. kb .. ' KB')
	end
	local r, g, b, a = texture:GetVertexColor()
	eq(r .. ',' .. g .. ',' .. b .. ',' .. a, '0.1,0.2,0.3,0.4', 'and the color reads back')
	r, g, b, a = framed:GetBackdropBorderColor()
	eq(r .. ',' .. g .. ',' .. b .. ',' .. a, '0.1,0.2,0.3,0.4', 'backdrop too')
	r, g, b, a = bar:GetStatusBarColor()
	eq(r .. ',' .. g .. ',' .. b, '0.1,0.2,0.3', 'a status bar')
end)

test('a reader that calls setters, makes frames, moves points and makes garbage is seen as such', function()
	local texture = UIParent:CreateTexture(nil, 'ARTWORK')
	local bar = CreateFrame('StatusBar')
	local framed = backdrop_frame()
	local frame = CreateFrame('Frame')
	local other = CreateFrame('Frame')
	local m = C.measure(function()
		CreateFrame('Frame') -- made
		UIParent:CreateTexture() -- made
		UIParent:CreateFontString() -- made
		texture:SetVertexColor(1, 1, 1) -- setter
		bar:SetStatusBarColor(1, 1, 1) -- setter
		framed:SetBackdropColor(1, 1, 1) -- setter
		framed:SetBackdropBorderColor(1, 1, 1) -- setter
		frame:SetPoint('CENTER') -- forbidden
		texture:SetPoint('CENTER') -- forbidden, even on a texture
		frame:Show() -- forbidden on a frame
		texture:Show() -- allowed on a texture
		texture:Hide()
		other:Hide() -- ignored below
		local t = {}
		for i = 1, 128 do t[i] = { i } end -- garbage
	end, 1, { [other] = true })
	eq(m.made, 3, 'three things made')
	eq(m.calls.total, 4, 'four setters')
	eq(m.calls.by.SetVertexColor, 1); eq(m.calls.by.SetStatusBarColor, 1)
	eq(m.calls.by.SetBackdropColor, 1); eq(m.calls.by.SetBackdropBorderColor, 1)
	eq(m.forbidden.total, 3, 'two points and a frame shown; a texture shown or hidden and an ignored frame are not')
	eq(m.forbidden.by.SetPoint, 2); eq(m.forbidden.by.Show, 1)
	check(m.kb > 12 and m.kb < 40, 'the frame, texture and font string made and 7 KB of tables: ' .. m.kb)
	local quiet = C.measure(function() texture:SetVertexColor(1, 1, 1) end, 100)
	check(quiet.kb < 1, 'a reader that makes nothing reads near 0: ' .. quiet.kb)
	check(m.ms >= 0, 'a time')
end)

test('every widget type the stubs have is counted, and st:SetBorderColor counts as a setter', function()
	local tooltip = CreateFrame('GameTooltip')
	local slider = CreateFrame('Slider')
	local cooldown = CreateFrame('Cooldown')
	local mask = UIParent:CreateMaskTexture()
	local font = CreateFont('SaftUI_ColorCostTestFont2')
	local button = CreateFrame('CheckButton')
	local edit = CreateFrame('EditBox')
	local scroll = CreateFrame('ScrollFrame')
	local framed = st:CreateFrame('Frame', nil, UIParent)
	st:SetTemplate(framed, 'thick', 'solid', 'panel')
	local m = C.measure(function()
		tooltip:Show(); tooltip:SetScript('OnShow', nil)
		slider:SetSize(10, 10)
		cooldown:Hide(); cooldown:SetPoint('CENTER')
		mask:SetPoint('CENTER')
		font:SetTextColor(1, 1, 1)
		button:SetWidth(5); edit:SetHeight(5); scroll:ClearAllPoints()
		st:SetBorderColor(framed, 1, 0, 0, 1)
	end)
	eq(m.forbidden.total, 9, 'every one of the nine forbidden calls: ' .. table.concat((function()
		local out = {}
		for k, v in pairs(m.forbidden.by) do out[#out + 1] = k .. '=' .. v end
		table.sort(out)
		return out
	end)(), ','))
	check((m.calls.by.SetTextColor or 0) == 1, 'a font object is a setter')
	check((m.calls.by.SetBackdropBorderColor or 0) >= 1, "the theme's own border color goes through the backdrop's setter: " .. tostring(m.calls.total))
end)

test('re-skinning calls count as forbidden', function()
	local texture = UIParent:CreateTexture(nil, 'ARTWORK')
	local text = UIParent:CreateFontString(nil, 'OVERLAY')
	local edit = CreateFrame('EditBox')
	local framed = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
	local m = C.measure(function()
		pcall(texture.SetTexture, texture, 'Interface\\Buttons\\WHITE8x8')
		pcall(texture.SetAtlas, texture, 'nothing')
		pcall(framed.SetBackdrop, framed, { bgFile = 'x' })
		pcall(text.SetFont, text, 'Fonts\\FRIZQT__.TTF', 12, '')
		pcall(edit.SetTextInsets, edit, 1, 1, 1, 1)
	end)
	for _, name in ipairs({ 'SetTexture', 'SetAtlas', 'SetBackdrop', 'SetFont', 'SetTextInsets' }) do
		check((m.forbidden.by[name] or 0) >= 1, name .. ' is counted')
	end
end)

test('the methods are put back, after an error too, and the garbage is read over all the runs', function()
	local texture = UIParent:CreateTexture(nil, 'ARTWORK')
	local methods = getmetatable(texture).__index
	local before, create, backdrop = methods.SetVertexColor, _G.CreateFrame, stub.backdrop.SetBackdropColor
	local runs = 0
	local m = C.measure(function() runs = runs + 1; texture:SetVertexColor(1, 1, 1) end, 5)
	eq(runs, 5, 'the runs'); eq(m.calls.total, 5, 'counted over all of them')
	check(methods.SetVertexColor == before and _G.CreateFrame == create and stub.backdrop.SetBackdropColor == backdrop, 'put back')
	local ok, err = pcall(C.measure, function() texture:SetVertexColor(1, 1, 1); error('boom', 0) end)
	check(not ok and err == 'boom', 'the error is raised again')
	check(methods.SetVertexColor == before and _G.CreateFrame == create and stub.backdrop.SetBackdropColor == backdrop, 'put back after the error')
end)

test("an ignored widget's setter calls still count, so ignoring cannot hide a reader's painting", function()
	local texture = UIParent:CreateTexture(nil, 'ARTWORK')
	local frame = CreateFrame('Frame')
	local m = C.measure(function() texture:SetVertexColor(1, 1, 1); frame:Hide() end, 1, { [texture] = true, [frame] = true })
	eq(m.calls.total, 1, 'the setter counts'); eq(m.forbidden.total, 0, 'the frame hiding is left out')
end)

test("the ticker's own Show and Hide are not counted; C.step and C.edit work with the modules swapped; C.edit ends the edit when fn errors", function()
	local CO = st:GetModule('Colors')
	local modules = st.modules
	st.modules = {}
	local ok, err = pcall(function()
		local m = C.measure(function()
			C.edit(st, function() st:ColorChanged('text', 'danger'); C.step(st) end)
		end)
		eq(m.forbidden.total, 0, 'the ticker shown and hidden is the mechanism: ' .. tostring(m.forbidden.total))
		local failed = pcall(C.edit, st, function() error('boom', 0) end)
		check(not failed, 'the error is raised again')
		check(not st:InColorEdit(), 'and the edit is over')
	end)
	st.modules = modules
	check(ok, tostring(err))
	check(not CO.ticker:IsShown(), 'nothing is due')
end)

test('the helper counts again after the world is rebuilt (T.client for another client)', function()
	T.client('retail')
	local texture = UIParent:CreateTexture(nil, 'ARTWORK')
	local frame = CreateFrame('Frame')
	local m = C.measure(function() texture:SetVertexColor(1, 1, 1); frame:Hide() end)
	eq(m.calls.total, 1, 'a setter counts in the new world'); eq(m.forbidden.total, 1, 'and a forbidden call')
	T.client('forever')
	m = C.measure(function() UIParent:CreateTexture() end)
	eq(m.made, 1, 'and back')
end)

test("SetTexCoord and SetAlpha are counted setters, never forbidden, and make no garbage (the states' Ruling 9)", function()
	local texture = UIParent:CreateTexture(nil, 'ARTWORK')
	local frame = CreateFrame('Frame')
	local button = CreateFrame('Button')
	local m = C.measure(function()
		texture:SetTexCoord(0, 1.4, 0, 1)
		texture:SetAlpha(0.5)
		frame:SetAlpha(0.4)
		button:SetAlpha(1)
	end)
	eq(m.calls.by.SetTexCoord, 1, 'a Fill\'s coordinates'); eq(m.calls.by.SetAlpha, 3, 'a texture, a frame and a button')
	eq(m.calls.total, 4); eq(m.forbidden.total, 0, 'neither is forbidden'); eq(m.made, 0)
	local quiet = C.measure(function() texture:SetTexCoord(0, 1.4, 0, 1); texture:SetAlpha(0.5); frame:SetAlpha(0.4) end, 1000)
	check(quiet.kb < 1, 'a pass that sets them makes nothing: ' .. quiet.kb)
	local r = { texture:GetTexCoord() }
	eq(r[5], 1.4, 'and the coordinates read back (the right edge)')
end)
