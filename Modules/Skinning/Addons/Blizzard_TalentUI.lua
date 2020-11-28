local st = SaftUI
local SK = st:GetModule('Skinning')

local button_spacing_y = 20
local button_spacing_x = 20
local button_size = 30

function SkinTalentButton(button)
	if button.skinned then return end
		
	button:SetSize(button_size, button_size)
	button:SetParent(TalentFrame)
	st:StripTextures(button)
	st:SkinActionButton(button)
	button:SetFrameLevel(20)
	local rank = _G[button:GetName()..'Rank']
	rank:ClearAllPoints()
	rank:SetPoint('BOTTOMRIGHT', 0, 2)
	
	button.skinned = true
end

function SK:SetTalentButtonLocation(button, tier, column)
	button:ClearAllPoints()
	local x = st.config.profile.panels.padding + (column - 1) * (button_size + button_spacing_x)
	local y = st.config.profile.panels.padding + (tier - 1) * (button_size + button_spacing_y)
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

function SK:TalentFrame_Update()

end

SK.AddonSkins.Blizzard_TalentUI = function()
	st:CreateFooter(TalentFrame)
	SK:SkinBlizzardPanel(TalentFrame, {fix_padding = false})
	
	st:Kill(TalentFrameScrollFrame)
	st:Kill(TalentFramePointsMiddle)
	st:Kill(TalentFrameSpentPoints)
	st:Kill(TalentFrameCancelButton)

	for i=21, 60 do
		local talent = CreateFrame('Button', 'TalentFrameTalent'..i, TalentFrame, 'TalentButtonTemplate')
		talent:SetID(i)
		talent:Hide()
	end

	local tree_width = 2 * st.config.profile.panels.padding + 4 * button_size + 3 * button_spacing_x
	TalentFrame.small_width = tree_width
	TalentFrame.large_width = tree_width*3
	local height = 2 * st.config.profile.panels.padding + 2 * st.config.profile.headers.height +  7 * button_size + 6 * button_spacing_x
	TalentFrame:SetSize(tree_width*3, height)
	UIPanelWindows["TalentFrame"].xoffset = 0
	UIPanelWindows["TalentFrame"].yoffset = 0
	
	SK:SecureHook('SetTalentButtonLocation')
	SK:SecureHook('TalentFrame_Update')

	TalentFrameTalentPoints:SetFontObject(st:GetFont(st.config.profile.panels.font))
	TalentFrameTalentPoints:SetParent(TalentFrame.footer)
	TalentFrameTalentPointsText:SetFontObject(st:GetFont(st.config.profile.panels.font))
	TalentFrameTalentPointsText:ClearAllPoints()
	TalentFrameTalentPointsText:SetPoint('RIGHT', TalentFrame.footer, 'RIGHT', -10, -2)
	
	
	
	local scale = 1.22
	-- TalentFrameBackgroundTopLeft:ClearAllPoints()
	-- TalentFrameBackgroundTopLeft:SetPoint('TOPLEFT', TalentFrame.header, 'BOTTOMLEFT')
	-- TalentFrameBackgroundTopLeft:SetWidth(250)
	-- TalentFrameBackgroundTopLeft:SetScale(scale)
	-- -- TalentFrameBackgroundTopLeft:SetTexCoord(0, 0.8, 0, 1)
	-- TalentFrameBackgroundBottomLeft:SetScale(scale)

	TalentFrameBackgroundTopLeft:Hide()
	TalentFrameBackgroundBottomLeft:Hide()
	TalentFrameBackgroundTopRight:Hide()
	TalentFrameBackgroundBottomRight:Hide()
end