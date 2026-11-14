-- What edit mode's test files share (the editmode_* tests): a test file loads
-- it with load_test_file and takes the helpers it uses from what it returns.
-- Each reads SaftUI.EditModeFrames when it is called, so it follows the world
-- a file builds, whenever it builds it.
--
-- settings()     the profile's edit mode settings
-- control(key)   the bar's control, by key
-- frame_of(key)  that control's frame
-- set_screen(width, height)   a screen of width x height physical pixels at
--                SaftUI's scale: a UIParent unit a pixel
-- look(name)     switches the theme ('thick', 'thin' or 'blizzard') and tells
--                SaftUI

local function EM() return SaftUI.EditModeFrames end

local function settings() return EM():GetSettings() end
local function control(key) return EM():BarControl(key) end
local function frame_of(key) return EM():BarControl(key).frame end

local function set_screen(width, height)
	stub.screen_width, stub.screen_height = width, height
	UIParent:SetScale(768 / height)
end

local function look(name)
	SaftUI.config.profile.theme.name = name
	SaftUI:ThemeChanged()
end

return {
	settings = settings,
	control = control,
	frame_of = frame_of,
	set_screen = set_screen,
	look = look,
}
