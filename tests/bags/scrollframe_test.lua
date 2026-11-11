-- st:CreateScrollFrame and st:ScrollBarRoom (SaftUI-Core/Widgets/scrollframe.lua),
-- which the bag windows are built on: the scroll bar hides itself when there is
-- nothing to scroll (Blizzard's ScrollFrameTemplate leaves it showing), and the
-- room it takes past the scroll frame is read from its real anchor and width.
--
-- Made by hand: ScrollFrameTemplate's ScrollFrame_OnLoad (the scroll bar it
-- makes, anchored as SCROLL_FRAME_SCROLL_BAR_OFFSET_LEFT says, with the one
-- Blizzard method used, SetHideIfUnscrollable) and the scroll bar skin
-- (SaftUI-Core/Widgets/scrollbar.lua, a no-op here).
reset_world()
load_core_helpers()
load_saftui('SaftUI-Core/Widgets/scrollframe.lua')
local st = SaftUI

local function frame_with_bar(offset, width)
	local createFrame = CreateFrame
	_G.CreateFrame = function(frameType, name, parent, template, ...)
		local f = createFrame(frameType, name, parent, nil, ...)
		if template == 'ScrollFrameTemplate' then
			local bar = createFrame('Frame', nil, f)
			bar:SetWidth(width)
			bar:SetPoint('TOPLEFT', f, 'TOPRIGHT', offset, -2)
			bar:SetPoint('BOTTOMLEFT', f, 'BOTTOMRIGHT', offset, 5)
			bar.SetHideIfUnscrollable = function(self, hide) self.hideIfUnscrollable = hide end
			f.ScrollBar = bar
		end
		return f
	end
	st.SkinScrollBar = function() end
	local f = st:CreateScrollFrame(UIParent)
	_G.CreateFrame = createFrame
	return f
end

test('the scroll bar hides itself when there is nothing to scroll', function()
	local f = frame_with_bar(6, 8)
	eq(f.ScrollBar.hideIfUnscrollable, true, 'hidden if unscrollable')
	eq(#take_errors(), 0, 'no errors')
end)

test("the room the bar takes is read from its anchor and width", function()
	eq(st:ScrollBarRoom(frame_with_bar(6, 8)), 14, "Blizzard's 6 and 8")
	eq(st:ScrollBarRoom(frame_with_bar(4, 10)), 14, 'another offset and width, summed')
	eq(st:ScrollBarRoom(frame_with_bar(3, 8)), 11, 'a nearer bar needs less')
	eq(st:ScrollBarRoom({}), 0, 'no bar, no room')
	eq(#take_errors(), 0, 'no errors')
end)
