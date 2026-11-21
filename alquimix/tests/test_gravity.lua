local T = require "tests.lib.testlib"
local H = require "tests.helpers"
local Board = require "scripts.board"
local gravity = require "scripts.gravity"
local match = require "scripts.match"
local terrain = require "scripts.terrain"

T.test("12. Gravity drops pieces and refills from the top", function()
	local b = Board.from_rows({
		"fa",
		"..",
		"we",
	})
	local fire_uid = b:piece(1, 1).uid
	local res = gravity.apply(b, function() return "earth" end)
	T.eq(b:piece(1, 2).uid, fire_uid, "fire fell one row")
	T.ok(b:piece(1, 1), "column refilled")
	T.eq(#res.spawns, 2)
	local path = res.paths[fire_uid]
	T.eq(path[1].y, 1)
	T.eq(path[#path].y, 2)
end)

T.test("12b. Rocks stop falling pieces; diagonal slide fills cells under rocks", function()
	local b = Board.from_rows({
		"fwe",
		"...",
		"...",
	})
	b:remove(2, 1)
	b.cells[1][2].blocker = { type = "rock", hp = 1, max_hp = 1 }
	gravity.apply(b, function() return "air" end)
	T.ok(b:piece(2, 2), "cell under rock filled diagonally")
	T.ok(b:piece(2, 3))
	T.eq(#gravity.unreachable_cells(b), 0)
end)

T.test("12c. Locked (frozen) pieces do not fall", function()
	local b = Board.from_rows({ "f", ".", "." })
	b.cells[1][1].cover = { type = "frost", hp = 1 }
	gravity.apply(b, function() return "air" end)
	T.eq(b:piece(1, 1).id, "fire")
	T.eq(b:piece(1, 2), nil, "nothing above to fill (column spawns blocked by the frozen piece)")
end)

T.test("13. Cascades resolve and stop (protection against endless loops)", function()
	local g = H.game({
		"fwef",
		"wfew",
		"ffwe",
		"weff",
	}, { fill = { "earth" } })
	-- a constant earth fill forms new runs forever: the cascade cap must stop it
	local r = g:try_swap(3, 1, 3, 2)
	T.ok(r.ok or r.reason)
	T.ok(g.stats.max_cascade <= g.MAX_CASCADES)
end)

T.test("13b. Cascade events are emitted after the first match", function()
	local g = H.game({
		"aewa",
		"ewea",
		"fwfe",
		"wfwa",
	}, { fill = { "water", "air", "fire", "earth" } })
	local r = g:try_swap(2, 4, 2, 3)
	T.ok(r.ok)
	-- the fall of (2,1),(2,2) into column 2 can produce new runs; when it does
	-- cascade events have level >= 2
	for _, e in ipairs(r.events) do
		if e.type == "cascade" then T.ok(e.level >= 2) end
	end
	T.no(match.has_any(g.board), "board stable at the end of the turn")
end)

T.test("17. Conveyor belts shift a row cyclically every 3 valid moves", function()
	local b = Board.from_rows({ "fwea", "eafw" })
	b.conveyors = { { axis = "row", index = 1, dir = 1 } }
	local first = b:piece(1, 1).uid
	local last = b:piece(4, 1).uid
	local mv = terrain.shift_conveyors(b)
	T.eq(#mv, 4)
	T.eq(b:piece(2, 1).uid, first)
	T.eq(b:piece(1, 1).uid, last, "wraps around")
	-- in a game the shift happens only every third move
	local g = H.game({
		"fwea....",
		"eafwefwa",
		"wefaewfe",
		"aefwafea",
	}, { fill = H.SAFE_FILL, conveyors = { { axis = "row", index = 3, dir = -1 } } })
	g.board.cells[1][5].piece = nil
	g.valid_moves = 2
	g.status = "playing"
	g:end_turn()
	local conv = T.has_event(g.events, "conveyor")
	T.ok(conv, "conveyor moved on the third move")
end)

T.test("17b. Conveyor lines with blockers are rejected", function()
	local b = Board.from_rows({ "fwea" })
	b.cells[1][2].blocker = { type = "rock", hp = 1 }
	T.no(terrain.line_is_safe(b, { axis = "row", index = 1, dir = 1 }))
	T.eq(#terrain.shift_conveyors(b), 0)
end)

T.test("18. Portals teleport a piece once per resolution", function()
	local b = Board.from_rows({
		"f.",
		"..",
		"..",
		"..",
	})
	b:remove(1, 1)
	b.cells[2][1].blocker = { type = "rock", hp = 1 }
	b.cells[2][2].blocker = { type = "rock", hp = 1 }
	b.portals = { { from = { x = 1, y = 1 }, to = { x = 1, y = 3 } } }
	local res = gravity.apply(b, function() return "water" end, {})
	T.ok(b:piece(1, 3), "exit filled through the portal")
	T.ok(b:piece(1, 4))
	T.ok(b:piece(2, 4), "neighbour below the exit filled diagonally")
	local used = {}
	for uid, path in pairs(res.paths) do
		local n = 0
		for _, p in ipairs(path) do if p.how == "portal" then n = n + 1 end end
		T.ok(n <= 1, "teleported at most once")
		if n == 1 then used[#used + 1] = uid end
	end
	T.ok(#used >= 2, "several pieces travel through the portal")
end)

T.test("18b. A two-way portal loop cannot cycle forever", function()
	local b = Board.from_rows({ "f", ".", "." })
	b.portals = { { from = { x = 1, y = 3 }, to = { x = 1, y = 1 } }, { from = { x = 1, y = 1 }, to = { x = 1, y = 3 } } }
	local res = gravity.apply(b, function() return "air" end, {})
	T.ok(res.steps < gravity.MAX_STEPS)
end)

return T
