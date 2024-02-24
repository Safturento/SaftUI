local st = SaftUI
local AU = st:NewModule('Auras')

function AU:OnInitialize()
    if st.retail then

    else
        BuffFrame:ClearAllPoints()
        BuffFrame:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -20, 0)
        BuffFrame:ClearAllPoints()
        BuffFrame:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -20, 0)
    end
end