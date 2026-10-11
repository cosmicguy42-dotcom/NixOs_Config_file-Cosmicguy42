import QtQuick
import Quickshell
import qs.services
import qs.components

// Month at a glance; weekends in accent, today filled.
Glass {
    id: root
    width: 310
    height: col.height + 40

    SystemClock {
        id: time
        precision: SystemClock.Hours
    }
    readonly property date first: new Date(time.date.getFullYear(), time.date.getMonth(), 1)

    Column {
        id: col
        x: 20
        y: 20
        spacing: 10
        Heading { text: Qt.formatDateTime(time.date, "MMMM"); font.pixelSize: 30 }
        Grid {
            columns: 7
            columnSpacing: 2
            rowSpacing: 2
            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Caption {
                    required property string modelData
                    required property int index
                    width: 36
                    height: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: index >= 5 ? Theme.accent : Theme.dim
                }
            }
            Repeater {
                model: 42
                Item {
                    id: cell
                    required property int index
                    readonly property int lead: (root.first.getDay() + 6) % 7
                    readonly property date day: new Date(time.date.getFullYear(), time.date.getMonth(), index - lead + 1)
                    readonly property bool inMonth: day.getMonth() === time.date.getMonth()
                    readonly property bool today: day.toDateString() === time.date.toDateString()
                    visible: index < 35 || inMonth
                    width: 36
                    height: 30
                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: Theme.r(height / 2)
                        color: Theme.accent
                        visible: cell.today
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.day.getDate()
                        font.family: Theme.mono
                        font.pixelSize: 12
                        color: cell.today ? Theme.accentFg : (cell.day.getDay() % 6 === 0 ? Theme.accent : Theme.fg)
                        opacity: cell.inMonth ? 1 : 0.2
                    }
                }
            }
        }
    }
}
