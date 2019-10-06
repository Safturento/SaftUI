local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

---------------------------------------------
-- INITIALIZE -------------------------------
---------------------------------------------

button_spacing_y = 20
button_spacing_x = 44
button_size = 30

function SK:SetTalentButtonLocation(button, tier, column)
	button:ClearAllPoints()
	local x = column * button_size + (column - 1) * button_spacing_x
	local y = tier * button_size + (tier - 1) * button_spacing_y
	button:SetPoint('TOPLEFT', TalentFrame.header, 'BOTTOMLEFT', x, -y)

	if not button.skinned then
		SkinTalentButton(button)
	end

	local tier, column, isLearnable = GetTalentPrereqs(PanelTemplates_GetSelectedTab(TalentFrame), button:GetID())

	if tier and column then
		local connected_button = _G['TalentFrameTalent'..TALENT_BRANCH_ARRAY[tier][column].id]

		if not button.connected_texture then
			button.connected_texture = button:CreateTexture(nil, 'OVERLAY')
			button.connected_texture:SetWidth(2)
			button.connected_texture:SetWidth(2)
			st:SetBackdrop(button.connected_texture, button.backdrop.template)
			button.connected_texture.backdrop:SetFrameLevel(button.backdrop:GetFrameLevel())
			button.connected_texture.backdrop.outer_shadow:Hide()
		end
		button.connected_texture:ClearAllPoints()
		button.connected_texture:SetPoint('BOTTOM', button, 'TOP', 0, 3)
		button.connected_texture:SetPoint('TOP', connected_button, 'BOTTOM', 0, -3)
		button.connected_texture:Show()
		button.connected_texture.backdrop:Show()
	elseif button.connected_texture then
		button.connected_texture:Hide()
		button.connected_texture.backdrop:Hide()
	end
end

function SkinTalentButton(button)
	if button.skinned then return end
		
	button:SetSize(button_size, button_size)
	button:SetParent(TalentFrame)
	st:StripTextures(button)
	st.SkinActionButton(button)
	button:SetFrameLevel(20)
	local rank = _G[button:GetName()..'Rank']
	rank:ClearAllPoints()
	rank:SetPoint('BOTTOMRIGHT', 0, 2)
	
	button.skinned = true
end

SK.AddonSkins.Blizzard_TalentUI = function()
	SK:SkinBlizzardPanel(TalentFrame, {fix_padding = true})
	
	st:Kill(TalentFrameScrollFrame)
	st:Kill(TalentFramePointsMiddle)
	st:Kill(TalentFrameSpentPoints)
	st:Kill(TalentFrameCancelButton)

	TalentFrame.backdrop:SetPoint('BOTTOMRIGHT', -58, 74)
	TalentFrame.header:SetPoint('TOPRIGHT', -58, -12)

	SK:SecureHook('SetTalentButtonLocation')
		
	TalentFrameBackgroundTopLeft:ClearAllPoints()
	TalentFrameBackgroundTopLeft:SetPoint('TOPLEFT', TalentFrame.header, 'BOTTOMLEFT')

	TalentFrameTalentPoints:SetFontObject(st:GetFont(st.config.profile.panels.font))
	TalentFrameTalentPointsText:SetFontObject(st:GetFont(st.config.profile.panels.font))
	TalentFrameTalentPointsText:ClearAllPoints()
	TalentFrameTalentPointsText:SetPoint('BOTTOMRIGHT', TalentFrame.backdrop, 'BOTTOMRIGHT', -10, 10)

	local scale = 1.22
	TalentFrameBackgroundTopLeft:SetScale(scale)
	TalentFrameBackgroundBottomLeft:SetScale(scale)

	TalentFrameBackgroundTopRight:Hide()
	TalentFrameBackgroundBottomRight:Hide()
end