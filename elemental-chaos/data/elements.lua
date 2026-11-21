-- Element catalogue. Names and descriptions live in scripts/localization.lua.
local M = {}

M.BASE = { "fire", "water", "earth", "air" }
M.COMPOUNDS = { "steam", "lava", "plasma", "life", "ice", "dust", "storm", "obsidian", "forest", "crystal" }

-- colour: rgb 0..1, used for effects and UI tints
M.info = {
	fire     = { base = true, color = { 1.00, 0.38, 0.25 }, sprite = "fire",  charged = "fire_charged" },
	water    = { base = true, color = { 0.21, 0.79, 0.96 }, sprite = "water", charged = "water_charged" },
	earth    = { base = true, color = { 0.32, 0.85, 0.54 }, sprite = "earth", charged = "earth_charged" },
	air      = { base = true, color = { 0.71, 0.58, 1.00 }, sprite = "air",   charged = "air_charged" },

	steam    = { compound = true, tier = 1, power = "column",    color = { 0.85, 0.93, 1.00 }, sprite = "steam" },
	lava     = { compound = true, tier = 1, power = "area3",     color = { 1.00, 0.45, 0.10 }, sprite = "lava" },
	plasma   = { compound = true, tier = 1, power = "row",       color = { 0.78, 0.45, 1.00 }, sprite = "plasma" },
	life     = { compound = true, tier = 1, power = "grow4",     color = { 0.45, 0.95, 0.45 }, sprite = "life" },
	ice      = { compound = true, tier = 1, power = "area2",     color = { 0.60, 0.90, 1.00 }, sprite = "ice" },
	dust     = { compound = true, tier = 1, power = "erode",     color = { 0.95, 0.80, 0.45 }, sprite = "dust" },
	storm    = { compound = true, tier = 2, power = "cross",     color = { 0.45, 0.55, 1.00 }, sprite = "storm" },
	obsidian = { compound = true, tier = 2, power = "shatter",   color = { 0.45, 0.25, 0.65 }, sprite = "obsidian" },
	forest   = { compound = true, tier = 2, power = "grow8",     color = { 0.20, 0.75, 0.35 }, sprite = "forest" },
	crystal  = { compound = true, tier = 2, power = "prism",     color = { 1.00, 0.55, 0.85 }, sprite = "crystal" },
}

M.OBSTACLES = { "rock", "frost", "vine", "corruption" }

function M.is_base(id)
	local i = M.info[id]
	return i ~= nil and i.base == true
end

function M.is_compound(id)
	local i = M.info[id]
	return i ~= nil and i.compound == true
end

function M.exists(id)
	return M.info[id] ~= nil
end

--- Sprite (atlas animation id) for a piece table {id, kind}
function M.sprite_for(piece)
	local i = M.info[piece.id]
	if not i then return "fire" end
	if piece.kind == "charged" and i.charged then return i.charged end
	return i.sprite
end

return M
