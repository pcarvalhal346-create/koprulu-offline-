-- Lumi dialogue box: animated portrait, typewriter text, "tap to continue"
-- and an optional "Saltar" (skip) button. Used by the intro, tutorials,
-- level tips and story sequences.
local ui = require "gui.ui"
local lumi_view = require "gui.lumi_view"
local L = require "scripts.localization"

local M = {}
M.__index = M

local function utf8_chars(s)
	local t = {}
	for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do t[#t + 1] = ch end
	return t
end

--- opts: { y (centre), skip = bool, on_skip, on_continue, sound = fn }
function M.create(parent, opts)
	opts = opts or {}
	local m = ui.metrics()
	local self = setmetatable({ opts = opts, buttons = ui.buttons(), visible = false, chars = {}, shown = 0, t = 0 }, M)
	self.y = opts.y or (m.safe_bottom + 170)
	self.root = ui.container(parent, 0, 0)
	self.panel = ui.box(m.cx + 70, self.y, 560, 236, "ui", "bubble", { parent = self.root, slice = 44 })
	self.text = ui.text(-250, 70, "", { parent = self.panel, size = 30, width = 500, color = "#2A1460", outline = "#FFFFFF", pivot = gui.PIVOT_NW, leading = 0.95 })
	self.hint = ui.text(250, -92, L("common.tap_continue"), { parent = self.panel, size = 22, color = "violet", outline = "#FFFFFF", pivot = gui.PIVOT_E })
	gui.animate(self.hint, "color.w", 0.3, gui.EASING_INOUTSINE, 0.7, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	self.lumi = lumi_view.create(self.root, m.cx - 255, self.y + 30, 0.5)
	if opts.skip ~= false then
		self.skip_btn = self.buttons:add(self.panel, 210, 140, 160, 64, L("common.skip"), "secondary", function()
			if self.opts.on_skip then self.opts.on_skip() end
		end, { size = 24 })
	end
	gui.set_enabled(self.root, false)
	return self
end

--- Show a line. opts: { tap = bool (show tap hint), mood }
function M:say(text, mood, opts)
	opts = opts or {}
	gui.set_enabled(self.root, true)
	if not self.visible then
		self.visible = true
		ui.pop_in(self.panel, 0, 1)
		gui.set_color(self.root, vmath.vector4(1, 1, 1, 1))
		if self.opts.sound then self.opts.sound() end
	end
	self.chars = utf8_chars(text)
	self.full = text
	self.shown = 0
	self.t = 0
	gui.set_text(self.text, "")
	self.tap_mode = opts.tap ~= false
	gui.set_enabled(self.hint, self.tap_mode)
	if self.skip_btn then gui.set_enabled(self.skip_btn.node, opts.skip ~= false) end
	self.lumi:set_mood(mood or "talk", math.min(3, #self.chars * 0.03))
end

function M:typing()
	return self.visible and self.shown < #self.chars
end

--- Reveal the whole line at once (first tap while typing).
function M:finish()
	self.shown = #self.chars
	gui.set_text(self.text, self.full or "")
end

function M:hide()
	if not self.visible then return end
	self.visible = false
	gui.set_enabled(self.root, false)
end

function M:update(dt)
	self.lumi:update(dt)
	if self.visible and self.shown < #self.chars then
		self.t = self.t + dt
		local n = math.min(#self.chars, math.floor(self.t * 55))
		if n ~= self.shown then
			self.shown = n
			gui.set_text(self.text, table.concat(self.chars, "", 1, n))
		end
	end
end

--- Returns true when consumed. A tap finishes typing or continues.
function M:on_input(action_id, action)
	if not self.visible then return false end
	if self.buttons:on_input(action_id, action) then return true end
	if not self.tap_mode then
		-- guided steps: only touches on the bubble itself are consumed
		if action_id == hash("touch") and gui.pick_node(self.panel, action.x, action.y) then
			if action.released and self:typing() then self:finish() end
			return true
		end
		return false
	end
	if action_id == hash("touch") and action.released then
		if self:typing() then
			self:finish()
		elseif self.opts.on_continue then
			self.opts.on_continue()
		end
		return true
	end
	return action_id == hash("touch")
end

function M:destroy()
	self.lumi:destroy()
	ui.delete(self.root)
end

return M
