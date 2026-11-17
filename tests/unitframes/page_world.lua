-- The unit frames' /sui page world that config_test.lua, parts_test.lua and the page tests of
-- the groups, the plates and the shared pages load (not a test: no _test suffix).
--
--   local PW = load_test_file('unitframes/page_world.lua').world()
--     PW.st, PW.UF, PW.OM, PW.OW, PW.W, PW.T, PW.AceConfigRegistry, PW.OF   the world's parts
--     PW.updates                                                              UF:UpdateConfig's calls (it has unitframes.lua's two
--                                                                             lines for sharing: UpdateConfig('all') propagates)
--
-- Real: Core's helpers and profile defaults (load_core_helpers), the unit frames' defaults,
-- filled the way AceDB fills them (apply_defaults), so a unit's settings are made by reading
-- them, as in game; AceConfigRegistry-3.0; the options model, widgets, body and window;
-- config/position.lua, profiles.lua, groupoptions.lua, parts.lua, config.lua, updaters.lua
-- (UF.UnpackColor) and every element file the TOC loads that defines options; nameplates/
-- nameplates.lua, threat.lua, subtext.lua and options.lua (the plate pages); tags.lua.
-- Stand-ins, for unitframes.lua, which needs oUF: UF:UpdateConfig counts its calls (a test
-- may put its own over it); UF:RegisterElement as unitframes.lua's table store (uf_world.lua's
-- UW.module); UF.units and UF.groups (a frame by config unit; boss is a list of five in game),
-- UF.holders for the groups, UF:GetMoverFrame, UF.unit_strings, UF.group_strings,
-- UF.PLATE_UNITS and UF.IsPlateUnit; and UF.oUF as far as tags.lua uses it.
local M = {}

function M.world()
	load_core_helpers()
	load_saftui('SaftUI-Unitframes/config/position.lua') -- config/load.xml's order: first
	load_saftui('SaftUI-Unitframes/config/default.lua')
	-- Every unit's own defaults, as config/load.xml lists them (the nameplates'
	-- are enable, friendly, threat_solo, the threat text, width, height).
	for _, file in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
		'arena', 'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate', 'all' }) do
		load_saftui('SaftUI-Unitframes/config/units/' .. file .. '.lua')
	end
	apply_defaults()
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	load_test_file('lib/options_walk.lua')
	local T = load_test_file('lib/theme_helpers.lua')

	local st = SaftUI
	local OM, OW, W = st.OptionsModel, st.OptionsWindow, st.OptionsWidgets
	local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
	-- The module by hand, UF:RegisterElement as unitframes.lua's table store
	-- (uf_world.lua's UW.module).
	local UF = load_test_file('unitframes/uf_world.lua').module()
	local PW = { updates = 0 }
	-- unitframes.lua's two lines for sharing, which the pages need (an All units set copies into the
	-- followers; an update with no unit prepares the profile): the rest needs oUF.
	function UF:UpdateConfig(unit, element)
		PW.updates = PW.updates + 1
		if unit == 'all' then return self:PropagateShared(element) end
		if not unit then self:PrepareShared() end
	end

	UF.units, UF.groups, UF.holders = {}, {}, {}
	for _, unit in ipairs({ 'boss', 'focustarget', 'player', 'pettarget', 'target', 'pet', 'targettarget', 'focus' }) do
		UF.units[unit] = CreateFrame('Frame', nil, UIParent)
	end
	for _, group in ipairs({ 'raid40', 'party', 'raid10' }) do
		UF.groups[group] = CreateFrame('Frame', nil, UIParent)
		UF.holders[group] = CreateFrame('Frame', nil, UIParent)
	end
	UF.unit_strings = {
		player = 'Player', target = 'Target', targettarget = 'TargetTarget', focus = 'Focus',
		focustarget = 'FocusTarget', pet = 'Pet', pettarget = 'PetTarget', boss = 'Boss', -- arena's is commented out
	}
	UF.group_strings = { party = 'Party', raid10 = 'Raid 10', raid40 = 'Raid 40' }
	UF.testGroups = {} -- the groups' Test mode, which Layout's toggle reads (unitframes.lua's)
	UF.PLATE_UNITS = { nameplate = true, friendlynameplate = true }
	function UF.IsPlateUnit(unit) return UF.PLATE_UNITS[unit] == true end
	function UF:GetMoverFrame(unit) return self.holders[unit] or self.units[unit] end

	load_saftui('SaftUI-Unitframes/config/shared.lua')
	load_saftui('SaftUI-Unitframes/config/sharedsetup.lua')
	load_saftui('SaftUI-Unitframes/config/profiles.lua')
	load_saftui('SaftUI-Unitframes/config/groupoptions.lua')
	load_saftui('SaftUI-Unitframes/config/parts.lua')
	load_saftui('SaftUI-Unitframes/config/sharedoptions.lua')
	load_saftui('SaftUI-Unitframes/config/config.lua')
	load_saftui('SaftUI-Unitframes/updaters.lua')
	load_saftui('SaftUI-Unitframes/nameplates/nameplates.lua')
	load_saftui('SaftUI-Unitframes/nameplates/threat.lua')
	load_saftui('SaftUI-Unitframes/nameplates/options.lua')
	-- Every element file the TOC loads that defines options (lib/options_files.lua's rule), in the TOC's
	-- order: a new element cannot be missed by the walk. (aurawatch.lua and portrait.lua register nothing.)
	local OF = load_test_file('lib/options_files.lua')
	for _, path in ipairs(OF.Files('SaftUI-Unitframes/elements/')) do load_saftui(path) end
	-- The name tag (tags.lua), with LibStringFormat-1.0, which init.lua makes
	-- st.StringFormat.
	UF.oUF = { Tags = { Events = {}, Methods = {} }, colors = { class = st.config.profile.colors.class } }
	load_string_format()
	load_saftui('SaftUI-Unitframes/tags.lua')
	-- The Subtext element (registers a tag on UF.oUF, so after tags.lua): the plate pages' Subtext tab.
	load_saftui('SaftUI-Unitframes/nameplates/subtext.lua')
	PW.st, PW.UF, PW.OM, PW.OW, PW.W, PW.T, PW.AceConfigRegistry, PW.OF = st, UF, OM, OW, W, T, AceConfigRegistry, OF
	return PW
end

return M
