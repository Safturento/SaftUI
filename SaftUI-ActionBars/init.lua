local st = SaftUI
local AB = st:NewModule('ActionBars')
st.ActionBars = AB

--[[
	SaftUI's own action bars, built on LibActionButton-1.0, in place of Blizzard's.

	  - init.lua: the module, the bars it owns and their Blizzard counterparts.
	  - hideblizzard.lua: takes Blizzard's bars off screen at load.
	  - skin.lua: SaftUI's look for the action buttons.
	  - bars.lua: building, laying out and updating the bars.
	  - buttons.lua: SaftUI's own secure buttons, for the pet and stance bars.
	  - petbar.lua and stancebar.lua: the pet bar and the stance bar.
	  - bindings.lua: the bars' keys, from Blizzard's binding commands, and
	    hover binding (/sui kb).
	  - extras.lua: the extra action button, the zone ability and the leave
	    vehicle button, on holders of SaftUI's.
	  - options.lua: the /sui section and the edit mode movers.

	Each bar mirrors one Blizzard bar: the same action slots and the same binding
	command. These were checked against Blizzard_ActionBar on the forever and live
	branches (MainActionBar.xml, MultiActionBars.xml, PetActionBar.xml,
	StanceBar.xml: commandNamePrefix and the actionpage attribute of each bar; a
	slot is (page - 1) * 12 + button; Bindings_Standard.xml for the pet and
	stance commands).

	  bar     Blizzard frame        page  slots         binding command
	  bar1    MainActionBar         1*    1-12          ACTIONBUTTON1-12 (*paged, bars.lua)
	  bar2    MultiBarBottomLeft    6     61-72         MULTIACTIONBAR1BUTTON1-12
	  bar3    MultiBarBottomRight   5     49-60         MULTIACTIONBAR2BUTTON1-12
	  bar4    MultiBarRight         3     25-36         MULTIACTIONBAR3BUTTON1-12
	  bar5    MultiBarLeft          4     37-48         MULTIACTIONBAR4BUTTON1-12
	  bar6    MultiBar5             13    145-156       MULTIACTIONBAR5BUTTON1-12
	  bar7    MultiBar6             14    157-168       MULTIACTIONBAR6BUTTON1-12
	  bar8    MultiBar7             15    169-180       MULTIACTIONBAR7BUTTON1-12
	  pet     PetActionBar          -     pet 1-10      BONUSACTIONBUTTON1-10
	  stance  StanceBar             -     forms 1-10    SHAPESHIFTBUTTON1-10

	Forever has all of them. Bars 1-8 are LibActionButton buttons (bars.lua).
	The pet and stance bars are SaftUI's own secure buttons (buttons.lua), as
	LibActionButton has no pet or stance button: AB.barTypes holds what's
	different about them.
]]

AB.BAR_IDS = { 'bar1', 'bar2', 'bar3', 'bar4', 'bar5', 'bar6', 'bar7', 'bar8', 'pet', 'stance' }

-- The buttons of an action bar (bars 1-8), and of an action bar page.
AB.NUM_BUTTONS = 12

-- The Blizzard action bar page each bar shows. bar1's is its unpaged page.
AB.BAR_PAGES = {
	bar1 = 1,
	bar2 = 6,
	bar3 = 5,
	bar4 = 3,
	bar5 = 4,
	bar6 = 13,
	bar7 = 14,
	bar8 = 15,
}

-- Blizzard's binding command for each bar is this prefix plus the button index.
AB.BINDING_PREFIXES = {
	bar1 = 'ACTIONBUTTON',
	bar2 = 'MULTIACTIONBAR1BUTTON',
	bar3 = 'MULTIACTIONBAR2BUTTON',
	bar4 = 'MULTIACTIONBAR3BUTTON',
	bar5 = 'MULTIACTIONBAR4BUTTON',
	bar6 = 'MULTIACTIONBAR5BUTTON',
	bar7 = 'MULTIACTIONBAR6BUTTON',
	bar8 = 'MULTIACTIONBAR7BUTTON',
	pet = 'BONUSACTIONBUTTON',
	stance = 'SHAPESHIFTBUTTON',
}

-- Each bar's name in /sui and on its edit mode outline.
AB.BAR_LABELS = {
	bar1 = 'Bar 1',
	bar2 = 'Bar 2',
	bar3 = 'Bar 3',
	bar4 = 'Bar 4',
	bar5 = 'Bar 5',
	bar6 = 'Bar 6',
	bar7 = 'Bar 7',
	bar8 = 'Bar 8',
	pet = 'Pet bar',
	stance = 'Stance bar',
}

-- Each bar's frame name. Bars 1-8 are SaftUI_ActionBar1..8.
AB.BAR_FRAME_NAMES = {
	pet = 'SaftUI_PetBar',
	stance = 'SaftUI_StanceBar',
}

--[[
	The bars whose buttons aren't LibActionButton's, keyed by bar id. petbar.lua
	and stancebar.lua fill it in at file load. Each entry has:
	  - CreateButtons(bar): makes bar.buttons, once, out of combat (AB:CreateBar).
	  - UpdateActions(bar): sets the buttons' secure attributes from the game,
	    out of combat (AB:UpdateBar).
	  - GetNumSlots(): optional, how many buttons the bar has something for now.
	    The bar shows at most that many (AB:GetNumButtons). All of them if unset.
	  - IsAvailable(): optional. While false the bar is hidden and its keys do
	    nothing, whatever its settings (a class without forms has no stance bar).
	  - unavailableLabel: its edit mode outline's second line while unavailable.
	  - buttonsNote: optional, added to its Buttons option's description.
	  - texts: the text settings its buttons use, as a set ({ hotkey = true }),
	    for /sui (options.lua). All of them if unset.
]]
AB.barTypes = {}

AB.bars = {}
AB.movers = {}

-- The Blizzard binding command whose keys button i of bar id takes, e.g.
-- ('bar2', 3) -> 'MULTIACTIONBAR1BUTTON3'. nil for an unknown bar.
function AB:GetBindingCommand(id, i)
	local prefix = self.BINDING_PREFIXES[id]
	return prefix and (prefix .. i) or nil
end

-- The action slot of button i on Blizzard action bar page page.
function AB:GetActionSlot(page, i)
	return (page - 1) * self.NUM_BUTTONS + i
end

-- Bar id's frame name: 'bar3' -> 'SaftUI_ActionBar3', 'pet' -> 'SaftUI_PetBar'.
-- Its buttons are this name plus 'Button' and their index.
function AB:GetBarFrameName(id)
	return self.BAR_FRAME_NAMES[id] or ('SaftUI_ActionBar' .. id:gsub('^bar', ''))
end

function AB:OnEnable()
	st:BindModuleConfig(self, 'actionbars')

	-- Secure frames can't be set up in combat. The UI loads before combat lockdown
	-- applies, also on a /reload in combat (the unit frames' headers rely on it
	-- too), so this is only a fallback: the bars are built when combat ends.
	if InCombatLockdown() then
		st:Print('The action bars will appear when combat ends.')
		st:QueueAfterCombat('actionbars_build', function() self:Build() end)
		return
	end
	self:Build()
end

-- Makes every bar, then lays them all out, maps their keys and gives each an
-- edit mode mover. Bars are anchored to each other by name, so every frame
-- exists before any is placed. One bar failing (e.g. a profile whose anchors
-- form a loop) doesn't stop the others, and a bar left without anchors goes
-- to the middle of the screen, where its mover can reach it. Then the extra
-- buttons, which sit on bar 3 by default (extras.lua); an error there doesn't
-- stop the keys being mapped. Once.
function AB:Build()
	if self.built then return end
	self.built = true

	for _, id in ipairs(self.BAR_IDS) do
		self:CreateBar(id)
	end
	for _, id in ipairs(self.BAR_IDS) do
		xpcall(function() self:UpdateBar(id) end, geterrorhandler())
		st:RestorePoints(self.bars[id])
	end
	for _, id in ipairs(self.BAR_IDS) do
		self:RegisterBarMover(id)
	end
	xpcall(function() self:SetupExtras() end, geterrorhandler())
	self:SetupBindings()
end

-- A profile change. Every bar is re-laid out, re-skinned and shown or hidden for
-- the new profile, then the extra buttons are placed and sized. All of it is
-- protected, so in combat it waits for the end of combat and reads the profile
-- then.
function AB:UpdateConfig()
	if not self.built then return end
	if st:QueueAfterCombat('actionbars', function() self:UpdateConfig() end) then return end

	-- The new profile may chain the bars the other way round (bar 1 on bar 2
	-- instead of bar 2 on bar 1). Clear every bar's anchors before any is placed,
	-- so no order passes through an anchor loop, and give any bar left without
	-- anchors its old ones back. On a profile switch out of combat, edit mode has
	-- cleared them already (EM:ClearPositions) and restores them itself
	-- (EM:UpdateConfig), so there's nothing saved here to restore.
	local saved = {}
	for _, bar in pairs(self.bars) do
		saved[bar] = st:GetPoints(bar)
		bar:ClearAllPoints()
	end
	for _, id in ipairs(self.BAR_IDS) do
		if self.bars[id] then
			xpcall(function() self:UpdateBar(id) end, geterrorhandler())
		end
	end
	for bar, points in pairs(saved) do
		if #points > 0 then
			st:RestorePoints(bar, points)
		end
	end
	self:UpdateExtras()
end
