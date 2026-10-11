#!/usr/bin/env bash
# Restart the "nothing" shell.
#  - only inside a live Hyprland session (never in Plasma, niri, ...)
#  - only this shell's instance (qs kill -c nothing) - other Quickshell
#    configs, like a niri shell, are left alone
#  - never while the session is locked (that would drop the lock surface)
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || ! hyprctl version >/dev/null 2>&1; then
    echo "restart.sh: not in a Hyprland session, not restarting" >&2
    exit 1
fi
if [[ "$(qs -c nothing ipc call lock isLocked 2>/dev/null)" == "true" ]]; then
    echo "restart.sh: session is locked, not restarting" >&2
    exit 1
fi
qs kill -c nothing >/dev/null 2>&1
sleep 0.3
setsid qs -c nothing >"${1:-/dev/null}" 2>&1 </dev/null &
