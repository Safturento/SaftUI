-- The unit frame profile popups in SaftUI-Unitframes/config/config.lua:
-- Rename, Export, Import and New/Copy. Migrated from the ufprofsim harness.
-- The profile is Core's and the unit frames' real defaults, filled the way
-- AceDB fills them (apply_defaults), so a profile is made by reading it from
-- profiles, as in game, and the real '**' defaults give it its units.
--
-- Stand-ins, each for a file that can't load here, and each only the
-- contract the popups use:
--   * UF:UpdateConfig is unitframes.lua's (it needs oUF). It counts its calls.
--   * st.Config:Export and Import are SaftUI-Core/Config/config.lua's, which
--     needs AceDB, AceConfigDialog and others. The real ones turn the data
--     into text and back (Base64 of compressed AceSerializer text); these
--     take the text 'GOOD' for { target = { width = 9 } } and any other text
--     for no profile, and Export records what it was given and returns
--     'EXPORTED'. The real Base64 / compress / serialize round trip is not
--     tested here.
--   * The popup is a frame with GetEditBox, as Blizzard's StaticPopup has on
--     current clients (config.lua's EditBoxOf). Its edit box is a real one.
load_saftui('SaftUI-Core/Config/defaults.lua')
load_saftui('SaftUI-Unitframes/config/default.lua')
apply_defaults()
load_test_file('unitframes/fixtures/ace_libs.lua')

local st = SaftUI
local UF = st:NewModule('Unitframes')
local updates = 0
function UF:UpdateConfig() updates = updates + 1 end

local exportData
function st.Config:Export(data) exportData = data; return 'EXPORTED' end
function st.Config:Import(text)
	if text == 'GOOD' then return true, { target = { width = 9 } } end
	return false
end

load_saftui('SaftUI-Unitframes/config/config.lua')

-- st:Print goes to print. Count what it prints.
local printed = {}
local real_print = print
print = function(...)
	printed[#printed + 1] = select('#', ...)
	return real_print(...)
end

local P = st.config.profile.unitframes
P.profiles.SaftUI.player.width = 1 -- reading profiles.SaftUI makes it, from the defaults

local function dialog(text)
	local popup = CreateFrame('Frame', nil, UIParent)
	local editbox = CreateFrame('EditBox', nil, popup)
	editbox:SetText(text or '')
	popup.GetEditBox = function() return editbox end
	return popup, editbox
end

local POPUP = StaticPopupDialogs

test('rename prefills the current name, keeps the settings and switches to it', function()
	local d, box = dialog()
	POPUP.SAFTUI_UF_PROFILE_RENAME.OnShow(d)
	eq(box:GetText(), 'SaftUI', 'rename prefills the current name')
	box:SetText('  Main  ')
	local before = updates
	POPUP.SAFTUI_UF_PROFILE_RENAME.OnAccept(d)
	check(rawget(P.profiles, 'Main') and P.profiles.Main.player.width == 1 and rawget(P.profiles, 'SaftUI') == nil, 'renamed, settings kept, old gone')
	check(P.config_profile == 'Main', 'switched to renamed profile')
	eq(updates, before + 1, 'the unit frames were updated once')
end)

test('rename refuses a taken name, the wildcard key and an empty name', function()
	local d, box = dialog()
	P.profiles.Other = {}
	box:SetText('Other'); POPUP.SAFTUI_UF_PROFILE_RENAME.OnAccept(d)
	check(P.config_profile == 'Main' and rawget(P.profiles, 'Main') and #printed == 1, 'taken name refused with a message')
	box:SetText('**'); POPUP.SAFTUI_UF_PROFILE_RENAME.OnAccept(d)
	check(rawget(P.profiles, '**') == nil and P.config_profile == 'Main', "'**' refused")
	box:SetText(''); POPUP.SAFTUI_UF_PROFILE_RENAME.OnAccept(d)
	check(P.config_profile == 'Main', 'empty refused')
end)

test('export shows the current profile', function()
	local e, box = dialog(); POPUP.SAFTUI_UF_PROFILE_EXPORT.OnShow(e)
	check(box:GetText() == 'EXPORTED' and exportData == P.profiles.Main, 'export shows the current profile')
	check(POPUP.SAFTUI_UF_PROFILE_EXPORT.maxLetters == 0, 'export uncapped')
end)

test('import makes Imported, then Imported 2, and refuses junk with a message', function()
	local i = dialog('GOOD'); POPUP.SAFTUI_UF_PROFILE_IMPORT.OnAccept(i)
	check(P.profiles.Imported and P.profiles.Imported.target.width == 9 and P.config_profile == 'Imported', 'import makes Imported')
	POPUP.SAFTUI_UF_PROFILE_IMPORT.OnAccept(i)
	check(P.profiles['Imported 2'] and P.config_profile == 'Imported 2', 'second import makes Imported 2')
	local n = #printed
	POPUP.SAFTUI_UF_PROFILE_IMPORT.OnAccept(dialog('junk'))
	check(#printed == n + 1 and P.config_profile == 'Imported 2', 'junk refused with a message')
end)

test('new copies the current profile when asked, and not otherwise', function()
	local c = dialog('Copied'); POPUP.SAFTUI_UF_PROFILE_NEW.OnAccept(c, { copy = true })
	check(P.profiles.Copied and P.profiles.Copied.target.width == 9, 'copy copies the current profile')
	local nw = dialog('Fresh'); POPUP.SAFTUI_UF_PROFILE_NEW.OnAccept(nw, nil)
	check(rawget(P.profiles, 'Fresh') == nil and P.config_profile == 'Fresh', 'new does not copy (AceDB fills it)')
end)
