local st = SaftUI
local UF = st:GetModule('Unitframes')

-- groups.lua's, which loads before this file.
local GROUP_HEADERS = UF.GROUP_HEADERS

--[[
	While either raid group is enabled, Blizzard's raid frames are hidden. oUF
	only hides Blizzard's party frames (DisableBlizzard('party'), when the party
	header spawns). That covers raid-style party frames too: CompactPartyFrame
	is parented to PartyFrame.

	Blizzard_CompactRaidFrames, the same on both clients:
	  - CompactRaidFrameContainer holds every raid frame: the group frames
	    (CompactRaidGroup1-8 and their member buttons) and the flowed member,
	    pet and main tank/assist buttons (CompactRaidFrame1, 2, ...). It's
	    Blizzard Edit Mode's Raid Frames system, so its Hide, SetShown, SetPoint
	    and ClearAllPoints are Lua overrides.
	  - Only CompactRaidFrameManager_UpdateContainerVisibility shows or hides
	    it: shown in a raid (or while Blizzard Edit Mode forces raid frames on),
	    unless the raid manager's hide toggle turned them off (the
	    raidOptionIsShown CVar). It runs on roster changes, zoning, that toggle
	    and Edit Mode changes.
	  - CompactRaidFrameManager, the tab at the screen's left edge with the raid
	    tools (markers, ready check, role poll, everyone is assist, ...), is a
	    separate frame. It's left alone.

	The container gets the 'alwaysBlocked' roleset, the way oUF's handleFrame
	hides the frames it replaces: the client doesn't draw it or anything in it,
	whatever Blizzard's Show and Hide calls do. In Blizzard's Edit Mode its
	Raid Frames can't be selected then. SetRolesets is a C method, so no
	Blizzard Lua runs and nothing is written onto the frame. It's protected:
	in combat this waits for the end of combat.

	Unlike handleFrame, this leaves the container's events registered. Its
	updates also refresh CompactPartyFrame and CompactArenaFrame, and they keep
	the hidden raid frames current. So turning the raid groups off brings
	Blizzard's frames back as they should be, with the rolesets the container
	had before.

	The roleset is only set or cleared while that doesn't change whether the
	container is on screen. Otherwise the OnHide/OnShow of the container, of
	every raid button (CompactUnitFrame_OnShow/OnHide) and, on Forever, of
	gamepad raid targeting would run in SaftUI's call chain (.agents/taint.md
	rule 4). With Blizzard's frames on screen (in a raid) it waits: a
	post-hook on CompactRaidFrameManager_UpdateContainerVisibility tries again
	each time Blizzard shows or hides the container, e.g. on leaving the raid.

	The raidOptionIsShown CVar isn't used. Setting it from SaftUI would run
	Blizzard's whole compact frame settings pass in SaftUI's call chain
	(CompactUnitFrameProfiles:ApplyCurrentSettings, on CVAR_UPDATE), which
	rewrites the options of every Blizzard compact frame and lays the container
	out again. It's also the user's own saved setting.
]]

-- The container's rolesets from before SaftUI blocked it (nil for none), whether
-- it's blocked, and whether the chat note for a change that has to wait was printed.
local blizzardRaidRolesets
local blizzardRaidBlocked = false
local blizzardRaidNoticed = false

-- True if either raid group is enabled.
local function ShouldHideBlizzardRaid()
	local config = UF:GetProfileConfig()
	for group in pairs(GROUP_HEADERS) do
		if group ~= 'party' and config[group].enable then
			return true
		end
	end
	return false
end

-- True only for a plain false. A secret IsShown/IsVisible counts as true, so
-- nothing is changed on a guess.
local function IsKnownFalse(value)
	return not issecretvalue(value) and not value
end

-- Blocks or unblocks Blizzard's raid frames as the profile says, if that
-- doesn't change whether they're on screen (see above). In combat it waits for
-- the end of combat and reads the profile again then.
function UF:UpdateBlizzardRaidFrames()
	local container = _G.CompactRaidFrameContainer
	if not (container and container.SetRolesets) then return end

	local hide = ShouldHideBlizzardRaid()
	if hide == blizzardRaidBlocked then
		blizzardRaidNoticed = false
		return
	end
	if st:QueueAfterCombat('uf_blizzard_raid', function() self:UpdateBlizzardRaidFrames() end) then return end

	-- Out of a raid the container is only shown until Blizzard first sorts out
	-- its frames after login (that comes right after OnEnable), or while
	-- Blizzard's Edit Mode shows raid frames. No note for a wait then.
	if hide then
		if not IsKnownFalse(container:IsVisible()) then
			if not blizzardRaidNoticed and IsInRaid() then
				blizzardRaidNoticed = true
				st:Print("Blizzard's raid frames will hide after you leave the raid.")
			end
			return
		end
		local rolesets = container:GetRolesetNames()
		if #rolesets == 1 and rolesets[1] == 'roleless' then
			blizzardRaidRolesets = nil
		else
			blizzardRaidRolesets = table.concat(rolesets, ',')
		end
		container:SetRolesets('alwaysBlocked')
	else
		-- A blocked container is never on screen, but one Blizzard has shown
		-- comes on screen as soon as it's unblocked.
		if not IsKnownFalse(container:IsShown()) then
			if not blizzardRaidNoticed and IsInRaid() then
				blizzardRaidNoticed = true
				st:Print("Blizzard's raid frames will show again after you leave the raid, or after a /reload.")
			end
			return
		end
		container:SetRolesets(blizzardRaidRolesets)
	end
	blizzardRaidBlocked = hide
	blizzardRaidNoticed = false
end

-- Applies the profile to Blizzard's raid frames now, and again after each time
-- Blizzard shows or hides them (a change that had to wait may be possible
-- then). Once, from OnEnable.
function UF:SetupBlizzardRaidFrames()
	if _G.CompactRaidFrameManager_UpdateContainerVisibility then
		-- Runs inside Blizzard's own updates, so an error here mustn't stop them.
		hooksecurefunc('CompactRaidFrameManager_UpdateContainerVisibility', function()
			xpcall(function() UF:UpdateBlizzardRaidFrames() end, geterrorhandler())
		end)
	end
	self:UpdateBlizzardRaidFrames()
end
