-- Element-specific particle effects for explosions (pieces removed) and fusions.
-- fire: flames rising + embers   water: splash drops + ripple + bubbles
-- earth: gem chips falling + dust  air: wind gusts + spiral + puffs
-- Compounds have their own signature burst when they are created.
local ui = require "gui.ui"
local effects = require "scripts.effects"
local elements = require "data.elements"

local M = {}

local function col(id, a)
	local info = elements.info[id]
	return info and ui.rgb(info.color, a) or vmath.vector4(1, 1, 1, a or 1)
end

local WHITE = vmath.vector4(1, 1, 1, 1)

local EXPLODE = {
	fire = function(x, y, s, big)
		effects.flash(x, y, "fx_glow", s * 1.6, ui.hex("#FF9A3C"), 0.28)
		effects.burst(x, y, { count = big and 9 or 6, sprite = "fx_flame", color = WHITE, add = false, speed = 120, size = s * 0.42, aspect = 1.3, dir = 90, spread = 120, gravity = -260, life = 0.45 })
		effects.burst(x, y, { count = big and 10 or 7, sprite = "fx_ember", color = ui.hex("#FFD36A"), speed = 260, size = s * 0.16, aspect = 1.6, gravity = -80, life = 0.5 })
	end,
	water = function(x, y, s, big)
		effects.flash(x, y, "fx_ring", s * 0.9, ui.hex("#BFF3FF"), 0.35, 2.0)
		effects.burst(x, y, { count = big and 10 or 7, sprite = "fx_drop", color = WHITE, add = false, speed = 230, size = s * 0.26, aspect = 1.35, dir = 90, spread = 200, gravity = 900, life = 0.5 })
		effects.burst(x, y, { count = big and 6 or 4, sprite = "fx_bubble", color = ui.hex("#DFF9FF"), add = false, speed = 70, size = s * 0.22, gravity = -220, life = 0.6 })
	end,
	earth = function(x, y, s, big)
		effects.flash(x, y, "fx_glow", s * 1.2, ui.hex("#8CF7B8"), 0.25)
		effects.burst(x, y, { count = big and 9 or 6, sprite = "fx_chip", color = ui.hex("#51D989"), add = false, speed = 210, size = s * 0.28, dir = 90, spread = 160, gravity = 1100, spin = 540, life = 0.55 })
		effects.burst(x, y, { count = 4, sprite = "fx_smoke", color = ui.hex("#C8B48A", 0.8), add = false, speed = 60, size = s * 0.5, life = 0.5 })
	end,
	air = function(x, y, s, big)
		effects.flash(x, y, "fx_swirl", s * 1.1, ui.hex("#E6DCFF"), 0.35, 1.8)
		effects.burst(x, y, { count = big and 6 or 4, sprite = "fx_wind", color = ui.hex("#F2ECFF"), speed = 220, size = s * 0.5, aspect = 0.5, life = 0.4 })
		effects.burst(x, y, { count = big and 6 or 4, sprite = "fx_smoke", color = ui.hex("#D9C8FF", 0.85), add = false, speed = 120, size = s * 0.42, life = 0.45 })
	end,
}

--- A piece of element `id` disappears at (x, y). `s` = cell size.
function M.explode(id, kind, x, y, s)
	local f = EXPLODE[id]
	if f then f(x, y, s, kind == "charged") end
	if kind == "charged" then
		effects.burst(x, y, { count = 8, sprite = "fx_spark", color = ui.hex("gold"), speed = 260, size = s * 0.3 })
	end
end

--- Small trail while a piece slides into the charge cell.
function M.trail(id, x, y, tx, ty, s, d)
	effects.fly(x, y, tx, ty, id == "fire" and "fx_ember" or (id == "water" and "fx_bubble" or (id == "earth" and "fx_chip" or "fx_spark")),
		col(id), s * 0.3, d)
end

-- signature burst of each compound when it is created
local COMPOUND = {
	steam = { "fx_cloud", "#FFFFFF", false, -160 },
	lava = { "fx_flame", "#FFFFFF", false, -200 },
	plasma = { "fx_spark", "#E3B5FF", true, 0 },
	life = { "fx_leaf", "#FFFFFF", false, 300 },
	ice = { "fx_shard", "#E6FAFF", false, 500 },
	dust = { "fx_grain", "#FFFFFF", false, 400 },
	storm = { "fx_bolt", "#BFE4FF", true, 0 },
	obsidian = { "fx_chip", "#9A4DFF", false, 700 },
	forest = { "fx_leaf", "#FFFFFF", false, 250 },
	crystal = { "fx_star", "#FF9AD5", true, 0 },
}

--- Two ingredients spiral into the destination, then the compound appears.
--- a_pos / b_pos / to_pos = {x, y} in GUI coordinates.
function M.fusion_gather(a_id, b_id, a_pos, b_pos, to_pos, s, d)
	for _, src in ipairs({ { a_id, a_pos }, { b_id, b_pos } }) do
		for i = 1, 5 do
			local ang = i * 1.26
			local ox, oy = math.cos(ang) * s * 0.5, math.sin(ang) * s * 0.5
			effects.fly(src[2].x + ox, src[2].y + oy, to_pos.x, to_pos.y, "fx_spark", col(src[1]), s * 0.28, d * (0.6 + i * 0.08))
		end
	end
end

function M.fusion_burst(result, x, y, s)
	local c = COMPOUND[result] or { "fx_spark", "#FFFFFF", true, 0 }
	effects.flash(x, y, "fx_glow", s * 2.8, col(result), 0.5)
	effects.flash(x, y, "fx_ring", s * 1.4, WHITE, 0.45, 2.4)
	effects.burst(x, y, { count = 14, sprite = c[1], color = ui.hex(c[2]), add = c[3], speed = 280, size = s * 0.38, gravity = c[4], spin = 360, life = 0.6,
		aspect = c[1] == "fx_bolt" and 2 or nil })
	effects.burst(x, y, { count = 12, sprite = "fx_spark", color = ui.hex("gold"), speed = 320, size = s * 0.26 })
end

return M
