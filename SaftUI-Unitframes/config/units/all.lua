local st = SaftUI

-- All units: the values every unit frame follows until it owns a setting
-- (config/shared.lua). The table is unit-shaped, so AceDB's unit wildcard
-- ('**' in config/default.lua) gives it every default a unit that names nothing
-- has; it names one setting of its own. Debuffs > Enable is the one setting whose
-- majority is not the every-unit default: six of the eleven members that have
-- Debuffs show them on (Player, Target, Focus, Boss, Party, Raid 10) against a
-- default of off, so a fresh profile's All units starts on, and shows no reset
-- icon for it. A fresh profile's conversion writes nothing into All units.
st.defaults.unitframes.profiles['**'].all = {
    debuffs = { enable = true },
}
