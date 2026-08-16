import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData
            Bar { screen: modelData }
            VolumeOsd { screen: modelData }
            BrightnessOsd { screen: modelData }
            MediaPanel { screen: modelData }
            SessionPanel { screen: modelData }
            CalendarPopup { screen: modelData }
            NetworkPanel { screen: modelData }
            LauncherPanel { screen: modelData }
            VolumePanel { screen: modelData }
            SettingsPanel { screen: modelData }
            WeatherPanel { screen: modelData }
            BatteryPanel { screen: modelData }
            NotifPanel { screen: modelData }
            NotifToast { screen: modelData }
            OverviewDock { screen: modelData }
            TrayMenu { screen: modelData }
        }
    }
}
