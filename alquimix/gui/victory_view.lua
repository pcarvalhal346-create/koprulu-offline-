-- End-of-level screens: victory (stars, score count-up), defeat (missing
-- objectives), discovery card and the world-finale / campaign-end sequences.
local ui = require "gui.ui"
local popup = require "gui.popup"
local lumi_view = require "gui.lumi_view"
local goal_icons = require "gui.goal_icons"
local book = require "gui.alchemy_book"
local lumi = require "scripts.lumi"
local recipes = require "data.recipes"
local L = require "scripts.localization"

local M = {}

local V3 = vmath.vector3

--- data: { level, stars, score, bonus, new_best, has_next }
--- handlers: { next, replay, map }
function M.victory(ctx, data, handlers)
	local line = lumi.line("victory")
	local lv
	return popup.open({
		w = 640, h = 880, title = L("victory.title"), y = ui.metrics().cy - 60,
		on_back = function(p) p:close() handlers.map() end,
		build = function(p)
			local m = ui.metrics()
			lv = lumi_view.create(p.root, p.cx - 236, p.cy + p.h / 2 + 10, 0.4)
			lv:set_mood("victory")
			ctx.audio.play("victory")
			ctx.effects.confetti(m, 60)
			local top = p.h / 2
			for s = 1, 3 do
				local x = (s - 2) * 150
				local y = top - 170 + (s == 2 and 26 or 0)
				ui.box(x, y, 130, 130, "ui", "star_empty", { parent = p.panel })
				if s <= data.stars then
					local st = ui.box(x, y, 130, 130, "ui", "star_full", { parent = p.panel })
					gui.set_scale(st, V3(0.01, 0.01, 1))
					gui.animate(st, "scale", V3(1, 1, 1), gui.EASING_OUTBACK, 0.4, 0.35 + s * 0.35, function()
						ctx.audio.play("star", { speed = 1 + s * 0.12 })
						ctx.effects.burst(p.cx + x, p.cy + y, { count = 14, sprite = "fx_star", color = ui.hex("gold"), speed = 260 })
					end)
				end
			end
			ui.text(0, top - 300, L("victory.score"), { parent = p.panel, size = 28, color = "#D9C8FF" })
			p.score_node = ui.text(0, top - 360, "0", { parent = p.panel, font = "title", size = 64, color = "gold" })
			p.score_t, p.score_target = 0, data.score
			if data.bonus and data.bonus > 0 then
				ui.text(0, top - 420, L("victory.bonus", { n = data.bonus }), { parent = p.panel, size = 24, color = "green" })
			end
			if data.new_best then
				local nb = ui.text(0, top - 465, L("victory.new_best"), { parent = p.panel, font = "title", size = 30, color = "pink" })
				ui.pulse(nb, 1.1, 0.5)
			end
			ui.text(0, top - 540, line, { parent = p.panel, size = 25, width = 540 })
			local by = -p.h / 2 + 200
			if data.has_next then
				local b = p.buttons:add(p.panel, 0, by, 420, 110, L("victory.next"), "primary", function() p:close() handlers.next() end, { icon = "play", size = 36 })
				ui.pulse(b.node, 1.04, 0.7)
			end
			p.buttons:add(p.panel, -110, by - 125, 200, 92, L("victory.replay"), "secondary", function() p:close() handlers.replay() end, { icon = "retry", size = 26 })
			p.buttons:add(p.panel, 110, by - 125, 200, 92, L("victory.map"), "secondary", function() p:close() handlers.map() end, { icon = "map", size = 26 })
		end,
		update = function(p, dt)
			if lv then lv:update(dt) end
			if p.score_t < 1.4 then
				p.score_t = p.score_t + dt
				local v = math.floor(p.score_target * math.min(1, p.score_t / 1.2))
				gui.set_text(p.score_node, tostring(v))
			end
		end,
		on_destroy = function() if lv then lv:destroy() end end,
	})
end

--- data: { remaining = { {type, id, left} }, goals = def.goals }
function M.defeat(ctx, data, handlers)
	local line = lumi.line("defeat")
	local lv
	local rows = #data.remaining
	return popup.open({
		w = 620, h = 560 + rows * 86, title = L("defeat.title"), y = ui.metrics().cy - 60,
		on_back = function(p) p:close() handlers.map() end,
		build = function(p)
			lv = lumi_view.create(p.root, p.cx - 226, p.cy + p.h / 2 + 10, 0.4)
			lv:set_mood("sad")
			ctx.audio.play("defeat")
			local top = p.h / 2
			ui.text(0, top - 110, line, { parent = p.panel, size = 26, width = 520 })
			ui.text(0, top - 200, L("defeat.missing"), { parent = p.panel, font = "title", size = 28, color = "gold" })
			for i, g in ipairs(data.remaining) do
				local y = top - 270 - (i - 1) * 86
				local row = ui.box(0, y, 500, 76, "ui", "goal_slot", { parent = p.panel, slice = 24 })
				local tex, anim = goal_icons.goal(g)
				ui.box(-210, 0, 60, 60, tex, anim, { parent = row })
				ui.text(-168, 2, L.goal(g, g.left), { parent = row, size = 26, pivot = gui.PIVOT_W })
				ui.pop_in(row, i * 0.08)
			end
			local by = -p.h / 2 + 190
			local b = p.buttons:add(p.panel, 0, by, 420, 110, L("defeat.retry"), "primary", function() p:close() handlers.retry() end, { icon = "retry", size = 34 })
			ui.pulse(b.node, 1.04, 0.7)
			p.buttons:add(p.panel, 0, by - 125, 300, 92, L("defeat.map"), "secondary", function() p:close() handlers.map() end, { icon = "map", size = 28 })
		end,
		update = function(_, dt) if lv then lv:update(dt) end end,
		on_destroy = function() if lv then lv:destroy() end end,
	})
end

--- Discovery card. on_close is called when the player continues.
function M.discovery(ctx, e, on_close)
	local r
	for _, x in ipairs(recipes.list) do if x.result == e.result then r = x end end
	local line = lumi.line("discovery")
	local lv
	ctx.audio.play("discovery")
	return popup.open({
		w = 640, h = 900, title = L("discovery.title"), auto_close = ctx.dev and ctx.dev.autoplay,
		on_close = function() if on_close then on_close() end end,
		on_back = function(p) p:close() end,
		build = function(p)
			lv = lumi_view.create(p.root, p.cx - 230, p.cy - p.h / 2 - 20, 0.42)
			lv:set_mood("surprised")
			local card = book.card(p.panel, 0, 150, r, { known = true, big = true })
			ui.pop_in(card, 0.15)
			ctx.effects.burst(p.cx, p.cy + 150, { count = 30, sprite = "fx_spark", color = ui.hex("gold"), speed = 420, size = 30 })
			ctx.effects.flash(p.cx, p.cy + 150, "fx_glow", 520, ui.hex("#FFF3C4"), 0.8)
			ui.text(0, -150, L("power." .. e.result), { parent = p.panel, size = 26, width = 540 })
			ui.text(60, -250, line, { parent = p.panel, size = 22, width = 440, color = "gold" })
			p.buttons:add(p.panel, 0, -p.h / 2 + 90, 360, 100, L("common.continue"), "primary", function() p:close() end, { icon = "check", size = 32 })
		end,
		update = function(p, dt)
			if lv then
				lv:update(dt)
				p.t = (p.t or 0) + dt
				if p.t > 0.9 and not p.happy then p.happy = true; lv:set_mood("happy") end
			end
		end,
		on_destroy = function() if lv then lv:destroy() end end,
	})
end

--- Crystal power: choose which element to remove.
function M.choose_element(ctx, options, on_choice)
	return popup.open({
		w = 600, h = 440, title = L("el.crystal"), closable = true,
		build = function(p)
			ui.text(0, 90, L("hud.choose_element"), { parent = p.panel, size = 28 })
			local n = #options
			for i, id in ipairs(options) do
				local x = (i - (n + 1) / 2) * 130
				local b = p.buttons:add(p.panel, x, -40, 120, 120, nil, "round", function()
					p:close()
					on_choice(id)
				end)
				ui.box(0, 4, 92, 92, "pieces", id, { parent = b.node })
			end
		end,
	})
end

--- World finale / campaign end: restored crystal, orbiting elements, Lumi.
function M.story(ctx, world, on_done)
	local lines = { L("story.world" .. world .. ".1"), L("story.world" .. world .. ".2") }
	if world == 3 then lines[3] = L("story.campaign_end") end
	local lv, crystal, orbit
	local idx = 1
	ctx.audio.play("discovery")
	return popup.open({
		w = 660, h = 1040, dim = 0.9,
		on_input = function(p, action_id, action)
			if action_id == hash("touch") and action.released and p.ready then
				idx = idx + 1
				if idx > #lines then
					p:close()
					if on_done then on_done() end
				else
					gui.set_text(p.line, lines[idx])
					lv:set_mood(idx == #lines and "victory" or "happy", 2)
					ctx.audio.play("lumi")
				end
			end
		end,
		build = function(p)
			local m = ui.metrics()
			local cy = 230
			ctx.effects.flash(p.cx, p.cy + cy, "fx_glow", 700, ui.hex(world == 1 and "#51D989" or (world == 2 and "#FF9A3C" or "#B593FF")), 1.6)
			crystal = ui.box(0, cy, 190, 190, "pieces", "crystal", { parent = p.panel })
			ui.pop_in(crystal, 0.2, 1)
			gui.animate(crystal, "euler.z", 8, gui.EASING_INOUTSINE, 1.4, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
			orbit = ui.container(p.panel, 0, cy)
			for i, id in ipairs({ "fire", "water", "earth", "air" }) do
				local a = (i - 1) * math.pi / 2
				local n = ui.box(math.cos(a) * 190, math.sin(a) * 190, 92, 92, "pieces", id, { parent = orbit })
				ui.pop_in(n, 0.3 + i * 0.15)
			end
			gui.animate(orbit, "euler.z", 360, gui.EASING_LINEAR, 6, 0, nil, gui.PLAYBACK_LOOP_FORWARD)
			for i = 1, 3 do
				timer.delay(0.4 * i, false, function()
					ctx.effects.burst(p.cx, p.cy + cy, { count = 24, sprite = i == 2 and "fx_star" or "fx_spark", color = ui.hex(({ "gold", "pink", "water" })[i]), speed = 420, size = 30 })
				end)
			end
			if world == 3 then
				ctx.effects.confetti(m, 80)
				ui.text(0, cy + 290, L("story.world3.1"), { parent = p.panel, font = "title", size = 40, color = "gold", width = 600 })
			end
			lv = lumi_view.create(p.root, p.cx, p.cy - 170, 0.6)
			lv:set_mood("victory")
			p.line = ui.text(0, -400, lines[1], { parent = p.panel, size = 28, width = 580 })
			p.hint = ui.text(0, -p.h / 2 + 36, L("common.tap_continue"), { parent = p.panel, size = 22, color = "#D9C8FF" })
			timer.delay(0.8, false, function() p.ready = true end)
		end,
		update = function(_, dt) if lv then lv:update(dt) end end,
		on_destroy = function() if lv then lv:destroy() end end,
	})
end

return M
