-- Lumi's personality: which line and expression to use in each situation.
-- Lines rotate so Lumi does not repeat herself; the view (gui/lumi_view.lua)
-- handles drawing and animation.
local L = require "scripts.localization"

local M = {}

M.MOODS = { "idle", "talk", "point", "happy", "surprised", "thinking", "sad", "victory" }

M.lines = {
	intro = { "lumi.intro.1", "lumi.intro.2", "lumi.intro.3" },
	victory = { "lumi.victory.1", "lumi.victory.2", "lumi.victory.3", "lumi.victory.4" },
	defeat = { "lumi.defeat.1", "lumi.defeat.2", "lumi.defeat.3" },
	discovery = { "lumi.discovery.1", "lumi.discovery.2", "lumi.discovery.3" },
	level_start = { "lumi.level_start.1", "lumi.level_start.2", "lumi.level_start.3", "lumi.level_start.4" },
}

M.moods = {
	victory = "victory", defeat = "sad", discovery = "surprised", level_start = "talk", intro = "talk",
}

local cursor = {}

--- Next line for a context (rotates through the variants).
function M.line(context)
	local list = M.lines[context]
	if not list then return L.get(context), "talk" end
	local i = (cursor[context] or 0) % #list + 1
	cursor[context] = i
	return L.get(list[i]), M.moods[context] or "talk"
end

function M.reset()
	cursor = {}
end

--- Tip for the first unfinished objective (after several moves without progress).
function M.tip_for(remaining)
	local g = remaining and remaining[1]
	if not g then return nil end
	if g.type == "clear" then return L.get("tip." .. g.id), "thinking" end
	return L.get("tip." .. g.type), "thinking"
end

return M
