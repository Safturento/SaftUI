local st = SaftUI
local TR = st:GetModule('Tracker')

-- The tracker's own colors (the Colors tab, options.lua): a color per part,
-- saved in tracker.colors[part] as { r, g, b } once the player picks one. A
-- part with none saved follows what it followed before there was a tab: a
-- Global settings > Colors color, or for the bar Blizzard's progress blue. So
-- a theme's or a Colors page's change still reaches every part the player
-- hasn't colored, and a reset (the saved color cleared) puts the part back to
-- following.
--
-- Finished and failed lines and titles stay Global settings > Colors >
-- Objectives, and a title colored by difficulty keeps the difficulty color.

-- Blizzard's progress blue, the bar's own color.
TR.BAR_COLOR = { r = 0.26, g = 0.42, b = 1 }

-- The parts, in the tab's order: key, name, what it colors, and what it
-- follows while it has no color of its own (a Text color's key, or 'bar').
TR.COLOR_PARTS = {
	{ key = 'header', name = 'Header', follows = 'normal',
		desc = "The Objectives line at the top of the tracker." },
	{ key = 'current_zone', name = 'Current zone', follows = 'normal',
		desc = "The header of the zone you're in." },
	{ key = 'zone', name = 'Zones', follows = 'muted',
		desc = 'The headers of the other zones.' },
	{ key = 'title', name = 'Quest titles', follows = 'normal',
		desc = "A quest's title, and a popup's. A finished or failed quest's takes Objectives' Completed or Failed, and with Color by difficulty (Quests) a title takes its difficulty's color." },
	{ key = 'objective', name = 'Objectives', follows = 'normal',
		desc = "A quest's lines you haven't finished: its objectives, the time left, the money and the waypoint." },
	{ key = 'bar', name = 'Progress bars', follows = 'bar',
		desc = "The fill of a progress objective's bar." },
}

local PART = {}
for _, part in ipairs(TR.COLOR_PARTS) do PART[part.key] = part end

local function Saved(key)
	local colors = st.config.profile.tracker.colors
	local color = type(colors) == 'table' and colors[key]
	if type(color) == 'table' and type(color.r) == 'number' then return color end
end

-- The color a part follows while it has none of its own: r, g, b.
function TR.PartFallback(key)
	local follows = PART[key].follows
	if follows == 'bar' then return TR.BAR_COLOR.r, TR.BAR_COLOR.g, TR.BAR_COLOR.b end
	return st:Color('text', follows):GetRGB()
end

-- The color a part draws in now: r, g, b. Read at draw time, never kept.
function TR.PartColor(key)
	local color = Saved(key)
	if color then return color.r, color.g, color.b end
	return TR.PartFallback(key)
end

-- Whether the player gave the part a color of its own.
function TR.PartColored(key)
	return Saved(key) ~= nil
end

-- Saves a part's color (r nil clears it: the part follows again) and paints
-- what the tracker colors itself.
function TR:SetPartColor(key, r, g, b)
	local config = st.config.profile.tracker
	if type(config.colors) ~= 'table' then config.colors = {} end
	if r == nil then
		config.colors[key] = nil
	else
		config.colors[key] = { r = r, g = g, b = b }
	end
	self:PaintColors()
end

-- What a part's color change repaints: the window's header and the rows (their
-- texts and bars). A color only, so it is safe in combat; nothing while the
-- tracker isn't built.
function TR:PaintColors()
	if not self.built then return end
	self:ColorWindow()
	self:ColorRows()
end
