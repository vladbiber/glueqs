import QtQuick

// One system number in a tile: cpu, ram, temp or disk. Lights up in the
// accent past `hot`.
Block {
    id: root
    property string kind: "cpu"

    Component.onCompleted: SysMon.acquire()
    Component.onDestruction: SysMon.release()

    readonly property real frac: kind === "cpu" ? SysMon.cpu : kind === "ram" ? SysMon.ram
                               : kind === "disk" ? SysMon.disk : Math.max(0, SysMon.temp) / 100
    readonly property bool hot: kind === "temp" ? SysMon.temp >= 80 : frac >= 0.85
    readonly property string value: kind === "temp" ? (SysMon.temp < 0 ? "--" : SysMon.temp + "°")
                                  : Math.round(frac * 100) + "%"

    Grid {
        columns: Theme.vertical ? 1 : 3
        spacing: Theme.vertical ? 4 : 6
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        DotIcon {
            name: root.kind
            px: Theme.vertical ? 1.2 : Theme.pxIcon * 0.8; gap: 0.8
            color: root.hot ? Theme.red : Theme.fg
        }
        DotText {
            text: root.value
            px: Theme.vertical ? 0.8 : Theme.pxSmall * 1.1; gap: 0.8
            color: root.hot ? Theme.red : Theme.fg
        }
        // a thin usage meter under the number, horizontal bar only
        Rectangle {
            visible: !Theme.vertical && root.kind !== "temp"
            width: 4; height: Theme.blockHeight - 18; radius: 2
            color: Theme.faint
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; radius: 2
                height: parent.height * root.frac
                color: root.hot ? Theme.red : Theme.fg
                Behavior on height { NumberAnimation { duration: Theme.ms(400); easing.type: Easing.OutCubic } }
            }
        }
    }
}
