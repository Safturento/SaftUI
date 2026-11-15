local st = SaftUI
local TR = st.Tracker

--[[
	The handover to Blizzard's tracker (design: "What the player sees: the
	handover" and "The handover's rules"). While a section SaftUI doesn't draw
	(probes.lua) has content, Blizzard's own tracker shows. The states:

	  own        SaftUI's tracker shows, Blizzard's is concealed;
	  blizzard   Blizzard's tracker in SaftUI's place, SaftUI's window and item
	             buttons hidden (the nearest item button stays, as its own frame);
	  both       Blizzard's tracker beside SaftUI's, SaftUI's shows.

	TR.Handover.Next is the design's table as a pure function; TR:UpdateHandover
	runs the actions it gives, through TR:PlaceBlizzard (blizzard.lua, the one
	function that moves Blizzard's tracker), the window (window.lua) and the item
	buttons (items.lua). The two states that hold SaftUI's tracker's parts away are
	derived from TR.handoverState (TR:ApplyWindowShown, items.lua's Wanted), so
	one that returns to own can never leave a part hidden.

	Combat: Blizzard's tracker isn't protected (no frame of its tracker is secure
	on either client: nothing in Blizzard_ObjectiveTracker's source on forever or
	live names a secure template, a roleset call or InCombatLockdown), so it is
	moved in combat by the three C methods like out of it. SaftUI's item buttons
	are secure: they are hidden only out of combat, and shown again only out of
	combat, so a need that starts in combat shows Blizzard's tracker beside, and
	one that ends in combat leaves it up while item buttons wait to be shown
	again. A tracker the game does count as protected (a system of Blizzard's Edit
	Mode snapped to it) waits for the end of combat in TR:PlaceBlizzard, with
	Blizzard's spot showing meanwhile.
]]

local Handover = {}
TR.Handover = Handover

-- Where each state puts Blizzard's tracker (TR:PlaceBlizzard's places).
local WHERE = { own = 'concealed', blizzard = 'place', both = 'beside' }

local NONE = {}

-- The design's table, as a function. state is 'own', 'blizzard' or 'both';
-- needed whether a section SaftUI doesn't draw has content; inCombat; mode
-- ('place' or 'beside', the setting); itemsToShow whether there are quest item
-- buttons to show again (TR:ItemsToShow). Returns the new state and the actions
-- to run, in order: 'hide_items', 'hide_window', 'reveal_place', 'reveal_beside',
-- 'conceal', 'show_window' and 'show_items'.
--
--   own      needed, In SaftUI's place, out of combat   -> blizzard (the buttons and
--                                                          the window away, then Blizzard's in place)
--   own      needed, In SaftUI's place, in combat       -> both (it can't hide secure buttons)
--   own      needed, Beside SaftUI's                    -> both
--   both     not needed                                 -> own (conceal)
--   both     needed, In SaftUI's place, out of combat   -> blizzard (combat ended)
--   blizzard not needed, out of combat                  -> own (conceal; the window, the buttons)
--   blizzard not needed, in combat, no buttons to show  -> own
--   blizzard not needed, in combat, buttons to show     -> stays: own when combat ends
function Handover.Next(state, needed, inCombat, mode, itemsToShow)
	if state == 'own' then
		if not needed then return 'own', NONE end
		if mode == 'beside' or inCombat then return 'both', { 'reveal_beside' } end
		return 'blizzard', { 'hide_items', 'hide_window', 'reveal_place' }
	elseif state == 'both' then
		if not needed then return 'own', { 'conceal' } end
		if mode == 'place' and not inCombat then
			return 'blizzard', { 'hide_items', 'hide_window', 'reveal_place' }
		end
		return 'both', NONE
	end
	-- blizzard
	if needed then return 'blizzard', NONE end
	if inCombat then
		if itemsToShow then return 'blizzard', NONE end
		return 'own', { 'conceal', 'show_window' }
	end
	if itemsToShow then return 'own', { 'conceal', 'show_window', 'show_items' } end
	return 'own', { 'conceal', 'show_window' }
end

-- What each action does. The state is already the new one when they run.
local ACTIONS = {
	hide_items = function(self) self:RefreshItems() end,
	-- The window's height as it is now is what Blizzard's tracker's spot is worked
	-- out from while it is hidden (TR:BlizzardTarget: with Grow up the holder's
	-- bottom and this height; the list behind it goes on changing height).
	hide_window = function(self)
		local height = self.window:GetHeight()
		self.heldHeight = (height ~= nil and not issecretvalue(height)) and height or nil
		self:ApplyWindowShown()
	end,
	reveal_place = function(self) self:PlaceBlizzard('place') end,
	reveal_beside = function(self) self:PlaceBlizzard('beside') end,
	conceal = function(self) self:PlaceBlizzard('concealed') end,
	show_window = function(self)
		self.heldHeight = nil
		self:ApplyWindowShown()
	end,
	show_items = function(self) self:RefreshItems() end,
}

local function Run(self, needed, combat, mode, items)
	local state, actions = Handover.Next(self.handoverState, needed, combat, mode, items)
	self.handoverState = state
	for _, action in ipairs(actions) do ACTIONS[action](self) end
end

-- Reads what the probes found and moves the trackers to match, and keeps
-- Blizzard's tracker where its state says (the holder, the window or the item
-- column may have moved or changed size since). Runs after each refresh and each
-- probe pass. A mode change (Ruling 28) goes back to own first (out of combat:
-- /sui is closed in combat), then runs the table again from own. Nothing runs
-- before the tracker is built or without Blizzard's tracker.
function TR:UpdateHandover()
	if not self.built or not self.blizzardFrame or not self.handoverState then return end
	local mode = self.config.blizzard.mode == 'beside' and 'beside' or 'place'
	local combat = InCombatLockdown() and true or false
	-- "Buttons to show" also holds Blizzard's tracker up while the game won't let it
	-- be put away in combat (a protected one: TR:PlaceBlizzard waits for the end),
	-- so SaftUI's window never comes back over it.
	local items = self:ItemsToShow() or (combat and not st:CanMoveNow(self.blizzardFrame))
	if self.handoverMode == nil then
		self.handoverMode = mode
	elseif self.handoverMode ~= mode then
		self.handoverMode = mode
		Run(self, false, combat, mode, items)
	end
	Run(self, #self:NeededSections() > 0, combat, mode, items)
	self:PlaceBlizzard(WHERE[self.handoverState])
end

-- The Blizzard's tracker tab's Now line: what the handover is doing.
function TR:HandoverText()
	local needed = self:NeededSections()
	if #needed == 0 then return 'Not needed now.' end
	local names = {}
	for index, key in ipairs(needed) do
		local section = TR.sectionByKey[key]
		names[index] = section and section.name or key
	end
	return ("Showing Blizzard's tracker for: %s."):format(table.concat(names, ', '))
end
