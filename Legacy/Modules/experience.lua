local st = SaftUI

local XP = st:NewModule('Experience', 'AceHook-3.0', 'AceEvent-3.0')

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

function XP:Update()
	self:UpdateExperience()
	self:UpdateReputation()

	local num_bars = 0
	local prev
	for _,bar in pairs(self.bars) do
		if bar:IsShown() then
			num_bars = num_bars + 1

			bar:ClearAllPoints()
			if prev then
				bar:SetPoint('TOP', prev, 'BOTTOM', 0, -self.config.spacing)
			else
				bar:SetPoint('TOP', self.container)
			end
			prev = bar
		end
	end

	self.container:SetHeight(num_bars*(self.config.height+self.config.spacing) - self.config.spacing)

end

function XP:UpdateConfig()
	self.bars.experience:SetStatusBarTexture(st.BLANK_TEX)
	self.bars.experience:SetStatusBarColor(unpack(self.colors.experience.normal))
	self.bars.experience:SetFrameLevel(5)
	self.bars.experience:SetSize(self.config.width, self.config.height)
	st:SetBackdrop(self.bars.experience, self.config.template)
	
	self.bars.experience.rested:SetStatusBarTexture(st.BLANK_TEX)
	self.bars.experience.rested:SetStatusBarColor(unpack(self.colors.experience.rested))
	self.bars.experience.rested:SetFrameLevel(3)
	self.bars.experience.rested:SetSize(self.config.width, self.config.height)
	self.bars.experience.rested:SetAlpha(self.config.rest_alpha)
	
	self.bars.reputation:SetStatusBarTexture(st.BLANK_TEX)
	self.bars.reputation:SetStatusBarColor(1, 1, 1)
	self.bars.reputation:SetFrameLevel(5)
	self.bars.reputation:SetSize(self.config.width, self.config.height)
	st:SetBackdrop(self.bars.reputation, self.config.template)
end

function XP:UpdateReputation()
	if GetWatchedFactionInfo() then
		local name, rank, minRep, maxRep, value = GetWatchedFactionInfo()
		local current = value - minRep
		local max = maxRep - minRep

		self.bars.reputation:SetMinMaxValues(0, max)
		self.bars.reputation:SetValue(current)
			
		self.bars.reputation:SetStatusBarColor(unpack(self.colors.reaction[rank]))

		self.bars.reputation:Show()
	else
		self.bars.reputation:Hide()
	end
end

function XP:UpdateExperience()
	if MAX_PLAYER_LEVEL ~= UnitLevel('player') then
		local current, max = UnitXP('player'), UnitXPMax('player')
		local rest = GetXPExhaustion()

		self.bars.experience:SetMinMaxValues(0, max)
		self.bars.experience:SetValue(current)
		self.bars.experience:SetStatusBarColor(
			unpack(self.colors.experience[rest and 'rested' or 'normal'])
		)

		self.bars.experience.rested:SetMinMaxValues(0, max)
		self.bars.experience.rested:SetValue(rest and current+rest or 0)


		self.bars.experience:Show()
	else
		self.bars.experience:Hide()
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

	if MAX_PLAYER_LEVEL ~= UnitLevel('player') then
		local current, max = UnitXP('player'), UnitXPMax('player')
		local rest = GetXPExhaustion()

		GameTooltip:AddDoubleLine('Current XP:', format('%s/%s (%s%%)', st.StringFormat:ShortFormat(current, 1), st.StringFormat:ShortFormat(max, 1), st.StringFormat:Round(current/max*100)), nil,nil,nil, 1,1,1)
		GameTooltip:AddDoubleLine('To go:', st.StringFormat:CommaFormat(max-current), nil,nil,nil, 1,1,1)
		if rest then
			GameTooltip:AddDoubleLine('Rested:', format('%s (%s%%)', st.StringFormat:CommaFormat(rest), st.StringFormat:Round(rest/max*100)), nil,nil,nil, 0,.6,1)
		end
	end

	if GetWatchedFactionInfo() then
		--Add a space between exp and rep
		if MAX_PLAYER_LEVEL ~= UnitLevel('player') then GameTooltip:AddLine('  ') end

		local name, rank, minRep, maxRep, value = GetWatchedFactionInfo()
		local current = value - minRep
		local max = maxRep - minRep
		
		local c = FACTION_BAR_COLORS[rank]

		GameTooltip:AddDoubleLine(name, _G['FACTION_STANDING_LABEL'..rank], nil,nil,nil, c.r, c.g, c.b)

		if max > 0 then
			GameTooltip:AddDoubleLine('Current:', format('%s/%s (%d%%)', st.StringFormat:ShortFormat(current, 1), st.StringFormat:ShortFormat(max, 1), st.StringFormat:Round(current/max*100)), nil,nil,nil, 1,1,1)
			GameTooltip:AddDoubleLine('To go:', st.StringFormat:CommaFormat(max-current), nil,nil,nil, 1,1,1)
		end
	end

	GameTooltip:Show()
end

function XP:OnLeave()
	GameTooltip:Hide()
end

function XP:OnEnable()
	self.config = st.config.profile.experience
	self.colors = st.config.profile.colors

	local container = CreateFrame('frame', st.name ..'_Experience', UIParent)
	container:SetWidth(self.config.width)
	container:SetPoint(unpack(self.config.position))
	self:HookScript(container, 'OnEnter')
	self:HookScript(container, 'OnLeave')
	self.container = container

	self.bars = {}
	self:SetupExperience()
	self:SetupReputation()
	self:UpdateConfig()
	self:Update()
	
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'Update')

	self:RegisterEvent('PLAYER_LEVEL_UP', 'Update')
	self:RegisterEvent('PLAYER_XP_UPDATE', 'Update')
	self:RegisterEvent('UPDATE_EXHAUSTION', 'Update')
	
	self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE', 'Update')
	self:RegisterEvent('UPDATE_FACTION', 'Update')
end