-- Match detection. Runs of 3+ equal matchable pieces (base or charged) are
-- grouped: runs that share a cell (T / L / + shapes) become one group, so no
-- piece is ever removed twice.
local Board = require "scripts.board"

local M = {}

local function key(x, y) return y * 64 + x end

local function piece_id(board, x, y)
	local c = board:cell(x, y)
	if not c or c.void or c.blocker then return nil end
	local p = c.piece
	if Board.matchable(p) then return p.id end
	return nil
end
M.piece_id = piece_id

--- All horizontal/vertical runs of length >= 3
function M.find_runs(board)
	local runs = {}
	for y = 1, board.h do
		local x = 1
		while x <= board.w do
			local id = piece_id(board, x, y)
			local len = 1
			if id then
				while x + len <= board.w and piece_id(board, x + len, y) == id do len = len + 1 end
				if len >= 3 then
					local cells = {}
					for i = 0, len - 1 do cells[#cells + 1] = { x = x + i, y = y } end
					runs[#runs + 1] = { id = id, cells = cells, dir = "h", len = len }
				end
			end
			x = x + len
		end
	end
	for x = 1, board.w do
		local y = 1
		while y <= board.h do
			local id = piece_id(board, x, y)
			local len = 1
			if id then
				while y + len <= board.h and piece_id(board, x, y + len) == id do len = len + 1 end
				if len >= 3 then
					local cells = {}
					for i = 0, len - 1 do cells[#cells + 1] = { x = x, y = y + i } end
					runs[#runs + 1] = { id = id, cells = cells, dir = "v", len = len }
				end
			end
			y = y + len
		end
	end
	return runs
end

--- Groups of connected runs. Each group: { id, cells = {{x,y}}, set = {key=true}, size, longest, shape }
function M.find_groups(board)
	local runs = M.find_runs(board)
	local parent = {}
	local function find(i)
		while parent[i] ~= i do
			parent[i] = parent[parent[i]]
			i = parent[i]
		end
		return i
	end
	local owner = {}
	for i, run in ipairs(runs) do
		parent[i] = i
		for _, c in ipairs(run.cells) do
			local k = key(c.x, c.y)
			if owner[k] then
				local a, b = find(owner[k]), find(i)
				if a ~= b then parent[b] = a end
			else
				owner[k] = i
			end
		end
	end
	local by_root, order = {}, {}
	for i, run in ipairs(runs) do
		local r = find(i)
		local g = by_root[r]
		if not g then
			g = { id = run.id, cells = {}, set = {}, longest = 0, runs = 0, dirs = {} }
			by_root[r] = g
			order[#order + 1] = g
		end
		g.runs = g.runs + 1
		g.dirs[run.dir] = true
		if run.len > g.longest then g.longest = run.len end
		for _, c in ipairs(run.cells) do
			local k = key(c.x, c.y)
			if not g.set[k] then
				g.set[k] = true
				g.cells[#g.cells + 1] = { x = c.x, y = c.y }
			end
		end
	end
	for _, g in ipairs(order) do
		g.size = #g.cells
		if g.dirs.h and g.dirs.v then
			g.shape = "cross"
		elseif g.longest >= 5 then
			g.shape = "line5"
		elseif g.longest == 4 then
			g.shape = "line4"
		else
			g.shape = "line3"
		end
	end
	-- deterministic order: top-left first
	table.sort(order, function(a, b)
		local ka, kb = key(a.cells[1].x, a.cells[1].y), key(b.cells[1].x, b.cells[1].y)
		return ka < kb
	end)
	return order
end

function M.contains(group, x, y)
	return group.set[key(x, y)] == true
end

--- Length of the longest run through (x,y) for the piece there.
function M.run_length_at(board, x, y)
	local id = piece_id(board, x, y)
	if not id then return 0, 0 end
	local h = 1
	local i = x - 1
	while i >= 1 and piece_id(board, i, y) == id do h = h + 1; i = i - 1 end
	i = x + 1
	while i <= board.w and piece_id(board, i, y) == id do h = h + 1; i = i + 1 end
	local v = 1
	i = y - 1
	while i >= 1 and piece_id(board, x, i) == id do v = v + 1; i = i - 1 end
	i = y + 1
	while i <= board.h and piece_id(board, x, i) == id do v = v + 1; i = i + 1 end
	return h, v
end

function M.matches_at(board, x, y)
	local h, v = M.run_length_at(board, x, y)
	return h >= 3 or v >= 3
end

--- Would swapping these two cells create a match? (board is restored)
function M.swap_creates_match(board, x1, y1, x2, y2)
	board:swap(x1, y1, x2, y2)
	local ok = M.matches_at(board, x1, y1) or M.matches_at(board, x2, y2)
	board:swap(x1, y1, x2, y2)
	return ok
end

--- Would placing `id` at (x,y) complete a run with already placed neighbours
--- to the left or above? Used by the generator (fills top-left to bottom-right).
function M.would_complete_run(board, x, y, id)
	local function same(px, py)
		return piece_id(board, px, py) == id
	end
	if same(x - 1, y) and same(x - 2, y) then return true end
	if same(x + 1, y) and same(x + 2, y) then return true end
	if same(x - 1, y) and same(x + 1, y) then return true end
	if same(x, y - 1) and same(x, y - 2) then return true end
	if same(x, y + 1) and same(x, y + 2) then return true end
	if same(x, y - 1) and same(x, y + 1) then return true end
	return false
end

function M.has_any(board)
	return #M.find_runs(board) > 0
end

return M
