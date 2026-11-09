-- LibCandyBar-3.0 (v104) and RestedXP's Timers.lua, as the SaftUI skin
-- (SaftUI-Misc/Skinning/restedxp.lua) sees them. Stand-ins for third-party
-- addons: the widgets and layout come from the shared stubs in tests/wow/.
--
--   candy = Timers.make_candy()     builds the library and registers it with
--                                   LibStub (real, loaded by load_core_helpers).
--                                   make_candy(false) builds it without
--                                   registering, for a world where it isn't loaded.
--   T = Timers.add_timers(R, candy) gives a RXP.make() window its BarContainer
--                                   and timer functions (T.Start, T.StopTimer,
--                                   T.Sort), and sets T.v2 for the v2 window.
--
-- Call both after reset_world(), in the world the skin is loaded into. Bars,
-- their parts and the container are locked (locked_widget.lua), so the skin
-- can't stamp fields onto them.

local lock = load_test_file('misc/fixtures/locked_widget.lua')

local Timers = {}

-- The game's Frame methods, for the ones a bar's own methods wrap.
local function frame_method(name)
	return getmetatable(UIParent).__index[name]
end

function Timers.make_candy(register)
	local lib
	if register == false then
		lib = {}
	else
		lib = LibStub:NewLibrary('LibCandyBar-3.0', 104)
	end
	lib.barCache = {}
	local registry = {}
	function lib.RegisterCallback(target, event, method)
		registry[event] = registry[event] or {}
		registry[event][target] = method
	end
	local function fire(event, ...)
		for target, method in pairs(registry[event] or {}) do
			if type(method) == 'string' then target[method](target, event, ...) else method(event, ...) end
		end
	end

	-- restyleBar (LibCandyBar-3.0.lua:172-210)
	local function restyle(bar)
		if not bar.running then return end
		local icon, sb = bar.candyBarIconFrame, bar.candyBarBar
		icon:ClearAllPoints()
		sb:ClearAllPoints()
		if icon.icon then
			icon:SetWidth(bar.height)
			icon:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, 0)
			icon:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', 0, 0)
			sb:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 0, 0)
			sb:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', 0, 0)
			sb:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', 0, 0)
			sb:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 0, 0)
			icon:Show()
		else
			sb:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, 0)
			sb:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 0, 0)
			icon:Hide()
		end
	end

	local proto = {}
	function proto:SetHeight(h) rawset(self, 'height', h); frame_method('SetHeight')(self, h); restyle(self) end
	function proto:SetColor(...) self.candyBarBar:SetStatusBarColor(...) end
	function proto:SetBackgroundColor(...) self.candyBarBackground:SetVertexColor(...) end
	function proto:SetTextColor(...) self.candyBarLabel:SetTextColor(...); self.candyBarDuration:SetTextColor(...) end
	function proto:SetFont(...) self.candyBarLabel:SetFont(...); self.candyBarDuration:SetFont(...) end
	function proto:SetTexture(t) self.candyBarBar:SetStatusBarTexture(t); self.candyBarBackground:SetTexture(t) end
	function proto:GetLabel() return self.candyBarLabel:GetText() end
	function proto:SetLabel(text) self.candyBarLabel:SetText(text) end
	function proto:SetIcon(icon) rawset(self.candyBarIconFrame, 'icon', icon); self.candyBarIconFrame:SetTexture(icon); restyle(self) end
	function proto:SetDuration(d) rawset(self, 'remaining', d) end
	function proto:Start()
		rawset(self, 'running', true)
		restyle(self)
		rawset(self, 'exp', 1000 + (self.remaining or 0))
		self:Show()
	end
	function proto:Stop()
		fire('LibCandyBar_Stop', self)
		rawset(self, 'running', nil)
		self:Hide()
		self:SetParent(UIParent)
		lib.barCache[self] = true
	end

	-- lib:New (LibCandyBar-3.0.lua:484-575): reuses a cached bar, resets it.
	function lib:New(texture, width, height)
		local bar = next(self.barCache)
		if bar then
			self.barCache[bar] = nil
		else
			bar = CreateFrame('Frame', nil, UIParent)
			for k, fn in pairs(proto) do rawset(bar, k, fn) end
			local icon = bar:CreateTexture()
			icon:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, 0)
			local sb = CreateFrame('StatusBar', nil, bar)
			local bg = sb:CreateTexture(nil, 'BACKGROUND')
			rawset(bar, 'candyBarIconFrame', icon)
			rawset(bar, 'candyBarBar', sb)
			rawset(bar, 'candyBarBackground', bg)
			rawset(bar, 'candyBarLabel', sb:CreateFontString(nil, 'OVERLAY'))
			rawset(bar, 'candyBarDuration', sb:CreateFontString(nil, 'OVERLAY'))
			for _, f in ipairs({ bar, icon, sb, bg, bar.candyBarLabel, bar.candyBarDuration }) do lock(f, 'LibCandyBar') end
		end
		bar:SetFrameStrata('MEDIUM')
		bar:SetFrameLevel(100)
		bar.candyBarBar:SetStatusBarTexture(texture)
		bar.candyBarBackground:SetTexture(texture)
		rawset(bar, 'height', height)
		rawset(bar, 'running', nil)
		bar:SetBackgroundColor(0.5, 0.5, 0.5, 0.3)
		bar:SetColor(0.5, 0.5, 0.5, 1)
		bar:ClearAllPoints()
		frame_method('SetHeight')(bar, height)
		bar:SetFont('GameFontHighlightSmallOutline', 10)
		bar:SetLabel(nil)
		bar:SetIcon(nil)
		return bar
	end

	return lib
end

-- Timers.lua (v4.11.35): BarContainer, CreateBar, StartTimer, StopTimer, SortTimers.
-- T.v2 = a frame stands in for the v2 window's footer (IsGuideWindowEnabled).
function Timers.add_timers(R, candy)
	local BarContainer = CreateFrame('Frame', 'RXPFrameBarContainer', R)
	rawset(BarContainer, 'height', 16)
	rawset(BarContainer, 'bars', {})
	rawset(BarContainer, 'barTexture', 'Interface\\CHARACTERFRAME\\BarFill')
	rawset(BarContainer, 'barIcon', 'Interface\\ICONS\\INV_Misc_PocketWatch_02')
	rawset(R, 'BarContainer', BarContainer)
	BarContainer:ClearAllPoints()
	BarContainer:SetPoint('TOPLEFT', R.Footer, 'TOPLEFT', 4, 0)
	BarContainer:SetPoint('BOTTOMRIGHT', R.Footer, 'BOTTOMRIGHT', 0, 1)

	local T = { pool = {}, v2 = nil }

	function T.Sort()
		local bars, lastBar, reverse = {}, false, nil
		for _, bar in pairs(BarContainer.bars) do table.insert(bars, bar) end
		if T.v2 then
			BarContainer:ClearAllPoints()
			BarContainer:SetPoint('TOPLEFT', T.v2, 'TOPLEFT', 0, 0)
			BarContainer:SetPoint('BOTTOMRIGHT', T.v2, 'BOTTOMRIGHT', -12, 0)
		elseif R.CurrentStepFrame.anchor == 'BOTTOM' and #bars > 1 then
			BarContainer:ClearAllPoints()
			BarContainer:SetPoint('BOTTOMLEFT', R.GuideName, 'TOPLEFT', 4, 0)
			BarContainer:SetPoint('BOTTOMRIGHT', R.GuideName, 'TOPRIGHT', 0, 1)
			BarContainer:SetHeight(BarContainer.height * #bars)
			reverse = true
		else
			BarContainer:ClearAllPoints()
			BarContainer:SetPoint('TOPLEFT', R.Footer, 'TOPLEFT', 4, 0)
			BarContainer:SetPoint('BOTTOMRIGHT', R.Footer, 'BOTTOMRIGHT', 0, 1)
		end
		table.sort(bars, function(a, b) return a.exp > b.exp end)
		for _, bar in ipairs(bars) do
			bar:ClearAllPoints()
			if lastBar then
				if reverse then
					bar:SetPoint('BOTTOMLEFT', lastBar, 'TOPLEFT')
				else
					bar:SetPoint('TOPLEFT', lastBar, 'BOTTOMLEFT')
				end
			elseif reverse then
				bar:SetPoint('BOTTOMLEFT', BarContainer, 'BOTTOMLEFT')
			else
				bar:SetPoint('TOPLEFT', BarContainer, 'TOPLEFT')
			end
			lastBar = bar
			if not T.v2 then bar:SetHeight(BarContainer.height) end
		end
	end

	local function onHide(bar)
		BarContainer.bars[bar:GetLabel()] = nil
		T.Sort()
	end

	local function createBar(label)
		local bar
		for _, v in pairs(T.pool) do
			if not v:IsShown() then bar = v; break end
		end
		if not bar then
			bar = candy:New(BarContainer.barTexture, 100, 16)
			table.insert(T.pool, bar)
			bar:SetDuration(60)
			bar:HookScript('OnHide', onHide) -- RestedXP SetScripts it; same effect here
		end
		bar:SetLabel(label)
		return bar
	end

	function T.Start(duration, label)
		label = label or ''
		local bar = BarContainer.bars[label] or createBar(label)
		BarContainer.bars[label] = bar
		bar:SetDuration(duration)
		bar:SetIcon(BarContainer.barIcon)
		bar:SetColor(0.6, 0.2, 0.8, 1) -- addon.colors.mapPins
		bar:SetHeight(BarContainer.height)
		bar:Start()
		T.Sort()
		return bar
	end

	function T.StopTimer(label)
		local bar = BarContainer.bars[label]
		if bar then bar:Stop(); T.Sort() end
	end

	lock(BarContainer, 'RestedXP')
	return T
end

return Timers
