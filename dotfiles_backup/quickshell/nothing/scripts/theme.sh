#!/usr/bin/env bash
# Applies wallpaper + colours for the "nothing" shell.
#
#   theme.sh                          re-apply current state
#   theme.sh wall <path>              set wallpaper
#   theme.sh random                   random wallpaper from the wallpaper folder
#   theme.sh mode dark|light|toggle
#   theme.sh scheme <matugen scheme type, e.g. scheme-monochrome>
#   theme.sh contrast <-1..1>
#   theme.sh lead <0-4>               which wallpaper colour leads (the accent)
#   theme.sh neutral on|off           neutral near-black/white surfaces
#   theme.sh source wallpaper|custom  colours from the wallpaper, or hand-picked
#   theme.sh custom <base> <surface> <accent>   hand-picked hex colours
#   theme.sh cover <hex>              accent from the playing track's cover art
#
# Arguments can be combined: theme.sh random mode light
set -uo pipefail

SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nothing"
STATE="$STATE_DIR/state.json"
WALLS=$(jq -r '.wallpaper.dir // empty' "$SHELL_DIR/config.json" 2>/dev/null)
WALLS="${WALLS:-${NOTHING_WALLPAPERS:-$HOME/Pictures/Wallpapers}}"
WALLS="${WALLS/#\~/$HOME}"
mkdir -p "$STATE_DIR"

list_walls() {
    find "$WALLS" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort
}

[[ -s "$STATE" ]] || echo '{}' > "$STATE"
get() { jq -r "$1" "$STATE"; }
wall=$(get '.wallpaper // ""')
mode=$(get '.mode // "dark"')
scheme=$(get '.scheme // "scheme-tonal-spot"')
contrast=$(get '.contrast // 0')
lead=$(get '.lead // 0')
neutral=$(get 'if .neutral == null then true else .neutral end')
source=$(get '.source // "wallpaper"')
cbase=$(get '.custom.base // "#000000"')
csurf=$(get '.custom.surface // "#141414"')
cacc=$(get '.custom.accent // "#d71921"')
cover=$(get '.cover // "#d71921"')

while (($#)); do
    case "$1" in
        wall) wall="$2"; lead=0; shift 2 ;;
        random) wall=$(list_walls | grep -vxF "$wall" | shuf -n1); lead=0; shift ;;
        mode)
            if [[ "$2" == toggle ]]; then
                [[ "$mode" == dark ]] && mode=light || mode=dark
            else
                mode="$2"
            fi
            shift 2 ;;
        scheme) scheme="$2"; shift 2 ;;
        contrast) contrast="$2"; shift 2 ;;
        lead) lead="$2"; shift 2 ;;
        neutral) [[ "$2" == on || "$2" == true ]] && neutral=true || neutral=false; shift 2 ;;
        source) source="$2"; shift 2 ;;
        custom) cbase="$2"; csurf="$3"; cacc="$4"; source=custom; shift 4 ;;
        cover) cover="$2"; source=cover; shift 2 ;;
        *) echo "theme.sh: unknown argument '$1'" >&2; exit 1 ;;
    esac
done

[[ -f "$wall" ]] || wall=$(list_walls | head -n1)
[[ -f "$wall" ]] || { echo "theme.sh: no wallpaper found in $WALLS" >&2; exit 1; }
CFG="$SHELL_DIR/matugen/config.toml"

# Candidate lead colours for Settings (matugen's source colours).
matugen image "$wall" -c "$CFG" --show-source-colors 2>/dev/null \
    | grep -oE '#[0-9a-fA-F]{6}' | jq -R . | jq -s . > "$STATE_DIR/sources.json"
count=$(jq length "$STATE_DIR/sources.json")
(( lead >= count )) && lead=0

# Written in place (not mv) so Quickshell's file watcher keeps working.
jq -n --arg w "$wall" --arg m "$mode" --arg s "$scheme" --argjson c "$contrast" \
      --argjson l "$lead" --argjson n "$neutral" --arg src "$source" \
      --arg b "$cbase" --arg sf "$csurf" --arg a "$cacc" --arg cv "$cover" \
    '{wallpaper: $w, mode: $m, scheme: $s, contrast: $c, lead: $l, neutral: $n, source: $src,
      custom: {base: $b, surface: $sf, accent: $a}, cover: $cv}' > "$STATE"

# 1. Palette from matugen (wallpaper, or the hand-picked accent)
PAL="$STATE_DIR/palette.json"
if [[ "$source" == cover ]]; then
    matugen color hex "$cover" -c "$CFG" -m "$mode" -t "$scheme" --contrast "$contrast" --dry-run -j hex > "$PAL" 2>/dev/null
elif [[ "$source" == custom ]]; then
    matugen color hex "$cacc" -c "$CFG" -m "$mode" -t "$scheme" --contrast "$contrast" --dry-run -j hex > "$PAL" 2>/dev/null
else
    matugen image "$wall" -c "$CFG" -m "$mode" -t "$scheme" --contrast "$contrast" \
        --source-color-index "$lead" --dry-run -j hex > "$PAL" 2>/dev/null
fi
jq -e .colors "$PAL" >/dev/null 2>&1 || { echo "theme.sh: matugen failed" >&2; exit 1; }

# 2. Neutral / custom surfaces + render all templates
python3 "$SHELL_DIR/scripts/render.py" "$PAL" "$STATE" || exit 1

# 3. Terminal palette
python3 "$SHELL_DIR/scripts/kitty.py" "$STATE_DIR/colors.json" "$STATE_DIR/kitty-colors.conf"

# Live-reload what's running. Everything here is Hyprland-session only.
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl eval "$(cat "$HOME/.config/hypr/hyprland/colors.lua")" >/dev/null
fi
# Reload only this session's kitties (the ones using our config dir), not
# kitty windows from other desktops.
for pid in $(pgrep -x kitty); do
    grep -qzx "KITTY_CONFIG_DIRECTORY=$SHELL_DIR/apps/kitty" "/proc/$pid/environ" 2>/dev/null && kill -USR1 "$pid"
done
exit 0
