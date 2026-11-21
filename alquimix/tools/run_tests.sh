#!/usr/bin/env bash
# Runs the automated tests (and optionally the play-testing bot) with LuaJIT or Lua 5.1.
set -euo pipefail
cd "$(dirname "$0")/.."
LUA="${LUA:-$(command -v luajit || command -v lua5.1)}"
"$LUA" tests/run_tests.lua "$@"
if [ "${SIMULATE:-0}" = "1" ]; then "$LUA" tests/simulate.lua 4; fi
