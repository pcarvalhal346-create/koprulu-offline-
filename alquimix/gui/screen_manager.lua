-- Screen flow (menu, map, game, book), popup stack and fade transitions.
-- Screens are Lua modules with create(ctx, params) -> instance exposing
-- update(dt), on_input(action_id, action), destroy() and optionally on_back().
local ui = require "gui.ui"

local M = {}

-- name -> module, filled by register() (Defold only bundles literal requires,
-- and the screens require this module, so they are registered by the caller).
M.SCREENS = {}

function M.register(name, module)
	M.SCREENS[name] = module
end

local state = { popups = {} }

function M.init(ctx)
	M.ctx = ctx
	state.layers = {
		screen = ui.container(nil, 0, 0, "screen"),
		popup = ui.container(nil, 0, 0, "popup"),
		fx = ui.container(nil, 0, 0, "fx"),
		top = ui.container(nil, 0, 0, "top"),
	}
	M.layers = state.layers
	local m = ui.metrics()
	state.fade = ui.box(m.cx, m.cy, m.vw + 40, m.vh + 40, "ui", "white", { parent = state.layers.top, color = "navy", alpha = 0 })
	gui.set_enabled(state.fade, false)
end

local function instantiate(name, params)
	local mod = assert(M.SCREENS[name], "unknown screen " .. tostring(name))
	state.name, state.params = name, params
	state.current = mod.create(M.ctx, params or {})
end

local function close_all_popups()
	for i = #state.popups, 1, -1 do
		local p = state.popups[i]
		if p.destroy then p:destroy() end
	end
	state.popups = {}
end

function M.go(name, params, instant)
	if state.transition then return end
	local function swap()
		close_all_popups()
		if state.current and state.current.destroy then state.current:destroy() end
		state.current = nil
		instantiate(name, params)
	end
	if instant or not state.current then
		swap()
		return
	end
	state.transition = true
	local m = ui.metrics()
	gui.set_size(state.fade, vmath.vector3(m.vw + 40, m.vh + 40, 0))
	gui.set_enabled(state.fade, true)
	gui.set_color(state.fade, ui.hex("navy", 0))
	local d = M.ctx.settings.reduced_motion and 0.08 or 0.22
	gui.animate(state.fade, "color.w", 1, gui.EASING_INQUAD, d, 0, function()
		swap()
		gui.animate(state.fade, "color.w", 0, gui.EASING_OUTQUAD, d, 0.02, function()
			gui.set_enabled(state.fade, false)
			state.transition = false
		end)
	end)
end

--- Rebuild the current screen (window resized / safe area changed).
function M.relayout()
	if not state.name or state.transition then return end
	ui.metrics()
	if state.current and state.current.on_resize then
		state.current:on_resize()
	end
end

function M.current()
	return state.current, state.name
end

function M.push(popup)
	state.popups[#state.popups + 1] = popup
end

function M.remove(popup)
	for i = #state.popups, 1, -1 do
		if state.popups[i] == popup then table.remove(state.popups, i) end
	end
end

function M.top_popup()
	return state.popups[#state.popups]
end

function M.on_input(action_id, action)
	if state.transition then return true end
	local p = state.popups[#state.popups]
	if action_id == hash("back") and action.released then
		if p and p.on_back then p:on_back() return true end
		if state.current and state.current.on_back then state.current:on_back() return true end
		return false
	end
	if p then
		if p.on_input then p:on_input(action_id, action) end
		return true
	end
	if state.current and state.current.on_input then
		return state.current:on_input(action_id, action)
	end
	return false
end

function M.update(dt)
	if state.current and state.current.update then state.current:update(dt) end
	for _, p in ipairs(state.popups) do
		if p.update then p:update(dt) end
	end
end

return M
