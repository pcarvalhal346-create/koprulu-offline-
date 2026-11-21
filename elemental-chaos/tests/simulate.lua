-- Automated play-tester: a greedy, objective-aware bot plays every level with
-- several seeds and reports win rate and moves left. It is a balancing aid,
-- not a substitute for human play-testing (the bot looks one move ahead and
-- never plans multi-step fusions the way a person does).
--
-- Usage (project root):  luajit tests/simulate.lua [runs_per_level] [first_level] [last_level]
package.path = "./?.lua;" .. package.path

local level_manager = require "scripts.level_manager"
local Game = require "scripts.game_rules"
local moves_mod = require "scripts.moves"
local recipes = require "data.recipes"
local rng_mod = require "scripts.rng"
local elements = require "data.elements"

local M = {}

local function wanted(game)
	local direct, pre = {}, {}
	local clear = false
	for _, g in ipairs(game.objectives:remaining()) do
		if g.type == "create" or g.type == "activate" then
			direct[g.id] = g.type
			local r = recipes.producing(g.id)
			if r then
				if elements.is_compound(r.a) then pre[r.a] = true end
				if elements.is_compound(r.b) then pre[r.b] = true end
			end
		elseif g.type == "clear" then
			clear = true
		end
	end
	return direct, pre, clear
end

function M.value(game)
	if game.status == "won" then return 1e6 + game.moves_left * 1000 end
	local v = 0
	for _, g in ipairs(game.objectives.goals) do
		v = v + math.min(1, g.progress / g.count) * 1000
	end
	local direct, pre, clear = wanted(game)
	local charged = 0
	game.board:each(function(c)
		local p = c.piece
		if not p then return end
		if p.kind == "compound" then
			if direct[p.id] == "activate" then v = v + 180
			elseif pre[p.id] then v = v + 140
			elseif clear then v = v + 50
			else v = v + 10 end
		elseif p.kind == "charged" then
			charged = charged + 1
		end
	end)
	v = v + math.min(charged, 6) * 12
	return v + game.score * 0.002
end

--- All candidate actions for the current state.
function M.actions(game)
	local list = {}
	for _, m in ipairs(moves_mod.find(game.board)) do
		list[#list + 1] = { kind = "swap", a = m.a, b = m.b }
		if m.kind == "fusion" then
			list[#list + 1] = { kind = "swap", a = m.b, b = m.a }
		end
	end
	for _, c in ipairs(moves_mod.compounds(game.board)) do
		if c.id == "crystal" then
			for _, o in ipairs(game:crystal_options()) do
				list[#list + 1] = { kind = "activate", x = c.x, y = c.y, choice = o }
			end
		else
			list[#list + 1] = { kind = "activate", x = c.x, y = c.y }
		end
	end
	return list
end

function M.apply(game, a)
	if a.kind == "swap" then
		return game:try_swap(a.a.x, a.a.y, a.b.x, a.b.y)
	end
	return game:activate(a.x, a.y, a.choice)
end

function M.choose(game)
	local best, best_v = nil, -math.huge
	for _, a in ipairs(M.actions(game)) do
		local c = game:clone()
		-- the bot must not see future refills: evaluate with an unrelated generator
		c.rng = rng_mod.new(game.rng.state + 104729)
		local r = M.apply(c, a)
		if r.ok then
			local v = M.value(c)
			if v > best_v then best, best_v = a, v end
		end
	end
	return best
end

function M.play(def, seed)
	local game = Game.new(def, { seed = seed })
	local guard = 0
	while game.status == "playing" and guard < 200 do
		guard = guard + 1
		local a = M.choose(game)
		if not a then break end
		M.apply(game, a)
	end
	return game
end

function M.run(runs, first, last)
	runs = runs or 4
	local report = {}
	for _, def in ipairs(level_manager.all()) do
		if def.id >= (first or 1) and def.id <= (last or 60) then
			local wins, left, stars, shuffles, fraction = 0, 0, 0, 0, 0
			for k = 1, runs do
				local g = M.play(def, def.seed + (k - 1) * 7919)
				if g.status == "won" then
					wins = wins + 1
					left = left + g.moves_left
					stars = stars + g.stars
				end
				shuffles = shuffles + g.stats.shuffles
				fraction = fraction + g.objectives:fraction()
			end
			local row = {
				id = def.id, moves = def.moves, win_rate = wins / runs,
				avg_left = wins > 0 and left / wins or 0, avg_stars = wins > 0 and stars / wins or 0,
				progress = fraction / runs, shuffles = shuffles,
			}
			report[#report + 1] = row
			io.write(("level %2d  moves %2d  wins %d/%d  avg left %5.1f  stars %.1f  progress %3d%%  shuffles %d\n"):format(
				row.id, row.moves, wins, runs, row.avg_left, row.avg_stars, math.floor(row.progress * 100 + 0.5), shuffles))
			io.flush()
		end
	end
	return report
end

if arg and arg[0] and arg[0]:find("simulate") then
	M.run(tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]))
end

return M
