local ADDON_NAME, st = ...

local GD = st:NewModule('Grid')

function GD:OnInitialize()
    self.GridLines = {
        ['Horizontal'] = {},
        ['Vertical'] = {}
    }

    --st.config.profile.grid.horizontalSpacing
    --st.config.profile.grid.verticalSpacing
end