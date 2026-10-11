import QtQuick
import qs.services
import qs.components

Page {
    title: "Widgets"
    subtitle: "Nothing-style widgets on the desktop, below your windows."

    Section {
        title: "Desktop"
        CSwitch { label: "Show widgets"; path: "widgets.enabled" }
        OptRow {
            label: "Arrange"
            sub: "Widgets rise above windows so you can drag them; press Done when finished"
            Row {
                spacing: 8
                OptButton { text: "Reset layout"; icon: "restart_alt"; onClicked: Config.set("widgets.layout", {}) }
                OptButton {
                    text: "Arrange widgets"
                    icon: "open_with"
                    accent: true
                    onClicked: {
                        Ui.widgetEdit = true;
                        Ui.settingsRequest = "__close"; // get Settings out of the way
                    }
                }
            }
        }
    }

    Section {
        title: "Widgets"
        CSwitch { label: "Clock"; sub: "Dot-matrix time and serif date"; path: "widgets.show.clock" }
        CSwitch { label: "Weather"; sub: "Temperature, glyph and the next few hours"; path: "widgets.show.weather" }
        CSwitch { label: "Now playing"; sub: "Shown only while something plays"; path: "widgets.show.media" }
        CSwitch { label: "Calendar"; path: "widgets.show.calendar" }
        CSwitch { label: "Battery"; sub: "Ring of dots"; path: "widgets.show.battery" }
        CSwitch { label: "System"; sub: "CPU, memory and disk"; path: "widgets.show.system" }
        CSwitch { label: "Note"; sub: "A sticky note that saves as you type"; path: "widgets.show.note" }
    }
}
