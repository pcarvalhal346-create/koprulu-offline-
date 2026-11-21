-- Lightweight GUI particle system. A fixed pool of box nodes is recycled,
-- so effects never create nodes per frame. Honours "reduce animations".
local M = {}

M.POOL = 160
M.reduced = false

local V3 = vmath.vector3
local pool, free, root = {}, {}, nil

function M.init(parent_layer_node)
	root = parent_layer_node
	pool, free = {}, {}
	for i = 1, M.POOL do
		local n = gui.new_box_node(V3(0, 0, 0), V3(32, 32, 0))
		gui.set_texture(n, "fx")
		gui.play_flipbook(n, "fx_dot")
		gui.set_size_mode(n, gui.SIZE_MODE_MANUAL)
		gui.set_parent(n, root)
		gui.set_enabled(n, false)
		gui.set_blend_mode(n, gui.BLEND_ADD)
		pool[i] = n
		free[#free + 1] = n
	end
end

local function take()
	local n = table.remove(free)
	if n then gui.set_enabled(n, true) end
	return n
end

local function release(_, n)
	gui.cancel_animations(n, "position")
	gui.cancel_animations(n, "scale")
	gui.cancel_animations(n, "color")
	gui.cancel_animations(n, "euler")
	gui.set_enabled(n, false)
	free[#free + 1] = n
end

--- Burst of particles.
--- opts: { count, sprite, color (vector4), speed, life, size, spread (deg), dir (deg), gravity, add (bool), spin }
function M.burst(x, y, opts)
	if not root then return end
	opts = opts or {}
	local count = opts.count or 10
	if M.reduced then count = math.max(1, math.floor(count / 3)) end
	local life = opts.life or 0.55
	for _ = 1, count do
		local n = take()
		if not n then return end
		gui.play_flipbook(n, opts.sprite or "fx_dot")
		gui.set_blend_mode(n, opts.add == false and gui.BLEND_ALPHA or gui.BLEND_ADD)
		local size = (opts.size or 26) * (0.6 + math.random() * 0.8)
		gui.set_size(n, V3(size, size * (opts.aspect or 1), 0))
		gui.set_position(n, V3(x, y, 0))
		local c = opts.color or vmath.vector4(1, 1, 1, 1)
		gui.set_color(n, vmath.vector4(c.x, c.y, c.z, 1))
		gui.set_scale(n, V3(1, 1, 1))
		gui.set_euler(n, V3(0, 0, math.random() * 360))
		local spread = math.rad(opts.spread or 360)
		local dir = math.rad(opts.dir or 90)
		local a = dir + (math.random() - 0.5) * spread
		local sp = (opts.speed or 160) * (0.4 + math.random() * 0.8)
		local tx, ty = x + math.cos(a) * sp * life, y + math.sin(a) * sp * life - (opts.gravity or 0) * life * life * 0.5
		local l = life * (0.7 + math.random() * 0.5)
		gui.animate(n, "position", V3(tx, ty, 0), gui.EASING_OUTQUAD, l)
		gui.animate(n, "scale", V3(0.2, 0.2, 1), gui.EASING_INQUAD, l)
		gui.animate(n, "color.w", 0, gui.EASING_INQUAD, l, 0, release)
		if opts.spin then gui.animate(n, "euler.z", math.random(-1, 1) * opts.spin, gui.EASING_LINEAR, l) end
	end
end

--- Single sprite that grows and fades (flash, ring, glow).
function M.flash(x, y, sprite, size, color, life, to_scale)
	if not root then return end
	local n = take()
	if not n then return end
	gui.play_flipbook(n, sprite or "fx_glow")
	gui.set_blend_mode(n, gui.BLEND_ADD)
	gui.set_size(n, V3(size, size, 0))
	gui.set_position(n, V3(x, y, 0))
	gui.set_euler(n, V3(0, 0, 0))
	local c = color or vmath.vector4(1, 1, 1, 1)
	gui.set_color(n, vmath.vector4(c.x, c.y, c.z, c.w or 1))
	gui.set_scale(n, V3(0.3, 0.3, 1))
	life = M.reduced and (life or 0.4) * 0.6 or (life or 0.4)
	local s = to_scale or 1.4
	gui.animate(n, "scale", V3(s, s, 1), gui.EASING_OUTQUAD, life)
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, life, 0, release)
end

--- Stretched sprite (beam) between two points.
function M.beam(x, y, w, h, sprite, color, life)
	if not root then return end
	local n = take()
	if not n then return end
	gui.play_flipbook(n, sprite or "fx_beam")
	gui.set_blend_mode(n, gui.BLEND_ADD)
	gui.set_size(n, V3(w, h, 0))
	gui.set_position(n, V3(x, y, 0))
	gui.set_euler(n, V3(0, 0, 0))
	gui.set_scale(n, V3(1, 0.2, 1))
	local c = color or vmath.vector4(1, 1, 1, 1)
	gui.set_color(n, vmath.vector4(c.x, c.y, c.z, 1))
	life = life or 0.45
	gui.animate(n, "scale", V3(1, 1, 1), gui.EASING_OUTBACK, life * 0.4)
	gui.animate(n, "color.w", 0, gui.EASING_INQUAD, life, life * 0.3, release)
end

--- Particle that flies from a point to another (e.g. towards a goal counter).
function M.fly(x, y, tx, ty, sprite, color, size, life, on_done)
	if not root then return end
	local n = take()
	if not n then return end
	gui.play_flipbook(n, sprite or "fx_star")
	gui.set_blend_mode(n, gui.BLEND_ADD)
	gui.set_size(n, V3(size or 30, size or 30, 0))
	gui.set_position(n, V3(x, y, 0))
	local c = color or vmath.vector4(1, 0.9, 0.5, 1)
	gui.set_color(n, vmath.vector4(c.x, c.y, c.z, 1))
	gui.set_scale(n, V3(1, 1, 1))
	life = life or 0.6
	gui.animate(n, "position", V3(tx, ty, 0), gui.EASING_INOUTQUAD, life, 0, function(s, node)
		release(s, node)
		if on_done then on_done() end
	end)
end

--- Confetti rain for victories.
function M.confetti(m, count)
	local colors = { "#FF623F", "#36C9F6", "#51D989", "#B593FF", "#FFD36A", "#FF75C9" }
	count = count or 50
	if M.reduced then count = 12 end
	for i = 1, count do
		local n = take()
		if not n then return end
		gui.play_flipbook(n, "fx_confetti")
		gui.set_blend_mode(n, gui.BLEND_ALPHA)
		gui.set_size(n, V3(14, 24, 0))
		local x = m.left + math.random() * m.vw
		gui.set_position(n, V3(x, m.top + 30 + math.random() * 200, 0))
		local hx = colors[(i % #colors) + 1]
		local r, g, b = tonumber(hx:sub(2, 3), 16) / 255, tonumber(hx:sub(4, 5), 16) / 255, tonumber(hx:sub(6, 7), 16) / 255
		gui.set_color(n, vmath.vector4(r, g, b, 1))
		gui.set_scale(n, V3(1, 1, 1))
		local life = 1.8 + math.random() * 1.4
		gui.animate(n, "position", V3(x + (math.random() - 0.5) * 240, m.bottom + 100 + math.random() * 300, 0), gui.EASING_INQUAD, life)
		gui.animate(n, "euler.z", (math.random() - 0.5) * 1080, gui.EASING_LINEAR, life)
		gui.animate(n, "color.w", 0, gui.EASING_INQUART, life, 0, release)
	end
end

function M.clear()
	for _, n in ipairs(pool) do
		if gui.is_enabled(n) then release(nil, n) end
	end
end

return M
