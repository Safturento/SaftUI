-- Every unit, group and plate page of /sui > Unit frames, every tab and sub tab, drawn on whole pixels: on a
-- customized, converted profile (so the own marks and the diff icons are drawn), under Thick, Thin and
-- Blizzard, with and without the size noise a scaled client gives (stub.size_noise), at a whole and at half
-- the window's width. lib/pixels.lua says what is off.
local SW = load_test_file('unitframes/shared_world.lua')
local P_ = load_test_file('lib/pixels.lua')
local PW = load_test_file('unitframes/page_world.lua').world()
local st, UF, OM, OB = PW.st, PW.UF, PW.OM, PW.st.OptionsBody
load_editmode()
_G.GameTooltip = _G.GameTooltip or CreateFrame('GameTooltip', 'GameTooltip', UIParent)
SW.customize(UF:GetProfileConfig())
UF:PrepareShared()
assert(UF:SharedReady(), 'the profile is converted')

local function tree() return { Unitframes = UF:GetConfigTable() } end
local PICKS = { 'all', 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate' }

local function in_look(look, fn)
	local was = st.config.profile.theme.name
	st.config.profile.theme.name = look
	local ok, err = pcall(fn)
	st.config.profile.theme.name = was
	if not ok then error(err, 0) end
end

local function views(root, unit)
	local out = {}
	local page = root.Unitframes.args[unit]
	for tab, group in pairs(page.args) do
		if type(group) == 'table' and group.type == 'group' then
			if group.childGroups == 'tab' then
				for sub, g in pairs(group.args) do
					if type(g) == 'table' and g.type == 'group' then out[#out + 1] = { tab, sub } end
				end
			else
				out[#out + 1] = { tab }
			end
		end
	end
	return out
end

for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
	for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
		for _, width in ipairs({ 774, 388 }) do
			test(('every page on whole pixels: %s, noise %s, width %d'):format(look, tostring(noise), width), function()
				stub.size_noise = noise
				in_look(look, function()
					local root = tree()
					local bad = {}
					for _, unit in ipairs(PICKS) do
						for _, v in ipairs(views(root, unit)) do
							local content = CreateFrame('Frame', nil, UIParent)
							content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
							content:SetSize(width, 900)
							local body = OB.New(content, root, nil, width)
							if width == 388 then body:SetWidth(388, true) end
							local view = OM.BuildView(root, 'Unitframes', { pick = unit, tab = v[1], subtab = v[2] })
							body:Draw(view.sections)
							local off = P_.off(content)
							if #off > 0 then bad[#bad + 1] = unit .. '/' .. v[1] .. (v[2] and ('/' .. v[2]) or '') .. ': ' .. P_.report(off):sub(1, 160) end
							body:Release()
						end
					end
					eq(#bad, 0, table.concat(bad, '\n'))
				end)
				stub.size_noise = 0
			end)
		end
	end
end
