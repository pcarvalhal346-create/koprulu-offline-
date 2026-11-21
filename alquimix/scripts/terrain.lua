-- Terrain modifiers that move pieces automatically: conveyor belts and the
-- shuffle used when the board runs out of moves.
local match = require "scripts.match"
local moves = require "scripts.moves"

local M = {}

--- Cells of a conveyor line in travel order.
function M.line_cells(board, cv)
	local cells = {}
	if cv.axis == "row" then
		for x = 1, board.w do cells[#cells + 1] = { x = x, y = cv.index } end
	else
		for y = 1, board.h do cells[#cells + 1] = { x = cv.index, y = y } end
	end
	return cells
end

--- A line is safe when every cell holds a free piece slot (no void, blocker, cover or corruption).
function M.line_is_safe(board, cv)
	for _, c in ipairs(M.line_cells(board, cv)) do
		local cell = board:cell(c.x, c.y)
		if not cell or cell.void or cell.blocker or cell.cover or cell.corrupt then return false end
	end
	return true
end

--- Shift every conveyor line one cell (cyclic). Returns list of piece moves.
function M.shift_conveyors(board)
	local out = {}
	for _, cv in ipairs(board.conveyors or {}) do
		if M.line_is_safe(board, cv) then
			local cells = M.line_cells(board, cv)
			local n = #cells
			local pieces = {}
			for i, c in ipairs(cells) do pieces[i] = board:remove(c.x, c.y) end
			for i, p in ipairs(pieces) do
				local j = ((i - 1 + cv.dir) % n) + 1
				local to = cells[j]
				if p then
					out[#out + 1] = {
						uid = p.uid, from = { x = cells[i].x, y = cells[i].y }, to = { x = to.x, y = to.y },
						wrap = math.abs(j - i) > 1,
					}
				end
				board:place(to.x, to.y, p)
			end
		end
	end
	return out
end

--- Rearrange free normal pieces until there is no match and at least one move.
--- Compounds, locked pieces and obstacles never move.
function M.shuffle(board, rng, elements_list)
	local slots, pool = {}, {}
	board:each(function(c, x, y)
		if c.piece and c.piece.kind ~= "compound" and board:movable(x, y) then
			slots[#slots + 1] = { x = x, y = y }
			pool[#pool + 1] = c.piece
		end
	end)
	local result = { moves = {}, recolor = {} }
	if #slots == 0 then return result, false end
	local original = {}
	for i, p in ipairs(pool) do original[p.uid] = slots[i] end

	local function apply(order)
		for i, s in ipairs(slots) do board:place(s.x, s.y, order[i]) end
	end

	local ok = false
	for _ = 1, 120 do
		rng:shuffle(pool)
		apply(pool)
		if not match.has_any(board) and moves.any(board) then
			ok = true
			break
		end
	end
	if not ok then
		-- recolour normal pieces (fallback for very crowded boards)
		for _ = 1, 60 do
			for _, s in ipairs(slots) do
				local p = board:piece(s.x, s.y)
				local tries = 0
				repeat
					p.id = elements_list[rng:random(#elements_list)]
					tries = tries + 1
				until not match.would_complete_run(board, s.x, s.y, p.id) or tries > 8
			end
			if not match.has_any(board) and moves.any(board) then
				ok = true
				break
			end
		end
		for _, s in ipairs(slots) do
			local p = board:piece(s.x, s.y)
			result.recolor[#result.recolor + 1] = { uid = p.uid, id = p.id }
		end
	end
	for _, s in ipairs(slots) do
		local p = board:piece(s.x, s.y)
		local from = original[p.uid]
		result.moves[#result.moves + 1] = { uid = p.uid, from = from, to = { x = s.x, y = s.y } }
	end
	return result, ok
end

return M
