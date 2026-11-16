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

-- The open page's look in the sidebar: a selected row (the states helper's Bar and Fill).
local function nav_look()
	for _, child in ipairs({ OW.GetFrames().navContent:GetChildren() }) do
		local look = st:StateLook(child)
		if look and look.bar and look.bar.shown then return look end
	end
end

test("Theme > Accent's swatch recolors the open /sui window at once, and its reset puts the default back", function()
	st.Config:Open('Fonts', 'theme')
	local row = cell('accent')
	check(row, 'the Accent row is drawn on the Theme tab')
	local look = nav_look()
	check(look, 'the open page has its bar')
	eq(text(look.bar.r, look.bar.g, look.bar.b), '0.00,0.68,0.94', 'in the accent at the defaults')
	row.widget:Commit(0.9, 0.1, 0.2)
	eq(text(st:Color('accent'):GetRGB()), '0.90,0.10,0.20', 'the swatch wrote the profile accent')
	look = nav_look()
	eq(text(look.bar.r, look.bar.g, look.bar.b), '0.90,0.10,0.20', "the sidebar's open page follows at once")
	check(look.fill.shown, "the open page's fill (the fade)")
	eq(text(look.fill.r, look.fill.g, look.fill.b), '0.90,0.10,0.20', 'in the accent too')
	local underlined = 0
	for _, child in ipairs({ OW.GetFrames().main:GetChildren() }) do
		local tab = st:StateLook(child)
		if tab and tab.shape == 'tab' and tab.bar.shown then
			underlined = underlined + 1
			eq(text(tab.bar.r, tab.bar.g, tab.bar.b), '0.90,0.10,0.20', "the active tab's underline follows the accent")
		end
	end
	check(underlined >= 1, 'a tab is underlined')
	-- Its reset: a click on the reset icon by the swatch.
	local icon = cell('accent').frame.defaultReset
	check(icon and icon:IsShown(), 'its own reset shows while it differs')
	stub.click(icon)
	eq(text(st:Color('accent'):GetRGB()), '0.00,0.68,0.94', 'the reset put the default back')
	look = nav_look()
	eq(text(look.bar.r, look.bar.g, look.bar.b), '0.00,0.68,0.94', 'and the window followed')
	close_all()
	local errors = take_errors()
	eq(#errors, 0, 'no errors: ' .. tostring(errors[1]))
end)
