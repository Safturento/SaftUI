-- A quest's wrapped text is as tall as the game draws it (fb-tracker-wrap): the
-- heights the rows keep per text and width stand only while the game would
-- answer the same, so a change of the UI scale, which moves where the game
-- wraps a text (glyph widths snap to whole pixels), asks them again.
--
-- Modelled, truthfully to what the client does and the stub doesn't: a font
-- string wraps to a number of lines that depends on its effective scale (here:
-- 2 lines at the scale the test starts at, 3 at any other); the stub's own wrapping is by a fixed
-- character width and knows no scale.
local RW = load_test_file('tracker/rows_world.lua')
local Q = RW.Q

local LONG = "Go to Sven's Farm and find what was buried behind the old stump."

local function scaled_wrap(home)
	local methods = getmetatable(UIParent:CreateFontString(nil, 'OVERLAY')).__index
	local original = methods.GetStringHeight
	local calls = 0
	methods.GetStringHeight = function(self)
		local height = original(self)
		if self.GetText and self:GetText() == LONG then
			calls = calls + 1
			local _, size = self:GetFont()
			return (self:GetEffectiveScale() == home and 2 or 3) * (size or 12)
		end
		return height
	end
	return function() methods.GetStringHeight = original end, function() return calls end
end

RW.both("a change of the UI scale measures the quests' texts again: a row is as tall as the text draws", function(st, TR)
	local home = UIParent:GetScale()
	local restore = scaled_wrap(home)
	local ok, err = pcall(function()
		Q.set({ Q.header('Duskwood'), Q.quest(25, { objectives = { { text = LONG } } }) }, { 25 })
		stub.real_zone_text = 'Duskwood'
		TR:Refresh()
		local row = RW.quest(TR, 25)
		local before = row:GetHeight()
		local part = TR:Part(row, 1).fs
		eq(part:GetStringHeight(), 2 * select(2, part:GetFont()), 'two lines at first')
		UIParent:SetScale(0.8)
		TR:UpdateConfig()
		local after = row:GetHeight()
		local _, size = part:GetFont()
		eq(after - before, size, 'a third line was measured, and the row is one line taller')
		eq(part:GetStringHeight(), 3 * size, 'what the text draws is what the row holds')
	end)
	restore()
	UIParent:SetScale(home)
	if not ok then error(err, 0) end
end)
