-- Misc's skins draw their interaction states through the states helpers (the
-- interaction states plan, Task 8; SaftUI-Core/Widgets/states.lua), not by hand:
--   - the color picker skin's Okay and Cancel: the hover is a Layer inside SaftUI's
--     box (a 'box' record, hosted on the box), said by post-hooks on Blizzard's
--     buttons; the edge is no longer the hover. The hex box's focus is the Accent
--     edge (was white);
--   - Blizzard's tracker's quest item: its own HIGHLIGHT texture, BLEND at the
--     derived hover (an 'icon' record with `pieces`); the ADD blend is gone;
--   - RestedXP's steps: the row Layer (SaftUI's texture) at the derived hover, shown by
--     RestedXP's own SetBackdropColor hook (the header strip color is gone).
-- Under the Blizzard theme the skins' pieces are left alone. Nothing is written onto
-- Blizzard's frames: records live in the helper's weak tables (the skins' own tests lock
-- every Blizzard widget).
-- Real: SaftUI-Misc's config, Skinning and the three skins, Core's helpers, theme
-- engine and states; Blizzard's frames from the fixtures.
local T = load_test_file('lib/theme_helpers.lua')
local SL = load_test_file('lib/states_look.lua')

local function hover_bytes(st) local h = { st:StateColor('hover') } return SL.bytes({ r = h[1], g = h[2], b = h[3] }) end

------------------------------------------------------------------ the color picker

local st, profile, SK, CP

local function cp_world(client)
	st = T.client(client)
	_G.ColorPickerFrame = nil
	T.watch()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua')
	SK = st:GetModule('Skinning')
	CP = load_test_file('misc/fixtures/color_picker.lua')
	CP.build({ forever = client == 'forever' })
	SK:Enable()
end

local function boxes_of(frame)
	local out = {}
	for _, child in ipairs({ frame:GetChildren() }) do
		local known = false
		for _, w in ipairs(CP.widgets or {}) do if w == child then known = true end end
		if not known then out[#out + 1] = child end
	end
	return out
end

local function switch(name)
	T.theme(name, function()
		SK:UpdateConfig()
		st:ColorsChanged('theme')
	end)
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test("the color picker's Okay and Cancel tint under the mouse on SaftUI's box; the hex box's focus is the Accent [" .. client .. ']', function()
		cp_world(client)
		for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
			local button = CP.frame.Footer[key]
			local box = boxes_of(button)[1]
			check(box ~= nil, key .. ': SaftUI\'s box')
			local look = st:StateLook(box)
			eq(look.shape, 'box', key .. ': a box record, hosted on SaftUI\'s box (nothing is written onto Blizzard\'s button)')
			check(st:GetState(button, 'hover') == nil, key .. ': Blizzard\'s button has no record')
			check(not look.layer.shown, key .. ': no tint at rest')
			local edge = look.edge
			stub.fire_script(button, 'OnEnter', true)
			look = st:StateLook(box)
			check(look.layer.shown, key .. ': tinted under the mouse')
			eq(look.layer.blend, 'BLEND', key .. ': BLEND')
			eq(SL.bytes(look.layer), hover_bytes(st), key .. ': the derived hover')
			eq(('%.2f'):format(look.layer.a), '0.16', key .. ': at 16%')
			eq(look.edge.r .. look.edge.g .. look.edge.b, edge.r .. edge.g .. edge.b, key .. ': the edge is not the hover (the body changes)')
			check(look.pieces.layer:GetParent() == box, key .. ': the Layer is on SaftUI\'s box, under the label')
			check(box:GetFrameLevel() < button:GetFrameLevel(), key .. ': the box is below the button, so its label is over the tint')
			stub.fire_script(button, 'OnLeave', true)
			check(not st:StateLook(box).layer.shown, key .. ': gone on leave')
		end
		-- the hex box: focus is the Accent edge
		local hex = CP.frame.Content.HexBox
		local backdrop = boxes_of(hex)[1]
		local rest = st:StateLook(backdrop).edge
		hex:SetFocus()
		stub.fire_script(hex, 'OnEditFocusGained')
		check(st:GetState(backdrop, 'focus'), 'the hex box: focus')
		local accent = profile.theme.accent
		eq(SL.bytes(st:StateLook(backdrop).edge), SL.bytes(accent), 'the edge is the Accent itself, not white')
		profile.theme.accent:SetRGB(0.9, 0.2, 0.4)
		st:ColorsChanged('accent')
		eq(SL.bytes(st:StateLook(backdrop).edge), SL.bytes({ r = 0.9, g = 0.2, b = 0.4 }), 'and follows a change of it')
		profile.theme.accent:SetRGB(0, 0.68, 0.94)
		st:ColorsChanged('accent')
		hex:ClearFocus()
		stub.fire_script(hex, 'OnEditFocusLost')
		eq(SL.rgb(st:StateLook(backdrop).edge), SL.rgb(rest), 'the rest edge back')
		-- under the Blizzard theme: the skin is off, nothing tints or focuses
		switch('blizzard')
		local button = CP.frame.Footer.OkayButton
		stub.fire_script(button, 'OnEnter', true)
		check(not st:StateLook(boxes_of(button)[1]).layer.shown, 'Blizzard theme: no tint on the hidden box')
		stub.fire_script(button, 'OnLeave', true)
		hex:SetFocus()
		stub.fire_script(hex, 'OnEditFocusGained')
		check(not st:GetState(backdrop, 'focus'), 'Blizzard theme: no focus on the hidden backdrop')
		eq(#take_errors(), 0, 'no errors')
		eq(table.concat(CP.stray, ','), '', 'SaftUI ran none of the picker\'s own functions')
	end)
end

------------------------------------------------------------------ Blizzard's tracker's quest item

local OT, ot_skin

local function ot_world(client)
	st = T.client(client)
	T.watch()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua')
	SK = st:GetModule('Skinning')
	ot_skin = SK:GetModule('Blizzard_ObjectiveTracker')
	OT = load_test_file('misc/fixtures/objective_tracker.lua')
	OT.build()
	SK:Enable()
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test("Blizzard's tracker's quest item: a BLEND tint at 0.16 in its own HIGHLIGHT texture [" .. client .. ']', function()
		ot_world(client)
		local blocks = OT.layout(OT.modules.QuestObjectiveTracker, { { id = 1, objectives = { 'One' }, item = 3 } })
		local item = blocks[1].rightEdgeFrame
		local hover
		for _, region in ipairs({ item:GetRegions() }) do
			if not OT.is_blizzard(region) and region:GetDrawLayer() == 'HIGHLIGHT' then hover = region end
		end
		check(hover ~= nil, 'its own hover texture')
		local look = st:StateLook(item)
		eq(look.shape, 'icon', 'an icon record (the item is Blizzard\'s, the record is in a weak table)')
		check(look.pieces.hover == hover, 'the pieces are that texture')
		eq(hover:GetBlendMode(), 'BLEND', 'BLEND, not ADD')
		eq(('%.2f'):format(select(4, hover:GetVertexColor())), '0.16', 'at 0.16')
		eq(SL.bytes(look.hover_piece), hover_bytes(st), 'the derived hover')
		check(item:GetHighlightTexture() ~= hover, 'never handed to SetHighlightTexture')
		-- the Blizzard theme: Blizzard's look back, the hover hidden
		T.theme('blizzard', function() SK:UpdateConfig() st:ColorsChanged('theme') end)
		check(not hover:IsShown(), 'Blizzard theme: the tint is hidden')
		T.theme('thick', function() SK:UpdateConfig() st:ColorsChanged('theme') end)
		check(hover:IsShown(), 'and back')
		eq(hover:GetBlendMode(), 'BLEND', 'BLEND after a round trip')
		eq(#take_errors(), 0, 'no errors')
		eq(table.concat(OT.stray, ','), '', "SaftUI ran none of the tracker's state-writing methods")
	end)
end

------------------------------------------------------------------ RestedXP's steps

test("RestedXP's steps: the hover tint in the tone, shown by RestedXP's own SetBackdropColor [rested]", function()
	local H = load_test_file('misc/restedxp_helpers.lua')
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = H.RXP.make()
	H.get_rx():OnEnable()
	R.LoadGuide(3)
	local f = R.ScrollChild.framePool[2]
	local s = SaftUI
	local look = s:StateLook(f)
	eq(look.shape, 'row', 'a row record on the step (RestedXP\'s frame; the record is in a weak table)')
	local layer = look.pieces.layer
	check(not layer:IsShown(), 'hidden at rest')
	eq(look.layer.blend, 'BLEND', 'BLEND')
	H.cursor_on(f)
	stub.fire_script(f, 'OnEnter')
	look = s:StateLook(f)
	check(look.layer.shown, 'shown on enter, by the SetBackdropColor hook')
	eq(SL.bytes(look.layer), hover_bytes(s), 'the derived hover, not the header strip color')
	eq(('%.2f'):format(look.layer.a), '0.16', 'at 16%')
	-- not wired: the step\'s scripts are RestedXP\'s and are replaced on every guide load
	H.cursor_off()
	stub.fire_script(f, 'OnLeave')
	check(not s:StateLook(f).layer.shown, 'hidden on leave')
	-- a change of the Accent reaches a hovered step
	H.cursor_on(f)
	stub.fire_script(f, 'OnEnter')
	local accent = s.config.profile.theme.accent
	accent:SetRGB(0.9, 0.2, 0.4)
	s:ColorsChanged('accent')
	eq(SL.bytes(s:StateLook(f).layer), hover_bytes(s), 'follows the Accent')
	accent:SetRGB(0, 0.68, 0.94)
	s:ColorsChanged('accent')
	-- a reload makes no second record or Layer
	local regions = #{ f:GetRegions() }
	R.LoadGuide(5)
	R.LoadGuide(3)
	eq(#{ R.ScrollChild.framePool[2]:GetRegions() }, regions, 'a guide reload adds no texture')
	eq(#take_errors(), 0, 'no errors')
end)
