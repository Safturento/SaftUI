-- The default tooltip's holder (SaftUI-Misc/tooltipposition.lua) against the
-- screen edge margin: Blizzard's GameTooltipDefaultContainer, which follows the
-- holder, is an Edit Mode system the game keeps on screen by its own clamp
-- (EditModeHudTooltipSystemTemplate: clampedToScreen, its Selection box on its
-- edges, so no insets). Below a 0 margin the holder, and edit mode's outline on
-- it, would go past the screen's edges while the container stopped at them; so
-- the holder goes no nearer the edges than the container can
-- (st:KeepHolderInScreenMargin).
--
-- Real: SaftUI-Misc's config.lua and tooltipposition.lua, Core's helpers and
-- edit mode. Stand-in: the container, locked (lib/locked_widget.lua) so a field
-- SaftUI writes onto it fails, with Edit Mode's SetPoint and ClearAllPoints
-- overrides and Blizzard's UpdateClampOffsets.
load_core_helpers()
load_editmode()
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
local st = SaftUI
local locked = load_test_file('lib/locked_widget.lua')
local profile = st.config.profile

stub.screen_width, stub.screen_height = 1000, 600
UIParent:SetScale(768 / 600)

local TT = st:NewModule('Tooltip')
st:BindModuleConfig(TT, 'tooltip')
load_saftui('SaftUI-Misc/tooltipposition.lua')

local function Container()
	local frame = CreateFrame('Frame', 'GameTooltipDefaultContainer', UIParent)
	frame:SetSize(250, 150)
	frame:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -100, 100)
	frame:SetClampedToScreen(true)
	local selection = CreateFrame('Frame', nil, frame)
	selection:SetAllPoints(frame)
	selection:Hide()
	frame.Selection = locked(selection, 'Blizzard Edit Mode box')
	local methods = getmetatable(frame).__index
	for _, name in ipairs({ 'SetPoint', 'ClearAllPoints' }) do
		rawset(frame, name, function(self, ...) return methods[name](self, ...) end)
	end
	rawset(frame, 'UpdateClampOffsets', function(self)
		self:SetClampRectInsets(self.Selection:GetLeft() - self:GetLeft(), self.Selection:GetRight() - self:GetRight(),
			self.Selection:GetTop() - self:GetTop(), self.Selection:GetBottom() - self:GetBottom())
	end)
	frame:UpdateClampOffsets()
	return locked(frame, 'Blizzard tooltip container')
end

local function Insets(frame)
	local out = { frame:GetClampRectInsets() }
	for i, v in ipairs(out) do out[i] = tostring(v == 0 and 0 or v) end
	return table.concat(out, ',')
end

test("the tooltip's holder goes no nearer the edges than the container's own clamp lets it go", function()
	_G.GameTooltipDefaultContainer = Container()
	TT:SetupTooltipPosition()
	local holder = TT.tooltipHolder
	eq(Insets(holder), '-20,20,20,-20', 'the margin, wider than the container needs')
	profile.misc.clamp_inset = -10
	st:UpdateScreenMargin()
	eq(Insets(holder), '0,0,0,0', "below 0, the screen's edges, where the container's clamp stops it")
	profile.misc.clamp_inset = 20
	st:UpdateScreenMargin()
	eq(Insets(holder), '-20,20,20,-20', 'and back')
	eq(#take_errors(), 0, 'no errors')
end)
