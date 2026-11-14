-- Quest log entries for SaftUI-Tracker's tests (the stubs' shapes are in
-- tests/wow/quests.lua). Not a test (no _test suffix); a test loads it with
-- `local Q = load_test_file('tracker/quest_log.lua')`.
--
--   Q.header(title, campaignID)   a header entry
--   Q.quest(id, fields)           a quest entry: title 'Quest <id>' and level
--                                 10 unless fields say, the rest as fields
--   Q.set(log, watched, extra)    puts the log and the watch list in
--                                 stub.quests (extra: more of its fields)
--   Q.settings(st, changes)       the profile's quests settings with changes
--                                 applied, as the model's text functions take
--   Q.find(model, id)             the model's quest with this ID
--   Q.ids(model)                  the model's quest IDs, joined by commas
local Q = {}

function Q.header(title, campaignID)
	return { header = true, title = title, campaignID = campaignID }
end

function Q.quest(id, fields)
	local entry = { id = id, title = 'Quest ' .. id, level = 10 }
	for key, value in pairs(fields or {}) do entry[key] = value end
	return entry
end

function Q.set(log, watched, extra)
	stub.quests.log = log
	stub.quests.watched = watched or {}
	for key, value in pairs(extra or {}) do stub.quests[key] = value end
end

function Q.settings(st, changes)
	local quests = st.config.profile.tracker.quests
	local copy = {}
	for key, value in pairs(quests) do copy[key] = value end
	for key, value in pairs(changes or {}) do copy[key] = value end
	return copy
end

function Q.find(model, id)
	for _, quest in ipairs(model.quests) do
		if quest.id == id then return quest end
	end
end

function Q.ids(model)
	local ids = {}
	for i, quest in ipairs(model.quests) do ids[i] = quest.id end
	return table.concat(ids, ',')
end

return Q
