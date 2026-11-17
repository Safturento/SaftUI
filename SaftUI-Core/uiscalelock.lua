local st = SaftUI
local UIScale = st.UIScale

-- Blizzard's Use UI Scale row (Options > Graphics: the checkbox and its
-- slider) while SaftUI sets the UI's scale: a cover of SaftUI's own lies over
-- the row, dims its checkbox and slider, takes their clicks and says on
-- mouseover where the size is set. In The game's UI scale there is no cover
-- and the row works as Blizzard made it. UIScale:Check still puts the scale
-- back should the row change it some other way (a gamepad).
--
-- Nothing of Blizzard's is written (.agents/taint.md rules 1 to 3): the row is
-- found by two post-hooks on its mixin's Init and Release, which only read the
-- initializer's setting; the cover is SaftUI's frame, parented to the row so it
-- scrolls and hides with it. No method of the row, its checkbox or its slider
-- is called (no SetEnabled, no DisplayEnabled).

-- The row's checkbox setting, the same on Forever and retail
-- (Blizzard_SettingsDefinitions_Shared/Graphics.lua).
UIScale.LOCK_SETTING = 'PROXY_USE_UI_SCALE'
UIScale.LOCK_TITLE = 'Use UI Scale'
UIScale.LOCK_TOOLTIP = "SaftUI sets the UI's scale. Change its size in /sui > Global settings > General, or choose The game's UI scale there to use this setting."
-- The dimming over the checkbox and the slider.
UIScale.LOCK_DIM = { 0, 0, 0, 0.6 }
-- How far above the row the cover sits: over the checkbox, the slider and its
-- steppers, which are the row's children and grandchildren.
UIScale.LOCK_LEVELS = 20

local cover, row, hooked

local function Safely(fn, ...)
	xpcall(fn, geterrorhandler(), ...)
end

-- The variable of a row's checkbox setting, or nil. Only reads.
local function Variable(initializer)
	local data = type(initializer) == 'table' and initializer.data
	local setting = type(data) == 'table' and data.cbSetting
	if type(setting) ~= 'table' or type(setting.GetVariable) ~= 'function' then return nil end
	local ok, variable = pcall(setting.GetVariable, setting)
	if ok then return variable end
	return nil
end

local function ShowTooltip(self)
	GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	GameTooltip:SetText(UIScale.LOCK_TITLE, 1, 1, 1)
	GameTooltip:AddLine(UIScale.LOCK_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

local function HideTooltip(self)
	if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
end

local function Cover()
	if cover then return cover end
	cover = CreateFrame('Frame')
	cover:Hide()
	cover:EnableMouse(true)
	cover:SetScript('OnEnter', ShowTooltip)
	cover:SetScript('OnLeave', HideTooltip)
	cover:SetScript('OnHide', HideTooltip)
	cover.dim = cover:CreateTexture(nil, 'OVERLAY')
	cover.dim:SetColorTexture(unpack(UIScale.LOCK_DIM))
	return cover
end

-- The cover is up while the row is on screen and SaftUI sets the scale (the
-- choice in effect, a preview included, isn't The game's UI scale).
function UIScale:IsLocked()
	return row ~= nil and UIScale:Current().mode ~= 'game'
end

-- Puts the cover on the row, or takes it off: from the row's Init and Release,
-- and after every scale check (a choice made in /sui while the options are open).
function UIScale:RefreshLock()
	if not UIScale:IsLocked() then
		if cover then cover:Hide() end
		return
	end
	local frame = Cover()
	frame:SetParent(row)
	frame:ClearAllPoints()
	frame:SetAllPoints(row)
	frame:SetFrameLevel(row:GetFrameLevel() + UIScale.LOCK_LEVELS)
	-- The dimming starts at the checkbox (the label stays readable) where the
	-- row has one; the whole row otherwise.
	frame.dim:ClearAllPoints()
	local checkbox = row.Checkbox
	if type(checkbox) == 'table' and checkbox.GetObjectType then
		frame.dim:SetPoint('TOPLEFT', checkbox, 'TOPLEFT', 0, 0)
		frame.dim:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
	else
		frame.dim:SetAllPoints(frame)
	end
	frame:Show()
end

local function OnInit(control, initializer)
	if Variable(initializer) == UIScale.LOCK_SETTING then
		row = control
	elseif control == row then
		row = nil -- a pooled row taken for another setting
	end
	UIScale:RefreshLock()
end

local function OnRelease(control)
	if control ~= row then return end
	row = nil
	UIScale:RefreshLock()
end

-- Hooks the checkbox-and-slider rows' mixin once it exists: true when hooked.
-- A row copies its mixin's functions when it is made, and the options make
-- their rows when a category is first shown, after login.
function UIScale:HookOptions()
	if hooked then return true end
	local mixin = SettingsCheckboxSliderControlMixin
	if type(mixin) ~= 'table' or type(mixin.Init) ~= 'function' or type(mixin.Release) ~= 'function' then
		return false
	end
	hooked = true
	hooksecurefunc(mixin, 'Init', function(...) Safely(OnInit, ...) end)
	hooksecurefunc(mixin, 'Release', function(...) Safely(OnRelease, ...) end)
	return true
end

if not UIScale:HookOptions() then
	local waiter = CreateFrame('Frame')
	waiter:RegisterEvent('ADDON_LOADED')
	waiter:SetScript('OnEvent', function(self)
		if UIScale:HookOptions() then self:UnregisterEvent('ADDON_LOADED') end
	end)
end
