-- Modal popup: dimmed background, framed panel with title ribbon and buttons.
local ui = require "gui.ui"
local screens = require "gui.screen_manager"

local M = {}
M.__index = M

local V3 = vmath.vector3

--- opts: { w, h, title, y, build = function(popup) end, on_close, closable (X button), dim }
function M.open(opts)
	local self = setmetatable({ opts = opts, buttons = ui.buttons(), closed = false }, M)
	local m = ui.metrics()
	self.root = ui.container(screens.layers.popup, 0, 0)
	self.dim = ui.box(m.cx, m.cy, m.vw + 40, m.vh + 40, "ui", "white", { parent = self.root, color = "dim", alpha = opts.dim or 0.72 })
	ui.fade_in(self.dim, 0.2)
	local w, h = opts.w or 600, opts.h or 640
	self.cx, self.cy = m.cx, opts.y or m.cy
	self.panel = ui.box(self.cx, self.cy, w, h, "ui", opts.style or "panel", { parent = self.root, slice = 46 })
	self.w, self.h = w, h
	if opts.title then
		local r = ui.box(0, h / 2 - 6, math.min(w - 40, 520), 104, "ui", "ribbon", { parent = self.panel })
		self.title = ui.text(0, 12, opts.title, { parent = r, font = "title", size = 40, outline = "#8A4F00" })
	end
	if opts.closable then
		self.buttons:add(self.panel, w / 2 - 30, h / 2 - 30, 84, 84, nil, "round", function() self:close() end, { icon = "close", icon_size = 44 })
	end
	if opts.build then opts.build(self) end
	if not (screens.ctx and screens.ctx.settings.reduced_motion) then
		ui.pop_in(self.panel)
	end
	screens.push(self)
	return self
end

function M:on_input(action_id, action)
	self.buttons:on_input(action_id, action)
	if self.opts.on_input then self.opts.on_input(self, action_id, action) end
end

function M:on_back()
	if self.opts.closable or self.opts.on_back then
		if self.opts.on_back then self.opts.on_back(self) else self:close() end
	end
end

function M:update(dt)
	if self.opts.update then self.opts.update(self, dt) end
end

function M:destroy()
	if self.closed then return end
	self.closed = true
	if self.opts.on_destroy then self.opts.on_destroy(self) end
	ui.delete(self.root)
end

function M:close(...)
	if self.closed then return end
	screens.remove(self)
	local args = { ... }
	gui.animate(self.panel, "scale", V3(0.85, 0.85, 1), gui.EASING_INQUAD, 0.1)
	gui.animate(self.dim, "color.w", 0, gui.EASING_INQUAD, 0.12, 0, function()
		self:destroy()
	end)
	if self.opts.on_close then self.opts.on_close(self, unpack(args)) end
end

return M
