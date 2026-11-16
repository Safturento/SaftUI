-- The Buttons section's opacity: the Buttons colors Normal, Hover, Pushed and
-- Checked no longer have a reader in Core (Core's buttons, check boxes, scroll
-- bar thumbs, slots and resize corners draw their states from the Accent, through
-- the helpers: tests/core/widget_states_test.lua; they are retired in a later
-- task), so what stays here is what still reads the section: the defaults'
-- opacity (Danger's reader is in the action bars, and in Bags), and
-- st:ColorRGBA, the accessor those readers use.
--
-- Real: Core's helpers and the real defaults.
local T = load_test_file('lib/theme_helpers.lua')
local text = T.text

local st = T.client('forever')

test('the defaults draw every Buttons color fully: 100% opacity, so every reader draws its own strength', function()
	for _, key in ipairs({ 'normal', 'hover', 'pushed', 'checked', 'danger' }) do
		eq(st.defaults.colors.button[key].a, 1, 'Buttons > ' .. key .. ' defaults at 100%')
		eq(st.config.profile.colors.button[key].a, 1, 'and so does the profile')
	end
	eq(text(st.defaults.colors.button.normal:GetRGB()), '0.10,0.10,0.10')
	eq(text(st.defaults.colors.button.hover:GetRGB()), '0.30,0.50,0.70')
	eq(text(st.defaults.colors.button.pushed:GetRGB()), '0.30,0.40,0.50')
	eq(text(st.defaults.colors.button.danger:GetRGB()), '0.60,0.10,0.10')
	eq(text(st.defaults.colors.button.checked:GetRGB()), '0.30,0.50,0.70', "Checked starts as Hover's default, so a checked box looks as it did")
end)

test('st:ColorRGBA allocates nothing per read, ten thousand times', function()
	st.config.profile.colors.button.hover.a = 0.5
	collectgarbage(); collectgarbage('stop')
	local before = collectgarbage('count')
	for _ = 1, 10000 do st:ColorRGBA('button', 'hover', 1) end
	local grown = collectgarbage('count') - before
	collectgarbage('restart')
	check(grown < 20, 'st:ColorRGBA makes no table per read (grew ' .. grown .. ' KB)')
	st.config.profile.colors.button.hover.a = 1
end)
