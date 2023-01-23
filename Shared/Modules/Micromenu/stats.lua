local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

local BUTTON_WIDTH = 48

local function getColorGradient(percent, inverted)
    local colors = st.config.profile.colors.text
    local badR, badG, badB = unpack(colors.orange)
    local okayR, okayG, okayB = unpack(colors.yellow)
    local goodR, goodG, goodB = unpack(colors.green)

    if inverted then
        return st:ColorGradient(percent,
           goodR, goodG, goodB, okayR, okayG, okayB, badR, badG, badB)
    else
        return st:ColorGradient(percent,
            badR, badG, badB, okayR, okayG, okayB, goodR, goodG, goodB)
    end
end

function MicroMenu:CreateLatencyButton()
    local latency = st:CreateFrame('Frame', nil, button)
    latency.width = BUTTON_WIDTH
    st:SetBackdrop(latency, 'thick')
    latency.text = latency:CreateFontString(nil, 'OVERLAY')
    latency.text:SetFontObject(st:GetFont('pixel'))
    latency.text:SetPoint('CENTER', 1, 0)
    latency.text:SetText('9999ms')


    self.Latency = latency
    self:HookScript(latency, 'OnUpdate', 'UpdateLatency')

    return latency
end

function MicroMenu:UpdateLatency(latency)
    local now = GetTime()
    if latency.lastUpdate and now - latency.lastUpdate < 1 then return end
    latency.lastUpdate = now

    local ms = select(3, GetNetStats())
    latency.text:SetFormattedText('%dms', ms)
    latency.text:SetTextColor(getColorGradient(ms/600, true))
end

function MicroMenu:CreateFramerateButton()
    local framerate = st:CreateFrame('Frame', nil, button)
    framerate.width = BUTTON_WIDTH
    st:SetBackdrop(framerate, 'thick')
    framerate:SetPoint('TOPLEFT')
    framerate:SetPoint('BOTTOMRIGHT', button, 'RIGHT', 0, 1)
    framerate.text = framerate:CreateFontString(nil, 'OVERLAY')
    framerate.text:SetFontObject(st:GetFont('pixel'))
    framerate.text:SetPoint('CENTER', 1, 0)
    framerate.text:SetText('999fps')

    self.Framerate = framerate
    self:HookScript(framerate, 'OnUpdate', 'UpdateFramerate')

    return framerate
end

function MicroMenu:UpdateFramerate(framerate)
    local now = GetTime()
    if framerate.lastUpdate and now - framerate.lastUpdate < 1 then return end
    framerate.lastUpdate = now

    local fps = GetFramerate()
    framerate.text:SetFormattedText('%dfps', fps)
    framerate.text:SetTextColor(getColorGradient(fps/144))
end