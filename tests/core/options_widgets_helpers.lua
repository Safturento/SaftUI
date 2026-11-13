-- The world and the helpers the options widgets' tests share
-- (options_kit_test.lua, options_range_test.lua, options_select_test.lua,
-- options_list_test.lua, options_fields_test.lua, options_dialog_test.lua,
-- options_position_test.lua and options_widget_look_test.lua). A test file
-- loads it with load_test_file and takes the helpers it uses from what it
-- returns.
--
-- It loads, in the file that loads it: config_helpers.lua, lib/options_walk.lua,
-- skinning.lua (st:StripTextures, which a header uses on a button that isn't
-- SaftUI's), the model (optionsmodel.lua), the widget files Config/load.xml lists
-- (load_options_widgets) and optionsbody.lua (the position block's caption
-- font). The helpers: opt, make and bind (a synthetic option, its row, and a
-- widget bound to it), click, yes and no (the confirm dialog's buttons), the
-- text a font string shows, and the readers of what a widget draws (shown
-- textures, atlases, anchors, insets, the Blizzard theme's Box and line).
-- parent is a frame 800 x 600 at the screen's center for the widgets to be
-- placed on, so each is laid out whatever case ran before it.

load_test_file('core/config_helpers.lua')
load_test_file('lib/options_walk.lua')
local st = SaftUI
load_saftui('SaftUI-Core/skinning.lua') -- st:StripTextures, which a header uses on a button that isn't SaftUI's
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua') -- the position block's caption font
local OM, W = st.OptionsModel, st.OptionsWidgets

local function opt(otype, name, fields)
	local option = { type = otype, name = name }
	for key, value in pairs(fields or {}) do option[key] = value end
	return option
end

-- The model's row for option key in a one-page tree, and the tree.
local function make(key, option, groupFields)
	local page = { type = 'group', name = 'Page', args = { [key] = option } }
	for k, v in pairs(groupFields or {}) do page[k] = v end
	local root = { page = page }
	for _, section in ipairs(OM.BuildView(root, 'page').sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return root, row end
		end
	end
	error('no row ' .. key)
end

local parent = CreateFrame('Frame', nil, UIParent)
parent:SetSize(800, 600)
parent:SetPoint('CENTER')

-- A bound widget, with what it told the window.
local function bind(rowType, key, option, groupFields)
	local root, row = make(key, option, groupFields)
	local w = W.Create(parent, rowType)
	local told = { n = 0 }
	w:Bind(root, row, function(ok, err, dragging)
		told.n, told.ok, told.err, told.dragging = told.n + 1, ok, err, dragging
	end)
	return w, told, root, row
end

local click = stub.click

-- The text a font string shows.
local function text_of(fs) return fs:GetText() end

local function yes() click(W.GetDialogFrames().yes) end
local function no() click(W.GetDialogFrames().no) end

local function range(fields)
	local value = fields.value
	local sets = {}
	local option = opt('range', 'Amount', {
		min = fields.min, max = fields.max, softMin = fields.softMin, softMax = fields.softMax,
		step = fields.step, bigStep = fields.bigStep, isPercent = fields.isPercent,
		get = function() return value end,
		set = function(info, v) sets[#sets + 1] = v; value = v end,
	})
	local w, told = bind('range', 'amount', option)
	return w, told, sets, function() return value end
end

local function entries_of(listFrames)
	local out = {}
	for _, row in ipairs(listFrames.rows) do
		if row:IsShown() then out[#out + 1] = text_of(row.text) end
	end
	return out
end

local function type_into(box, text)
	box:SetText(text)
	stub.fire_script(box, 'OnEnterPressed')
end

-- The textures shown on a frame (shown and not see-through).
local function shown_textures(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAlpha() > 0 then
			out[#out + 1] = region
		end
	end
	return out
end

-- The panel button's pieces shown on a button, as 'Left=Up,Middle=Up,Right=Up'
-- (each piece by its left texture coordinate and the state its file is), and
-- the pieces by name ('' and none for no panel button).
local PIECE_BY_LEFT = { ['0.00000'] = 'Left', ['0.09375'] = 'Middle', ['0.53125'] = 'Right' }
local function panel_of(button)
	local out, pieces = {}, {}
	for _, region in ipairs(shown_textures(button)) do
		local file = region:GetTexture()
		local state = type(file) == 'string' and file:match('^Interface\\Buttons\\UI%-Panel%-Button%-(%a+)$')
		if state and state ~= 'Highlight' then
			local key = PIECE_BY_LEFT[('%.5f'):format((region:GetTexCoord()))] or '?'
			pieces[key] = region
			out[#out + 1] = key .. '=' .. state
		end
	end
	table.sort(out)
	return table.concat(out, ','), pieces
end

-- The atlases shown on a frame, sorted and comma-joined.
local function atlases_of(frame)
	local out = {}
	for _, region in ipairs(shown_textures(frame)) do
		if region:GetAtlas() then out[#out + 1] = region:GetAtlas() end
	end
	table.sort(out)
	return table.concat(out, ',')
end

-- Where a region's edges sit from another's, 'left,top,right,bottom', in whole pixels.
local function around(outer, inner)
	local function px(a, b) return string.format('%d', math.floor(a - b + 0.5)) end
	return table.concat({ px(outer:GetLeft(), inner:GetLeft()), px(outer:GetTop(), inner:GetTop()),
		px(outer:GetRight(), inner:GetRight()), px(outer:GetBottom(), inner:GetBottom()) }, ',')
end

local function rgba(...) return string.format('%.2f,%.2f,%.2f,%.2f', ...) end

local function theme(name) st.config.profile.theme.name = name end
local function rebind(w) w:Bind(w.root, w.row, w.onChanged) end
local FIELD_RGBA, EDGE_RGBA, BG_RGBA = rgba(unpack(st.BOX_COLORS.field)), rgba(unpack(st.BOX_COLORS.edge)), rgba(unpack(st.BOX_COLORS.bg))
local INPUT_ART = 'auctionhouse-ui-inputfield-left,auctionhouse-ui-inputfield-middle,auctionhouse-ui-inputfield-right'

-- Whether region lies inside frame's rect on screen.
local function inside(region, frame)
	local e = 0.001
	return region:GetLeft() >= frame:GetLeft() - e and region:GetRight() <= frame:GetRight() + e
		and region:GetBottom() >= frame:GetBottom() - e and region:GetTop() <= frame:GetTop() + e
end

-- Every texture shown on frame lies inside its rect: Blizzard's art is drawn
-- inside each control's own rect.
local function art_inside(frame, name)
	for _, region in ipairs(shown_textures(frame)) do
		check(inside(region, frame), name .. ': ' .. tostring(region:GetAtlas() or region:GetTexture()) .. ' inside its rect')
	end
end

-- How far in from frame's edges a region sits, 'left,top,right,bottom'.
local function insets(region, frame)
	local function px(a) return string.format('%d', math.floor(a + 0.5)) end
	return table.concat({ px(region:GetLeft() - frame:GetLeft()), px(frame:GetTop() - region:GetTop()),
		px(frame:GetRight() - region:GetRight()), px(region:GetBottom() - frame:GetBottom()) }, ',')
end

-- The shown texture of frame whose atlas starts with prefix.
local function atlas_piece(frame, prefix)
	for _, region in ipairs(shown_textures(frame)) do
		local atlas = region:GetAtlas()
		if atlas and atlas:sub(1, #prefix) == prefix then return region end
	end
end

-- frame wears Box: the field's fill (or fill), the edge, and the dark line.
-- anyEdge for a box whose edge may be lit (focused, or left lit by an
-- earlier case's pooled widget).
local function check_box(frame, name, fill, anyEdge)
	check(frame.backdropInfo ~= nil, name .. ': its own box')
	eq(rgba(frame:GetBackdropColor()), fill or FIELD_RGBA, name .. ': its own fill')
	if not anyEdge then eq(rgba(frame:GetBackdropBorderColor()), EDGE_RGBA, name .. ': its own edge') end
	check(frame.outline:IsShown(), name .. ': its dark line')
end

-- frame's Box is off, for Blizzard's art.
local function check_no_box(frame, name)
	eq(frame.backdropInfo, nil, name .. ': its own box off')
	check(not frame.outline:IsShown(), name .. ': and its dark line')
end

-- frame is a 1px line in the Blizzard theme's Border around its Background.
local function check_line(frame, name)
	local colors = st.config.profile.templates.blizzard
	check(frame.backdropInfo ~= nil, name .. ': a backdrop')
	eq(frame.backdropInfo and frame.backdropInfo.edgeSize, 1, name .. ': a 1px line')
	eq(frame.backdropInfo and frame.backdropInfo.insets.left, 1, name .. ': the fill inside it')
	eq(rgba(frame:GetBackdropBorderColor()), rgba(unpack(colors.bordercolor)), name .. ": in the Blizzard theme's Border")
	eq(rgba(frame:GetBackdropColor()), rgba(unpack(colors.backdropcolor)), name .. ': around its Background')
	if frame.outline then check(not frame.outline:IsShown(), name .. ': no dark line') end
end

local function size_of(frame) return frame:GetWidth() .. 'x' .. frame:GetHeight() end

-- The shown texture of frame showing exactly atlas.
local function atlas_exact(frame, atlas)
	for _, region in ipairs(shown_textures(frame)) do
		if region:GetAtlas() == atlas then return region end
	end
end

-- A region's first anchor, 'POINT to POINT x,y', its frame named by names.
local function anchor(region, names)
	local point, rel, relPoint, x, y = region:GetPoint(1)
	return string.format('%s %s %s %d,%d', point, names[rel] or tostring(rel), relPoint, x, y)
end

return {
	click = click,
	bind = bind,
	opt = opt,
	no = no,
	yes = yes,
	parent = parent,
	make = make,
	text_of = text_of,
	range = range,
	check_no_box = check_no_box,
	shown_textures = shown_textures,
	check_box = check_box,
	rebind = rebind,
	art_inside = art_inside,
	theme = theme,
	INPUT_ART = INPUT_ART,
	atlases_of = atlases_of,
	inside = inside,
	size_of = size_of,
	anchor = anchor,
	type_into = type_into,
	entries_of = entries_of,
	around = around,
	atlas_exact = atlas_exact,
	atlas_piece = atlas_piece,
	insets = insets,
	check_line = check_line,
	BG_RGBA = BG_RGBA,
	rgba = rgba,
	panel_of = panel_of,
}
