local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The game's nameplate settings (its CVars) that SaftUI sets while its plates
	are drawn, and puts back when Nameplates is turned off.

	The first time SaftUI changes a setting, the user's own value is recorded
	in st.config.global.nameplateCVars (account-wide, like the game's settings,
	and outside any profile). Turning Nameplates off, or logging in with it off,
	sets each recorded value back and clears the record, so the next time
	SaftUI's plates are on it records whatever is set then.

	The game refuses some of these from addon code in combat, so every change
	waits for the end of combat. While another nameplate addon draws the plates
	(UF:NameplateAddon) nothing is set or put back: that addon owns them.
]]

-- Each setting SaftUI sets while its plates are on, by name, and its value
-- (a string, as the game keeps them) from the nameplate config.
UF.NAMEPLATE_CVARS = {
	-- Friendly plates (the page's toggle): the game shows plates over friendly
	-- players and NPCs only while these are on.
	nameplateShowFriendlyPlayers = function(config) return config.friendly and '1' or '0' end,
	nameplateShowFriendlyNpcs = function(config) return config.friendly and '1' or '0' end,
}

-- Sets one of the game's settings, recording the user's value the first time.
-- A setting this client doesn't have (C_CVar.GetCVar gives nil) is skipped.
-- Out of combat only: callers wait for the end of combat.
function UF:SetNameplateCVar(name, value)
	local current = C_CVar.GetCVar(name)
	if current == nil then return end
	local global = st.config.global
	global.nameplateCVars = global.nameplateCVars or {}
	if global.nameplateCVars[name] == nil then
		global.nameplateCVars[name] = current
	end
	C_CVar.SetCVar(name, value)
end

-- Sets every UF.NAMEPLATE_CVARS setting from the nameplate config, while
-- SaftUI's plates are drawn (there's a driver: UF:SpawnNameplates).
function UF:ApplyNameplateCVars()
	if not self.plateDriver then return end
	if st:QueueAfterCombat('NameplateCVars', function() UF:ApplyNameplateCVars() end) then return end
	local config = self:GetProfileConfig().nameplate
	for name, value in pairs(UF.NAMEPLATE_CVARS) do
		self:SetNameplateCVar(name, value(config))
	end
end

-- Puts back every setting SaftUI recorded, then clears the record.
function UF:RestoreNameplateCVars()
	if st:QueueAfterCombat('NameplateCVars', function() UF:RestoreNameplateCVars() end) then return end
	local record = st.config.global.nameplateCVars
	if not record then return end
	for name, value in pairs(record) do
		C_CVar.SetCVar(name, value)
	end
	st.config.global.nameplateCVars = nil
end
