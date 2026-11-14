-- What the docked edit mode bar covers (SaftUI-Core/EditMode/Bar/bardock.lua):
-- EM:BarRect is the rect of the frame and the line its backdrop draws, flush
-- with the screen's top, nil while the bar is floating, hidden, not built or
-- hidden until hovered; EM:BarCoverHeight is that rect's height or 0; both
-- follow the bar as it slides and BarModeChanged tells what keeps clear of it.
-- A mover can be dragged into the top strip beside the bar. (/sui's offset is
-- options_editbar_test.lua's, the Coordinates label's is
-- editmode_coordinates_test.lua's and editmode_bar_window_test.lua's.)

local H, st, EM

local function build()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM = st.EditModeFrames
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

build()

local EMH = load_test_file('core/editmode_helpers.lua')
local frame_of, set_screen, look = EMH.frame_of, EMH.set_screen, EMH.look

local added = {}
local function add_mover(key)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -300)
	local config = { position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 100, y_off = -300 } }
	local function apply()
		local pos = config.position
		st:SafeReposition(frame, 'bar_rect_' .. key, function()
			frame:ClearAllPoints()
			frame:SetPoint(pos.point, UIParent, pos.rel_point, tonumber(pos.x_off) or 0, tonumber(pos.y_off) or 0)
		end)
	end
	local mover = st:RegisterConfigMover(frame, { key = key, config = function() return config end, apply = apply })
	added[key] = true
	return mover, config
end

local function reset()
	if EM.active then EM:Deactivate() end
	for key in pairs(added) do
		local mover = EM.movers[key]
		if mover then mover.overlay:Hide() end
		EM.movers[key] = nil
		added[key] = nil
	end
	st.config.global.editModeBar = nil
	EM:SetBarFloating(false)
	stub.in_combat = false
	stub.size_noise = 0
	stub.time = 1000
	stub.cursor_x, stub.cursor_y = 0, 0
	set_screen(1920, 1080)
	look('thick')
	H.close_all()
end

local function bar_x() return EM:GetBar():GetLeft() - UIParent:GetLeft() end

test('BarRect: the frame and the line it draws, flush with the top; nil not built, hidden, floating, in combat or hidden until hovered', function()
	reset()
	local inset = st:ThemeInset('theme', 'theme', 'panel')
	check(inset > 0, 'Thick draws a line')
	eq(EM:BarRect(), nil, 'edit mode off: nil')
	eq(EM:BarCoverHeight(), 0, 'and no cover')
	EM:Activate()
	local bar = EM:GetBar()
	local rect = EM:BarRect()
	eq(rect.left, bar_x() - inset, 'left')
	eq(rect.right, bar_x() + bar:GetWidth() + inset, 'right')
	eq(rect.top, UIParent:GetHeight(), 'top: the screen\'s')
	eq(rect.bottom, UIParent:GetHeight() - 70 - inset, 'bottom')
	eq(EM:BarCoverHeight(), 70 + inset, 'the cover is its height')
	-- Thin and Blizzard have their own line.
	for _, name in ipairs({ 'thin', 'blizzard' }) do
		look(name)
		local line = st:ThemeInset('theme', 'theme', 'panel')
		rect = EM:BarRect()
		eq(rect.top - rect.bottom, 70 + line, name .. ': 70 and its line')
		eq(rect.right - rect.left, bar:GetWidth() + 2 * line, name .. ': the width and its line each side')
	end
	look('thick')
	-- It follows the bar as it slides.
	EM:SetBarX(300)
	eq(EM:BarRect().left, 300 - inset, 'slid: the left follows')
	-- Floating: nothing.
	EM:SetBarFloating(true)
	eq(EM:BarRect(), nil, 'floating: nil')
	EM:SetBarFloating(false)
	check(EM:BarRect() ~= nil, 'docked again: back')
	-- Hidden until hovered: nothing.
	EM:SetBarHideUntilHovered(true)
	eq(EM:BarRect(), nil, 'hidden until hovered: nil')
	eq(EM:BarCoverHeight(), 0, 'no cover')
	EM:SetBarHideUntilHovered(false)
	-- Combat: edit mode closes.
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	eq(EM:BarRect(), nil, 'in combat: nil')
	stub.in_combat = false
	reset()
end)

test('BarModeChanged fires when what the bar covers changes: sliding, hiding until hovered, detaching, and not when nothing changed', function()
	reset()
	EM:Activate()
	local count = 0
	EM:On('BarModeChanged', function() count = count + 1 end)
	EM:SetBarX(300)
	check(count >= 1, 'slid: told')
	local n = count
	EM:PlaceBar()
	eq(count, n, 'placed again where it is: not told')
	EM:SetBarHideUntilHovered(true)
	check(count > n, 'hide until hovered: told')
	n = count
	EM:SetBarHideUntilHovered(false)
	check(count > n, 'and off')
	n = count
	EM:SetBarFloating(true)
	check(count > n, 'detached: told')
	reset()
end)

test('a mover can be dragged into the top strip beside the bar: nothing keeps it out, and the bar stays where it is', function()
	reset()
	local mover, config = add_mover('strip_beside')
	EM:Activate()
	local rect = EM:BarRect()
	local scale = UIParent:GetEffectiveScale()
	-- Drag it up to the very top, its left at x = 100: far left of the bar.
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(mover)
	stub.cursor_x, stub.cursor_y = 500, 500 + 400 * scale
	EM:UpdateDrag(mover)
	stub.time = stub.time + 0.2
	EM:UpdateDrag(mover)
	local l, r, b, t = EM.GetOutlineRect(mover)
	check(t > rect.bottom, 'its outline is up in the strip the bar covers in the middle: ' .. t .. ' over ' .. rect.bottom)
	check(r < rect.left, 'beside the bar, not under it')
	EM:StopDrag(mover)
	check(config.position.y_off > -300, 'it moved up')
	reset()
end)
