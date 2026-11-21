-- Settings popup (music, sound effects, reduced animations, replay tutorials)
-- and the in-game pause menu.
local ui = require "gui.ui"
local popup = require "gui.popup"
local L = require "scripts.localization"

local M = {}

local function toggle_row(p, y, icon, label, get, set)
	local row = ui.box(0, y, p.w - 80, 104, "ui", "goal_slot", { parent = p.panel, slice = 30 })
	ui.box(-(p.w - 80) / 2 + 52, 0, 58, 58, "ui", "icon_" .. icon, { parent = row })
	ui.text(-(p.w - 80) / 2 + 100, 2, label, { parent = row, size = 30, pivot = gui.PIVOT_W })
	local b
	b = p.buttons:add(row, (p.w - 80) / 2 - 92, 0, 150, 74, get() and L("common.on") or L("common.off"), get() and "green" or "secondary", function()
		set(not get())
		gui.set_text(b.label, get() and L("common.on") or L("common.off"))
		gui.play_flipbook(b.node, get() and "btn_green" or "btn_secondary")
	end, { size = 26 })
	return row
end

--- Settings popup. ctx: game context (save manager, audio, settings).
function M.open_settings(ctx, on_close)
	local s = ctx.settings
	return popup.open({
		w = 620, h = 700, title = L("settings.title"), closable = true, on_close = on_close,
		build = function(p)
			toggle_row(p, 180, "music", L("settings.music"), function() return s.music end, function(v)
				s.music = v
				ctx.audio.refresh()
				ctx.save.save()
			end)
			toggle_row(p, 60, "sound", L("settings.sfx"), function() return s.sfx end, function(v)
				s.sfx = v
				ctx.save.save()
			end)
			toggle_row(p, -60, "motion", L("settings.reduced"), function() return s.reduced_motion end, function(v)
				s.reduced_motion = v
				ctx.effects.reduced = v
				ctx.save.save()
			end)
			local info = ui.text(0, -270, "", { parent = p.panel, size = 24, width = 520, color = "gold" })
			p.buttons:add(p.panel, 0, -185, 440, 96, L("settings.tutorials"), "secondary", function()
				ctx.save.reset_tutorials()
				gui.set_text(info, L("settings.tutorials_done"))
			end, { icon = "tutorial", size = 28 })
		end,
	})
end

--- Pause popup. handlers: { resume, restart, map, tutorial (optional) }
function M.open_pause(ctx, handlers)
	local h = handlers.tutorial and 860 or 740
	return popup.open({
		w = 560, h = h, title = L("pause.title"),
		on_back = function(p) p:close() handlers.resume() end,
		build = function(p)
			local y = h / 2 - 170
			local function add(label, style, icon, fn)
				p.buttons:add(p.panel, 0, y, 420, 100, label, style, fn, { icon = icon, size = 32 })
				y = y - 122
			end
			add(L("pause.resume"), "green", "play", function() p:close() handlers.resume() end)
			add(L("pause.restart"), "primary", "retry", function() p:close() handlers.restart() end)
			if handlers.tutorial then
				add(L("settings.tutorials"), "secondary", "tutorial", function() p:close() handlers.tutorial() end)
			end
			add(L("pause.settings"), "secondary", "gear", function() M.open_settings(ctx) end)
			add(L("pause.map"), "danger", "map", function() p:close() handlers.map() end)
		end,
	})
end

return M
