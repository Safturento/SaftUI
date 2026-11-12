local st = SaftUI

-- SaftUI's nameplates (nameplates/nameplates.lua): on by default, with friendly
-- plates, and threat shown in a group only (threat_solo off). The width and
-- height are the plates' size, which every plate takes (the game has one size
-- for all of them). The elements' defaults are every unit's.
st.defaults.unitframes.profiles["**"].nameplate = {
    enable = true,
    friendly = true,
    threat_solo = false,
    -- The threat text (nameplates/threat.lua): your threat on an enemy as a
    -- percent, small, above the bar's right end, level with the debuffs.
    threat = {
        enable = true,
        font = 'pixel',
        position = { point = 'BOTTOMRIGHT', element = 'Health', rel_point = 'TOPRIGHT', x_off = 0, y_off = 6 },
    },
    width = 200,
    height = 20,
}
