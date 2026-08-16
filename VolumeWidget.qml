import QtQuick

// Speaker with dynamic waves + percent.
// Left click opens the mixer panel, right click mutes, scroll changes volume.
Block {
    id: root
    readonly property string iconName: Audio.muted ? "volx"
        : Audio.volume > 0.5 ? "vol2"
        : Audio.volume > 0 ? "vol1" : "vol0"

    Grid {
        columns: 1

        Row {
            visible: !Theme.vertical
            spacing: 8
            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.iconName
                px: Theme.pxIcon; gap: 1
                color: Audio.muted ? Theme.red
                     : Popups.open === "volume" ? Theme.red : Theme.fg
            }
            DotText {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.percent + "%"
                px: Theme.pxMed; gap: 1
                color: Audio.muted ? Theme.dim : Theme.fg
            }
        }

        Column {
            visible: Theme.vertical
            spacing: 4
            DotIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: root.iconName
                px: 1.2; gap: 0.9
                color: Audio.muted ? Theme.red : Theme.fg
            }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String(Audio.percent)
                px: 1; gap: 0.9
                color: Audio.muted ? Theme.dim : Theme.fg
            }
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Audio.toggleMute();
            else Popups.toggle("volume");
        }
        onWheel: wheel => {
            const step = Settings.s.volumeStep / 100;
            Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0 ? step : -step));
        }
    }
}
