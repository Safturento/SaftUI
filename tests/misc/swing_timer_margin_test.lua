-- The swing timer bars' holders (SaftUI-Misc/Skinning/blizzard/
-- Blizzard_SwingTimerPosition.lua) against the screen edge margin. Each bar is a
-- Blizzard Edit Mode system the game keeps on screen by its own clamp
-- (EditModeSwingTimerSystemTemplate: clampedToScreen, its Selection box on its
-- edges, so no insets), held 5 and 4 outside its holder (st:HoldFrame) so its
-- StatusBar covers the holder. At a margin under 5 and 4 the holder, and edit
-- mode's outline on it, would go on past a bar its clamp stopped; so the holder
-- goes no nearer the edges than the bar can (st:KeepHolderInScreenMargin).
--
-- Real: SaftUI-Misc's config.lua and Blizzard_SwingTimerPosition.lua (STP:Setup
-- and its TakeOver), Core's helpers and edit mode. Stand-ins: the three bars,
-- locked (lib/locked_widget.lua) so a field SaftUI writes onto one fails, with
-- their StatusBar's labels, their Edit Mode box, Edit Mode's SetPoint and
-- ClearAllPoints overrides and Blizzard's UpdateClampOffsets.
load_core_helpers()
load_editmode()
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
local st = SaftUI
local locked = load_test_file('lib/locked_widget.lua')
local profile = st.config.profile

stub.screen_width, stub.screen_height = 1000, 600
UIParent:SetScale(768 / 600)

load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_SwingTimerPosition.lua')
local STP = st:GetModule('SwingTimer')
st:BindModuleConfig(STP, 'swingtimer')

local function Bar(name)
	local bar = CreateFrame('Frame', name, UIParent)
	bar:SetSize(200, 20)
	bar:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	bar:SetClampedToScreen(true)
	local statusBar = CreateFrame('Frame', nil, bar)
	statusBar.TypeLabel = statusBar:CreateFontString()
	statusBar.TypeLabelShadow = statusBar:CreateFontString()
	statusBar.TimeLabel = statusBar:CreateFontString()
	bar.StatusBar = statusBar
	local selection = CreateFrame('Frame', nil, bar)
	selection:SetAllPoints(bar)
	selection:Hide()
	bar.Selection = locked(selection, 'Blizzard Edit Mode box')
	local methods = getmetatable(bar).__index
	for _, name in ipairs({ 'SetPoint', 'ClearAllPoints' }) do
		rawset(bar, name, function(self, ...) return methods[name](self, ...) end)
	end
	rawset(bar, 'UpdateClampOffsets', function(self)
		self:SetClampRectInsets(self.Selection:GetLeft() - self:GetLeft(), self.Selection:GetRight() - self:GetRight(),
			self.Selection:GetTop() - self:GetTop(), self.Selection:GetBottom() - self:GetBottom())
	end)
	bar:UpdateClampOffsets()
	return locked(bar, 'Blizzard swing timer')
end

local function Insets(frame)
	local out = { frame:GetClampRectInsets() }
	for i, v in ipairs(out) do out[i] = tostring(v == 0 and 0 or v) end
	return table.concat(out, ',')
end

local function SetMargin(value)
	profile.misc.clamp_inset = value
	st:UpdateScreenMargin()
end

test("each bar's holder goes no nearer the edges than the bar, 5 and 4 outside it, can go", function()
	for _, name in ipairs({ 'SwingTimerMainHandFrame', 'SwingTimerOffHandFrame', 'SwingTimerRangedFrame' }) do
		_G[name] = Bar(name)
	end
	STP:Setup()
	for _, key in ipairs({ 'mainhand', 'offhand', 'ranged' }) do
		eq(Insets(STP.holders[key]), '-20,20,20,-20', key .. ': the margin, wider than the bar needs')
	end
	SetMargin(0)
	for _, key in ipairs({ 'mainhand', 'offhand', 'ranged' }) do
		eq(Insets(STP.holders[key]), '-5,5,4,-4', key .. ': at 0, 5 and 4 in, so the bar reaches the edge and no further')
	end
	SetMargin(20)
	eq(Insets(STP.holders.mainhand), '-20,20,20,-20', 'and back')
	eq(#take_errors(), 0, 'no errors')
end)

test("a swing timer mover is disabled while Blizzard's saved Visibility for its bar is Hidden, and has the defaults' position", function()
	local EM = st.EditModeFrames
	local mover = EM.movers.swingtimer_mainhand
	eq(EM:MoverModule(mover), 'Misc', 'module')
	eq(EM:IsMoverHidden(mover), false, 'never hidden on its own')
	local realBar, enum = STP.bars.mainhand, Enum
	Enum = { EditModeSwingTimerVisibility = { Always = 0, Hidden = 1 } }
	STP.bars.mainhand = { visibility = 0 }
	eq(EM:IsMoverDisabled(mover), false, "Blizzard's Visibility is not Hidden")
	STP.bars.mainhand = { visibility = 1 }
	eq(EM:IsMoverDisabled(mover), true, 'Hidden by Blizzard setting')
	STP.bars.mainhand, Enum = realBar, enum
	local default = EM:GetDefaultPosition(mover)
	eq(default.y_off, st.defaults.swingtimer.mainhand.position.y_off, "the defaults' position")
	check(default ~= st.defaults.swingtimer.mainhand.position, 'a copy')
	eq(#take_errors(), 0, 'no errors')
end)
