-- Icons for the non-item feed entries (skill ups, experience, reputation).
-- All values are fileDataIDs from the community listfile.

local st = SaftUI
local LT = st.Loot

LT.FEED_ICONS = {
	Experience = 397907,       -- Interface/ICONS/LEVELUPICON-LFD
	ReputationUp = 236685,     -- Interface/ICONS/Achievement_Reputation_05
	ReputationDown = 236683,   -- Interface/ICONS/Achievement_Reputation_03
	SkillFallback = 133741,    -- Interface/ICONS/INV_Misc_Book_09
}

-- skillLineID -> { icon fileDataID, enUS name }
-- The enUS name is only a fallback for when the skill line API can't give us
-- the localized name for an ID.
local SKILLS = {
	-- weapons / combat
	[43]  = { 135274, 'Swords' },
	[44]  = { 132392, 'Axes' },
	[45]  = { 135495, 'Bows' },
	[46]  = { 135610, 'Guns' },
	[54]  = { 133476, 'Maces' },
	[55]  = { 135274, 'Two-Handed Swords' },
	[95]  = { 132110, 'Defense' },
	[118] = { 132147, 'Dual Wield' },
	[136] = { 135145, 'Staves' },
	[160] = { 133476, 'Two-Handed Maces' },
	[162] = { 132938, 'Unarmed' },
	[172] = { 132392, 'Two-Handed Axes' },
	[173] = { 135641, 'Daggers' },
	[176] = { 135426, 'Thrown' },
	[226] = { 135530, 'Crossbows' },
	[228] = { 135463, 'Wands' },
	[229] = { 135124, 'Polearms' },
	[473] = { 132938, 'Fist Weapons' },
	-- secondary
	[129] = { 133685, 'First Aid' },
	[185] = { 133971, 'Cooking' },
	[356] = { 132932, 'Fishing' },
	[762] = { 132261, 'Riding' },
	[794] = { 441139, 'Archaeology' },
	-- professions
	[164] = { 136241, 'Blacksmithing' },
	[165] = { 136247, 'Leatherworking' },
	[171] = { 136240, 'Alchemy' },
	[182] = { 136246, 'Herbalism' },
	[186] = { 136248, 'Mining' },
	[197] = { 136249, 'Tailoring' },
	[202] = { 136243, 'Engineering' },
	[333] = { 136244, 'Enchanting' },
	[393] = { 134366, 'Skinning' },
	[633] = { 134237, 'Lockpicking' },
	[755] = { 134071, 'Jewelcrafting' },
	[773] = { 237171, 'Inscription' },
}

-- Extra enUS names the client has used for the same skill lines.
local ALIASES = {
	['One-Handed Axes'] = 132392,
	['One-Handed Maces'] = 133476,
	['One-Handed Swords'] = 135274,
	['Fist Weapon'] = 132938,
}

local iconByName = {}
local indexed = false
local scanned = {} -- skill names whose spellbook/skill list we've already searched

local function addName(name, icon)
	if type(name) == 'string' and not issecretvalue(name) and name ~= '' then
		iconByName[name] = icon
	end
end

-- Map localized names (from the skill line API) and enUS names to icons.
local function indexKnownSkills()
	if indexed then return end
	indexed = true

	for id, data in pairs(SKILLS) do
		addName(data[2], data[1])
		if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
			local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, id)
			if ok and info then addName(info.name, data[1]) end
		end
	end
	for name, icon in pairs(ALIASES) do
		addName(name, icon)
	end
end

-- Walk the character's own skill list for an exact name match, then use its skillID.
local function findInSkillList(name)
	if scanned[name] then return end
	scanned[name] = true
	if not (C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo) then return end

	local ok, num = pcall(C_SkillInfo.GetNumSkillLines)
	if not ok or type(num) ~= 'number' then return end

	for i = 1, num do
		local ok2, info = pcall(C_SkillInfo.GetSkillLineInfo, i)
		if ok2 and info and not info.isHeader and info.name == name and SKILLS[info.skillID] then
			addName(name, SKILLS[info.skillID][1])
			return
		end
	end
end

function LT:GetSkillIcon(skillName)
	if type(skillName) ~= 'string' or issecretvalue(skillName) then
		return self.FEED_ICONS.SkillFallback
	end

	indexKnownSkills()
	if iconByName[skillName] then return iconByName[skillName] end

	findInSkillList(skillName)
	if iconByName[skillName] then return iconByName[skillName] end

	-- Unmapped skill: try the spell of the same name (works for professions), else generic.
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, texture = pcall(C_Spell.GetSpellTexture, skillName)
		if ok and texture and not issecretvalue(texture) then
			iconByName[skillName] = texture
			return texture
		end
	end

	return self.FEED_ICONS.SkillFallback
end
