local T = require "tests.lib.testlib"
local H = require "tests.helpers"
local obstacles = require "scripts.obstacles"
local Game = require "scripts.game_rules"
local level_manager = require "scripts.level_manager"
local tutorial_manager = require "scripts.tutorial_manager"

T.test("16a. Rocks block swaps and are not damaged by adjacent matches", function()
	local g = H.game({
		"ffwe",
		"waff",
		"aewa",
		"eawe",
	}, { fill = H.SAFE_FILL })
	g.board:remove(4, 2)
	g.board:cell(4, 2).blocker = { type = "rock", hp = 1, max_hp = 1 }
	local bad = g:try_swap(4, 2, 4, 1)
	T.no(bad.ok)
	T.eq(bad.reason, "locked")
	local r = g:try_swap(3, 2, 3, 1)
	T.ok(r.ok)
	T.ok(g.board:cell(4, 2).blocker, "rock untouched by the neighbouring match")
end)

T.test("16b. Frost locks a piece; adjacent matches remove one layer", function()
	local g = H.game({
		"ffwe",
		"waff",
		"aewa",
		"eawe",
	}, { fill = H.SAFE_FILL, goals = { { type = "clear", id = "frost", count = 2 } } })
	g.board:cell(4, 1).cover = { type = "frost", hp = 2 }
	T.no(g.board:movable(4, 1))
	local r = g:try_swap(3, 2, 3, 1)
	T.ok(r.ok)
	T.eq(g.board:cell(4, 1).cover.hp, 1)
	T.eq(g.objectives.goals[1].progress, 1, "one frost layer counted")
end)

T.test("16c. Vines are cut by adjacent matches and by powers", function()
	local g = H.game({
		"ffwe",
		"waff",
		"aewa",
		"eawe",
	}, { fill = H.SAFE_FILL, goals = { { type = "clear", id = "vine", count = 1 } } })
	g.board:cell(2, 2).cover = { type = "vine", hp = 1 }
	local r = g:try_swap(3, 2, 3, 1)
	T.ok(r.ok)
	T.eq(g.board:cell(2, 2).cover, nil)
	T.eq(g.status, "won")
end)

T.test("16d. Matched covered pieces stay but lose a layer", function()
	local g = H.game({ "ffwe", "waff", "aewa", "eawe" }, { fill = H.SAFE_FILL })
	g.board:cell(1, 1).cover = { type = "frost", hp = 1 }
	local uid = g.board:piece(1, 1).uid
	g:try_swap(3, 2, 3, 1)
	T.eq(g.board:cell(1, 1).cover, nil)
	T.ok(g.board:find_uid(uid), "the frozen piece survived")
end)

T.test("16e. Hard rocks need two hits; a normal power hit deals 1", function()
	local g = H.game({ "fwea", "eafw", "wefa", "aefw" }, { fill = H.SAFE_FILL })
	g.board:remove(3, 3)
	g.board:cell(3, 3).blocker = { type = "rock", hp = 2, max_hp = 2 }
	obstacles.hit(g, 3, 3)
	T.eq(g.board:cell(3, 3).blocker.hp, 1)
	obstacles.hit(g, 3, 3)
	T.eq(g.board:cell(3, 3).blocker, nil)
end)

T.test("19. Corruption locks pieces, is cleansed by neighbours and spreads with a limit", function()
	local g = H.game({
		"ffwe",
		"waff",
		"aewa",
		"eawe",
	}, { fill = H.SAFE_FILL, goals = { { type = "clear", id = "corruption", count = 1 } } })
	g.corruption = { period = 3, limit = 1, max_cells = 10, spread = 0 }
	g.board:cell(1, 4).corrupt = true
	T.no(g.board:movable(1, 4))
	local s1 = obstacles.spread(g)
	T.ok(s1, "spreads once")
	T.ok(g.board:cell(s1.x, s1.y).corrupt)
	T.eq(obstacles.spread(g), nil, "limit reached")
	g.board:cell(2, 2).corrupt = true
	local r = g:try_swap(3, 2, 3, 1)
	T.ok(r.ok)
	T.eq(g.board:cell(2, 2).corrupt, nil, "cleansed by the adjacent match")
	T.eq(g.objectives.goals[1].progress, 1)
end)

T.test("19b. Corruption never spreads onto obstacles, compounds or conveyors", function()
	local g = H.game({ "fwea", "eafw", "w.fa", "aefw" }, { compounds = { { x = 2, y = 3, id = "steam" } } })
	g.corruption = { period = 1, limit = 10, max_cells = 30, spread = 0 }
	g.board:cell(1, 3).corrupt = true
	g.board:cell(1, 2).cover = { type = "frost", hp = 1 }
	g.board.conveyors = { { axis = "row", index = 4, dir = 1 } }
	local cands = obstacles.spread_candidates(g.board)
	T.eq(#cands, 0, "neighbours are frost, steam and a conveyor")
end)

T.test("Tutorial presets demonstrate their guided moves", function()
	local data = require "data.tutorial_data"
	for id, tut in pairs(data.tutorials) do
		local def = level_manager.get(tut.level)
		T.eq(def.tutorial, id, "level " .. tut.level .. " uses tutorial " .. id)
		local game = Game.new(def)
		local tm = tutorial_manager.new(id, game)
		local guard = 0
		while not tm.finished and guard < 20 do
			guard = guard + 1
			local st = tm:step()
			if st.kind == "say" then
				tm:on_continue()
			elseif st.kind == "swap" then
				T.ok(tm.move, id .. ": guided swap found")
				if st.from then
					T.ok(tm.move.a.x == st.from.x and tm.move.a.y == st.from.y, id .. ": fixed move used (preset valid)")
					T.eq(tm.rebuilt, nil, id .. ": no rebuild needed")
				end
				T.ok(tm:allows_swap(tm.move.a, tm.move.b))
				T.no(tm:allows_swap({ x = 1, y = 1 }, { x = 1, y = 2 }) and not (tm.move.a.x == 1 and tm.move.a.y == 1))
				local r = game:try_swap(tm.move.a.x, tm.move.a.y, tm.move.b.x, tm.move.b.y)
				T.ok(r.ok, id .. ": guided swap valid")
				if st.expect == "fusion" then T.eq(r.result, st.result, id .. ": fusion result") end
				tm:on_action(r.kind)
			elseif st.kind == "select" then
				T.ok(tm.target, id .. ": select target")
				T.ok(tm:allows_tap(tm.target.x, tm.target.y))
				tm:on_action("select")
			elseif st.kind == "activate" then
				local choice = game.board:piece(tm.target.x, tm.target.y).id == "crystal" and game:crystal_options()[1] or nil
				local r = game:activate(tm.target.x, tm.target.y, choice)
				T.ok(r.ok, id .. ": activation")
				tm:on_action("activate")
			end
		end
		T.ok(tm.finished, id .. " finished")
	end
end)

T.test("Tutorial finder rebuilds a demonstration when none exists", function()
	local g = H.game({
		"fwef",
		"wefw",
		"efwe",
		"fwef",
	}, { elements = { "fire", "water", "earth" } })
	local move, changed = tutorial_manager.inject(g.board, { type = "match", element = "water" }, { "fire", "water", "earth" })
	T.ok(move)
	T.ok(#changed > 0)
	local r = g:try_swap(move.a.x, move.a.y, move.b.x, move.b.y)
	T.ok(r.ok)
end)

return T
