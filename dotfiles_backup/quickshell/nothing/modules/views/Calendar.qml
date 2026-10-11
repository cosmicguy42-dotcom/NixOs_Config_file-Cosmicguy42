import QtQuick
import Quickshell
import qs.services
import qs.components

// Big dot-matrix clock + month grid. Scroll to change month.
Column {
    id: root

    spacing: 18

    SystemClock {
        id: time
        precision: SystemClock.Seconds
    }

    property int monthOffset: 0
    readonly property date shown: new Date(time.date.getFullYear(), time.date.getMonth() + monthOffset, 1)

    Row {
        spacing: 22

        DotText {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(time.date, "hh:mm")
            dot: 4.6
            gap: 2
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Caption {
                text: Qt.formatDateTime(time.date, "dddd")
                color: Theme.accent
            }
            Heading {
                text: Qt.formatDateTime(time.date, "d MMMM")
                font.pixelSize: 30
            }
            Caption {
                text: Qt.formatDateTime(time.date, "yyyy") + "  ·  " + Qt.formatDateTime(time.date, "ss") + "s"
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.faint
    }

    Item {
        width: grid.width
        height: header.height + 10 + grid.height

        Row {
            id: header
            width: grid.width
            Heading {
                width: parent.width - 40
                text: Qt.formatDateTime(root.shown, "MMMM yyyy")
                font.pixelSize: 20
            }
            Caption {
                width: 40
                horizontalAlignment: Text.AlignRight
                text: root.monthOffset === 0 ? "" : "today"
                color: Theme.accent
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset = 0
                }
            }
        }

        Grid {
            id: grid
            anchors.top: header.bottom
            anchors.topMargin: 10
            columns: 7
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Caption {
                    required property string modelData
                    width: 36
                    height: 22
                    text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.faint
                }
            }

            Repeater {
                // Monday-first grid, 6 weeks.
                model: 42
                Item {
                    id: cell
                    required property int index
                    readonly property int lead: (root.shown.getDay() + 6) % 7
                    readonly property date day: new Date(root.shown.getFullYear(), root.shown.getMonth(), index - lead + 1)
                    readonly property bool inMonth: day.getMonth() === root.shown.getMonth()
                    readonly property bool today: day.toDateString() === time.date.toDateString()

                    width: 36
                    height: 28

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: Theme.r(13)
                        color: Theme.accent
                        visible: cell.today
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.day.getDate()
                        font.family: Theme.mono
                        font.pixelSize: 12
                        color: cell.today ? Theme.accentFg : (cell.day.getDay() === 0 || cell.day.getDay() === 6) ? Theme.accent : Theme.fg
                        opacity: cell.inMonth ? 1 : 0.22
                    }
                }
            }
        }

        WheelHandler {
            onWheel: e => root.monthOffset += e.angleDelta.y > 0 ? -1 : 1
        }
    }
}
