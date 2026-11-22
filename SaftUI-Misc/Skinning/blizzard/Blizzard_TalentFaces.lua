local st = SaftUI
local TF = st:NewModule('TalentFaces')

--[[
	A face on every talent button of WoW Forever's talent window
	(PlayerSpellsFrame.TalentsFrame, Blizzard_PlayerSpells, Camelot): one frame of
	SaftUI's over each button, drawn from the button's own state (or, while a plan
	source gives the node a display, from the plan's simulated state).

	  SaftUI look (the talent window skin is active, TalentWindow: PS:IsActive()):
	    every button has a face: the icon cropped square inside SaftUI's border
	    ('action'), the rank in the Skinning font, the border and the rank colored by
	    the state, the node dimmed and grey as Blizzard dims it.
	  Blizzard look (skin off, or Skinning's Theme Blizzard):
	    no face, Blizzard's buttons as they are, until a plan source (the talent
	    plan, TF:SetPlanSource) gives a node a display: then a face in Blizzard's
	    own node art (SaftUI's textures over the button's, each anchored to the
	    Blizzard region it copies) showing the simulated state.
	  Either look, with a display: the planned rank in the face's top left corner,
	  the real rank left where it is at 30% alpha.

	Taint (.agents/taint.md rules 1 to 3, 6 and 23). Blizzard's tables and frames
	are read only, with one exception, SetAlpha: on a faced button's SpendText,
	spendTextShadows, Shadow and SelectableIcon (Blizzard never sets their alpha:
	it sets their text, color, atlas or shown state, TalentButtonArtMixin:OnLoad
	and ApplyVisualState, TalentButtonUtil.SetSpendText). Each alpha is read first
	into a weak table and put back when the face goes (the skin off, the Blizzard
	theme, planning off under the Blizzard look, the window hidden, a button
	released or re-bound to a node with no face). Never hidden, moved or resized.
	Everything else Blizzard's is read: GetNodeID, GetNodeInfo (its type, to skip
	choice and sub tree nodes), GetFrameLevel, GetSize, the fields visualState,
	artSet, Icon, IconMask, DisabledOverlay, StateBorder, SpendText,
	spendTextShadows, Shadow and SelectableIcon, and GetTexture, GetAtlas, IsShown,
	GetText, GetTextColor, GetFontObject and GetAlpha on those regions, and the
	global TalentButtonUtil's BaseVisualState and GetColorForBaseVisualState. SaftUI's
	own state is in weak tables keyed by Blizzard's frames; nothing is written
	onto one.
	Hooks, post-hooks only, each in xpcall to geterrorhandler(), each only queueing
	a draw on the next frame (C_Timer.After(0)), never drawing inside Blizzard's
	call: hooksecurefunc on each talent button's ApplyVisualState and
	UpdateSpendText, HookScript on each button's OnEnter and OnLeave (which only set
	the hover state on SaftUI's own face), on TalentsFrame's OnShow and OnHide, and
	EventRegistry's TalentFrameBase.ButtonsUpdated and .ConfigUpdated with this
	module as the owner. A button is hooked once, whatever node the pool gives it.
	Never called: C_Traits.PurchaseRank, RefundRank, CommitConfig, any button's
	OnClick, PurchaseRank, SetSelection, UpdateVisualState or ApplyVisualState.
	PlayerSpellsFrame is protected on Forever, so in combat no face is made (a draw
	that would make one waits for the end of combat, st:QueueAfterCombat); a face
	that exists still updates. Forever only: OnEnable returns before hooking
	anything on retail.
]]

local weak = { __mode = 'k' }
local faces = setmetatable({}, weak)  -- button -> its face record
local hooked = setmetatable({}, weak) -- button -> true once its hooks are on
local alphas = setmetatable({}, weak) -- region -> the alpha Blizzard had, while SaftUI has faded it
TF.faces = faces

local PLAN_ALPHA = 0.3     -- the real rank while a plan is shown
local ICON_TRIM = 0.08     -- when the profile gives none
local RED = { 0.8, 0.1, 0.1 } -- DIM_RED_FONT_COLOR, the icon's tint on an error
local LEVEL_ABOVE = 2      -- under the plan's dim (+4), glow (+5), light (+6) and catcher (+10)

local source, queued

------------------------------------------------------------------ pure parts

-- Blizzard's TalentButtonUtil.BaseVisualState, as the face's state keys (7,
-- Invisible, hides the face). Read from the game's table when it has it.
local NAMES = { Normal = 'partial', Gated = 'gated', Disabled = 'disabled', Locked = 'locked', Selectable = 'selectable',
	Maxed = 'maxed', RefundInvalid = 'error', DisplayError = 'error' }
TF.STATE = { [1] = 'partial', [2] = 'gated', [3] = 'disabled', [4] = 'locked', [5] = 'selectable', [6] = 'maxed',
	[8] = 'error', [9] = 'error' }
local NUMBER = {} -- key -> the base visual state's number (the last of two, 'error' being DisplayError)

local function ReadStates()
	local base = _G.TalentButtonUtil and _G.TalentButtonUtil.BaseVisualState
	if type(base) == 'table' then
		for number in pairs(TF.STATE) do TF.STATE[number] = nil end
		for name, key in pairs(NAMES) do
			if type(base[name]) == 'number' then TF.STATE[base[name]] = key end
		end
	end
	for key in pairs(NUMBER) do NUMBER[key] = nil end
	for number, key in pairs(TF.STATE) do
		if not NUMBER[key] or number > NUMBER[key] then NUMBER[key] = number end
	end
end
ReadStates()

-- What a state looks like (the spec's table): the border (a color { group, key },
-- 'accent', or nil: the theme's own), the rank's color, the overlay's alpha (nil:
-- none), grey, and tinted red. The alphas are Blizzard's
-- (TalentButtonArtMixin:ApplyVisualState); the colors are the owner's, by meaning.
local function Style(border, text, overlay, desaturate, red)
	return { border = border, text = text, overlay = overlay, desaturate = desaturate, red = red }
end
local PAINT = {
	selectable = Style({ 'text', 'success' }, { 'text', 'success' }, nil, false, false),
	partial = Style({ 'text', 'caution' }, { 'text', 'caution' }, nil, false, false),
	maxed = Style('accent', { 'text', 'caution' }, nil, false, false),
	gated = Style(nil, { 'text', 'muted' }, 0.7, true, false),
	locked = Style(nil, { 'text', 'muted' }, 0.25, true, false),
	disabled = Style(nil, { 'text', 'muted' }, 0.25, true, false),
	error = Style({ 'text', 'danger' }, { 'text', 'danger' }, 0.3, false, true),
}
function TF.Paint(state) return PAINT[state] end

-- Blizzard's border art of a state (TalentButtonArtMixin:UpdateStateBorder), the key
-- of the button's artSet.
local ART = { selectable = 'selectable', partial = 'normal', maxed = 'maxed', gated = 'locked', locked = 'disabled',
	disabled = 'disabled', error = 'displayError' }
function TF.BlizzardArt(state) return ART[state] end

------------------------------------------------------------------ reads

local function Profile() return st.config.profile end

local function Apply(fn, ...) xpcall(fn, geterrorhandler(), ...) end

-- A hook runs in the middle of Blizzard's own code: an error in it would stop
-- the caller there, so each runs in xpcall to the error handler.
local function Guarded(fn)
	return function(...)
		local a, b, c = ...
		xpcall(function() fn(a, b, c) end, geterrorhandler())
	end
end

local function TalentsFrame()
	local window = _G.PlayerSpellsFrame
	return window and window.TalentsFrame
end

-- The talent window skin, whose IsActive says whether SaftUI's look is on.
local function Skin()
	local ok, skinning = pcall(st.GetModule, st, 'Skinning', true)
	if not ok or not skinning then return nil end
	local found, skin = pcall(skinning.GetModule, skinning, 'Blizzard_PlayerSpellsSkin', true)
	return found and skin or nil
end

local function SaftUILook()
	local skin = Skin()
	return skin ~= nil and skin.IsActive ~= nil and skin:IsActive() or false
end

-- Choice (Selection, 2) and sub tree selection (3) nodes keep Blizzard's art.
local function Plain(button)
	if not button.GetNodeInfo then return true end
	local info = button:GetNodeInfo()
	local kind = type(info) == 'table' and info.type
	return kind ~= 2 and kind ~= 3
end

-- The display the plan source gives a node, or nil (an error in the source goes
-- to the error handler: the node shows its real state).
local function Display(nodeID)
	if not source or not nodeID then return nil end
	local ok, display = xpcall(source, geterrorhandler(), nodeID)
	if ok and type(display) == 'table' and display.state then return display end
	return nil
end

-- A named global font object (the only kind safe to set again, rule 10), or nil.
local function Named(font)
	local name = font and font.GetName and font:GetName()
	if name and _G[name] == font then return font end
end

------------------------------------------------------------------ Blizzard's numbers, faded

-- The regions a face fades while it shows: the real number and its four shadows,
-- the shadow that reaches outside the button and the colorblind plus.
local function FadeList(button)
	local list = { button.SpendText, button.Shadow, button.SelectableIcon }
	for _, shadow in ipairs(button.spendTextShadows or {}) do list[#list + 1] = shadow end
	return list
end

local function Fade(rec, button, on)
	if on then
		rec.faded = rec.faded or {}
		for _, region in ipairs(FadeList(button)) do
			if region.SetAlpha then
				if alphas[region] == nil then
					local alpha = region.GetAlpha and region:GetAlpha()
					if alpha == nil or issecretvalue(alpha) then alpha = 1 end
					alphas[region] = alpha
				end
				rec.faded[region] = true
				region:SetAlpha(0)
			end
		end
	elseif rec.faded then
		for region in pairs(rec.faded) do
			if alphas[region] ~= nil then
				region:SetAlpha(alphas[region])
				alphas[region] = nil
			end
		end
		rec.faded = nil
	end
end

------------------------------------------------------------------ the face

local function Layer()
	if TF.layer then return TF.layer end
	TF.layer = st:CreateFrame('Frame', nil, TalentsFrame())
	TF.layer:SetAllPoints(TalentsFrame())
	TF.layer:EnableMouse(false)
	return TF.layer
end

local function MakeFace(button)
	local face = st:CreateFrame('Frame', nil, Layer())
	face:SetAllPoints(button)
	face:EnableMouse(false)
	local level = button:GetFrameLevel()
	if not issecretvalue(level) then face:SetFrameLevel(level + LEVEL_ABOVE) end
	local rec = { face = face, button = button }
	rec.icon = face:CreateTexture(nil, 'ARTWORK')
	rec.overlay = face:CreateTexture(nil, 'ARTWORK')
	rec.overlay:SetDrawLayer('ARTWORK', 1)
	rec.overlay:SetColorTexture(0, 0, 0, 1)
	rec.overlay:Hide()
	-- the hover piece: a flat texture over the icon that the states helper shows
	-- and colors (the face is mouse-disabled, the hooks and TF:Hover say when)
	rec.hover = face:CreateTexture(nil, 'OVERLAY')
	rec.hover:SetTexture(st.BLANK_TEX)
	rec.hover:SetAllPoints(rec.icon)
	rec.art = face:CreateTexture(nil, 'OVERLAY')
	rec.art:SetDrawLayer('OVERLAY', 1)
	rec.art:Hide()
	rec.rank = face:CreateFontString(nil, 'OVERLAY')
	rec.rank:SetDrawLayer('OVERLAY', 2)
	rec.planned = face:CreateFontString(nil, 'OVERLAY')
	rec.planned:SetDrawLayer('OVERLAY', 2)
	rec.planned:Hide()
	st:AddStates(face, 'icon', { wire = false, pieces = { hover = rec.hover } })
	faces[button] = rec
	return rec
end

local function HideFace(rec)
	rec.face:Hide()
	if st:GetState(rec.face, 'hover') then st:SetState(rec.face, 'hover', false) end
	Fade(rec, rec.button, false)
end

local function RGB(color)
	if not color then return 1, 1, 1 end
	return color:GetRGB()
end

local function Colored(spec)
	if spec == 'accent' then return RGB(st:Color('accent')) end
	return RGB(st:Color(spec[1], spec[2]))
end

-- The color Blizzard gives a state's number (the Blizzard look), or the face's own.
local function BlizzardText(state, paint)
	local util = _G.TalentButtonUtil
	local number = NUMBER[state]
	if util and util.GetColorForBaseVisualState and number then
		local ok, color = pcall(util.GetColorForBaseVisualState, number)
		if ok and color and color.GetRGB then return color:GetRGB() end
	end
	return Colored(paint.text)
end

local function TextFont(button, mode)
	if mode == 'saftui' then return st:FontObject(Profile().skinning.font) end
	local own = button.SpendText and button.SpendText.GetFontObject and Named(button.SpendText:GetFontObject())
	return own or _G.GameFontNormal
end

-- The icon's mask (the Blizzard look; Blizzard's own, cut round or by the
-- button's shape) on the icon and the overlay, or none.
local function Mask(rec, button, on)
	local atlas = on and button.IconMask and button.IconMask.IsShown and button.IconMask:IsShown()
		and button.IconMask.GetAtlas and button.IconMask:GetAtlas()
	if atlas then
		if not rec.mask then rec.mask = rec.face:CreateMaskTexture() end
		rec.mask:ClearAllPoints()
		rec.mask:SetAllPoints(button.IconMask)
		rec.mask:SetAtlas(atlas)
		rec.icon:AddMaskTexture(rec.mask)
		rec.overlay:AddMaskTexture(rec.mask)
	elseif rec.mask then
		rec.icon:RemoveMaskTexture(rec.mask)
		rec.overlay:RemoveMaskTexture(rec.mask)
	end
end

local function SetIcon(rec, button, mode)
	local source = button.Icon
	local atlas = source and source.GetAtlas and source:GetAtlas()
	if atlas then
		rec.icon:SetAtlas(atlas)
	elseif source and source.GetTexture then
		rec.icon:SetTexture(source:GetTexture())
		if mode == 'saftui' then
			local width, height = button:GetSize()
			if issecretvalue(width) or issecretvalue(height) then width, height = nil, nil end
			rec.icon:SetTexCoord(st:IconTexCoords((Profile().misc or {}).icon_trim or ICON_TRIM, width, height))
		else
			rec.icon:SetTexCoord(0, 1, 0, 1)
		end
	end
end

-- Puts the look on the face: mode 'saftui' or 'blizzard', state a key of PAINT,
-- planned the plan's rank (nil: no display, the real state), display the source's.
local function Dress(rec, button, mode, state, planned, display)
	local face, paint = rec.face, PAINT[state]
	local config = Profile().skinning
	local theme, background = config.theme, config.background
	local inset = 0
	if mode == 'saftui' then
		st:SetTemplate(face, theme, background, 'action')
		inset = st:ThemeInset(theme, background, 'action') or 0
		rec.drawn = true
		rec.icon:ClearAllPoints()
		st:SetInside(rec.icon, inset)
	else
		if rec.drawn then
			st:SetTemplate(face, 'none', background, 'action')
			rec.drawn = false
		end
		rec.icon:ClearAllPoints()
		rec.icon:SetAllPoints(button.Icon or face)
	end
	SetIcon(rec, button, mode)
	Mask(rec, button, mode == 'blizzard')

	-- the dim, the grey and the red of the state (Blizzard's ApplyVisualState)
	rec.icon:SetDesaturated(paint.desaturate)
	if paint.red then rec.icon:SetVertexColor(RED[1], RED[2], RED[3], 1) else rec.icon:SetVertexColor(1, 1, 1, 1) end
	rec.overlay:ClearAllPoints()
	rec.overlay:SetAllPoints(mode == 'saftui' and rec.icon or button.DisabledOverlay or rec.icon)
	if paint.overlay then
		rec.overlay:SetAlpha(paint.overlay)
		rec.overlay:Show()
	else
		rec.overlay:Hide()
	end

	-- the border: SaftUI's, colored by the state; or Blizzard's art, copied
	if mode == 'saftui' then
		rec.art:Hide()
		if paint.border then
			local r, g, b = Colored(paint.border)
			st:SetBorderColor(face, r, g, b)
		else
			st:SetBorderColor(face)
		end
	else
		local atlas = button.artSet and button.artSet[ART[state]]
		if atlas and button.StateBorder then
			rec.art:ClearAllPoints()
			rec.art:SetAllPoints(button.StateBorder)
			rec.art:SetAtlas(atlas)
			rec.art:Show()
		else
			rec.art:Hide()
		end
	end

	-- the texts: the real rank (faded while a plan shows), the planned rank on top
	local font = TextFont(button, mode)
	if font then
		rec.rank:SetFontObject(font)
		rec.planned:SetFontObject(font)
	end
	local text = button.SpendText and button.SpendText.GetText and button.SpendText:GetText()
	if issecretvalue(text) or type(text) ~= 'string' then text = '' end
	rec.rank:SetText(text)
	rec.rank:ClearAllPoints()
	rec.planned:ClearAllPoints()
	if mode == 'saftui' then
		rec.rank:SetPoint('BOTTOMRIGHT', face, 'BOTTOMRIGHT', -(inset + 1), inset + 1)
	else
		rec.rank:SetPoint('CENTER', button.SpendText or face, 'CENTER', 0, 0)
	end
	rec.planned:SetPoint('TOPLEFT', face, 'TOPLEFT', inset + 1, -(inset + 1))
	if display then
		local r, g, b
		if mode == 'saftui' then
			r, g, b = Colored({ 'text', 'muted' })
		elseif button.SpendText and button.SpendText.GetTextColor then
			r, g, b = button.SpendText:GetTextColor()
			if issecretvalue(r) then r, g, b = 1, 1, 1 end
		end
		rec.rank:SetTextColor(r or 1, g or 1, b or 1, 1)
		rec.rank:SetAlpha(PLAN_ALPHA)
		local show = type(planned) == 'number' and (planned > 0 or state == 'selectable')
		if show then
			local pr, pg, pb
			if mode == 'saftui' then pr, pg, pb = Colored(paint.text) else pr, pg, pb = BlizzardText(state, paint) end
			rec.planned:SetText(tostring(planned))
			rec.planned:SetTextColor(pr, pg, pb, 1)
		end
		rec.planned:SetShown(show)
	else
		local r, g, b
		if mode == 'saftui' then r, g, b = Colored(paint.text) else r, g, b = BlizzardText(state, paint) end
		rec.rank:SetTextColor(r, g, b, 1)
		rec.rank:SetAlpha(1)
		rec.planned:Hide()
	end

	rec.mode = mode
	rec.face:Show()
	-- after the theme drew the face: the states read its look again
	st:RestyleStates(face)
	Fade(rec, button, true)
end

------------------------------------------------------------------ hooks

local function HoverButton(button, on)
	local rec = faces[button]
	if rec and rec.face:IsShown() then st:SetState(rec.face, 'hover', on) end
end

local function HookButton(button)
	if hooked[button] then return end
	hooked[button] = true
	for _, method in ipairs({ 'ApplyVisualState', 'UpdateSpendText' }) do
		if type(button[method]) == 'function' then
			hooksecurefunc(button, method, Guarded(function() TF:Queue() end))
		end
	end
	if button.HookScript then
		button:HookScript('OnEnter', Guarded(function(self) HoverButton(self, true) end))
		button:HookScript('OnLeave', Guarded(function(self) HoverButton(self, false) end))
	end
end

------------------------------------------------------------------ drawing

-- Every face again, from the buttons the pool has handed out now. Faces of buttons
-- that aren't (released) or that have none to show go, with their fades.
function TF:Draw()
	queued = false
	local talents = TalentsFrame()
	if not talents or not talents.EnumerateAllTalentButtons then return end
	ReadStates()
	if not talents:IsShown() then
		for _, rec in pairs(faces) do HideFace(rec) end
		return
	end
	local entries, anyDisplay = {}, false
	for button in talents:EnumerateAllTalentButtons() do
		local nodeID = button.GetNodeID and button:GetNodeID()
		local plain = nodeID ~= nil and Plain(button)
		local display = plain and Display(nodeID) or nil
		if display then anyDisplay = true end
		entries[#entries + 1] = { button = button, nodeID = nodeID, plain = plain, display = display }
	end
	local look = SaftUILook() and 'saftui' or (anyDisplay and 'blizzard' or nil)
	local present, deferred = {}, false
	for _, entry in ipairs(entries) do
		local button, display = entry.button, entry.display
		present[button] = true
		HookButton(button)
		local state, planned
		if display then
			state, planned = display.state, display.planned
		else
			state = TF.STATE[button.visualState]
		end
		local rec = faces[button]
		if look and entry.plain and state and PAINT[state] and (look == 'saftui' or display) then
			if not rec then
				if InCombatLockdown() then
					deferred = true
				else
					rec = MakeFace(button)
				end
			end
			if rec then
				if rec.nodeID ~= entry.nodeID and st:GetState(rec.face, 'hover') then st:SetState(rec.face, 'hover', false) end
				rec.nodeID = entry.nodeID
				Apply(Dress, rec, button, look, state, planned, display)
			end
		elseif rec then
			rec.nodeID = entry.nodeID
			HideFace(rec)
		end
	end
	for button, rec in pairs(faces) do
		if not present[button] then HideFace(rec) end
	end
	if deferred then
		st:QueueAfterCombat('talentfaces', function() TF:Draw() end)
	end
end

-- A draw on the next frame, once however many ask.
function TF:Queue()
	if queued then return end
	queued = true
	C_Timer.After(0, function()
		queued = false
		xpcall(function() TF:Draw() end, geterrorhandler())
	end)
end

-- 'saftui' while the skin is active, 'blizzard' while a source gives a display
-- under the Blizzard look, else nil (Blizzard's buttons as they are).
function TF:Look()
	if SaftUILook() then return 'saftui' end
	local talents = TalentsFrame()
	if source and talents and talents.EnumerateAllTalentButtons then
		for button in talents:EnumerateAllTalentButtons() do
			local nodeID = button.GetNodeID and button:GetNodeID()
			if nodeID and Plain(button) and Display(nodeID) then return 'blizzard' end
		end
	end
	return nil
end

-- fn(nodeID) -> { state, planned } | nil, the talent plan's simulation; nil clears it.
function TF:SetPlanSource(fn)
	source = fn
	self:Queue()
end

-- The hover of a node's face, from the plan's catcher (which covers the button, so
-- the button's own OnEnter doesn't fire while planning).
function TF:Hover(nodeID, on)
	if nodeID == nil then return end
	for _, rec in pairs(faces) do
		if rec.nodeID == nodeID and rec.face:IsShown() then st:SetState(rec.face, 'hover', on and true or false) end
	end
end

------------------------------------------------------------------ setup

function TF:Install()
	local talents = TalentsFrame()
	if not talents or self.talents then return end
	self.talents = talents
	talents:HookScript('OnShow', Guarded(function() TF:Queue() end))
	talents:HookScript('OnHide', Guarded(function() TF:Queue() end))
	local queue = Guarded(function() TF:Queue() end)
	EventRegistry:RegisterCallback('TalentFrameBase.ButtonsUpdated', queue, self)
	EventRegistry:RegisterCallback('TalentFrameBase.ConfigUpdated', queue, self)
	if talents:IsShown() then self:Queue() end
end

-- A profile change, the Skinning page's look (the talent window skin asks too), a
-- recolor or a font change: every face again.
function TF:UpdateConfig()
	if self.talents then self:Queue() end
end
TF.OnColorsChanged = TF.UpdateConfig
TF.OnFontsChanged = TF.UpdateConfig

-- On retail nothing is hooked or touched.
function TF:OnEnable()
	if not st.forever then return end
	st:OnBlizzardAddon('Blizzard_PlayerSpells', function() TF:Install() end)
end

function TF:OnDisable()
	for _, rec in pairs(faces) do HideFace(rec) end
end
