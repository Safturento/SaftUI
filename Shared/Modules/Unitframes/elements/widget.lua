local st = SaftUI
local UF = st:GetModule('Unitframes')

function Constructor(unitframe)
    local widget = UF:AddStatusBarElement(unitframe, 'Widget')
    UF:AddText(unitframe, widget)

    return widget
end

UF:RegisterElement('Widget', Constructor)