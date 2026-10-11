import QtQuick
import qs.services
import qs.components

// Two weather tiles like Nothing's widget: serif number + dot glyph.
Column {
    readonly property bool available: Forecast.ready
    spacing: 10

    Row {
        spacing: 10
        Glass {
            width: 180
            height: 180
            Heading {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -8
                text: Forecast.temp
                font.pixelSize: 120
            }
            Caption {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                text: "°" + Forecast.unit + " · " + (Forecast.days[0]?.max ?? "") + "/" + (Forecast.days[0]?.min ?? "")
            }
        }
        Glass {
            width: 180
            height: 180
            DotIcon {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -8
                kind: Forecast.kind
                dot: 9
                gap: 3.6
                offOpacity: 0.05
            }
            Caption {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                text: Forecast.desc
            }
        }
    }
    Glass {
        width: 370
        height: 50
        Row {
            anchors.centerIn: parent
            spacing: 26
            Repeater {
                model: Forecast.hours.filter((h, i) => i > 0 && i % 3 === 0).slice(0, 5)
                Row {
                    required property var modelData
                    spacing: 6
                    DotIcon { anchors.verticalCenter: parent.verticalCenter; kind: parent.modelData.kind; dot: 1.3; gap: 0.6; offOpacity: 0 }
                    Caption { anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.temp + "°"; color: Theme.fg }
                }
            }
        }
    }
}
