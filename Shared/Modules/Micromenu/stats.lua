local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

local lastUpdate = GetTime()

function MicroMenu:UpdateNetStats(button)
    local now = GetTime()
    if now - lastUpdate < 1 then return end
    lastUpdate = now

    local colors = st.config.profile.colors.text
    local badR, badG, badB = unpack(colors.orange)
    local okayR, okayG, okayB = unpack(colors.yellow)
    local goodR, goodG, goodB = unpack(colors.green)

    local framerate = GetFramerate()
    button.fps.text:SetFormattedText('%dfps', framerate)
    button.fps.text:SetTextColor(st:ColorGradient(framerate/144,
            badR, badG, badB, okayR, okayG, okayB, goodR, goodG, goodB))

    local latency = select(3, GetNetStats())
    button.ms.text:SetFormattedText('%dms', latency)
    button.ms.text:SetTextColor(st:ColorGradient(latency/600,
           goodR, goodG, goodB, okayR, okayG, okayB, badR, badG, badB))
end

function MicroMenu:CreateNetStatsButton()
    local button = st:CreateFrame('Frame', 'SaftUI_NetStats', UIParent)
    button.width = 49
    st:SetBackdrop(button, 'thick')

    fps = st:CreateFrame('Frame', nil, button)
    st:SetBackdrop(fps, 'thick')
    fps:SetPoint('TOPLEFT')
    fps:SetPoint('BOTTOMRIGHT', button, 'RIGHT', 0, 1)
    fps.text = fps:CreateFontString(nil, 'OVERLAY')
    fps.text:SetFontObject(st:GetFont('pixel'))
    fps.text:SetPoint('CENTER', 1, 0)
    fps.text:SetText('999fps')
    button.fps = fps

    ms = st:CreateFrame('Frame', nil, button)
    st:SetBackdrop(ms, 'thick')
    ms:SetPoint('BOTTOMLEFT')
    ms:SetPoint('TOPRIGHT', button, 'RIGHT', 0, -1)
    ms.text = ms:CreateFontString(nil, 'OVERLAY')
    ms.text:SetFontObject(st:GetFont('pixel'))
    ms.text:SetPoint('CENTER', 1, 0)
    ms.text:SetText('9999ms')
    button.ms = ms

    self.NetStatsButton = button

    self:HookScript(self.NetStatsButton, 'OnUpdate', 'UpdateNetStats')

    return button
end