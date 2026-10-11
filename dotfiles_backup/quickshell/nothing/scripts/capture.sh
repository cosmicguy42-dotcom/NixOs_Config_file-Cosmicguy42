#!/usr/bin/env bash
# Screenshots and screen recording for the "nothing" shell.
#
#   capture.sh shot area|window|screen [delay-seconds]
#   capture.sh rec  area|screen [audio]      toggles: a second call stops
#   capture.sh stop                          stop recording
#   capture.sh edit|copy|open                act on the last capture
#
# Screenshots: ~/Pictures/Screenshots (also copied to the clipboard).
# Recordings:  ~/Videos/Recordings.
# The last capture's path is kept in ~/.local/state/nothing/last-capture, the
# recording start time in ~/.local/state/nothing/recording.
set -uo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nothing"
SHOTS="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
VIDS="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Recordings"
mkdir -p "$STATE" "$SHOTS" "$VIDS"
stamp() { date '+%Y-%m-%d_%H.%M.%S'; }
monitor() { hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'; }
window_geom() { hyprctl activewindow -j | jq -r 'if .at then "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])" else empty end'; }
notify() { notify-send -a "${3:-Capture}" ${4:+-i "$4"} "$1" "$2"; }

case "${1:-}" in
shot)
    mode="${2:-area}"; delay="${3:-0}"
    # let the island collapse before anything is captured
    sleep 0.35
    geom=""
    case "$mode" in
        area) geom=$(slurp -d) || exit 1 ;;
        window) geom=$(window_geom); [[ -n "$geom" ]] || { notify "Screenshot" "No focused window"; exit 1; } ;;
        screen) ;;
        *) echo "unknown mode $mode" >&2; exit 1 ;;
    esac
    (( delay > 0 )) && sleep "$delay"
    file="$SHOTS/Screenshot_$(stamp).png"
    if [[ -n "$geom" ]]; then grim -g "$geom" "$file"; else grim -o "$(monitor)" "$file"; fi || exit 1
    wl-copy --type image/png < "$file"
    printf '%s' "$file" > "$STATE/last-capture"
    notify "Screenshot saved" "$(basename "$file") · copied" "Screenshot" "$file"
    ;;
rec)
    if pgrep -x wf-recorder >/dev/null; then exec "$0" stop; fi
    mode="${2:-area}"; audio="${3:-}"
    sleep 0.35
    args=()
    case "$mode" in
        area) geom=$(slurp -d) || exit 1; args+=(-g "$geom") ;;
        screen) args+=(-o "$(monitor)") ;;
        *) echo "unknown mode $mode" >&2; exit 1 ;;
    esac
    if [[ "$audio" == audio ]]; then
        sink=$(pactl get-default-sink 2>/dev/null)
        args+=(--audio="${sink}.monitor")
    fi
    file="$VIDS/Recording_$(stamp).mp4"
    printf '%s' "$file" > "$STATE/last-capture"
    date +%s > "$STATE/recording"
    setsid wf-recorder "${args[@]}" --pixel-format yuv420p -f "$file" >/dev/null 2>&1 &
    ;;
stop)
    pkill -INT -x wf-recorder
    for _ in $(seq 20); do pgrep -x wf-recorder >/dev/null || break; sleep 0.2; done
    : > "$STATE/recording"
    file=$(cat "$STATE/last-capture" 2>/dev/null)
    notify "Recording saved" "$(basename "$file")" "Recorder"
    ;;
edit) swappy -f "$(cat "$STATE/last-capture")" ;;
copy)
    f=$(cat "$STATE/last-capture")
    [[ "$f" == *.png ]] && wl-copy --type image/png < "$f" || printf 'file://%s' "$f" | wl-copy --type text/uri-list
    ;;
open) xdg-open "$(cat "$STATE/last-capture")" ;;
*) sed -n '2,12p' "$0"; exit 1 ;;
esac
