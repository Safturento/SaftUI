-- The world the nameplate tests share, returned as NP:
--
--   NP.world(client) -> st, UF
--     A fresh world on 'forever' or 'retail' (T.client), set up as UF:OnEnable
--     leaves it before the plates are spawned. Real: Core's helpers and
--     defaults; the unit frames' defaults and every unit's config, the files
--     config/load.xml lists (nameplate.lua among them), filled the way AceDB
--     fills them; unitframes.lua, the group files (grouplayout.lua,
--     groups.lua, blizzardraid.lua, grouppreview.lua), config/config.lua,
--     constructors.lua, updaters.lua, tags.lua and aurafilters.lua; the files
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
--     as Blizzard's (misc/fixtures/locked_widget.lua), so SaftUI writing a
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
local T = load_test_file('lib/theme_helpers.lua')
local fixture = load_test_file('unitframes/fixtures/ouf.lua')
local lock = load_test_file('misc/fixtures/locked_widget.lua')

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
	-- config.lua, which needs the module (unitframes.lua) first.
	local configFiles = scripts('SaftUI-Unitframes/config/load.xml')
	local configLua
	for _, file in ipairs(configFiles) do
		if file:match('/config%.lua$') then
			configLua = file
		else
			load_saftui(file)
		end
	end
	-- Not a repeat of T.client's: the files above added the unit frames' defaults.
	apply_defaults()
	st.config.global = {}

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
	load_saftui('SaftUI-Unitframes/unitframes.lua')
	for _, file in ipairs({ 'grouplayout', 'groups', 'blizzardraid', 'grouppreview' }) do
		load_saftui('SaftUI-Unitframes/' .. file .. '.lua')
	end
	load_saftui(configLua)
	for _, file in ipairs({ 'constructors', 'updaters', 'tags', 'aurafilters' }) do
		load_saftui('SaftUI-Unitframes/' .. file .. '.lua')
	end
	for _, xml in ipairs({ 'SaftUI-Unitframes/elements/elements.xml', 'SaftUI-Unitframes/nameplates/nameplates.xml' }) do
		for _, file in ipairs(scripts(xml)) do load_saftui(file) end
	end
	load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')
	st.StringFormat = LibStub('LibStringFormat-1.0')

	local UF = st:GetModule('Unitframes')
	-- What UF:OnEnable sets up before it spawns.
	ouf:RegisterInitCallback(UF.InitUnit)
	ouf:RegisterStyle('SaftUI', UF.ConstructUnit)
	ouf:SetActiveStyle('SaftUI')
	UF.units = {}
	UF.allUnits = {}
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

return NP
