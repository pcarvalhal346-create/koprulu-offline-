-- Automated play-tester: a greedy, objective-aware bot (scripts/autoplay.lua)
-- plays every level with several seeds and reports win rate and moves left.
-- It is a balancing aid, not a substitute for human play-testing (the bot looks
-- one move ahead and does not plan the way a person does).
--
-- Usage (project root):  luajit tests/simulate.lua [runs_per_level] [first_level] [last_level]
package.path = "./?.lua;" .. package.path

local level_manager = require "scripts.level_manager"
local Game = require "scripts.game_rules"
local bot = require "scripts.autoplay"

local M = {}

function M.play(def, seed)
	local game = Game.new(def, { seed = seed })
	local guard = 0
	while game.status == "playing" and guard < 200 do
		guard = guard + 1
		local a = bot.choose(game)
		if not a then break end
		bot.apply(game, a)
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
