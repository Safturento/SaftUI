--[[
	One of Blizzard's chat windows (FloatingChatFrameTemplate, ChatFrame.xml and
	ChatFrameEditBox.xml), as far as SaftUI-Chat's CHT:SkinChatFrame and the
	hooks drive it. Load it with
	`local CW = load_test_file('chat/fixtures/chat_window.lua')`, then
	CW.build(id) makes ChatFrame<id> with what Blizzard's XML makes around it:

	  - the window (a Frame), its edit box ChatFrame<id>EditBox (an EditBox with
	    its Header and HeaderSuffix font strings, as _G names), its tab
	    ChatFrame<id>Tab (a Button with its Text, as the tab's parentKey) and a
	    ScrollBar, ScrollToBottomButton, Background, RightTexture and ButtonFrame,
	    all in _G;
	  - the edit box's own OnShow and OnHide (ChatFrameEditBoxMixin:OnShow and
	    OnHide), set the way the game's XML sets them, counted in CW.ran: SaftUI
	    must add to them, not replace them;
	  - GeneralDockManager (the dock's frame, in _G once for every window).

	The window, its edit box and its tab are locked (lib/locked_widget.lua), so a
	skin that writes a field onto one, or SetScripts the edit box or the tab,
	fails. The window's SetScript is open for the wheel's script only: SaftUI's wheel handler
	(CHT's onMouseScroll) replaces Blizzard's, which is the owner's call
	(docs/followups.md, "Chat writes fields and scripts onto Blizzard's chat
	frames"). Everything the skin kills or strips (the Kill helpers write fields
	onto what they take: a separate followup) and the scroll bar are not locked.
]]

local locked = load_test_file('lib/locked_widget.lua')

local CW = { ran = { show = 0, hide = 0 } }

-- The keys a table has, as a sorted list in text.
function CW.keys(widget)
	local out = {}
	for key in pairs(widget) do out[#out + 1] = tostring(key) end
	table.sort(out)
	return table.concat(out, ',')
end

function CW.build(id)
	local name = 'ChatFrame' .. id
	local methods
	-- An EditBox stands in for the ScrollingMessageFrame: it has the font methods
	-- (tests/chat/font_test.lua does the same).
	local frame = CreateFrame('EditBox', name, UIParent)
	frame:SetSize(400, 200)
	frame:SetPoint('CENTER')
	methods = getmetatable(frame).__index

	-- The ScrollingMessageFrame methods SkinChatFrame calls (the stubs have no such
	-- widget; the game's are the widget's own, not fields).
	rawset(frame, 'SetFading', function() end)

	-- Frames SaftUI kills, strips or skins (not locked, see the header).
	rawset(frame, 'ScrollBar', CreateFrame('Frame', nil, frame))
	frame.ScrollBar.ThumbTexture = frame.ScrollBar:CreateTexture()
	frame.ScrollBar.ScrollUpButton = frame.ScrollBar:CreateTexture()
	frame.ScrollBar.ScrollDownButton = frame.ScrollBar:CreateTexture()
	rawset(frame, 'ScrollToBottomButton', CreateFrame('Button', nil, frame))
	_G[name .. 'Background'] = frame:CreateTexture(name .. 'Background')
	_G[name .. 'RightTexture'] = frame:CreateTexture(name .. 'RightTexture')
	_G[name .. 'ButtonFrame'] = CreateFrame('Frame', name .. 'ButtonFrame', frame)

	local editbox = CreateFrame('EditBox', name .. 'EditBox', frame)
	editbox:SetSize(400, 32)
	editbox:CreateFontString(name .. 'EditBoxHeader')
	editbox:CreateFontString(name .. 'EditBoxHeaderSuffix')
	-- The stubs have no SetAltArrowKeyMode (the game's is the widget's own method).
	rawset(editbox, 'SetAltArrowKeyMode', function() end)
	editbox:Hide()
	editbox:SetScript('OnShow', function() CW.ran.show = CW.ran.show + 1 end)
	editbox:SetScript('OnHide', function() CW.ran.hide = CW.ran.hide + 1 end)

	local tab = CreateFrame('Button', name .. 'Tab', UIParent)
	tab:SetSize(60, 20)
	rawset(tab, 'Text', tab:CreateFontString(name .. 'TabText'))

	if not _G.GeneralDockManager then
		_G.GeneralDockManager = CreateFrame('Frame', 'GeneralDockManager', UIParent)
	end

	locked(frame, 'Blizzard chat window')
	locked(editbox, 'Blizzard chat edit box')
	locked(tab, 'Blizzard chat tab')
	-- The wheel handler is allowed (see the header); no other script of the window.
	rawset(frame, 'SetScript', function(self, script, fn)
		if script ~= 'OnMouseWheel' then
			error('SetScript ' .. tostring(script) .. ' on a Blizzard chat window frame', 2)
		end
		return methods.SetScript(self, script, fn)
	end)
	return frame, editbox, tab
end

return CW
