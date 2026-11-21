-- luacheck configuration (Defold globals + LuaJIT)
std = "luajit"
max_line_length = false
globals = { "init", "final", "update", "on_input", "on_message", "on_reload" }
read_globals = { "gui", "vmath", "msg", "hash", "sys", "sound", "timer", "window", "socket", "go", "json" }
files["tests"] = { globals = { "arg" } }
exclude_files = { "tools/art/node_modules", "build" }
-- callbacks keep the Defold signature (self, ...) even when unused
unused_args = false
