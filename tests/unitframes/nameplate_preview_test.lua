-- The preview plate at the top of the Enemy and Friendly nameplates pages
-- (SaftUI-Unitframes/nameplates/preview.lua):
--   - one plain frame per page, built from the registered parts that take a
--     plate (not the aura areas yet), styled from the page's config, or the
--     source page's while its box is checked, through the real updaters, and
--     filled with made-up data;
--   - a part its config turns off is hidden, the threat text shows on the
--     Enemy page only, the subtext follows the page's NPC or Player box;
--   - the band: no height while another nameplate addon draws, else from the
--     extent of the shown parts, clamped; both pages carry it.
--
-- The world is nameplate_world.lua's (see its top). No plates are spawned:
-- the preview never touches one.
local NP = load_test_file('unitframes/nameplate_world.lua')

-- Blizzard's raid mark texture helper (SharedXML), which oUF's raid target
-- element calls: the stand-in records the index on the texture.
local function world(client)
	local st, UF = NP.world(client or 'forever')
	_G.SetRaidTargetIconTexture = function(texture, index)
		texture:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		texture.raidIndex = index
	end
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	return st, UF, UF:GetProfileConfig()
end

local function rgb(r, g, b) return table.concat({ r, g, b }, ',') end
local function hex(st, color) return '|cff' .. st.StringFormat:ToHex(color:GetRGB()) end

-- A holder as the window's band is: a frame the band draws in.
local function holder(width, height)
	local f = CreateFrame('Frame', nil, UIParent)
	f:SetSize(width or 774, height or 150)
	f:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	return f
end

-- The page's frame styled, and anchored so its parts have rects (a frame with
-- no anchor has none, as in the game).
local function styled(UF, page)
	local frame = UF:StylePlatePreview(page)
	frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	return frame
end

test('preview: every part on by default shows on the Enemy page', function()
	local st, UF, config = world()
	local frame = styled(UF, 'nameplate')
	eq(frame.base_unit, 'nameplate')
	eq(frame.isNamePlate, true)
	eq(frame.friendly, false)
	for _, part in ipairs({ 'Health', 'Name', 'Castbar', 'Threat', 'QuestIndicator', 'RaidTargetIndicator' }) do
		assert(frame[part], part .. ' built')
		eq(frame[part]:IsShown(), true, part .. ' shown')
	end
	eq(frame.Subtext:IsShown() and frame.Subtext:GetText() ~= '', false, 'subtext empty: the NPC box is off')
	eq(frame.Castbar.Icon:IsShown(), true, 'cast icon')
	eq(frame.Castbar.Text:GetText(), 'Shadow Bolt')
	eq(frame.Castbar.Text:IsShown(), true)
	eq(frame.Buffs, nil, 'no aura areas yet')
	eq(frame.Debuffs, nil)
	eq(frame.Name:GetText(), hex(st, st:Color('text', 'danger')) .. 'Thornfang Ravager|r')
	eq(frame.Health.text:GetText(), UF.PlainHealthText(config.nameplate.health.text, 180000, 250000))
	eq(frame.Threat:GetText(), '87%')
	eq(rgb(frame.Health:GetStatusBarColor()), table.concat({ UF.oUF.colors.reaction[2]:GetRGB() }, ','), 'reaction colour')
	eq(frame.Castbar.Icon.texture:GetTexture(), 136197)
	eq(frame.RaidTargetIndicator.raidIndex, 8, 'skull')
	eq(frame.QuestIndicator:GetTexture(), [[Interface\TargetingFrame\PortraitQuestBadge]])
	eq(#take_errors(), 0)
end)

test('preview: parts placed by the page config', function()
	local st, UF, config = world()
	local frame = styled(UF, 'nameplate')
	local function gap() return frame.Health:GetBottom() - frame.Castbar:GetTop() end
	eq(gap(), 6)
	config.nameplate.castbar.position.y_off = -10
	styled(UF, 'nameplate')
	eq(gap(), 10)
	-- A part anchored to another resolves through UF:GetFrame on the preview.
	eq(UF:GetFrame(frame, { element = 'Health' }), frame.Health)
	local _, rel = frame.Castbar:GetPoint(1)
	eq(rel, frame.Health)
	local _, relIcon = frame.Castbar.Icon:GetPoint(1)
	eq(relIcon, frame.Castbar)
	eq(#take_errors(), 0)
end)

test('preview: a part turned off hides', function()
	local st, UF, config = world()
	local frame = styled(UF, 'nameplate')
	eq(frame.Castbar:IsShown(), true)
	config.nameplate.castbar.enable = false
	UF:StylePlatePreview('nameplate')
	eq(frame.Castbar:IsShown(), false)
	eq(frame.Castbar.Text:IsShown(), false)
	config.nameplate.castbar.enable = true
	UF:StylePlatePreview('nameplate')
	eq(frame.Castbar:IsShown(), true)
	eq(frame.Castbar.Text:IsShown(), true)
end)

test('preview: Friendly page shows no threat and draws from Friendly config', function()
	local st, UF, config = world()
	local frame = styled(UF, 'friendlynameplate')
	eq(frame.base_unit, 'friendlynameplate')
	eq(frame.friendly, true)
	eq(frame.Name:GetText():find('Aldric', 1, true) ~= nil, true, frame.Name:GetText())
	eq(frame.Threat:IsShown(), false)
	eq(frame.Castbar.Text:GetText(), 'Flash Heal')
	eq(frame.Castbar.Icon.texture:GetTexture(), 135907)
	local class = select(2, UnitClass('player'))
	if config.friendlynameplate.health.colorClass then
		eq(rgb(frame.Health:GetStatusBarColor()), table.concat({ UF.oUF.colors.class[class]:GetRGB() }, ','), 'class colour')
	end
	eq(#take_errors(), 0)
end)

test('preview: the box draws from the other page', function()
	local st, UF, config = world()
	config.friendlynameplate.use_enemy = true
	config.nameplate.castbar.position.y_off = -14
	local frame = styled(UF, 'friendlynameplate')
	eq(frame.base_unit, 'nameplate')
	eq(frame.Castbar.config, config.nameplate.castbar)
	eq(frame.Health:GetBottom() - frame.Castbar:GetTop(), 14)
	eq(frame.Threat:IsShown(), false, 'still no threat on a friend')
	-- Unchecked, back to its own.
	config.friendlynameplate.use_enemy = false
	UF:StylePlatePreview('friendlynameplate')
	eq(frame.base_unit, 'friendlynameplate')
	-- The Enemy page's box.
	config.nameplate.use_friendly = true
	local enemy = styled(UF, 'nameplate')
	eq(enemy.base_unit, 'friendlynameplate')
	eq(#take_errors(), 0)
end)

test("preview: subtext follows the page's boxes", function()
	local st, UF, config = world()
	config.nameplate.subtext.npc = true
	local frame = styled(UF, 'nameplate')
	eq(frame.Subtext:GetText(), '<Pack Leader>')
	eq(frame.Subtext:IsShown(), true)
	config.friendlynameplate.subtext.player = true
	local friend = styled(UF, 'friendlynameplate')
	eq(friend.Subtext:GetText(), '<Emerald Wardens>')
	config.friendlynameplate.subtext.player = false
	UF:StylePlatePreview('friendlynameplate')
	eq(friend.Subtext:IsShown(), false)
end)

test('preview: a profile switch reads the new tables', function()
	local st, UF, config = world()
	local frame = styled(UF, 'nameplate')
	local function gap() return frame.Health:GetBottom() - frame.Castbar:GetTop() end
	eq(frame:GetWidth(), 200)
	eq(gap(), 6)
	-- A switch swaps the profile's tables (UF:UpdateConfig): the next style
	-- reads the new ones, never a table cached from the old.
	local function copy(t)
		if type(t) ~= 'table' or t.GetRGB then return t end
		local out = {}
		for k, v in pairs(t) do out[k] = copy(v) end
		return out
	end
	local new = copy(config.nameplate)
	new.width = 260
	new.castbar.position.y_off = -9
	config.nameplate = new
	styled(UF, 'nameplate')
	eq(frame:GetWidth(), 260)
	eq(frame.Health:GetWidth(), 260)
	eq(frame.Castbar.config, new.castbar)
	eq(gap(), 9)
	eq(#take_errors(), 0)
end)

test('band: none while another nameplate addon draws', function()
	local st, UF = world()
	local band = UF.PlatePreviewBand('nameplate')
	assert(band.height(774) >= 120)
	stub.loaded_addons.Plater = true
	eq(band.height(774), nil)
end)

test('band: height from the extent', function()
	local st, UF = world()
	local band = UF.PlatePreviewBand('nameplate')
	local height = band.height(774)
	local frame = UF:PlatePreviewFrame('nameplate')
	local above, below = UF.PlatePreviewExtent(frame)
	local want = math.min(200, math.max(120, above + 20 + below + 24))
	eq(height, math.ceil(want - 0.001))
	assert(height >= 120 and height <= 200, height)
	eq(#take_errors(), 0)
end)

test('band: a moved part and the cap', function()
	local st, UF, config = world()
	local band = UF.PlatePreviewBand('nameplate')
	-- The raid mark is 48 above the bar and the castbar 18 under it by
	-- default: 48 + 20 + 18 + 24 = 110, the minimum 120 shows.
	eq(band.height(774), 120)
	-- The castbar 40 under the bar (12 tall): below = 52; 48 + 20 + 52 + 24.
	config.nameplate.castbar.position.y_off = -40
	eq(band.height(774), 144)
	-- 90 under: 48 + 20 + 102 + 24 = 194; 120 under: capped at 200.
	config.nameplate.castbar.position.y_off = -90
	eq(band.height(774), 194)
	config.nameplate.castbar.position.y_off = -120
	eq(band.height(774), 200)
	eq(#take_errors(), 0)
end)

test('band: a fractional edge still puts the bar on a whole pixel', function()
	local st, UF, config = world()
	local band = UF.PlatePreviewBand('nameplate')
	-- The threat text 6.4 above the bar, the bar itself 0.5 down in the frame.
	config.nameplate.threat.position.y_off = 6.4
	config.nameplate.health.position.y_off = -0.5
	local height = band.height(774)
	local h = holder(774, height)
	band.draw(h, 774, height)
	local frame = UF:PlatePreviewFrame('nameplate')
	local drop = h:GetTop() - frame.Health:GetTop()
	eq(drop, math.floor(drop), 'whole pixels under the holder: ' .. drop)
	eq(band.height(774) % 1, 0)
	eq(#take_errors(), 0)
end)

test('band: draw centres the bar under the holder top and release hides', function()
	local st, UF = world()
	local band = UF.PlatePreviewBand('nameplate')
	local h = holder(774, band.height(774))
	band.draw(h, 774, band.height(774))
	local frame = UF:PlatePreviewFrame('nameplate')
	eq(frame:IsShown(), true)
	eq(frame:GetParent(), h)
	local above = UF.PlatePreviewExtent(frame)
	eq(frame.Health:GetTop(), h:GetTop() - 12 - above)
	eq((frame.Health:GetLeft() + frame.Health:GetRight()) / 2, (h:GetLeft() + h:GetRight()) / 2)
	band.release(h)
	eq(frame:IsShown(), false)
	eq(UF.PlatePreviewBand('nameplate'), band, 'one table per page')
	eq(#take_errors(), 0)
end)

test('band: the page has it', function()
	local st, UF = world()
	local args = UF:GetConfigTable().args
	for _, page in ipairs({ 'nameplate', 'friendlynameplate' }) do
		local band = args[page].pickerBand
		eq(type(band), 'table', page)
		eq(type(band.height), 'function')
		eq(type(band.draw), 'function')
		eq(band, UF.PlatePreviewBand(page))
	end
end)
