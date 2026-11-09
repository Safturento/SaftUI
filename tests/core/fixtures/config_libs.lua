-- The libraries SaftUI-Core/Config/config.lua takes from LibStub when it
-- loads but calls only in paths the config tests don't reach:
--   AceConfig-3.0 and AceConfigDialog-3.0: the AceConfigDialog /sui window
--     (Config:Open, PLAYER_REGEN_DISABLED, and the rebuild on a profile change
--     while that window is open);
--   AceSerializer-3.0, LibCompress and LibBase64-1.0: Config:Export and Import.
-- Real LibStub (SaftUI-Core/Libraries/LibStub), so a library nobody
-- registered errors, as in game. Each has no methods, so a path that reaches
-- one errors naming the method: add it here, behaving as the library's, when
-- a test needs it.
for _, name in ipairs({ 'AceConfig-3.0', 'AceConfigDialog-3.0', 'AceSerializer-3.0', 'LibCompress', 'LibBase64-1.0' }) do
	LibStub:NewLibrary(name, 1)
end
