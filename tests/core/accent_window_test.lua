-- Theme > Accent set in the open /sui window: the window recolors itself at
-- once (the sidebar's open page, its bar), and the row's own reset puts the
-- default back and says accent. accent_test.lua has the kit's controls and
-- edit mode.
--
-- Real: Core's Config on a real AceDB-3.0 and AceConfigRegistry-3.0, the model,
-- the widgets, the body and the window's files (options_window_helpers.lua),
-- with the real Colors and Theme modules.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OW = st.OptionsWindow
local cell, close_all = H.cell, H.close_all
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

local function text(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local function texture_rgb(t) return text(unpack(stub.state(t).color_texture)) end

-- The open page's bar in the sidebar.
local function nav_bar()
	for _, child in ipairs({ OW.GetFrames().navContent:GetChildren() }) do
		if child.bar and child.bar:IsShown() then return child.bar end
	end
end

test("Theme > Accent's swatch recolors the open /sui window at once, and its reset puts the default back", function()
	st.Config:Open('Fonts', 'theme')
	local row = cell('accent')
	check(row, 'the Accent row is drawn on the Theme tab')
	local bar = nav_bar()
	check(bar, 'the open page has its bar')
	eq(texture_rgb(bar), '0.00,0.68,0.94', 'in the accent at the defaults')
	row.widget:Commit(0.9, 0.1, 0.2)
	eq(text(st:Color('accent'):GetRGB()), '0.90,0.10,0.20', 'the swatch wrote the profile accent')
	eq(texture_rgb(nav_bar()), '0.90,0.10,0.20', "the sidebar's open page follows at once")
	for _, child in ipairs({ OW.GetFrames().navContent:GetChildren() }) do
		if child.bar and child.bar:IsShown() then
			local c = stub.state(child.bg).color_texture
			eq(text(c[1], c[2], c[3]) .. ' ' .. string.format('%.2f', c[4]), '0.90,0.10,0.20 0.25', "the open page's fill, at TINT_ROW")
		end
	end
	local underlined = 0
	for _, child in ipairs({ OW.GetFrames().main:GetChildren() }) do
		if child.underline and child.underline:IsShown() then
			underlined = underlined + 1
			eq(texture_rgb(child.underline), '0.90,0.10,0.20', "the active tab's underline follows the accent")
		end
	end
	check(underlined >= 1, 'a tab is underlined')
	-- Its reset: a click on the reset icon by the swatch.
	local icon = cell('accent').frame.defaultReset
	check(icon and icon:IsShown(), 'its own reset shows while it differs')
	stub.click(icon)
	eq(text(st:Color('accent'):GetRGB()), '0.00,0.68,0.94', 'the reset put the default back')
	eq(texture_rgb(nav_bar()), '0.00,0.68,0.94', 'and the window followed')
	close_all()
	local errors = take_errors()
	eq(#errors, 0, 'no errors: ' .. tostring(errors[1]))
end)
