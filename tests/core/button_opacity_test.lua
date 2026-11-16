-- The Buttons section's opacity: Buttons holds only Danger now (the colors Normal,
-- Hover, Pushed and Checked retired at migration step 8: every interaction state is
-- derived from the Accent, Media/states.lua), so what stays here is what still reads
-- the section: Danger's default opacity (its readers are the action bars, the totem
-- bar and Bags), and st:ColorRGBA, the accessor those readers use.
--
-- Real: Core's helpers and the real defaults.
local T = load_test_file('lib/theme_helpers.lua')
local text = T.text

local st = T.client('forever')

test('the defaults draw Danger fully: 100% opacity, so every reader draws its own strength', function()
	eq(st.defaults.colors.button.danger.a, 1, 'Buttons > Danger defaults at 100%')
	eq(st.config.profile.colors.button.danger.a, 1, 'and so does the profile')
	eq(text(st.defaults.colors.button.danger:GetRGB()), '0.60,0.10,0.10')
end)

test('the Buttons defaults hold only Danger; the four retired colors are no colors', function()
	local keys = {}
	for key in pairs(st.defaults.colors.button) do keys[#keys + 1] = key end
	eq(table.concat(keys, ','), 'danger')
	for _, key in ipairs({ 'normal', 'hover', 'pushed', 'checked' }) do
		check(not pcall(st.Color, st, 'button', key), "st:Color('button', '" .. key .. "') errors at the caller")
		check(not pcall(st.ColorRGBA, st, 'button', key, 0.4), "st:ColorRGBA('button', '" .. key .. "') errors at the caller")
		eq(st.config.profile.colors.button[key], nil, key .. ' is not in the profile')
	end
end)

test('st:ColorRGBA allocates nothing per read, ten thousand times', function()
	st.config.profile.colors.button.danger.a = 0.5
	collectgarbage(); collectgarbage('stop')
	local before = collectgarbage('count')
	for _ = 1, 10000 do st:ColorRGBA('button', 'danger', 1) end
	local grown = collectgarbage('count') - before
	collectgarbage('restart')
	check(grown < 20, 'st:ColorRGBA makes no table per read (grew ' .. grown .. ' KB)')
	st.config.profile.colors.button.danger.a = 1
end)
