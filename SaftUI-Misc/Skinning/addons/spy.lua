local st = SaftUI
local SK = st:GetModule('Skinning')

-- Restyles the Spy addon (Spy Forever: a third-party addon, not Blizzard's) in
-- SaftUI's look: its Nearby window, the alert popup, the Statistics window and
-- the Kill on Sight button, in the Skinning page's Theme, Background and font.
-- Its pieces are kept in side tables keyed by Spy's frames; nothing is written
-- onto a Spy frame, and a script is only ever hooked, never replaced.
--
-- What it relies on Spy doing (names checked against Spy 1.3.8-forever28):
-- - Spy loads by ADDON_LOADED 'Spy'. SpyStatsFrame exists at its load,
--   Spy.MainWindow and Spy.AlertWindow after Spy:CreateMainWindow, and
--   Spy.KoSButton after Spy:CreateKoSButton, so the skin hooks both functions
--   and skins what they made.
-- - Spy_MainWindow and its rows (Spy_MainWindow_Bar<n>) are secure: the window
--   is protected in combat. The skin never moves, sizes, shows, hides or
--   reparents either; only SaftUI's own panels, which are children of them,
--   are placed.
-- - Every piece is type-checked first. One a Spy version lacks keeps Spy's look.
--
-- The skin is installed only if, when it is set up, Skinning -> Spy is on and
-- the Skinning page's Theme isn't Blizzard. Turning it off or on takes a reload.
-- The Theme, Background and font changing after that apply live.
local SP = SK:NewModule('Spy')

local weak = { __mode = 'k' }
local panels = setmetatable({}, weak) -- Spy's frame -> its SaftUI backdrop frame (st:SetBackdropIn)

local installed = false

local function Spy() return _G.Spy end

-- The Skinning page's Theme, Background and font name.
function SP:GetStyle()
	local config = st.config.profile.skinning
	return config.theme, config.background, config.font
end

-- Whether the skin is wanted now: the toggle on and the Theme not Blizzard.
function SP:IsWanted()
	local config = st.config.profile.skinning
	return config.spy and not st:IsBlizzardLook(config.theme, config.background) or false
end

-- A SaftUI panel behind frame (kind panel, a child of it one level under it).
local function Panel(frame, kind)
	local theme, background = SP:GetStyle()
	return st:SetBackdropIn(panels, frame, theme, background, kind or 'panel')
end

-- Draws what each of Spy's windows is made of. Tasks that follow fill these; each
-- one is called only when its target exists, and an error in one doesn't stop the
-- others.
function SP:SkinMain()
	local window = Spy() and Spy().MainWindow
	if type(window) ~= 'table' then return end
	Panel(window)
end

function SP:SkinAlert() end

function SP:SkinStats() end

function SP:SkinKoS() end

local function Run(fn)
	xpcall(fn, geterrorhandler(), SP)
end

-- Installs the skin once Spy and its pieces exist, and hooks the two functions that
-- make the windows later.
function SP:Setup()
	if installed or not self:IsWanted() then return end
	local spy = Spy()
	if type(spy) ~= 'table' then return end
	installed = true

	Run(self.SkinStats)
	Run(self.SkinMain)
	Run(self.SkinAlert)
	Run(self.SkinKoS)

	if type(spy.CreateMainWindow) == 'function' then
		hooksecurefunc(spy, 'CreateMainWindow', function()
			Run(SP.SkinMain)
			Run(SP.SkinAlert)
		end)
	end
	if type(spy.CreateKoSButton) == 'function' then
		hooksecurefunc(spy, 'CreateKoSButton', function() Run(SP.SkinKoS) end)
	end
end

function SP:ADDON_LOADED(_, name)
	if name ~= 'Spy' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

-- A profile change, or the Skinning page's Theme, Background or font: draws the
-- panels again.
function SP:UpdateConfig()
	if not installed then return end
	local theme, background = self:GetStyle()
	for frame in pairs(panels) do
		st:SetBackdropIn(panels, frame, theme, background, 'panel')
	end
end

-- A shared font or a font setting changed (st:FontsChanged): the Skinning font on
-- Spy's texts again.
function SP:OnFontsChanged()
	if not installed then return end
end

-- A color changed (st:ColorsChanged): what is colored from the theme or the text
-- colors, colored again.
function SP:OnColorsChanged()
	if not installed then return end
end

-- Off (Skinning -> Spy), or under the Blizzard theme, nothing is hooked or touched.
function SP:OnEnable()
	if not self:IsWanted() then return end
	if C_AddOns.IsAddOnLoaded('Spy') and Spy() then
		self:Setup()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end
