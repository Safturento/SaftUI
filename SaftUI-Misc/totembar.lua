local st = SaftUI
local TB = st:NewModule('TotemBar')

--[[
	/sui options to hide WoW Forever's totem bar, MultiCastActionBarFrame
	(Blizzard_ActionBar/Shared/MultiCastActionBarFrame.xml), and to size and space its
	buttons. Blizzard_ActionBar loads it only for the camelot, wrath and cata game types, so
	retail has no totem bar: nothing here runs there and the /sui section doesn't appear.

	What Blizzard does with the bar:
	  - Shows and hides it in TotemActionBarMixin:UpdateShownState, through the bar's
	    Edit Mode SetShown override. It's shown while a totem slot has spells
	    (numActiveSlots, counted on PLAYER_ENTERING_WORLD and UPDATE_MULTI_CAST_ACTIONBAR)
	    or Edit Mode's Totem Bar checkbox is on, and only while no vehicle or override bar
	    replaces the main action bar (the ActionBarController.MainActionBarStateOverridden
	    callback). That callback runs on every action bar page, bonus bar and vehicle
	    change, so Blizzard re-shows the bar often.
	  - Places it through Blizzard's Edit Mode. It isn't a managed frame. In its default
	    position it's the last of the bottom action bars (Camelot EditModeUtil's
	    GetBottomActionBars), and EditModeManagerFrame:UpdateBottomActionBarPositions
	    re-anchors it above the bars stacked on MainActionBar. That also runs in combat:
	    on each action bar's combat visibility update, when the pet, stance or possess
	    bar or the vehicle leave button shows or hides, and when the XP bars change.
	  - Its buttons are secure action buttons (ActionBarButtonTemplate, and
	    SecureFrameTemplate for the summon and recall buttons), so the bar is
	    protected. Addon code can't show, hide, reparent or move it in combat.

	Hiding parents the bar to a hidden SaftUI frame, out of combat. Blizzard keeps
	showing, hiding and placing the bar as before. Its show and hide calls only change
	the bar's own shown flag, and under a hidden parent the bar never becomes visible.
	So it never flashes, and its buttons' OnShow/OnHide scripts don't run. Nothing of
	Blizzard's reparents this bar (Blizzard's Edit Mode only reparents managed frames
	and the cast bar), so it stays under the hidden frame. Turning the option off puts
	the bar back under its old parent and leaves the shown flag alone. It shows again
	only if Blizzard wants it shown, e.g. not on a character with no totems.

	A state driver (RegisterStateDriver(bar, 'visibility', 'hide')) would have hidden it
	by calling the bar's Hide every 0.2s. After each of Blizzard's re-shows the bar would
	be on screen until the next tick. Turning the option off would also need a Show,
	which overrides Blizzard's own rules for when the bar shows.

	Position stays Blizzard's: the bar is moved in Blizzard's Edit Mode, after ticking
	Totem Bar in its settings. Once moved there, Blizzard's bottom bar layout leaves it
	where it was put. SaftUI can't own its position the way it owns the swing timer
	bars. In Blizzard's default position Blizzard re-anchors it in combat (see above),
	and a protected bar can't be put back until combat ends, so it would jump back to
	Blizzard's spot mid-fight.

	Nothing is written onto the bar or any Blizzard table. The only calls on the bar are
	GetParent, GetFrameLevel, SetParent, SetFrameLevel and SetSize (through st:SetSizeDirect),
	all plain widget methods (the bar's Edit Mode overrides are SetScale, SetPoint,
	ClearAllPoints, SetShown and Hide).

	The buttons' size and the gap between them are settings (button_size, button_spacing),
	laid out by TB:ApplyButtonLayout. Blizzard's XML makes every button 30px, puts the
	first one 3 in from the bar's bottom-left corner and the rest 3 or 8 apart, in a 230x38
	bar. SaftUI keeps that 3px margin and puts one gap between all neighbouring buttons:
	  - The summon button in the corner, then the element buttons, then the recall button
	    after the last element shown. Blizzard hides the summon button without a summon
	    spell, and the elements then start in the corner.
	  - Each element is a slot button with an action button on it per summon page
	    (totemskin.lua). Each page's four action buttons sit in a page frame. The pages go
	    where the first slot button goes, a row of buttons wide and a button tall, and
	    their buttons chain the same way, so every page lines up with the slot buttons.
	  - The bar is sized to hold the summon button, four elements and the recall button
	    (margin + buttons + gaps + margin), whichever show, as Blizzard's 230x38 holds
	    them all. That keeps Blizzard's Edit Mode outline (its Selection is set to the
	    bar's edges) and snapping on the buttons. It's only sized, never moved. Edit Mode
	    never sizes it. In its default position UpdateBottomActionBarPositions anchors
	    the bar's bottom-left corner above the bars stacked on MainActionBar, so a new size
	    doesn't move the buttons. The stack reads each bar's height for the next bar up,
	    and the totem bar is the last one. With Camelot's stacking from MainActionBar
	    (ACTION_BARS_RELATIVE_TO_BASE_POSITIONING) it doesn't read the bars' widths. A bar
	    moved in Edit Mode stays on the anchor point Edit Mode saved, which can be its
	    centre or right edge, so there a new size moves the buttons around that point, as
	    resizing any Edit Mode frame would.
	Blizzard re-anchors some of these in MultiCastActionBarFrame_Update, on
	PLAYER_ENTERING_WORLD, UPDATE_MULTI_CAST_ACTIONBAR and a summon page change, in combat
	too:
	  - MultiCastSummonSpellButton_Update puts the pages and the first slot button 8 after
	    the summon button, or in the corner while it's hidden.
	  - MultiCastRecallSpellButton_Update puts the recall button 8 after the last shown slot
	    button.
	Post-hooks on both put SaftUI's layout back. Everything it sizes and moves is
	protected: the summon, recall and action buttons are secure, the slot buttons are
	protected through the recall button's anchor (.agents/taint.md rule 6), and the pages
	and the bar hold secure buttons. So in combat the layout waits for the end of combat,
	and a fight that runs Blizzard's update (a summon page change does) shows Blizzard's 8
	after the summon button and before the recall button until it ends. The sizes and the
	gaps between elements stay SaftUI's, as Blizzard never sets them, and the pages move
	with the first slot button, so they still line up. SaftUI
	anchors these by the points Blizzard re-sets (BOTTOMLEFT for the pages and the first
	slot button, LEFT for the recall button), so Blizzard's SetPoint replaces SaftUI's
	anchor instead of adding a second one that would pull against it.

	SaftUI's look for the bar's buttons and its flyout is in totemskin.lua, and the totem
	timers above its element buttons are in totemtimers.lua. The flyout's choices follow the
	button size (totemskin.lua), and the timers follow the slot buttons' width.
]]

-- Puts the bar under the hidden frame, or back under the parent it had, as the
-- profile says. The bar is protected, so in combat this waits for the end of combat
-- and then reads the profile again.
function TB:Apply()
	local bar, hider = self.bar, self.hider
	if not bar then return end
	if st:QueueAfterCombat('totembar', function() self:Apply() end) then return end

	-- Only reparent when it doesn't change whether the bar is on screen. If it did,
	-- the secure buttons' OnHide/OnShow would run from SaftUI's call chain and can
	-- leave tainted state in Blizzard's shared action button code (an
	-- ADDON_ACTION_BLOCKED later, e.g. entering a vehicle in combat). At login the bar
	-- is still hidden, so a reload always applies the setting cleanly.
	if self.config.hide then
		if bar:GetParent() ~= hider then
			if bar:IsVisible() then
				st:Print('The totem bar will be hidden after a /reload.')
				return
			end
			self.oldParent, self.oldLevel = bar:GetParent(), bar:GetFrameLevel()
			bar:SetParent(hider)
		end
	elseif bar:GetParent() == hider then
		if bar:IsShown() then
			st:Print('The totem bar will show again after a /reload.')
			return
		end
		bar:SetParent(self.oldParent or UIParent)
		-- SetParent can renumber the bar's frame level, so put back the one it had.
		if self.oldLevel then bar:SetFrameLevel(self.oldLevel) end
	end
end

------------------------------------
--- Button layout -------------------
------------------------------------

-- Blizzard's margin between the bar's edges and its buttons: its XML puts the first
-- button 3 in from the bar's bottom-left corner.
local MARGIN = 3

-- Blizzard's button size, which the buttons have until SaftUI first lays them out.
local BLIZZARD_BUTTON_SIZE = 30

-- Blizzard's frames the layout sizes and places, collected once by TB:SetupButtonLayout:
-- { summon, recall, slots = { MultiCastSlotButton1-4 }, pages = { { frame, buttons } } },
-- a page being a MultiCastActionPage and its four MultiCastActionButtons. A SaftUI table,
-- so nothing is written onto Blizzard's frames. nil until the layout is set up.
local layout

-- The button size last laid out. The timers' text is centred from the slot buttons'
-- width, and the cooldown numbers' font depends on the size (totemskin.lua), so both are
-- refreshed when it changes.
local laidOutSize = BLIZZARD_BUTTON_SIZE

-- Sizes a row of buttons and anchors each one after the one before it, spacing apart,
-- LEFT to RIGHT as Blizzard chains them. The caller places the first one.
local function ChainRow(buttons, size, spacing)
	for i, button in ipairs(buttons) do
		button:SetSize(size, size)
		if i > 1 then
			button:ClearAllPoints()
			button:SetPoint('LEFT', buttons[i - 1], 'RIGHT', spacing, 0)
		end
	end
end

-- Lays the bar's buttons out from the profile (see the top of this file): their size,
-- one gap between neighbours, and the bar's size around them. Out of combat only, as all
-- of it is protected: in combat this waits for the end of combat, then reads the profile
-- and Blizzard's buttons again.
function TB:ApplyButtonLayout()
	local bar = self.bar
	if not (bar and layout) then return end
	if st:QueueAfterCombat('totembar_layout', function() self:ApplyButtonLayout() end) then return end

	local size, spacing = self.config.button_size, self.config.button_spacing
	local slots = layout.slots
	local numSlots = #slots

	st:SetSizeDirect(bar,
		2 * MARGIN + (numSlots + 2) * size + (numSlots + 1) * spacing,
		2 * MARGIN + size)

	local summon = layout.summon
	summon:SetSize(size, size)
	summon:ClearAllPoints()
	summon:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', MARGIN, MARGIN)

	-- The elements start after the summon button, or in its place while Blizzard hides it.
	local x = summon:IsShown() and MARGIN + size + spacing or MARGIN

	ChainRow(slots, size, spacing)
	slots[1]:ClearAllPoints()
	slots[1]:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', x, MARGIN)

	-- Blizzard anchors each page's first button by its LEFT, so with the page a button
	-- tall the row's bottom is the page's.
	for _, page in ipairs(layout.pages) do
		local frame, buttons = page.frame, page.buttons
		frame:SetSize(numSlots * size + (numSlots - 1) * spacing, size)
		frame:ClearAllPoints()
		frame:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', x, MARGIN)
		ChainRow(buttons, size, spacing)
		buttons[1]:ClearAllPoints()
		buttons[1]:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	end

	-- After the last element shown, as Blizzard does: it shows the first
	-- numActiveSlots slot buttons and hides the rest. With none shown, Blizzard hides the
	-- recall button too, and it goes after the first slot button.
	local last = slots[1]
	for _, slot in ipairs(slots) do
		if slot:IsShown() then last = slot end
	end
	local recall = layout.recall
	recall:SetSize(size, size)
	recall:ClearAllPoints()
	recall:SetPoint('LEFT', last, 'RIGHT', spacing, 0)

	if size ~= laidOutSize then
		laidOutSize = size
		self:ApplySkin()
		self:ApplyTimerLayout()
	end
end

-- Collects the frames the layout places, hooks Blizzard's updates that re-anchor them,
-- and lays them out. Once, out of combat, as the layout sizes and moves protected frames:
-- after a /reload in combat the buttons keep Blizzard's layout until the end of combat. Not
-- set up if any of Blizzard's frames is missing.
function TB:SetupButtonLayout()
	if layout then return end
	if st:QueueAfterCombat('totembar_layout_setup', function() self:SetupButtonLayout() end) then return end

	local perPage = NUM_MULTI_CAST_BUTTONS_PER_PAGE or 4
	local frames = {
		summon = _G.MultiCastSummonSpellButton,
		recall = _G.MultiCastRecallSpellButton,
		slots = {},
		pages = {},
	}
	if not (frames.summon and frames.recall) then return end
	for i = 1, perPage do
		local slot = _G['MultiCastSlotButton' .. i]
		if not slot then return end
		frames.slots[i] = slot
	end
	for p = 1, NUM_MULTI_CAST_PAGES or 3 do
		local page = { frame = _G['MultiCastActionPage' .. p], buttons = {} }
		if not page.frame then return end
		for i = 1, perPage do
			local button = _G['MultiCastActionButton' .. ((p - 1) * perPage + i)]
			if not button then return end
			page.buttons[i] = button
		end
		frames.pages[p] = page
	end
	layout = frames

	local function Reapply() self:ApplyButtonLayout() end
	TB.PostHook('MultiCastSummonSpellButton_Update', Reapply)
	TB.PostHook('MultiCastRecallSpellButton_Update', Reapply)

	self:ApplyButtonLayout()
end

-- A profile change.
function TB:UpdateConfig()
	self:Apply()
	self:ApplyButtonLayout()
	self:ApplySkin()
	self:ApplyTimerLayout()
end

function TB:Setup()
	if self.bar then return end
	local bar = _G.MultiCastActionBarFrame
	if not bar then return end
	self.bar = bar

	-- Never shown. While the bar is under it, it's protected too, and nothing moves it.
	self.hider = CreateFrame('Frame', nil, UIParent)
	self.hider:Hide()

	-- Blizzard first counts the totem slots on PLAYER_ENTERING_WORLD, so at login the
	-- bar is still hidden here and reparenting it runs none of its scripts.
	self:Apply()

	self:SetupSkinAndTimers()
	self:SetupButtonLayout()
end

-- The timers above the element buttons (totemtimers.lua) and SaftUI's look for the
-- bar's buttons and its flyout (totemskin.lua). The timers are SaftUI's own frames,
-- anchored to the slot buttons but never moving them, so they're made straight away,
-- in combat too: a /reload mid-fight still shows how long the totems have left. The
-- skin anchors regions of the secure buttons, so after a /reload in combat it waits
-- for the end of combat. The two sets of hooks touch separate things, so their order
-- doesn't matter.
function TB:SetupSkinAndTimers()
	self:SetupTimers()
	if st:QueueAfterCombat('totembar_setup', function() self:SetupSkin() end) then return end
	self:SetupSkin()
end

function TB:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_ActionBar' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

function TB:OnEnable()
	st:BindModuleConfig(self, 'totembar')
	if _G.MultiCastActionBarFrame then
		self:Setup()
	elseif st.forever then
		self:RegisterEvent('ADDON_LOADED')
	end
end

-- The Totem Bar section in the /sui tree. Absent until the bar exists, so never shown
-- on retail. The bar has no SaftUI mover (see the top of this file), so the section
-- says where to move it instead.
function TB:GetConfigTable()
	if not self.bar then return end

	local hide = st.Config.generators.toggle(1, 'Hide totem bar', 'full')
	hide.desc = "Hides Blizzard's totem bar. Turning this off shows it again whenever Blizzard would show it. If the bar is on screen when you change this, it applies after a /reload."

	-- The bar's buttons (TB:ApplyButtonLayout). /sui doesn't open in combat, so these
	-- always apply straight away.
	local buttonSize = st.Config.generators.range(2, 'Button size', 20, 60, 1)
	buttonSize.desc = "Every button on the bar, its border included. The totem choices that open above a button are 6 smaller, so the flyout is as wide as the button. Blizzard's are 30."
	local buttonSpacing = st.Config.generators.range(3, 'Spacing', 0, 20, 1)
	buttonSpacing.desc = 'The gap between buttons.'

	-- The totem timers above the element buttons (totemtimers.lua).
	local timerBar = st.Config.generators.toggle(4, 'Show timer bar', 'full')
	timerBar.desc = "A bar above each element button that drains, in the element's colour, as that element's totem runs out. It turns red in the last 10 seconds."
	local timerText = st.Config.generators.toggle(5, 'Show timer text', 'full')
	timerText.desc = "How long each element's totem has left, above its button. It turns red in the last 10 seconds."

	-- Text alone sits just above the button either way, so this only matters with both on.
	local timerTextPosition = {
		order = 6,
		name = 'Text position',
		desc = 'Where the time goes while both the bar and the text show: above a thin bar, or on a taller one.',
		type = 'select',
		values = { above = 'Above the bar', on = 'On the bar' },
		sorting = { 'above', 'on' },
		disabled = function() return not (self.config.timer_bar and self.config.timer_text) end,
	}

	local timerBarHeight = st.Config.generators.range(7, 'Timer bar height', 2, 20, 1)
	timerBarHeight.desc = "The timer bar's height, its border included. With the text on the bar, it's never shorter than the text needs."
	timerBarHeight.disabled = function() return not self.config.timer_bar end

	return {
		name = 'Totem Bar',
		type = 'group',
		get = function(info) return self.config[info[#info]] end,
		set = function(info, value)
			local key = info[#info]
			self.config[key] = value
			if key == 'hide' then
				self:Apply()
			elseif key == 'button_size' or key == 'button_spacing' then
				self:ApplyButtonLayout()
			else
				self:ApplyTimerLayout()
			end
		end,
		args = {
			hide = hide,
			button_size = buttonSize,
			button_spacing = buttonSpacing,
			timer_bar = timerBar,
			timer_text = timerText,
			timer_text_position = timerTextPosition,
			timer_bar_height = timerBarHeight,
			move_note = {
				order = 8,
				type = 'description',
				name = ("To move the totem bar, open Blizzard's Edit Mode, tick %s in its settings and drag the bar. "
					.. "SaftUI doesn't move it: Blizzard re-places the bar during combat, and because its buttons "
					.. "are secure, SaftUI couldn't put it back until combat ends."):format(_G.HUD_EDIT_MODE_TOTEM_ACTION_BAR_LABEL or 'Totem Bar'),
			},
		},
	}
end
