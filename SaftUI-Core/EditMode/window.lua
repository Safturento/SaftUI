local st = SaftUI
local EM = st.EditModeFrames

-- The per-frame settings window: opens when a mover is selected, beside its
-- frame, with the mover's options in a sidebar tree.

local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

local APP = st.name .. '_EditMode'
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 560, 440
local GAP = 10 -- between the mover's frame and the window
local FOOTER_BUTTON_HEIGHT = 16
local FOOTER_SPACING = 4

local window      -- the open AceGUI Frame, or nil
local placedFor   -- mover the window was last placed beside
local footer      -- SaftUI frame laid over the window's status bar
local footerButtons = {}

local function IsSecret(...)
	if not issecretvalue then return false end
	for i = 1, select('#', ...) do
		if issecretvalue((select(i, ...))) then return true end
	end
	return false
end

-- def.options() is the root, so its groups (General, Position) are the sidebar.
local function BuildOptions(mover)
	local def = mover.def
	local root = def.options and def.options() or { args = {} }
	root.type = 'group'
	root.name = def.label or mover.key
	root.childGroups = 'tree'
	root.args = root.args or {}
	if def.shared and def.shared.options then
		local shared = def.shared.options()
		shared.name = shared.name or def.shared.label
		shared.order = shared.order or 1000
		root.args.shared = shared
	end
	return root
end

-- Writes a spot beside the mover's frame into the window's status table, which
-- the AceGUI Frame positions itself from (also on every refresh). Right side if
-- it fits, else left, else whichever side has more room; clamped to the screen.
local function Place(status, mover)
	local overlay = mover.overlay
	local left, right, top = overlay:GetLeft(), overlay:GetRight(), overlay:GetTop()
	local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
	if not (left and right and top and screenWidth and screenHeight)
			or IsSecret(left, right, top, screenWidth, screenHeight) then
		status.left, status.top = nil, nil -- the Frame centers itself
		return
	end
	-- overlay coordinates -> UIParent coordinates (the window's parent)
	local ratio = overlay:GetEffectiveScale() / UIParent:GetEffectiveScale()
	left, right, top = left * ratio, right * ratio, top * ratio

	local width, height = status.width or DEFAULT_WIDTH, status.height or DEFAULT_HEIGHT
	local x
	if right + GAP + width <= screenWidth then
		x = right + GAP
	elseif left - GAP - width >= 0 then
		x = left - GAP - width
	elseif screenWidth - right >= left then
		x = screenWidth - width
	else
		x = 0
	end
	x = math.max(0, math.min(x, screenWidth - width))
	local y = math.max(math.min(height, screenHeight), math.min(top, screenHeight))

	status.left = math.floor(x + 0.5)
	status.top = math.floor(y + 0.5)
end

local function GetFooter()
	if not footer then
		footer = st:CreateFrame('Frame', nil, UIParent)
		footer:Hide()
	end
	return footer
end

-- Keeps AceConfigDialog's status text (validation errors) right of the buttons.
local function UpdateStatusText()
	if not window then return end
	-- Buttons are laid out from the left edge: spacing, button, spacing, button...
	local inset = 0
	for _, button in ipairs(footerButtons) do
		inset = inset + FOOTER_SPACING + button:GetWidth()
	end
	st.AceSkin:SetStatusTextInset(window, inset)
end

local function AttachFooter()
	local statusbar = st.AceSkin:GetStatusBar(window)
	if not statusbar then return end
	local f = GetFooter()
	f:SetParent(window.frame)
	f:ClearAllPoints()
	f:SetAllPoints(statusbar)
	f:SetFrameLevel(statusbar:GetFrameLevel() + 2)
	f:Show()
	UpdateStatusText()
end

local function DetachFooter()
	if not footer then return end
	footer:Hide()
	footer:ClearAllPoints()
	footer:SetParent(UIParent)
end

-- The window was released (closed by us, its close button, Escape, ...).
local function OnWindowClosed()
	window = nil
	placedFor = nil
	DetachFooter()
	if EM.selected then
		EM:Select(nil) -- closing the window ends the selection
	end
end

function EM:OpenWindow(mover)
	AceConfigRegistry:RegisterOptionsTable(APP, BuildOptions(mover))

	local status = AceConfigDialog:GetStatusTable(APP)
	status.width = status.width or DEFAULT_WIDTH
	status.height = status.height or DEFAULT_HEIGHT
	-- Re-place only for a new mover; otherwise keep where the user dragged it.
	if not window or placedFor ~= mover then
		Place(status, mover)
		placedFor = mover
	end

	window = st.AceSkin:CreateWindow(APP, mover.def.label or mover.key, OnWindowClosed)
	AceConfigDialog:Open(APP)
	AttachFooter()
end

function EM:CloseWindow()
	if window then
		window:Hide() -- AceGUI releases it; OnWindowClosed cleans up
	end
end

-- Adds a button to the window's footer strip, left to right. Call from
-- OnEnable or later (it needs the profile's templates).
function EM:AddFooterButton(text, onClick)
	local f = GetFooter()
	local button = st:CreateButton(nil, f, text)
	button:SetHeight(FOOTER_BUTTON_HEIGHT)
	button:SetWidth(math.ceil(button.text:GetStringWidth()) + 16)
	button:SetScript('OnClick', function(self) onClick(self) end)

	local previous = footerButtons[#footerButtons]
	if previous then
		button:SetPoint('LEFT', previous, 'RIGHT', FOOTER_SPACING, 0)
	else
		button:SetPoint('LEFT', f, 'LEFT', FOOTER_SPACING, 0)
	end
	footerButtons[#footerButtons + 1] = button
	UpdateStatusText()
	return button
end

EM:On('Selected', function(mover)
	if mover then
		EM:OpenWindow(mover)
	else
		EM:CloseWindow()
	end
end)

EM:On('Disabled', function() EM:CloseWindow() end)

-- Drags and nudges: refresh the Position fields.
EM:On('PositionChanged', function()
	if window then
		AceConfigRegistry:NotifyChange(APP)
	end
end)
