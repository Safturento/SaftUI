-- Boss frames' test mode: UF:UpdateGroupPreview (SaftUI-Unitframes/groups.lua)
-- fills the boss holder with SaftUI-owned preview frames, one for each boss
-- frame the boss Layout shows, each where UF:PlaceUnitFrame (unitframes.lua)
-- puts that boss frame, and hides them while any real boss frame is shown. The
-- boss page's Test mode toggle turns it on, and a Layout or color change draws
-- the previews again.
--
-- Real: Core's helpers and profile defaults, the unit frames' defaults (boss's
-- too), filled the way AceDB fills them; unitframes.lua (UF:PlaceUnitFrame,
-- UF:PlaceHolder, UF:ApplyConfig, UF:UpdateConfig, UF:OnColorsChanged);
-- groups.lua; config/config.lua (UF:GetProfileConfig and the boss page, whose
-- General set is the Layout options' set); constructors.lua and updaters.lua,
-- which build and style the previews' bars and texts; LibStringFormat-1.0,
-- which init.lua makes st.StringFormat.
--
-- Stand-ins, for what needs oUF:
--   * UF.oUF, as far as unitframes.lua and the previews use it: its colors
--     table, into which UF:UpdateColors merges the profile's.
--   * What OnEnable makes for boss, as far as the code under test reads it.
--     In game oUF:Spawn makes the five boss frames and UF.ConstructUnit gives
--     them their elements; here they are SaftUI buttons with ID, base_unit,
--     config and GetConfig, no elements, and oUF's UpdateAllElements as a
--     no-op. They start hidden, as oUF's unit watch keeps them with no boss
--     up, and a test shows one to play a boss appearing. The boss holder is
--     OnEnable's, and SaftUI_Target is there because boss's default position
--     is relative to it.
load_core_helpers()
load_saftui('SaftUI-Unitframes/config/default.lua')
load_saftui('SaftUI-Unitframes/config/units/boss.lua')
apply_defaults()
addon_namespace('SaftUI-Unitframes').oUF = {
	colors = {
		class = {},
		reaction = {},
		power = {},
		disconnected = CreateColor(1, 1, 1),
		tapped = CreateColor(1, 1, 1),
		health = CreateColor(0.2, 0.8, 0.2),
		roles = {},
		runes = {},
	},
}
load_saftui('SaftUI-Unitframes/unitframes.lua')
load_saftui('SaftUI-Unitframes/groups.lua')
load_saftui('SaftUI-Unitframes/config/config.lua')
load_saftui('SaftUI-Unitframes/constructors.lua')
load_saftui('SaftUI-Unitframes/updaters.lua')
load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')

local st = SaftUI
st.StringFormat = LibStub('LibStringFormat-1.0')
local UF = st:GetModule('Unitframes')
local P = UF:GetProfileConfig()
local profile_colors = st.config.profile.colors

local target = CreateFrame('Frame', 'SaftUI_Target', UIParent)
target:SetPoint('CENTER')
target:SetSize(300, 40)

UF.units = { boss = {} }
UF.allUnits = {}
UF.holders.boss = CreateFrame('Frame', 'SaftUI_BossHolder', UIParent)
for i = 1, 5 do
	local frame = CreateFrame('Button', 'SaftUI_Boss' .. i, UIParent)
	frame.ID, frame.base_unit, frame.elements = i, 'boss', {}
	frame.GetConfig = function() return UF:GetProfileConfig().boss end
	frame.config = frame:GetConfig()
	function frame:UpdateAllElements() end
	frame:Hide()
	UF.units.boss[i] = frame
end
-- As OnEnable does for boss: the previews watch the boss frames, then the
-- frames are placed and the colors go to oUF. This call stands in for
-- UF:OnEnable's own WatchFramesForPreview(unit) after it spawns the boss frames
-- (SaftUI-Unitframes/unitframes.lua), which no test runs, since spawning needs
-- oUF. Without that line in OnEnable the previews would stay up over real
-- bosses in game, and these tests would still pass.
UF:WatchFramesForPreview('boss')
UF:ApplyConfig('boss')
UF:UpdateColors()

local bosses = UF.units.boss

local function previews()
	return UF.previews.boss and UF.previews.boss.frames or {}
end

-- How many previews are on screen.
local function shown_previews()
	local n = 0
	for _, frame in ipairs(previews()) do
		if frame:IsVisible() then n = n + 1 end
	end
	return n
end

local function previews_shown()
	return UF.previews.boss ~= nil and UF.previews.boss:IsShown()
end

local function rect(frame)
	local left, bottom, width, height = frame:GetRect()
	return string.format('%.2f,%.2f,%.2f,%.2f', left, bottom, width, height)
end

local function rgb(r, g, b)
	return string.format('%.2f,%.2f,%.2f', r, g, b)
end

-- The boss page's General group (its set is the Layout options') and its
-- Layout's Test mode toggle.
local function general()
	return UF:GetConfigTable().args.boss.args.general
end

local function set_layout(key, value)
	general().set({ 'boss', 'general', key }, value)
end

test("the boss page's Test mode toggle shows a preview for each boss frame, where that boss frame goes", function()
	local toggle = general().args.layout.args.test_mode
	if not check(toggle and toggle.type == 'toggle', 'the boss Layout has a Test mode toggle') then return end
	eq(toggle.get(), false, 'off to start with')
	toggle.set({ 'boss', 'general', 'layout', 'test_mode' }, true)
	eq(toggle.get(), true, 'on')
	if not check(previews_shown(), 'the previews show') then return end

	eq(shown_previews(), 5, "five: boss's default layout shows every boss frame")
	for i = 1, 5 do
		eq(rect(previews()[i]), rect(bosses[i]), 'preview ' .. i .. ' covers boss frame ' .. i)
	end
	eq(rect(UF.previews.boss), rect(UF.holders.boss), 'together they fill the boss holder')
	check(previews()[2]:GetTop() < previews()[1]:GetBottom(), 'a column growing down')
end)

test('a preview shows a boss: a name, full health in the hostile reaction color, and no role corner', function()
	local hostile = rgb(profile_colors.reaction[2]:GetRGB())
	local names = {}
	for i = 1, 5 do
		local preview = previews()[i]
		local name = preview.Name:GetText()
		check(type(name) == 'string' and name ~= '' and not names[name], 'preview ' .. i .. ' has a name of its own: ' .. tostring(name))
		names[name or i] = true
		eq(preview.Health:GetValue(), 1, 'preview ' .. i .. ' at full health')
		eq(rgb(preview.Health:GetStatusBarColor()), hostile, 'preview ' .. i .. ' in the hostile reaction color, not a class color')
		check(not preview.GroupRoleIndicator:IsShown(), 'preview ' .. i .. ' has no role corner')
	end

	-- A boss has no role, so the corner stays hidden with every role shown.
	local role = P.boss.grouproleindicator
	role.enable, role.showDps = true, true
	UF:UpdateGroupPreview('boss')
	check(not previews()[1].GroupRoleIndicator:IsShown(), 'no role corner with the role indicator on')
	role.enable, role.showDps = false, false

	-- NPC class colors a boss by its class (Class is for players only).
	P.boss.health.colorClassNPC = true
	UF:UpdateGroupPreview('boss')
	local color = rgb(previews()[1].Health:GetStatusBarColor())
	local npc_class = false
	for _, class in ipairs({ 'WARRIOR', 'PALADIN', 'ROGUE', 'MAGE' }) do
		npc_class = npc_class or color == rgb(profile_colors.class[class]:GetRGB())
	end
	check(npc_class, 'NPC class gives an NPC class color: ' .. color)
	P.boss.health.colorClassNPC = false

	-- Color hostile reds a hostile name, as the name tag does.
	P.boss.name.color_hostile = true
	UF:UpdateGroupPreview('boss')
	local red = st.StringFormat:ToHex(profile_colors.text.red:GetRGB())
	check(previews()[1].Name:GetText():find('|cff' .. red, 1, true), 'a hostile name in red: ' .. previews()[1].Name:GetText())
	P.boss.name.color_hostile = false

	-- Boss percent adds the percent after the health, as on a skull-level unit.
	P.boss.health.text.enable = true
	UF:UpdateGroupPreview('boss')
	local text = tostring(previews()[1].Health.text:GetText())
	check(text:find(' | 100.0', 1, true) and text:sub(-8) == ' | 100.0', 'the health, then | 100.0: ' .. text)
	P.boss.health.text.enable = false
	UF:UpdateGroupPreview('boss')
end)

test('a Layout change places them again with the boss frames, in one line for each growth direction and spacing', function()
	for _, growth in ipairs({ 'TOP', 'BOTTOM', 'LEFT', 'RIGHT' }) do
		for _, spacing in ipairs({ 0, 12 }) do
			set_layout('growthDirection', growth)
			set_layout('spacing', spacing)
			local tag = growth .. ' ' .. spacing
			eq(shown_previews(), 5, 'all five: ' .. tag)
			for i = 1, 5 do
				eq(rect(previews()[i]), rect(bosses[i]), 'preview ' .. i .. ' covers boss frame ' .. i .. ': ' .. tag)
			end
			eq(rect(UF.previews.boss), rect(UF.holders.boss), 'together they fill the boss holder: ' .. tag)
			local a, b = previews()[1], previews()[2]
			if growth == 'TOP' then
				eq(a:GetBottom() - spacing, b:GetTop(), 'the second hangs spacing below the first: ' .. tag)
			elseif growth == 'BOTTOM' then
				eq(a:GetTop() + spacing, b:GetBottom(), 'the second sits spacing above the first: ' .. tag)
			elseif growth == 'LEFT' then
				eq(a:GetRight() + spacing, b:GetLeft(), 'the second sits spacing right of the first: ' .. tag)
			else
				eq(a:GetLeft() - spacing, b:GetRight(), 'the second sits spacing left of the first: ' .. tag)
			end
		end
	end
	set_layout('growthDirection', 'TOP')
	set_layout('spacing', 41)
end)

test('column keys an old profile saved on boss change neither the boss frames nor the previews', function()
	local P = UF:GetProfileConfig()
	local before = rect(UF.previews.boss)
	P.boss.unitsPerColumn, P.boss.maxColumns, P.boss.columnSpacing, P.boss.initialAnchor = 2, 3, 10, 'RIGHT'
	UF:ApplyConfig('boss')
	UF:UpdateGroupPreview('boss')
	eq(shown_previews(), 5, 'all five, in one line')
	for i = 1, 5 do
		eq(rect(previews()[i]), rect(bosses[i]), 'preview ' .. i .. ' covers boss frame ' .. i)
	end
	eq(rect(UF.previews.boss), before, 'the same spot and size')
	P.boss.unitsPerColumn, P.boss.maxColumns, P.boss.columnSpacing, P.boss.initialAnchor = nil, nil, nil, nil
	UF:ApplyConfig('boss')
end)

test('a real boss frame showing hides the previews, and they come back when it hides, with no wait for combat to end', function()
	check(previews_shown(), 'shown with no boss up')
	bosses[3]:Show()
	check(not previews_shown(), 'hidden while boss 3 is up')
	bosses[1]:Show()
	bosses[3]:Hide()
	check(not previews_shown(), 'still hidden while boss 1 is up')

	-- Nothing secure is touched, so nothing waits for the end of combat. The
	-- stubs don't model protection: this shows only that there's no
	-- InCombatLockdown gate, not that the game allows it. That needs a pull in game.
	stub.in_combat = true
	bosses[1]:Hide()
	check(previews_shown(), 'back once no boss frame is up')
	eq(shown_previews(), 5, 'all five')
	bosses[2]:Show()
	check(not previews_shown(), 'hidden again in combat')
	bosses[2]:Hide()
	stub.in_combat = false
	check(previews_shown(), 'and back')
end)

test('a reputation color change draws the boss previews again in the new color', function()
	local hostile = profile_colors.reaction[2]
	local r, g, b = hostile:GetRGB()
	hostile:SetRGB(0.9, 0.1, 0.5)
	UF:OnColorsChanged('reaction')
	eq(rgb(previews()[1].Health:GetStatusBarColor()), '0.90,0.10,0.50', 'the new hostile color')
	hostile:SetRGB(r, g, b)
	UF:OnColorsChanged('reaction')
	eq(rgb(previews()[1].Health:GetStatusBarColor()), rgb(r, g, b), 'and back')
end)

test('test mode off hides them, and so do boss frames turned off', function()
	UF:SetGroupTestMode('boss', false)
	check(not previews_shown(), 'hidden with test mode off')
	eq(general().args.layout.args.test_mode.get(), false, 'the toggle reads off')

	UF:SetGroupTestMode('boss', true)
	check(previews_shown(), 'on again')
	general().set({ 'boss', 'general', 'enable' }, false)
	check(not previews_shown(), 'hidden while boss frames are off')
	general().set({ 'boss', 'general', 'enable' }, true)
	check(previews_shown(), 'back when they are on')
	UF:SetGroupTestMode('boss', false)
end)
