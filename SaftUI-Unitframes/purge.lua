local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The filters every aura element's group is built and updated with, and
	"Only buffs I can purge", a toggle on every unit's Buffs.

	Aura data is secret in combat, so only Blizzard's AuraContainer filters
	work: a filter string, and candidate filters that Blizzard's own code
	checks against each aura (AuraContainerUtil.DoesAuraPassCandidateFilters).
	There is no filter for "the player alone can remove it":
	RAID_PLAYER_DISPELLABLE keeps the buffs anyone in the raid can dispel (the
	player alone when solo), and the dispel types the player's own spells
	remove narrow that down (includeDispelTypes). So SaftUI keeps a table of
	those spells and asks the spellbook which the player knows.
]]

--[[
	The purge, dispel and steal spells that take a buff off an enemy, by
	client and class, and what each removes: Magic, Enrage (dispel types 1 and
	9) or stealable (a steal). pet: the spell is the pet's, in the pet's
	spellbook.

	Checked on 2026-11-11 against wago.tools' SpellName, SpellEffect,
	SpellDispelType, SkillLineAbility and TraitDefinition tables at Forever
	1.60.1.70888 and retail 12.1.5.70783: each ID's name, and an effect that
	dispels (Effect 38, the dispel type its EffectMiscValue_0) or steals a buff
	(Effect 126). What each removes is read from those effects.

	forever: every ID named Purge, Dispel Magic, Devour Magic or Tranquilizing
	Shot with such an effect and a SkillLineAbility row on its class's skill
	line, the ranks a player learns: Purge 370 and 8012 (Elemental Combat),
	Dispel Magic 527 and 988 (Discipline), the felhunter's Devour Magic 19505,
	19731, 19734 and 19736 (Pet - Felhunter), and Tranquilizing Shot 19801
	(Beast Mastery), which removes dispel type 9, there named Frenzy. The other
	IDs with those names are on no skill line (NPCs' and items' spells).
	Forever has no Greater Purge, Consume Magic or Spellsteal, and its Soothe
	(2908 is Soothe Animal) and Shivs (5938, 424799, 424800) remove nothing,
	so it has no entry for the demon hunter, mage, druid or rogue.

	live: Purge 370, Greater Purge 378773, Dispel Magic 528 (527 is Purify
	there), Consume Magic 278326, Tranquilizing Shot 19801 (Enrage and Magic),
	Spellsteal 30449, Soothe 2908 and Shiv 5938, each a talent
	(TraitDefinition), and the felhunter's Devour Magic 19505 (Pet -
	Felhunter). Forever's other ranks (8012, 988, 19731, 19734, 19736) don't
	exist there.
]]
UF.PURGE_SPELLS = {
	forever = {
		SHAMAN = {
			{ id = 370, removes = { 'Magic' } }, -- Purge (Rank 1)
			{ id = 8012, removes = { 'Magic' } }, -- Purge (Rank 2)
		},
		PRIEST = {
			{ id = 527, removes = { 'Magic' } }, -- Dispel Magic (Rank 1)
			{ id = 988, removes = { 'Magic' } }, -- Dispel Magic (Rank 2)
		},
		HUNTER = {
			{ id = 19801, removes = { 'Enrage' } }, -- Tranquilizing Shot
		},
		WARLOCK = {
			{ id = 19505, removes = { 'Magic' }, pet = true }, -- Devour Magic (Rank 1)
			{ id = 19731, removes = { 'Magic' }, pet = true }, -- Devour Magic (Rank 2)
			{ id = 19734, removes = { 'Magic' }, pet = true }, -- Devour Magic (Rank 3)
			{ id = 19736, removes = { 'Magic' }, pet = true }, -- Devour Magic (Rank 4)
		},
	},
	live = {
		SHAMAN = {
			{ id = 370, removes = { 'Magic' } }, -- Purge
			{ id = 378773, removes = { 'Magic' } }, -- Greater Purge
		},
		PRIEST = {
			{ id = 528, removes = { 'Magic' } }, -- Dispel Magic
		},
		DEMONHUNTER = {
			{ id = 278326, removes = { 'Magic' } }, -- Consume Magic
		},
		HUNTER = {
			{ id = 19801, removes = { 'Magic', 'Enrage' } }, -- Tranquilizing Shot
		},
		WARLOCK = {
			{ id = 19505, removes = { 'Magic' }, pet = true }, -- Devour Magic
		},
		MAGE = {
			{ id = 30449, removes = { 'stealable' } }, -- Spellsteal
		},
		DRUID = {
			{ id = 2908, removes = { 'Enrage' } }, -- Soothe
		},
		ROGUE = {
			{ id = 5938, removes = { 'Enrage' } }, -- Shiv
		},
	},
}

-- The names Blizzard's candidate filters match an aura's dispelName against
-- (includeDispelTypes) for a removal. An aura's dispelName is its dispel
-- type's internal name in SpellDispelType: Magic on both clients, and type 9
-- is Enrage on retail. On Forever type 9 is Frenzy with no internal name, and
-- Blizzard's code allows for a dispelName of '' (Blizzard_PrivateAurasUI.lua
-- checks dispelName ~= '' on both clients), which is most likely what Forever
-- gives a Frenzy; that's unconfirmed in game, so Forever matches both names.
local function DispelNames(removal)
	if removal == 'Enrage' and st.forever then return { 'Enrage', '' } end
	return { removal }
end

-- What the player can take off a unit with the spells they know now, a set
-- of Magic, Enrage and stealable: the player's class's spells on this client
-- (UF.PURGE_SPELLS), each looked for in the player's spellbook or, for a
-- pet's, the pet's (known only while the pet is out). The spellbook's answers
-- are never secret.
function UF:KnownRemovals()
	local known = {}
	local _, class = UnitClass('player')
	local spells = UF.PURGE_SPELLS[st.forever and 'forever' or 'live'][class]
	for _, spell in ipairs(spells or {}) do
		local bank = spell.pet and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
		if C_SpellBook.IsSpellKnown(spell.id, bank) then
			for _, removal in ipairs(spell.removes) do
				known[removal] = true
			end
		end
	end
	return known
end

-- The filter string and candidate filters that show only the buffs the
-- player can remove (known, from UF:KnownRemovals). Blizzard's candidate
-- filters must all pass, so dispel types and stealable can't be either-or in
-- one group. A stealable buff is a magic one, so Magic covers a steal, and a
-- player who can only steal gets the stealable buffs. A player who can
-- remove nothing sees no buffs: an empty list of dispel types lets none
-- through.
function UF.PurgeFilter(known)
	if known.Magic or known.Enrage then
		local types = {}
		for _, removal in ipairs({ 'Magic', 'Enrage' }) do
			if known[removal] then
				for _, name in ipairs(DispelNames(removal)) do
					types[name] = true
				end
			end
		end
		return 'HELPFUL|RAID_PLAYER_DISPELLABLE', { includeDispelTypes = types }
	end
	if known.stealable then
		return 'HELPFUL', { isStealable = true }
	end
	return 'HELPFUL', { includeDispelTypes = {} }
end

-- The filter string and candidate filters (nil for none) an aura element's
-- group shows (auraType 'Buffs' or 'Debuffs', config the element's config):
--   * Buffs with Only buffs I can purge: UF.PurgeFilter's.
--   * Debuffs on a nameplate: nameplate-only debuffs too, which plain HARMFUL
--     leaves out. Only mine checks each aura's own flag, so the pet's debuffs
--     stay, as Blizzard's plates show them.
--   * Otherwise every buff or debuff. Only mine adds PLAYER, and checks each
--     aura's own flag too: Forever leaves sourceUnit nil on other players'
--     auras, and its PLAYER filter keeps every one of them. On retail the two
--     agree.
function UF.AuraFilter(unitframe, auraType, config)
	if auraType == 'Buffs' and config.purgeable then
		return UF.PurgeFilter(UF:KnownRemovals())
	end
	if auraType == 'Debuffs' and unitframe.isNamePlate then
		return 'HARMFUL|INCLUDE_NAME_PLATE_ONLY', config.onlyShowPlayer and { isFromPlayerOrPlayerPet = true } or nil
	end
	local filter = auraType == 'Buffs' and 'HELPFUL' or 'HARMFUL'
	if config.onlyShowPlayer then
		return filter .. '|PLAYER', { isFromPlayerOrPlayerPet = true }
	end
	return filter, nil
end

-- Whether two candidate filters (or two of their values) are the same.
local function SameFilters(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for key, value in pairs(a) do
		if not SameFilters(value, b[key]) then return false end
	end
	for key in pairs(b) do
		if a[key] == nil then return false end
	end
	return true
end

-- Gives an aura element's group the filter UF.AuraFilter gives it now. The
-- group was built with one (AddGroup in auras.lua, which notes it as the
-- group's groupFilter and groupCandidateFilters); each of Blizzard's setters
-- runs only if its part has changed, since each makes the container update
-- every aura. Nothing before the group is built.
function UF:ApplyAuraFilter(auras)
	if not auras.hasGroup then return end
	local filter, candidateFilters = UF.AuraFilter(auras.unitframe, auras.name, auras.config)
	if filter ~= auras.groupFilter then
		auras:SetAuraGroupFilterString(auras.groupKey, filter)
		auras.groupFilter = filter
	end
	if not SameFilters(candidateFilters, auras.groupCandidateFilters) then
		auras:SetAuraGroupCandidateFilters(auras.groupKey, candidateFilters)
		auras.groupCandidateFilters = candidateFilters
	end
end

-- The spells the player knows changed: every unit frame's Buffs with Only
-- buffs I can purge on gets its filter again. In combat that waits for the
-- end of combat. Nothing before the unit frames are made.
function UF:RefreshPurgeFilters()
	if not self.units then return end
	if st:QueueAfterCombat('PurgeFilters', function() UF:RefreshPurgeFilters() end) then return end
	self:ForEachUnitFrame(function(frame)
		local buffs = frame.Buffs
		if buffs and buffs.hasGroup and buffs.config and buffs.config.purgeable then
			self:ApplyAuraFilter(buffs)
		end
	end)
end

-- What changes the spells the player knows, on both clients: learning or
-- unlearning a spell (SPELLS_CHANGED), talents (PLAYER_TALENT_UPDATE,
-- TRAIT_CONFIG_UPDATED), and the player's pet coming or going (UNIT_PET; a
-- pet's spells are known only while it's out).
local events = CreateFrame('Frame')
for _, event in ipairs({ 'SPELLS_CHANGED', 'PLAYER_TALENT_UPDATE', 'TRAIT_CONFIG_UPDATED', 'UNIT_PET' }) do
	events:RegisterEvent(event)
end
events:SetScript('OnEvent', function(_, event, unit)
	if event == 'UNIT_PET' and unit ~= 'player' then return end
	UF:RefreshPurgeFilters()
end)
