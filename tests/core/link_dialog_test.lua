-- The /link copy dialog (SaftUI-Core/utilities.lua, EXTRACT_LINK_DIALOG).
-- Its edit box is Blizzard's, so the dialog must not SetScript on it. Blizzard
-- calls the dialog definition's EditBoxOnTextChanged / EditBoxOnEscapePressed
-- as (editBox, data) (Blizzard_StaticPopup/SharedTemplates.lua, forever branch):
-- no userInput flag, and data is the link given to StaticPopup_Show. The stub
-- dialog below plays Blizzard's part: it owns the edit box scripts and
-- forwards to the definition the same way.

local def = StaticPopupDialogs.EXTRACT_LINK_DIALOG
local LINK = '|cff0070dd|Hitem:6948::::::::1:::::::|h[Hearthstone]|h|r'
local ESCAPED = '\\124cff0070dd\\124Hitem:6948::::::::1:::::::\\124h[Hearthstone]\\124h\\124r'

-- Stand-in for Blizzard's StaticPopup_Hide: hides the shown dialog.
local shown
function StaticPopup_Hide(which)
	assert(which == 'EXTRACT_LINK_DIALOG', 'unexpected dialog ' .. tostring(which))
	if shown then shown:Hide() end
end

local script_calls
local function make_dialog(with_get_edit_box)
	local popup = CreateFrame('Frame', 'StaticPopupTest', UIParent)
	local box = CreateFrame('EditBox', 'StaticPopupTestEditBox', popup)
	popup.data = LINK
	-- Blizzard's own handlers, set before the dialog's code runs.
	box:SetScript('OnTextChanged', function(self)
		def.EditBoxOnTextChanged(self, popup.data)
	end)
	box:SetScript('OnEscapePressed', function(self)
		def.EditBoxOnEscapePressed(self, popup.data)
	end)
	-- From here, any SetScript on the box is the dialog's doing.
	script_calls = {}
	box.SetScript = function(self, ...)
		script_calls[#script_calls + 1] = { ... }
	end
	if with_get_edit_box then popup.GetEditBox = function() return box end end
	shown = popup
	return popup, box
end

local function show(popup)
	def.OnShow(popup, LINK)
end

test('OnShow sets the escaped link and highlights it', function()
	local popup, box = make_dialog(true)
	show(popup)
	eq(box:GetText(), ESCAPED, 'text')
	local h = stub.state(box).highlight
	check(h and h[1] == 0 and h[2] == -1, 'all text highlighted')
	eq(#script_calls, 0, 'SetScript calls')
end)

test('OnShow finds the edit box by name without GetEditBox', function()
	local popup, box = make_dialog(false)
	show(popup)
	eq(box:GetText(), ESCAPED, 'text')
end)

test('typing is reverted to the link', function()
	local popup, box = make_dialog(true)
	show(popup)
	box:SetText('typed over it') -- the stub fires OnTextChanged(self, false)
	eq(box:GetText(), ESCAPED, 'after a change')
	stub.fire_script(box, 'OnTextChanged', true)
	eq(box:GetText(), ESCAPED, 'after user input')
	box:SetText('')
	eq(box:GetText(), ESCAPED, 'after clearing')
	eq(#script_calls, 0, 'SetScript calls')
end)

test('Esc hides the dialog', function()
	local popup, box = make_dialog(true)
	popup:Show()
	show(popup)
	check(popup:IsShown(), 'shown before Esc')
	stub.fire_script(box, 'OnEscapePressed')
	check(not popup:IsShown(), 'hidden after Esc')
end)

test('no SetScript on the edit box, and Blizzard keeps its handlers', function()
	local popup, box = make_dialog(true)
	show(popup)
	box:SetText('x')
	stub.fire_script(box, 'OnEscapePressed')
	eq(#script_calls, 0, 'SetScript calls')
	check(box:GetScript('OnTextChanged') ~= nil, 'OnTextChanged still set')
	check(box:GetScript('OnEscapePressed') ~= nil, 'OnEscapePressed still set')
end)

test('the slash command shows the dialog with the link as data', function()
	local got
	function StaticPopup_Show(...) got = { ... } end
	SlashCmdList.EXTRACT_LINK(LINK)
	eq(got[1], 'EXTRACT_LINK_DIALOG', 'dialog')
	eq(got[4], LINK, 'data')
end)
