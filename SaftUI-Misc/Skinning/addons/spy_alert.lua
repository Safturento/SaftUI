local st = SaftUI
local SP = st:GetModule('Skinning'):GetModule('Spy')
local L = SP.lib

-- The Spy skin's the alert popup (Spy_AlertWindow). Shares spy.lua's pieces through SP.lib.
--
-- What it relies on Spy doing (Spy 1.3.8-forever28):
-- - Each alert kind in Spy:ShowAlert sets the alert's border through
--   Spy.Colors:RegisterBorder('Alert', <kind's border>, Spy.AlertWindow); that color
--   is the panel's border, so an alert reads at a glance. Spy:ApplyBorderStyle puts
--   a backdrop (and, classic, a white border) on the alert again; it is cleared again.
-- - The icon is a frame whose backdrop is the icon (bgFile), set on every alert: it
--   is kept and given a thin border of SaftUI's.
-- Every piece is type-checked first; one a Spy version lacks keeps Spy's look.

local ICON_THEME, ICON_BACKGROUND = 'thin', 'none'

local alertColor -- { r, g, b, a } the last alert's border color, nil before the first
local hooked = false
local iconFrames = setmetatable({}, L.weak) -- Spy's icon frame -> its SaftUI border frame

local function Alert()
	local spy = _G.Spy
	local alert = type(spy) == 'table' and spy.AlertWindow
	return type(alert) == 'table' and alert or nil
end

-- The panel's border in the alert's color, or the theme's own before there is one.
local function ColorBorder(panel)
	if not panel then return end
	local c = alertColor
	if c then
		st:SetBorderColor(panel, c.r, c.g, c.b, c.a)
	else
		st:SetBorderColor(panel)
	end
end

-- Spy's backdrop and gold border off the alert again.
local function Clear()
	local alert = Alert()
	if not alert then return end
	if alert.SetBackdrop then alert:SetBackdrop(nil) end
	if alert.ForeverBorder then alert.ForeverBorder:Hide() end
end

local function Hook(owner, name, fn)
	if type(owner) == 'table' and type(owner[name]) == 'function' then
		hooksecurefunc(owner, name, fn)
	end
end

local function Install()
	if hooked then return end
	hooked = true
	local spy = _G.Spy
	local function Run(fn)
		xpcall(fn, geterrorhandler())
	end
	-- Which color the alert takes is Spy's: its registered border for the kind.
	Hook(spy.Colors, 'RegisterBorder', function(colors, branch, name, frame)
		if branch ~= 'Alert' or frame ~= Alert() then return end
		Run(function()
			local c = colors:GetColor(branch, name)
			if type(c) ~= 'table' then return end
			alertColor = { r = c.r, g = c.g, b = c.b, a = c.a or 1 }
			ColorBorder(L.panels[frame])
		end)
	end)
	-- spy.lua's redraw (a Skinning page change or a profile change) paints the panel in
	-- the theme's border again.
	L.OnConfig(function() ColorBorder(L.panels[Alert()]) end)
	Hook(spy, 'ShowAlert', function() Run(Clear) end)
	Hook(spy, 'ApplyBorderStyle', function() Run(Clear) end)
end

function SP:SkinAlert()
	Install()
	local alert = Alert()
	if not alert then return end

	Clear()
	local panel = L.Panel(alert)
	if panel then
		-- A redraw or recolor takes a border color off: it is put back.
		st:KeepOwnColors(panel, ColorBorder)
		ColorBorder(panel)
	end

	local icon = alert.Icon
	if type(icon) == 'table' and icon.SetBackdrop and not iconFrames[icon] then
		local frame = st:SetBackdropIn(L.panels, icon, ICON_THEME, ICON_BACKGROUND, 'small')
		if frame then
			iconFrames[icon] = frame
			-- Over the icon, so its edge shows.
			local level = icon:GetFrameLevel()
			if not issecretvalue(level) then frame:SetFrameLevel(level + 1) end
		end
	end

	L.HookFont(alert.Title, 'title')
	L.HookFont(alert.Name, 'text')
	L.HookFont(alert.Location, 'text')
end
