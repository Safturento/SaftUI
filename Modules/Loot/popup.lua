local ADDON_NAME, st = ...
local LT = st:GetModule('Loot')

function LT:LootFrame_Show()
	if not LootFrame.skinned then
		LT:SkinLootFrame()
		LootFrame.skinned = true
	end

	local numItems = LootFrame.numLootItems
	for ID = numItems, 1, -1 do

		local button = LootFrame.buttons[ID] or self:CreateLootButton(ID)
		button:ClearAllPoints()
		if ID == numItems then
			button:SetPoint('TOP', LootFrame.header, 'BOTTOM', 0, -self.config.popup.spacing)
		else
			button:SetPoint('TOP', LootFrame.buttons[ID + 1], 'BOTTOM', 0, -self.config.popup.spacing)
		end
	end
	LOOTFRAME_NUMBUTTONS = max(LOOTFRAME_NUMBUTTONS, numItems)
end

function LT:CreateLootButton(ID)
	local button = CreateFrame('Frame', 'LootButton'..ID,  LootFrame, 'LootButtonTemplate')
	button:SetID(ID)

	-- button.icon = button:CreateTexture('LootButton'..ID..'IconTexture', 'OVERLAY')
	-- button.Count = button:CreateFontString(nil, 'OVERLAY')
	-- button.IconBorder = button:CreateTexture(nil, 'OVERLAY')
	-- button.IconOverlay = button:CreateTexture(nil, 'OVERLAY')

	LootFrame.buttons[ID] = button

	self:SkinLootButton(button)

	return button
end

function LT:SkinLootButton(button)
	local ID = button:GetID()
	st:Kill(_G['LootButton'..ID..'NameFrame'])

	button:SetSize(self.config.popup.width, self.config.popup.button_height)

	button.icon:ClearAllPoints()
	button.icon:SetPoint('LEFT')
	button.icon:SetSize(self.config.popup.button_height, self.config.popup.button_height)
	st.SkinActionButton(button, self.config.popup)

	st:Kill(button.IconBorder)
	st:Kill(button.IconOverlay)

	button.nametext = _G['LootButton'..ID..'Text']
	button.nametext:SetFontObject(st:GetFont(self.config.popup.font))
	button.nametext:ClearAllPoints()
	button.nametext:SetPoint('LEFT', button.icon, 'RIGHT', 7, 0)
	button.nametext:SetPoint('RIGHT', button, 'RIGHT', -7, 0)
	button.nametext:SetWordWrap(self.config.popup.name_wrap)

	button.Count:SetFontObject(st:GetFont(self.config.popup.font))
	button.Count:ClearAllPoints()
	button.Count:SetPoint('BOTTOMRIGHT', button.icon, 'BOTTOMRIGHT', 0, 0)
end


function LT:SkinLootFrame()
	local config = self.config.popup

	st:StripTextures(LootFrame)
	st:Kill(LootFrameInsetBg)
	st:Kill(LootFramePortraitOverlay)
	st:Kill(LootFrameBtnCornerLeft)
	st:Kill(LootFrameButtonBottomBorder)
	st:Kill(LootFrameInset)

	for k,region in pairs({LootFrame:GetRegions()}) do
		if region:GetObjectType() == 'FontString' then
			if region:GetText() == ITEMS then
				LootFrameTitle = region
			else
				st:Kill(region)
			end
		end
	end

	LootFrameTitle:SetFontObject(st:GetFont(config.font))
	st:CreateHeader(LootFrame, LootFrameTitle, LootFrameCloseButton) 
	st:SetBackdrop(LootFrame.header, config.template)
	
	LootFrame.buttons = {}
	for i=1, 4 do
		LootFrame.buttons[i] = _G['LootButton'..i]
		self:SkinLootButton(_G['LootButton'..i])
	end

	LootFrame:SetWidth(self.config.popup.width)
end


function LT:InitializeLootFrame()
	self:SecureHook('LootFrame_Show')
end