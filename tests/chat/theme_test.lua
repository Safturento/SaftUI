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
local T = load_test_file('lib/theme_draws.lua')
local drawn = T.watch()
for _, file in ipairs({ 'editmode', 'mover', 'picker', 'footer', 'grid', 'snap', 'settings' }) do
	load_saftui('SaftUI-Core/EditMode/' .. file .. '.lua') -- EditMode/load.xml's order
end
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

	local general = CHT:GetConfigTable().args.general
	T.check_options(general, 'Chat')
	eq(general.get({ 'theme' }), 'theme', 'Theme reads chat.theme')
	eq(general.get({ 'background' }), 'theme', 'Background reads chat.background')
	general.set({ 'theme' }, 'thin')
	general.set({ 'background' }, 'solid')
	eq(profile.chat.theme, 'thin', 'Theme writes chat.theme')
	eq(profile.chat.background, 'solid', 'Background writes chat.background')
	eq(applied, 2, 'each restyles the chat windows at once')

	CHT.ApplyAppearance = apply
	profile.chat.theme, profile.chat.background = 'theme', 'theme'
end)

-- A chat window as SkinChatFrame leaves it (the frame and its tab are Blizzard's).
local function chat_frame()
	local frame = CreateFrame('Frame', 'ChatFrame7', UIParent)
	frame:SetSize(400, 200)
	frame:SetPoint('CENTER')
	frame.Tab = CreateFrame('Button', 'ChatFrame7Tab', frame)
	return frame
end

test("a chat window's backdrop is a panel in chat's Theme and Background, the padding outside it", function()
	local frame = chat_frame()
	CHT:UpdateChatFrameDisplay(frame)
	eq(drawn(frame), 'theme,theme,panel', "chat's Theme and Background, as a panel")
	eq(T.inset(frame.backdrop), 2, "Thick's border")
	eq(T.offset(frame.backdrop, 'TOPLEFT'), '-10.00,10.00', 'the padding outside the window')
	eq(drawn(frame.Tab), nil, 'the tab gets no backdrop')

	profile.chat.theme, profile.chat.background = 'thin', 'transparent'
	CHT:UpdateChatFrameDisplay(frame)
	eq(drawn(frame), 'thin,transparent,panel', 'a new Theme and Background')
	eq(T.inset(frame.backdrop), 1, "Thin's border")
	eq(T.offset(frame.backdrop, 'TOPLEFT'), '-10.00,10.00', 'still the padding outside the window')

	profile.chat.theme = 'none'
	CHT:UpdateChatFrameDisplay(frame)
	eq(frame.backdrop.backdropInfo, nil, 'None draws none')
	profile.chat.theme, profile.chat.background = 'theme', 'theme'
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
