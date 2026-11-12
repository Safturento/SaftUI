local st = SaftUI
local UF = st:GetModule('Unitframes')

-- oUF's smoothing for a bar's Smooth setting: eased while on, immediate while
-- off (oUF's own default).
function UF:GetSmoothing(smooth)
	return smooth and Enum.StatusBarInterpolation.ExponentialEaseOut or Enum.StatusBarInterpolation.Immediate
end

-- A power bar's text as a whole percent. With secret values the game works the
-- percent out through Blizzard's 0-100 curve, and the FontString formats it
-- without Lua reading it.
function UF:SetPowerPercentText(text, unit, current, max, powerType)
	if issecretvalue(current) or issecretvalue(max) then
		text:SetFormattedText('%.0f', UnitPowerPercent(unit, powerType, false, CurveConstants.ScaleTo100))
	elseif max > 0 then
		text:SetFormattedText('%.0f', current / max * 100)
	else
		text:SetText('')
	end
end

-- The kind of frame (st.THEME_KINDS) an element's Theme draws it as. Its bars
-- (health, power, additional power, the castbar) draw as their unit frame's
-- unit does, at their own size (UF.SizedKind): a unit frame, a party or raid
-- member, or a small frame where the bronze box doesn't fit. Everything else
-- (the castbar's icon, the indicators) is a control, which Thick and Thin draw
-- as a small frame and Blizzard draws bare. configOverride is the one
-- UF:UpdateElement was handed, which UF:UpdateElementSize sizes it by.
function UF:ElementKind(element, configOverride)
	if not element:IsObjectType('StatusBar') then return 'control' end
	return UF.SizedKind(element.unitframe.base_unit, self:ElementSize(element, configOverride))
end

-- Whether an element's config puts it exactly over its unit frame: as wide and
-- as tall as the frame (Relative, 0), anchored to the frame itself (no element
-- or frame named) at the same point, with no offset (read as st:UnpackPoint
-- reads them: no relative point is the point, no offset 0).
function UF.FillsFrame(config)
	local position = config.position
	if not (position and config.relative_width and config.relative_height) then return false end
	if tonumber(config.width) ~= 0 or tonumber(config.height) ~= 0 then return false end
	if position.element or position.frame then return false end
	local point, _, relativePoint, x, y = st:UnpackPoint(position)
	return point == relativePoint and tonumber(x) == 0 and tonumber(y) == 0
end

-- The kinds a bar draws with a border of its own under Blizzard: the bronze
-- box, or a small frame's line where the box doesn't fit (UF.SizedKind).
local BORDERED = { unitframe = true, small = true }

-- The Theme and Background an element draws with: its config's, but None for
-- a bar drawn with a border (the bronze box, or a small frame's line) that
-- lies exactly over its unit frame (UF.FillsFrame) while both its own Theme
-- and its frame's draw in Blizzard's art. Filling the frame, it has the
-- frame's size and so its kind, and the frame's border alone shows on those
-- edges (health fills the frame by default). A bar that doesn't quite fill its
-- frame (resized, moved, anchored to another element) keeps its own border,
-- as does one over a frame drawn in another look; under Thick and Thin every
-- element draws its own pair, as before. configOverride as for
-- UF:ElementKind: the config the bar is sized by, where config is the one its
-- Theme comes from (UF:UpdateElement).
function UF:ElementTheme(element, config, configOverride)
	if BORDERED[self:ElementKind(element, configOverride)]
			and UF.FillsFrame(configOverride or config)
			and st:IsBlizzardLook(config.theme, config.background) then
		local frame = element.unitframe.config
		if st:IsBlizzardLook(frame.theme, frame.background) then
			return 'none', config.background
		end
	end
	return config.theme, config.background
end

-- Elements whose Theme draws their buttons or points, not the element: the
-- aura areas (auras.lua draws each aura button, as an aura) and the class
-- power row (classpower.lua draws each point). The area itself gets no
-- backdrop. An aura area is Blizzard's AuraContainer, and a frame anchored to
-- it must carry its layout aspect (.agents/taint.md, rule 11), so none of
-- SaftUI's is made there.
local BARE_ELEMENTS = { Buffs = true, Debuffs = true, ClassPower = true }

function UF:UpdateElement(element, configOverride)
    element.config = element:GetConfig()

    local config = element.config or configOverride

    local enabled = self:SetElementEnabled(element, configOverride)
    if not enabled then
        -- An element's texts usually live on the unit frame's TextOverlay, not
        -- on the element, so they don't hide with it. Enabling it again shows
        -- them through UpdateText below, each by its own config.
        if element.textElements then
            for _, text in pairs(element.textElements) do
                text:Hide()
            end
        end
        return false
    end

    if config.theme and not BARE_ELEMENTS[element.name] then
        -- Taken first: a call inside an argument list gives only its first return.
        local theme, background = self:ElementTheme(element, config, configOverride)
        st:SetBackdrop(element, theme, background, self:ElementKind(element, configOverride))
    end

    element:SetAlpha(config.alpha or 1)
    self:UpdateElementSize(element, configOverride)
    self:UpdateElementPosition(element, configOverride)
    self:UpdateElementLevel(element, configOverride)

    if element:IsObjectType('StatusBar') then
        self:UpdateStatusBarElement(element, configOverride)
    end

    if element:IsObjectType('FontString') then
        element:SetFontObject(st:GetFont(config.font))
    end

    if element.textElements then
        for key, text in pairs(element.textElements) do
            self:UpdateText(text, configOverride and configOverride[key] or nil)
        end
    end

    if element.icons then
        for _,icon in pairs(element.icons) do
            self:UpdateIcon(icon)
        end
    end

    return true
end

-- Whether an element shows: its config's Enable (a plate's config is its
-- kind's, nameplates.lua), except that a friendly unit's plate never shows
-- the parts only an enemy's does, the threat text (UF.PLATE_ENEMY_ONLY;
-- frame.friendly is set on each add).
function UF:ElementWanted(element)
    if not element.config.enable then return false end
    local frame = element.unitframe
    if frame and frame.isNamePlate and frame.friendly and UF.PLATE_ENEMY_ONLY[element.name] then
        return false
    end
    return true
end

-- Shows or hides an element (UF:ElementWanted), and returns its config's
-- Enable, which UF:UpdateElement goes on to place and size it by: a part a
-- friendly plate hides is still laid out, ready for the plate's next enemy.
-- It only shows or hides: oUF enables every element a frame has when it
-- builds the frame, before the frame's first update (UF.InitUnit,
-- UF:ApplyConfig). DisableElement is used only on plates, by their config
-- (nameplates.lua), because oUF's castbar Disable gives Blizzard's player
-- and pet castbars their events back (Libraries/oUF/elements/castbar.lua,
-- Disable), which the player castbar's option promises not to do. An element
-- oUF shows on its own updates hides itself again while it's off (power's
-- PostUpdate; power isn't on plates) or not wanted (the castbar's ShouldShow,
-- the indicators' PostUpdate).
function UF:SetElementEnabled(element)
    element:SetShown(self:ElementWanted(element))
    return element.config.enable
end

-- Sets a bar's colorTapping and colorReaction (health and power) from its
-- config. oUF registers their recolor event (UNIT_FACTION) in the bar's Enable,
-- and only if a flag is on then. While oUF has the bar enabled and running it
-- has given it setters, which set the flag and, forced, register or unregister
-- the event to match. Otherwise they're plain fields, which the next Enable
-- reads: before oUF enables the bar, and while it's disabled or paused (a plate
-- showing only widgets, nameplates.lua), where a setter would register the
-- event on a bar that's off.
function UF.SetFactionColorFlags(bar, config)
    local owner = bar.__owner
    if owner and bar.SetColorTapping and bar.SetColorReaction
            and owner:IsElementEnabled(bar.name) and not owner:IsElementPaused(bar.name) then
        bar:SetColorTapping(config.colorTapping, true)
        bar:SetColorReaction(config.colorReaction, true)
    else
        bar.colorTapping = config.colorTapping
        bar.colorReaction = config.colorReaction
    end
end

-- The width and height an element's config gives it: its size on both sides,
-- then its own width and height, each added to its unit frame's with Relative
-- on. nil for a side the config doesn't set, and both for an element that
-- isn't sized (noSize). configOverride, when given, is the config it's sized by.
function UF:ElementSize(element, configOverride)
    if element.noSize then return end
    local config = configOverride or element.config
    local unitframe = element.unitframe or element:GetParent()
    local width, height

    if config.size then
        width = config.relative_size and unitframe.config.height + config.size or config.size
        height = width
    end
    if config.height then
        height = config.relative_height and unitframe.config.height + config.height or config.height
    end
    if config.width then
        width = config.relative_width and unitframe.config.width + config.width or config.width
    end
    return width, height
end

function UF:UpdateElementSize(element, configOverride)
    local width, height = self:ElementSize(element, configOverride)
    if width then st:SetWidth(element, width) end
    if height then st:SetHeight(element, height) end
end

function UF:UpdateElementPosition(element, unitframe, configOverride)
    local config = configOverride or element.config
    unitframe = element.unitframe or element:GetParent()

    local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(config.position)
    local frame = self:GetFrame(unitframe, config.position)
    element:ClearAllPoints()
    element:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
end

function UF:UpdateElementLevel(element, configOverride)
    local config = configOverride or element.config
    if config.framelevel and element.SetFrameLevel then
        element:SetFrameLevel(config.framelevel)
    end
end

-- r, g, b of a color object or a plain { r, g, b } list (a config's customColor
-- is a list in the defaults, and can be a color object in a saved profile).
function UF.UnpackColor(color)
	if type(color) == 'table' and color.GetRGB then return color:GetRGB() end
	return color[1], color[2], color[3]
end

-- Colors a status bar's background (power, additional power, castbar: anything
-- with .bg and .config.bg) as a darker shade of the bar color.
-- oUF can hand us secret colors (smoothed power colors, secret class colors),
-- which can't be multiplied; for those the multiplier goes into the alpha
-- instead, which looks the same over the frame's dark backdrop.
function UF.SetPowerBackgroundColor(power, r, g, b)
	local bg = power.config.bg
	if issecretvalue(r) or issecretvalue(g) or issecretvalue(b) then
		power.bg:SetVertexColor(r, g, b, bg.alpha * bg.multiplier)
	else
		power.bg:SetVertexColor(r * bg.multiplier, g * bg.multiplier, b * bg.multiplier, bg.alpha)
	end
end

-- Where the Blizzard fills apply, by element name: the key of
-- st.ThemeArt.Control('unitbars').
local FILL_KEYS = { Health = 'health', Power = 'power', AdditionalPower = 'power' }

-- The Blizzard fill (a Control('unitbars') entry) an element's bar draws with,
-- or nil for the flat one: only health and the power bars, only where the
-- element's texture is the default (SaftUI Flat; a texture the user picked
-- stays), and only under the element's own resolved Theme being Blizzard's
-- (health set to None under SaftUI's Blizzard theme keeps the flat fill). The
-- castbar keeps its texture.
function UF.BlizzardFill(element, config)
	local key = FILL_KEYS[element.name]
	if not key then return nil end
	if config.texture ~= nil and config.texture ~= 'SaftUI Flat' then return nil end
	if not st:IsBlizzardLook(config.theme, config.background) then return nil end
	return st.ThemeArt.Control('unitbars')[key]
end

-- Draws a bar's fill and the background behind it: fill's art, tiled as it
-- says (a UF.BlizzardFill), or the flat texture (st.BLANK_TEX unless flat is
-- given) with no tiling. What was drawn is kept on the element, and a call
-- that would draw the same does nothing: a bar's own updates (power's every
-- tick) call this, and setting the art again after oUF's SetValue could
-- reset the fill's texture coordinates.
function UF:SetBarFill(element, fill, flat)
	flat = not fill and (flat or st.BLANK_TEX) or nil
	if element.drawnFill == (fill or false) and element.drawnFlat == flat then return end
	element.drawnFill, element.drawnFlat = fill or false, flat
	local bar = element:GetStatusBarTexture()
	if fill then
		bar:SetAtlas(fill.fill)
		if element.bg then element.bg:SetAtlas(fill.bg) end
	else
		element:SetStatusBarTexture(flat)
		bar = element:GetStatusBarTexture()
		if element.bg then element.bg:SetTexture(st.BLANK_TEX) end
	end
	local h, v = fill and fill.tileH or false, fill and fill.tileV or false
	bar:SetHorizTile(h)
	bar:SetVertTile(v)
	if element.bg then
		element.bg:SetHorizTile(h)
		element.bg:SetVertTile(v)
	end
end

-- Draws again what UpdateStatusBarElement last drew: for a bar's own updates
-- (power's), which used to put the flat texture back every time.
function UF:RedrawBarFill(element)
	UF:SetBarFill(element, element.barFill, element.barFlat)
end

function UF:UpdateStatusBarElement(element, configOverride)
    local config = configOverride or element.config

    if not element:IsObjectType('StatusBar') then
        return st:Error(element:GetName(), 'is not a status bar')
    end

    element.barFill = UF.BlizzardFill(element, config)
    element.barFlat = st:GetStatusBarTexture(config.texture)
    UF:SetBarFill(element, element.barFill, element.barFlat)
    element:SetReverseFill(config.reverse_fill or false)
	element:SetOrientation(config.vertical_fill and "VERTICAL" or "HORIZONTAL")

    if config.colorCustom then
		element:SetStatusBarColor(UF.UnpackColor(config.customColor))
	end

    if element.bg and config.bg then
        if config.bg.enable then
            element.bg:Show()
            element.bg:SetAlpha(config.bg.alpha)
            element.bg.multiplier = config.bg.multiplier
        else
            element.bg:Hide()
        end
    end
end

function UF:UpdateText(text, configOverride)
    local config = configOverride or text:GetConfig()
    if not text:IsObjectType('FontString') then
        return st:Error(text:GetName(), 'is not a text object')
    end

    UF:UpdateElement(text, configOverride)
    text:SetFontObject(st:GetFont(config.font))
end

function UF:UpdateIcon(icon)
    UF:UpdateElement(icon)
    st:SkinIcon(icon.texture)
end