-- The Spy skin's Kill on Sight button (SaftUI-Misc/Skinning/addons/spy_kos.lua): restyled
-- in place, and moved onto SaftUI's target frame (SaftUI_Target) when there is one, shown
-- for an enemy player and drawn as a skull that is Danger on the list and Muted off it.
-- Real: spy.lua, spy_kos.lua, Core. Spy is fixtures/spy_world.lua.
local SpyFix = load_test_file('misc/fixtures/spy_world.lua')
local T = load_test_file('lib/theme_helpers.lua')

local S = load_test_file('lib/secrets.lua')

local st, SK, SP

-- The target's hostility and name aren't in the stubs: each case defines them and puts
-- every global it touched back when it is done.
local saved = {}
for _, name in ipairs({ 'UnitIsEnemy', 'GetUnitName', 'SaftUI_Target', 'issecretvalue', 'UnitIsPlayer' }) do saved[name] = _G[name] end
local savedUnits = stub.units
local savedTest = test
local function test(name, fn)
	savedTest(name, function()
		local ok, err = pcall(fn)
		for k, v in pairs(saved) do _G[k] = v end
		stub.units = savedUnits
		if not ok then error(err, 0) end
	end)
end

local ON = [[Interface\AddOns\Spy\Textures\button-on.tga]]
local OFF = [[Interface\AddOns\Spy\Textures\button-off.tga]]

local function world(opts)
	opts = opts or {}
	st = T.client('forever')
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/addons/spy.lua')
	load_saftui('SaftUI-Misc/Skinning/addons/spy_kos.lua')
	SK = st:GetModule('Skinning')
	SP = SK:GetModule('Spy')
	-- Not in the stubs: the target's hostility and name.
	function UnitIsEnemy(a, b) local u = stub.units[b == 'player' and a or b]; return u and u.enemy or false end
	-- (the stub's UnitIsPlayer turns the field into a plain boolean; a secret must get through)
	function UnitIsPlayer(unit) local u = stub.units[unit]; return u and u.player or false end
	function GetUnitName(unit) local u = stub.units[unit]; return u and u.name end
	stub.units = {}
	if opts.saftui then
		SaftUI_Target = CreateFrame('Button', 'SaftUI_Target', UIParent)
		SaftUI_Target:SetSize(200, 40)
	else
		SaftUI_Target = nil
	end
	SpyFix.make(opts)
	if opts.noEnemyName then Spy.EnemyPlayerName = nil end
	if opts.noToggle then Spy.ToggleKOSPlayer = nil end
	SK:Enable()
	stub.fire_event('ADDON_LOADED', 'Spy')
end

local function target(unit)
	stub.units.target = unit
	stub.fire_event('PLAYER_TARGET_CHANGED')
end

local function rgb(texture) return { texture:GetVertexColor() } end
local function near(a, b) return math.abs(a - b) < 0.01 end
local function same(c, r, g, b) return near(c[1], r) and near(c[2], g) and near(c[3], b) end

test('kos_rehomed_on_saftui_target', function()
	world({ saftui = true })
	local kos = Spy.KoSButton
	eq(kos:GetParent(), SaftUI_Target, 'child of the SaftUI target frame')
	local point, rel, relPoint, x, y = kos:GetPoint(1)
	eq(point, 'TOPRIGHT'); eq(rel, SaftUI_Target); eq(relPoint, 'TOPRIGHT')
	eq(x, -2); eq(y, -2)
	eq(kos:GetWidth(), 16); eq(kos:GetHeight(), 16)
	eq(kos.Background:GetAlpha(), 0); eq(kos.Border:GetAlpha(), 0)
	eq(#take_errors(), 0)
end)

test('kos_shows_for_enemy_player_only', function()
	world({ saftui = true })
	local kos = Spy.KoSButton
	check(not kos:IsShown(), 'no target: hidden')
	target({ name = 'Foe', player = true, enemy = true })
	check(kos:IsShown(), 'enemy player shown')
	target({ name = 'Pal', player = true, enemy = false })
	check(not kos:IsShown(), 'friendly hidden')
	target({ name = 'Wolf', player = false, enemy = true })
	check(not kos:IsShown(), 'enemy npc hidden')
	target({ name = 'Foe', player = true, enemy = true })
	Spy.db.profile.ShowKoSButton = false
	target({ name = 'Foe', player = true, enemy = true })
	check(not kos:IsShown(), 'option off: hidden')
	target(nil)
	check(not kos:IsShown(), 'no target again: hidden')
end)

test('kos_icon_tracks_list', function()
	world({ saftui = true })
	local icon = Spy.KoSButton.Icon
	target({ name = 'Foe', player = true, enemy = true })
	local d, m = { st:Color('text', 'danger'):GetRGB() }, { st:Color('text', 'muted'):GetRGB() }
	check(same(rgb(icon), m[1], m[2], m[3]), 'off the list: muted')
	eq(icon:GetTexture(), st.icons.skull)
	Spy:ToggleKOSPlayer(true, 'Foe')
	check(same(rgb(icon), d[1], d[2], d[3]), 'on the list: danger')
	Spy:ToggleKOSPlayer(false, 'Foe')
	check(same(rgb(icon), m[1], m[2], m[3]), 'removed: muted')
	eq(#take_errors(), 0)
end)

test('kos_left_on_blizzard_frame_without_saftui_target', function()
	world()
	local kos = Spy.KoSButton
	eq(kos:GetParent(), TargetFrame)
	local point, rel = kos:GetPoint(1)
	eq(point, 'TOPLEFT'); eq(rel, TargetFrame)
	eq(kos:GetWidth(), 22)
	eq(kos.Background:GetAlpha(), 0)
	eq(Spy.KoSButton.Icon:GetTexture(), st.icons.skull)
	target({ name = 'Foe', player = true, enemy = true })
	check(not kos:IsShown(), 'Spy drives its own visibility there')
	eq(#take_errors(), 0)
end)

test('kos_skull_after_spy_retextures', function()
	world()
	local icon = Spy.KoSButton.Icon
	local d, m = { st:Color('text', 'danger'):GetRGB() }, { st:Color('text', 'muted'):GetRGB() }
	icon:SetTexture(ON)
	eq(icon:GetTexture(), st.icons.skull)
	check(same(rgb(icon), d[1], d[2], d[3]), 'on art: danger')
	icon:SetTexture(OFF)
	eq(icon:GetTexture(), st.icons.skull)
	check(same(rgb(icon), m[1], m[2], m[3]), 'off art: muted')
end)

test('kos_skinned_once_and_box_drawn', function()
	world()
	local n = 0
	for _, c in ipairs({ Spy.KoSButton:GetChildren() }) do if c.SetBackdrop and not SpyFix.is_spy(c) then n = n + 1 end end
	eq(n, 1, 'one SaftUI box')
	Spy:CreateKoSButton() -- already made: nothing again
	SP:SkinKoS()
	eq(#take_errors(), 0)
end)

test('kos_secret_target_hides_with_no_error', function()
	local restore = S.install()
	for _, opts in ipairs({ { saftui = true }, { saftui = true, noEnemyName = true } }) do
		world(opts)
		restore = S.install()
		local kos = Spy.KoSButton
		target({ name = 'Foe', player = true, enemy = true })
		check(kos:IsShown(), 'readable: shown')
		target({ name = 'Foe', player = true, enemy = S.secret('hostility') })
		check(not kos:IsShown(), 'secret hostility: hidden')
		target({ name = S.secret('name'), player = true, enemy = true })
		check(not kos:IsShown(), 'secret name: hidden')
		target({ name = 'Foe', player = S.secret('kind'), enemy = true })
		check(not kos:IsShown(), 'secret kind: hidden')
		eq(#take_errors(), 0, 'no error')
	end
	restore()
end)

test('kos_colors_repaint_icon', function()
	world({ saftui = true })
	local icon = Spy.KoSButton.Icon
	target({ name = 'Foe', player = true, enemy = true })
	Spy:ToggleKOSPlayer(true, 'Foe')
	icon:SetVertexColor(1, 1, 1)
	SP:OnColorsChanged('text')
	local d = { st:Color('text', 'danger'):GetRGB() }
	check(same(rgb(icon), d[1], d[2], d[3]), 'a text color change repaints')
	icon:SetVertexColor(1, 1, 1)
	SP:OnColorsChanged('theme')
	check(same(rgb(icon), 1, 1, 1), 'another group leaves it')
	eq(#take_errors(), 0)
end)

test('kos_missing_pieces_skipped', function()
	world({ saftui = true, noToggle = true })
	target({ name = 'Foe', player = true, enemy = true })
	check(Spy.KoSButton:IsShown(), 'works without ToggleKOSPlayer')
	eq(#take_errors(), 0)
	world({ renamed = true })
	eq(#take_errors(), 0)
end)
