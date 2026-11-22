-- SaftUI-Misc/TalentPlan/parser.lua: a pasted talent order into plan steps. No WoW API.
load_saftui('SaftUI-Misc/TalentPlan/talentplan.lua')
load_saftui('SaftUI-Misc/TalentPlan/model.lua')
load_saftui('SaftUI-Misc/TalentPlan/parser.lua')
local TP = SaftUI:GetModule('TalentPlan')
local M = TP.Model
local SH = load_test_file('misc/fixtures/talentplan_shaman.lua')
local GUIDE = read_test_source('misc/fixtures/talentplan_guide_enhancement.txt')

test("the owner's guide: 51 steps, levels 10 to 60, nothing reported", function()
	local r = TP.Parse(GUIDE, SH.NAMES)
	eq(#r.steps, 51); eq(#r.warnings, 0); eq(#r.unmatched, 0, 'the "Talent Order" header is skipped silently')
	eq(r.steps[1], SH.ID['Thundering Strikes']); eq(r.steps[11], SH.ID['Shamanistic Focus'])
	eq(r.steps[16], SH.ID['Stormstrike']); eq(r.steps[21], SH.ID['Improved Stormstrike'])
	eq(r.steps[15], SH.ID['Ancestral Knowledge'], 'rank 3 after a gap'); eq(M.Ranks(r.steps)[15], 3)
	eq(TP.ImportSummary(r, 3)[1], '51 steps, levels 10 to 60.')
end)

test('one line per step reads the same', function()
	local r = TP.Parse('10 Thundering Strikes Rank 1\n11 Thundering Strikes Rank 2\n12 Flurry 1/5', SH.NAMES)
	eq(#r.steps, 3); eq(#r.warnings, 0); eq(r.steps[3], SH.ID['Flurry'])
end)

test('longest name first, unmatched lines and warnings', function()
	local r = TP.Parse('10 Improved Stormstrike\n11 Stormstrike\n12 Totem Twisting\n14 Flurry Rank 3\n15 Spirit Weapons\n16 Spirit Weapons', SH.NAMES)
	eq(r.steps[1], SH.ID['Improved Stormstrike']); eq(r.steps[2], SH.ID['Stormstrike'])
	eq(#r.unmatched, 1); eq(r.unmatched[1].line, 3); eq(r.unmatched[1].text, '12 Totem Twisting')
	eq(r.warnings[1].text, 'Line 4: level 14 comes after level 12.')
	eq(r.warnings[2].text, 'Line 4: Flurry says rank 3, but it is rank 1 in the plan.')
	eq(r.warnings[3].text, 'Line 6: Spirit Weapons has only 1 ranks, so this one is left out.')
	eq(#r.steps, 4)
end)

test('parser reads web-shaped text', function() -- Review Focus 2
	local text = 'Leveling order\r\n\t10.\194\160Thundering Strikes (Rank 1)\r\n• Level 11: thundering strikes r2\r\n12 - Natures Guardian\r\n'
	local r = TP.Parse(text, SH.NAMES)
	eq(#r.steps, 3); eq(#r.warnings, 0); eq(#r.unmatched, 0)
	eq(r.steps[3], SH.ID["Nature's Guardian"])
end)

test('a guide from another class reports, never guesses', function()
	local r = TP.Parse('10 Improved Fireball\n11 Ignite', SH.NAMES)
	eq(#r.steps, 0); eq(#r.unmatched, 0, 'no match at all: all preamble')
	eq(TP.ImportSummary(r, 3)[1], 'No talents found.')
end)

test('the summary cuts long lists', function()
	local r = { steps = { 1 }, warnings = {}, unmatched = {} }
	for i = 1, 5 do r.unmatched[i] = { line = i, text = 'x' .. i } end
	local s = TP.ImportSummary(r, 3)
	eq(s[2], 'Not matched, line 1: x1'); eq(s[5], 'and 2 more'); eq(#s, 5)
end)
