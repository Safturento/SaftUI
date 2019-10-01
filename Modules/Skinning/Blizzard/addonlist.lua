local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

SK.FrameSkins.AddonList = function()
	st:StripTextures(AddonList)

	st:CreateHeader(AddonList, AddonListTitleText, AddonListCloseButton)
	st:SetBackdrop(AddonList, st.config.profile.panels.template)

	st:StripTextures(AddonListScrollFrameScrollChildFrame)
	st:Kill(AddonListInsetBg)
	st:Kill(AddonListInset)

	st:SkinScrollBar(AddonListScrollFrameScrollBar)

	for _,name in pairs({'EnableAll', 'DisableAll', 'Okay', 'Cancel'}) do
		st:StripTextures(_G['AddonList'..name..'Button'])
		st.SkinActionButton(_G['AddonList'..name..'Button'])
	end

	AddonListDisableAllButton:ClearAllPoints()
	AddonListDisableAllButton:SetPoint('LEFT', AddonListEnableAllButton, 'RIGHT', 7, 0)
	
	AddonListOkayButton:ClearAllPoints()
	AddonListOkayButton:SetPoint('RIGHT', AddonListCancelButton, 'LEFT', -7, 0)
end