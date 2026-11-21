-- Alchemy recipes. Data only: rules live in scripts/alchemy.lua.
local M = {}

M.recipes = {
	["fire|water"]  = "steam",
	["earth|fire"]  = "lava",
	["air|fire"]    = "plasma",
	["earth|water"] = "life",
	["air|water"]   = "ice",
	["air|earth"]   = "dust",
	["air|steam"]   = "storm",
	["lava|water"]  = "obsidian",
	["life|water"]  = "forest",
	["fire|ice"]    = "crystal",
}

-- Ordered list used by the Alchemy Book and by tests.
M.list = {
	{ a = "fire",  b = "water", result = "steam",    tier = 1 },
	{ a = "fire",  b = "earth", result = "lava",     tier = 1 },
	{ a = "fire",  b = "air",   result = "plasma",   tier = 1 },
	{ a = "water", b = "earth", result = "life",     tier = 1 },
	{ a = "water", b = "air",   result = "ice",      tier = 1 },
	{ a = "earth", b = "air",   result = "dust",     tier = 1 },
	{ a = "steam", b = "air",   result = "storm",    tier = 2 },
	{ a = "lava",  b = "water", result = "obsidian", tier = 2 },
	{ a = "life",  b = "water", result = "forest",   tier = 2 },
	{ a = "ice",   b = "fire",  result = "crystal",  tier = 2 },
}

function M.key(a, b)
	if a > b then
		a, b = b, a
	end
	return a .. "|" .. b
end

function M.find(a, b)
	if type(a) ~= "string" or type(b) ~= "string" then return nil end
	return M.recipes[M.key(a, b)]
end

--- Recipe entry (from M.list) that produces `result`.
function M.producing(result)
	for _, r in ipairs(M.list) do
		if r.result == result then return r end
	end
	return nil
end

--- Base elements needed (recursively) to produce `result`.
function M.base_requirements(result, out)
	out = out or {}
	local r = M.producing(result)
	if not r then
		out[result] = true
		return out
	end
	M.base_requirements(r.a, out)
	M.base_requirements(r.b, out)
	return out
end

return M
