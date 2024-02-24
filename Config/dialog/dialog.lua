local addonName = ...
local st = SaftUI
local Config = st:GetModule('Config')

local config = LibStub("AceConfig-3.0")
local dialog = LibStub("AceConfigDialog-3.0")

local dialogRoot = {
	type = "group",
	args = {
		version = {
			order = 1,
			type = "description",
			name = function() return ("version %s"):format(GetAddOnMetadata(addonName, "Version")) end,
		}
	},
}
function Config:InitializeConfigDialog()
    config:RegisterOptionsTable(addonName, dialogRoot)
    dialog:AddToBlizOptions(addonName, addonName)
end