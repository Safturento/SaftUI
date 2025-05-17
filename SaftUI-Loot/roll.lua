local st = SaftUI

local LT = st:GetModule('Loot')
local DEBUG = false

local roll_buttons = {
	{name = 'Pass', icon_text = 'P', color = 'red',
		icon_texture = [[Interface\ICONS\Spell_Shadow_SacrificialShield]]},
	{name = 'Greed', icon_text = 'G', color = 'yellow',
		icon_texture = [[Interface\ICONS\INV_Misc_Coin_01]]},
	{name = 'Transmog', icon_text = 'DE', color = 'purple',
		icon_texture = [[Interface\ICONS\Spell_Holy_RemoveCurse]]},
	{name = 'Need', icon_text = 'N', color = 'white',
		icon_texture = [[Interface\ICONS\INV_Misc_PunchCards_White]]},
}

function LT:DebugGroupLootFrame()
	GetLootRollItemInfo = function(rollID)
		local texture = 135575
		name = 'Ravager'
		count = rollID
		quality	= rollID+1
		bindOnPickUp = math.random(0,1) > 0.5
		canNeed	= true
		canGreed = true
		canDisenchant = true
		canTransmog = math.random(0,1) > 0.5
		reasonNeed = 0
		reasonGreed	= 0
		reasonDisenchant = 0
		deSkillRequired = 0

		return texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant, deSkillRequired, canTransmog
	end

	function GetLootRollTimeLeft(rollId)
		return rollId * 50
	end

	for i=1, 4 do
		GroupLootContainer_AddRoll(i, 300)
	end
end

function LT:SkinRollFrame(frame)
	if frame.skinned then return end
	frame.skinned = true

	st:StripTextures(frame)

	st:SkinIcon(frame.IconFrame.Icon, nil, frame.IconFrame)
	frame.IconFrame:ClearAllPoints()
	frame.IconFrame:SetPoint('LEFT', frame, 0, 0)
	st:Kill(frame.IconFrame.Border)

	st:Kill(frame.Timer.Background)
	st:Kill(_G[frame:GetName()..'NameFrame'])
	st:Kill(_G[frame:GetName()..'Corner'])

	frame.Name:SetParent(frame.Timer)

	st:Kill(frame.IconFrame.Count)

	frame.Timer.Text = frame.Timer:CreateFontString(nil, 'OVERLAY')
	frame.Timer.Text:SetFontObject(GameFontNormal)

	local prev
	for i, info in ipairs(roll_buttons) do
		local button = frame[info.name..'Button']
		button.Text = button:CreateFontString(nil, 'OVERLAY')
		button.Text:SetFontObject(GameFontNormal)
		button.Text:SetPoint('CENTER', 1, 0)
		button.Text:SetVertexColor(unpack(st.config.profile.colors.text[info.color]))

		prev = button
	end

	self:SecureHookScript(frame, 'OnShow', 'GroupLootFrame_OnShow')
	self:SecureHookScript(frame.Timer, 'OnUpdate', 'GroupLootFrame_OnUpdateTimer')
	self:UpdateRollFrame(frame)
end

function LT:UpdateRollFrame(frame)
	local config = self.config.roll
	local font_obj = st:GetFont(config.font)

	frame:SetSize(config.width, config.height)

	frame.InfoFrame = st:CreateFrame('frame', nil, frame)
	st:SetBackdrop(frame.InfoFrame, config.template)
	frame.InfoFrame:SetPoint('BOTTOMRIGHT')
	frame.InfoFrame:SetPoint('TOPLEFT', frame.IconFrame, 'TOPRIGHT', 7, 0)
	frame.InfoFrame:SetFrameLevel(1)

	frame.Name:SetFontObject(st:GetFont(config.font))
	frame.Name:ClearAllPoints()
	frame.Name:SetHeight(config.height)
	frame.Name:SetPoint('LEFT', frame.InfoFrame, 5, 0)
	frame.Name:SetPoint('RIGHT', frame.Timer.Text, 'LEFT', -5, 0)

	st:SetBackdrop(frame.IconFrame, config.template)
	frame.IconFrame.Count:SetFontObject(st:GetFont(config.font))
	frame.IconFrame:SetSize(config.height, config.height)

	frame.Timer:SetStatusBarTexture(st.BLANK_TEX)
	frame.Timer:ClearAllPoints()
	frame.Timer:SetPoint('BOTTOMLEFT', frame.IconFrame, 'BOTTOMRIGHT', config.spacing, 0)
	frame.Timer:SetHeight(1)
	frame.Timer:SetWidth(config.width - config.height - config.spacing)

	--st:StripTextures(frame.Timer, true)

	local prev
	for i, info in ipairs(roll_buttons) do
		local button = frame[info.name..'Button']
		if button:IsShown() then
			button:ClearAllPoints()
			if i == 1 then
				button:SetPoint('RIGHT', frame.InfoFrame, 'RIGHT', -2, 0)
			else
				button:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
			end

			button.Text:SetFontObject(st:GetFont(config.font))

			button:SetSize(config.height - 4, config.height - 4)
			--st:SetBackdrop(button, config.template)
			prev = button
		end
	end

	frame.Timer.Text:SetFontObject(st:GetFont(config.font))
	frame.Timer.Text:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
	frame.Timer.Text:SetWidth(40)
end

function LT:GroupLootFrame_OnShow(frame)
	local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant, deSkillRequired = GetLootRollItemInfo(frame.rollID);

	frame:SetBackdrop(nil)
	local color = ITEM_QUALITY_COLORS[quality]
	frame.Timer:SetStatusBarColor(color.r, color.g, color.b)
	frame.Name:SetVertexColor(1, 1, 1)

	local text = ''

	if (quality >= 3) and (not bindOnPickUp) then
		text = 'BoE '
	end

	if count > 1 then
		text = text .. '(' .. count .. ') '
	end

	frame.Name:SetText(text .. name)
end

function LT:GroupLootFrame_OnUpdateTimer(self, elapsed)
	local sec = self:GetValue()

	self.Text:SetText(st.StringFormat:ToClock(sec))

	self:SetStatusBarColor(unpack(st.config.profile.colors.button.blue))

	if sec < 60 then
		self.Text:SetVertexColor(unpack(st.config.profile.colors.text.red))
	else
		self.Text:SetVertexColor(1, 1, 1)
	end
end

function LT:GroupLootContainer_Update(container)
	local config = st.config.profile.loot.roll
	local prev

	local height = 0

	for id, frame in ipairs(container.rollFrames) do
		frame:ClearAllPoints()
		if id == 1 then
			if config.grow_down then
				frame:SetPoint('TOP', container)
			else
				frame:SetPoint('BOTTOM', container)
			end
		else
			if config.grow_down then
				frame:SetPoint('TOP', prev, 'BOTTOM', 0, -config.spacing)
			else
				frame:SetPoint('BOTTOM', prev, 'TOP', 0, config.spacing)
			end
		end
		prev = frame
		height = height + config.height + config.spacing
	end

	container:SetHeight(height - config.spacing)

	--GroupLootContainer:ClearAllPoints()
	--GroupLootContainer:SetPoint(unpack(self.config.roll.position))
end

function LT:SkinNewRollFrame()
	for _,frame in pairs(GroupLootContainer.rollFrames) do
		self:SkinRollFrame(frame)
	end
end

function LT:InitializeRollFrame()
	self:SecureHook('GroupLootContainer_Update')
	self:SecureHook('GroupLootContainer_OpenNewFrame', 'SkinNewRollFrame')

	for _,frame in pairs(GroupLootContainer.rollFrames) do
		self:SkinRollFrame(frame)
	end

	-- Stop UIParent from moving the loot frame, we'll handle it
	if UIPARENT_MANAGED_FRAME_POSITIONS then
		UIPARENT_MANAGED_FRAME_POSITIONS.GroupLootContainer = nil
	end

	self:RegisterRollFrameEditMode()
	self:UpdateGroupLootConfig()

	if DEBUG then
		self:DebugGroupLootFrame()
	end
end

function LT:RegisterRollFrameEditMode()
	st:RegisterEditMode(GroupLootContainer, 'Group Loot Rolls', self.config.roll.position)
	GroupLootContainer.Selection:SetFrameStrata('DIALOG')
	st.EditMode:RegisterSlider(GroupLootContainer, "Width", "width", function(value)
		self.config.roll.width = value
		LT:UpdateGroupLootConfig()
	end, 100, 1000, 1)
end

function LT:UpdateGroupLootConfig()
	for _,frame in pairs(GroupLootContainer.rollFrames) do
		self:UpdateRollFrame(frame)
	end
	GroupLootContainer:SetWidth(self.config.roll.width)
end