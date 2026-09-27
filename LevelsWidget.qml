import QtQuick

// Volume and brightness in one tile. Click opens the levels panel, the wheel
// changes whichever half is under the pointer (shift+wheel is always the
// backlight), right click mutes, middle click toggles the screen off.
Block {
    id: root
    border.color: Popups.open === "levels" ? Theme.red : Theme.blockBorder
    readonly property bool hasLight: Brightness.available
    readonly property string volIcon: Audio.muted ? "volx"
        : Audio.volume > 0.5 ? "vol2"
        : Audio.volume > 0 ? "vol1" : "vol0"

    Grid {
        columns: 1
        Row {
            id: hrow
            visible: !Theme.vertical
            spacing: 8
            DotIcon { anchors.verticalCenter: parent.verticalCenter; name: root.volIcon; px: Theme.pxIcon * 0.8; gap: 1; color: Audio.muted ? Theme.red : Theme.fg }
            DotText { anchors.verticalCenter: parent.verticalCenter; text: Audio.percent + "%"; px: Theme.pxMed; gap: 1; color: Audio.muted ? Theme.dim : Theme.fg }
            Rectangle { visible: root.hasLight; anchors.verticalCenter: parent.verticalCenter; width: 1; height: 16; color: Theme.blockBorder }
            DotIcon { visible: root.hasLight; anchors.verticalCenter: parent.verticalCenter; name: "sun"; px: Theme.pxIcon * 0.7; gap: 1; color: Brightness.percent === 0 ? Theme.offDot : Theme.fg }
            DotText { visible: root.hasLight; anchors.verticalCenter: parent.verticalCenter; text: Brightness.percent + "%"; px: Theme.pxMed; gap: 1; color: Brightness.percent === 0 ? Theme.red : Theme.fg }
        }
        Column {
            id: vcol
            visible: Theme.vertical
            spacing: 3
            DotIcon { anchors.horizontalCenter: parent.horizontalCenter; name: root.volIcon; px: 1.2; gap: 0.9; color: Audio.muted ? Theme.red : Theme.fg }
            DotText { anchors.horizontalCenter: parent.horizontalCenter; text: String(Audio.percent); px: 1; gap: 0.9 }
            Rectangle { visible: root.hasLight; anchors.horizontalCenter: parent.horizontalCenter; width: 16; height: 1; color: Theme.blockBorder }
            DotIcon { visible: root.hasLight; anchors.horizontalCenter: parent.horizontalCenter; name: "sun"; px: 1.2; gap: 0.9; color: Brightness.percent === 0 ? Theme.offDot : Theme.fg }
            DotText { visible: root.hasLight; anchors.horizontalCenter: parent.horizontalCenter; text: String(Brightness.percent); px: 1; gap: 0.9; color: Brightness.percent === 0 ? Theme.red : Theme.fg }
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        function lightSide(mouse) {
            if (!root.hasLight) return false;
            return Theme.vertical ? mouse.y > root.height / 2 : mouse.x > root.width / 2;
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Audio.toggleMute();
            else if (mouse.button === Qt.MiddleButton) { if (root.hasLight) Brightness.set(Brightness.percent === 0 ? 50 : 0); }
            else Popups.toggle("levels");
        }
        onWheel: wheel => {
            const up = wheel.angleDelta.y > 0;
            if (root.hasLight && ((wheel.modifiers & Qt.ShiftModifier) || lightSide(wheel)))
                Brightness.set(Brightness.percent + (up ? 5 : -5));
            else {
                const step = Settings.s.volumeStep / 100;
                Audio.setVolume(Audio.volume + (up ? step : -step));
            }
        }
    }
}
