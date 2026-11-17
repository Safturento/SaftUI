-- The range's slider and value box must be what the mouse lands on in /sui: a slider under
-- its row's frame (the row takes the mouse) or any frame drawn above it shows no hover or
-- held knob, whatever the states helper does. Each shown range's slider and box get the
-- mouse focus at their centres, so the engine fires their scripts. The widget frame's level is
-- set after its parent is (W.Create), and a frame level set on a parent need not reach its
-- children in the client, so the range puts its own children above its frame (Bind).
--
-- Real: the /sui window and its widgets (options_window_helpers.lua), the real Theme and
-- Colors modules and the states engine. The stub's mouse focus is the topmost visible
-- mouse-enabled frame under the cursor (strata, then level, then creation order).
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OW = st.OptionsWindow
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

local function put_cursor_on(frame)
	local x, y = frame:GetCenter()
	local scale = frame:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = x * scale, y * scale
end

test("a shown range's slider and value box are above their row: they get the mouse", function()
	H.theme('thin')
	st.Config:Open('Fonts', 'general')
	local seen = 0
	for _, c in ipairs(OW.GetDrawnRows()) do
		local w = c.widget
		if w and w.type == 'range' then
			seen = seen + 1
			for name, frame in pairs({ slider = w.slider, box = w.edit }) do
				put_cursor_on(frame)
				check(frame:IsMouseMotionFocus(), c.row.name .. ': the ' .. name .. ' has the mouse at its centre (level '
					.. frame:GetFrameLevel() .. ', its widget frame ' .. w.frame:GetFrameLevel() .. ', its row ' .. c.frame:GetFrameLevel() .. ')')
			end
		end
	end
	check(seen > 0, 'a range is drawn')
	H.close_all()
end)

test('a released range acquired again by another row is above that row too', function()
	H.theme('thin')
	st.Config:Open('Fonts', 'general')
	H.close_all()
	st.Config:Open('Fonts', 'general')
	for _, c in ipairs(OW.GetDrawnRows()) do
		local w = c.widget
		if w and w.type == 'range' then
			put_cursor_on(w.slider)
			check(w.slider:IsMouseMotionFocus(), c.row.name .. ': the slider has the mouse after the window is opened again')
		end
	end
	H.close_all()
end)
