-- Board state: pure Lua tables, no GUI references.
-- Coordinates: x = 1..w (left to right), y = 1..h (top to bottom). Gravity pulls towards larger y.
--
-- Each cell has separate layers:
--   void     : true if the cell is not part of the board
--   piece    : { uid, id, kind = "base"|"charged"|"compound", x, y } or nil
--   blocker  : { type = "rock", hp, max_hp } occupies the cell (no piece)
--   cover    : { type = "frost"|"vine", hp } overlays a piece and locks it
--   corrupt  : true when dark energy sits on the cell (locks its piece)
--   conveyor : { axis, dir } terrain modifier (informational, lines live in board.conveyors)
--   portal   : { role = "in"|"out", pair = n } terrain modifier
local elements = require "data.elements"

local M = {}
M.__index = M

function M.new(w, h)
	local self = setmetatable({ w = w or 8, h = h or 8, cells = {}, next_uid = 1, portals = {}, conveyors = {} }, M)
	for y = 1, self.h do
		self.cells[y] = {}
		for x = 1, self.w do
			self.cells[y][x] = { x = x, y = y }
		end
	end
	return self
end

function M:in_bounds(x, y)
	return x >= 1 and y >= 1 and x <= self.w and y <= self.h
end

function M:cell(x, y)
	if not self:in_bounds(x, y) then return nil end
	return self.cells[y][x]
end

function M:playable(x, y)
	local c = self:cell(x, y)
	return c ~= nil and not c.void
end

function M:piece(x, y)
	local c = self:cell(x, y)
	return c and c.piece or nil
end

function M:new_piece(id, kind)
	local p = { uid = self.next_uid, id = id, kind = kind or "base" }
	self.next_uid = self.next_uid + 1
	return p
end

function M:place(x, y, piece)
	local c = self.cells[y][x]
	c.piece = piece
	if piece then
		piece.x, piece.y = x, y
	end
	return piece
end

function M:spawn(x, y, id, kind)
	return self:place(x, y, self:new_piece(id, kind))
end

function M:remove(x, y)
	local c = self.cells[y][x]
	local p = c.piece
	c.piece = nil
	return p
end

function M:move(x1, y1, x2, y2)
	local p = self:remove(x1, y1)
	self:place(x2, y2, p)
	return p
end

function M:swap(x1, y1, x2, y2)
	local a = self.cells[y1][x1].piece
	local b = self.cells[y2][x2].piece
	self:place(x1, y1, b)
	self:place(x2, y2, a)
end

--- True when the cell can hold a piece (playable and not occupied by a blocker)
function M:holds_piece(x, y)
	local c = self:cell(x, y)
	return c ~= nil and not c.void and c.blocker == nil
end

--- A piece is locked when frost/vines/corruption sit on it.
function M:locked(x, y)
	local c = self:cell(x, y)
	return c ~= nil and (c.cover ~= nil or c.corrupt == true)
end

--- The player can pick up the piece at x,y
function M:movable(x, y)
	local c = self:cell(x, y)
	return c ~= nil and not c.void and c.blocker == nil and c.piece ~= nil and c.cover == nil and not c.corrupt
end

--- Pieces that fall with gravity (locked pieces stay in place)
function M:falls(x, y)
	return self:movable(x, y)
end

--- Static cells stop falling pieces.
function M:obstructs(x, y)
	local c = self:cell(x, y)
	if c == nil or c.void or c.blocker then return true end
	if c.piece and (c.cover or c.corrupt) then return true end
	return false
end

function M.matchable(piece)
	return piece ~= nil and (piece.kind == "base" or piece.kind == "charged")
end

function M:empty(x, y)
	local c = self:cell(x, y)
	return c ~= nil and not c.void and c.blocker == nil and c.piece == nil
end

function M:each(fn)
	for y = 1, self.h do
		for x = 1, self.w do
			fn(self.cells[y][x], x, y)
		end
	end
end

function M:count(predicate)
	local n = 0
	self:each(function(c, x, y)
		if predicate(c, x, y) then n = n + 1 end
	end)
	return n
end

function M:find_uid(uid)
	for y = 1, self.h do
		for x = 1, self.w do
			local p = self.cells[y][x].piece
			if p and p.uid == uid then return p end
		end
	end
end

--- Top-most playable cell of a column: new pieces enter the board there.
function M:spawn_row(x)
	for y = 1, self.h do
		local c = self.cells[y][x]
		if not c.void then
			if c.blocker then return nil end
			return y
		end
	end
	return nil
end

local function copy(t)
	if type(t) ~= "table" then return t end
	local r = {}
	for k, v in pairs(t) do r[k] = copy(v) end
	return r
end

function M:clone()
	local b = setmetatable({ w = self.w, h = self.h, next_uid = self.next_uid, cells = {} }, M)
	for y = 1, self.h do
		b.cells[y] = {}
		for x = 1, self.w do
			b.cells[y][x] = copy(self.cells[y][x])
		end
	end
	b.portals = copy(self.portals)
	b.conveyors = copy(self.conveyors)
	return b
end

--- Compact text dump (useful in tests and bug reports)
local SHORT = { fire = "f", water = "w", earth = "e", air = "a" }
function M:dump()
	local rows = {}
	for y = 1, self.h do
		local r = {}
		for x = 1, self.w do
			local c = self.cells[y][x]
			local s
			if c.void then s = " "
			elseif c.blocker then s = c.blocker.hp > 1 and "R" or "r"
			elseif not c.piece then s = "."
			elseif c.piece.kind == "compound" then s = "*"
			else
				s = SHORT[c.piece.id] or "?"
				if c.piece.kind == "charged" then s = s:upper() end
			end
			r[#r + 1] = s
		end
		rows[#rows + 1] = table.concat(r)
	end
	return table.concat(rows, "\n")
end

--- Load pieces from rows of single-letter tokens ("fwea", uppercase = charged,
--- "." = leave empty, "#" = void, "r"/"R" handled by level_manager instead).
--- Compounds can be written as {x=, y=, id=} in `compounds`.
function M.from_rows(rows, compounds)
	local LONG = { f = "fire", w = "water", e = "earth", a = "air" }
	local b = M.new(#rows[1], #rows)
	for y, row in ipairs(rows) do
		for x = 1, #row do
			local ch = row:sub(x, x)
			local id = LONG[ch:lower()]
			if ch == "#" then
				b.cells[y][x].void = true
			elseif id then
				b:spawn(x, y, id, ch:match("%u") and "charged" or "base")
			end
		end
	end
	for _, c in ipairs(compounds or {}) do
		assert(elements.is_compound(c.id), "unknown compound " .. tostring(c.id))
		b:spawn(c.x, c.y, c.id, "compound")
	end
	return b
end

return M
