const test = require('node:test')
const assert = require('node:assert/strict')
const G = require('../../tools/item-groups.cjs')

test('parseCSV handles quotes, short rows and CRLF', () => {
	const rows = G.parseCSV('ID,Name,Extra\r\n1,"Gnomish ""Fixer"", Mk 2",x\r\n2,Plain\r\n')
	assert.equal(rows.length, 2)
	assert.deepEqual(rows[0], { ID: '1', Name: 'Gnomish "Fixer", Mk 2', Extra: 'x' })
	assert.deepEqual(rows[1], { ID: '2', Name: 'Plain', Extra: '' })
})

function tables() {
	const item = (ID, ClassID, icon) => ({ ID: String(ID), ClassID: String(ClassID), IconFileDataID: String(icon) })
	return {
		Item: [
			item(1, 7, 10), item(2, 7, 11), item(3, 0, 12), item(4, 7, 10),
			item(5, 7, 10), item(6, 0, 10), item(7, 4, 10), item(8, 7, 11),
		],
		ItemSparse: [
			{ ID: '1', Display_lang: 'Raw Slitherskin Mackerel' },
			{ ID: '2', Display_lang: 'Oily Blackmouth' },
			{ ID: '3', Display_lang: 'Deviate Fish' },
			{ ID: '4', Display_lang: 'Wild Steelbloom' },
			{ ID: '5', Display_lang: '17 Pound Catfish' },
			{ ID: '6', Display_lang: 'Baked Salmon' },
			{ ID: '7', Display_lang: 'Raw Fish Helm' },
			{ ID: '8', Display_lang: 'Wild Steelbloom' },
		],
		ManifestInterfaceData: [
			{ ID: '10', FilePath: 'Interface\\Icons\\', FileName: 'INV_Misc_Fish_01.blp' },
			{ ID: '11', FilePath: 'Interface\\Icons\\', FileName: 'INV_Misc_MonsterHead_02.blp' },
			{ ID: '12', FilePath: 'Interface\\Icons\\', FileName: 'INV_Misc_Fish_02.blp' },
		],
		SpellReagents: [
			{ SpellID: '100', Reagent_0: '2', Reagent_1: '0' },
			{ SpellID: '101', Reagent_0: '3' },
			{ SpellID: '102', Reagent_0: '8' },
			{ SpellID: '103', Reagent_0: '6' },
		],
		SkillLineAbility: [
			{ SkillLine: '185', Spell: '100' },
			{ SkillLine: '186', Spell: '101' },
			{ SkillLine: '171', Spell: '102' },
			{ SkillLine: '999', Spell: '103' },
		],
		SkillLine: [
			{ ID: '185', DisplayName_lang: 'Cooking', ParentSkillLineID: '0' },
			{ ID: '186', DisplayName_lang: 'Classic Fishing', ParentSkillLineID: '356' },
			{ ID: '356', DisplayName_lang: 'Fishing', ParentSkillLineID: '0' },
			{ ID: '171', DisplayName_lang: 'Alchemy', ParentSkillLineID: '0' },
			{ ID: '999', DisplayName_lang: 'Blacksmithing', ParentSkillLineID: '0' },
		],
	}
}

test('selectFish picks fish and refuses lookalikes', () => {
	const got = G.selectFish(tables())
	assert.deepEqual(got.map(f => f.name), ['Raw Slitherskin Mackerel', 'Oily Blackmouth', 'Deviate Fish'])
	assert.deepEqual(got.map(f => f.id), [1, 2, 3])
})

test('parseOverrides reads + and - lines and rejects junk', () => {
	const o = G.parseOverrides('# why\n\n+13757 Lightning Eel\n-5468 Soft Frenzy Flesh\n')
	assert.equal(o.add.get(13757), 'Lightning Eel')
	assert.ok(o.remove.has(5468))
	assert.throws(() => G.parseOverrides('# c\n\nx123\n'), /line 3/)
})

test('applyOverrides: removal wins, adds named, sorted', () => {
	const cands = [{ id: 9, name: 'Nine' }, { id: 5468, name: 'Soft Frenzy Flesh' }]
	const o = G.parseOverrides('-5468 x\n+13757 Lightning Eel\n+7 Seven\n-7 Seven')
	const out = G.applyOverrides(cands, o)
	assert.deepEqual(out, [{ id: 9, name: 'Nine' }, { id: 13757, name: 'Lightning Eel' }])
})

test('renderLua output shape', () => {
	const lua = G.renderLua({ build: '1.60.1.71091', groups: { fish: [{ id: 13757, name: 'Lightning Eel' }] } })
	for (const s of ['wowf 1.60.1.71091', 'INV.ItemGroupsData = {', 'forever = {', 'fish = {', '[13757] = true, -- Lightning Eel'])
		assert.ok(lua.includes(s), s)
})
