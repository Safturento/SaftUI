-- A drawn frame as text, for the theme engine's k = 1 guard
-- (tests/core/theme_scale_test.lua): every number the engine hands the game
-- for a frame drawn as a kind, to the last digit: the backdrop (edge, insets,
-- colors, frame level), where it sits outside its owner, Thick's strips (their
-- size, anchors, texture, draw layer and color) and every shown piece of
-- Blizzard art (its atlas or file, size, anchors, draw layer, color and alpha).
-- Loaded with local S = load_test_file('core/theme_snapshot.lua') (no
-- globals). Not a test.
--
-- The golden (theme_k1_golden.lua) was generated from the engine as it was at
-- 8a4ad66f, before the scale work, by running S.all(client) in a scratch copy of
-- that commit (git archive 8a4ad66f), never from the engine being tested.
--
-- S.kinds(st) -> st.THEME_KINDS sorted.
-- S.draw(st, how, kind) -> an owner drawn 'template' (st:SetTemplate on the
--   frame) or 'backdrop' (st:SetBackdrop: the backdrop sits outside it).
-- S.read(st, owner, how, extra) -> the text; extra names more regions.
-- S.all(st, client) -> { [key] = text }: every kind under Thick, Thin and
--   Blizzard drawn both ways, then again after a redraw from another theme; a
--   backdrop in a table (st:SetBackdropIn), a drawn border color, a button as
--   host, a draw of None, and the close button.
local S = {}

S.KINDS = {}
function S.kinds(st)
	local list = {}
	for kind in pairs(st.THEME_KINDS) do list[#list + 1] = kind end
	table.sort(list)
	S.KINDS = list
	return list
end

local function num(v)
	if v == nil then return 'nil' end
	return string.format('%.17g', v)
end

local function rgba(...)
	local out = {}
	for i = 1, select('#', ...) do out[i] = num((select(i, ...))) end
	return table.concat(out, ',')
end

local function points(region, names)
	local out = {}
	for i = 1, region:GetNumPoints() do
		local p, rel, relPoint, x, y = region:GetPoint(i)
		out[#out + 1] = ('%s>%s:%s %s,%s'):format(p, names[rel] or '?', relPoint, num(x), num(y))
	end
	return table.concat(out, ' | ')
end

function S.draw(st, how, kind)
	local owner = st:CreateFrame('Frame', nil, UIParent)
	owner:SetSize(36, 36)
	owner:SetPoint('CENTER')
	if how == 'template' then
		st:SetTemplate(owner, 'theme', 'theme', kind)
	else
		st:SetBackdrop(owner, 'theme', 'theme', kind)
	end
	return owner
end

local function backdrop_info(f)
	local info = f.backdropInfo
	if not info then return 'no backdrop' end
	local ins = info.insets or {}
	local bg, border = 'none', 'none'
	if f.GetBackdropColor and f:GetBackdropColor() then bg = rgba(f:GetBackdropColor()) end
	if f.GetBackdropBorderColor and f:GetBackdropBorderColor() then border = rgba(f:GetBackdropBorderColor()) end
	return ('edge %s edgeFile %s bgFile %s insets %s,%s,%s,%s level %s fill %s edgecolor %s'):format(
		num(info.edgeSize), tostring(info.edgeFile ~= nil), tostring(info.bgFile ~= nil),
		num(ins.left), num(ins.right), num(ins.top), num(ins.bottom), tostring(f:GetFrameLevel()), bg, border)
end

local STRIPS = { 'LEFT', 'RIGHT', 'TOP', 'BOTTOM' }

local function strips(f, names)
	local out = {}
	if not f.altborder then return 'no strips' end
	for _, key in ipairs(STRIPS) do
		local line = f.altborder[key]
		local layer, sub = line:GetDrawLayer()
		out[#out + 1] = ('%s %s w%s h%s tex %s layer %s/%s color %s %s'):format(key, line:IsShown() and 'shown' or 'hidden',
			num(line:GetWidth()), num(line:GetHeight()), tostring(line:GetTexture()), tostring(layer), tostring(sub),
			rgba(line:GetVertexColor()), points(line, names))
	end
	return table.concat(out, '; ')
end

local function art_names(st, f, names)
	local art = st.ThemeArt.Get(f)
	if not art then return end
	for _, setName in ipairs({ 'pieces', 'over' }) do
		for key, piece in pairs(art[setName]) do names[piece] = setName .. ':' .. key end
	end
	if art.own then names[art.own] = 'own' end
end

local function piece_text(label, piece, names)
	local layer, sub = piece:GetDrawLayer()
	return ('%s w%s h%s %s layer %s/%s color %s alpha %s %s'):format(label, num(piece:GetWidth()), num(piece:GetHeight()),
		tostring(piece:GetAtlas() or piece:GetTexture()), tostring(layer), tostring(sub), rgba(piece:GetVertexColor()),
		num(piece:GetAlpha()), points(piece, names))
end

local function pieces(st, f, names)
	local art = st.ThemeArt.Get(f)
	if not art then return 'no art' end
	local out = {}
	for _, setName in ipairs({ 'pieces', 'over' }) do
		local keys = {}
		for key in pairs(art[setName]) do keys[#keys + 1] = key end
		table.sort(keys)
		for _, key in ipairs(keys) do
			local piece = art[setName][key]
			if piece:IsShown() then out[#out + 1] = piece_text(setName .. '.' .. key, piece, names) end
		end
	end
	if art.own then
		out[#out + 1] = (art.own:IsShown() and 'own shown ' or 'own hidden ') .. piece_text('own', art.own, names)
	end
	return #out > 0 and table.concat(out, '; ') or 'no pieces shown'
end

-- The text for a drawn owner: its backdrop (the owner's, or the one behind
-- it), that backdrop's anchors to the owner, Thick's strips and the art.
function S.read(st, owner, how, extra)
	local target = how == 'template' and owner or owner.backdrop
	local names = { [owner] = 'owner', [target] = 'target' }
	for region, name in pairs(extra or {}) do names[region] = name end
	if target then art_names(st, target, names) end
	local parts = {
		'backdrop ' .. (target and backdrop_info(target) or 'none'),
		'inset ' .. num(st:DrawnInset(owner)),
	}
	if target then
		if how ~= 'template' then parts[#parts + 1] = 'at ' .. points(target, names) end
		parts[#parts + 1] = 'strips ' .. strips(target, names)
		parts[#parts + 1] = 'art ' .. pieces(st, target, names)
	end
	return table.concat(parts, ' / ')
end

local THEMES = { 'thick', 'thin', 'blizzard' }
local NEXT = { thick = 'blizzard', thin = 'thick', blizzard = 'thin' }

-- Every row, for the world as it is (a fresh T.client).
function S.all(st, client)
	local rows = {}
	local kinds = S.kinds(st)
	for _, theme in ipairs(THEMES) do
		st.config.profile.theme.name = theme
		local made = {}
		for _, how in ipairs({ 'template', 'backdrop' }) do
			for _, kind in ipairs(kinds) do
				local owner = S.draw(st, how, kind)
				made[#made + 1] = { how = how, kind = kind, owner = owner }
				rows[('%s %s %s %s'):format(client, theme, how, kind)] = S.read(st, owner, how)
			end
		end

		-- A backdrop in the caller's table (a skinned frame), a drawn border color,
		-- a button as the host of a ring, and a draw of None.
		local backdrops = setmetatable({}, { __mode = 'k' })
		for _, kind in ipairs({ 'slot', 'small', 'panel', 'action' }) do
			local frame = st:CreateFrame('Frame', nil, UIParent)
			frame:SetSize(36, 36)
			frame:SetPoint('CENTER')
			local bd = st:SetBackdropIn(backdrops, frame, 'theme', 'theme', kind)
			local text = bd.backdropInfo and backdrop_info(bd) or 'no backdrop'
			local names = { [frame] = 'owner', [bd] = 'target' }
			art_names(st, bd, names)
			rows[('%s %s in %s'):format(client, theme, kind)] = ('%s / at %s / strips %s / art %s'):format(
				text, points(bd, names), strips(bd, names), pieces(st, bd, names))
			made[#made + 1] = { in_frame = frame, in_backdrop = bd, kind = kind, backdrops = backdrops }
		end
		for _, kind in ipairs({ 'slot', 'action', 'small', 'aura', 'panel' }) do
			local owner = S.draw(st, 'backdrop', kind)
			st:SetBorderColor(owner.backdrop, 1, 0, 0, 1)
			rows[('%s %s bordercolor %s'):format(client, theme, kind)] = S.read(st, owner, 'backdrop')
			st:SetBorderColor(owner.backdrop)
			rows[('%s %s bordercolor off %s'):format(client, theme, kind)] = S.read(st, owner, 'backdrop')
			made[#made + 1] = { how = 'backdrop', kind = kind, owner = owner, tinted = true }
		end
		do
			local button = CreateFrame('Button', nil, UIParent)
			button:SetSize(36, 36)
			button:SetPoint('CENTER')
			local frame = st:CreateFrame('Frame', nil, button)
			frame:SetSize(36, 36)
			frame:SetPoint('CENTER')
			st:SetTemplate(frame, 'theme', 'theme', 'action', button)
			st:SetBorderColor(frame, 0, 1, 0, 1)
			local names = { [frame] = 'owner', [button] = 'host' }
			art_names(st, frame, names)
			rows[('%s %s host'):format(client, theme)] = S.read(st, frame, 'template', { [button] = 'host' })
		end
		do
			local none = st:CreateFrame('Frame', nil, UIParent)
			none:SetSize(36, 36)
			none:SetPoint('CENTER')
			st:SetTemplate(none, 'none', 'theme', 'panel')
			rows[('%s %s none'):format(client, theme)] = S.read(st, none, 'template')
		end
		do
			local panel = st:CreateFrame('Frame', nil, UIParent)
			panel:SetSize(200, 100)
			panel:SetPoint('CENTER')
			local close = st:CreateCloseButton(panel)
			local out = close.outline
			rows[('%s %s close'):format(client, theme)] = ('%s / outline %s at %s / icon %s'):format(
				backdrop_info(close), backdrop_info(out), points(out, { [close] = 'close' }), points(close.icon, { [close] = 'close' }))
		end

		-- Everything again after a redraw from another theme and back.
		st.config.profile.theme.name = NEXT[theme]
		st:RedrawThemed()
		st.config.profile.theme.name = theme
		st:RedrawThemed()
		for _, m in ipairs(made) do
			if m.owner and not m.tinted then
				rows[('%s %s redraw %s %s'):format(client, theme, m.how, m.kind)] = S.read(st, m.owner, m.how)
			end
		end
	end
	return rows
end

return S
