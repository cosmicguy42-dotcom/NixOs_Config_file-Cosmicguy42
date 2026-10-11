-- Look & feel: flat, borderless (focus = opacity), no shadows; blur behind translucency. Colours: hyprland/colors.lua

-- Any monitor without its own rule: native resolution and a scale Hyprland
-- picks from the panel's DPI (so 4K / hi-DPI screens aren't tiny). Per-monitor
-- choices from Settings > Display land in hyprland/settings.lua.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto"
})

hl.gesture({ fingers = 3, direction = "swipe", action = "move" })
hl.gesture({ fingers = 3, direction = "pinch", action = "fullscreen" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        gaps_workspaces = 40,
        border_size = 0, -- focus is shown by opacity instead (see decoration)
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = true, -- lets the `immediate` window rule work
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 8,
            respect_gaps = true
        }
    },
    decoration = {
        rounding = 16,
        rounding_power = 2.5,
        -- Focus indicator: the focused window is solid, the rest turn to
        -- frosted glass (blur below shows through).
        active_opacity = 1.0,
        inactive_opacity = 0.82,
        fullscreen_opacity = 1.0,
        -- Blur shows through anything translucent: the pill, launcher, kitty.
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            noise = 0.02,
            contrast = 1.0,
            brightness = 1.0,
            vibrancy = 0.25,
            xray = false,
            popups = true,
            new_optimizations = true
        },
        shadow = { enabled = false },
        dim_inactive = false
    },
    animations = { enabled = true },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false
    },
    gestures = {
        workspace_swipe_distance = 700,
        workspace_swipe_cancel_ratio = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new = true
    },
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,
        follow_mouse = 1,
        off_window_axis_events = 2,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.7
        }
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        initial_workspace_tracking = false,
        focus_on_activate = true
    },
    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true
    },
    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        zoom_disable_aa = true,
        hotspot_padding = 1
    },
    xwayland = {
        force_zero_scaling = true
    }
})

-- Motion: one soft decelerating curve, short durations.
hl.curve("out", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("inOut", { type = "bezier", points = { { 0.65, 0 }, { 0.35, 1 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "out", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "out", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "out", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "out" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "out" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "out", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5, bezier = "inOut", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "out", style = "slidevert" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3, bezier = "out" })
