local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

-- Moves LibDBIcon minimap buttons into Blizzard's addon compartment dropdown.
--
-- AddonCompartmentFrame:RegisterAddon(data) reads (Blizzard_Minimap, live + forever):
--   text         name shown in the menu (also the sort key, must be a string)
--   icon         texture path / fileID / atlas shown to the right of the name
--   func         func(data, menuInputData, menu), menuInputData.buttonName is the mouse button
--   funcOnEnter  func(menuButton, elementDescription)
--   funcOnLeave  func(menuButton, elementDescription)
-- Every entry already registers for any click.

local DBICON_PREFIX = 'LibDBIcon10_'

-- Addons that build their own button without LibDBIcon (FollowTheArrow, DungeonMaster, Lueur, ...)
-- name it '<Addon>MinimapButton' and parent it to Minimap. That naming is the explicit marker we
-- key on: map pins (HandyNotes, Questie) and other Minimap children never use it.
local CUSTOM_BUTTON_SUFFIX = 'MinimapButton'

local entries = {} -- [name] = compartment data we registered
local handled = {} -- [name] = true once a LibDBIcon button has been processed
local callbackOwner = {} -- key for LibDBIcon / LibDataBroker callbacks
local hookedLibs = {}
local hiddenButtons = {}
local ready = false
local anchor

local function Normalize(text)
    if type(text) ~= 'string' then return end
    text = text:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('|H.-|h(.-)|h', '%1'):gsub('|T.-|t', '')
    text = text:lower():gsub('[^%w]', '')
    return text ~= '' and text or nil
end

-- Has this addon put itself into the compartment through its TOC (AddonCompartmentFunc)?
local function InCompartmentByToc(name)
    if not (C_AddOns and C_AddOns.GetAddOnMetadata) then return false end
    if C_AddOns.DoesAddOnExist and not C_AddOns.DoesAddOnExist(name) then return false end

    local ok, func = pcall(C_AddOns.GetAddOnMetadata, name, 'AddonCompartmentFunc')
    return ok and func ~= nil
end

-- Is there already an entry with this name in the compartment that we didn't add?
local function InCompartmentByText(name)
    local key = Normalize(name)
    if not key then return false end

    for _, data in ipairs(AddonCompartmentFrame.registeredAddons or {}) do
        if data ~= entries[name] and Normalize(data.text) == key then
            return true
        end
    end
    return false
end

local function AlreadyInCompartment(name, button)
    if button.compartmentData then return true end -- LibDBIcon's own showInCompartment option
    return InCompartmentByToc(name) or InCompartmentByText(name)
end

local function GetAnchor()
    -- Handed to OnClick so menus/windows anchor near the compartment button
    -- without addons getting a reference to a Blizzard frame
    if not anchor then
        anchor = CreateFrame('Frame', 'SaftUI_CompartmentAnchor', UIParent)
        anchor:SetAllPoints(AddonCompartmentFrame)
    end
    return anchor
end

local function GetDataObject(name, button)
    if button and button.dataObject then return button.dataObject end
    local ldb = LibStub('LibDataBroker-1.1', true)
    return ldb and ldb:GetDataObjectByName(name)
end

local function HideButton(button)
    if hiddenButtons[button] then return end
    hiddenButtons[button] = true

    -- LibDBIcon (and the owning addon) can call Show/Refresh at any time
    button:HookScript('OnShow', button.Hide)
    button:Hide()
end

local function RemoveEntry(name)
    local data = entries[name]
    if not data then return end
    entries[name] = nil

    local list = AddonCompartmentFrame.registeredAddons
    for i = #list, 1, -1 do
        if list[i] == data then
            tremove(list, i)
            AddonCompartmentFrame:UpdateDisplay()
            return
        end
    end
end

local function RegisterEntry(name, button)
    local data = {
        text = name,
        icon = GetDataObject(name, button).icon,
        func = function(_, menuInputData)
            local obj = GetDataObject(name, button)
            if obj and obj.OnClick then
                obj.OnClick(GetAnchor(), menuInputData and menuInputData.buttonName or 'LeftButton')
            end
        end,
        funcOnEnter = function(frame)
            local obj = GetDataObject(name, button)
            if not obj then return end

            if obj.OnTooltipShow then
                GameTooltip:SetOwner(frame, 'ANCHOR_RIGHT')
                obj.OnTooltipShow(GameTooltip)
                GameTooltip:Show()
            elseif obj.OnEnter then
                obj.OnEnter(frame)
            end
        end,
        funcOnLeave = function(frame)
            if GameTooltip:GetOwner() == frame then
                GameTooltip:Hide()
            end

            local obj = GetDataObject(name, button)
            if obj and obj.OnLeave then
                obj.OnLeave(frame)
            end
        end,
    }

    entries[name] = data
    AddonCompartmentFrame:RegisterAddon(data)
end

-- Custom (non-LibDBIcon) buttons have no data object, so entries forward to the button's own
-- scripts. They get our anchor frame as `self` so menus/tooltips open at the compartment.
local function GetCustomIcon(button)
    local icon = button.icon or button.Icon
    if icon and icon.GetTexture then
        return icon:GetTexture(), icon.GetAtlas and icon:GetAtlas()
    end

    for _, region in ipairs({ button:GetRegions() }) do
        if region:IsObjectType('Texture') and region:GetDrawLayer() == 'ARTWORK' then
            return region:GetTexture(), region:GetAtlas()
        end
    end
end

local function RegisterCustomEntry(name, title, button)
    local texture, atlas = GetCustomIcon(button)

    local data = {
        text = title,
        icon = atlas or texture,
        func = function(_, menuInputData)
            local onClick = button:GetScript('OnClick')
            if onClick then
                onClick(GetAnchor(), menuInputData and menuInputData.buttonName or 'LeftButton')
            end
        end,
        funcOnEnter = function(frame)
            local onEnter = button:GetScript('OnEnter')
            if onEnter then onEnter(frame) end
        end,
        funcOnLeave = function(frame)
            local onLeave = button:GetScript('OnLeave')
            if onLeave then
                onLeave(frame)
            elseif GameTooltip:GetOwner() == frame then
                GameTooltip:Hide()
            end
        end,
    }

    entries[name] = data
    AddonCompartmentFrame:RegisterAddon(data)
end

local function HandleCustomButton(name, button)
    if handled[name] then return end
    if not button:IsObjectType('Button') or button:GetParent() ~= Minimap then return end
    if not button:GetScript('OnClick') then return end
    handled[name] = true

    HideButton(button)

    -- DungeonMaster and Lueur declare AddonCompartmentFunc in their TOC, so hiding the button is enough
    local addon = name:sub(1, -#CUSTOM_BUTTON_SUFFIX - 1)
    local title = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addon, 'Title')
    if type(title) ~= 'string' or title == '' then
        title = addon:gsub('(%l)(%u)', '%1 %2')
    end

    if not (InCompartmentByToc(addon) or InCompartmentByText(title)) then
        RegisterCustomEntry(name, title, button)
    end
end

local function HandleButton(name, button)
    if handled[name] or not button then return end
    if not GetDataObject(name, button) then return end
    handled[name] = true

    HideButton(button)

    if not AlreadyInCompartment(name, button) then
        RegisterEntry(name, button)
    end
end

local function OnIconChanged(_, name, _, value)
    if entries[name] then
        entries[name].icon = value
    end
end

local function HookLibraries()
    local dbicon = LibStub('LibDBIcon-1.0', true)
    if dbicon and not hookedLibs[dbicon] then
        hookedLibs[dbicon] = true

        dbicon.RegisterCallback(callbackOwner, 'LibDBIcon_IconCreated', function(_, button, name)
            -- LibDBIcon adds its own compartment entry right before firing this
            HandleButton(name, button)
        end)

        -- The owning addon's own "show in compartment" option was toggled after we ran
        if dbicon.AddButtonToCompartment then
            hooksecurefunc(dbicon, 'AddButtonToCompartment', function(_, name)
                local button = dbicon:GetMinimapButton(name)
                if button and button.compartmentData then
                    RemoveEntry(name)
                end
            end)
        end
        if dbicon.RemoveButtonFromCompartment then
            hooksecurefunc(dbicon, 'RemoveButtonFromCompartment', function(_, name)
                if handled[name] and not entries[name] then
                    handled[name] = nil
                    HandleButton(name, dbicon:GetMinimapButton(name))
                end
            end)
        end
    end

    local ldb = LibStub('LibDataBroker-1.1', true)
    if ldb and not hookedLibs[ldb] then
        hookedLibs[ldb] = true
        ldb.RegisterCallback(callbackOwner, 'LibDataBroker_AttributeChanged__icon', OnIconChanged)
    end
end

local function ScanCustomButtons()
    for _, child in ipairs({ Minimap:GetChildren() }) do
        local name = child:GetName()
        if name and #name > #CUSTOM_BUTTON_SUFFIX and name:sub(-#CUSTOM_BUTTON_SUFFIX) == CUSTOM_BUTTON_SUFFIX
            and not name:find('^'..DBICON_PREFIX) and not name:find('^SaftUI')
            and not issecurevariable(name) then
            HandleCustomButton(name, child)
        end
    end
end

local function ScanButtons()
    local dbicon = LibStub('LibDBIcon-1.0', true)
    if dbicon then
        for _, name in ipairs(dbicon:GetButtonList()) do
            HandleButton(name, dbicon:GetMinimapButton(name))
        end
    end

    ScanCustomButtons()
end

local function Start()
    if ready then return end
    ready = true

    HookLibraries()
    ScanButtons()
    C_Timer.After(5, ScanCustomButtons) -- catches buttons created after login
end

function MicroMenu:SetupMinimapButtons()
    if not AddonCompartmentFrame or not AddonCompartmentFrame.RegisterAddon then return end
    if not st.config.profile.minimap.compartment_buttons then return end

    local events = CreateFrame('Frame')
    events:RegisterEvent('PLAYER_ENTERING_WORLD')
    events:RegisterEvent('ADDON_LOADED')
    events:SetScript('OnEvent', function(_, event)
        if event == 'PLAYER_ENTERING_WORLD' then
            events:UnregisterEvent('PLAYER_ENTERING_WORLD')
            -- Wait for the compartment's own PLAYER_ENTERING_WORLD registration of TOC addons
            C_Timer.After(0, Start)
        elseif ready then
            -- Load-on-demand addons can bring LibDBIcon in late
            -- The addon's own ADDON_LOADED handler (which may create its button) runs after ours
            C_Timer.After(0, function()
                HookLibraries()
                ScanButtons()
            end)
        end
    end)

    -- Enabled after login: the compartment has already registered TOC addons
    if not AddonCompartmentFrame:IsEventRegistered('PLAYER_ENTERING_WORLD') then
        events:UnregisterEvent('PLAYER_ENTERING_WORLD')
        Start()
    end
end
