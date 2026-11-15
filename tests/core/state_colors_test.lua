-- The state colors (Text > Strong, Danger, and Text > Normal read through the
-- accessor) in what the options window, its kit and Core draw: a status line
-- and a tip line that says it is Danger, the share line's links under the
-- mouse in Strong, the close button's hover, and the labels, fields and knobs in
-- Text. The migration and the Colors page rows are color_migration_test.lua's
-- and colors_test.lua's; the other addons' readers are in their own files.
--
-- Every case runs with Danger, Strong and Text set to values that are not
-- their defaults (at the top, before the window is first built), so a reader
-- that drew a red or a white of its own fails.
--
-- Real: the /sui window's world (options_window_helpers.lua).
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local W, OB, OW = st.OptionsWidgets, st.OptionsBody, st.OptionsWindow
local frames, theme, close_all = H.frames, H.theme, H.close_all

local DANGER, STRONG, NORMAL = { 0.9, 0.2, 0.3 }, { 0.3, 0.8, 0.1 }, { 0.1, 0.5, 0.7 }
local colors = st.config.profile.colors.text
colors.danger:SetRGB(unpack(DANGER)); colors.strong:SetRGB(unpack(STRONG)); colors.normal:SetRGB(unpack(NORMAL))

local function text(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local function rgb(c) return text(c[1], c[2], c[3]) end
local function ink(fs) return text(fs:GetTextColor()) end
local function vertex(region) return text(region:GetVertexColor()) end

if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
local lines
local realAddLine = GameTooltip.AddLine
GameTooltip.AddLine = function(self, line, r, g, b, wrap)
	lines[#lines + 1] = { text = line, color = r and text(r, g, b) or nil }
	return realAddLine(self, line, r, g, b, wrap)
end

test('a tip line given danger = true is Danger, the others Text > Normal and the title white, at odd values', function()
	lines = {}
	local owner = CreateFrame('Frame', nil, UIParent)
	W.ShowTip(owner, 'Title', { 'one', { text = 'two', danger = true }, { text = 'three' } })
	eq(lines[1].color, '1.00,1.00,1.00', "the game's white title")
	eq(lines[2].color, rgb(NORMAL), 'a plain line in Text > Normal')
	eq(lines[3].color, rgb(DANGER), 'a danger line in Text > Danger')
	eq(lines[4].color, rgb(NORMAL), 'a line with a table and no flag')
	lines = {}
	W.ShowTip(owner, 'Title', { { text = 'old field', red = true } })
	eq(lines[2].color, rgb(NORMAL), 'red = true is no longer read: Normal')
	GameTooltip:Hide()
end)

test('a tip line is the same red at the defaults as the old Text > Red', function()
	colors.danger:SetRGB(220/255, 100/255, 100/255)
	lines = {}
	W.ShowTip(CreateFrame('Frame', nil, UIParent), 'Title', { { text = 'x', danger = true } })
	eq(lines[2].color, text(220/255, 100/255, 100/255), 'dc6464')
	colors.danger:SetRGB(unpack(DANGER))
	GameTooltip:Hide()
end)

test("a disabled row's why in its tooltip is Text > Danger", function()
	lines = {}
	local frame = CreateFrame('Frame', nil, UIParent)
	frame.row = { name = 'Row', desc = 'What it does.', disabledDesc = 'Why not.' }
	OB.ShowTip(frame)
	eq(lines[1].color, '1.00,1.00,1.00', 'the name white')
	eq(lines[2].color, nil, "the desc in the game's own color")
	eq(lines[3].text .. '|' .. lines[3].color, 'Why not.|' .. rgb(DANGER), 'the why in Danger')
	GameTooltip:Hide()
end)

test("the window's status line and the small dialog's are Text > Danger", function()
	theme('thick')
	close_all()
	st.Config:Open('MutedPage')
	local F = frames()
	eq(ink(F.status), rgb(DANGER), "the window's status line")
	local values = { t1 = true }
	OW:OpenDialog('Copy', {
		type = 'group', name = 'Copy',
		get = function(info) return values[info[#info]] end, set = function() end,
		args = { t1 = { order = 1, type = 'toggle', name = 'One' } },
	})
	eq(ink(OW.GetDialogFrames().status), rgb(DANGER), "the small dialog's status line")
	OW:CloseDialog()
	close_all()
end)

test("the close button's hover fill is templates.close's, its edge and cross Danger, and at rest as before", function()
	theme('thick')
	local close = st:CreateCloseButton(CreateFrame('Frame', nil, UIParent))
	stub.fire_script(close, 'OnEnter')
	eq(text(close:GetBackdropColor()), text(0.5, 0.1, 0.1), "the template's fill at its default")
	local fill = st.config.profile.templates.close.backdropcolor
	local keep = { unpack(fill) }
	fill[1], fill[2], fill[3], fill[4] = 0.2, 0.4, 0.6, 0.3
	stub.fire_script(close, 'OnLeave')
	stub.fire_script(close, 'OnEnter')
	local r, g, b, a = close:GetBackdropColor()
	eq(text(r, g, b) .. ',' .. string.format('%.2f', a), '0.20,0.40,0.60,0.30', "templates.close.backdropcolor, read at each hover (no copy of 0.5, 0.1, 0.1)")
	eq(text(close:GetBackdropBorderColor()), rgb(DANGER), 'its edge in Danger')
	eq(vertex(close.icon), rgb(DANGER), 'its cross in Danger')
	stub.fire_script(close, 'OnLeave')
	eq(vertex(close.icon), text(st.config.profile.colors.text.muted:GetRGB()), 'the cross Muted at rest')
	fill[1], fill[2], fill[3], fill[4] = unpack(keep)
end)

test('the close hover follows a changed Danger the next time it is hovered', function()
	theme('thick')
	local close = st:CreateCloseButton(CreateFrame('Frame', nil, UIParent))
	colors.danger:SetRGB(0.1, 0.9, 0.2)
	stub.fire_script(close, 'OnEnter')
	eq(text(close:GetBackdropBorderColor()), '0.10,0.90,0.20'); eq(vertex(close.icon), '0.10,0.90,0.20')
	colors.danger:SetRGB(unpack(DANGER))
end)

-- A page with a toggle, a range and a text box: the label, the knob and the field.
local STATE_PAGE = st:NewModule('StatePage')
function STATE_PAGE:GetConfigTable()
	return {
		name = 'State page', type = 'group', category = 'Frames',
		args = { general = { name = 'General', type = 'group', args = {
			section = { name = 'A section', type = 'group', inline = true, order = 1, args = {
				on = { type = 'toggle', name = 'On row', order = 1, get = function() return true end, set = function() end },
				size = { type = 'range', name = 'Size', order = 2, min = 1, max = 10, step = 1,
					get = function() return 3 end, set = function() end },
				word = { type = 'input', name = 'Word', order = 3, get = function() return 'abc' end, set = function() end },
			} },
		} } },
	}
end

local function walk(frame, out, seen)
	seen = seen or {}
	if seen[frame] then return out end
	seen[frame] = true
	for _, region in ipairs({ frame:GetRegions() }) do
		local kind = region:GetObjectType()
		if kind == 'FontString' and region:GetText() and region:GetText() ~= '' then
			out[#out + 1] = { what = 'text "' .. region:GetText() .. '"', rgb = ink(region) }
		end
	end
	for _, child in ipairs({ frame:GetChildren() }) do walk(child, out, seen) end
	return out
end

test('Text through the accessor: labels and fields in Text > Normal at an odd value, the knob too', function()
	theme('thick')
	close_all()
	st.Config:Open('StatePage')
	local F = frames()
	local seen = {}
	for _, found in ipairs(walk(F.content, {})) do seen[found.what] = found.rgb end
	eq(seen['text "On row"'], rgb(NORMAL), "a toggle's label")
	eq(seen['text "Size"'], rgb(NORMAL), "a range's label")
	eq(seen['text "Word"'], rgb(NORMAL), "an input's label")
	local knobs = 0
	for _, cell in ipairs(OW.GetDrawnRows()) do
		local slider = cell.row.key == 'size' and cell.widget and cell.widget.slider
		if slider then knobs = knobs + 1; eq(vertex(slider:GetThumbTexture()), rgb(NORMAL), "the range's knob") end
	end
	eq(knobs, 1, 'the page has one range')
	close_all()
end)

test('Text at its defaults draws what it did: Normal 0.9, 0.9, 0.8; Strong and Danger as the old White and Red', function()
	eq(text(st.defaults.colors.text.normal:GetRGB()), '0.90,0.90,0.80')
	eq(text(st.defaults.colors.text.strong:GetRGB()), '1.00,1.00,1.00')
	eq(text(st.defaults.colors.text.danger:GetRGB()), text(220/255, 100/255, 100/255))
	eq(text(st.defaults.colors.button.danger:GetRGBA()), text(0.6, 0.1, 0.1))
	eq(select(4, st.defaults.colors.button.danger:GetRGBA()), 1, 'at 100%: its opacity is drawn now')
end)
