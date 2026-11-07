local st = SaftUI
local AB = st:NewModule('ActionBars')
st.ActionBars = AB

--[[
	SaftUI's own action bars, built on LibActionButton-1.0, in place of Blizzard's.

	  - init.lua: the module, the bars it owns and their Blizzard counterparts.
	  - hideblizzard.lua: takes Blizzard's bars off screen at load.
	  - skin.lua: SaftUI's look for the LibActionButton buttons.
	  - bars.lua: building, laying out and updating the bars.

	Each bar mirrors one Blizzard bar: the same action slots and the same binding
	command. These were checked against Blizzard_ActionBar on the forever and live
	branches (MainActionBar.xml, MultiActionBars.xml: commandNamePrefix and the
	actionpage attribute of each bar; a slot is (page - 1) * 12 + button).

	  bar   Blizzard frame        page  slots    binding command
	  bar1  MainActionBar         1*    1-12     ACTIONBUTTON1-12 (*paged, bars.lua)
	  bar2  MultiBarBottomLeft    6     61-72    MULTIACTIONBAR1BUTTON1-12
	  bar3  MultiBarBottomRight   5     49-60    MULTIACTIONBAR2BUTTON1-12
	  bar4  MultiBarRight         3     25-36    MULTIACTIONBAR3BUTTON1-12
	  bar5  MultiBarLeft          4     37-48    MULTIACTIONBAR4BUTTON1-12
	  bar6  MultiBar5             13    145-156  MULTIACTIONBAR5BUTTON1-12
	  bar7  MultiBar6             14    157-168  MULTIACTIONBAR6BUTTON1-12
	  bar8  MultiBar7             15    169-180  MULTIACTIONBAR7BUTTON1-12

	Forever has all eight. The pet and stance bars (BONUSACTIONBUTTON1-10,
	SHAPESHIFTBUTTON1-10) come later; their commands are listed here already.
]]

AB.BAR_IDS = { 'bar1', 'bar2', 'bar3', 'bar4', 'bar5', 'bar6', 'bar7', 'bar8' }
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

AB.bars = {}

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

-- The number in a bar's frame name: 'bar3' -> '3'. Other ids are used as they are.
function AB:GetFrameSuffix(id)
	return (id:gsub('^bar', ''))
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

-- Makes every bar, then lays them all out. Bars are anchored to each other by
-- name, so every frame exists before any is placed. Once.
function AB:Build()
	if self.built then return end
	self.built = true

	for _, id in ipairs(self.BAR_IDS) do
		self:CreateBar(id)
	end
	for _, id in ipairs(self.BAR_IDS) do
		self:UpdateBar(id)
	end
end

-- A profile change. Every bar is re-laid out, re-skinned and shown or hidden for
-- the new profile. All of it is protected, so in combat it waits for the end of
-- combat and reads the profile then.
function AB:UpdateConfig()
	if not self.built then return end
	if st:QueueAfterCombat('actionbars', function() self:UpdateConfig() end) then return end

	-- The new profile may chain the bars the other way round (bar 1 on bar 2
	-- instead of bar 2 on bar 1). Clear every bar's anchors before any is placed,
	-- so no order passes through an anchor loop, and give any bar left without
	-- anchors its old ones back.
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
		st:RestorePoints(bar, points)
	end
end
