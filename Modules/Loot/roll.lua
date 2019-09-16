local ADDON_NAME, st = ...

local LT = st:GetModule('Loot')

local roll_buttons = {
	{name = 'Pass', icon_text = 'P', color = 'red'},
	{name = 'Greed', icon_text = 'G', color = 'normal'},
	{name = 'Need', icon_text = 'N', color = 'yellow'},
}

function LT:DebugGroupLootFrame()
	GetLootRollItemInfo = function(rollID)
		local texture			= 135575
		name						= 'Ravager'
		count						= rollID
		quality					= rollID+1
		bindOnPickUp			= math.random(0,1) > 0.5
		canNeed					= true
		canGreed					= true
		canDisenchant			= true
		reasonNeed				= 0
		reasonGreed				= 0
		reasonDisenchant		= 0
		deSkillRequired		= 0

		return texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant, deSkillRequired
	end
	
	function GroupLootFrame_OnUpdate(self, elapsed)
	end

	for i=1, NUM_GROUP_LOOT_FRAMES do
		GroupLootFrame_OpenNewFrame(i, 300)
		_G['GroupLootFrame'..i].Timer:SetValue(math.random(10, 300))
	end
end

function LT:SkinRollFrame(frame)
	st:StripTextures(frame)

	st:SkinIcon(frame.IconFrame.Icon,nil, frame.IconFrame)
	frame.IconFrame:ClearAllPoints()
	frame.IconFrame:SetPoint('LEFT', frame, 0, 0)

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
		st:StripTextures(button)
		
		button:SetHighlightTexture(st.BLANK_TEX)
		button:GetHighlightTexture():SetAlpha(0.1)

		button.Text = button:CreateFontString(nil, 'OVERLAY')
		button.Text:SetFontObject(GameFontNormal)
		button.Text:SetPoint('CENTER', 1, 0)
		button.Text:SetVertexColor(unpack(st.config.profile.colors.text[info.color]))
		button.Text:SetText(info.icon_text)

		prev = button
	end
end

function LT:UpdateRollFrame(frame)
	local config = self.config.roll
	local font_obj = st:GetFont(config.font)

	frame:SetSize(config.width, config.height)
	
	frame.Name:SetFontObject(font_obj)
	frame.Name:ClearAllPoints()
	frame.Name:SetHeight(config.height)
	frame.Name:SetPoint('LEFT', frame.Timer, 5, 0)
	frame.Name:SetPoint('RIGHT', frame.Timer.Text, 'LEFT', -5, 0)
	
	st:SetBackdrop(frame.IconFrame, config.template)
	frame.IconFrame.Count:SetFontObject(font_obj)
	frame.IconFrame:SetSize(config.height, config.height)

	st:SetBackdrop(frame.Timer, config.template)
	frame.Timer:SetStatusBarTexture(st.BLANK_TEX)
	frame.Timer:ClearAllPoints()
	frame.Timer:SetPoint('LEFT', frame.IconFrame, 'RIGHT', config.spacing, 0)
	frame.Timer:SetHeight(config.height)
	frame.Timer:SetWidth(config.width - 4 * (config.height + config.spacing))
	
	st:StripTextures(frame.Timer, true)

	frame.Timer.Text:SetFontObject(font_obj)
	frame.Timer.Text:SetPoint('RIGHT', -5, 0)
	frame.Timer.Text:SetWidth(40)

	local prev 
	for i, info in ipairs(roll_buttons) do
		local button = frame[info.name..'Button']
		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
		else
			button:SetPoint('RIGHT', prev, 'LEFT', -config.spacing, 0)
		end
		
		button.Text:SetFontObject(font_obj)
		
		button:SetSize(config.height, config.height)
		st:SetBackdrop(button, config.template)
		prev = button
	end
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
	
	if sec < 30 then
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
end

function LT:InitializeRollFrame()
	self:SecureHook('GroupLootContainer_Update')

	for i=1, NUM_GROUP_LOOT_FRAMES do
		self:SkinRollFrame(_G['GroupLootFrame'..i])
	end

	-- Stop UIParent from moving the loot frame, we'll handle it
	UIPARENT_MANAGED_FRAME_POSITIONS.GroupLootContainer = nil

	self:UpdateGroupLootConfig()

	if self.DEBUG then self:DebugGroupLootFrame() end
end

function LT:UpdateGroupLootConfig()
	
	for i=1, NUM_GROUP_LOOT_FRAMES do
		self:UpdateRollFrame(_G['GroupLootFrame'..i])
		self:SecureHookScript(_G['GroupLootFrame'..i], 'OnShow', 'GroupLootFrame_OnShow')
		self:SecureHookScript(_G['GroupLootFrame'..i].Timer, 'OnUpdate', 'GroupLootFrame_OnUpdateTimer')
	end
	
	GroupLootContainer:SetWidth(self.config.roll.width)
	GroupLootContainer:ClearAllPoints()
	GroupLootContainer:SetPoint(unpack(self.config.roll.position))
end