local st = SaftUI
local SK = st:GetModule('Skinning')
local WF = SK:NewModule('Blizzard_WatchFrame')

function WF:WatchFrame_Update()
    WatchFrame:ClearAllPoints()
    WatchFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT',  50, -280)
    WatchFrame:SetHeight(700)
    WatchFrame:SetWidth(300)
	WatchFrame:UpdateScrollChildRect();
end

function WF:OnEnable()
    if st.retail then return end

    WatchFrame:SetScript("OnSizeChanged", function() end);
--     WatchFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT',  50, -280)
    WatchFrame:SetHeight(700)
    WatchFrame:SetWidth(300)
    WatchFrame:ClearAllPoints()
    local _SetPoint = WatchFrame.SetPoint
    WatchFrame.SetPoint = function(self)
        WatchFrame:ClearAllPoints()
        _SetPoint(self, 'TOPLEFT', UIParent, 'TOPLEFT',  50, -280)
    end
--     self:SecureHook('WatchFrame_Update')
--     self:SecureHook('WatchFrame_OnEvent', 'WatchFrame_Update')
--     self:WatchFrame_Update()
end
