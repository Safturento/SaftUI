local st = SaftUI
local EM = st.EditModeFrames
local W, OB = st.OptionsWidgets, st.OptionsBody

--[[
	The edit mode bar's controls for what shows (filter.lua has the rule):
	  show    (left, 30, row 2, section 'show')  Show disabled and Show hidden
	                                             (icon buttons, on while the
	                                             setting is), the module list's
	                                             face and the filter box
	Each control is { key, frame, Lay, Refresh, Look } as bar.lua says; the face
	and the filter are 150 wide on the bar and 140 in the floating window. Clicks
	go through EM.BarGuard (nothing in combat), as bargroups.lua's do; an icon
	says nothing, so its tooltip does.

	The filter box is the kit's input with a search glass: Lucide's, 6 in at its
	left, with the text inset past it; under Blizzard it is the search box's
	art (W.LookSearch), whose own glass replaces the Lucide one. It lets go of
	the keyboard when a mover is pressed or dragged and when edit mode closes,
	so the arrow keys keep nudging; Enter selects the first match (and lets
	go), Esc clears the text and lets go.
]]

local FIELD_HEIGHT = W.Kit.FIELD_HEIGHT
local Guard = EM.BarGuard

local GLASS, GLASS_LEFT, GLASS_GAP, TEXT_RIGHT = 16, 6, 4, 8

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
	face.tip = function() return 'Show', { "Which modules' movers edit mode shows." } end
	return {
		key = 'modules', frame = face,
		Lay = function(_, floating)
			local width = floating and 140 or 150
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
	box:SetScript('OnEnter', function(self)
		W.Edge(self, true)
		W.ShowTip(self, 'Filter movers',
			{ 'Shows only the movers whose name has this text. Enter selects the first one, Esc clears it.' })
	end)
	box:SetScript('OnLeave', function(self)
		W.Edge(self, self:HasFocus())
		W.HideTip(self)
	end)
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
		Lay = function(_, floating)
			local width = floating and 140 or 150
			box:SetWidth(width)
			return width
		end,
		Look = function(_, blizzard)
			-- Blizzard's art carries its own glass; the text starts clear of it.
			local left = W.LookSearch(box, blizzard, FIELD_HEIGHT) or GLASS_LEFT + GLASS + GLASS_GAP
			box.icon:SetShown(not blizzard)
			box.icon:SetVertexColor(OB.Muted())
			box.hint:SetTextColor(OB.Muted())
			box:SetTextInsets(left, TEXT_RIGHT, 0, 0)
			box.hint:ClearAllPoints()
			box.hint:SetPoint('LEFT', box, 'LEFT', left, 0)
			box.hint:SetPoint('RIGHT', box, 'RIGHT', -TEXT_RIGHT, 0)
		end,
		-- A color pass: the glass and the hint, not the insets or the points.
		Recolor = function()
			box.icon:SetVertexColor(OB.Muted())
			box.hint:SetTextColor(OB.Muted())
		end,
		Refresh = ShowHint,
	}
end

------------------------------------------------------------------ the groups

EM:AddBarGroup({
	key = 'show', order = 30, side = 'left', row = 2, section = 'show',
	controls = function(bar)
		return {
			EM.BarToggle(bar, 'showDisabled', st.icons.powerOff, 'show_disabled', 'Show disabled',
				"Shows the movers of frames you've turned off."),
			EM.BarToggle(bar, 'showHidden', st.icons.eye, 'show_hidden', 'Show hidden',
				"Shows the movers of frames that aren't on screen right now: closed bags, no pet, no boss."),
			Modules(bar),
			Filter(bar),
		}
	end,
})
