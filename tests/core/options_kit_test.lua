-- SaftUI-Core/Config/optionswidgets.lua, the kit the widget files after it in
-- Config/load.xml build on: W.Create and its pool, the toggle (optionstypes.lua),
-- the validate, confirm and set path every widget's change takes
-- (OptionsModel.Set), custom types made with W.Define, ace_ready
-- (tests/lib/options_walk.lua) leaving SaftUI's own types out, and the close
-- button of SaftUI-Core/panels.lua (st:CreateCloseButton, st:CreateHeader).
--
-- Real: the model (optionsmodel.lua) the widgets read and write through, the
-- widgets, panels.lua and the helpers it needs (config_helpers.lua, with a real
-- AceConfigRegistry-3.0). Synthetic AceConfig option tables stand for the
-- options. The mouse and the keyboard are played by firing the frames' scripts
-- (stub.fire_script), and the color picker by stub.pick_color and friends
-- (tests/wow/blizzard.lua). The world and the helpers are
-- options_widgets_helpers.lua's.
local H = load_test_file('core/options_widgets_helpers.lua')
local st = SaftUI
local W = st.OptionsWidgets
local click, bind, opt, no, yes = H.click, H.bind, H.opt, H.no, H.yes
local parent, make, text_of = H.parent, H.make, H.text_of

------------------------------------------------------------------ toggle

test('toggle: Bind reads through the model, a click writes through it', function()
	local value, sets = true, {}
	local w, told = bind('toggle', 'on', opt('toggle', 'On', {
		get = function(info) return value end,
		set = function(info, v) sets[#sets + 1] = { info[#info], v }; value = v end,
	}))
	eq(w:GetWidth(), 18, 'checkbox width')
	eq(w.frame:GetChecked(), true, 'checked from get')
	check(w.frame.mark:IsShown(), 'the mark shows')

	click(w.frame)
	eq(#sets, 1, 'one set')
	eq(sets[1][1], 'on', 'info is the option path')
	eq(sets[1][2], false, 'the value flipped')
	eq(told.ok, true, 'onChanged(true)')
	eq(told.n, 1, 'told once')
	eq(w.frame:GetChecked(), false, 'now unchecked')
	check(not w.frame.mark:IsShown(), 'the mark is gone')

	click(w.frame)
	eq(value, true, 'and back')
	w:Release()
end)

test('a disabled widget ignores clicks', function()
	local sets = 0
	local w, told = bind('toggle', 'on', opt('toggle', 'On', {
		get = function() return false end,
		set = function() sets = sets + 1 end,
		disabled = true,
	}))
	check(w:IsDisabled(), 'disabled from the row')
	click(w.frame)
	eq(sets, 0, 'nothing set')
	eq(told.n, 0, 'nobody told')
	w:SetDisabled(false)
	click(w.frame)
	eq(sets, 1, 'enabled again')
	w:Release()
end)

------------------------------------------------------------------ validate, confirm, set

test('a change is validated, then confirmed, then set', function()
	local log, value = {}, 'a'
	local w, told = bind('input', 'name', opt('input', 'Name', {
		get = function() return value end,
		validate = function(info, v) log[#log + 1] = 'validate ' .. v; return v ~= 'bad' or 'No bad names' end,
		confirm = function(info, v) log[#log + 1] = 'confirm ' .. v; return v == 'big' and 'Really big?' or false end,
		set = function(info, v) log[#log + 1] = 'set ' .. v; value = v end,
	}))

	-- Invalid: nothing is confirmed or set, and the window is told why.
	w.frame:SetText('bad')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(table.concat(log, ','), 'validate bad', 'validated only')
	eq(told.ok, false, 'told: not ok')
	eq(told.err, 'No bad names', 'with the validate message')
	eq(value, 'a', 'nothing was set')
	eq(w.frame:GetText(), 'bad', 'the box keeps what was typed (AceConfigDialog does)')

	-- No confirm text: validate, then confirm, then set (OM.Set validates once more, as it always does).
	log = {}
	w.frame:SetText('small')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(table.concat(log, ','), 'validate small,confirm small,validate small,set small', 'order')
	eq(told.ok, true, 'ok')

	-- A confirm text asks first; nothing is set until Yes.
	log = {}
	w.frame:SetText('big')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(table.concat(log, ','), 'validate big,confirm big', 'asked, not set')
	log = {}
	eq(W.ConfirmText(), 'Really big?', 'the dialog asks the text')
	no()
	eq(#log, 0, 'No sets nothing')
	eq(value, 'small', 'value unchanged')
	check(not W.GetDialogFrames().catcher:IsShown(), 'dialog closed')

	w.frame:SetText('big')
	stub.fire_script(w.frame, 'OnEnterPressed')
	log = {}
	yes()
	eq(value, 'big', 'Yes sets')
	eq(log[#log], 'set big', 'the set comes after the question')
	eq(told.ok, true, 'told ok after Yes')
	w:Release()
end)

test('an input keeps its typed text and shows the error after a failed validate', function()
	local w, told = bind('input', 'name', opt('input', 'Name', {
		get = function() return 'stored' end,
		validate = function(_, v) return v ~= 'nope' or 'Not that one' end,
		set = function() end,
	}))
	w.frame:SetFocus() -- Enter drops focus first, and the focus loss refreshes the box
	w.frame:SetText('nope')
	stub.fire_script(w.frame, 'OnEnterPressed')
	check(not w.frame:HasFocus(), 'focus dropped')
	eq(w.frame:GetText(), 'nope', 'the typed text survives the focus loss')
	eq(told.ok, false, 'told: not ok')
	eq(told.err, 'Not that one', 'the error shows')
	-- A valid text still commits.
	w.frame:SetText('fine')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(told.ok, true, 'a valid text is set')
	w:Release()
end)

test('a validation pattern on an input fails the same way', function()
	local value, sets = '1', 0
	local w, told = bind('input', 'n', opt('input', 'N', {
		pattern = '^%d+$', usage = 'digits only',
		get = function() return value end,
		set = function(info, v) sets = sets + 1; value = v end,
	}))
	w.frame:SetText('x1')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(sets, 0, 'not set')
	eq(told.ok, false, 'not ok')
	check(told.err:find('digits only', 1, true), 'the usage text is the message')
	w:Release()
end)

------------------------------------------------------------------ pooling

test('a released widget is reused for the same type, and only that type', function()
	local a = W.Create(parent, 'toggle')
	local b = W.Create(parent, 'toggle')
	check(a ~= b, 'two live widgets differ')
	a:Release()
	eq(W.Pooled('toggle') >= 1, true, 'in the pool')
	local c = W.Create(parent, 'toggle')
	check(c == a, 'the released one comes back')
	local d = W.Create(parent, 'select')
	check(d ~= a and d ~= b, 'another type is its own')
	b:Release()
	c:Release()
	d:Release()
end)

test('a released widget is hidden, detached and forgets its row', function()
	local sets = 0
	local w = bind('toggle', 'on', opt('toggle', 'On', { get = function() return false end, set = function() sets = sets + 1 end }))
	local frame = w.frame
	w:Release()
	check(not frame:IsShown(), 'hidden')
	eq(frame:GetParent(), nil, 'no parent')
	eq(w.row, nil, 'row dropped')
	click(frame)
	eq(sets, 0, 'a stray click on the released frame sets nothing')
	w:Release() -- twice is harmless
	local count = W.Pooled('toggle')
	w:Release()
	eq(W.Pooled('toggle'), count, 'and does not pool twice')
end)

test('a reused widget shows its new row, not the old one', function()
	local a = bind('toggle', 'on', opt('toggle', 'On', { get = function() return true end, set = function() end }))
	a:Release()
	local root, row = make('off', opt('toggle', 'Off', { get = function() return false end, set = function() end }))
	local b = W.Create(parent, 'toggle')
	b:Bind(root, row)
	check(b == a, 'reused')
	eq(b.frame:GetChecked(), false, 'shows the new value')
	eq(b.frame:GetParent(), parent, 'under its new parent')
	b:Release()
end)

test('every widget type in the brief builds, binds and releases', function()
	local made = {}
	for _, rowType in ipairs({ 'toggle', 'range', 'select', 'multiselect', 'input', 'color', 'execute', 'keybinding', 'description' }) do
		local w = W.Create(parent, rowType)
		check(w.frame ~= nil, rowType .. ' has a frame')
		check(w:GetWidth() > 0, rowType .. ' has a width')
		made[#made + 1] = w
	end
	for _, w in ipairs(made) do w:Release() end
	local ok = pcall(W.Create, parent, 'nonsense')
	check(not ok, 'an unknown type is an error')
end)

------------------------------------------------------------------ the close button

test('CreateCloseButton: the look', function()
	local frame = st:CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(frame)
	eq(st:GetCloseButton(frame), close, 'found with st:GetCloseButton')
	eq(close:GetWidth(), 24, '24 wide')
	eq(close:GetHeight(), 24, '24 tall')
	eq(st.CLOSE_X_BUTTON_SIZE[1], 24, 'the constant says so too')
	eq(st.CLOSE_BUTTON_SIZE[1], 20, 'a Blizzard button keeps its old size constant')
	eq(close.icon:GetTexture(), st.textures.close, 'the close texture')
	check(st.textures.close:find('close.tga', 1, true), 'registered in st.textures')
	local colors = st.config.profile.colors
	local gr, gg, gb = close.icon:GetVertexColor()
	eq(gr, colors.text.grey.r, 'the X is grey')
	eq(gg, colors.text.grey.g, 'grey g')
	eq(gb, colors.text.grey.b, 'grey b')
	local br, bg, bb = close:GetBackdropBorderColor()
	eq(br, 0.3, 'the edge border')
	local fr = close:GetBackdropColor()
	eq(fr, 0.078, 'the field fill')
	check(close.outline ~= nil, 'a dark line outside')
	eq(close.outline:GetBackdropBorderColor(), 0.1, 'in the alt color')
end)

test('CreateCloseButton writes no field onto the frame it is given', function()
	local frame = CreateFrame('Frame', nil, UIParent)
	local before = {}
	for k in pairs(frame) do before[k] = true end
	st:CreateCloseButton(frame)
	for k in pairs(frame) do check(before[k], 'new field on the frame: ' .. tostring(k)) end
end)

test('CreateCloseButton: hover turns red, pressed moves the X down 1px, a click hides the frame', function()
	local frame = st:CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(frame)
	local red = st.config.profile.colors.text.red

	stub.fire_script(close, 'OnEnter')
	local br, bg, bb = close:GetBackdropBorderColor()
	eq(br, red.r, 'border red r')
	eq(bg, red.g, 'border red g')
	eq(bb, red.b, 'border red b')
	local xr, xg = close.icon:GetVertexColor()
	eq(xr, red.r, 'the X is red')
	eq(xg, red.g, 'X g')
	local fr, fg, fb, fa = close:GetBackdropColor()
	eq(fr, 0.5, 'a red fill')
	check(fa > 0 and fa < 1, 'a faint one')

	local _, _, _, _, y0 = close.icon:GetPoint(1)
	stub.fire_script(close, 'OnMouseDown', 'LeftButton')
	local _, _, _, _, y1 = close.icon:GetPoint(1)
	eq(y1, y0 - 1, 'the X moves down 1px')
	stub.fire_script(close, 'OnMouseUp', 'LeftButton')
	local _, _, _, _, y2 = close.icon:GetPoint(1)
	eq(y2, y0, 'and back up')

	stub.fire_script(close, 'OnLeave')
	eq((close:GetBackdropBorderColor()), 0.3, 'the border is back')
	local gr = close.icon:GetVertexColor()
	eq(gr, st.config.profile.colors.text.grey.r, 'the X is grey again')

	check(frame:IsShown(), 'shown before the click')
	click(close, 'LeftButton')
	check(not frame:IsShown(), 'a click hides the frame')
end)

test('CreateHeader: a SaftUI close button keeps its look and sits in the header; a handed-in other button keeps its old one', function()
	local frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetSize(300, 200)
	local close = st:CreateCloseButton(frame)
	local header = st:CreateHeader(frame, 'Title')
	eq(frame.close_button, close, 'the header found the frame\'s close button')
	eq(close.backdrop, nil, 'no template backdrop was put over it')
	eq(close:GetWidth(), 24, 'still 24 wide')
	local point, relative = close:GetPoint(1)
	eq(point, 'RIGHT', 'anchored to the header\'s right')
	eq(relative, header, 'to the header')
	eq(close.icon:GetTexture(), st.textures.close, 'the X is still there')

	local other = st:CreateFrame('Frame', nil, UIParent)
	local plain = st:CreateFrame('Button', nil, other)
	st:CreateHeader(other, 'Other', plain)
	check(plain.backdrop ~= nil, 'a button that is not SaftUI\'s is skinned as before')
	eq(plain:GetWidth(), 20, 'at the old size')
	eq(plain:GetHeight(), 10, 'and height')
end)

test('CreatePanel builds its header with the new close button', function()
	local panel = st:CreatePanel('Test panel', 200, 100)
	local close = st:GetCloseButton(panel)
	check(close ~= nil, 'the panel has its close button')
	eq(close.icon:GetTexture(), st.textures.close, 'with the X')
	click(close)
	check(not panel:IsShown(), 'and it closes the panel')
end)

------------------------------------------------------------------ custom types

test('W.Define: W.Create gives the type from its pool, and Bind, Refresh and Release run its methods', function()
	local log = {}
	W.Define('testcustom', {
		width = 120,
		bare = true,
		build = function(w)
			log[#log + 1] = 'build'
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(120, 40)
			w.text = w.frame:CreateFontString(nil, 'OVERLAY')
			w.text:SetFontObject(W.GetFont())
		end,
		methods = {
			Refresh = function(self)
				log[#log + 1] = 'refresh ' .. tostring(self:Value())
				self.text:SetText(tostring(self:Value()))
			end,
			OnRelease = function(self) log[#log + 1] = 'release ' .. tostring(self.row and self.row.key) end,
			Shout = function(self) return 'shout ' .. self.row.key end,
		},
	})
	eq(W.WIDTH.testcustom, 120, 'W.WIDTH has its width')
	eq(W.CUSTOM.testcustom.bare, true, 'W.CUSTOM marks it bare')

	local value = 'one'
	local w, told = bind('testcustom', 'mine', opt('testcustom', 'Mine', {
		get = function() return value end,
		set = function(_, v) value = v end,
	}))
	eq(table.concat(log, ','), 'build,refresh one', 'built once, then Bind ran its Refresh')
	eq(w.type, 'testcustom', 'its type')
	eq(w:GetWidth(), 120, 'its width')
	eq(w.frame:GetParent(), parent, 'under the parent W.Create was given')
	check(w.frame:IsShown(), 'shown')
	eq(w:Shout(), 'shout mine', 'its own methods are on the widget')

	value = 'two'
	w:Refresh()
	eq(text_of(w.text), 'two', 'Refresh reads the row again')
	w:Commit('three')
	eq(value, 'three', 'a change sets through the model')
	eq(told.ok, true, 'and tells the window')

	w:Release()
	eq(log[#log], 'release mine', 'Release runs its OnRelease, before the row is dropped')
	check(not w.frame:IsShown(), 'hidden')
	eq(w.frame:GetParent(), nil, 'detached')
	eq(w.row, nil, 'the row is dropped')
	local count = #log
	w:Refresh()
	eq(#log, count, 'a Refresh after the release does nothing')
	eq(W.Pooled('testcustom'), 1, 'in its pool')

	local again = W.Create(parent, 'testcustom')
	check(again == w, 'W.Create gives it back from the pool')
	eq(#log, count, 'not built again')
	check(again.frame:IsShown(), 'shown again')
	check(again.Shout ~= nil, 'with its methods')
	again:Release()

	-- A custom type may be defined again: new widgets are the new
	-- definition's, and a widget of the old one never joins the new pool.
	local old = W.Create(parent, 'testcustom')
	W.Define('testcustom', {
		width = 90,
		build = function(nw)
			nw.frame = CreateFrame('Frame', nil, UIParent)
			nw.second = true
		end,
	})
	eq(W.WIDTH.testcustom, 90, 'the new width')
	eq(W.CUSTOM.testcustom.bare, false, 'no longer bare')
	local fresh = W.Create(parent, 'testcustom')
	check(fresh ~= old and fresh.second, "the new definition's widget")
	eq(fresh:GetWidth(), 90, 'with the new width')
	old:Release()
	eq(W.Pooled('testcustom'), 0, "the old widget isn't pooled with the new ones")
	fresh:Release()
	check(W.Create(parent, 'testcustom') == fresh, 'the new one is')

	local ok = pcall(W.Define, 'nobuild', { width = 10 })
	check(not ok, 'a type with no build function is an error')
	eq(W.WIDTH.nobuild, nil, 'and is not defined')
end)

test('redefining a built-in type is an error', function()
	for _, rowType in ipairs({ 'toggle', 'range', 'select', 'multiselect', 'input', 'color', 'execute', 'keybinding', 'description', 'position' }) do
		local width = W.WIDTH[rowType]
		local ok, err = pcall(W.Define, rowType, {
			width = 1, bare = true,
			build = function(w) w.frame = CreateFrame('Frame', nil, UIParent) end,
		})
		check(not ok and tostring(err):find(rowType, 1, true) ~= nil, rowType .. ': an error naming it: ' .. tostring(err))
		eq(W.WIDTH[rowType], width, rowType .. ' keeps its width')
		eq(W.CUSTOM[rowType], nil, rowType .. ' is not a custom type')
	end
	local w = W.Create(parent, 'toggle')
	check(w.frame.mark ~= nil, 'a toggle still builds as one')
	w:Release()
end)

------------------------------------------------------------------ ace_ready

test("ace_ready leaves out SaftUI's own types", function()
	local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
	local names = {}
	for rowType in pairs(SAFTUI_TYPES) do names[#names + 1] = rowType end
	table.sort(names)
	eq(table.concat(names, ','), 'bagcategories,bagitems,bagrule,position', 'SAFTUI_TYPES')

	local function Validate(page)
		return pcall(AceConfigRegistry.ValidateOptionsTable, AceConfigRegistry,
			{ name = st.name, type = 'group', args = { Page = page } }, st.name)
	end
	local function Page()
		return { type = 'group', name = 'Page', args = {
			on = { type = 'toggle', name = 'On' },
			items = { type = 'bagitems', name = 'Items' },
			pos = st.Config.generators.position(1, true, {}),
			inner = { type = 'group', name = 'Inner', args = {
				list = { type = 'bagcategories', name = 'Categories' },
				rule = { type = 'bagrule', name = 'Rule' },
				keep = { type = 'toggle', name = 'Keep' },
			} },
		} }
	end
	local function keys(args)
		local out = {}
		for key in pairs(args) do out[#out + 1] = key end
		table.sort(out)
		return table.concat(out, ',')
	end

	local page = Page()
	local ready = ace_ready(page)
	eq(keys(ready.args), 'inner,on', 'left out at the top')
	eq(keys(ready.args.inner.args), 'keep', 'and inside a group')
	eq(keys(page.args), 'inner,items,on,pos', 'the original keeps them')
	eq(keys(page.args.inner.args), 'keep,list,rule', 'all the way down')
	check(Validate(ace_ready(Page())), 'AceConfigRegistry passes the copy')

	-- Why: AceConfig has no widget for any of them.
	for _, rowType in ipairs(names) do
		local one = { type = 'group', name = 'Page', args = {
			on = { type = 'toggle', name = 'On' },
			mine = rowType == 'position' and st.Config.generators.position(1, true, {}) or { type = rowType, name = 'Mine' },
		} }
		local ok, err = Validate(one)
		check(not ok and tostring(err):find(rowType, 1, true) ~= nil, rowType .. ' is unknown to it: ' .. tostring(err))
		check(Validate(ace_ready(one)), rowType .. ': passes once left out')
	end
end)
