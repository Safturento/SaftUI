-- The bag window's search box: it is one line and skinned once, as
-- st:StyleEditBox draws it (INV:InitializeSearch), and a bank eye toggle
-- re-applies the search to the combined bank's items (INV:UpdateContainerBagIds).
local H = load_test_file('bags/container_helpers.lua')

local INV, W

local function names_alpha(container)
	local out = {}
	for _, category in pairs(container.categories) do
		for _, slot in ipairs(category.slots) do
			if slot:IsShown() then out[#out + 1] = slot.info.name .. '=' .. string.format('%.1f', slot:GetAlpha()) end
		end
	end
	table.sort(out)
	return table.concat(out, ' ')
end

test("a bank eye toggle re-applies the bag window's search to the combined bank's items", function()
	INV, W = H.views_world('retail')
	load_saftui('SaftUI-Bags/containers/combinedbank.lua')
	W.bag(0, 20, 'Backpack')
	local bankTab, warbandTab = INV.bagIds.bank[1], INV.bagIds.warband[1]
	W.bag(bankTab, 10, 'Bank 1'); W.bag(warbandTab, 20, 'Warband 1')
	W.put(bankTab, 1, W.item(701, 'Gold Bar', 'Trade Goods', 30))
	W.put(warbandTab, 1, W.item(702, 'Silver Bar', 'Trade Goods', 20))
	INV.config.stackItems = false
	INV.config.combinedbank.view = 'multibag'
	local bag = H.window('bag')
	local search = H.search(bag)
	local c = H.window('combinedbank')
	c:Show()
	INV:UpdateContainer('combinedbank', true)
	search:SetText('gold')
	eq(names_alpha(c), 'Gold Bar=1.0 Silver Bar=0.1', 'the search lights the matching item')
	-- An item that arrived since the last search change sits on a slot no
	-- search has dimmed: a toggle that lays the window out again must dim it.
	W.put(bankTab, 2, W.item(703, 'Iron Bar', 'Trade Goods', 5))
	INV:UpdateContainerBagIds('warband', false)
	eq(names_alpha(c), 'Gold Bar=1.0 Iron Bar=0.1', 'the warband eye closed: the new item is dimmed')
	INV:UpdateContainerBagIds('warband', true)
	eq(names_alpha(c), 'Gold Bar=1.0 Iron Bar=0.1 Silver Bar=0.1', 'opened again: the search still holds')
	eq(#take_errors(), 0, 'no errors')
end)

test("the bag window's search box is one line, skinned once, in SaftUI's look", function()
	INV, W = H.views_world('forever')
	load_saftui('SaftUI-Core/Widgets/editbox.lua')
	load_saftui('SaftUI-Bags/search.lua')
	local container = H.window('bag')
	local st = SaftUI
	-- InputBoxTemplate isn't in the stubs: a plain edit box with the text the
	-- template gives, and a recorder of SetMultiLine (the game's multi-line
	-- box is the one that takes Enter as a new line).
	local multiline = false
	local createFrame = CreateFrame
	_G.CreateFrame = function(frameType, name, parent, template, ...)
		if template ~= 'InputBoxTemplate' then return createFrame(frameType, name, parent, template, ...) end
		local box = createFrame(frameType, name, parent, nil, ...)
		box:CreateFontString(nil, 'OVERLAY')
		box.SetMultiLine = function(_, on) multiline = on end
		return box
	end
	-- Every skin the box gets.
	local real_skin, real_style = st.SkinEditBox, st.StyleEditBox
	local skins, styles = 0, {}
	st.SkinEditBox = function(self, ...) skins = skins + 1; return real_skin(self, ...) end
	st.StyleEditBox = function(self, box, theme, background, font)
		styles[#styles + 1] = tostring(theme) .. '/' .. tostring(background)
		return real_style(self, box, theme, background, font)
	end
	INV:InitializeSearch(container)
	_G.CreateFrame = createFrame
	st.SkinEditBox, st.StyleEditBox = real_skin, real_style
	eq(multiline, false, 'one line: Enter is not a new line')
	eq(skins, 1, 'skinned once, inside st:CreateEditBox')
	eq(table.concat(styles, ' '), 'nil/nil theme/theme', "the skin's default look, then SaftUI's theme and background by st:StyleEditBox, with no second skin")
	check(container.search ~= nil and container.search:GetParent() == container.footer, "it is the window's search box, in the footer")
	eq(container.search:GetHeight(), 20, 'twenty tall')
	eq(#take_errors(), 0, 'no errors')
end)
