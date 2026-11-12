local st = SaftUI
local MV = st:NewModule('Movable')

-- A window with an addon belongs to a load-on-demand Blizzard addon (both
-- clients: Blizzard_Transmog is LoadOnDemand), so it is made movable when that
-- addon loads, if it isn't there at login.
local frames = {
    { name = 'SettingsPanel' },
    { name = 'AddonList' },
    { name = 'TransmogFrame', addon = 'Blizzard_Transmog' },
}

local function MakeMovable(frameName)
    local frame = _G[frameName]
    if frame then st:EnableMoving(frame) end
    return frame
end

function MV:OnEnable()
    for _, info in ipairs(frames) do
        if not MakeMovable(info.name) then
            if info.addon then
                st:OnBlizzardAddon(info.addon, function() MakeMovable(info.name) end)
            else
                print('Frame not found:', info.name)
            end
        end
    end
end
