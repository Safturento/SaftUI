
local st = SaftUI
local MV = st:NewModule('Movable')

local frames = {
    'SettingsPanel',
    'AddonList',
    'TransmogFrame',
}

function MV:OnEnable()
    for _,frameName in pairs(frames) do
        local frame = _G[frameName]
        if frame then
            st:EnableMoving(frame)
        else
            print('Frame not found:', frameName)
        end
    end
end