local T = require "tests.lib.testlib"
local H = require "tests.helpers"
local Board = require "scripts.board"
local match = require "scripts.match"
local moves = require "scripts.moves"

T.test("1. Match-3 horizontal is detected", function()
	local b = Board.from_rows({ "fffw", "wewa", "aeae" })
	local groups = match.find_groups(b)
	T.eq(#groups, 1)
	T.eq(groups[1].id, "fire")
	T.eq(groups[1].size, 3)
	T.eq(groups[1].shape, "line3")
end)

T.test("2. Match-3 vertical is detected", function()
	local b = Board.from_rows({ "wea", "wae", "wea", "aew" })
	local groups = match.find_groups(b)
	T.eq(#groups, 1)
	T.eq(groups[1].id, "water")
	T.eq(groups[1].size, 3)
end)

T.test("3a. Match-4 and Match-5 shapes", function()
	local g4 = match.find_groups(Board.from_rows({ "eeeew", "wawaf" }))
	T.eq(g4[1].size, 4)
	T.eq(g4[1].shape, "line4")
	local g5 = match.find_groups(Board.from_rows({ "aaaaa", "wewef" }))
	T.eq(g5[1].size, 5)
	T.eq(g5[1].shape, "line5")
end)

T.test("3b. Match-4 manual swap removes 3, charges 1 and gives a bonus", function()
	local g = H.game({
		"wwaw",
		"efwe",
		"aeae",
	}, { fill = H.SAFE_FILL })
	local r = g:try_swap(3, 2, 3, 1)
	T.ok(r.ok)
	local m = T.has_event(r.events, "match")
	T.eq(m.groups[1].size, 4)
	T.eq(m.groups[1].shape, "line4")
	local removed = 0
	for _, e in ipairs(r.events) do
		if e.type == "remove" and e.id == "water" and e.reason == "match" then removed = removed + 1 end
	end
	T.ok(removed >= 3)
	local ch = T.has_event(r.events, "charge")
	T.eq(ch.x, 3)
	T.ok(T.has_event(r.events, "score", function(e) return e.delta == 60 end), "match-4 bonus")
end)

T.test("4. T and L shapes form one group without duplicates", function()
	local b = Board.from_rows({
		"fffa",
		"wfaw",
		"efwe",
	})
	local groups = match.find_groups(b)
	T.eq(#groups, 1)
	T.eq(groups[1].size, 5) -- 3 horizontal + 2 more vertical, shared corner counted once
	T.eq(groups[1].shape, "cross")
	local lb = Board.from_rows({
		"waew",
		"eaww",
		"aaae",
	})
	local lg = match.find_groups(lb)
	T.eq(#lg, 1)
	T.eq(lg[1].size, 5)
end)

T.test("5. Manual match creates a charged piece at the moved piece position", function()
	local g = H.game({
		"ffwe",
		"waff",
		"aewa",
		"eaae",
	}, { fill = H.SAFE_FILL })
	-- drag fire (3,2) up onto water (3,1): row 1 = f f f e
	local r = g:try_swap(3, 2, 3, 1)
	T.ok(r.ok, "swap should be valid")
	local ch = T.has_event(r.events, "charge")
	T.ok(ch, "charge event")
	T.eq(ch.x, 3)
	T.eq(ch.y, 1 + 0) -- charge stays where the dragged piece landed (gravity cannot move row 1 down)
	T.eq(g.stats.charges, 1)
	local removed = 0
	for _, e in ipairs(r.events) do
		if e.type == "remove" and e.reason == "match" and e.id == "fire" then removed = removed + 1 end
	end
	T.ok(removed >= 2, "two fires removed")
end)

T.test("5b. Automatic cascades never create charged pieces", function()
	local g = H.game({
		"awea",
		"ewae",
		"fwwe",
		"affa",
	}, { fill = { "earth" } })
	-- swap (1,3) fire with (2,3)... make row 4 fff: drag fire (1,3) down to (1,4)
	local r = g:try_swap(1, 3, 1, 4)
	T.ok(r.ok)
	T.eq(T.count_events(r.events, "charge"), 1, "only the manual match charges")
end)

T.test("6. Invalid swaps are rejected and do not consume moves", function()
	local g = H.game({ "fwea", "eawf", "wfae", "afew" })
	local before = g.moves_left
	local r = g:try_swap(1, 1, 2, 1)
	T.no(r.ok)
	T.eq(r.reason, "no_match")
	T.ok(T.has_event(r.events, "invalid_swap"))
	T.eq(g.moves_left, before)
	T.eq(g.board:piece(1, 1).id, "fire", "board restored")
	local far = g:try_swap(1, 1, 3, 1)
	T.no(far.ok)
	T.eq(far.reason, "not_adjacent")
end)

T.test("14. Spawned pieces come from the level elements only", function()
	local Game = require "scripts.game_rules"
	local g = Game.new(H.level({ elements = { "fire", "water", "earth" } }))
	local seen = {}
	for _ = 1, 300 do seen[g:spawn_id()] = true end
	T.ok(seen.fire and seen.water and seen.earth)
	T.no(seen.air)
end)

T.test("15. Board without moves is detected and reshuffled", function()
	local g = H.game({
		"fwef",
		"wefw",
		"efwe",
		"fwef",
	}, { elements = { "fire", "water", "earth" } })
	T.eq(#moves.find(g.board), 0, "no moves on a diagonal pattern")
	g:ensure_moves()
	local ev = T.has_event(g.events, "shuffle")
	T.ok(ev, "shuffle event")
	T.ok(moves.any(g.board), "moves after shuffle")
	T.no(match.has_any(g.board), "no matches after shuffle")
end)

T.test("15b. Shuffle preserves compounds and obstacles", function()
	local g = H.game({
		"fwef",
		"wefw",
		"efwe",
		"fw.f",
	}, { compounds = { { x = 3, y = 4, id = "steam" } }, elements = { "fire", "water", "earth" } })
	g.board:cell(1, 1).cover = { type = "frost", hp = 1 }
	local frozen_uid = g.board:piece(1, 1).uid
	local steam_uid = g.board:piece(3, 4).uid
	g:ensure_moves()
	T.eq(g.board:piece(3, 4).uid, steam_uid)
	T.eq(g.board:piece(1, 1).uid, frozen_uid)
	T.ok(g.board:cell(1, 1).cover)
end)

return T
