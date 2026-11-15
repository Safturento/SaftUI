-- Chat in edit mode against the screen edge margin: the Chat mover's outline
-- (on SaftUI's holder) and the chat itself (ChatFrame1, Blizzard's) stop at the
-- same place when the mover is dragged or nudged into the screen's edges, and
-- the position stored is where they stop.
--
-- ChatFrame1 is a Blizzard Edit Mode system (EditModeChatFrameSystemTemplate):
-- clamped to the screen by its XML, with insets Blizzard's Edit Mode sets from
-- its Selection box on every layout apply and Edit Mode enter
-- (EditModeSystemMixin:UpdateClampOffsets). The box is anchored TOPLEFT -32,60
-- and BOTTOMRIGHT 25,-32 (both clients), so the game keeps ChatFrame1 32 in from
-- the screen's left and bottom, 25 from its right and 60 from its top. SaftUI
-- keeps the holder the screen edge margin in (misc.clamp_inset, 20 by default),
-- and ChatFrame1 takes the holder's anchor (CHT:PlaceChatFrame).
--
-- Real: SaftUI-Chat's config.lua and chatframe.lua, Core's helpers and edit mode.
-- Stand-in: ChatFrame1, an Edit Mode system with Blizzard's chat Selection box
-- and Blizzard's UpdateClampOffsets, locked (lib/locked_widget.lua) so a field
-- SaftUI writes onto it fails. The stubs remember a frame's clamp but don't
-- clamp it (.agents/testing.md), so where the game shows a clamped frame is
-- worked out here (Shown) from its rect and its insets.
load_core_helpers()
load_editmode()
load_saftui('SaftUI-Chat/config.lua')
apply_defaults()
load_saftui('SaftUI-Chat/chatframe.lua')

local st = SaftUI
local EM = st.EditModeFrames
local CHT = st:GetModule('Chat')
st:BindModuleConfig(CHT, 'chat')
local profile = st.config.profile
local locked = load_test_file('lib/locked_widget.lua')

-- A 1000 x 600 screen at the scale SaftUI sets at login: one UIParent unit per
-- physical pixel, so UIParent is 1000 x 600 too.
stub.screen_width, stub.screen_height = 1000, 600
UIParent:SetScale(768 / 600)

-- The chat's size in the profile, so nothing waits for Blizzard's (CaptureSize).
profile.chat.width, profile.chat.height = 400, 200

-- ChatFrame1 as Blizzard's Edit Mode makes it. layoutAnchor is where Blizzard's
-- layout puts it (ApplySystemAnchor), through the SetPoint and ClearAllPoints
-- overrides (EditModeSystemMixin:OnSystemLoad), which SaftUI must never call.
local function ChatFrame()
	local frame = CreateFrame('Frame', 'ChatFrame1', UIParent)
	frame:SetSize(400, 200)
	frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 35, 140)
	frame:SetClampedToScreen(true) -- clampedToScreen in FloatingChatFrameTemplate and EditModeSystemTemplate
	local selection = CreateFrame('Frame', nil, frame)
	selection:SetPoint('TOPLEFT', frame, 'TOPLEFT', -32, 60)
	selection:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 25, -32)
	selection:Hide()
	frame.Selection = locked(selection, 'Blizzard Edit Mode box')
	frame.EditModeResizeButton = CreateFrame('Button', nil, frame)
	frame.EditModeResizeButton:Hide()
	local methods = getmetatable(frame).__index
	for _, name in ipairs({ 'SetPoint', 'ClearAllPoints' }) do
		rawset(frame, name, function(self, ...) return methods[name](self, ...) end)
	end
	-- Blizzard's EditModeSystemMixin:UpdateClampOffsets, as it is.
	rawset(frame, 'UpdateClampOffsets', function(self)
		if not self:GetLeft() then
			self:SetClampRectInsets(0, 0, 0, 0)
			return
		end
		local leftOffset = self.Selection:GetLeft() - self:GetLeft()
		local rightOffset = self.Selection:GetRight() - self:GetRight()
		local topOffset = self.Selection:GetTop() - self:GetTop()
		local bottomOffset = self.Selection:GetBottom() - self:GetBottom()
		self:SetClampRectInsets(leftOffset, rightOffset, topOffset, bottomOffset)
	end)
	-- A layout apply (EditModeSystemMixin:UpdateSystem): the layout's anchor,
	-- then AnchorSelectionFrame, which sets the clamp insets from the box.
	rawset(frame, 'UpdateSystem', function(self)
		rawset(self, 'systemInfo', {})
		self:ClearAllPoints()
		self:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 35, 140)
		self:UpdateClampOffsets()
	end)
	return locked(frame, 'Blizzard chat')
end

-- Where the game shows frame: moved in just far enough that its rect, grown by
-- its clamp insets, is on screen ('left,bottom,right,top'). Every frame here is
-- UIParent's child with no scale of its own, so all of it is in UIParent units.
local function Shown(frame)
	local l, r, b, t = frame:GetLeft(), frame:GetRight(), frame:GetBottom(), frame:GetTop()
	local dx, dy = 0, 0
	if frame:IsClampedToScreen() then
		local il, ir, it, ib = frame:GetClampRectInsets()
		local width, height = UIParent:GetWidth(), UIParent:GetHeight()
		if l + il < 0 then dx = -(l + il) elseif r + ir > width then dx = width - (r + ir) end
		if b + ib < 0 then dy = -(b + ib) elseif t + it > height then dy = height - (t + it) end
	end
	return ('%g,%g,%g,%g'):format(l + dx, b + dy, r + dx, t + dy)
end

local function Insets(frame)
	local out = { frame:GetClampRectInsets() }
	for i, v in ipairs(out) do out[i] = tostring(v == 0 and 0 or v) end
	return table.concat(out, ',')
end

local function At(position) return position.x_off .. ',' .. position.y_off end

-- Drags the mover's overlay by dx, dy (UIParent units) and lets go.
local function Drag(mover, dx, dy)
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = 500 * scale, 300 * scale
	EM:StartDrag(mover)
	stub.cursor_x, stub.cursor_y = (500 + dx) * scale, (300 + dy) * scale
	EM:UpdateDrag(mover)
	EM:StopDrag(mover)
end

-- The margin as the General tab's row sets it: the profile, then every frame
-- kept inside it.
local function SetMargin(value)
	profile.misc.clamp_inset = value
	st:UpdateScreenMargin()
end

-- SaftUI's chat as CHT:OnEnable sets it up (without skinning the chat windows,
-- which needs all of Blizzard's), then Blizzard's first layout apply, which
-- gives ChatFrame1 its clamp insets.
_G.ChatFrame1 = ChatFrame()
CHT.holder = CreateFrame('Frame', st.name .. 'ChatHolder', UIParent)
CHT:TakeOverChatFrame()
CHT:CaptureSize()
CHT:ApplyHolder()
CHT:RegisterChatMover()
ChatFrame1:UpdateSystem()
local mover = CHT.mover
local position = profile.chat.position

test("Blizzard's layout gives ChatFrame1 its chat clamp: 32 in from the left and bottom, 25 from the right, 60 from the top", function()
	eq(Insets(ChatFrame1), '-32,25,60,-32', "UpdateClampOffsets, from the chat's Selection box")
	eq(At(position), '30,30', "chat's default")
	eq(Shown(ChatFrame1), Shown(CHT.holder), 'the chat shows on its holder')
	eq(#take_errors(), 0, 'no errors')
end)

test('dragged into the bottom left corner, the outline and the chat stop together, and that is what is stored', function()
	Drag(mover, -1000, -1000)
	eq(Shown(CHT.holder), Shown(ChatFrame1), "the holder, and the outline on it, stop where the chat does")
	eq(Shown(ChatFrame1), '32,32,432,232', "where Blizzard's clamp stops the chat")
	local left, _, bottom = EM.GetOutlineRect(mover)
	eq(left .. ',' .. bottom, '22,22', "the outline on the chat's border, the padding (10) outside it")
	eq(At(position), '32,32', 'stored where it shows, so a /reload puts it there')
	-- Placed again from what is stored, as after a /reload.
	CHT:ApplyHolder()
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'placed from the profile, still together')
	eq(Shown(ChatFrame1), '32,32,432,232', 'and still there')
	eq(#take_errors(), 0, 'no errors')
end)

test('dragged into the top right corner, they stop 25 in from the right and 60 from the top', function()
	Drag(mover, 5000, 5000)
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'the outline stops with the chat')
	eq(Shown(ChatFrame1), '575,340,975,540', '25 in from the right, 60 from the top')
	eq(At(position), '575,340', 'stored where it shows')
	Drag(mover, -5000, -5000)
	eq(#take_errors(), 0, 'no errors')
end)

test("nudges stop where the chat does too", function()
	Drag(mover, -1000, -1000)
	EM:Nudge(mover, 'LEFT', false)
	EM:Nudge(mover, 'DOWN', true)
	eq(At(position), '32,32', "a nudge doesn't take the outline past the chat")
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'together')
	EM:Nudge(mover, 'RIGHT', false)
	eq(At(position), '33,32', 'away from the edge, it moves a pixel')
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'together')
	eq(#take_errors(), 0, 'no errors')
end)

test("a margin wider than Blizzard's clamp is the margin; a narrower or negative one leaves the chat at Blizzard's", function()
	SetMargin(40)
	Drag(mover, -1000, -1000)
	eq(Shown(ChatFrame1), '40,40,440,240', 'the margin, 40 in')
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'together')
	Drag(mover, 5000, 5000)
	eq(Shown(ChatFrame1), '560,340,960,540', "40 in from the right, Blizzard's 60 from the top")
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'together')

	SetMargin(-10)
	Drag(mover, -5000, -5000)
	eq(Shown(ChatFrame1), '32,32,432,232', "below 0 the chat still can't go past Blizzard's clamp")
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'and neither can the outline')
	SetMargin(20)
	eq(#take_errors(), 0, 'no errors')
end)

test("Blizzard's clamp arriving after SaftUI's setup (a layout apply, Edit Mode opening) reaches the holder at once", function()
	-- Until Blizzard's first layout apply ChatFrame1 has no insets (SaftUI's skin
	-- leaves them alone: tests/chat/theme_test.lua), and Blizzard sets them on its
	-- layout apply or Edit Mode enter.
	ChatFrame1:SetClampRectInsets(0, 0, 0, 0)
	SetMargin(20)
	eq(Insets(CHT.holder), '-20,20,20,-20', 'no clamp on the chat: the margin alone')
	Drag(mover, -1000, -1000)
	eq(Shown(ChatFrame1), '20,20,420,220', 'so both go to the margin')
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'together')
	-- Edit Mode enter (HighlightSystem, AnchorSelectionFrame): the holder is clamped
	-- again, and nothing places ChatFrame1.
	ChatFrame1:UpdateClampOffsets()
	eq(Insets(CHT.holder), '-32,25,60,-32', "the chat's clamp, at once")
	eq(Shown(ChatFrame1), '32,32,432,232', "the chat at Blizzard's 32")
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'the holder with it, before any drag')
	Drag(mover, -1000, -1000)
	eq(Shown(CHT.holder), Shown(ChatFrame1), 'and after one')
	eq(#take_errors(), 0, 'no errors')
end)

test("in combat Blizzard's clamp still reaches the holder, and nothing is done to ChatFrame1", function()
	ChatFrame1:SetClampRectInsets(0, 0, 0, 0)
	SetMargin(20)
	local before = ChatFrame1:GetLeft() .. ',' .. ChatFrame1:GetBottom()
	-- Any call SaftUI makes on ChatFrame1 from here on is recorded.
	local calls = {}
	local methods = getmetatable(ChatFrame1).__index
	local real = {}
	for _, name in ipairs({ 'SetClampRectInsets', 'SetClampedToScreen', 'SetPoint', 'ClearAllPoints', 'SetSize' }) do
		real[name] = methods[name]
		rawset(methods, name, function(self, ...)
			if self == ChatFrame1 then calls[#calls + 1] = name end
			return real[name](self, ...)
		end)
	end
	stub.in_combat = true
	stub.blocked = {}
	ChatFrame1:UpdateClampOffsets() -- Blizzard's, then any post-hook of SaftUI's
	stub.in_combat = false
	for name, fn in pairs(real) do rawset(methods, name, fn) end
	eq(table.concat(calls, ','), 'SetClampRectInsets', "only Blizzard's own call (in its UpdateClampOffsets) on ChatFrame1")
	eq(Insets(CHT.holder), '-32,25,60,-32', "the holder (SaftUI's) takes the chat's clamp in combat")
	eq(ChatFrame1:GetLeft() .. ',' .. ChatFrame1:GetBottom(), before, 'ChatFrame1 not moved')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test("chat's mover is the Chat module, with a copy of the profile defaults' position as its default", function()
	eq(EM:MoverModule(mover), 'Chat', 'module')
	eq(EM:IsMoverDisabled(mover), false, 'never disabled')
	eq(EM:IsMoverHidden(mover), false, 'never hidden')
	local default = EM:GetDefaultPosition(mover)
	local want = st.defaults.chat.position
	eq(At(default), want.x_off .. ',' .. want.y_off, "the defaults' position")
	check(default ~= want, 'a copy, not the defaults table')
	default.x_off = 777
	eq(st.defaults.chat.position.x_off, want.x_off, 'a write into it never reaches the defaults')
	eq(#take_errors(), 0, 'no errors')
end)
