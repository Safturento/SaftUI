-- The world SaftUI's /sui option tree is built in: Core's real
-- Config/config.lua on a real AceDB-3.0, as after login. Not a test (no _test
-- suffix), so the runner doesn't run it. A test file sets the world up with
-- load_test_file('core/config_helpers.lua'); then st.Config:GetOptionsTable()
-- builds the real tree, and st.config is a real AceDB database whose profile
-- changes run Config:UpdateConfig.
--
-- Real: LibStub, CallbackHandler, AceDB-3.0, AceDBOptions-3.0 (the profiles
-- table), AceConfigRegistry-3.0 (Config:Refresh notifies it),
-- Config/config.lua, Core's helpers (load_core_helpers, Config/widgets.lua's
-- generators among them) and edit mode (EditMode/load.xml's files;
-- InitializeAceConfig listens to it). Fixtures (fixtures/config_libs.lua): the
-- libraries config.lua uses only for Export and Import.
--
-- The /sui window (Config/optionsmodel.lua, optionswidgets.lua and
-- optionswindow.lua, which config.lua's Open, Close and GetWindow use) isn't
-- loaded here: a test that opens /sui loads those three after this
-- (options_window_test.lua).
--
-- Modules a test wants in the tree (e.g. SaftUI-Misc/experience.lua) load
-- after this, and the test enables them.

local st = SaftUI

-- Core's TOC loads its libraries, Ace3 among them, before any SaftUI file.
load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
load_saftui('SaftUI-Core/Libraries/CallbackHandler-1.0/CallbackHandler-1.0.lua')
load_saftui('SaftUI-Core/Libraries/Ace3/AceDB-3.0/AceDB-3.0.lua')
load_saftui('SaftUI-Core/Libraries/Ace3/AceDBOptions-3.0/AceDBOptions-3.0.lua')
load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
load_test_file('core/fixtures/config_libs.lua')

-- config.lua makes the Config module itself, so the shell's goes first. Then
-- Core's helpers, which come after config.lua in the TOC (Config/widgets.lua
-- adds to st.Config), and edit mode.
remove_shell_config()
load_saftui('SaftUI-Core/Config/config.lua')
load_core_helpers()
for _, file in ipairs({ 'editmode', 'mover', 'picker', 'footer', 'grid', 'snap', 'settings' }) do
	load_saftui('SaftUI-Core/EditMode/' .. file .. '.lua')
end

-- What SaftUI:OnEnable (init.lua) does at login: st.config becomes a real
-- AceDB database over the profile defaults, and /sui is set up.
st.Config:InitializeAceConfig()
