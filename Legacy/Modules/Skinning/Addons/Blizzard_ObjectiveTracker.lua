local st = SaftUI
local SK = st:GetModule('Skinning')

local function SkinBlock(self, id)
	local block = self.usedBlocks[id]
	if block and not block.skinned then
		local config = st.config.profile.addon_skins.objective_tracker

		if block.HeaderText then
			block.HeaderText:SetFontObject(st:GetFont(config.font))
		end

		block.skinned = true
	end
end

local function SkinLine(self, block, objectiveKey, lineType)
	local line = block.lines[objectiveKey]

	if line and not line.skinned then
		local config = st.config.profile.addon_skins.objective_tracker

		line.Text:SetFontObject(st:GetFont(config.font))
		
		line.skinned = true
	end
end

local function SkinHeader(self)
	local config = st.config.profile.addon_skins.objective_tracker
	
	self.Text:SetFontObjectsToTry(st:GetFont(config.font))
	self.Background:Hide()
	self.LineGlow:Hide()
	self.SoftGlow:Hide()
	self.StarBurst:Hide()
	self.LineSheen:Hide()
end

local function SkinRightButton(block, button, initialAnchorOffsets)
	if block.rightButton and not block.rightButton.skinned then
		st:SkinActionButton(block.rightButton)
		block.rightButton.skinned = true
	end
end

SK.AddonSkins.Blizzard_ObjectiveTracker = function()
	--st:CreateHeader(ObjectiveTrackerFrame)
	--ObjectiveTrackerFrame.header:SetBackdrop(nil)
	--
	--for _,key in pairs({
	--	'QuestHeader',
	--	'AchievementHeader',
	--	'ScenarioHeader',
	--	'UIWidgetsHeader',
	--}) do	SkinHeader(ObjectiveTrackerFrame.BlocksFrame[key]) end
	--
	--hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, 'GetBlock', SkinBlock)
	--hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, 'GetLine', SkinLine)
	-- hooksecurefunc('QuestObjectiveSetupBlockButton_AddRightButton', SkinRightButton)

	-- ScenarioStageBlock
end