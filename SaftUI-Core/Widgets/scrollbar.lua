local st = SaftUI

-- A thumb is a 'thumb' state frame (Widgets/states.lua): its fill rests in
-- ST.THUMB_REST (kit-edge, #4d4d4d), is lighter under the mouse and darker held,
-- all the helpers' (st:SetState from the mouse hooks; nothing is written onto
-- the thumb, which is Blizzard's). Its rest color comes only from an explicit
-- st:PaintStates, so it is called where the thumb is skinned and after every
-- redraw. None under the Blizzard theme, where the thumb is a control with no
-- backdrop of SaftUI's, and MinimalScrollBar's own art shows.

-- thumb -> the layers of its scroll bar that hold MinimalScrollBar's own art,
-- { frame, layer } each: the thumb's, the track's and the steppers'.
local barLayers = setmetatable({}, { __mode = 'k' })

-- Turns MinimalScrollBar's own art on under the Blizzard theme
-- (EnableDrawLayer) and off under the others, as the thumb is drawn, then
-- draws its states for the look and puts its rest color back. Runs again after
-- every recolor and redraw (st:KeepOwnColors). Widget methods only: chat's
-- scroll bar is Blizzard's.
local function DrawScrollBar(thumb)
    local blizzard = st:DrawnTheme(thumb) == 'blizzard'
    for _, entry in ipairs(barLayers[thumb]) do
        if blizzard then
            entry[1]:EnableDrawLayer(entry[2])
        else
            entry[1]:DisableDrawLayer(entry[2])
        end
    end
    st:RestyleStates(thumb)
    st:PaintStates(thumb)
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
    st:AddStates(thumb, 'thumb', {
        solidRest = function() return unpack(st.States.THUMB_REST) end,
        blizzard = function() return st:DrawnTheme(thumb) == 'blizzard' end,
    })
    DrawScrollBar(thumb)
    st:KeepOwnColors(thumb, DrawScrollBar)

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