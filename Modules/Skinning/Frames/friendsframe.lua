local st = SaftUI
local SK = st:GetModule('Skinning')

local function SkinFriendsButton(button)
	button:SetHighlightTexture(st.BLANK_TEX)
	button:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.1)
	button.name:SetFontObject(st:GetFont(st.config.profile.panels.font))
	button:SetHeight(50)

	button.status:ClearAllPoints()
	button.status:SetPoint('TOPLEFT')
	button.status:SetPoint('BOTTOMLEFT')
	button.status:SetWidth(4)

	-- button.travelPassButton:ClearAllPoints()
	st:Kill(button.gameIcon)
end

-- function FriendsFrame_UpdateFriends()
-- 	local scrollFrame = FriendsFrameFriendsScrollFrame;
-- 	local offset = HybridScrollFrame_GetOffset(scrollFrame);
-- 	local buttons = scrollFrame.buttons;
-- 	local numButtons = #buttons;
-- 	local numFriendButtons = scrollFrame.numFriendListEntries;

-- 	local usedHeight = 0;

-- 	scrollFrame.dividerPool:ReleaseAll();
-- 	scrollFrame.invitePool:ReleaseAll();
-- 	scrollFrame.PendingInvitesHeaderButton:Hide();
-- 	for i = 1, numButtons do
-- 		local button = buttons[i];
-- 		local index = offset + i;
-- 		if ( index <= numFriendButtons ) then
-- 			button.index = index;
-- 			local height = FriendsFrame_UpdateFriendButton(button);
-- 			button:SetHeight(height);
-- 			usedHeight = usedHeight + height;
-- 		else
-- 			button.index = nil;
-- 			button:Hide();
-- 		end
-- 	end
-- 	HybridScrollFrame_Update(scrollFrame, scrollFrame.totalFriendListEntriesHeight, usedHeight);
-- end

function SK:FriendsFrame_UpdateFriendButton(button)
	if not button.travelPassButton:IsEnabled() then
		button.travelPassButton:Hide()
	end

	local status_tex = button.status:GetTexture()
	button.status:SetTexture(st.BLANK_TEX)
	if status_tex == FRIENDS_TEXTURE_DND then
		button.status:SetVertexColor(unpack(st.config.profile.colors.button.red))
	elseif status_tex == FRIENDS_TEXTURE_AFK then
		button.status:SetVertexColor(unpack(st.config.profile.colors.button.yellow))
	else
		button.status:SetTexture('')
	end
end

SK.FrameSkins.FriendsFrame = function()
	SK:SkinBlizzardPanel(FriendsFrame)
	SK:SkinTabHeader(FriendsTabHeader)

	FriendsTabHeader:ClearAllPoints()
	FriendsTabHeader:SetPoint('TOPLEFT', FriendsFrame.header, 'BOTTOMLEFT', 6, -7)
	FriendsTabHeader:SetPoint('TOPRIGHT', FriendsFrame.header, 'BOTTOMRIGHT', -6, -7)

	FriendsFrameFriendsScrollFrame:ClearAllPoints()
	FriendsFrameFriendsScrollFrame:SetPoint('TOPLEFT', FriendsTabHeader, 'BOTTOMLEFT', 0, -7)
	st:SkinScrollBar(FriendsFrameFriendsScrollFrameScrollBar, 10)
	
	FriendsFrameIgnoreScrollFrame:ClearAllPoints()
	FriendsFrameIgnoreScrollFrame:SetPoint('TOPLEFT', FriendsTabHeader, 'BOTTOMLEFT', 0, -7)
	st:SkinScrollBar(FriendsFrameIgnoreScrollFrameScrollBar, 10)

	
	FriendsFrameFriendsScrollFrame:ClearAllPoints()
	FriendsFrameFriendsScrollFrame:SetPoint('TOPLEFT', FriendsTabHeader, 'BOTTOMLEFT', 0, -7)
	for _,button in pairs(FriendsFrameFriendsScrollFrame.buttons) do SkinFriendsButton(button) end

	st:Kill(FriendsFrameStatusDropDown)
	st:Kill(FriendsFrameBattlenetFrame)

	SK:SecureHook('FriendsFrame_UpdateFriendButton')

	local height = 40
	_G.FRIENDS_BUTTON_HEIGHTS[FRIENDS_BUTTON_TYPE_DIVIDER] = 1
	_G.FRIENDS_BUTTON_HEIGHTS[FRIENDS_BUTTON_TYPE_BNET] = height
	_G.FRIENDS_BUTTON_HEIGHTS[FRIENDS_BUTTON_TYPE_WOW] = height
	_G.FRIENDS_BUTTON_HEIGHTS[FRIENDS_BUTTON_TYPE_INVITE] = height
	_G.FRIENDS_BUTTON_HEIGHTS[FRIENDS_BUTTON_TYPE_INVITE_HEADER] = height

	FriendsFrameFriendsScrollFrame:SetHeight(height * 8)
end