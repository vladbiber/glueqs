import Quickshell
import QtQuick

ShellRoot {
    // a screen that mirrors another, or is switched off, gets no windows of
    // its own: the compositor shows a mirror the source, bar and all. A
    // screen listed twice (seen on upstream Quickshell after an output
    // re-announces itself) gets one set of windows, not two bars.
    readonly property var liveScreens: {
        const seen = ({});
        return Quickshell.screens.filter(s => {
            if (s.name === "" || seen[s.name] || Gluewc.isPassive(s.name)) return false;
            seen[s.name] = true;
            return true;
        });
    }
    Variants {
        model: liveScreens

        Scope {
            required property var modelData
            Wallpaper { screen: modelData }
            Bar { screen: modelData }
            WallpaperPanel { screen: modelData }
            VolumeOsd { screen: modelData }
            BrightnessOsd { screen: modelData }
            MediaPanel { screen: modelData }
            SessionPanel { screen: modelData }
            CalendarPopup { screen: modelData }
            NetworkPanel { screen: modelData }
            LauncherPanel { screen: modelData }
            VolumePanel { screen: modelData }
            SettingsPanel { screen: modelData }
            GluewcPanel { screen: modelData }
            GwIdentify { screen: modelData }
            WeatherPanel { screen: modelData }
            BatteryPanel { screen: modelData }
            BrightnessPanel { screen: modelData }
            NotifPanel { screen: modelData }
            NotifToast { screen: modelData }
            OverviewDock { screen: modelData }
            TrayMenu { screen: modelData }
        }
    }
}
