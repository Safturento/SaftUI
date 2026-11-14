-- SaftUI-Core/Config/optionsresize.lua: /sui growing taller by its bottom edge
-- or its grip, the render a resize holds off, the window hiding mid-resize, a
-- screen edge margin change, and a saved height the screen no longer fits.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (load_options_widgets), the body (optionsbody.lua), the window
-- (load_options_window) and edit mode. The /sui tree is the real one
-- Config:GetOptionsTable builds, from the real General, Fonts, Colors, Theme and
-- EditMode modules, AceDBOptions' profiles table, and the synthetic modules
-- options_window_helpers.lua registers. The mouse, the keyboard and the frame
-- clock are played by firing scripts (stub.fire_script): the window re-renders
-- and searches on its ticker's OnUpdate, which the stubs never run by
-- themselves.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OW = st.OptionsWindow
local theme, close_all, frames, rgba, FillRowsTable = H.theme, H.close_all, H.frames, H.rgba, H.FillRowsTable
local cell, FillRowsModule, tick = H.cell, H.FillRowsModule, H.tick

-- Where a region sits in the window: x and y from its top left, and its size.
local function at(f)
	local w = frames().window
	return ('%d,%d %dx%d'):format(f:GetLeft() - w:GetLeft(), w:GetTop() - f:GetTop(), f:GetWidth(), f:GetHeight())
end

-- Drags handle dy units down (up when negative): the button down, one frame, the button up.
local function resize(handle, dy)
	local scale = frames().window:GetEffectiveScale()
	stub.mouse_buttons.LeftButton = true
	stub.cursor_y = 500 * scale
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	stub.cursor_y = (500 - dy) * scale
	stub.fire_script(handle, 'OnUpdate', 0.016)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
end

------------------------------------------------------------------ /sui grows taller

test('/sui grows taller by its bottom edge or its grip: its width and top stay, the body takes the height, and it remembers it', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Loot')
	local F = frames(); local w = F.window; local top = w:GetTop()
	eq(at(F.grip), '1024,684 16x16', 'the grip in the bottom right corner')
	eq(F.grip:GetNormalTexture():GetTexture(), st.textures.cornerbr, "st:EnableResizing's corner")
	local r, g, b = st.config.profile.colors.button.hover:GetRGB()
	local hover = rgba(r, g, b, 1)
	for _, state in ipairs({ 'Highlight', 'Pushed' }) do
		local texture = F.grip['Get' .. state .. 'Texture'](F.grip)
		eq(texture:GetTexture(), st.textures.cornerbr, state .. ': the corner')
		eq(rgba(texture:GetVertexColor()), hover, state .. ": tinted the buttons' hover color")
	end
	eq(F.grip:GetHighlightTexture():GetBlendMode(), 'BLEND', 'the highlight blends, as st:EnableResizing has it')
	eq(F.grip:GetHighlightTexture():GetDrawLayer(), st.ThemeArt.HOVER_LAYER, 'in the highlight layer')
	eq(at(F.sizer), '0,694 1024x6', 'the bottom edge, up to the grip')
	eq(F.grip:GetFrameLevel(), w:GetFrameLevel() + 10, 'the grip over the window')
	eq(F.sizer:GetFrameLevel(), F.grip:GetFrameLevel(), 'the edge at its level')
	check(F.grip:IsMouseEnabled() and F.sizer:IsMouseEnabled(), 'both take the mouse')

	local function corner()
		local point, relative, relPoint, x, y = w:GetPoint(1)
		return table.concat({ point, tostring(relative == UIParent), relPoint, x, y }, ' ')
	end
	local anchored = corner()
	eq(anchored, 'TOPRIGHT true TOPRIGHT -440 -190', 'anchored by its top right corner')
	resize(F.grip, 100)
	eq(at(w), '0,0 1040x800')
	eq(w:GetTop(), top, 'its top stays')
	eq(corner(), anchored, 'the anchor stays TOPRIGHT at the same offsets: no re-anchoring')
	eq(at(F.side), '2,2 208x796'); eq(at(F.navFrame), '2,152 207x615'); eq(at(F.body), '238,113 774x639')
	eq(at(F.reloadButton:GetParent()), '210,752 828x46', 'the footer at the bottom')
	eq(at(F.grip), '1024,784 16x16', 'the grip with it')
	eq(st.config.global.optionsWindow.height, 800, "saved in SaftUI's global settings")
	resize(F.sizer, -300); eq(w:GetHeight(), 700, 'no shorter than its default')
	eq(corner(), anchored, 'shorter: the anchor the same')
	resize(F.sizer, 51); eq(w:GetHeight(), 752, 'an even height')
	eq(w:GetTop(), top, 'the top still where it was')
	eq(corner(), anchored, 'the anchor the same')
	st.Config:Close(); st.Config:Open('Loot'); eq(w:GetHeight(), 752, 'restored when it opens'); eq(w:GetTop(), top)
	resize(F.grip, 5000)
	local inset = st.config.profile.misc.clamp_inset
	check(w:GetBottom() >= inset and w:GetBottom() < inset + 2, 'it stops at the screen edge margin')
	eq(w:GetTop(), top, 'its top stays')

	-- A press with no travel saves nothing; a move keeps the height saved.
	st.config.global.optionsWindow = nil
	st.Config:Close(); st.Config:Open('Loot')
	resize(F.grip, 0)
	eq(st.config.global.optionsWindow, nil, 'a click on the grip saves nothing')
	resize(F.grip, 40)
	stub.fire_script(F.header, 'OnDragStart'); stub.fire_script(F.header, 'OnDragStop')
	eq(st.config.global.optionsWindow.height, 740, 'a move keeps the height')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('a resize renders nothing; a fill page draws its fill row once, when the mouse is let go', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	local module = FillRowsModule()
	module.GetConfigTable = FillRowsTable
	st.Config:Open('FillRows')
	local F = frames()
	local scale = F.window:GetEffectiveScale()
	local renders, view = OW.GetRenderCount(), F.body:GetHeight()
	local fill = cell('fill').widget.frame:GetHeight()
	stub.mouse_buttons.LeftButton = true
	stub.cursor_y = 500 * scale
	stub.fire_script(F.grip, 'OnMouseDown', 'LeftButton')
	for _, dy in ipairs({ 30, 60, 100 }) do
		stub.cursor_y = (500 - dy) * scale
		stub.fire_script(F.grip, 'OnUpdate', 0.016)
		tick()
		eq(F.body:GetHeight(), view + dy, dy .. ' down: the body follows')
		eq(OW.GetRenderCount(), renders, dy .. ' down: no render while the mouse is held')
		eq(cell('fill').widget.frame:GetHeight(), fill, dy .. ' down: the fill row waits')
	end
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(F.grip, 'OnMouseUp', 'LeftButton')
	tick()
	eq(OW.GetRenderCount(), renders + 1, 'one render once let go')
	eq(cell('fill').widget.frame:GetHeight(), fill + 100, 'the fill row 100 taller')
	eq(F.content:GetHeight(), F.body:GetHeight(), 'the drawn height is the view')
	tick()
	eq(OW.GetRenderCount(), renders + 1, 'and only the one')

	-- Shorter mid-drag, the fill row drawn to the old height is taller than
	-- the view, but the body's bar doesn't show over the page until the render.
	stub.mouse_buttons.LeftButton = true
	stub.cursor_y = 500 * scale
	stub.fire_script(F.grip, 'OnMouseDown', 'LeftButton')
	stub.cursor_y = 560 * scale
	stub.fire_script(F.grip, 'OnUpdate', 0.016)
	tick()
	eq(F.body:GetHeight(), view + 40, '60 up: the body follows')
	check(F.content:GetHeight() > F.body:GetHeight(), 'the fill row drawn taller than the view')
	check(not F.bar:IsShown(), "no body bar over the fill page while the mouse is held")
	eq(F.body:GetVerticalScroll(), 0, 'nor a scroll')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(F.grip, 'OnMouseUp', 'LeftButton')
	tick()
	eq(F.content:GetHeight(), F.body:GetHeight(), 'let go: drawn to the view')
	check(not F.bar:IsShown(), 'and still no bar')
	module.GetConfigTable = nil

	-- A button let go away from the handle (its mouse up lost) ends the resize
	-- on the handle's next frame.
	eq(F.window:GetHeight(), 740, '100 down and 60 up')
	stub.mouse_buttons.LeftButton = true
	stub.cursor_y = 500 * scale
	stub.fire_script(F.sizer, 'OnMouseDown', 'LeftButton')
	stub.mouse_buttons.LeftButton = nil
	stub.cursor_y = 480 * scale
	stub.fire_script(F.sizer, 'OnUpdate', 0.016)
	eq(F.window:GetHeight(), 740, 'the button up: no resize')
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(F.sizer, 'OnUpdate', 0.016)
	eq(F.window:GetHeight(), 740, 'and none after')
	stub.mouse_buttons.LeftButton = nil

	-- A page that scrolls, scrolled to its bottom.
	local tall = st:NewModule('TallPage')
	function tall:GetConfigTable()
		local args = {}
		for i = 1, 30 do
			args['t' .. i] = { type = 'toggle', name = 'Toggle ' .. i, order = i, size = 'wide', get = function() return true end, set = function() end }
		end
		return { name = 'Tall page', type = 'group', category = 'Frames', args = args }
	end
	st.config.global.optionsWindow = nil
	st.Config:Close(); st.Config:Open('TallPage')
	for _ = 1, 50 do stub.fire_script(F.body, 'OnMouseWheel', -1) end
	local total = F.content:GetHeight()
	eq(F.body:GetVerticalScroll(), total - 539, 'scrolled to its bottom')
	renders = OW.GetRenderCount()
	resize(F.grip, 100)
	tick()
	eq(OW.GetRenderCount(), renders, 'a resize renders nothing')
	eq(F.body:GetVerticalScroll(), total - 639, 'the offset clamps to the new range')
	local size = math.max(20, math.floor(639 * 639 / total))
	eq(F.bar:GetHeight(), size, 'the bar its share of the new view')
	eq(F.body:GetTop() - F.bar:GetTop(), 639 - size, 'at the bottom of it')
	tall.GetConfigTable = nil
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the window hiding mid-resize ends it: the height is saved, and the renders it held off run", function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Loot')
	local F = frames()
	local scale = F.window:GetEffectiveScale()
	stub.mouse_buttons.LeftButton = true
	stub.cursor_y = 500 * scale
	stub.fire_script(F.grip, 'OnMouseDown', 'LeftButton')
	stub.cursor_y = 440 * scale
	stub.fire_script(F.grip, 'OnUpdate', 0.016)
	eq(F.window:GetHeight(), 760, 'mid-resize: 60 taller')
	eq(st.config.global.optionsWindow, nil, 'nothing saved while the mouse is held')
	st.Config:Close() -- Esc, or /sui again, with the button still down
	eq(st.config.global.optionsWindow and st.config.global.optionsWindow.height, 760, 'hidden: the height saved')
	stub.cursor_y = 400 * scale
	stub.fire_script(F.grip, 'OnUpdate', 0.016)
	eq(F.window:GetHeight(), 760, 'the resize is over: the cursor moves nothing')
	stub.mouse_buttons.LeftButton = nil
	st.Config:Open('Loot')
	eq(F.window:GetHeight(), 760, 'opened again at the saved height')
	local renders = OW.GetRenderCount()
	st.Config:Refresh()
	tick()
	eq(OW.GetRenderCount(), renders + 1, 'a scheduled render runs: no resize holds it off')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('a screen edge margin change while /sui is open takes its height in at once, with the scroll bar following', function()
	theme('thick')
	local inset = st.config.profile.misc.clamp_inset
	local tall = st:GetModule('MarginPage', true) or st:NewModule('MarginPage')
	function tall:GetConfigTable()
		local args = {}
		for i = 1, 30 do
			args['t' .. i] = { type = 'toggle', name = 'Toggle ' .. i, order = i, size = 'wide', get = function() return true end, set = function() end }
		end
		return { name = 'Margin page', type = 'group', category = 'Frames', args = args }
	end
	-- The bar's height: its share of the view.
	local function share(F)
		local view = F.body:GetHeight()
		return math.max(20, math.floor(view * view / F.content:GetHeight()))
	end
	st.config.global.optionsWindow = { point = 'CENTER', x = 0, y = 0, height = 5000 }
	st.Config:Close(); st.Config:Open('MarginPage')
	local F = frames()
	eq(F.window:GetHeight(), 1080 - 2 * inset, 'at its most')

	st.config.profile.misc.clamp_inset = inset + 50
	st:UpdateScreenMargin()
	eq(F.window:GetHeight(), 1080 - 2 * (inset + 50), 'a wider margin: shorter at once, no reopen')
	eq(F.window:GetHeight(), OW.MaxHeight(), 'its new most')
	eq(F.bar:GetHeight(), share(F), 'the bar its share of the shorter view')
	eq(st.config.global.optionsWindow.height, 5000, 'the saved height kept')
	for _ = 1, 100 do stub.fire_script(F.body, 'OnMouseWheel', -1) end
	eq(F.body:GetVerticalScroll(), F.content:GetHeight() - F.body:GetHeight(), 'scrolled to its bottom')

	st.config.profile.misc.clamp_inset = inset
	st:UpdateScreenMargin()
	eq(F.window:GetHeight(), 1080 - 2 * inset, 'back: its most again')
	eq(F.body:GetVerticalScroll(), F.content:GetHeight() - F.body:GetHeight(), 'the offset clamped to the new range')
	eq(F.bar:GetHeight(), share(F), 'the bar its share of the taller view')
	eq(F.body:GetTop() - F.bar:GetTop(), F.body:GetHeight() - F.bar:GetHeight(), 'at the bottom of it')
	tall.GetConfigTable = nil
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('a saved height the screen no longer fits, or under the least', function()
	theme('thick')
	local inset = st.config.profile.misc.clamp_inset
	local function open(height)
		st.config.global.optionsWindow = { point = 'CENTER', x = 0, y = 0, height = height }
		st.Config:Close(); st.Config:Open('Loot')
		return frames().window
	end
	local w = open(5000)
	eq(w:GetHeight(), OW.MaxHeight(), 'too tall: as tall as the screen allows')
	eq(OW.MaxHeight(), 1080 - 2 * inset, 'the screen less the margin at its top and bottom')
	check(w:GetTop() <= UIParent:GetHeight() - inset and w:GetBottom() >= inset, 'inside the screen edge margin')
	eq(open(600):GetHeight(), 700, "under the least: Thick's 700")
	eq(open('tall'):GetHeight(), 700, 'not a number: no height')
	eq(open(751):GetHeight(), 752, 'made even')

	-- A screen shorter than 700 and the margin, at SaftUI's scale for it.
	stub.screen_height = 500
	UIParent:SetScale(768 / 500)
	eq(OW.MaxHeight(), 500 - 2 * inset, 'the screen less the margin')
	eq(open(5000):GetHeight(), 700, 'the least wins')
	eq(open(nil):GetHeight(), 700, 'none saved: the least')
	stub.screen_height = 1080
	UIParent:SetScale(st.scale)
	eq(OW.WindowHeight(OW.LAYOUT.blizzard), 728, "none saved under Blizzard: its 728")
	st.config.global.optionsWindow = { point = 'CENTER', x = 0, y = 0, height = 900 }
	eq(OW.WindowHeight(OW.LAYOUT.blizzard), 900, 'the saved height in either look')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)
