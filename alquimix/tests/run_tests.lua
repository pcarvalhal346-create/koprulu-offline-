-- Runs every automated test outside Defold.
-- Usage (from the project root):  luajit tests/run_tests.lua [filter]
-- Works with LuaJIT 2.1 (same VM as Defold) and Lua 5.1.
package.path = "./?.lua;" .. package.path

local T = require "tests.lib.testlib"
local files = {
	"tests.test_matches",
	"tests.test_alchemy",
	"tests.test_gravity",
	"tests.test_obstacles",
	"tests.test_levels",
	"tests.test_progression",
}
for _, f in ipairs(files) do
	T.current = f
	require(f)
end
local ok = T.run(arg and arg[1])
os.exit(ok and 0 or 1)
