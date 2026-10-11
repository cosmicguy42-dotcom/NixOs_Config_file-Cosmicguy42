import QtQuick
import qs.services
import qs.components

Page {
    title: "Weather"
    subtitle: "Forecast by Open-Meteo. Auto location uses wttr.in's IP lookup."

    Section {
        title: "Location"
        CText { label: "City"; sub: "Leave empty to locate automatically"; path: "weather.location"; placeholder: "Auto (by IP)" }
        OptRow {
            label: Forecast.location || "Locating…"
            sub: Forecast.ready ? Forecast.temp + "°" + Forecast.unit + " · " + Forecast.desc : ""
            OptButton { text: "Refresh"; icon: "refresh"; onClicked: Forecast.locate() }
        }
    }
    Section {
        title: "Units"
        CChoice {
            label: "Temperature"
            path: "weather.units"
            options: [{ label: "°C · km/h", value: "metric" }, { label: "°F · mph", value: "imperial" }]
        }
    }
    Section {
        title: "Show weather in"
        CSwitch { label: "Pill"; path: "pill.weather" }
        CSwitch { label: "Lock screen"; path: "lock.weather" }
    }
}
