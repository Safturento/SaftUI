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

local waiting = {} -- addon name -> the frame names waiting for it

local function MakeMovable(frameName)
    local frame = _G[frameName]
    if frame then st:EnableMoving(frame) end
    return frame
end

function MV:ADDON_LOADED(event, addon)
    local names = waiting[addon]
    if not names then return end
    waiting[addon] = nil
    for _, frameName in ipairs(names) do
        MakeMovable(frameName)
    end
    if not next(waiting) then self:UnregisterEvent('ADDON_LOADED') end
end

function MV:OnEnable()
    for _, info in ipairs(frames) do
        if not MakeMovable(info.name) then
            if info.addon then
                waiting[info.addon] = waiting[info.addon] or {}
                table.insert(waiting[info.addon], info.name)
                self:RegisterEvent('ADDON_LOADED')
            else
                print('Frame not found:', info.name)
            end
        end
    end
end
