-- Chat's font conversion on the profile changes the game really makes: a switch
-- to a stored profile with an old Font size, a copy from one, a reset, on a real
-- AceDB-3.0 and Core's real Config:UpdateConfig (core/config_helpers.lua), which
-- re-points the modules and runs st:FontsChanged before any module's UpdateConfig.
--
-- Stand-ins as tests/chat/font_test.lua: the chat windows are EditBoxes.
load_test_file('core/config_helpers.lua')
load_saftui('SaftUI-Chat/config.lua')
local st = SaftUI
load_saftui('SaftUI-Chat/chatframe.lua')
local CHT = st:GetModule('Chat')

NUM_CHAT_WINDOWS = 2
local frames = {}
for i = 1, 2 do
	frames[i] = CreateFrame('EditBox', 'ChatFrame' .. i, UIParent)
	frames[i]:SetSize(400, 200)
	frames[i]:SetPoint('CENTER')
end
CHT.holder = CreateFrame('Frame', nil, UIParent)
CHT.holder:SetSize(400, 200)
CHT.holder:SetPoint('CENTER')

local function path(name) return st.LSM:Fetch('font', name) end
local function size_of(frame) return select(2, frame:GetFont()) end

-- A stored profile whose chat has an old Font size, made through the database.
local first = st.config:GetCurrentProfile()
local function stored(name, fontsize)
	st.config:SetProfile(name)
	local chat = st.config.profile.chat
	chat.fontsize, chat.fontsVersion = fontsize, nil
	chat.width, chat.height = 400, 200
	return chat
end

test('a switch to a stored profile with an old Font size converts it and draws it', function()
	st:BindModuleConfig(CHT, 'chat')
	stored('ChatFontOld', 14)
	st.config:SetProfile(first)
	st.config:SetProfile('ChatFontOld')
	local chat = st.config.profile.chat
	eq(CHT.config, chat, 'chat is bound to the new profile')
	eq(type(chat.font), 'table', 'a typeface')
	eq(chat.font.font_size, 14, 'at the old Font size')
	eq(rawget(chat, 'fontsize'), nil, 'fontsize is gone')
	eq(chat.fontsVersion, 1, 'marked')
	eq(size_of(frames[1]), 14, 'ChatFrame1 draws at 14')
	eq(size_of(frames[2]), 14, 'ChatFrame2 too')
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile already converted is left; a copy from an unconverted one converts', function()
	st.config:SetProfile('ChatFontOld')
	local chat = st.config.profile.chat
	chat.fontsize = 5 -- not read: marked
	st.config:SetProfile(first)
	st.config:SetProfile('ChatFontOld')
	eq(type(st.config.profile.chat.font), 'table', 'the typeface stays')
	eq(st.config.profile.chat.font.font_size, 14, 'not 5')

	stored('ChatFontSource', 12)
	st.config:SetProfile('ChatFontCopy')
	st.config:CopyProfile('ChatFontSource')
	chat = st.config.profile.chat
	eq(type(chat.font), 'table', 'the copy converted')
	eq(chat.font.font_size, 12, 'at its Font size')
	eq(size_of(frames[1]), 12, 'and draws it')
	eq(#take_errors(), 0, 'no errors')
end)

test('a reset profile is unmarked, converts again and writes nothing on the defaults', function()
	st.config:SetProfile('ChatFontReset')
	st.config:ResetProfile()
	local chat = st.config.profile.chat
	eq(chat.font, 'normal', 'chat follows Text')
	eq(chat.fontsVersion, 1, 'marked again')
	eq(size_of(frames[1]), 16, 'Text at 16')
	eq(#take_errors(), 0, 'no errors')
	st.config:SetProfile(first)
end)
