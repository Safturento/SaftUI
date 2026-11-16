-- Accent readers in the bags that no other test pinned at an accent that is not
-- the default (color roles, Task 2's review): a bag bar slot's hover. The
-- selected bank window's border is pinned in theme_test.lua, the drop line in
-- categories_drag_test.lua and the rule editor's check mark in
-- rule_editor_test.lua.
--
-- Real: container_helpers.lua's world and containers/bag.lua, whose file-local
-- RestyleBagSlot is taken from the upvalues of INV:InitializePlayerBagSlots.
local H = load_test_file('bags/container_helpers.lua')
local INV = H.views_world('forever')
local st = SaftUI
load_saftui('SaftUI-Bags/containers/bag.lua')

local function up(fn, name)
	for i = 1, 40 do
		local n, v = debug.getupvalue(fn, i)
		if not n then return nil end
		if n == name then return v end
	end
end

test("a bag bar slot's hover follows the accent (T+ of it), at an accent that is not the default", function()
	local restyle = up(INV.InitializePlayerBagSlots, 'RestyleBagSlot')
	check(restyle, 'the restyle function')
	local slot = CreateFrame('Button', nil, UIParent)
	slot.icon = slot:CreateTexture(nil, 'BORDER')
	slot:SetNormalTexture(st.BLANK_TEX)
	slot:SetHighlightTexture(st.BLANK_TEX)
	slot:SetPushedTexture(st.BLANK_TEX)
	-- an icon of the states helper, as InitializePlayerBagSlots registers it
	st:AddStates(slot, 'icon', {
		pieces = { hover = slot:GetHighlightTexture(), pushed = slot:GetPushedTexture() },
		blizzard = function() return false end,
	})
	st.config.profile.theme.accent:SetRGB(0.9, 0.2, 0.4)
	restyle(slot)
	local function text(t) return string.format('%.2f,%.2f,%.2f,%.2f', t[1], t[2], t[3], t[4]) end
	local function hover() local r, g, b, a = slot:GetHighlightTexture():GetVertexColor(); return text({ r, g, b, a }) end
	eq(hover(), text({ st:StateColor('hover') }), 'T+ of the accent, set again whenever Blizzard rewrites the texture')
	-- A pick reaches it at once (the helper's pass of the Accent), no restyle.
	st.config.profile.theme.accent:SetRGB(0.2, 0.9, 0.5)
	st:ColorChanged('accent')
	eq(hover(), text({ st:StateColor('hover') }), 'the accent that was picked')
	st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
end)
