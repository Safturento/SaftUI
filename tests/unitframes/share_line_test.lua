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
