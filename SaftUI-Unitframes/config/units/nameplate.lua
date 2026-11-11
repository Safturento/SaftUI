local st = SaftUI

-- SaftUI's nameplates (nameplates/nameplates.lua): on by default, with friendly
-- plates, and threat shown in a group only (threat_solo off). The width and
-- height are the plates' size, which every plate takes (the game has one size
-- for all of them). The elements' defaults are every unit's.
st.defaults.unitframes.profiles["**"].nameplate = {
    enable = true,
    friendly = true,
    threat_solo = false,
    width = 200,
    height = 20,
}
