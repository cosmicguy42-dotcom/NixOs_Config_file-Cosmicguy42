-- Hyprland Lua Configuration - Arch Hyprland Rice & ZaneyOS Integration

-- Load ZaneyOS base modules
require("zaneyos.vars")
require("zaneyos.settings")
require("zaneyos.monitors")
require("zaneyos.env")
require("zaneyos.animations")
require("zaneyos.window_rules")
require("zaneyos.startup")
require("zaneyos.keybinds")

-- Ensure French keyboard layout
hl.config({
  input = {
    kb_layout = "fr",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
    },
  },
})

-- Parse dynamic Matugen colors
local colors = {}
local colors_file = io.open(os.getenv("HOME") .. "/.config/hypr/colors.conf", "r")
if colors_file then
  for line in colors_file:lines() do
    local var, val = line:match("^%$([%w_]+)%s*=%s*(.+)$")
    if var and val then
      colors[var] = val:gsub("%s+$", "")
    end
  end
  colors_file:close()
end

local active_border = {
  colors = {
    colors["primary"] or "rgba(99ccfaff)",
    colors["primary_fixed"] or "rgba(74c7ecff)",
  },
  angle = 45,
}
local inactive_border = colors["outline_variant"] or "rgba(42474eff)"

-- Arch-Hyprland Look & Feel (Gaps 5/10, Border 2, Rounding 10, Dynamic Matugen Borders)
hl.config({
  general = {
    layout = "dwindle",
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
    resize_on_border = false,
    col = {
      active_border = active_border,
      inactive_border = inactive_border,
    },
  },
  decoration = {
    rounding = 10,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 0.85,
    shadow = {
      enabled = false,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      enabled = true,
      size = 5,
      passes = 3,
      ignore_opacity = true,
      new_optimizations = true,
      special = false,
      popups = true,
      xray = true,
      vibrancy = 0.1696,
    },
  },
  dwindle = {
    preserve_split = true,
  },
  misc = {
    disable_hyprland_logo = true,
  },
})

-- Layer rules (Blur and transparency for rofi launcher)
hl.layer_rule({
  match = { namespace = "rofi" },
  blur = true,
  ignore_alpha = 0.5,
  xray = false,
})

-- Keybindings
local home = os.getenv("HOME")
local scripts = home .. "/.config/hypr/scripts"

local function safe_bind(chord_str, action)
  if hl.unbind then
    pcall(hl.unbind, chord_str)
  end
  hl.bind(chord_str, action)
end

local function run(cmd)
  return function()
    os.execute(cmd .. " &")
  end
end

-- App Launcher & Wallpapers
safe_bind("SUPER + R", run(home .. "/.local/bin/rofi-launcher"))
safe_bind("SUPER + D", run(home .. "/.local/bin/rofi-launcher"))
safe_bind("SUPER + W", run(scripts .. "/wppicker.sh"))
safe_bind("SUPER + B", run("zen"))
safe_bind("SUPER + C", run("hyprpicker -a"))
safe_bind("SUPER + H", run("pkill -SIGUSR1 waybar"))
safe_bind("SUPER + SHIFT + R", run(scripts .. "/wbrestart.sh"))
safe_bind("SUPER + CTRL + B", run(scripts .. "/WaybarStyles.sh"))
safe_bind("SUPER + ALT + B", run(scripts .. "/WaybarLayout.sh"))
safe_bind("SUPER + E", run("nautilus"))

-- Spotify / Scratchpad
safe_bind("SUPER + S", function()
  if hl.dsp and hl.dsp.workspace and hl.dsp.workspace.toggle_special then
    hl.dispatch(hl.dsp.workspace.toggle_special())
  end
end)
safe_bind("SUPER + SHIFT + S", function()
  if hl.dsp and hl.dsp.window and hl.dsp.window.move then
    hl.dispatch(hl.dsp.window.move({ workspace = "special:magic" }))
  end
end)

-- Screenshots & Screen Recording
safe_bind("Print", run(scripts .. "/screenshot.sh"))
safe_bind("SUPER + A", run(scripts .. "/screenshot.sh"))
safe_bind("SHIFT + Print", run(scripts .. "/screenrecord.sh"))
safe_bind("SUPER + SHIFT + A", run(scripts .. "/screenrecord.sh"))

-- Multimedia keys
safe_bind("XF86AudioRaiseVolume", run(scripts .. "/volume.sh --inc"))
safe_bind("XF86AudioLowerVolume", run(scripts .. "/volume.sh --dec"))
safe_bind("XF86AudioMute", run(scripts .. "/volume.sh --toggle"))
safe_bind("XF86MonBrightnessUp", run(scripts .. "/brightness.sh --inc"))
safe_bind("XF86MonBrightnessDown", run(scripts .. "/brightness.sh --dec"))
