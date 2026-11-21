-- Fusion rules and compound power targeting. Recipes are data (data/recipes.lua).
local recipes = require "data.recipes"
local elements = require "data.elements"

local M = {}

local KINDS = { base = true, charged = true, compound = true }

--- Ingredient identifier of a piece (charged/base -> element, compound -> compound id)
local function ingredient(piece)
	if not piece or not KINDS[piece.kind] then return nil end
	if not elements.exists(piece.id) then return nil end
	return piece.id
end

--- Result of fusing two pieces, or nil + reason.
--- Rules:
---  * two normal (base) elements never fuse
---  * charged + base / charged + charged fuse when a recipe exists
---  * compound + base / compound + charged fuse when a recipe exists
---  * compound + compound never fuse
function M.fusion_result(a, b)
	local ia, ib = ingredient(a), ingredient(b)
	if not ia or not ib then return nil, "invalid_piece" end
	if a.kind == "base" and b.kind == "base" then return nil, "both_base" end
	if a.kind == "compound" and b.kind == "compound" then return nil, "both_compound" end
	local r = recipes.find(ia, ib)
	if not r then return nil, "no_recipe" end
	return r
end

--- Adjacent cells whose piece could fuse with the piece at x,y (for highlighting)
function M.partners(board, x, y)
	local out = {}
	local p = board:piece(x, y)
	if not p or p.kind == "base" or not board:movable(x, y) then return out end
	for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local nx, ny = x + d[1], y + d[2]
		if board:movable(nx, ny) then
			local r = M.fusion_result(p, board:piece(nx, ny))
			if r then out[#out + 1] = { x = nx, y = ny, result = r } end
		end
	end
	return out
end

--- Cells hit by an area power (excluding the compound cell itself where noted).
function M.area_cells(board, id, x, y)
	local cells = {}
	local function add(cx, cy)
		if board:playable(cx, cy) and not (cx == x and cy == y) then
			cells[#cells + 1] = { x = cx, y = cy }
		end
	end
	if id == "steam" then
		for cy = 1, board.h do add(x, cy) end
	elseif id == "plasma" then
		for cx = 1, board.w do add(cx, y) end
	elseif id == "storm" then
		for cx = 1, board.w do add(cx, y) end
		for cy = 1, board.h do add(x, cy) end
	elseif id == "lava" then
		for cy = y - 1, y + 1 do
			for cx = x - 1, x + 1 do add(cx, cy) end
		end
	elseif id == "ice" then
		-- 2x2 block: the compound cell, right, below and below-right (shifted to stay on the board)
		local ox = (x < board.w) and x or x - 1
		local oy = (y < board.h) and y or y - 1
		for cy = oy, oy + 1 do
			for cx = ox, ox + 1 do add(cx, cy) end
		end
	end
	return cells
end

--- Description used by the UI and the simulator
function M.power_kind(id)
	local info = elements.info[id]
	return info and info.power
end

return M
