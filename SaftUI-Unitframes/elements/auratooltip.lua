local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Tooltips for unit frame buffs and debuffs (elements/auras.lua).

	Blizzard's aura buttons show their own tooltip, AuraButtonTooltip. It's a
	forbidden frame, so addons can't hook or restyle it, and SaftUI's tooltip skin
	doesn't reach it. On Forever it's also wrong: it looks the aura up by instance ID,
	which gives another aura or none for some auras on other players
	(.agents/clients.md). The buttons can't be hooked either: their template forbids
	addon scripts on them and on their children.

	So each aura element gets an overlay, a SaftUI frame over the whole aura area that
	takes mouse motion and lets clicks through. While the cursor is on it, it finds the
	shown button under the cursor, matches that button's icon to the unit's auras, and
	shows GameTooltip:SetUnitAura for the match's index. That's right on both clients
	and carries SaftUI's tooltip skin. The tooltip sits above the button, left edges
	lined up, like Blizzard's (ANCHOR_TOPLEFT). Two auras with the same icon show the
	first one's tooltip; with Only mine, the first one that's yours.

	The buttons refuse addon access while aura data is secret (C_Secrets.ShouldAurasBeSecret;
	on Forever, in combat). Then the overlay stops taking the mouse, and Blizzard's own
	tooltip shows as before.
]]

local THROTTLE = 0.1

-- Every overlay, so events can turn them all on or off.
local overlays = {}

local function AurasSecret()
	return C_Secrets ~= nil and C_Secrets.ShouldAurasBeSecret ~= nil and C_Secrets.ShouldAurasBeSecret()
end

local function HideTooltip(overlay)
	overlay.tooltipButton = nil
	if GameTooltip:IsOwned(overlay) then
		GameTooltip:Hide()
	end
end

-- Takes the mouse (and so blocks Blizzard's tooltip) only while it's on.
local function SetOverlayActive(overlay, active)
	overlay:SetMouseMotionEnabled(active)
	if not active then
		overlay:SetScript('OnUpdate', nil)
		HideTooltip(overlay)
	end
end

local function RefreshOverlays(forceOff)
	local active = not forceOff and not AurasSecret()
	for overlay in pairs(overlays) do
		SetOverlayActive(overlay, active and overlay.enabled)
	end
end

-- The shown button under the cursor, its top-left corner and its effective scale.
-- The cursor is tested against each button's rect: the buttons' IsMouseOver read
-- false in game even with the cursor on them.
local function GetHoveredButton(auras)
	local key = auras.groupKey
	if not key then return end

	local cursorX, cursorY = GetCursorPosition()
	for i = 1, auras:GetAuraGroupFrameCount(key) do
		local button = auras:GetAuraGroupFrame(key, i)
		if button and button:IsShown() then
			local left, bottom, width, height = button:GetRect()
			if left and not (issecretvalue(left) or issecretvalue(bottom) or issecretvalue(width) or issecretvalue(height)) then
				local scale = button:GetEffectiveScale()
				local x, y = cursorX / scale, cursorY / scale
				if x >= left and x < left + width and y >= bottom and y < bottom + height then
					return button, left, bottom + height, scale
				end
			end
		end
	end
end

-- The index (for filter) of the unit's first aura with this icon. With mineOnly,
-- the first one the player or their pet cast.
local function FindAuraIndex(unit, filter, icon, mineOnly)
	if not icon or issecretvalue(icon) then return end

	local index = 1
	local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
	while aura do
		if issecretvalue(aura.icon) then return end
		if aura.icon == icon and (not mineOnly or aura.isFromPlayerOrPlayerPet == true) then
			return index
		end
		index = index + 1
		aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
	end
end

-- Anchored to UIParent, not to the button: anything anchored to an aura container
-- or its buttons has to carry the container's layout aspect, and GameTooltip doesn't.
local function ShowTooltip(overlay, button, left, top, scale, unit, index)
	local tooltip = GameTooltip
	if overlay.tooltipButton ~= button or not tooltip:IsOwned(overlay) then
		tooltip:SetOwner(overlay, 'ANCHOR_NONE')
		tooltip:ClearAllPoints()
		local ratio = scale / tooltip:GetEffectiveScale()
		tooltip:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', left * ratio, top * ratio)
		overlay.tooltipButton = button
	end
	-- Again on every update, so the time left stays current.
	tooltip:SetUnitAura(unit, index, overlay.filter)
end

local function UpdateHover(overlay)
	if AurasSecret() then
		RefreshOverlays()
		return
	end

	local auras = overlay.auras
	local unit = auras.unitframe.unit
	local button, left, top, scale = GetHoveredButton(auras)
	local index = button and unit
		and FindAuraIndex(unit, overlay.filter, button.Icon:GetTexture(), auras.config.onlyShowPlayer)

	if index then
		ShowTooltip(overlay, button, left, top, scale, unit, index)
	else
		HideTooltip(overlay)
	end
end

local function OnUpdate(overlay, elapsed)
	overlay.elapsed = overlay.elapsed + elapsed
	if overlay.elapsed < THROTTLE then return end
	overlay.elapsed = 0

	-- An error here would repeat every update: report it once and stop until the
	-- cursor comes back.
	local ok, err = pcall(UpdateHover, overlay)
	if not ok then
		overlay:SetScript('OnUpdate', nil)
		HideTooltip(overlay)
		geterrorhandler()(err)
	end
end

local function OnEnter(overlay)
	overlay.elapsed = THROTTLE -- update straight away
	overlay:SetScript('OnUpdate', OnUpdate)
end

local function OnLeave(overlay)
	overlay:SetScript('OnUpdate', nil)
	HideTooltip(overlay)
end

-- Makes the overlay for an aura element (Constructor in auras.lua). filter is the
-- element's base filter ('HELPFUL' or 'HARMFUL'), which SetUnitAura's index counts in.
-- It starts off; UF:UpdateAuraTooltip turns it on.
function UF:AttachAuraTooltip(auras, filter)
	-- The template carries the container's layout aspect, which anything anchored to
	-- the container needs once it has an aura group (AddAuraGroup in
	-- Blizzard_CustomAuraContainer.lua).
	local overlay = CreateFrame('Frame', nil, auras, 'DisableUntrustedLayoutScriptsTemplate')
	overlay:SetAllPoints(auras)
	overlay:SetMouseClickEnabled(false)
	overlay:SetMouseMotionEnabled(false)
	overlay:SetScript('OnEnter', OnEnter)
	overlay:SetScript('OnLeave', OnLeave)
	overlay.auras = auras
	overlay.filter = filter
	overlay.elapsed = 0
	overlay.enabled = false

	auras.tooltipOverlay = overlay
	overlays[overlay] = true
end

-- Follows the element's config update (UpdateConfig in auras.lua): on while the
-- element is, above its buttons.
function UF:UpdateAuraTooltip(auras, enabled)
	local overlay = auras.tooltipOverlay
	if not overlay then return end

	overlay.enabled = enabled
	if enabled then
		overlay:SetFrameLevel(auras:GetFrameLevel() + 20)
	end
	SetOverlayActive(overlay, enabled and not AurasSecret())
end

-- Whether aura data is secret decides when the overlays are on, checked whenever it
-- may have changed. Off as combat starts, as the secret state can follow a moment
-- later; the hover update checks it again anyway.
local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_REGEN_DISABLED')
events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:RegisterEvent('PLAYER_ENTERING_WORLD')
if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid('ADDON_RESTRICTION_STATE_CHANGED') then
	events:RegisterEvent('ADDON_RESTRICTION_STATE_CHANGED')
end
events:SetScript('OnEvent', function(_, event)
	if event == 'PLAYER_REGEN_DISABLED' then
		RefreshOverlays(true)
		return
	end
	RefreshOverlays()
	-- The restriction can lift a frame after the event.
	C_Timer.After(0, function() RefreshOverlays() end)
end)
