local st = SaftUI

local function thumbOnEnter(self)
    self.entered = true
        if self.pressed then return end
        self.backdrop:SetBackdropColor(unpack(st.config.profile.colors.button.hover))
end

local function thumbOnLeave(self)
    self.entered = false
    if self.pressed then return end
    self.backdrop:SetBackdropColor(unpack(st.config.profile.colors.button.normal))
end

local function thumbOnMouseDown(self)
    self.pressed = true
    self.backdrop:SetBackdropColor(unpack(st.config.profile.colors.button.pushed))
end

local function thumbOnMouseUp(self)
    self.pressed = false
    if self.entered then
        self.backdrop:SetBackdropColor(unpack(st.config.profile.colors.button.hover))
    else
        self.backdrop:SetBackdropColor(unpack(st.config.profile.colors.button.normal))
    end
end

function st:HideScrollBar(scrollBar)
    local thumb = scrollBar:GetThumb()
    thumb:DisableDrawLayer('BACKGROUND')
    thumb:DisableDrawLayer('ARTWORK')
    local track = scrollBar:GetTrack()
    track:DisableDrawLayer('ARTWORK')
    scrollBar:SetAlpha(1)

    local forward = scrollBar:GetForwardStepper()
    forward:DisableDrawLayer('BACKGROUND')

    local backward = scrollBar:GetBackStepper()
    backward:DisableDrawLayer('BACKGROUND')
end

function st:SkinScrollBar(scrollBar)
    st:HideScrollBar(scrollBar)

    local thumb = scrollBar:GetThumb()
    st:SetBackdrop(thumb, 'thick')
    thumb.backdrop:SetBackdropColor(unpack(st.config.profile.colors.button.normal))

    thumb:HookScript('OnEnter', thumbOnEnter)
    thumb:HookScript('OnLeave', thumbOnLeave)
    thumb:HookScript('OnMouseDown', thumbOnMouseDown)
    thumb:HookScript('OnMouseUp', thumbOnMouseUp)

    local track = scrollBar:GetTrack()
    track:ClearAllPoints()
    track:SetPoint('TOP', 0, -2)
    track:SetPoint('BOTTOM', 0, 2)
end

--function st:CreateScrollbar(name, parent)
--end