import QtQuick
import qs.services
import qs.components

Page {
    title: "Input"
    subtitle: "Keyboard, mouse, touchpad and gestures."

    Section {
        title: "Keyboard"
        HText { label: "Layout"; sub: "Comma-separated, e.g. us,de"; key: "input:kb_layout"; placeholder: "us" }
        HText { label: "Variant"; key: "input:kb_variant"; placeholder: "none" }
        HText { label: "Options"; sub: "XKB options, e.g. caps:escape,grp:alt_shift_toggle"; key: "input:kb_options"; placeholder: "none"; fieldWidth: 280 }
        HSlider { label: "Repeat rate"; key: "input:repeat_rate"; from: 10; to: 80; suffix: "/s" }
        HSlider { label: "Repeat delay"; key: "input:repeat_delay"; from: 150; to: 1000; step: 10; suffix: " ms" }
        HSwitch { label: "Num Lock on start"; key: "input:numlock_by_default" }
    }

    Section {
        title: "Mouse"
        HSlider { label: "Sensitivity"; key: "input:sensitivity"; from: -1; to: 1; step: 0.05; decimals: 2 }
        HChoice {
            label: "Acceleration"
            key: "input:accel_profile"
            options: [{ label: "Default", value: "" }, { label: "Adaptive", value: "adaptive" }, { label: "Flat", value: "flat" }]
        }
        HSwitch { label: "Natural scrolling"; key: "input:natural_scroll" }
        HSlider { label: "Scroll speed"; key: "input:scroll_factor"; from: 0.1; to: 3; step: 0.1; decimals: 1; suffix: "×" }
        HChoice {
            label: "Focus follows mouse"
            key: "input:follow_mouse"
            options: [{ label: "Off", value: 0 }, { label: "Always", value: 1 }, { label: "Click", value: 2 }, { label: "Loose", value: 3 }]
        }
        HSwitch { label: "Left-handed"; key: "input:left_handed" }
        HSwitch { label: "Middle-click paste"; key: "misc:middle_click_paste" }
    }

    Section {
        title: "Touchpad"
        HSwitch { label: "Natural scrolling"; key: "input:touchpad:natural_scroll" }
        HSwitch { label: "Tap to click"; key: "input:touchpad:tap-to-click" }
        HSwitch { label: "Disable while typing"; key: "input:touchpad:disable_while_typing" }
        HSwitch { label: "Click with fingers"; sub: "Two-finger click = right, three = middle"; key: "input:touchpad:clickfinger_behavior" }
        HSwitch { label: "Drag lock"; sub: "Lifting a finger mid-drag doesn't drop"; key: "input:touchpad:drag_lock" }
        HSwitch { label: "Middle-button emulation"; key: "input:touchpad:middle_button_emulation" }
        HSlider { label: "Scroll speed"; key: "input:touchpad:scroll_factor"; from: 0.1; to: 2; step: 0.05; decimals: 2; suffix: "×" }
    }

    Section {
        title: "Gestures"
        HSwitch { label: "Invert workspace swipe"; key: "gestures:workspace_swipe_invert" }
        HSlider { label: "Swipe distance"; key: "gestures:workspace_swipe_distance"; from: 100; to: 1500; step: 10; suffix: " px" }
        HSlider { label: "Cancel ratio"; sub: "How far a swipe must go to switch"; key: "gestures:workspace_swipe_cancel_ratio"; from: 0; to: 1; step: 0.05; decimals: 2 }
        HSwitch { label: "Swipe creates workspaces"; key: "gestures:workspace_swipe_create_new" }
    }

    Section {
        title: "Cursor"
        HSlider { label: "Hide after inactivity"; sub: "0 keeps it visible"; key: "cursor:inactive_timeout"; from: 0; to: 30; suffix: " s" }
        HSwitch { label: "Hide while typing"; key: "cursor:hide_on_key_press" }
        HSwitch { label: "No cursor warps"; sub: "Don't move the cursor when focus changes"; key: "cursor:no_warps" }
    }
}
