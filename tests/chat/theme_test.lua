-- SaftUI-Chat with SaftUI's themes (SaftUI-Core/theme.lua):
--   - chat's default looks as its old template name did;
--   - the Chat page offers Theme and Background, not Template;
--   - a chat window's backdrop is drawn as a panel in chat's Theme and
--     Background, the padding outside the window, and None draws none; its tab
--     gets no backdrop, as before;
--   - edit mode's outline sits on the backdrop's border, or on the chat itself
--     under None.
--
-- Real: SaftUI-Chat's config.lua, chatframe.lua and options.lua, Core's helpers,
-- the theme engine and edit mode.
load_core_helpers()
local T = load_test_file('lib/theme_helpers.lua')
local drawn = T.watch()
load_editmode()
load_saftui('SaftUI-Core/Widgets/scrollbar.lua') -- st:SkinScrollBar, which SkinChatFrame calls
load_saftui('SaftUI-Chat/config.lua')
apply_defaults()
load_saftui('SaftUI-Chat/chatframe.lua')
load_saftui('SaftUI-Chat/options.lua')

local st = SaftUI
local CHT = st:GetModule('Chat')
st:BindModuleConfig(CHT, 'chat')
local profile = st.config.profile

test('chat defaults look as they did', function()
	T.check_default(profile.chat, 'thicktransparent', 'chat') -- base commit 7ec1df8
end)

test('each page offers Theme and Background, not Template', function()
	CHT.holder = CreateFrame('Frame', nil, UIParent) -- SaftUI's, made by OnEnable
	-- Reaches every ChatFrame1..N, Blizzard's; counted.
	local applied = 0
	local apply = CHT.ApplyAppearance
	function CHT:ApplyAppearance() applied = applied + 1 end

	T.check_theme_page({
		group = CHT:GetConfigTable().args.general, where = 'Chat', config = profile.chat, path = 'chat',
		reads = { { 'theme', 'theme' }, { 'background', 'theme' } },
		writes = { { 'theme', 'thin' }, { 'background', 'solid' } },
	})
	eq(applied, 2, 'each restyles the chat windows at once')

	CHT.ApplyAppearance = apply
	profile.chat.theme, profile.chat.background = 'theme', 'theme'
end)

-- A chat window as SkinChatFrame leaves it (the frame and its tab are Blizzard's).
-- The backdrop is SaftUI's, in the module's own table: st:DrawnFrame finds it.
local CW = load_test_file('chat/fixtures/chat_window.lua')
local function chat_frame()
	local frame, _, tab = CW.build(7)
	return frame, tab
end

test("a chat window's backdrop is a panel in chat's Theme and Background, the padding outside it", function()
	local frame, tab = chat_frame()
	CHT:UpdateChatFrameDisplay(frame)
	local backdrop = st:DrawnFrame(frame)
	check(backdrop ~= nil and backdrop ~= frame, "SaftUI's own frame is drawn behind the window")
	eq(drawn(frame), 'theme,theme,panel', "chat's Theme and Background, as a panel")
	eq(T.inset(backdrop), 2, "Thick's border")
	eq(T.offset(backdrop, 'TOPLEFT'), '-10.00,10.00', 'the padding outside the window')
	eq(drawn(tab), nil, 'the tab gets no backdrop')
	eq(backdrop:GetParent(), frame, 'a child of the window, as before')
	eq(backdrop:GetFrameLevel(), math.max(0, frame:GetFrameLevel() - 1), 'one level under it, as before')

	profile.chat.theme, profile.chat.background = 'thin', 'transparent'
	CHT:UpdateChatFrameDisplay(frame)
	eq(drawn(frame), 'thin,transparent,panel', 'a new Theme and Background')
	eq(T.inset(backdrop), 1, "Thin's border")
	eq(T.offset(backdrop, 'TOPLEFT'), '-10.00,10.00', 'still the padding outside the window')

	profile.chat.theme = 'none'
	CHT:UpdateChatFrameDisplay(frame)
	eq(backdrop.backdropInfo, nil, 'None draws none')
	profile.chat.theme, profile.chat.background = 'theme', 'theme'
end)

-- What SkinChatFrame does to Blizzard's chat window, edit box and tab: no field
-- written onto any of them, and no script replaced but the wheel's (.agents/taint.md,
-- rules 1 and 2). The fixture locks all three, so a write fails the case where it
-- happens; the keys compared here are the ones the fixture's own rawsets would hide.
test("skinning a chat window writes no field onto Blizzard's window, edit box or tab", function()
	local frame, editbox, tab = CW.build(8)
	local before = { CW.keys(frame), CW.keys(editbox), CW.keys(tab) }
	CHT:SkinChatFrame(frame)
	eq(CW.keys(frame), before[1], "the chat window's keys")
	eq(CW.keys(editbox), before[2], "the edit box's keys")
	-- The one new key is hooksecurefunc's wrapper for SetAlpha (a secure post-hook, as
	-- .agents/taint.md allows), made while fading is off.
	check(stub.hook_wrappers[rawget(tab, 'SetAlpha')], "the tab's SetAlpha is only a hooksecurefunc wrapper")
	rawset(tab, 'SetAlpha', nil)
	eq(CW.keys(tab), before[3], "the tab's keys")
	check(st:DrawnFrame(frame) ~= nil, "the window is drawn behind all the same")
end)

test("the edit box keeps Blizzard's OnShow and OnHide, and SaftUI's hide and show the dock after them", function()
	local frame, editbox = CW.build(9)
	CHT:SkinChatFrame(frame)
	CW.ran.show, CW.ran.hide = 0, 0
	GeneralDockManager:Show()
	editbox:Show()
	eq(CW.ran.show, 1, "Blizzard's OnShow ran")
	check(not GeneralDockManager:IsShown(), 'the dock is hidden while the edit box shows')
	editbox:Hide()
	eq(CW.ran.hide, 1, "Blizzard's OnHide ran")
	check(GeneralDockManager:IsShown(), 'and shown again when it hides')
end)

-- ChatFrame1 is an Edit Mode system frame: Blizzard sets its clamp insets from its
-- Selection box on every layout apply (EditModeSystemMixin:UpdateClampOffsets), and
-- they're Blizzard's to keep (.agents/taint.md, rule 5). The other windows' stay SaftUI's.
test("skinning leaves ChatFrame1's clamp insets Blizzard's, and zeroes the other windows'", function()
	local frame1 = CW.build(1)
	_G.ChatFrame1 = frame1
	frame1:SetClampRectInsets(-32, 25, 60, -32) -- Blizzard's
	CHT:SkinChatFrame(frame1)
	eq(table.concat({ frame1:GetClampRectInsets() }, ','), '-32,25,60,-32', "ChatFrame1's band is Blizzard's")

	local frame2 = CW.build(2)
	frame2:SetClampRectInsets(-32, 25, 60, -32)
	CHT:SkinChatFrame(frame2)
	eq(table.concat({ frame2:GetClampRectInsets() }, ','), '0,0,0,0', "another window's is zeroed, as before")
	_G.ChatFrame1 = nil
end)

-- Tab fading is off by default (tabs.fade). Blizzard fades a tab through its own
-- SetAlpha (UIFrameFade, from FCF_FadeInChatFrame and FCF_FadeOutChatFrame, and
-- FCF_FadeInTabs), which SaftUI used to replace with UIFrameFadeRemoveFrame: a
-- tainted method called inside Blizzard's own fade loop. Now it is a post-hook that
-- puts alpha 1 back, reading the profile each time.
test("with tab fading off a Blizzard SetAlpha leaves the tab at 1, by a post-hook", function()
	local frame, _, tab = CW.build(10)
	local method = tab.SetAlpha
	CHT:SkinChatFrame(frame)
	check(stub.hook_wrappers[rawget(tab, 'SetAlpha')], "SetAlpha is hooksecurefunc's wrapper, not a function of SaftUI's")
	eq(tab:GetAlpha(), 1, 'alpha 1 at skin time')
	tab:SetAlpha(0.25) -- Blizzard's fade, a step
	eq(tab:GetAlpha(), 1, 'a fade step leaves it at 1')
	tab:SetAlpha(0) -- and its end
	eq(tab:GetAlpha(), 1, 'and so does the end of a fade out')
	eq(method, getmetatable(tab).__index.SetAlpha, "the widget's own SetAlpha is untouched")

	profile.chat.tabs.fade = true -- the profile is read each time
	tab:SetAlpha(0.25)
	eq(tab:GetAlpha(), 0.25, 'with fading on, Blizzard keeps the alpha it sets')
	profile.chat.tabs.fade = false
	tab:SetAlpha(0.5)
	eq(tab:GetAlpha(), 1, 'and with it off again, 1')
end)

test("with tab fading on SaftUI hooks nothing on the tab", function()
	profile.chat.tabs.fade = true
	local frame, _, tab = CW.build(11)
	CHT:SkinChatFrame(frame)
	eq(rawget(tab, 'SetAlpha'), nil, 'no SetAlpha hook')
	tab:SetAlpha(0.3)
	eq(tab:GetAlpha(), 0.3, 'Blizzard fades it')
	profile.chat.tabs.fade = false
end)

-- Tab fading (tabs.fade) follows the profile live: a profile switch or copy that turns
-- it off holds the tabs at 1 from then on, and one that turns it on lets Blizzard fade.
test("a profile change turns tab fading off and on without a reload", function()
	profile.chat.tabs.fade = true
	local frame, _, tab = CW.build(12)
	CHT:SkinChatFrame(frame)
	tab:SetAlpha(0.4)
	eq(rawget(tab, 'SetAlpha'), nil, 'fading on at skin time: nothing hooked')

	profile.chat.tabs.fade = false -- a switch to a profile that doesn't fade
	CHT:ApplyChatFrameConfig(frame)
	check(stub.hook_wrappers[rawget(tab, 'SetAlpha')], 'the post-hook is there now')
	eq(tab:GetAlpha(), 1, 'the tab is at 1 at once')
	tab:SetAlpha(0.2)
	eq(tab:GetAlpha(), 1, 'and stays there through a fade step')
	local hook = rawget(tab, 'SetAlpha')
	CHT:ApplyChatFrameConfig(frame)
	eq(rawget(tab, 'SetAlpha'), hook, 'a second apply adds no second hook')

	profile.chat.tabs.fade = true -- and back to one that fades
	CHT:ApplyChatFrameConfig(frame)
	tab:SetAlpha(0.2)
	eq(tab:GetAlpha(), 0.2, 'Blizzard fades it again')
	profile.chat.tabs.fade = false
end)

test("edit mode's outline sits on the chat's border, or on the chat under None", function()
	CHT.holder = CreateFrame('Frame', nil, UIParent)
	CHT.holder:SetSize(400, 200)
	CHT.holder:SetPoint('CENTER')
	CHT:RegisterChatMover()
	local overlay = CHT.mover.overlay
	local inset = profile.chat.padding - st.EditModeFrames.OutlineOutset()
	eq(T.offset(overlay, 'TOPLEFT'), T.text(-inset, inset), 'inside the padding by the outline')
	profile.chat.theme = 'none'
	CHT:UpdateFootprint()
	local point, _, _, x, y = overlay:GetPoint(1)
	check(point == 'TOPLEFT' and x == 0 and y == 0, 'on the chat itself under None')
	profile.chat.theme = 'theme'
end)
