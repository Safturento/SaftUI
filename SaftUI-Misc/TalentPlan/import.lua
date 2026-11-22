local st = SaftUI
local TP = st:GetModule('TalentPlan')
local S = TP.Store

--[[
	The import dialog: paste a guide's talent order, see what was read, and put
	it in the plan shown (Replace) or in a new one. A SaftUI frame on UIParent,
	centered on the talent window; nothing is written onto a Blizzard frame
	(.agents/taint.md rule 1). The result is worked out again on every change of
	the text, with the names of the talent tree read when it opens (TP.view can
	be stale while the panel is hidden, so it isn't relied on).

	TP.importFrame = { box, hint, summary, name, import, cancel, mode, group,
	names, result }.
]]

local WIDTH, HEIGHT, PAD = 420, 460, 16
local BOX_HEIGHT = 220
local SUMMARY_LINES = 3 -- the lines of warnings and of unmatched text it names
local DEFAULT_NAME = 'Imported'

-- 'replace' puts the steps in the active plan of group, clearing its phases
-- (with no active plan it acts as 'new'); 'new' makes a plan named name (or
-- 'Imported') and makes it active. Returns the plan.
function TP:ApplyImport(result, mode, name, group)
	local plan = mode == 'replace' and S.Active(group) or nil
	if plan then
		plan.steps, plan.phases = { unpack(result.steps) }, {}
	else
		name = (name or ''):match('^%s*(.-)%s*$')
		plan = S.New(name ~= '' and name or DEFAULT_NAME, group)
		plan.steps = { unpack(result.steps) }
	end
	self.selected = nil -- the old plan's row number means nothing in the new steps
	self:QueueRefresh()
	return plan
end

local function Muted() return st:Color('text', 'muted'):GetRGB() end

-- The result of the text in the box, its summary and the Import button.
local function Update(f)
	local text = f.box:GetText()
	f.hint:SetShown(text == '')
	f.result = TP.Parse(text, f.names)
	f.summary:SetText(table.concat(TP.ImportSummary(f.result, SUMMARY_LINES), '\n'))
	f.import:SetEnabled(#f.result.steps > 0)
	-- the box grows with its text, so the scroll frame can scroll to the end
	f.measure:SetText(text == '' and ' ' or text)
	f.scroll:SetContentSize(f.boxWidth, math.max(BOX_HEIGHT, f.measure:GetStringHeight() + 8))
end

local function SetMode(f, mode)
	f.mode = mode
	local picked = mode == 'replace' and 1 or 2
	for i, button in ipairs(f.radio.buttons) do
		button.picked = i == picked
		st:SetState(button, 'selected', i == picked)
		st:SetButtonTab(button, i == picked)
	end
end

function TP:CloseImport()
	local f = self.importFrame
	if not f then return end
	f.box:ClearFocus()
	f.name:ClearFocus()
	f:Hide()
	if not InCombatLockdown() then f.keys:SetPropagateKeyboardInput(true) end
end

local function Build()
	local f = st:CreateFrame('Frame', 'SaftUI_TalentPlanImport', UIParent)
	f:SetSize(WIDTH, HEIGHT)
	f:SetFrameStrata('DIALOG')
	f:EnableMouse(true)
	st:SetTemplate(f, 'theme', 'options', 'panel')
	f:Hide()

	local title = st:CreateFontString(f, 'heading', 'Import a talent order')
	title:SetPoint('TOPLEFT', f, 'TOPLEFT', PAD, -PAD)

	-- the paste box, in a scroll frame
	local box = st:CreateEditBox(nil, f, true)
	box:SetFontObject(st:GetFont('normal'))
	box:SetTextInsets(4, 4, 4, 4)
	local scroll = st:CreateScrollFrame(f, box)
	scroll:SetPoint('TOPLEFT', f, 'TOPLEFT', PAD, -(PAD + 28))
	scroll:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -(PAD + st:ScrollBarRoom(scroll)), -(PAD + 28))
	scroll:SetHeight(BOX_HEIGHT)
	scroll:SetContentSize(WIDTH - PAD * 2 - st:ScrollBarRoom(scroll), BOX_HEIGHT)
	box:SetWidth(WIDTH - PAD * 2 - st:ScrollBarRoom(scroll))
	f.box, f.scroll = box, scroll
	f.boxWidth = WIDTH - PAD * 2 - st:ScrollBarRoom(scroll)

	local hint = st:CreateFontString(box, 'normal', "Paste a guide's talent order")
	hint:SetPoint('TOPLEFT', box, 'TOPLEFT', 6, -6)
	hint:SetTextColor(Muted())
	f.hint = hint

	-- measures the text's height at the box's width (never shown)
	local measure = st:CreateFontString(f, 'normal')
	measure:SetWidth(WIDTH - PAD * 2 - st:ScrollBarRoom(scroll) - 8)
	measure:SetWordWrap(true)
	measure:SetJustifyH('LEFT')
	measure:Hide()
	f.measure = measure

	-- Replace or New, and the new plan's name
	local radio = st:CreateRadioGroup('SaftUITalentPlanImportMode', f, {
		buttonWidth = 100, buttonHeight = 22, buttonSpacing = 2, theme = 'theme', background = 'theme',
		items = {
			{ label = 'Replace this plan', onClick = function() SetMode(f, 'replace') end },
			{ label = 'New plan', onClick = function() SetMode(f, 'new') end },
		},
	})
	radio:SetPoint('TOPLEFT', scroll, 'BOTTOMLEFT', 0, -10)
	f.radio = radio

	local name = st:CreateEditBox(nil, f)
	name:SetHeight(22)
	name:SetPoint('LEFT', radio.buttons[2], 'RIGHT', 10, 0)
	name:SetPoint('RIGHT', f, 'RIGHT', -PAD, 0)
	f.name = name

	local summary = st:CreateFontString(f, 'pixel')
	summary:SetJustifyH('LEFT')
	summary:SetJustifyV('TOP')
	summary:SetWordWrap(true)
	summary:SetPoint('TOPLEFT', radio.buttons[1], 'BOTTOMLEFT', 0, -12)
	summary:SetPoint('RIGHT', f, 'RIGHT', -PAD, 0)
	summary:SetHeight(100)
	f.summary = summary

	local cancel = st:CreateButton(nil, f, 'Cancel', 'theme', 'theme')
	cancel:SetSize(90, 24)
	cancel:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -PAD, PAD)
	local import = st:CreateButton(nil, f, 'Import', 'theme', 'theme')
	import:SetSize(90, 24)
	import:SetPoint('RIGHT', cancel, 'LEFT', -8, 0)
	f.import, f.cancel = import, cancel

	cancel:SetScript('OnClick', function() TP:CloseImport() end)
	import:SetScript('OnClick', function()
		if #f.result.steps == 0 then return end
		TP:ApplyImport(f.result, f.mode, f.name:GetText(), f.group)
		TP:CloseImport()
	end)
	box:SetScript('OnTextChanged', function() Update(f) end)
	box:SetScript('OnEscapePressed', function() TP:CloseImport() end)
	name:SetScript('OnEscapePressed', function() TP:CloseImport() end)

	-- Esc closes it, through a keyboard catcher that is a child of the frame
	-- (so it hears keys only while shown); any other key goes on to the game.
	local keys = CreateFrame('Frame', nil, f)
	keys:EnableKeyboard(true)
	keys:SetPropagateKeyboardInput(true)
	f.keys = keys
	keys:SetScript('OnKeyDown', function(self, key)
		if InCombatLockdown() then return end
		local escape = key == 'ESCAPE' and not GetCurrentKeyBoardFocus()
		self:SetPropagateKeyboardInput(not escape)
		if escape then TP:CloseImport() end
	end)
	return f
end

function TP:OpenImport()
	local f = self.importFrame
	if not f then
		f = Build()
		self.importFrame = f
	end
	-- it closes when the talent window hides (the panel hides with it)
	if self.panel and not f.hooked then
		f.hooked = true
		self.panel:HookScript('OnHide', function() TP:CloseImport() end)
	end

	local group = self:ViewedGroup()
	local tree = TP.Data.Read(group)
	f.group, f.names = group, tree and tree.names or {}
	f.name:SetText(DEFAULT_NAME)
	f.box:SetText('')
	SetMode(f, S.Active(group) and 'replace' or 'new')
	Update(f)

	local window = _G.PlayerSpellsFrame
	f:ClearAllPoints()
	f:SetPoint('CENTER', window and window:IsShown() and window or UIParent, 'CENTER', 0, 0)
	f:Show()
	f.box:SetFocus()
end
