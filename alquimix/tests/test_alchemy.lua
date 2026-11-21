local T = require "tests.lib.testlib"
local H = require "tests.helpers"
local recipes = require "data.recipes"
local alchemy = require "scripts.alchemy"
local elements = require "data.elements"

local function P(id, kind) return { id = id, kind = kind or "base" } end

T.test("7. Fusion Fogo carregado + Água -> Vapor at the destination", function()
	local g = H.game({
		"aeaw",
		"Fwea",
		"eafe",
	}, { fill = H.SAFE_FILL, goals = { { type = "create", id = "steam", count = 1 } } })
	local before = g.moves_left
	local r = g:try_swap(1, 2, 2, 2)
	T.ok(r.ok)
	T.eq(r.kind, "fusion")
	T.eq(g.moves_left, before - 1, "fusion consumes a move")
	local f = T.has_event(r.events, "fusion")
	T.eq(f.result, "steam")
	T.eq(f.to.x, 2)
	T.ok(T.has_event(r.events, "discovery"), "first fusion is a discovery")
	T.ok(g.status == "won", "create goal completed")
	-- the compound is on the destination column (gravity may only move it down)
	local found
	g.board:each(function(c, x) if c.piece and c.piece.id == "steam" then found = x end end)
	T.eq(found, 2)
end)

T.test("7b. Fusion ingredients do not count for collect", function()
	local g = H.game({
		"aeaw",
		"Fwea",
		"eafe",
	}, { fill = { "earth" }, goals = { { type = "collect", id = "fire", count = 5 } } })
	g:try_swap(1, 2, 2, 2)
	T.eq(g.objectives.goals[1].progress, 0)
end)

T.test("8. Fusion Vapor + Ar -> Tempestade (advanced fusion creates a new compound)", function()
	local g = H.game({
		"eaew",
		"w.aw",
		"efea",
	}, { compounds = { { x = 2, y = 2, id = "steam" } }, fill = H.SAFE_FILL })
	local r = g:try_swap(2, 2, 3, 2)
	T.ok(r.ok)
	local f = T.has_event(r.events, "fusion")
	T.eq(f.result, "storm")
	T.no(T.has_event(r.events, "activate"), "steam power is not triggered")
	T.no(T.has_event(r.events, "power"))
end)

T.test("9. All 10 recipes resolve in any ingredient order", function()
	T.eq(#recipes.list, 10)
	for _, r in ipairs(recipes.list) do
		T.eq(recipes.find(r.a, r.b), r.result, r.a .. "+" .. r.b)
		T.eq(recipes.find(r.b, r.a), r.result, r.b .. "+" .. r.a)
		local ka = elements.is_compound(r.a) and "compound" or "charged"
		local kb = elements.is_compound(r.b) and "compound" or "base"
		T.eq(alchemy.fusion_result(P(r.a, ka), P(r.b, kb)), r.result)
		T.eq(alchemy.fusion_result(P(r.b, kb), P(r.a, ka)), r.result)
	end
end)

T.test("9b. Every recipe works inside a real game turn", function()
	for _, r in ipairs(recipes.list) do
		local comps = {}
		local rows = { "eaew", "..aw", "efea" }
		local ka = elements.is_compound(r.a)
		if ka then comps[1] = { x = 1, y = 2, id = r.a } end
		local g = H.game(rows, { compounds = comps, fill = H.SAFE_FILL })
		if not ka then g.board:spawn(1, 2, r.a, "charged") end
		g.board:spawn(2, 2, r.b, elements.is_compound(r.b) and "compound" or "base")
		local res = g:try_swap(1, 2, 2, 2)
		T.ok(res.ok, "fusion " .. r.result)
		T.eq(T.has_event(res.events, "fusion").result, r.result)
	end
end)

T.test("10. Missing recipes and base+base never fuse", function()
	T.eq(recipes.find("fire", "fire"), nil)
	T.eq(recipes.find("storm", "air"), nil)
	T.eq(alchemy.fusion_result(P("fire"), P("water")), nil, "two normal elements")
	T.eq(alchemy.fusion_result(P("steam", "compound"), P("lava", "compound")), nil, "two compounds")
	T.eq(alchemy.fusion_result(P("fire", "charged"), P("fire")), nil, "same element")
	T.eq(alchemy.fusion_result(P("steam", "compound"), P("fire")), nil, "no recipe")
	T.eq(alchemy.fusion_result(P("fire", "charged"), P("water", "charged")), "steam", "charged+charged allowed")
	T.eq(alchemy.fusion_result(P("ice", "compound"), P("fire", "charged")), "crystal", "compound+charged allowed")
end)

T.test("10b. Discoveries are only announced the first time", function()
	local g = H.game({ "aeaw", "Fwea", "eafe" }, { fill = H.SAFE_FILL, discovered = { ["fire|water"] = true } })
	local r = g:try_swap(1, 2, 2, 2)
	T.ok(r.ok)
	T.no(T.has_event(r.events, "discovery"))
end)

-- --------------------------------------------------------------- powers --

local function power_game(id, extra)
	local rows = {
		"fwea",
		"weaf",
		"eafw",
		"afwe",
	}
	local g = H.game(rows, { fill = H.SAFE_FILL, goals = { { type = "activate", id = id, count = 1 }, { type = "collect", id = "fire", count = 99 } } })
	g.board:remove(2, 2)
	g.board:spawn(2, 2, id, "compound")
	if extra then extra(g) end
	return g
end

local function removed_cells(events)
	local set = {}
	for _, e in ipairs(events) do
		if e.type == "remove" and e.reason ~= "match" then set[e.x .. "," .. e.y] = true end
	end
	return set
end

T.test("11a. Vapor clears its column", function()
	local g = power_game("steam")
	local r = g:activate(2, 2)
	T.ok(r.ok)
	local rm = removed_cells(r.events)
	T.ok(rm["2,1"] and rm["2,3"] and rm["2,4"])
	T.no(rm["1,2"])
	T.eq(g.objectives.goals[1].progress, 1)
end)

T.test("11b. Plasma clears its row", function()
	local r = power_game("plasma"):activate(2, 2)
	local rm = removed_cells(r.events)
	T.ok(rm["1,2"] and rm["3,2"] and rm["4,2"])
	T.no(rm["2,1"])
end)

T.test("11c. Tempestade clears row and column", function()
	local r = power_game("storm"):activate(2, 2)
	local rm = removed_cells(r.events)
	T.ok(rm["1,2"] and rm["4,2"] and rm["2,1"] and rm["2,4"])
end)

T.test("11d. Lava clears 3x3 and deals double damage to rocks", function()
	local g = power_game("lava", function(g)
		g.board:remove(3, 3)
		g.board:cell(3, 3).blocker = { type = "rock", hp = 2, max_hp = 2 }
	end)
	g.objectives:add("collect", "fire", 0)
	local r = g:activate(2, 2)
	local rm = removed_cells(r.events)
	T.ok(rm["1,1"] and rm["3,1"] and rm["1,3"])
	T.no(rm["4,4"])
	T.eq(g.board:cell(3, 3).blocker, nil, "resistant rock destroyed by lava")
end)

T.test("11e. Gelo clears 2x2 and removes a frost layer", function()
	local g = power_game("ice", function(g)
		g.board:cell(3, 3).cover = { type = "frost", hp = 2 }
	end)
	local r = g:activate(2, 2)
	local rm = removed_cells(r.events)
	T.ok(rm["3,2"] and rm["2,3"])
	T.no(rm["1,1"])
	T.eq(g.board:cell(3, 3).cover.hp, 1)
end)

T.test("11f. Vida turns up to 4 neighbours into Terra", function()
	local g = power_game("life")
	local r = g:activate(2, 2)
	local tr = T.has_event(r.events, "transform")
	T.ok(tr)
	T.ok(#tr.items <= 4 and #tr.items >= 1)
	for _, it in ipairs(tr.items) do T.eq(it.to, "earth") end
end)

T.test("11g. Floresta transforms up to 8 normal pieces deterministically", function()
	local a = power_game("forest")
	local b = power_game("forest")
	local ra = T.has_event(a:activate(2, 2).events, "transform")
	local rb = T.has_event(b:activate(2, 2).events, "transform")
	T.ok(#ra.items <= 8 and #ra.items > 0)
	T.eq(#ra.items, #rb.items)
	for i = 1, #ra.items do
		T.eq(ra.items[i].x, rb.items[i].x)
		T.eq(ra.items[i].y, rb.items[i].y)
	end
end)

T.test("11h. Poeira damages every obstacle", function()
	local g = power_game("dust", function(g)
		g.board:cell(4, 4).cover = { type = "vine", hp = 1 }
		g.board:cell(1, 1).corrupt = true
		g.board:remove(4, 1)
		g.board:cell(4, 1).blocker = { type = "rock", hp = 2, max_hp = 2 }
	end)
	g:activate(2, 2)
	T.eq(g.board:cell(4, 4).cover, nil)
	T.eq(g.board:cell(1, 1).corrupt, nil)
	T.eq(g.board:cell(4, 1).blocker.hp, 1)
end)

T.test("11i. Obsidiana destroys every rock", function()
	local g = power_game("obsidian", function(g)
		for _, c in ipairs({ { 4, 4 }, { 1, 4 } }) do
			g.board:remove(c[1], c[2])
			g.board:cell(c[1], c[2]).blocker = { type = "rock", hp = 2, max_hp = 2 }
		end
	end)
	g.objectives = require("scripts.objectives").new({ { type = "clear", id = "rock", count = 2 } })
	g:activate(2, 2)
	T.eq(g.board:cell(4, 4).blocker, nil)
	T.eq(g.board:cell(1, 4).blocker, nil)
	T.eq(g.status, "won")
end)

T.test("11j. Cristal asks for a choice and removes that element", function()
	local g = power_game("crystal")
	local first = g:activate(2, 2)
	T.no(first.ok)
	T.ok(first.need_choice)
	T.ok(#first.options >= 3)
	local before = g.moves_left
	local r = g:activate(2, 2, "fire")
	T.ok(r.ok)
	T.eq(g.moves_left, before - 1)
	local n = 0
	for _, e in ipairs(r.events) do
		if e.type == "remove" and e.reason == "crystal" then
			T.eq(e.id, "fire")
			n = n + 1
		end
	end
	T.ok(n >= 3)
end)

T.test("11k. Compounds are immune to other powers", function()
	local g = power_game("plasma", function(g)
		g.board:remove(4, 2)
		g.board:spawn(4, 2, "lava", "compound")
	end)
	g:activate(2, 2)
	local found = false
	g.board:each(function(c) if c.piece and c.piece.id == "lava" then found = true end end)
	T.ok(found)
end)

return T
