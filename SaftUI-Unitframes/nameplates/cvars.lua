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
-- (a string, as the game keeps them) from the nameplate config and the
-- setting's value now: value(config, current).
UF.NAMEPLATE_CVARS = {
	-- Friendly plates (the page's toggle): the game shows plates over friendly
	-- players and NPCs only while these are on.
	nameplateShowFriendlyPlayers = function(config) return config.friendly and '1' or '0' end,
	nameplateShowFriendlyNpcs = function(config) return config.friendly and '1' or '0' end,
	-- The plates' scale: the game scales each plate by its distance, and the
	-- target's up. SaftUI's frame on a plate keeps UIParent's scale
	-- (pixels.lua) but covers its plate, so a scaled plate would make it
	-- another size, off whole pixels. At 1 every plate keeps the size SaftUI
	-- gives it.
	nameplateMinScale = function() return '1' end,
	nameplateMaxScale = function() return '1' end,
	nameplateSelectedScale = function() return '1' end,
	-- Simplified plates, which the game draws smaller for the types the user
	-- picks (minions, minor mobs, friendly players and NPCs). The setting is a
	-- bit array the game keeps as text: a version character, then the bits,
	-- six to a character (CVarCallbackRegistry:SetCVarBitfieldMask,
	-- CvarUtil.lua, both clients). Its version character alone has no bit set,
	-- so it simplifies nothing: what Blizzard's settings write when every type
	-- is unticked.
	nameplateSimplifiedTypes = function(_, current) return current:sub(1, 1) end,
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
	-- Only a setting that differs: one the user toggled themselves (Blizzard's
	-- friendly plates key binding toggles players alone) stays as they left it
	-- until Friendly plates itself changes.
	if current ~= value then
		C_CVar.SetCVar(name, value)
	end
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
		-- A setting this client doesn't have is skipped.
		local current = C_CVar.GetCVar(name)
		if current ~= nil then
			self:SetNameplateCVar(name, value(config, current))
		end
	end
	-- What Friendly plates was when they were set (UF:ApplyConfig sets them
	-- again only when a profile switch changes it).
	self.appliedFriendly = config.friendly and true or false
	-- Blizzard re-anchors its plates' widgets and sets their click areas when
	-- the friendly NPC setting changes (UpdateWidgetsOnlyMode is a CVar
	-- callback, which the game runs as the setting is set): put both back on
	-- the plates SaftUI shows.
	self:RefreshPlateWidgets()
end

-- Puts back every setting SaftUI recorded, clearing each the game takes. One
-- it refuses (C_CVar.SetCVar gives false) stays recorded, so the user's value
-- isn't lost; the record goes once it's empty.
function UF:RestoreNameplateCVars()
	if st:QueueAfterCombat('NameplateCVars', function() UF:RestoreNameplateCVars() end) then return end
	self.appliedFriendly = nil
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
