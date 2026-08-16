import Quickshell
import Quickshell.Wayland
import QtQuick

// Month calendar in dot-matrix; today boxed in red. Opens from the clock.
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 280
    implicitHeight: 264
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Popups.open === "calendar"

    property int year: 2026
    property int month: 0   // 0-based
    onVisibleChanged: if (visible) reset()
    Component.onCompleted: reset()

    function reset() {
        const now = new Date();
        year = now.getFullYear();
        month = now.getMonth();
    }
    function shift(d) {
        let m = month + d;
        if (m < 0) { m = 11; year--; }
        if (m > 11) { m = 0; year++; }
        month = m;
    }
    // 42 cells, Monday-first; 0 = blank
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const off = (first.getDay() + 6) % 7;
        const days = new Date(year, month + 1, 0).getDate();
        const a = [];
        for (let i = 0; i < 42; i++) {
            const d = i - off + 1;
            a.push(d >= 1 && d <= days ? d : 0);
        }
        return a;
    }
    readonly property var today: new Date()
    readonly property var monthNames:
        ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        Column {
            anchors { top: parent.top; topMargin: 16; horizontalCenter: parent.horizontalCenter }
            spacing: 12

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "prev"; px: 1.4; gap: 1
                    color: pa.containsMouse ? Theme.red : Theme.mid
                    MouseArea { id: pa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: root.shift(-1) }
                }
                DotText {
                    text: root.monthNames[root.month] + " " + root.year
                    px: 1.6; gap: 1
                }
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "next"; px: 1.4; gap: 1
                    color: na.containsMouse ? Theme.red : Theme.mid
                    MouseArea { id: na; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: root.shift(1) }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: ["M","T","W","T","F","S","S"]
                    delegate: Item {
                        required property string modelData
                        width: 34; height: 12
                        DotText {
                            anchors.centerIn: parent
                            text: parent.modelData
                            px: 1; gap: 1; color: Theme.dim
                        }
                    }
                }
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 7
                Repeater {
                    model: root.cells
                    delegate: Rectangle {
                        required property int modelData
                        readonly property bool isToday:
                            modelData === root.today.getDate()
                            && root.month === root.today.getMonth()
                            && root.year === root.today.getFullYear()
                        width: 34; height: 26
                        radius: 5
                        color: isToday ? "#26090b" : "transparent"
                        border.color: isToday ? Theme.red : "transparent"
                        border.width: 1
                        DotText {
                            anchors.centerIn: parent
                            visible: parent.modelData > 0
                            text: String(parent.modelData)
                            px: 1.2; gap: 1
                            color: parent.isToday ? Theme.fg : Theme.mid
                        }
                    }
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 1000
        onTriggered: { Popups.open = "calendar"; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1200
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/calendar-" + root.screen.name + ".png"))
    }
}
