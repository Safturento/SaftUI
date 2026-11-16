-- The tracker's quest item button under Blizzard: StyleButton draws the
-- backdrop (placed the action inset outside the button), then anchors it on the
-- button itself. The ring fills the button, cut to the button's part of
-- Blizzard's art, as the own-color piece does.
local RW = load_test_file('tracker/rows_world.lua')
local Q = RW.Q
local T = load_test_file('lib/theme_helpers.lua')

local function log(ids)
	local entries = { Q.header('Elwynn Forest') }
	for _, id in ipairs(ids) do
		entries[#entries + 1] = Q.quest(id, {
			item = { link = 'item:' .. (1000 + id), texture = 134400 + id, charges = 0 },
			objectives = { { text = '1/2 Wolves', type = 'monster' } },
		})
	end
	Q.set(entries, ids)
end

test("under Blizzard the quest item button's ring and own-color piece fill the button, cut to 45/46", function()
	local st, TR = RW.world({ enabling = function() log({ 1 }) end })
	T.theme('blizzard', function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
	local b = TR:GetItemButton(1)
	local art = st.ThemeArt.Get(b.backdrop)
	local cut = T.text(0, 0, 0, 1, 45 / 46, 0, 45 / 46, 1)
	for name, piece in pairs({ ring = art.over.Ring, own = art.own }) do
		eq(T.around(piece, b), '0,0,0,0', name .. ' fills the button')
		eq(T.text(piece:GetTexCoord()), cut, name .. ' is cut to the button\'s part')
	end
	take_errors()
end)
