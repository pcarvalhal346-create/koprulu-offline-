-- Interactive tutorial state machine (no GUI code).
-- The view asks `targets()` for the cells to highlight / demonstrate and
-- routes player input through `allows_swap` / `allows_tap` so that only the
-- demonstrated action is accepted during guided steps.
local data = require "data.tutorial_data"
local moves = require "scripts.moves"
local match = require "scripts.match"
local recipes = require "data.recipes"
local elements = require "data.elements"

local M = {}
M.__index = M

--- @param id string tutorial id
--- @param game Game running game
function M.new(id, game)
	local def = data.get(id)
	if not def then return nil end
	local self = setmetatable({ id = id, def = def, game = game, index = 1, finished = false, skipped = false }, M)
	self:prepare()
	return self
end

function M:step()
	if self.finished then return nil end
	return self.def.steps[self.index]
end

local function same(a, b)
	return a and b and a.x == b.x and a.y == b.y
end

-- ---------------------------------------------------------------- finders --

local function find_obstacles(board, id)
	local out = {}
	board:each(function(c, x, y)
		local ok = false
		if id == "rock" then ok = c.blocker and c.blocker.type == "rock"
		elseif id == "rock_hard" then ok = c.blocker and c.blocker.type == "rock" and c.blocker.hp >= 2
		elseif id == "frost" or id == "vine" then ok = c.cover and c.cover.type == id
		elseif id == "corruption" then ok = c.corrupt == true end
		if ok then out[#out + 1] = { x = x, y = y } end
	end)
	return out
end

local function find_cells(board, finder)
	if finder.type == "obstacle" then return find_obstacles(board, finder.id) end
	local out = {}
	if finder.type == "compound" then
		board:each(function(c, x, y)
			if c.piece and c.piece.kind == "compound" and c.piece.id == finder.id then out[#out + 1] = { x = x, y = y } end
		end)
	elseif finder.type == "conveyor" then
		board:each(function(c, x, y) if c.conveyor then out[#out + 1] = { x = x, y = y } end end)
	elseif finder.type == "portal" then
		board:each(function(c, x, y) if c.portal then out[#out + 1] = { x = x, y = y } end end)
	end
	return out
end
M.find_cells = find_cells

--- Swap demonstrating the finder, or nil.
function M.find_swap(board, finder)
	local list = moves.find(board)
	for _, m in ipairs(list) do
		if finder.type == "fusion" and m.kind == "fusion" and m.result == finder.result then
			-- show the direction that moves the charged/compound piece onto the partner
			local pa = board:piece(m.a.x, m.a.y)
			if pa.kind == "base" then return { a = m.b, b = m.a } end
			return { a = m.a, b = m.b }
		elseif finder.type == "match" and m.kind == "match" then
			if not finder.element then return { a = m.a, b = m.b } end
			board:swap(m.a.x, m.a.y, m.b.x, m.b.y)
			local ok = false
			for _, g in ipairs(match.find_groups(board)) do
				if g.id == finder.element then ok = true end
			end
			board:swap(m.a.x, m.a.y, m.b.x, m.b.y)
			if ok then return { a = m.a, b = m.b } end
		end
	end
	return nil
end

--- Rebuild a demonstrable configuration without consuming moves.
--- Returns the move and the list of changed cells.
function M.inject(board, finder, elements_list)
	local spots = { { 4, 5 }, { 3, 4 }, { 5, 3 }, { 2, 6 }, { 4, 2 }, { 6, 6 } }
	for y = 2, board.h do
		for x = 1, board.w - 2 do spots[#spots + 1] = { x, y } end
	end
	for _, s in ipairs(spots) do
		local x, y = s[1], s[2]
		local changed, backup = {}, {}
		local function set(cx, cy, id, kind)
			if not board:movable(cx, cy) then return false end
			local p = board:piece(cx, cy)
			backup[#backup + 1] = { p = p, id = p.id, kind = p.kind }
			p.id, p.kind = id, kind
			changed[#changed + 1] = { x = cx, y = cy, uid = p.uid, id = id, kind = kind }
			return true
		end
		local function restore()
			for i = #backup, 1, -1 do backup[i].p.id, backup[i].p.kind = backup[i].id, backup[i].kind end
		end
		local ok, move = true, nil
		if finder.type == "fusion" then
			local r = recipes.producing(finder.result)
			local first_kind = elements.is_compound(r.a) and "compound" or "charged"
			ok = set(x, y, r.a, first_kind) and set(x + 1, y, r.b, elements.is_compound(r.b) and "compound" or "base")
			move = { a = { x = x, y = y }, b = { x = x + 1, y = y } }
		else
			local id = finder.element or elements_list[1]
			local other = id
			for _, e in ipairs(elements_list) do if e ~= id then other = e; break end end
			ok = set(x, y, id, "base") and set(x + 1, y, id, "base") and set(x + 2, y - 1, id, "base") and set(x + 2, y, other, "base")
			move = { a = { x = x + 2, y = y - 1 }, b = { x = x + 2, y = y } }
		end
		if ok and not match.has_any(board) then
			local found = finder.type == "fusion" and M.find_swap(board, finder) or (M.find_swap(board, finder) and move)
			if found then return found, changed end
		end
		restore()
	end
	return nil, nil
end

-- ------------------------------------------------------------ preparation --

--- Resolve targets for the current step against the live board.
--- Sets self.move (swap), self.target (tap cell) and self.cells (highlight).
function M:prepare()
	self.move, self.target, self.cells, self.rebuilt = nil, nil, {}, nil
	local st = self:step()
	if not st then return end
	local board = self.game.board
	if st.kind == "swap" then
		if st.from and st.to then
			local ok = false
			for _, m in ipairs(moves.find(board)) do
				if (same(m.a, st.from) and same(m.b, st.to)) or (same(m.a, st.to) and same(m.b, st.from)) then
					ok = (st.expect ~= "fusion") or (m.kind == "fusion" and m.result == st.result)
				end
			end
			if ok then self.move = { a = st.from, b = st.to } end
		end
		if not self.move then
			local finder = st.finder or (st.expect == "fusion" and { type = "fusion", result = st.result }) or { type = "match" }
			self.move = M.find_swap(board, finder)
			if not self.move then
				local mv, changed = M.inject(board, finder, self.game.level.elements)
				self.move = mv
				self.rebuilt = changed
			end
		end
		if self.move then self.cells = { self.move.a, self.move.b } end
	elseif st.kind == "select" or st.kind == "activate" then
		local cells = find_cells(board, st.finder)
		self.target = cells[1]
		if self.target then self.cells = { self.target } end
	elseif st.kind == "say" and st.highlight then
		self.cells = find_cells(board, st.highlight)
	end
	-- a guided step that cannot be demonstrated is skipped rather than blocking the player
	if (st.kind == "swap" and not self.move) or ((st.kind == "select" or st.kind == "activate") and not self.target) then
		self:advance()
	end
end

-- ----------------------------------------------------------------- input --

function M:blocks_board()
	local st = self:step()
	return st ~= nil and st.kind == "say"
end

function M:allows_swap(a, b)
	local st = self:step()
	if not st then return true end
	if st.kind ~= "swap" then return false end
	local m = self.move
	return m ~= nil and ((same(a, m.a) and same(b, m.b)) or (same(a, m.b) and same(b, m.a)))
end

function M:allows_tap(x, y)
	local st = self:step()
	if not st then return true end
	if st.kind == "select" or st.kind == "activate" then
		return self.target ~= nil and self.target.x == x and self.target.y == y
	end
	return false
end

function M:advance()
	self.index = self.index + 1
	if self.index > #self.def.steps then
		self.finished = true
		self.move, self.target, self.cells = nil, nil, {}
		return
	end
	self:prepare()
end

--- Called by the view after the board finished animating an action.
function M:on_action(kind)
	local st = self:step()
	if not st then return false end
	if (st.kind == "swap" and (kind == "fusion" or kind == "match"))
		or (st.kind == "select" and kind == "select")
		or (st.kind == "activate" and kind == "activate") then
		self:advance()
		return true
	end
	return false
end

function M:on_continue()
	local st = self:step()
	if st and st.kind == "say" then
		self:advance()
		return true
	end
	return false
end

function M:skip()
	self.skipped = true
	self.finished = true
	self.move, self.target, self.cells = nil, nil, {}
end

return M
