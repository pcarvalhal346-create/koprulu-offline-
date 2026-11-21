-- Main menu: logo, animated Lumi, Play / Alchemy Book / Settings and the
-- first-launch introduction (skippable).
local ui = require "gui.ui"
local lumi_view = require "gui.lumi_view"
local dialog = require "gui.dialog"
local settings_view = require "gui.settings_view"
local lumi = require "scripts.lumi"
local L = require "scripts.localization"

local M = {}
M.__index = M

local function cover_bg(parent, m, anim)
	local s = math.max(m.vw / 480, m.vh / 854)
	return ui.box(m.cx, m.cy, 480 * s, 854 * s, "bg", anim, { parent = parent })
end
M.cover_bg = cover_bg

function M.create(ctx)
	local self = setmetatable({ ctx = ctx, buttons = ui.buttons() }, M)
	local m = ui.metrics()
	self.m = m
	self.root = ui.container(ctx.screens.layers.screen, 0, 0)
	cover_bg(self.root, m, "bg_menu")

	local logo_y = math.min(m.safe_top - 170, 1130)
	self.logo = ui.box(m.cx, logo_y, 640, 278, "ui", "logo", { parent = self.root })
	ui.pop_in(self.logo, 0.1)
	ui.float(self.logo, 8, 2.2)
	self.subtitle = ui.text(m.cx, logo_y - 164, L("menu.subtitle"), { parent = self.root, size = 28, color = "white", outline = "#5A2BB0" })

	local lumi_y = (logo_y - 200 + m.safe_bottom + 470) / 2 + 20
	self.lumi = lumi_view.create(self.root, m.cx, lumi_y, 0.95)

	local by = m.safe_bottom + 330
	local play = self.buttons:add(self.root, m.cx, by, 400, 120, L("menu.play"), "primary", function()
		ctx.screens.go("map")
	end, { size = 52 })
	ui.pulse(play.node, 1.04, 0.8)
	self.buttons:add(self.root, m.cx, by - 134, 400, 100, L("menu.book"), "secondary", function()
		ctx.screens.go("book", { from = "menu" })
	end, { size = 32 })
	self.buttons:add(self.root, m.safe_left + 70, m.safe_bottom + 70, 96, 96, nil, "round", function()
		settings_view.open_settings(ctx)
	end, { icon = "gear", icon_size = 50 })

	ctx.audio.music("music_menu")

	if not ctx.profile.intro_seen then
		self.intro = 1
		self.dialog = dialog.create(self.root, {
			y = m.safe_bottom + 170,
			sound = function() ctx.audio.play("lumi") end,
			on_continue = function() self:next_intro() end,
			on_skip = function() self:end_intro() end,
		})
		self.intro_delay = 0.7
	else
		self.lumi:set_mood("happy")
	end
	return self
end

function M:next_intro()
	self.intro = self.intro + 1
	if self.intro > #lumi.lines.intro then
		self:end_intro()
	else
		self.dialog:say(L(lumi.lines.intro[self.intro]), self.intro == 2 and "thinking" or "talk")
	end
end

function M:end_intro()
	self.ctx.profile.intro_seen = true
	self.ctx.save.save()
	self.dialog:hide()
	self.intro = nil
	self.lumi:set_mood("happy")
end

function M:update(dt)
	self.lumi:update(dt)
	if self.dialog then
		self.dialog:update(dt)
		if self.intro_delay then
			self.intro_delay = self.intro_delay - dt
			if self.intro_delay <= 0 then
				self.intro_delay = nil
				self.dialog:say(L(lumi.lines.intro[1]), "talk")
				self.lumi:set_mood("talk", 2)
			end
		end
	end
end

function M:on_input(action_id, action)
	if self.dialog and self.intro then
		return self.dialog:on_input(action_id, action) or true
	end
	return self.buttons:on_input(action_id, action)
end

function M:on_resize()
	self.ctx.screens.go("menu", nil, true)
end

function M:destroy()
	self.lumi:destroy()
	if self.dialog then self.dialog:destroy() end
	ui.delete(self.root)
end

return M
