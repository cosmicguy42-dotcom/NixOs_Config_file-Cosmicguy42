import QtQuick
import Quickshell
import qs.services
import qs.components

Page {
    id: page
    title: "Display"
    subtitle: "Changes apply straight away and revert after " + HyprConf.revertSeconds + " seconds unless you keep them, so a bad mode can't strand you."

    // Confirm banner for pending monitor changes
    Rectangle {
        visible: HyprConf.pendingMonitor !== null
        width: parent.width
        height: 64
        radius: Theme.r(Theme.radius)
        color: Theme.active
        Label {
            x: 22
            anchors.verticalCenter: parent.verticalCenter
            text: "Keep these display settings?"
            color: Theme.activeFg
            font.pixelSize: 13
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Rectangle {
                width: rv.implicitWidth + 30; height: 34; radius: Theme.r(height / 2)
                color: "transparent"; border.width: 1; border.color: Theme.activeFg
                Label { id: rv; anchors.centerIn: parent; text: "Revert"; color: Theme.activeFg }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HyprConf.revertMonitor() }
            }
            Rectangle {
                width: kp.implicitWidth + 30; height: 34; radius: Theme.r(height / 2)
                color: Theme.activeFg
                Label { id: kp; anchors.centerIn: parent; text: "Keep"; color: Theme.active }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HyprConf.keepMonitor() }
            }
        }
    }

    Repeater {
        model: HyprConf.monitors
        Section {
            id: mon
            required property var modelData
            // what you picked (a pending change shows immediately), and what
            // the display actually runs
            readonly property var st: HyprConf.pendingMonitor?.name === modelData.name
                ? HyprConf.pendingMonitor.next : (HyprConf.monitorState(modelData.name) ?? ({}))
            readonly property bool refused: String(st.cm ?? "srgb") !== "srgb" && String(st.cm) !== "auto"
                && modelData.colorManagementPreset !== undefined && modelData.colorManagementPreset !== st.cm
            readonly property var modes: (modelData.availableModes ?? []).map(m => {
                const x = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(m);
                return x ? { w: +x[1], h: +x[2], hz: +x[3] } : null;
            }).filter(x => x)
            readonly property var resolutions: {
                const seen = {}, out = [];
                for (const m of modes) {
                    const k = m.w + "x" + m.h;
                    if (!seen[k]) { seen[k] = true; out.push({ w: m.w, h: m.h }); }
                }
                return out.slice(0, 6);
            }
            readonly property var rates: modes.filter(m => m.w === modelData.width && m.h === modelData.height)
                .map(m => m.hz).filter((v, i, a) => a.findIndex(x => Math.abs(x - v) < 0.5) === i).sort((a, b) => b - a).slice(0, 6)
            readonly property bool hdr: String(st.cm ?? "").startsWith("hdr")
            // physical DPI, for the suggestion under Scale
            readonly property real dpi: modelData.physicalWidth > 0 ? modelData.width / (modelData.physicalWidth / 25.4) : 0

            function set(patch) { HyprConf.setMonitor(modelData.name, patch); }
            function mode(w, h, hz) { return w + "x" + h + "@" + hz.toFixed(2); }

            title: modelData.name + " · " + ((modelData.make || "") + " " + (modelData.model || "")).trim()

            OptChoice {
                label: "Resolution"
                sub: mon.modelData.width + " × " + mon.modelData.height + (mon.dpi ? " · " + Math.round(mon.dpi) + " dpi" : "")
                options: mon.resolutions.map(r => ({ label: r.w + "×" + r.h, value: r.w + "x" + r.h }))
                current: mon.modelData.width + "x" + mon.modelData.height
                onPicked: v => {
                    const [w, h] = v.split("x").map(Number);
                    const best = mon.modes.filter(m => m.w === w && m.h === h).sort((a, b) => b.hz - a.hz)[0];
                    mon.set({ mode: mon.mode(w, h, best.hz) });
                }
            }
            OptChoice {
                label: "Refresh rate"
                sub: mon.rates.length > 1 ? "" : "This panel only offers one rate"
                options: mon.rates.map(hz => ({ label: Math.round(hz) + " Hz", value: hz }))
                current: mon.rates.find(hz => Math.abs(hz - mon.modelData.refreshRate) < 0.5)
                onPicked: v => mon.set({ mode: mon.mode(mon.modelData.width, mon.modelData.height, v) })
            }
            OptChoice {
                label: "Scale"
                sub: "Auto picks from the panel's DPI" + (mon.dpi > 170 ? " · this is a hi-DPI screen" : "")
                options: [{ label: "Auto", value: "auto" }].concat([1, 1.25, 1.5, 1.75, 2, 2.5, 3].map(s => ({ label: s + "×", value: s })))
                current: mon.st.scale === "auto" ? "auto" : mon.modelData.scale
                onPicked: v => mon.set({ scale: v })
            }
            OptChoice {
                label: "Rotation"
                options: [{ label: "0°", value: 0 }, { label: "90°", value: 1 }, { label: "180°", value: 2 }, { label: "270°", value: 3 }]
                current: mon.modelData.transform ?? 0
                onPicked: v => mon.set({ transform: v })
            }
            OptChoice {
                label: "Variable refresh"
                sub: "For this monitor (overrides the global setting below)"
                options: [{ label: "Default", value: -1 }, { label: "Off", value: 0 }, { label: "On", value: 1 }, { label: "Fullscreen", value: 2 }]
                current: mon.st.vrr ?? -1
                onPicked: v => mon.set({ vrr: v < 0 ? undefined : v })
            }

            // --- Colour
            OptChoice {
                label: "Colour"
                sub: "sRGB for most panels · Wide for P3 panels · HDR needs an HDR-capable display"
                options: [
                    { label: "sRGB", value: "srgb" }, { label: "Wide", value: "wide" },
                    { label: "HDR", value: "hdr" }, { label: "HDR (EDID)", value: "hdredid" }, { label: "Auto", value: "auto" }
                ]
                current: mon.st.cm
                // HDR wants a 10-bit buffer; switching to it bumps the depth too
                onPicked: v => mon.set(String(v).startsWith("hdr") ? { cm: v, bitdepth: 10 } : { cm: v })
            }
            OptRow {
                visible: mon.refused
                label: "The display kept " + (mon.modelData.colorManagementPreset ?? "sRGB")
                sub: "It doesn't report " + (mon.hdr ? "HDR" : "wide colour") + " support in its EDID. Some panels support it anyway - forcing is safe to try, it reverts unless you keep it."
                OptButton {
                    text: "Force " + (mon.hdr ? "HDR" : "wide colour")
                    icon: "bolt"
                    onClicked: mon.set({ supports_hdr: true })
                }
            }
            OptChoice {
                label: "Bit depth"
                sub: "10-bit reduces banding; required for HDR"
                options: [{ label: "8-bit", value: 8 }, { label: "10-bit", value: 10 }]
                current: mon.st.bitdepth
                onPicked: v => mon.set({ bitdepth: v })
            }
            OptSlider {
                visible: mon.hdr
                label: "SDR brightness"
                sub: "How bright normal content looks while HDR is on"
                from: 0.5
                to: 2
                step: 0.05
                decimals: 2
                suffix: "×"
                value: mon.st.sdrbrightness ?? 1
                onCommitted: v => mon.set({ sdrbrightness: Number(v.toFixed(2)) })
            }
            OptSlider {
                visible: mon.hdr
                label: "SDR saturation"
                from: 0.5
                to: 1.5
                step: 0.05
                decimals: 2
                suffix: "×"
                value: mon.st.sdrsaturation ?? 1
                onCommitted: v => mon.set({ sdrsaturation: Number(v.toFixed(2)) })
            }
            OptText {
                label: "ICC profile"
                sub: "Path to a calibration .icc/.icm file (empty = none)"
                text: mon.st.icc ?? ""
                placeholder: "~/.local/share/icc/panel.icc"
                fieldWidth: 300
                onAccepted: t => mon.set({ icc: t.trim().replace(/^~/, Quickshell.env("HOME")) })
            }
            OptRow {
                label: "Position"
                sub: "Arrange multiple monitors in nwg-displays or HyprMod"
                Row {
                    spacing: 10
                    Caption { anchors.verticalCenter: parent.verticalCenter; text: mon.modelData.x + ", " + mon.modelData.y; color: Theme.fg }
                    OptButton {
                        visible: HyprConf.monitorOverrides[mon.modelData.name] !== undefined
                        text: "Reset monitor"
                        icon: "restart_alt"
                        onClicked: HyprConf.resetMonitor(mon.modelData.name)
                    }
                }
            }
        }
    }

    Section {
        title: "Picture"
        OptSlider {
            visible: Brightness.available
            label: "Brightness"
            from: 1
            to: 100
            suffix: "%"
            value: Math.round(Brightness.value * 100)
            onCommitted: v => Brightness.set(v / 100)
        }
        OptSwitch {
            label: "Night light"
            sub: "Warmer colours via hyprsunset"
            checked: Toggles.nightLight
            onToggled: on => Toggles.setNightLight(on)
        }
        OptSlider {
            label: "Night light warmth"
            from: 2500
            to: 6000
            step: 100
            suffix: " K"
            value: Config.nightTemp
            onCommitted: v => {
                Config.set("nightLight.temperature", Math.round(v));
                if (Toggles.nightLight)
                    applyLater.restart();
            }
            Timer { id: applyLater; interval: 200; onTriggered: Toggles.applyNightLight() }
        }
    }

    Section {
        title: "Colour management"
        HSwitch { label: "Colour management"; sub: "Needed for Wide, HDR and ICC profiles"; key: "render:cm_enabled" }
        HChoice {
            label: "Auto HDR for fullscreen"
            sub: "Switch HDR on when a fullscreen app (game, video) asks for it"
            key: "render:cm_auto_hdr"
            options: [{ label: "Off", value: 0 }, { label: "HDR", value: 1 }, { label: "HDR (EDID)", value: 2 }]
        }
        HSwitch { label: "Send content type"; sub: "Tell the display whether it's showing a game, video or photo"; key: "render:send_content_type" }
    }

    Section {
        title: "Refresh & power"
        HChoice {
            label: "Variable refresh rate"
            sub: "Default for all monitors"
            key: "misc:vrr"
            options: [{ label: "Off", value: 0 }, { label: "On", value: 1 }, { label: "Fullscreen", value: 2 }]
        }
        HSwitch { label: "Wake on mouse move"; key: "misc:mouse_move_enables_dpms" }
        HSwitch { label: "Wake on key press"; key: "misc:key_press_enables_dpms" }
        HSwitch { label: "XWayland zero scaling"; sub: "Sharp X11 apps on scaled displays (they may look small)"; key: "xwayland:force_zero_scaling" }
    }
}
