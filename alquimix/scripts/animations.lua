-- Ordered animation queue (pure Lua, driven by update(dt)).
-- An item is a function(done) that starts an animation and either returns its
-- duration in seconds or calls done() itself (return nil). Items pushed with
-- { parallel = true } start immediately and do not block the next parallel
-- item; the next sequential item waits until all of them have finished.
-- While busy() is true the board ignores player input.
local M = {}
M.__index = M

function M.new()
	return setmetatable({ items = {}, running = false, timer = 0, parallel_wait = 0, token = 0 }, M)
end

function M:push(fn, opts)
	self.items[#self.items + 1] = { fn = fn, parallel = opts and opts.parallel or false }
end

--- Wait a fixed time (sequential).
function M:delay(seconds)
	self:push(function() return seconds end)
end

function M:busy()
	return self.running or #self.items > 0 or self.parallel_wait > 0
end

function M:clear()
	self.items = {}
	self.running = false
	self.timer = 0
	self.parallel_wait = 0
	self.token = self.token + 1
end

function M:pump()
	while not self.running and #self.items > 0 do
		local it = self.items[1]
		if not it.parallel and self.parallel_wait > 0 then return end
		table.remove(self.items, 1)
		self.token = self.token + 1
		local token = self.token
		local sync_done, in_call = false, true
		local function done()
			if token ~= self.token then return end
			if in_call then
				sync_done = true
			elseif self.running then
				self.running = false
				self.timer = 0
				self:pump()
			end
		end
		if it.parallel then
			local d = it.fn(function() end)
			in_call = false
			self.parallel_wait = math.max(self.parallel_wait, tonumber(d) or 0)
		else
			self.running = true
			self.timer = -1
			local d = it.fn(done)
			in_call = false
			if sync_done then
				self.running = false
			elseif type(d) == "number" then
				if d <= 0 then
					self.running = false
				else
					self.timer = d
				end
			end
		end
	end
end

function M:update(dt)
	if self.parallel_wait > 0 then
		self.parallel_wait = math.max(0, self.parallel_wait - dt)
	end
	if self.running and self.timer > 0 then
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.running = false
			self.timer = 0
		end
	end
	self:pump()
end

return M
