local st = SaftUI
local MP = st:GetModule('Maps')

function MP:InitializeMinimap()
    MinimapCompassTexture:Hide()
    Minimap:SetMaskTexture(st.BLANK_TEX)
	function GetMinimapShape() return "SQUARE" end
    st:SetBackdrop(Minimap, self.config.minimap.template)

    Minimap:SetSize(self.config.minimap.size, self.config.minimap.size)

    -- Stop blizzard from moving minimap around
    MinimapCluster.SetHeaderUnderneath = function()  end

	Minimap:ClearAllPoints()
	Minimap:SetPoint(st:UnpackPoint(self.config.minimap.position))

    Minimap:SetArchBlobRingScalar(0)
    Minimap:SetQuestBlobRingScalar(0)
end

