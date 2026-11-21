-- Visual board: renders the logic board (scripts/board.lua) with GUI nodes and
-- plays back the events produced by scripts/game_rules.lua through an ordered
-- animation queue. It never changes game state.
local ui = require "gui.ui"
local effects = require "scripts.effects"
local animations = require "scripts.animations"
local elements = require "data.elements"

local M = {}
M.__index = M

local V3 = vmath.vector3
local PIECE = 0.9 -- piece size relative to the cell

local OB_COLOR = { rock = "#9C8A70", frost = "#E6FAFF", vine = "#7CD67A", corruption = "#B030E0" }

local function key(x, y) return y * 64 + x end

--- layout: { cx, cy, cell }
function M.create(parent, ctx, layout)
	local self = setmetatable({
		ctx = ctx, cell = layout.cell, cx = layout.cx, cy = layout.cy,
		pieces = {}, blockers = {}, covers = {}, corrupt = {}, queue = animations.new(),
		speed = ctx.settings.reduced_motion and 0.65 or 1,
		callbacks = {},
	}, M)
	self.root = ui.container(parent, layout.cx, layout.cy)
	local size = layout.cell * 8
	self.frame = ui.box(0, 0, size + 34, size + 34, "board", "board_frame", { parent = self.root, slice = 40 })
	self.tiles_c = ui.container(self.root)
	self.terrain_c = ui.container(self.root)
	self.blocker_c = ui.container(self.root)
	-- pieces are clipped to the board so new pieces slide in from the top edge
	self.clip = ui.box(0, 0, size, size, nil, nil, { parent = self.root, color = vmath.vector4(1, 1, 1, 0), inherit = false })
	gui.set_clipping_mode(self.clip, gui.CLIPPING_MODE_STENCIL)
	gui.set_clipping_visible(self.clip, false)
	self.pieces_c = ui.container(self.clip)
	self.cover_c = ui.container(self.root)
	self.hl_c = ui.container(self.root)
	self.text_c = ui.container(self.root)
	return self
end

function M:local_pos(x, y)
	return (x - 4.5) * self.cell, (4.5 - y) * self.cell
end

--- Absolute GUI position of a cell (for particles and overlays).
function M:world_pos(x, y)
	local lx, ly = self:local_pos(x, y)
	return self.cx + lx, self.cy + ly
end

function M:cell_at(gx, gy)
	-- inverse of local_pos: centre of cell x is (x - 4.5) * cell
	local x = math.floor((gx - self.cx) / self.cell + 5)
	local y = math.floor(5 - (gy - self.cy) / self.cell)
	if x < 1 or x > 8 or y < 1 or y > 8 then return nil end
	return x, y
end

function M:dur(d) return d * self.speed end

-- ------------------------------------------------------------- building --

function M:build(board)
	self.board = board
	local c = self.cell
	for y = 1, 8 do
		for x = 1, 8 do
			local cell = board:cell(x, y)
			if not cell.void then
				local lx, ly = self:local_pos(x, y)
				ui.box(lx, ly, c - 2, c - 2, "board", (x + y) % 2 == 0 and "tile_light" or "tile_dark", { parent = self.tiles_c })
				if cell.conveyor then
					local a = ui.box(lx, ly, c * 0.9, c * 0.9, "board", "conveyor", { parent = self.terrain_c, alpha = 0.75 })
					local rot = cell.conveyor.axis == "row" and (cell.conveyor.dir > 0 and 0 or 180) or (cell.conveyor.dir > 0 and -90 or 90)
					gui.set_euler(a, V3(0, 0, rot))
				end
				if cell.portal then
					local p = ui.box(lx, ly, c * 1.0, c * 1.0, "board", cell.portal.role == "in" and "portal_in" or "portal_out", { parent = self.terrain_c, alpha = 0.9 })
					gui.animate(p, "euler.z", cell.portal.role == "in" and -360 or 360, gui.EASING_LINEAR, 4, 0, nil, gui.PLAYBACK_LOOP_FORWARD)
				end
			end
		end
	end
	self:sync(board)
end

local function piece_size(self) return self.cell * PIECE end

function M:create_piece(p, x, y)
	local lx, ly = self:local_pos(x, y)
	local s = piece_size(self)
	local n = ui.box(lx, ly, s, s, "pieces", elements.sprite_for(p), { parent = self.pieces_c })
	local entry = { node = n, id = p.id, kind = p.kind }
	self.pieces[p.uid] = entry
	self:decorate(entry)
	return entry
end

--- Aura/pulse for charged and compound pieces.
function M:decorate(entry)
	if entry.aura then ui.delete(entry.aura); entry.aura = nil end
	gui.cancel_animations(entry.node, "scale")
	gui.set_scale(entry.node, V3(1, 1, 1))
	gui.play_flipbook(entry.node, elements.sprite_for(entry))
	if entry.kind == "charged" then
		local s = self.cell * 1.15
		entry.aura = ui.box(0, 0, s, s, "board", "aura", { parent = entry.node, color = ui.rgb(elements.info[entry.id].color, 0.8), blend = gui.BLEND_ADD })
		gui.animate(entry.aura, "scale", V3(1.15, 1.15, 1), gui.EASING_INOUTSINE, 0.6, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		gui.animate(entry.aura, "color.w", 0.35, gui.EASING_INOUTSINE, 0.6, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	elseif entry.kind == "compound" then
		gui.animate(entry.node, "scale", V3(1.07, 1.07, 1), gui.EASING_INOUTSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	end
end

function M:delete_piece(uid)
	local e = self.pieces[uid]
	if e then
		ui.delete(e.node)
		self.pieces[uid] = nil
	end
end

local function cover_anim(cell)
	if cell.cover.type == "frost" then return cell.cover.hp > 1 and "frost_2" or "frost_1" end
	return "vine"
end

local function blocker_anim(b)
	if b.max_hp and b.max_hp > 1 then return b.hp > 1 and "rock_hard" or "rock_hard_cracked" end
	return "rock"
end

--- Reconcile every node with the logic board (also used after rebuilds).
function M:sync(board)
	self.board = board
	local seen = {}
	local c = self.cell
	for y = 1, 8 do
		for x = 1, 8 do
			local cell = board:cell(x, y)
			local k = key(x, y)
			local lx, ly = self:local_pos(x, y)
			local p = cell.piece
			if p then
				seen[p.uid] = true
				local e = self.pieces[p.uid]
				if not e then
					e = self:create_piece(p, x, y)
				elseif e.id ~= p.id or e.kind ~= p.kind then
					e.id, e.kind = p.id, p.kind
					self:decorate(e)
				end
				gui.set_position(e.node, V3(lx, ly, 0))
				gui.set_color(e.node, vmath.vector4(1, 1, 1, 1))
			end
			-- blockers
			local b = self.blockers[k]
			if cell.blocker then
				if not b then
					b = ui.box(lx, ly, c * 0.98, c * 0.98, "board", blocker_anim(cell.blocker), { parent = self.blocker_c })
					self.blockers[k] = b
				else
					gui.play_flipbook(b, blocker_anim(cell.blocker))
				end
			elseif b then
				ui.delete(b)
				self.blockers[k] = nil
			end
			-- covers
			local cv = self.covers[k]
			if cell.cover then
				if not cv then
					cv = ui.box(lx, ly, c * 0.98, c * 0.98, "board", cover_anim(cell), { parent = self.cover_c })
					self.covers[k] = cv
				else
					gui.play_flipbook(cv, cover_anim(cell))
				end
			elseif cv then
				ui.delete(cv)
				self.covers[k] = nil
			end
			local cr = self.corrupt[k]
			if cell.corrupt then
				if not cr then
					cr = ui.box(lx, ly, c * 0.98, c * 0.98, "board", "corruption", { parent = self.cover_c })
					gui.animate(cr, "color.w", 0.75, gui.EASING_INOUTSINE, 1.2, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
					self.corrupt[k] = cr
				end
			elseif cr then
				ui.delete(cr)
				self.corrupt[k] = nil
			end
		end
	end
	for uid in pairs(self.pieces) do
		if not seen[uid] then self:delete_piece(uid) end
	end
end

--- Update sprites of specific cells (tutorial rebuild).
function M:refresh_cells(cells)
	for _, c in ipairs(cells or {}) do
		local e = self.pieces[c.uid]
		if e then
			e.id, e.kind = c.id, c.kind
			self:decorate(e)
			local wx, wy = self:world_pos(c.x, c.y)
			effects.flash(wx, wy, "fx_glow", self.cell * 1.4, ui.hex("gold"), 0.4)
		end
	end
end

-- ------------------------------------------------------------ highlights --

function M:clear_highlights()
	for _, n in ipairs(self.highlights or {}) do ui.delete(n) end
	self.highlights = {}
end

function M:add_highlight(x, y, anim, color, pulse)
	self.highlights = self.highlights or {}
	local lx, ly = self:local_pos(x, y)
	local n = ui.box(lx, ly, self.cell * 1.05, self.cell * 1.05, "board", anim, { parent = self.hl_c, color = color, blend = anim == "hint_glow" and gui.BLEND_ADD or nil })
	if pulse ~= false then ui.pulse(n, 1.1, 0.45) end
	self.highlights[#self.highlights + 1] = n
	return n
end

function M:select(x, y, partners)
	self:clear_highlights()
	if not x then return end
	self:add_highlight(x, y, "select_ring")
	for _, p in ipairs(partners or {}) do
		self:add_highlight(p.x, p.y, "partner_ring", nil, true)
	end
	local e = self.board and self.board:piece(x, y) and self.pieces[self.board:piece(x, y).uid]
	if e then
		gui.animate(e.node, "scale", V3(1.15, 1.15, 1), gui.EASING_OUTBACK, 0.12, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
	end
end

function M:show_hint(move)
	self:clear_highlights()
	if not move then return end
	for _, c in ipairs({ move.a, move.b }) do self:add_highlight(c.x, c.y, "hint_glow", ui.hex("gold", 0.9)) end
	local p = self.board:piece(move.a.x, move.a.y)
	local e = p and self.pieces[p.uid]
	if e then
		local lx, ly = self:local_pos(move.a.x, move.a.y)
		local dx, dy = (move.b.x - move.a.x) * self.cell * 0.12, (move.a.y - move.b.y) * self.cell * 0.12
		gui.animate(e.node, "position", V3(lx + dx, ly + dy, 0), gui.EASING_INOUTSINE, 0.35, 0, function()
			gui.animate(e.node, "position", V3(lx, ly, 0), gui.EASING_INOUTSINE, 0.35)
		end)
	end
end

function M:floating_text(x, y, text, color, size)
	local lx, ly = self:local_pos(x, y)
	local t = ui.text(lx, ly, text, { parent = self.text_c, font = "title", size = size or 40, color = color or "gold" })
	gui.set_scale(t, gui.get_scale(t) * 0.3)
	gui.animate(t, "scale", gui.get_scale(t) * (1 / 0.3), gui.EASING_OUTBACK, 0.25)
	gui.animate(t, "position.y", ly + 70, gui.EASING_OUTQUAD, 0.9)
	gui.animate(t, "color.w", 0, gui.EASING_INQUAD, 0.4, 0.6, function() ui.delete(t) end)
end

-- --------------------------------------------------------------- events --

local H = {}

function H.swap(self, e)
	local d = self:dur(0.17)
	local ea, eb = self.pieces[e.ua], self.pieces[e.ub]
	local ax, ay = self:local_pos(e.a.x, e.a.y)
	local bx, by = self:local_pos(e.b.x, e.b.y)
	if ea then gui.animate(ea.node, "position", V3(bx, by, 0), gui.EASING_OUTSINE, d) end
	if eb then gui.animate(eb.node, "position", V3(ax, ay, 0), gui.EASING_OUTSINE, d) end
	self.ctx.audio.play("swap")
	return d
end

function H.invalid_swap(self, e)
	self.ctx.audio.play("invalid")
	local pa, pb = self.board:piece(e.a.x, e.a.y), self.board:piece(e.b.x, e.b.y)
	local ea, eb = pa and self.pieces[pa.uid], pb and self.pieces[pb.uid]
	local ax, ay = self:local_pos(e.a.x, e.a.y)
	local bx, by = self:local_pos(e.b.x, e.b.y)
	local d = self:dur(0.12)
	if e.reason == "no_match" and ea and eb then
		gui.animate(ea.node, "position", V3(bx, by, 0), gui.EASING_OUTSINE, d, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
		gui.animate(eb.node, "position", V3(ax, ay, 0), gui.EASING_OUTSINE, d, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
		return d * 2
	end
	for _, en in ipairs({ ea, eb }) do
		if en then
			gui.animate(en.node, "euler.z", 12, gui.EASING_INOUTSINE, 0.05, 0, function() gui.set_euler(en.node, V3(0, 0, 0)) end, gui.PLAYBACK_ONCE_PINGPONG)
		end
	end
	if self.callbacks.on_locked then self.callbacks.on_locked(e) end
	return 0.12
end

function H.fusion(self, e)
	local d = self:dur(0.5)
	local ea, eb = self.pieces[e.a.uid], self.pieces[e.b.uid]
	local tx, ty = self:local_pos(e.to.x, e.to.y)
	local wx, wy = self:world_pos(e.to.x, e.to.y)
	if ea then
		gui.animate(ea.node, "position", V3(tx, ty, 0), gui.EASING_INQUAD, d * 0.35)
		gui.animate(ea.node, "scale", V3(0.2, 0.2, 1), gui.EASING_INQUAD, d * 0.5, d * 0.2)
	end
	if eb then gui.animate(eb.node, "scale", V3(0.2, 0.2, 1), gui.EASING_INQUAD, d * 0.5, d * 0.2) end
	self.ctx.audio.play("fusion")
	local color = ui.rgb(elements.info[e.result].color)
	local function spawn_compound()
		self:delete_piece(e.a.uid)
		self:delete_piece(e.b.uid)
		local entry = self:create_piece({ uid = e.uid, id = e.result, kind = "compound" }, e.to.x, e.to.y)
		ui.pop_in(entry.node, 0, 1)
		self:decorate(entry)
		effects.flash(wx, wy, "fx_glow", self.cell * 2.6, color, 0.5)
		effects.flash(wx, wy, "fx_ring", self.cell * 1.6, vmath.vector4(1, 1, 1, 1), 0.45, 2)
		effects.burst(wx, wy, { count = 18, sprite = "fx_spark", color = color, speed = 240, size = 26 })
		local ca, cb = elements.info[e.a.id].color, elements.info[e.b.id].color
		effects.burst(wx, wy, { count = 8, sprite = "fx_dot", color = ui.rgb(ca), speed = 160 })
		effects.burst(wx, wy, { count = 8, sprite = "fx_dot", color = ui.rgb(cb), speed = 160 })
	end
	timer.delay(d * 0.55, false, spawn_compound)
	return d
end

function H.discovery(self, e)
	if self.callbacks.on_discovery then
		return self.callbacks.on_discovery(e) -- returns nil and calls done later
	end
	return 0
end

function H.match(self, e)
	local pitch = 1 + math.min(0.5, (e.cascade - 1) * 0.08)
	self.ctx.audio.play("match", { speed = pitch })
	for _, g in ipairs(e.groups) do
		if g.shape ~= "line3" then
			local c = g.cells[math.ceil(#g.cells / 2)]
			local key_t = g.shape == "line5" and "match.line5" or (g.shape == "cross" and "match.cross" or "match.line4")
			self:floating_text(c.x, c.y, self.ctx.L(key_t), g.shape == "line5" and "pink" or "gold", 40)
		end
		for _, c in ipairs(g.cells) do
			local wx, wy = self:world_pos(c.x, c.y)
			effects.flash(wx, wy, "fx_glow", self.cell * 1.3, ui.rgb(elements.info[g.id].color), 0.3)
		end
	end
	return self:dur(0.1)
end

function H.remove(self, e)
	local en = self.pieces[e.uid]
	local d = self:dur(0.24)
	local wx, wy = self:world_pos(e.x, e.y)
	local info = elements.info[e.id]
	local color = info and ui.rgb(info.color) or vmath.vector4(1, 1, 1, 1)
	if en then
		self.pieces[e.uid] = nil
		gui.cancel_animations(en.node, "scale")
		gui.animate(en.node, "scale", V3(1.25, 1.25, 1), gui.EASING_OUTQUAD, d * 0.4)
		gui.animate(en.node, "color.w", 0, gui.EASING_INQUAD, d * 0.6, d * 0.4, function() ui.delete(en.node) end)
	end
	effects.burst(wx, wy, { count = 6, sprite = e.id == "fire" and "fx_flame" or (e.id == "water" and "fx_drop" or (e.id == "earth" and "fx_shard" or "fx_spark")), color = color, speed = 150, size = 22, gravity = 120 })
	if self.callbacks.on_collect then self.callbacks.on_collect(e, wx, wy) end
	return d
end

function H.charge(self, e)
	local en = self.pieces[e.uid]
	local wx, wy = self:world_pos(e.x, e.y)
	if en then
		en.kind = "charged"
		timer.delay(self:dur(0.12), false, function()
			if self.pieces[e.uid] == en then
				self:decorate(en)
				ui.pop_in(en.node, 0, 1)
			end
		end)
	end
	effects.flash(wx, wy, "fx_ring", self.cell * 1.2, ui.rgb(elements.info[e.id].color), 0.5, 1.8)
	effects.burst(wx, wy, { count = 10, sprite = "fx_spark", color = ui.hex("gold"), speed = 180 })
	self.ctx.audio.play("charge")
	if self.callbacks.on_charge then self.callbacks.on_charge(e) end
	return self:dur(0.3)
end

local BREAK = {
	rock = { sprite = "fx_dot", sound = "rock_break" }, frost = { sprite = "fx_shard", sound = "frost_break" },
	vine = { sprite = "fx_leaf", sound = "vine_cut" }, corruption = { sprite = "fx_smoke", sound = "frost_break" },
}

function H.clear_obstacle(self, e)
	local k = key(e.x, e.y)
	local wx, wy = self:world_pos(e.x, e.y)
	local b = BREAK[e.obstacle] or BREAK.rock
	local node = (e.obstacle == "rock" and self.blockers[k]) or (e.obstacle == "corruption" and self.corrupt[k]) or self.covers[k]
	local color = ui.hex(OB_COLOR[e.obstacle] or "#FFFFFF")
	self.ctx.audio.play(b.sound, { speed = e.obstacle == "corruption" and 0.7 or 1 })
	effects.burst(wx, wy, { count = e.destroyed and 12 or 6, sprite = b.sprite, color = color, speed = 200, size = 24, gravity = 200, add = e.obstacle ~= "corruption" and false or nil })
	if node then
		if e.destroyed then
			if e.obstacle == "rock" then self.blockers[k] = nil elseif e.obstacle == "corruption" then self.corrupt[k] = nil else self.covers[k] = nil end
			gui.cancel_animations(node, "color.w")
			gui.animate(node, "scale", V3(1.3, 1.3, 1), gui.EASING_OUTQUAD, self:dur(0.2))
			gui.animate(node, "color.w", 0, gui.EASING_INQUAD, self:dur(0.2), 0, function() ui.delete(node) end)
		else
			local anim = e.obstacle == "rock" and "rock_hard_cracked" or (e.obstacle == "frost" and "frost_1" or nil)
			if anim then gui.play_flipbook(node, anim) end
			gui.animate(node, "position.x", gui.get_position(node).x + 5, gui.EASING_INOUTSINE, 0.05, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
		end
	end
	return self:dur(0.22)
end

function H.activate(self, e)
	local en = self.pieces[e.uid]
	local wx, wy = self:world_pos(e.x, e.y)
	self.ctx.audio.power(e.id)
	local color = ui.rgb(elements.info[e.id].color)
	if en then
		self.pieces[e.uid] = nil
		gui.cancel_animations(en.node, "scale")
		gui.animate(en.node, "scale", V3(1.6, 1.6, 1), gui.EASING_OUTBACK, self:dur(0.2))
		gui.animate(en.node, "color.w", 0, gui.EASING_INQUAD, self:dur(0.15), self:dur(0.15), function() ui.delete(en.node) end)
	end
	effects.flash(wx, wy, "fx_glow", self.cell * 3, color, 0.5)
	effects.flash(wx, wy, "fx_ring", self.cell * 1.5, vmath.vector4(1, 1, 1, 1), 0.4, 2.4)
	return self:dur(0.25)
end

local function power_beams(self, e, color)
	local wx, wy = self:world_pos(e.x, e.y)
	local size = self.cell * 8
	if e.id == "steam" or e.id == "storm" then
		effects.beam(wx, self.cy, self.cell * 1.1, size, "fx_beam_v", color, 0.55)
		for i = 1, 4 do effects.burst(wx, self.cy - size / 2 + i * size / 5, { count = 3, sprite = "fx_cloud", color = vmath.vector4(1, 1, 1, 1), speed = 70, size = 44, add = false }) end
	end
	if e.id == "plasma" or e.id == "storm" then
		effects.beam(self.cx, wy, size, self.cell * 1.1, "fx_beam", color, 0.55)
		effects.burst(wx, wy, { count = 16, sprite = "fx_spark", color = ui.hex("gold"), speed = 380, spread = 30, dir = 0 })
		effects.burst(wx, wy, { count = 16, sprite = "fx_spark", color = ui.hex("gold"), speed = 380, spread = 30, dir = 180 })
	end
	if e.id == "storm" then
		effects.burst(wx, wy, { count = 3, sprite = "fx_bolt", color = ui.hex("#BFE4FF"), speed = 120, size = 70, aspect = 2, life = 0.4 })
	end
end

function H.power(self, e)
	local color = ui.rgb(elements.info[e.id].color)
	local wx, wy = self:world_pos(e.x, e.y)
	local id = e.id
	if id == "steam" or id == "plasma" or id == "storm" then
		power_beams(self, e, color)
	elseif id == "lava" then
		effects.flash(wx, wy, "fx_glow", self.cell * 3.6, ui.hex("#FF7A1A"), 0.5)
		effects.burst(wx, wy, { count = 26, sprite = "fx_flame", color = vmath.vector4(1, 1, 1, 1), speed = 260, size = 34, add = false, gravity = -60 })
	elseif id == "ice" then
		effects.flash(wx + self.cell / 2, wy - self.cell / 2, "fx_glow", self.cell * 2.6, ui.hex("#BFF3FF"), 0.45)
		effects.burst(wx + self.cell / 2, wy - self.cell / 2, { count = 18, sprite = "fx_shard", color = ui.hex("#E6FAFF"), speed = 220, add = false, spin = 360 })
	elseif id == "dust" then
		for _, c in ipairs(e.cells) do
			local cx, cy = self:world_pos(c.x, c.y)
			effects.burst(cx, cy, { count = 6, sprite = "fx_grain", color = vmath.vector4(1, 1, 1, 1), speed = 120, add = false })
		end
		effects.beam(self.cx, wy, self.cell * 8, self.cell * 2, "fx_beam", ui.hex("#FFE8A3"), 0.6)
	elseif id == "obsidian" then
		effects.flash(wx, wy, "fx_glow", self.cell * 4, ui.hex("#9A4DFF"), 0.6)
		for _, c in ipairs(e.cells) do
			local cx, cy = self:world_pos(c.x, c.y)
			effects.flash(cx, cy, "fx_crack", self.cell * 1.1, ui.hex("#E0B0FF"), 0.5, 1.2)
		end
	elseif id == "life" or id == "forest" or id == "crystal" then
		local sprite = id == "crystal" and "fx_spark" or "fx_leaf"
		for _, c in ipairs(e.cells) do
			local cx, cy = self:world_pos(c.x, c.y)
			effects.fly(wx, wy, cx, cy, sprite, id == "crystal" and ui.hex("pink") or ui.hex("#8BE36E"), 34, self:dur(0.35))
		end
		effects.flash(wx, wy, "fx_glow", self.cell * 2.5, color, 0.5)
	end
	local slow = id == "life" or id == "forest" or id == "crystal"
	return self:dur(slow and 0.4 or 0.3)
end

function H.transform(self, e)
	local d = self:dur(0.3)
	for _, it in ipairs(e.items) do
		local en = self.pieces[it.uid]
		if en then
			en.id = it.to
			gui.animate(en.node, "scale.x", 0.05, gui.EASING_INQUAD, d / 2, 0, function()
				gui.play_flipbook(en.node, elements.sprite_for(en))
				gui.animate(en.node, "scale.x", 1, gui.EASING_OUTBACK, d / 2)
			end)
			local wx, wy = self:world_pos(it.x, it.y)
			effects.burst(wx, wy, { count = 5, sprite = "fx_leaf", color = vmath.vector4(1, 1, 1, 1), speed = 100, add = false })
		end
	end
	return d
end

function H.gravity(self, e)
	local longest = 0
	local spawn_ids = {}
	for _, s in ipairs(e.spawns) do spawn_ids[s.uid] = s end
	for _, uid in ipairs(e.order) do
		local path = e.paths[uid]
		local en = self.pieces[uid]
		local sp = spawn_ids[uid]
		if not en and sp then
			en = self:create_piece({ uid = uid, id = sp.id, kind = "base" }, sp.x, sp.y - sp.stack)
		end
		if en then
			local node = en.node
			gui.cancel_animations(node, "position")
			local segs = {}
			if sp then segs[1] = { x = sp.x, y = sp.y } end
			for i = 2, #path do segs[#segs + 1] = path[i] end
			local origin = sp and { x = sp.x, y = sp.y - sp.stack } or path[1]
			local total = 0
			local function step(i, prev)
				if i > #segs then return end
				local p = segs[i]
				local lx, ly = self:local_pos(p.x, p.y)
				if p.how == "portal" then
					local d1 = self:dur(0.09)
					gui.animate(node, "scale", V3(0.05, 0.05, 1), gui.EASING_INQUAD, d1, 0, function()
						gui.set_position(node, V3(lx, ly, 0))
						gui.animate(node, "scale", V3(1, 1, 1), gui.EASING_OUTBACK, d1, 0, function() step(i + 1, p) end)
					end)
				else
					local dist = prev and math.max(math.abs(p.y - prev.y), math.abs(p.x - prev.x)) or 1
					local d = self:dur(0.05 + 0.055 * dist)
					gui.animate(node, "position", V3(lx, ly, 0), i == #segs and gui.EASING_OUTBACK or gui.EASING_INQUAD, d, 0, function() step(i + 1, p) end)
				end
			end
			for i = 1, #segs do
				local p, prev = segs[i], segs[i - 1] or origin
				if p.how == "portal" then
					total = total + self:dur(0.18)
				else
					total = total + self:dur(0.05 + 0.055 * math.max(math.abs(p.y - prev.y), math.abs(p.x - prev.x)))
				end
			end
			step(1, origin)
			if total > longest then longest = total end
		end
	end
	return longest + 0.02
end

function H.cascade(self, e)
	local key_t = "combo." .. math.min(5, e.level)
	if self.callbacks.on_cascade then self.callbacks.on_cascade(e, self.ctx.L(key_t)) end
	self.ctx.audio.play("cascade", { speed = 1 + math.min(0.6, e.level * 0.07) })
	return 0
end

function H.conveyor(self, e)
	local d = self:dur(0.35)
	for _, mv in ipairs(e.moves) do
		local en = self.pieces[mv.uid]
		if en then
			local tx, ty = self:local_pos(mv.to.x, mv.to.y)
			if mv.wrap then
				gui.animate(en.node, "scale", V3(0.05, 0.05, 1), gui.EASING_INQUAD, d / 2, 0, function()
					gui.set_position(en.node, V3(tx, ty, 0))
					gui.animate(en.node, "scale", V3(1, 1, 1), gui.EASING_OUTBACK, d / 2)
				end)
			else
				gui.animate(en.node, "position", V3(tx, ty, 0), gui.EASING_INOUTSINE, d)
			end
		end
	end
	self.ctx.audio.play("swap", { speed = 0.7 })
	return d
end

function H.corruption_spread(self, e)
	local k = key(e.x, e.y)
	local lx, ly = self:local_pos(e.x, e.y)
	local wx, wy = self:world_pos(e.x, e.y)
	if not self.corrupt[k] then
		local n = ui.box(lx, ly, self.cell * 0.98, self.cell * 0.98, "board", "corruption", { parent = self.cover_c })
		ui.pop_in(n, 0, 1)
		self.corrupt[k] = n
	end
	effects.burst(wx, wy, { count = 10, sprite = "fx_smoke", color = ui.hex("#7A1FA8"), speed = 90, add = false })
	self.ctx.audio.play("invalid", { speed = 0.6 })
	return self:dur(0.35)
end

function H.shuffle(self, e)
	local d = self:dur(0.6)
	if self.callbacks.on_shuffle then self.callbacks.on_shuffle() end
	self.ctx.audio.play("shuffle")
	local recolor = {}
	for _, r in ipairs(e.recolor or {}) do recolor[r.uid] = r.id end
	for _, mv in ipairs(e.moves) do
		local en = self.pieces[mv.uid]
		if en then
			local tx, ty = self:local_pos(mv.to.x, mv.to.y)
			gui.animate(en.node, "position", V3(0, 0, 0), gui.EASING_INQUAD, d / 2, 0, function()
				if recolor[mv.uid] then
					en.id = recolor[mv.uid]
					gui.play_flipbook(en.node, elements.sprite_for(en))
				end
				gui.animate(en.node, "position", V3(tx, ty, 0), gui.EASING_OUTBACK, d / 2)
			end)
		end
	end
	return d + 0.05
end

local PASSTHROUGH = { score = true, objective_progress = true, moves = true, victory = true, defeat = true }
local PARALLEL = { remove = true, charge = true, clear_obstacle = true, transform = true, cascade = true }

--- Queue a list of events. `on_done` runs when every animation finished.
function M:play(events, on_done)
	for _, e in ipairs(events) do
		local h = H[e.type]
		if PASSTHROUGH[e.type] then
			self.queue:push(function()
				if self.callbacks.on_event then self.callbacks.on_event(e) end
				return 0
			end, { parallel = true })
		elseif h then
			self.queue:push(function(done)
				local d = h(self, e)
				if d == nil and e.type == "discovery" then
					self.pending_done = done
				end
				return d
			end, { parallel = PARALLEL[e.type] or false })
		end
	end
	self.queue:push(function()
		if self.board then self:sync(self.board) end
		if on_done then on_done() end
		return 0
	end)
end

--- Called by the owner when a blocking step (discovery popup) is finished.
function M:resume()
	local d = self.pending_done
	self.pending_done = nil
	if d then d() end
end

function M:busy()
	return self.queue:busy()
end

function M:update(dt)
	self.queue:update(dt)
end

function M:destroy()
	self.queue:clear()
	ui.delete(self.root)
end

return M
