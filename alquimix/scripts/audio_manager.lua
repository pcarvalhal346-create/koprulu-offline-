-- Sound effects and music, respecting the player's settings.
-- Sound components live in /main/audio.go (one per file in assets/audio).
local M = {}

M.URL = "main:/audio#"
M.current_music = nil
M.settings = { music = true, sfx = true }

local POWER = {
	steam = "power_steam", lava = "power_lava", plasma = "power_plasma", life = "power_life", ice = "power_ice",
	dust = "power_dust", storm = "power_storm", obsidian = "power_obsidian", forest = "power_forest", crystal = "power_crystal",
}

function M.init(settings)
	M.settings = settings
end

--- Play a sound effect. opts: { gain, speed }
function M.play(name, opts)
	if not M.settings.sfx then return end
	local props = {}
	if opts and opts.gain then props.gain = opts.gain end
	if opts and opts.speed then props.speed = opts.speed end
	pcall(sound.play, M.URL .. name, props)
end

function M.power(id)
	M.play(POWER[id] or "fusion")
end

function M.music(name)
	if M.current_music == name and M.settings.music then return end
	if M.current_music then pcall(sound.stop, M.URL .. M.current_music) end
	M.current_music = name
	if name and M.settings.music then
		pcall(sound.play, M.URL .. name)
	end
end

--- Re-apply after a settings change.
function M.refresh()
	local name = M.current_music
	if name then pcall(sound.stop, M.URL .. name) end
	if name and M.settings.music then pcall(sound.play, M.URL .. name) end
end

return M
