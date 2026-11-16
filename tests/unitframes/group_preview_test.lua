-- A group's previews (Test mode) read the stored values the part rows' menus write, and the shared page
-- walk's mirror skip (shared_world.lua's SW.rows) counts a part's settings once.
--
-- Real: the shared world (shared_world.lua: uf_world.lua's module with unitframes.lua, the group files,
-- grouppreview.lua, config/parts.lua, config.lua and every element file) and the options model, which
-- reads and writes a part's menu rows as the window does. Stand-in: oUF as far as the previews use it,
-- and a frame for each group header and holder.
local SW = load_test_file('unitframes/shared_world.lua')
local st, UF, P = SW.world()
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
local OM = st.OptionsModel

local function tree() return { Unitframes = UF:GetConfigTable() } end

-- The part's menu row key, written as the menu writes it.
local function set_menu(unit, part, key, value)
	local root = tree()
	local item = root.Unitframes.args[unit].args.general.args.parts.args[part]
	local menuRoot = OM.MenuRoot(item)
	local row = { path = { OM.MENU_KEY, key }, option = item.menu.args[key], type = item.menu.args[key].type, key = key }
	OM.Set(menuRoot, row, value)
end

local function preview_names(group)
	local out = {}
	for i, frame in ipairs(UF.previews[group].frames) do
		if frame:IsVisible() then out[#out + 1] = frame.Name:GetText() end
	end
	return out
end

for _, unit in ipairs({ 'party', 'raid10', 'boss' }) do
	test(unit .. "'s previews read its stored values: a Name part setting set through the menu shows after UpdateConfig", function()
		-- The real header is not up: the previews show.
		if UF.groups[unit] then UF.groups[unit]:Hide() end
		if unit == 'boss' then UF.units.boss = {} end
		UF:SetGroupTestMode(unit, true)
		local before = preview_names(unit)
		check(#before > 0, 'previews are up')
		local config = P[unit].name
		eq(config.allCaps, false, 'all caps starts off')
		set_menu(unit, 'name', 'allCaps', true)
		eq(config.allCaps, true, 'the menu wrote the unit\'s own saved value')
		UF:UpdateConfig(unit, 'Name')
		UF:UpdateGroupPreview(unit)
		local after = preview_names(unit)
		check(#after > 0, 'still up')
		for i, text in ipairs(after) do
			eq(text, (before[i] or ''):upper(), 'preview ' .. i .. ' in capitals')
		end
		-- And its reset puts the saved value back.
		set_menu(unit, 'name', 'allCaps', false)
		UF:UpdateGroupPreview(unit)
		eq(preview_names(unit)[1], before[1], 'back as it was')
		UF:SetGroupTestMode(unit, false)
	end)
end

-- N3 of Task 3's re-review: SW.rows counts a text part's settings once, at the part's menu; the Health text
-- tab's mirror group is skipped. Without the skip, each saved path of Health text would be listed twice.
test("SW.rows counts a text part's settings once: the mirror on the Health tab is skipped", function()
	for _, unit in ipairs({ 'player', 'party' }) do
		local seen = {}
		for _, row in ipairs(SW.rows(UF, unit)) do
			if row.path and row.path:find('^health%.text%.') then
				seen[row.path] = (seen[row.path] or 0) + 1
			end
		end
		local n = 0
		for path, count in pairs(seen) do
			n = n + 1
			eq(count, 1, unit .. ': ' .. path .. ' is one row')
		end
		check(n > 0, unit .. ': Health text has rows')
	end
end)
