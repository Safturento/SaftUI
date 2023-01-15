local st = SaftUI
local TaintFix = st:NewModule('TaintFix', 'AceHook-3.0', 'AceEvent-3.0')


function TaintFix:OnInitalize()
    ClickBindingFrame:UnregisterEvent('CLICKBINDINGS_SET_HIGHLIGHTS_SHOWN')
end

