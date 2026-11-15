-- A drawn frame as text, for the theme engine's k = 1 guard
-- (tests/core/theme_scale_test.lua): every number the engine hands the game
-- for a frame drawn as a kind, to the last digit. Loaded with
-- local S = load_test_file('core/theme_snapshot.lua') (no globals). Not a test.
--
-- S.draw(st, how, kind) -> the frame drawn on a 36 x 36 owner (how 'template':
-- st:SetTemplate on the frame itself, 'backdrop': st:SetBackdrop, so the
-- backdrop sits outside its owner), and S.read(st, owner, how) -> the text.
-- S.KINDS lists every kind (st.THEME_KINDS), sorted.
local S = {}

S.KINDS = {}
-- Filled from st.THEME_KINDS by S.kinds(st).
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

local function points(region, names)
	local out = {}
	for i = 1, region:GetNumPoints() do
		local p, rel, relPoint, x, y = region:GetPoint(i)
		out[#out + 1] = ('%s>%s:%s %s,%s'):format(p, names[rel] or '?', relPoint, num(x), num(y))
	end
	return table.concat(out, ' | ')
end

-- The frame drawn, as the engine hands it to the game.
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
	return ('edge %s edgeFile %s insets %s,%s,%s,%s'):format(
		num(info.edgeSize), tostring(info.edgeFile ~= nil), num(ins.left), num(ins.right), num(ins.top), num(ins.bottom))
end

local STRIPS = { 'LEFT', 'RIGHT', 'TOP', 'BOTTOM' }

local function strips(f, names)
	local out = {}
	if not f.altborder then return 'no strips' end
	for _, key in ipairs(STRIPS) do
		local line = f.altborder[key]
		out[#out + 1] = ('%s %s w%s h%s %s'):format(key, line:IsShown() and 'shown' or 'hidden',
			num(line:GetWidth()), num(line:GetHeight()), points(line, names))
	end
	return table.concat(out, '; ')
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
			if piece:IsShown() then
				out[#out + 1] = ('%s.%s w%s h%s %s'):format(setName, key, num(piece:GetWidth()), num(piece:GetHeight()), points(piece, names))
			end
		end
	end
	return #out > 0 and table.concat(out, '; ') or 'no pieces shown'
end

-- The text for a drawn owner: its backdrop (the owner's, or the one behind
-- it), that backdrop's anchors to the owner, Thick's strips and the shown art.
function S.read(st, owner, how)
	local target = how == 'template' and owner or owner.backdrop
	local names = { [owner] = 'owner', [target] = 'target' }
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

return S
