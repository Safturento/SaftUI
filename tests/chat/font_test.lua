-- SaftUI-Chat's text on the shared fonts (SaftUI-Chat/chatframe.lua):
--   - chat's font setting is read through st:FontValues: the face, size,
--     outline and an opaque black shadow of Text (or of a typeface), at Blizzard's
--     line spacing (chat never sets one);
--   - the one-time conversion (CHT:ConvertFonts, marker chat.fontsVersion):
--     the old Font size row's value (fontsize, 16 when none) and the old forced
--     shadow of 0, 0 become a typeface only where chat's look differs from its
--     shared font, so chat looks as before after the upgrade;
--   - the Chat page has a Font row with Size, Outline and both shadows in its dots
--     and no Font size row;
--   - a change on the Fonts tab, or a profile update, reaches every chat window
--     at once (CHT:OnFontsChanged).
--
-- Real: SaftUI-Chat's config.lua, chatframe.lua and options.lua, Core's helpers
-- (the Fonts module's helpers and st:FontsChanged), edit mode.
-- Stand-ins: the chat windows are EditBoxes named ChatFrame1 and ChatFrame2 (the
-- stubs have no ScrollingMessageFrame, and ApplyChatFont calls only SetFont,
-- SetShadowColor and SetShadowOffset on one; chat never sets its spacing, so
-- neither does a window here).
local function world(client)
	use_client(client)
	load_core_helpers()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionsdefault.lua') -- st.Config.SavedIn, which the page's groups use
	load_editmode()
	load_saftui('SaftUI-Chat/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Chat/chatframe.lua')
	load_saftui('SaftUI-Chat/options.lua')
	local st = SaftUI
	local CHT = st:GetModule('Chat')
	st:BindModuleConfig(CHT, 'chat')
	CHT.holder = CreateFrame('Frame', nil, UIParent)
	CHT.holder:SetSize(400, 200)
	CHT.holder:SetPoint('CENTER')
	NUM_CHAT_WINDOWS = 2
	local frames = {}
	for i = 1, 2 do
		frames[i] = CreateFrame('EditBox', 'ChatFrame' .. i, UIParent)
		frames[i]:SetSize(400, 200)
		frames[i]:SetPoint('CENTER')
		_G['ChatFrame' .. i] = frames[i]
	end
	return st, CHT, st.config.profile, frames
end

local st, CHT, profile, frames
local function path(name) return st.LSM:Fetch('font', name) end

local function drawn(frame)
	local face, size, flags = frame:GetFont()
	local x, y = frame:GetShadowOffset()
	return { face = face, size = size, flags = flags, x = x, y = y }
end

local function eqdrawn(frame, face, size, flags, x, y, message)
	local d = drawn(frame)
	eq(d.face, path(face), message .. ': face')
	eq(d.size, size, message .. ': size')
	eq(d.flags, flags, message .. ': outline')
	eq(d.x .. ',' .. d.y, x .. ',' .. y, message .. ': shadow')
	local r, g, b, a = frame:GetShadowColor()
	eq(r + g + b, 0, message .. ': a black shadow')
	eq(a, 1, message .. ': opaque')
end

-- A profile as the game hands it after an upgrade: the old Font size row's value
-- saved (or not, at its old default of 16, which AceDB never saves), and the
-- font setting as given.
local function old_profile(font, fontsize)
	profile.chat.font, profile.chat.fontsize, profile.chat.fontsVersion = font, fontsize, nil
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': as shipped: nothing written, chat follows Text; fontsize cleared and the profile marked', function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', nil)
		eq(CHT.OLD_FONT_SIZE, 16, "the old Font size's default")
		eq(CHT:ConvertFonts(), true, 'it converted')
		eq(profile.chat.font, 'normal', 'chat still follows Text')
		eq(rawget(profile.chat, 'fontsize'), nil, 'fontsize is gone')
		eq(profile.chat.fontsVersion, 1, 'the profile is marked')
		CHT:ApplyChatFont(frames[1])
		eqdrawn(frames[1], 'AgencyFB Bold', 16, 'OUTLINE', 0, 0, 'ChatFrame1')
		eq(frames[1]:GetSpacing(), 0, "chat leaves Blizzard's line spacing alone")
		eq(CHT:ConvertFonts(), false, 'a second run does nothing')
		eq(profile.chat.font, 'normal', 'and writes nothing')
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ': ' .. "a Font size of 14 keeps chat's look as a typeface", function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', 14)
		CHT:ConvertFonts()
		local font = profile.chat.font
		eq(type(font), 'table', 'a typeface')
		eq(font.font_name, 'AgencyFB Bold', 'in Text\'s face')
		eq(font.font_size, 14, 'at the old size')
		eq(font.font_outline, 'OUTLINE', "with Text's outline")
		eq(font.shadow_offset[1] .. ',' .. font.shadow_offset[2], '0,0', 'and the shadow chat forced')
		eq(font.spacing, 4, "and Text's own spacing, which chat never reads")
		eq(rawget(profile.chat, 'fontsize'), nil, 'fontsize is gone')
		eq(profile.chat.fontsVersion, 1, 'marked')
		CHT:ApplyChatFont(frames[1])
		eqdrawn(frames[1], 'AgencyFB Bold', 14, 'OUTLINE', 0, 0, 'drawn at 14')
		eq(frames[1]:GetSpacing(), 0, 'no spacing')
	end)

	test(client .. ': ' .. 'Text at 18 with Font size left at 16 (G5): chat keeps 16, as a typeface', function()
		st, CHT, profile, frames = world(client)
		st.config.profile.fonts.normal.font_size = 18
		old_profile('normal', nil)
		CHT:ConvertFonts()
		eq(type(profile.chat.font), 'table', 'a typeface')
		eq(profile.chat.font.font_size, 16, 'at 16')
		CHT:ApplyChatFont(frames[1])
		eqdrawn(frames[1], 'AgencyFB Bold', 16, 'OUTLINE', 0, 0, 'still 16')
		st.config.profile.fonts.normal.font_size = nil
	end)

	test(client .. ': ' .. "Text's shadow set to 1, -1: chat keeps no shadow, as a typeface", function()
		st, CHT, profile, frames = world(client)
		st.config.profile.fonts.normal.shadow_offset = { 1, -1 }
		old_profile('normal', 16)
		CHT:ConvertFonts()
		eq(type(profile.chat.font), 'table', 'a typeface')
		eq(profile.chat.font.shadow_offset[1] .. ',' .. profile.chat.font.shadow_offset[2], '0,0', 'with no shadow')
		CHT:ApplyChatFont(frames[1])
		eqdrawn(frames[1], 'AgencyFB Bold', 16, 'OUTLINE', 0, 0, 'no shadow')
		st.config.profile.fonts.normal.shadow_offset = { 0, 0 }
	end)

	test(client .. ': ' .. 'chat on odd profiles (Review Focus 3)', function()
		st, CHT, profile, frames = world(client)
		-- A dropped font: Normal Med was 24; chat at 16 keeps what it drew.
		old_profile('normal_med', 16)
		CHT:ConvertFonts()
		eq(type(profile.chat.font), 'table', 'a dropped font at another size becomes a typeface')
		eq(profile.chat.font.font_name .. ' ' .. profile.chat.font.font_size, 'AgencyFB Bold 16', 'Agency 16')
		local once = st.config.profile.chat.font
		CHT:ConvertFonts()
		eq(profile.chat.font, once, 'run twice: nothing more')
		CHT:ApplyChatFont(frames[1])
		eqdrawn(frames[1], 'AgencyFB Bold', 16, 'OUTLINE', 0, 0, 'drawn')

		-- A key that names nothing: drawn as Text, kept.
		old_profile('gone', 16)
		CHT:ConvertFonts()
		eq(profile.chat.font, 'gone', 'a font that names nothing is kept')
		CHT:ApplyChatFont(frames[1])
		eqdrawn(frames[1], 'AgencyFB Bold', 16, 'OUTLINE', 0, 0, 'drawn as Text')
		CHT:ConvertFonts()
		eq(profile.chat.font, 'gone', 'run twice: nothing more')

		-- Text's size changed while Font size stayed at its default.
		st.config.profile.fonts.normal.font_size = 20
		old_profile('normal', 16)
		CHT:ConvertFonts()
		eq(profile.chat.font.font_size, 16, 'Text at 20, Font size 16: 16 as a typeface')
		st.config.profile.fonts.normal.font_size = nil

		-- A typeface table already (a hand edit) with a Font size left over.
		old_profile({ font_name = 'Colus', font_size = 12 }, 12)
		CHT:ConvertFonts()
		eq(profile.chat.font.font_name, 'Colus', "a typeface's face is kept")
		eq(profile.chat.font.font_size, 12, 'at 12')
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ': ' .. 'a conversion that has run is not run again, whatever fontsize holds', function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', nil)
		CHT:ConvertFonts()
		profile.chat.fontsize = 9 -- a value saved later by something else
		eq(CHT:ConvertFonts(), false, 'marked: left alone')
		eq(profile.chat.font, 'normal', 'nothing written')
		profile.chat.fontsize = nil
	end)

	test(client .. ': ' .. 'a profile switched to with an old Font size converts on the profile update; one already converted is left', function()
		st, CHT, profile, frames = world(client)
		-- What Config:UpdateConfig does: re-point the bound modules at the new
		-- profile, then st:FontsChanged (before any module's UpdateConfig).
		local converted = { font = 'normal', fontsVersion = 1, padding = 10 }
		local old = { font = 'normal', fontsize = 13, padding = 10 }
		for k, v in pairs({ theme = 'theme', background = 'theme', editbox = { height = 25 }, tabs = { fade = false } }) do
			converted[k], old[k] = v, v
		end
		CHT.config = old
		st:FontsChanged()
		eq(type(old.font), 'table', 'the old profile converted')
		eq(old.font.font_size, 13, 'at its Font size')
		eq(old.fontsVersion, 1, 'and marked')
		eqdrawn(frames[1], 'AgencyFB Bold', 13, 'OUTLINE', 0, 0, 'ChatFrame1 at 13')
		eqdrawn(frames[2], 'AgencyFB Bold', 13, 'OUTLINE', 0, 0, 'ChatFrame2 too')

		CHT.config = converted
		converted.fontsize = 5 -- not read: the profile is marked
		st:FontsChanged()
		eq(converted.font, 'normal', 'a converted profile is left')
		eqdrawn(frames[1], 'AgencyFB Bold', 16, 'OUTLINE', 0, 0, 'ChatFrame1 follows Text')
		eq(#take_errors(), 0, 'no errors')
		CHT.config = profile.chat
	end)

	test(client .. ': ' .. 'UpdateConfig converts first, before the windows are drawn', function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', 12)
		CHT:UpdateConfig()
		eq(profile.chat.font.font_size, 12, 'converted')
		eqdrawn(frames[1], 'AgencyFB Bold', 12, 'OUTLINE', 0, 0, 'drawn at the converted size')
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ': ' .. 'the page: Font is a font row with Size, Outline and both shadows in its dots; no Font size row', function()
		st, CHT, profile, frames = world(client)
		local args = CHT:GetConfigTable().args.general.args
		eq(args.fontsize, nil, 'no Font size row')
		eq(args.font.type, 'font', 'the font row')
		eq(table.concat(args.font.fontFields, ','), 'font_size,font_outline,shadow_x,shadow_y', 'its dots')
		eq(st.defaults.chat.fontsize, nil, 'no default for fontsize')
		eq(st.defaults.chat.fontsVersion, nil, 'and none for the marker')
	end)

	test(client .. ': ' .. 'a Fonts tab change to Text reaches every chat frame at once; a typeface on chat leaves the line spacing alone', function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', nil)
		CHT:ConvertFonts()
		profile.chat.font = 'normal'
		st.config.profile.fonts.normal.font_size = 19
		local FN = st:GetModule('Fonts')
		FN:UpdateFontConfig('normal')
		st:FontsChanged()
		for i = 1, 2 do eqdrawn(frames[i], 'AgencyFB Bold', 19, 'OUTLINE', 0, 0, 'ChatFrame' .. i .. ' at 19') end

		st.config.profile.fonts.normal.shadow_offset = { 2, -2 }
		FN:UpdateFontConfig('normal')
		st:FontsChanged()
		eqdrawn(frames[1], 'AgencyFB Bold', 19, 'OUTLINE', 2, -2, 'the shadow follows Text')

		profile.chat.font = { font_name = 'Colus', font_size = 12, font_outline = 'NONE', shadow_offset = { 1, 1 }, spacing = 9 }
		st:FontsChanged()
		eqdrawn(frames[2], 'Colus', 12, '', 1, 1, 'a typeface on chat')
		eq(frames[2]:GetSpacing(), 0, 'its spacing of 9 is not applied')
		st.config.profile.fonts.normal.font_size = nil
		st.config.profile.fonts.normal.shadow_offset = { 0, 0 }
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ': ' .. 'a module that is not enabled draws nothing on a font change', function()
		st, CHT, profile, frames = world(client)
		CHT.config = nil
		st:FontsChanged()
		eq(#take_errors(), 0, 'no errors')
		CHT.config = profile.chat
	end)

	test(client .. ": a Fonts tab change that leaves chat's font alone keeps a size Blizzard's menu set; chat's own changes put it back", function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', nil)
		CHT:ConvertFonts()
		local FN = st:GetModule('Fonts')
		st:FontsChanged()
		eqdrawn(frames[1], 'AgencyFB Bold', 16, 'OUTLINE', 0, 0, 'applied the first time')
		-- Blizzard's tab menu (FCF_SetChatWindowFontSize) sets the size on a window.
		frames[1]:SetFont(path('AgencyFB Bold'), 22, 'OUTLINE')
		profile.fonts.heading.font_size = 30
		FN:UpdateFontConfig('heading')
		st:FontsChanged()
		eqdrawn(frames[1], 'AgencyFB Bold', 22, 'OUTLINE', 0, 0, "Heading's size leaves Blizzard's size alone")
		profile.fonts.normal.font_size = 19
		FN:UpdateFontConfig('normal')
		st:FontsChanged()
		eqdrawn(frames[1], 'AgencyFB Bold', 19, 'OUTLINE', 0, 0, "Text's size is chat's font: applied")
		frames[1]:SetFont(path('AgencyFB Bold'), 22, 'OUTLINE')
		CHT:ApplyAppearance()
		eqdrawn(frames[1], 'AgencyFB Bold', 19, 'OUTLINE', 0, 0, "chat's own update (its options, a profile change) puts it back")
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ": a face whose file fails to load draws in Text's face on chat, which cannot tell by itself", function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', nil)
		CHT:ConvertFonts()
		-- A face LibSharedMedia lists whose file the game refuses. A chat window's
		-- SetFont returns nothing in game (ScrollingMessageFrame's wraps the font
		-- object's), so the window can't tell: the refusal is found once on a font
		-- string of SaftUI's (stub.refused_fonts), and the window gets Text's face.
		st.LSM:Register('font', 'Refused chat face', 'Interface\\AddOns\\SaftUI-Core\\Media\\Fonts\\refused-chat.ttf')
		local broken = { font_name = 'Refused chat face', font_size = 12, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
		local method = getmetatable(frames[1]).__index.SetFont
		rawset(frames[1], 'SetFont', function(self, ...) method(self, ...) end) -- returns nothing, as a chat window's
		eq(frames[1]:SetFont(path('Refused chat face'), 12, ''), nil, 'the stand-in returns nothing, as a chat window does')
		stub.refused_fonts[path('Refused chat face')] = true
		profile.chat.font = broken
		CHT:ApplyChatFont(frames[1])
		eqdrawn(frames[1], 'AgencyFB Bold', 12, '', 0, 0, "chat: Text's face at the typeface's size")
		eq(#take_errors(), 0, 'no errors')
	end)
	test(client .. ": a Fonts tab change reaches chat's edit box and its instructions, and a change of Text's face reaches the windows", function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', nil)
		CHT:ConvertFonts()
		local box = CreateFrame('EditBox', 'ChatFrame1EditBox', UIParent)
		-- Its text is the first region, as st:StyleEditBox reads it.
		local text = box:CreateFontString(nil, 'ARTWORK')
		text:SetFontObject(GameFontNormal)
		box.Instructions = box:CreateFontString(nil, 'ARTWORK')
		box.Instructions:SetFontObject(GameFontNormal)
		local FN = st:GetModule('Fonts')
		st:FontsChanged()
		check(text:GetFontObject() == st:GetFont('normal'), "the edit box's text takes chat's font")
		check(box.Instructions:GetFontObject() == st:GetFont('normal'), 'and its instructions')
		local face = { font_name = 'Colus', font_size = 12, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
		profile.chat.font = face
		st:FontsChanged()
		check(text:GetFontObject() == st:FontObject(face), "a typeface reaches the edit box's text")
		check(box.Instructions:GetFontObject() == st:FontObject(face), 'and its instructions')
		profile.chat.font = 'normal'
		-- Text's face changed on the Fonts tab, its size and shadow as they were.
		profile.fonts.normal.font_name = 'Colus'
		FN:UpdateFontConfig('normal')
		st:FontsChanged()
		eqdrawn(frames[1], 'Colus', 16, 'OUTLINE', 0, 0, "Text's new face reaches the window")
		profile.fonts.normal.font_name = nil
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ': a Font size that is not a number counts as the old default', function()
		st, CHT, profile, frames = world(client)
		old_profile('normal', 'big')
		CHT:ConvertFonts()
		eq(profile.chat.font, 'normal', 'nothing written: 16 is Text')
		eq(rawget(profile.chat, 'fontsize'), nil, 'fontsize is gone')
	end)
end

-- CHT:OnEnable reads chat's profile after the conversion has run, before any window
-- is skinned (a stand-in for running OnEnable, which needs Blizzard's whole chat):
-- ConvertFonts follows st:BindModuleConfig and comes before SkinChatFrame.
test('CHT:OnEnable converts the profile right after binding it, before it skins a window', function()
	local L = load_test_file('lib/source_lex.lua')
	local code = select(1, L.Lex(read_saftui_source('SaftUI-Chat/chatframe.lua')))
	local body = code:match('function CHT:OnEnable%(%).-\nend')
	check(body ~= nil, 'found OnEnable')
	local bind = body:find("st:BindModuleConfig(self, 'chat')", 1, true)
	local convert = body:find('self:ConvertFonts()', 1, true)
	local skin = body:find('self:SkinChatFrame(', 1, true)
	check(bind and convert and skin, 'all three are there')
	check(bind < convert and convert < skin, 'bind, then ConvertFonts, then SkinChatFrame')
end)
