local T = require "tests.lib.testlib"
local level_manager = require "scripts.level_manager"
local validator = require "scripts.level_validator"
local Game = require "scripts.game_rules"
local match = require "scripts.match"
local moves = require "scripts.moves"

T.test("25. All 60 levels pass structural validation", function()
	local list = level_manager.all()
	T.eq(#list, 60)
	local errors = validator.validate_all(list)
	if #errors > 0 then error(table.concat(errors, "\n")) end
end)

T.test("25b. Levels are individual (no duplicated configuration)", function()
	local seen = {}
	for _, d in ipairs(level_manager.all()) do
		local sig = table.concat({
			d.moves, d.seed, #d.goals,
			(d.goals[1].type or "") .. (d.goals[1].id or ""),
			tostring(d.layout and table.concat(d.layout)), tostring(d.layers and d.layers[1] and d.layers[1].pattern),
		}, "|")
		T.no(seen[sig], "duplicate level config " .. d.id)
		seen[sig] = true
		local w = level_manager.world_of(d.id)
		T.eq(w.id, d.world, "world of level " .. d.id)
	end
end)

T.test("25c. Mechanics are introduced at the designed levels", function()
	local first = {}
	for _, d in ipairs(level_manager.all()) do
		local t = d.terrain or {}
		local function mark(k) if not first[k] then first[k] = d.id end end
		for _, e in ipairs(d.elements) do if e == "air" then mark("air") end end
		if t.conveyors then mark("conveyor") end
		if t.portals then mark("portal") end
		if t.corruption then mark("corruption") end
		local g = level_manager.layout_grid(d)
		for y = 1, 8 do
			for x = 1, 8 do
				local c = g[y][x]
				if c == "r" or c == "R" then mark("rock") end
				if c == "R" then mark("rock_hard") end
				if c == "i" or c == "I" then mark("frost") end
				if c == "v" then mark("vine") end
			end
		end
	end
	T.eq(first.air, 7)
	T.eq(first.rock, 5)
	T.eq(first.frost, 11)
	T.eq(first.vine, 13)
	T.eq(first.rock_hard, 21)
	T.eq(first.conveyor, 31)
	T.eq(first.portal, 41)
	T.eq(first.corruption, 51)
end)

T.test("25d. Every level starts stable, playable and deterministic", function()
	for _, d in ipairs(level_manager.all()) do
		local a = Game.new(d)
		local b = Game.new(d)
		T.no(match.has_any(a.board), "level " .. d.id .. " starts with a match")
		T.ok(moves.any(a.board), "level " .. d.id .. " has a move")
		T.eq(a.board:dump(), b.board:dump(), "level " .. d.id .. " deterministic")
	end
end)

T.test("Validator rejects broken definitions", function()
	local bad = {
		id = 1, world = 1, name = "x", moves = 10, seed = 1, elements = { "fire", "water", "earth" },
		goals = { { type = "create", id = "plasma", count = 1 }, { type = "clear", id = "rock", count = 3 } },
	}
	local e = validator.validate(bad)
	T.ok(#e >= 2, "plasma needs air; no rocks exist")
	local e2 = validator.validate({
		id = 2, world = 1, name = "y", moves = 20, seed = 2, elements = { "fire", "water", "earth", "air" },
		goals = { { type = "collect", id = "fire", count = 5 } },
		layout = { "rrrrrrrr", "........", "........", "........", "........", "........", "........", "........" },
	})
	T.ok(#e2 >= 1, "cells under a full rock bar can never be refilled")
	local e3 = validator.validate({
		id = 3, world = 1, name = "z", moves = 20, seed = 3, elements = { "fire", "water", "earth", "air" },
		goals = { { type = "collect", id = "fire", count = 5 } },
		layout = { "........", "....i...", "........", "........", "........", "........", "........", "........" },
		terrain = { conveyors = { { axis = "row", index = 2, dir = 1 } } },
	})
	T.ok(#e3 >= 1, "conveyor over frost")
end)

return T
