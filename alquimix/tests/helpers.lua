-- Shared helpers for tests: build games on hand-written boards.
local Board = require "scripts.board"
local Game = require "scripts.game_rules"
local objectives = require "scripts.objectives"

local M = {}

--- A minimal level definition.
function M.level(t)
	t = t or {}
	return {
		id = t.id or 999, world = 1, name = "Teste", moves = t.moves or 20, seed = t.seed or 42,
		elements = t.elements or { "fire", "water", "earth", "air" },
		goals = t.goals or { { type = "collect", id = "fire", count = 99 } },
		terrain = t.terrain,
	}
end

--- Game whose board is replaced by `rows` (see Board.from_rows).
--- `fill` sequence controls new pieces entering from the top (cycled).
function M.game(rows, opts)
	opts = opts or {}
	local def = M.level(opts)
	local g = Game.new(def, { seed = def.seed, discovered = opts.discovered })
	g.board = Board.from_rows(rows, opts.compounds)
	for _, cv in ipairs(opts.conveyors or {}) do g.board.conveyors[#g.board.conveyors + 1] = cv end
	for _, p in ipairs(opts.portals or {}) do g.board.portals[#g.board.portals + 1] = p end
	if opts.goals then g.objectives = objectives.new(opts.goals) end
	if opts.fill then
		local i = 0
		g.spawn_id = function()
			i = i % #opts.fill + 1
			return opts.fill[i]
		end
	end
	return g
end

-- A filler sequence that never forms runs by itself when stacked in columns.
M.SAFE_FILL = { "fire", "water", "earth", "air", "water", "fire", "air", "earth" }

return M
