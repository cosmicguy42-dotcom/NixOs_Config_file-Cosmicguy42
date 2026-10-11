-- ######## Window rules ########

-- Dialogs float, centred
local dialogs = {
    "^(Open File)(.*)$", "^(Select a File)(.*)$", "^(Choose wallpaper)(.*)$", "^(Open Folder)(.*)$",
    "^(Save As)(.*)$", "^(Library)(.*)$", "^(File Upload)(.*)$", "^(.*)(wants to save)$", "^(.*)(wants to open)$",
}
for _, title in ipairs(dialogs) do
    hl.window_rule({ match = { title = title }, float = true })
    hl.window_rule({ match = { title = title }, center = true })
end

-- Small utility apps float
local utilities = { "^(pavucontrol)$", "^(org.pulseaudio.pavucontrol)$", "^(nm-connection-editor)$", "^(Zotero)$" }
for _, class in ipairs(utilities) do
    hl.window_rule({ match = { class = class }, float = true })
    hl.window_rule({ match = { class = class }, center = true })
    hl.window_rule({ match = { class = class }, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
end
hl.window_rule({ match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" }, float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, size = { "(monitor_w*0.60)", "(monitor_h*0.65)" } })
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = { 40, 80 } })
hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- Picture-in-Picture
local pip = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
hl.window_rule({ match = { title = pip }, float = true })
hl.window_rule({ match = { title = pip }, pin = true })
hl.window_rule({ match = { title = pip }, keep_aspect_ratio = true })
hl.window_rule({ match = { title = pip }, move = { "(monitor_w*0.73)", "(monitor_h*0.72)" } })
hl.window_rule({ match = { title = pip }, size = { "(monitor_w*0.25)", "(monitor_h*0.25)" } })
hl.window_rule({ match = { title = pip }, opaque = true }) -- video never fades when unfocused

-- Screen sharing indicator
local sharing = ".*is sharing (a window|your screen).*"
hl.window_rule({ match = { title = sharing }, float = true })
hl.window_rule({ match = { title = sharing }, pin = true })
hl.window_rule({ match = { title = sharing }, move = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" } })

-- Tearing for games
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ match = { title = ".*minecraft.*" }, immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- ######## Workspace rules ########
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- ######## Layer rules ########
-- Blur behind the pill and launcher. ignore_alpha keeps the blur to the
-- pill's shape (the rest of the bar layer is fully transparent).
hl.layer_rule({ match = { namespace = "nothing:bar" }, blur = true })
hl.layer_rule({ match = { namespace = "nothing:bar" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "nothing:bar" }, blur_popups = true })
hl.layer_rule({ match = { namespace = "vicinae" }, blur = true })
hl.layer_rule({ match = { namespace = "vicinae" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "vicinae" }, no_anim = true })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true })
hl.layer_rule({ match = { namespace = "launcher" }, ignore_alpha = 0.2 })

-- The shell animates itself; Hyprland shouldn't add its own on top.
hl.layer_rule({ match = { namespace = "nothing:.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })

-- Shell windows
hl.window_rule({ match = { title = "^(Lock screen preview)$" }, float = true })
hl.window_rule({ match = { title = "^(Lock screen preview)$" }, center = true })
hl.window_rule({ match = { title = "^(Nothing Settings)$" }, float = true })
hl.window_rule({ match = { title = "^(Nothing Settings)$" }, center = true })

-- Desktop widgets: frosted like the pill
hl.layer_rule({ match = { namespace = "nothing:widgets" }, blur = true })
hl.layer_rule({ match = { namespace = "nothing:widgets" }, ignore_alpha = 0.2 })
