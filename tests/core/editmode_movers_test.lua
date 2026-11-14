-- What a mover's registration tells the edit mode bar (SaftUI-Core/EditMode/
-- editmode.lua): the module it belongs to, whether its frame is turned off
-- (isDisabled) or on but not on screen (isHidden), and the position Reset
-- goes back to. Also a scan that every registration in every addon gives them.
--
-- Real: Core's helpers and the edit mode files. The movers are made through
-- st:RegisterConfigMover on stub frames.

load_core_helpers()
local T = load_test_file('lib/theme_helpers.lua')
local S = load_test_file('lib/secrets.lua')
load_editmode()

local st = SaftUI
local EM = st.EditModeFrames

local function add_mover(key, extra)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	frame:SetPoint('CENTER')
	local config = { position = { point = 'CENTER', x_off = 0, y_off = 0 } }
	local spec = { key = key, config = function() return config end, apply = function() end }
	for field, value in pairs(extra or {}) do spec[field] = value end
	return st:RegisterConfigMover(frame, spec)
end

test('RegisterConfigMover passes module, the predicates and noDefaultReason through; defaults gives a fresh copy', function()
	local defaults = { position = { point = 'TOP', frame = 'UIParent', rel_point = 'TOP', x_off = 0, y_off = -40 } }
	local mover = add_mover('m1', { module = 'Chat', isHidden = function() return true end,
		defaults = function() return defaults end, noDefaultReason = 'a reason' })
	eq(EM:MoverModule(mover), 'Chat', 'module')
	eq(EM:IsMoverHidden(mover), true, 'isHidden')
	eq(mover.def.noDefaultReason, 'a reason', 'noDefaultReason passes through')
	eq(mover.def.defaults, nil, 'defaults is turned into getDefaultPosition, not passed on')
	local copy = EM:GetDefaultPosition(mover)
	eq(copy.y_off, -40, 'the default position')
	copy.y_off = 99
	eq(defaults.position.y_off, -40, 'a write into the copy never reaches the defaults')
	check(EM:GetDefaultPosition(mover) ~= copy, 'a new copy each call')
end)

test('a mover without a module is Other; a missing, failing, secret or non-boolean predicate is false', function()
	local plain = add_mover('m2')
	eq(EM.OTHER_MODULE, 'Other', 'the name')
	eq(EM:MoverModule(plain), 'Other', 'no module')
	eq(EM:IsMoverDisabled(plain), false, 'no isDisabled')
	eq(EM:IsMoverHidden(plain), false, 'no isHidden')
	eq(EM:GetDefaultPosition(plain), nil, 'no default')

	local failing = add_mover('m3', { isDisabled = function() error('boom') end })
	take_errors()
	eq(EM:IsMoverDisabled(failing), false, 'an erroring isDisabled')
	eq(#take_errors(), 1, 'reported to the error handler')

	local restore = S.install()
	local secret = add_mover('m4', { isHidden = function() return S.secret('shown') end })
	eq(EM:IsMoverHidden(secret), false, 'a secret')
	eq(#take_errors(), 0, 'no error for a secret')
	restore()

	local number = add_mover('m5', { isHidden = function() return 1 end, isDisabled = function() return 'yes' end })
	eq(EM:IsMoverHidden(number), false, 'a number is not true')
	eq(EM:IsMoverDisabled(number), false, 'a string is not true')

	local yes = add_mover('m6', { isDisabled = function() return true end })
	eq(EM:IsMoverDisabled(yes), true, 'true is true')

	local ok, err = pcall(add_mover, 'm7', { defaults = function() return {} end, getDefaultPosition = function() end })
	eq(ok, false, 'both defaults and getDefaultPosition')
	check(tostring(err):find('give defaults or getDefaultPosition, not both', 1, true), 'the error names both')
end)

test('a defaults table with no position gives no default', function()
	local mover = add_mover('m8', { defaults = function() return {} end })
	eq(EM:GetDefaultPosition(mover), nil, 'no position')
	local none = add_mover('m9', { defaults = function() return nil end })
	eq(EM:GetDefaultPosition(none), nil, 'no table')
end)

local MODULES = { ['Action bars'] = true, ['Bags'] = true, ['Chat'] = true, ['Loot'] = true,
	['Minimap'] = true, ['Misc'] = true, ['Tracker'] = true, ['Unit frames'] = true }

test('every mover SaftUI registers names one of the eight modules, and a default or the reason it has none', function()
	local sites, problems = 0, {}
	for _, path in ipairs(T.saftui_files()) do
		if path ~= 'SaftUI-Core/EditMode/editmode.lua' then
			local text = read_saftui_source(path)
			if text then
				local line = 0
				local lines = {}
				for l in (text .. '\n'):gmatch('([^\n]*)\n') do lines[#lines + 1] = l end
				while line < #lines do
					line = line + 1
					if lines[line]:find('st:RegisterMover%(') or lines[line]:find('st:RegisterConfigMover%(') then
						sites = sites + 1
						local body = {}
						local i = line
						repeat
							body[#body + 1] = lines[i]
							i = i + 1
						until i > #lines or lines[i - 1] ~= lines[line] and lines[i - 1]:find('^%s*}%)%s*$')
						local call = table.concat(body, '\n')
						local name = call:match("module = '([^']+)'")
						local where = path .. ':' .. line
						if not name then
							problems[#problems + 1] = where .. ' has no module'
						elseif not MODULES[name] then
							problems[#problems + 1] = where .. ' names ' .. name
						end
						if not (call:find('defaults =', 1, true) or call:find('getDefaultPosition =', 1, true)
								or call:find('noDefaultReason =', 1, true)) then
							problems[#problems + 1] = where .. ' has no default and no noDefaultReason'
						end
					end
				end
			end
		end
	end
	check(sites >= 15, 'found ' .. sites .. ' call sites, expected at least 15')
	eq(table.concat(problems, '\n'), '', 'registrations without their data')
end)
