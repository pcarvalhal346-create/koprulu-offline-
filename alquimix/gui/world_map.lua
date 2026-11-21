-- Vertical progression map of the 60 levels across 3 worlds.
-- Only the level widgets, path dots and background tiles near the viewport
-- exist as nodes: small pools are recycled while the player scrolls.
local ui = require "gui.ui"
local popup = require "gui.popup"
local goal_icons = require "gui.goal_icons"
local settings_view = require "gui.settings_view"
local level_manager = require "scripts.level_manager"
local progression = require "scripts.progression"
local L = require "scripts.localization"

local M = {}
M.__index = M

local V3 = vmath.vector3
local LEVEL_POOL, DOT_POOL, BG_POOL = 14, 90, 4
local STONES = 5 -- stepping stones between two levels
local SPACING, WORLD_GAP, BASE_Y = 150, 260, 340

local WORLD_BG = { "bg_world1", "bg_world2", "bg_world3" }
local WORLD_TINT = { "#51D989", "#FF9A3C", "#B593FF" }

-- content coordinates -----------------------------------------------------
local function level_y(i)
	local w = level_manager.world_of(i).id
	return BASE_Y + (i - 1) * SPACING + (w - 1) * WORLD_GAP
end

local function level_x(i)
	return 360 + 205 * math.sin(i * 0.82)
end

local function world_start_y(w)
	return level_y(level_manager.WORLDS[w].first) - SPACING * 0.5 - WORLD_GAP * 0.5
end

function M.create(ctx, params)
	local self = setmetatable({ ctx = ctx, buttons = ui.buttons(), scroll = 0, vel = 0 }, M)
	local m = ui.metrics()
	self.m = m
	self.profile = ctx.profile
	self.root = ui.container(ctx.screens.layers.screen, 0, 0)
	self.content = ui.container(self.root, 0, 0)
	self.count = level_manager.count()
	self.total_h = level_y(self.count) + 380
	self.view_h = m.vh

	-- background tiles (pooled)
	self.bg = {}
	self.tile_h = m.vw * 854 / 480
	for i = 1, BG_POOL do
		self.bg[i] = ui.box(m.cx, 0, m.vw, self.tile_h, "bg", "bg_world1", { parent = self.content })
	end
	-- world banners (3 static widgets)
	self.banners = {}
	for w = 1, 3 do
		local y = world_start_y(w) + (w == 1 and 40 or 0)
		local b = ui.box(m.cx, y, 520, 120, "ui", "ribbon", { parent = self.content })
		ui.text(0, 30, L("world.label", { n = w }), { parent = b, size = 26, color = "#FFF6D6", outline = "#8A4F00" })
		ui.text(0, -2, L(level_manager.WORLDS[w].key), { parent = b, font = "title", size = 34, outline = "#8A4F00" })
		local lock = ui.text(0, -70, L("map.locked_world", { n = level_manager.WORLDS[w].first - 1 }), { parent = b, size = 22, color = "white" })
		gui.set_enabled(lock, not progression.is_unlocked(self.profile, level_manager.WORLDS[w].first))
		self.banners[w] = b
	end
	-- path dots (pooled)
	self.dots = {}
	for i = 1, DOT_POOL do
		self.dots[i] = ui.box(0, 0, 34, 28, "ui", "path_dot", { parent = self.content })
		gui.set_enabled(self.dots[i], false)
	end
	-- level widgets (pooled)
	self.widgets = {}
	for i = 1, LEVEL_POOL do
		local w = { level = nil }
		w.root = ui.container(self.content, 0, 0)
		w.glow = ui.box(0, 0, 170, 170, "ui", "node_glow", { parent = w.root, blend = gui.BLEND_ADD })
		gui.animate(w.glow, "scale", V3(1.15, 1.15, 1), gui.EASING_INOUTSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		w.node = ui.box(0, 0, 112, 112, "ui", "node_open", { parent = w.root })
		w.num = ui.text(0, 4, "1", { parent = w.node, font = "title", size = 44 })
		w.lock = ui.box(0, 0, 50, 50, "ui", "icon_lock", { parent = w.node })
		w.stars = {}
		for s = 1, 3 do
			w.stars[s] = ui.box((s - 2) * 32, -62 + (s == 2 and -6 or 0), 34, 34, "ui", "star_empty", { parent = w.root })
		end
		gui.set_enabled(w.root, false)
		self.widgets[i] = w
	end

	-- top bar: back, title, total stars
	local top = m.safe_top
	ui.box(m.cx, top - 56, m.vw - 12, 112, "ui", "hud_bar", { parent = self.root, slice = 40 })
	self.buttons:add(self.root, m.safe_left + 62, top - 56, 84, 84, nil, "round", function()
		ctx.screens.go("menu")
	end, { icon = "back", icon_size = 42 })
	ui.text(m.cx - 40, top - 56, L("map.title"), { parent = self.root, font = "title", size = 34 })
	local sp = ui.box(m.safe_right - 110, top - 56, 170, 64, "ui", "pill", { parent = self.root, slice = 30 })
	ui.box(-50, 2, 44, 44, "ui", "star_full", { parent = sp })
	ui.text(14, 2, tostring(progression.total_stars(self.profile)), { parent = sp, font = "title", size = 30 })

	-- bottom navigation bar: Mapa / Livro / Definições
	local nb = m.safe_bottom + 58
	ui.box(m.cx, m.safe_bottom + 30, m.vw + 20, 150, "ui", "bottom_bar", { parent = self.root, slice = 40 })
	local tabs = {
		{ "nav_tab_on", "map", L("map.title"):match("^(%S+)"), function() self:set_scroll(level_y(progression.current_level(self.profile)) - m.vh * 0.38) end },
		{ "nav_tab_off", "book", L("menu.book"):match("^(%S+)"), function() ctx.screens.go("book", { from = "map" }) end },
		{ "nav_tab_off", "gear", L("menu.settings"), function() settings_view.open_settings(ctx) end },
	}
	local tw = math.min(220, (m.vw - 40) / 3)
	for i, t in ipairs(tabs) do
		local b = self.buttons:add(self.root, m.cx + (i - 2) * (tw + 8), nb, tw, 96, nil, "icon", t[4])
		-- the hit area is transparent, so the visible tab must not inherit its alpha
		local bg = ui.box(0, 0, tw, 96, "ui", t[1], { parent = b.node, slice = 30, inherit = false })
		ui.box(0, 14, 50, 50, "ui", "icon_" .. t[2], { parent = bg })
		ui.text(0, -30, t[3], { parent = bg, size = 22, outline = i == 1 and "#9C5A00" or "#A3205B" })
	end

	-- initial scroll: the current level near the lower third
	local focus = params.focus or progression.current_level(self.profile)
	self.max_scroll = math.max(0, self.total_h - m.vh + 240)
	self:set_scroll(level_y(focus) - m.vh * 0.38)
	ctx.audio.music("music_menu")

	-- new world unlocked transition
	local w_new = params.new_world
	if w_new then
		self.anim_to = level_y(level_manager.WORLDS[w_new].first) - m.vh * 0.38
		self:set_scroll(level_y(level_manager.WORLDS[w_new].first - 1) - m.vh * 0.38)
		self.banner_world = w_new
		self.profile.worlds_seen[w_new] = true
		ctx.save.save()
	end
	return self
end

function M:set_scroll(s)
	self.scroll = math.max(0, math.min(self.max_scroll, s))
	gui.set_position(self.content, V3(0, self.m.bottom - self.scroll, 0))
	self:refresh()
end

--- Assign pooled widgets to the levels inside the viewport.
function M:refresh()
	local m = self.m
	local lo, hi = self.scroll - 160, self.scroll + m.vh + 160
	-- background tiles
	local first_tile = math.floor(math.max(0, self.scroll - 40) / self.tile_h)
	for i, n in ipairs(self.bg) do
		local k = first_tile + i - 1
		local y = k * self.tile_h + self.tile_h / 2
		local world = 1
		for w = 2, 3 do if y >= world_start_y(w) then world = w end end
		gui.set_position(n, V3(m.cx, y, 0))
		gui.play_flipbook(n, WORLD_BG[world])
		gui.set_enabled(n, y - self.tile_h / 2 < hi)
	end
	-- levels
	local wi, di = 1, 1
	local current = progression.current_level(self.profile)
	self.visible = {}
	for id = 1, self.count do
		local y = level_y(id)
		if y > lo and y < hi and wi <= LEVEL_POOL then
			local w = self.widgets[wi]
			wi = wi + 1
			w.level = id
			gui.set_enabled(w.root, true)
			gui.set_position(w.root, V3(level_x(id), y, 0))
			local unlocked = progression.is_unlocked(self.profile, id)
			local stars = progression.stars(self.profile, id)
			gui.play_flipbook(w.node, (not unlocked) and "node_locked" or (stars > 0 and "node_done" or "node_open"))
			gui.set_text(w.num, tostring(id))
			gui.set_enabled(w.num, unlocked)
			gui.set_enabled(w.lock, not unlocked)
			gui.set_enabled(w.glow, id == current and unlocked)
			for s = 1, 3 do
				gui.set_enabled(w.stars[s], unlocked and stars > 0)
				gui.play_flipbook(w.stars[s], s <= stars and "star_full" or "star_empty")
			end
			self.visible[#self.visible + 1] = w
		end
		-- dots towards the next level
		if id < self.count and di <= DOT_POOL then
			local y2 = level_y(id + 1)
			if y2 > lo and y < hi then
				local x1, x2 = level_x(id), level_x(id + 1)
				for k = 1, STONES do
					if di > DOT_POOL then break end
					local t = k / (STONES + 1)
					local d = self.dots[di]
					di = di + 1
					gui.set_enabled(d, true)
					gui.set_position(d, V3(x1 + (x2 - x1) * t, y + (y2 - y) * t, 0))
					local done = progression.stars(self.profile, id) > 0
					gui.set_color(d, done and vmath.vector4(1, 1, 1, 1) or vmath.vector4(0.85, 0.82, 0.95, 0.75))
				end
			end
		end
	end
	for i = wi, LEVEL_POOL do gui.set_enabled(self.widgets[i].root, false); self.widgets[i].level = nil end
	for i = di, DOT_POOL do gui.set_enabled(self.dots[i], false) end
end

function M:open_level(id)
	local def = level_manager.get(id)
	local ctx = self.ctx
	local rec = progression.level_record(self.profile, id)
	local goals = #def.goals
	popup.open({
		w = 620, h = 560 + goals * 86, title = L("level.label", { n = id }), closable = true,
		build = function(p)
			local top = p.h / 2
			ui.text(0, top - 110, def.name, { parent = p.panel, font = "title", size = 34, color = "gold" })
			local stars = rec and rec.stars or 0
			for s = 1, 3 do
				local st = ui.box((s - 2) * 86, top - 190 + (s == 2 and 14 or 0), 82, 82, "ui", s <= stars and "star_full" or "star_empty", { parent = p.panel })
				ui.pop_in(st, 0.1 * s)
			end
			ui.text(0, top - 270, L("level.goals"), { parent = p.panel, size = 26, color = "#D9C8FF" })
			for i, g in ipairs(def.goals) do
				local y = top - 330 - (i - 1) * 86
				local row = ui.box(0, y, 500, 76, "ui", "goal_slot", { parent = p.panel, slice = 24 })
				local tex, anim = goal_icons.goal(g)
				ui.box(-210, 0, 60, 60, tex, anim, { parent = row })
				ui.text(-168, 2, L.goal(g), { parent = row, size = 26, pivot = gui.PIVOT_W })
			end
			local by = -p.h / 2 + 150
			ui.text(0, by + 80, L("level.moves") .. ": " .. def.moves .. (rec and rec.best_score > 0 and ("   ·   " .. L("level.best", { n = rec.best_score })) or ""),
				{ parent = p.panel, size = 24, color = "#D9C8FF" })
			local b = p.buttons:add(p.panel, 0, by - 10, 360, 110, L("level.start"), "primary", function()
				p:close()
				ctx.screens.go("game", { level = id })
			end, { icon = "play", size = 40 })
			ui.pulse(b.node, 1.04, 0.7)
		end,
	})
end

function M:update(dt)
	if self.anim_to then
		local d = self.anim_to - self.scroll
		if math.abs(d) < 2 then
			self:set_scroll(self.anim_to)
			self.anim_to = nil
			if self.banner_world then self:celebrate_world(self.banner_world) end
		else
			self:set_scroll(self.scroll + d * math.min(1, dt * 2.5))
		end
		return
	end
	if not self.dragging and math.abs(self.vel) > 1 then
		self:set_scroll(self.scroll + self.vel * dt)
		self.vel = self.vel * math.max(0, 1 - dt * 4)
	end
end

function M:celebrate_world(w)
	local m = self.m
	local ctx = self.ctx
	self.banner_world = nil
	ctx.audio.play("discovery")
	local y = level_y(level_manager.WORLDS[w].first)
	ctx.effects.burst(level_x(level_manager.WORLDS[w].first), y + self.m.bottom - self.scroll, { count = 40, sprite = "fx_star", color = ui.hex(WORLD_TINT[w]), speed = 400, size = 34 })
	local t = ui.text(m.cx, m.cy + 200, L("map.new_world"), { parent = self.root, font = "title", size = 52, color = "gold" })
	ui.pop_in(t)
	gui.animate(t, "color.w", 0, gui.EASING_INQUAD, 0.6, 2.2, function() ui.delete(t) end)
	gui.animate(self.banners[w], "scale", V3(1.15, 1.15, 1), gui.EASING_OUTBACK, 0.3, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
end

function M:on_input(action_id, action)
	if self.buttons:on_input(action_id, action) then return true end
	if action_id == hash("wheel_up") or action_id == hash("wheel_down") then
		self.anim_to = nil
		self:set_scroll(self.scroll + (action_id == hash("wheel_up") and 90 or -90))
		return true
	end
	if action_id ~= hash("touch") then return false end
	local k = ui.input_scale()
	if action.pressed then
		self.dragging = true
		self.drag_dist = 0
		self.vel = 0
		self.anim_to = nil
	elseif action.released then
		self.dragging = false
		if (self.drag_dist or 0) < 14 then
			for _, w in ipairs(self.visible or {}) do
				if w.level and gui.pick_node(w.node, action.x, action.y) and progression.is_unlocked(self.profile, w.level) then
					self.ctx.audio.play("select")
					gui.animate(w.node, "scale", V3(1.15, 1.15, 1), gui.EASING_OUTQUAD, 0.08, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
					self:open_level(w.level)
					break
				end
			end
		end
	elseif self.dragging then
		local dy = action.dy * k
		self.drag_dist = (self.drag_dist or 0) + math.abs(dy)
		self:set_scroll(self.scroll - dy)
		self.vel = -dy * 60
	end
	return true
end

function M:on_back()
	self.ctx.screens.go("menu")
end

function M:on_resize()
	self.ctx.screens.go("map", { focus = progression.current_level(self.profile) }, true)
end

function M:destroy()
	ui.delete(self.root)
end

return M
