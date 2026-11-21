local T = require "tests.lib.testlib"
local H = require "tests.helpers"
local progression = require "scripts.progression"
local save = require "scripts.save_manager"
local objectives = require "scripts.objectives"
local animations = require "scripts.animations"
local L = require "scripts.localization"

T.test("20. Combined objectives complete only when all goals are done", function()
	local o = objectives.new({
		{ type = "collect", id = "fire", count = 2 },
		{ type = "create", id = "steam", count = 1 },
		{ type = "clear", id = "rock", count = 1 },
		{ type = "charge", count = 1 },
	})
	o:add("collect", "fire", 5)
	o:add("collect", "water", 5)
	T.eq(o.goals[1].progress, 2, "clamped")
	T.no(o:complete())
	o:add("create", "lava", 1)
	T.eq(o.goals[2].progress, 0)
	o:add("create", "steam", 1)
	o:add("clear", "rock", 1)
	T.no(o:complete())
	o:add("charge", "earth", 1)
	T.ok(o:complete())
end)

T.test("21a. Victory when objectives are completed", function()
	local g = H.game({ "ffwe", "waff", "aewa", "eawe" }, { fill = H.SAFE_FILL, goals = { { type = "charge", count = 1 } } })
	local r = g:try_swap(3, 2, 3, 1)
	T.ok(T.has_event(r.events, "victory"))
	T.eq(g.status, "won")
	T.ok(g.stars >= 1 and g.stars <= 3)
	local after = g:try_swap(1, 1, 2, 1)
	T.no(after.ok, "no actions after the end")
end)

T.test("21b. Defeat when moves run out", function()
	local g = H.game({ "ffwe", "waff", "aewa", "eawe" }, { moves = 1, fill = H.SAFE_FILL, goals = { { type = "collect", id = "air", count = 50 } } })
	g.moves_left = 1
	local r = g:try_swap(3, 2, 3, 1)
	local d = T.has_event(r.events, "defeat")
	T.ok(d)
	T.eq(g.status, "lost")
	T.ok(#d.remaining == 1)
end)

T.test("22. Winning a level unlocks the next one and worlds", function()
	local p = save.defaults()
	T.ok(progression.is_unlocked(p, 1))
	T.no(progression.is_unlocked(p, 2))
	local res = progression.record_win(p, 1, 1000, 2, 20)
	T.ok(res.first_clear)
	T.eq(res.unlocked, 2)
	T.ok(progression.is_unlocked(p, 2))
	p.unlocked = 20
	local w = progression.record_win(p, 20, 500, 1, 20)
	T.eq(w.world_unlocked, 2)
	T.ok(progression.is_unlocked(p, 21))
	p.unlocked = 60
	local fin = progression.record_win(p, 60, 10, 1, 60)
	T.ok(fin.campaign_complete)
end)

T.test("23. Stars thresholds (rounded up) and stars never decrease", function()
	T.eq(progression.stars_for(20, 8), 3)  -- 40% of 20 = 8
	T.eq(progression.stars_for(20, 7), 2)
	T.eq(progression.stars_for(20, 4), 2)  -- 20% of 20 = 4
	T.eq(progression.stars_for(20, 3), 1)
	T.eq(progression.stars_for(17, 7), 3)  -- ceil(6.8) = 7
	T.eq(progression.stars_for(17, 6), 2)
	T.eq(progression.stars_for(17, 4), 2)  -- ceil(3.4) = 4
	T.eq(progression.stars_for(17, 3), 1)
	T.eq(progression.stars_for(16, 0), 1)
	local p = save.defaults()
	progression.record_win(p, 1, 900, 3)
	progression.record_win(p, 1, 2000, 1)
	T.eq(progression.stars(p, 1), 3)
	T.eq(p.levels[1].best_score, 2000)
	T.eq(progression.total_stars(p), 3)
end)

T.test("24. Save and load round trip with defaults and migration", function()
	local backend = save.memory_backend(nil)
	local p = save.init(backend)
	T.eq(p.unlocked, 1, "defaults when there is no file")
	p.unlocked = 7
	p.levels[3] = { stars = 2, best_score = 1234, completed = true }
	p.settings.music = false
	save.add_discovery("fire|water", 3)
	p.tutorials.first_match = true
	T.ok(save.save())
	local again = save.init(backend)
	T.eq(again.unlocked, 7)
	T.eq(again.levels[3].best_score, 1234)
	T.eq(again.settings.music, false)
	T.eq(again.settings.sfx, true)
	T.eq(again.discovered["fire|water"].order, 1)
	T.ok(again.tutorials.first_match)
	T.eq(again.version, save.VERSION)

	-- v0 prototype file -> current version
	local old = save.memory_backend({ max_level = 5, stars = { [1] = 3, [2] = 1 }, recipes = { ["fire|water"] = true } })
	local m = save.init(old)
	T.eq(m.version, save.VERSION)
	T.eq(m.unlocked, 5)
	T.eq(m.levels[1].stars, 3)
	T.eq(m.discovered["fire|water"].order, 1)
	T.eq(m.discovery_count, 1)
	T.eq(old.data.version, save.VERSION, "migrated file saved back")

	-- string keys after serialisation are converted back to numbers
	local strkeys = save.memory_backend({ version = save.VERSION, levels = { ["4"] = { stars = 1, best_score = 1, completed = true } } })
	local s = save.init(strkeys)
	T.eq(s.levels[4].stars, 1)
end)

T.test("Animation queue runs items in order and waits for parallel work", function()
	local q = animations.new()
	local log = {}
	q:push(function() log[#log + 1] = "a"; return 0.5 end)
	q:push(function() log[#log + 1] = "p1"; return 0.3 end, { parallel = true })
	q:push(function() log[#log + 1] = "p2"; return 0.2 end, { parallel = true })
	q:push(function(done) log[#log + 1] = "b"; done() end)
	q:push(function() log[#log + 1] = "c"; return 0.1 end)
	q:update(0)
	T.eq(table.concat(log, ","), "a")
	T.ok(q:busy())
	q:update(0.6)
	T.eq(table.concat(log, ","), "a,p1,p2")
	q:update(0.31)
	T.eq(table.concat(log, ","), "a,p1,p2,b,c")
	q:update(0.2)
	T.no(q:busy())
end)

T.test("Localization has every key used by goals, elements and tutorials", function()
	local elements = require "data.elements"
	for id in pairs(elements.info) do T.ok(L.has("el." .. id), id) end
	for _, id in ipairs(elements.COMPOUNDS) do T.ok(L.has("power." .. id), id) end
	for _, tut in pairs(require("data.tutorial_data").tutorials) do
		for _, st in ipairs(tut.steps) do T.ok(L.has(st.text), st.text) end
	end
	T.eq(L.get("goal.create", { n = 2, name = "Vapor" }), "Cria 2 Vapor")
	T.eq(L.goal({ type = "clear", id = "frost", count = 3 }), "Remove 3 camadas de gelo")
end)

return T
