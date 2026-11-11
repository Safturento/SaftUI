local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The game's nameplate settings (its CVars) that SaftUI sets while its plates
	are drawn, and puts back when Nameplates is turned off.

	The first time SaftUI changes a setting, the user's own value is recorded
	in st.config.char.nameplateCVars: per character (each character puts back
	its own, whether the game keeps a setting per character or per account)
	and outside any profile. Turning Nameplates off, or logging in with it off,
	sets each recorded value back and clears it from the record, so the next
	time SaftUI's plates are on it records whatever is set then. A value the
	game refuses to take back stays recorded, to be put back next time.

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
	local char = st.config.char
	char.nameplateCVars = char.nameplateCVars or {}
	if char.nameplateCVars[name] == nil then
		char.nameplateCVars[name] = current
	end
	C_CVar.SetCVar(name, value)
end

-- Sets every UF.NAMEPLATE_CVARS setting from the nameplate config, while
-- SaftUI's plates are drawn (there's a driver: UF:SpawnNameplates) and
-- Nameplates is on. Turned off with the reload declined, the plates stay up
-- until the next one, but the game's settings are the user's again, so
-- nothing is set; checked before waiting out combat too, so it never takes
-- the place of a restore that waits under the same key.
function UF:ApplyNameplateCVars()
	if not self.plateDriver then return end
	if not self:GetProfileConfig().nameplate.enable then return end
	if st:QueueAfterCombat('NameplateCVars', function() UF:ApplyNameplateCVars() end) then return end
	local config = self:GetProfileConfig().nameplate
	for name, value in pairs(UF.NAMEPLATE_CVARS) do
		self:SetNameplateCVar(name, value(config))
	end
end

-- Puts back every setting SaftUI recorded, clearing each the game takes. One
-- it refuses (C_CVar.SetCVar gives false) stays recorded, so the user's value
-- isn't lost; the record goes once it's empty.
function UF:RestoreNameplateCVars()
	if st:QueueAfterCombat('NameplateCVars', function() UF:RestoreNameplateCVars() end) then return end
	local record = st.config.char.nameplateCVars
	if not record then return end
	local kept = {}
	for name, value in pairs(record) do
		if not C_CVar.SetCVar(name, value) then
			kept[name] = value
		end
	end
	st.config.char.nameplateCVars = next(kept) and kept or nil
end
