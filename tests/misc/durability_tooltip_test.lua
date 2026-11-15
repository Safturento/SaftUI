-- The durability figure's tooltip (SaftUI-Misc/durability.lua's page toggle and
-- durabilitytooltip.lua). Under Blizzard's own lines (its OnEnter: the title
-- "Repair Armor" and one line), while the figure owns GameTooltip:
--   - one line per equipped slot with durability below 100%, the item's name in
--     its quality color on the left and its percent on the right, green from 50%,
--     orange from 20%, red under that (the Colors page's text colors), lowest
--     first, a slot at 100% and a slot with no durability left out;
--   - a last line, Repair cost, with the sum of every equipped item's repair
--     cost as the game's coin string;
--   - nothing at all when every slot is at 100%, when an API is missing, or for
--     a value that is a secret (never compared or added; the slot or the sum
--     left out);
--   - no change to the tooltip when something else owns it, when the setting is
--     off, and nothing hooked on GameTooltip or written onto Blizzard's frames.
-- On both clients (one shape; both have C_TooltipInfo.GetInventoryItem and
-- GetMoneyString).
--
-- Real: SaftUI-Misc's config.lua, durability.lua and durabilitytooltip.lua,
-- Core's helpers. The figure is fixtures/durability_frame.lua. The inventory
-- APIs here are the test's stand-ins (inventory below), in a global each, as
-- the game has them.
local S = load_test_file('lib/secrets.lua')
local st, DF, DUR, profile

-- Slot -> { current, maximum, quality, name, cost }: what the player wears.
local function inventory()
	return {
		[1] = { 50, 100, 4, 'Crown of Ash', 120000 },
		[2] = { nil, nil, 3, 'Amulet', 0 }, -- no durability
		[3] = { 10, 100, 3, 'Pauldrons', 5000 },
		[5] = { 100, 100, 2, 'Plain Chestplate', 0 },
		[16] = { 199, 200, 2, 'Rusty Sword', 3 },
		[17] = { 30, 100, 1, 'Wooden Shield', 400 },
	}
end

local worn

local function world(client, opts)
	opts = opts or {}
	use_client(client, function()
		stub.screen_width, stub.screen_height = 1000, 600
		stub.installed_addons.Blizzard_DurabilityFrame = true
	end)
	load_core_helpers()
	load_editmode()
	UIParent:SetScale(768 / 600)
	st = SaftUI
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.tooltip_details == false then profile.durability.tooltip_details = false end
	worn = opts.worn or inventory()
	-- Each API is a global the game has; a case without one removes it.
	GetInventoryItemDurability = nil
	if not opts.no_durability_api then
		GetInventoryItemDurability = function(slot)
			local item = worn[slot]
			if item then return item[1], item[2] end
		end
	end
	GetInventoryItemQuality = function(_, slot) return worn[slot] and worn[slot][3] end
	GetInventoryItemLink = function(_, slot)
		local item = worn[slot]
		return item and ('|cffa335ee|Hitem:%d::::::::|h[%s]|h|r'):format(1000 + slot, item[4])
	end
	C_TooltipInfo, C_CurrencyInfo, GetMoneyString = nil, nil, nil
	if not opts.no_tooltip_info then
		C_TooltipInfo = {
			GetInventoryItem = function(_, slot)
				local item = worn[slot]
				if item then return { repairCost = item[5] } end
			end,
		}
	end
	if not opts.no_money then
		GetMoneyString = function(copper)
			return ('%dg %ds %dc'):format(copper / 10000, (copper % 10000) / 100, copper % 100)
		end
	end
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end
	DF = load_test_file('misc/fixtures/durability_frame.lua')
	DF.build()
	load_saftui('SaftUI-Misc/durability.lua')
	load_saftui('SaftUI-Misc/durabilitytooltip.lua')
	DUR = st:GetModule('Durability')
	DUR:Enable()
	stub.run_timers()
	DF.show()
end

local function clean() eq(#take_errors(), 0, 'no errors') end

-- What the tooltip shows now: a list of "left | right" per line.
local function lines()
	local s = stub.state(GameTooltip)
	local out = {}
	for i = 1, s.lines or 0 do
		out[i] = (s.texts[i] or '') .. (s.rights[i] and (' | ' .. s.rights[i]) or '')
	end
	return out
end

local function hover() stub.fire_script(DF.frame, 'OnEnter') end

-- |cffRRGGBB text |r, as the game writes a colored string, from a color's channels.
local function hex(color)
	return ('|cff%02x%02x%02x'):format(math.floor(color.r * 255 + 0.5), math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5))
end

local function quality_hex(quality) return hex(st:QualityColor(quality)) end
local function text_hex(name) return hex(profile.colors.text[name]) end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': a line per damaged slot, lowest first, colored; the repair cost last; Blizzard\'s lines kept first', function()
		world(client)
		hover()
		local got = lines()
		eq(got[1], 'Repair Armor', "Blizzard's title")
		check(got[2]:find('getting low', 1, true), "Blizzard's line")
		eq(got[3], ' ', 'a blank line before the details')
		eq(got[4], quality_hex(3) .. 'Pauldrons|r | ' .. text_hex('danger') .. '10%|r', 'lowest first, red under 20%')
		eq(got[5], quality_hex(1) .. 'Wooden Shield|r | ' .. text_hex('warning') .. '30%|r', 'orange from 20%')
		eq(got[6], quality_hex(4) .. 'Crown of Ash|r | ' .. text_hex('success') .. '50%|r', 'green from 50%')
		eq(got[7], quality_hex(2) .. 'Rusty Sword|r | ' .. text_hex('success') .. '99%|r', "99.5% never reads 100%")
		eq(got[8], 'Repair cost | 12g 54s 3c', "the sum of every item's cost (125403 copper) in the game's money string")
		eq(#got, 8, 'a slot at 100% and a slot with no durability left out')
		clean()
	end)

	test(client .. ': nothing is added when every slot is at 100%', function()
		world(client, { worn = { [1] = { 100, 100, 4, 'Crown', 0 }, [3] = { 60, 60, 3, 'Pauldrons', 0 } } })
		hover()
		eq(#lines(), 2, "only Blizzard's two lines")
		clean()
	end)

	test(client .. ': a missing API adds only what it can', function()
		world(client, { no_durability_api = true })
		hover()
		eq(#lines(), 2, 'no durability API: nothing added, no error')
		clean()

		world(client, { no_tooltip_info = true })
		hover()
		local got = lines()
		eq(#got, 7, 'no repair costs: the items, and no Repair cost line (a guess)')
		check(got[#got]:find('Rusty Sword', 1, true), 'the items still there, the last one the highest percent')
		clean()

		world(client, { no_money = true })
		C_CurrencyInfo = { GetCoinTextureString = function(copper) return 'coins ' .. copper end }
		hover()
		eq(lines()[8], 'Repair cost | coins 125403', "the currency API's coin string when GetMoneyString is missing")
		C_CurrencyInfo.GetCoinTextureString = nil
		hover()
		eq(#lines(), 7, 'and no cost line with neither')
		clean()
	end)

	test(client .. ': secret values are never compared or added', function()
		local restore = S.install()
		world(client)
		worn[3][1] = S.secret('durability') -- Pauldrons: a secret current value
		worn[1][5] = S.secret('cost') -- Crown: a secret repair cost
		worn[16][3] = S.secret('quality') -- Rusty Sword: a secret quality
		hover()
		local got = lines()
		eq(#got, 6, 'the slot with a secret durability left out, and no Repair cost: Crown of Ash\'s cost is secret')
		check(not table.concat(got, '\n'):find('Pauldrons', 1, true), 'Pauldrons is not there')
		eq(got[#got], 'Rusty Sword | ' .. text_hex('success') .. '99%|r', 'a secret quality: the name uncolored')
		clean()
		restore()
	end)

	test(client .. ': something else owning the tooltip is left alone; so is the setting off', function()
		world(client)
		local other = CreateFrame('Frame', nil, UIParent)
		GameTooltip:SetOwner(other, 'ANCHOR_RIGHT')
		GameTooltip:SetText('Some item')
		-- The figure's OnEnter doesn't run for the other frame; its hook only adds while the figure owns the tooltip.
		DF.hide()
		hover()
		eq(table.concat(lines(), '\n'), 'Some item', 'no alerts: the figure makes no tooltip, and the hook adds nothing')
		check(GameTooltip:GetOwner() == other, 'still the other frame\'s')

		world(client, { tooltip_details = false })
		hover()
		eq(#lines(), 2, 'the setting off: only Blizzard\'s lines')
		profile.durability.tooltip_details = true
		hover()
		eq(#lines(), 8, 'on again, at once')
		clean()
	end)

	test(client .. ': nothing is hooked on GameTooltip or written onto Blizzard\'s frames', function()
		world(client)
		local function snapshot()
			local out = {}
			for _, frame in ipairs({ DF.frame, DF.container, DF.frame.Selection }) do
				local keys = {}
				for key in pairs(frame) do keys[#keys + 1] = tostring(key) end
				table.sort(keys)
				out[#out + 1] = table.concat(keys, ',')
			end
			return out
		end
		local before = snapshot()
		hover()
		DF.hide()
		DF.show(true)
		hover()
		local after = snapshot()
		for i = 1, 3 do eq(after[i], before[i], 'the same keys, frame ' .. i) end
		check(next(stub.state(GameTooltip).hooks) == nil, 'no hook on GameTooltip')
		clean()
	end)
end

test('the Durability page has the tooltip setting, on by default', function()
	world('forever')
	local general = DUR:GetConfigTable().args.general
	eq(general.args.tooltip_details.type, 'toggle', 'a toggle')
	eq(general.args.tooltip_details.name, 'Durability details in its tooltip', 'named')
	check(type(general.args.tooltip_details.desc) == 'string' and general.args.tooltip_details.desc ~= '', 'with a desc')
	check(general.args.tooltip_details.order > general.args.move.order, 'beside the first, after it')
	check(general.args.tooltip_details.order < general.args.position.order, 'Position stays last')
	eq(general.get({ 'tooltip_details' }), true, 'on by default')
	general.set({ 'tooltip_details' }, false)
	eq(profile.durability.tooltip_details, false, 'writes durability.tooltip_details')
	clean()
end)
