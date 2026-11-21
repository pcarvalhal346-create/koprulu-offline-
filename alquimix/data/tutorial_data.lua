-- Guided tutorials. Text keys live in scripts/localization.lua.
-- Step kinds:
--   say       Lumi talks; tap to continue (optional `highlight` finder)
--   swap      guided swap; `from`/`to` fixed cells (validated by tests) or `finder`
--   select    tap a compound once (finder = { type = "compound", id = ... })
--   activate  tap the selected compound again to use its power
-- Finders (resolved against the live board, never hard-coded screen positions):
--   { type = "match", element = id? }   a swap that creates a match
--   { type = "fusion", result = id }    a swap that fuses into `result`
--   { type = "compound", id = id }      a compound on the board
--   { type = "obstacle", id = "rock"|"rock_hard"|"frost"|"vine"|"corruption" }
--   { type = "conveyor" } / { type = "portal" }
local M = {}

M.tutorials = {
	first_match = {
		level = 1,
		steps = {
			{ kind = "say", text = "tut.first_match.1", mood = "talk" },
			{ kind = "swap", text = "tut.first_match.2", mood = "point", from = { x = 5, y = 5 }, to = { x = 5, y = 6 }, expect = "match" },
			{ kind = "say", text = "tut.first_match.3", mood = "happy" },
		},
	},
	charge = {
		level = 2,
		steps = {
			{ kind = "say", text = "tut.charge.1", mood = "talk" },
			{ kind = "swap", text = "tut.charge.2", mood = "point", from = { x = 4, y = 5 }, to = { x = 4, y = 6 }, expect = "match" },
			{ kind = "say", text = "tut.charge.3", mood = "surprised" },
		},
	},
	first_fusion = {
		level = 3,
		steps = {
			{ kind = "say", text = "tut.fusion.1", mood = "talk" },
			{ kind = "swap", text = "tut.fusion.2", mood = "point", from = { x = 4, y = 5 }, to = { x = 5, y = 5 }, expect = "fusion", result = "steam" },
			{ kind = "say", text = "tut.fusion.3", mood = "happy" },
		},
	},
	activate = {
		level = 4,
		steps = {
			{ kind = "say", text = "tut.activate.1", mood = "talk" },
			{ kind = "select", text = "tut.activate.2", mood = "point", finder = { type = "compound", id = "steam" } },
			{ kind = "activate", text = "tut.activate.3", mood = "point", finder = { type = "compound", id = "steam" } },
			{ kind = "say", text = "tut.activate.4", mood = "happy" },
		},
	},
	rocks = {
		level = 5,
		steps = {
			{ kind = "say", text = "tut.rocks.1", mood = "thinking", highlight = { type = "obstacle", id = "rock" } },
			{ kind = "swap", text = "tut.rocks.2", mood = "point", from = { x = 3, y = 6 }, to = { x = 4, y = 6 }, expect = "fusion", result = "lava" },
			{ kind = "select", text = "tut.rocks.3", mood = "point", finder = { type = "compound", id = "lava" } },
			{ kind = "activate", text = "tut.rocks.4", mood = "point", finder = { type = "compound", id = "lava" } },
			{ kind = "say", text = "tut.rocks.5", mood = "happy" },
		},
	},
	air = {
		level = 7,
		steps = {
			{ kind = "say", text = "tut.air.1", mood = "surprised" },
			{ kind = "swap", text = "tut.air.2", mood = "point", finder = { type = "match", element = "air" }, expect = "match" },
			{ kind = "say", text = "tut.air.3", mood = "talk" },
		},
	},
	two_stage = {
		level = 9,
		steps = {
			{ kind = "say", text = "tut.two_stage.1", mood = "talk" },
			{ kind = "swap", text = "tut.two_stage.2", mood = "point", from = { x = 3, y = 4 }, to = { x = 4, y = 4 }, expect = "fusion", result = "steam" },
			{ kind = "say", text = "tut.two_stage.3", mood = "thinking" },
			{ kind = "swap", text = "tut.two_stage.4", mood = "point", finder = { type = "fusion", result = "storm" }, expect = "fusion", result = "storm" },
			{ kind = "say", text = "tut.two_stage.5", mood = "happy" },
		},
	},
	frost = {
		level = 11,
		steps = {
			{ kind = "say", text = "tut.frost.1", mood = "surprised", highlight = { type = "obstacle", id = "frost" } },
			{ kind = "say", text = "tut.frost.2", mood = "thinking", highlight = { type = "obstacle", id = "frost" } },
		},
	},
	vines = {
		level = 13,
		steps = {
			{ kind = "say", text = "tut.vines.1", mood = "surprised", highlight = { type = "obstacle", id = "vine" } },
			{ kind = "say", text = "tut.vines.2", mood = "talk" },
		},
	},
	obsidian = {
		level = 15,
		steps = {
			{ kind = "say", text = "tut.obsidian.1", mood = "talk" },
			{ kind = "swap", text = "tut.obsidian.2", mood = "point", from = { x = 4, y = 5 }, to = { x = 5, y = 5 }, expect = "fusion", result = "obsidian" },
			{ kind = "select", text = "tut.obsidian.3", mood = "point", finder = { type = "compound", id = "obsidian" } },
			{ kind = "activate", text = "tut.obsidian.4", mood = "point", finder = { type = "compound", id = "obsidian" } },
			{ kind = "say", text = "tut.obsidian.5", mood = "happy" },
		},
	},
	crystal = {
		level = 17,
		steps = {
			{ kind = "say", text = "tut.crystal.1", mood = "talk" },
			{ kind = "swap", text = "tut.crystal.2", mood = "point", from = { x = 4, y = 5 }, to = { x = 5, y = 5 }, expect = "fusion", result = "crystal" },
			{ kind = "select", text = "tut.crystal.3", mood = "point", finder = { type = "compound", id = "crystal" } },
			{ kind = "activate", text = "tut.crystal.4", mood = "point", finder = { type = "compound", id = "crystal" } },
			{ kind = "say", text = "tut.crystal.5", mood = "happy" },
		},
	},
	hard_rocks = {
		level = 21,
		steps = {
			{ kind = "say", text = "tut.hard_rocks.1", mood = "surprised", highlight = { type = "obstacle", id = "rock_hard" } },
			{ kind = "say", text = "tut.hard_rocks.2", mood = "thinking" },
		},
	},
	conveyor = {
		level = 31,
		steps = {
			{ kind = "say", text = "tut.conveyor.1", mood = "surprised", highlight = { type = "conveyor" } },
			{ kind = "say", text = "tut.conveyor.2", mood = "thinking", highlight = { type = "conveyor" } },
		},
	},
	portals = {
		level = 41,
		steps = {
			{ kind = "say", text = "tut.portals.1", mood = "surprised", highlight = { type = "portal" } },
			{ kind = "say", text = "tut.portals.2", mood = "talk", highlight = { type = "portal" } },
		},
	},
	corruption = {
		level = 51,
		steps = {
			{ kind = "say", text = "tut.corruption.1", mood = "sad", highlight = { type = "obstacle", id = "corruption" } },
			{ kind = "say", text = "tut.corruption.2", mood = "thinking", highlight = { type = "obstacle", id = "corruption" } },
			{ kind = "say", text = "tut.corruption.3", mood = "talk" },
		},
	},
	finale = {
		level = 60,
		steps = {
			{ kind = "say", text = "tut.finale.1", mood = "talk" },
			{ kind = "say", text = "tut.finale.2", mood = "thinking", highlight = { type = "portal" } },
			{ kind = "say", text = "tut.finale.3", mood = "thinking", highlight = { type = "obstacle", id = "corruption" } },
			{ kind = "say", text = "tut.finale.4", mood = "happy" },
		},
	},
}

-- Contextual tips used after several turns without objective progress.
M.tips = {
	rock = "tip.rock", frost = "tip.frost", vine = "tip.vine", corruption = "tip.corruption",
	create = "tip.create", activate = "tip.activate", collect = "tip.collect", charge = "tip.charge",
}

function M.get(id)
	return M.tutorials[id]
end

return M
