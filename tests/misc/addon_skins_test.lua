-- The Hekili and WeakAuras skins (SaftUI-Misc/Skinning/addons/hekili.lua and
-- weakauras.lua), which draw SaftUI's theme behind another addon's frames:
--   - nothing is written onto their frames: every frame of the fixtures is
--     locked (lib/locked_widget.lua), so a field (.backdrop, .thick, .skinned)
--     fails;
--   - under Skinning's Theme None the skins don't error, still record each
--     frame as skinned, and draw it once the theme is no longer None, with its
--     strata and level set after that first draw too;
--   - a frame is skinned once, however often its addon hands it out.
-- Real: SaftUI-Misc's config.lua, Skinning/skinning.lua and the two skins, Core's
-- helpers and the theme engine. Hekili and WeakAuras are fixtures/addon_skins.lua.
local A = load_test_file('misc/fixtures/addon_skins.lua')
local T = load_test_file('lib/theme_helpers.lua')

local st, SK, HK, WA

-- A fresh world with both addons built and both skins enabled, Skinning's
-- Theme set to theme (the default if nil).
local function world(theme)
	st = T.client('forever')
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	if theme then st.config.profile.skinning.theme = theme end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/addons/hekili.lua')
	load_saftui('SaftUI-Misc/Skinning/addons/weakauras.lua')
	SK = st:GetModule('Skinning')
	A.make_hekili()
	A.make_weakauras()
	SK:Enable()
	HK, WA = SK:GetModule('Hekili'), SK:GetModule('WeakAuras')
	HK:Enable()
	WA:Enable()
end

-- The backdrop of SaftUI's behind a frame: its one child frame with a backdrop.
local function backdrop_of(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if child.SetBackdrop then return child end
	end
end

local function same_keys(frame, before)
	for key in pairs(frame) do
		if not before[key] then return false, key end
	end
	return true
end

-- The skinned guard: a region handed out again is not drawn again, nor listed
-- twice for UpdateConfig (st:SetBackdropIn reuses the backdrop, so only the
-- number of draws shows it).
local function count_draws(frame, run)
	local real, draws = st.SetBackdropIn, 0
	st.SetBackdropIn = function(self, backdrops, f, ...)
		if f == frame then draws = draws + 1 end
		return real(self, backdrops, f, ...)
	end
	local ok, err = pcall(run)
	st.SetBackdropIn = real
	assert(ok, err)
	return draws
end

test('Hekili: a skinned button gets no field written onto it', function()
	world()
	local before = A.keys(A.button)
	HK:SkinIcon(nil, 1, 1)
	local ok, key = same_keys(A.button, before)
	check(ok, 'field written onto the button: ' .. tostring(key))
	local backdrop = backdrop_of(A.button)
	check(backdrop, 'a backdrop of SaftUI\'s behind the button')
	eq(backdrop:GetFrameStrata(), 'LOW', 'below the icons')
end)

test('Hekili: a button is skinned once', function()
	world()
	HK:SkinIcon(nil, 1, 1)
	HK:SkinIcon(nil, 1, 1)
	eq(select('#', A.button:GetChildren()), 1, 'one backdrop')
	local draws = count_draws(A.button, function()
		HK:SkinIcon(nil, 1, 1)
		HK:UpdateConfig()
	end)
	eq(draws, 1, 'a skinned button is drawn only by UpdateConfig, once')
end)

test('Hekili: Theme None does not error, and the button is drawn once the theme changes', function()
	world('none')
	HK:SkinIcon(nil, 1, 1)
	check(backdrop_of(A.button) == nil, 'None draws nothing')
	st.config.profile.skinning.theme = 'thick'
	HK:UpdateConfig()
	local backdrop = backdrop_of(A.button)
	check(backdrop, 'drawn after the switch')
	eq(backdrop:GetFrameStrata(), 'LOW', 'its strata set after the first draw made by UpdateConfig')
end)

test('WeakAuras: a skinned region gets no field written onto it', function()
	world()
	local region = A.region()
	local before = A.keys(region)
	WA:SkinIcon(nil, region, {})
	local ok, key = same_keys(region, before)
	check(ok, 'field written onto the region: ' .. tostring(key))
	local backdrop = backdrop_of(region)
	check(backdrop, 'a backdrop of SaftUI\'s behind the region')
	eq(backdrop:GetFrameStrata(), 'LOW', 'below the icons')
	eq(backdrop:GetFrameLevel(), math.max(0, region:GetFrameLevel() - 4), 'four levels under the region')
end)

test('WeakAuras: a region is skinned once', function()
	world()
	local region = A.region()
	WA:SkinIcon(nil, region, {})
	WA:SkinIcon(nil, region, {})
	eq(select('#', region:GetChildren()), 1, 'one backdrop')
	local draws = count_draws(region, function()
		WA:SkinIcon(nil, region, {})
		WA:UpdateConfig()
	end)
	eq(draws, 1, 'a skinned region is drawn only by UpdateConfig, once')
end)

test('WeakAuras: Theme None does not error, and the region is drawn once the theme changes', function()
	world('none')
	local region = A.region()
	WA:SkinIcon(nil, region, {})
	check(backdrop_of(region) == nil, 'None draws nothing')
	st.config.profile.skinning.theme = 'thin'
	WA:UpdateConfig()
	local backdrop = backdrop_of(region)
	check(backdrop, 'drawn after the switch')
	eq(backdrop:GetFrameStrata(), 'LOW', 'strata set after the first draw made by UpdateConfig')
	eq(backdrop:GetFrameLevel(), math.max(0, region:GetFrameLevel() - 4), 'level set too')
end)
