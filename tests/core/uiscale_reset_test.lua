-- /sui scale reset, the way out of any size, with SaftUI-Core/Config/
-- uiscaleprompt.lua not loaded: it lives in uiscale.lua (UIScale:Reset) and
-- config.lua's slash handler, so a load error in the prompt's file can't take
-- it away. The other forms say the prompt didn't load.
--
-- Real: Core's Config/config.lua on a real AceDB (core/config_helpers.lua) and
-- uiscale.lua's runtime. The prompt's file is never loaded here.

load_test_file('core/config_helpers.lua')
local st = SaftUI

local function printed_by(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

local function near(a, b) return math.abs(a - b) < 1e-9 end

test('/sui scale reset works with the prompt absent: Automatic at 100% at once, in combat after it', function()
	eq(st.UIScalePrompt, nil, 'no prompt in this world')
	stub.screen_width, stub.screen_height = 2560, 1440
	st.config.global.uiScale = { mode = 'auto', size = 1.5 }
	st.UIScale:Start()
	check(near(UIParent:GetScale(), 768 / 1440 * 1.5), 'at 150%')
	local lines = printed_by(function() SlashCmdList.SAFTUI('scale reset') end)
	eq(st.config.global.uiScale, nil, 'saved: nothing')
	check(near(UIParent:GetScale(), 768 / 1440), 'at 100% at once')
	check(lines[1] and lines[1]:find('UI scale back to Automatic at 100%.', 1, true), 'says so: ' .. tostring(lines[1]))

	st.config.global.uiScale = { mode = 'auto', size = 1.5 }
	st.UIScale:Revert()
	stub.in_combat = true
	lines = printed_by(function() SlashCmdList.SAFTUI(' Scale  RESET ') end)
	stub.in_combat = false
	eq(st.config.global.uiScale, nil, 'in combat: saved at once')
	check(lines[1] and lines[1]:find('goes back to Automatic at 100% when combat ends', 1, true), 'in combat: ' .. tostring(lines[1]))
	eq(#take_errors(), 0, 'no errors')
end)

test('without the prompt the other forms say so and change nothing', function()
	stub.in_combat = false
	st.config.global.uiScale = nil
	for _, form in ipairs({ 'scale', 'scale 90', 'scale pixel' }) do
		local lines = printed_by(function() SlashCmdList.SAFTUI(form) end)
		check(lines[1] and lines[1]:find("Keep prompt didn't load", 1, true) and lines[1]:find('/sui scale reset', 1, true), form .. ': ' .. tostring(lines[1]))
		eq(st.UIScale:IsPreviewing(), false, form .. ': no preview')
	end
end)
