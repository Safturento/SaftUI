local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's range widget (st.OptionsWidgets,
	optionswidgets.lua): a slider and its value box, and the numbers it
	snaps and shows.
]]

local floor, max, min = math.floor, math.max, math.min
local format = string.format

local Box, Edge, HoverStates, BlizzardLook, AtlasSize = W.Box, W.Edge, W.HoverStates, W.BlizzardLook, W.AtlasSize
local FIELD_HEIGHT, Base, builders, define = Kit.FIELD_HEIGHT, Kit.Base, Kit.builders, Kit.define
local ALT, EDGE, FIELD, Art, Changes = Kit.ALT, Kit.EDGE, Kit.FIELD, Kit.Art, Kit.Changes
local HidePieces, LayThree, LookInput = Kit.HidePieces, Kit.LayThree, Kit.LookInput

local TRACK_WIDTH, VALUE_WIDTH, GAP = 116, 46, 6

------------------------------------------------------------------ numbers

-- Strips float drift (0.1 * 3 is 0.30000000000000004).
local function Tidy(value)
	return tonumber(format('%.10g', value))
end

-- value on min's grid of step (no grid for a step of 0).
local function Snap(value, minimum, step)
	if step and step > 0 then
		value = floor((value - minimum) / step + 0.5) * step + minimum
	end
	return Tidy(value)
end

-- A number as the value box shows it: 0.065, 12, 33.5.
local function Shown(value, percent)
	if percent then value = value * 100 end
	return tostring(tonumber(format('%.6g', value)))
end

------------------------------------------------------------------ range

local KNOB_WIDTH, KNOB_HEIGHT = 6, 14
Kit.KNOB_WIDTH, Kit.KNOB_HEIGHT = KNOB_WIDTH, KNOB_HEIGHT -- read by the color picker's preview (optionspreview.lua)

-- The range's look, when it changed: its flat track and knob, or Blizzard's
-- minimal slider (st.ThemeArt.Control('slider')): the track's ends and
-- middle at their atlas's height across the slider's middle, and the thumb
-- at its atlas's size, under which the slider centres it. Its value box is
-- a text box (LookInput).
local function LookRange(w, blizzard)
	w.fill:SetColorTexture(st:Color('accent'):GetRGB()) -- at each bind, so a pooled slider follows the accent
	local art = Art(w.slider)
	if Changes(art, blizzard) then
		for _, texture in ipairs(w.flat) do texture:SetShown(not blizzard) end
		local knob = w.slider:GetThumbTexture()
		if blizzard then
			local look = st.ThemeArt.Control('slider')
			local _, height = AtlasSize(look.middle)
			LayThree(art, w.slider, look, 'BACKGROUND', height or FIELD_HEIGHT, '')
			knob:SetAtlas(look.thumb)
			local width, thumbHeight = AtlasSize(look.thumb)
			if width then knob:SetSize(width, thumbHeight) end
			knob:SetVertexColor(1, 1, 1, 1)
		else
			HidePieces(art)
			knob:SetTexture(st.BLANK_TEX)
			knob:SetTexCoord(0, 1, 0, 1)
			knob:SetSize(KNOB_WIDTH, KNOB_HEIGHT)
		end
		-- the slider's own atlas under Blizzard, else the knob's rest color (Text > Normal), the helper's
		w.slider.blizzard = blizzard
		st:RestyleStates(w.slider)
		st:PaintStates(w.slider)
	end
	-- The slider between the arrows (Blizzard), else across the whole 116.
	local look = blizzard and st.ThemeArt.Control('slider')
	w.slider:ClearAllPoints()
	if blizzard then
		local backWidth, backHeight = AtlasSize(look.back)
		local forwardWidth, forwardHeight = AtlasSize(look.forward)
		local left = (backWidth or 0) + look.arrowGap
		local width = TRACK_WIDTH - left - look.arrowGap - (forwardWidth or 0)
		w.slider:SetPoint('LEFT', w.frame, 'LEFT', left, 0)
		w.slider:SetSize(width, FIELD_HEIGHT)
		for _, arrow in ipairs({ { w.backArrow, look.back, 0 }, { w.forwardArrow, look.forward, left + width + look.arrowGap } }) do
			local button, atlas, x = arrow[1], arrow[2], arrow[3]
			local aw, ah = AtlasSize(atlas)
			button:SetSize(aw or 0, ah or 0)
			button:ClearAllPoints()
			-- Each arrow's top is centred in the row, rounded down on whole pixels.
			button:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', x, -floor((FIELD_HEIGHT - (ah or 0)) / 2))
			button.texture:SetAtlas(atlas)
		end
	else
		w.slider:SetPoint('LEFT', w.frame, 'LEFT', 0, 0)
		w.slider:SetSize(TRACK_WIDTH, FIELD_HEIGHT)
	end
	w.backArrow:SetShown(blizzard)
	w.forwardArrow:SetShown(blizzard)
	LookInput(w.edit, blizzard, FIELD_HEIGHT)
end

builders.range = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(TRACK_WIDTH + GAP + VALUE_WIDTH, FIELD_HEIGHT)
	w.frame = frame

	local slider = CreateFrame('Slider', nil, frame)
	slider:SetOrientation('HORIZONTAL')
	slider:SetSize(TRACK_WIDTH, FIELD_HEIGHT)
	slider:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	slider:EnableMouse(true)
	slider:SetObeyStepOnDrag(true)
	w.slider = slider

	-- The track is the slider's own textures, under the knob by draw layer. A
	-- child frame put under it by frame level drew over it in game once the
	-- widget was reparented (that moves children back above their parent).
	-- A box's look: the dark line outside, the edge, the field inside it.
	local outline = slider:CreateTexture(nil, 'BACKGROUND')
	outline:SetColorTexture(unpack(ALT))
	outline:SetPoint('LEFT', slider, 'LEFT', -1, 0)
	outline:SetSize(TRACK_WIDTH + 2, 8)
	local track = slider:CreateTexture(nil, 'BORDER', nil, 0)
	track:SetColorTexture(unpack(EDGE))
	track:SetPoint('LEFT', slider, 'LEFT', 0, 0)
	track:SetSize(TRACK_WIDTH, 6)
	w.track = track
	local inside = slider:CreateTexture(nil, 'BORDER', nil, 1)
	inside:SetColorTexture(unpack(FIELD))
	inside:SetPoint('TOPLEFT', track, 'TOPLEFT', 1, -1)
	inside:SetPoint('BOTTOMRIGHT', track, 'BOTTOMRIGHT', -1, 1)
	local fill = slider:CreateTexture(nil, 'ARTWORK')
	fill:SetColorTexture(st:Color('accent'):GetRGB())
	fill:SetPoint('TOPLEFT', track, 'TOPLEFT', 1, -1)
	fill:SetPoint('BOTTOMLEFT', track, 'BOTTOMLEFT', 1, 1)
	fill:SetWidth(1)
	w.fill = fill

	-- The flat track, hidden under Blizzard (LookRange).
	w.flat = { outline, track, inside, fill }

	slider:SetThumbTexture(st.BLANK_TEX)
	local knob = slider:GetThumbTexture()
	knob:SetDrawLayer('OVERLAY')
	knob:SetSize(KNOB_WIDTH, KNOB_HEIGHT)
	knob:SetVertexColor(st:Color('text', 'normal'):GetRGB())
	-- The end arrows, hidden until Blizzard's look (LookRange): each a button
	-- of the frame's with its art as a texture, in colour while it can step
	-- and desaturated while it can't (RangeArrows).
	for key, direction in pairs({ backArrow = -1, forwardArrow = 1 }) do
		local arrow = CreateFrame('Button', nil, frame)
		arrow.texture = arrow:CreateTexture(nil, 'ARTWORK')
		arrow.texture:SetAllPoints(arrow)
		arrow:Hide()
		arrow:SetScript('OnClick', function() w:StepBy(direction) end)
		w[key] = arrow
	end

	local edit = Box(st:CreateFrame('EditBox', nil, frame))
	edit:SetSize(VALUE_WIDTH, FIELD_HEIGHT)
	edit:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH('CENTER')
	edit:SetTextInsets(2, 2, 0, 0)
	edit:SetAutoFocus(false)
	w.edit = edit

	slider:SetScript('OnValueChanged', function(_, value)
		if w.updating or not w.row or w.disabled then return end
		-- A click on the track moves the slider before OnMouseDown runs, so a
		-- held button already means a drag: the window mustn't re-render (and
		-- take this slider away) until it's let go.
		if IsMouseButtonDown('LeftButton') then w.dragging = true end
		w:Dragged(value)
	end)
	slider:SetScript('OnMouseDown', function() w.dragging = true end)
	slider:SetScript('OnMouseUp', function()
		local changed, pending = w.dirty, w.pending
		w.dragging, w.dirty, w.pending = nil, nil, nil
		if pending ~= nil then
			-- applyOnRelease: the one set of the drag, with the value shown, if
			-- it differs from the setting (a drag that came back sets nothing).
			if not w.row then return end
			if pending ~= w:Number() then w:Commit(pending) else w:Refresh() end
		elseif changed and w.onChanged then
			w.onChanged(true)
		end
	end)

	-- A knob: the rest color is Text > Normal, the helper's Solid under the mouse and while
	-- dragged (the slider's own scripts are set just above: the helper hooks after them).
	st:AddStates(slider, 'knob', {
		solid = slider:GetThumbTexture(), solidRest = function() return st:Color('text', 'normal'):GetRGB() end,
		blizzard = function(self) return self.blizzard == true end,
	})
	Kit.Track(w, slider)

	edit:SetScript('OnEnterPressed', function(self)
		if not w.row then return end
		local text = self:GetText():gsub('%%', ''):gsub('^%s+', ''):gsub('%s+$', '')
		local number = tonumber(text)
		if number then w:Typed(number) else w:Refresh() end
		self:ClearFocus()
	end)
	edit:SetScript('OnEscapePressed', function(self)
		w:Refresh()
		self:ClearFocus()
	end)
	edit:SetScript('OnEditFocusGained', function(self)
		Edge(self, true)
		self:HighlightText(0, -1)
	end)
	edit:SetScript('OnEditFocusLost', function(self)
		Edge(self, false)
		w:Refresh()
	end)
	HoverStates(edit, function() return w.disabled end)
	Kit.Track(w, edit)
end

-- Enables the end arrows: each while there's room to step that way from the
-- shown value (the value, else the slider's low end) and the range isn't
-- disabled; a disabled one is desaturated.
local function RangeArrows(w)
	if not w.softMin then return end
	local shown = w.value or w.softMin
	local back = not w.disabled and shown > w.softMin
	local forward = not w.disabled and shown < w.softMax
	w.backArrow:SetEnabled(back)
	w.forwardArrow:SetEnabled(forward)
	w.backArrow.texture:SetDesaturated(not back)
	w.forwardArrow.texture:SetDesaturated(not forward)
end

-- Shows a value without setting it: the box, the fill and the arrows. The
-- slider's own knob is where the mouse has it (or Refresh puts it).
local function Show(w, value)
	w.value = value
	local span = w.softMax - w.softMin
	local fraction = span > 0 and max(0, min(1, (value - w.softMin) / span)) or 0
	w.fill:SetWidth(max(1, (TRACK_WIDTH - 2) * fraction))
	w.edit:SetText(Shown(value, w.percent) .. (w.percent and '%' or ''))
	RangeArrows(w)
end

define('range', {
	Bind = function(self, ...)
		self.pending = nil -- a pooled widget released mid-drag keeps nothing
		LookRange(self, BlizzardLook())
		return Base.Bind(self, ...)
	end,

	-- The setting's value, a number or nil (the shown one may be a pending drag).
	Number = function(self)
		local value = self:Value()
		return type(value) == 'number' and value or nil
	end,

	-- The slider's ends (softMin and softMax, else min and max, as
	-- AceConfigDialog gives them), and the hard limits typed numbers get cut to.
	Limits = function(self)
		local root, row = self.root, self.row
		local min_, max_ = OM.Member(root, row, 'min'), OM.Member(root, row, 'max')
		local softMin, softMax = OM.Member(root, row, 'softMin'), OM.Member(root, row, 'softMax')
		local step, bigStep = OM.Member(root, row, 'step'), OM.Member(root, row, 'bigStep')
		self.softMin, self.softMax = softMin or min_ or 0, softMax or max_ or 100
		self.hardMin = min_ or (not softMin and 0 or nil)
		self.hardMax = max_ or (not softMax and 100 or nil)
		self.step, self.dragStep = step or 0, bigStep or step or 0
		self.percent = OM.Member(root, row, 'isPercent') and true or false
	end,

	-- The hard limits, as AceConfigDialog's ActivateSlider cuts a value.
	Cut = function(self, value)
		if self.hardMin then value = max(value, self.hardMin) end
		if self.hardMax then value = min(value, self.hardMax) end
		return value
	end,

	-- The slider moved by the user: snapped to bigStep (or step) while
	-- dragging. With SaftUI's applyOnRelease a drag only shows the value
	-- (the box, the fill, the arrows) and the mouse button coming up sets it
	-- once; a move with no button down (the keys, the wheel) sets at once.
	Dragged = function(self, value)
		value = self:Cut(Snap(value, self.softMin, self.dragStep))
		if value == self.value then return end
		if self.dragging then self.dirty = true end
		if self.dragging and OM.Member(self.root, self.row, 'applyOnRelease') then
			self.pending = value
			Show(self, value)
			return
		end
		self:Commit(value)
	end,

	-- An arrow's click: a step back (-1) or forward (1) from the shown value,
	-- by step, else bigStep, else a hundredth of the span, snapped on
	-- softMin's grid of that step, held to the slider's ends, then cut to min
	-- and max. It commits as a drag does, and only a changed value.
	StepBy = function(self, direction)
		if not self.row or self.disabled then return end
		local by = self.step > 0 and self.step or self.dragStep > 0 and self.dragStep or (self.softMax - self.softMin) / 100
		if by <= 0 then return end
		local value = Snap((self.value or self.softMin) + direction * by, self.softMin, by)
		value = self:Cut(max(self.softMin, min(self.softMax, value)))
		if value == self.value then return end
		self:Commit(value)
	end,

	-- A number typed in the box: cut to the slider's ends first, then snapped
	-- to step and cut to min and max.
	Typed = function(self, number)
		if self.percent then number = number / 100 end
		number = max(self.softMin, min(self.softMax, number))
		number = self:Cut(Snap(number, self.hardMin or self.softMin, self.step))
		self:Commit(number)
	end,

	Refresh = function(self)
		self:Limits()
		local value = self:Value()
		self.value = type(value) == 'number' and value or nil
		local shown = self.value or self.softMin
		self.updating = true
		self.slider:SetMinMaxValues(self.softMin, self.softMax)
		-- Always set (AceGUI's SetSliderValues does): a pooled slider keeps its last row's step.
		self.slider:SetValueStep(self.dragStep)
		self.slider:SetValue(max(self.softMin, min(self.softMax, shown)))
		self.updating = false
		local span = self.softMax - self.softMin
		local fraction = span > 0 and max(0, min(1, (shown - self.softMin) / span)) or 0
		self.fill:SetWidth(max(1, (TRACK_WIDTH - 2) * fraction))
		self.edit:SetText(self.value and (Shown(self.value, self.percent) .. (self.percent and '%' or '')) or '')
		RangeArrows(self)
	end,

	OnDisabled = function(self, disabled)
		RangeArrows(self)
		self.slider:EnableMouse(not disabled)
		self.edit:EnableMouse(not disabled)
		if disabled then self.edit:ClearFocus() end
	end,
})
