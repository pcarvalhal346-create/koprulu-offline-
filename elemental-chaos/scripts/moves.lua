-- Enumerates every legal player action on a board.
local match = require "scripts.match"
local alchemy = require "scripts.alchemy"

local M = {}

--- Swap/fusion moves. Each move: { a = {x,y}, b = {x,y}, kind = "fusion"|"match", result }
--- `limit` stops early (used to test "is there any move?").
function M.find(board, limit)
	local out = {}
	for y = 1, board.h do
		for x = 1, board.w do
			if board:movable(x, y) then
				for _, d in ipairs({ { 1, 0 }, { 0, 1 } }) do
					local nx, ny = x + d[1], y + d[2]
					if board:movable(nx, ny) then
						local pa, pb = board:piece(x, y), board:piece(nx, ny)
						local r = alchemy.fusion_result(pa, pb)
						if r then
							out[#out + 1] = { a = { x = x, y = y }, b = { x = nx, y = ny }, kind = "fusion", result = r }
						elseif match.swap_creates_match(board, x, y, nx, ny) then
							out[#out + 1] = { a = { x = x, y = y }, b = { x = nx, y = ny }, kind = "match" }
						end
						if limit and #out >= limit then return out end
					end
				end
			end
		end
	end
	return out
end

function M.any(board)
	return #M.find(board, 1) > 0
end

--- Compounds the player could activate.
function M.compounds(board)
	local out = {}
	board:each(function(c, x, y)
		if c.piece and c.piece.kind == "compound" and board:movable(x, y) then
			out[#out + 1] = { x = x, y = y, id = c.piece.id }
		end
	end)
	return out
end

return M
