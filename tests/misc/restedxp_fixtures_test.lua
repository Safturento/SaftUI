-- The RestedXP and LibCandyBar fixtures' own checks: what they lock, and what
-- they leave to the addon they stand in for. If the lock stops catching a
-- skin that writes onto RestedXP's frames, the restedxp_*_test.lua files
-- would pass where the game breaks the addon.
local H = load_test_file('misc/restedxp_helpers.lua')
local RXP = H.RXP
local Timers = load_test_file('misc/fixtures/libcandybar.lua')

test("a RestedXP frame refuses a skin's fields and scripts, and keeps its own ways", function()
	H.fresh()
	local R = RXP.make()
	local guide = R.GuideName
	local ok, err = pcall(function() guide.skinned = true end)
	eq(ok, false, 'a new field errors')
	check(tostring(err):find('skin wrote field "skinned" onto a RestedXP frame', 1, true), 'naming the field: ' .. tostring(err))
	ok, err = pcall(guide.SetScript, guide, 'OnShow', function() end)
	eq(ok, false, 'SetScript errors')
	check(tostring(err):find('SetScript on a RestedXP frame', 1, true), 'naming the call: ' .. tostring(err))
	-- a real st:SetBackdrop writes backdrop and thick onto its frame
	ok = pcall(SaftUI.SetBackdrop, SaftUI, guide, 'thick')
	eq(ok, false, 'so st:SetBackdrop on one errors')

	guide._state = 1
	eq(guide._state, 1, 'a fixture field starting with _ is allowed')
	local hooked = 0
	guide:HookScript('OnShow', function() hooked = hooked + 1 end)
	guide:Hide()
	guide:Show()
	eq(hooked, 1, 'HookScript hooks run')
	hooksecurefunc(guide, 'SetHeight', function() end)
	guide:SetHeight(40)
	eq(guide:GetHeight(), 40, 'hooksecurefunc hooks a method')
	guide:SetBackdrop({ bgFile = 'bg' })
	check(guide.backdropInfo ~= nil, "Blizzard's backdrop code can write backdropInfo")

	check(RXP.is_rxp(guide), 'it is RestedXP\'s')
	check(not RXP.is_rxp(SaftUI:CreateFrame('Frame', nil, R)), 'a SaftUI frame is not')
end)

test('LibCandyBar is registered with LibStub, and its bars are locked', function()
	H.fresh()
	eq(LibStub('LibCandyBar-3.0', true), nil, 'not there until the fixture builds it')
	local candy = Timers.make_candy()
	check(LibStub('LibCandyBar-3.0', true) == candy, 'registered once built')
	local bar = candy:New('tex', 100, 16)
	local ok, err = pcall(function() bar.skinned = true end)
	eq(ok, false, 'a new field on a bar errors')
	check(tostring(err):find('onto a LibCandyBar frame', 1, true), 'naming the addon: ' .. tostring(err))
	ok = pcall(function() bar.candyBarBar.skinned = true end)
	eq(ok, false, 'and on its parts')
	bar:SetLabel('x')
	eq(bar:GetLabel(), 'x', 'the library can still label it')

	H.fresh()
	Timers.make_candy(false)
	eq(LibStub('LibCandyBar-3.0', true), nil, 'make_candy(false) leaves it unregistered')
end)
