-- Structural and theoretical-feasibility checks for level definitions.
-- This does NOT prove a level is fun or balanced: see tests/simulate.lua for
-- automated play-throughs and docs/BALANCE.md for real play-testing notes.
local elements = require "data.elements"
local recipes = require "data.recipes"
local patterns = require "data.obstacle_patterns"
local presets = require "data.board_presets"
local tutorials = require "data.tutorial_data"
local objectives = require "scripts.objectives"
local level_manager = require "scripts.level_manager"
local terrain = require "scripts.terrain"
local gravity = require "scripts.gravity"
local match = require "scripts.match"
local moves = require "scripts.moves"
local rng_mod = require "scripts.rng"

local M = {}

local CLEAR_IDS = { rock = true, frost = true, vine = true, corruption = true }

-- rough number of moves needed per objective unit (used for the move budget check)
local COST = { collect = 0.25, charge = 1, create = { 2, 4 }, activate = { 3, 5 }, clear = 0.5 }

local function err(list, def, msg, ...)
	list[#list + 1] = ("level %s: " .. msg):format(tostring(def and def.id), ...)
end

--- Can `id` (compound) be produced with the given base elements?
function M.producible(id, available)
	for base in pairs(recipes.base_requirements(id)) do
		if not available[base] then return false end
	end
	return true
end

function M.validate(def)
	local errors, warnings = {}, {}
	if type(def) ~= "table" then
		return { "level is not a table" }, {}
	end
	if type(def.id) ~= "number" then err(errors, def, "missing numeric id") end
	if type(def.name) ~= "string" or #def.name == 0 then err(errors, def, "missing name") end
	if type(def.world) ~= "number" or def.world < 1 or def.world > 3 then err(errors, def, "invalid world") end
	if type(def.moves) ~= "number" or def.moves < 5 then err(errors, def, "invalid moves") end
	if type(def.seed) ~= "number" then err(errors, def, "missing seed") end

	local available = {}
	if type(def.elements) ~= "table" or #def.elements < 3 then
		err(errors, def, "needs at least 3 elements")
	else
		for _, e in ipairs(def.elements) do
			if not elements.is_base(e) then err(errors, def, "unknown element %s", tostring(e)) end
			available[e] = true
		end
	end
	for k in pairs(def.weights or {}) do
		if not available[k] then err(errors, def, "weight for unused element %s", k) end
	end

	-- layout ----------------------------------------------------------------
	for _, layer in ipairs(def.layers or {}) do
		if not patterns.get(layer.pattern) then err(errors, def, "unknown pattern %s", tostring(layer.pattern)) end
		if not level_manager.CODES[layer.tile] then err(errors, def, "unknown tile %s", tostring(layer.tile)) end
	end
	if def.layout then
		if #def.layout ~= 8 then err(errors, def, "layout must have 8 rows") end
		for y, row in ipairs(def.layout) do
			if #row ~= 8 then err(errors, def, "layout row %d must have 8 columns", y) end
			for x = 1, #row do
				if not level_manager.CODES[row:sub(x, x)] then err(errors, def, "invalid code at %d,%d", x, y) end
			end
		end
	end
	-- overlapping pattern layers
	if def.layers and #def.layers > 1 then
		local seen = {}
		for _, layer in ipairs(def.layers) do
			local pat = patterns.get(layer.pattern) or {}
			for y, row in ipairs(pat) do
				for x = 1, #row do
					if row:sub(x, x) == "x" then
						local k = y * 64 + x
						if seen[k] then err(errors, def, "pattern layers overlap at %d,%d", x, y) end
						seen[k] = true
					end
				end
			end
		end
	end
	if #errors > 0 then return errors, warnings end

	local ok_shell, board = pcall(level_manager.build_shell, def)
	if not ok_shell then
		err(errors, def, "cannot build board: %s", tostring(board))
		return errors, warnings
	end

	-- obstacle inventory
	local inv = { rock = 0, frost = 0, vine = 0, corruption = 0, cells = 0, locked = 0 }
	board:each(function(c)
		if not c.void then inv.cells = inv.cells + 1 end
		if c.blocker and c.blocker.type == "rock" then inv.rock = inv.rock + 1 end
		if c.cover and c.cover.type == "frost" then inv.frost = inv.frost + c.cover.hp end
		if c.cover and c.cover.type == "vine" then inv.vine = inv.vine + 1 end
		if c.corrupt then inv.corruption = inv.corruption + 1 end
		if c.cover or c.corrupt then inv.locked = inv.locked + 1 end
		if c.portal and (c.blocker or c.void) then err(errors, def, "portal on a blocked cell") end
	end)
	if inv.cells < 40 then err(errors, def, "board too small (%d cells)", inv.cells) end
	if inv.locked > 20 then err(warnings, def, "%d locked pieces at start", inv.locked) end

	-- goals ------------------------------------------------------------------
	if type(def.goals) ~= "table" or #def.goals == 0 then
		err(errors, def, "no goals")
	end
	local budget = 0
	local any_power = false
	for _, r in ipairs(recipes.list) do
		if M.producible(r.result, available) then any_power = true end
	end
	for i, g in ipairs(def.goals or {}) do
		if not objectives.TYPES[g.type] then err(errors, def, "goal %d: unknown type %s", i, tostring(g.type)) end
		if type(g.count) ~= "number" or g.count < 1 then err(errors, def, "goal %d: invalid count", i) end
		if g.type == "collect" then
			if not available[g.id] then err(errors, def, "goal %d: collects unavailable element %s", i, tostring(g.id)) end
			budget = budget + COST.collect * g.count
		elseif g.type == "charge" then
			budget = budget + COST.charge * g.count
		elseif g.type == "create" or g.type == "activate" then
			if not elements.is_compound(g.id) then
				err(errors, def, "goal %d: unknown compound %s", i, tostring(g.id))
			elseif not M.producible(g.id, available) then
				err(errors, def, "goal %d: %s cannot be produced with these elements", i, g.id)
			else
				local tier = elements.info[g.id].tier
				budget = budget + COST[g.type][tier] * g.count
			end
		elseif g.type == "clear" then
			if not CLEAR_IDS[g.id] then
				err(errors, def, "goal %d: unknown obstacle %s", i, tostring(g.id))
			elseif inv[g.id] < g.count then
				err(errors, def, "goal %d: needs %d %s but only %d exist", i, g.count, g.id, inv[g.id])
			end
			if g.id == "rock" and not any_power then err(errors, def, "rocks need powers but no recipe is possible") end
			budget = budget + COST.clear * g.count
		end
	end
	if def.moves and budget > def.moves then
		err(errors, def, "estimated minimum %.1f moves exceeds the limit %d", budget, def.moves)
	elseif def.moves and budget > def.moves * 0.8 then
		err(warnings, def, "tight move budget (%.1f of %d)", budget, def.moves)
	end

	-- terrain ----------------------------------------------------------------
	local t = def.terrain or {}
	for i, cv in ipairs(t.conveyors or {}) do
		if (cv.axis ~= "row" and cv.axis ~= "col") or type(cv.index) ~= "number" or cv.index < 1 or cv.index > 8 or (cv.dir ~= 1 and cv.dir ~= -1) then
			err(errors, def, "conveyor %d invalid", i)
		elseif not terrain.line_is_safe(board, cv) then
			err(errors, def, "conveyor %d crosses an immovable cell", i)
		end
	end
	for i, p in ipairs(t.portals or {}) do
		if not (p.from and p.to and board:playable(p.from.x, p.from.y) and board:playable(p.to.x, p.to.y)) then
			err(errors, def, "portal %d has invalid cells", i)
		elseif p.from.x == p.to.x and p.from.y == p.to.y then
			err(errors, def, "portal %d enters and exits on the same cell", i)
		end
	end
	if t.corruption then
		if inv.corruption == 0 then err(errors, def, "corruption configured but no corrupted cell") end
		if (t.corruption.limit or 0) < 0 then err(errors, def, "corruption limit must be >= 0") end
	end
	if inv.corruption > 0 and not t.corruption then
		err(warnings, def, "corrupted cells without spread configuration (static)")
	end

	-- tutorial & preset --------------------------------------------------------
	if def.tutorial and not tutorials.get(def.tutorial) then err(errors, def, "unknown tutorial %s", def.tutorial) end
	if def.board_preset then
		local pr = presets[def.board_preset]
		if not pr then
			err(errors, def, "unknown preset %s", def.board_preset)
		else
			for y, row in ipairs(pr.rows) do
				for x = 1, #row do
					local ch = row:sub(x, x)
					if ch ~= "." then
						local id = ({ f = "fire", w = "water", e = "earth", a = "air" })[ch:lower()]
						if not id then err(errors, def, "preset invalid char '%s'", ch) end
						if id and not available[id] then err(errors, def, "preset uses unavailable %s", id) end
						if not board:holds_piece(x, y) then err(errors, def, "preset piece on blocked cell %d,%d", x, y) end
					end
				end
			end
		end
	end
	if #errors > 0 then return errors, warnings end

	-- generated board ----------------------------------------------------------
	local b = level_manager.build_board(def, rng_mod.new(def.seed))
	if match.has_any(b) then err(errors, def, "starting board contains a match") end
	if not moves.any(b) then err(errors, def, "starting board has no valid move") end
	local missing = 0
	b:each(function(c, x, y)
		if b:holds_piece(x, y) and not c.piece then missing = missing + 1 end
	end)
	if missing > 0 then err(errors, def, "%d cells without pieces", missing) end
	local unreachable = gravity.unreachable_cells(b)
	if #unreachable > 0 then
		err(errors, def, "%d cells can never be refilled by gravity (first at %d,%d)", #unreachable, unreachable[1].x, unreachable[1].y)
	end
	return errors, warnings
end

--- Validate a list of levels (ids must be unique and sequential).
function M.validate_all(list)
	local errors, warnings = {}, {}
	for i, def in ipairs(list) do
		if def.id ~= i then errors[#errors + 1] = ("level index %d has id %s"):format(i, tostring(def.id)) end
		local e, w = M.validate(def)
		for _, x in ipairs(e) do errors[#errors + 1] = x end
		for _, x in ipairs(w) do warnings[#warnings + 1] = x end
	end
	return errors, warnings
end

return M
