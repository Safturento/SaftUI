-- Secret values for tests. In game, protected data (a unit's name, health,
-- level or reaction in restricted content, aura data in combat) can reach an
-- addon as a secret value (.agents/clients.md, "Secret values"), which the
-- stubs can't make. This makes stand-ins:
--   * S.secret(label): a userdata (newproxy, a Lua 5.1 base function the
--     harness keeps) whose metatable errors on indexing (read or write),
--     calling, `#`, `..`, arithmetic and ordering comparisons, as a secret does
--     in game. The label is what tostring gives, for test messages only.
--     Lua 5.1 can't catch everything the game refuses: `==` against a number
--     or string (__eq only fires between two tables or two userdata), so
--     `secret == 5` is quietly false here where the game errors, and
--     string.format('%s', secret) gives the label where the game errors. Code
--     must guard with issecretvalue before either; nothing here proves it did.
--   * S.install(): makes the global issecretvalue recognise every value
--     S.secret made, plus whatever it recognised before. Returns restore(),
--     which puts the old function back.
-- Not a test (no _test suffix), so the runner doesn't run it. Load it with
-- `local S = load_test_file('lib/secrets.lua')`; it makes no globals until
-- S.install().
local S = {}

-- Every secret made, kept weakly so a test's secrets go when it's done with them.
local made = setmetatable({}, { __mode = 'k' })

function S.secret(label)
	label = label or 'SECRET'
	local value = newproxy(true)
	local meta = getmetatable(value)
	local function refuse(what)
		return function() error(('attempt to %s a secret value (%s)'):format(what, label), 2) end
	end
	meta.__tostring = function() return label end
	meta.__index, meta.__newindex = refuse('index'), refuse('index')
	meta.__call, meta.__len, meta.__concat = refuse('call'), refuse('take the length of'), refuse('concatenate')
	meta.__lt, meta.__le = refuse('compare'), refuse('compare')
	for _, op in ipairs({ '__add', '__sub', '__mul', '__div', '__mod', '__pow', '__unm' }) do
		meta[op] = refuse('do arithmetic on')
	end
	made[value] = true
	return value
end

function S.install()
	local old = issecretvalue
	issecretvalue = function(value)
		if made[value] then return true end
		return old ~= nil and old(value) or false
	end
	return function() issecretvalue = old end
end

return S
