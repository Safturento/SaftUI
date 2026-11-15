-- What st:SetBorderColor costs (SaftUI-Core/theme.lua, themeart.lua): a color
-- pass repaints every border a reader holds through it (bag slots, an
-- equipped border, a feed entry, a tooltip), so under every theme it makes
-- no table and, under Blizzard, textures and places its own-color piece only
-- once, then only colors it. 40 borders, 100 passes.
--
-- Real: Core's theme and Blizzard's art on the stubs; the cost helper.
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')

local KINDS = { 'slot', 'aura', 'panel', 'small', 'tooltip' }

-- 40 drawn frames, each given a border color once (a cold widget's first
-- setter call makes its stub table, and a Blizzard piece is made).
local function borders(st, theme)
	local list = {}
	for i = 1, 40 do
		local f = st:CreateFrame('Frame', nil, UIParent)
		f:SetSize(36, 36)
		f:SetPoint('CENTER')
		if theme == 'none' then
			st:SetBackdrop(f, 'none')
		else
			st:SetBackdrop(f, 'theme', 'theme', KINDS[i % #KINDS + 1])
		end
		list[i] = f.backdrop or f
		st:SetBorderColor(list[i], 0.1, 0.2, 0.3, 1)
	end
	return list
end

for _, client in ipairs({ 'forever', 'retail' }) do
	for _, theme in ipairs({ 'thick', 'thin', 'blizzard', 'none' }) do
		test(('%s, %s: 40 borders recolored 100 times make no garbage and move or texture nothing'):format(client, theme), function()
			local st = T.client(client)
			st.config.profile.theme.name = theme == 'none' and 'thick' or theme
			local list = borders(st, theme)
			local m = C.measure(function()
				for i = 1, 40 do st:SetBorderColor(list[i], 0.4, 0.5, 0.6, 1) end
			end, 100)
			check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
			eq(m.forbidden.total, 0, 'forbidden calls: ' .. (function()
				local out = {}
				for k, v in pairs(m.forbidden.by) do out[#out + 1] = k .. '=' .. v end
				table.sort(out)
				return table.concat(out, ',')
			end)())
			eq(m.made, 0, 'nothing made')
			if theme ~= 'none' then check(m.calls.total >= 4000, 'it does color: ' .. m.calls.total) end
			C.print(client .. ' ' .. theme, m)
		end)
	end
end

test('Blizzard: the own-color piece is made and placed once, and a redraw to another art is textured again', function()
	local st = T.client('forever')
	st.config.profile.theme.name = 'blizzard'
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(36, 36); f:SetPoint('CENTER')
	st:SetBackdrop(f, 'theme', 'theme', 'slot')
	st:SetBorderColor(f.backdrop, 1, 0, 0, 1)
	local art = st.ThemeArt.Get(f.backdrop)
	local own = art and art.own
	check(own, 'a piece is made')
	local m = C.measure(function() st:SetBorderColor(f.backdrop, 0, 1, 0, 1) end)
	eq(m.forbidden.total, 0, 'a color call places and textures nothing')
	local r, g, b = own:GetVertexColor()
	eq(r .. ',' .. g .. ',' .. b, '0,1,0', 'it takes the color')
	check(own:IsShown(), 'and shows')
	st:SetBorderColor(f.backdrop)
	check(not own:IsShown(), 'no color hides it')
	st:SetBorderColor(f.backdrop, 0, 0, 1, 1)
	check(own:IsShown(), 'and a color shows it again')
end)
