-- The nameplates in each theme (SaftUI's nameplates/, with updaters.lua's
-- kinds and fills, nameplates/target.lua's border and nameplates/threat.lua's
-- tint, and unitframes.lua's UF:OnColorsChanged):
--   - under Thick and Thin the plate's health bar and castbar draw as unit
--     frames, so as every other unit frame's bars (a bar's look), the cast
--     icon as a control and the aura buttons as auras;
--   - under Blizzard the health bar and the castbar sit in the bronze box, the
--     health bar on Blizzard's raid fill and the castbar on its own texture;
--   - the target's border (white under Thick and Thin, Blizzard's art under
--     Blizzard) survives a theme recolour and redraw, and
--     UF:OnColorsChanged('theme') checks it again on every plate;
--   - the threat tint stays on through a theme change both ways, on the flat
--     fill and on Blizzard's, and comes off Blizzard's fill cleanly;
--   - a theme switch both ways with plates showing leaves nothing of one look
--     in the other;
--   - the Enemy nameplates page's Theme draws the plate frame as every unit's
--     frame is drawn.
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua), whose elements don't update from the
-- unit's data. So oUF colouring a bar is done by hand (ouf_colours), and an
-- aura button is handed to the area's PostCreateButton as oUF's aura
-- container hands it one (aura_button; the stand-in container makes none).
-- The draw calls are watched (T.watch), since the kind changes nothing under
-- Thick and Thin. The shell's Config has no Config:UpdateConfig, so a theme
-- change runs st:ThemeChanged's steps here, in Config:UpdateConfig's order
-- (theme_changed).
local T = load_test_file('lib/theme_helpers.lua')
local NP = load_test_file('unitframes/nameplate_world.lua')

local CLIENTS = { 'forever', 'retail' }
local BOX = 'BottomEdge,BottomLeftCorner,BottomRightCorner,LeftEdge,RightEdge,TopEdge,TopLeftCorner,TopRightCorner'
local WHITE = '1.00,1.00,1.00'

-- A world on client with SaftUI's theme set to theme, the draw calls watched
-- (drawn), the plates spawned, and the player a damage dealer in a party with
-- party1, so the threat tint shows.
local function world(client, theme)
	local st, UF = NP.world(client)
	local drawn = T.watch()
	st.config.profile.theme.name = theme
	UF:SpawnNameplates()
	stub.role = 'DAMAGER'
	stub.group = { members = { 'party1' } }
	stub.units.party1 = { name = 'Friend', player = true, friend = true, role = 'DAMAGER' }
	return st, UF, UF:GetProfileConfig().nameplate, drawn
end

-- An enemy's plate, with the player's threat status on it (nil: not on its
-- threat list). Returns SaftUI's frame on the plate.
local function enemy(unit, status)
	stub.units[unit] = { name = unit, friend = false, attackable = true, reaction = 2 }
	stub.threat[unit] = { player = status }
	return NP.add(unit)
end

-- The target changes: the game's answer, then its event.
local function target(unit)
	stub.nameplate_target = unit
	stub.fire_event('PLAYER_TARGET_CHANGED')
end

-- st:ThemeChanged with theme as SaftUI's theme: Config:UpdateConfig's steps
-- (SaftUI-Core/Config/config.lua), in its order: every drawn frame redrawn
-- (st:RedrawThemed), every module's UpdateConfig (the unit frames' here),
-- then st:ColorsChanged('theme').
local function theme_changed(st, UF, theme)
	T.theme(theme, function()
		UF:UpdateConfig()
		st:ColorsChanged('theme')
	end)
end

-- oUF colouring an enemy's health bar SaftUI's hostile red, then its colour
-- callback, as its ColorPath does.
local HOSTILE = { 135 / 255, 81 / 255, 81 / 255 }
local function ouf_colours(frame)
	frame.Health:SetStatusBarColor(unpack(HOSTILE))
	frame.Health:PostUpdateColor(frame.__unit)
end

-- A button oUF's aura container made for an aura, handed to the area's
-- PostCreateButton as oUF does (theme_test.lua's make_aura_button).
local function aura_button(auras)
	local button = CreateFrame('Button', nil, auras)
	button:SetSize(20, 20)
	button:SetPoint('TOPLEFT')
	button.Icon = button:CreateTexture(nil, 'BORDER')
	button.Icon:SetAllPoints()
	button.Count = button:CreateFontString(nil, 'OVERLAY')
	button.Border = button:CreateTexture(nil, 'OVERLAY')
	button.Border:SetAllPoints()
	auras:PostCreateButton(button)
	return button
end

local rgb = T.rgb
local function color(c) return rgb(c.r, c.g, c.b) end
local function bar(frame) return rgb(frame.Health:GetStatusBarColor()) end

-- The kind a frame was last drawn as: the last of drawn's three.
local function kind(drawn, frame)
	local d = drawn(frame)
	return d and d:match('[^,]+$')
end

-- What a frame's backdrop shows: its inset, fill and edge colours, whether
-- Thick's outer lines show, whether it has an edge line, where it sits round
-- the frame and the Blizzard art shown on it (blizzard_look_test.lua's);
-- 'bare' for none.
local function looks(frame)
	local backdrop = frame.backdrop
	if not (backdrop and backdrop.backdropInfo) then return 'bare' end
	local outer = backdrop.altborder and backdrop.altborder.LEFT:IsShown() and 'outer' or 'no outer'
	local line = backdrop.backdropInfo.edgeFile and 'a line' or 'no line'
	return ('inset %d, fill %s, edge %s, %s, %s, at %s, art {%s}'):format(T.inset(backdrop), T.fill(backdrop),
		T.edge(backdrop), outer, line, T.around(backdrop, frame), T.art(backdrop))
end

-- What a frame of frame's size looks like drawn with theme and background as
-- a bar, which every unit frame's bars look like under Thick and Thin.
local function as_bar(st, frame, theme, background)
	local other = CreateFrame('Frame', nil, UIParent)
	other:SetSize(frame:GetWidth(), frame:GetHeight())
	other:SetPoint('CENTER')
	st:SetBackdrop(other, theme, background, 'bar')
	return looks(other)
end

-- The shown pieces of a drawn frame's Blizzard art, by key; '' for none.
local function pieces(frame)
	return (T.art(frame):gsub('=[^,]*', ''))
end

-- The shown pieces of a drawn frame's Blizzard art with their tint, sorted:
-- 'key=r,g,b,a'; '' for none.
local function tints(frame)
	local art = SaftUI.ThemeArt.Get(frame)
	local out = {}
	for key, piece in pairs(art and art.pieces or {}) do
		if piece:IsShown() then out[#out + 1] = key .. '=' .. T.text(piece:GetVertexColor()) end
	end
	table.sort(out)
	return table.concat(out, ';')
end

-- The bar's fill: 'atlas <name>' for an atlas, else 'flat <file>', and
-- whether it tiles.
local function fill(statusbar)
	local texture = statusbar:GetStatusBarTexture()
	local atlas = texture:GetAtlas()
	local what = atlas and ('atlas ' .. atlas) or ('flat ' .. tostring(texture:GetTexture()))
	local tiled = (texture:GetHorizTile() or texture:GetVertTile()) and 'tiled' or 'untiled'
	return what .. ', ' .. tiled
end

------------------------------------------------------------------ Thick and Thin

for _, theme in ipairs({ 'thick', 'thin' }) do
	for _, client in ipairs(CLIENTS) do
		test(client .. ': ' .. theme .. ': plate health and castbar draw as unit frames, the cast icon as a control, aura buttons as auras', function()
			local st, UF, P, drawn = world(client, theme)
			local frame = enemy('nameplate1', 0)
			eq(drawn(frame.Health), 'theme,theme,unitframe', 'the health bar')
			eq(drawn(frame.Castbar), 'theme,theme,unitframe', 'the castbar (182 by 12 holds the box)')
			eq(drawn(frame.Castbar.Icon), 'theme,theme,control', 'the cast icon')
			local debuff, buff = aura_button(frame.Debuffs), aura_button(frame.Buffs)
			eq(drawn(debuff), P.debuffs.theme .. ',' .. P.debuffs.background .. ',aura', 'a debuff')
			eq(drawn(buff), P.buffs.theme .. ',' .. P.buffs.background .. ',aura', 'a purgeable buff')
			eq(drawn(frame), 'none,theme,unitframe', 'the plate frame itself: None, as every unit frame by default')

			-- As every other unit frame's bars: a bar's look.
			for name, part in pairs({ Health = frame.Health, Castbar = frame.Castbar }) do
				local config = part == frame.Health and P.health or P.castbar
				eq(looks(part), as_bar(st, part, config.theme, config.background), name .. ' looks as a bar')
				eq(T.inset(part.backdrop), theme == 'thick' and 2 or 1, name .. "'s border is " .. theme .. "'s")
			end
			eq(fill(frame.Health), 'flat ' .. st.BLANK_TEX .. ', untiled', 'the flat fill')
			eq(#take_errors(), 0, 'no error')
		end)
	end
end

------------------------------------------------------------------ Blizzard

for _, client in ipairs(CLIENTS) do
	test(client .. ": Blizzard: health and castbar in the bronze box, health on Blizzard's raid fill, the castbar on its own texture", function()
		local st, UF, P, drawn = world(client, 'blizzard')
		local frame = enemy('nameplate1', 0)
		eq(drawn(frame.Health), 'theme,theme,unitframe', 'the health bar as a unit frame')
		eq(drawn(frame.Castbar), 'theme,theme,unitframe', 'the castbar too')
		for name, part in pairs({ Health = frame.Health, Castbar = frame.Castbar }) do
			local box = st:DrawnFrame(part)
			eq(pieces(box), BOX, name .. ': the bronze box')
			eq(T.inset(box), 2, name .. ': at the box inset')
			eq(T.around(box, part), '-2,2,2,-2', name .. ': 2 round the bar')
			eq(box.backdropInfo.edgeFile, nil, name .. ': no line')
		end
		eq(fill(frame.Health), 'atlas RaidFrame-Hp-Fill, tiled', "health: Blizzard's raid fill")
		eq(frame.Health.bg:GetAtlas(), 'raidframe-hp-bg-white', 'over its background')
		eq(frame.Castbar:GetStatusBarTexture():GetAtlas(), nil, 'the castbar keeps its texture')
		eq(looks(frame.Castbar.Icon), 'bare', 'the cast icon is a control: Blizzard draws it bare')
		eq(kind(drawn, aura_button(frame.Debuffs)), 'aura', 'a debuff as an aura')
		eq(#take_errors(), 0, 'no error')
	end)
end

-- A plate bar too small for the bronze box (UF.BoxFits: under 12 on a side
-- for the box's 8px corners and inset 2) draws as a small frame under
-- Blizzard, as every unit's bars do: one line round the fill, no pieces.
for _, client in ipairs(CLIENTS) do
	test(client .. ': Blizzard: a plate bar under the box threshold draws as a small frame, a line and the fill', function()
		local st, UF, P, drawn = world(client, 'blizzard')
		P.castbar.height = 8
		P.height = 10 -- the plate, and the health bar filling it
		UF:UpdateConfig('nameplate')
		local frame = enemy('nameplate1', 0)
		eq(drawn(frame.Castbar), 'theme,theme,small', 'the castbar, 8 tall')
		eq(drawn(frame.Health), 'theme,theme,small', 'the health bar, 10 tall')
		for name, part in pairs({ Health = frame.Health, Castbar = frame.Castbar }) do
			local box = st:DrawnFrame(part)
			eq(pieces(box), '', name .. ': no pieces of the box')
			eq(T.inset(box), 1, name .. ': at the small inset')
			eq(T.around(box, part), '-1,1,1,-1', name .. ': 1 round the bar')
			check(box.backdropInfo.edgeFile ~= nil, name .. ': a line')
		end
		eq(fill(frame.Health), 'atlas RaidFrame-Hp-Fill, tiled', "health still on Blizzard's raid fill")
		-- At the threshold, the box again.
		P.castbar.height = 12
		UF:UpdateConfig('nameplate')
		eq(drawn(frame.Castbar), 'theme,theme,unitframe', 'the castbar, 12 tall: the box')
		eq(pieces(st:DrawnFrame(frame.Castbar)), BOX, 'its pieces')
		eq(#take_errors(), 0, 'no error')
	end)
end

------------------------------------------------------------------ the target border

for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
	test('the target border survives a recolor and a redraw: ' .. theme, function()
		local st, UF = world('forever', theme)
		local one, two = enemy('nameplate1', 0), enemy('nameplate2', 0)
		target('nameplate1')

		local function marked(frame)
			if theme == 'blizzard' then return UF:PlateTargetArt(frame):IsShown() end
			return T.edge_rgb(UF.PlateBorderFrame(frame)) == WHITE
		end
		local own = T.edge_rgb(UF.PlateBorderFrame(two))
		local box = T.art(UF.PlateBorderFrame(two)) .. ' ' .. tints(UF.PlateBorderFrame(two))
		eq(marked(one), true, 'the target marked')
		eq(marked(two), false, 'the other not')

		for _, step in ipairs({
			{ 'a recolour', function() st:RecolorThemed() end },
			{ "a module's colours put back", function() st:ColorsChanged('theme') end },
			{ 'a redraw', function() st:RedrawThemed() end },
			{ 'a theme change to itself', function() theme_changed(st, UF, theme) end },
		}) do
			step[2]()
			eq(marked(one), true, step[1] .. ': the target still marked')
			eq(marked(two), false, step[1] .. ': the other still not')
			if theme == 'blizzard' then
				local art = UF:PlateTargetArt(one).texture
				eq(art:GetAtlas(), st.ThemeArt.Control('nameplatetarget').atlas, step[1] .. ": Blizzard's target art")
				eq(T.art(UF.PlateBorderFrame(one)) .. ' ' .. tints(UF.PlateBorderFrame(one)), box,
					step[1] .. ': the bronze box keeps its own colour under the art, as the other plate\'s')
				check(tints(UF.PlateBorderFrame(one)):find('TopEdge=1.00,1.00,1.00,1.00', 1, true) ~= nil,
					step[1] .. ': untinted')
			else
				eq(T.edge_rgb(UF.PlateBorderFrame(two)), own, step[1] .. ": the other keeps the theme's own")
			end
		end
		eq(#take_errors(), 0, 'no error')
	end)
end

test("UF:OnColorsChanged('theme') checks the target border on every plate, shown or not", function()
	local st, UF = world('forever', 'thick')
	local one, two = enemy('nameplate1', 0), enemy('nameplate2', 0)
	NP.remove('nameplate2')
	local checked = {}
	local update = UF.UpdatePlateTarget
	UF.UpdatePlateTarget = function(self, frame)
		checked[frame] = (checked[frame] or 0) + 1
		return update(self, frame)
	end
	st:ColorsChanged('theme')
	UF.UpdatePlateTarget = update
	eq(checked[one], 1, 'the plate showing a unit, once')
	eq(checked[two], 1, 'and the plate the game took away')

	-- So a target border coloured off by anything but the theme engine (which
	-- puts it back itself) comes back with the theme's colours.
	target('nameplate1')
	st:SetBorderColor(UF.PlateBorderFrame(one))
	check(T.edge_rgb(UF.PlateBorderFrame(one)) ~= WHITE, 'coloured off')
	st:ColorsChanged('theme')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'white again')

	-- A plate whose border errors is reported, and the plates after it are
	-- still drawn (the plates are kept by number, so one comes first).
	local three = enemy('nameplate3', 0)
	target('nameplate3')
	st:SetBorderColor(UF.PlateBorderFrame(three))
	UF.UpdatePlateTarget = function(self, frame)
		if frame == one then error('a broken plate') end
		return update(self, frame)
	end
	st:ColorsChanged('theme')
	UF.UpdatePlateTarget = update
	eq(#take_errors(), 1, 'the broken plate reported')
	eq(T.edge_rgb(UF.PlateBorderFrame(three)), WHITE, 'a later plate still white')

	-- Other colour groups don't touch it.
	checked = {}
	UF.UpdatePlateTarget = function(self, frame)
		checked[frame] = (checked[frame] or 0) + 1
		return update(self, frame)
	end
	st:ColorsChanged('text')
	UF.UpdatePlateTarget = update
	eq(next(checked), nil, 'a text colour change checks no plate')
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ the threat tint

test('a threat tint survives a theme change, both ways, on the flat fill and on Blizzard\'s', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF = world(client, 'thick')
		local threat = st.config.profile.colors.threat
		local frame = enemy('nameplate1', 3)
		eq(bar(frame), color(threat.bad), client .. ': bad, tinted')

		theme_changed(st, UF, 'blizzard')
		eq(fill(frame.Health), 'atlas RaidFrame-Hp-Fill, tiled', client .. ": Blizzard: on Blizzard's raid fill")
		eq(bar(frame), color(threat.bad), client .. ': Blizzard: the fill takes the tint')
		ouf_colours(frame)
		eq(bar(frame), color(threat.bad), client .. ': Blizzard: and keeps it when oUF colours the bar')

		theme_changed(st, UF, 'thin')
		eq(fill(frame.Health), 'flat ' .. st.BLANK_TEX .. ', untiled', client .. ': Thin: the flat fill')
		eq(bar(frame), color(threat.bad), client .. ': Thin: still tinted')

		theme_changed(st, UF, 'blizzard')
		eq(bar(frame), color(threat.bad), client .. ': Blizzard again: still tinted')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("under Blizzard the tint comes off the raid fill cleanly: oUF's colour, on the same fill", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF = world(client, 'blizzard')
		local threat = st.config.profile.colors.threat
		local frame = enemy('nameplate1', 1)
		eq(bar(frame), color(threat.warning), client .. ': warning, on the fill')
		local before = frame.Health.__forceUpdates or 0
		stub.threat.nameplate1.player = 0
		stub.fire_event('UNIT_THREAT_LIST_UPDATE', 'nameplate1')
		eq(frame.threatState, 'good', client .. ': good')
		eq((frame.Health.__forceUpdates or 0) - before, 1, client .. ": oUF colours the bar again")
		ouf_colours(frame)
		eq(bar(frame), rgb(unpack(HOSTILE)), client .. ": oUF's colour")
		eq(fill(frame.Health), 'atlas RaidFrame-Hp-Fill, tiled', client .. ': on the same fill')
		eq(frame.Health.bg:GetAtlas(), 'raidframe-hp-bg-white', client .. ': over its background')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ switching

-- Everything of a look that shows on a plate showing an enemy, as text: the
-- health bar's and castbar's backdrops, the health's fill and background, the
-- cast icon's backdrop, an aura button's dispel border and whether Thick's
-- dark line shows (a look that never made it shows none), the target art
-- when it shows and the target's border colour.
local function snapshot(st, UF, frame, button)
	local art = UF:PlateTargetArt(frame)
	local line = false
	for _, region in ipairs({ button:GetRegions() }) do
		if region ~= button.Icon and region ~= button.Border and region:IsObjectType('Texture')
				and (region:GetDrawLayer()) == 'BACKGROUND' and region:IsShown() then
			line = true
		end
	end
	return table.concat({
		'health {' .. looks(frame.Health) .. '}',
		'castbar {' .. looks(frame.Castbar) .. '}',
		'fill {' .. fill(frame.Health) .. ', bg ' .. tostring(frame.Health.bg:GetAtlas() or frame.Health.bg:GetTexture()) .. '}',
		'icon {' .. looks(frame.Castbar.Icon) .. '}',
		'aura border {' .. tostring(button.Border:GetTexture()) .. ' ' .. tostring((button.Border:GetDrawLayer())) .. '}',
		'aura line {' .. tostring(line) .. '}',
		'target art {' .. (art:IsShown() and tostring(art.texture:GetAtlas()) or 'hidden') .. '}',
		'border {' .. tostring(UF.PlateBorderFrame(frame) and T.edge_rgb(UF.PlateBorderFrame(frame))) .. '}',
	}, '\n')
end

for _, case in ipairs({ { 'thick', 'blizzard' }, { 'thin', 'blizzard' }, { 'blizzard', 'thick' } }) do
	local from, to = case[1], case[2]
	for _, client in ipairs(CLIENTS) do
		test(client .. ': a switch ' .. from .. ' to ' .. to .. ' and back with plates showing leaves nothing of one look in the other', function()
			-- What each look is when it's the first one drawn.
			local fresh = {}
			for _, theme in ipairs({ from, to }) do
				local st, UF = world(client, theme)
				local frame = enemy('nameplate1', 0)
				local button = aura_button(frame.Debuffs)
				target('nameplate1')
				fresh[theme] = snapshot(st, UF, frame, button)
			end
			check(fresh[from] ~= fresh[to], 'the two looks differ')

			local st, UF = world(client, from)
			local frame = enemy('nameplate1', 0)
			local button = aura_button(frame.Debuffs)
			target('nameplate1')
			eq(snapshot(st, UF, frame, button), fresh[from], from .. ' first')
			theme_changed(st, UF, to)
			eq(snapshot(st, UF, frame, button), fresh[to], 'switched to ' .. to .. ': as ' .. to .. ' drawn first')
			theme_changed(st, UF, from)
			eq(snapshot(st, UF, frame, button), fresh[from], 'and back to ' .. from)
			eq(#take_errors(), 0, 'no error')
		end)
	end
end

------------------------------------------------------------------ the page's Theme

test("the Enemy nameplates page's Theme draws the plates as every unit's does", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P, drawn = world(client, 'thick')
		local frame = enemy('nameplate1', 0)
		P.theme = 'thin'
		UF:UpdateConfig('nameplate')
		eq(drawn(frame), 'thin,theme,unitframe', client .. ': the plate frame in Thin, as a unit frame')
		eq(drawn(frame.Health), 'theme,theme,unitframe', client .. ': its bars keep their own')

		-- Blizzard's on the plate and its health: one box, the plate's, as a
		-- unit frame whose health fills it; the target art still round the bar.
		st.config.profile.theme.name = 'blizzard'
		P.theme = 'blizzard'
		UF:UpdateConfig('nameplate')
		eq(drawn(frame), 'blizzard,theme,unitframe', client .. ': the plate frame in the box')
		eq(drawn(frame.Health), 'none,theme,unitframe', client .. ': health, filling it, draws none of its own')
		eq(pieces(st:DrawnFrame(frame)), BOX, client .. ": the plate's box")
		eq(UF.PlateBorderFrame(frame), st:DrawnFrame(frame), client .. ': the border is the plate frame\'s')
		eq(fill(frame.Health), 'atlas RaidFrame-Hp-Fill, tiled', client .. ': health on the raid fill still')
		target('nameplate1')
		eq(UF:PlateTargetArt(frame):IsShown(), true, client .. ': the target art')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)
