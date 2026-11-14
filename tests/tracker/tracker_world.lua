-- The world SaftUI-Tracker's tests run in. Not a test (no _test suffix); a
-- test loads it with `local TW = load_test_file('tracker/tracker_world.lua')`.
--
--   TW.toc_files()      the TOC's Lua files, in order, as the game loads them,
--                       by path from the repo root ('SaftUI-Tracker/init.lua').
--   TW.world(opts)      a fresh world: st, TR. opts:
--                         client   'forever' (default) or 'retail'
--                         on       the profile's switch (tracker.enable)
--                         misc     Misc's config loaded (true), or a table
--                                  { skinning, skin, otp } to load those too
--                         blizzard Blizzard's tracker built from the misc
--                                  fixture (true, or its OT.build options);
--                                  TW.OT is the fixture
--                         combat   in combat when the addon enables
--                         addons   names for C_AddOns.IsAddOnLoaded
--                         before   function(st) run before SaftUI-Tracker's
--                                  files load
--                       It runs T.client, load_editmode(), st.config.char = {},
--                       the TOC's files with apply_defaults() after config.lua,
--                       then TR:Enable().
--   TW.counts           what SaftUI-Tracker made, counted from just before its
--                       files load: frames, hooks, events (frame
--                       RegisterEvent) and secure frames.
--   TW.combat(on)       combat starts or ends: stub.in_combat, then
--                       PLAYER_REGEN_DISABLED or PLAYER_REGEN_ENABLED.
--
-- Real: SaftUI-Tracker's files, Core's helpers and edit mode, and, where asked
-- for, Misc's.
local T = load_test_file('lib/theme_helpers.lua')

local TW = {}

TW.counts = { frames = 0, hooks = 0, events = 0, secure = 0 }

function TW.toc_files()
	local text = assert(read_saftui_source('SaftUI-Tracker/SaftUI-Tracker.toc'))
	local files = {}
	for line in (text .. '\n'):gmatch('(.-)\r?\n') do
		line = line:gsub('^%s+', ''):gsub('%s+$', '')
		if line ~= '' and not line:find('^#') and line:find('%.lua$') then
			files[#files + 1] = 'SaftUI-Tracker/' .. line:gsub('\\', '/')
		end
	end
	return files
end

local counting = false

-- Counts frames, hooks and events from now on. Frame methods live in a table
-- per frame type (getmetatable(frame).__index), so each is wrapped once.
local function InstallCounters()
	local counts = TW.counts
	counts.frames, counts.hooks, counts.events, counts.secure = 0, 0, 0, 0
	local create, hook = CreateFrame, hooksecurefunc
	local wrapped = {}
	for _, kind in ipairs({ 'Frame', 'Button', 'CheckButton', 'ScrollFrame', 'EditBox', 'StatusBar', 'Slider', 'Cooldown', 'GameTooltip' }) do
		local ok, frame = pcall(create, kind)
		local methods = ok and getmetatable(frame).__index
		if type(methods) == 'table' and not wrapped[methods] then
			wrapped[methods] = true
			for _, name in ipairs({ 'RegisterEvent', 'RegisterUnitEvent', 'RegisterAllEvents' }) do
				local original = methods[name]
				if original then
					methods[name] = function(...)
						if counting then counts.events = counts.events + 1 end
						return original(...)
					end
				end
			end
		end
	end
	CreateFrame = function(frameType, name, parent, template, ...)
		local frame = create(frameType, name, parent, template, ...)
		if counting then
			counts.frames = counts.frames + 1
			if tostring(template or ''):find('Secure') then counts.secure = counts.secure + 1 end
		end
		return frame
	end
	hooksecurefunc = function(...)
		if counting then counts.hooks = counts.hooks + 1 end
		return hook(...)
	end
end

function TW.world(opts)
	opts = opts or {}
	counting = false
	local st = T.client(opts.client or 'forever')
	load_editmode()
	st.config.char = {}
	InstallCounters()
	if opts.addons then
		for _, name in ipairs(opts.addons) do stub.loaded_addons[name] = true end
	end

	TW.OT, TW.SK, TW.OTP = nil, nil, nil
	if opts.misc then
		local misc = type(opts.misc) == 'table' and opts.misc or {}
		load_saftui('SaftUI-Misc/config.lua')
		apply_defaults()
		if misc.skinning or misc.skin then
			load_saftui('SaftUI-Misc/Skinning/skinning.lua')
			load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua')
		end
		if misc.otp then
			load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua')
		end
		if opts.blizzard then
			TW.OT = load_test_file('misc/fixtures/objective_tracker.lua')
			TW.OT.build(type(opts.blizzard) == 'table' and opts.blizzard or nil)
		end
		-- Misc's modules enable before SaftUI-Tracker's, as the TOCs load in
		-- the game's order: Skinning, then its skins, then the tracker's mover.
		if misc.skinning or misc.skin then
			TW.SK = st:GetModule('Skinning')
			TW.SK:Enable()
		end
		if misc.otp then
			TW.OTP = st:GetModule('ObjectiveTracker')
			TW.OTP:Enable()
		end
	end

	if opts.before then opts.before(st) end

	counting = true
	local files = TW.toc_files()
	for _, file in ipairs(files) do
		load_saftui(file)
		if file == 'SaftUI-Tracker/config.lua' then apply_defaults() end
	end
	if opts.on ~= nil then st.config.profile.tracker.enable = opts.on end
	local TR = st:GetModule('Tracker')
	if opts.combat then stub.in_combat = true end
	TR:Enable()
	counting = false
	return st, TR
end

function TW.combat(on)
	stub.in_combat = on and true or false
	stub.fire_event(on and 'PLAYER_REGEN_DISABLED' or 'PLAYER_REGEN_ENABLED')
end

return TW
