-- The role corner (elements/indicators.lua's GroupRoleIndicator) and the group
-- test previews' corners (grouppreview.lua) read Colors > Roles, not Colors >
-- Text; and UF:UpdateColors leaves oUF its own role colors.
--
-- The world is boss_preview_test.lua's: real Core and its defaults, the unit
-- frames' defaults, unitframes.lua, the group files, the elements, with oUF
-- stood in for by its colors table (uf_world.lua).
local T = load_test_file('lib/theme_helpers.lua')
local UW = load_test_file('unitframes/uf_world.lua')
local st, UF, P = UW.world()
local colors = st.config.profile.colors

local ROLES = { TANK = T.rgb(0, 0.68, 0.94), HEALER = T.rgb(60/255, 240/255, 60/255), DAMAGER = T.rgb(220/255, 100/255, 100/255) }

local function set(color, r, g, b) color.r, color.g, color.b = r, g, b end

-- A party member's frame with its role corner, built by the real constructor.
local member = UW.unit_frame('SaftUI_RoleCornerTest', 'party', { 'GroupRoleIndicator' })
member.__unit = 'party1'
local corner = member.GroupRoleIndicator

-- The corner after oUF's update for a unit with this role.
local function update(role)
	_G.UnitGroupRolesAssigned = function() return role end
	corner:PostUpdate(role)
	return T.rgb(corner:GetVertexColor())
end

test('the role corner takes Roles: Tank, Healer, and Damage with Show damage dealers', function()
	corner.config.showDps = true
	eq(update('TANK'), ROLES.TANK, 'Tank'); eq(update('HEALER'), ROLES.HEALER, 'Healer')
	eq(update('DAMAGER'), ROLES.DAMAGER, 'Damage')
	eq(update(nil), ROLES.DAMAGER, 'a unit with no role, as Damage'); check(corner:IsShown(), 'shown with Show damage dealers')
	corner.config.showDps = false
	update('DAMAGER'); check(not corner:IsShown(), 'a damage dealer hidden without it')

	-- Text > Blue, Green and Red no longer reach any corner.
	local saved = {}
	for _, key in ipairs({ 'blue', 'green', 'red' }) do
		saved[key] = { colors.text[key]:GetRGB() }
		set(colors.text[key], 0, 0, 0)
	end
	corner.config.showDps = true
	eq(update('TANK'), ROLES.TANK, 'Tank, with Text > Blue changed')
	eq(update('HEALER'), ROLES.HEALER, 'Healer, with Text > Green changed')
	eq(update('DAMAGER'), ROLES.DAMAGER, 'Damage, with Text > Red changed')
	for key, rgb in pairs(saved) do set(colors.text[key], unpack(rgb)) end

	-- A changed Roles color is the next update's.
	local tank = { colors.roles.TANK:GetRGB() }
	set(colors.roles.TANK, 0.2, 0.3, 0.4)
	eq(update('TANK'), T.rgb(0.2, 0.3, 0.4), 'a changed Roles > Tank')
	set(colors.roles.TANK, unpack(tank))
end)

test("the party preview's corners take Roles too", function()
	local player = CreateFrame('Frame', 'SaftUI_Player', UIParent)
	player:SetPoint('CENTER'); player:SetSize(300, 40)
	UF.groups = { party = CreateFrame('Frame', 'SaftUI_Party', UIParent) }
	UF.groups.party:Hide()
	UF.holders.party = CreateFrame('Frame', 'SaftUI_PartyHolder', UIParent)
	UF.holders.party:SetPoint('CENTER')
	local button = UW.unit_frame('SaftUI_PartyUnitButton1', 'party', { 'Health', 'Power', 'GroupRoleIndicator' }, UF.groups.party)
	button.is_group_unit = true
	button:SetPoint('CENTER', UIParent)
	UF:UpdateUnitFrame(button)
	UF.testGroups.party = true

	local saved = {}
	for _, key in ipairs({ 'blue', 'green', 'red' }) do
		saved[key] = { colors.text[key]:GetRGB() }
		set(colors.text[key], 0, 0, 0)
	end
	UF:UpdateGroupPreview('party')
	local frames = UF.previews.party and UF.previews.party.frames or {}
	-- The previews' members, in order: a tank, a healer, then damage dealers.
	local expected = { 'TANK', 'HEALER', 'DAMAGER', 'DAMAGER' }
	check(#frames >= #expected, 'the previews show')
	for i, role in ipairs(expected) do
		eq(T.rgb(frames[i].GroupRoleIndicator:GetVertexColor()), ROLES[role], 'preview ' .. i .. ': ' .. role)
	end
	for key, rgb in pairs(saved) do set(colors.text[key], unpack(rgb)) end

	set(colors.roles.HEALER, 0.2, 0.3, 0.4)
	UF:UpdateGroupPreview('party')
	eq(T.rgb(UF.previews.party.frames[2].GroupRoleIndicator:GetVertexColor()), T.rgb(0.2, 0.3, 0.4), 'a changed Roles > Healer')
	set(colors.roles.HEALER, 60/255, 240/255, 60/255)
	eq(#take_errors(), 0, 'no errors')
end)

test('UF:UpdateColors leaves oUF its own role colors', function()
	-- oUF has no role colors of its own; the profile's are not handed to it.
	UF:UpdateColors()
	check(UF.oUF.colors.roles ~= colors.roles, "oUF's colors.roles is not the profile's Roles")
	local roles = UF.oUF.colors.roles
	set(colors.roles.TANK, 0.5, 0.5, 0.5)
	UF:UpdateColors()
	check(UF.oUF.colors.roles == roles, 'and a Roles change leaves it as it was')
	set(colors.roles.TANK, 0, 0.68, 0.94)
end)
