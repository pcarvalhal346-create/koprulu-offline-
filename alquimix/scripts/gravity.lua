-- Gravity, refill, portals and diagonal sliding.
--
-- Order of a pass (repeated until stable):
--   1. vertical fall inside every column (locked pieces and blockers stop pieces)
--   2. spawn a new piece in the top playable cell of each column when empty
--   3. portals: a piece on an entrance jumps to the exit if the exit is empty
--      (each piece teleports at most once per resolution -> no infinite loops)
--   4. diagonal slide into an empty cell that cannot be reached from above
-- Every move is recorded so the view can animate the exact path.
local M = {}

M.MAX_STEPS = 4000

local function record(paths, order, p, x, y, how)
	local path = paths[p.uid]
	if not path then
		path = { { x = p.x, y = p.y } }
		paths[p.uid] = path
		order[#order + 1] = p.uid
	end
	path[#path + 1] = { x = x, y = y, how = how }
end

--- @param board Board
--- @param spawn_fn function(x, landing_y, board) -> element id for a new base piece
--- @param teleported table set uid->true shared by one whole resolution
--- @return result { paths = {uid -> points}, order = {uid...}, spawns = {...}, moved = bool }
function M.apply(board, spawn_fn, teleported)
	teleported = teleported or {}
	local paths, order, spawns = {}, {}, {}
	local spawn_count = {}
	local moved = false
	local steps = 0

	local function vertical()
		local any = false
		for x = 1, board.w do
			for y = board.h, 1, -1 do
				if board:empty(x, y) then
					local k = y - 1
					while k >= 1 and board:empty(x, k) do k = k - 1 end
					if k >= 1 and board:falls(x, k) then
						local p = board:piece(x, k)
						record(paths, order, p, x, y, "fall")
						board:move(x, k, x, y)
						any = true
					end
				end
			end
		end
		return any
	end

	local function spawn()
		local any = false
		for x = 1, board.w do
			local sy = board:spawn_row(x)
			if sy and board:empty(x, sy) then
				-- the new piece will fall to the lowest empty cell straight below
				local land = sy
				while board:empty(x, land + 1) do land = land + 1 end
				local id = spawn_fn(x, land, board)
				local p = board:spawn(x, sy, id, "base")
				spawn_count[x] = (spawn_count[x] or 0) + 1
				spawns[#spawns + 1] = { uid = p.uid, id = id, x = x, y = sy, stack = spawn_count[x] }
				paths[p.uid] = { { x = x, y = sy } }
				order[#order + 1] = p.uid
				any = true
			end
		end
		return any
	end

	local function portals()
		local any = false
		for _, pr in ipairs(board.portals or {}) do
			local f, t = pr.from, pr.to
			local p = board:piece(f.x, f.y)
			if p and board:falls(f.x, f.y) and board:empty(t.x, t.y) and not teleported[p.uid] then
				teleported[p.uid] = true
				record(paths, order, p, t.x, t.y, "portal")
				board:move(f.x, f.y, t.x, t.y)
				any = true
			end
		end
		return any
	end

	local function diagonal()
		for y = board.h, 2, -1 do
			for x = 1, board.w do
				if board:empty(x, y) then
					local first, second = -1, 1
					if (x + y) % 2 == 0 then first, second = 1, -1 end
					for _, dx in ipairs({ first, second }) do
						local sx = x + dx
						if board:in_bounds(sx, y - 1) and board:falls(sx, y - 1) then
							local p = board:piece(sx, y - 1)
							record(paths, order, p, x, y, "slide")
							board:move(sx, y - 1, x, y)
							return true
						end
					end
				end
			end
		end
		return false
	end

	while steps < M.MAX_STEPS do
		steps = steps + 1
		local v = vertical()
		local s = spawn()
		if v or s then
			moved = true
		elseif portals() then
			moved = true
		elseif diagonal() then
			moved = true
		else
			break
		end
	end

	return { paths = paths, order = order, spawns = spawns, moved = moved, steps = steps }
end

--- Cells that can never receive a piece through gravity (used by the validator).
function M.unreachable_cells(board)
	local b = board:clone()
	b:each(function(c)
		-- covers and corruption are temporary: only rocks and voids matter here
		c.cover, c.corrupt = nil, nil
		c.piece = nil
	end)
	M.apply(b, function() return "fire" end, {})
	local out = {}
	b:each(function(c, x, y)
		if b:empty(x, y) then out[#out + 1] = { x = x, y = y } end
	end)
	return out
end

return M
