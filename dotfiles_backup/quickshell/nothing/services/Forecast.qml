pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Weather: Open-Meteo forecast (no key). Location comes from config
// (Open-Meteo geocoding) or, when empty, wttr.in's IP lookup.
// Refreshes every 20 minutes.
Singleton {
    id: root

    property bool ready: false
    property string location: ""
    property real lat: NaN
    property real lon: NaN

    property int temp: 0
    property int feels: 0
    property int humidity: 0
    property int wind: 0
    property int code: 3
    property bool isDay: true
    readonly property string kind: kindFor(code, !isDay)
    readonly property string desc: describe(code)

    property var hours: [] // next 24h: { label, temp, kind, rain }
    property var days: []  // 10 days: { label, weekend, max, min, kind, rain }
    property string sunrise: ""
    property string sunset: ""
    property real uv: 0
    property int rainToday: 0

    readonly property string unit: Config.imperial ? "F" : "C"

    function refresh() {
        if (isNaN(lat))
            locate();
        else
            fetch.running = true;
    }
    function locate() {
        lat = NaN;
        const q = Config.weatherLocation;
        geo.command = q
            ? ["curl", "-sf", "--max-time", "15", "https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(q)]
            : ["curl", "-sf", "--max-time", "15", "https://wttr.in/?format=j2"];
        geo.running = true;
    }

    // WMO weather interpretation codes
    function kindFor(c, night) {
        if (c === 0) return night ? "night" : "clear";
        if (c <= 2) return night ? "night" : "partly";
        if (c === 3) return "cloudy";
        if (c === 45 || c === 48) return "fog";
        if (c >= 95) return "storm";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow";
        return "rain";
    }
    function describe(c) {
        const m = { 0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Rime fog",
            51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
            61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
            71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains", 80: "Showers", 81: "Showers",
            82: "Violent showers", 85: "Snow showers", 86: "Snow showers", 95: "Thunderstorm", 96: "Thunderstorm", 99: "Thunderstorm" };
        return m[c] ?? "—";
    }
    function ordinal(n) {
        const s = ["th", "st", "nd", "rd"], v = n % 100;
        return n + (s[(v - 20) % 10] || s[v] || s[0]);
    }
    function hhmm(iso) { return (iso ?? "").slice(11, 16); }

    function parseGeo(text) {
        try {
            const j = JSON.parse(text);
            if (j.results) {
                const r = j.results[0];
                location = r.name;
                lat = r.latitude;
                lon = r.longitude;
            } else {
                const a = j.nearest_area[0];
                location = a.areaName[0].value;
                lat = parseFloat(a.latitude);
                lon = parseFloat(a.longitude);
            }
            fetch.running = true;
        } catch (e) {
            console.warn("nothing: weather location lookup failed, retrying");
            retry.restart();
        }
    }

    function parse(text) {
        try {
            apply(JSON.parse(text));
        } catch (e) {
            console.warn("nothing: forecast failed, retrying", e);
            retry.restart();
        }
    }
    function apply(j) {
        const c = j.current;
        temp = Math.round(c.temperature_2m);
        feels = Math.round(c.apparent_temperature);
        humidity = c.relative_humidity_2m;
        wind = Math.round(c.wind_speed_10m);
        code = c.weather_code;
        isDay = c.is_day === 1;

        const H = j.hourly;
        const nowIdx = Math.max(0, H.time.findIndex(t => t.slice(0, 13) === c.time.slice(0, 13)));
        const h = [];
        for (let i = nowIdx; i < Math.min(H.time.length, nowIdx + 24); i++) {
            h.push({
                label: i === nowIdx ? "Now" : hhmm(H.time[i]),
                temp: Math.round(H.temperature_2m[i]),
                kind: kindFor(H.weather_code[i], H.is_day[i] === 0),
                rain: H.precipitation_probability[i] ?? 0
            });
        }
        hours = h;

        const D = j.daily;
        days = D.time.map((t, i) => {
            const d = new Date(t + "T12:00:00");
            return {
                label: i === 0 ? "Today" : Qt.formatDate(d, "ddd") + ", " + ordinal(d.getDate()),
                weekend: d.getDay() === 0 || d.getDay() === 6,
                max: Math.round(D.temperature_2m_max[i]),
                min: Math.round(D.temperature_2m_min[i]),
                kind: kindFor(D.weather_code[i], false),
                rain: D.precipitation_probability_max[i] ?? 0
            };
        });
        sunrise = hhmm(D.sunrise[0]);
        sunset = hhmm(D.sunset[0]);
        uv = D.uv_index_max[0] ?? 0;
        rainToday = D.precipitation_probability_max[0] ?? 0;
        ready = true;
    }

    Process {
        id: geo
        stdout: StdioCollector {
            onStreamFinished: root.parseGeo(text)
        }
    }
    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "20",
            "https://api.open-meteo.com/v1/forecast?latitude=" + root.lat + "&longitude=" + root.lon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max,uv_index_max"
            + "&timezone=auto&forecast_days=10"
            + (Config.imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "")]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
    // Network hiccups (e.g. right after resume) shouldn't blank the weather for 20 min.
    Timer {
        id: retry
        interval: 30 * 1000
        onTriggered: root.refresh()
    }
    Timer {
        interval: 20 * 60 * 1000
        running: Config.loaded
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Connections {
        target: Config
        function onWeatherLocationChanged() { root.locate(); }
        function onImperialChanged() { if (!isNaN(root.lat)) fetch.running = true; }
    }
}
