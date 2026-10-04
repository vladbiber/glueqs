import QtQuick

// WEATHER
Column {
    width: parent.width
    spacing: 0
    GwTitle { first: true; text: "SOURCE"; sub: "Current conditions from wttr.in through curl." }
    GwCard {
        SToggle { label: "Show weather"; skey: "showWeather" }
        GwRow { label: "Location"; hint: "A city name. Empty finds you by IP address."
            GwField {
                width: 200
                text: Settings.s.weatherLocation
                placeholder: "auto (IP)"
                onCommitted: v => Settings.s.weatherLocation = v.trim()
            }
        }
        GwRow { label: "Refresh"
            GwNumber { bound: true; value: Settings.s.weatherInterval; min: 5; max: 60; step: 5; unit: "min"; onChanged: v => Settings.s.weatherInterval = Math.round(v) }
        }
    }
}
