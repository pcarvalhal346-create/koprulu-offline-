-- Loads level definitions and builds their starting boards.
-- Levels are pure data (levels/world_0X.lua); adding a level never requires
-- changes here.
--
-- Layout codes (8 characters per row, top row first):
--   .  normal cell (random piece)        #  void (not part of the board)
--   r  rock (1 hp)                        R  resistant rock (2 hp)
--   i  frost, 1 layer over a piece        I  frost, 2 layers
--   v  vines over a piece                 c  corruption over a piece
local Board = require "scripts.board"
local match = require "scripts.match"
local moves = require "scripts.moves"
local patterns = require "data.obstacle_patterns"
local presets = require "data.board_presets"

local M = {}

M.WORLDS = {
	{ id = 1, key = "world1", first = 1,  last = 20 },
	{ id = 2, key = "world2", first = 21, last = 40 },
	{ id = 3, key = "world3", first = 41, last = 60 },
}

M.CODES = {
	["."] = {}, ["#"] = { void = true },
	r = { blocker = { type = "rock", hp = 1 } }, R = { blocker = { type = "rock", hp = 2 } },
	i = { cover = { type = "frost", hp = 1 } }, I = { cover = { type = "frost", hp = 2 } },
	v = { cover = { type = "vine", hp = 1 } }, c = { corrupt = true },
}

local cache

local function load_all()
	if cache then return cache end
	cache = { list = {}, by_id = {} }
	-- literal requires so the Defold build includes every world file
	local worlds = { require("levels.world_01"), require("levels.world_02"), require("levels.world_03") }
	for _, world in ipairs(worlds) do
		for _, def in ipairs(world) do
			cache.list[#cache.list + 1] = def
			cache.by_id[def.id] = def
		end
	end
	table.sort(cache.list, function(a, b) return a.id < b.id end)
	return cache
end

function M.all() return load_all().list end
function M.get(id) return load_all().by_id[id] end
function M.count() return #load_all().list end

function M.world_of(id)
	for _, w in ipairs(M.WORLDS) do
		if id >= w.first and id <= w.last then return w end
	end
	return M.WORLDS[#M.WORLDS]
end

--- Merge pattern layers and the explicit layout into an 8x8 grid of codes.
function M.layout_grid(def)
	local grid = {}
	for y = 1, 8 do
		grid[y] = {}
		for x = 1, 8 do grid[y][x] = "." end
	end
	for _, layer in ipairs(def.layers or {}) do
		local pat = patterns.get(layer.pattern)
		assert(pat, "unknown pattern " .. tostring(layer.pattern))
		for y, row in ipairs(pat) do
			for x = 1, #row do
				if row:sub(x, x) == "x" then grid[y][x] = layer.tile end
			end
		end
	end
	if def.layout then
		for y, row in ipairs(def.layout) do
			for x = 1, #row do
				local ch = row:sub(x, x)
				if ch ~= "." then grid[y][x] = ch end
			end
		end
	end
	-- board silhouette: only cells that are still plain become void
	if def.shape then
		local pat = patterns.get(def.shape)
		assert(pat, "unknown shape " .. tostring(def.shape))
		for y, row in ipairs(pat) do
			for x = 1, #row do
				if row:sub(x, x) == "x" and grid[y][x] == "." then grid[y][x] = "#" end
			end
		end
	end
	return grid
end

function M.weights(def)
	local w = {}
	for _, id in ipairs(def.elements) do
		w[id] = (def.weights and def.weights[id]) or 10
	end
	return w
end

local function copy(t)
	if type(t) ~= "table" then return t end
	local r = {}
	for k, v in pairs(t) do r[k] = copy(v) end
	return r
end

--- Build the board shell (cells, obstacles, terrain) without pieces.
function M.build_shell(def)
	local board = Board.new(8, 8)
	local grid = M.layout_grid(def)
	for y = 1, 8 do
		for x = 1, 8 do
			local code = M.CODES[grid[y][x]]
			assert(code, ("level %s: invalid layout code '%s'"):format(tostring(def.id), grid[y][x]))
			local c = board.cells[y][x]
			c.void = code.void
			c.blocker = copy(code.blocker)
			if c.blocker then c.blocker.max_hp = c.blocker.hp end
			c.cover = copy(code.cover)
			c.corrupt = code.corrupt
		end
	end
	local t = def.terrain or {}
	for i, p in ipairs(t.portals or {}) do
		board.portals[#board.portals + 1] = { from = copy(p.from), to = copy(p.to), pair = i }
		board.cells[p.from.y][p.from.x].portal = { role = "in", pair = i }
		board.cells[p.to.y][p.to.x].portal = { role = "out", pair = i }
	end
	for _, cv in ipairs(t.conveyors or {}) do
		board.conveyors[#board.conveyors + 1] = { axis = cv.axis, index = cv.index, dir = cv.dir }
		local cells = {}
		if cv.axis == "row" then
			for x = 1, 8 do cells[#cells + 1] = board.cells[cv.index][x] end
		else
			for y = 1, 8 do cells[#cells + 1] = board.cells[y][cv.index] end
		end
		for _, c in ipairs(cells) do c.conveyor = { axis = cv.axis, dir = cv.dir } end
	end
	return board
end

local function pick(rng, def, weights, board, x, y)
	local id
	for _ = 1, 12 do
		id = rng:weighted(def.elements, weights)
		if not match.would_complete_run(board, x, y, id) then return id end
	end
	-- deterministic fallback: first element that does not complete a run
	for _, e in ipairs(def.elements) do
		if not match.would_complete_run(board, x, y, e) then return e end
	end
	return id
end

--- Build the playable starting board.
function M.build_board(def, rng)
	local weights = M.weights(def)
	local preset = def.board_preset and presets[def.board_preset]
	local min_moves = def.min_moves or 3
	local best
	for _ = 1, 40 do
		local board = M.build_shell(def)
		local fixed = {}
		if preset then
			for y, row in ipairs(preset.rows) do
				for x = 1, #row do
					local ch = row:sub(x, x)
					local LONG = { f = "fire", w = "water", e = "earth", a = "air" }
					local id = LONG[ch:lower()]
					if id and board:holds_piece(x, y) then
						board:spawn(x, y, id, ch:match("%u") and "charged" or "base")
						fixed[y * 64 + x] = true
					end
				end
			end
			for _, cp in ipairs(preset.compounds or {}) do
				board:spawn(cp.x, cp.y, cp.id, "compound")
				fixed[cp.y * 64 + cp.x] = true
			end
		end
		for y = 1, 8 do
			for x = 1, 8 do
				if board:holds_piece(x, y) and not board:piece(x, y) then
					board:spawn(x, y, pick(rng, def, weights, board, x, y), "base")
				end
			end
		end
		-- remove accidental runs created next to preset pieces
		local guard = 0
		while match.has_any(board) and guard < 50 do
			guard = guard + 1
			for _, g in ipairs(match.find_groups(board)) do
				for _, c in ipairs(g.cells) do
					if not fixed[c.y * 64 + c.x] then
						board:piece(c.x, c.y).id = def.elements[rng:random(#def.elements)]
						break
					end
				end
			end
		end
		local count = #moves.find(board, min_moves)
		if not match.has_any(board) and count >= min_moves then
			return board
		end
		if not best then best = board end
	end
	return best
end

return M
