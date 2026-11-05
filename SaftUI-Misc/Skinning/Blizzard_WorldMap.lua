local st = SaftUI
local SK = st:GetModule('Skinning')
local WF = SK:NewModule('Blizzard_WorldMap')


function WF:OnEnable()
    st:EnableResizing(WorldMapFrame)
    st:EnableMoving(WorldMapFrame)
end
