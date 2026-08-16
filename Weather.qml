pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Weather from wttr.in JSON (location + interval configurable in settings).
Singleton {
    id: root

    property string temp: ""
    property string condition: ""
    property string feels: ""
    property string humidity: ""
    property string wind: ""
    property string windDir: ""
    property string uv: ""
    property string pressure: ""
    property string area: ""
    property string country: ""
    property string sunrise: ""
    property string sunset: ""
    property var forecast: []   // [{name, max, min, icon}]
    readonly property bool ok: temp !== ""

    function iconFor(desc) {
        const c = desc.toLowerCase();
        if (c.includes("thunder")) return "storm";
        if (c.includes("snow") || c.includes("sleet") || c.includes("blizzard")) return "snow";
        if (c.includes("rain") || c.includes("drizzle") || c.includes("shower")) return "rain";
        if (c.includes("sun") || c.includes("clear")) return "sun";
        return "cloud";
    }
    readonly property string icon: iconFor(condition)

    Process {
        id: fetch
        command: ["curl", "-sm", "15",
            "wttr.in/" + encodeURIComponent(Settings.s.weatherLocation) + "?format=j1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current_condition[0];
                    root.temp = c.temp_C + "°C";
                    root.condition = c.weatherDesc[0].value;
                    root.feels = c.FeelsLikeC + "°C";
                    root.humidity = c.humidity + "%";
                    root.wind = c.windspeedKmph + " KM/H";
                    root.windDir = c.winddir16Point;
                    root.uv = c.uvIndex;
                    root.pressure = c.pressure + " HPA";
                    const a = d.nearest_area[0];
                    root.area = a.areaName[0].value;
                    root.country = a.country[0].value;
                    const astro = d.weather[0].astronomy[0];
                    root.sunrise = astro.sunrise;
                    root.sunset = astro.sunset;
                    const days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
                    root.forecast = d.weather.map((w, i) => ({
                        name: i === 0 ? "TODAY" : days[new Date(w.date + "T12:00:00").getDay()],
                        max: w.maxtempC + "°",
                        min: w.mintempC + "°",
                        icon: root.iconFor(w.hourly[4].weatherDesc[0].value)
                    }));
                } catch (e) {
                    retry.start();
                }
            }
        }
    }

    Connections {
        target: Settings.s
        function onWeatherLocationChanged() { fetch.running = true }
    }

    function refresh() { fetch.running = true }

    Timer {
        running: true; repeat: true
        interval: Math.max(5, Settings.s.weatherInterval) * 60 * 1000
        onTriggered: fetch.running = true
    }
    Timer {
        id: retry
        interval: 2 * 60 * 1000
        onTriggered: fetch.running = true
    }
}
