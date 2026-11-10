local st = SaftUI

-- The thumb's fill: the pushed color while it's pressed, the hover color under
-- the mouse, else the button color. Kept through a theme recolor.
local function ColorThumb(thumb)
    local colors = st.config.profile.colors.button
    local color = thumb.pressed and colors.pushed or thumb.entered and colors.hover or colors.normal
    thumb.backdrop:SetBackdropColor(color:GetRGB())
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
    thumb:DisableDrawLayer('BACKGROUND')
    thumb:DisableDrawLayer('ARTWORK')
    st:SetBackdrop(thumb, 'theme', 'solid', 'small')
    ColorThumb(thumb)
    st:KeepOwnColors(thumb, ColorThumb)

    thumb:HookScript('OnEnter', thumbOnEnter)
    thumb:HookScript('OnLeave', thumbOnLeave)
    thumb:HookScript('OnMouseDown', thumbOnMouseDown)
    thumb:HookScript('OnMouseUp', thumbOnMouseUp)

    local track = scrollBar:GetTrack()
    track:DisableDrawLayer('ARTWORK')
    scrollBar:SetAlpha(1)
    track:ClearAllPoints()
    track:SetPoint('TOP', 0, -2)
    track:SetPoint('BOTTOM', 0, 2)

    local forward = scrollBar:GetForwardStepper()
    forward:DisableDrawLayer('BACKGROUND')

    local backward = scrollBar:GetBackStepper()
    backward:DisableDrawLayer('BACKGROUND')
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