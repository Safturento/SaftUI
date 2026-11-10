-- Saved template choices becoming a Theme and a Background
-- (st:MigrateTemplateKeys, SaftUI-Core/theme.lua), wherever saved data enters
-- a profile, so a profile the old version saved keeps its look with no step
-- the user takes:
--   - the walk itself: every key named template or <something>template, read
--     through the old names' table, and idempotent;
--   - at login, once the AceDB database is made (Config:InitializeAceConfig);
--   - a profile switch to a profile the old version saved (Review Focus 3), and
--     a profile copied from one (Config:UpdateConfig, which AceDB's profile
--     callbacks run), before any module updates from it;
--   - an imported profile string (Config:Import), and so the unit frames'
--     Import, which goes through it.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (core/config_helpers.lua),
-- whose profile is filled from the defaults the way AceDB fills it; the bags',
-- chat's and unit frames' defaults; LibBase64-1.0, LibCompress and
-- AceSerializer-3.0 (loaded before config_helpers.lua, so its fixtures for them
-- stay out); the unit frames' config/config.lua, for its Import prompt, with the
-- stand-ins tests/unitframes/profiles_test.lua has for unitframes.lua (it needs
-- oUF): UF:UpdateConfig counts its calls, and UF.units and the rest of what
-- its OnEnable makes are empty, enough for UF:GetConfigTable's Profiles group.

local st

-- A fresh world logged in with saved (SaftUI_DB as the game loads it from the
-- SavedVariables file before login, or nil for a new install).
local function fresh(saved)
	reset_world()
	SaftUI_DB = saved
	load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
	load_saftui('SaftUI-Core/Libraries/LibBase64-1.0/LibBase64-1.0.lua')
	load_saftui('SaftUI-Core/Libraries/LibCompress/LibCompress.lua')
	load_saftui('SaftUI-Core/Libraries/Ace3/AceSerializer-3.0/AceSerializer-3.0.lua')
	load_test_file('core/config_helpers.lua')
	st = SaftUI
	return st
end

-- The bags', chat's and unit frames' defaults, as their addons add them before
-- login; a profile made or switched to after this is filled from them too.
local function load_module_defaults()
	load_saftui('SaftUI-Bags/config.lua')
	load_saftui('SaftUI-Chat/config.lua')
	load_saftui('SaftUI-Unitframes/config/default.lua')
	apply_defaults()
end

-- AceDB's key for this character's profile choice.
local function char_key() return UnitName('player') .. ' - ' .. GetRealmName() end

-- A profile as the old version saved it: template names, where the bags kept
-- theirs (inventory) and where the unit frames keep theirs.
local function old_profile()
	return {
		bags = { template = 'thin' },
		inventory = { template = 'thin', buttontemplate = 'thintransparent' },
		chat = { template = 'highlight' },
		unitframes = { profiles = { SaftUI = {
			player = { template = 'thick', health = { template = 'thicktransparent' }, portrait = { template = 'none' } },
		} } },
	}
end

test('old template keys migrate', function()
	fresh()
	local legacy = {
		bags = { template = 'thin', buttontemplate = 'thicktransparent' },
		chat = { template = 'highlight' },
		unitframes = { profiles = { SaftUI = { player = {
			health = { template = 'thicktransparent' }, portrait = { template = 'none' } } } } },
	}
	st:MigrateTemplateKeys(legacy)
	eq(legacy.bags.theme, 'thin'); eq(legacy.bags.background, 'solid'); eq(legacy.bags.template, nil)
	eq(legacy.bags.buttontheme, 'thick'); eq(legacy.bags.buttonbackground, 'transparent')
	eq(legacy.chat.theme, nil); eq(legacy.chat.background, nil); eq(legacy.chat.template, nil)
	local player = legacy.unitframes.profiles.SaftUI.player
	eq(player.health.theme, 'thick'); eq(player.health.background, 'transparent')
	eq(player.portrait.theme, 'none')
	st:MigrateTemplateKeys(legacy) -- a second run changes nothing
	eq(legacy.bags.background, 'solid')

	-- Each old name, and what isn't one.
	local each = {
		a = { template = 'thicktransparent' }, b = { template = 'thintransparent' },
		c = { template = 'thick' }, d = { template = 'thin' },
		e = { template = 'none', background = 'transparent' }, f = { template = 'close' },
		g = { template = 'nonsense' },
	}
	st:MigrateTemplateKeys(each)
	local function look(t) return tostring(t.theme) .. ',' .. tostring(t.background) .. ',' .. tostring(t.template) end
	eq(look(each.a), 'thick,transparent,nil', 'thicktransparent: Thick, Transparent')
	eq(look(each.b), 'thin,transparent,nil', 'thintransparent: Thin, Transparent')
	eq(look(each.c), 'thick,solid,nil', 'thick: Thick, Solid')
	eq(look(each.d), 'thin,solid,nil', 'thin: Thin, Solid')
	eq(look(each.e), 'none,transparent,nil', 'none: None, and the background left as it was')
	eq(look(each.f), 'nil,nil,nil', "close: removed, so the module's defaults apply")
	eq(look(each.g), 'nil,nil,nil', "a name that was never a template: removed, so the module's defaults apply")

	-- Only template keys: templates (the themes' colors) and other keys stay.
	local other = {
		templates = { thick = { bordercolor = { 1, 0, 0, 1 } } },
		font = 'pixel', bg = { template = 'thin' }, list = { { template = 'thick' } },
	}
	st:MigrateTemplateKeys(other)
	eq(other.templates.thick.bordercolor[1], 1, "templates, the themes' colors, untouched")
	eq(other.templates.theme, nil, 'and nothing added to it')
	eq(other.font, 'pixel', 'other keys untouched')
	eq(look(other.bg), 'thin,solid,nil', 'a table at any depth')
	eq(look(other.list[1]), 'thick,solid,nil', 'a table in a list too')

	-- The walk reads only what's saved: a table whose missing keys make
	-- themselves (AceDB's '**' defaults) gets none made, and a loop ends.
	local made = 0
	local wild = setmetatable({ unit = { template = 'thin' } }, {
		__index = function(t, k)
			made = made + 1
			local new = {}
			rawset(t, k, new)
			return new
		end,
	})
	wild.unit.self = wild
	st:MigrateTemplateKeys(wild)
	eq(made, 0, 'no key read through __index')
	eq(look(rawget(wild, 'unit')), 'thin,solid,nil', 'its saved tables migrate')
end)

test('a profile the old version saved migrates at login', function()
	fresh({ profileKeys = { [char_key()] = 'Old' }, profiles = { Old = old_profile() } })
	eq(st.config:GetCurrentProfile(), 'Old', 'logged in on the old profile')
	local p = st.config.profile
	eq(p.inventory.theme, 'thin', 'inventory.template thin: Thin')
	eq(p.inventory.background, 'solid', 'and Solid')
	eq(rawget(p.inventory, 'template'), nil, 'no template key left')
	eq(p.inventory.buttontheme, 'thin', 'buttontemplate thintransparent: Thin')
	eq(p.inventory.buttonbackground, 'transparent', 'and Transparent')
	local player = p.unitframes.profiles.SaftUI.player
	eq(player.theme .. ',' .. player.background, 'thick,solid', "a unit frame's own profile")
	eq(player.health.theme .. ',' .. player.health.background, 'thick,transparent', 'and its elements')
end)

test('a profile saved by the old version migrates on a profile switch', function()
	fresh()
	load_module_defaults()
	-- A module that updates from the bags' config, as the bags do.
	local seen
	local probe = st:NewModule('MigrationProbe')
	st:BindModuleConfig(probe, 'inventory')
	function probe:UpdateConfig()
		seen = ('%s,%s,%s'):format(tostring(self.config.theme), tostring(self.config.background),
			tostring(rawget(self.config, 'template')))
	end

	SaftUI_DB.profiles.Old = old_profile()
	st.config:SetProfile('Old')
	local p = st.config.profile
	eq(p.bags.theme, 'thin', 'bags.template thin: Thin')
	eq(p.bags.background, 'solid', 'and Solid')
	eq(rawget(p.bags, 'template'), nil, 'no template key left')
	-- AceDB filled the profile from the defaults (Use SaftUI's theme for both)
	-- before anything read it; the saved name wins over them.
	eq(p.inventory.theme, 'thin', "the bags' Thin, not the default")
	eq(p.inventory.background, 'solid', "Solid, not the default Use SaftUI's theme")
	eq(p.inventory.buttontheme .. ',' .. p.inventory.buttonbackground, 'thin,transparent', "the bags' slots")
	eq(p.chat.theme .. ',' .. p.chat.background, 'theme,theme', "chat's highlight: removed, so chat's defaults")
	eq(rawget(p.chat, 'template'), nil, "chat's template key gone")
	local player = p.unitframes.profiles.SaftUI.player
	eq(player.theme .. ',' .. player.background, 'thick,solid', 'a unit frame')
	eq(player.health.theme .. ',' .. player.health.background, 'thick,transparent', 'its health bar')
	eq(player.portrait.theme, 'none', 'its portrait: None')
	eq(seen, 'thin,solid,nil', 'modules updated from the migrated keys')

	-- What gets saved: the new keys, with no template left to migrate again.
	st.config:SetProfile('Default')
	local saved = SaftUI_DB.profiles.Old
	eq(saved.inventory.template, nil, 'the saved profile has no template key')
	eq(saved.inventory.theme .. ',' .. saved.inventory.background, 'thin,solid', 'it saves the Theme and Background')
	st.config:SetProfile('Old')
	eq(st.config.profile.inventory.theme .. ',' .. st.config.profile.inventory.background, 'thin,solid',
		'switching back finds them')
end)

test('a profile copied from one the old version saved migrates', function()
	fresh()
	load_module_defaults()
	SaftUI_DB.profiles.Old = old_profile()
	st.config:CopyProfile('Old')
	local p = st.config.profile
	eq(st.config:GetCurrentProfile(), char_key(), "still on this character's profile")
	eq(p.inventory.theme .. ',' .. p.inventory.background, 'thin,solid', 'the copied bags')
	eq(rawget(p.inventory, 'template'), nil, 'no template key copied in')
	local player = p.unitframes.profiles.SaftUI.player
	eq(player.health.theme .. ',' .. player.health.background, 'thick,transparent', 'the copied unit frames')
end)

-- Text as Config:Export gives it for data: AceSerializer's text, compressed
-- by LibCompress, in Base64. An export picks LibCompress's smallest codec;
-- this one is stored uncompressed (LibCompress:Store), since the stubbed bit
-- library has only band and the other codecs need the rest. Import reads any
-- codec the same way.
local function export_text(data)
	local serialized = LibStub('AceSerializer-3.0'):Serialize(data)
	return LibStub('LibBase64-1.0').Encode(LibStub('LibCompress'):Store(serialized))
end

test('an imported old profile string migrates', function()
	fresh()
	-- A unit frame profile the old version exported.
	local old = {
		player = { template = 'thick', health = { template = 'thicktransparent', height = 7 } },
		target = { power = { template = 'thin' } },
	}
	local ok, data = st.Config:Import(export_text(old))
	eq(ok, true, 'Import reads it')
	eq(data.player.theme .. ',' .. data.player.background, 'thick,solid', 'the unit')
	eq(data.player.health.theme .. ',' .. data.player.health.background, 'thick,transparent', 'its health bar')
	eq(data.player.health.height, 7, 'the rest as it was')
	eq(data.target.power.theme .. ',' .. data.target.power.background, 'thin,solid', 'another unit')
	eq(data.player.template, nil, 'no template keys')
	eq(data.player.health.template, nil, 'none at all')
	eq((st.Config:Import('not an export')), false, 'junk is still refused')

	-- The unit frames' Import prompt goes through it.
	load_saftui('SaftUI-Unitframes/config/default.lua')
	apply_defaults()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionswidgets.lua')
	local UF = st:NewModule('Unitframes')
	function UF:UpdateConfig() end
	UF.units, UF.groups, UF.holders, UF.elements = {}, {}, {}, {}
	UF.unit_strings, UF.group_strings = {}, {}
	function UF:GetMoverFrame(unit) return self.holders[unit] or self.units[unit] end
	load_saftui('SaftUI-Unitframes/config/config.lua')

	UF:GetConfigTable().args.profile.args.import.func()
	local W = st.OptionsWidgets
	W.PromptBox():SetText(export_text(old))
	stub.fire_script(W.PromptBox(), 'OnEnterPressed')
	local profiles = st.config.profile.unitframes
	eq(profiles.config_profile, 'Imported', "the import is the unit frames' profile now")
	local imported = profiles.profiles.Imported
	eq(imported.player.health.theme .. ',' .. imported.player.health.background, 'thick,transparent',
		"the imported profile's health bar")
	eq(rawget(imported.player, 'template'), nil, "no template key in the unit frames' profile")
end)
