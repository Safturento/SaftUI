--[[
	The core shell: SaftUI's core as it is in game before any module code
	runs, without loading Ace3. It stands in for init.lua and the module
	plumbing Ace3 gives SaftUI (AceAddon modules, AceEvent, AceHook, AceDB's
	profile), mimicking those libraries' behavior, then loads Core's real
	constants.lua, api.lua, uiscale.lua and utilities.lua in their TOC order.

	It never fakes what a test checks. SaftUI's own helpers come from its real
	files: tests that need Core's frame helpers (st:CreateFrame, st:SetBackdrop,
	st:CreateButton, st:GetFont, st.Config.generators) call
	load_core_helpers().

	What it gives tests, besides the real files' contents:
	  SaftUI                  SaftUI-Core's namespace, as in game
	  st:NewModule(name), st:GetModule(name, silent), st:IterateModules(), st.modules
	  on every module (and SaftUI): NewModule, GetModule, IterateModules, SetDefaultModuleLibraries, Enable,
	    IsEnabled, RegisterEvent, UnregisterEvent, SecureHook, SecureHookScript, HookScript, IsHooked
	  st.config.profile       empty until apply_defaults()
	  st:BindModuleConfig     as SaftUI-Core/Config/config.lua has it
	  st.Config               the Config module, with Refresh and GetWindow (no /sui window)
	  remove_shell_config()   takes that Config module out, for a test that loads the real config.lua
	  apply_defaults()        fills st.config.profile from st.defaults, with AceDB's wildcard keys
	  load_core_helpers()     loads Core's frame helpers and what they need
	  load_options_widgets()  loads the /sui window's widget files (st.OptionsWidgets)
	                          in the game's order; options_widget_files() lists them
	  load_options_window()   loads the /sui window's own files (st.OptionsWindow)
	                          in the game's order; options_window_files() lists them
	  tick_options_window(elapsed) one frame passes on the /sui window's clock
	  load_editmode()         loads edit mode's files in the game's order; editmode_files() lists them
	  load_editmode_bar()     loads the edit mode bar's files (after the options window's world);
	                          editmode_bar_files() lists them
	  load_string_format()    loads LibStringFormat-1.0 as st.StringFormat, as init.lua takes it
	  use_client(name, before) a fresh world on 'forever' or 'retail'
	  st.config.global        an empty table, as AceDB gives
	  SCALE_SCREENS           the screens use_scale knows, by k: { width, height, mode }
	  TEST_SCALE              set in a scaled run: the shell then builds every world at use_scale(TEST_SCALE)
	  use_scale(k)            puts the world on k's screen at the scale the model gives it
	                          (0.75, 1, 1.25 or 1.55); nothing is reset; returns UIScale.Resolve's table
]]

local function pack(...)
	return { n = select('#', ...), ... }
end

-- In game init.lua makes the addon object from SaftUI-Core's namespace, so
-- SaftUI and the namespace Core's files get are the same table.
local st = addon_namespace('SaftUI-Core')
SaftUI = st

-- AceAddon's safecall: optional handlers (OnInitialize, OnEnable) run
-- through the error handler, so one failing doesn't stop the rest.
local function safecall(fn, ...)
	if type(fn) == 'function' then
		local args = pack(...)
		return xpcall(function() return fn(unpack(args, 1, args.n)) end, geterrorhandler())
	end
end

------------------------------------------------------------------ AceEvent

-- AceEvent registers its events on one frame and dispatches them to every
-- object registered for them, through CallbackHandler.
local eventFrame = CreateFrame('Frame')
-- event -> list of { owner, fn }. The shell calls them in registration order.
-- Real CallbackHandler iterates its registry with pairs, so the game
-- guarantees no order between objects: tests must not rely on handler order.
local handlers = {}

eventFrame:SetScript('OnEvent', function(_, event, ...)
	local args = pack(...)
	local list = {}
	for i, handler in ipairs(handlers[event] or {}) do list[i] = handler end
	for _, handler in ipairs(list) do
		if handler.active then
			safecall(handler.fn, event, unpack(args, 1, args.n))
		end
	end
end)

local function unregister(owner, event)
	for i, handler in ipairs(handlers[event] or {}) do
		if handler.owner == owner then
			handler.active = false
			table.remove(handlers[event], i)
			break
		end
	end
	if handlers[event] and #handlers[event] == 0 then
		handlers[event] = nil
		eventFrame:UnregisterEvent(event)
	end
end

------------------------------------------------------------------ objects

-- The methods SaftUI's addon object and each module get. In game they're
-- AceAddon's plus the AceEvent and AceHook mixins init.lua sets as every
-- module's default libraries. Like AceAddon's embeds, they're copied onto
-- each object.
local Object = {}

local function new_object(object, name)
	for key, fn in pairs(Object) do object[key] = fn end
	object.name = name
	object.modules, object.orderedModules = {}, {}
	object.hooks = {} -- AceHook keeps a hooked script's original handler here
	object.enabledState = true -- AceAddon's default module state
	return object
end

-- AceAddon names a module after its parent: SaftUI_EditMode.
function Object:NewModule(name, ...)
	if type(name) ~= 'string' then
		error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]): 'name' - string expected got '%s'."):format(type(name)), 2)
	end
	if select('#', ...) > 0 then
		error("the core shell's NewModule takes only a name (SaftUI's modules get AceEvent and AceHook by default)", 2)
	end
	if self.modules[name] then
		error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]): 'name' - Module '%s' already exists."):format(name), 2)
	end
	local module = new_object({}, ('%s_%s'):format(self.name or tostring(self), name))
	module.moduleName = name
	self.modules[name] = module
	table.insert(self.orderedModules, module)
	return module
end

-- AceAddon's: the libraries every module made after this call gets. The shell
-- gives every module AceEvent and AceHook (SaftUI's default), so those are the
-- only ones it takes. Like AceAddon, it can't change once a module exists.
function Object:SetDefaultModuleLibraries(...)
	if next(self.modules) then
		error('Usage: SetDefaultModuleLibraries(...): cannot change the module defaults after a module has been registered.', 2)
	end
	for i = 1, select('#', ...) do
		local library = select(i, ...)
		if library ~= 'AceEvent-3.0' and library ~= 'AceHook-3.0' then
			error(("the core shell's modules only have AceEvent-3.0 and AceHook-3.0, got '%s'"):format(tostring(library)), 2)
		end
	end
end

function Object:GetModule(name, silent)
	if not self.modules[name] and not silent then
		error(("Usage: GetModule(name, silent): 'name' - Cannot find module '%s'."):format(tostring(name)), 2)
	end
	return self.modules[name]
end

function Object:IterateModules()
	return pairs(self.modules)
end

-- AceAddon's: the module's enabled state, true by default, even before
-- Enable has run.
function Object:IsEnabled()
	return self.enabledState
end

local initialized, enabled = {}, {}

-- In game AceAddon runs every OnInitialize (the addon's, then its modules',
-- at ADDON_LOADED) before any OnEnable (at login). The shell's Enable does
-- both, each once: it initializes the object and its whole module subtree
-- first, then enables the object and then its modules in the order they were
-- made, as AceAddon:EnableAddon does.
local function initialize(object)
	if initialized[object] then return end
	initialized[object] = true
	safecall(object.OnInitialize, object)
	for _, module in ipairs(object.orderedModules) do
		initialize(module)
	end
end

local function enable(object)
	if enabled[object] or not object.enabledState then return false end
	enabled[object] = true
	safecall(object.OnEnable, object)
	for _, module in ipairs(object.orderedModules) do
		enable(module)
	end
	return true
end

function Object:Enable()
	self.enabledState = true
	initialize(self)
	return enable(self)
end

-- AceEvent (through CallbackHandler): method is a method name (default: the
-- event's name), which must exist on self now, or a function. A method name
-- is called as self[method](self, event, ...), a function as fn(event, ...).
-- With an extra arg, it comes before event. Registering again replaces it.
function Object:RegisterEvent(event, method, ...)
	if type(event) ~= 'string' then
		error("Usage: RegisterEvent(eventname, method[, arg]): 'eventname' - string expected.", 2)
	end
	method = method or event
	local hasArg, arg = select('#', ...) >= 1, ...
	local fn
	if type(method) == 'string' then
		if type(self[method]) ~= 'function' then
			error(("Usage: RegisterEvent(\"eventname\", \"methodname\"): 'methodname' - method '%s' not found on self."):format(method), 2)
		end
		fn = hasArg and function(...) self[method](self, arg, ...) end or function(...) self[method](self, ...) end
	elseif type(method) == 'function' then
		fn = hasArg and function(...) method(arg, ...) end or method
	else
		error("Usage: RegisterEvent(eventname, method[, arg]): 'methodname' - string or function expected.", 2)
	end
	unregister(self, event)
	handlers[event] = handlers[event] or {}
	table.insert(handlers[event], { owner = self, fn = fn, active = true })
	eventFrame:RegisterEvent(event)
end

function Object:UnregisterEvent(event)
	unregister(self, event)
end

-- AceHook's checks: a handler named by string must exist on self, and the
-- same target can't be hooked twice.
local hooked = {} -- object -> target -> name -> true

local function claim_hook(object, target, name)
	hooked[object] = hooked[object] or {}
	hooked[object][target] = hooked[object][target] or {}
	if hooked[object][target][name] then
		error(('Attempting to rehook already active hook %s.'):format(name), 3)
	end
	hooked[object][target][name] = true
end

local function call_handler(object, handler, ...)
	if type(handler) == 'string' then
		return object[handler](object, ...)
	end
	return handler(...)
end

local function check_handler(object, handler, usage)
	if type(handler) ~= 'string' and type(handler) ~= 'function' then
		error(("%s: 'handler' - nil, string, or function expected got %s"):format(usage, type(handler)), 3)
	end
	if type(handler) == 'string' and type(object[handler]) ~= 'function' then
		error(("%s: 'handler' - Handler specified does not exist at self[handler]"):format(usage), 3)
	end
end

-- AceHook:SecureHook([object], method, [handler]): a post-hook through
-- hooksecurefunc. The handler gets the hooked call's arguments.
function Object:SecureHook(object, method, handler)
	if type(object) == 'string' then
		object, method, handler = nil, object, method
	end
	local usage = 'Usage: SecureHook([object], method, [handler])'
	handler = handler or method
	check_handler(self, handler, usage)
	local target = object or _G
	if type(target[method]) ~= 'function' then
		error(usage .. ': Attempting to hook a non existing target', 2)
	end
	claim_hook(self, target, method)
	hooksecurefunc(target, method, function(...) call_handler(self, handler, ...) end)
end

-- AceHook:HookScript(frame, script, [handler]): a pre-hook that replaces the
-- script with one calling the handler, then the original.
function Object:HookScript(frame, script, handler)
	local usage = 'Usage: HookScript(object, method, [handler])'
	handler = handler or script
	check_handler(self, handler, usage)
	if type(frame) ~= 'table' or not frame.GetScript or not frame:HasScript(script) then
		error(usage .. ': You can only hook a script on a frame object', 2)
	end
	claim_hook(self, frame, script)
	local original = frame:GetScript(script) or function() end
	self.hooks[frame] = self.hooks[frame] or {}
	self.hooks[frame][script] = original
	frame:SetScript(script, function(...)
		call_handler(self, handler, ...)
		return original(...)
	end)
end

-- AceHook:SecureHookScript(frame, script, [handler]): a post-hook on a frame's
-- script, through the frame's own HookScript (the original handler stays).
function Object:SecureHookScript(frame, script, handler)
	local usage = 'Usage: SecureHookScript(object, method, [handler])'
	handler = handler or script
	check_handler(self, handler, usage)
	if type(frame) ~= 'table' or not frame.GetScript or not frame:HasScript(script) then
		error(usage .. ': You can only hook a script on a frame object', 2)
	end
	claim_hook(self, frame, script)
	frame:HookScript(script, function(...) call_handler(self, handler, ...) end)
end

-- AceHook:IsHooked([object], method): whether self has an active hook on it
-- (SecureHook or HookScript; there's no Unhook here, so it never goes false).
function Object:IsHooked(object, method)
	if type(object) == 'string' then
		object, method = nil, object
	end
	local byTarget = hooked[self]
	local names = byTarget and byTarget[object or _G]
	return names and names[method] or false
end

------------------------------------------------------------------ SaftUI

-- AceAddon names the addon after its folder; constants.lua renames it.
new_object(st, 'SaftUI-Core')

-- AceDB's profile. In game AceDB builds it from st.defaults; here it starts
-- empty and apply_defaults() fills it.
st.config = { profile = {} }

-- As SaftUI-Core/Config/config.lua has it: points module.config at the
-- profile's key and remembers the key for a profile change.
function st:BindModuleConfig(module, key)
	module.configKey = key
	module.config = st.config.profile[key]
	return module.config
end

-- Fills st.config.profile from st.defaults the way AceDB-3.0's copyDefaults
-- does (SaftUI-Core/Libraries/Ace3/AceDB-3.0/AceDB-3.0.lua): every key the
-- profile lacks gets the default (tables are deep-copied), and values the
-- profile has are kept. The wildcard keys are AceDB's too:
--   ['*'] and ['**'] are never keys of the profile. Their value is the
--   default of every key the table doesn't have: a table is copied into each
--   new subtable, a plain value is what any other key reads as. It works for
--   keys made later, through a metatable on the table, and it is filled into
--   the tables the profile already has there.
--   ['**'] beside other tables' keys also fills those keys' tables.
-- Load the defaults files (e.g. SaftUI-Core/Config/defaults.lua) first.
local function copy_defaults(dest, src)
	for key, value in pairs(src) do
		if key == '*' or key == '**' then
			if type(value) == 'table' then
				setmetatable(dest, {
					__index = function(t, key2)
						if key2 == nil then return nil end
						local subtable = {}
						copy_defaults(subtable, value)
						rawset(t, key2, subtable)
						return subtable
					end,
				})
				for existing_key, existing in pairs(dest) do
					if not rawget(src, existing_key) and type(existing) == 'table' then
						copy_defaults(existing, value)
					end
				end
			else
				setmetatable(dest, { __index = function(t, key2) return key2 ~= nil and value or nil end })
			end
		elseif type(value) == 'table' then
			if not rawget(dest, key) then rawset(dest, key, {}) end
			if type(dest[key]) == 'table' then
				copy_defaults(dest[key], value)
				if src['**'] then
					copy_defaults(dest[key], src['**'])
				end
			end
		elseif rawget(dest, key) == nil then
			rawset(dest, key, value)
		end
	end
	return dest
end

function apply_defaults()
	if type(st.defaults) ~= 'table' then
		error('apply_defaults: there is no st.defaults yet; load SaftUI-Core/Config/defaults.lua first', 2)
	end
	copy_defaults(st.config.profile, st.defaults)
end

-- Core's frame helpers and what they need, in TOC order: LibSharedMedia and
-- its libraries, Widgets/button.lua (st:CreateButton), skinning.lua
-- (st:SkinIcon and st:IconTexCoords, which the General tab's Icon zoom
-- preview cuts its icon with), panels.lua (st:CreateFrame,
-- st:CreateFontString), theme.lua (st:SetTemplate, st:SetBackdrop and the
-- theme they draw), themeart_data.lua (the Blizzard theme's tables, which make
-- st.ThemeArt) and themeart.lua (its accessors and drawing),
-- the media and fonts (st:GetFont) with the Colors
-- and Theme modules, the profile defaults, Config/generators.lua (st.Config.generators) and
-- the General module (Global settings' General tab). Then the profile is
-- filled from the defaults and the Fonts module enabled, as at login, so
-- st:GetFont has font objects.
function load_core_helpers()
	load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
	load_saftui('SaftUI-Core/Libraries/CallbackHandler-1.0/CallbackHandler-1.0.lua')
	load_saftui('SaftUI-Core/Libraries/LibSharedMedia-3.0/LibSharedMedia-3.0.lua')
	load_saftui('SaftUI-Core/Widgets/button.lua')
	load_saftui('SaftUI-Core/skinning.lua')
	load_saftui('SaftUI-Core/panels.lua')
	load_saftui('SaftUI-Core/theme.lua')
	load_saftui('SaftUI-Core/themeart_data.lua')
	load_saftui('SaftUI-Core/themeart.lua')
	load_saftui('SaftUI-Core/Media/sharedmedia.lua')
	load_saftui('SaftUI-Core/Media/fonts.lua')
	load_saftui('SaftUI-Core/Media/colors.lua')
	load_saftui('SaftUI-Core/Media/theme.lua')
	load_saftui('SaftUI-Core/Config/defaults.lua')
	load_saftui('SaftUI-Core/Config/generators.lua')
	-- The model and its saved fields (st.Config.SavedIn), which every page's table calls (the game's TOC loads them before the modules; load_saftui brings the kit with the model).
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/general.lua')
	apply_defaults()
	st:GetModule('Fonts'):Enable()
end

-- The /sui window's widget files (st.OptionsWidgets), by path from the repo
-- root, in the order the game loads them: right after Config/optionsmodel.lua
-- and before Config/optionsbody.lua.
function options_widget_files()
	return {
		'SaftUI-Core/Config/optionswidgets.lua',
		'SaftUI-Core/Config/optionslook.lua',
		'SaftUI-Core/Config/optionsdialog.lua',
		'SaftUI-Core/Config/optionsbar.lua',
		'SaftUI-Core/Config/optionslist.lua',
		'SaftUI-Core/Config/optionstypes.lua',
		'SaftUI-Core/Config/optionsrange.lua',
		'SaftUI-Core/Config/optionsselect.lua',
		'SaftUI-Core/Config/optionskeybinding.lua',
		'SaftUI-Core/Config/optionsitem.lua',
		'SaftUI-Core/Config/optionscontrols.lua',
		'SaftUI-Core/Config/optionscolorpicker.lua',
		'SaftUI-Core/Config/optionsfont.lua',
		'SaftUI-Core/Config/optionsposition.lua',
	}
end

-- Loads the widget files in that order. Load Config/optionsmodel.lua first.
function load_options_widgets()
	for _, path in ipairs(options_widget_files()) do
		load_saftui(path)
	end
end

-- The /sui window's own files (st.OptionsWindow), by path from the repo root,
-- in the order the game loads them: right after Config/optionsbody.lua and
-- before Config/generators.lua.
function options_window_files()
	return {
		'SaftUI-Core/Config/optionsshare.lua',
		'SaftUI-Core/Config/optionslayout.lua',
		'SaftUI-Core/Config/optionswindow.lua',
		'SaftUI-Core/Config/optionsresize.lua',
		'SaftUI-Core/Config/optionssizes.lua',
		'SaftUI-Core/Config/optionsnav.lua',
		'SaftUI-Core/Config/optionssmalldialog.lua',
		'SaftUI-Core/Config/optionsmenu.lua',
	}
end

-- Loads the window's files in that order. Load Config/optionsmodel.lua, the
-- widget files (load_options_widgets) and Config/optionsbody.lua first.
function load_options_window()
	for _, path in ipairs(options_window_files()) do
		load_saftui(path)
	end
end

-- One frame passes on the /sui window's clock: its ticker's OnUpdate runs with
-- elapsed seconds (0.01 by default), as the game runs it every frame. Nothing
-- runs before the window is built, when it has no ticker yet. It reads the
-- window from SaftUI when called, so it follows a reset_world().
function tick_options_window(elapsed)
	local ticker = SaftUI.OptionsWindow.GetFrames().ticker
	if ticker then stub.fire_script(ticker, 'OnUpdate', elapsed or 0.01) end
end

-- Edit mode's files (st.EditModeFrames, st:RegisterMover and the rest), by
-- path from the repo root, in the order SaftUI-Core/EditMode/load.xml loads
-- them.
function editmode_files()
	return {
		'SaftUI-Core/EditMode/editmode.lua',
		'SaftUI-Core/EditMode/mover.lua',
		'SaftUI-Core/EditMode/picker.lua',
		'SaftUI-Core/EditMode/grid.lua',
		'SaftUI-Core/EditMode/snap.lua',
		'SaftUI-Core/EditMode/settings.lua',
		'SaftUI-Core/EditMode/coordinates.lua',
		'SaftUI-Core/EditMode/filter.lua',
		'SaftUI-Core/EditMode/history.lua',
		'SaftUI-Core/EditMode/moves.lua',
	}
end

-- Loads edit mode's files in that order. Load Core's helpers
-- (load_core_helpers) first.
function load_editmode()
	for _, path in ipairs(editmode_files()) do
		load_saftui(path)
	end
end

-- The edit mode bar's files (EditMode/Bar/load.xml, which EditMode/load.xml
-- includes last), by path from the repo root, in the order it loads them.
function editmode_bar_files()
	return {
		'SaftUI-Core/EditMode/Bar/bar.lua',
		'SaftUI-Core/EditMode/Bar/bargroups.lua',
		'SaftUI-Core/EditMode/Bar/barshow.lua',
		'SaftUI-Core/EditMode/Bar/barchanges.lua',
		'SaftUI-Core/EditMode/Bar/historylist.lua',
		'SaftUI-Core/EditMode/Bar/barwindow.lua',
		'SaftUI-Core/EditMode/Bar/bardock.lua',
	}
end

-- Loads the bar's files in that order. Load the options window's world
-- (tests/core/options_window_helpers.lua: the kit's controls and the window's
-- footer) first; edit mode's own files (load_editmode) come with it.
function load_editmode_bar()
	for _, path in ipairs(editmode_bar_files()) do
		load_saftui(path)
	end
end

-- LibStringFormat-1.0, as st.StringFormat: SaftUI-Core/init.lua takes it from
-- LibStub. Load Core's helpers (load_core_helpers, which loads LibStub) first.
function load_string_format()
	load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')
	st.StringFormat = LibStub('LibStringFormat-1.0')
end

-- Core's TOC loads these three in this order (with Widgets, skinning.lua,
-- panels.lua and theme.lua between api.lua and utilities.lua).
load_saftui('SaftUI-Core/constants.lua')
load_saftui('SaftUI-Core/api.lua')
load_saftui('SaftUI-Core/uiscale.lua')
load_saftui('SaftUI-Core/utilities.lua')

-- Config/config.lua's module, made after constants.lua as in game, so it's
-- SaftUI_Config. Its real Refresh redraws an open /sui window and GetWindow
-- returns it; the shell has no /sui window.
st.Config = st:NewModule('Config')
function st.Config:Refresh() end
function st.Config:GetWindow() return nil end

-- For a test that loads Core's real Config/config.lua instead: it makes the
-- Config module itself, and NewModule errors on a name that exists (as
-- AceAddon's does), so this takes the shell's out of st.modules, the enable
-- order and st.Config. Load config.lua before Config/generators.lua
-- (load_core_helpers), as Core's TOC does: generators.lua adds to st.Config.
-- tests/core/config_helpers.lua does all of it.
function remove_shell_config()
	local config = st.modules.Config
	st.modules.Config = nil
	for i, module in ipairs(st.orderedModules) do
		if module == config then
			table.remove(st.orderedModules, i)
			break
		end
	end
	st.Config = nil
end

-- The interface each client a world can be on reports (GetBuildInfo).
local CLIENT_INTERFACES = { forever = 16001, retail = 120000 }

-- A fresh world on one client, 'forever' or 'retail': reset_world(), then
-- stub.interface set to the client's, the globals that client lacks dropped
-- (stub.apply_client, tests/wow/game.lua) and Core's constants.lua run again
-- (it reads the interface and the player's name and realm when it loads, so
-- st.forever follows), then, in a scaled run, use_scale(TEST_SCALE) once more,
-- so the world is at the scale after everything that rebuilt it. before, if
-- given, runs on the fresh stubs first, to change what constants.lua reads (a
-- screen it sets is put back to the scale's in a scaled run). Returns SaftUI.
-- Everything else is as reset_world() leaves it, so a file can switch clients between cases;
-- the caller loads the rest of its world after it (load_core_helpers(), or
-- core/config_helpers.lua for the real AceDB).
function use_client(name, before)
	local interface = CLIENT_INTERFACES[name]
	if not interface then
		error(("use_client: no client '%s' (forever or retail)"):format(tostring(name)), 2)
	end
	reset_world()
	if before then before() end
	stub.interface = interface
	stub.apply_client()
	load_saftui('SaftUI-Core/constants.lua')
	if TEST_SCALE then use_scale(TEST_SCALE) end
	return SaftUI
end

-- AceDB's global table, which the profile-less settings (st.config.global)
-- live in.
st.config.global = {}

-- What the shell sets UIParent to: SaftUI's pixel for pixel scale, one UIParent
-- unit per physical pixel, worked out by the scale model and read back into
-- the tokens. The shell never calls UIScale:Start, whose events (from Task 4) would set back
-- the scales a test sets.
UIParent:SetScale(st.UIScale.Resolve({ mode = 'pixel' }, st.UIScale.ReadScreen()).uiScale)
st.UIScale:SetTokens()

-- The screens a test can draw on, by the k each makes: { width, height, mode }.
-- 0.75 and 1 are the stub's 1920 x 1080, in Automatic and Pixel for pixel.
SCALE_SCREENS = {
	[0.75] = { 1920, 1080, 'auto' },
	[1] = { 1920, 1080, 'pixel' },
	[1.25] = { 3200, 1800, 'auto' },
	[1.55] = { 3456, 2234, 'auto' },
}

-- Puts the world on the screen for k (a key of SCALE_SCREENS): the screen,
-- UIParent's scale as the model gives it and the tokens read back from it.
-- Nothing is reset. Returns what the model resolved. Any other k is an error.
function use_scale(k)
	local row = SCALE_SCREENS[k]
	if not row then
		error(("use_scale: no screen for k %s (0.75, 1, 1.25 or 1.55)"):format(tostring(k)), 2)
	end
	local width, height, mode = row[1], row[2], row[3]
	stub.screen_width, stub.screen_height = width, height
	local resolved = st.UIScale.Resolve({ mode = mode, size = 1 }, { width = width, height = height })
	UIParent:SetScale(resolved.uiScale)
	st.UIScale:SetTokens()
	return resolved
end

-- In a scaled run (TEST_SCALE, which runner.py sets) every world is built at
-- that scale: this file runs again on every reset_world and use_client.
if TEST_SCALE then
	use_scale(TEST_SCALE)
end
