hl.on("hyprland.start", function()
    -- Shell: bar, wallpaper, notifications, polkit
    hl.exec_cmd("qs -c $qsConfig")
    -- Launcher (Raycast-style). Only in this session; skipped if not installed.
    hl.exec_cmd("command -v vicinae >/dev/null && vicinae server")

    -- Core
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    -- Only what portals/services need. (Not --all: that would push this
    -- session's PATH, kitty and Qt settings into the systemd user session,
    -- where they can leak into Plasma or niri.)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
