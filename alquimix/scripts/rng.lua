-- Deterministic pseudo-random generator (Park–Miller "minimal standard").
-- All arithmetic stays below 2^53, so results are identical in LuaJIT,
-- Lua 5.1 and the Defold runtime on every platform.
local M = {}
M.__index = M

local MOD = 2147483647
local MUL = 16807

local function normalise_seed(seed)
	seed = math.floor(tonumber(seed) or 1) % MOD
	if seed <= 0 then seed = seed + MOD - 1 end
	return seed
end

function M.new(seed)
	local self = setmetatable({}, M)
	self.state = normalise_seed(seed)
	-- warm up: the first outputs of Park–Miller correlate with small seeds
	for _ = 1, 4 do self:next() end
	return self
end

function M:next()
	self.state = (self.state * MUL) % MOD
	return self.state
end

--- Behaves like math.random: () -> [0,1), (n) -> [1,n], (a,b) -> [a,b]
function M:random(a, b)
	local r = (self:next() - 1) / (MOD - 1)
	if a == nil then return r end
	if b == nil then a, b = 1, a end
	if b < a then a, b = b, a end
	return a + math.floor(r * (b - a + 1))
end

--- Pick a key from `items` (array) using parallel `weights` (array or map id->weight)
function M:weighted(items, weights)
	local total = 0
	for i, item in ipairs(items) do
		local w = weights and (weights[item] or weights[i]) or 1
		total = total + w
	end
	if total <= 0 then return items[self:random(#items)] end
	local roll = self:random() * total
	for i, item in ipairs(items) do
		local w = weights and (weights[item] or weights[i]) or 1
		roll = roll - w
		if roll < 0 then return item end
	end
	return items[#items]
end

function M:shuffle(t)
	for i = #t, 2, -1 do
		local j = self:random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

function M:clone()
	return setmetatable({ state = self.state }, M)
end

return M
