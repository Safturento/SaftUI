local st = SaftUI
local EM = st.EditModeFrames
local W, OB = st.OptionsWidgets, st.OptionsBody

--[[
	The edit mode bar's controls for what shows (filter.lua has the rule):
	  show    (left, 30, section 'show')  the caption "Show", Show disabled and
	                                      Show hidden (icon buttons, on while
	                                      the setting is), and the module list's
	                                      face
	  filter  (left, 40, section 'show')  the filter box
	Each control is { key, frame, Lay, Refresh, Look } as bar.lua says; a
	control reads its stage in Lay and ignores the others (the caption is gone
	from stage 2, the face is narrower from 3, the filter is narrower from 1
	and gone at 5; floating, each has its own width). Clicks go through
	EM.BarGuard (nothing in combat), as bargroups.lua's do; an icon says
	nothing, so its tooltip does.

	The filter box is the kit's input with a search glass: Lucide's, 6 in at its
	left, with the text inset past it; under Blizzard it is the search box's
	art (W.LookSearch), whose own glass replaces the Lucide one. It lets go of
	the keyboard when a mover is pressed or dragged and when edit mode closes,
	so the arrow keys keep nudging; Enter selects the first match (and lets
	go), Esc clears the text and lets go.
]]

local FIELD_HEIGHT = W.Kit.FIELD_HEIGHT
local Guard = EM.BarGuard
local ceil = math.ceil

local GLASS, GLASS_LEFT, GLASS_GAP, TEXT_RIGHT = 16, 6, 4, 8
local CAPTION_HEIGHT = 16

------------------------------------------------------------------ the caption

local function Caption(bar)
	local frame = st:CreateFrame('Frame', nil, bar)
	frame:SetHeight(CAPTION_HEIGHT)
	local text = OB.Text(frame, 'caption', 'LEFT')
	text:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	text:SetText('Show')
	frame.text = text
	return {
		key = 'caption', frame = frame,
		-- Gone from stage 2, and in the floating window (its section has a title).
		Lay = function(_, stage, floating)
			if floating or stage >= 2 then return 0 end
			local width = ceil(text:GetStringWidth())
			frame:SetWidth(width)
			return width
		end,
		Look = function() text:SetTextColor(OB.Grey()) end,
	}
end

------------------------------------------------------------------ the module list

-- Opens the check list under the face: a row for each module with a mover, a
-- click applies at once and the list stays open, and All and None under it.
local function OpenModules(face)
	local entries = {}
	for _, name in ipairs(EM:GetModules()) do entries[#entries + 1] = { key = name, label = name } end
	W.OpenCheckList(face, entries,
		function(name) return EM:IsModuleShown(name) end,
		function(name) EM:SetModuleShown(name, not EM:IsModuleShown(name)) end,
		{
			{ label = 'All', onClick = function() EM:SetAllModulesShown(true) end },
			{ label = 'None', onClick = function() EM:SetAllModulesShown(false) end },
		})
end

local function Modules(bar)
	local face = W.SelectFace(bar, 150, nil)
	face.onClick = Guard(function() OpenModules(face) end)
	return {
		key = 'modules', frame = face,
		Lay = function(_, stage, floating)
			local width = floating and 140 or stage >= 3 and 110 or 150
			face:SetWidth(width)
			return width
		end,
		Look = function(_, blizzard) W.LookSelectFace(face, blizzard) end,
		Refresh = function()
			face.text:SetText(EM.ShowFaceText(EM:GetModules(), function(name) return EM:IsModuleShown(name) end))
		end,
	}
end

------------------------------------------------------------------ the filter

local function Filter(bar)
	local box = W.Box(st:CreateFrame('EditBox', nil, bar))
	box:SetSize(150, FIELD_HEIGHT)
	box:SetFontObject(W.GetFont())
	box:SetAutoFocus(false)

	box.icon = box:CreateTexture(nil, 'OVERLAY')
	box.icon:SetTexture(st.icons.search)
	box.icon:SetSize(GLASS, GLASS)
	box.icon:SetPoint('TOPLEFT', box, 'TOPLEFT', GLASS_LEFT, -math.floor((FIELD_HEIGHT - GLASS) / 2))
	box.hint = OB.Text(box, 'field')
	box.hint:SetText('Filter movers...')

	local function ShowHint()
		box.hint:SetShown(box:GetText() == '' and not box:HasFocus())
	end
	box:SetScript('OnEnter', function(self) W.Edge(self, true) end)
	box:SetScript('OnLeave', function(self) W.Edge(self, self:HasFocus()) end)
	box:SetScript('OnEditFocusGained', function(self)
		W.Edge(self, true)
		ShowHint()
	end)
	box:SetScript('OnEditFocusLost', function(self)
		W.Edge(self, false)
		ShowHint()
	end)
	box:SetScript('OnTextChanged', function(self)
		EM:SetFilter(self:GetText())
		ShowHint()
	end)
	box:SetScript('OnEnterPressed', Guard(function(self)
		EM:SelectFirstMatch()
		self:ClearFocus()
	end))
	box:SetScript('OnEscapePressed', function(self)
		self:SetText('')
		self:ClearFocus()
	end)

	-- Keyboard back to edit mode's catcher: the arrow keys nudge again.
	local function Drop() box:ClearFocus() end
	EM:On('Pressed', Drop)
	EM:On('DragStarted', Drop)
	EM:On('Disabled', function()
		Drop()
		box:SetText('') -- the filter is for this session of edit mode
	end)

	return {
		key = 'filter', frame = box,
		Lay = function(_, stage, floating)
			local width = floating and 140 or stage >= 5 and 0 or stage >= 1 and 100 or 150
			if width > 0 then box:SetWidth(width) end
			return width
		end,
		Look = function(_, blizzard)
			-- Blizzard's art carries its own glass; the text starts clear of it.
			local left = W.LookSearch(box, blizzard, FIELD_HEIGHT) or GLASS_LEFT + GLASS + GLASS_GAP
			box.icon:SetShown(not blizzard)
			box.icon:SetVertexColor(OB.Grey())
			box.hint:SetTextColor(OB.Grey())
			box:SetTextInsets(left, TEXT_RIGHT, 0, 0)
			box.hint:ClearAllPoints()
			box.hint:SetPoint('LEFT', box, 'LEFT', left, 0)
		end,
		Refresh = ShowHint,
	}
end

------------------------------------------------------------------ the groups

EM:AddBarGroup({
	key = 'show', order = 30, side = 'left', section = 'show',
	controls = function(bar)
		return {
			Caption(bar),
			EM.BarToggle(bar, 'showDisabled', st.icons.powerOff, 'show_disabled', 'Show disabled',
				"Shows the movers of frames you've turned off."),
			EM.BarToggle(bar, 'showHidden', st.icons.eye, 'show_hidden', 'Show hidden',
				"Shows the movers of frames that aren't on screen right now: closed bags, no pet, no boss."),
			Modules(bar),
		}
	end,
})

EM:AddBarGroup({
	key = 'filter', order = 40, side = 'left', section = 'show',
	controls = function(bar) return { Filter(bar) } end,
})
