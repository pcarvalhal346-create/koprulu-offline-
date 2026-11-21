-- Tutorial overlay: dims everything except the relevant cells, pulses them,
-- and animates a hand demonstrating the gesture. Text is shown by the shared
-- Lumi dialogue (gui/dialog.lua) owned by the game screen.
local ui = require "gui.ui"

local M = {}
M.__index = M

local V3 = vmath.vector3

function M.create(parent, board_view)
	local self = setmetatable({ bv = board_view, nodes = {} }, M)
	self.root = ui.container(parent, 0, 0)
	return self
end

function M:clear()
	for _, n in ipairs(self.nodes) do ui.delete(n) end
	self.nodes = {}
end

local function add(self, n)
	self.nodes[#self.nodes + 1] = n
	return n
end

--- Dark veil around the rectangle (x0,y0)-(x1,y1) in GUI coordinates.
function M:dim_around(x0, y0, x1, y1)
	local m = ui.metrics()
	local col = ui.hex("dim", 0.68)
	local function rect(ax, ay, bx, by)
		if bx - ax <= 0 or by - ay <= 0 then return end
		local n = add(self, ui.box((ax + bx) / 2, (ay + by) / 2, bx - ax, by - ay, "ui", "white", { parent = self.root, color = col }))
		ui.fade_in(n, 0.25)
	end
	local L, R, B, T = m.left - 10, m.right + 10, m.bottom - 10, m.top + 10
	rect(L, y1, R, T)
	rect(L, B, R, y0)
	rect(L, y0, x0, y1)
	rect(x1, y0, R, y1)
end

--- step: tutorial step table; tm: tutorial manager (cells / move / target already resolved)
function M:show(step, tm)
	self:clear()
	if not step then return end
	local bv = self.bv
	local cell = bv.cell
	local cells = tm.cells or {}
	local guided = step.kind ~= "say"
	if guided and #cells > 0 then
		local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
		for _, c in ipairs(cells) do
			local wx, wy = bv:world_pos(c.x, c.y)
			x0, x1 = math.min(x0, wx - cell / 2), math.max(x1, wx + cell / 2)
			y0, y1 = math.min(y0, wy - cell / 2), math.max(y1, wy + cell / 2)
		end
		self:dim_around(x0 - 6, y0 - 6, x1 + 6, y1 + 6)
	end
	for _, c in ipairs(cells) do
		local wx, wy = bv:world_pos(c.x, c.y)
		local ring = add(self, ui.box(wx, wy, cell * 1.12, cell * 1.12, "board", guided and "select_ring" or "partner_ring", { parent = self.root }))
		ui.pulse(ring, 1.1, 0.45)
		if guided then
			local g = add(self, ui.box(wx, wy, cell * 1.6, cell * 1.6, "board", "hint_glow", { parent = self.root, blend = gui.BLEND_ADD, alpha = 0.6 }))
			ui.pulse(g, 1.15, 0.5)
		end
	end
	-- animated hand
	if step.kind == "swap" and tm.move then
		local ax, ay = bv:world_pos(tm.move.a.x, tm.move.a.y)
		local bx, by = bv:world_pos(tm.move.b.x, tm.move.b.y)
		local hand = add(self, ui.box(ax + 30, ay - 40, 96, 96, "ui", "hand", { parent = self.root }))
		local function loop()
			if not self.nodes[1] then return end
			gui.set_position(hand, V3(ax + 30, ay - 40, 0))
			gui.set_color(hand, vmath.vector4(1, 1, 1, 1))
			gui.animate(hand, "scale", V3(0.85, 0.85, 1), gui.EASING_OUTQUAD, 0.2, 0.1)
			gui.animate(hand, "position", V3(bx + 30, by - 40, 0), gui.EASING_INOUTQUAD, 0.6, 0.35)
			gui.animate(hand, "scale", V3(1, 1, 1), gui.EASING_OUTQUAD, 0.2, 0.95)
			gui.animate(hand, "color.w", 0, gui.EASING_INQUAD, 0.25, 1.05, function() loop() end)
		end
		loop()
	elseif (step.kind == "select" or step.kind == "activate") and tm.target then
		local tx, ty = bv:world_pos(tm.target.x, tm.target.y)
		local hand = add(self, ui.box(tx + 30, ty - 40, 96, 96, "ui", "hand", { parent = self.root }))
		gui.animate(hand, "scale", V3(0.82, 0.82, 1), gui.EASING_INOUTSINE, 0.35, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	end
end

function M:destroy()
	self:clear()
	ui.delete(self.root)
end

return M
