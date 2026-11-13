local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	Keybinds. Each SaftUI button takes the keys of its Blizzard counterpart's
	binding command (AB:GetBindingCommand; init.lua has the table): ACTIONBUTTON1-12
	for bar 1, MULTIACTIONBAR1BUTTON1-12 for bar 2, and so on. The binds stay
	Blizzard's. The user's saved keys, Blizzard's Key Bindings menu and SaftUI's
	hover binding all read and write those commands. SaftUI only lays override
	bindings over them while it's loaded. Override bindings aren't saved, and
	SaftUI never binds a key to anything but a Blizzard command, so disabling
	SaftUI-ActionBars and reloading gives every key back to Blizzard's bars.

	AB:UpdateBindings goes through every bar in AB.bars, the pet bar
	(BONUSACTIONBUTTON1-10) and the stance bar (SHAPESHIFTBUTTON1-10) too:
	  - Each key of a button's command (GetBindingKey, the saved binds) clicks the
	    button: SetOverrideBindingClick with the 'Keybind' mouse button, as
	    Bartender4 binds. LibActionButton's OnClick wrap takes a 'Keybind' click
	    as a key press, not a pickup click, so a bind with the pickup modifier
	    (Shift by default) still casts on key down. A flyout action opens
	    LibActionButton's flyout from the SaftUI button. The pet and stance
	    buttons (buttons.lua) do what a left click does.
	  - The keys of a disabled bar, of a bar that isn't available (the stance
	    bar of a class without forms) and of the buttons a bar doesn't show click
	    SaftUI_ActionBarNoop, a button that does nothing. Released instead, they'd
	    go back to Blizzard's commands, which click Blizzard's hidden buttons.
	    The pet bar's keys stay on its buttons without a pet, as a pet can come
	    in combat, when binds can't change; its buttons do nothing then.
	  - In a pet battle, bar 1's keys are released. Blizzard's ACTIONBUTTON
	    commands drive the pet battle's abilities (ActionButtonDown ->
	    CheckPetActionButtonEvent -> PetBattleFrame_ButtonDown), and bar 1 hides.
	    They come back when it ends. PET_BATTLE_OPENING_START and PET_BATTLE_CLOSE
	    are the events Blizzard's ActionBarController follows.
	It clears SaftUI's overrides (ClearOverrideBindings on one SaftUI frame) and
	sets them again, only when the result differs from what's applied, so its
	own changes can't loop back through UPDATE_BINDINGS.

	It runs:
	  - when the bars are built
	  - on UPDATE_BINDINGS, when any bind changes (Blizzard's menu, hover binding,
	    a binding set loaded)
	  - from AB:UpdateBar, when a bar is turned on or off, a profile switches or
	    the class's forms change (stancebar.lua)
	  - on the pet battle events
	Binding calls are blocked in combat, so in combat it waits for the end of
	combat. Until then a newly bound key does what it does in Blizzard's UI.

	Hotkey text: each button's LibActionButton keyBoundTarget is its command
	(skin.lua). LibActionButton shows that command's key and refreshes it on
	UPDATE_BINDINGS, and skin.lua shortens it.
	Hover binding (/sui kb, or Keybind mode in /sui) is keybindmode.lua's.
]]

-- Bars whose keys go back to Blizzard's commands in a pet battle.
local PET_BATTLE_BARS = { bar1 = true }

-- The frame that owns SaftUI's override bindings.
local owner = CreateFrame('Frame')

-- The click target of keys that should do nothing. It has no scripts.
local NOOP = 'SaftUI_ActionBarNoop'
CreateFrame('Button', NOOP, UIParent):Hide()

local applied     -- the override bindings set now, as one string
local inPetBattle -- nil until the first update reads it

local function SortedBarIds(bars)
	local ids = {}
	for id in pairs(bars) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

-- Every override binding SaftUI should have now, as a list of { key, button
-- name }, and the same as one string to compare.
local function WantedBindings(self)
	local bindings, parts = {}, {}
	for _, id in ipairs(SortedBarIds(self.bars)) do
		if not (inPetBattle and PET_BATTLE_BARS[id]) then
			local bar = self.bars[id]
			local config = self.config[id]
			local numShown = (config and config.enable and self:IsBarAvailable(id)) and self:GetNumButtons(id) or 0
			for i, button in ipairs(bar.buttons) do
				local command = self:GetBindingCommand(id, i)
				local target = i <= numShown and button:GetName() or NOOP
				if command then
					for _, key in ipairs({ GetBindingKey(command) }) do
						if key ~= '' then
							bindings[#bindings + 1] = { key, target }
							parts[#parts + 1] = key .. '=' .. target
						end
					end
				end
			end
		end
	end
	return bindings, table.concat(parts, '\n')
end

-- Points every key of the bars' Blizzard commands at SaftUI's buttons (see the
-- top of this file). In combat this waits for the end of combat.
function AB:UpdateBindings()
	if not self.built then return end
	if st:QueueAfterCombat('actionbars_bindings', function() self:UpdateBindings() end) then return end

	if inPetBattle == nil then
		inPetBattle = C_PetBattles.IsInBattle() and true or false
	end

	local bindings, signature = WantedBindings(self)
	if signature == applied then return end

	ClearOverrideBindings(owner)
	for _, binding in ipairs(bindings) do
		local key, target = binding[1], binding[2]
		if target == NOOP then
			SetOverrideBindingClick(owner, false, key, NOOP)
		else
			SetOverrideBindingClick(owner, false, key, target, 'Keybind')
		end
	end
	applied = signature
end

function AB:PET_BATTLE_OPENING_START()
	inPetBattle = true
	self:UpdateBindings()
end

-- The battle is over. Kept from the events rather than read from
-- C_PetBattles.IsInBattle(), which may not have caught up when this fires.
function AB:PET_BATTLE_CLOSE()
	inPetBattle = false
	self:UpdateBindings()
end

------------------------------------
--- Setup ---------------------------
------------------------------------

-- Once, when the bars are built (AB:Build).
function AB:SetupBindings()
	self:RegisterEvent('UPDATE_BINDINGS', 'UpdateBindings')
	self:RegisterEvent('PET_BATTLE_OPENING_START')
	self:RegisterEvent('PET_BATTLE_CLOSE')

	-- Edit mode's movers cover the bars, so the two modes don't run together.
	st.EditModeFrames:On('Enabled', function() self:StopKeybindMode() end)

	-- Blizzard's Quick Keybind Mode only reaches Blizzard's hidden buttons, so
	-- when it opens, point to SaftUI's. A post-hook that only prints
	-- (.agents/taint.md rule 2). Blizzard_QuickKeybind isn't load on demand,
	-- so its frame exists by now.
	if QuickKeybindFrame then
		QuickKeybindFrame:HookScript('OnShow', function()
			st:Print("SaftUI's action bars bind by hovering in /sui kb.")
		end)
	end

	self:UpdateBindings()
end
