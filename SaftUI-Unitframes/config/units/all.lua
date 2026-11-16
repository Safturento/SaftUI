local st = SaftUI

-- All units' own defaults (config/shared.lua), over what AceDB's unit wildcard ('**' in
-- config/default.lua) gives a unit that names nothing. They are NOT registered with AceDB: a named `all`
-- table in the defaults would give every unit frame profile a block of empty tables in its saved data
-- before anything converts it. shared.lua lays them over the wildcard's (UF.DefaultShared), and the
-- first conversion writes them into a profile's All units.
-- Debuffs > Enable is the one setting whose majority is not the every-unit default: six of the eleven
-- members that have Debuffs show them on (Player, Target, Focus, Boss, Party, Raid 10) against a default
-- of off, so a fresh profile's All units starts on.
st.ALL_UNITS_DEFAULTS = {
    debuffs = { enable = true },
}
