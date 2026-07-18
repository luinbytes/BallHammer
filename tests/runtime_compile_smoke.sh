#!/usr/bin/env bash
set -euo pipefail

bytecode=$(mktemp)
trap 'rm -f "$bytecode"' EXIT
luajit -b scripts/mods/BallHammer/BallHammer.lua "$bytecode"
echo "BallHammer LuaJIT compile smoke: ok"
