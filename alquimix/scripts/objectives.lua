-- Level objectives.
--   collect  id=<base element>  pieces removed by matches or powers (not fusion ingredients)
--   charge   (id optional)      charged elements created by manual matches
--   create   id=<compound>      compounds produced by fusion (every creation counts)
--   activate id=<compound>      compounds whose power was used
--   clear    id=rock|frost|vine|corruption   obstacles destroyed / layers removed
local M = {}
M.__index = M

M.TYPES = { collect = true, charge = true, create = true, activate = true, clear = true }

function M.new(goals)
	local self = setmetatable({ goals = {} }, M)
	for i, g in ipairs(goals or {}) do
		self.goals[i] = { type = g.type, id = g.id, count = g.count, progress = 0 }
	end
	return self
end

--- Register `amount` units of (type, id). Returns list of {index, progress, count, done, just_done}
function M:add(type, id, amount)
	amount = amount or 1
	local changed = {}
	for i, g in ipairs(self.goals) do
		if g.type == type and (g.id == nil or g.id == id) and g.progress < g.count then
			local before = g.progress
			g.progress = math.min(g.count, g.progress + amount)
			if g.progress ~= before then
				changed[#changed + 1] = {
					index = i, progress = g.progress, count = g.count,
					done = g.progress >= g.count, just_done = g.progress >= g.count,
				}
			end
		end
	end
	return changed
end

function M:complete()
	for _, g in ipairs(self.goals) do
		if g.progress < g.count then return false end
	end
	return true
end

function M:remaining()
	local out = {}
	for i, g in ipairs(self.goals) do
		if g.progress < g.count then
			out[#out + 1] = { index = i, type = g.type, id = g.id, left = g.count - g.progress }
		end
	end
	return out
end

--- Total fraction 0..1, used by hints/simulator
function M:fraction()
	local sum, n = 0, 0
	for _, g in ipairs(self.goals) do
		sum = sum + math.min(1, g.progress / g.count)
		n = n + 1
	end
	if n == 0 then return 1 end
	return sum / n
end

function M:clone()
	local c = setmetatable({ goals = {} }, M)
	for i, g in ipairs(self.goals) do
		c.goals[i] = { type = g.type, id = g.id, count = g.count, progress = g.progress }
	end
	return c
end

return M
