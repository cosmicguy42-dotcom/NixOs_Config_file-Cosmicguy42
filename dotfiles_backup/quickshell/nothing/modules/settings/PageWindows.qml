import QtQuick
import qs.services
import qs.components

Page {
    title: "Windows"
    subtitle: "Hyprland layout and decoration. Changes apply instantly; a dot marks what you've changed (click it to reset)."

    Section {
        title: "Layout"
        HChoice {
            label: "Tiling layout"
            key: "general:layout"
            options: [{ label: "Dwindle", value: "dwindle" }, { label: "Master", value: "master" }]
        }
        HSwitch { label: "Preserve split"; sub: "Dwindle keeps the split direction when windows move"; key: "dwindle:preserve_split" }
        HSwitch { label: "Smart split"; sub: "Split based on where the cursor is"; key: "dwindle:smart_split" }
        HChoice {
            label: "New window (master)"
            key: "master:new_status"
            options: [{ label: "Slave", value: "slave" }, { label: "Master", value: "master" }, { label: "Inherit", value: "inherit" }]
        }
        HSwitch { label: "Snapping"; sub: "Floating windows snap to edges and each other"; key: "general:snap:enabled" }
        HSwitch { label: "Resize on border"; sub: "Drag window edges to resize"; key: "general:resize_on_border" }
    }

    Section {
        title: "Gaps & borders"
        CSlider { label: "Gap"; sub: "Shared with the pill (Appearance > Shape)"; path: "look.gap"; from: 0; to: 24; step: 2; suffix: " px" }
        HSlider { label: "Border width"; sub: "0 by default: focus is shown by opacity"; key: "general:border_size"; from: 0; to: 6; suffix: " px" }
        CSlider { label: "Corner radius"; sub: "Shared with every shell surface (Appearance > Shape)"; path: "look.radius"; from: 0; to: 32; suffix: " px" }
        HSlider { label: "Corner shape"; sub: "2 is a circle arc, higher is squircle-ish"; key: "decoration:rounding_power"; from: 1; to: 5; step: 0.1; decimals: 1 }
    }

    Section {
        title: "Focus"
        HSlider { label: "Unfocused windows"; sub: "Frosted glass instead of borders shows which window has focus. 1 turns it off."; key: "decoration:inactive_opacity"; from: 0.5; to: 1; step: 0.01; decimals: 2 }
        HSlider { label: "Focused window"; key: "decoration:active_opacity"; from: 0.5; to: 1; step: 0.01; decimals: 2 }
        HSwitch { label: "Dim inactive windows"; key: "decoration:dim_inactive" }
        HSlider { label: "Dim strength"; key: "decoration:dim_strength"; from: 0; to: 0.6; step: 0.01; decimals: 2 }
    }

    Section {
        title: "Blur"
        HSwitch { label: "Enabled"; key: "decoration:blur:enabled" }
        HSlider { label: "Size"; key: "decoration:blur:size"; from: 1; to: 20 }
        HSlider { label: "Passes"; sub: "More passes are smoother but cost GPU"; key: "decoration:blur:passes"; from: 1; to: 6 }
        HSlider { label: "Vibrancy"; key: "decoration:blur:vibrancy"; from: 0; to: 1; step: 0.05; decimals: 2 }
        HSlider { label: "Noise"; key: "decoration:blur:noise"; from: 0; to: 0.2; step: 0.01; decimals: 2 }
        HSwitch { label: "X-ray"; sub: "Floating windows blur only the wallpaper"; key: "decoration:blur:xray" }
        HSwitch { label: "Blur popups"; key: "decoration:blur:popups" }
    }

    Section {
        title: "Shadow"
        HSwitch { label: "Enabled"; key: "decoration:shadow:enabled" }
        HSlider { label: "Range"; key: "decoration:shadow:range"; from: 0; to: 60; suffix: " px" }
        HSlider { label: "Falloff"; key: "decoration:shadow:render_power"; from: 1; to: 4 }
    }

    Section {
        title: "Motion & behaviour"
        HSwitch { label: "Animations"; key: "animations:enabled" }
        HSwitch { label: "Focus on activate"; sub: "Apps asking for attention get focused"; key: "misc:focus_on_activate" }
        HSwitch { label: "Window swallowing"; sub: "Terminals hide while a GUI app they launched is open"; key: "misc:enable_swallow" }
        HSwitch { label: "Allow tearing"; sub: "Lower latency for games that request it"; key: "general:allow_tearing" }
        HSwitch { label: "Workspace back and forth"; sub: "Pressing the current workspace key goes back"; key: "binds:workspace_back_and_forth" }
    }

    Row {
        spacing: 10
        OptButton { text: "Reset all Hyprland changes"; icon: "restart_alt"; onClicked: HyprConf.resetAll() }
    }
}
