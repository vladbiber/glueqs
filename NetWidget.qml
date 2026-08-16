import QtQuick

// Wifi + bluetooth dot icons; click opens the network panel.
// white = connected/active, light gray = enabled, dark gray = off.
Block {
    id: root

    Grid {
        columns: Theme.vertical ? 1 : 2
        spacing: 14
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        DotIcon {
            name: !NetStatus.wifiConnected ? "wifi3"
                : NetStatus.wifiSignal > 66 ? "wifi3"
                : NetStatus.wifiSignal > 33 ? "wifi2" : "wifi1"
            px: Theme.pxIcon; gap: 1
            color: NetStatus.wifiEnabled ? Theme.fg : Theme.mid
        }

        DotIcon {
            name: "bt"
            px: Theme.pxIcon; gap: 1
            color: NetStatus.btPowered || NetStatus.btConnected > 0 ? Theme.fg : Theme.mid
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: Popups.toggle("net")
    }
}
