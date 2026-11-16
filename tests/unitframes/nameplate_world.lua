-- The world the nameplate tests share, returned as NP:
--
--   NP.world(client) -> st, UF
--     A fresh world on 'forever' or 'retail' (T.client), set up as UF:OnEnable
--     leaves it before the plates are spawned. Real: Core's helpers and
--     defaults; the unit frames' defaults and every unit's config, the files
--     config/load.xml lists (nameplate.lua among them), filled the way AceDB
--     fills them; the module's files (uf_world.lua's UW.load_module:
--     unitframes.lua, the group files, config/profiles.lua,
--     config/groupoptions.lua, config/config.lua, constructors.lua and
--     updaters.lua), then tags.lua and aurafilters.lua; the files
--     elements/elements.xml and nameplates/nameplates.xml list, read from the
--     XML so a file a later change adds there loads too; LibStringFormat-1.0,
--     which init.lua makes st.StringFormat. UF.units, UF.allUnits and
--     UF.holders are empty, and st.config.global is {}.
--     Stand-in: oUF (fixtures/ouf.lua, which says what the real one does
--     beyond it) as UF.oUF, with UF.InitUnit registered and SaftUI's style
--     registered and active, as UF:OnEnable leaves them.
--     Blizzard's NamePlateDriverFrame, and every NamePlateN the game makes
--     with each UnitFrame it hands one and that one's WidgetContainer and
--     SoftTargetFrame (tests/wow/game.lua's stub.add_nameplate), are locked
--     as Blizzard's (lib/locked_widget.lua), so SaftUI writing a
--     field onto one fails. What oUF writes onto a plate (unitFrame, style),
--     and the hook hooksecurefunc stores, are set with rawset.
--
--   NP.add(unit, opts) -> frame
--     The game shows unit on a plate (stub.add_nameplate, which takes the same
--     opts), and SaftUI's frame on it is returned: the plate's child marked
--     isNamePlate, never read from the plate's unitFrame. nil when the plate
--     has none (a forbidden plate, or no driver).
--
--   NP.remove(unit)
--     The game takes unit's plate away (stub.remove_nameplate).
--
--   NP.enemy(unit), NP.friend(unit)
--     unit is a hostile NPC (unfriendly, attackable, reaction 2) or a
--     friendly one (reaction 5), named after its token, in stub.units.
local T = load_test_file('lib/theme_helpers.lua')
local UW = load_test_file('unitframes/uf_world.lua')
local fixture = load_test_file('unitframes/fixtures/ouf.lua')
local lock = load_test_file('lib/locked_widget.lua')

local NP = {}

-- The Script files an XML file lists, as paths from the repo root.
local function scripts(xml)
	local folder = xml:match('^(.*)/[^/]+$')
	local text = assert(read_saftui_source(xml))
	local files = {}
	for file in text:gmatch('<Script%s+file="([^"]+)"') do
		files[#files + 1] = folder .. '/' .. file:gsub('\\', '/')
	end
	return files
end

function NP.world(client)
	local st = T.client(client)
	stub.on_nameplate_frame = function(frame) lock(frame, 'Blizzard') end
	lock(NamePlateDriverFrame, 'Blizzard')

	-- config/load.xml: position.lua, default.lua and the units' files, then
	-- the files that need the module (unitframes.lua) first: profiles.lua,
	-- groupoptions.lua and config.lua, which UW.load_module loads after it.
	local NEEDS_MODULE = { ['shared.lua'] = true, ['profiles.lua'] = true, ['groupoptions.lua'] = true, ['config.lua'] = true }
	for _, file in ipairs(scripts('SaftUI-Unitframes/config/load.xml')) do
		if not NEEDS_MODULE[file:match('[^/]+$')] then load_saftui(file) end
	end
	-- Not a repeat of T.client's: the files above added the unit frames' defaults.
	apply_defaults()
	st.config.global = {}
	-- AceDB's per-character table, which the shell doesn't have: a profile
	-- switch (UF:ApplyConfig) sets the game's plate settings, which records
	-- the user's values in it.
	st.config.char = {}

	-- C_TooltipInfo.GetUnit(unit) (the same on both clients; it can give
	-- nothing): stub.tooltips[unit], the tooltip data a test sets ({ lines =
	-- { { type = ..., leftText = ... }, ... } }), nothing by default. Each call
	-- is counted in stub.tooltip_reads, so a test can show none was made.
	stub.tooltips, stub.tooltip_reads = {}, 0
	C_TooltipInfo = {
		GetUnit = function(unit)
			stub.tooltip_reads = stub.tooltip_reads + 1
			return stub.tooltips[unit]
		end,
	}

	local ouf = fixture.new()
	addon_namespace('SaftUI-Unitframes').oUF = ouf
	UW.load_module({ 'tags', 'aurafilters' })
	for _, xml in ipairs({ 'SaftUI-Unitframes/elements/elements.xml', 'SaftUI-Unitframes/nameplates/nameplates.xml' }) do
		for _, file in ipairs(scripts(xml)) do load_saftui(file) end
	end
	load_string_format()

	local UF = st:GetModule('Unitframes')
	-- What UF:OnEnable sets up before it spawns.
	UW.before_spawn(UF, ouf)
	UF.holders = {}
	UF:UpdateColors()
	NP.ouf = ouf
	return st, UF
end

function NP.add(unit, opts)
	local plate = stub.add_nameplate(unit, opts)
	for _, child in ipairs({ plate:GetChildren() }) do
		if rawget(child, 'isNamePlate') then return child end
	end
end

function NP.remove(unit)
	stub.remove_nameplate(unit)
end

function NP.enemy(unit) stub.units[unit] = { name = unit, friend = false, attackable = true, reaction = 2 } end
function NP.friend(unit) stub.units[unit] = { name = unit, friend = true, attackable = false, reaction = 5 } end

return NP
