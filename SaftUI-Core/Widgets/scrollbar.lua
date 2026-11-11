local st = SaftUI

-- The thumb's fill: the pushed color while it's pressed, the hover color under
-- the mouse, else the button color. None under the Blizzard theme, where the
-- thumb is a control with no backdrop of SaftUI's, and MinimalScrollBar's own
-- art shows.
local function ColorThumb(thumb)
    if st:DrawnTheme(thumb) == 'blizzard' then return end
    local colors = st.config.profile.colors.button
    local color = thumb.pressed and colors.pushed or thumb.entered and colors.hover or colors.normal
    thumb.backdrop:SetBackdropColor(color:GetRGB())
end

-- thumb -> the layers of its scroll bar that hold MinimalScrollBar's own art,
-- { frame, layer } each: the thumb's, the track's and the steppers'.
local barLayers = setmetatable({}, { __mode = 'k' })

-- Turns MinimalScrollBar's own art on under the Blizzard theme
-- (EnableDrawLayer) and off under the others, as the thumb is drawn, then
-- colors the thumb. Runs again after every recolor and redraw
-- (st:KeepOwnColors). Widget methods only: chat's scroll bar is Blizzard's.
local function DrawScrollBar(thumb)
    local blizzard = st:DrawnTheme(thumb) == 'blizzard'
    for _, entry in ipairs(barLayers[thumb]) do
        if blizzard then
            entry[1]:EnableDrawLayer(entry[2])
        else
            entry[1]:DisableDrawLayer(entry[2])
        end
    end
    ColorThumb(thumb)
end

local function thumbOnEnter(self)
    self.entered = true
    ColorThumb(self)
end

local function thumbOnLeave(self)
    self.entered = false
    ColorThumb(self)
end

local function thumbOnMouseDown(self)
    self.pressed = true
    ColorThumb(self)
end

local function thumbOnMouseUp(self)
    self.pressed = false
    ColorThumb(self)
end

function st:SkinNewScrollBar(scrollBar)
    if not scrollBar.GetThumb then return end

    local thumb = scrollBar:GetThumb()
    local track = scrollBar:GetTrack()
    barLayers[thumb] = {
        { thumb, 'BACKGROUND' }, { thumb, 'ARTWORK' }, { track, 'ARTWORK' },
        { scrollBar:GetForwardStepper(), 'BACKGROUND' }, { scrollBar:GetBackStepper(), 'BACKGROUND' },
    }
    st:SetBackdrop(thumb, 'theme', 'solid', 'control')
    DrawScrollBar(thumb)
    st:KeepOwnColors(thumb, DrawScrollBar)

    thumb:HookScript('OnEnter', thumbOnEnter)
    thumb:HookScript('OnLeave', thumbOnLeave)
    thumb:HookScript('OnMouseDown', thumbOnMouseDown)
    thumb:HookScript('OnMouseUp', thumbOnMouseUp)

    scrollBar:SetAlpha(1)
    track:ClearAllPoints()
    track:SetPoint('TOP', 0, -2)
    track:SetPoint('BOTTOM', 0, 2)
end

function st:SkinScrollBar(scrollBar)
    if scrollBar.GetThumb then
        return self:SkinNewScrollBar(scrollBar)
    end

    scrollBar.ThumbTexture:SetTexture(nil)
    scrollBar.Thumb = st:CreateFrame('frame')
    scrollBar.ScrollDownButton:SetTexture(nil)
    scrollBar.ScrollUpButton:SetTexture(nil)
end

function st:CreateScrollBar(parent)
    local scrollBar = CreateFrame('EventFrame', nil, parent, 'MinimalScrollBar')
    scrollBar:SetPoint('TOPLEFT', parent, 'TOPRIGHT')
    scrollBar:SetPoint('BOTTOMLEFT', parent, 'BOTTOMRIGHT')

    st:SkinScrollBar(scrollBar)

    return scrollBar
end