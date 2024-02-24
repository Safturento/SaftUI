local st = SaftUI
local UF = st:GetModule('Unitframes')

function Constructor(unitframe)
    if st.retail then
        local widget = UF:AddStatusBarElement(unitframe, 'Widget')
        UF:AddText(unitframe, widget)

        return widget
    end
end

UF:RegisterElement('Widget', Constructor)