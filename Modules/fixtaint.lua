local st = SaftUI
local TaintFix = st:NewModule('TaintFix')

function TaintFix:OnInitalize()
    ClickBindingFrame:UnregisterEvent('CLICKBINDINGS_SET_HIGHLIGHTS_SHOWN')
end