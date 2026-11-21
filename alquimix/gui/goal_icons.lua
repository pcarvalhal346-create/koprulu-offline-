-- Icon (texture, animation) for objectives, obstacles and elements.
local M = {}

local OBSTACLE = { rock = "rock", frost = "frost_1", vine = "vine", corruption = "corruption" }

function M.element(id)
	return "pieces", id
end

function M.goal(goal)
	if goal.type == "collect" then return "pieces", goal.id end
	if goal.type == "charge" then return "pieces", (goal.id or "fire") .. "_charged" end
	if goal.type == "create" or goal.type == "activate" then return "pieces", goal.id end
	if goal.type == "clear" then return "board", OBSTACLE[goal.id] or "rock" end
	return "ui", "icon_check"
end

--- Small badge for the goal type (create = plus, activate = lightning/play)
function M.badge(goal)
	if goal.type == "create" then return "icon_plus" end
	if goal.type == "activate" then return "icon_play" end
	return nil
end

return M
