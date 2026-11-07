local st = SaftUI
local EM = st.EditModeFrames

-- Edit mode's footer buttons (e.g. grid, snap) on the /sui window's status
-- bar. They show while edit mode is active and /sui is open, and the status
-- text (where AceConfigDialog shows validation errors) moves clear of them.

local BUTTON_HEIGHT = 16
local SPACING = 4

local footer      -- SaftUI frame laid over the window's status bar
local attachedTo  -- the /sui window the footer is on, or nil
local buttons = {}

local function GetFooter()
	if not footer then
		footer = st:CreateFrame('Frame', nil, UIParent)
		footer:Hide()
	end
	return footer
end

-- Buttons are laid out from the left edge: spacing, button, spacing, button...
local function ButtonsWidth()
	local width = 0
	for _, button in ipairs(buttons) do
		width = width + SPACING + button:GetWidth()
	end
	return width
end

local function Detach()
	if attachedTo then
		-- /sui may stay open, so give the status text its full width back. A
		-- released window had its anchors restored already, and this skips it.
		st.AceSkin:SetStatusTextInset(attachedTo, 0)
		attachedTo = nil
	end
	if footer then
		footer:Hide()
		footer:ClearAllPoints()
		footer:SetParent(UIParent)
	end
end

-- Puts the footer on the open /sui window while edit mode is active, and takes
-- it off otherwise. Runs when edit mode turns on or off, when /sui opens or
-- closes, and when a button is added.
function EM:UpdateFooter()
	local window = self.active and st.Config:GetWindow() or nil
	local statusbar = window and st.AceSkin:GetStatusBar(window)
	if attachedTo ~= window or not statusbar then
		Detach()
	end
	if not statusbar then return end

	local f = GetFooter()
	f:SetParent(window.frame)
	f:ClearAllPoints()
	f:SetAllPoints(statusbar)
	f:SetFrameLevel(statusbar:GetFrameLevel() + 2)
	f:Show()
	attachedTo = window
	st.AceSkin:SetStatusTextInset(window, ButtonsWidth())
end

-- Adds a button to the footer, left to right. Call from OnEnable or later (it
-- needs the profile's templates).
function EM:AddFooterButton(text, onClick)
	local f = GetFooter()
	local button = st:CreateButton(nil, f, text)
	button:SetHeight(BUTTON_HEIGHT)
	button:SetWidth(math.ceil(button.text:GetStringWidth()) + 16)
	button:SetScript('OnClick', function(self) onClick(self) end)

	local previous = buttons[#buttons]
	if previous then
		button:SetPoint('LEFT', previous, 'RIGHT', SPACING, 0)
	else
		button:SetPoint('LEFT', f, 'LEFT', SPACING, 0)
	end
	buttons[#buttons + 1] = button
	self:UpdateFooter()
	return button
end

EM:On('Enabled', function() EM:UpdateFooter() end)
EM:On('Disabled', function() EM:UpdateFooter() end)
