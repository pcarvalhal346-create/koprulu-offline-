-- Minimal test framework (no dependencies). Used by tests/run_tests.lua.
local M = { tests = {}, current = nil }

function M.test(name, fn)
	M.tests[#M.tests + 1] = { name = name, fn = fn, file = M.current }
end

local function fmt(v)
	if type(v) == "string" then return ("%q"):format(v) end
	return tostring(v)
end

function M.eq(a, b, msg)
	if a ~= b then
		error(("%sexpected %s, got %s"):format(msg and (msg .. ": ") or "", fmt(b), fmt(a)), 2)
	end
end

function M.ok(v, msg)
	if not v then error(msg or "expected truthy value", 2) end
end

function M.no(v, msg)
	if v then error(msg or "expected falsy value", 2) end
end

function M.near(a, b, eps, msg)
	if math.abs(a - b) > (eps or 1e-9) then
		error(("%sexpected %s ~ %s"):format(msg and (msg .. ": ") or "", tostring(a), tostring(b)), 2)
	end
end

function M.has_event(events, type, pred)
	for _, e in ipairs(events) do
		if e.type == type and (not pred or pred(e)) then return e end
	end
	return nil
end

function M.count_events(events, type)
	local n = 0
	for _, e in ipairs(events) do if e.type == type then n = n + 1 end end
	return n
end

function M.run(filter)
	local passed, failed = 0, 0
	local failures = {}
	for _, t in ipairs(M.tests) do
		if not filter or t.name:find(filter, 1, true) or (t.file or ""):find(filter, 1, true) then
			local ok, e = xpcall(t.fn, debug.traceback)
			if ok then
				passed = passed + 1
			else
				failed = failed + 1
				failures[#failures + 1] = ("[%s] %s\n    %s"):format(t.file or "?", t.name, tostring(e):gsub("\n", "\n    "))
			end
		end
	end
	for _, f in ipairs(failures) do print("FAIL " .. f) end
	print(("%d passed, %d failed"):format(passed, failed))
	return failed == 0
end

return M
