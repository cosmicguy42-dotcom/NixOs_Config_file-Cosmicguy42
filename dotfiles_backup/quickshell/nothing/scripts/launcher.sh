#!/usr/bin/env bash
# One entry point for the launcher, clipboard and emoji pickers.
#   launcher.sh apps | clipboard | emoji
# Uses vicinae when its server is running; otherwise falls back to the
# pill's own launcher and fuzzel, so nothing breaks if vicinae is missing.
set -uo pipefail
what="${1:-apps}"

# (the server process is "vicinae-server"; ping is the reliable check)
if command -v vicinae >/dev/null && vicinae ping >/dev/null 2>&1; then
    case "$what" in
        apps) exec vicinae vicinae://toggle ;;
        clipboard) exec vicinae vicinae://launch/clipboard/history ;;
        emoji) exec vicinae vicinae://launch/core/search-emojis ;;
    esac
fi

pkill -x fuzzel && exit 0 # a second press closes the fallback picker
case "$what" in
    apps) qs -c nothing ipc call shell toggle launcher 2>/dev/null || exec fuzzel ;;
    clipboard) cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy ;;
    emoji) exec "$HOME/.config/hypr/hyprland/scripts/fuzzel-emoji.sh" copy ;;
esac
