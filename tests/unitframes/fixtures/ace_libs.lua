-- The Ace3 libraries SaftUI-Unitframes/config/config.lua takes from LibStub
-- when it loads. Real LibStub (SaftUI-Core/Libraries/LibStub), so a library
-- nobody registered errors, as in game ("Cannot find a library instance of
-- ...").
--
-- Each library has only the methods the loaded files call. config.lua keeps
-- both in locals and uses them only in the copy-from window (AceConfig's
-- RegisterOptionsTable, AceConfigDialog's Open and Close, ...), which no test
-- opens, so they have none yet. Add a method here, behaving as the library's,
-- when a test reaches a path that calls it.
load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')

for _, name in ipairs({ 'AceConfigDialog-3.0', 'AceConfig-3.0' }) do
	LibStub:NewLibrary(name, 1)
end
