#!/usr/bin/env bash
# Prints the live value of each Hyprland option given as an argument, as one
# JSON object: {"general:gaps_in": 4, ...}. Unknown options are skipped.
for k in "$@"; do
    out=$(hyprctl getoption "$k" -j 2>/dev/null)
    jq -e . >/dev/null 2>&1 <<<"$out" && printf '%s\n' "$out"
done | jq -s '
  map(select(.option != null) | {(.option): (
      if has("int") then .int
      elif has("float") then .float
      elif has("bool") then .bool
      elif has("str") then (if .str == "[[EMPTY]]" then "" else .str end)
      elif has("css") then (.css | split(" ")[0] | tonumber)
      else null end)}) | add // {}'
