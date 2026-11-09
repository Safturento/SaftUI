local st = SaftUI
local EM = st.EditModeFrames

-- Edit mode's footer buttons (Grid, Snap to grid, Snap to frames and the size
-- steppers, settings.lua) on the /sui window's footer, in the region between
-- Reload UI and Close (st.OptionsWindow:GetFooter()). They show while edit
-- mode is active and /sui is open, and the window's status line (validate
-- errors) starts clear of them.

local BUTTON_HEIGHT = 22
local SPACING = 6

local footer   -- SaftUI frame the buttons are on, laid over the footer region
local attached -- the footer region it's on, or nil
local buttons = {}

local function GetFooter()
	if not footer then
		footer = st:CreateFrame('Frame', nil, UIParent)
		footer:Hide()
	end
	return footer
end

-- Buttons are laid out from the left edge: button, spacing, button...
local function ButtonsWidth()
	local width = 0
	for _, button in ipairs(buttons) do
		width = width + button:GetWidth() + SPACING
	end
	return width
end

local function Detach()
	if attached then
		-- /sui may stay open, so give the status line the region back.
		st.OptionsWindow:SetFooterInset(0)
		attached = nil
	end
	if footer then
		footer:Hide()
		footer:ClearAllPoints()
		footer:SetParent(UIParent)
	end
end

-- Puts the buttons on the open /sui window while edit mode is active, and
-- takes them off otherwise. Runs when edit mode turns on or off, when /sui
-- opens or closes, and when a button is added.
function EM:UpdateFooter()
	local region = self.active and st.Config:GetWindow() and st.OptionsWindow:GetFooter() or nil
	if not region then
		Detach()
		return
	end
	local f = GetFooter()
	f:SetParent(region)
	f:ClearAllPoints()
	f:SetAllPoints(region)
	f:SetFrameLevel(region:GetFrameLevel() + 2)
	f:Show()
	attached = region
	st.OptionsWindow:SetFooterInset(ButtonsWidth())
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
		button:SetPoint('LEFT', f, 'LEFT', 0, 0)
	end
	buttons[#buttons + 1] = button
	self:UpdateFooter()
	return button
end

EM:On('Enabled', function() EM:UpdateFooter() end)
EM:On('Disabled', function() EM:UpdateFooter() end)
