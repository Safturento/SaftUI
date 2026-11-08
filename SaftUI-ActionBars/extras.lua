local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	The extra action button, the zone ability and the leave vehicle button. Each
	sits on a holder of SaftUI's, sized and placed from the profile, which is its
	edit mode mover and has a /sui section (options.lua). The holders always have
	a size, so their outlines show while the buttons don't.

	Extra action button and zone ability. They stay Blizzard's own buttons, with
	Blizzard's look, and Blizzard decides when they show. How Blizzard places
	them, the same on forever and live (Blizzard_UIPanels_Game/Shared/
	ExtraAbilityContainer.lua and .xml, Blizzard_ActionBar/Shared/
	ExtraActionBar.lua and .xml, Blizzard_ZoneAbility/ZoneAbility.lua and .xml,
	Blizzard_ManagedFrameSystem/Shared/ManagedFrameSystem.lua):
	  - ExtraActionBarFrame (256x128, holding the secure ExtraActionButton1, 52px)
	    and ZoneAbilityFrame (256x128, holding the Style art and
	    SpellButtonContainer, a row of 52px buttons whose own OnClick casts the
	    zone spell) are put into ExtraAbilityContainer while they have something
	    to show. AddFrame reparents and shows them, RemoveFrame hides them.
	  - The container is a HorizontalLayoutFrame. When it shows, and the frame
	    after one is added or removed, it lays them out side by side with
	    ClearAllPoints and SetPoint, in combat too: a boss's extra action button
	    usually turns up mid-fight.
	  - The container is Blizzard's Edit Mode "Extra Abilities" system. In its
	    default position it's a managed frame: each time it shows,
	    BottomManagedFrameContainer reparents it to itself and stacks it above
	    Blizzard's bottom bars (ManagedFrameContainerMixin:UpdateFrame). Moved in
	    Blizzard's Edit Mode, it's anchored from the saved layout instead.
	Post-hooks on SetPoint can't keep these frames on SaftUI's holders: the
	extra action frame holds a secure button, so it can't be moved in combat,
	and Blizzard lays it out again each time the button appears. So SaftUI moves
	none of Blizzard's frames. It anchors what Blizzard never re-anchors to the
	holders, out of combat:
	  - ExtraActionButton1 to the extra holder's centre. Its art (button.style)
	    is one of its own regions, so it comes along.
	  - ZoneAbilityFrame.SpellButtonContainer to the zone holder's centre, and
	    the zone art (ZoneAbilityFrame.Style) to the buttons' centre, where
	    Blizzard's layout has it too.
	Those anchors hold whatever the container and Blizzard's Edit Mode do, so the
	buttons show at SaftUI's spot even when they first appear in combat, with no
	SaftUI code running then. They're still the children of Blizzard's frames, so
	they show, hide and fade in exactly when Blizzard's would. Blizzard's own
	frames stay in Blizzard's layout, empty and invisible. ExtraActionBarFrame,
	the only one that takes the mouse, is made click-through, so it can't catch
	clicks meant for SaftUI's bars under it (AB:DisableMouse, hideblizzard.lua).
	The container's Edit Mode box is kept hidden (AB:HideEditModeSelection). Its
	Edit Mode system has no settings but its position, which the holders take
	over.
	  - Size: a Scale setting, the widgets' own SetScale on ExtraActionButton1
	    and on ZoneAbilityFrame, so each button scales with its art. Scale, not
	    size: their art and masks are fixed-size textures laid out around a
	    52px button. The holder is one 52px button at that scale. Several zone
	    buttons (some zones give a set) spread out either side of its centre,
	    as they do in Blizzard's frame.
	  - The extra action button is secure, and anchoring it to its holder makes
	    the holder protected: the holder and the button's scale change out of
	    combat only (st:SafeReposition). The zone buttons aren't secure, so the
	    zone holder moves any time.
	  - Keys: EXTRAACTIONBUTTON1 (retail) is Blizzard's binding, which clicks
	    ExtraActionButton1 wherever it is. Nothing here changes it.
	  - Forever has no extra action bar: its ActionButtonUtil.
	    IsExtraActionButtonDisabled (Blizzard_ActionBar/Camelot) says so, and
	    its bindings have no EXTRAACTIONBUTTON1. Its frames exist though, so the
	    holder and outline do too.

	Leave vehicle button. Blizzard's (MainMenuBarVehicleLeaveButton) and its
	possess bar (PossessActionBar) are off screen (hideblizzard.lua), so SaftUI
	has its own button for both: SaftUI_VehicleLeaveButton, made from
	ActionButtonTemplate and SecureActionButtonTemplate and skinned like SaftUI's
	other buttons (skin.lua), in the secure header SaftUI_VehicleLeave, which is
	its holder. It does what Blizzard's leave button does
	(Blizzard_ActionBar/Shared/VehicleLeaveButton.lua) and what the possess
	bar's cancel slot does (Blizzard_ActionBar/Shared/PossessActionBar.lua),
	both the same on forever and live:
	  - A click on a flight path requests an early landing
	    (TaxiRequestEarlyLanding while UnitOnTaxi('player')), and leaves the
	    vehicle otherwise (VehicleExit). Neither is protected, so the button's
	    PostClick calls them, in combat too; Blizzard's button calls them from
	    a plain OnClick as well. It stays checked once a landing is asked for,
	    as Blizzard's button locks its highlight.
	  - While possessing (a mind control, a quest that has you control a
	    creature) with no vehicle to leave, a click cancels the possess.
	    Blizzard's only way to do that is the possess bar's cancel slot,
	    PossessButton2 (POSSESS_CANCEL_SLOT). Its OnClick
	    (PossessButtonMixin:OnClick) requests an early landing on a flight
	    path, leaves a vehicle the player controls, and otherwise calls
	    CancelPetPossess. Blizzard makes
	    that button a SecureFrameTemplate one, as it does the stance and pet
	    buttons whose OnClicks call protected functions, and not its two leave
	    buttons. So CancelPetPossess is taken to be protected (its C side isn't
	    in the source), and SaftUI's button clicks Blizzard's instead of calling
	    it: the secure template's 'click' type (SECURE_ACTIONS.click,
	    Blizzard_FrameXML/SecureTemplates.lua) clicks PossessButton2 from
	    secure code. That runs Blizzard's own OnClick, in Blizzard's order, in
	    combat too, and nothing of SaftUI's runs in it. The possess bar is
	    blocked, but ActionBarController still keeps it current
	    (PossessActionBar:Update on UPDATE_POSSESS_BAR), which enables the
	    cancel button. The header's snippet sets the 'click' type only while
	    possessing; otherwise the type is empty and the secure template does
	    nothing.
	  - It shows while CanExitVehicle(), which is true on a flight path too, or
	    while possessing. Blizzard also hides its leave button while an
	    override bar is up, as that bar has a leave button of its own. SaftUI
	    hides Blizzard's override bar (hideblizzard.lua), so SaftUI's button
	    shows then too.
	  - In combat only a state driver can show and hide it and set its type.
	    [canexitvehicle] doesn't turn true on a flight path, so the driver's
	    token changes on [canexitvehicle], on [possessbar] and on [mounted] (a
	    flight path mounts you), and the header's snippet shows it while
	    CanExitVehicle() or possessing. [canexitvehicle] comes first, so a
	    vehicle you can leave keeps the leave click even while possessing.
	    Out of combat, Blizzard's leave button events, the possess bar's event
	    and a flight starting or ending (PLAYER_CONTROL_LOST/GAINED) apply the
	    same rules from Lua: that catches a flight taken while already
	    mounted, when the token doesn't change.
	  - It's a secure button, so Enable and Disable are protected on it in
	    combat. A landing request disables it out of combat only (a flight
	    path can't be taken in combat). It's enabled again each time the
	    header shows or hides: by Lua out of combat, by the snippet in combat.
	  - Size: SaftUI's own button, so a Size setting, as on the bars.
]]

AB.EXTRA_IDS = { 'extra', 'zone', 'vehicleleave' }

-- Each one's name in /sui and on its edit mode outline.
AB.EXTRA_LABELS = {
	extra = 'Extra action button',
	zone = 'Zone ability',
	vehicleleave = 'Leave vehicle button',
}

-- id -> its holder, the frame its edit mode mover moves. Only the ones the
-- client has Blizzard's frames for. The leave vehicle button's is its header.
AB.extras = {}

-- Blizzard's extra action and zone ability buttons at scale 1
-- (ExtraActionButtonTemplate, ZoneAbilityFrameSpellButtonTemplate).
local BLIZZARD_SIZE = 52

-- The leave art of Blizzard's button, cropped to the inside of its round frame.
local LEAVE_TEXTURE = [[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]]
local LEAVE_CROP_MIN, LEAVE_CROP_MAX = 0.22, 0.78

-- The leave vehicle button has no hotkey, stack count or macro name, but
-- skin.lua lays those out from a bar's text settings. These keep them hidden.
local NO_TEXT = { show = false, size = 10, point = 'CENTER', rel_point = 'CENTER', x_off = 0, y_off = 0 }
local LEAVE_TEXT = { hotkey = NO_TEXT, count = NO_TEXT, macro = NO_TEXT }

-- The header's state driver: its token changes as you get into or out of a
-- vehicle you can leave, as you start or stop possessing, and as you mount or
-- dismount (a flight path). Lua reads the same token out of combat
-- (SecureCmdOptionParse), so both apply one rule.
local LEAVE_DRIVER = '[canexitvehicle] vehicle; [possessbar] possess; [mounted] mounted; none'

-- The leave button's secure type while possessing: click Blizzard's possess
-- cancel button (see the top of this file).
local POSSESS_TYPE = 'click'

-- Restricted code: self is the header, newstate the driver's token, and the
-- 'button' frame ref the leave button. CanExitVehicle is in the restricted
-- environment (Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua),
-- and the handles' SetAttribute, Enable, Show and Hide are in
-- RestrictedFrames.lua next to it, all the same on forever and live.
local LEAVE_SNIPPET = [[
	local button = self:GetFrameRef('button')
	local possess = newstate == 'possess'
	if possess then
		button:SetAttribute('type', 'click')
	else
		button:SetAttribute('type', nil)
	end

	local show = (CanExitVehicle() or possess) and true or false
	-- Each ride starts clickable. The header's OnShow and OnHide hooks uncheck
	-- the button, but Lua can't enable a secure button in combat.
	if show ~= (self:IsShown() and true or false) then
		button:Enable()
	end
	if show then
		self:Show()
	else
		self:Hide()
	end
]]

-- Blizzard's leave button's events (VehicleLeaveButton.lua), its possess bar's
-- (ActionBarController.lua), and a flight path starting and ending.
local LEAVE_EVENTS = {
	'UNIT_ENTERED_VEHICLE',
	'UNIT_EXITED_VEHICLE',
	'VEHICLE_UPDATE',
	'UPDATE_BONUS_ACTIONBAR',
	'UPDATE_MULTI_CAST_ACTIONBAR',
	'UPDATE_POSSESS_BAR',
	'PLAYER_CONTROL_LOST',
	'PLAYER_CONTROL_GAINED',
	-- Changes during combat waited for this.
	'PLAYER_REGEN_ENABLED',
}

local leaveButton -- SaftUI_VehicleLeaveButton, once made

-- The widget's own SetScale, so no Lua replacement on a Blizzard frame runs.
local function SetScaleDirect(frame, scale)
	getmetatable(frame).__index.SetScale(frame, scale)
end

local function Clamp(value, low, high, default)
	return math.min(math.max(tonumber(value) or default, low), high)
end

------------------------------------
--- Layout --------------------------
------------------------------------

--[[
	How each one is sized, what's anchored to its holder, and where the holder
	goes. What's on the holder is anchored first, so it follows the holder even
	if placing the holder fails (a profile's anchor loop), when it's given its
	old place or the middle of the screen (st:RestorePoints, edit mode). Every
	change runs it again, and it makes nothing.
]]
local layouts = {}

function layouts.extra(self, holder, config)
	local button = _G.ExtraActionButton1
	local scale = Clamp(config.scale, 0.5, 2, 1)
	SetScaleDirect(button, scale)
	st:ClearAllPointsDirect(button)
	st:SetPointDirect(button, 'CENTER', holder, 'CENTER')

	local size = st:RoundToPixel(BLIZZARD_SIZE * scale, holder)
	self:PlaceFrame(holder, size, size, config.position)
end

function layouts.zone(self, holder, config)
	local zone = _G.ZoneAbilityFrame
	local buttons = zone.SpellButtonContainer
	local scale = Clamp(config.scale, 0.5, 2, 1)
	SetScaleDirect(zone, scale)
	st:ClearAllPointsDirect(buttons)
	st:SetPointDirect(buttons, 'CENTER', holder, 'CENTER')
	if zone.Style then
		st:ClearAllPointsDirect(zone.Style)
		st:SetPointDirect(zone.Style, 'CENTER', buttons, 'CENTER')
	end

	local size = st:RoundToPixel(BLIZZARD_SIZE * scale, holder)
	self:PlaceFrame(holder, size, size, config.position)
end

-- The button is square, from the header's top left: AB:PlaceFrame can make a
-- centred header a pixel longer, as it does a bar.
function layouts.vehicleleave(self, header, config)
	local size = st:RoundToPixel(Clamp(config.size, 16, 80, 30), header)
	leaveButton:ClearAllPoints()
	leaveButton:SetSize(size, size)
	leaveButton:SetPoint('TOPLEFT', header, 'TOPLEFT')
	self:StyleButton(leaveButton, { size = size, text = LEAVE_TEXT }, self.config.template)
	-- After the style, which crops icons for spell art.
	leaveButton.icon:SetTexCoord(LEAVE_CROP_MIN, LEAVE_CROP_MAX, LEAVE_CROP_MIN, LEAVE_CROP_MAX)

	self:PlaceFrame(header, size, size, config.position)
end

-- Sizes and places extra id from the profile. In combat, while its holder can't
-- move (the extra action button's holder and the leave vehicle header are
-- protected), this waits for the end of combat and reads the profile then.
function AB:LayoutExtra(id)
	local holder = self.extras[id]
	if not holder then return end
	st:SafeReposition(holder, 'actionbars_extra_' .. id, function()
		layouts[id](self, holder, self.config[id])
	end)
end

-- Every one, from the profile (AB:UpdateConfig). One failing doesn't stop the others.
function AB:UpdateExtras()
	for _, id in ipairs(self.EXTRA_IDS) do
		if self.extras[id] then
			xpcall(function() self:LayoutExtra(id) end, geterrorhandler())
		end
	end
end

------------------------------------
--- Leave vehicle button ------------
------------------------------------

-- True while a click goes to Blizzard's possess cancel button.
local function IsCancellingPossess(button)
	return button:GetAttribute('type') == POSSESS_TYPE
end

-- After the secure template's click (PostClick): it did nothing unless
-- possessing. A CheckButton checks itself on every click, so the check is set
-- here each time.
local function LeaveOnClick(button)
	if IsCancellingPossess(button) then
		-- Blizzard's possess cancel button did it all.
		button:SetChecked(false)
	elseif UnitOnTaxi('player') then
		TaxiRequestEarlyLanding()
		-- Show that the request went through, as Blizzard's button does.
		-- SetChecked isn't protected. Disable is, on a secure button in combat,
		-- and a flight path can't be taken in combat.
		button:SetChecked(true)
		if not InCombatLockdown() then
			button:Disable()
		end
	else
		VehicleExit()
		button:SetChecked(false)
	end
end

-- Blizzard's tooltips for its leave button and possess cancel button, where
-- SaftUI's buttons put theirs.
local function LeaveOnEnter(button)
	if GameTooltip:IsForbidden() then return end
	AB:AnchorTooltip(button)
	if UnitOnTaxi('player') then
		GameTooltip:SetText(TAXI_CANCEL, 1, 1, 1)
		GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
	elseif IsCancellingPossess(button) then
		GameTooltip:SetText(CANCEL, 1, 1, 1)
	else
		GameTooltip:SetText(LEAVE_VEHICLE, 1, 1, 1)
	end
	GameTooltip:Show()
end

local function LeaveOnLeave(button)
	AB:HideTooltip(button)
end

-- The header and its button, shown and hidden as the top of this file says.
-- Once, out of combat. Its size and place come from AB:LayoutExtra.
local function CreateLeaveButton(self)
	local header = CreateFrame('Frame', 'SaftUI_VehicleLeave', UIParent, 'SecureHandlerStateTemplate')

	local button = CreateFrame('CheckButton', 'SaftUI_VehicleLeaveButton', header,
		'ActionButtonTemplate, SecureActionButtonTemplate')
	-- A left click, as on Blizzard's buttons. The secure template acts on the
	-- release, the click it gets, whatever Blizzard's "cast on key down"
	-- setting says (SecureActionButton_ShouldUseOnKeyDown).
	button:RegisterForClicks('LeftButtonUp')
	button:SetAttribute('useOnKeyDown', false)
	-- What the 'click' type clicks while possessing. The type itself is set by
	-- the header's snippet.
	local possessCancel = _G['PossessButton' .. (POSSESS_CANCEL_SLOT or 2)]
	if possessCancel then
		button:SetAttribute('clickbutton', possessCancel)
	end
	button:SetScript('PostClick', LeaveOnClick)
	button:SetScript('OnEnter', LeaveOnEnter)
	button:SetScript('OnLeave', LeaveOnLeave)
	-- The template's flyout handlers; this button has no flyout.
	button:SetScript('OnAttributeChanged', nil)
	button:SetScript('OnDragStart', nil)
	button.icon:SetTexture(LEAVE_TEXTURE)
	self:SkinButton(button)
	leaveButton = button

	-- Each ride starts unchecked. The header is SaftUI's own frame. Enable is
	-- protected on the secure button in combat; the snippet enables it then.
	local function Uncheck()
		button:SetChecked(false)
		if not InCombatLockdown() then
			button:Enable()
		end
	end
	header:HookScript('OnShow', Uncheck)
	header:HookScript('OnHide', Uncheck)

	-- The snippet and its frame ref first: registering the driver sets the
	-- state straight away.
	header:SetFrameRef('button', button)
	header:SetAttribute('_onstate-exit', LEAVE_SNIPPET)
	RegisterStateDriver(header, 'exit', LEAVE_DRIVER)

	-- The snippet's rules, from Lua. Setting attributes on a secure frame and
	-- showing it from Lua are protected, so only out of combat.
	local events = CreateFrame('Frame')
	for _, event in ipairs(LEAVE_EVENTS) do
		events:RegisterEvent(event)
	end
	events:SetScript('OnEvent', function()
		if InCombatLockdown() then return end
		local possess = SecureCmdOptionParse(LEAVE_DRIVER) == 'possess'
		button:SetAttribute('type', possess and POSSESS_TYPE or nil)
		header:SetShown((CanExitVehicle() or possess) and true or false)
	end)

	return header
end

------------------------------------
--- Setup ---------------------------
------------------------------------

-- Once, when the bars are built (AB:Build), out of combat. Makes the holders and
-- the leave vehicle button, puts Blizzard's buttons on their holders, lays each
-- one out and gives it an edit mode mover. The extra action button and the zone
-- ability are only set up if the client has their Blizzard frames. A holder
-- left without anchors goes to the middle of the screen, where its mover can
-- reach it.
function AB:SetupExtras()
	if self.extrasSetUp then return end
	self.extrasSetUp = true

	local extraBar = _G.ExtraActionBarFrame
	if extraBar and _G.ExtraActionButton1 then
		self.extras.extra = CreateFrame('Frame', 'SaftUI_ExtraActionHolder', UIParent)
		-- Its empty frame stays in Blizzard's layout, over SaftUI's bars.
		self:DisableMouse(extraBar)
	end

	local zone = _G.ZoneAbilityFrame
	if zone and zone.SpellButtonContainer then
		self.extras.zone = CreateFrame('Frame', 'SaftUI_ZoneAbilityHolder', UIParent)
	end

	-- Blizzard's Edit Mode box for the container, which shows nothing now.
	self:HideEditModeSelection(_G.ExtraAbilityContainer)

	self.extras.vehicleleave = CreateLeaveButton(self)

	for _, id in ipairs(self.EXTRA_IDS) do
		local holder = self.extras[id]
		if holder then
			xpcall(function() self:LayoutExtra(id) end, geterrorhandler())
			st:RestorePoints(holder)
			self:RegisterExtraMover(id)
		end
	end
end
