-- The totem bar's timers lay out again when a font changes (TB:OnFontsChanged,
-- run by st:FontsChanged): after SetupTimers has run, and not before.
--
-- Stand-in: TB:ApplyTimerLayout is a counter. The real one lays out the
-- timers' frames, which need Blizzard's multi-cast slot buttons; what is
-- checked here is only that OnFontsChanged asks for the layout, and when.

load_core_helpers()
local st = SaftUI

for _, file in ipairs({ 'totembar', 'totemtimers' }) do
	load_saftui('SaftUI-Misc/' .. file .. '.lua') -- the TOC's order
end
local TB = st:GetModule('TotemBar')

test('a font change lays the timers out again once they are set up, and not before', function()
	local layouts = 0
	function TB:ApplyTimerLayout() layouts = layouts + 1 end

	st:FontsChanged()
	eq(layouts, 0, 'before SetupTimers: nothing to lay out')
	TB.config = TB.config or {}
	TB:SetupTimers()
	local after_setup = layouts
	st:FontsChanged()
	eq(layouts, after_setup + 1, 'after SetupTimers: laid out again')
	eq(#take_errors(), 0, 'no errors')
end)
