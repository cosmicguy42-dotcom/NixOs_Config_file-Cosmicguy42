local cfg = ZANEYOS or {}
local keyboard = cfg.keyboard or {}
local theme = cfg.theme or {}

local function non_empty(value)
  return value ~= nil and value ~= ""
end
local function normalize_hex(raw, fallback)
  local value = tostring(raw or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("^#", "")
  if value:match("^[0-9a-fA-F]+$") and (#value == 6 or #value == 8) then
    return value:lower()
  end
  return fallback
end

local function rgba(raw, fallback, alpha)
  local hex = normalize_hex(raw, fallback)
  if #hex == 6 then
    hex = hex .. alpha
  end
  return "rgba(" .. hex .. ")"
end

local active_border = {
  colors = {
    rgba("99ccfa", "99ccfa", "ff"),
    rgba("74c7ec", "74c7ec", "ff"),
  },
  angle = 45,
}

local inactive_border = rgba("42474e", "42474e", "aa")

hl.config({
  input = {
    kb_layout = keyboard.layout or "us",
    kb_options = "grp:alt_caps_toggle,caps:super",
    numlock_by_default = true,
    repeat_delay = 300,
    follow_mouse = 1,
    float_switch_override_focus = 0,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      scroll_factor = 0.8,
    },
  },
})

if non_empty(keyboard.variant) then
  hl.config({
    input = {
      kb_variant = keyboard.variant,
    },
  })
end

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

hl.config({
  gestures = {
    workspace_swipe_distance = 500,
    workspace_swipe_invert = true,
    workspace_swipe_min_speed_to_force = 30,
    workspace_swipe_cancel_ratio = 0.5,
    workspace_swipe_create_new = true,
    workspace_swipe_forever = true,
  },
})

hl.config({
  general = {
    layout = "dwindle",
    gaps_in = 4,
    gaps_out = 8,
    border_size = 1,
    resize_on_border = true,
    col = {
      active_border = active_border,
      inactive_border = inactive_border,
    },
  },
})

hl.config({
  misc = {
    layers_hog_keyboard_focus = true,
    initial_workspace_tracking = 0,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    enable_swallow = false,
    vrr = 2,
    enable_anr_dialog = true,
    anr_missed_pings = 15,
  },
})

hl.config({
  dwindle = {
    preserve_split = true,
    smart_resizing = true,
    use_active_for_splits = true,
    smart_split = false,
    default_split_ratio = 1.0,
    split_bias = 0,
    precise_mouse_move = false,
    special_scale_factor = 0.8,
  },
})

hl.config({
  decoration = {
    rounding = 2,
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      ignore_opacity = false,
      new_optimizations = true,
    },
    shadow = {
      enabled = true,
      range = 3,
      render_power = 3,
      color = "rgba(121212ff)",
    },
  },
})

hl.config({
  ecosystem = {
    no_donation_nag = true,
    no_update_news = false,
  },
})

hl.config({
  cursor = {
    sync_gsettings_theme = true,
    no_hardware_cursors = 2,
    enable_hyprcursor = false,
    warp_on_change_workspace = 2,
    no_warps = false,
  },
})

hl.config({
  render = {
    direct_scanout = 0,
  },
})

hl.config({
  master = {
    new_status = "slave",
    new_on_top = false,
    new_on_active = "none",
    orientation = "left",
    mfact = 0.55,
    slave_count_for_center_master = 2,
    center_master_fallback = "left",
    smart_resizing = true,
    drop_at_cursor = true,
    always_keep_position = false,
  },
})

hl.config({
  scrolling = {
    column_width = 0.80,
    fullscreen_on_one_column = true,
    direction = "right",
    follow_focus = true,
  },
})

hl.config({
  monocle = {},
})

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})
