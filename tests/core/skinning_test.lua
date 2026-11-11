-- SaftUI-Core/skinning.lua's icon crop: st:IconTexCoords, the tex coords
-- SaftUI cuts an icon of a size to at a trim, and st:SkinIcon, which crops
-- the icons SaftUI skins with them. The Icon zoom preview in /sui (Global
-- Settings, General) draws with st:IconTexCoords, so the two must agree.
--
-- Real: skinning.lua, and Core's helpers it's loaded with (load_core_helpers)
-- for the profile's misc.icon_trim. The icons are stub textures, sized as the
-- game would size them.

load_core_helpers()
local st = SaftUI

-- Numbers as text, rounded so float drift doesn't decide a check.
local function text(...)
	local out = {}
	for i = 1, select('#', ...) do out[i] = string.format('%.4f', (select(i, ...))) end
	return table.concat(out, ',')
end

-- left, right, top, bottom as the eight corners GetTexCoord gives.
local function corners(left, right, top, bottom)
	return text(left, top, left, bottom, right, top, right, bottom)
end

local holder = CreateFrame('Frame', nil, UIParent)

local function icon(width, height)
	local texture = holder:CreateTexture(nil, 'ARTWORK')
	texture:SetSize(width, height)
	return texture
end

test('IconTexCoords: a square icon, or one with no size, loses trim off each edge', function()
	eq(text(st:IconTexCoords(0.1, 36, 36)), text(0.1, 0.9, 0.1, 0.9), 'square')
	eq(text(st:IconTexCoords(0.1)), text(0.1, 0.9, 0.1, 0.9), 'no size')
	eq(text(st:IconTexCoords(0.1, 0, 0)), text(0.1, 0.9, 0.1, 0.9), 'no size yet (0 by 0)')
	eq(text(st:IconTexCoords(0, 36, 36)), text(0, 1, 0, 1), 'no trim: the whole art')
end)

test("IconTexCoords: a wide or tall icon's art is cut to its shape around the middle, then trimmed", function()
	-- 40 by 20: the art's middle half of its height, less 0.1 of the art off each edge.
	eq(text(st:IconTexCoords(0.1, 40, 20)), text(0.1, 0.9, 0.35, 0.65), 'wide')
	eq(text(st:IconTexCoords(0.1, 20, 40)), text(0.35, 0.65, 0.1, 0.9), 'tall')
	eq(text(st:IconTexCoords(0, 30, 10)), text(0, 1, 1 / 3, 2 / 3), 'wide, no trim')
end)

test("SkinIcon crops with IconTexCoords: the profile's zoom, a custom trim, an anchor frame's size", function()
	local trim = st.config.profile.misc.icon_trim
	eq(trim, 0.065, 'the default zoom')
	for _, size in ipairs({ { 36, 36 }, { 40, 20 }, { 20, 40 }, { 0, 0 } }) do
		local w, h = size[1], size[2]
		local texture = icon(w, h)
		st:SkinIcon(texture)
		eq(text(texture:GetTexCoord()), corners(st:IconTexCoords(trim, w, h)), w .. 'x' .. h)
		texture = icon(w, h)
		st:SkinIcon(texture, 0.2)
		eq(text(texture:GetTexCoord()), corners(st:IconTexCoords(0.2, w, h)), w .. 'x' .. h .. ', a custom trim')
	end
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(50, 30)
	local texture = icon(10, 10)
	st:SkinIcon(texture, nil, frame)
	eq(text(texture:GetTexCoord()), corners(st:IconTexCoords(trim, 50, 30)), "sized to the anchor frame, cut to its shape")

	-- Another zoom in the profile reaches both.
	st.config.profile.misc.icon_trim = 0.15
	texture = icon(36, 36)
	st:SkinIcon(texture)
	eq(text(texture:GetTexCoord()), corners(st:IconTexCoords(0.15, 36, 36)), 'the zoom set now')
	eq(text(texture:GetTexCoord()), corners(0.15, 0.85, 0.15, 0.85), 'which is 0.15 off each edge')
	st.config.profile.misc.icon_trim = trim
end)

test('SkinIcon: an icon whose size is secret is cut square, as before', function()
	-- A secret value, as the game gives an icon in a restricted frame (an aura
	-- container); issecretvalue is told to recognise it for this case.
	local secret = newproxy(false)
	local real = issecretvalue
	issecretvalue = function(v) return v == secret or real(v) end
	local texture = icon(40, 20)
	texture.GetSize = function() return secret, secret end
	st:SkinIcon(texture, 0.1)
	issecretvalue = real
	eq(text(texture:GetTexCoord()), corners(0.1, 0.9, 0.1, 0.9), 'trim off each edge, not cut to a shape')
end)

test('SkinIcon: a crop the game resets is put back, with Icon zoom at 0 too, and nothing is written onto the icon', function()
	-- Blizzard's SetItemButtonTexture resets an icon to full tex coords each
	-- time it sets a texture; SaftUI's hook puts its crop back.
	local texture = icon(36, 36)
	st:SkinIcon(texture, 0.1)
	texture:SetTexCoord(0, 1, 0, 1)
	eq(text(texture:GetTexCoord()), corners(0.1, 0.9, 0.1, 0.9), 'the crop is put back after a reset')
	texture:SetTexCoord(0.2, 0.8, 0.2, 0.8)
	eq(text(texture:GetTexCoord()), corners(0.2, 0.8, 0.2, 0.8), 'any other tex coords are left alone')

	-- Icon zoom 0: the crop is the full texture. Skinning again (a theme
	-- switch restyles every icon) and a reset must not re-enter the hook
	-- forever (2026-11-11 in game: "C stack overflow" in the hook).
	local full = icon(36, 36)
	local ok, err = pcall(function()
		st:SkinIcon(full, 0)
		st:SkinIcon(full, 0)
		full:SetTexCoord(0, 1, 0, 1)
	end)
	check(ok, 'no stack overflow at zoom 0: ' .. tostring(err))
	eq(text(full:GetTexCoord()), corners(0, 1, 0, 1), 'the full texture')

	-- A zoom change after the hook is in reaches it.
	st:SkinIcon(full, 0.15)
	full:SetTexCoord(0, 1, 0, 1)
	eq(text(full:GetTexCoord()), corners(0.15, 0.85, 0.15, 0.85), 'the new zoom is put back after a reset')

	-- What the hook needs is kept in SaftUI's own table, not on the icon,
	-- which is often Blizzard's (.agents/taint.md).
	eq(rawget(texture, '__stTexCoord'), nil, 'no crop written onto the icon')
	eq(rawget(texture, '__stTexCoordHooked'), nil, 'no hooked flag written onto the icon')
end)
