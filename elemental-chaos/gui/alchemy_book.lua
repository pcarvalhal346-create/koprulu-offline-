-- Livro de Alquimia: all 10 recipes, known and unknown (silhouettes),
-- discovery counter, "Novo!" badges and a detail card per recipe.
local ui = require "gui.ui"
local popup = require "gui.popup"
local recipes = require "data.recipes"
local L = require "scripts.localization"

local M = {}
M.__index = M

local V3 = vmath.vector3
local CARD_W, CARD_H = 318, 236

--- Card content (used by the book grid, the detail popup and discoveries).
--- Returns the card node. opts: { known, new, big }
function M.card(parent, x, y, r, opts)
	opts = opts or {}
	local sc = opts.scale or (opts.big and 1.55 or 1)
	local known = opts.known
	local card = ui.box(x, y, CARD_W * sc, CARD_H * sc, "ui", known and "card_known" or "card_unknown", { parent = parent, slice = 40 })
	local icon = ui.box(0, 30 * sc, 112 * sc, 112 * sc, "pieces", r.result, { parent = card })
	if not known then
		gui.set_color(icon, vmath.vector4(0.08, 0.06, 0.2, 0.85))
		ui.text(0, 30 * sc, "?", { parent = card, font = "title", size = 64 * sc, color = "#B593FF" })
	else
		gui.animate(icon, "scale", V3(1.06, 1.06, 1), gui.EASING_INOUTSINE, 1.1, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	end
	ui.text(0, -50 * sc, known and L.element(r.result) or L("book.unknown"), { parent = card, font = "title", size = (known and 28 or 22) * sc, color = known and "gold" or "#B593FF" })
	-- ingredients: icon + icon
	local iy = -88 * sc
	if known then
		ui.box(-48 * sc, iy, 46 * sc, 46 * sc, "pieces", r.a, { parent = card })
		ui.text(0, iy + 2, "+", { parent = card, font = "title", size = 34 * sc })
		ui.box(48 * sc, iy, 46 * sc, 46 * sc, "pieces", r.b, { parent = card })
	else
		ui.text(0, iy, "? + ?", { parent = card, font = "title", size = 28 * sc, color = "#7A6CC9" })
	end
	if opts.new then
		local b = ui.box(CARD_W * sc / 2 - 44, CARD_H * sc / 2 - 22, 96, 44, "ui", "btn_danger", { parent = card, slice = 20 })
		ui.text(0, 2, L("book.new"), { parent = b, size = 22 })
		ui.pulse(b, 1.1, 0.5)
	end
	return card
end

function M.create(ctx, params)
	local self = setmetatable({ ctx = ctx, buttons = ui.buttons(), scroll = 0, from = params.from or "menu" }, M)
	local m = ui.metrics()
	self.m = m
	local profile = ctx.profile
	self.root = ui.container(ctx.screens.layers.screen, 0, 0)
	local s = math.max(m.vw / 480, m.vh / 854)
	ui.box(m.cx, m.cy, 480 * s, 854 * s, "bg", "bg_menu", { parent = self.root })
	ui.box(m.cx, m.cy, m.vw, m.vh, "ui", "white", { parent = self.root, color = "navy", alpha = 0.45 })
	self.content = ui.container(self.root, 0, 0)

	local top = m.safe_top
	local count = 0
	for _ in pairs(profile.discovered) do count = count + 1 end
	self.cards = {}
	local y = top - 230
	local idx = 0
	for tier = 1, 2 do
		ui.text(m.cx, y, L(tier == 1 and "book.tier1" or "book.tier2"), { parent = self.content, font = "title", size = 30, color = "gold" })
		y = y - 160
		local col = 0
		for _, r in ipairs(recipes.list) do
			if r.tier == tier then
				idx = idx + 1
				local key = recipes.key(r.a, r.b)
				local d = profile.discovered[key]
				local x = m.cx + (col == 0 and -170 or 170)
				local card = M.card(self.content, x, y, r, { known = d ~= nil, new = d ~= nil and not d.seen })
				self.cards[#self.cards + 1] = { node = card, recipe = r, key = key }
				ui.pop_in(card, idx * 0.03)
				col = col + 1
				if col == 2 then col = 0; y = y - CARD_H - 20 end
			end
		end
		if col == 1 then y = y - CARD_H - 20 end
		y = y + 60
	end
	self.content_bottom = y
	self.max_scroll = math.max(0, (m.safe_bottom + 40) - (y - 60))

	-- header
	ui.box(m.cx, top - 70, m.vw, 140, "ui", "panel_dark", { parent = self.root, slice = 30 })
	self.buttons:add(self.root, m.safe_left + 64, top - 70, 92, 92, nil, "round", function() self:on_back() end, { icon = "back", icon_size = 46 })
	ui.text(m.cx + 20, top - 50, L("book.title"), { parent = self.root, font = "title", size = 40, color = "gold" })
	ui.text(m.cx + 20, top - 100, L("book.count", { n = count, total = #recipes.list }), { parent = self.root, size = 24 })
	return self
end

function M:open_detail(c)
	local ctx = self.ctx
	local d = ctx.profile.discovered[c.key]
	popup.open({
		w = 640, h = 860, closable = true,
		build = function(p)
			M.card(p.panel, 0, 140, c.recipe, { known = d ~= nil, big = true })
			local info = d and L("power." .. c.recipe.result) or L("book.unknown_hint")
			ui.text(0, -150, d and L("book.power") or "", { parent = p.panel, font = "title", size = 30, color = "gold" })
			ui.text(0, -230, info, { parent = p.panel, size = 28, width = 540 })
			if d and type(d) == "table" and d.order then
				ui.text(0, -340, L("book.discovered_in", { n = d.order, level = d.level or "-" }), { parent = p.panel, size = 22, color = "#D9C8FF" })
			end
		end,
	})
	if d and type(d) == "table" and not d.seen then
		d.seen = true
		ctx.save.save()
	end
end

--- Compact book shown as a popup during a level (does not leave the game).
function M.open_popup(ctx)
	local profile = ctx.profile
	return popup.open({
		w = 680, h = 1000, title = L("book.title"), closable = true,
		build = function(p)
			for i, r in ipairs(recipes.list) do
				local col = (i - 1) % 2
				local row = math.floor((i - 1) / 2)
				local d = profile.discovered[recipes.key(r.a, r.b)]
				M.card(p.panel, col == 0 and -150 or 150, 330 - row * 168, r, { known = d ~= nil, scale = 0.68 })
			end
		end,
	})
end

function M:update() end

function M:on_input(action_id, action)
	if self.buttons:on_input(action_id, action) then return true end
	if action_id == hash("wheel_up") or action_id == hash("wheel_down") then
		self:set_scroll(self.scroll + (action_id == hash("wheel_up") and -80 or 80))
		return true
	end
	if action_id ~= hash("touch") then return false end
	if action.pressed then
		self.drag = 0
	elseif action.released then
		if (self.drag or 0) < 14 then
			for _, c in ipairs(self.cards) do
				if gui.pick_node(c.node, action.x, action.y) then
					self.ctx.audio.play("select")
					self:open_detail(c)
					break
				end
			end
		end
	else
		local dy = action.dy * ui.input_scale()
		self.drag = (self.drag or 0) + math.abs(dy)
		self:set_scroll(self.scroll + dy)
	end
	return true
end

function M:set_scroll(s)
	self.scroll = math.max(0, math.min(self.max_scroll, s))
	gui.set_position(self.content, V3(0, self.scroll, 0))
end

function M:on_back()
	self.ctx.screens.go(self.from == "map" and "map" or "menu")
end

function M:on_resize()
	self.ctx.screens.go("book", { from = self.from }, true)
end

function M:destroy()
	ui.delete(self.root)
end

return M
