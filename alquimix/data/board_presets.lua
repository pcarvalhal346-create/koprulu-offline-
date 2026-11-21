-- Fixed starting pieces for tutorial levels. "." cells are filled by the
-- generator (avoiding matches); letters are fixed: f/w/e/a = base element,
-- uppercase = charged. Compounds are listed separately.
-- tests/test_levels.lua verifies that every guided move in data/tutorial_data.lua
-- is valid on these boards.
return {
	tutorial_match = {
		rows = {
			"........",
			"........",
			"........",
			"........",
			"....f...",
			"..ffw...",
			"........",
			"........",
		},
	},
	tutorial_charge = {
		rows = {
			"........",
			"........",
			"........",
			"........",
			"...w....",
			".wwew...",
			"........",
			"........",
		},
	},
	tutorial_fusion = {
		rows = {
			"........",
			"........",
			"........",
			"........",
			"...Fw...",
			"........",
			"........",
			"........",
		},
	},
	tutorial_activate = {
		rows = {
			"........",
			"........",
			"........",
			"........",
			"........",
			"........",
			"........",
			"........",
		},
		compounds = { { x = 4, y = 4, id = "steam" } },
	},
	tutorial_lava = {
		rows = {
			"........",
			"........",
			"........",
			"........",
			"........",
			"..Fe....",
			"........",
			"........",
		},
	},
	tutorial_two_stage = {
		rows = {
			"........",
			"........",
			"........",
			"..Fwa...",
			"........",
			"........",
			"........",
			"........",
		},
	},
	tutorial_obsidian = {
		rows = {
			"........",
			"........",
			"........",
			"........",
			"....w...",
			"........",
			"........",
			"........",
		},
		compounds = { { x = 4, y = 5, id = "lava" } },
	},
	tutorial_crystal = {
		rows = {
			"........",
			"........",
			"........",
			"........",
			"....f...",
			"........",
			"........",
			"........",
		},
		compounds = { { x = 4, y = 5, id = "ice" } },
	},
}
