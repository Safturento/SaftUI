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
--                         enabling function(st, TR) run after Misc's modules
--                                  enable, just before TR:Enable()
--                         before   function(st) run before SaftUI-Tracker's
--                                  files load
--                       It runs as the game does: T.client, load_editmode(),
--                       st.config.char = {}, Misc's files and Blizzard's tracker
--                       (when asked), then SaftUI-Tracker's files with st.config
--                       NOT there (the game makes it at login, so a file-scope
--                       read of it fails), then st.config back and
--                       apply_defaults(), opts.on and opts.combat applied, and
--                       only then every module enables: Misc's Skinning and its
--                       tracker mover first (the Tracker module exists by then,
--                       its OnEnable not yet run), then TR:Enable().
--   TW.snapshot(frame)  a string of a frame's points, shown state, parent,
--                       alpha and scripts, to compare before and after.
--   TW.counts           what SaftUI-Tracker made, counted from just before its
--                       files load: frames, hooks (hooksecurefunc and frame
--                       HookScript, AceHook's script hooks among them), scripts
--                       (SetScript on a frame it didn't make), events (frame
--                       RegisterEvent), timers (C_Timer.After, NewTimer,
--                       NewTicker) and secure frames. Misc's enables aren't
--                       counted.
--   TW.combat(on)       combat starts or ends: stub.in_combat, then
--                       PLAYER_REGEN_DISABLED or PLAYER_REGEN_ENABLED.
--   TW.scroll_frame(parent)
--                       the scroll frame's stand-in (Ruling 24): TR.NewScrollFrame
--                       in the world, where the game's is st:CreateScrollFrame.
--                       That needs Blizzard's ScrollFrameTemplate and the scroll
--                       bar skin, which the stubs lack, so this is the bags'
--                       stand-in (tests/bags/container_helpers.lua) with the
--                       rest of the contract the window reads: a ScrollFrame
--                       with its ScrollChild, SetContentSize (which sizes the
--                       child; the game's also calls UpdateScrollChildRect), and
--                       a ScrollBar with the anchors and width Blizzard's
--                       template gives it (6 right of the frame, 2 down and 5 up,
--                       8 wide), so st:ScrollBarRoom reads 14. It does not clamp
--                       SetVerticalScroll as the game's frame does: the window's
--                       own clamp is what a test sees.
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
		if line ~= '' and not line:find('^#') then
			if not line:find('%.lua$') then
				error('SaftUI-Tracker.toc: a line the test world does not understand: ' .. line, 2)
			end
			files[#files + 1] = 'SaftUI-Tracker/' .. line:gsub('\\', '/')
		end
	end
	return files
end

local counting = false
local made = setmetatable({}, { __mode = 'k' }) -- frames made while counting

-- Counts frames, hooks, scripts, events and timers from now on. Frame methods
-- live in a table per frame type (getmetatable(frame).__index), so each is
-- wrapped once.
local function InstallCounters()
	local counts = TW.counts
	for _, key in ipairs({ 'frames', 'hooks', 'scripts', 'events', 'timers', 'secure' }) do counts[key] = 0 end
	local create, hook = CreateFrame, hooksecurefunc
	local wrapped = {}
	local function Wrap(methods, name, key, only_unmade)
		local original = methods[name]
		if not original then return end
		methods[name] = function(self, ...)
			if counting and not (only_unmade and made[self]) then counts[key] = counts[key] + 1 end
			return original(self, ...)
		end
	end
	for _, kind in ipairs({ 'Frame', 'Button', 'CheckButton', 'ScrollFrame', 'EditBox', 'StatusBar', 'Slider', 'Cooldown', 'GameTooltip' }) do
		local ok, frame = pcall(create, kind)
		local methods = ok and getmetatable(frame).__index
		if type(methods) == 'table' and not wrapped[methods] then
			wrapped[methods] = true
			Wrap(methods, 'RegisterEvent', 'events')
			Wrap(methods, 'RegisterUnitEvent', 'events')
			Wrap(methods, 'RegisterAllEvents', 'events')
			Wrap(methods, 'HookScript', 'hooks')
			Wrap(methods, 'SetScript', 'scripts', true)
		end
	end
	CreateFrame = function(frameType, name, parent, template, ...)
		local frame = create(frameType, name, parent, template, ...)
		if counting then
			made[frame] = true
			counts.frames = counts.frames + 1
			if tostring(template or ''):find('Secure') then counts.secure = counts.secure + 1 end
		end
		return frame
	end
	hooksecurefunc = function(...)
		if counting then counts.hooks = counts.hooks + 1 end
		return hook(...)
	end
	for _, name in ipairs({ 'After', 'NewTimer', 'NewTicker' }) do
		local original = C_Timer[name]
		if original then
			C_Timer[name] = function(...)
				if counting then counts.timers = counts.timers + 1 end
				return original(...)
			end
		end
	end
end

local SCRIPTS = { 'OnShow', 'OnHide', 'OnEvent', 'OnUpdate', 'OnSizeChanged', 'OnEnter', 'OnLeave', 'OnMouseDown', 'OnMouseUp', 'OnDragStart' }

function TW.snapshot(frame)
	local parts = {}
	for i = 1, frame:GetNumPoints() do
		local point, rel, relPoint, x, y = frame:GetPoint(i)
		parts[#parts + 1] = ('%s>%s:%s:%s,%s'):format(point, rel and rel.GetName and rel:GetName() or tostring(rel), relPoint, tostring(x), tostring(y))
	end
	local parent = frame:GetParent()
	parts[#parts + 1] = 'shown=' .. tostring(frame:IsShown())
	parts[#parts + 1] = 'parent=' .. tostring(parent and parent:GetName())
	parts[#parts + 1] = 'alpha=' .. tostring(frame:GetAlpha())
	for _, script in ipairs(SCRIPTS) do
		if frame:HasScript(script) then parts[#parts + 1] = script .. '=' .. tostring(frame:GetScript(script)) end
	end
	return table.concat(parts, ' ')
end

function TW.world(opts)
	opts = opts or {}
	counting = false
	local st = T.client(opts.client or 'forever')
	load_editmode()
	load_saftui('SaftUI-Core/Widgets/scrollframe.lua') -- st:ScrollBarRoom (the window reads the bar's room)
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	GameTooltip:Hide()
	st.config.char = {}
	InstallCounters()
	if opts.addons then
		for _, name in ipairs(opts.addons) do stub.loaded_addons[name] = true end
	end

	-- Every addon's files load first, Misc's before the tracker's (its
	-- OptionalDeps).
	TW.OT, TW.SK, TW.OTP = nil, nil, nil
	local misc = opts.misc and (type(opts.misc) == 'table' and opts.misc or {})
	if misc then
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
	end

	if opts.before then opts.before(st) end

	-- st.config is made at login, after every file has loaded.
	local config = st.config
	st.config = nil
	counting = true
	for _, file in ipairs(TW.toc_files()) do load_saftui(file) end
	counting = false
	st.config = config
	apply_defaults()
	st:GetModule('Tracker').NewScrollFrame = TW.scroll_frame
	if opts.on ~= nil then st.config.profile.tracker.enable = opts.on end
	if opts.combat then stub.in_combat = true end

	-- Then the modules enable, Misc's first.
	if misc then
		if misc.skinning or misc.skin then
			TW.SK = st:GetModule('Skinning')
			TW.SK:Enable()
		end
		if misc.otp then
			TW.OTP = st:GetModule('ObjectiveTracker')
			TW.OTP:Enable()
		end
	end
	local TR = st:GetModule('Tracker')
	if opts.enabling then opts.enabling(st, TR) end
	counting = true
	TR:Enable()
	counting = false
	return st, TR
end

function TW.scroll_frame(parent)
	local scrollFrame = CreateFrame('ScrollFrame', nil, parent)
	scrollFrame:SetSize(500, 500)
	local content = CreateFrame('Frame', nil, scrollFrame)
	scrollFrame:SetScrollChild(content)
	scrollFrame.ScrollChild = content
	scrollFrame.SetContentSize = function(self, width, height) content:SetSize(width, height) end
	local bar = CreateFrame('Frame', nil, scrollFrame)
	bar:SetWidth(8)
	bar:SetPoint('TOPLEFT', scrollFrame, 'TOPRIGHT', 6, -2)
	bar:SetPoint('BOTTOMLEFT', scrollFrame, 'BOTTOMRIGHT', 6, 5)
	scrollFrame.ScrollBar = bar

	-- The bar's own input, as Blizzard's ScrollUtil.InitScrollFrameWithScrollBar
	-- and ScrollBarBaseTemplate make it (identical on both clients): every one
	-- ends in scrollFrame:SetVerticalScroll(percentage * range), unrounded, which
	-- the game follows with the frame's OnVerticalScroll. A wheel notch over the
	-- bar is panExtent * 2 (ScrollController's wheelPanScalar), a stepper
	-- panExtent, a thumb drag or a track click any percentage. The stand-in's
	-- range is the child's height less the frame's, and a percentage is clamped
	-- to 0..1 as the bar clamps it.
	local methods = getmetatable(scrollFrame).__index
	scrollFrame.SetVerticalScroll = function(self, offset)
		methods.SetVerticalScroll(self, offset)
		stub.fire_script(self, 'OnVerticalScroll', offset)
	end
	local panExtent = 30
	scrollFrame.SetPanExtent = function(_, extent) panExtent = extent end
	local function Range() return math.max(0, content:GetHeight() - scrollFrame:GetHeight()) end
	-- A thumb drag, a track click: the bar's percentage.
	bar.SetScrollPercentage = function(_, percentage)
		scrollFrame:SetVerticalScroll(math.min(math.max(percentage, 0), 1) * Range())
	end
	local function Pan(self, pixels)
		local range = Range()
		if range > 0 then self:SetScrollPercentage(scrollFrame:GetVerticalScroll() / range + pixels / range) end
	end
	-- A stepper: direction 1 is down.
	bar.Step = function(self, direction) Pan(self, direction * panExtent) end
	bar:SetScript('OnMouseWheel', function(self, delta) Pan(self, -delta * panExtent * 2) end)
	-- MinimalScrollBar's thumb, which SaftUI's skin draws (st:SkinNewScrollBar).
	local thumb = SaftUI:CreateFrame('Frame', nil, bar)
	bar.GetThumb = function() return thumb end
	return scrollFrame
end

function TW.combat(on)
	stub.in_combat = on and true or false
	stub.fire_event(on and 'PLAYER_REGEN_DISABLED' or 'PLAYER_REGEN_ENABLED')
end

return TW
