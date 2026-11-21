-- Stars, unlocking and per-level records. Works on the profile table owned by
-- scripts/save_manager.lua (no I/O here).
local M = {}

M.TOTAL_LEVELS = 60
M.THREE_STAR = 0.40 -- fraction of moves left
M.TWO_STAR = 0.20

--- Minimum moves left for 2 and 3 stars. Thresholds round UP (math.ceil)
--- so a star never comes from rounding in the player's favour.
function M.thresholds(total)
	return math.ceil(total * M.TWO_STAR), math.ceil(total * M.THREE_STAR)
end

function M.stars_for(total, left)
	local two, three = M.thresholds(total)
	if left >= three then return 3 end
	if left >= two then return 2 end
	return 1
end

function M.level_record(profile, id)
	return profile.levels[id] or profile.levels[tostring(id)]
end

function M.is_unlocked(profile, id)
	return id >= 1 and id <= (profile.unlocked or 1)
end

function M.stars(profile, id)
	local r = M.level_record(profile, id)
	return r and r.stars or 0
end

function M.total_stars(profile)
	local n = 0
	for id = 1, M.TOTAL_LEVELS do n = n + M.stars(profile, id) end
	return n
end

function M.completed_count(profile)
	local n = 0
	for id = 1, M.TOTAL_LEVELS do
		local r = M.level_record(profile, id)
		if r and r.completed then n = n + 1 end
	end
	return n
end

--- Record a victory. Stars and best score never decrease.
--- Returns { first_clear, new_best, unlocked = id|nil, world_unlocked = n|nil, campaign_complete }
function M.record_win(profile, id, score, stars, world_last)
	local r = M.level_record(profile, id)
	local res = { first_clear = false, new_best = false }
	if not r then
		r = { stars = 0, best_score = 0, completed = false }
		profile.levels[id] = r
	end
	if not r.completed then res.first_clear = true end
	r.completed = true
	if stars > (r.stars or 0) then r.stars = stars end
	if score > (r.best_score or 0) then
		r.best_score = score
		res.new_best = true
	end
	if id < M.TOTAL_LEVELS and (profile.unlocked or 1) < id + 1 then
		profile.unlocked = id + 1
		res.unlocked = id + 1
		if world_last and id == world_last then
			res.world_unlocked = math.floor(id / 20) + 1
		end
	end
	if id == M.TOTAL_LEVELS and res.first_clear then
		res.campaign_complete = true
		profile.campaign_complete = true
	end
	return res
end

--- Index of the level the map should focus on.
function M.current_level(profile)
	return math.min(profile.unlocked or 1, M.TOTAL_LEVELS)
end

return M
