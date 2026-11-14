-- A seeded random walk over the bag window and the combined bank, in every
-- view: open and close, loot arriving, items leaving, view switches, setting
-- changes (Items per row, Max columns, Empty slots, icon size, a font), search
-- text, and combat starting and ending (with the update queued for its end).
-- After every step: every shown item button is inside its section or category
-- frame, no two shown frames overlap, every frame is inside the scroll frame and
-- that inside the window, no item button is moved or made in combat, no Lua
-- error, and out of combat every section frame's slotLine is the window's line
-- and the window is a whole width. Settings change out of combat only, as /sui
-- closes in combat. The seeds are fixed; the first three are ones that broke
-- earlier code (a Compact window opened in combat after Items per row changed
-- while it was closed; a section frame sized by a line its slots were not
-- anchored at).
local H = load_test_file('bags/container_helpers.lua')

local SEEDS = { 243, 260, 179, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
local STEPS = 70
local EPS = 0.01
local COVER = { combatLayouts = 0, combatDisagree = 0, lineQueued = 0, combatOpens = 0, combatLoots = 0, steps = 0, catchups = 0 }

local function rng(seed)
	local state = seed % 2147483646 + 1
	return function(n)
		state = state * 16807 % 2147483647
		return state % n + 1
	end
end

local CLASSES = { 'Consumable', 'Weapon', 'Trade Goods', 'Armor', 'Quest', 'Miscellaneous', 'Recipe', 'Gem' }
local VIEWS = { 'onebag', 'multibag', 'compact', 'rows' }
local QUERIES = { '', 'item 1', 'zzz', 'a' }

local function rect(r) return r:GetLeft(), r:GetRight(), r:GetTop(), r:GetBottom() end

local function run_walk(seed)
	local roll = rng(seed)
	local INV, W = H.views_world('forever')
	SaftUI.RegisterConfigMover = SaftUI.RegisterConfigMover or function() end
	local log, failures = {}, {}
	local combatMoves, madeInCombat = 0, 0
	local origLayout = INV.LayoutSections
	INV.LayoutSections = function(self, container, sections)
		if stub.in_combat then
			COVER.combatLayouts = COVER.combatLayouts + 1
			for _, section in ipairs(sections) do
				local f = container.categories[self:SectionFrameName(section)]
				if f and f.slotLine and container.sectionLine and f.slotLine ~= container.sectionLine then COVER.combatDisagree = COVER.combatDisagree + 1; break end
			end
		end
		return origLayout(self, container, sections)
	end
	local origQueue = SaftUI.QueueAfterCombat
	SaftUI.QueueAfterCombat = function(self, key, fn)
		local queued = origQueue(self, key, fn)
		if queued and key == 'InventoryLine' then COVER.lineQueued = COVER.lineQueued + 1 end
		return queued
	end
	local origCreate = INV.CreateSlot
	INV.CreateSlot = function(self, container, name)
		local slot = origCreate(self, container, name)
		if stub.in_combat then madeInCombat = madeInCombat + 1 end
		for _, m in ipairs({ 'SetPoint', 'ClearAllPoints' }) do
			local o = slot[m]
			slot[m] = function(...)
				if stub.in_combat then combatMoves = combatMoves + 1 end
				return o(...)
			end
		end
		return slot
	end

	-- Currencies, as views_layout_test.lua gives them.
	C_CurrencyInfo.RequestCurrencyDataForAccountCharacters = function() end
	local numCurrencies = roll(8) - 1
	C_CurrencyInfo.GetCurrencyListSize = function() return numCurrencies end
	C_CurrencyInfo.GetCurrencyListInfo = function(i) return { name = 'Coin ' .. i, quantity = i, iconFileID = i, isHeader = false } end
	C_CurrencyInfo.GetCurrencyListLink = function(i) return 'currency:' .. i end
	C_CurrencyInfo.GetCurrencyIDFromLink = function(link) return tonumber(link:match('%d+')) end
	C_CurrencyInfo.GetBasicCurrencyInfo = function() return { quality = 1 } end

	local tab1, tab2 = INV.bagIds.combinedbank[1], INV.bagIds.combinedbank[2]
	W.bag(0, 20, 'Backpack')
	W.bag(1, 16, 'Bottomless Bag of the Endlessly Wandering Desert Nomad')
	W.bag(2, 12, 'Herb Pouch', 32)
	W.bag(tab1, 28, 'Bank')
	W.bag(tab2, 16, 'Bank bag')
	local bagsOf = { bag = { 0, 1, 2 }, combinedbank = { tab1, tab2 } }
	local nextId = 1000
	local function loot(id, n)
		for _ = 1, n do
			local bags = bagsOf[id]
			local bagID = bags[roll(#bags)]
			local bag = W.bags[bagID]
			local free = {}
			for s = 1, bag.slots do if not bag.items[s] then free[#free + 1] = s end end
			if #free > 0 then
				nextId = nextId + 1
				local class = CLASSES[roll(#CLASSES)]
				W.put(bagID, free[roll(#free)], W.item(nextId, 'Item ' .. nextId, class, roll(90)))
			end
		end
	end
	local function remove(id, n)
		for _ = 1, n do
			local filled = {}
			for _, bagID in ipairs(bagsOf[id]) do
				for s, item in pairs(W.bags[bagID].items) do if item then filled[#filled + 1] = { bagID, s } end end
			end
			if #filled > 0 then
				local pick = filled[roll(#filled)]
				W.bags[pick[1]].items[pick[2]] = nil
			end
		end
	end
	loot('bag', roll(20))
	loot('combinedbank', roll(30))

	INV.config.stackItems = false
	INV.config.bag.view = VIEWS[roll(4)]
	INV.config.combinedbank.view = VIEWS[roll(4)]
	local bag = H.window('bag')
	local search = H.search(bag)
	local bank = H.window('combinedbank')
	for _, c in ipairs({ bag, bank }) do
		c:HookScript('OnHide', function() INV:ReleaseLayout(c) end)
	end
	bank:Hide()
	INV:UpdateContainer('bag', true)

	local function tick()
		INV.NEED_UPDATE = false
		local layout = INV.UPDATE_LAYOUT
		INV.UPDATE_LAYOUT = false
		INV:EnsureSlotPools()
		for id, c in pairs(INV.containers) do
			if c:IsShown() then INV:UpdateContainer(id, layout) end
		end
		INV:UpdateSearchFilter(search, false)
	end
	local function update() INV:QueueUpdate(true); tick() end

	local function fail(step, msg)
		if #failures < 12 then failures[#failures + 1] = ('seed %d step %d (%s%s): %s'):format(seed, step, log[#log] or '?', stub.in_combat and ', in combat' or '', msg) end
	end

	local function check_window(step, c)
		local id = c.id
		local view = INV:GetLaidOutView(c)
		local sl, sr, st_, sb = rect(c.scrollFrame)
		local wl, wr = c:GetLeft(), c:GetRight()
		if sl < wl - EPS or sr > wr + EPS then fail(step, id .. ': scroll frame outside the window') end
		local frames = {}
		for name, f in pairs(c.categories) do
			if f:IsShown() and (view ~= 'compact' or name ~= 'Currencies' or true) then
				local fl, fr, ft, fb = rect(f)
				if fl and ft then
					frames[#frames + 1] = { name = name, l = fl, r = fr, t = ft, b = fb }
					if fl < sl - EPS or fr > sr + EPS then
						fail(step, ('%s %s: section %s outside the scroll frame (%s..%s in %s..%s)'):format(id, view, name, fl, fr, sl, sr))
					end
					local slots = {}
					for _, s in ipairs(f.slots) do if s:IsShown() then slots[#slots + 1] = s end end
					if f.slotPool and name == 'Currencies' then
						for s in f.slotPool:EnumerateActive() do if s:IsShown() then slots[#slots + 1] = s end end
					end
					for _, s in ipairs(slots) do
						local l, r, t, b = rect(s)
						if l < fl - EPS or r > fr + EPS or t > ft + EPS or b < fb - EPS then
							fail(step, ('%s %s: a slot of %s outside it (slot %s..%s %s..%s, frame %s..%s %s..%s, slotLine %s, line %s)'):format(
								id, view, name, l, r, t, b, fl, fr, ft, fb, tostring(f.slotLine), tostring(c.sectionLine)))
							break
						end
					end
					if not stub.in_combat and view ~= 'compact' and c.sectionLine and f.slotLine and name ~= 'Currencies'
							and f.slotLine ~= c.sectionLine then
						fail(step, ('%s %s: out of combat %s has slotLine %s, the line is %s'):format(id, view, name, f.slotLine, c.sectionLine))
					end
				end
			end
		end
		for i = 1, #frames do
			for j = i + 1, #frames do
				local a, b = frames[i], frames[j]
				local w = math.min(a.r, b.r) - math.max(a.l, b.l)
				local h = math.min(a.t, b.t) - math.max(a.b, b.b)
				if w > EPS and h > EPS then
					fail(step, ('%s %s: sections %s and %s overlap by %sx%s'):format(id, view, a.name, b.name, w, h))
				end
			end
		end
		if not stub.in_combat and c:GetWidth() % 1 ~= 0 then fail(step, id .. ': a window width off a whole pixel: ' .. c:GetWidth()) end
	end

	local function check(step)
		for _, e in ipairs(take_errors()) do fail(step, 'error: ' .. tostring(e)) end
		if combatMoves > 0 then fail(step, combatMoves .. ' SetPoint/ClearAllPoints on item buttons in combat'); combatMoves = 0 end
		if madeInCombat > 0 then fail(step, madeInCombat .. ' item buttons made in combat'); madeInCombat = 0 end
		for _, c in ipairs({ bag, bank }) do
			if c:IsShown() then check_window(step, c) end
		end
	end

	local actions = {
		function() log[#log + 1] = 'open bags'; if stub.in_combat and not bag:IsShown() then COVER.combatOpens = COVER.combatOpens + 1 end; bag:Show(); update() end,
		function() log[#log + 1] = 'close bags'; bag:Hide(); bank:Hide() end,
		function() log[#log + 1] = 'open bank'; bank:Show(); bag:Show(); update() end,
		function() log[#log + 1] = 'close bank'; bank:Hide(); bag:Hide() end,
		function() local n = roll(8); log[#log + 1] = 'loot ' .. n .. ' into bags'; if stub.in_combat then COVER.combatLoots = COVER.combatLoots + 1 end; loot('bag', n); update() end,
		function() local n = roll(8); log[#log + 1] = 'loot ' .. n .. ' into bank'; loot('combinedbank', n); update() end,
		function() local n = roll(5); log[#log + 1] = 'remove ' .. n .. ' from bags'; remove('bag', n); update() end,
		function() local n = roll(5); log[#log + 1] = 'remove ' .. n .. ' from bank'; remove('combinedbank', n); update() end,
		function()
			local id = roll(2) == 1 and 'bag' or 'combinedbank'
			local v = VIEWS[roll(4)]
			log[#log + 1] = 'view ' .. id .. ' ' .. v
			INV.config[id].view = v
			INV:UpdateViewButtons(id)
			INV:ApplyView(id)
		end,
		function()
			local id = roll(2) == 1 and 'bag' or 'combinedbank'
			local which = roll(5)
			-- /sui closes in combat and won't open: settings change out of combat only.
			if stub.in_combat then log[#log + 1] = 'setting skipped (combat)'; return end
			if which == 1 then INV.config[id].perrow = roll(5) + 1
			elseif which == 2 then INV.config[id].maxColumns = roll(5)
			elseif which == 3 then INV.config[id].emptySlots = ({ 'off', 'grouped', 'all' })[roll(3)]
			elseif which == 4 then INV.config.iconsize = ({ 40, 50, 37 })[roll(3)]
			else INV.config.fonts.titles = INV.config.fonts.titles end
			log[#log + 1] = ('setting %s #%d (perrow %d, maxColumns %d, empty %s, icon %s)'):format(id, which, INV.config[id].perrow,
				INV.config[id].maxColumns, tostring(INV.config[id].emptySlots), tostring(INV.config.iconsize))
			INV:UpdateConfig()
			INV:SyncAnchorSize(id)
			tick()
		end,
		function() local q = QUERIES[roll(#QUERIES)]; log[#log + 1] = 'search "' .. q .. '"'; search:SetText(q); INV:UpdateSearchFilter(search) end,
		function() log[#log + 1] = 'combat starts'; stub.in_combat = true; stub.fire_event('PLAYER_REGEN_DISABLED') end,
		function()
			log[#log + 1] = 'combat ends'
			stub.in_combat = false
			stub.fire_event('PLAYER_REGEN_ENABLED')
			if INV.NEED_UPDATE then COVER.catchups = COVER.catchups + 1; tick() end
		end,
		function() log[#log + 1] = 'tick'; update() end,
	}

	stub.in_combat = false
	check(0)
	for step = 1, STEPS do
		local a = roll(#actions)
		-- Combat a little more often, so long fights happen.
		if roll(6) == 1 then a = stub.in_combat and 13 or 12 end
		actions[a]()
		COVER.steps = COVER.steps + 1
		check(step)
	end
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	return failures
end

for _, seed in ipairs(SEEDS) do
	test('walk seed ' .. seed, function()
		local failures = run_walk(seed)
		for i = 1, math.min(4, #failures) do print(failures[i]) end
		eq(#failures, 0, 'seed ' .. seed .. ' kept the invariant')
	end)
end

test('the walk reaches combat layouts, queued catch-ups and opens in combat', function()
	check(COVER.combatLayouts > 0, 'layouts in combat')
	check(COVER.lineQueued > 0, 'a layout queued for the end of combat')
	check(COVER.combatOpens > 0, 'a window opened in combat')
	check(COVER.combatLoots > 0, 'loot arriving in combat')
end)
