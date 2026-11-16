-- The micro button's PushedBackground is the state helper's checked piece
-- (microbuttons.lua AddStates): under Thick an open window puts
-- SetTexCoord(0, 1/f, 0, 1) on it (Widgets/states.lua); under Blizzard the
-- button puts Blizzard's atlas on it, and SetAtlas keeps coordinates unless it
-- resets them.
local T = load_test_file('lib/theme_helpers.lua')
local locked = load_test_file('lib/locked_widget.lua')
local st, MM

local function world(theme)
	st = T.client('forever')
	CreateFrame('Frame', 'Minimap', UIParent)
	load_saftui('SaftUI-Minimap/minimap.lua')
	load_saftui('SaftUI-Minimap/config.lua')
	apply_defaults()
	for _, file in ipairs({ 'micromenu', 'micromenuart', 'micromenuitems', 'micromenuoptions', 'microbuttons',
			'instancedifficulty', 'queuebutton', 'expansionbutton' }) do
		load_saftui('SaftUI-Minimap/' .. file .. '.lua')
	end
	MM = st:GetModule('MicroMenu')
	MM.Container = CreateFrame('Frame', nil, UIParent)
	MM.Container:SetPoint('TOPLEFT')
	st.config.profile.theme.name = theme
	st:RedrawThemed()
end

local function micro_button(index, textureName)
	local menu = _G.MicroMenu
	if not menu then
		menu = CreateFrame('Frame', 'MicroMenu', UIParent)
		function menu:Layout() end
	end
	local button = CreateFrame('Button', nil, menu)
	button.layoutIndex, button.textureName = index, textureName
	button.Background = button:CreateTexture(nil, 'BACKGROUND')
	button.PushedBackground = button:CreateTexture(nil, 'BACKGROUND')
	button.PushedBackground:SetAtlas('UI-HUD-MicroMenu-ButtonBG-Down', true)
	button.PushedBackground:Hide()
	button.FlashBorder = button:CreateTexture(nil, 'OVERLAY')
	button.Shadow = button:CreateTexture(nil, 'BORDER')
	button.PushedShadow = button:CreateTexture(nil, 'OVERLAY')
	button.MainMenuBarPerformanceBar = button:CreateTexture(nil, 'ARTWORK')
	button.Emblem = button:CreateTexture(nil, 'ARTWORK')
	button.HighlightEmblem = button:CreateTexture(nil, 'ARTWORK')
	button.NotificationOverlay = CreateFrame('Frame', nil, button)
	button.NotificationOverlay:CreateTexture(nil, 'OVERLAY')
	button:SetNormalTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetPushedTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetHighlightTexture(button:CreateTexture(nil, 'HIGHLIGHT'))
	button.SetHighlightAtlas = function(self, atlas, blend)
		local highlight = self:GetHighlightTexture()
		highlight:SetAtlas(atlas)
		highlight:SetBlendMode(blend or 'BLEND')
	end
	button.SetPushed = function(self) self:SetButtonState('PUSHED', true); self:SetHighlightAtlas('UI-HUD-MicroMenu-x-Mouseover', 'BLEND') end
	button.SetNormal = function(self) self:SetButtonState('NORMAL'); self:SetHighlightAtlas('UI-HUD-MicroMenu-x-Mouseover', 'BLEND') end
	return locked(button, 'Blizzard micro button')
end

test('a micro button\'s pushed background is the whole atlas under Blizzard after a window was open under Thick', function()
	world('thick')
	local buttons = {}
	for i = 1, 3 do buttons[i] = micro_button(i, 'Tex' .. i) end
	MM:SkinBlizzardMicroMenu()
	local button = buttons[2]
	button:SetPushed() -- its window opens under Thick: the fade's coordinates go on
	button:SetNormal()
	T.theme('blizzard'); MM:UpdateButtons()
	local pushed = button.PushedBackground
	eq(T.text(pushed:GetTexCoord()), T.text(0, 0, 0, 1, 1, 0, 1, 1), "Blizzard's pushed background is the whole atlas")
	-- and round: Thick, a window open, Blizzard again
	T.theme('thick'); MM:UpdateButtons()
	button:SetPushed(); button:SetNormal()
	T.theme('blizzard'); MM:UpdateButtons()
	eq(T.text(pushed:GetTexCoord()), T.text(0, 0, 0, 1, 1, 0, 1, 1), 'again after a second round')
	take_errors()
end)
