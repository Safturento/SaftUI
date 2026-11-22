-- SaftUI-Misc/TalentPlan/store.lua: the saved plans, per class in the account
-- and the chosen plan per spec tab in the character.
stub.class = 'SHAMAN'
SaftUI.config.global = {}
SaftUI.config.char = {}
load_saftui('SaftUI-Misc/TalentPlan/talentplan.lua')
load_saftui('SaftUI-Misc/TalentPlan/model.lua')
load_saftui('SaftUI-Misc/TalentPlan/store.lua')
local S = SaftUI:GetModule('TalentPlan').Store

test('store renames, duplicates and deletes', function()
	local a = S.New('Enhancement', 1); eq(a.id, 1); eq(S.Active(1), a)
	local b = S.New('Enhancement', 2); eq(b.name, 'Enhancement 2'); eq(S.Active(2), b)
	eq(select(2, S.Rename(b, '  ')), 'empty'); eq(select(2, S.Rename(b, 'Enhancement')), 'taken')
	check(S.Rename(a, 'Enhancement'), 'same name is fine'); check(S.Rename(a, 'Enh leveling'))
	eq(S.Active(1).name, 'Enh leveling', 'the tab follows by id')
	local c = S.Duplicate(a, 2); eq(c.name, 'Enh leveling copy'); eq(S.Active(2), c)
	check(c.steps ~= a.steps, 'a deep copy')
	S.SetActive(1, c.id); S.Delete(c)
	eq(S.Active(1), nil); eq(S.Active(2), nil, 'both tabs that used it are empty')
	eq(#S.List(), 2); eq(S.List()[1].name, 'Enh leveling')
	eq(SaftUI.config.global.talentplan.plans.SHAMAN[a.id], a, 'saved by class and id')
end)

test('a choice pointing at a plan that is gone reads as none', function()
	S.Char().active[1] = 42
	eq(S.Active(1), nil)
end)
