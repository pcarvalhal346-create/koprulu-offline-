-- Gameplay screen: HUD (level, moves, goals, score, pause), the board, Lumi,
-- guided tutorials, hints and the end-of-level flow.
local ui = require "gui.ui"
local board_view = require "gui.board_view"
local tutorial_view = require "gui.tutorial_view"
local dialog = require "gui.dialog"
local lumi_view = require "gui.lumi_view"
local victory_view = require "gui.victory_view"
local settings_view = require "gui.settings_view"
local book = require "gui.alchemy_book"
local goal_icons = require "gui.goal_icons"
local cover_bg = require("gui.main_menu").cover_bg
local Game = require "scripts.game_rules"
local level_manager = require "scripts.level_manager"
local progression = require "scripts.progression"
local tutorial_manager = require "scripts.tutorial_manager"
local lumi = require "scripts.lumi"
local autoplay = require "scripts.autoplay"
local elements = require "data.elements"
local L = require "scripts.localization"

local M = {}
M.__index = M

local V3 = vmath.vector3
local HINT_DELAY = 7
local DRAG_THRESHOLD = 28

function M.create(ctx, params)
	local self = setmetatable({ ctx = ctx, params = params, idle = 0 }, M)
	self.level_id = params.level or 1
	self.def = level_manager.get(self.level_id)
	self.world = level_manager.world_of(self.level_id)
	self.game = Game.new(self.def, { discovered = ctx.save.discovered_set() })

	-- tutorial
	local tut = self.def.tutorial
	if tut and (not ctx.profile.tutorials[tut] or params.force_tutorial) then
		self.tm = tutorial_manager.new(tut, self.game)
	end

	self:build_view()
	if self.tm and self.tm.rebuilt then self.bv:refresh_cells(self.tm.rebuilt) end
	self:intro_banner()
	ctx.audio.music("music_game")
	return self
end

--- Create every node from the current logic state (also used after a resize).
function M:build_view()
	local ctx = self.ctx
	local m = ui.metrics()
	self.m = m
	self.buttons = ui.buttons()
	self.root = ui.container(ctx.screens.layers.screen, 0, 0)
	cover_bg(self.root, m, "bg_world" .. self.world.id)

	-- layout: HUD at the top, board in the middle, Lumi area at the bottom
	local hud_bottom = m.safe_top - 204
	local bottom_area = m.safe_bottom + 196
	local cell = math.floor(math.min(84, (m.vw - 36) / 8, (hud_bottom - bottom_area - 40) / 8))
	local board_cy = (hud_bottom + bottom_area) / 2
	self.bv = board_view.create(self.root, ctx, { cx = m.cx, cy = board_cy, cell = cell })
	self.bv:build(self.game.board)
	self.bv.callbacks = {
		on_event = function(e) self:on_event(e) end,
		on_discovery = function(e) return self:on_discovery(e) end,
		on_cascade = function(e, text) self:combo_text(e.level, text) end,
		on_collect = function(e, wx, wy) self:fly_to_goal(e, wx, wy) end,
		on_shuffle = function() self:toast(L("hud.shuffle")) end,
		on_locked = function() self:toast(L("hud.locked")) end,
	}

	self:build_hud(m)
	self:build_bottom(m)

	self.tv = tutorial_view.create(self.root, self.bv)
	self.dialog = dialog.create(self.root, {
		y = m.safe_bottom + 150,
		sound = function() ctx.audio.play("lumi") end,
		on_continue = function() self:dialog_continue() end,
		on_skip = function() self:skip_tutorial() end,
	})
	self:update_hud()
end

-- -------------------------------------------------------------------- HUD --

--- Top HUD: goals on the left, a large moves badge in the centre that hangs
--- below the bar, score and the live star meter on the right.
function M:build_hud(m)
	local top = m.safe_top
	local bw = math.min(m.vw - 12, 716)
	local hud = ui.box(m.cx, top - 78, bw, 148, "ui", "hud_bar", { parent = self.root, slice = 44 })
	self.hud = hud
	local half = bw / 2

	-- goals pill (left)
	local gw = half - 96
	local gx = m.cx - half + 10 + gw / 2
	ui.box(gx, top - 80, gw, 118, "ui", "pill", { parent = self.root, slice = 36 })
	self.slots = {}
	local n = #self.def.goals
	local step = gw / n
	local isz = n >= 4 and 46 or 56
	for i, g in ipairs(self.def.goals) do
		local x = gx - gw / 2 + step * (i - 0.5)
		local slot = ui.container(self.root, x, top - 80)
		local tex, anim = goal_icons.goal(g)
		local icon = ui.box(0, 16, isz, isz, tex, anim, { parent = slot })
		local badge = goal_icons.badge(g)
		if badge then
			local bb = ui.box(isz * 0.36, -isz * 0.12, 30, 30, "ui", "btn_round_gold", { parent = icon })
			ui.box(0, 2, 18, 18, "ui", badge, { parent = bb })
		end
		local count = ui.text(0, -34, ("0/%d"):format(g.count), { parent = slot, font = "title", size = n >= 4 and 22 or 26 })
		local check = ui.box(isz * 0.4, 36, 36, 36, "ui", "icon_check", { parent = slot, color = "green" })
		gui.set_enabled(check, false)
		self.slots[i] = { node = slot, icon = icon, count = count, check = check, x = x, y = top - 64 }
	end

	-- score + star meter (right)
	local sx = m.cx + half - 10 - gw / 2
	ui.box(sx, top - 80, gw, 118, "ui", "pill", { parent = self.root, slice = 36 })
	ui.text(sx, top - 40, L("level.label", { n = self.level_id }), { parent = self.root, size = 20, color = "#FFE8A3" })
	self.score_text = ui.text(sx, top - 74, "0", { parent = self.root, font = "title", size = 34 })
	self.star_nodes = {}
	for i = 1, 3 do
		self.star_nodes[i] = ui.box(sx + (i - 2) * 40, top - 114, 36, 36, "ui", "star_full", { parent = self.root })
	end

	-- moves badge (centre, hanging below the bar)
	local mv = ui.box(m.cx, top - 112, 172, 172, "ui", "moves_badge", { parent = self.root })
	self.moves_text = ui.text(0, 14, tostring(self.game.moves_left), { parent = mv, font = "title", size = 66 })
	ui.text(0, -40, L("level.moves"), { parent = mv, size = 20, color = "#E7C9FF" })
	self.moves_node = mv
	ui.pop_in(hud, 0, 1)
end

--- Bottom bar: Lumi on the left, contextual info, book and pause buttons on the right.
function M:build_bottom(m)
	local ctx = self.ctx
	ui.box(m.cx, m.safe_bottom + 46, m.vw + 20, 130, "ui", "bottom_bar", { parent = self.root, slice = 40 })
	self.lumi = lumi_view.create(self.root, m.safe_left + 104, m.safe_bottom + 128, 0.46)
	self.info = ui.text(m.cx + 10, m.safe_bottom + 70, "", { parent = self.root, size = 23, width = 330 })
	self.buttons:add(self.root, m.safe_right - 170, m.safe_bottom + 70, 100, 100, nil, "round_gold", function()
		book.open_popup(ctx)
	end, { icon = "book", icon_size = 54 })
	self.buttons:add(self.root, m.safe_right - 62, m.safe_bottom + 70, 100, 100, nil, "round", function()
		self:pause()
	end, { icon = "pause", icon_size = 46 })
end

function M:update_stars()
	local left = math.max(0, self.game.moves_left)
	local stars = progression.stars_for(self.game.moves_total, left)
	for i, n in ipairs(self.star_nodes) do
		gui.play_flipbook(n, i <= stars and "star_full" or "star_empty")
	end
end

function M:update_hud()
	gui.set_text(self.moves_text, tostring(self.game.moves_left))
	gui.set_text(self.score_text, tostring(self.game.score))
	for i, g in ipairs(self.game.objectives.goals) do
		local s = self.slots[i]
		gui.set_text(s.count, ("%d/%d"):format(g.progress, g.count))
		gui.set_enabled(s.check, g.progress >= g.count)
	end
	self:update_stars()
end

function M:on_event(e)
	if e.type == "moves" then
		gui.set_text(self.moves_text, tostring(e.left))
		gui.animate(self.moves_node, "scale", V3(1.08, 1.08, 1), gui.EASING_OUTQUAD, 0.1, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
		self:update_stars()
		if e.left <= 5 then gui.set_color(self.moves_text, ui.hex(e.left <= 3 and "#FF6B6B" or "white")) end
	elseif e.type == "score" then
		gui.set_text(self.score_text, tostring(e.total))
		if e.delta >= 100 and e.x then
			self.bv:floating_text(e.x, e.y, "+" .. e.delta, "white", 30)
		end
	elseif e.type == "objective_progress" then
		local s = self.slots[e.index]
		if s then
			gui.set_text(s.count, ("%d/%d"):format(e.progress, e.count))
			gui.animate(s.node, "scale", V3(1.1, 1.1, 1), gui.EASING_OUTQUAD, 0.08, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
			if e.done and not gui.is_enabled(s.check) then
				gui.set_enabled(s.check, true)
				ui.pop_in(s.check)
				self.ctx.effects.burst(s.x, s.y, { count = 16, sprite = "fx_star", color = ui.hex("gold"), speed = 200 })
				self.ctx.audio.play("star")
			end
		end
	end
end

function M:fly_to_goal(e, wx, wy)
	if e.reason == "fusion" then return end
	for i, g in ipairs(self.game.objectives.goals) do
		if g.type == "collect" and g.id == e.id then
			local s = self.slots[i]
			self.ctx.effects.fly(wx, wy, s.x, s.y + 16, "fx_dot", ui.rgb(elements.info[e.id].color), 26, 0.5)
			return
		end
	end
end

function M:combo_text(level, text)
	local m = self.m
	local t = ui.text(m.cx, self.bv.cy + self.bv.cell * 4 - 30, text, { parent = self.root, font = "title", size = 46 + math.min(level, 5) * 4, color = level >= 4 and "pink" or "gold" })
	ui.pop_in(t, 0, 1)
	gui.animate(t, "position.y", gui.get_position(t).y + 50, gui.EASING_OUTQUAD, 0.8)
	gui.animate(t, "color.w", 0, gui.EASING_INQUAD, 0.3, 0.6, function() ui.delete(t) end)
	if level >= 4 and not self.combo_said then
		self.combo_said = true
		self:lumi_says(L("lumi.combo"), "happy")
	end
end

function M:toast(text)
	local m = self.m
	if self.toast_node then ui.delete(self.toast_node) end
	local t = ui.text(m.cx, self.bv.cy, text, { parent = self.root, font = "title", size = 34, color = "white", width = 600 })
	self.toast_node = t
	ui.pop_in(t, 0, 1)
	gui.animate(t, "color.w", 0, gui.EASING_INQUAD, 0.4, 1.4, function()
		ui.delete(t)
		if self.toast_node == t then self.toast_node = nil end
	end)
end

--- Short, non-blocking line from the small Lumi at the bottom.
function M:lumi_says(text, mood)
	gui.set_text(self.info, text)
	gui.set_color(self.info, ui.hex("gold"))
	self.lumi:set_mood(mood or "talk", 1.5)
	self.info_t = 4
end

function M:set_info(text)
	gui.set_text(self.info, text or "")
	gui.set_color(self.info, ui.hex("white"))
	self.info_t = nil
end

-- ------------------------------------------------------------- intro flow --

function M:intro_banner()
	local m = self.m
	local b = ui.box(m.cx, m.cy + 40, 600, 220, "ui", "panel", { parent = self.root, slice = 46 })
	ui.text(0, 54, L("level.label", { n = self.level_id }), { parent = b, size = 28, color = "gold" })
	ui.text(0, 4, self.def.name, { parent = b, font = "title", size = 42, width = 560 })
	local goals = {}
	for _, g in ipairs(self.def.goals) do goals[#goals + 1] = L.goal(g) end
	ui.text(0, -62, table.concat(goals, " · "), { parent = b, size = 22, width = 560, color = "#D9C8FF" })
	ui.pop_in(b, 0.1, 1)
	self.banner = b
	self.banner_t = self.ctx.settings.reduced_motion and 1.0 or 1.8
end

function M:end_banner()
	local b = self.banner
	self.banner = nil
	gui.animate(b, "scale", V3(0.01, 0.01, 1), gui.EASING_INBACK, 0.25, 0, function() ui.delete(b) end)
	if self.tm then
		self:show_tutorial_step()
	else
		local rec = progression.level_record(self.ctx.profile, self.level_id)
		if not (rec and rec.completed) then
			local line, mood = lumi.line("level_start")
			self:lumi_says(line, mood)
		end
	end
end

-- -------------------------------------------------------------- tutorial --

function M:show_tutorial_step()
	local tm = self.tm
	if not tm or tm.finished then
		self:finish_tutorial()
		return
	end
	local st = tm:step()
	if tm.rebuilt then
		self.bv:refresh_cells(tm.rebuilt)
		tm.rebuilt = nil
	end
	self.lumi_hidden = true
	gui.set_enabled(self.lumi.root, false)
	gui.set_enabled(self.info, false)
	self.dialog:say(L(st.text), st.mood, { tap = st.kind == "say" })
	self.tv:show(st, tm)
end

function M:dialog_continue()
	if self.tm and not self.tm.finished and self.tm:on_continue() then
		self:show_tutorial_step()
	end
end

function M:finish_tutorial()
	if self.tm then
		self.ctx.profile.tutorials[self.tm.id] = true
		self.ctx.save.save()
	end
	self.tm = nil
	self.tv:clear()
	self.dialog:hide()
	gui.set_enabled(self.lumi.root, true)
	gui.set_enabled(self.info, true)
	self.lumi:set_mood("happy")
end

function M:skip_tutorial()
	if self.tm then self.tm:skip() end
	self:finish_tutorial()
end

-- ---------------------------------------------------------------- actions --

local function adjacent(a, b)
	return math.abs(a.x - b.x) + math.abs(a.y - b.y) == 1
end

function M:clear_selection()
	self.selected = nil
	self.bv:select(nil)
	if not self.info_t then self:set_info("") end
end

function M:run(result, kind)
	self:clear_selection()
	self.idle = 0
	self.bv:play(result.events, function() self:after_action(kind) end)
end

function M:attempt_swap(a, b)
	if self.tm and not self.tm.finished then
		if not self.tm:allows_swap(a, b) then
			self.ctx.audio.play("invalid")
			return
		end
	end
	local r = self.game:try_swap(a.x, a.y, b.x, b.y)
	if #r.events > 0 then self:run(r, r.ok and r.kind or nil) end
	if not r.ok then self:clear_selection() end
end

function M:activate(x, y, choice)
	local r = self.game:activate(x, y, choice)
	if r.need_choice then
		victory_view.choose_element(self.ctx, r.options, function(id) self:activate(x, y, id) end)
		return
	end
	if r.ok then self:run(r, "activate") end
end

function M:tap(x, y)
	local tm = self.tm and not self.tm.finished and self.tm or nil
	local st = tm and tm:step()
	local sel = self.selected
	if sel and sel.x == x and sel.y == y then
		local p = self.game.board:piece(x, y)
		if p and p.kind == "compound" then
			if tm and not (st.kind == "activate" and tm:allows_tap(x, y)) then return end
			self:activate(x, y)
		else
			self:clear_selection()
		end
		return
	end
	if sel and adjacent(sel, { x = x, y = y }) then
		self:attempt_swap(sel, { x = x, y = y })
		return
	end
	if tm then
		local ok = (st.kind == "select" and tm:allows_tap(x, y))
			or (st.kind == "swap" and tm.move and ((tm.move.a.x == x and tm.move.a.y == y) or (tm.move.b.x == x and tm.move.b.y == y)))
		if not ok then return end
	end
	local info = self.game:select_info(x, y)
	if not info.piece then
		self:clear_selection()
		return
	end
	if not info.movable then
		self:clear_selection()
		self:toast(L("hud.locked"))
		self.ctx.audio.play("invalid")
		return
	end
	self.selected = { x = x, y = y }
	self.bv:select(x, y, info.partners)
	self.ctx.audio.play("select")
	local p = info.piece
	if p.kind == "compound" then
		self:set_info(L.element(p.id) .. ": " .. L("power." .. p.id) .. "\n" .. L("hud.tap_again"))
	elseif p.kind == "charged" then
		self:set_info(L("hud.charged", { name = L.element(p.id) }))
	else
		self:set_info("")
	end
	if tm and st.kind == "select" and p.kind == "compound" then
		tm:on_action("select")
		self:show_tutorial_step()
	end
end

function M:after_action(kind)
	self:update_hud()
	local g = self.game
	if self.tm and not self.tm.finished and kind then
		if self.tm:on_action(kind) then self:show_tutorial_step() end
	end
	if g.status == "won" then
		self:on_victory()
		return
	elseif g.status == "lost" then
		self:on_defeat()
		return
	end
	if not self.tm then
		if g.no_progress_turns >= 4 then
			g.no_progress_turns = 0
			local tip, mood = lumi.tip_for(g.objectives:remaining())
			if tip then self:lumi_says(tip, mood) end
		elseif g.moves_left == 3 and not self.low_said then
			self.low_said = true
			self:lumi_says(L("lumi.low_moves"), "surprised")
		end
	end
end

-- ---------------------------------------------------------------- outcome --

function M:on_discovery(e)
	self.ctx.save.add_discovery(e.key, self.level_id)
	self.lumi:set_mood("surprised")
	victory_view.discovery(self.ctx, e, function()
		self.lumi:set_mood("happy")
		self.bv:resume()
	end)
	return nil
end

function M:on_victory()
	local ctx, g = self.ctx, self.game
	if self.tm then self:finish_tutorial() end
	local prev = progression.level_record(ctx.profile, self.level_id)
	local res = progression.record_win(ctx.profile, self.level_id, g.score, g.stars, self.world.last)
	ctx.save.save()
	self.lumi:set_mood("victory")
	local data = {
		level = self.level_id, stars = g.stars, score = g.score, bonus = g.moves_left * Game.SCORE.move_left,
		new_best = res.new_best and prev ~= nil, has_next = self.level_id < level_manager.count(),
	}
	local new_world = res.world_unlocked
	local handlers = {
		next = function()
			if new_world then
				ctx.screens.go("map", { new_world = new_world })
			else
				ctx.screens.go("game", { level = self.level_id + 1 })
			end
		end,
		replay = function() ctx.screens.go("game", { level = self.level_id }) end,
		map = function() ctx.screens.go("map", { new_world = new_world }) end,
	}
	local function show() victory_view.victory(ctx, data, handlers) end
	if self.def.world_finale and res.first_clear then
		timer.delay(0.6, false, function() victory_view.story(ctx, self.world.id, show) end)
	else
		timer.delay(0.5, false, show)
	end
end

function M:on_defeat()
	local ctx = self.ctx
	self.lumi:set_mood("sad")
	timer.delay(0.5, false, function()
		victory_view.defeat(ctx, { remaining = self.game.objectives:remaining() }, {
			retry = function() ctx.screens.go("game", { level = self.level_id }) end,
			map = function() ctx.screens.go("map") end,
		})
	end)
end

function M:pause()
	local ctx = self.ctx
	settings_view.open_pause(ctx, {
		resume = function() end,
		restart = function() ctx.screens.go("game", { level = self.level_id }) end,
		map = function() ctx.screens.go("map") end,
		tutorial = self.def.tutorial and function()
			ctx.screens.go("game", { level = self.level_id, force_tutorial = true })
		end or nil,
	})
end

function M:on_back()
	self:pause()
end

-- ------------------------------------------------------------------ input --

function M:board_input(action)
	local gx, gy = ui.to_gui(action)
	if action.pressed then
		local x, y = self.bv:cell_at(gx, gy)
		self.press = x and { x = x, y = y, gx = gx, gy = gy, dragged = false } or nil
		return
	end
	local p = self.press
	if not p then return end
	if not action.released then
		if not p.dragged then
			local dx, dy = gx - p.gx, gy - p.gy
			if math.max(math.abs(dx), math.abs(dy)) > DRAG_THRESHOLD then
				p.dragged = true
				local tx, ty = p.x, p.y
				if math.abs(dx) > math.abs(dy) then tx = tx + (dx > 0 and 1 or -1) else ty = ty + (dy > 0 and -1 or 1) end
				if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
					self:attempt_swap({ x = p.x, y = p.y }, { x = tx, y = ty })
				end
			end
		end
		return
	end
	self.press = nil
	if not p.dragged then self:tap(p.x, p.y) end
end

function M:on_input(action_id, action)
	if self.banner then return true end
	if self.dialog:on_input(action_id, action) then return true end
	if self.buttons:on_input(action_id, action) then return true end
	if action_id ~= hash("touch") then return false end
	if self.bv:busy() or self.game.status ~= "playing" then return true end
	if self.tm and not self.tm.finished and self.tm:blocks_board() then return true end
	self.idle = 0
	if self.hinting then
		self.hinting = false
		self.bv:clear_highlights()
		if self.selected then self.bv:select(self.selected.x, self.selected.y, self.game:select_info(self.selected.x, self.selected.y).partners) end
	end
	self:board_input(action)
	return true
end

function M:update(dt)
	self.bv:update(dt)
	self.dialog:update(dt)
	if not self.lumi_hidden or not self.tm then self.lumi:update(dt) end
	if self.banner then
		self.banner_t = self.banner_t - dt
		if self.banner_t <= 0 then self:end_banner() end
		return
	end
	if self.info_t then
		self.info_t = self.info_t - dt
		if self.info_t <= 0 then self:set_info("") end
	end
	if self.ctx.dev.autoplay then self:autoplay(dt) end
	-- idle hint
	if not self.tm and self.game.status == "playing" and not self.bv:busy() and not self.ctx.screens.top_popup() then
		self.idle = self.idle + dt
		if self.idle > HINT_DELAY and not self.hinting then
			self.hinting = true
			self.bv:show_hint(self.game:hint())
		end
		if self.hinting and self.idle > HINT_DELAY + 2.5 then
			self.idle = HINT_DELAY
			self.hinting = false
		end
	end
end

--- Developer autoplay: the bot plays (and follows the tutorial) by itself.
function M:autoplay(dt)
	self.auto_t = (self.auto_t or 0) + dt
	if self.auto_t < 0.7 or self.banner then return end
	local top = self.ctx.screens.top_popup()
	if top then
		if top.opts.auto_close then top:close() end
		self.auto_t = 0
		return
	end
	if self.bv:busy() or self.game.status ~= "playing" then return end
	self.auto_t = 0
	local tm = self.tm and not self.tm.finished and self.tm or nil
	if tm then
		local st = tm:step()
		if st.kind == "say" then
			self.dialog:finish()
			self:dialog_continue()
		elseif st.kind == "swap" then
			self:attempt_swap(tm.move.a, tm.move.b)
		elseif st.kind == "activate" and self.game.board:piece(tm.target.x, tm.target.y).id == "crystal" then
			self:activate(tm.target.x, tm.target.y, self.game:crystal_options()[1])
		else
			self:tap(tm.target.x, tm.target.y)
		end
		return
	end
	local a = autoplay.choose(self.game)
	if not a then return end
	if a.kind == "swap" then
		self:attempt_swap(a.a, a.b)
	else
		self:activate(a.x, a.y, a.choice)
	end
end

function M:on_resize()
	-- rebuild the nodes from the logic state: nothing is lost
	if self.bv:busy() or self.banner then return end
	self:destroy()
	self.selected, self.hinting = nil, false
	self:build_view()
	if self.tm and not self.tm.finished then self:show_tutorial_step() end
end

function M:destroy()
	self.bv:destroy()
	self.tv:destroy()
	self.dialog:destroy()
	self.lumi:destroy()
	ui.delete(self.root)
end

return M
