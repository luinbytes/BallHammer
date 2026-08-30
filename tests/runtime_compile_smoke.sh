#!/usr/bin/env bash
set -euo pipefail

bytecode=$(mktemp)
trap 'rm -f "$bytecode"' EXIT
while IFS= read -r source; do
    luajit -b "$source" "$bytecode"
done < <(find scripts -type f -name '*.lua' -print | sort)
echo "BallHammer production LuaJIT compile smoke: ok"
