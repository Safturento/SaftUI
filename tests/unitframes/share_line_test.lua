-- A shared row's hover line ("Own, reset, Apply to: All | Multiple") stops before the row's control
-- (SaftUI-Core/Config/optionsshare.lua, OB.PlaceShare): on Unit frames > Player > General > Parts > Health
-- text's menu (376 wide, the owner's case: the Font row), and on a unit's page at full and half width.
--
-- Real: page_world.lua's unit frame world on a customized profile converted by UF:PrepareShared, the options
-- kit, a body drawn as the part menu draws its own (optionsmenu.lua: OB.New on OM.MenuRoot, a half body 376
-- wide) and as the window draws a page.
local SW = load_test_file('unitframes/shared_world.lua')
local P_ = load_test_file('lib/pixels.lua')
local PW, st, UF, OM, W, OB

local ROOM = 4 -- OB's LABEL_ROOM: the line ends this far before the control

local function world()
	reset_world()
	PW = load_test_file('unitframes/page_world.lua').world()
	st, UF, OM, W = PW.st, PW.UF, PW.OM, PW.W
	OB = st.OptionsBody
	load_editmode()
	SW.customize(UF:GetProfileConfig())
	UF:PrepareShared()
	assert(UF:SharedReady(), 'the profile did not convert')
	_G.GameTooltip = _G.GameTooltip or CreateFrame('GameTooltip', 'GameTooltip', UIParent)
end

local function tree() return { Unitframes = UF:GetConfigTable() } end

local function in_look(look, fn)
	local was = st.config.profile.theme.name
	st.config.profile.theme.name = look
	local ok, err = pcall(fn)
	W.CloseList()
	st.config.profile.theme.name = was
	stub.cursor_x, stub.cursor_y = 0, 0
	if not ok then error(err, 0) end
end

-- Where a region and everything shown in it draws leftmost (the control's drawn left edge).
local function drawn_left(region, left)
	if not region:IsShown() then return left end
	local l = region:GetLeft()
	if l and (not left or l < left) then left = l end
	if region.GetRegions then
		for _, r in ipairs({ region:GetRegions() }) do left = drawn_left(r, left) end
		for _, c in ipairs({ region:GetChildren() }) do left = drawn_left(c, left) end
	end
	return left
end

local PIECES = { 'ownText', 'reset', 'sep', 'all', 'pipe', 'multiple' }

-- A part's menu as optionsmenu.lua draws it: the body, its view's sections drawn, its cells by key.
local function menu_body(root, unit, part)
	local item = root.Unitframes.args[unit].args.general.args.parts.args[part]
	local menu_root = OM.MenuRoot(item)
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(376, 900)
	local body = OB.New(content, menu_root, nil, 376)
	body:SetWidth(376, true)
	body:Draw(OM.BuildView(menu_root, OM.MENU_KEY).sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content, menu_root
end

local function page_body(root, unit, width, half)
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(width, 1400)
	local body = OB.New(content, root, nil, 774)
	if half then body:SetWidth(width, true) end
	body:Draw(OM.BuildView(root, 'Unitframes', { pick = unit, tab = 'general' }).sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content
end

-- Hovers cell's row; checks its line (when one shows) ends before the control. Returns whether a line showed.
local function check_line(cell, label)
	local frame = cell.frame
	stub.fire_script(frame, 'OnEnter', true)
	local parts = frame.share
	local showed = parts ~= nil and parts.line:IsShown()
	if showed and cell.widget and cell.row.type ~= 'item' and cell.height <= cell.rowHeight then
		local control = drawn_left(cell.widget.frame)
		check(control ~= nil, label .. ': the control has a left edge')
		local limit = control - ROOM
		check(parts.line:GetRight() <= limit, label .. ': the line ends before the control: ' .. parts.line:GetRight() .. ' vs ' .. limit)
		for _, key in ipairs(PIECES) do
			local piece = parts[key]
			if piece:IsShown() and piece:GetRight() > limit then
				-- a piece shown across the cut takes no mouse past it, and the cut line clips it
				check(parts.line:DoesClipChildren(), label .. ': ' .. key .. ' runs past the control, so the line must clip it')
				check(piece.GetHitRectInsets == nil or (select(2, piece:GetHitRectInsets())) >= piece:GetRight() - limit,
					label .. ': ' .. key .. ' takes no mouse past the control')
			end
		end
	end
	stub.fire_script(frame, 'OnLeave', true)
	stub.cursor_x, stub.cursor_y = 0, 0
	return showed
end

test("the owner's case: Player > Health text's menu, the Font row owned: its hover line ends before the select", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		world()
		in_look(look, function()
			local root = tree()
			local body, by, content, mroot = menu_body(root, 'player', 'healthtext')
			local cell = by.font
			check(cell ~= nil, look .. ': the Font row is in the menu')
			local state = OM.ShareState(mroot, cell.row)
			check(state ~= nil, look .. ': the Font row is shared')
			-- own it: a set on the player's own
						local ok = false
			for _, name in ipairs({ 'Friz Quadrata TT', 'Arial Narrow', 'Morpheus', 'Skurri' }) do
				if OM.Set(mroot, cell.row, name) then ok = true; if UF:IsOwn('player', 'health.text.font') then break end end
			end
			body:Release()
			body, by, content, mroot = menu_body(root, 'player', 'healthtext')
			cell = by.font
			eq(OM.ShareState(mroot, cell.row).own, true, look .. ': the Font row is own')
			stub.fire_script(cell.frame, 'OnEnter', true)
			local parts = cell.frame.share
			check(parts and parts.line:IsShown(), look .. ': the line shows')
			local select_left = drawn_left(cell.widget.frame)
			local limit = select_left - ROOM
			for _, key in ipairs(PIECES) do
				local piece = parts[key]
				if piece:IsShown() then
					check(piece:GetRight() <= limit or parts.line:DoesClipChildren(), look .. ': ' .. key .. ' ends right of the select')
				end
			end
			check(parts.line:GetRight() <= limit, look .. ': the line ends before the select (' .. parts.line:GetRight() .. ' vs ' .. limit .. ')')
			body:Release()
		end)
	end
end)

-- What each row kind's line shows in a part's menu, for the report: kind -> "shown pieces / dropped".
local MEASURE = false -- true prints each kind's room and what its line shows

local function shown_of(parts)
	local out = {}
	for _, key in ipairs(PIECES) do
		if parts[key]:IsShown() then out[#out + 1] = key end
	end
	return table.concat(out, ',')
end

-- Every shared row of every part's menu of the units, owned first, hovered under each look.
local function own_everything(root, mroot, by)
	for _, cell in pairs(by) do
		local state = OM.ShareState(mroot, cell.row)
		if state and state.member and not state.own then
			local value = OM.Get and OM.Get(mroot, cell.row)
			if cell.row.type == 'toggle' then OM.Set(mroot, cell.row, not value)
			elseif cell.row.type == 'range' then OM.Set(mroot, cell.row, (tonumber(value) or 0) + 1)
			end
		end
	end
end

test('every row kind in a part menu: the line ends before the control, in order, Own\'s words in Reset\'s tooltip', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		world()
		in_look(look, function()
			local root = tree()
			local tip = {}
			local saved = _G.GameTooltip
			_G.GameTooltip = {
				SetOwner = function() tip.lines = {} end,
				AddLine = function(_, text) tip.lines[#tip.lines + 1] = text end,
				AddDoubleLine = function(_, l, r) tip.lines[#tip.lines + 1] = l .. '|' .. r end,
				Show = function() end, IsOwned = function() return true end, Hide = function() end,
			}
			local seen, kinds = 0, {}
			for _, unit in ipairs({ 'player', 'target', 'party', 'raid10', 'boss', 'all' }) do
				local parts = root.Unitframes.args[unit].args.general.args.parts.args
				for part, item in pairs(parts) do
					if type(item) == 'table' and item.menu then
						local body, by, content, mroot = menu_body(root, unit, part)
						own_everything(root, mroot, by)
						body:Release()
						body, by, content, mroot = menu_body(root, unit, part)
						eq(#P_.off(content), 0, look .. ' ' .. unit .. '.' .. part .. ': whole pixels: ' .. P_.report(P_.off(content)))
						for key, cell in pairs(by) do
							local label = look .. ' ' .. unit .. '.' .. part .. '.' .. key .. ' (' .. cell.row.type .. ')'
							if check_line(cell, label) then
								seen = seen + 1
								stub.fire_script(cell.frame, 'OnEnter', true)
								local p = cell.frame.share
								local control = cell.widget and drawn_left(cell.widget.frame)
								if control and cell.height <= cell.rowHeight then
									kinds[cell.row.type] = kinds[cell.row.type] or {}
									local room = math.floor(control - cell.frame:GetLeft()) - ROOM - ((cell.labelX or 0) + (cell.frame.shareShift or 0))
									kinds[cell.row.type][look .. ':' .. room .. ' -> ' .. shown_of(p)] = true
								end
								-- order: Own is dropped before the words; the words never without Own's drop
								if p.ownText:IsShown() then check(p.sep:IsShown(), label .. ': Own shows only with the words') end
								if p.ownDropped then
									stub.fire_script(p.reset, 'OnEnter', true)
									local text = table.concat(tip.lines or {}, ' ')
									check(#(tip.lines or {}) >= 3, label .. ': Reset\'s tooltip carries what Own said: ' .. text)
									stub.fire_script(p.reset, 'OnLeave', true)
								end
								stub.fire_script(cell.frame, 'OnLeave', true)
								stub.cursor_x, stub.cursor_y = 0, 0
							end
						end
						body:Release()
					end
				end
			end
			_G.GameTooltip = saved
			check(seen > 10, look .. ': lines were checked: ' .. seen)
			if MEASURE then
				for kind, set in pairs(kinds) do
					local list = {}
					for text in pairs(set) do list[#list + 1] = text end
					table.sort(list)
					print(look .. ' ' .. kind .. ': ' .. table.concat(list, ' | '))
				end
			end
		end)
	end
end)

test("a unit's page at full and half width: every row's line ends before its control", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		world()
		in_look(look, function()
			local root = tree()
			local seen = 0
			for _, shape in ipairs({ { 774, false }, { 388, true } }) do
				local body, by, content = page_body(root, 'player', shape[1], shape[2])
				eq(#P_.off(content), 0, look .. ' ' .. shape[1] .. ': whole pixels: ' .. P_.report(P_.off(content)))
				for key, cell in pairs(by) do
					if check_line(cell, look .. ' ' .. shape[1] .. ' ' .. key) then seen = seen + 1 end
				end
				body:Release()
			end
			check(seen > 0, look .. ': some line was checked')
		end)
	end
end)

-- The game's sequence the tests above missed: a part's menu is drawn by OW:OpenMenu (optionsmenu.lua, Draw),
-- which draws the rows before it anchors the menu to its dots, and clears its old anchors first; Draw holds
-- the menu on the screen meanwhile, so every row has a rect as it is drawn (checked below). The line must
-- end before the control when it shows, entered through the label or through the control itself.
-- The stub counts 6.5 units a byte, wider than the game's text, so on its own the toggle's line fits either
-- room; small_text(9) puts the line without Own (141) between the control's room (137) and the cell's (160), as the game has it.
local function small_text(size)
	local fo = OB.Font('small')
	local path, _, flags = fo:GetFont()
	fo:SetFont(path, size, flags)
end

-- The first shown, mouse-enabled part of a control (it or what is under it) that the share hooked: where the mouse enters.
local function hooked_part(region)
	if region:IsShown() and region:IsMouseEnabled() and region.shareHooked then return region end
	for _, child in ipairs({ region:GetChildren() }) do
		local found = hooked_part(child)
		if found then return found end
	end
end

local function open_menu(look)
	local root = tree()
	local body, by = page_body(root, 'player', 774, false)
	local part = by.healthtext
	check(part and part.widget:OpenMenu(), look .. ': the menu opens')
	return body, part, PW.OW.GetMenuFrames(1)
end

test("a part's menu as the game opens it (rows drawn on a menu held on the screen): the hover line still ends before the control", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		world()
		in_look(look, function()
			local OW = PW.OW
			small_text(9)
			local body, part, menu = open_menu(look)
			local mroot = OM.MenuRoot(part.row.option)
			local by = {}
			for _, c in ipairs(menu.body.cells) do by[c.row.key] = c end
			own_everything(nil, mroot, by)
			for _, name in ipairs({ 'Friz Quadrata TT', 'Arial Narrow', 'Morpheus', 'Skurri' }) do
				if by.font and OM.Set(mroot, by.font.row, name) and UF:IsOwn('player', 'health.text.font') then break end
			end
			OW:CloseMenu()
			-- every row has a rect as PlaceShare and PlaceDefault run (the margin of the cases below is a few units)
			local placed, rectless = 0, 0
			local place_share = OB.PlaceShare
			OB.PlaceShare = function(cell)
				placed = placed + 1
				if not (cell.frame:GetLeft() and (not cell.widget or cell.widget.frame:GetLeft())) then rectless = rectless + 1 end
				return place_share(cell)
			end
			local opened = part.widget:OpenMenu()
			OB.PlaceShare = place_share
			check(opened, look .. ': the menu opens again')
			check(placed > 0, look .. ': rows were placed: ' .. placed)
			eq(rectless, 0, look .. ': every row has a rect as it is drawn')
			menu = OW.GetMenuFrames(1)
			local seen, toggles, fonts = 0, 0, 0
			for _, c in ipairs(menu.body.cells) do
				if c.row.type ~= 'item' and c.widget and c.frame.share and c.frame.shareOffers then
					local label = look .. ' ' .. tostring(c.row.key) .. ' (' .. c.row.type .. ')'
					-- through the label, then through the control's own OnEnter (a hooked part of it)
					if check_line(c, label) then seen = seen + 1 end
					local p = c.frame.share
					-- the line goes away (its watcher does it when the mouse has left), then the control's own part takes the mouse
					p.line:Hide()
					local part_hit = hooked_part(c.widget.frame)
					check(part_hit ~= nil, label .. ': a part of the control takes the mouse')
					if part_hit then stub.fire_script(part_hit, 'OnEnter', true) end
					local control = drawn_left(c.widget.frame)
					check(p.line:IsShown(), label .. ': the line shows from the control')
					check(p.line:GetRight() <= control - ROOM, label .. ': from the control, the line ends before it: ' .. p.line:GetRight() .. ' vs ' .. (control - ROOM))
					stub.fire_script(c.frame, 'OnLeave', true)
					stub.cursor_x, stub.cursor_y = 0, 0
					if c.row.type == 'toggle' then toggles = toggles + 1 elseif c.row.type == 'font' then fonts = fonts + 1 end
				end
			end
			check(seen > 0 and toggles > 0 and fonts > 0, look .. ': lines checked: ' .. seen .. ', toggles ' .. toggles .. ', fonts ' .. fonts)
			eq(#P_.off(menu.content), 0, look .. ': whole pixels: ' .. P_.report(P_.off(menu.content)))
			OW:CloseMenu()
			body:Release()
		end)
	end
end)

-- A setting's own reset icon in a menu (a source page's row, whose line has no Reset): placed at draw time from the
-- control's drawn left, so it needs the rect the menu's hold on the screen gives; it ends DEFAULT_GAP (6) before
-- that, Blizzard's art included.
test("a part's menu as the game opens it: a toggle's own reset icon ends before the control", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		world()
		in_look(look, function()
			local OW = PW.OW
			local root = tree()
			local body, by = page_body(root, 'all', 774, false)
			local part = by.healthtext
			check(part.widget:OpenMenu(), look .. ': the menu opens')
			local mroot = OM.MenuRoot(part.row.option)
			local menu = OW.GetMenuFrames(1)
			for _, c in ipairs(menu.body.cells) do
				if c.row.type == 'toggle' then
					local v = OM.Get(mroot, c.row)
					OM.Set(mroot, c.row, not v)
				end
			end
			OW:CloseMenu()
			check(part.widget:OpenMenu(), look .. ': the menu opens again')
			menu = OW.GetMenuFrames(1)
			local seen = 0
			for _, c in ipairs(menu.body.cells) do
				local icon = c.frame.defaultReset
				if c.row.type == 'toggle' and icon and icon:IsShown() then
					seen = seen + 1
					local control = drawn_left(c.widget.frame)
					check(icon:GetRight() <= control - 6, look .. ' ' .. tostring(c.row.key) .. ': the icon ends 6 before the control: '
						.. icon:GetRight() .. ' vs ' .. (control - 6))
				end
			end
			check(seen > 0, look .. ': a toggle shows its reset icon: ' .. seen)
			OW:CloseMenu()
			body:Release()
		end)
	end
end)

-- The fallback for a row with no rect at draw time (SaftUI-Core/Config/optionsshare.lua: LineEnd reckons the control at
-- the cell's right edge less the widget's, ShowLine fits the line again as it shows). A menu holds a rect now, so this
-- body is drawn on a frame with no anchor, then the frame is anchored and the rows are hovered.
test('rows drawn with no rect: the hover line is fitted again as it shows, and the reset icon stays clear of the control frame', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		world()
		in_look(look, function()
			small_text(9)
			local root = tree()
			local function bare_body(unit, part)
				local item = root.Unitframes.args[unit].args.general.args.parts.args[part]
				local menu_root = OM.MenuRoot(item)
				local content = CreateFrame('Frame', nil, UIParent) -- no anchor: no rect
				content:SetSize(376, 900)
				local body = OB.New(content, menu_root, nil, 376)
				body:SetWidth(376, true)
				body:Draw(OM.BuildView(menu_root, OM.MENU_KEY).sections)
				local by = {}
				for _, c in ipairs(body.cells) do by[c.row.key] = c end
				return body, by, content, menu_root
			end
			-- owned toggles and Font on the player
			local body, by, content, mroot = bare_body('player', 'healthtext')
			own_everything(nil, mroot, by)
			for _, name in ipairs({ 'Friz Quadrata TT', 'Arial Narrow', 'Morpheus', 'Skurri' }) do
				if OM.Set(mroot, by.font.row, name) and UF:IsOwn('player', 'health.text.font') then break end
			end
			body:Release()
			body, by, content = bare_body('player', 'healthtext')
			eq(by.deficit.frame:GetLeft(), nil, look .. ': no rect while drawn')
			content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
			local seen = 0
			for _, c in pairs(by) do
				if c.row.type ~= 'item' and c.widget and c.frame.shareOffers then
					if check_line(c, look .. ' ' .. tostring(c.row.key)) then seen = seen + 1 end
				end
			end
			check(seen > 0, look .. ': lines checked: ' .. seen)
			body:Release()
			-- a source page's toggle with its own reset icon, drawn the same way
			local sroot = tree()
			local item = sroot.Unitframes.args.all.args.general.args.parts.args.healthtext
			local sm = OM.MenuRoot(item)
			local scontent = CreateFrame('Frame', nil, UIParent)
			scontent:SetSize(376, 900)
			local sbody = OB.New(scontent, sm, nil, 376)
			sbody:SetWidth(376, true)
			sbody:Draw(OM.BuildView(sm, OM.MENU_KEY).sections)
			for _, c in ipairs(sbody.cells) do
				if c.row.type == 'toggle' then OM.Set(sm, c.row, not OM.Get(sm, c.row)) end
			end
			sbody:Release()
			sbody = OB.New(scontent, sm, nil, 376)
			sbody:SetWidth(376, true)
			sbody:Draw(OM.BuildView(sm, OM.MENU_KEY).sections)
			scontent:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
			local icons = 0
			for _, c in ipairs(sbody.cells) do
				local icon = c.frame.defaultReset
				if c.row.type == 'toggle' and icon and icon:IsShown() then
					icons = icons + 1
					-- no rect at draw: the control is reckoned at the cell's edge (its art is not known)
					check(icon:GetRight() <= c.widget.frame:GetLeft() - 6, look .. ' ' .. tostring(c.row.key) .. ': the icon is clear of the control frame')
				end
			end
			check(icons > 0, look .. ': icons: ' .. icons)
			sbody:Release()
		end)
	end
end)
