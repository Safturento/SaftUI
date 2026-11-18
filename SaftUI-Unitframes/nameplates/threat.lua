local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Threat on enemy nameplates. The player's threat on each enemy tints its
	health bar, and a small text above the bar's right end (the Threat
	element, frame.Threat) gives it as a percent.

	The state is by role (UF.ThreatState): a tank's bad is not holding the
	mob, unless another of the group's tanks holds it, and also a mob loose on
	a group member who isn't a tank, even one not on the tank's own threat
	list; a damage dealer's or healer's is having it. Warning comes just
	before bad. Warning and bad replace the bar's colour with the Colors
	tab's Threat colours while they apply: elements/health.lua's
	PostUpdateColor puts the tint on each time oUF colours the bar, and good
	leaves the bar oUF's. The text takes the tint's colour too, and the
	normal text colour while good.

	Tints show on enemy plates only, in a party or raid, and on your own only
	with Threat when solo on (Enemy nameplates' General, whichever page the
	plate draws from). A secret threat state (restricted content) shows
	nothing: a secret can't become a colour.
	The player's role is Blizzard's own (PlayerUtil.IsPlayerEffectivelyTank:
	on Forever an aura that makes a tank first, then the assigned role; on
	retail the role, else the spec's).

	Only reads the game's threat, group and role API, and writes only onto
	SaftUI's own frames.
]]

-- The group's unit tokens: a party's members besides the player, and a
-- raid's members (the player among them).
local PARTY, RAID = {}, {}
for i = 1, 4 do PARTY[i] = 'party' .. i end
for i = 1, 40 do RAID[i] = 'raid' .. i end

-- The states that tint the bar.
local TINTED = { warning = true, bad = true }

-- The state of the player's threat on a mob, by role. status is
-- UnitThreatSituation's: 0 lower threat than the mob's tank, 1 higher but not
-- tanking, 2 tanking while someone else has more, 3 tanking securely; nil is
-- not on the mob's threat list, which gives nil.
--   tank:   3 good, 2 warning, 0 or 1 bad, but good when coTanked (another
--           of the group's tanks holds the mob);
--   others: 0 good, 1 warning, 2 or 3 bad.
function UF.ThreatState(isTank, status, coTanked)
	if status == nil then return nil end
	if isTank then
		if status == 3 then return 'good' end
		if status == 2 then return 'warning' end
		return coTanked and 'good' or 'bad'
	end
	if status == 0 then return 'good' end
	if status == 1 then return 'warning' end
	return 'bad'
end

-- Whether a group member is one of the group's tanks: given the tank role, or
-- with an aura that makes it one, where the client has
-- UnitHasEffectivelyTankAura (Forever does, retail doesn't). A secret answer
-- is no.
function UF.IsGroupTank(unit)
	local role = UnitGroupRolesAssigned(unit)
	if not issecretvalue(role) and role == 'TANK' then return true end
	if UnitHasEffectivelyTankAura then
		local aura = UnitHasEffectivelyTankAura(unit)
		if not issecretvalue(aura) and aura then return true end
	end
	return false
end

-- The group member tanking a mob, or nil when none is. The mob's target can't
-- tell (its token is secret), so each member's threat state on it is read,
-- up to the one tanking it (status 2 or 3: only the mob's target is). The
-- state, not UnitDetailedThreatSituation's isTanking: the game keeps the
-- threat values secret more often than the state (its secret predicates
-- single bosses out), and a member whose state is secret is skipped. A mob
-- out of combat has no threat list, so nobody tanks it and the group isn't
-- read: up to 40 reads saved for each idle hostile plate round a raid's tank.
-- A secret answer can't rule combat out, so the group is read then.
local function MemberTanking(mob)
	local inCombat = UnitAffectingCombat(mob)
	if not issecretvalue(inCombat) and not inCombat then return nil end
	local tokens, count = PARTY, GetNumGroupMembers() - 1
	if IsInRaid() then tokens, count = RAID, GetNumGroupMembers() end
	for i = 1, math.min(count, #tokens) do
		local member = tokens[i]
		local status = UnitThreatSituation(member, mob)
		if not issecretvalue(status) and status ~= nil and status >= 2 then
			return member
		end
	end
end

-- The player's threat state on a plate's unit (UF.ThreatState), or nil where
-- no tint shows: a friendly plate, on your own with Threat when solo off, a
-- threat state the game makes secret, or a unit whose threat list the player
-- isn't on. A tank who doesn't hold the mob (status 0 or 1, or not on its
-- list) has the group read for who does: another of the group's tanks makes
-- it good; a member who isn't a tank makes it bad, the mob loose on them, on
-- the tank's list or not; nobody tanking it, off the tank's list, shows
-- nothing.
function UF:PlateThreat(frame)
	local unit = frame.__unit
	if not unit or frame.friendly then return nil end
	if not IsInGroup() and not self:GetProfileConfig().nameplate.threat_solo then return nil end
	if C_Secrets.ShouldUnitThreatStateBeSecret('player', unit) then return nil end
	local status = UnitThreatSituation('player', unit)
	if issecretvalue(status) then return nil end
	local isTank = PlayerUtil.IsPlayerEffectivelyTank() and true or false
	if status == nil then
		if not isTank then return nil end
		local member = MemberTanking(unit)
		if member and not UF.IsGroupTank(member) then return 'bad' end
		return nil
	end
	local coTanked = false
	if isTank and status <= 1 then
		local member = MemberTanking(unit)
		coTanked = member ~= nil and UF.IsGroupTank(member)
	end
	return UF.ThreatState(isTank, status, coTanked)
end

-- What each threat text shows while it's shown: { state, percent, r, g, b },
-- so an update that would write the same again is skipped (a mob's threat
-- list changes many times a second in a pull). A secret percent can't be
-- compared, so none is kept for it and the next update writes again.
local shownText = setmetatable({}, { __mode = 'k' })

-- Writes the threat text for the plate's state: the player's scaled threat
-- percent, in the tint's colour, or the normal text colour while good. Hidden
-- with no state, while the text is off or not wanted (a friendly plate), or
-- with no percent. A secret percent is handed to the game to write: the
-- font string formats it without Lua reading it. Unless force, the same
-- state, percent and colour as it shows already writes nothing.
local function UpdateThreatText(frame, state, force)
	local text = frame.Threat
	if not text then return end
	if not state or not UF:ElementWanted(text) then
		text:Hide()
		shownText[text] = nil
		return
	end
	local _, _, percent = UnitDetailedThreatSituation('player', frame.__unit)
	local secret = issecretvalue(percent)
	if not secret and percent == nil then
		text:Hide()
		shownText[text] = nil
		return
	end
	local colors = st.config.profile.colors
	local color = TINTED[state] and colors.threat[state] or st:Color('text', 'normal')
	local shown = shownText[text]
	if not force and not secret and shown and shown.state == state and shown.percent == percent
			and shown.r == color.r and shown.g == color.g and shown.b == color.b then
		return
	end
	text:SetFormattedText('%.0f%%', percent)
	text:SetTextColor(color.r, color.g, color.b)
	text:Show()
	if secret then
		shownText[text] = nil
	else
		shown = shown or {}
		shown.state, shown.percent, shown.r, shown.g, shown.b = state, percent, color.r, color.g, color.b
		shownText[text] = shown
	end
end

-- Works a plate's threat out again (frame.threatState, which health.lua's
-- PostUpdateColor reads) and tints its bar now: warning or bad in their
-- colour; otherwise a bar that had a tint is coloured again by oUF
-- (Health:ForceUpdate), with none. A plate showing no unit (taken away, or
-- showing only widgets) keeps no state; oUF colours its bar anew at its next
-- add. force writes the threat text even when what it shows is unchanged.
function UF:UpdatePlateThreat(frame, force)
	local shown = self:PlateShowsUnit(frame)
	local state = shown and self:PlateThreat(frame) or nil
	local wasTinted = TINTED[frame.threatState]
	frame.threatState = state
	local health = frame.Health
	if TINTED[state] then
		local color = st.config.profile.colors.threat[state]
		health:SetStatusBarColor(color.r, color.g, color.b)
	elseif wasTinted and shown and health.ForceUpdate then
		health:ForceUpdate()
	end
	UpdateThreatText(frame, state, force)
end

local function UpdatePlate(frame) UF:UpdatePlateThreat(frame) end
local function ForceUpdatePlate(frame) UF:UpdatePlateThreat(frame, true) end

-- Updates the plate showing unit, for a nameplate token ('nameplate3') only:
-- the same mob's other tokens (target, focus, boss1, mouseover) and group
-- members' aren't looked for among the plates.
local function UpdateUnitPlate(unit)
	if type(unit) ~= 'string' or not unit:find('^nameplate%d') then return end
	local frame = UF:PlateForUnit(unit)
	if frame then UF:UpdatePlateThreat(frame) end
end

-- The plate's kind is set on every add and when the unit's faction changes
-- ('kind'), its config on every update ('updated'), and a plate taken away
-- drops its state ('removed'). The first two write the text whatever it
-- showed: a new unit, or a font, alpha or place just set.
UF:RegisterPlateCallback('kind', ForceUpdatePlate)
UF:RegisterPlateCallback('updated', ForceUpdatePlate)
UF:RegisterPlateCallback('removed', UpdatePlate)

-- A mob's threat list changing retints its plate. A threat situation
-- change retints every plate for the player's, and a plate's own for its
-- unit's; a group member's is left to the mob's threat list update, which
-- the game fires for the mob too, so a raid's changes don't each run every
-- plate. The group, the roles in it, the player's spec and the player's form
-- or stance (a tanking one is a tank aura on Forever) retint every plate.
-- Every one of these is in both clients' API documentation.
local events = CreateFrame('Frame')
for _, event in ipairs({
	'UNIT_THREAT_LIST_UPDATE', 'UNIT_THREAT_SITUATION_UPDATE',
	'GROUP_ROSTER_UPDATE', 'PLAYER_ROLES_ASSIGNED', 'PLAYER_SPECIALIZATION_CHANGED',
	'UPDATE_SHAPESHIFT_FORM',
}) do
	events:RegisterEvent(event)
end
events:SetScript('OnEvent', function(_, event, unit)
	if event == 'UNIT_THREAT_LIST_UPDATE' then
		UpdateUnitPlate(unit)
	elseif event == 'UNIT_THREAT_SITUATION_UPDATE' and unit ~= 'player' then
		UpdateUnitPlate(unit)
	else
		UF:ForEachPlate(UpdatePlate)
	end
end)

--[[
	The threat text, the Threat element: a font string of the plate's, on the
	plates only (enemy plates: UF.PLATE_ENEMY_ONLY). Its config is Enemy
	nameplates' threat table (config/units/nameplate.lua): Enable, Font (its
	size), Alpha and Position. That one whatever config unit the plate draws
	from (frame.base_unit, nameplates.lua): an enemy's plate drawn from
	Friendly nameplates, which has no threat settings, keeps the Enemy page's.
]]
local function ThreatConfig() return UF:GetProfileConfig().nameplate.threat end

local function Constructor(frame)
	local text = UF:AddTextElement(frame, 'Threat')
	text.config = ThreatConfig()
	text.GetConfig = ThreatConfig
	return text
end

-- Its font, alpha, place and Enable. What it says, and whether it shows,
-- follow at the end of the plate's update (the 'updated' callback).
local function UpdateConfig(frame)
	UF:UpdateElement(frame.Threat)
end

local function GetConfigTable(unit)
	local G = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function Config() return UF:GetProfileConfig()[unit].threat end
	local function Update() UF:UpdateConfig(unit, 'Threat') end

	return {
		type = 'group',
		name = 'Threat',
		order = 1.5,
		saved = UF.SavedIn(unit, 'threat'),
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			Update()
		end,
		args = {
			enable = G.toggle(0, 'Enable',
				"Shows your threat on an enemy as a percent above its health bar: in the bar's threat color while it's tinted, else in the normal text color. Only where the bars are tinted: in a party or raid, or on your own with Threat when solo on.", 'small'),
			font = G.font(1, "The threat text's font, which sets its size."),
			alpha = G.alpha(2, 'How solid the threat text is, from see-through to opaque.'),
			max_width = G.max_width(2.9, 'threat text'),
			justify = G.justify(3, 'threat text', function() return Config().max_width end),
			-- Last in the tab.
			position = G.uf_element_position(1000,
				function(index) return Config().position[index] end,
				function(index, value)
					Config().position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'Threat'),
				"Where the threat text sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
				nil, UF.SavedAt(unit, 'threat', 'position')
			),
		},
	}
end

UF:RegisterElement('Threat', Constructor, UpdateConfig, GetConfigTable, function(unit)
	return unit == 'nameplate'
end)
