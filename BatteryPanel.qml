import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import "DotFont.js" as DotFont

// Rich battery view: dot-matrix battery gauge, big percent, details grid and
// power profile selector (needs power-profiles-daemon for the modes to apply).
PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: Theme.popupTop; right: Theme.popupRight }
    implicitWidth: 340
    implicitHeight: 356
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Popups.open === "battery"

    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev?.percentage ?? 0
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
                                  || dev?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged

    function fmtTime(s) {
        if (!s || s <= 0) return "--";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return (h > 0 ? h + "H " : "") + m + "M";
    }

    property real intro: 0
    onVisibleChanged: if (visible) { intro = 0; introAnim.restart(); }
    NumberAnimation {
        id: introAnim
        target: root; property: "intro"
        from: 0; to: 1; duration: 700
        easing.type: Easing.OutCubic
    }
    function stage(a, b) { return Math.max(0, Math.min(1, (intro - a) / (b - a))) }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1

        DotIcon {
            anchors { top: parent.top; right: parent.right; margins: 14 }
            name: "x"
            px: 1.6; gap: 1
            color: bxArea.containsMouse ? Theme.red : Theme.dim
            MouseArea {
                id: bxArea
                anchors.fill: parent; anchors.margins: -6
                hoverEnabled: true
                onClicked: Popups.open = ""
            }
        }

        Column {
            anchors { fill: parent; margins: 18 }
            spacing: 12

            Row {
                spacing: 16
                opacity: root.stage(0, 0.4)

                // dot-matrix battery gauge, fill sweeps in with the intro
                Canvas {
                    id: gauge
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property int cols: 15
                    readonly property int rows: 7
                    readonly property real cell: 8
                    width: (cols + 1) * cell - 3
                    height: rows * cell - 3
                    property real sweep: root.stage(0.05, 0.8)
                    property real lvl: root.pct
                    onSweepChanged: requestPaint()
                    onLvlChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const r = 2.5;
                        const dot = (c, row, col) => {
                            ctx.fillStyle = c;
                            DotFont.dot(ctx, col * cell, row * cell, r * 2, Theme.dotShape);
                        };
                        const litCols = Math.round(lvl * (cols - 2) * sweep);
                        const fillCol = root.charging || root.full
                                      ? String(Theme.fg) : String(Theme.red);
                        for (let row = 0; row < rows; row++)
                            for (let col = 0; col < cols; col++) {
                                const edge = row === 0 || row === rows - 1
                                          || col === 0 || col === cols - 1;
                                if (edge) { dot(String(Theme.mid), row, col); continue; }
                                dot(col - 1 < litCols ? fillCol : String(Theme.faint), row, col);
                            }
                        for (let row = 2; row < rows - 2; row++)  // nub
                            dot(String(Theme.mid), row, cols);
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    DotText { text: Math.round(root.pct * 100) + "%"; px: 3; gap: 1.4 }
                    DotText {
                        text: root.full ? "FULLY CHARGED"
                            : root.charging ? "CHARGING" : "ON BATTERY"
                        px: 1; gap: 1
                        color: root.charging || root.full ? Theme.fg : Theme.red
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.blockBorder }

            Grid {
                columns: 2
                columnSpacing: 24
                rowSpacing: 8
                opacity: root.stage(0.2, 0.7)

                component Detail: Item {
                    property string label: ""
                    property string value: ""
                    width: 140; height: 24
                    DotText {
                        anchors { left: parent.left; top: parent.top }
                        text: parent.label
                        px: 0.8; gap: 0.8; color: Theme.dim
                    }
                    DotText {
                        anchors { left: parent.left; bottom: parent.bottom }
                        text: parent.value
                        px: 1.1; gap: 1
                    }
                }

                Detail {
                    label: root.charging ? "TIME TO FULL" : "TIME LEFT"
                    value: root.full ? "--"
                        : root.fmtTime(root.charging ? root.dev?.timeToFull : root.dev?.timeToEmpty)
                }
                Detail {
                    label: "POWER DRAW"
                    value: (root.dev?.changeRate ?? 0).toFixed(1) + " W"
                }
                Detail {
                    label: "HEALTH"
                    value: (root.dev?.healthSupported ?? false)
                         ? Math.round(root.dev.healthPercentage) + "%" : "--"
                }
                Detail {
                    label: "CAPACITY"
                    value: (root.dev?.energyCapacity ?? 0).toFixed(1) + " WH"
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.blockBorder }

            DotText {
                text: "POWER MODE"
                px: 1; gap: 1; color: Theme.dim
                opacity: root.stage(0.4, 0.9)
            }

            Row {
                spacing: 6
                opacity: root.stage(0.5, 1)

                component ModeChip: Rectangle {
                    id: chip
                    property string label: ""
                    property int mode: PowerProfile.Balanced
                    readonly property bool active: PowerProfiles.profile === mode
                    width: 97; height: 30
                    radius: 8
                    color: mArea.containsMouse ? Theme.hover : "transparent"
                    border.color: active ? Theme.red : Theme.blockBorder
                    border.width: 1
                    DotText {
                        anchors.centerIn: parent
                        text: chip.label
                        px: 0.9; gap: 0.9
                        color: chip.active ? Theme.fg : Theme.mid
                    }
                    MouseArea {
                        id: mArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: PowerProfiles.profile = chip.mode
                    }
                }

                ModeChip { label: "SAVER";       mode: PowerProfile.PowerSaver }
                ModeChip { label: "BALANCED";    mode: PowerProfile.Balanced }
                ModeChip { label: "PERFORMANCE"; mode: PowerProfile.Performance }
            }

            DotText {
                visible: !PowerProfiles.hasPerformanceProfile
                text: "NEEDS POWER-PROFILES-DAEMON"
                px: 0.8; gap: 0.8; color: Theme.hint
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 14600
        onTriggered: { Popups.open = "battery"; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1400
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/battery-" + root.screen.name + ".png"))
    }
}
