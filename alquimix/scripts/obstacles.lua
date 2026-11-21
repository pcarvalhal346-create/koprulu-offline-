-- Obstacles: rocks (blocker layer), frost & vines (cover layer) and corruption.
-- Functions receive the running game (scripts/game_rules.lua) so that every
-- change emits an event and updates objectives in one place.
local M = {}

M.ROCK_HP = { normal = 1, hard = 2 }

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
M.DIRS = DIRS

local function emit(game, x, y, kind, hp, destroyed, layers)
	game:emit({ type = "clear_obstacle", x = x, y = y, obstacle = kind, hp = hp, destroyed = destroyed, layers = layers })
end

function M.damage_blocker(game, x, y, amount)
	local c = game.board:cell(x, y)
	local b = c and c.blocker
	if not b then return false end
	local dealt = math.min(b.hp, amount or 1)
	b.hp = b.hp - dealt
	local destroyed = b.hp <= 0
	if destroyed then
		c.blocker = nil
		game:count_obstacle(b.type, 1)
		game:add_score(50, x, y)
	else
		game:add_score(20, x, y)
	end
	emit(game, x, y, b.type, math.max(0, b.hp), destroyed, dealt)
	return true
end

function M.damage_cover(game, x, y, amount)
	local c = game.board:cell(x, y)
	local cv = c and c.cover
	if not cv then return false end
	local dealt = math.min(cv.hp, amount or 1)
	cv.hp = cv.hp - dealt
	local destroyed = cv.hp <= 0
	if destroyed then c.cover = nil end
	-- frost objectives count layers, vine objectives count removed vines
	if cv.type == "frost" then
		game:count_obstacle("frost", dealt)
	elseif destroyed then
		game:count_obstacle(cv.type, 1)
	end
	game:add_score(20 * dealt, x, y)
	emit(game, x, y, cv.type, math.max(0, cv.hp), destroyed, dealt)
	return true
end

function M.cleanse(game, x, y)
	local c = game.board:cell(x, y)
	if not c or not c.corrupt then return false end
	c.corrupt = nil
	game:count_obstacle("corruption", 1)
	game:add_score(40, x, y)
	emit(game, x, y, "corruption", 0, true, 1)
	return true
end

--- A power hits a cell. The top-most layer absorbs the hit:
--- blocker > cover > corruption > piece. Compounds are immune to other powers.
function M.hit(game, x, y, opts)
	opts = opts or {}
	local c = game.board:cell(x, y)
	if not c or c.void then return "none" end
	if c.blocker then
		M.damage_blocker(game, x, y, (c.blocker.type == "rock" and opts.rock_damage) or 1)
		return "blocker"
	end
	if c.cover then
		M.damage_cover(game, x, y, 1)
		return "cover"
	end
	if c.corrupt then
		M.cleanse(game, x, y)
		return "corrupt"
	end
	if c.piece and c.piece.kind ~= "compound" then
		game:remove_piece(x, y, opts.reason or "power")
		return "piece"
	end
	return "none"
end

--- Matches damage covers and corruption next to the removed cells (once per cell).
function M.adjacent(game, cells, done)
	done = done or {}
	local board = game.board
	for _, cell in ipairs(cells) do
		for _, d in ipairs(DIRS) do
			local nx, ny = cell.x + d[1], cell.y + d[2]
			local k = ny * 64 + nx
			if not done[k] then
				local c = board:cell(nx, ny)
				if c and (c.cover or c.corrupt) then
					done[k] = true
					if c.cover then
						M.damage_cover(game, nx, ny, 1)
					else
						M.cleanse(game, nx, ny)
					end
				end
			end
		end
	end
	return done
end

--- Dust: one point of damage to every obstacle on the board.
function M.erode_all(game)
	local hits = {}
	game.board:each(function(c, x, y)
		if c.blocker or c.cover or c.corrupt then hits[#hits + 1] = { x = x, y = y } end
	end)
	for _, h in ipairs(hits) do
		local c = game.board:cell(h.x, h.y)
		if c.blocker then
			M.damage_blocker(game, h.x, h.y, 1)
		elseif c.cover then
			M.damage_cover(game, h.x, h.y, 1)
		elseif c.corrupt then
			M.cleanse(game, h.x, h.y)
		end
	end
	return hits
end

--- Obsidian: destroy every rock, including resistant ones.
function M.shatter_rocks(game)
	local hits = {}
	game.board:each(function(c, x, y)
		if c.blocker and c.blocker.type == "rock" then hits[#hits + 1] = { x = x, y = y } end
	end)
	for _, h in ipairs(hits) do
		local c = game.board:cell(h.x, h.y)
		M.damage_blocker(game, h.x, h.y, c.blocker.hp)
	end
	return hits
end

local function on_conveyor(board, x, y)
	for _, cv in ipairs(board.conveyors or {}) do
		if (cv.axis == "row" and cv.index == y) or (cv.axis == "col" and cv.index == x) then return true end
	end
	return false
end
M.on_conveyor = on_conveyor

--- Cells corruption may spread to.
function M.spread_candidates(board)
	local out, seen = {}, {}
	board:each(function(c, x, y)
		if c.corrupt then
			for _, d in ipairs(DIRS) do
				local nx, ny = x + d[1], y + d[2]
				local n = board:cell(nx, ny)
				local k = ny * 64 + nx
				if n and not seen[k] and not n.void and not n.blocker and not n.cover and not n.corrupt
					and n.piece and n.piece.kind ~= "compound" and not n.portal and not on_conveyor(board, nx, ny) then
					seen[k] = true
					out[#out + 1] = { x = nx, y = ny }
				end
			end
		end
	end)
	table.sort(out, function(a, b) return a.y * 64 + a.x < b.y * 64 + b.x end)
	return out
end

--- Spread corruption to one adjacent cell. Returns the cell or nil.
function M.spread(game)
	local cfg = game.corruption
	if not cfg then return nil end
	if (cfg.spread or 0) >= (cfg.limit or 0) then return nil end
	local board = game.board
	local current = board:count(function(c) return c.corrupt == true end)
	if current == 0 or current >= (cfg.max_cells or 64) then return nil end
	local cands = M.spread_candidates(board)
	if #cands == 0 then return nil end
	local pick = cands[game.rng:random(#cands)]
	board:cell(pick.x, pick.y).corrupt = true
	cfg.spread = (cfg.spread or 0) + 1
	game:emit({ type = "corruption_spread", x = pick.x, y = pick.y })
	return pick
end

return M
