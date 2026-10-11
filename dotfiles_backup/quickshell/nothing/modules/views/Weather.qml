import QtQuick
import qs.services
import qs.components

// Weather, laid out like Nothing's weather app: city, serif hero number,
// dot-matrix glyph, hourly strip, 7-day list (weekends in accent) and details.
Column {
    id: root

    width: 400
    spacing: 8

    property bool details: false

    Card {
        width: parent.width
        height: 52
        Label {
            anchors.verticalCenter: parent.verticalCenter
            x: 20
            width: parent.width - 80
            text: Forecast.location || "Locating…"
            font.pixelSize: 15
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 18
            text: "near_me"
            size: 18
            color: Theme.dim
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: Forecast.locate()
            }
        }
    }

    Row {
        spacing: 8
        Card {
            width: (root.width - 8) / 2
            height: 160
            Heading {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -10
                text: Forecast.ready ? Forecast.temp : "--"
                font.pixelSize: 118
            }
            Caption {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                text: "°" + Forecast.unit + " · feels " + Forecast.feels + "°"
            }
        }
        Card {
            width: (root.width - 8) / 2
            height: 160
            DotIcon {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -10
                kind: Forecast.kind
                dot: 8
                gap: 3
                offOpacity: 0.05
            }
            Caption {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 24
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: Forecast.desc
            }
        }
    }

    // Next 24 hours
    Card {
        width: parent.width
        height: 88
        clip: true
        ListView {
            id: hours
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            orientation: ListView.Horizontal
            boundsBehavior: Flickable.StopAtBounds
            model: Forecast.hours
            delegate: Item {
                required property var modelData
                width: 64
                height: hours.height
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    DotIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        kind: parent.parent.modelData.kind
                        dot: 1.8
                        gap: 0.8
                        offOpacity: 0
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.parent.modelData.temp + "°"
                        font.pixelSize: 14
                    }
                    Caption {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.parent.modelData.label
                    }
                }
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse
                onWheel: e => hours.flick(e.angleDelta.y * 10, 0)
            }
        }
    }

    // 7-day list  /  details grid
    Card {
        width: parent.width
        height: (root.details ? grid.height : days.height) + 20
        Behavior on height { NumberAnimation { duration: Theme.dur; easing.type: Theme.easing } }
        clip: true

        Column {
            id: days
            y: 10
            width: parent.width
            opacity: root.details ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Repeater {
                model: Forecast.days.slice(0, 7)
                Item {
                    id: day
                    required property var modelData
                    width: days.width
                    height: 40
                    Label {
                        x: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: day.modelData.label
                        font.pixelSize: 14
                        color: day.modelData.weekend ? Theme.accent : Theme.fg
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        Caption {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            horizontalAlignment: Text.AlignRight
                            text: day.modelData.rain >= 30 ? day.modelData.rain + "%" : ""
                            color: Theme.accent
                        }
                        DotIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            kind: day.modelData.kind
                            dot: 1.8
                            gap: 0.8
                            offOpacity: 0
                        }
                        Label {
                            width: 28
                            horizontalAlignment: Text.AlignRight
                            text: day.modelData.max
                            font.pixelSize: 14
                        }
                        Label {
                            width: 28
                            horizontalAlignment: Text.AlignRight
                            text: day.modelData.min
                            font.pixelSize: 14
                            color: Theme.dim
                        }
                    }
                }
            }
        }

        Grid {
            id: grid
            y: 10
            x: 10
            columns: 3
            spacing: 8
            opacity: root.details ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Repeater {
                model: [
                    { k: "Sunrise", v: Forecast.sunrise },
                    { k: "Sunset", v: Forecast.sunset },
                    { k: "UV index", v: Math.round(Forecast.uv) },
                    { k: "Humidity", v: Forecast.humidity + "%" },
                    { k: "Wind", v: Forecast.wind + (Config.imperial ? " mph" : " km/h") },
                    { k: "Rain today", v: Forecast.rainToday + "%" }
                ]
                Rectangle {
                    required property var modelData
                    width: (root.width - 20 - 16) / 3
                    height: 84
                    radius: Theme.radius
                    color: Theme.raised
                    Caption {
                        x: 14
                        y: 12
                        text: parent.modelData.k
                    }
                    Heading {
                        x: 14
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        width: parent.width - 20
                        text: parent.modelData.v
                        font.pixelSize: 30
                    }
                }
            }
        }
    }

    Card {
        width: parent.width
        height: 48
        color: more.containsMouse ? Theme.raised : Theme.card
        Label {
            anchors.centerIn: parent
            text: root.details ? "View the 7-day forecast" : "View the details"
            font.pixelSize: 13
        }
        MouseArea {
            id: more
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.details = !root.details
        }
    }
}
