local st = SaftUI

local GD = st:NewModule('Grid')
local gridFrame = CreateFrame('frame', nil, UIParent)

local function createLine()
    local line = gridFrame:CreateTexture(nil, 'OVERLAY')
    line:SetTexture(st.BLANK_TEX)
    line:SetVertexColor(0, 0, 0)
    line:SetSize(st.mult, st.mult)
    return line
end

local function createHorizontalLine(yPos)
    local line = createLine()
    line:SetPoint('TOPLEFT', 0, -st:Scale(yPos))
    line:SetPoint('TOPRIGHT', 0, -st:Scale(yPos))
    return line
end

local function createVerticalLine(xPos)
    local line = createLine()
    line:SetPoint('TOPLEFT', st:Scale(xPos), 0)
    line:SetPoint('BOTTOMLEFT', st:Scale(xPos), 0)
   return line
end

function GD:OnInitialize()
    self.GridLines = {
        ['Horizontal'] = {},
        ['Vertical'] = {}
    }
    gridFrame:SetAllPoints()
    self.GridFrame = gridFrame

    local x, y = UIParent:GetSize()
    local horizontalCenter = createHorizontalLine(y/2)
    horizontalCenter:SetVertexColor(1, 0, 0 )
    local verticalCenter = createVerticalLine(x/2)
    verticalCenter:SetVertexColor(1, 0, 0 )

    for i=0, floor(UIParent:GetHeight()/st.config.profile.grid.verticalSpacing) do
        self.GridLines.Horizontal[i] = createHorizontalLine(
            (i + 1) * st.config.profile.grid.verticalSpacing)
    end

    for i=0, floor(UIParent:GetWidth()/st.config.profile.grid.horizontalSpacing) do
        self.GridLines.Vertical[i] = createVerticalLine(
            (i + 1) * st.config.profile.grid.horizontalSpacing)
    end

    self.GridFrame:Hide()
end