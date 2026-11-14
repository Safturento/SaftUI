-- What the unit frames' movers tell the edit mode bar
-- (SaftUI-Unitframes/unitframes.lua, UF:RegisterMovers and UF.DefaultUnitConfig):
-- the module, disabled by the unit's enable setting, hidden while its frame (a
-- group's header, or Test mode's previews) isn't shown, and the profile
-- defaults' position as the default.
--
-- Real: Core's helpers and edit mode, the unit frames' defaults and the
-- module's files (uf_world.lua). Stand-ins: the unit frames, the headers and
-- the preview containers, plain frames put where oUF's spawns would be.
local UW = load_test_file('unitframes/uf_world.lua')
local st, UF = UW.world()
load_editmode()
local EM = st.EditModeFrames

local function frame(name)
	local f = CreateFrame('Frame', name, UIParent)
	f:SetSize(100, 30)
	f:SetPoint('CENTER')
	return f
end

local player, target = frame('MoverDataPlayer'), frame('MoverDataTarget')
local boss = { frame('MoverDataBoss1'), frame('MoverDataBoss2') }
local party = frame('MoverDataParty')
UF.units = { player = player, target = target, boss = boss }
UF.holders = { boss = frame('MoverDataBossHolder'), party = frame('MoverDataPartyHolder') }
UF.groups = { party = party }
UF.unit_strings = { player = 'Player', target = 'Target', boss = 'Boss' }
UF.group_strings = { party = 'Party' }
UF:RegisterMovers()

test('DefaultUnitConfig gives the unit\'s own defaults when they hold a position, else the shared ones', function()
	local profiles = st.defaults.unitframes.profiles['**']
	eq(UF.DefaultUnitConfig('player'), profiles.player, "the player's own")
	eq(UF.DefaultUnitConfig('nobody'), profiles['**'], 'a unit with none: the shared table')
	eq(UF.DefaultUnitConfig('nobody').position.point, 'CENTER', 'with a position')
end)

test('every unit frame mover is the Unit frames module, with its unit\'s default position as a copy', function()
	for _, key in ipairs({ 'uf_player', 'uf_target', 'uf_boss', 'uf_party' }) do
		eq(EM:MoverModule(EM.movers[key]), 'Unit frames', key .. ': module')
	end
	local default = EM:GetDefaultPosition(EM.movers.uf_player)
	local want = st.defaults.unitframes.profiles['**'].player.position
	eq(default.x_off, want.x_off, "the player's default x")
	eq(default.y_off, want.y_off, "and y")
	default.x_off = 12345
	eq(want.x_off, -157, 'a write into the copy leaves the defaults')
end)

test("a unit frame mover is disabled by the unit's enable setting", function()
	local mover = EM.movers.uf_target
	local config = UF:GetProfileConfig().target
	config.enable = true
	eq(EM:IsMoverDisabled(mover), false, 'enabled')
	config.enable = false
	eq(EM:IsMoverDisabled(mover), true, 'its enable off')
	config.enable = true
end)

test('a unit frame mover is hidden while its frame, its boss frames or its header are not shown; previews count as shown', function()
	local function hidden(key) return EM:IsMoverHidden(EM.movers[key]) end
	target:Hide()
	eq(hidden('uf_target'), true, 'no target')
	target:Show()
	eq(hidden('uf_target'), false, 'a target')
	for _, f in ipairs(boss) do f:Hide() end
	eq(hidden('uf_boss'), true, 'no boss')
	boss[2]:Show()
	eq(hidden('uf_boss'), false, 'one boss frame is enough')
	party:Hide()
	eq(hidden('uf_party'), true, 'solo: no party header')
	UF.previews.party = frame('MoverDataPartyPreview')
	UF.previews.party:Show()
	eq(hidden('uf_party'), false, "Test mode's previews count as shown")
	UF.previews.party:Hide()
	eq(hidden('uf_party'), true, 'and no longer when they hide')
	party:Show()
	eq(hidden('uf_party'), false, 'the header shown')
	eq(#take_errors(), 0, 'no errors')
end)
