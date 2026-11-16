-- The unit frames' world the unit frame tests share, returned as UW. Not a
-- test (no _test suffix), so the runner doesn't run it; load it with
-- `local UW = load_test_file('unitframes/uf_world.lua')`. It makes no globals.
--
--   UW.world(opts) -> st, UF, P
--     Real: Core's helpers and defaults (a fresh world on opts.client through
--     T.client, or load_core_helpers() in the world the file is in), the unit
--     frames' defaults (config/default.lua, after config/position.lua with
--     opts.position) and the config of each unit in opts.units (UW.UNITS),
--     filled the way AceDB fills them; the module's own files
--     (UW.load_module(opts.after)); the elements in opts.elements
--     (UW.ELEMENTS); nameplates/options.lua (the nameplate pages, which
--     config.lua builds); LibStringFormat-1.0 (load_string_format). Then
--     UF:UpdateColors(), unless opts.colors is false.
--     Stand-in: UF.oUF is opts.ouf, else UW.ouf_colors(), oUF as far as
--     unitframes.lua and the previews use it.
--     Returns SaftUI, the Unitframes module and its profile config.
--
--   UW.load_module(after)
--     unitframes.lua, the group files (grouplayout.lua, groups.lua,
--     blizzardraid.lua, grouppreview.lua), config/profiles.lua,
--     config/groupoptions.lua, config/config.lua, constructors.lua and
--     updaters.lua, in the TOC's order (UW.MODULE_FILES), then the files after
--     names (e.g. { 'tags', 'aurafilters' }), in its order. Set UF.oUF's
--     stand-in first: unitframes.lua asserts it is there.
--
--   UW.before_spawn(UF, ouf)
--     What UF:OnEnable sets up before it spawns, on an oUF stand-in that
--     takes styles (fixtures/ouf.lua): UF.InitUnit registered, SaftUI's style
--     registered and active, UF.units and UF.allUnits empty.
--
--   UW.unit_frame(name, unit, elements, parent, auras) -> frame
--     A unit frame for a config unit. In game oUF:Spawn makes it and
--     UF.ConstructUnit gives it its text overlay, config and elements, by the
--     elements' own constructors. Here a Button (parent UIParent by default)
--     with ConstructUnit's fields and only the elements named, built by those
--     same constructors; oUF's UpdateAllElements is a no-op. Its CreateAuras
--     makes the aura container with auras(frame), UW.aura_container by default.
--
--   UW.aura_container(frame) -> container
--     The aura container (oUF's CreateAuras makes a Blizzard AuraContainer):
--     a plain frame with the methods auras.lua's UpdateConfig calls on it,
--     oUF's AddGroup, which gives a group key, and the container's
--     SetEnabled, flow layout setters, SetAuraGroupLayout and
--     SetAuraGroupMaxFrameCount, which only take their arguments.
--
--   UW.aura_button(auras, size) -> button
--     A button the aura container made for an aura (size by size), with
--     oUF's Icon, Count and Border, handed to the element's PostCreateButton
--     as the container hands it one.
--
--   UW.module() -> UF
--     For a test that can't load unitframes.lua (it needs oUF): the
--     Unitframes module made by hand, with UF:RegisterElement as
--     unitframes.lua's table store, so the real element files load and give
--     their tabs and constructors.
local T = load_test_file('lib/theme_helpers.lua')

local UW = {}

-- Every unit's config file in config/units/ but the nameplates'.
UW.UNITS = { 'arena', 'boss', 'focus', 'focustarget', 'party', 'pet', 'pettarget', 'player', 'raid10', 'raid40', 'target', 'targettarget', 'all' }

-- The bar, aura and indicator elements.
UW.ELEMENTS = { 'auras', 'power', 'additionalpower', 'health', 'castbar', 'classpower', 'indicators' }

-- The module's own files, by path from SaftUI-Unitframes/ without .lua, in
-- the TOC's order (config/load.xml loads the three config files after
-- unitframes.lua and the group files).
UW.MODULE_FILES = {
	'unitframes', 'grouplayout', 'groups', 'blizzardraid', 'grouppreview',
	'config/profiles', 'config/groupoptions', 'config/parts', 'config/config', 'constructors', 'updaters',
}

-- oUF as far as unitframes.lua and the previews use it: its colors table,
-- into which UF:UpdateColors merges the profile's.
function UW.ouf_colors()
	return {
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
end

function UW.load_module(after)
	for _, file in ipairs(UW.MODULE_FILES) do
		load_saftui('SaftUI-Unitframes/' .. file .. '.lua')
	end
	for _, file in ipairs(after or {}) do
		load_saftui('SaftUI-Unitframes/' .. file .. '.lua')
	end
end

function UW.world(opts)
	opts = opts or {}
	if opts.client then T.client(opts.client) else load_core_helpers() end
	local st = SaftUI
	if opts.position then load_saftui('SaftUI-Unitframes/config/position.lua') end
	load_saftui('SaftUI-Unitframes/config/default.lua')
	for _, unit in ipairs(opts.units or UW.UNITS) do
		load_saftui('SaftUI-Unitframes/config/units/' .. unit .. '.lua')
	end
	apply_defaults()
	addon_namespace('SaftUI-Unitframes').oUF = opts.ouf or UW.ouf_colors()
	UW.load_module(opts.after)
	for _, file in ipairs(opts.elements or UW.ELEMENTS) do
		load_saftui('SaftUI-Unitframes/elements/' .. file .. '.lua')
	end
	load_saftui('SaftUI-Unitframes/nameplates/options.lua')
	load_string_format()
	local UF = st:GetModule('Unitframes')
	local P = UF:GetProfileConfig()
	if opts.colors ~= false then UF:UpdateColors() end
	return st, UF, P
end

function UW.before_spawn(UF, ouf)
	ouf:RegisterInitCallback(UF.InitUnit)
	ouf:RegisterStyle('SaftUI', UF.ConstructUnit)
	ouf:SetActiveStyle('SaftUI')
	UF.units = {}
	UF.allUnits = {}
end

function UW.aura_container(frame)
	local auras = CreateFrame('Frame', nil, frame)
	function auras:SetEnabled() end
	function auras:SetFlowLayoutAnchorPoint() end
	function auras:SetFlowLayoutMaximumLineSize() end
	function auras:SetFlowLayoutGrowthDirection() end
	function auras:AddGroup() return 'Group1' end
	function auras:SetAuraGroupLayout() end
	function auras:SetAuraGroupMaxFrameCount() end
	return auras
end

function UW.unit_frame(name, unit, elements, parent, auras)
	local UF = SaftUI:GetModule('Unitframes')
	local frame = CreateFrame('Button', name, parent or UIParent)
	frame.base_unit = unit
	frame.GetConfig = function() return UF:GetProfileConfig()[unit] end
	frame.config = frame:GetConfig()
	function frame:UpdateAllElements() end
	function frame:CreateAuras() return (auras or UW.aura_container)(self) end
	local overlay = CreateFrame('Frame', nil, frame)
	overlay:SetFrameLevel(99)
	overlay:SetAllPoints(frame)
	frame.TextOverlay = overlay
	frame.elements = {}
	for _, element in ipairs(elements) do
		frame.elements[element] = UF.elements[element].Constructor(frame, element)
	end
	return frame
end

function UW.aura_button(auras, size)
	local button = CreateFrame('Button', nil, auras)
	button:SetSize(size, size)
	button:SetPoint('TOPLEFT')
	button.Icon = button:CreateTexture(nil, 'BORDER')
	button.Icon:SetAllPoints()
	button.Count = button:CreateFontString(nil, 'OVERLAY')
	button.Border = button:CreateTexture(nil, 'OVERLAY')
	button.Border:SetAllPoints()
	auras:PostCreateButton(button)
	return button
end

function UW.module()
	local UF = SaftUI:NewModule('Unitframes')
	UF.elements = {}
	function UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable, ValidUnit)
		self.elements[name] = { name = name, Constructor = Constructor, UpdateConfig = UpdateConfig,
			GetConfigTable = GetConfigTable, ValidUnit = ValidUnit }
	end
	return UF
end

return UW
