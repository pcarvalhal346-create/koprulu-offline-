-- Persistent profile. The storage backend is injected so the module can be
-- tested outside Defold; in the engine it uses sys.get_save_file/sys.save/sys.load.
local M = {}

M.VERSION = 2
M.APP_ID = "elemental_chaos"
M.FILE = "profile"

function M.defaults()
	return {
		version = M.VERSION,
		unlocked = 1,
		levels = {},            -- [level_id] = { stars, best_score, completed }
		discovered = {},        -- [recipe_key] = { order = n, level = id, seen = bool }
		discovery_count = 0,
		tutorials = {},         -- [tutorial_id] = true
		intro_seen = false,
		campaign_complete = false,
		worlds_seen = { [1] = true },
		settings = { music = true, sfx = true, reduced_motion = false },
	}
end

-- Migrations: index = version being upgraded FROM.
-- v0: unversioned prototype profile ({ max_level, stars = {..}, recipes = {key=true} }).
-- v1: discovered recipes stored as booleans, no worlds_seen.
M.migrations = {
	[0] = function(d)
		local out = M.defaults()
		out.version = 1
		out.unlocked = tonumber(d.max_level or d.unlocked) or 1
		for id, s in pairs(d.stars or {}) do
			out.levels[tonumber(id)] = { stars = s, best_score = 0, completed = s > 0 }
		end
		out.discovered = {}
		for k, v in pairs(d.recipes or d.discovered or {}) do
			if v then out.discovered[k] = true end
		end
		return out
	end,
	[1] = function(d)
		local order = 0
		local keys = {}
		for k in pairs(d.discovered or {}) do keys[#keys + 1] = k end
		table.sort(keys)
		local disc = {}
		for _, k in ipairs(keys) do
			order = order + 1
			local v = d.discovered[k]
			if type(v) == "table" then
				disc[k] = v
			else
				disc[k] = { order = order, seen = true }
			end
		end
		d.discovered = disc
		d.discovery_count = order
		d.worlds_seen = d.worlds_seen or { [1] = true }
		d.version = 2
		return d
	end,
}

--- Fill missing fields with defaults (tolerates partially written files).
local function fill(dst, def)
	for k, v in pairs(def) do
		if dst[k] == nil then
			if type(v) == "table" then
				dst[k] = {}
				fill(dst[k], v)
			else
				dst[k] = v
			end
		elseif type(v) == "table" and type(dst[k]) == "table" and k == "settings" then
			fill(dst[k], v)
		end
	end
	return dst
end

function M.migrate(data)
	if type(data) ~= "table" or next(data) == nil then return M.defaults(), false end
	local v = tonumber(data.version) or 0
	local migrated = false
	while v < M.VERSION do
		local fn = M.migrations[v]
		if not fn then return M.defaults(), true end
		data = fn(data)
		v = tonumber(data.version) or (v + 1)
		migrated = true
	end
	-- level keys must be numbers after a round trip
	local levels = {}
	for k, r in pairs(data.levels or {}) do levels[tonumber(k) or k] = r end
	data.levels = levels
	return fill(data, M.defaults()), migrated
end

-- ------------------------------------------------------------- backends --

function M.defold_backend()
	local path = sys.get_save_file(M.APP_ID, M.FILE)
	return {
		load = function()
			local ok, t = pcall(sys.load, path)
			if ok then return t end
			return nil
		end,
		save = function(t)
			local ok, res = pcall(sys.save, path, t)
			return ok and res
		end,
	}
end

function M.memory_backend(initial)
	local store = { data = initial }
	store.load = function()
		return store.data
	end
	store.save = function(t)
		-- simulate serialisation (string keys etc. are preserved, references are not)
		local function deep(v)
			if type(v) ~= "table" then return v end
			local r = {}
			for k, x in pairs(v) do r[k] = deep(x) end
			return r
		end
		store.data = deep(t)
		return true
	end
	return store
end

-- ------------------------------------------------------------- instance --

function M.init(backend)
	M.backend = backend
	local raw = backend.load()
	local profile, migrated = M.migrate(raw)
	M.profile = profile
	if migrated then M.save() end
	return profile
end

function M.save()
	if not M.backend or not M.profile then return false end
	return M.backend.save(M.profile)
end

function M.get()
	return M.profile
end

function M.discovered_set()
	local set = {}
	for k in pairs(M.profile.discovered) do set[k] = true end
	return set
end

--- Register a recipe discovered in a level. Returns true if it was new.
function M.add_discovery(key, level_id)
	local p = M.profile
	if p.discovered[key] then return false end
	p.discovery_count = (p.discovery_count or 0) + 1
	p.discovered[key] = { order = p.discovery_count, level = level_id, seen = false }
	M.save()
	return true
end

function M.reset_tutorials()
	M.profile.tutorials = {}
	M.profile.intro_seen = false
	M.save()
end

return M
