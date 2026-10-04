import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import QtQuick

// The bar. Sits on any screen edge; widgets are placed by the ordered
// zone lists in settings (barLeft / barCenter / barRight).
// If "clock" is in the center zone it is pinned to the exact screen center
// and its center-zone neighbours flank it.
PanelWindow {
    id: root
    readonly property string pos: Settings.s.barPosition
    readonly property bool vertical: Theme.vertical

    anchors {
        top: pos !== "bottom"
        bottom: pos !== "top"
        left: pos !== "right"
        right: pos !== "left"
    }
    implicitWidth: Theme.barHeight
    implicitHeight: Theme.barHeight
    color: "transparent"


    readonly property var leftModel: Settings.s.barLeft.split(",").filter(x => x !== "")
    readonly property var centerModel: Settings.s.barCenter.split(",").filter(x => x !== "")
    readonly property var rightModel: Settings.s.barRight.split(",").filter(x => x !== "")

    readonly property int clockIdx: centerModel.indexOf("clock")
    readonly property var centerPre: clockIdx >= 0 ? centerModel.slice(0, clockIdx) : []
    readonly property var centerPost: clockIdx >= 0 ? centerModel.slice(clockIdx + 1) : []
    readonly property bool pivot: clockIdx >= 0

    Component { id: cSettings;   SettingsWidget {} }
    Component { id: cLauncher;   LauncherWidget {} }
    Component { id: cWorkspaces; Workspaces { outputName: root.screen?.name ?? "" } }
    Component { id: cWeather;    WeatherWidget {} }
    Component { id: cClock;      ClockWidget {} }
    Component { id: cMedia;      MediaWidget {} }
    Component { id: cNetSpeed;   NetSpeedWidget {} }
    Component { id: cNetwork;    NetWidget {} }
    Component { id: cVolume;     VolumeWidget {} }
    Component { id: cBattery;    BatteryWidget {} }
    Component { id: cBrightness; BrightnessWidget {} }
    Component { id: cLevels;     LevelsWidget {} }
    Component { id: cPower;      PowerWidget {} }
    Component { id: cTray;       TrayWidget {} }
    Component { id: cNotifs;     NotifWidget {} }
    Component { id: cStat;       StatWidget {} }
    Component { id: cButton;     ButtonWidget {} }
    Component { id: cViz;        VizWidget {} }

    // single source of truth for widget visibility (loaders collapse in the layout)
    readonly property var visMap: ({
        settings: true,
        launcher: Settings.s.showLauncher,
        workspaces: Settings.s.showWorkspaces && WsState.available,
        weather: Weather.ok && Settings.s.showWeather,
        clock: Settings.s.showClock,
        media: Settings.s.showMedia && MediaService.active !== null,
        netspeed: Settings.s.showNetSpeed,
        network: Settings.s.showNetwork,
        volume: Settings.s.showVolume,
        battery: Settings.s.showBattery && (UPower.displayDevice?.isLaptopBattery ?? false),
        brightness: Settings.s.showBrightness && Brightness.available,
        levels: Settings.s.showLevels,
        power: Settings.s.showPower,
        tray: Settings.s.showTray && SystemTray.items.values.length > 0,
        notifs: Settings.s.showNotifs
    })

    // ids that take a parameter: cpu/ram/temp/disk are StatWidget kinds,
    // the one-icon tiles are ButtonWidget kinds, viz:STYLE is a visualiser
    readonly property var statKinds: ["cpu", "ram", "temp", "disk"]
    readonly property var buttonKinds: ["keepawake", "wallpaper", "mic", "window", "caps", "spacer"]
    function compFor(id) {
        if (id.startsWith("viz:")) return cViz;
        if (statKinds.includes(id)) return cStat;
        if (buttonKinds.includes(id)) return cButton;
        return comps[id] ?? null;
    }
    readonly property var comps: ({
        settings: cSettings, launcher: cLauncher, workspaces: cWorkspaces,
        weather: cWeather, clock: cClock, media: cMedia, netspeed: cNetSpeed,
        network: cNetwork, volume: cVolume, battery: cBattery, power: cPower,
        tray: cTray, notifs: cNotifs, brightness: cBrightness, levels: cLevels
    })

    component ZoneLoader: Loader {
        required property var modelData
        sourceComponent: root.compFor(modelData)
        visible: root.visMap[modelData] ?? true
        onLoaded: {
            if (modelData.startsWith("viz:")) item.style = modelData.slice(4);
            else if (item.kind !== undefined) item.kind = modelData;
        }
    }

    Rectangle {
        id: content
        anchors { fill: parent; margins: Theme.barMargin }
        radius: Theme.floating ? Theme.panelRadius : 0
        color: Settings.s.barSolid ? Qt.alpha(Theme.bg, Settings.s.panelOpacity) : "transparent"
        border.color: Settings.s.barSolid && Theme.floating ? Theme.blockBorder : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.ms(250) } }

        // ---- horizontal layout ----
        Row {
            visible: !root.vertical
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: Theme.spacing
            Repeater { model: root.vertical ? [] : root.leftModel; delegate: ZoneLoader {} }
        }

        Loader {
            id: hClock
            active: !root.vertical && root.pivot
            visible: active && (root.visMap.clock ?? true)
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: item?.centerShift ?? 0
            sourceComponent: cClock
        }
        Row {
            visible: !root.vertical && root.pivot
            anchors { right: hClock.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: Theme.spacing
            Repeater { model: (!root.vertical && root.pivot) ? root.centerPre : []; delegate: ZoneLoader {} }
        }
        Row {
            visible: !root.vertical && root.pivot
            anchors { left: hClock.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: Theme.spacing
            Repeater { model: (!root.vertical && root.pivot) ? root.centerPost : []; delegate: ZoneLoader {} }
        }
        Row {
            visible: !root.vertical && !root.pivot
            anchors.centerIn: parent
            spacing: Theme.spacing
            Repeater { model: (!root.vertical && !root.pivot) ? root.centerModel : []; delegate: ZoneLoader {} }
        }

        Row {
            visible: !root.vertical
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: Theme.spacing
            Repeater { model: root.vertical ? [] : root.rightModel; delegate: ZoneLoader {} }
        }

        // ---- vertical layout ----
        Column {
            visible: root.vertical
            anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
            spacing: Theme.spacing
            Repeater { model: root.vertical ? root.leftModel : []; delegate: ZoneLoader {} }
        }

        Loader {
            id: vClock
            active: root.vertical && root.pivot
            visible: active && (root.visMap.clock ?? true)
            anchors.centerIn: parent
            sourceComponent: cClock
        }
        Column {
            visible: root.vertical && root.pivot
            anchors { bottom: vClock.top; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
            spacing: Theme.spacing
            Repeater { model: (root.vertical && root.pivot) ? root.centerPre : []; delegate: ZoneLoader {} }
        }
        Column {
            visible: root.vertical && root.pivot
            anchors { top: vClock.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
            spacing: Theme.spacing
            Repeater { model: (root.vertical && root.pivot) ? root.centerPost : []; delegate: ZoneLoader {} }
        }
        Column {
            visible: root.vertical && !root.pivot
            anchors.centerIn: parent
            spacing: Theme.spacing
            Repeater { model: (root.vertical && !root.pivot) ? root.centerModel : []; delegate: ZoneLoader {} }
        }

        Column {
            visible: root.vertical
            anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
            spacing: Theme.spacing
            Repeater { model: root.vertical ? root.rightModel : []; delegate: ZoneLoader {} }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 2500
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/bar-" + root.screen.name + ".png"))
    }
}
