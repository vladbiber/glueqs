import QtQuick
import Quickshell.Services.UPower

// Vertical pill with red charge fill + big percent, like the Nothing battery widget.
// Second line shows time remaining; click opens the battery panel.
Block {
    id: root
    border.color: Popups.open === "battery" ? Theme.red : Theme.blockBorder
    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev?.percentage ?? 0
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
                                  || dev?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged

    readonly property string eta: {
        const s = charging ? (dev?.timeToFull ?? 0) : (dev?.timeToEmpty ?? 0);
        if (!s || s <= 0) return "";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return (h > 0 ? h + "H " : "") + m + "M";
    }

    component Pill: Item {
        width: 10; height: 21
        Rectangle { // nub
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0; width: 5; height: 2; radius: 1
            color: Theme.blockBorder
        }
        Rectangle { // body
            y: 3; width: 10; height: 18
            radius: 3
            color: "#0a0a0a"
            border.color: Theme.blockBorder
            border.width: 1
            Rectangle { // charge fill
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 2 }
                height: Math.max(2, (parent.height - 4) * root.pct)
                radius: 2
                color: root.charging || root.full ? Theme.fg : Theme.red
            }
        }
    }

    Grid {
        columns: 1

        Row {
            visible: !Theme.vertical
            spacing: 10

            Pill { anchors.verticalCenter: parent.verticalCenter }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                DotText {
                    text: Math.round(root.pct * 100) + "%"
                    px: Theme.pxMed; gap: 1
                }
                DotText {
                    text: root.full ? "FULL"
                        : root.eta !== "" ? root.eta + (root.charging ? " CHG" : " LEFT")
                        : root.charging ? "CHARGING" : "ON BATTERY"
                    px: 0.8; gap: 0.8
                    color: Theme.fg
                }
            }
        }

        Column {
            visible: Theme.vertical
            spacing: 4
            Pill { anchors.horizontalCenter: parent.horizontalCenter }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String(Math.round(root.pct * 100))
                px: 1; gap: 0.9
            }
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: Popups.toggle("battery")
    }
}
