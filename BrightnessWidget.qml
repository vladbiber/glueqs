import QtQuick

// Backlight tile: sun icon and the percent. Stays put at 0% so the way back
// is one click away. Click opens the brightness panel.
Block {
    id: root
    border.color: Popups.open === "brightness" ? Theme.red : Theme.blockBorder
    readonly property int pct: Brightness.percent

    Grid {
        columns: 1
        Row {
            visible: !Theme.vertical
            spacing: 8
            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "sun"; px: Theme.pxIcon * 0.7; gap: 1
                color: root.pct === 0 ? Theme.offDot : Theme.fg
            }
            DotText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.pct + "%"
                px: Theme.pxMed; gap: 1
                color: root.pct === 0 ? Theme.red : Theme.fg
            }
        }
        Column {
            visible: Theme.vertical
            spacing: 4
            DotIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "sun"; px: Theme.pxIcon * 0.7; gap: 1
                color: root.pct === 0 ? Theme.offDot : Theme.fg
            }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String(root.pct)
                px: 1; gap: 0.9
                color: root.pct === 0 ? Theme.red : Theme.fg
            }
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) Brightness.set(root.pct === 0 ? 50 : 0);
            else Popups.toggle("brightness");
        }
        onWheel: wheel => Brightness.set(root.pct + (wheel.angleDelta.y > 0 ? 5 : -5))
    }
}
