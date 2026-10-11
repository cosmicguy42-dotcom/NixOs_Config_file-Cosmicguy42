local home_dir = os.getenv("HOME")
local shell_dir = home_dir .. "/.config/quickshell/nothing"

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Applications
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
hl.env("XDG_DATA_DIRS", home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs_old)

-- Wallpaper-themed kitty + fuzzel, for this session only (niri keeps its own)
hl.env("KITTY_CONFIG_DIRECTORY", shell_dir .. "/apps/kitty")
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not path:find(shell_dir .. "/bin", 1, true) then
    hl.env("PATH", shell_dir .. "/bin:" .. path)
end
