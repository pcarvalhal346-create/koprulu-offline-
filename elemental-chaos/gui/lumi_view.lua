-- Lumi rendered from the generated rig (data/lumi_rig.lua): body parts are GUI
-- nodes attached to joints, animated with gui.animate. Moods:
-- idle, talk, point, happy, surprised, thinking, sad, victory.
local rig = require "data.lumi_rig"
local ui = require "gui.ui"
local effects = require "scripts.effects"

local M = {}
M.__index = M

local V3 = vmath.vector3

local FACES = {
	idle = { "eyes_open", "mouth_smile" }, talk = { "eyes_open", "mouth_smile" }, point = { "eyes_open", "mouth_open" },
	happy = { "eyes_happy", "mouth_grin" }, surprised = { "eyes_wide", "mouth_o" }, thinking = { "eyes_think", "mouth_small" },
	sad = { "eyes_sad", "mouth_sad" }, victory = { "eyes_happy", "mouth_grin" },
}

-- joint rotations (degrees) per mood
local POSES = {
	idle = { arm_r = 0, arm_l = 0, head = 0 },
	talk = { arm_r = 8, arm_l = -10, head = 3 },
	point = { arm_r = 38, arm_l = -6, head = -4 },
	happy = { arm_r = 25, arm_l = -40, head = 6 },
	surprised = { arm_r = 12, arm_l = -55, head = 0 },
	thinking = { arm_r = 0, arm_l = 150, head = 8 },
	sad = { arm_r = -6, arm_l = 6, head = -9 },
	victory = { arm_r = 62, arm_l = -120, head = 5 },
}

local function rel(jx, jy)
	return jx - rig.canvas.w / 2, -(jy - rig.canvas.h / 2)
end

--- @param parent node|nil
--- @param x number, y number centre position
--- @param scale number (1 = 400x520 canvas)
function M.create(parent, x, y, scale)
	local self = setmetatable({ joints = {}, parts = {}, mood = "idle", talk_t = 0, blink_t = 2 + math.random() * 2, mouth_open = false }, M)
	self.root = ui.container(parent, x, y)
	-- absolute position for particles (set by the owner when the parent is not at the origin)
	self.world_x, self.world_y = x, y
	gui.set_scale(self.root, V3(scale or 1, scale or 1, 1))
	self.float = ui.container(self.root, 0, 0)
	for _, part in ipairs(rig.parts) do
		local j = self.joints[part.joint]
		if not j then
			local jd = rig.joints[part.joint]
			local jx, jy = rel(jd.x, jd.y)
			j = ui.container(self.float, jx, jy)
			self.joints[part.joint] = j
			self.joints[part.joint .. "_pos"] = jd
		end
		local jd = rig.joints[part.joint]
		local geo = part.variants and part.variants[part.face == "eyes" and "eyes_open" or "mouth_smile"] or part
		local anim = part.variants and (part.face == "eyes" and "lumi_eyes_open" or "lumi_mouth_smile") or part.id
		local n = ui.box(geo.cx - jd.x, -(geo.cy - jd.y), geo.w, geo.h, "lumi", anim, { parent = j })
		self.parts[part.id] = { node = n, def = part }
	end
	-- floating sparkles around her
	self.sparkles = {}
	for i = 1, 3 do
		local s = ui.box((i - 2) * 120, 120 + i * 40, 26, 26, "fx", "fx_spark", { parent = self.float, color = "gold", blend = gui.BLEND_ADD })
		ui.float(s, 14 + i * 4, 1.1 + i * 0.3)
		gui.animate(s, "color.w", 0.2, gui.EASING_INOUTSINE, 0.9 + i * 0.25, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		self.sparkles[i] = s
	end
	ui.float(self.float, 12, 1.8)
	self:idle_loops()
	self:set_mood("idle")
	return self
end

function M:set_face(face, variant)
	local p = self.parts[face == "eyes" and "lumi_eyes" or "lumi_mouth"]
	local geo = p.def.variants[variant]
	if not geo then return end
	local jd = rig.joints[p.def.joint]
	gui.play_flipbook(p.node, "lumi_" .. variant)
	gui.set_size(p.node, V3(geo.w, geo.h, 0))
	gui.set_position(p.node, V3(geo.cx - jd.x, -(geo.cy - jd.y), 0))
	if face == "eyes" then self.eyes = variant else self.mouth = variant end
end

function M:idle_loops()
	local wl, wr = self.joints.wing_l, self.joints.wing_r
	gui.animate(wl, "euler.z", -7, gui.EASING_INOUTSINE, 0.7, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	gui.animate(wr, "euler.z", 7, gui.EASING_INOUTSINE, 0.7, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	gui.animate(self.joints.body, "scale.y", 1.015, gui.EASING_INOUTSINE, 1.2, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end

function M:pose(name, d)
	local p = POSES[name] or POSES.idle
	d = d or 0.3
	for joint, angle in pairs(p) do
		local j = self.joints[joint]
		gui.cancel_animations(j, "euler.z")
		gui.animate(j, "euler.z", angle, gui.EASING_OUTBACK, d)
		if joint == "head" then
			gui.cancel_animations(self.joints.head_back, "euler.z")
			gui.animate(self.joints.head_back, "euler.z", angle, gui.EASING_OUTBACK, d)
		end
	end
end

--- Change expression and pose. `talk_seconds` animates the mouth.
function M:set_mood(mood, talk_seconds)
	mood = FACES[mood] and mood or "idle"
	self.mood = mood
	local f = FACES[mood]
	self:set_face("eyes", f[1])
	self:set_face("mouth", f[2])
	self:pose(mood)
	self.talk_t = talk_seconds or 0
	local sc = gui.get_scale(self.root).x
	if mood == "happy" or mood == "victory" then
		gui.cancel_animations(self.root, "scale")
		gui.animate(self.root, "scale", V3(sc * 1.06, sc * 1.06, 1), gui.EASING_OUTQUAD, 0.18, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
		-- scepter star (canvas 310,254) in root coordinates; only valid for root-level Lumis
		if self.world_x then
			effects.burst(self.world_x + 110 * sc, self.world_y + 6 * sc, { count = mood == "victory" and 20 or 10, sprite = "fx_star", color = ui.hex("gold"), speed = 220, size = 26 })
		end
	elseif mood == "surprised" then
		gui.cancel_animations(self.root, "scale")
		gui.animate(self.root, "scale", V3(sc * 1.1, sc * 1.1, 1), gui.EASING_OUTBACK, 0.15, 0, nil, gui.PLAYBACK_ONCE_PINGPONG)
	end
end

function M:talk(seconds)
	self.talk_t = seconds or 1.5
end

function M:update(dt)
	if self.talk_t > 0 then
		self.talk_t = self.talk_t - dt
		self.mouth_timer = (self.mouth_timer or 0) - dt
		if self.mouth_timer <= 0 then
			self.mouth_timer = 0.11 + math.random() * 0.06
			self.mouth_open = not self.mouth_open
			self:set_face("mouth", self.mouth_open and "mouth_open" or FACES[self.mood][2])
		end
		if self.talk_t <= 0 then self:set_face("mouth", FACES[self.mood][2]) end
	end
	self.blink_t = self.blink_t - dt
	if self.blink_t <= 0 then
		if self.eyes == "eyes_closed" then
			self:set_face("eyes", FACES[self.mood][1])
			self.blink_t = 2.2 + math.random() * 2.5
		elseif self.eyes == "eyes_open" or self.eyes == "eyes_think" then
			self:set_face("eyes", "eyes_closed")
			self.blink_t = 0.12
		else
			self.blink_t = 1.5
		end
	end
end

function M:set_position(x, y)
	gui.set_position(self.root, V3(x, y, 0))
	self.world_x, self.world_y = x, y
end

function M:destroy()
	ui.delete(self.root)
end

return M
