local st = SaftUI

local XP = st:NewModule('Experience')

-- Read at use time: a profile change replaces the profile's colors table.
local function Colors()
	return st.config.profile.colors
end

function XP:SetupExperience()
	local expbar = CreateFrame('StatusBar', st.name ..'_ExperienceBar', self.container)
	self.bars.experience = expbar

	local restbar = CreateFrame('StatusBar', st.name ..'_RestBar', self.container)
	restbar:SetAllPoints(expbar)
	expbar.rested = restbar
end

function XP:SetupReputation()
	local reputation = CreateFrame('StatusBar', st.name ..'_ReputationBar', self.container)
	self.bars.reputation = reputation
end

-- Stacks the shown bars and fits the container's height around them.
function XP:StackBars()
	local barHeight = st:RoundToPixel(self.config.height, self.container)
	local spacing = st:RoundToPixel(self.config.spacing, self.container)
	local num_bars = 0
	local prev
	for _,bar in pairs(self.bars) do
		if bar:IsShown() then
			num_bars = num_bars + 1

			bar:ClearAllPoints()
			if prev then
				bar:SetPoint('TOP', prev, 'BOTTOM', 0, -spacing)
			else
				bar:SetPoint('TOP', self.container)
			end
			prev = bar
		end
	end

	-- With no bar shown the container keeps one bar's height, so edit mode's
	-- overlay still has something to grab.
	local height = num_bars > 0
		and num_bars*(barHeight+spacing) - spacing
		or barHeight
	self.container:SetHeight(height)
end

function XP:Update()
	self:UpdateExperience()
	self:UpdateReputation()

	-- The bars hang off the container, so a protected frame (e.g. a unit frame)
	-- anchored to any of them makes the container protected too. In combat the
	-- stacking then waits for the end of combat.
	st:SafeReposition(self.container, 'experience_stack', function() self:StackBars() end)
end

-- The position used to be saved as a { point, frame, rel_point, x, y } array.
-- Converts that to the named shape in place, so the saved spot is kept. AceDB
-- fills the named keys with defaults, so every one is overwritten.
function XP:MigratePosition()
	local pos = self.config.position
	if pos[1] == nil then return end
	pos.point, pos.frame, pos.rel_point, pos.x_off, pos.y_off = pos[1], pos[2], pos[3], pos[4] or 0, pos[5] or 0
	for i = 1, 5 do
		pos[i] = nil
	end
end

-- The experience section in the /sui tree: General, with the Position option
-- last. Clicking the bars in edit mode selects its General group (the mover's
-- configPath).
function XP:GetConfigTable()
	-- Getters and setters go through self.config, which a profile change
	-- re-points at the new profile's table.
	local position = st.Config.generators.position(1000, true,
		function(key)
			self:MigratePosition()
			return self.config.position[key]
		end,
		function(key, value)
			self.config.position[key] = value
			self:UpdateConfig()
		end,
		self.container
	)

	-- The profile's colors.experience[key]. 'normal' also colors the loot feed's
	-- experience entries.
	local function Color(order, name, key, desc)
		return {
			order = order,
			name = name,
			desc = desc,
			type = 'color',
			get = function()
				return Colors().experience[key]:GetRGB()
			end,
			set = function(_, r, g, b)
				local color = Colors().experience[key]
				color.r, color.g, color.b = r, g, b
				self:UpdateConfig()
			end,
		}
	end

	return {
		name = 'Experience',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionswindow.lua)
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value) self.config[info[#info]] = value; self:UpdateConfig() end,
				args = {
					template = st.Config.generators.template(1),
					width = st.Config.generators.range(2, 'Width', 50, 800, 1),
					height = st.Config.generators.range(3, 'Height', 2, 60, 1),
					spacing = st.Config.generators.range(4, 'Spacing', 0, 30, 1),
					rest_alpha = st.Config.generators.range(5, 'Rested bar alpha', 0, 1, 0.05),
					normal_color = Color(6, 'Experience color', 'normal', 'The bar while you have no rested experience.'),
					rested_color = Color(7, 'Rested color', 'rested',
						'The bar while you have rested experience, and the rested part past it (at Rested bar alpha).'),
					position = position,
				},
			},
		},
	}
end

-- Applies the profile's size, spacing, template, colors and position. Runs on
-- enable and on every profile change.
function XP:UpdateConfig()
	if not self.bars then return end -- not enabled
	self:MigratePosition()

	-- Before the frame levels below, which place its backdrop.
	st:SetBackdrop(self.bars.experience, self.config.template)

	-- Size, position and frame levels; in combat these wait for the end of
	-- combat if a protected frame is anchored to the container or a bar.
	st:SafeReposition(self.container, 'experience', function()
		-- Whole pixels (sizes are rounded like positions)
		local width = st:RoundToPixel(self.config.width, self.container)
		local height = st:RoundToPixel(self.config.height, self.container)
		self.container:SetWidth(width)
		self.container:ClearAllPoints()
		self.container:SetPoint(st:UnpackPoint(self.config.position))

		-- The rested bar goes between the experience bar's backdrop and its fill.
		-- Under the backdrop it only showed through the backdrop's transparency.
		local expbar = self.bars.experience
		expbar:SetFrameLevel(5)
		if expbar.backdrop then expbar.backdrop:SetFrameLevel(3) end
		expbar:SetSize(width, height)
		expbar.rested:SetFrameLevel(4)
		expbar.rested:SetSize(width, height)
		self.bars.reputation:SetFrameLevel(5)
		self.bars.reputation:SetSize(width, height)
	end)

	self.bars.experience:SetStatusBarTexture(st.BLANK_TEX)
	self.bars.experience:SetStatusBarColor(Colors().experience.normal:GetRGB())

	self.bars.experience.rested:SetStatusBarTexture(st.BLANK_TEX)
	self.bars.experience.rested:SetStatusBarColor(Colors().experience.rested:GetRGB())
	self.bars.experience.rested:SetAlpha(self.config.rest_alpha)

	self.bars.reputation:SetStatusBarTexture(st.BLANK_TEX)
	self.bars.reputation:SetStatusBarColor(1, 1, 1)
	st:SetBackdrop(self.bars.reputation, self.config.template)

	-- Re-stacks the bars with the new spacing and height
	self:Update()
end

function XP:GetWatchedFactionInfo()
	local name, rank, minRep, maxRep, value, factionId

	if C_Reputation.GetWatchedFactionData then
		local factionData = C_Reputation.GetWatchedFactionData()
		if not factionData then return end
		name = factionData.name
		rank = factionData.reaction
		minRep = factionData.currentReactionThreshold
		maxRep = factionData.nextReactionThreshold
		value = factionData.currentStanding
		factionId = factionData.factionID
	elseif GetWatchedFactionInfo then
		name, rank, minRep, maxRep, value, factionId = GetWatchedFactionInfo()
	end

	if not name then return end

	local friendshipInfo = C_GossipInfo.GetFriendshipReputation(factionId)

	if st.retail and C_Reputation.IsMajorFaction(factionId) then
		-- https://wowpedia.fandom.com/wiki/API_C_MajorFactions.GetMajorFactionData
		local factionData = C_MajorFactions.GetMajorFactionData(factionId)
		return {
			name = factionData.name,
			rank = factionData.renownLevel,
			rankLabel = 'Rank '..factionData.renownLevel,
			color = Colors().renown,
			current = factionData.renownReputationEarned,
			max = factionData.renownLevelThreshold,
			rewardMessage = factionData.unlockDescription or nil
		}
	elseif C_Reputation.IsFactionParagon and C_Reputation.IsFactionParagon(factionId) then
		local value, max, rewardQuestID, rewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionId)
		local rewardMessage = C_QuestLog.GetTitleForQuestID(rewardQuestID)
		return {
			name = name,
			rank = rank,
			rankLabel = "Paragon " .. math.floor(value/10000),
			color = Colors().reaction[rank],
			current = rewardPending and max or value % 10000,
			max = max,
			rewardPending = rewardPending,
			rewardMessage = rewardMessage and ("Reward Pending: " .. C_QuestLog.GetTitleForQuestID(rewardQuestID))
		}
	elseif friendshipInfo and friendshipInfo.friendshipFactionID > 0 then
		return {
			name = friendshipInfo.name,
			rank = rank,
			rankLabel = friendshipInfo.reaction,
			color = Colors().reaction[rank],
			current = friendshipInfo.standing - friendshipInfo.reactionThreshold,
			-- TODO: nextThreshold is nil when maxed, need to handle that edge case
			max = friendshipInfo.nextThreshold - friendshipInfo.reactionThreshold
		}
	else
		return {
			name = name,
			rank = rank,
			rankLabel = _G['FACTION_STANDING_LABEL'..rank],
			color = Colors().reaction[rank],
			current = value - minRep,
			max = maxRep - minRep
		}
	end

	return {
		name = name,
		rank = rank,
		rankLabel = _G['FACTION_STANDING_LABEL'..rank],
		color = Colors().reaction[rank],
		current = value - minRep,
		max = maxRep - minRep
	}
end

function XP:UpdateReputation()
	local info = self:GetWatchedFactionInfo()

	if info then
		self.bars.reputation:SetMinMaxValues(0, info.max)
		self.bars.reputation:SetValue(info.current)

		self.bars.reputation:SetStatusBarColor(info.color:GetRGB())

		self.bars.reputation:Show()
	else
		self.bars.reputation:Hide()
	end
end

function XP:UpdateExperience()
	if GetMaxPlayerLevel() ~= UnitLevel('player') then
		local current, max = UnitXP('player'), UnitXPMax('player')
		local rest = GetXPExhaustion()

		self.bars.experience:SetMinMaxValues(0, max)
		self.bars.experience:SetValue(current)
		self.bars.experience:SetStatusBarColor(
			Colors().experience[rest and 'rested' or 'normal']:GetRGB()
		)

		self.bars.experience.rested:SetMinMaxValues(0, max)
		self.bars.experience.rested:SetValue(rest and current+rest or 0)


		self.bars.experience:Show()
	else
		self.bars.experience:Hide()
	end
end

function XP:AddExperienceTooltipInfo(tooltip)
	if GetMaxPlayerLevel() == UnitLevel('player') then return end

	local current, max = UnitXP('player'), UnitXPMax('player')
	local rest = GetXPExhaustion()

	GameTooltip:AddDoubleLine('Current XP:', format('%s/%s (%s%%)', st.StringFormat:ShortFormat(current, 1), st.StringFormat:ShortFormat(max, 1), st.StringFormat:Round(current/max*100)), nil,nil,nil, 1,1,1)
	GameTooltip:AddDoubleLine('To go:', st.StringFormat:CommaFormat(max-current), nil,nil,nil, 1,1,1)
	if rest then
		GameTooltip:AddDoubleLine('Rested:', format('%s (%s%%)', st.StringFormat:CommaFormat(rest), st.StringFormat:Round(rest/max*100)), nil,nil,nil, 0,.6,1)
	end
end

function XP:AddFactionTooltipInfo(tooltip)
	local info = XP:GetWatchedFactionInfo()
	if not info then return end


	local current, max = info.current, info.max
	if max == 0 then return end

	if GetMaxPlayerLevel() ~= UnitLevel('player') then tooltip:AddLine('  ') end

	GameTooltip:AddDoubleLine(info.name, info.rankLabel, nil,nil,nil, info.color:GetRGB())
	GameTooltip:AddDoubleLine('Current:', format('%s/%s (%d%%)', st.StringFormat:ShortFormat(current, 1), st.StringFormat:ShortFormat(max, 1), st.StringFormat:Round(current/max*100)), nil,nil,nil, 1,1,1)
	GameTooltip:AddDoubleLine('To go:', st.StringFormat:CommaFormat(max-current), nil,nil,nil, 1,1,1)

	if info.rewardMessage then
		GameTooltip:AddLine("\n" .. info.rewardMessage, 1, 1, 1, true)
	end
end

function XP:OnEnter()
	local container = self.container
	if container:GetLeft() > GetScreenWidth()/2 then
		--Right size of screen
		GameTooltip:SetOwner(container, 'ANCHOR_LEFT', -self.config.spacing, -container:GetHeight())
	else
		--Left size of screen
		GameTooltip:SetOwner(container, 'ANCHOR_RIGHT', self.config.spacing, -container:GetHeight())
	end
	GameTooltip:ClearLines()

	self:AddExperienceTooltipInfo(GameTooltip)
	self:AddFactionTooltipInfo(GameTooltip)

	GameTooltip:Show()
end

-- Blizzard's status tracking bars (xp/rep/honor/azerite/artifact/house favor)
-- live in two Edit Mode system containers, on retail and on Forever alike.
-- StatusTrackingBarContainerMixin:UpdateShownState re-shows them on every bar
-- change (level up, rep, honor, equipment, zone, Edit Mode enter/exit), so a
-- single Hide() doesn't stick. Hook OnShow instead. Hidden is also the state
-- Blizzard's own bottom-bar stacking expects when no bar is active (it only
-- stacks frames where IsShown() is true), so the action bars close the gap.
-- Nothing is written onto the Blizzard frames, only method calls and a hook.
local BLIZZ_BAR_CONTAINERS = {
	'MainStatusTrackingBarContainer',
	'SecondaryStatusTrackingBarContainer',
}

local hookedBlizzBars = {}
local pendingBlizzBars = {}

local function HideBlizzBar(frame)
	-- A protected frame can't be hidden from addon code in combat; wait it out.
	if InCombatLockdown() and frame:IsProtected() then
		pendingBlizzBars[frame] = true
		return
	end
	pendingBlizzBars[frame] = nil
	frame:Hide()
end

function XP:FlushBlizzBars()
	for frame in pairs(pendingBlizzBars) do
		HideBlizzBar(frame)
	end
end

function XP:HideBlizz()
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'FlushBlizzBars')

	for _, name in ipairs(BLIZZ_BAR_CONTAINERS) do
		local frame = _G[name]
		if frame then
			if not hookedBlizzBars[frame] then
				hookedBlizzBars[frame] = true
				frame:HookScript('OnShow', HideBlizzBar)
				-- Blizzard's Edit Mode box for the container no longer
				-- controls anything, so keep it hidden. HookScript only.
				if frame.Selection then
					frame.Selection:HookScript('OnShow', function(selection)
						selection:Hide()
					end)
				end
			end
			if frame:IsShown() then
				HideBlizzBar(frame)
			end
		end
	end
end

function XP:OnLeave()
	GameTooltip:Hide()
end

function XP:OnEnable()
	st:BindModuleConfig(self, 'experience')

	local container = CreateFrame('frame', st.name ..'_Experience', UIParent)
	container:SetWidth(self.config.width)
	self:MigratePosition()
	container:SetPoint(st:UnpackPoint(self.config.position))
	self:HookScript(container, 'OnEnter')
	self:HookScript(container, 'OnLeave')
	self.container = container

	self.bars = {}

	self:HideBlizz()
	self:SetupExperience()
	self:SetupReputation()
	self:UpdateConfig()

	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'Update')

	self:RegisterEvent('PLAYER_LEVEL_UP', 'Update')
	self:RegisterEvent('PLAYER_XP_UPDATE', 'Update')
	self:RegisterEvent('UPDATE_EXHAUSTION', 'Update')

	self:RegisterEvent("QUEST_LOG_UPDATE", 'Update')
	self:RegisterEvent("UPDATE_FACTION", 'Update')
	if st.retail then
		self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", 'Update')
		self:RegisterEvent("MAJOR_FACTION_UNLOCKED", 'Update')
	end

	self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE', 'Update')
	self:RegisterEvent('UPDATE_FACTION', 'Update')

	st:RegisterMover('experience', {
		frame = self.container,
		label = 'Experience',
		getPosition = function()
			self:MigratePosition()
			return self.config.position
		end,
		setPosition = function(pos) self.config.position = pos end,
		apply = function() XP:UpdateConfig() end,
		configPath = { 'Experience', 'general' },
	})
end