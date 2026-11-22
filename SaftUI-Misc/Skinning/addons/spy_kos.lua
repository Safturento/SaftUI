local st = SaftUI
local SP = st:GetModule('Skinning'):GetModule('Spy')
local L = SP.lib

-- The Spy skin's the Kill on Sight button (Spy_KoSButton). Shares spy.lua's pieces through SP.lib.
-- Spy's own click handler stays. Where SaftUI's unit frames own the target (SaftUI_Target), the
-- button moves onto it, at its top right, and is driven by the target and the KoS list;
-- otherwise it stays where Spy put it, only restyled. Nothing here calls Blizzard's TargetFrame.

local SIZE, INSET, ICON = 16, 2, 12

local skinned = setmetatable({}, L.weak) -- Spy's button -> its icon texture, once skinned
local iconState = setmetatable({}, L.weak) -- icon texture -> true while Spy says the target is on KoS
local settingIcon = false -- the skin's own SetTexture isn't taken for Spy's
local hookedToggle = false
local listening = false

local function Button() return _G.Spy and _G.Spy.KoSButton end

local function Paint(icon)
	local color = st:Color('text', iconState[icon] and 'danger' or 'muted')
	icon:SetVertexColor(color:GetRGB())
end

-- Spy sets the on or off art, which says the state; the skull goes back on it.
local function SwapArt(icon, path)
	if settingIcon then return end
	if type(path) == 'string' then
		if path:find('button%-on') then iconState[icon] = true
		elseif path:find('button%-off') then iconState[icon] = false end
	end
	settingIcon = true
	icon:SetTexture(st.icons.skull)
	settingIcon = false
	Paint(icon)
end

local function Home()
	return _G.SaftUI_Target
end

local rehomed = setmetatable({}, L.weak)

-- Moves the button onto SaftUI's target frame once it exists.
local function Rehome(button)
	local target = Home()
	if not target or rehomed[button] == target then return rehomed[button] ~= nil end
	rehomed[button] = target
	button:SetParent(target)
	button:ClearAllPoints()
	button:SetPoint('TOPRIGHT', target, 'TOPRIGHT', -INSET, -INSET)
	button:SetSize(SIZE, SIZE)
	local icon = skinned[button]
	if icon then
		icon:ClearAllPoints()
		icon:SetPoint('CENTER')
		icon:SetSize(ICON, ICON)
	end
	return true
end

local function OnList(name)
	local db = _G.SpyPerCharDB
	return name ~= nil and type(db) == 'table' and type(db.KOSData) == 'table' and db.KOSData[name] and true or false
end

-- The name of the target when it is an enemy player, else nil. Spy Forever's own reader
-- guards every secret value (a battleground's unit can hand back a secret name or
-- hostility); without it the unit calls are read through st.Plain and a secret reads as no.
local function TargetName()
	local spy = _G.Spy
	if type(spy.EnemyPlayerName) == 'function' then return spy:EnemyPlayerName('target') end
	if not (st.Plain(UnitIsEnemy('player', 'target')) and st.Plain(UnitIsPlayer('target'))) then return end
	local name = st.PlainString(GetUnitName('target', true))
	if type(name) == 'string' and name ~= '' then return name end
end

-- Shows or hides the button for the current target and shows whether it is on the list.
-- Only when the button lives on SaftUI's target; Spy drives it otherwise.
function SP:UpdateKoS()
	local button = Button()
	if type(button) ~= 'table' or not skinned[button] or not Rehome(button) then return end
	local spy = _G.Spy
	local profile = spy.db and spy.db.profile
	local name = profile and profile.ShowKoSButton and TargetName()
	if name then
		local icon = skinned[button]
		iconState[icon] = OnList(name)
		Paint(icon)
		button:Show()
	else
		button:Hide()
	end
end

function SP:SkinKoS()
	local button = Button()
	if type(button) ~= 'table' or skinned[button] then return end
	local icon = button.Icon
	if type(icon) ~= 'table' or not icon.SetTexture then return end
	skinned[button] = icon

	if button.Background then button.Background:SetAlpha(0) end
	if button.Border then button.Border:SetAlpha(0) end
	L.Panel(button, 'control')
	if button.SetHighlightTexture then
		button:SetHighlightTexture(st.BLANK_TEX, 'BLEND')
		st:AddStates(button, 'icon', { pieces = { hover = button:GetHighlightTexture() } })
	end

	hooksecurefunc(icon, 'SetTexture', SwapArt)
	SwapArt(icon, icon.GetTexture and icon:GetTexture())

	if not hookedToggle and type(_G.Spy.ToggleKOSPlayer) == 'function' then
		hookedToggle = true
		hooksecurefunc(_G.Spy, 'ToggleKOSPlayer', function() SP:UpdateKoS() end)
	end
	if not listening then
		listening = true
		SP:RegisterEvent('PLAYER_TARGET_CHANGED', 'UpdateKoS')
		SP:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateKoS')
	end
	SP:UpdateKoS()
end

-- Colors changed: the icon's tone again (spy.lua's handler runs first).
local colorsChanged = SP.OnColorsChanged
function SP:OnColorsChanged(group, ...)
	if colorsChanged then colorsChanged(self, group, ...) end
	if group ~= nil and group ~= 'text' then return end
	for _, icon in pairs(skinned) do Paint(icon) end
end
