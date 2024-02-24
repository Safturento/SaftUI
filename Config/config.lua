local st = SaftUI
local AceSerializer = LibStub('AceSerializer-3.0')
local LibCompress = LibStub('LibCompress')
local LibBase64 = LibStub('LibBase64-1.0')

local Config = st:NewModule('Config')
st.CF = Config

function Config:OnInitialize()
	--self:InitializeConfigDialog()
end

SLASH_SAFTUI1 = '/saftui'
SLASH_SAFTUI2 = '/sui'
SLASH_SAFTUI3 = '/stui'
SlashCmdList.SAFTUI = function(msg)
	InterfaceOptionsFrame_OpenToCategory("SaftUI")
end
