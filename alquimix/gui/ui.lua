-- GUI helpers shared by every screen: layout metrics for any aspect ratio,
-- node factories, buttons with press feedback, colours and tweens.
-- Only gui/* and scripts/effects.lua talk to the Defold gui API.
local M = {}

M.REF_W, M.REF_H = 720, 1280
M.FONT_SIZE = { title = 56, body = 40 }

M.COLORS = {
	fire = "#FF623F", water = "#36C9F6", earth = "#51D989", air = "#B593FF",
	gold = "#FFD36A", navy = "#15224E", violet = "#6553D9", pink = "#FF75C9",
	white = "#FFFFFF", ink = "#2A1460", dim = "#0A0F2A", green = "#7CF0AE", red = "#FF6B6B",
}

function M.hex(h, a)
	h = M.COLORS[h] or h
	local r = tonumber(h:sub(2, 3), 16) / 255
	local g = tonumber(h:sub(4, 5), 16) / 255
	local b = tonumber(h:sub(6, 7), 16) / 255
	return vmath.vector4(r, g, b, a or 1)
end

function M.rgb(t, a)
	return vmath.vector4(t[1], t[2], t[3], a or 1)
end

-- ---------------------------------------------------------------- layout --

--- Visible GUI rectangle (reference 720x1280, FIT adjust, centred) and safe area.
function M.metrics()
	local w, h = window.get_size()
	if not w or w <= 0 then w, h = M.REF_W, M.REF_H end
	local s = math.min(w / M.REF_W, h / M.REF_H)
	local vw, vh = w / s, h / s
	local m = {
		scale = s, vw = vw, vh = vh, cx = M.REF_W / 2, cy = M.REF_H / 2,
		left = (M.REF_W - vw) / 2, right = M.REF_W + (vw - M.REF_W) / 2,
		bottom = (M.REF_H - vh) / 2, top = M.REF_H + (vh - M.REF_H) / 2,
	}
	local inset = { top = 0, bottom = 0, left = 0, right = 0 }
	if window.get_safe_area then
		local ok, sa = pcall(window.get_safe_area)
		if ok and type(sa) == "table" then
			inset.top = (sa.inset_top or 0) / s
			inset.bottom = (sa.inset_bottom or 0) / s
			inset.left = (sa.inset_left or 0) / s
			inset.right = (sa.inset_right or 0) / s
		end
	end
	m.safe_top = m.top - inset.top
	m.safe_bottom = m.bottom + inset.bottom
	m.safe_left = m.left + inset.left
	m.safe_right = m.right - inset.right
	M.m = m
	return m
end

--- Convert an input action position to GUI coordinates.
function M.to_gui(action)
	local m = M.m or M.metrics()
	return m.left + action.x * m.vw / M.REF_W, m.bottom + action.y * m.vh / M.REF_H
end

--- Scale factor from input deltas to GUI units (vertical).
function M.input_scale()
	local m = M.m or M.metrics()
	return m.vh / M.REF_H
end

-- ----------------------------------------------------------------- nodes --

local V3 = vmath.vector3

function M.container(parent, x, y, layer)
	local n = gui.new_box_node(V3(x or 0, y or 0, 0), V3(1, 1, 0))
	gui.set_visible(n, false)
	if parent then gui.set_parent(n, parent) end
	if layer then gui.set_layer(n, layer) end
	return n
end

--- Textured (or plain) box.
--- opts: { parent, color, alpha, slice, pivot, blend, inherit (default true), layer }
function M.box(x, y, w, h, texture, anim, opts)
	opts = opts or {}
	local n = gui.new_box_node(V3(x, y, 0), V3(w, h, 0))
	if texture then
		gui.set_texture(n, texture)
		gui.play_flipbook(n, anim)
	end
	gui.set_size_mode(n, gui.SIZE_MODE_MANUAL)
	gui.set_size(n, V3(w, h, 0))
	if opts.parent then gui.set_parent(n, opts.parent) end
	if opts.color then gui.set_color(n, type(opts.color) == "string" and M.hex(opts.color, opts.alpha) or opts.color) end
	if opts.alpha and not opts.color then gui.set_color(n, vmath.vector4(1, 1, 1, opts.alpha)) end
	if opts.slice then gui.set_slice9(n, vmath.vector4(opts.slice, opts.slice, opts.slice, opts.slice)) end
	if opts.pivot then gui.set_pivot(n, opts.pivot) end
	if opts.blend then gui.set_blend_mode(n, opts.blend) end
	if opts.layer then gui.set_layer(n, opts.layer) end
	gui.set_inherit_alpha(n, opts.inherit ~= false)
	return n
end

--- Text node. size = desired glyph height in GUI units.
--- opts: { parent, font = "body"|"title", size, color, outline, width (wrap), pivot, align, leading }
function M.text(x, y, str, opts)
	opts = opts or {}
	local font = opts.font or "body"
	local n = gui.new_text_node(V3(x, y, 0), str or "")
	gui.set_font(n, font)
	local s = (opts.size or 30) / M.FONT_SIZE[font]
	gui.set_scale(n, V3(s, s, 1))
	if opts.parent then gui.set_parent(n, opts.parent) end
	gui.set_color(n, type(opts.color) == "userdata" and opts.color or M.hex(opts.color or "white"))
	gui.set_outline(n, type(opts.outline) == "userdata" and opts.outline or M.hex(opts.outline or "ink"))
	gui.set_shadow(n, vmath.vector4(0, 0, 0, 0))
	if opts.width then
		gui.set_line_break(n, true)
		gui.set_size(n, V3(opts.width / s, 400 / s, 0))
	end
	if opts.leading then gui.set_leading(n, opts.leading) end
	if opts.pivot then gui.set_pivot(n, opts.pivot) end
	gui.set_inherit_alpha(n, true)
	return n
end

function M.set_text(n, str)
	gui.set_text(n, str)
end

function M.delete(n)
	if n then pcall(gui.delete_node, n) end
end

-- --------------------------------------------------------------- tweens --

function M.pop_in(n, delay, to_scale)
	to_scale = to_scale or 1
	gui.set_scale(n, V3(0.01, 0.01, 1))
	gui.animate(n, "scale", V3(to_scale, to_scale, 1), gui.EASING_OUTBACK, 0.35, delay or 0)
end

--- Fade from transparent to the node's current alpha.
function M.fade_in(n, d, delay)
	local c = gui.get_color(n)
	local target = c.w
	c.w = 0
	gui.set_color(n, c)
	gui.animate(n, "color.w", target, gui.EASING_OUTQUAD, d or 0.25, delay or 0)
end

function M.pulse(n, amount, period)
	local s = gui.get_scale(n)
	gui.animate(n, "scale", s * (amount or 1.08), gui.EASING_INOUTSINE, period or 0.9, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end

function M.float(n, dy, period)
	local p = gui.get_position(n)
	gui.animate(n, "position.y", p.y + (dy or 10), gui.EASING_INOUTSINE, period or 1.6, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end

-- -------------------------------------------------------------- buttons --

--- A button group handles hit testing and press feedback for one screen/popup.
local Group = {}
Group.__index = Group

function M.buttons()
	return setmetatable({ list = {}, pressed = nil, enabled = true }, Group)
end

--- style: "primary" | "secondary" | "danger" | "green" | "round" | "round_gold" | "icon"
function Group:add(parent, x, y, w, h, label, style, cb, opts)
	opts = opts or {}
	style = style or "primary"
	local anim = ({ primary = "btn_primary", secondary = "btn_secondary", danger = "btn_danger", green = "btn_green",
		round = "btn_round", round_gold = "btn_round_gold" })[style]
	local n
	if anim then
		n = M.box(x, y, w, h, "ui", anim, { parent = parent, slice = (not style:find("round")) and 40 or nil })
	else
		n = M.box(x, y, w, h, nil, nil, { parent = parent, color = vmath.vector4(1, 1, 1, 0) })
	end
	local b = { node = n, cb = cb, enabled = true, base = vmath.vector3(1, 1, 1) }
	if opts.icon then
		local isz = opts.icon_size or math.min(w, h) * 0.55
		local ix = label and (-w / 2 + isz * 0.5 + 22) or 0
		b.icon = M.box(ix, label and 0 or 4, isz, isz, "ui", "icon_" .. opts.icon, { parent = n })
	end
	if label then
		local tx = opts.icon and (opts.icon_size or h * 0.55) * 0.5 + 6 or 0
		b.label = M.text(tx, 4, label, { parent = n, font = opts.font or "title", size = opts.size or math.min(34, h * 0.4), color = "white", outline = opts.outline or "ink" })
	end
	self.list[#self.list + 1] = b
	return b
end

function Group:set_enabled(b, on)
	b.enabled = on
	gui.set_color(b.node, on and vmath.vector4(1, 1, 1, 1) or vmath.vector4(0.55, 0.55, 0.6, 1))
end

local function hit(b, action)
	return b.enabled and gui.is_enabled(b.node, true) and gui.pick_node(b.node, action.x, action.y)
end

--- Returns true when the input was consumed by a button.
function Group:on_input(action_id, action)
	if not self.enabled or action_id ~= hash("touch") then return false end
	if action.pressed then
		for i = #self.list, 1, -1 do
			local b = self.list[i]
			if hit(b, action) then
				self.pressed = b
				gui.animate(b.node, "scale", V3(0.92, 0.92, 1), gui.EASING_OUTQUAD, 0.06)
				return true
			end
		end
		return false
	elseif action.released and self.pressed then
		local b = self.pressed
		self.pressed = nil
		gui.animate(b.node, "scale", V3(1, 1, 1), gui.EASING_OUTBACK, 0.18)
		if hit(b, action) and b.cb then
			if M.on_click then M.on_click() end
			b.cb(b)
		end
		return true
	end
	return self.pressed ~= nil
end

return M
