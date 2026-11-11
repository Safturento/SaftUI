-- The unit frame profile prompts in SaftUI-Unitframes/config/config.lua: New,
-- Copy, Rename, Delete, Export and Import, drawn by SaftUI's own dialog
-- (st.OptionsWidgets Prompt and Confirm, which show over the /sui window).
-- Migrated from the ufprofsim harness. The prompts are driven the way a user
-- does: typing into the prompt's box and pressing Enter, clicking a button, Esc.
-- The profile is Core's and the unit frames' real defaults, filled the way
-- AceDB fills them (apply_defaults), so a profile is made by reading it from
-- profiles, as in game, and the real '**' defaults give it its units.
--
-- Stand-ins, each for a file that can't load here, and each only the
-- contract the prompts use:
--   * UF:UpdateConfig is unitframes.lua's (it needs oUF). It counts its calls.
--   * UF.units and the rest of what its OnEnable makes: empty, enough for
--     UF:GetConfigTable, whose Profiles group holds the buttons pressed here.
--   * st.Config:Export and Import are SaftUI-Core/Config/config.lua's, which
--     needs AceDB, AceConfigRegistry and others. The real ones turn the data
--     into text and back (Base64 of compressed AceSerializer text); these
--     take the text 'GOOD' for { target = { width = 9 } } and any other text
--     for no profile, and Export records what it was given and returns
--     'EXPORTED'. The real Base64 / compress / serialize round trip is not
--     tested here.
load_core_helpers()
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionswidgets.lua')
load_saftui('SaftUI-Unitframes/config/default.lua')
apply_defaults()

local st = SaftUI
local W = st.OptionsWidgets
local UF = st:NewModule('Unitframes')
local updates = 0
function UF:UpdateConfig() updates = updates + 1 end
-- What unitframes.lua's OnEnable makes, as far as UF:GetConfigTable reads it
-- (as tests/unitframes/config_test.lua has it): no units, groups or elements.
UF.units, UF.groups, UF.holders, UF.elements = {}, {}, {}, {}
UF.unit_strings, UF.group_strings = {}, {}
function UF:GetMoverFrame(unit) return self.holders[unit] or self.units[unit] end

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

local function profile_buttons() return UF:GetConfigTable().args.profile.args end

-- Presses a Profiles button (New, Copy, Delete, ...) as the options window does.
local function press(key) profile_buttons()[key].func() end

local D = W.GetDialogFrames
local function box() return W.PromptBox() end
local function type_and_enter(text)
	box():SetText(text)
	stub.fire_script(box(), 'OnEnterPressed')
end
local function esc() stub.fire_script(box(), 'OnEscapePressed') end
local function count_profiles()
	local n = 0
	for _ in pairs(P.profiles) do n = n + 1 end
	return n
end

test('rename prefills the current name, keeps the settings and switches to it', function()
	press('rename')
	eq(W.ConfirmText(), 'Enter a new profile name', 'the prompt')
	eq(box():GetText(), 'SaftUI', 'rename prefills the current name')
	local before = updates
	type_and_enter('  Main  ')
	check(rawget(P.profiles, 'Main') and P.profiles.Main.player.width == 1 and rawget(P.profiles, 'SaftUI') == nil, 'renamed, settings kept, old gone')
	check(P.config_profile == 'Main', 'switched to renamed profile')
	eq(updates, before + 1, 'the unit frames were updated once')
	eq(W.PromptBox(), nil, 'the prompt closed')
end)

test('rename refuses a taken name, the wildcard key and an empty name', function()
	P.profiles.Other = {}
	press('rename')
	type_and_enter('Other')
	check(P.config_profile == 'Main' and rawget(P.profiles, 'Main') and #printed == 1, 'taken name refused with a message')
	press('rename')
	type_and_enter('**')
	check(rawget(P.profiles, '**') == nil and P.config_profile == 'Main', "'**' refused")
	press('rename')
	type_and_enter('')
	check(P.config_profile == 'Main', 'empty refused')
	press('rename')
	type_and_enter('Main')
	check(P.config_profile == 'Main' and #printed == 1, 'the same name does nothing, with no message')
end)

test('rename: Esc and the cancel button change nothing', function()
	press('rename')
	box():SetText('Nope')
	esc()
	check(rawget(P.profiles, 'Nope') == nil and P.config_profile == 'Main', 'Esc cancels')
	press('rename')
	box():SetText('Nope')
	stub.fire_script(D().no, 'OnClick')
	check(rawget(P.profiles, 'Nope') == nil and P.config_profile == 'Main', 'the cancel button cancels')
	press('rename')
	box():SetText('Nope')
	stub.fire_script(D().catcher, 'OnMouseDown')
	check(rawget(P.profiles, 'Nope') == nil and P.config_profile == 'Main', 'a click outside cancels')
end)

test('export shows the current profile in a box, with one Close button', function()
	press('export')
	check(box():GetText() == 'EXPORTED' and exportData == P.profiles.Main, 'export shows the current profile')
	eq(box():GetMaxLetters(), 0, 'export uncapped')
	eq(D().yes.text:GetText(), 'Close', 'the one button is Close')
	check(D().yes:IsShown() and not D().no:IsShown(), 'and it is the only one')
	local count = count_profiles()
	stub.fire_script(D().yes, 'OnClick')
	eq(W.PromptBox(), nil, 'Close closes it')
	eq(count_profiles(), count, 'and changes nothing')
end)

test('import makes Imported, then Imported 2, and refuses junk with a message', function()
	press('import')
	eq(box():GetMaxLetters(), 0, 'import uncapped')
	eq(box():GetText(), '', 'import starts empty')
	type_and_enter('GOOD')
	check(P.profiles.Imported and P.profiles.Imported.target.width == 9 and P.config_profile == 'Imported', 'import makes Imported')
	press('import')
	type_and_enter('GOOD')
	check(P.profiles['Imported 2'] and P.config_profile == 'Imported 2', 'second import makes Imported 2')
	local n = #printed
	press('import')
	type_and_enter('junk')
	check(#printed == n + 1 and P.config_profile == 'Imported 2', 'junk refused with a message')
	press('import')
	box():SetText('GOOD')
	stub.fire_script(D().yes, 'OnClick')
	check(P.profiles['Imported 3'], 'the accept button imports too')
end)

test('new copies the current profile when asked, and not otherwise', function()
	press('copy')
	type_and_enter('Copied')
	check(P.profiles.Copied and P.profiles.Copied.target.width == 9, 'copy copies the current profile')
	eq(P.config_profile, 'Copied', 'and switches to it')
	press('new')
	type_and_enter('Fresh')
	check(rawget(P.profiles, 'Fresh') == nil and P.config_profile == 'Fresh', 'new does not copy (AceDB fills it)')
end)

test('new and copy refuse an empty name, the wildcard key and a taken name', function()
	local count, current = count_profiles(), P.config_profile
	for _, key in ipairs({ 'new', 'copy' }) do
		for _, name in ipairs({ '', '   ', '**', ' ** ' }) do
			press(key)
			type_and_enter(name)
			eq(count_profiles(), count, key .. ' with ' .. string.format('%q', name) .. ' creates nothing')
			eq(P.config_profile, current, key .. ' does not switch')
		end
	end
	check(rawget(P.profiles, '') == nil and rawget(P.profiles, '**') == nil, 'no such key')
	local n = #printed
	press('new')
	type_and_enter('Copied')
	eq(#printed, n + 1, 'a taken name prints a message')
	eq(P.config_profile, current, 'and does not switch')
	press('new')
	type_and_enter('  Trimmed  ')
	eq(P.config_profile, 'Trimmed', 'names are trimmed')
end)

test('delete asks first, removes the current profile and switches to another', function()
	local _ = P.profiles[P.config_profile] -- the page reads the profile it shows, which makes it (AceDB)
	local count = count_profiles()
	check(count > 1, 'more than one profile to start')
	local current = P.config_profile
	press('delete')
	eq(W.ConfirmText(), 'Are you sure you wish to delete this profile?', 'asks')
	eq(W.PromptBox(), nil, 'a confirm, not a prompt')
	stub.fire_script(D().no, 'OnClick')
	eq(count_profiles(), count, 'No deletes nothing')
	press('delete')
	stub.fire_script(D().yes, 'OnClick')
	eq(count_profiles(), count - 1, 'Yes deletes one')
	check(rawget(P.profiles, current) == nil, 'the current profile is gone')
	check(P.config_profile ~= current and rawget(P.profiles, P.config_profile) ~= nil, 'switched to one that exists')
end)

test('delete does nothing with only one profile', function()
	for name in pairs(P.profiles) do
		if name ~= P.config_profile then P.profiles[name] = nil end
	end
	local only = P.config_profile
	press('delete')
	eq(W.ConfirmText(), nil, 'no question')
	check(rawget(P.profiles, only) ~= nil, 'the profile stays')
end)

test('a prompt opened over an open confirm answers the confirm No; Esc cancels a prompt', function()
	local answered = {}
	W.Confirm('Sure?', function() answered[#answered + 1] = 'yes' end, function() answered[#answered + 1] = 'no' end)
	press('rename')
	eq(answered[1], 'no', 'the open confirm is answered No')
	check(box() ~= nil, 'the prompt is up')
	local name = P.config_profile
	box():SetText('Whatever')
	esc()
	eq(W.PromptBox(), nil, 'Esc closes the prompt')
	eq(P.config_profile, name, 'and changes nothing')
	check(rawget(P.profiles, 'Whatever') == nil, 'no profile made')
end)
