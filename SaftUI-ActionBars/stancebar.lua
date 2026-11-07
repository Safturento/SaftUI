local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	The stance bar, in place of Blizzard's StanceBar: SaftUI_StanceBar, holding
	ten of SaftUI's secure buttons (buttons.lua), SaftUI_StanceBarButton1..10,
	one per shapeshift form slot (stances, forms, auras, presences, stealth:
	whatever the class has there). Blizzard_ActionBar StanceBar.lua and .xml,
	forever and live, which differ only in a gamepad check in ShouldShow.

	  - A click, or a key bound to SHAPESHIFTBUTTON<n> (bindings.lua), casts the
	    form's spell: the secure template's 'spell' type, with the spell ID from
	    GetShapeshiftFormInfo, so CastSpellByID (SecureTemplates.lua): the same
	    as casting the form's spell from an action bar. Blizzard's own button
	    and binding call CastShapeshiftForm(slot) instead, which is protected
	    and has no secure template type. A slot without a spell ID (or a secret
	    one) has no type and does nothing. If a form turns out not to cast this
	    way, casting by name won't help (it's the same spell-cast path); build
	    the buttons from Blizzard's StanceButtonTemplate instead, as Bartender4
	    and ElvUI do.
	  - The attributes are protected, so they're set out of combat: when the
	    bar is built, and whenever the forms change (UPDATE_SHAPESHIFT_FORMS,
	    SPELLS_CHANGED for new ranks), through AB:UpdateBar, which also lays the
	    bar out again. A form learned in combat shows when combat ends.
	  - The bar shows one button per form, up to its Buttons setting
	    (GetNumSlots), and is hidden while the class has no forms (IsAvailable),
	    with its keys doing nothing. Like Blizzard's, it also hides in pet
	    battles, vehicles, override bars and while possessing
	    (AB.HIDE_CONDITIONS.stance; StanceBarMixin:ShouldShow and
	    ActionBarBusy).
	  - Drawn on the stance events (StanceBar.lua and ActionBarController.lua):
	    icon, checked while active, dimmed while it can't be cast, cooldown.
	    Only drawing, so in combat too.
]]

-- Blizzard's stance bar has ten buttons (StanceBar.xml numButtons), and there
-- are ten commands, SHAPESHIFTBUTTON1-10.
local NUM_SLOTS = 10

AB.HIDE_CONDITIONS.stance = '[petbattle][vehicleui][overridebar][possessbar]'

local IsSet = AB.IsSet

local bar          -- AB.bars.stance, once made
local numForms = 0 -- the last known number of forms
local applied      -- Signature() of the spells the buttons cast now

-- How many forms the class has, at most NUM_SLOTS. A secret count keeps the
-- last one known.
local function NumForms()
	local count = GetNumShapeshiftForms()
	if not issecretvalue(count) then
		numForms = math.min(count or 0, NUM_SLOTS)
	end
	return numForms
end

-- The spell of form i, or nil when there's no form there or its spell is secret.
local function FormSpell(i)
	if i > NumForms() then return end
	local spellID = select(4, GetShapeshiftFormInfo(i))
	if issecretvalue(spellID) then return end
	return spellID
end

-- The forms as one string, to tell when the buttons' spells are out of date.
local function Signature()
	local parts = { NumForms() }
	for i = 1, NUM_SLOTS do
		parts[#parts + 1] = tostring(FormSpell(i))
	end
	return table.concat(parts, ',')
end

------------------------------------
--- Buttons ------------------------
------------------------------------

local StanceButton = {}

function StanceButton:Refresh()
	local i = self.index
	local texture, isActive, isCastable
	if i <= NumForms() then
		texture, isActive, isCastable = GetShapeshiftFormInfo(i)
	end
	self.hasAction = issecretvalue(texture) or texture ~= nil
	self.icon:SetTexture(texture)
	self.icon:SetShown(self.hasAction)
	self:SetChecked(IsSet(isActive))
	self:SetTint(IsSet(isCastable), false)
	if self.hasAction then
		self:SetCooldownTimes(GetShapeshiftFormCooldown(i))
	else
		self.cooldown:Clear()
	end
	self:UpdateGrid()
end

function StanceButton:SetTooltip()
	if not self.hasAction then return false end
	GameTooltip:SetShapeshift(self.index)
	return true
end

local function RefreshAll()
	for _, button in ipairs(bar.buttons) do
		button:Refresh()
	end
end

-- Each button casts its form's spell. Out of combat only (AB:UpdateBar).
local function UpdateActions()
	for i, button in ipairs(bar.buttons) do
		local spellID = FormSpell(i)
		if button:GetAttribute('spell') ~= spellID then
			button:SetAttribute('type', spellID and 'spell' or nil)
			button:SetAttribute('spell', spellID)
		end
	end
	applied = Signature()
end

------------------------------------
--- Events -------------------------
------------------------------------

-- The events that can change which forms there are. The others only redraw.
local FORMS_EVENTS = {
	UPDATE_SHAPESHIFT_FORMS = true,
	PLAYER_ENTERING_WORLD = true,
	SPELLS_CHANGED = true,
}
local DRAW_EVENTS = {
	UPDATE_SHAPESHIFT_FORM = true,
	UPDATE_SHAPESHIFT_USABLE = true,
	UPDATE_SHAPESHIFT_COOLDOWN = true,
}

-- New or changed forms re-lay the bar out, set its spells, show or hide it and
-- move its keys, after combat if need be (AB:UpdateBar). The buttons redraw
-- now either way.
local function OnEvent(_, event)
	if FORMS_EVENTS[event] and Signature() ~= applied then
		AB:UpdateBar('stance')
	end
	RefreshAll()
end

------------------------------------
--- The bar ------------------------
------------------------------------

-- Once, out of combat (AB:CreateBar).
local function CreateButtons(header)
	bar = header
	for i = 1, NUM_SLOTS do
		bar.buttons[i] = AB:CreateSecureButton(bar, i, StanceButton)
	end

	local events = CreateFrame('Frame')
	for event in pairs(FORMS_EVENTS) do
		events:RegisterEvent(event)
	end
	for event in pairs(DRAW_EVENTS) do
		events:RegisterEvent(event)
	end
	events:SetScript('OnEvent', OnEvent)
end

AB.barTypes.stance = {
	CreateButtons = CreateButtons,
	UpdateActions = UpdateActions,
	GetNumSlots = NumForms,
	IsAvailable = function() return NumForms() > 0 end,
	unavailableLabel = 'no forms',
	buttonsNote = 'It shows one button per form, so no more than the class has.',
	texts = { hotkey = true },
}
