-- What a body drawn at half must keep of its section notes (a note wraps to the
-- body's width and its height goes into the layout): none cut, and none
-- over the rows under it. Loaded with local N = load_test_file('lib/halfnotes.lua')
-- (no globals); the checks are the runner's eq and check.
--
-- N.check(body, where) -> the number of notes it checked
local N = {}

function N.check(body, where)
	local count = 0
	for _, note in ipairs(body.pools.note.used) do
		count = count + 1
		local width = body.width
		check(note:CanWordWrap(), where .. ': the note wraps')
		eq(math.floor(note:GetWidth() + 0.5), width, where .. ': at the body\'s width')
		local _, _, _, _, y = note:GetPoint(1)
		local top, bottom = -y, -y + note:GetStringHeight()
		for _, cell in ipairs(body.cells) do
			if cell.y and cell.height then
				check(cell.y >= bottom or cell.y + cell.height <= top + 2, where .. ': ' .. tostring(cell.row.key) .. ' clear of the note')
			end
		end
	end
	return count
end

return N
