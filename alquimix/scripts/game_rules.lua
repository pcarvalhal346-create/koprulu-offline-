-- Game rules: turns, swaps, fusions, compound powers, cascades, victory/defeat.
-- Every player action changes the state and appends events to `self.events`,
-- which the view (gui/board_view.lua) plays back in order.
--
-- Event types: swap, invalid_swap, match, charge, fusion, discovery, activate,
-- power, transform, remove, clear_obstacle, gravity, cascade, conveyor,
-- corruption_spread, shuffle, objective_progress, score, moves, victory, defeat
local rng_mod = require "scripts.rng"
local match = require "scripts.match"
local gravity = require "scripts.gravity"
local alchemy = require "scripts.alchemy"
local obstacles = require "scripts.obstacles"
local objectives_mod = require "scripts.objectives"
local moves_mod = require "scripts.moves"
local terrain = require "scripts.terrain"
local level_manager = require "scripts.level_manager"
local progression = require "scripts.progression"
local recipes = require "data.recipes"
local elements = require "data.elements"

local Game = {}
Game.__index = Game

Game.MAX_CASCADES = 50
Game.CASCADE_DAMPING = 0.92
Game.SCORE = {
	piece = 10, line4 = 60, line5 = 150, cross = 80,
	fusion = { 100, 250 }, activate = 150, objective = 300, move_left = 120,
}

local function copy(t)
	if type(t) ~= "table" then return t end
	local r = {}
	for k, v in pairs(t) do r[k] = copy(v) end
	return r
end

--- @param def table level definition
--- @param opts table|nil { seed = number, discovered = {recipe_key = true} }
function Game.new(def, opts)
	opts = opts or {}
	local self = setmetatable({}, Game)
	self.level = def
	self.rng = rng_mod.new(opts.seed or def.seed)
	self.board = level_manager.build_board(def, self.rng)
	self.moves_total = def.moves
	self.moves_left = def.moves
	self.score = 0
	self.objectives = objectives_mod.new(def.goals)
	self.valid_moves = 0
	self.status = "playing"
	self.discovered = copy(opts.discovered or {})
	self.new_discoveries = {}
	self.weights = level_manager.weights(def)
	self.damping = def.cascade_damping or Game.CASCADE_DAMPING
	self.conveyor_period = (def.terrain and def.terrain.conveyor_period) or 3
	local cor = def.terrain and def.terrain.corruption
	if cor then
		self.corruption = { period = cor.period or 3, limit = cor.limit or 6, max_cells = cor.max_cells or 20, spread = 0 }
	end
	self.stats = { matches = 0, charges = 0, fusions = 0, activations = 0, max_cascade = 0, shuffles = 0 }
	self.no_progress_turns = 0
	self.events = {}
	self.cascade = 0
	return self
end

-- ---------------------------------------------------------------- helpers --

function Game:emit(e)
	self.events[#self.events + 1] = e
	return e
end

function Game:take_events()
	local ev = self.events
	self.events = {}
	return ev
end

function Game:add_score(n, x, y)
	if n == 0 then return end
	self.score = self.score + n
	self:emit({ type = "score", delta = n, total = self.score, x = x, y = y })
end

function Game:progress(type, id, amount)
	local changed = self.objectives:add(type, id, amount)
	for _, ch in ipairs(changed) do
		self.turn_progress = true
		self:emit({ type = "objective_progress", index = ch.index, progress = ch.progress, count = ch.count, done = ch.done })
		if ch.done then self:add_score(Game.SCORE.objective) end
	end
end

function Game:count_obstacle(kind, amount)
	self:progress("clear", kind, amount)
end

--- New piece for the refill. With probability `damping` the generator avoids
--- completing a run at the landing cell, keeping chain reactions exciting but rare.
function Game:spawn_id(x, y, board)
	local id = self.rng:weighted(self.level.elements, self.weights)
	if board and self.rng:random() < self.damping then
		for _ = 1, 4 do
			if not match.would_complete_run(board, x, y, id) then break end
			id = self.rng:weighted(self.level.elements, self.weights)
		end
	end
	return id
end

--- Remove a piece because of a match or a power (counts for "collect").
function Game:remove_piece(x, y, reason)
	local p = self.board:remove(x, y)
	if not p then return nil end
	self:emit({ type = "remove", uid = p.uid, x = x, y = y, id = p.id, kind = p.kind, reason = reason })
	if p.kind == "base" or p.kind == "charged" then
		self:progress("collect", p.id, 1)
		local mult = 1 + 0.5 * math.max(0, self.cascade - 1)
		self.score = self.score + math.floor(Game.SCORE.piece * mult)
	end
	return p
end

function Game:use_move()
	self.moves_left = self.moves_left - 1
	self:emit({ type = "moves", left = self.moves_left })
end

-- ------------------------------------------------------------- resolution --

--- Refill tuning: a freshly spawned piece that completes a run is re-rolled
--- with probability `damping` (only new pieces, never pieces already visible).
--- With 3 elements on an 8x8 board unrestricted refills chain almost forever.
function Game:damp_spawns(g)
	local list = self.level.elements
	for _, s in ipairs(g.spawns) do
		local path = g.paths[s.uid]
		local last = path[#path]
		local p = self.board:piece(last.x, last.y)
		if p and p.uid == s.uid and match.matches_at(self.board, last.x, last.y) and self.rng:random() < self.damping then
			local start = self.rng:random(#list)
			for i = 0, #list - 1 do
				p.id = list[(start + i - 1) % #list + 1]
				if not match.matches_at(self.board, last.x, last.y) then break end
			end
			s.id = p.id
		end
	end
end

function Game:process_groups(groups, manual)
	self.stats.matches = self.stats.matches + #groups
	-- the charge cell is known before removal so the view can make pieces converge on it
	local charge_of = {}
	if manual then
		for i, g in ipairs(groups) do
			for _, m in ipairs(manual) do
				if match.contains(g, m.x, m.y) then charge_of[i] = { x = m.x, y = m.y }; break end
			end
		end
	end
	local evgroups = {}
	for i, g in ipairs(groups) do
		evgroups[#evgroups + 1] = { id = g.id, size = g.size, shape = g.shape, cells = copy(g.cells), charge = charge_of[i] }
	end
	self:emit({ type = "match", cascade = self.cascade, groups = evgroups })

	local removed, touched = {}, {}
	for i, g in ipairs(groups) do
		local charge_cell = charge_of[i]
		for _, c in ipairs(g.cells) do
			if not (charge_cell and charge_cell.x == c.x and charge_cell.y == c.y) then
				local cell = self.board:cell(c.x, c.y)
				touched[c.y * 64 + c.x] = true
				if cell.cover then
					obstacles.damage_cover(self, c.x, c.y, 1)
				elseif cell.corrupt then
					obstacles.cleanse(self, c.x, c.y)
				else
					self:remove_piece(c.x, c.y, "match")
					removed[#removed + 1] = { x = c.x, y = c.y }
				end
			end
		end
		if charge_cell then
			removed[#removed + 1] = { x = charge_cell.x, y = charge_cell.y }
			local p = self.board:piece(charge_cell.x, charge_cell.y)
			if p then
				local fresh = p.kind == "base"
				p.kind = "charged"
				self:emit({ type = "charge", x = p.x, y = p.y, uid = p.uid, id = p.id, size = g.size })
				if fresh then
					self.stats.charges = self.stats.charges + 1
					self:progress("charge", p.id, 1)
				end
			end
		end
		local bonus = 0
		if g.shape == "line5" then bonus = Game.SCORE.line5
		elseif g.shape == "line4" then bonus = Game.SCORE.line4
		elseif g.shape == "cross" then bonus = Game.SCORE.cross end
		if bonus > 0 then
			local c = g.cells[math.ceil(#g.cells / 2)]
			self:add_score(bonus, c.x, c.y)
		end
	end
	obstacles.adjacent(self, removed, touched)
end

--- Resolve gravity and cascades until the board is stable.
--- `manual` = list of cells moved by the player (only the first match creates charges).
function Game:resolve(manual)
	local teleported = {}
	self.cascade = 0
	for _ = 1, Game.MAX_CASCADES do
		local g = gravity.apply(self.board, function(x, y, b) return self:spawn_id(x, y, b) end, teleported)
		if g.moved then
			self:damp_spawns(g)
			self:emit({ type = "gravity", paths = g.paths, order = g.order, spawns = g.spawns })
		end
		local groups = match.find_groups(self.board)
		if #groups == 0 then break end
		self.cascade = self.cascade + 1
		if self.cascade >= 2 then
			self:emit({ type = "cascade", level = self.cascade })
		end
		self:process_groups(groups, self.cascade == 1 and manual or nil)
	end
	if self.cascade > self.stats.max_cascade then self.stats.max_cascade = self.cascade end
	self.cascade = 0
end

function Game:check_victory()
	if self.status ~= "playing" then return true end
	if self.objectives:complete() then
		self.status = "won"
		local bonus = self.moves_left * Game.SCORE.move_left
		self.score = self.score + bonus
		self.stars = progression.stars_for(self.moves_total, self.moves_left)
		self:emit({ type = "victory", stars = self.stars, score = self.score, moves_left = self.moves_left, bonus = bonus })
		return true
	end
	return false
end

function Game:end_turn()
	self.valid_moves = self.valid_moves + 1
	if self:check_victory() then return end

	if #self.board.conveyors > 0 and self.valid_moves % self.conveyor_period == 0 then
		local mv = terrain.shift_conveyors(self.board)
		if #mv > 0 then
			self:emit({ type = "conveyor", moves = mv })
			self:resolve(nil)
		end
	end
	if self.corruption and self.valid_moves % self.corruption.period == 0 then
		obstacles.spread(self)
	end
	if self:check_victory() then return end

	if self.turn_progress then
		self.no_progress_turns = 0
	else
		self.no_progress_turns = self.no_progress_turns + 1
	end
	self.turn_progress = false

	if self.moves_left <= 0 then
		self.status = "lost"
		self:emit({ type = "defeat", remaining = self.objectives:remaining(), score = self.score })
		return
	end
	self:ensure_moves()
end

function Game:ensure_moves()
	if moves_mod.any(self.board) then return end
	local res, ok = terrain.shuffle(self.board, self.rng, self.level.elements)
	self.stats.shuffles = self.stats.shuffles + 1
	self:emit({ type = "shuffle", moves = res.moves, recolor = res.recolor, ok = ok })
end

-- ---------------------------------------------------------------- actions --

local function adjacent(x1, y1, x2, y2)
	return math.abs(x1 - x2) + math.abs(y1 - y2) == 1
end

--- Player drags (x1,y1) onto (x2,y2).
--- Returns { ok = bool, kind = "fusion"|"match"|nil, reason = string|nil, events = {...} }
function Game:try_swap(x1, y1, x2, y2)
	local b = self.board
	if self.status ~= "playing" then return { ok = false, reason = "not_playing", events = {} } end
	if not (b:in_bounds(x1, y1) and b:in_bounds(x2, y2)) or not adjacent(x1, y1, x2, y2) then
		return { ok = false, reason = "not_adjacent", events = {} }
	end
	if not b:movable(x1, y1) or not b:movable(x2, y2) then
		self:emit({ type = "invalid_swap", a = { x = x1, y = y1 }, b = { x = x2, y = y2 }, reason = "locked" })
		return { ok = false, reason = "locked", events = self:take_events() }
	end
	local pa, pb = b:piece(x1, y1), b:piece(x2, y2)
	local result = alchemy.fusion_result(pa, pb)
	if result then
		self:fuse(x1, y1, x2, y2, result)
		return { ok = true, kind = "fusion", result = result, events = self:take_events() }
	end
	if not match.swap_creates_match(b, x1, y1, x2, y2) then
		self:emit({ type = "invalid_swap", a = { x = x1, y = y1 }, b = { x = x2, y = y2 }, reason = "no_match", ua = pa.uid, ub = pb.uid })
		return { ok = false, reason = "no_match", events = self:take_events() }
	end
	b:swap(x1, y1, x2, y2)
	self:emit({ type = "swap", a = { x = x1, y = y1 }, b = { x = x2, y = y2 }, ua = pa.uid, ub = pb.uid })
	self:use_move()
	self:resolve({ { x = x2, y = y2 }, { x = x1, y = y1 } })
	self:end_turn()
	return { ok = true, kind = "match", events = self:take_events() }
end

function Game:fuse(x1, y1, x2, y2, result)
	local b = self.board
	local pa = b:remove(x1, y1)
	local pb = b:remove(x2, y2)
	local np = b:spawn(x2, y2, result, "compound")
	local key = recipes.key(pa.id, pb.id)
	local info = elements.info[result]
	local first = not self.discovered[key]
	self:use_move()
	self:emit({
		type = "fusion", from = { x = x1, y = y1 }, to = { x = x2, y = y2 },
		a = copy(pa), b = copy(pb), result = result, uid = np.uid, key = key, tier = info.tier, first = first,
	})
	if first then
		self.discovered[key] = true
		self.new_discoveries[#self.new_discoveries + 1] = key
		self:emit({ type = "discovery", key = key, result = result, a = pa.id, b = pb.id })
	end
	self.stats.fusions = self.stats.fusions + 1
	self:add_score(Game.SCORE.fusion[info.tier] or 100, x2, y2)
	self:progress("create", result, 1)
	self:resolve(nil)
	self:end_turn()
end

--- Elements present on the board (options for the Crystal power).
function Game:crystal_options()
	local seen, out = {}, {}
	self.board:each(function(c)
		local p = c.piece
		if p and (p.kind == "base" or p.kind == "charged") and not seen[p.id] then
			seen[p.id] = true
		end
	end)
	for _, id in ipairs(elements.BASE) do
		if seen[id] then out[#out + 1] = id end
	end
	return out
end

local function transform(self, cells, power)
	local items = {}
	for _, c in ipairs(cells) do
		local p = self.board:piece(c.x, c.y)
		items[#items + 1] = { uid = p.uid, x = c.x, y = c.y, from = p.id, to = "earth" }
		p.id = "earth"
	end
	self:emit({ type = "transform", items = items, power = power })
end

--- Use the power of the compound at x,y. `choice` is required for crystal.
function Game:activate(x, y, choice)
	local b = self.board
	if self.status ~= "playing" then return { ok = false, reason = "not_playing", events = {} } end
	local p = b:piece(x, y)
	if not p or p.kind ~= "compound" or not b:movable(x, y) then
		return { ok = false, reason = "not_compound", events = {} }
	end
	local id = p.id
	if id == "crystal" then
		local opts = self:crystal_options()
		local valid = false
		for _, o in ipairs(opts) do if o == choice then valid = true end end
		if not valid then
			return { ok = false, reason = "need_choice", need_choice = true, options = opts, events = {} }
		end
	end

	self:use_move()
	b:remove(x, y)
	self:emit({ type = "activate", x = x, y = y, id = id, uid = p.uid, choice = choice })
	self.stats.activations = self.stats.activations + 1
	self:add_score(Game.SCORE.activate, x, y)
	self:progress("activate", id, 1)

	local power = elements.info[id].power
	if power == "column" or power == "row" or power == "cross" or power == "area3" or power == "area2" then
		local cells = alchemy.area_cells(b, id, x, y)
		self:emit({ type = "power", id = id, x = x, y = y, cells = cells })
		local dmg = (id == "lava") and 2 or 1
		for _, c in ipairs(cells) do
			obstacles.hit(self, c.x, c.y, { rock_damage = dmg, reason = id })
		end
	elseif power == "grow4" then
		local cells = {}
		for _, d in ipairs(obstacles.DIRS) do
			local nx, ny = x + d[1], y + d[2]
			local q = b:piece(nx, ny)
			if q and q.kind == "base" and q.id ~= "earth" and b:movable(nx, ny) then
				cells[#cells + 1] = { x = nx, y = ny }
			end
		end
		self:emit({ type = "power", id = id, x = x, y = y, cells = cells })
		transform(self, cells, id)
	elseif power == "grow8" then
		local cand = {}
		b:each(function(c, cx, cy)
			local q = c.piece
			if q and q.kind == "base" and q.id ~= "earth" and b:movable(cx, cy) then cand[#cand + 1] = { x = cx, y = cy } end
		end)
		self.rng:shuffle(cand)
		local cells = {}
		for i = 1, math.min(8, #cand) do cells[i] = cand[i] end
		table.sort(cells, function(a1, b1) return a1.y * 64 + a1.x < b1.y * 64 + b1.x end)
		self:emit({ type = "power", id = id, x = x, y = y, cells = cells })
		transform(self, cells, id)
	elseif power == "erode" then
		local cells = {}
		b:each(function(c, cx, cy)
			if c.blocker or c.cover or c.corrupt then cells[#cells + 1] = { x = cx, y = cy } end
		end)
		self:emit({ type = "power", id = id, x = x, y = y, cells = cells })
		obstacles.erode_all(self)
	elseif power == "shatter" then
		local cells = {}
		b:each(function(c, cx, cy)
			if c.blocker and c.blocker.type == "rock" then cells[#cells + 1] = { x = cx, y = cy } end
		end)
		self:emit({ type = "power", id = id, x = x, y = y, cells = cells })
		obstacles.shatter_rocks(self)
	elseif power == "prism" then
		local cells = {}
		b:each(function(c, cx, cy)
			local q = c.piece
			if q and (q.kind == "base" or q.kind == "charged") and q.id == choice then cells[#cells + 1] = { x = cx, y = cy } end
		end)
		self:emit({ type = "power", id = id, x = x, y = y, cells = cells, choice = choice })
		for _, c in ipairs(cells) do obstacles.hit(self, c.x, c.y, { reason = id }) end
	end

	self:resolve(nil)
	self:end_turn()
	return { ok = true, kind = "activate", id = id, events = self:take_events() }
end

-- -------------------------------------------------------------- queries --

--- Information for the selection UI.
function Game:select_info(x, y)
	local b = self.board
	local p = b:piece(x, y)
	local info = { piece = p, movable = b:movable(x, y), partners = {}, can_activate = false }
	if p and info.movable then
		info.partners = alchemy.partners(b, x, y)
		info.can_activate = p.kind == "compound"
	end
	return info
end

function Game:find_moves()
	return moves_mod.find(self.board)
end

--- Elements/compounds the remaining objectives need (used by hints and the bot).
function Game:wanted()
	local want = { compounds = {}, elements = {}, obstacles = {}, charge = false }
	for _, g in ipairs(self.objectives:remaining()) do
		if g.type == "create" or g.type == "activate" then
			want.compounds[g.id] = (want.compounds[g.id] or 0) + 1
			local r = recipes.producing(g.id)
			while r do
				if elements.is_compound(r.a) then want.compounds[r.a] = (want.compounds[r.a] or 0) + 0.5 end
				if elements.is_compound(r.b) then want.compounds[r.b] = (want.compounds[r.b] or 0) + 0.5 end
				local nxt = (elements.is_compound(r.a) and recipes.producing(r.a)) or (elements.is_compound(r.b) and recipes.producing(r.b))
				r = nxt
			end
		elseif g.type == "collect" then
			want.elements[g.id] = true
		elseif g.type == "clear" then
			want.obstacles[g.id] = true
		elseif g.type == "charge" then
			want.charge = true
		end
	end
	return want
end

--- A helpful move for the idle hint: prefer fusions toward the objectives.
function Game:hint()
	local list = self:find_moves()
	if #list == 0 then return nil end
	local want = self:wanted()
	local best, best_score = nil, -1
	for i, m in ipairs(list) do
		local s = 1
		if m.kind == "fusion" then
			s = 5 + (want.compounds[m.result] and 20 or 0)
		else
			local pa = self.board:piece(m.a.x, m.a.y)
			local pb = self.board:piece(m.b.x, m.b.y)
			if (pa and want.elements[pa.id]) or (pb and want.elements[pb.id]) then s = s + 3 end
			if want.charge then s = s + 2 end
		end
		s = s + (#list - i) * 0.001 -- stable tie-break
		if s > best_score then best, best_score = m, s end
	end
	return best
end

function Game:clone()
	local g = setmetatable({}, Game)
	for k, v in pairs(self) do g[k] = v end
	g.board = self.board:clone()
	g.rng = self.rng:clone()
	g.objectives = self.objectives:clone()
	g.discovered = copy(self.discovered)
	g.new_discoveries = {}
	g.corruption = copy(self.corruption)
	g.stats = copy(self.stats)
	g.events = {}
	return g
end

return Game
